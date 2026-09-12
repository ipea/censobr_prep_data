# 1970 microdata sample.
#
# A fonte e a versao harmonizada pelo CEM (Centro de Estudos da Metropole),
# hospedada no release_legacy deste repo -- mesma politica de 1960, 1980 e 1991.
#
# Nao se usa o FWF do FTP do IBGE. Dois dos 27 arquivos de la, DAMO70AL.txt e
# Damo70PE.txt, trazem 1.785 registros deslocados: um bloco de 18 ou 60
# caracteres muda de lugar e o peso, que sao os dois ultimos caracteres, deixa
# de cair nas posicoes 75-76. Numa leitura por posicao fixa 899 ficam sem peso
# e 650 saem com um numero errado mas plausivel. A versao do CEM nao tem esse
# defeito. Ver references/microdata_1970_corrupcao_al_pe.md e
# references/microdata_1970_ftp_vs_cem.md.
#
# Tres entradas, e as tres sao necessarias:
#  - pessoas: 24.793.358 registros, com iddomicilio e idpessoa proprios;
#  - domicilios: 4.737.407 registros, ja com os campos derivados (peso, renda,
#    numero de moradores) -- nao ha derivacao por na.locf a refazer aqui;
#  - crosswalk idpessoa -> household_id. Ele e indispensavel: o `iddomicilio`
#    do arquivo de pessoas e outro espaco de numeracao (4.803.419 valores) e
#    NAO casa com o `household_id` dos domicilios (4.737.407) -- nem por
#    formula: testado, erra em 72% das pessoas.
#
# O identificador do arquivo de pessoas tambem foi construido por na.locf e
# tem falhas em coletivos e unipessoais: ha blocos onde a fronteira nunca foi
# encontrada e centenas de pessoas caem num mesmo id (o maior tem 1.281). Por
# isso id_household so vale quando resolve na tabela de domicilios; nos demais
# casos e NA. Sao 468.164 pessoas (1,888%), numero identico ao do publicado.
#
# Public API: download_microdata_1970, clean_microdata_1970, save_microdata_1970.


# Baixa os inputs do release_legacy (smart-skip via download_file_censobr).
download_microdata_1970 <- function(){

  dest_dir <- "./data_raw/microdata/1970"
  dir.create(dest_dir, recursive = TRUE, showWarnings = FALSE)

  message("\nDownloading 1970 microdata (release_legacy)...\n")

  get_release_legacy(c("Censo.1970.brasil.domicilios.amostra.25porcento.parquet",
                       "Censo.1970.brasil.pessoas.amostra.25porcento.parquet",
                       "crosswalk_personid_hhid_1970.parquet"),
                     dest_dir)
}


# Abre o parquet da tabela, anexa geografia e devolve query arrow preguicosa.
clean_microdata_1970 <- function(raw_paths, dataset_name){

  message("Cleaning microdata 1970: ", dataset_name)

  if(dataset_name == "households"){

    arrw <- arrow::open_dataset(raw_paths[grepl("domicilios", basename(raw_paths))])

    arrw <- arrw |>
      dplyr::rename(id_household           = household_id,
                    code_muni              = municcode2010,
                    code_muni_1970         = municcode1970,
                    weight_household       = wgthh,
                    numb_dwellers          = numberDwellers,
                    numb_dwellers_hhincome = numberDwellers_hhIncome,
                    hh_income              = hhIncome,
                    hh_income_per_cap      = hhIncomePerCap) |>
      dplyr::rename_with(toupper, dplyr::starts_with("v"))

    arrw <- add_geo_1970(arrw)

    # all_of sem o prefixo dplyr:: de proposito: o arrow nao resolve a forma
    # qualificada dentro do tidyselect e cai em "tentativa de aplicar uma
    # nao-funcao". Vale para relocate e select; dentro de across() tanto faz.
    vs <- paste0("V", sprintf("%03d", c(1:4, 6:21)))
    arrw <- arrw |>
      dplyr::relocate(all_of(c(GEO_COLS_1970, "id_household", vs,
                               "weight_household", "numb_dwellers",
                               "numb_dwellers_hhincome", "hh_income",
                               "hh_income_per_cap")))
    return(arrw)
  }

  arrw <- arrow::open_dataset(raw_paths[grepl("pessoas", basename(raw_paths))])

  # as cinco colunas cem* sao da harmonizacao do CEM e nao entram no produto
  arrw <- arrw |>
    dplyr::select(-dplyr::matches("^cem", ignore.case = TRUE)) |>
    dplyr::rename(code_muni      = MunicCode2010,
                  code_muni_1970 = MunicCode1970,
                  id_person      = idpessoa)

  # o vinculo pessoa -> domicilio vem do crosswalk, nao do iddomicilio
  cw <- arrow::read_parquet(raw_paths[grepl("crosswalk_personid", basename(raw_paths))])
  hh <- arrow::read_parquet(raw_paths[grepl("domicilios", basename(raw_paths))],
                            col_select = "household_id")

  # so vale o id que existe na tabela de domicilios: coletivos, improvisados e
  # pessoas isoladas nao formam domicilio, e os blocos que o na.locf do CEM
  # deixou colados apontariam para um domicilio inexistente
  cw <- data.frame(id_person    = cw$idpessoa,
                   id_household = ifelse(cw$household_id %in% hh$household_id,
                                         cw$household_id, NA_real_))
  rm(hh); gc(verbose = FALSE)

  arrw <- arrw |>
    dplyr::select(-iddomicilio) |>
    dplyr::left_join(cw, by = "id_person")

  arrw <- add_geo_1970(arrw)

  vs <- paste0("V", sprintf("%03d", 1:54))
  arrw |>
    dplyr::relocate(all_of(c(GEO_COLS_1970, vs, "id_person", "id_household")))
}


# Ordem canonica das colunas de geografia de 1970.
GEO_COLS_1970 <- c("code_muni", "code_muni_1970", "code_state", "abbrev_state",
                   "abbrev_state_1970", "name_state", "name_state_1970",
                   "code_region", "name_region")


# Geografia de 1970: a UF moderna sai do code_muni e a de 1970 do prefixo do
# code_muni_1970. Inline, e nao via add_geography_cols(), pelo mesmo motivo das
# outras edicoes portadas: la os code_* terminam em as.integer, e a convencao
# v0.6.0 pede numeric.
#
# As UFs como eram em 1970: Mato Grosso antes da divisao, Goias antes do
# Tocantins. Guanabara e Fernando de Noronha aparecem sob RJ e PE, que e como
# o produto publicado os trata.
add_geo_1970 <- function(arrw){

  uf_1970_nomes <- data.frame(
    uf_1970           = c(1, 2, 3, 4, 5, 6, 8, 9, 10, 11, 13, 14, 15, 16, 17,
                          19, 21, 23, 24, 25, 27, 29, 31, 32, 34, 35, 36),
    abbrev_state_1970 = c("RO", "AC", "AM", "RR", "PA", "AP", "MA", "PI", "CE",
                          "RN", "PB", "PE", "AL", "PE", "SE", "BA", "MG", "ES",
                          "RJ", "RJ", "SP", "PR", "SC", "RS", "MT", "GO", "DF"),
    name_state_1970   = c("Rondônia", "Acre", "Amazonas", "Roraima", "Pará",
                          "Amapá", "Maranhão", "Piauí", "Ceará",
                          "Rio Grande do Norte", "Paraíba", "Pernambuco", "Alagoas",
                          "Pernambuco", "Sergipe", "Bahia", "Minas Gerais",
                          "Espírito Santo", "Rio de Janeiro", "Rio de Janeiro",
                          "São Paulo", "Paraná", "Santa Catarina",
                          "Rio Grande do Sul", "Mato Grosso", "Goiás",
                          "Distrito Federal"))

  states <- states_censobr()[, c("code_state", "abbrev_state", "name_state",
                                 "code_region", "name_region")]

  arrw |>
    dplyr::mutate(code_state = code_muni %/% 100000,
                  uf_1970    = code_muni_1970 %/% 100000) |>
    dplyr::left_join(states, by = "code_state") |>
    dplyr::left_join(uf_1970_nomes, by = "uf_1970") |>
    dplyr::mutate(uf_1970 = NULL)
}


# Grava o parquet nacional da tabela.
save_microdata_1970 <- function(arrw, dataset_name, data_version){

  message("Saving microdata 1970: ", dataset_name)

  # escrita por streaming: a tabela de pessoas tem 24,8M linhas e nao passa
  # pela RAM. Grupos de 1e6 linhas evitam a fragmentacao em row groups
  # pequenos, que infla o arquivo com o mesmo zstd-22.
  out_dir <- "./data/microdata_sample/1970"
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

  dest_file <- paste0(out_dir, "/1970_", dataset_name, "_", data_version, ".parquet")
  file.rename(file.path(temp_dir, "part-0.parquet"), dest_file)
  unlink(temp_dir, recursive = TRUE)

  dest_file
}
