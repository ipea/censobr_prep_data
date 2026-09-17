
###### detect year from file name  -----------------
detect_year_from_string <- function(string){

  yyyy <- regmatches(string, gregexpr("\\d{4}", string))[[1]]
  yyyy <- unique(yyyy)
  yyyy <- yyyy[ yyyy != '2500' ]
  return(yyyy)
}


###### ftp do IBGE -----------------

# Enderecos do FTP do IBGE, um por fonte. Ficam num lugar so porque duas coisas
# precisam deles: a funcao de download de cada ano e o alvo que confere o que o
# servidor esta servindo agora.
FTP_CENSOBR <- list(

  microdata_2000     = 'https://ftp.ibge.gov.br/Censos/Censo_Demografico_2000/Microdados/',
  microdata_2010     = 'https://ftp.ibge.gov.br/Censos/Censo_Demografico_2010/Resultados_Gerais_da_Amostra/Microdados/',
  microdata_2022     = 'https://ftp.ibge.gov.br/Censos/Censo_Demografico_2022/Microdados_e_Areas_de_Ponderacao/Microdados_de_acesso_Publico/csv/',

  tracts_2000        = 'https://ftp.ibge.gov.br/Censos/Censo_Demografico_2000/Dados_do_Universo/Agregado_por_Setores_Censitarios/',
  tracts_2010        = 'https://ftp.ibge.gov.br/Censos/Censo_Demografico_2010/Resultados_do_Universo/Agregados_por_Setores_Censitarios/',
  tracts_2022        = c('https://ftp.ibge.gov.br/Censos/Censo_Demografico_2022/Agregados_por_Setores_Censitarios/Agregados_por_Setor_csv/',
                         'https://ftp.ibge.gov.br/Censos/Censo_Demografico_2022/Agregados_por_Setores_Censitarios_Caracteristicas_urbanisticas_do_entorno_dos_domicilios/Agregados_por_Setor_csv/',
                         'https://ftp.ibge.gov.br/Censos/Censo_Demografico_2022/Agregados_por_Setores_Censitarios_Rendimento_do_Responsavel/Agregados_por_setores_renda_responsavel_BR_20260508_csv.zip'),
  tracts_2022_prelim = 'https://ftp.ibge.gov.br/Censos/Censo_Demografico_2022/Agregados_por_Setores_Censitarios_preliminares/agregados_por_setores_csv/BR/Agregados_preliminares_por_setores_censitarios_BR.zip'
)


# O que o FTP esta servindo agora: url, arquivo, data e tamanho de tudo que ha
# na fonte. Um alvo com cue "always" chama isto e o alvo de download depende do
# resultado -- e a unica forma de o pipeline perceber republicacao, porque o
# targets compara o hash dos arquivos locais, que nao muda quando o IBGE troca
# os dele. Em 14/09/2026 o IBGE acrescentou a P0115 aos microdados de 2022 e
# nada aqui se mexeu.
#
# Uma requisicao por pasta: o indice do Apache ja traz nome, data e tamanho de
# todos os arquivos de uma vez. URL de arquivo solto, que nao tem indice, vai
# por HEAD. Sem resposta do servidor devolve a ultima impressao gravada em
# disco -- o FTP do IBGE cai e recusa rajadas, e isso nao pode derrubar um
# tar_make que nao precisa baixar nada.
ftp_fingerprint_censobr <- function(fonte){

  cache <- file.path("./data_raw/ftp_fingerprints", paste0(fonte, ".csv"))

  impressao <- tryCatch(

    lapply(FTP_CENSOBR[[fonte]], function(url){

      if(!grepl("/$", url)){
        resp <- httr2::request(url) |>
          httr2::req_method("HEAD") |>
          httr2::req_options(timeout = 120, ssl_verifypeer = 0L) |>
          httr2::req_perform()
        return(data.frame(url     = url,
                          arquivo = basename(url),
                          data    = httr2::resp_header(resp, "Last-Modified"),
                          tamanho = httr2::resp_header(resp, "Content-Length")))
      }

      # indice do Apache: <td> de icone, link, data, tamanho e descricao. O
      # texto do link vem truncado com "..>", entao o nome sai do href; as
      # linhas de cabecalho, o pai e os links de ordenacao nao tem os cinco.
      linhas <- rvest::html_elements(rvest::read_html(url), "table tr")

      campos <- lapply(linhas, function(linha){
        td   <- rvest::html_text2(rvest::html_elements(linha, "td"))
        href <- rvest::html_attr(rvest::html_element(linha, "td a"), "href")
        if(length(td) < 4 || is.na(href) || grepl("^[./?]", href)) return(NULL)
        data.frame(url     = paste0(url, href),
                   arquivo = href,
                   data    = trimws(td[3]),
                   tamanho = trimws(td[4]))
      })

      do.call(rbind, campos)
    }),

    error = function(e) NULL)

  if(is.null(impressao)){
    message("FTP mudo: ", fonte, " fica com a ultima impressao conhecida")
    return(data.table::fread(cache, data.table = FALSE))
  }

  impressao <- do.call(rbind, impressao)
  impressao <- impressao[order(impressao$arquivo), ]
  rownames(impressao) <- NULL

  dir.create(dirname(cache), recursive = TRUE, showWarnings = FALSE)
  data.table::fwrite(impressao, cache)

  impressao
}



###### Download file to tempdir -----------------
#
# Smart-skip: if a local file already exists and its size and mtime match the
# remote (via HEAD request), the download is skipped. Mismatched files are
# re-downloaded. Each download is retried up to `max_retries` times with
# exponential backoff.
#
# Defaults:
#   max_active = 3   (parallel; conservative against IBGE FTP rate-limit)
#   max_retries = 3  (per-URL retry on transient failures)
#
download_file_censobr <- function(file_url,
                                dest_dir = NULL,
                                showProgress = TRUE,
                                timeout = 500,
                                max_active = 3,
                                max_retries = 3) {

  if (is.null(dest_dir)) {
    dest_dir <- tempdir()
  }

  if (!dir.exists(dest_dir)) {
    stop("'dest_dir' does not exist")
  }

  dest_files <- file.path(dest_dir, basename(file_url))

  # ---- Step 1: HEAD requests to learn remote size + Last-Modified -----------
  head_reqs <- lapply(file_url, function(url) {
    httr2::request(url) |>
      httr2::req_method("HEAD") |>
      httr2::req_options(timeout = timeout, ssl_verifypeer = 0L)
  })

  head_resps <- if (length(head_reqs) == 1L) {
    list(tryCatch(httr2::req_perform(head_reqs[[1]]),
                  error = function(e) structure(list(), class = "httr2_failure")))
  } else {
    httr2::req_perform_parallel(
      head_reqs, max_active = max_active, on_error = "continue"
    )
  }

  remote_size <- sapply(head_resps, function(r){
    if (inherits(r, "httr2_failure")) return(NA_real_)
    h <- httr2::resp_header(r, "Content-Length")
    if (is.null(h)) return(NA_real_)
    suppressWarnings(as.numeric(h))
  })

  remote_mtime <- as.POSIXct(NA, tz = "GMT") |> rep(length(head_resps))
  for (i in seq_along(head_resps)) {
    r <- head_resps[[i]]
    if (inherits(r, "httr2_failure")) next
    h <- httr2::resp_header(r, "Last-Modified")
    if (is.null(h)) next
    parsed <- suppressWarnings(
      as.POSIXct(h, format = "%a, %d %b %Y %H:%M:%S", tz = "GMT")
    )
    if (!is.na(parsed)) remote_mtime[i] <- parsed
  }

  # ---- Step 2: decide which files need (re-)download ------------------------
  needs_download <- sapply(seq_along(file_url), function(i){
    if (!file.exists(dest_files[i])) return(TRUE)
    if (is.na(remote_size[i])) return(TRUE)   # HEAD failed; safer to redownload

    local_info <- file.info(dest_files[i])
    if (!isTRUE(local_info$size == remote_size[i])) return(TRUE)

    # If we have a remote mtime, require a tight match (within 2s tolerance,
    # since mtime granularity differs between filesystems).
    if (!is.na(remote_mtime[i])) {
      local_m <- as.POSIXct(local_info$mtime, tz = "GMT")
      delta_s <- abs(as.numeric(difftime(local_m, remote_mtime[i], units = "secs")))
      if (delta_s > 2) return(TRUE)
    }

    FALSE  # size (and mtime, if known) match: keep local file
  })

  to_download <- which(needs_download)
  n_skip      <- length(file_url) - length(to_download)

  if (length(to_download) == 0L) {
    message("download_file_censobr: all ", length(file_url),
            " files already match remote (size+mtime); skipping.")
    return(dest_files)
  }
  if (n_skip > 0L) {
    message("download_file_censobr: skipping ", n_skip,
            " up-to-date file(s); downloading ",
            length(to_download), " new/changed.")
  }

  # delete partials / stale files before downloading
  for (i in to_download) {
    if (file.exists(dest_files[i])) unlink(dest_files[i])
  }

  # ---- Step 3: download with per-URL retry ----------------------------------
  remaining     <- to_download
  attempt       <- 1L

  while (length(remaining) > 0L && attempt <= max_retries) {
    if (attempt > 1L) {
      message("  retry ", attempt, "/", max_retries,
              " for ", length(remaining), " file(s)")
    }

    urls_now  <- file_url[remaining]
    paths_now <- dest_files[remaining]

    reqs <- lapply(urls_now, function(url){
      httr2::request(url) |>
        httr2::req_options(timeout = timeout, ssl_verifypeer = 0L)
    })

    if (length(reqs) == 1L) {
      ok <- tryCatch({
        httr2::req_perform(reqs[[1]], path = paths_now[1])
        TRUE
      }, error = function(e) FALSE)
      ok_vec <- ok
    } else {
      resps <- httr2::req_perform_parallel(
        reqs, paths = paths_now,
        max_active = max_active, on_error = "continue"
      )
      ok_vec <- sapply(resps, function(x) !inherits(x, "httr2_failure"))
    }

    # Set local mtime to remote Last-Modified for files that succeeded -- so
    # the next run's HEAD-based skip check can recognize them as up-to-date.
    for (j in which(ok_vec)) {
      idx <- remaining[j]
      if (!is.na(remote_mtime[idx])) {
        try(Sys.setFileTime(dest_files[idx], remote_mtime[idx]), silent = TRUE)
      }
    }

    failed_j <- which(!ok_vec)
    if (length(failed_j) == 0L) break
    # clean partials before retry
    for (j in failed_j) {
      if (file.exists(paths_now[j])) unlink(paths_now[j])
    }
    remaining <- remaining[failed_j]
    attempt   <- attempt + 1L
    if (length(remaining) > 0L && attempt <= max_retries) {
      Sys.sleep(2 ^ (attempt - 2L))  # backoff: 1s, 2s, 4s
    }
  }

  if (length(remaining) > 0L) {
    warning("download_file_censobr: after ", max_retries, " attempts, ",
            length(remaining), " file(s) still failed:\n",
            paste(file_url[remaining], collapse = "\n"))
  }

  return(dest_files[file.exists(dest_files)])
}


# Unzip censobr function ---------------------------------------------------------

unzip_censobr <- function(zip_dir, out_zip = NULL) {

  if (is.null(out_zip)) {
    out_zip <- file.path(zip_dir, "unzipped")
  }
  dir.create(out_zip, showWarnings = FALSE, recursive = TRUE)

  zip_names <- list.files(zip_dir, pattern = "\\.zip$", full.names = TRUE)

  purrr::walk(zip_names, function(z) {

    # extracao anterior intacta nao se refaz: todo item do zip ja esta em disco
    # com o tamanho que o zip declara. O alvo de download volta a rodar sempre
    # que a impressao do FTP muda, e reextrair dezenas de GB a toa custa muito
    # mais que a conferencia.
    # Os zips dos setores de 2000 gravam o nome dos arquivos em latin-1, que no
    # R sai como string multibyte invalida: ali nao da para conferir nada, e o
    # zip segue para extracao.
    itens <- utils::unzip(z, list = TRUE)

    if(all(validUTF8(itens$Name))){
      itens    <- itens[!grepl("/$", itens$Name), ]
      tamanhos <- file.size(file.path(out_zip, itens$Name))
      if(nrow(itens) && isTRUE(all(tamanhos == itens$Length))) return(invisible(NULL))
    }

    ok <- tryCatch({
      unzip(z, exdir = out_zip)
      TRUE
    }, error = function(e) FALSE)

    if (!ok) {
      system2(
        "unzip",
        args = c("-oq", shQuote(z), "-d", shQuote(out_zip)),
        stdout = FALSE,
        stderr = FALSE
      )
    }
  })

  files <- list.files(path = out_zip, full.names = T, recursive = T)
  files <- unique(files)

  return(files)
}



# code coulumns to numeric ---------------------------

code_cols_to_numeric <- function(df){
  df <- df |>
    dplyr::mutate(
      dplyr::across(
        dplyr::starts_with("code_"), as.numeric
      )
    )

  return(df)
}


# As colunas de geografia do censobr sao adicionais: as do IBGE ficam com o nome
# original, e estas vem sempre no inicio da tabela, nesta ordem -- do maior para
# o menor recorte, codigo antes do nome; depois os atributos do setor e as
# variantes historicas.
GEO_COLS_CENSOBR <- c(
  "code_region", "name_region",
  "code_state", "abbrev_state", "name_state",
  "code_meso", "name_meso",
  "code_micro", "name_micro",
  "code_intermediate", "name_intermediate",
  "code_immediate", "name_immediate",
  "code_metro", "name_metro",
  "code_urban_concentration", "name_urban_concentration",
  "code_muni", "name_muni",
  "code_district", "name_district",
  "code_subdistrict", "name_subdistrict",
  "code_neighborhood", "name_neighborhood",
  "code_nucleo_urbano", "name_nucleo_urbano",
  "code_favela", "name_favela",
  "code_aglomerado", "name_aglomerado",
  "code_weighting", "code_tract",
  "code_situacao", "situacao", "code_type", "area_km2",
  "code_muni_1960", "code_muni_1970", "code_muni_1980",
  "name_muni_1960", "code_district_1960", "name_district_1960", "name_bairro_1960",
  "name_region_1960", "code_state_1960", "abbrev_state_1960", "name_state_1960",
  "abbrev_state_1970", "name_state_1970")

relocate_geo_cols_censobr <- function(df){
  first <- intersect(GEO_COLS_CENSOBR, names(df))
  if(data.table::is.data.table(df)){
    data.table::setcolorder(df, first)
    return(df)
  }
  # all_of sem prefixo de pacote: o arrow so traduz o seletor assim
  dplyr::relocate(df, all_of(first))
}



# detect encoding of a csv file
detect_csv_encoding <- function(file_path){

  out <- list()

  out$readr <- readr::guess_encoding(file_path)

  temp <- stringi::stri_enc_detect(
    readLines(
    file_path,
    warn = FALSE,
    encoding = "bytes")
    )

 df_stringi <- lapply(
   X = 1:length(temp),
   FUN = function(i, mylist = temp){
     mylist[[i]] |>
       dplyr::filter(Language=='pt')
           }
         ) |>
   data.table::rbindlist() |>
   dplyr::arrange(-Confidence) |>
   unique() |>
   head()


  out$stringi <- df_stringi
  return(out)
}




# Add State abbreviation -------------------------------------------------------
# Adiciona code_state, name_state e abbrev_state em temp_df.
#  - column == "name_state": deriva code_state via lookup tolerante a grafias
#    historicas (Goyaz, Guapore, Districto Federal, Brasilia, Rondonia
#    com/sem acento). Distrito Federal eh ambiguo: codigo 34 ate 1960 (era
#    Rio/Guanabara), 53 a partir de 1950 (Brasilia) — requer coluna 'year'.
#  - column != "name_state": deriva code_state de substr(column, 1, 2) e gera
#    name_state via fcase canonica.
# abbrev_state eh sempre derivado do code_state final.
add_state_info <- function(temp_df, column){

  options(encoding = "UTF-8")
  col_names <- names(temp_df)

  # Lookup name_state -> code_state. Usado quando code_state esta ausente OU
  # quando existe mas tem NAs (1940-1991: raw IBGE traz code_state=NA pra quase
  # todos os estados) ou 0 (marker de litigio). Coalesce preserva valores
  # nao-NA pre-existentes.
  if ("name_state" %in% col_names &&
      (!"code_state" %in% col_names ||
       any(is.na(as.numeric(temp_df$code_state))))) {

    ns <- temp_df$name_state
    yr <- if ("year" %in% col_names) temp_df$year else rep(NA_real_, length(ns))

    code_from_ns <- data.table::fcase(
      ns %like% "Rondonia|Rondônia|Guapoé|Guaporé",                       11,
      ns %like% "Acre",                                                                  12,
      ns == "Amazonas",                                                                  13,
      ns %like% "Roraima|Rio Branco",                                                    14,
      ns %in% c("Pará", "Para"),                                                    15,
      ns %like% "Amapá|Amapa",                                                      16,
      ns == "Tocantins",                                                                 17,
      ns %like% "(?i)territ" & ns %like% "(?i)fernando",                                 20,
      ns == "Maranhão",                                                             21,
      ns %like% "Piaui|Piauhy|Piauí",                                               22,
      ns == "Ceará",                                                                23,
      ns == "Rio Grande do Norte",                                                       24,
      ns %like% "Paraiba|Parahyba|Paraíba",                                         25,
      ns == "Pernambuco" | ns %like% "Fernando de Noronha",                              26,
      ns == "Alagoas" | ns == "Alagôas",                                            27,
      ns == "Sergipe",                                                                   28,
      ns == "Bahia",                                                                     29,
      ns == "Minas Gerais" | ns == "Minas Geraes",                                       31,
      ns %like% "Espirito Santo|Espírito Santo",                                    32,
      ns == "Rio de Janeiro",                                                            33,
      ns == "Guanabara" | ns %like% "(?i)munic[ií]pio neutro",                      34,
      ns == "São Paulo",                                                            35,
      ns %like% "Paraná|Parana",                                                    41,
      ns == "Santa Catarina" | ns == "Santa Catharina",                                  42,
      ns == "Rio Grande do Sul",                                                         43,
      ns == "Mato Grosso do Sul",                                                        50,
      ns == "Mato Grosso" | ns == "Matto Grosso",                                        51,
      ns %like% "Goiás|Goyaz|Goias",                                                52,
      (ns == "Distrito Federal" | ns == "Districto Federal") & yr < 1960,                34,
      (ns == "Distrito Federal" | ns %like% "Brasília|Brasilia") & yr > 1950,       53,
      default = NA_real_)

    if (!"code_state" %in% col_names) {
      temp_df$code_state <- code_from_ns
    } else {
      orig_cs <- as.numeric(temp_df$code_state)
      orig_cs <- ifelse(is.na(orig_cs) | orig_cs == 0, NA_real_, orig_cs)
      temp_df$code_state <- dplyr::coalesce(orig_cs, code_from_ns)
    }
  }

  # Sem name_state na entrada: deriva code_state da coluna passada (primeiros 2
  # digitos do codigo hierarquico, ex.: code_muni '3550308' -> code_state 35) e
  # adiciona name_state canonico.
  if (column != 'name_state') {
    temp_df$code_state <- as.numeric(substr(temp_df[[column]], 1, 2))
    temp_df$name_state <- data.table::fcase(
      temp_df$code_state == 11, "Rondônia",
      temp_df$code_state == 12, "Acre",
      temp_df$code_state == 13, "Amazonas",
      temp_df$code_state == 14, "Roraima",
      temp_df$code_state == 15, "Pará",
      temp_df$code_state == 16, "Amapá",
      temp_df$code_state == 17, "Tocantins",
      temp_df$code_state == 20, "Fernando de Noronha",
      temp_df$code_state == 21, "Maranhão",
      temp_df$code_state == 22, "Piauí",
      temp_df$code_state == 23, "Ceará",
      temp_df$code_state == 24, "Rio Grande do Norte",
      temp_df$code_state == 25, "Paraíba",
      temp_df$code_state == 26, "Pernambuco",
      temp_df$code_state == 27, "Alagoas",
      temp_df$code_state == 28, "Sergipe",
      temp_df$code_state == 29, "Bahia",
      temp_df$code_state == 31, "Minas Gerais",
      temp_df$code_state == 32, "Espírito Santo",
      temp_df$code_state == 33, "Rio de Janeiro",
      temp_df$code_state == 34, "Guanabara",
      temp_df$code_state == 35, "São Paulo",
      temp_df$code_state == 41, "Paraná",
      temp_df$code_state == 42, "Santa Catarina",
      temp_df$code_state == 43, "Rio Grande do Sul",
      temp_df$code_state == 50, "Mato Grosso do Sul",
      temp_df$code_state == 51, "Mato Grosso",
      temp_df$code_state == 52, "Goiás",
      temp_df$code_state == 53, "Distrito Federal",
      default = NA_character_)
  }

  # abbrev_state final, sempre derivado do code_state.
  temp_df$abbrev_state <- data.table::fcase(
    temp_df$code_state == 11, "RO",
    temp_df$code_state == 12, "AC",
    temp_df$code_state == 13, "AM",
    temp_df$code_state == 14, "RR",
    temp_df$code_state == 15, "PA",
    temp_df$code_state == 16, "AP",
    temp_df$code_state == 17, "TO",
    temp_df$code_state == 20, "FN",
    temp_df$code_state == 21, "MA",
    temp_df$code_state == 22, "PI",
    temp_df$code_state == 23, "CE",
    temp_df$code_state == 24, "RN",
    temp_df$code_state == 25, "PB",
    temp_df$code_state == 26, "PE",
    temp_df$code_state == 27, "AL",
    temp_df$code_state == 28, "SE",
    temp_df$code_state == 29, "BA",
    temp_df$code_state == 31, "MG",
    temp_df$code_state == 32, "ES",
    temp_df$code_state == 33, "RJ",
    temp_df$code_state == 34, "GB",
    temp_df$code_state == 35, "SP",
    temp_df$code_state == 41, "PR",
    temp_df$code_state == 42, "SC",
    temp_df$code_state == 43, "RS",
    temp_df$code_state == 50, "MS",
    temp_df$code_state == 51, "MT",
    temp_df$code_state == 52, "GO",
    temp_df$code_state == 53, "DF",
    default = NA_character_)

  temp_df
}


# Add Region info --------------------------------------------------------------
add_region_info <- function(temp_df, column){

  # add code_region
  temp_df$code_region <- substr( temp_df[[ column ]] , 1,1) |> as.numeric()

  # add name_region
  temp_df <- temp_df |> dplyr::mutate(name_region =
                                        data.table::fcase(code_region==1, 'Norte',
                                                          code_region==2, 'Nordeste',
                                                          code_region==3, 'Sudeste',
                                                          code_region==4, 'Sul',
                                                          code_region==5, 'Centro-Oeste',
                                                          default = NA))
  return(temp_df)
}


# snake case names -------------------------------------------------------------
snake_case_names <- function(temp_df, colname){

  for (i in colname) {

    if(i %in% names(temp_df)){
      # Capitalize the first letter
      temp_df[[ i ]] <- stringr::str_to_title( temp_df[[ i ]] )

      # prepositions to lower
      temp_df[[ i ]] <- gsub(" Do ",  " do ",   temp_df[[ i ]] )
      temp_df[[ i ]] <- gsub(" Dos ", " dos ", temp_df[[ i ]] )
      temp_df[[ i ]] <- gsub(" Da ",  " da ",   temp_df[[ i ]] )
      temp_df[[ i ]] <- gsub(" Das ", " das ", temp_df[[ i ]] )
      temp_df[[ i ]] <- gsub(" De ",  " de ",   temp_df[[ i ]] )
      temp_df[[ i ]] <- gsub(" Del ", " del ",   temp_df[[ i ]] )

      temp_df[[ i ]] <- gsub(" D'o",   " d'O",   temp_df[[ i ]] )
      temp_df[[ i ]] <- gsub(" D'ó",   " d'Ó",   temp_df[[ i ]] )
      temp_df[[ i ]] <- gsub(" D'a",   " d'A",   temp_df[[ i ]] )
      temp_df[[ i ]] <- gsub(" D'á",   " d'Á",   temp_df[[ i ]] )
    }
  }
  return(temp_df)
}




# Canonical writer for censobr parquets (zstd-22). ------------------------------
write_censobr_parquet <- function(df, path) {
  arrow::write_parquet(x = df,
                       sink = path,
                       compression = "zstd",
                       compression_level = 22)
}






# Robust sf read censobr function ------------------------------------------------
# Função para ler csv de multiplos arquivos e importá-los com
#  apenas as colunas que existem em todos

readmerge_censobr <-  function(folder_path,
                               encoding = "UTF-8"){

  # lista todos os .csv na pasta (busca recursiva opcional)
  csv_files <- list.files(folder_path, pattern = "\\.csv$", full.names = TRUE)
  csv_files <- unique(csv_files)

  # read files
  csv_list <- purrr::map(csv_files, function(f) {
    message("Lendo: ", f)
    data.table::fread(f, encoding = encoding) |>
      janitor::clean_names()
  })

  # une tudo
  merged <- data.table::rbindlist(csv_list)

  return(merged)
}

# States table codes for correction censobr function -----------------------------

states_censobr <- function() {
  states <- tibble::tibble(code_state = as.numeric(c(11, 12, 13, 14, 15, 16, 17, 21, 22,
                                                     23, 24, 25, 26, 27, 28, 29, 31, 32,
                                                     33, 35, 41, 42, 43, 50, 51, 52, 53)),
                           abbrev_state = c("RO", "AC", "AM", "RR", "PA", "AP", "TO",
                                            "MA", "PI", "CE", "RN", "PB", "PE", "AL",
                                            "SE", "BA", "MG", "ES", "RJ", "SP", "PR",
                                            "SC", "RS", "MS", "MT", "GO", "DF"),
                           name_state = c("Rondônia", "Acre", "Amazonas", "Roraima",
                                          "Pará", "Amapá", "Tocantins", "Maranhão",
                                          "Piauí", "Ceará", "Rio Grande do Norte",
                                          "Paraíba", "Pernambuco", "Alagoas", "Sergipe",
                                          "Bahia", "Minas Gerais", "Espírito Santo",
                                          "Rio de Janeiro", "São Paulo", "Paraná",
                                          "Santa Catarina", "Rio Grande do Sul",
                                          "Mato Grosso do Sul", "Mato Grosso", "Goiás",
                                          "Distrito Federal"),
                           code_region = c(rep(1, 7), rep(2, 9), rep(3, 4), rep(4, 3),
                                           rep(5, 4)),
                           name_region = c(rep("Norte", 7), rep("Nordeste", 9),
                                           rep("Sudeste", 4), rep("Sul", 3),
                                           rep("Centro-Oeste", 4)),
                           abbrevm_state = stringr::str_to_lower(abbrev_state))

  return(states)
}


# dicionario de colunas censobr --------------------------------------------------------

dicionario_municipality <- list(
  code_muni = c("cod_mun", "codmunic", "mun", "municipio_codigo", "geocod", "cod",
                "cod_muni", "cd_mun", "geocodigo", "geocodig_m", "br91poly_i",
                "cd_geocodm", "cd_geocmu", "geo_mun", "codigo"),
  name_muni = c("nome_cidade", "cidade", "nm_muni", "nome_muni",
                "nome_munic", "nm_municip", "nm_mun", "municipio", "nomemuni",
                "nomemunicp", "nome")
)


dicionario_state <- list(
  code_state = c("cd_estado", "uf", "coduf", "estado_codigo", "cod_uf", "codigo",
                 "cd_uf", "code_uf", "codigo_uf", "cod_state", "cd_geocodu",
                 "cd_geocuf", "geo_uf"),
  # abbrev_state = c("sigla", "sigla_uf", "sg_uf", "uf"),
  name_state = c("nm_uf", "nm_state", "nm_estado", "nome")
)



# Função para aplicar a padronização de colnames ------------------------------------------

rename_cols_censobr <- function(df, dict) {

  # original names
  original_names <- names(df)

  # normalized version for flexible matching
  normalize <- function(x) gsub("[^a-z0-9]", "", tolower(x))

  normalized_names <- normalize(original_names)

  # iterate over dictionary
  for (new_name in names(dict)) {
    candidates <- dict[[new_name]]
    normalized_candidates <- normalize(candidates)

    # find match
    idx <- match(normalized_candidates, normalized_names)
    idx <- idx[!is.na(idx)]  # keep only matches

    if (length(idx) > 0) {
      # rename: only first match if several exist
      names(df)[idx[1]] <- new_name
    }
  }

  return(df)
}





rename_files_toupper_lower_ext <- function(paths) {
  stopifnot(all(file.exists(paths)))

  dir <- dirname(paths)
  base <- basename(paths)

  name_no_ext <- tools::file_path_sans_ext(base)
  ext <- tools::file_ext(base)

  new_base <- ifelse(
    nzchar(ext),
    paste0(toupper(name_no_ext), ".", tolower(ext)),
    toupper(name_no_ext)
  )

  new_paths <- file.path(dir, new_base)

  ok <- file.rename(from = paths, to = new_paths)

  if (!all(ok)) {
    warning("Some files could not be renamed.")
  }

  invisible(new_paths)
}

UF_SIGLAS <- c("RO","AC","AM","RR","PA","AP","TO",
               "MA","PI","CE","RN","PB","PE","AL","SE","BA",
               "MG","ES","RJ","SP","PR","SC","RS",
               "MS","MT","GO","DF")


# Quando IBGE re-publica zips de UF com nova data (RS_20231030.zip foi
# substituido por RS_20241211.zip; GO_20231030.zip por GO_20250915.zip per
# Atualizacoes_20250915.txt), manter so a versao mais recente por UF.
# Aplicavel tanto a listagem do FTP (input pra download) quanto a arquivos
# locais (delete de versoes obsoletas).
# Zips fora do pattern <UF>_YYYYMMDD.zip (ex.: Documentacao_*.zip) saem intactos.
pick_latest_per_uf <- function(zip_files){
  ufs_known <- c(UF_SIGLAS, "SP_Capital", "SP_Exceto_Capital")
  pat <- sprintf("^(%s)_(\\d{8})\\.zip$", paste(ufs_known, collapse = "|"))
  m <- regmatches(basename(zip_files), regexec(pat, basename(zip_files)))

  is_uf_zip <- sapply(m, length) > 0
  uf_zips   <- zip_files[is_uf_zip]
  other     <- zip_files[!is_uf_zip]

  if(length(uf_zips) == 0) return(zip_files)

  uf   <- sapply(m[is_uf_zip], `[`, 2)
  date <- as.integer(sapply(m[is_uf_zip], `[`, 3))

  dt <- data.table::data.table(file = uf_zips, uf = uf, date = date)
  data.table::setorder(dt, uf, -date)
  latest <- dt[, .SD[1L], by = uf]$file

  c(other, latest)
}


# Crosswalk code_tract -> code_weighting (areas de ponderacao 2010), distribuido
# pelo IBGE em Documentacao_microdados_2010.zip. Eh estrato de amostra do censo
# 2010: cada area agrupa N setores. Ate geobr 1.10 essa info vinha de
# read_census_tract(); foi removida; agora puxamos da fonte canonica IBGE.
# Retorna data.table(code_tract numeric, code_weighting numeric).
get_areas_ponderacao_2010 <- function(){

  zip_path <- "./data_raw/tracts/2010/Documentacao_microdados_2010.zip"

  if(!file.exists(zip_path)){
    download_file_censobr(
      file_url = "https://ftp.ibge.gov.br/Censos/Censo_Demografico_2010/Resultados_Gerais_da_Amostra/Microdados/Documentacao.zip",
      dest_dir = dirname(zip_path)
    )
    src <- file.path(dirname(zip_path), "Documentacao.zip")
    if(file.exists(src)) file.rename(src, zip_path)
  }

  # R unzip nao le filenames com bytes nao-ASCII; fallback system unzip.
  out_dir <- file.path(tempdir(), "ap_2010")
  dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
  res <- system2("unzip", c("-o", "-q", shQuote(zip_path), "-d", shQuote(out_dir)))
  if(res != 0) stop("system unzip failed for ", basename(zip_path))

  txt_files <- list.files(out_dir, pattern = "\\.txt$", recursive = TRUE, full.names = TRUE)
  txt_path  <- txt_files[grepl("Composi.+Pondera", txt_files)]
  if(length(txt_path) != 1) stop("Composicao das Areas de Ponderacao.txt nao encontrado")

  # UTF-16LE com BOM, separador TAB. Header: "Area de ponderacao\tSetor".
  # Mantem character: conversao pra numeric acontece downstream em code_cols_to_numeric.
  ap <- read.table(txt_path, sep = "\t", header = TRUE, fileEncoding = "UTF-16LE",
                   colClasses = "character", quote = "", check.names = FALSE)
  data.table::setDT(ap)
  data.table::setnames(ap, c("code_weighting", "code_tract"))

  unlink(out_dir, recursive = TRUE)

  ap[, .(code_tract, code_weighting)]
}


# detect table name from raw IBGE filename (e.g., "PESSOA02_AC.csv" -> "PESSOA")
detect_2010_table_name <- function(file_path){

  # get all tables
  root_names <- basename(file_path)
  root_names <- stringr::str_split(root_names, '_', simplify = TRUE)[,1]
  table_names <- str_replace_all(root_names, "[:digit:]", "") |> unique()
  table_names <- table_names[!grepl("-MG.csv",table_names)]  |> unique()

  return(table_names)

}
