# download zipped files of census tracts and return the paths to unzipped files
download_tract_2010 <- function(year, remote, overwrite = FALSE){ # year = 2010
  
  # create dest_dir
  dest_dir <- paste0('./data_raw/tracts/', year)
  dir.create(dest_dir, recursive = T, showWarnings = FALSE)
  
  message(paste0("\nDownloading year: ", year, '\n'))
  
  # get ftp
  if(year==2010){
    ftp   <- FTP_CENSOBR$tracts_2010
    files <- NULL
  }
  
  # if(year==2022){
  #   ftp   <- c('https://ftp.ibge.gov.br/Censos/Censo_Demografico_2022/Agregados_por_Setores_Censitarios/Agregados_por_Setor_csv/',
  #              'https://ftp.ibge.gov.br/Censos/Censo_Demografico_2022/Agregados_por_Setores_Censitarios_Caracteristicas_urbanisticas_do_entorno_dos_domicilios/Agregados_por_Setor_csv/')
  #   
  #   files <- c("https://ftp.ibge.gov.br/Censos/Censo_Demografico_2022/Agregados_por_Setores_Censitarios_Rendimento_do_Responsavel/Agregados_por_setores_renda_responsavel_BR_csv.zip")
  # }
  
  # get file names -- `remote` e a listagem do FTP vinda de
  # ftp_fingerprint_censobr(), e a dependencia que faz este alvo rodar de novo
  # quando o IBGE republica.
  listed_files <- remote$arquivo

  # keep zip files
  listed_files <- listed_files[listed_files %like% ".zip$"]

  # IBGE as vezes re-publica zip de uma UF com data nova (RS_20231030 ->
  # RS_20241211; GO_20231030 -> GO_20250915). Manter so o mais recente por UF.
  listed_files <- pick_latest_per_uf(listed_files)

  # Baixar so o que nao esta em disco (smart-skip via download_file_censobr
  # confere size+mtime via HEAD pra deteccao de re-publicacao com mesmo nome).
  if(overwrite){
    files_to_download <- listed_files
  } else {
    files_to_download <- listed_files[!listed_files %in% list.files(dest_dir)]
  }

  if(length(files_to_download) > 0){
    download_file_censobr(file_url = paste0(ftp, files_to_download),
                          dest_dir = dest_dir)
  }

  # Apos o download (ou skip), remover do disco zips locais com versao obsoleta
  # cuja UF tem versao mais recente. Ex: se RS_20231030.zip e RS_20241211.zip
  # estao ambos em dest_dir, mantem so o mais recente.
  local_zips    <- list.files(dest_dir, pattern = "\\.zip$", full.names = TRUE)
  keep_zips     <- pick_latest_per_uf(local_zips)
  obsolete_zips <- setdiff(local_zips, keep_zips)
  if(length(obsolete_zips)) file.remove(obsolete_zips)
  
  # unzip files
  
  # pass unzipped files to a temp dir so we don't overload local disk
  
  temp_zip_dir <- tempdir()
  
  unzipped_files <- unzip_censobr(
    zip_dir = dest_dir, 
    out_zip = dest_dir
    )
  
  # ignore documentation files
  unzipped_files <- unzipped_files[ ! unzipped_files %like% "Descri|.zip"]
  
  # rename files to upper case but keep file extension to lowercase
  # this is necessary to enforce consistency of file names across states and tables 
  rename_files_toupper_lower_ext(unzipped_files)
  
  # retorna XLS (não CSV). Os CSVs do IBGE têm múltiplos problemas:
  # ENTORNO_*.csv: Cod_setor em notação científica (UFs grandes, perde precisão).
  # PESSOA*_SP2.csv, RESPONSAVEL*_SP2.csv, PESSOA02_AC.csv: separador "," + quotes
  # duplicados (formato malformado). XLS preserva tudo. readxl + col_types="text"
  # mantém "X" como texto literal — issues #71+#73 não regridem porque o all-NA-drop
  # não dispara em strings "X" (só em colunas genuinamente NA).
  # xlsx? casa .xls e .xlsx — RS publicou Domicilio01_RS.xlsx (único fora do padrão).
  raw_file_paths <- list.files(
    path = dest_dir,
    pattern = "\\.xlsx?$",
    ignore.case = TRUE,
    all.files = T,
    full.names = T,
    recursive = T
    )

  raw_file_paths <- raw_file_paths[ ! raw_file_paths %like% "Descri|.zip"]
  raw_file_paths <- unique(raw_file_paths)
  raw_file_paths
}


# generate a national df with all states for a given table
# raw_file_paths <- tar_read(raw_tracts_paths_2010)
# tbl_name <- tar_read(table_names_tracts)[1]
clean_tracts_2010 <- function(raw_file_paths, tbl_name){
  
  # create dest dir for clean data
  dir.create('./data/tracts/2010/', recursive = T, showWarnings = FALSE)
  
  # read a single file for a given combination of state and table
  read_single_file_tract_2010 <- function(f){ # f = temp_files[55]
    
    ### replace "X" with NA
    ### delete a couple of tracts with ÿ caracter

    # f = "./data_raw/tracts/2010/CE_20171016/CE/Base informaçoes setores2010 universo CE/CSV/Pessoa07_CE.csv"
    # f = "./data_raw/tracts/2010/CE_20231030/Base informaçoes setores2010 universo CE/CSV/Basico_CE.csv"
    # f = './data_raw/tracts/2010/CE_20231030/Base informaçoes setores2010 universo CE/EXCEL/Basico_CE.xls'
    
    # f = "./data_raw/tracts/2010/RO_20231030/Base informaçoes setores2010 universo RO/EXCEL/Entorno05_RO.xls"
    # f = "./data_raw/tracts/2010/CE_20231030/Base informaçoes setores2010 universo CE/EXCEL/Entorno05_CE.xls"
    
    message(f)
    
    # # detect state
    # st <- str_trim(str_extract(f, "_([:upper:][:upper:])")) |> unique()
    # 
    # # determine encoding
    # enc <- ifelse(st=='_ES', 'UTF-8', 'Latin-1')
    
    # XLS preserva "X" como texto literal, Cod_setor full precision, e nomes
    # de colunas íntegros — independente dos quirks de CSV-export do IBGE.
    temp_df <- as.data.table(readxl::read_excel(f, col_types = "text"))

    # readxl gera nomes auto "...242" para cells de header sem nome — descartar.
    spurious <- grep("^\\.{3}\\d+$", names(temp_df), value = TRUE)
    if(length(spurious)) temp_df[, (spurious) := NULL]

    # Algumas UFs vêm com nomes duplicados (DOMICILIO02_RO 107 dups; ENTORNO02_RO).
    names(temp_df) <- make.unique(names(temp_df), sep = "_")

    # Issue #68: Pessoa02 de GO tinha V01..V09 (zeros omitidos). IBGE corrigiu
    # em 2025-09-15 (Atualizacoes_20250915.txt do FTP); GO_20250915.zip ja vem
    # com V001-V099. Fix mantido como salvaguarda defensiva caso IBGE re-shipe
    # versao com bug. SP1/SP2 nunca tiveram V01-V09 nos arquivos atuais (tem
    # outro problema, shift +85 - tratado abaixo, ver relatorio_pessoa02_sp_shift.md).
    uf <- str_remove_all(str_extract(basename(f), "_[A-Z]{2}[0-9]?\\."), "[_.]")
    if(uf %in% c("GO", "SP1", "SP2")){
      names(temp_df) <- sub("^V(\\d{2})$", "V0\\1", names(temp_df))
    }

    # Pessoa02_SP1.xls e Pessoa02_SP2.xls têm numeração shiftada em +85 vs
    # dicionário oficial: V086 corresponde a V001, V255 a V170, e assim por
    # diante. Confirmado por 84 das 85 identidades aritméticas Pessoa01_V_i =
    # Pessoa02_homens_i + Pessoa02_mulheres_i (relatório em
    # references/relatorio_pessoa02_sp_shift.md). Crosswalk: V_n -> V_(n-85)
    # para todo n >= 86.
    if(uf %in% c("SP1", "SP2") && grepl("^PESSOA02_", basename(f), ignore.case = TRUE)){
      v_old <- grep("^V\\d+$", names(temp_df), value = TRUE)
      v_num <- as.integer(sub("V", "", v_old))
      to_shift <- v_num >= 86
      if(any(to_shift)){
        v_new <- ifelse(to_shift, sprintf("V%03d", v_num - 85), v_old)
        data.table::setnames(temp_df, v_old, v_new)
      }
    }

    # dropar colunas 100% NA
    setDT(temp_df)
    all_NA <- names(temp_df)[sapply(temp_df, function(x) all(is.na(x)))]
    if(length(all_NA)) temp_df[, (all_NA) := NULL]

    # ÿ aparece em alguns arquivos (Pessoa07_CE, Entorno05_RO) — striped.
    has_y <- any(vapply(temp_df, function(col) any(grepl("ÿ", col, fixed = TRUE), na.rm = TRUE), logical(1)))
    if(has_y){
      message("ÿ detected in ", f)
      for(col in names(temp_df))
        set(temp_df, j = col, value = gsub("ÿ", "", temp_df[[col]], fixed = TRUE))
    }
    
    
    # get root of file name
    root_name <- basename(f)
    root_name <- sub("_.*$", "", root_name)
    root_name <- tolower(root_name)
    
    # Cod_setor fica como o IBGE escreve; code_tract e code_muni sao as chaves censobr
    temp_df[, code_tract := as.character(Cod_setor)]
    temp_df[, code_muni := substr(code_tract, 1, 7)]
    data.table::setcolorder(temp_df, c('code_muni', 'code_tract', 'Cod_setor'))

    # IBGE às vezes inclui linhas-resumo sem código de setor. Filtrar antes do
    # merge — data.table casa NA==NA no join (gera Cartesian); dplyr::left_join
    # antigo silenciosamente dropava NAs.
    temp_df <- temp_df[!is.na(code_tract)]
    
    # prefixa V cols com nome do sub-arquivo (pessoa01_, domicilio02_, etc.)
    tabl <- detect_2010_table_name(f)
    if(tabl %in% c("PESSOA", "DOMICILIO", "RESPONSAVEL", "ENTORNO")){
      cols_to_rename <- names(temp_df)[4:ncol(temp_df)]
      names(temp_df)[4:ncol(temp_df)] <- paste0(root_name, "_", cols_to_rename)
    }

    # table_name é re-adicionado em clean_tracts_2010 após rbindlist; mantê-lo
    # aqui faz merge.data.table acumular table_name.x/.y entre sub-tabelas.
    temp_df
  }
  
  # processa todos os arquivos de uma UF; em temas com 2+ sub-tabelas, faz
  # join iterativo data.table consumindo a fila pra liberar memória.
  prep_state <- function(abbrev, temp_files){
    message(abbrev)

    uf_files <- temp_files[temp_files %like% paste0(abbrev, "/EXCEL/")]
    df_list  <- lapply(uf_files, read_single_file_tract_2010)

    temp_uf <- df_list[[1]]
    df_list[[1]] <- NULL
    while(length(df_list) > 0){
      temp_uf <- merge(temp_uf, df_list[[1]],
                       by = c("code_muni", "code_tract", "Cod_setor"),
                       all.x = TRUE, sort = FALSE)
      df_list[[1]] <- NULL
      gc(verbose = FALSE)
    }

    rm(df_list); gc(verbose = FALSE)
    temp_uf
  }


  # workers ≤ 4 por regra (memory-discipline). Mais que isso saturou RAM em ENTORNO.
  future::plan(future::multisession, workers = 4)

  temp_files <- raw_file_paths[raw_file_paths %like% tbl_name]
  if(tbl_name %in% c("PESSOA", "DOMICILIO", "RESPONSAVEL", "ENTORNO")){
    temp_files <- temp_files[str_detect(basename(temp_files), "[0-9]{2}")]
  }

  # SP vem em duas peças (SP_Capital + SP_Exceto_Capital); 26 UFs comuns + 2 SP.
  all_states <- c(UF_SIGLAS[!grepl("SP", UF_SIGLAS)], "SP_Capital", "SP_Exceto_Capital")

  ufs_list <- furrr::future_map(all_states, prep_state,
                                temp_files = temp_files, .progress = TRUE)

  br_df <- rbindlist(ufs_list, fill = TRUE, use.names = TRUE)
  rm(ufs_list); gc(verbose = FALSE)

  br_df$table_name <- tbl_name
  br_df
}




# generate a national df with all states for a given table
# br_df <- tar_read(clean_tract_table_2010, 1)
# data_version <- tar_read(data_version)
save_tracts_2010 <- function(br_df, data_version){

  tbl <- br_df$table_name[1]
  message(tbl)

  # code_weighting (área de ponderação): crosswalk IBGE em Documentacao_microdados_2010.zip.
  # geobr (>=1.10) deixou de expor essa coluna; lemos da fonte canônica.
  ap <- get_areas_ponderacao_2010()
  data.table::setDT(br_df)
  br_df <- merge(br_df, ap, by = "code_tract", all.x = TRUE, sort = FALSE)

  br_df <- add_geography_cols_tracts(br_df, year = 2010)

  # Padroniza nomes de UF/região (issue #75). add_state_info reescreve code_state
  # numeric + refresca name_state/abbrev_state; add_region_info deriva code_region.
  br_df <- add_state_info(br_df, column = "code_state")
  br_df <- add_region_info(br_df, column = "code_state")

  AT <- br_df

  # rename columns
  if(tbl == 'BASICO'){
    
    options(scipen = 999)

    # colunas censobr copiadas das do IBGE, que ficam com o nome original
    AT <- dplyr::mutate(AT,
                        name_muni         = Nome_do_municipio,
                        code_meso         = Cod_meso,
                        name_meso         = Nome_da_meso,
                        code_micro        = Cod_micro,
                        name_micro        = Nome_da_micro,
                        code_metro        = Cod_RM,
                        name_metro        = Nome_da_RM,
                        name_neighborhood = Nome_do_bairro,
                        code_neighborhood = Cod_bairro,
                        code_district     = Cod_distrito,
                        name_district     = Nome_do_distrito,
                        code_subdistrict  = Cod_subdistrito,
                        name_subdistrict  = Nome_do_subdistrito,
                        code_situacao     = as.numeric(Situacao_setor))
  } else {
    # nos outros temas a Situacao_setor vem repetida por sub-tabela, identica
    sit <- grep("Situacao_setor$", names(AT), value = TRUE)[1]
    AT$code_situacao <- as.numeric(AT[[sit]])
  }

  AT <- collect(AT)

  # V cols vêm como character (fread colClasses) com vírgula decimal IBGE.
  # Loop set é preferível a mutate(across) — evita cópia da tabela inteira.
  message("to numeric")
  data.table::setDT(AT)
  for(v in grep("(^|_)V\\d", names(AT), value = TRUE))
    set(AT, j = v, value = as.numeric(gsub(",", ".", AT[[v]], fixed = TRUE)))

  AT <- AT[order(code_muni, code_tract)]
  setindex(AT, NULL)
  setDF(AT)

  # colunas censobr de geografia no inicio; convenção v0.6.0: code_* numeric.
  AT <- relocate_geo_cols_censobr(AT)
  AT <- code_cols_to_numeric(AT)
  AT <- cast_censobr_types(AT, paste0("2010_tracts_", tolower(tbl)))

  # table_name é metadata interna do pipeline — não vai pro output.
  AT$table_name <- NULL

  # save data
  message("saving")
  dir.create("./data/tracts/2010/", recursive = TRUE, showWarnings = FALSE)
  dest_file <- paste0("./data/tracts/2010/2010_tracts_", tolower(tbl), "_", data_version,".parquet")
  write_censobr_parquet(AT, dest_file)

  dest_file
}
