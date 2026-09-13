# 2000 census tracts (agregados por setor).
# Portado do script legado census_tracts_aggreg_2000.R (git, ate 18d2ac7) para arquitetura
# targets: 3 funcoes publicas (download_tract_2000, clean_tracts_2000,
# save_tracts_2000) + 3 helpers top-level (recode_datasets_2000,
# recode_basico_2000, make_theme_dataset_2000).
# Convencao v0.6.0: code_* todas numeric (aplicado em save).
#
# IBGE 2000: 28 zips (26 UFs + SP_RM + SP_Exclusive_RM). Cada zip extrai numa
# subpasta com nome longo do estado (ex.: "Roraima/"). Filenames mistos:
# Basico_<UF>.XLS, Domicilio_<UF>.XLS, Morador_<UF>.XLS,
# Pessoa<1-7>_<UF>.XLS, Responsavel<1-5>_<UF>.XLS, Instrucao<1-6>_<UF>.XLS.


# recodifica X/,/. para NA, converte cols numericas, normaliza CD_setor.
recode_datasets_2000 <- function(df){

  variants <- c("CD_setor", "COD_SETOR", "CD_SETOR", "SETOR")
  present  <- intersect(names(df), variants)

  if(present != "CD_setor"){
    df <- df |> rename("CD_setor" = !!sym(present))
  }

  df_recoded <- df |>
    mutate(CD_setor = as.numeric(CD_setor)) |>

    ### replace "X" "," "." with NA
    mutate_if(is.character, .funs = \(var){

      var <- iconv(var, to = "utf-8")
      var <- str_squish(var)
      ifelse((nchar(var) %in% 1) & (var %in% c("X",",",".")), NA_character_, var)

    }) |>

    ### replace "," with "."
    mutate_if(is.character, .funs = \(var) str_replace(string = var, pattern = ",", ".")) |>

    # convert to numeric those variables which do not present any letter
    mutate_if(.predicate = \(x) !any(grepl(x = str_to_lower(x), pattern = "[a-z]")),
              .funs      = \(x) suppressWarnings(as.numeric(x))) |>

    # replace "" with NA
    mutate_if(is.character, \(x) ifelse(x %in% "", NA_character_, x))

  test_missings <- sapply(names(df), \(var){
    all(
      (df[[var]] %in% c("X", ",", ".", "")) == is.na(df_recoded[[var]]) |
      (is.na(df[[var]]) == is.na(df_recoded[[var]]))
    )
  })

  if(!all(test_missings)){
    stop("Missing values criados onde nao deveriam")
  }

  df_recoded |> select(CD_setor, everything())
}


# le todos os Basico_<UF>.XLS, empilha, recodifica, aplica rename canonico.
# IBGE entrega cols Var01-Var14 ja como cols separadas; str_to_upper -> VAR01-VAR14
# que casa com o baseline v0.5.0.
recode_basico_2000 <- function(raw_xls_paths, dataset_info_2000){

  basico_files <- dataset_info_2000$file[dataset_info_2000$theme == "Basico"]
  if(length(basico_files) == 0) stop("Nenhum arquivo Basico encontrado")

  basico_list <- lapply(basico_files, \(f) readxl::read_excel(path = f))
  basico_list <- lapply(basico_list, \(x) setNames(x, str_to_upper(names(x))))

  datasets_basico <- data.table::rbindlist(basico_list, use.names = TRUE, fill = TRUE)
  rm(basico_list); gc(verbose = FALSE)

  datasets_basico <- recode_datasets_2000(datasets_basico)

  datasets_basico |>
    rename(code_tract        = CD_setor,
           code_state        = COD_UF,
           name_state        = NOME_DA_UF,
           code_meso         = COD_MESO,
           name_meso         = NOME_DA_MESO,
           code_micro        = COD_MICRO,
           name_micro        = NOME_DA_MICRO,
           code_metro        = COD_RM,
           name_metro        = NOME_DA_RM,
           code_muni         = COD_MUNICIPIO,
           name_muni         = NOME_DO_MUNICIPIO,
           code_district     = COD_DISTRITO,
           name_district     = NOME_DO_DISTRITO,
           code_subdistrict  = COD_SUBDISTRITO,
           name_subdistrict  = NOME_DO_SUBDISTRITO,
           code_neighborhood = COD_BAIRRO,
           name_neighborhood = NOME_DO_BAIRRO,
           situacao          = SITUACAO,
           code_type         = TIPO_DO_SETOR)
}


# constroi tema multi-arquivo: para cada prefix do tema, le e empilha os XLS
# das 28 UFs, recodifica; depois prefixa V cols, joina sub-tabelas, anexa geo.
make_theme_dataset_2000 <- function(theme_i, raw_xls_paths, dataset_basico, dataset_info_2000){

  dataset_basico_sub <- dataset_basico |>
    select(-starts_with("V"))

  dataset_info_i <- dataset_info_2000 |>
    filter(theme %in% theme_i)

  prefixes <- unique(dataset_info_i$prefix)

  # 1 stack por prefix: empilha os 28 XLS daquele prefix, recodifica
  datasets_i <- lapply(prefixes, \(prefix_j){

    message("  prefix: ", prefix_j)

    prefix_j_files <- dataset_info_i$file[dataset_info_i$prefix == prefix_j]

    prefix_j_list  <- lapply(prefix_j_files, \(f) readxl::read_excel(path = f))
    prefix_j_list  <- lapply(prefix_j_list, \(x) setNames(x, str_to_upper(names(x))))
    prefix_j_stack <- data.table::rbindlist(prefix_j_list, use.names = TRUE, fill = TRUE)
    rm(prefix_j_list); gc(verbose = FALSE)

    recode_datasets_2000(prefix_j_stack)
  })

  gc(verbose = FALSE)

  # adiciona prefixo de tema as V cols (somente quando ha mais de 1 sub-tabela)
  if(length(prefixes) > 1){
    for(j in seq_along(prefixes)){
      prefix_j <- prefixes[j]

      datasets_i[[j]]$SITUACAO      <- NULL
      datasets_i[[j]]$TIPO_DO_SETOR <- NULL

      names_to_change <- setdiff(names(datasets_i[[j]]), "CD_setor")
      if(any(grepl(x = names_to_change, pattern = prefix_j))) next

      data.table::setnames(datasets_i[[j]], old = "CD_setor", new = "code_tract")
      datasets_i[[j]] <- datasets_i[[j]] |> select(code_tract, everything())

      newnames <- paste(prefix_j, names_to_change, sep = "_")
      data.table::setnames(datasets_i[[j]], old = names_to_change, new = newnames)
    }
  } else {
    datasets_i[[1]]$SITUACAO      <- NULL
    datasets_i[[1]]$TIPO_DO_SETOR <- NULL
    data.table::setnames(datasets_i[[1]], old = "CD_setor", new = "code_tract")
    datasets_i[[1]] <- datasets_i[[1]] |> select(code_tract, everything())
  }

  # full_join entre sub-tabelas do mesmo tema
  if(length(datasets_i) > 1){

    nrows <- unlist(lapply(datasets_i, nrow))
    if(var(nrows) > 0){
      warning("Sub-tabelas do tema '", theme_i, "' tem nrow diferente: ",
              paste(nrows, collapse = ", "))
    }

    whichMax    <- which.max(nrows)
    data_join_i <- datasets_i[[whichMax]]

    for(dataset_j in datasets_i[-whichMax]){
      data_join_i <- full_join(data_join_i, dataset_j, by = "code_tract")
    }

  } else {
    data_join_i <- datasets_i[[1]]
  }

  rm(datasets_i); gc(verbose = FALSE)

  # left_join geo do basico (basico_sub: 19 geo cols, sem V)
  data_with_geo <- left_join(dataset_basico_sub,
                             data_join_i,
                             by = "code_tract") |>
    filter(code_tract %in% data_join_i$code_tract)

  rm(data_join_i); gc(verbose = FALSE)

  data_with_geo
}


# baixa 28 zips do FTP IBGE, descompacta, retorna paths dos XLS.
download_tract_2000 <- function(){

  dest_dir <- "./data_raw/tracts/2000"
  dir.create(dest_dir, recursive = TRUE, showWarnings = FALSE)

  message("\nDownloading 2000 census tracts ...\n")

  ftp <- 'https://ftp.ibge.gov.br/Censos/Censo_Demografico_2000/Dados_do_Universo/Agregado_por_Setores_Censitarios/'

  listed <- list_folders(ftp)
  listed <- listed[grepl("\\.zip$", listed)]
  if(length(listed) == 0) stop("Nenhum zip listado em ", ftp)

  download_file_censobr(file_url = paste0(ftp, listed), dest_dir = dest_dir)

  unzip_censobr(zip_dir = dest_dir, out_zip = dest_dir)

  xls_paths <- list.files(dest_dir,
                          pattern    = "\\.xls$",
                          full.names = TRUE,
                          recursive  = TRUE,
                          ignore.case = TRUE)
  xls_paths <- xls_paths[!grepl("compatibiliza|descri|instalad", xls_paths, ignore.case = TRUE)]
  xls_paths <- unique(xls_paths)
  if(length(xls_paths) == 0) stop("Nenhum XLS extraido em ", dest_dir)

  xls_paths
}


# raw_xls_paths : output de download_tract_2000.
# tbl_name      : "Basico" | "Domicilio" | "Morador" | "Responsavel" | "Pessoa" | "Instrucao".
clean_tracts_2000 <- function(raw_xls_paths, tbl_name){

  message("Cleaning tracts 2000: ", tbl_name)

  # Constroi dataset_info: prefix (Basico, Pessoa1..7, etc), uf, theme.
  # Filenames sao "<prefix>_<UF>.XLS" dentro de subdirs por estado.
  parsed <- sub("\\.xls$", "", basename(raw_xls_paths), ignore.case = TRUE)
  parts  <- str_split(parsed, "_", simplify = TRUE)

  dataset_info_2000 <- tibble(prefix = parts[, 1],
                              uf     = parts[, 2],
                              file   = raw_xls_paths) |>
    mutate(theme  = str_remove_all(prefix, "[[:digit:]]"),
           prefix = tolower(prefix))

  # Basico vai sempre, e ele que carrega as 19 geo cols.
  dataset_basico <- recode_basico_2000(raw_xls_paths, dataset_info_2000)

  if(tbl_name == "Basico"){
    out <- dataset_basico
  } else {
    if(!tbl_name %in% dataset_info_2000$theme){
      stop("clean_tracts_2000: tema desconhecido '", tbl_name, "'")
    }
    out <- make_theme_dataset_2000(theme_i           = tbl_name,
                                   raw_xls_paths     = raw_xls_paths,
                                   dataset_basico    = dataset_basico,
                                   dataset_info_2000 = dataset_info_2000)
  }

  out$table_name <- tbl_name
  out
}


save_tracts_2000 <- function(cleaned_dt, data_version){

  tbl <- cleaned_dt$table_name[1]
  message("Saving tracts 2000: ", tbl)

  dir.create("./data/tracts/2000/", recursive = TRUE, showWarnings = FALSE)

  out <- cleaned_dt
  out$table_name <- NULL

  # convencao v0.6.0: code_* numeric.
  out <- code_cols_to_numeric(out)

  
  
  # save data
  message("saving")
  dir.create("./data/tracts/2000/", recursive = TRUE, showWarnings = FALSE)
  dest_file <- paste0("./data/tracts/2000/2000_tracts_", tolower(tbl), "_", data_version,".parquet")
  write_censobr_parquet(out, dest_file)
  
  dest_file
}
