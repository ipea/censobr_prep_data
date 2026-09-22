# Piloto real FN -> SE, somente depois dos relatorios com os pesos atuais.
# Exige autorizacao explicita no processo filho; nao chama targets nem downloads.
# Usar references/rodar_r_isolado_1960.py com --windows-arch e log novo.
if(!identical(Sys.getenv("CENSOBR_AUTORIZAR_PESOS25_PILOTO"), "SIM"))
  stop("piloto de pesos nao autorizado: aguardar liberacao apos os relatorios atuais")
.libPaths(c("renv/library/windows/R-4.5/x86_64-w64-mingw32", .libPaths()))
Sys.setlocale("LC_CTYPE", ".UTF-8")
stopifnot(l10n_info()[["UTF-8"]])
library(data.table)
library(arrow)
setDTthreads(1L)
arrow::set_cpu_count(1L)
arrow::set_io_thread_count(2L)

local({
  out_root <- file.path("tmp/execucao_1960_20260922",
                        paste0("pesos25_piloto_", format(Sys.time(), "%Y%m%d_%H%M%S")))
  if(dir.exists(out_root)) stop("destino do piloto ja existe; nao sobrescrever")
  dir.create(out_root, recursive = TRUE)
  message("PILOTO_DESTINO: ", normalizePath(out_root, winslash = "/"))
  fontes <- c("R/microdata_1960_amostra_127.R", "R/microdata_1960_amostra_25.R",
              "R/microdata_1960_validacao.R", "read_guides/1960_municipios.csv",
              "references/censo_1960_resultados_definitivos_serie_nacional.csv")
  arquivos <- unlist(lapply(c("fn", "se"), function(uf)
    file.path("data_raw/microdata/1960/amostra_25", uf,
              c("domicilios.parquet", "pessoas_geo.parquet", "domicilios_pesos.parquet", "pessoas_pesos.parquet"))))
  manifesto <- data.table(arquivo = c(fontes, arquivos), md5_antes = unname(tools::md5sum(c(fontes, arquivos))))
  if(anyNA(manifesto$md5_antes)) stop("insumo do piloto inexistente ou sem hash")
  fwrite(manifesto, file.path(out_root, "manifesto_antes.csv"))
  capture.output(sessionInfo(), file = file.path(out_root, "sessionInfo.txt"))

  # A instrumentacao vive so neste ambiente: chama o solver original sem mudar
  # controles, limites ou pesos. Registra a matriz efetivamente recebida por ele.
  funcoes <- new.env(parent = globalenv())
  for(f in fontes[grepl("^R/", fontes)]) sys.source(f, envir = funcoes, keep.source = TRUE)
  solver <- funcoes$raking_1960_amostra_127
  pesos_antes <- numeric()
  contexto <- list()
  funcoes$raking_1960_amostra_127 <- function(X, totais, d, limites = NULL, ...){
    if(length(pesos_antes) != nrow(X)) stop("ordem dos domicilios divergiu na auditoria dos controles")
    controles <- data.table(celula = colnames(X), alvo = totais,
      suporte_pessoas = as.numeric(Matrix::colSums(X)),
      suporte_domicilios = as.numeric(Matrix::colSums(X != 0)),
      soma_desenho = as.numeric(Matrix::crossprod(X, d)),
      soma_antes = as.numeric(Matrix::crossprod(X, pesos_antes)))
    controles[, `:=`(UF = contexto$uf, status = "antes_do_solver",
                     alvo_estimado = TRUE,
                     origem = fifelse(grepl("^mun_", celula), "Sinopse municipal reescalada", "Serie Nacional amostral"),
                     soma_depois = NA_real_, residuo_relativo_depois = NA_real_)]
    if(!is.null(limites)) controles[, `:=`(minimo_isolado = limites[1] * soma_desenho,
                                          maximo_isolado = limites[2] * soma_desenho)]
    destino <- file.path(contexto$dir, "controles.csv")
    fwrite(controles, destino)
    tryCatch({
      w <- solver(X, totais, d, limites, ...)
      controles[, `:=`(soma_depois = as.numeric(Matrix::crossprod(X, w)), status = "convergente")]
      controles[, residuo_relativo_depois := (soma_depois - alvo) / alvo]
      fwrite(controles, destino)
      w
    }, error = function(e){
      controles[, `:=`(status = "falha_no_solver", motivo = conditionMessage(e))]
      fwrite(controles, destino)
      stop(e)
    })
  }

  status <- data.table(uf = c("fn", "se"), status = "nao_iniciado", motivo = "")
  tryCatch({
    for(unidade in status$uf){
      status[uf == unidade, status := "em_execucao"]
      fwrite(status, file.path(out_root, "status.csv"))
      base <- file.path("data_raw/microdata/1960/amostra_25", unidade)
      dest <- file.path(out_root, "pesos", unidade)
      diag <- file.path(out_root, "diagnosticos", unidade)
      dir.create(diag, recursive = TRUE)
      contexto <- list(uf = unidade, dir = diag)
      dom_contagens <- as.data.table(arrow::read_parquet(file.path(base, "domicilios.parquet"),
        col_select = c("censobr_idhousehold", "censobr_n_presentes")))
      dom_contagens[, domicilio_fornecido := TRUE]
      pes_contagens <- as.data.table(arrow::read_parquet(file.path(base, "pessoas_geo.parquet"),
        col_select = c("censobr_idhousehold", "V202")))
      diretas <- pes_contagens[, .(n_listadas_direto = .N,
        n_presentes_direto = sum(V202 %in% c(1L, 2L, 5L, 6L)),
        n_presenca_desconhecida = sum(!V202 %in% 1:6)), by = censobr_idhousehold]
      contagens <- merge(dom_contagens, diretas, by = "censobr_idhousehold", all = TRUE)
      contagens[domicilio_fornecido %in% TRUE & is.na(n_listadas_direto),
        `:=`(n_listadas_direto = 0L, n_presentes_direto = 0L, n_presenca_desconhecida = 0L)]
      contagens[, status := fcase(!domicilio_fornecido %in% TRUE, "pessoa_sem_domicilio",
        is.na(censobr_n_presentes), "contagem_domiciliar_ausente",
        n_presenca_desconhecida > 0L, "presenca_desconhecida",
        censobr_n_presentes != n_presentes_direto, "contagem_divergente", default = "confere")]
      fwrite(contagens, file.path(diag, "contagem_presentes_por_domicilio.csv"))
      if(anyDuplicated(dom_contagens$censobr_idhousehold) || anyNA(contagens$censobr_idhousehold) ||
         any(contagens$status != "confere")) stop("contagem domiciliar e contagem direta de presentes nao conferem na UF ", unidade)
      ids <- dom_contagens$censobr_idhousehold
      rm(dom_contagens, pes_contagens, diretas, contagens); gc(verbose = FALSE)
      antes <- as.data.table(arrow::read_parquet(file.path(base, "domicilios_pesos.parquet"),
        col_select = c("censobr_idhousehold", "censobr_weight", "censobr_weight_ibge")))
      if(anyDuplicated(ids) || anyDuplicated(antes$censobr_idhousehold) ||
         !setequal(ids, antes$censobr_idhousehold)) stop("domicilios atuais e entrada nao correspondem na UF ", unidade)
      pesos_antes <- antes[match(ids, censobr_idhousehold), censobr_weight]
      if(any(!is.finite(pesos_antes)) || any(pesos_antes <= 0)) stop("peso atual invalido na UF ", unidade)
      funcoes$validate_definitivos_1960_amostra_25(
        file.path(base, c("domicilios_pesos.parquet", "pessoas_pesos.parquet")), fontes[5],
        out_dir = file.path(diag, "antes"))
      novos <- funcoes$weight_1960_amostra_25(file.path(base, c("domicilios.parquet", "pessoas_geo.parquet")),
        unidade, fontes[4], fontes[5], out_dir = dest)
      depois <- as.data.table(arrow::read_parquet(novos[1],
        col_select = c("censobr_idhousehold", "censobr_weight", "censobr_weight_ibge")))
      if(anyDuplicated(depois$censobr_idhousehold) || !setequal(ids, depois$censobr_idhousehold))
        stop("domicilios mudaram na recalibracao da UF ", unidade)
      comparacao <- merge(antes, depois, by = "censobr_idhousehold", suffixes = c("_antes", "_depois"))
      comparacao[, `:=`(diferenca = censobr_weight_depois - censobr_weight_antes,
                        razao = censobr_weight_depois / censobr_weight_antes)]
      fwrite(comparacao, file.path(diag, "pesos_domicilios_antes_depois.csv"))
      funcoes$validate_definitivos_1960_amostra_25(novos, fontes[5], out_dir = file.path(diag, "depois"))
      status[uf == unidade, status := "concluido_em_staging"]
      fwrite(status, file.path(out_root, "status.csv"))
      rm(antes, depois, comparacao); gc(verbose = FALSE)
    }
  }, error = function(e){
    status[status == "em_execucao", `:=`(status = "falha", motivo = conditionMessage(e))]
    fwrite(status, file.path(out_root, "status.csv"))
    stop(e)
  }, finally = {
    manifesto[, md5_depois := unname(tools::md5sum(arquivo))]
    manifesto[, preservado := !is.na(md5_depois) & md5_antes == md5_depois]
    fwrite(manifesto, file.path(out_root, "manifesto_depois.csv"))
    if(any(!manifesto$preservado)) stop("arquivos de entrada ou codigo mudaram durante o piloto; conferir manifesto")
  })
  message("PILOTO_PESOS25_CONCLUIDO_EM_STAGING: ", normalizePath(out_root, winslash = "/"))
})
