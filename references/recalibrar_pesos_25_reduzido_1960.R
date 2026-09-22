# Uma UF, mesmas funcoes e controles, entradas/saidas AUXILIARES PARCIAIS.
# Nao executar diretamente: o orquestrador Python mede memoria e preserva hashes.
if(!identical(Sys.getenv("CENSOBR_AUTORIZAR_PESOS25_REDUZIDO"), "SIM"))
  stop("recalibracao reduzida nao autorizada")
.libPaths(c("renv/library/windows/R-4.5/x86_64-w64-mingw32", .libPaths()))
Sys.setlocale("LC_CTYPE", ".UTF-8")
stopifnot(l10n_info()[["UTF-8"]])
library(data.table)
library(arrow)
setDTthreads(1L)
arrow::set_cpu_count(1L)
arrow::set_io_thread_count(2L)

local({
  unidade <- Sys.getenv("CENSOBR_PESOS25_UF")
  raiz <- Sys.getenv("CENSOBR_PESOS25_RAIZ")
  if(!nzchar(raiz) || !dir.exists(raiz)) stop("raiz auxiliar inexistente")
  funcoes <- new.env(parent = globalenv())
  fontes <- c("R/microdata_1960_amostra_127.R", "R/microdata_1960_amostra_25.R", "R/microdata_1960_validacao.R")
  for(f in fontes) sys.source(f, envir = funcoes, keep.source = TRUE)
  if(!unidade %in% names(funcoes$UF_1960_AMOSTRA_25)) stop("UF invalida")
  base <- file.path("data_raw/microdata/1960/amostra_25", unidade)
  entrada <- file.path(raiz, "entradas_parciais", unidade)
  dest <- file.path(raiz, "saidas_parciais", unidade)
  diag <- file.path(raiz, "diagnosticos", unidade)
  if(dir.exists(dest)) stop("saida da UF ja existe; nao sobrescrever")
  dir.create(diag, recursive = TRUE, showWarnings = FALSE)
  definitivo <- "references/censo_1960_resultados_definitivos_serie_nacional.csv"
  municipios <- "read_guides/1960_municipios.csv"
  capture.output(sessionInfo(), file = file.path(diag, "sessionInfo.txt"))

  # Recontagem independente imediata, antes de usar a contagem domiciliar.
  dom <- as.data.table(arrow::read_parquet(file.path(entrada, "domicilios.parquet"),
    col_select = c("censobr_idhousehold", "censobr_n_presentes")))
  pes <- as.data.table(arrow::read_parquet(file.path(entrada, "pessoas_geo.parquet"),
    col_select = c("censobr_idhousehold", "V202")))
  dom[, domicilio_fornecido := TRUE]
  diretas <- pes[, .(n_listadas_direto = .N,
    n_presentes_direto = sum(V202 %in% c(1L, 2L, 5L, 6L)),
    n_presenca_desconhecida = sum(!V202 %in% 1:6)), by = censobr_idhousehold]
  contagens <- merge(dom, diretas, by = "censobr_idhousehold", all = TRUE)
  contagens[domicilio_fornecido %in% TRUE & is.na(n_listadas_direto),
    `:=`(n_listadas_direto = 0L, n_presentes_direto = 0L, n_presenca_desconhecida = 0L)]
  contagens[, status := fcase(!domicilio_fornecido %in% TRUE, "pessoa_sem_domicilio",
    is.na(censobr_n_presentes), "contagem_domiciliar_ausente",
    n_presenca_desconhecida > 0L, "presenca_desconhecida",
    censobr_n_presentes != n_presentes_direto, "contagem_divergente", default = "confere")]
  fwrite(contagens, file.path(diag, "contagem_presentes_por_domicilio.csv"))
  if(anyDuplicated(dom$censobr_idhousehold) || anyNA(contagens$censobr_idhousehold) || any(contagens$status != "confere"))
    stop("contagem domiciliar e contagem direta nao conferem: ", unidade)
  ids <- dom$censobr_idhousehold
  rm(dom, pes, diretas, contagens); gc(verbose = FALSE)
  antes <- as.data.table(arrow::read_parquet(file.path(base, "domicilios_pesos.parquet"),
    col_select = c("censobr_idhousehold", "censobr_weight", "censobr_weight_ibge")))
  if(anyDuplicated(antes$censobr_idhousehold) || !setequal(ids, antes$censobr_idhousehold))
    stop("identificadores de entrada e pesos atuais divergem")
  pesos_antes <- antes[match(ids, censobr_idhousehold), censobr_weight]
  if(any(!is.finite(pesos_antes)) || any(pesos_antes <= 0)) stop("peso anterior invalido")

  # Encapsula somente a instrumentacao. Solver, limites e matriz nao mudam.
  solver <- funcoes$raking_1960_amostra_127
  funcoes$raking_1960_amostra_127 <- function(X, totais, d, limites = NULL, ...){
    if(length(pesos_antes) != nrow(X)) stop("ordem domiciliar divergiu nos controles")
    controles <- data.table(celula = colnames(X), alvo = totais,
      suporte_pessoas = as.numeric(Matrix::colSums(X)),
      suporte_domicilios = as.numeric(Matrix::colSums(X != 0)),
      soma_desenho = as.numeric(Matrix::crossprod(X, d)),
      soma_antes = as.numeric(Matrix::crossprod(X, pesos_antes)))
    controles[, `:=`(UF = unidade, status = "antes_do_solver", alvo_estimado = TRUE,
      origem = fifelse(grepl("^mun_", celula), "Sinopse municipal reescalada", "Serie Nacional amostral"),
      soma_depois = NA_real_, residuo_relativo_depois = NA_real_)]
    if(!is.null(limites)) controles[, `:=`(minimo_isolado = limites[1] * soma_desenho,
      maximo_isolado = limites[2] * soma_desenho)]
    arquivo <- file.path(diag, "controles.csv")
    fwrite(controles, arquivo)
    tryCatch({
      w <- solver(X, totais, d, limites, ...)
      controles[, `:=`(soma_depois = as.numeric(Matrix::crossprod(X, w)), status = "convergente")]
      controles[, residuo_relativo_depois := (soma_depois - alvo) / alvo]
      fwrite(controles, arquivo)
      w
    }, error = function(e){
      controles[, `:=`(status = "falha_no_solver", motivo = conditionMessage(e))]
      fwrite(controles, arquivo)
      stop(e)
    })
  }
  funcoes$validate_definitivos_1960_amostra_25(
    file.path(base, c("domicilios_pesos.parquet", "pessoas_pesos.parquet")), definitivo,
    out_dir = file.path(diag, "antes"))
  novos <- funcoes$weight_1960_amostra_25(
    file.path(entrada, c("domicilios.parquet", "pessoas_geo.parquet")), unidade,
    municipios, definitivo, out_dir = dest)
  depois <- as.data.table(arrow::read_parquet(novos[1],
    col_select = c("censobr_idhousehold", "censobr_weight", "censobr_weight_ibge")))
  if(anyDuplicated(depois$censobr_idhousehold) || !setequal(ids, depois$censobr_idhousehold))
    stop("domicilios mudaram durante a recalibracao")
  comparacao <- merge(antes, depois, by = "censobr_idhousehold", suffixes = c("_antes", "_depois"))
  comparacao[, `:=`(diferenca = censobr_weight_depois - censobr_weight_antes,
    razao = censobr_weight_depois / censobr_weight_antes)]
  fwrite(comparacao, file.path(diag, "pesos_domicilios_antes_depois.csv"))
  rm(antes, depois, comparacao); gc(verbose = FALSE)
  funcoes$validate_definitivos_1960_amostra_25(novos, definitivo, out_dir = file.path(diag, "depois"))
  message("UF_REDUZIDA_CONCLUIDA_EM_STAGING: ", unidade)
})
