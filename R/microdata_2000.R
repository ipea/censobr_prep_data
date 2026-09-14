# 2000 microdata sample.
#
# Tudo vem do FTP do IBGE: 27 zips por UF, cada um com DOM<cod>.txt,
# PES<cod>.txt e FAMI<cod>.TXT em largura fixa. O parsing usa os read guides
# do repo (read_guides/readguide_2000_*.csv).
#
# Dois defeitos de empacotamento do IBGE que precisam de tratamento explicito,
# os dois silenciosos (nada quebra, o dado e que sai errado):
#
#  - RN.zip traz seis arquivos, nao tres: os do Rio Grande do Norte (codigo 24)
#    E uma copia integral da Paraiba (codigo 25), byte a byte igual a de
#    PB.zip. Um glob ingenuo empilha a PB duas vezes (+487.848 pessoas). Por
#    isso so aceitamos, de cada pasta de UF, o arquivo cujo codigo bate com o
#    da propria UF.
#  - BA.zip tem zip dentro de zip: PES29.zip e FAMI29.zip. Sem descompactar em
#    laco, a Bahia entra so com domicilios e somem 1,6 milhao de pessoas. E o
#    arquivo interno dela vem em minusculas (pes29.txt), unico no lote.
#
# Public API: download_microdata_2000, clean_microdata_2000, save_microdata_2000.


# Baixa os 27 zips por UF do FTP e descompacta em laco (ha zip aninhado).
download_microdata_2000 <- function(){

  dest_dir <- "./data_raw/microdata/2000"
  txt_dir  <- file.path(dest_dir, "txt")
  dir.create(dest_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(txt_dir,  recursive = TRUE, showWarnings = FALSE)

  message("\nDownloading 2000 microdata...\n")

  ftp <- 'https://ftp.ibge.gov.br/Censos/Censo_Demografico_2000/Microdados/'

  listed <- list_folders(ftp)
  uf_zips <- listed[grepl("^[A-Z]{2}\\.zip$", listed)]

  # max_active = 1: o FTP do IBGE recusa rajadas paralelas (ver microdata_2022)
  for(tentativa in 1:3){
    download_file_censobr(file_url = paste0(ftp, uf_zips),
                          dest_dir = dest_dir,
                          max_active = 1)
    faltando <- setdiff(uf_zips, list.files(dest_dir, pattern = "\\.zip$"))
    if(length(faltando) == 0) break
  }
  if(length(faltando) > 0) stop("Faltaram UFs no download: ", paste(faltando, collapse = ", "))

  unzip_censobr(zip_dir = dest_dir, out_zip = txt_dir)

  # segundo nivel: a Bahia embrulhou PES e FAMI em zips proprios
  repeat {
    aninhados <- list.files(txt_dir, pattern = "\\.zip$", full.names = TRUE, recursive = TRUE)
    if(length(aninhados) == 0) break
    for(z in aninhados){
      utils::unzip(z, exdir = dirname(z))
      unlink(z)
    }
  }

  txt_paths <- list.files(txt_dir, pattern = "\\.txt$", full.names = TRUE,
                          recursive = TRUE, ignore.case = TRUE)
  if(length(txt_paths) == 0) stop("No TXT files extracted to ", txt_dir)

  txt_paths
}


# Parseia os 27 arquivos de largura fixa de uma tabela, um por vez, gravando um
# parquet de staging por UF. Pessoas nacional tem 20,3M linhas x 183 colunas.
clean_microdata_2000 <- function(raw_paths, dataset_name){

  message("Cleaning microdata 2000: ", dataset_name)

  prefixo <- switch(dataset_name,
                    households = "DOM",
                    population = "PES",
                    families   = "FAMI")

  # de cada pasta de UF so entra o arquivo cujo codigo bate com a propria UF --
  # e o que descarta a copia da Paraiba que veio dentro do RN.zip
  states <- states_censobr()
  cod_da_pasta <- states$code_state[match(toupper(basename(dirname(raw_paths))), states$abbrev_state)]
  esperado <- paste0(prefixo, cod_da_pasta, ".txt")
  files <- raw_paths[!is.na(cod_da_pasta) &
                     toupper(basename(raw_paths)) == toupper(esperado)]

  # um arquivo por pasta de UF -- pega tanto a duplicata da PB quanto uma UF
  # que tenha ficado para tras na descompactacao
  ufs <- unique(basename(dirname(raw_paths)))
  if(length(files) != length(ufs))
    stop("2000 ", dataset_name, ": ", length(ufs), " UFs na entrada mas ", length(files), " arquivos selecionados")

  dic <- data.table::fread(paste0("./read_guides/readguide_2000_", dataset_name, ".csv"))
  dec <- dic[dic$col_type == "d" & !is.na(dic$decimal_places) & dic$decimal_places > 0, ]

  geo <- states[, c("code_state", "abbrev_state", "name_state", "code_region", "name_region")]

  stage_dir <- file.path("./data_raw/microdata/2000/parquet", dataset_name)
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

    # geografia inline. Em 2000 o municipio (V0103) ja vem com 7 digitos e a
    # area de ponderacao e a AREAP. convencao v0.6.0: code_* numeric.
    df[, code_muni      := as.numeric(V0103)]
    df[, code_state     := as.numeric(V0102)]
    df[, code_weighting := as.numeric(AREAP)]

    # o byte de fim de arquivo do DOS (0x1A) no fim de alguns .txt vira um
    # registro com tudo vazio. Sao 2 linhas no pais inteiro (1 em Domicilios,
    # 1 em Pessoas), sem peso e sem geografia -- estao ate no produto
    # publicado. Aqui saem, e a contagem fica no log.
    lixo <- sum(is.na(df$code_state))
    if(lixo > 0){
      message("    descartando ", lixo, " registro(s) sem UF (byte de EOF)")
      df <- df[!is.na(code_state)]
    }

    df <- merge(df, geo, by = "code_state", all.x = TRUE, sort = FALSE)

    data.table::setcolorder(df, c("code_muni", "code_state", "abbrev_state", "name_state",
                                  "code_region", "name_region", "code_weighting"))

    arrow::write_parquet(df, file.path(stage_dir, paste0(tools::file_path_sans_ext(basename(f)), ".parquet")))
    rm(df); gc(verbose = FALSE)
  }

  arrow::open_dataset(stage_dir)
}


# Grava o parquet nacional da tabela.
save_microdata_2000 <- function(arrw, dataset_name, data_version){

  message("Saving microdata 2000: ", dataset_name)

  out_dir <- "./data/microdata_sample/2000"
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

  temp_dir <- file.path(out_dir, paste0("tmp_", dataset_name))
  unlink(temp_dir, recursive = TRUE)

  arrw <- relocate_geo_cols_censobr(arrw)
  arrow::write_dataset(arrw,
                       path               = temp_dir,
                       format             = "parquet",
                       compression        = "zstd",
                       compression_level  = 22,
                       min_rows_per_group = 1e6L,
                       max_rows_per_group = 1e6L,
                       basename_template  = "part-{i}.parquet")

  dest_file <- paste0(out_dir, "/2000_", dataset_name, "_", data_version, ".parquet")
  file.rename(file.path(temp_dir, "part-0.parquet"), dest_file)
  unlink(temp_dir, recursive = TRUE)

  dest_file
}
