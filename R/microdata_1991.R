# 1991 microdata sample.
#
# O IBGE republicou 1991 em DBF no FTP, num arquivo unico em nivel de PESSOA
# (as variaveis do domicilio se repetem em cada morador). Essa versao nao traz
# a V0102 -- "Identificacao do Questionario", o numero unico do domicilio e a
# chave entre pessoa e domicilio. O agrupamento pessoa->domicilio ate se
# reconstroi a partir do DBF (a ordem da pessoa reinicia a cada domicilio), mas
# o codigo em si nao.
#
# A V0102 tem 9 digitos: prefixo(2) + PASTA(4) + NUMERO NA PASTA(3), que sao os
# campos 2 e 3 do cabecalho do CD 1.02. Pasta e arquivo, nao geografia: o Manual
# do Recenseador (PA 1.09, p. 32) diz que os campos 2 e 3 sao "para Uso do Orgao
# Central" e o recenseador nao os preenche. O dado confirma -- mediana de 154
# questionarios por pasta, quartis 135-171, numeracao interna 1..N sem buraco em
# 87,1% delas. Nao e unidade de ponderacao: o peso e praticamente unico dentro
# da pasta (3 de 27.819 tem peso constante) e ela explica R2 = 0,218 da variancia
# do peso, contra 0,210 so do municipio. O prefixo tambem nao e a UF: 26 UFs usam
# o proprio codigo, e SP usa dois -- 35 para os 8 municipios do nucleo
# metropolitano, 36 para os outros 564.
#
# A geografia submunicipal de verdade -- distrito, subdistrito, setor, quarteirao
# e face, campos 4 a 8 do mesmo cabecalho -- nao esta em nenhuma das duas fontes. Por isso a fonte canonica aqui e a amostra
# preparada, hospedada no release `release_legacy` -- mesma politica do 1960 e
# do 1980. Apuracao em references/microdata_1991_ftp_vs_aux.md.
#
# Tres correcoes apuradas contra o DBF do IBGE e, sobretudo, contra o dicionario
# oficial (Dicionario 1991.xls, que acompanha o zip do FTP):
#
#  - os tipos eram decididos por duas listas escritas a mao, uma por ramo, e 11
#    colunas saiam numericas em domicilios e string em pessoas. Uma delas e a
#    V0102, a unica ponte entre as duas tabelas: o join so casava com cast
#    explicito. Agora a lista e unica;
#  - V2012 (renda domiciliar) e V3045 (renda familiar) traziam 9999999999, de
#    dez digitos, em 1.175.719 registros. O dicionario declara a faixa 0 a
#    999999999, com NSA = 999999998 e Ignorado = 999999999. Varri as 132
#    variaveis com faixa declarada: estas duas eram as unicas fora da faixa;
#  - a renda familiar per capita (10.8 RFAPCAPV no dicionario) nao vinha na
#    fonte do CEM, e e reconstruida aqui.
#
# O DBF do FTP serve so de referencia de validacao, nunca de fonte. Ele tem 59
# registros de pessoa a mais que o produto, e a diferenca e toda de um municipio
# so: Ariquemes (1100023, RO), onde faltam 58 pessoas e 11 domicilios; o 59o
# esta na Bahia. O domicilio 110043042, que consta da tabela de domicilios sem
# nenhum morador no banco de pessoas, e desse mesmo municipio. As outras 26 UFs
# batem registro a registro. Ver references/microdata_1991_ftp_vs_aux.md.
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

  # as V numericas, e o peso, que o IBGE grava como inteiro com 8 casas decimais
  # implicitas. Na tabela de pessoas ha dois: V7301 (da pessoa) e V7300 (do
  # domicilio, repetido em cada morador). O script legado so dividia o da
  # pessoa, e a V7300 saia como string com o inteiro cru -- 10% dela em notacao
  # cientifica, inutilizavel. Aqui os dois recebem o mesmo tratamento.
  #
  # Uma lista so para as duas tabelas, e nao uma por ramo: o que existir na
  # tabela e convertido. Com duas listas escritas a mao, as 11 colunas que
  # apareciam numa e nao na outra -- V0098, V0102, V0109, V0111, V0112, V0209,
  # V0211, V0212, V2012, V2111, V2121 -- saiam numericas em domicilios e string
  # em pessoas. A V0102 e a unica ponte entre as duas tabelas, e o join so
  # casava com cast explicito.
  num_vars <- c("V0098", "V0102", "V0109", "V0111", "V0112", "V0209", "V0211",
                "V0212", "V2012", "V2111", "V2121",
                "V3041", "V3042", "V3043", "V3045", "V3072", "V3073", "V3152",
                "V0317", "V0318", "V3311", "V3312", "V3341", "V0354", "V0355",
                "V3561", "V0357", "V0360", "V0361", "V3351", "V3352", "V3353",
                "V3354", "V3355", "V3356", "V3360", "V3361", "V3362", "V0335",
                "V0336", "V0340", "V3357", "V3443", "V7300", "V7301")
  peso     <- c("V7300", "V7301")
  num_vars <- intersect(num_vars, names(arrw))
  peso     <- intersect(peso, names(arrw))

  arrw <- arrw |>
    dplyr::mutate(dplyr::across(dplyr::all_of(num_vars), as.numeric)) |>
    dplyr::mutate(dplyr::across(dplyr::all_of(peso), ~ .x / 10^8))

  # o dicionario do IBGE declara NSA = 999999998 e Ignorado = 999999999 para a
  # renda domiciliar (V2012) e a familiar (V3045). A fonte do CEM colapsou os
  # dois num 9999999999 de dez digitos, fora da faixa declarada, em 1.175.719
  # registros das duas tabelas. Volta ao codigo do dicionario -- a distincao
  # entre NSA e Ignorado ja se perdeu a montante e nao e recuperavel aqui.
  sentinela <- intersect(c("V2012", "V3045"), names(arrw))
  arrw <- arrw |>
    dplyr::mutate(dplyr::across(all_of(sentinela),
                                ~ ifelse(.x == 9999999999, 999999999, .x)))

  # Renda familiar per capita. O dicionario do IBGE tem a variavel (10.8
  # RFAPCAPV) e a versao do CEM nao a trouxe -- e a unica variavel substantiva
  # do dicionario ausente do produto; as outras quatro sem mapeamento sao
  # rotulos de nome de UF, meso, micro e municipio, que ja saem como name_*.
  # A regra abaixo reproduz o DBF do IBGE em 97,01% dos registros ao centavo em
  # Roraima: renda familiar sobre os membros da familia, fora pensionista (14),
  # empregado domestico (15) e parente do empregado domestico (16). Excluir
  # tambem o agregado piora para 89,5%, entao ele conta como membro.
  if(dataset_name == "population"){

    membros <- arrw |>
      dplyr::filter(!(V0303 %in% c("14", "15")), !(V0302 %in% c("14", "15", "16"))) |>
      dplyr::count(V0102, V0304, name = "numb_family_members") |>
      dplyr::collect()

    arrw <- arrw |>
      dplyr::left_join(membros, by = c("V0102", "V0304")) |>
      dplyr::mutate(family_income_per_cap =
                      ifelse(V3045 >= 999999998, NA_real_,
                             V3045 / numb_family_members))
  }

  relocate_geo_cols_censobr(arrw)
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
