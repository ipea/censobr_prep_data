# 1970 microdata sample.
#
# O FTP do IBGE traz um zip unico com 27 arquivos de largura fixa
# (Dados/Damo70<UF>.txt, 76 chars por registro, nomes em caixa mista). Nao ha
# read guide de 1970 no repo: as posicoes saem do layout_1970.xlsx, que cobre
# as 54 variaveis V001-V054 sem buraco nem sobreposicao.
#
# Duas coisas exigem cuidado:
#
#  - O registro NAO tem campo de UF. Ela vem do nome do arquivo, e o codigo de
#    UF de 1970 sai do proprio crosswalk de municipios.
#  - Nao existe registro de domicilio: ele e DERIVADO das pessoas, por um
#    na.locf sobre a ordem original das linhas. Qualquer reordenacao, dentro de
#    um arquivo ou entre arquivos, muda todos os ids. Os arquivos entram em
#    ordem alfabetica do nome em maiusculas (AC..SP), que e a ordem que
#    reproduz a amostra ja publicada -- conferido na primeira e na ultima
#    linha (Acre e Sao Paulo, 24.793.358 registros).
#
# Public API: download_microdata_1970, clean_microdata_1970, save_microdata_1970.


# Baixa o zip do FTP e descompacta.
download_microdata_1970 <- function(){

  dest_dir <- "./data_raw/microdata/1970"
  dir.create(dest_dir, recursive = TRUE, showWarnings = FALSE)

  message("\nDownloading 1970 microdata...\n")

  url <- "https://ftp.ibge.gov.br/Censos/Censo_Demografico_1970/Microdados/Microdados_Censo_Demografico_1970_Amostra.zip"
  download_file_censobr(file_url = url, dest_dir = dest_dir, max_active = 1)
  unzip_censobr(zip_dir = dest_dir, out_zip = dest_dir)

  # o crosswalk de municipio 1970->2010 nao existe no FTP; vem do release_legacy
  cw <- get_release_legacy("crosswalk_munic_1970_to_2010.rda", dest_dir)

  txt_paths <- list.files(file.path(dest_dir, "Dados"), pattern = "\\.txt$",
                          full.names = TRUE, ignore.case = TRUE)
  if(length(txt_paths) != 27) stop("1970: esperava 27 arquivos em Dados/, achei ", length(txt_paths))

  # a ordem e semantica -- ver cabecalho
  c(txt_paths[order(toupper(basename(txt_paths)))], cw)
}


# Parseia os 27 arquivos na ordem, deriva o identificador de domicilio e
# devolve a tabela pedida. Um unico parse alimenta as duas: o staging por UF
# fica em data_raw/, e a derivacao le dele so as colunas de que precisa.
clean_microdata_1970 <- function(raw_paths, dataset_name){

  message("Cleaning microdata 1970: ", dataset_name)

  files <- raw_paths[grepl("\\.txt$", raw_paths, ignore.case = TRUE)]
  files <- files[order(toupper(basename(files)))]

  # posicoes das 54 variaveis, no read guide do repo (gerado do layout do IBGE)
  dic <- data.table::fread("./read_guides/readguide_1970_population.csv")

  # crosswalk de municipio: traz a sigla da UF de 1970, que liga ao nome do
  # arquivo, e o codigo de 2010
  e <- new.env()
  load(raw_paths[grepl("crosswalk_munic", raw_paths)], envir = e)
  cw <- data.table::as.data.table(get(ls(e)[1], envir = e))
  data.table::setnames(cw, c("code_muni", "code_muni_1970", "uf_sigla", "name_muni_1970"))
  cw[, code_muni_1970 := as.numeric(code_muni_1970)]
  cw[, code_muni := as.numeric(code_muni)]
  uf_cod <- unique(cw[, .(uf_sigla, uf_1970 = code_muni_1970 %/% 100000)])


  stage_dir <- "./data_raw/microdata/1970/parquet"
  if(!dir.exists(stage_dir)){
    dir.create(stage_dir, recursive = TRUE, showWarnings = FALSE)
    for(f in files){
      message("  ", basename(f))
      sigla <- toupper(substr(basename(f), 7, 8))
      uf <- uf_cod$uf_1970[match(sigla, uf_cod$uf_sigla)]

      df <- readr::read_fwf(f, readr::fwf_positions(dic$int_pos, dic$fin_pos, dic$var_name),
                            col_types = paste(rep("i", nrow(dic)), collapse = ""))
      data.table::setDT(df)

      # o municipio de 1970 e UF + microrregiao + municipio. Guanabara e
      # Distrito Federal vem agregados no crosswalk (2531000 e 3600000), entao
      # tentamos a chave completa e caimos para as formas zeradas.
      df[, k1 := uf * 100000 + (V001 %% 100) * 1000 + V002]
      df[, k2 := uf * 100000 + (V001 %% 100) * 1000]
      df[, k3 := uf * 100000]
      df[, code_muni_1970 := data.table::fifelse(k1 %in% cw$code_muni_1970, k1,
                             data.table::fifelse(k2 %in% cw$code_muni_1970, k2, k3))]
      df[, c("k1", "k2", "k3") := NULL]
      df[cw, on = "code_muni_1970", code_muni := i.code_muni]

      # o byte de fim de arquivo do DOS no fim de cada .txt vira um registro
      # todo vazio -- um por UF, 27 no pais
      vazias <- df[, rowSums(is.na(.SD)) == length(dic$var_name), .SDcols = dic$var_name]
      if(any(vazias)){
        message("    descartando ", sum(vazias), " registro(s) vazio(s) (byte de EOF)")
        df <- df[!vazias]
      }

      # a UF vem do arquivo, entao vale mesmo quando V001/V002 estao
      # corrompidos e o municipio nao resolve (156 registros no pais)
      df[, uf_1970 := uf]

      arrow::write_parquet(df, file.path(stage_dir, paste0(sigla, ".parquet")))
      rm(df); gc(verbose = FALSE)
    }
  }

  # o staging e lido na mesma ordem em que foi escrito
  stage <- file.path(stage_dir, paste0(toupper(substr(basename(files), 7, 8)), ".parquet"))

  # ---- derivacao do domicilio, sobre a ordem original ----
  # so as colunas que a derivacao e a agregacao usam
  cols <- c(paste0("V", sprintf("%03d", c(1:21, 24:27, 41, 54))),
            "code_muni_1970", "code_muni", "uf_1970")
  p <- data.table::rbindlist(lapply(stage, \(s) arrow::read_parquet(s, col_select = dplyr::all_of(cols))))
  gc(verbose = FALSE)

  p[, ind_collective := data.table::fifelse(is.na(V007), 0L, V007)]
  p[, flag := NA_real_]
  # em domicilio particular, quem chefia familia (nao secundaria) abre domicilio
  p[ind_collective == 0 & V025 == 1 & V006 %in% c(1, 2), flag := 1]
  # a primeira pessoa de um coletivo abre domicilio; o coletivo so termina
  # quando comeca um particular
  p[c(0L, diff(ind_collective)) == 1, flag := 1]
  # quem mora sozinho abre domicilio
  p[V006 == 0, flag := 1]
  # chefe de familia secundaria nao abre domicilio
  p[V025 == 1 & V006 %in% c(3, 4), flag := NA]

  p[flag == 1, idhh := seq_len(.N)]
  p[, idhh := (idhh * 100 + V003) * 10 + V004]
  p[, household_id := data.table::nafill(idhh, type = "locf")]

  # coletivos, improvisados e pessoas isoladas nao viram domicilio
  p[, m7 := mean(V007, na.rm = TRUE), by = household_id]
  p[m7 %in% 1 | is.nan(m7), household_id := NA_real_]
  p[, m8 := mean(V008, na.rm = TRUE), by = household_id]
  p[m8 %in% 2 | is.nan(m8), household_id := NA_real_]
  p[V006 %in% 0, household_id := NA_real_]

  if(dataset_name == "population"){
    hh <- p$household_id
    rm(p); gc(verbose = FALSE)
    return(list(stage = stage, household_id = hh))
  }

  # ---- agregacao para o registro de domicilio ----
  # renda domiciliar: so parentes entram, e menores de 10 anos nao somam.
  # As atribuicoes sao em passos, e nao com fifelse, de proposito: quando a
  # condicao e NA o valor inicial fica de pe, que e o que o script original
  # fazia. Com fifelse o NA se propaga e a renda e o peso do domicilio inteiro
  # viram NA.
  p[, nonrelative := as.numeric(V025 == 0 | V025 >= 7)]
  p[, numberRelatives := sum(1 - nonrelative), by = household_id]

  p[, age := NA_real_]
  p[V026 %in% c(1, 2), age := 0]
  p[V026 %in% c(3, 4), age := as.numeric(V027)]

  p[, totalIncome := 0]
  p[V041 <= 9998, totalIncome := as.numeric(V041)]
  p[nonrelative == 1, totalIncome := 0]
  p[age <= 9, totalIncome := 0]

  p[, hhIncome := sum(totalIncome), by = household_id]
  p[is.na(household_id), hhIncome := NA_real_]
  p[, hhIncomePerCap := hhIncome / numberRelatives]
  p[nonrelative == 1, c("hhIncome", "hhIncomePerCap") := NA_real_]

  # o peso do domicilio e o do chefe
  p[, wgthh := 0]
  p[V025 == 1, wgthh := as.numeric(V054)]
  p[, wgthh := max(wgthh), by = household_id]
  p[is.na(household_id), wgthh := NA_real_]

  # V005 e V022+ sao de pessoa; o registro de domicilio fica com V001-V021
  medias <- paste0("V", sprintf("%03d", c(1:4, 6:20)))
  out <- p[!is.na(household_id),
           c(lapply(.SD, mean, na.rm = TRUE),
             list(V021                   = data.table::first(V021),
                  weight_household       = mean(wgthh, na.rm = TRUE),
                  numb_dwellers          = .N,
                  numb_dwellers_hhincome = mean(numberRelatives, na.rm = TRUE),
                  hh_income              = mean(hhIncome, na.rm = TRUE),
                  hh_income_per_cap      = mean(hhIncomePerCap, na.rm = TRUE),
                  code_muni_1970         = data.table::first(code_muni_1970),
                  code_muni              = data.table::first(code_muni),
                  uf_1970                = data.table::first(uf_1970))),
           by = household_id, .SDcols = medias]
  data.table::setnames(out, "household_id", "id_household")

  # onde o chefe nao tem peso no arquivo, a media do grupo sai NaN; NA e o
  # valor honesto. Sao 131 domicilios em 4,7 milhoes -- registros incompletos
  # do proprio FWF do IBGE (V054 falta em 1.114 das 24,8M pessoas).
  for(v in c("weight_household", "hh_income", "hh_income_per_cap"))
    data.table::set(out, which(is.nan(out[[v]])), v, NA_real_)

  rm(p); gc(verbose = FALSE)
  add_geo_1970(out)
}


# Geografia de 1970: a UF moderna sai do code_muni, e a de 1970 do prefixo do
# code_muni_1970. Inline, e nao via add_geography_cols(), pelo mesmo motivo das
# outras edicoes portadas: la os code_* terminam em as.integer, e a convencao
# v0.6.0 pede numeric.
#
# As UFs como eram em 1970: Mato Grosso antes da divisao, Goias antes do
# Tocantins. Guanabara e Fernando de Noronha aparecem sob RJ e PE, que e como
# o produto publicado os trata.
add_geo_1970 <- function(dt){

  uf_1970_nomes <- data.table::data.table(
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

  # a UF de 1970 vem do arquivo (coluna uf_1970); a moderna, do municipio.
  # Quando o municipio nao resolve, a UF moderna vem do mapa de 1970 -- que so
  # e ambiguo para MT (que virou MS e MT) e GO (que virou TO e GO).
  uf_moderna <- data.table::data.table(
    uf_1970    = c(1, 2, 3, 4, 5, 6, 8, 9, 10, 11, 13, 14, 15, 16, 17,
                   19, 21, 23, 24, 25, 27, 29, 31, 32, 36),
    code_state = c(11, 12, 13, 14, 15, 16, 21, 22, 23, 24, 25, 26, 27, 26, 28,
                   29, 31, 32, 33, 33, 35, 41, 42, 43, 53))

  dt[, code_state := as.numeric(code_muni %/% 100000)]
  dt[uf_moderna, on = "uf_1970", code_state := data.table::fifelse(
       is.na(code_state), as.numeric(i.code_state), code_state)]

  states <- data.table::as.data.table(
    states_censobr()[, c("code_state", "abbrev_state", "name_state",
                         "code_region", "name_region")])
  dt[states, on = "code_state",
     `:=`(abbrev_state = i.abbrev_state, name_state = i.name_state,
          code_region = i.code_region, name_region = i.name_region)]
  dt[uf_1970_nomes, on = "uf_1970",
     `:=`(abbrev_state_1970 = i.abbrev_state_1970,
          name_state_1970 = i.name_state_1970)]
  dt[, uf_1970 := NULL]

  data.table::setcolorder(dt, c("code_muni", "code_muni_1970", "code_state",
                                "abbrev_state", "abbrev_state_1970", "name_state",
                                "name_state_1970", "code_region", "name_region"))
  dt
}


# Grava o parquet nacional da tabela.
save_microdata_1970 <- function(cleaned, dataset_name, data_version){

  message("Saving microdata 1970: ", dataset_name)

  out_dir <- "./data/microdata_sample/1970"
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  dest_file <- paste0(out_dir, "/1970_", dataset_name, "_", data_version, ".parquet")

  if(dataset_name == "population"){
    # id_household vem alinhado por posicao com o staging, e id_person e a
    # propria ordem da linha no arquivo nacional -- nao ha join a fazer
    temp_dir <- file.path(out_dir, "tmp_population")
    unlink(temp_dir, recursive = TRUE)
    dir.create(temp_dir, recursive = TRUE, showWarnings = FALSE)

    vs <- paste0("V", sprintf("%03d", 1:54))
    de <- 1L
    for(s in cleaned$stage){
      df <- arrow::read_parquet(s)
      data.table::setDT(df)
      n <- nrow(df)
      df[, id_household := cleaned$household_id[de:(de + n - 1L)]]
      df[, id_person    := as.integer(de:(de + n - 1L))]
      de <- de + n
      df <- add_geo_1970(df)
      data.table::setcolorder(df, c("code_muni", "code_muni_1970", "code_state",
                                    "abbrev_state", "abbrev_state_1970", "name_state",
                                    "name_state_1970", "code_region", "name_region",
                                    vs, "id_person", "id_household"))
      arrow::write_parquet(df, file.path(temp_dir, basename(s)))
      rm(df); gc(verbose = FALSE)
    }

    arrow::write_dataset(arrow::open_dataset(temp_dir),
                         path = file.path(out_dir, "tmp_write"), format = "parquet",
                         compression = "zstd", compression_level = 22,
                         min_rows_per_group = 1e6L, max_rows_per_group = 1e6L,
                         basename_template = "part-{i}.parquet")
    file.rename(file.path(out_dir, "tmp_write", "part-0.parquet"), dest_file)
    unlink(c(temp_dir, file.path(out_dir, "tmp_write")), recursive = TRUE)

  } else {
    write_censobr_parquet(cleaned, dest_file)
  }

  dest_file
}
