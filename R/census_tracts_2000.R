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


# recodifica X/,/. para NA, converte cols numericas, normaliza a chave do setor.
# O IBGE chama o setor de Cod_setor; as variantes so diferem de caixa ou de
# prefixo e casam sem mexer nas outras colunas, que ficam com o nome original.
recode_datasets_2000 <- function(df){

  variants <- c("cod_setor", "cd_setor", "setor")
  present  <- names(df)[tolower(names(df)) %in% variants]

  if(present != "Cod_setor"){
    df <- df |> rename("Cod_setor" = !!sym(present))
  }

  df_recoded <- df |>
    mutate(Cod_setor = as.numeric(Cod_setor)) |>

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

  df_recoded |> select(Cod_setor, everything())
}


# os nomes de coluna ficam como o IBGE os escreve. Entre UFs a unica diferenca
# e de caixa; casa-se com a grafia do primeiro arquivo da pilha.
match_names_2000 <- function(lst){
  ref <- names(lst[[1]])
  lapply(lst, \(x){
    i <- match(tolower(names(x)), tolower(ref))
    setNames(x, ifelse(is.na(i), names(x), ref[i]))
  })
}


# le todos os Basico_<UF>.XLS, empilha, recodifica e acrescenta as colunas
# censobr de geografia. As do IBGE (Cod_UF, Nome_da_UF, ..., Var01-Var14)
# ficam com o nome original.
recode_basico_2000 <- function(raw_xls_paths, dataset_info_2000){

  basico_files <- dataset_info_2000$file[dataset_info_2000$theme == "Basico"]
  if(length(basico_files) == 0) stop("Nenhum arquivo Basico encontrado")

  basico_list <- lapply(basico_files, \(f) readxl::read_excel(path = f))
  basico_list <- match_names_2000(basico_list)

  datasets_basico <- data.table::rbindlist(basico_list, use.names = TRUE, fill = TRUE)
  rm(basico_list); gc(verbose = FALSE)

  datasets_basico <- recode_datasets_2000(datasets_basico)

  datasets_basico <- datasets_basico |>
    mutate(code_tract        = Cod_setor,
           code_state        = Cod_UF,
           code_meso         = Cod_meso,
           name_meso         = Nome_da_meso,
           code_micro        = Cod_micro,
           name_micro        = Nome_da_micro,
           code_metro        = Cod_RM,
           name_metro        = Nome_da_RM,
           code_muni         = Cod_municipio,
           name_muni         = Nome_do_municipio,
           code_district     = Cod_distrito,
           name_district     = Nome_do_distrito,
           code_subdistrict  = Cod_subdistrito,
           name_subdistrict  = Nome_do_subdistrito,
           code_neighborhood = Cod_bairro,
           name_neighborhood = Nome_do_bairro,
           code_situacao     = Situacao,
           code_type         = Tipo_do_setor)

  # name_state canonico, abbrev_state e regiao
  datasets_basico <- add_state_info(datasets_basico, column = "code_muni")
  datasets_basico <- add_region_info(datasets_basico, column = "code_state")
  datasets_basico
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
    prefix_j_list  <- match_names_2000(prefix_j_list)
    prefix_j_stack <- data.table::rbindlist(prefix_j_list, use.names = TRUE, fill = TRUE)
    rm(prefix_j_list); gc(verbose = FALSE)

    recode_datasets_2000(prefix_j_stack)
  })

  gc(verbose = FALSE)

  # adiciona prefixo de tema as V cols (somente quando ha mais de 1 sub-tabela).
  # Situacao e Tipo_do_setor repetem os do Basico, que ja entram pelo join.
  if(length(prefixes) > 1){
    for(j in seq_along(prefixes)){
      prefix_j <- prefixes[j]

      datasets_i[[j]]$Situacao      <- NULL
      datasets_i[[j]]$Tipo_do_setor <- NULL

      names_to_change <- setdiff(names(datasets_i[[j]]), "Cod_setor")
      if(any(grepl(x = names_to_change, pattern = prefix_j))) next

      data.table::setnames(datasets_i[[j]], old = "Cod_setor", new = "code_tract")
      datasets_i[[j]] <- datasets_i[[j]] |> select(code_tract, everything())

      newnames <- paste(prefix_j, names_to_change, sep = "_")
      data.table::setnames(datasets_i[[j]], old = names_to_change, new = newnames)
    }
  } else {
    datasets_i[[1]]$Situacao      <- NULL
    datasets_i[[1]]$Tipo_do_setor <- NULL
    data.table::setnames(datasets_i[[1]], old = "Cod_setor", new = "code_tract")
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

  ftp    <- FTP_CENSOBR$tracts_2000
  remote <- ftp_fingerprint_censobr("tracts_2000")

  listed <- remote$arquivo[grepl("\\.zip$", remote$arquivo)]
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

  # colunas censobr de geografia no inicio; convencao v0.6.0: code_* numeric.
  out <- relocate_geo_cols_censobr(out)
  out <- code_cols_to_numeric(out)
  out <- cast_censobr_types(out, paste0("2000_tracts_", tolower(tbl)))

  # save data
  message("saving")
  dir.create("./data/tracts/2000/", recursive = TRUE, showWarnings = FALSE)
  dest_file <- paste0("./data/tracts/2000/2000_tracts_", tolower(tbl), "_", data_version,".parquet")
  write_censobr_parquet(out, dest_file)
  
  dest_file
}
