# 2022 microdata sample -- ACESSO PUBLICO.
#
# O IBGE divulgou a amostra de 2022 (31/08/2026) em tres niveis de acesso. Este
# pipeline le o nivel 1 (publico), o unico redistribuivel: os demais sao
# entregues em arquivos rastreaveis por pesquisador, e o termo de compromisso
# veda republicacao.
#
# Duas diferencas do publico que o codigo precisa respeitar:
#  - a geografia para na UF. Nao ha municipio nem area de ponderacao.
#  - o peso amostral se chama *0110 (no controlado e *0111).
#
# O layout publico e o controlado compartilham 256 variaveis com rotulo,
# categorias, largura e tipo identicos, mas com POSICOES FWF diferentes em 248
# delas. Por isso lemos o CSV, que traz header, e nao o TXT.
#
# Public API: download_microdata_2022, clean_microdata_2022, save_microdata_2022.


# Baixa os 27 zips por UF do FTP (smart-skip via download_file_censobr) e
# descompacta os CSVs.
download_microdata_2022 <- function(){

  dest_dir <- "./data_raw/microdata/2022"
  csv_dir  <- file.path(dest_dir, "csv")
  dir.create(dest_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(csv_dir,  recursive = TRUE, showWarnings = FALSE)

  message("\nDownloading 2022 microdata (amostra publica)...\n")

  ftp <- 'https://ftp.ibge.gov.br/Censos/Censo_Demografico_2022/Microdados_e_Areas_de_Ponderacao/Microdados_de_acesso_Publico/csv/'

  listed <- list_folders(ftp)

  # so os zips por UF: Todas_as_UFs.zip repete o mesmo conteudo e dobraria tudo
  uf_zips <- listed[grepl("^[0-9]{2}_[A-Z]{2}\\.zip$", listed)]

  # max_active = 1: pedir as 27 UFs em paralelo faz o FTP do IBGE recusar todas
  # (testado em 2026-09-11: 0 de 27 com o default; serial baixa as 27). Mesmo
  # motivo do coress = 1 no _targets.R.
  # O laco cobre a falha silenciosa que sobrar: uma UF faltando aqui viraria um
  # parquet nacional incompleto sem aviso nenhum. Repetir e barato, porque o
  # smart-skip por tamanho e mtime nao rebaixa o que ja veio inteiro.
  for(tentativa in 1:3){
    download_file_censobr(file_url = paste0(ftp, uf_zips),
                          dest_dir = dest_dir,
                          max_active = 1)
    faltando <- setdiff(uf_zips, list.files(dest_dir, pattern = "\\.zip$"))
    if(length(faltando) == 0) break
  }
  if(length(faltando) > 0) stop("Faltaram UFs no download: ", paste(faltando, collapse = ", "))

  unzip_censobr(zip_dir = dest_dir, out_zip = csv_dir)

  csv_paths <- list.files(csv_dir,
                          pattern    = "\\.csv$",
                          full.names = TRUE,
                          recursive  = TRUE,
                          ignore.case = TRUE)
  csv_paths <- unique(csv_paths)
  if(length(csv_paths) == 0) stop("No CSV files extracted to ", csv_dir)

  csv_paths
}


# Abre os 27 CSVs de uma tabela e anexa a geografia. Devolve query arrow ainda
# preguicosa: Pessoas tem 21,5M linhas x 168 colunas, que nao passam pela RAM
# nem pelo _targets/objects/ -- por isso clean e save vivem no mesmo target.
clean_microdata_2022 <- function(raw_paths, dataset_name){

  message("Cleaning microdata 2022: ", dataset_name)

  # nome da tabela nos arquivos do IBGE e prefixo das colunas do registro
  tbl_file <- switch(dataset_name,
                     households = "Domicilios",
                     families   = "Familia",
                     mortality  = "Mortalidade",
                     population = "Pessoas")

  prefix <- switch(dataset_name,
                   households = "D",
                   families   = "F",
                   mortality  = "M",
                   population = "P")

  files <- raw_paths[grepl(paste0("^", tbl_file, "_"), basename(raw_paths))]

  # schema declarado: sem ele o arrow tipa como null as colunas que estao em
  # branco no primeiro bloco do primeiro arquivo que le.
  arrw <- arrow::open_delim_dataset(files,
                                    delim     = ";",
                                    col_types = get_schema(2022, dataset_name),
                                    na        = "")

  # geografia inline, e nao via add_geography_cols(): o publico so tem regiao e
  # UF, a coluna de origem muda de nome por tabela (D0020/P0020/F0020/M0020) e
  # o ramo year == 2022 daquela funcao ja pertence aos setores.
  # convencao v0.6.0: code_* numeric ja na criacao -- code_cols_to_numeric()
  # opera sobre data.frame e quebraria o lazy.
  col_state <- paste0(prefix, "0020")

  arrw <- arrw |>
    dplyr::mutate(code_state = as.numeric(get(col_state)))

  states <- states_censobr()[, c("code_state", "abbrev_state", "name_state",
                                 "code_region", "name_region")]

  arrw <- arrw |>
    dplyr::left_join(states, by = "code_state")

  relocate_geo_cols_censobr(arrw)
}


# Grava o parquet nacional da tabela.
#
# O sufixo `.publico` distingue a amostra publica da de acesso controlado, que
# o pesquisador importa por conta propria: as duas tem as mesmas 4 tabelas, mas
# colunas diferentes (peso *0110 contra *0111, e geografia ate a UF contra ate
# a area de ponderacao).
save_microdata_2022 <- function(arrw, dataset_name, data_version){

  message("Saving microdata 2022: ", dataset_name)

  # escrita por streaming: write_censobr_parquet() materializaria a tabela
  # inteira em RAM. write_dataset consome batch a batch; os grupos de 1e6
  # linhas evitam a fragmentacao em row groups pequenos, que infla o arquivo em
  # ~45% com o mesmo zstd-22.
  out_dir <- "./data/microdata_sample/2022"
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

  temp_dir <- file.path(out_dir, paste0("tmp_", dataset_name))
  unlink(temp_dir, recursive = TRUE)

  arrw <- cast_censobr_types(arrw, paste0("2022_", dataset_name))
  arrow::write_dataset(arrw,
                       path               = temp_dir,
                       format             = "parquet",
                       compression        = "zstd",
                       compression_level  = 22,
                       min_rows_per_group = 1e6L,
                       max_rows_per_group = 1e6L,
                       basename_template  = "part-{i}.parquet")

  dest_file <- paste0(out_dir, "/2022_", dataset_name, ".publico_", data_version, ".parquet")
  file.rename(file.path(temp_dir, "part-0.parquet"), dest_file)
  unlink(temp_dir, recursive = TRUE)

  dest_file
}
