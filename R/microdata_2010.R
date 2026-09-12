# 2010 microdata sample.
#
# Tudo vem do FTP do IBGE: 28 zips por UF (SP vem partido em SP1 e SP2_RM),
# cada um com os 4 registros em largura fixa. O parsing usa os read guides do
# repo (read_guides/readguide_2010_*.csv), que trazem posicao inicial, final,
# tipo e casas decimais de cada variavel.
#
# Nao uso convert_raw_to_parquet() aqui, por tres motivos: ela ordena pelas 15
# primeiras colunas (destruindo a ordem original), o filtro de integer64 dela
# nunca casa e faz V0011 (13 digitos) estourar int32 virando NA, e ela deriva
# code_muni so de V0002, que e a sequencia dentro da UF (5 digitos) e nao o
# codigo de 7. Aqui o parsing e inline, como em 2022.
#
# Public API: download_microdata_2010, clean_microdata_2010, save_microdata_2010.


# Baixa os 28 zips por UF do FTP e descompacta os .txt.
download_microdata_2010 <- function(){

  dest_dir <- "./data_raw/microdata/2010"
  txt_dir  <- file.path(dest_dir, "txt")
  dir.create(dest_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(txt_dir,  recursive = TRUE, showWarnings = FALSE)

  message("\nDownloading 2010 microdata...\n")

  ftp <- 'https://ftp.ibge.gov.br/Censos/Censo_Demografico_2010/Resultados_Gerais_da_Amostra/Microdados/'

  listed <- list_folders(ftp)

  # 26 UFs + SP1 + SP2_RM; fora a Documentacao.zip
  uf_zips <- listed[grepl("^([A-Z]{2}|SP1|SP2_RM)\\.zip$", listed)]

  # max_active = 1: o FTP do IBGE recusa rajadas paralelas (ver microdata_2022).
  # O laco cobre a falha silenciosa: uma UF faltando viraria um parquet
  # nacional incompleto sem aviso nenhum.
  for(tentativa in 1:3){
    download_file_censobr(file_url = paste0(ftp, uf_zips),
                          dest_dir = dest_dir,
                          max_active = 1)
    faltando <- setdiff(uf_zips, list.files(dest_dir, pattern = "\\.zip$"))
    if(length(faltando) == 0) break
  }
  if(length(faltando) > 0) stop("Faltaram UFs no download: ", paste(faltando, collapse = ", "))

  unzip_censobr(zip_dir = dest_dir, out_zip = txt_dir)

  txt_paths <- list.files(txt_dir, pattern = "\\.txt$", full.names = TRUE, recursive = TRUE)
  if(length(txt_paths) == 0) stop("No TXT files extracted to ", txt_dir)

  txt_paths
}


# Parseia os 28 arquivos de largura fixa de uma tabela, um por vez, gravando um
# parquet de staging por UF. Pessoas nacional tem 20,6M linhas x 244 colunas
# (~37 GB se lido de uma vez), entao ler UF a UF e liberar a RAM entre elas nao
# e otimizacao, e requisito. Devolve query arrow preguicosa sobre o staging.
clean_microdata_2010 <- function(raw_paths, dataset_name){

  message("Cleaning microdata 2010: ", dataset_name)

  tbl_file <- switch(dataset_name,
                     households = "Domicilios",
                     population = "Pessoas",
                     mortality  = "Mortalidade",
                     emigration = "Emigracao")

  files <- raw_paths[grepl(paste0("^Amostra_", tbl_file, "_"), basename(raw_paths))]

  dic <- data.table::fread(paste0("./read_guides/readguide_2010_", dataset_name, ".csv"))

  # as colunas 'd' com casas decimais implicitas: o IBGE grava o inteiro e o
  # numero de casas fica no guide (V0010, o peso, tem 13)
  dec <- dic[dic$col_type == "d" & !is.na(dic$decimal_places) & dic$decimal_places > 0, ]

  states <- states_censobr()[, c("code_state", "abbrev_state", "name_state",
                                 "code_region", "name_region")]

  stage_dir <- file.path("./data_raw/microdata/2010/parquet", dataset_name)
  unlink(stage_dir, recursive = TRUE)
  dir.create(stage_dir, recursive = TRUE, showWarnings = FALSE)

  for(f in files){
    message("  ", basename(f))

    df <- readr::read_fwf(f,
                          readr::fwf_positions(dic$int_pos, dic$fin_pos, dic$var_name),
                          col_types = paste(dic$col_type, collapse = ""))
    data.table::setDT(df)

    for(i in seq_len(nrow(dec)))
      data.table::set(df, j = dec$var_name[i],
                      value = df[[dec$var_name[i]]] / 10^dec$decimal_places[i])

    # geografia inline. code_muni e UF (V0001) + sequencia municipal (V0002,
    # com zeros a esquerda) = 7 digitos; code_weighting vem inteiro em V0011.
    # convencao v0.6.0: code_* numeric.
    df[, code_muni      := as.numeric(paste0(V0001, V0002))]
    df[, code_state     := as.numeric(V0001)]
    df[, code_weighting := as.numeric(V0011)]
    df <- merge(df, states, by = "code_state", all.x = TRUE, sort = FALSE)

    data.table::setcolorder(df, c("code_muni", "code_state", "abbrev_state", "name_state",
                                  "code_region", "name_region", "code_weighting"))

    arrow::write_parquet(df, file.path(stage_dir, sub("\\.txt$", ".parquet", basename(f))))
    rm(df); gc(verbose = FALSE)
  }

  arrow::open_dataset(stage_dir)
}


# Grava o parquet nacional da tabela.
save_microdata_2010 <- function(arrw, dataset_name, data_version){

  message("Saving microdata 2010: ", dataset_name)

  out_dir <- "./data/microdata_sample/2010"
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

  temp_dir <- file.path(out_dir, paste0("tmp_", dataset_name))
  unlink(temp_dir, recursive = TRUE)

  arrow::write_dataset(arrw,
                       path               = temp_dir,
                       format             = "parquet",
                       compression        = "zstd",
                       compression_level  = 22,
                       min_rows_per_group = 1e6L,
                       max_rows_per_group = 1e6L,
                       basename_template  = "part-{i}.parquet")

  dest_file <- paste0(out_dir, "/2010_", dataset_name, "_", data_version, ".parquet")
  file.rename(file.path(temp_dir, "part-0.parquet"), dest_file)
  unlink(temp_dir, recursive = TRUE)

  dest_file
}
