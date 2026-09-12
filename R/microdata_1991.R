# 1991 microdata sample.
#
# O IBGE republicou 1991 em DBF no FTP, num arquivo unico em nivel de PESSOA
# (as variaveis do domicilio se repetem em cada morador). Essa versao nao traz
# a V0102 -- "Identificacao do Questionario", o numero unico do domicilio, que
# e a chave entre pessoa e domicilio e carrega, nos 4 digitos do meio, a
# unidade submunicipal de ponderacao. O agrupamento pessoa->domicilio ate se
# reconstroi (a ordem da pessoa reinicia a cada domicilio), mas o codigo em si
# e o bloco submunicipal nao. Por isso a fonte canonica aqui e a amostra
# preparada, hospedada no release `release_legacy` -- mesma politica do 1960 e
# do 1980. Apuracao em references/microdata_1991_ftp_vs_aux.md.
#
# Public API: download_microdata_1991, clean_microdata_1991, save_microdata_1991.


# Baixa os inputs do release_legacy (smart-skip via download_file_censobr).
download_microdata_1991 <- function(){

  dest_dir <- "./data_raw/microdata/1991"
  dir.create(dest_dir, recursive = TRUE, showWarnings = FALSE)

  message("\nDownloading 1991 microdata (release_legacy)...\n")

  get_release_legacy(c("Censo.1991.brasil.domicilios.amostra.10porcento.parquet",
                       "Censo.1991.brasil.pessoas.amostra.10porcento.parquet"),
                     dest_dir)
}


# Abre o parquet da tabela, anexa geografia e devolve query arrow preguicosa:
# pessoas tem 17M linhas x 145 colunas.
clean_microdata_1991 <- function(raw_paths, dataset_name){

  message("Cleaning microdata 1991: ", dataset_name)

  tbl_file <- switch(dataset_name,
                     households = "domicilios",
                     population = "pessoas")

  arrw <- arrow::open_dataset(raw_paths[grepl(tbl_file, basename(raw_paths))])

  # o CSV de pessoas veio com os V minusculos misturados
  arrw <- dplyr::rename_with(arrw, toupper, dplyr::starts_with("v"))

  # code_muni de 7 digitos pela malha de 1991, casando pelos 6 primeiros:
  # UF (V1101) + municipio (V1102, com zeros a esquerda)
  muni <- geobr::read_municipality(year = 1991, showProgress = FALSE)
  muni <- sf::st_drop_geometry(muni)
  muni <- data.frame(code_muni6 = substr(as.character(muni$code_muni), 1, 6),
                     code_muni  = as.numeric(muni$code_muni))

  # V1102 vai preenchida com zeros a esquerda tambem no produto, como em v0.5.0
  arrw <- arrw |>
    dplyr::mutate(V1102 = stringr::str_pad(V1102, 4, pad = "0"),
                  code_muni6 = paste0(V1101, V1102)) |>
    dplyr::left_join(muni, by = "code_muni6") |>
    dplyr::mutate(code_muni6 = NULL)

  # Itapipoca (CE): a camada de 1991 do geobr traz o codigo com dois digitos
  # trocados (2306045 em vez de 2306405), e sem isso 1.525 domicilios ficam sem
  # code_muni. 2306405 e o codigo correto -- e o que as camadas de 2000 em
  # diante do proprio geobr usam, e o que v0.5.0/v0.6.0 publicam.
  arrw <- arrw |>
    dplyr::mutate(code_muni = dplyr::if_else(V1101 == "23" & V1102 == "0640",
                                             2306405, code_muni))

  # geografia inline; convencao v0.6.0: code_* numeric ja na criacao
  arrw <- arrw |>
    dplyr::mutate(code_state = as.numeric(V1101),
                  code_meso  = as.numeric(V7001),
                  code_micro = as.numeric(V7002),
                  code_metro = as.numeric(V7003))

  states <- states_censobr()[, c("code_state", "abbrev_state", "name_state",
                                 "code_region", "name_region")]

  arrw <- arrw |>
    dplyr::left_join(states, by = "code_state")

  # as V numericas de cada tabela, e o peso, que o IBGE grava como inteiro
  # com 8 casas decimais implicitas
  if(dataset_name == "households"){
    num_vars <- c("V0102", "V0098", "V0109", "V0111", "V0112", "V2012",
                  "V0209", "V0211", "V2111", "V0212", "V2121", "V7300")
    peso <- "V7300"
  } else {
    num_vars <- c("V3041", "V3042", "V3043", "V3045", "V3072", "V3073",
                  "V3152", "V0317", "V0318", "V3311", "V3312", "V3341", "V0354",
                  "V0355", "V3561", "V0357", "V0360", "V0361", "V3351", "V3352",
                  "V3353", "V3354", "V3355", "V3356", "V3360", "V3361", "V3362",
                  "V0335", "V0336", "V0340", "V3357", "V3443", "V7301")
    peso <- "V7301"
  }
  num_vars <- intersect(num_vars, names(arrw))

  arrw <- arrw |>
    dplyr::mutate(dplyr::across(dplyr::all_of(num_vars), as.numeric)) |>
    dplyr::mutate(dplyr::across(dplyr::all_of(peso), ~ .x / 10^8)) |>
    dplyr::relocate(code_muni, code_state, abbrev_state, name_state,
                    code_region, name_region, code_meso, code_micro, code_metro)

  arrw
}


# Grava o parquet nacional da tabela.
save_microdata_1991 <- function(arrw, dataset_name, data_version){

  message("Saving microdata 1991: ", dataset_name)

  out_dir <- "./data/microdata_sample/1991"
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

  dest_file <- paste0(out_dir, "/1991_", dataset_name, "_", data_version, ".parquet")
  file.rename(file.path(temp_dir, "part-0.parquet"), dest_file)
  unlink(temp_dir, recursive = TRUE)

  dest_file
}
