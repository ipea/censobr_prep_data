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

  # municipios que mudaram de UF entre 1980 e 2010: Fernando de Noronha (PE) e
  # os 52 que foram de Goias para o Tocantins. A coluna Observation do
  # crosswalk e nota de trabalho e nao entra no produto.
  cross <- readxl::read_xlsx(raw_paths[grepl("crosswalk", basename(raw_paths))])
  cross <- data.frame(code_muni_1980    = as.numeric(cross$municCod1980),
                      municCod2010_6dig = as.numeric(cross$municCod2010_6dig))

  arrw <- arrw |>
    dplyr::left_join(cross, by = "code_muni_1980") |>
    dplyr::mutate(municCod2010_6dig = dplyr::coalesce(municCod2010_6dig, code_muni_1980))

  # code_muni de 7 digitos pela malha de 1980, casando pelos 6 primeiros
  muni <- geobr::read_municipality(year = 1980, showProgress = FALSE)
  muni <- sf::st_drop_geometry(muni)
  muni <- data.frame(municCod2010_6dig = as.numeric(substr(as.character(muni$code_muni), 1, 6)),
                     code_muni         = as.numeric(muni$code_muni))

  arrw <- arrw |>
    dplyr::left_join(muni, by = "municCod2010_6dig") |>
    dplyr::mutate(municCod2010_6dig = NULL)

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

  # V604 (PESOP) vem zerada em 42 das 29,4M pessoas. O peso do domicilio em que
  # a pessoa mora e o substituto natural -- ele esta na propria linha, porque as
  # variaveis de domicilio vem repetidas em cada morador.
  # Nao se mexe na V603 (PESOD): ela e zero em 233.399 domicilios por desenho do
  # IBGE, que so calculou fator de expansao para particular permanente. Ver
  # references/microdata_1980_ftp_vs_aux.md.
  if(dataset_name == "population"){
    arrw <- arrw |>
      dplyr::mutate(V604 = dplyr::if_else(V604 == 0 & V603 > 0, V603, V604))

    # sobram 24 pessoas em domicilio coletivo, onde nem o peso da pessoa nem o
    # do domicilio existem; herdam a mediana do municipio
    med <- arrw |>
      dplyr::filter(V604 > 0) |>
      dplyr::group_by(code_muni) |>
      dplyr::summarise(V604_muni = stats::median(V604)) |>
      dplyr::collect()

    arrw <- arrw |>
      dplyr::left_join(med, by = "code_muni") |>
      dplyr::mutate(V604 = dplyr::if_else(V604 == 0, V604_muni, V604),
                    V604_muni = NULL)
  }

  arrw <- arrw |>
    dplyr::relocate(code_muni, code_muni_1980, code_state, abbrev_state, name_state,
                    code_region, name_region, code_meso, code_micro)

  arrw
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
