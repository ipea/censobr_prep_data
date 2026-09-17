# 1980 microdata sample.
#
# O IBGE republicou 1980 em DBF no FTP em 2025, mas essa versao perde quatro
# variaveis que a amostra preparada pelo Rogerio tem: V518 (UF e/ou municipio
# anterior -- a unica origem geografica do bloco de migracao), V3 (mesorregiao),
# V4 (microrregiao) e V6 (distrito). Nenhuma delas e reconstruivel a partir do
# DBF. Por isso a fonte canonica aqui e a amostra preparada, hospedada no
# release `release_legacy` deste repo -- mesma politica do 1960.
# Apuracao em references/microdata_1980_ftp_vs_aux.md.
#
# Public API: download_microdata_1980, clean_microdata_1980, save_microdata_1980.


# Baixa os inputs do release_legacy (smart-skip via download_file_censobr).
download_microdata_1980 <- function(){

  dest_dir <- "./data_raw/microdata/1980"
  dir.create(dest_dir, recursive = TRUE, showWarnings = FALSE)

  message("\nDownloading 1980 microdata (release_legacy)...\n")

  get_release_legacy(c("Censo.1980.brasil.domicilios.amostra.25porcento.parquet",
                       "Censo.1980.brasil.pessoas.amostra.25porcento.parquet",
                       "crosswalk_tocantins_ferNoronha_1980_2010.xlsx"),
                     dest_dir)
}


# Abre o parquet da tabela, anexa geografia e devolve query arrow preguicosa:
# pessoas tem 29,4M linhas x 90 colunas, que nao passam pela RAM nem pelo
# _targets/objects/ -- por isso clean e save vivem no mesmo target.
clean_microdata_1980 <- function(raw_paths, dataset_name){

  message("Cleaning microdata 1980: ", dataset_name)

  tbl_file <- switch(dataset_name,
                     households = "domicilios",
                     population = "pessoas")

  arrw <- arrow::open_dataset(raw_paths[grepl(tbl_file, basename(raw_paths))])

  # o CSV de pessoas veio com os V minusculos misturados; o de domicilios nao
  arrw <- dplyr::rename_with(arrw, toupper, dplyr::starts_with("v"))

  # code_muni_1980: o codigo historico de 6 digitos e UF (V2) + municipio (V5)
  arrw <- arrw |>
    dplyr::mutate(code_muni_1980 = as.numeric(V2) * 10000 + as.numeric(V5))

  # code_muni de 7 digitos pela malha de 1980, casando pelos 6 primeiros. O
  # produto tem de casar com geobr::read_municipality(year = 1980), entao a
  # geografia fica na geografia de 1980: Fernando de Noronha e 2000107, no
  # territorio 20, e os 52 municipios que viriam a ser o Tocantins continuam em
  # Goias (52xxxxx), que e onde estavam. Os 3.991 codigos do dado resolvem
  # todos nessa malha.
  #
  # O crosswalk_tocantins_ferNoronha_1980_2010.xlsx NAO entra aqui: ele reescreve
  # esses 53 municipios para o codigo de 2010 (prefixo 17 e 26), que nao existe
  # na malha de 1980 -- era o que deixava 35.567 domicilios sem code_muni.
  # Decisao de 2026-09-12: o arquivo continua sendo baixado e nao e usado. Optou-se
  # por nao expor o codigo de 2010 em coluna propria nem tirar do download, para
  # nao mexer no schema publicado. Fica disponivel se um dia se quiser a ligacao
  # 1980 <-> 2010.
  m80 <- sf::st_drop_geometry(geobr::read_municipality(year = 1980, showProgress = FALSE))
  muni <- data.frame(code_muni_1980 = as.numeric(substr(as.character(m80$code_muni), 1, 6)),
                     code_muni      = as.numeric(m80$code_muni))

  arrw <- arrw |>
    dplyr::left_join(muni, by = "code_muni_1980")

  # geografia inline, e nao via add_geography_cols(): o ramo 1980 daquela
  # funcao atribui V3 tanto a code_meso quanto a code_micro, e V4 (a
  # microrregiao de verdade) fica de fora. Aqui code_micro recebe V4.
  # convencao v0.6.0: code_* numeric ja na criacao.
  arrw <- arrw |>
    dplyr::mutate(code_state = as.numeric(V2),
                  code_meso  = as.numeric(V3),
                  code_micro = as.numeric(V4))

  states <- states_censobr()[, c("code_state", "abbrev_state", "name_state",
                                 "code_region", "name_region")]

  # o Territorio de Fernando de Noronha (codigo 20) existia em 1980 e nao esta
  # em states_censobr(), que so traz as 27 UFs de hoje. Sem esta linha os 69
  # domicilios de la ficam sem sigla, sem nome de UF e sem regiao.
  states <- rbind(states,
                  data.frame(code_state   = 20,
                             abbrev_state = "FN",
                             name_state   = "Fernando de Noronha",
                             code_region  = 2,
                             name_region  = "Nordeste"))

  arrw <- arrw |>
    dplyr::left_join(states, by = "code_state")

  # as poucas V numericas; o resto do questionario fica como string, que e
  # como a amostra preparada guarda
  num_vars <- c("V211", "V212", "V213", "V602", "V603")
  if(dataset_name == "population"){
    num_vars <- c(num_vars, "V517", "V536", "V557", "V570", "V604", "V606",
                  "V607", "V608", "V609", "V610", "V611", "V612", "V613")
  }
  num_vars <- intersect(num_vars, names(arrw))

  arrw <- arrw |>
    dplyr::mutate(dplyr::across(dplyr::all_of(num_vars), as.numeric))

  # Nos 233.344 domicilios de especie != 1 o questionario de domicilio nunca foi
  # aplicado, e as 17 variaveis categoricas do bloco ja marcam essas linhas com
  # NA. V212 (total de comodos), V213 (comodos servindo de dormitorio) e V602
  # (aluguel) vinham com zero no lugar, que nao e valor: e "nao perguntamos", e
  # somado ou mediado por engano puxa qualquer media para baixo.
  # O corte e por universo (V201), nao por valor: em V602 os outros 4.692.950
  # zeros sao de especie 1 e sao substantivos -- domicilio proprio, que de fato
  # nao paga aluguel -- e continuam zero.
  arrw <- arrw |>
    dplyr::mutate(V212 = dplyr::if_else(V201 == "1", V212, NA_real_),
                  V213 = dplyr::if_else(V201 == "1", V213, NA_real_),
                  V602 = dplyr::if_else(V201 == "1", V602, NA_real_))

  # Nenhum dos dois pesos e tocado. Como o IBGE entrega, V603 soma 25.210.639
  # (= SIDRA t206, domicilios particulares permanentes, exato em 40 celulas:
  # Brasil, 26 UFs, 2 situacoes e 11 classes de comodos) e V604 soma
  # 119.011.052 (= SIDRA t200/t202, populacao, exato em 20 celulas). Os zeros
  # -- 233.399 em V603 e 42 em V604 -- nao sao lacunas: sao a marca de
  # fora-do-universo com que o IBGE produziu essas tabelas, e imputar qualquer
  # um deles faz o censobr deixar de reproduzir o publicado.
  # Ver references/microdata_1980_pesos_v603_v604.md.

  relocate_geo_cols_censobr(arrw, "code_muni_1980")
}


# Grava o parquet nacional da tabela.
save_microdata_1980 <- function(arrw, dataset_name, data_version){

  message("Saving microdata 1980: ", dataset_name)

  # escrita por streaming: write_censobr_parquet() materializaria a tabela
  # inteira em RAM. Grupos de 1e6 linhas evitam a fragmentacao em row groups
  # pequenos, que infla o arquivo com o mesmo zstd-22.
  out_dir <- "./data/microdata_sample/1980"
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

  temp_dir <- file.path(out_dir, paste0("tmp_", dataset_name))
  unlink(temp_dir, recursive = TRUE)

  arrw <- cast_censobr_types(arrw, paste0("1980_", dataset_name))
  arrow::write_dataset(arrw,
                       path               = temp_dir,
                       format             = "parquet",
                       compression        = "zstd",
                       compression_level  = 22,
                       min_rows_per_group = 1e6L,
                       max_rows_per_group = 1e6L,
                       basename_template  = "part-{i}.parquet")

  dest_file <- paste0(out_dir, "/1980_", dataset_name, "_", data_version, ".parquet")
  file.rename(file.path(temp_dir, "part-0.parquet"), dest_file)
  unlink(temp_dir, recursive = TRUE)

  dest_file
}
