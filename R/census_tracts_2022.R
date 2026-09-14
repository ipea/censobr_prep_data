# 2022 census tracts (agregados por setor).
# Portado do script legado census_tracts_aggreg_2022.R (git, ate 18d2ac7) para arquitetura
# targets: 3 funcoes publicas (download_tract_2022, clean_tracts_2022,
# save_tracts_2022) + 3 helpers top-level (recode_datasets_2022,
# recode_basico_2022, make_theme_dataset_2022).
# Convencao v0.6.0: code_* todas numeric (aplicado em save).


# a function for recoding the list of datasets
recode_datasets_2022 <- function(df){

  variants <- c("CD_SETOR", "SETOR", "COD_SETOR_M22FINAL")

  present <- intersect(names(df), variants)

  if(present != "CD_setor"){
    df <- df |> rename("CD_setor" = !!sym(present))
  }

  df_recoded <- df |>
    mutate(CD_setor = as.numeric(CD_setor)) |>

    ### replace "X" "," "." with NA
    mutate_if(is.character, .funs = \(var){

      var <- iconv(var, from = "latin1", to = "utf-8")
      var <- str_squish(var)
      var <- ifelse((nchar(var) %in% 1) & (var %in% c("X",",",".")), NA_character_, var)
      var

    }) |>

    ### replace "," with "."
    mutate_if(is.character, .funs = \(var) str_replace(string = var, pattern = ",", ".")) |>

    # convert to numeric those variables which do not present any letter
    mutate_if(.predicate = \(x) !any(grepl(x = str_to_lower(x), pattern = "[a-z]")),
              .funs      = \(x) suppressWarnings(as.numeric(x))) |>

    # replace "" with NA
    mutate_if(is.character, \(x) ifelse(x %in% "", NA_character_, x))

  test_missings <- sapply(names(df), \(var){
    all((df[[var]] %in% c("X", ",", ".", "")) == is.na(df_recoded[[var]]))
  })

  if(!all(test_missings)){
    stop("Missing values foram criados onde provavelmente nao deveriam ser")
  }

  df_recoded |> select(CD_setor, everything())
}


# le o Basico, recodifica, e acrescenta as colunas censobr de geografia. As
# colunas do IBGE ficam com o nome original.
recode_basico_2022 <- function(raw_csv_paths, dataset_info_2022){

  pattern     <- dataset_info_2022$pattern[dataset_info_2022$theme == "Basico"]
  basico_path <- raw_csv_paths[grepl(pattern, basename(raw_csv_paths))]
  if(length(basico_path) != 1) stop("Basico CSV match falhou (esperado 1, achou ", length(basico_path), ")")

  datasets_basico <- data.table::fread(file = basico_path, sep = ";", dec = ",")
  names(datasets_basico) <- str_to_upper(names(datasets_basico))

  datasets_basico <- recode_datasets_2022(datasets_basico)

  datasets_basico |>
    mutate(code_tract               = CD_setor   ,
           situacao                 = SITUACAO   ,
           code_situacao            = CD_SIT     ,
           code_type                = CD_TIPO    ,
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
           code_neighborhood        = CD_BAIRRO  ,
           name_neighborhood        = NM_BAIRRO  ,
           code_favela              = CD_FCU     ,
           name_favela              = NM_FCU     ,
           code_intermediate        = CD_RGINT   ,
           name_intermediate        = NM_RGINT   ,
           code_immediate           = CD_RGI     ,
           name_immediate           = NM_RGI     ,
           code_nucleo_urbano       = CD_NU      ,
           name_nucleo_urbano       = NM_NU      ,
           code_aglomerado          = CD_AGLOM   ,
           name_aglomerado          = NM_AGLOM   ,
           code_urban_concentration = CD_CONCURB ,
           name_urban_concentration = NM_CONCURB)
}


# constroi tema multi-arquivo: le, recodifica, prefixa V cols, joina, anexa geo.
make_theme_dataset_2022 <- function(theme_i, raw_csv_paths, dataset_basico, dataset_info_2022){

  dataset_basico_sub <- dataset_basico |>
    select(-starts_with("V"))

  dataset_info_i <- dataset_info_2022 |>
    filter(theme %in% theme_i)

  # resolve filenames por regex (IBGE re-publica com sufixo de data opcional).
  files_i <- sapply(dataset_info_i$pattern, \(pat){
    hits <- raw_csv_paths[grepl(pat, basename(raw_csv_paths))]
    if(length(hits) != 1) stop("CSV match falhou para tema='", theme_i, "' pattern='", pat, "'")
    hits
  })

  # creating list of datasets from the same theme
  datasets_i <- lapply(files_i,
                       \(file) data.table::fread(file = file, sep = ";", dec = ","))
  gc(reset = T, full = T, verbose = T)

  datasets_i <- lapply(datasets_i, \(x) setNames(x, str_to_upper(names(x))))

  # Recoding the dataset
  datasets_i <- lapply(datasets_i, recode_datasets_2022)

  # Adding prefixes to themes with more than one table
  if(nrow(dataset_info_i) > 1){
    for(i in 1:nrow(dataset_info_i)){

      prefix_i <- dataset_info_i$prefix[i]
      names_to_change <- setdiff(names(datasets_i[[i]]), "CD_setor")

      if(any(grepl(x = names_to_change, pattern = prefix_i))) next

      newnames <- c("code_tract", paste(prefix_i, names_to_change, sep = "_"))

      names(datasets_i[[i]]) <- newnames
    }
  }else{
    names(datasets_i[[1]])[1] <- "code_tract"
  }


  if(length(datasets_i) > 1){

    numberOfrows <- unlist(lapply(datasets_i, nrow))
    variance_of_numberOfrows <- var(numberOfrows)

    if(variance_of_numberOfrows > 0){
      warning("Datasets of the same theme do not have the same number of rows")
    }

    whichMaxRows <- which.max(numberOfrows)
    data_join_i  <- datasets_i[[whichMaxRows]]

    for(dataset_j in datasets_i[-whichMaxRows]){

      data_join_i <- full_join(data_join_i,
                               dataset_j,
                               by = "code_tract")
    }

  }else{

    data_join_i <- datasets_i[[1]]

  }

  # Adding geographic variables
  data_with_geoVariables <- left_join(dataset_basico_sub,
                                      data_join_i,
                                      by = "code_tract") |>
    filter(code_tract %in% data_join_i$code_tract)

  gc(T, T, T)

  data_with_geoVariables
}


# baixa zips de 3 endpoints IBGE, descompacta, retorna paths dos CSVs.
download_tract_2022 <- function(){

  dest_dir <- "./data_raw/tracts/2022"
  csv_dir  <- file.path(dest_dir, "csv")
  dir.create(dest_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(csv_dir,  recursive = TRUE, showWarnings = FALSE)

  message("\nDownloading 2022 census tracts ...\n")

  ftps <- c('https://ftp.ibge.gov.br/Censos/Censo_Demografico_2022/Agregados_por_Setores_Censitarios/Agregados_por_Setor_csv/',
            'https://ftp.ibge.gov.br/Censos/Censo_Demografico_2022/Agregados_por_Setores_Censitarios_Caracteristicas_urbanisticas_do_entorno_dos_domicilios/Agregados_por_Setor_csv/')

  hardcoded_url <- 'https://ftp.ibge.gov.br/Censos/Censo_Demografico_2022/Agregados_por_Setores_Censitarios_Rendimento_do_Responsavel/Agregados_por_setores_renda_responsavel_BR_20260508_csv.zip'
                   
  scraped_urls <- unlist(lapply(ftps, \(ftp){
    listed <- list_folders(ftp)
    listed <- listed[grepl("\\.zip$", listed)]
    if(length(listed) == 0) return(character(0))
    paste0(ftp, listed)
  }))

  all_urls <- c(scraped_urls, hardcoded_url)

  download_file_censobr(file_url = all_urls, dest_dir = dest_dir)

  zip_files <- list.files(dest_dir, pattern = "\\.zip$", full.names = TRUE)
  if(length(zip_files) == 0) stop("No ZIP files in ", dest_dir, " after download")

  # O IBGE republica o mesmo agregado com sufixo de data novo, e o zip antigo
  # fica em disco ao lado do novo. Sem isto o tema casa com dois CSVs e o clean
  # para: foi o que aconteceu com o basico, republicado em 20260520 sobre o
  # 20250417. Fica so o mais recente de cada base. Note que o nome interno do
  # CSV nao acompanha o do zip -- o zip novo extrai sem sufixo e o antigo com --
  # entao a ordenacao tem de ser pela data do ZIP, nao pelo nome do CSV.
  nm   <- sub("_csv$", "", sub("\\.zip$", "", basename(zip_files)))
  date <- suppressWarnings(as.integer(sub("^.*_(\\d{8})$", "\\1", nm)))
  date[is.na(date)] <- 0L
  zips <- data.table::data.table(file = zip_files,
                                 base = sub("_\\d{8}$", "", nm),
                                 date = date)
  data.table::setorder(zips, base, -date)
  superados <- setdiff(zip_files, zips[, .SD[1L], by = base]$file)
  if(length(superados)){
    message("  descartando ", length(superados), " zip(s) superados pelo IBGE")
    file.remove(superados)
  }

  # o csv/ e refeito do zero: extracao de uma rodada anterior sobrevive ao
  # descarte do zip e continuaria casando com o padrao do tema
  unlink(csv_dir, recursive = TRUE)
  dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)
  unzip_censobr(zip_dir = dest_dir, out_zip = csv_dir)

  csv_paths <- list.files(csv_dir,
                          pattern    = "\\.csv$",
                          full.names = TRUE,
                          recursive  = TRUE,
                          ignore.case = TRUE)
  csv_paths <- unique(csv_paths)
  if(length(csv_paths) == 0) stop("No CSV files extracted to ", csv_dir)

  csv_paths
}


# raw_csv_paths : output de download_tract_2022.
# tbl_name      : "Basico"|"Domicilio"|"Pessoas"|"ResponsavelRenda"|"Indigenas"|
#                 "Quilombolas"|"Entorno"|"Obitos".
clean_tracts_2022 <- function(raw_csv_paths, tbl_name){

  # tema -> [prefixo V cols, regex filename]. IBGE re-publica com mesmo nome ou
  # nome+sufixo de data; regex aceita ambos. domicilios entorno tem í acentuado
  # que vira "domic_lios"/"domic..lios" apos unzip — regex permissivo 0-4 bytes.
  dataset_info_2022 <- tribble(
    ~theme, ~prefix, ~pattern,

    "Basico",           NA_character_,    "^Agregados_por_setores_basico_BR(_\\d{8})?\\.csv$",

    "Domicilio",        "domicilio01",    "^Agregados_por_setores_caracteristicas_domicilio1_BR(_\\d{8})?\\.csv$",
    "Domicilio",        "domicilio02",    "^Agregados_por_setores_caracteristicas_domicilio2_BR(_\\d{8})?\\.csv$",
    "Domicilio",        "domicilio03",    "^Agregados_por_setores_caracteristicas_domicilio3_BR(_\\d{8})?\\.csv$",

    "Pessoas",          "alfabetizacao",  "^Agregados_por_setores_alfabetizacao_BR(_\\d{8})?\\.csv$",
    "Pessoas",          "raca",           "^Agregados_por_setores_cor_ou_raca_BR(_\\d{8})?\\.csv$",
    "Pessoas",          "demografia",     "^Agregados_por_setores_demografia_BR(_\\d{8})?\\.csv$",
    "Pessoas",          "parentesco",     "^Agregados_por_setores_parentesco_BR(_\\d{8})?\\.csv$",

    "ResponsavelRenda", NA_character_,    "^Agregados_por_setores_renda_responsavel_BR(_\\d{8})?\\.csv$",

    "Indigenas",        "domicilios",     "^Agregados_por_setores_domicilios_indigenas_BR(_\\d{8})?\\.csv$",
    "Indigenas",        "pessoas",        "^Agregados_por_setores_pessoas_indigenas_BR(_\\d{8})?\\.csv$",

    "Quilombolas",      "domicilios",     "^Agregados_por_setores_domicilios_quilombolas_BR(_\\d{8})?\\.csv$",
    "Quilombolas",      "pessoas",        "^Agregados_por_setores_pessoas_quilombolas_BR(_\\d{8})?\\.csv$",

    "Entorno",          "domicilios",     "^Agregados_por_setores_entorno_domic.{0,4}lios_BR(_\\d{8})?\\.csv$",
    "Entorno",          "faces",          "^Agregados_por_setores_entorno_faces_BR(_\\d{8})?\\.csv$",
    "Entorno",          "moradores",      "^Agregados_por_setores_entorno_moradores_BR(_\\d{8})?\\.csv$",

    "Obitos",           NA_character_,    "^Agregados_por_setores_obitos_BR(_\\d{8})?\\.csv$"
  )

  dataset_basico <- recode_basico_2022(raw_csv_paths, dataset_info_2022)

  if(tbl_name == "Basico"){
    out <- dataset_basico
  } else {
    if(!tbl_name %in% dataset_info_2022$theme) stop("clean_tracts_2022: tema desconhecido '", tbl_name, "'")
    out <- make_theme_dataset_2022(theme_i           = tbl_name,
                                   raw_csv_paths     = raw_csv_paths,
                                   dataset_basico    = dataset_basico,
                                   dataset_info_2022 = dataset_info_2022)
  }

  out$table_name <- tbl_name
  out
}


save_tracts_2022 <- function(cleaned_dt, data_version){

  tbl <- cleaned_dt$table_name[1]
  message("Saving tracts 2022: ", tbl)

  dir.create("./data/tracts/2022/", recursive = TRUE, showWarnings = FALSE)

  out <- cleaned_dt
  out$table_name <- NULL

  # a chave do IBGE volta ao nome que tem no CSV; as colunas censobr vao para o inicio
  data.table::setnames(out, "CD_setor", "CD_SETOR")
  out <- relocate_geo_cols_censobr(out)

  # convencao v0.6.0: code_* numeric.
  out <- code_cols_to_numeric(out)

  # save data
  message("saving")
  dir.create("./data/tracts/2022/", recursive = TRUE, showWarnings = FALSE)
  dest_file <- paste0("./data/tracts/2022/2022_tracts_", tolower(tbl), "_", data_version,".parquet")
  write_censobr_parquet(out, dest_file)

  dest_file
}
