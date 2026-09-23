# Conferencia tecnica da entrega; nao homologa pesos, desenho ou variancias.
conferir_publicacao_1960 <- function(paths, validacao_path, definitivos_path,
                                      schema_path = "schemas/censobr_types.csv",
                                      fontes_path = paste0(validacao_path, ".fontes.json"),
                                      out_dir = "./data_raw/microdata/1960/compilada"){
  message("Conferindo integridade da exportacao de 1960")
  arquivos <- sort(normalizePath(as.character(unlist(paths, use.names = FALSE)), winslash = "/", mustWork = TRUE))
  fontes <- jsonlite::read_json(fontes_path, simplifyVector = TRUE)
  insumos <- sort(c(arquivos, normalizePath(definitivos_path, winslash = "/", mustWork = TRUE)))
  codigo_validacao <- digest::digest(list(body(validate_1960), body(tabular_pessoas_validacao_1960),
    body(tabular_domicilios_validacao_1960), body(completar_validacao_pessoas_1960),
    UF_1960_AMOSTRA_25, UF_1960_AMOSTRA_127), algo = "sha256")
  if(!identical(insumos, fontes$arquivos) || !identical(codigo_validacao, fontes$codigo) ||
     !identical(unname(sapply(insumos, digest::digest, file = TRUE, algo = "sha256")), fontes$sha256) ||
     !identical(digest::digest(validacao_path, file = TRUE, algo = "sha256"), fontes$relatorio_sha256))
    stop("Validacao desatualizada: insumos, codigo ou relatorio mudaram.")

  ufs <- c(UF_1960_AMOSTRA_25, UF_1960_AMOSTRA_127)
  for(arquivo in c("domicilios.parquet", "pessoas.parquet")){
    unidades <- basename(dirname(arquivos[basename(arquivos) == arquivo]))
    if(anyDuplicated(unidades) || !setequal(unidades, names(ufs)))
      stop("Exportacao exige um par de arquivos para cada UF.")
  }
  if(length(arquivos) != 2L * length(ufs)) stop("Arquivos fora da particao de UFs.")

  def <- data.table::fread(definitivos_path, encoding = "UTF-8")
  def[nivel == "brasil", uf60 := 999L]
  grade <- def[nivel %in% c("uf", "brasil") &
    ((tabela %in% c(32L, 33L, 34L, 37L, 40L) & sexo %in% c("homens", "mulheres")) | tabela == 7L),
    .(uf60, tabela, item, sexo, medida, publicado = valor)]
  grade[is.na(sexo), sexo := ""][is.na(medida), medida := ""]
  cmp <- data.table::fread(validacao_path, encoding = "UTF-8")
  cmp[is.na(sexo), sexo := ""][is.na(medida), medida := ""]
  chaves <- c("uf60", "tabela", "item", "sexo", "medida")
  cobertura <- grade[, .(pessoas = sum(tabela != 7L), domicilios = sum(tabela == 7L)), by = uf60]
  if(!setequal(cobertura$uf60, c(unname(ufs), 999L)) ||
     any(cobertura$pessoas != 54L | cobertura$domicilios != 6L) || anyDuplicated(grade[, ..chaves]))
    stop("Gabarito incompleto ou duplicado para a grade examinada.")
  if(anyDuplicated(cmp[, ..chaves]) || nrow(cmp) != nrow(grade) ||
     nrow(grade[!cmp, on = chaves]) || nrow(cmp[!grade, on = chaves]))
    stop("Grade de validacao incompleta ou duplicada.")
  referencia <- merge(grade, cmp[, c(chaves, "publicado"), with = FALSE], by = chaves)
  if(anyNA(referencia$publicado.x) || anyNA(referencia$publicado.y) ||
     any(referencia$publicado.x != referencia$publicado.y)) stop("Referencia do relatorio diverge do gabarito.")
  if(any(!cmp$status_celula %in% c("observada", "sem_observacoes")) || any(!is.finite(cmp$valor)))
    stop("Validacao tem comparacoes nao calculadas ou incompletas.")
  contadores <- c("n_pesos_ausentes", "n_sem_classificacao", "n_pesos_ausentes_sem_classificacao",
                 "n_domicilios_sem_lista", "n_pessoas_sem_domicilio")
  if(anyNA(cmp[, ..contadores]) || any(as.matrix(cmp[, ..contadores]) != 0L))
    stop("Validacao registra pesos, classificacoes ou vinculos pendentes.")

  # Uma categoria sem pessoas na amostra continua na grade, mesmo se publicada positiva.
  tipos <- data.table::fread(schema_path)
  totais <- list()
  for(unidade in names(ufs)){
    par <- arquivos[basename(dirname(arquivos)) == unidade]
    d_path <- par[basename(par) == "domicilios.parquet"]
    p_path <- par[basename(par) == "pessoas.parquet"]
    for(dataset in c("households", "population")){
      caminho <- if(dataset == "households") d_path else p_path
      colunas <- names(arrow::open_dataset(caminho))
      esperadas <- if(dataset == "households") COLUNAS_1960_DOM else COLUNAS_1960_PES
      dataset_id <- paste0("1960_", dataset)
      esquema <- tipos[tipos$dataset == dataset_id]
      if(!setequal(colunas, esperadas)) stop("Colunas compiladas divergentes: ", unidade, "/", dataset)
      if(anyDuplicated(esquema$coluna) || !all(colunas %in% esquema$coluna) ||
         any(!esquema$tipo_alvo %in% c("string", "double", "int32")))
        stop("Tipos nao medidos ou esquema incompleto: ", unidade, "/", dataset)
    }
    cols <- c("UF", "censobr_idhousehold", "censobr_weight", "censobr_amostra",
              "censobr_familia_origem", "censobr_diagnostico")
    d <- data.table::as.data.table(arrow::read_parquet(d_path, col_select = c(cols, "censobr_convivente_isolada")))
    p <- data.table::as.data.table(arrow::read_parquet(p_path, col_select = c(cols, "censobr_idperson", "censobr_idfamily")))
    amostra <- if(unidade %in% names(UF_1960_AMOSTRA_25)) "25%" else "1,27%"
    for(z in list(d, p)){
      if(!nrow(z) || any(!z$UF %in% ufs[[unidade]]) || any(!z$censobr_amostra %in% amostra))
        stop("UF ou amostra incompatível: ", unidade)
      if(anyNA(z$censobr_idhousehold) || any(!is.finite(z$censobr_weight) | z$censobr_weight <= 0))
        stop("Identificacao domiciliar ou peso invalido: ", unidade)
      if(any(grepl("(^|[+])(corrompida|dano_salto_nao_resolvido)([+]|$)", z$censobr_diagnostico)) ||
         (amostra == "1,27%" && any(!z$censobr_familia_origem %in% c("registro", "reconciliada_25"))))
        stop("Registros com dano ou vinculo pendente: ", unidade)
    }
    if(anyDuplicated(d$censobr_idhousehold) || anyNA(p$censobr_idperson) ||
       anyDuplicated(p$censobr_idperson) || anyNA(p$censobr_idfamily))
      stop("Identificadores ausentes ou duplicados: ", unidade)
    identificadores <- c(d$censobr_idhousehold, p$censobr_idperson, p$censobr_idfamily, p$censobr_idhousehold)
    inicio <- ufs[[unidade]] * 1e7
    if(any(!is.finite(identificadores) | identificadores != floor(identificadores) |
           identificadores <= inicio | identificadores >= inicio + 1e7))
      stop("Identificadores fora do intervalo nacional da UF: ", unidade)
    if(any(d$censobr_convivente_isolada %in% TRUE) ||
       !setequal(p$censobr_idhousehold, d$censobr_idhousehold))
      stop("Pessoas ou domicilios sem vinculo completo: ", unidade)
    domicilios <- match(p$censobr_idhousehold, d$censobr_idhousehold)
    if(any(abs(p$censobr_weight - d$censobr_weight[domicilios]) > 1e-8 * p$censobr_weight))
      stop("Peso pessoal diverge do peso domiciliar: ", unidade)
    familias <- p[, .(domicilios = data.table::uniqueN(censobr_idhousehold)), by = censobr_idfamily]
    if(any(familias$domicilios != 1L))
      stop("Uma familia aparece em mais de um domicilio: ", unidade)
    totais[[unidade]] <- data.table::data.table(uf = unidade, domicilios = nrow(d), pessoas = nrow(p))
    rm(d, p, z, identificadores, familias); gc(verbose = FALSE)
  }

  codigo <- digest::digest(list(body(conferir_publicacao_1960), body(save_microdata_1960),
    body(validate_1960), body(tabular_pessoas_validacao_1960),
    body(tabular_domicilios_validacao_1960), body(completar_validacao_pessoas_1960),
    body(cast_censobr_types), body(relocate_geo_cols_censobr),
    UF_1960_AMOSTRA_25, UF_1960_AMOSTRA_127, COLUNAS_1960_DOM, COLUNAS_1960_PES,
    GEO_COLS_CENSOBR, GEO_COLS_HIST_1960), algo = "sha256")
  provas <- sort(c(insumos, normalizePath(c(validacao_path, fontes_path, schema_path), winslash = "/", mustWork = TRUE)))
  conferencia <- list(
    integridade_tecnica            = TRUE,
    pesos_e_variancias_homologados = FALSE,
    escopo                         = "Integridade dos arquivos e completude da grade; nao equivale a homologacao metodologica.",
    microdados                     = arquivos,
    schema                         = normalizePath(schema_path, winslash = "/", mustWork = TRUE),
    arquivos                       = provas,
    sha256                         = unname(sapply(provas, digest::digest, file = TRUE, algo = "sha256")),
    codigo                         = codigo,
    contagens                      = data.table::rbindlist(totais),
    comparacoes                    = nrow(cmp),
    sem_observacoes                = sum(cmp$status_celula == "sem_observacoes"),
    diferencas_nao_nulas           = sum(cmp$dif != 0, na.rm = TRUE))
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  saida <- file.path(out_dir, "conferencia_publicacao.json")
  jsonlite::write_json(conferencia, saida, auto_unbox = TRUE, pretty = TRUE)
  saida
}
