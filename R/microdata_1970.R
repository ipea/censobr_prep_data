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
# So o arquivo de pessoas entra no produto: 24.793.358 registros. A tabela de
# domicilios do CEM e o crosswalk dele continuam no release_legacy, e continuam
# a ser baixados, mas servem de referencia de validacao -- os domicilios sao
# derivados aqui, em derive_households_1970().
#
# Ficam sem id_household 453.643 pessoas (1,830%): 339.316 individuos em
# domicilio coletivo (V006 == 0) e 114.325 de familias que moram em coletivo
# (V007 == 1).
#
# O dicionario do IBGE rotula V006 == 0 como "PESSOA SO" e V025 == 9 como
# "MEMBRO GRUPO-CONVIDADO", e os dois rotulos enganam. O questionario CD 1.01
# mostra o certo: no quesito 4 a opcao 9 aparece so na coluna da 1a pessoa, e e
# "Individual (Em domicilio coletivo)"; no quesito 1 das caracteristicas do
# domicilio a opcao e "0E Individual", ao lado de "1 Unica" e do grupo
# Convivente (2 Principal, 3E Parente, 4E Nao parente). "Convivente" nomeia as
# familias 2/3/4, nao o codigo 9. As duas colunas dizem a mesma coisa: V006 == 0
# e V025 == 9 coincidem em 339.316 de 339.316, nos dois sentidos.
#
# Nao sao moradores solitarios. Medido so na ordem crua do arquivo, sem usar
# nenhum identificador derivado: as 339.316 formam 40.310 blocos contiguos, de
# comprimento medio 8,4 e ate 3.337 pessoas, 392 deles com 100 ou mais, e
# nenhum atravessa municipio. Se estivessem espalhados ao acaso o comprimento
# medio seria 1,014 e blocos de 100+ teriam probabilidade da ordem de 1e-187.
# Quem mora sozinho de fato (V006 == 1 e V005 == 1) forma 217.013 blocos de
# comprimento medio 1,12, nenhum acima de 74 -- que e o comportamento esperado.
# O perfil fecha: os V006 == 0 tem idade mediana 25 e 11,7% de menores de 15,
# contra 49 e 1,2% de quem mora sozinho.
#
# Os 243.070 domicilios unipessoais particulares estao no produto, e a forma de
# identifica-los no banco de pessoas e V006 == 1 & V005 == 1: familia unica no
# domicilio, e de uma pessoa so. Sao 5,13% dos domicilios.
#
# Sao 4.741.386 domicilios, contra os 4.737.407 da tabela do CEM: entram os
# 3.979 improvisados que ela descartava.
#
# No banco de pessoas a unica alteracao de valor e V021, que vinha 0 onde o
# quesito era pulado e passa a NA. O bloco de caracteristicas da habitacao
# (V007-V021) fica como o IBGE gravou -- preenchido so nos registros da familia
# unica ou principal; nao se propaga para as familias secundarias, porque isso
# seria inventar dado. Ver clean_microdata_1970().
#
# Public API: download_microdata_1970, derive_households_1970,
# clean_microdata_1970, save_microdata_1970.


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


# Deriva a tabela de domicilios a partir do arquivo de pessoas.
#
# O produto ate a v0.6.0 usava a tabela pronta do CEM. Ela continua no
# release_legacy como referencia de validacao, mas nao entra mais no produto:
# a derivacao abaixo reproduz os 4.737.407 domicilios dela em 100,000000% das
# 24.793.358 pessoas, e corrigir os defeitos exige refazer os agregados.
#
# O que muda em relacao ao CEM:
#  - entram os 3.979 domicilios improvisados, que a regra "(5.2) Assigning NA to
#    improvised households" descartava. Sao particulares: V007 == 0 em
#    14.212/14.212, um unico chefe em cada, e o tamanho do grupo bate com o V005
#    do chefe em 3.900 de 3.900 familias unicas;
#  - weight_household passa a ser o peso do chefe do DOMICILIO. O CEM fazia
#    max(V054) entre os chefes de familia, e em domicilio multifamiliar ha dois
#    ou tres V025 == 1: em 46.136 domicilios o max adotava o peso de um chefe
#    secundario, sempre maior, inflando sum(weight_household) em 0,303%;
#  - V006 passa a ser a condicao da familia do chefe do domicilio (1 ou 2). O CEM
#    tirava a media do V006 das pessoas, e V006 e variavel de FAMILIA: 230.394
#    linhas (4,86%) saiam com valores como 2,5 e 2,33, que nao existem no
#    dicionario;
#  - o bloco estrutural (V001-V004, V006-V021) vem da linha do chefe, e nao de
#    mean(). Da no mesmo -- zero domicilios tem mais de um valor de V007 a V020
#    -- e nao inventa codigo de distrito ou de situacao nos 36 domicilios em que
#    o na.locf colou familias de distritos diferentes;
#  - numb_families e numb_residents sao colunas novas. numb_dwellers conta linhas
#    do domicilio, inclusive as 154.719 pessoas que o IBGE marca como NAO MORADOR
#    (V024 == 2, todas pensionista ou hospede); numb_residents exclui essas;
#  - V025 == 0 e IGNORADO, nao nao-parente, e volta a contar no denominador da
#    renda per capita. Sao 341 pessoas em 322 domicilios.
#
# Coletivos ficam de fora: renda domiciliar per capita nao significa nada em
# hotel, quartel, convento ou presidio, cujos moradores nao partilham orcamento.
# Sao 453.641 pessoas -- 339.316 individuais (V006 == 0, o "0E Individual" do
# formulario) e 114.325 de familias que moram em coletivo (V007 == 1).
derive_households_1970 <- function(raw_paths){

  message("Deriving 1970 households")

  pessoas <- raw_paths[grepl("pessoas", basename(raw_paths))]

  # passo 1: a fronteira de domicilio, sobre as 24,8M linhas. Regras do CEM
  # linha a linha, menos a (5.2) que descartava improvisados.
  p <- arrow::open_dataset(pessoas) |>
    dplyr::select(idpessoa, V003, V004, V006, V007, V008, V024, V025, V041, V054) |>
    dplyr::collect() |>
    data.table::as.data.table()
  data.table::setorder(p, idpessoa)

  p[, ind_collective := data.table::fifelse(is.na(V007), 0, V007)]
  p[, flag := NA_real_]
  p[ind_collective == 0 & V025 == 1 & V006 %in% c(1, 2), flag := 1]
  p[c(0, diff(ind_collective)) == 1, flag := 1]
  p[V006 == 0, flag := 1]
  p[V025 == 1 & V006 %in% c(3, 4), flag := NA]

  p[flag == 1, seq_hh := 1:nrow(p[flag == 1])]
  p[, household_id := data.table::nafill((seq_hh * 100 + V003) * 10 + V004,
                                         type = "locf")]

  p[, mean_v007 := mean(V007, na.rm = TRUE), by = household_id]
  p[, mean_v008 := mean(V008, na.rm = TRUE), by = household_id]
  p[mean_v007  %in% 1, household_id := NA_real_]
  p[is.nan(mean_v007), household_id := NA_real_]
  p[is.nan(mean_v008), household_id := NA_real_]
  p[V006 %in% 0,       household_id := NA_real_]

  # passo 2: os agregados. Nao-parente nao entra na renda nem no denominador do
  # per capita: pensionista e hospede paga aluguel ao chefe e empregado domestico
  # recebe salario dele, entao somar as duas pontas contaria a mesma renda duas
  # vezes. O IGNORADO (V025 == 0) nao e nao-parente e conta normalmente.
  p[, nonrelative := as.numeric(V025 >= 7)]
  p[, totalIncome := 0]
  p[V041 <= 9998, totalIncome := V041]
  p[nonrelative == 1, totalIncome := 0]

  agg <- p[!is.na(household_id),
           list(numb_dwellers          = .N,
                numb_residents         = sum(V024 != 2),
                numb_families          = sum(V025 == 1),
                numb_dwellers_hhincome = sum(1 - nonrelative),
                hhIncome               = sum(totalIncome)),
           by = household_id]

  cw     <- p[, list(idpessoa, household_id)]
  chefes <- p[!is.na(household_id) & V025 == 1 & V006 %in% c(1, 2), idpessoa]
  n_pes  <- nrow(p)
  rm(p); gc(verbose = FALSE)

  message("  ", nrow(agg), " households, ", sum(!is.na(cw$household_id)), " people")

  # passo 3: o bloco estrutural e a linha do chefe do domicilio. Lido em faixas
  # de idpessoa porque as 22 colunas em double sobre 24,8M linhas nao cabem na
  # RAM de uma vez.
  vs <- paste0("V", sprintf("%03d", c(1:4, 6:21)))
  faixas <- seq(1, n_pes, by = 5e6)
  blocos <- vector("list", length(faixas))
  for (i in seq_along(faixas)) {
    lo <- faixas[i]
    hi <- min(lo + 5e6 - 1, n_pes)
    b <- arrow::open_dataset(pessoas) |>
      dplyr::filter(idpessoa >= lo, idpessoa <= hi) |>
      dplyr::select(all_of(c("idpessoa", vs, "V054",
                             "MunicCode1970", "MunicCode2010"))) |>
      dplyr::collect() |>
      data.table::as.data.table()
    blocos[[i]] <- b[idpessoa %in% chefes]
    rm(b); gc(verbose = FALSE)
  }
  dom <- data.table::rbindlist(blocos)
  rm(blocos); gc(verbose = FALSE)

  dom <- merge(dom, cw[idpessoa %in% chefes], by = "idpessoa")
  dom <- merge(dom, agg, by = "household_id")

  data.table::setnames(dom, c("V054", "MunicCode1970", "MunicCode2010", "hhIncome"),
                       c("wgthh", "municcode1970", "municcode2010", "hhIncome"))
  dom[, hhIncomePerCap := hhIncome / numb_dwellers_hhincome]
  dom[, idpessoa := NULL]
  data.table::setnames(dom, vs, tolower(vs))
  data.table::setcolorder(dom, c("household_id", tolower(vs), "wgthh",
                                 "numb_dwellers", "numb_residents", "numb_families",
                                 "numb_dwellers_hhincome", "hhIncome",
                                 "hhIncomePerCap", "municcode1970", "municcode2010"))

  out_dir <- "./data_raw/microdata/1970"
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  paths <- c(file.path(out_dir, "households_1970.parquet"),
             file.path(out_dir, "crosswalk_1970.parquet"))
  write_censobr_parquet(dom, paths[1])
  write_censobr_parquet(cw, paths[2])

  rm(dom, cw, agg); gc(verbose = FALSE)

  paths
}


# Abre o parquet da tabela, anexa geografia e devolve query arrow preguicosa.
clean_microdata_1970 <- function(raw_paths, derived_paths, dataset_name){

  message("Cleaning microdata 1970: ", dataset_name)

  dom_path <- derived_paths[grepl("households_1970", basename(derived_paths))]

  if(dataset_name == "households"){

    arrw <- arrow::open_dataset(dom_path) |>
      dplyr::rename(id_household      = household_id,
                    code_muni         = municcode2010,
                    code_muni_1970    = municcode1970,
                    weight_household  = wgthh,
                    hh_income         = hhIncome,
                    hh_income_per_cap = hhIncomePerCap) |>
      dplyr::rename_with(toupper, dplyr::starts_with("v"))

    arrw <- add_geo_1970(arrw)

    # all_of sem o prefixo dplyr:: de proposito: o arrow nao resolve a forma
    # qualificada dentro do tidyselect e cai em "tentativa de aplicar uma
    # nao-funcao". Vale para relocate e select; dentro de across() tanto faz.
    vs <- paste0("V", sprintf("%03d", c(1:4, 6:21)))
    arrw <- arrw |>
      dplyr::relocate(all_of(c(GEO_COLS_1970, "id_household", vs,
                               "weight_household", "numb_dwellers",
                               "numb_residents", "numb_families",
                               "numb_dwellers_hhincome", "hh_income",
                               "hh_income_per_cap")))
    arrw <- relocate_geo_cols_censobr(arrw)
    return(arrw)
  }

  arrw <- arrow::open_dataset(raw_paths[grepl("pessoas", basename(raw_paths))])

  # as cinco colunas cem* sao da harmonizacao do CEM e nao entram no produto
  arrw <- arrw |>
    dplyr::select(-dplyr::matches("^cem", ignore.case = TRUE)) |>
    dplyr::select(-iddomicilio) |>
    dplyr::rename(code_muni      = MunicCode2010,
                  code_muni_1970 = MunicCode1970,
                  id_person      = idpessoa)

  cw <- arrow::read_parquet(derived_paths[grepl("crosswalk_1970", basename(derived_paths))])
  names(cw) <- c("id_person", "id_household")
  arrw <- arrw |> dplyr::left_join(cw, by = "id_person")

  # V021 vem 0 onde o formulario mandava pular -- familia secundaria e individual
  # em domicilio coletivo. Zero ali nao e numero de dormitorios, e o branco do
  # impresso: sao 61.390 registros, todos exatamente 0. Vira NA. O resto do bloco
  # V007-V020 fica como o IBGE gravou: NA fora da familia unica ou principal.
  arrw <- arrw |>
    dplyr::mutate(V021 = ifelse(V006 %in% c(0, 3, 4) & V021 == 0, NA_real_, V021))

  arrw <- add_geo_1970(arrw)

  vs <- paste0("V", sprintf("%03d", 1:54))
  arrw <- arrw |>
    dplyr::relocate(all_of(c(GEO_COLS_1970, vs, "id_person", "id_household")))
  relocate_geo_cols_censobr(arrw)
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

  arrw <- cast_censobr_types(arrw, paste0("1970_", dataset_name))
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
