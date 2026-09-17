# 2022 census tracts -- resultados PRELIMINARES.
#
# Divulgacao previa do Censo 2022, anterior aos agregados definitivos. Fonte:
# Agregados_preliminares_por_setores_censitarios_BR.zip, um unico CSV nacional
# de 29 colunas -- CD_SETOR, AREA_KM2, 20 de geografia e v0001 a v0007.
#
# O codigo de setor vem com um "P" (de preliminar) que precisa sair para casar
# com o setor definitivo.
#
# Duas divergencias deliberadas em relacao ao 2022_tracts_preliminares
# publicado ate a v0.6.0, que nao veio deste pipeline:
#
#  - o publicado tem 414.790 setores, e este tem os 452.340 que o IBGE
#    divulgou. A diferenca sao 37.550 setores (8,3%) que existem na malha
#    preliminar e nao na definitiva -- a versao antiga fazia inner join com o
#    Basico definitivo e os descartava em silencio;
#  - o publicado tem 57 colunas porque trazia, alem dos nomes crus do IBGE e
#    dos censobr, seis colunas que so existem na malha definitiva (situacao,
#    code_type, code_neighborhood, code_nucleo_urbano, code_favela e
#    code_aglomerado). Aqui ficam as 28 da fonte com o nome original (AREA_KM2
#    vira area_km2), mais as 22 colunas censobr de geografia derivadas delas.
#
# Esta tabela guarda code_meso e code_micro, que o IBGE nao publica no Basico
# definitivo de 2022.
#
# Public API: download_tract_2022_prelim, clean_tracts_2022_prelim,
#             save_tracts_2022_prelim.


# Baixa e descompacta o CSV nacional.
download_tract_2022_prelim <- function(remote){

  dest_dir <- "./data_raw/tracts/2022_preliminares"
  dir.create(dest_dir, recursive = TRUE, showWarnings = FALSE)

  message("\nDownloading 2022 census tracts (preliminares) ...\n")

  # `remote` vem de ftp_fingerprint_censobr() com a URL do zip (o endereco
  # esta em FTP_CENSOBR) e e a dependencia que detecta republicacao.
  download_file_censobr(file_url = remote$url, dest_dir = dest_dir, max_active = 1)
  unzip_censobr(zip_dir = dest_dir, out_zip = dest_dir)

  csv <- list.files(dest_dir, pattern = "\\.csv$", full.names = TRUE, ignore.case = TRUE)
  if(length(csv) != 1) stop("2022 preliminares: esperava 1 CSV, achei ", length(csv))

  csv
}


# Le o CSV, acrescenta as colunas censobr de geografia e devolve a tabela. As
# 29 colunas do IBGE ficam com o nome original.
clean_tracts_2022_prelim <- function(raw_csv_path){

  message("Cleaning 2022 tracts: preliminares")

  df <- data.table::fread(raw_csv_path, sep = ";", dec = ",", showProgress = FALSE)
  data.table::setnames(df, toupper(names(df)))

  # o "P" marca o setor como preliminar e nao faz parte do codigo; o code_tract
  # censobr e numerico, o CD_SETOR do IBGE segue como texto
  df <- dplyr::mutate(df,
                      code_tract               = as.numeric(gsub("P", "", CD_SETOR)),
                      area_km2                 = AREA_KM2   ,
                      code_region              = CD_REGIAO  ,
                      name_region              = NM_REGIAO  ,
                      code_state               = CD_UF      ,
                      name_state               = NM_UF      ,
                      code_muni                = CD_MUN     ,
                      name_muni                = NM_MUN     ,
                      code_district            = CD_DIST    ,
                      name_district            = NM_DIST    ,
                      code_subdistrict         = CD_SUBDIST ,
                      name_subdistrict         = NM_SUBDIST ,
                      code_meso                = CD_MESO    ,
                      name_meso                = NM_MESO    ,
                      code_micro               = CD_MICRO   ,
                      name_micro               = NM_MICRO   ,
                      code_intermediate        = CD_RGINT   ,
                      name_intermediate        = NM_RGINT   ,
                      code_immediate           = CD_RGI     ,
                      name_immediate           = NM_RGI     ,
                      code_urban_concentration = CD_CONCURB ,
                      name_urban_concentration = NM_CONCURB)

  # convencao v0.6.0: todo code_* e numeric. As V tambem, que o IBGE censura
  # com "X" em setor pequeno e o fread deixa como texto.
  num_cols <- c(grep("^code_", names(df), value = TRUE), "area_km2",
                paste0("V000", 1:7))
  df <- dplyr::mutate(df, dplyr::across(dplyr::all_of(num_cols), as.numeric))

  # unica excecao a regra de manter as colunas do IBGE: area_km2 substitui AREA_KM2
  df$AREA_KM2 <- NULL

  relocate_geo_cols_censobr(df)
}


# Grava o parquet.
save_tracts_2022_prelim <- function(df, data_version){

  message("Saving 2022 tracts: preliminares")

  out_dir <- "./data/tracts/2022"
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

  dest_file <- paste0(out_dir, "/2022_tracts_preliminares_", data_version, ".parquet")
  df <- cast_censobr_types(df, "2022_tracts_preliminares")
  write_censobr_parquet(df, dest_file)

  dest_file
}
