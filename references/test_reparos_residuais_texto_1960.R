# Microlote real e contraprovas; somente pelo runner R isolado.
.libPaths(c("renv/library/windows/R-4.5/x86_64-w64-mingw32", .libPaths()))
Sys.setlocale("LC_CTYPE", "Portuguese_Brazil.utf8")
library(data.table)
library(jsonlite)
setDTthreads(1L)
source("R/microdata_1960_amostra_127.R", encoding = "UTF-8")

proposta <- fromJSON("references/resolucao_residuais_1960_evidencias/texto_propostas.json", simplifyVector = FALSE)
manifesto <- fromJSON("read_guides/1960_amostra_127_reparos_fonte25.json", simplifyVector = FALSE)
novos_ids <- as.integer(sapply(proposta$reparos, `[[`, "linha127"))
manifesto$reparos <- Filter(function(x) !x$linha127 %in% novos_ids, manifesto$reparos)
manifesto$reparos <- c(manifesto$reparos, proposta$reparos)
saida <- tempfile("test_texto_", tmpdir = "tmp/resolver_residuais_registros_1960_20260922/texto")
dir.create(saida)
manifesto_path <- file.path(saida, "manifesto.json")
write_json(manifesto, manifesto_path, auto_unbox = TRUE, pretty = TRUE, null = "null")
dec <- as.data.table(read.csv("read_guides/1960_amostra_127_correcoes.csv", colClasses = "character", fileEncoding = "UTF-8-BOM"))
for(r in proposta$reparos) dec[linha == as.character(r$linha127),
  `:=`(decisao = "reparo_fonte25", texto_corrigido = r$texto_corrigido_proposto)]
danos <- as.integer(unlist(proposta$danos_sem_reparo))
dec[linha %in% as.character(danos), `:=`(decisao = "dano_salto_nao_resolvido", texto_corrigido = "")]
dec_path <- file.path(saida, "decisoes.csv")
write.csv(dec, dec_path, row.names = FALSE, fileEncoding = "UTF-8")

entrada_texto <- function(ids){
  con <- file("data_raw/microdata/1960/amostra_127/HHOLDA.txt", "rb")
  originais <- character(length(ids))
  for(i in seq_along(ids)){
    seek(con, where = (ids[i] - 1) * 64, origin = "start")
    originais[i] <- readChar(con, 62L, useBytes = TRUE)
  }
  close(con)
  p <- file.path(saida, "entrada.txt")
  writeLines(originais, p, useBytes = TRUE)
  x <- read_1960_amostra_127(p)
  x[, linha := as.integer(ids)]
  x
}

if(Sys.getenv("CENSOBR_TESTE_TEXTO_ANTES") == "1"){
  for(n in c(238423L, 540394L, 540461L)){
    erro <- tryCatch(apply_corrections_1960_amostra_127(entrada_texto(n), dec_path, manifesto_path), error = identity)
    stopifnot(inherits(erro, "error"), grepl("geografia|composicao integral", conditionMessage(erro)))
    message("Antes: reparo bloqueado em ", n, " - ", conditionMessage(erro))
  }
} else {
  alvos <- unique(as.integer(unlist(lapply(proposta$reparos, function(x) sapply(x$grupo127, `[[`, "linha")))))
  entrada <- entrada_texto(alvos)
  antes <- copy(entrada)
  resultado <- apply_corrections_1960_amostra_127(entrada, dec_path, manifesto_path)
  stopifnot(identical(entrada, antes), nrow(resultado) == nrow(entrada))
  for(r in proposta$reparos){
    x <- resultado[linha == r$linha127]
    stopifnot(x$texto == r$texto_corrigido_proposto, x$texto_original == r$texto_original,
              substr(x$texto, 1, 27) == substr(x$texto_original, 1, 27),
              substr(x$texto, 29, 62) == substr(x$texto_original, 29, 62))
  }
  stopifnot(substr(resultado[linha == 238423L, texto], 7, 8) == "X7")
  contexto_sem_reparo <- setdiff(alvos, novos_ids)
  stopifnot(identical(resultado[linha %in% contexto_sem_reparo, texto],
                      antes[linha %in% contexto_sem_reparo, texto]))
  resultado_dano <- apply_corrections_1960_amostra_127(entrada_texto(danos), dec_path, manifesto_path)
  stopifnot(nrow(resultado_dano) == 10L, all(resultado_dano$texto == resultado_dano$texto_original),
            all(resultado_dano$censobr_diagnostico == "dano_salto_nao_resolvido"))

  rejeitar_texto <- function(prova, alvo, padrao){
    p <- file.path(saida, "contraprova.json")
    write_json(prova, p, auto_unbox = TRUE, pretty = TRUE, null = "null")
    x <- entrada_texto(alvo); antes_x <- copy(x)
    erro <- tryCatch(apply_corrections_1960_amostra_127(x, dec_path, p), error = identity)
    stopifnot(inherits(erro, "error"), identical(x, antes_x), grepl(padrao, conditionMessage(erro)))
    message("Contraprova: ", conditionMessage(erro))
  }
  ids <- as.integer(sapply(manifesto$reparos, `[[`, "linha127"))
  idx <- match(540394L, ids); idx_pe <- match(238423L, ids)
  p <- manifesto; p$reparos[[idx]]$divergencias_pessoais_preservadas <- list()
  rejeitar_texto(p, 540394L, "divergencia|composicao")
  p <- manifesto; p$reparos[[idx]]$testemunhas_identidade <- p$reparos[[idx]]$testemunhas_identidade[1]
  rejeitar_texto(p, 540394L, "testemunh")
  p <- manifesto; p$reparos[[idx]]$testemunhas_identidade[[1]]$linha127 <- 540391L
  rejeitar_texto(p, 540394L, "testemunh")
  p <- manifesto; p$reparos[[idx_pe]]$geografia_parcial_preservada[[1]]$depois <- "17"
  rejeitar_texto(p, 238423L, "geografia")
  p <- manifesto; p$reparos[[idx_pe]]$testemunhas_identidade[[1]]$campos_ignorados <- list("AGE")
  rejeitar_texto(p, 238423L, "testemunh")
  ruim <- copy(dec); ruim[linha == "760807", texto_corrigido := gsub("9", " ", texto_original, fixed = TRUE)]
  ruim_path <- file.path(saida, "dano_apagado.csv")
  write.csv(ruim, ruim_path, row.names = FALSE, fileEncoding = "UTF-8")
  erro <- tryCatch(apply_corrections_1960_amostra_127(entrada_texto(760807L), ruim_path, manifesto_path), error = identity)
  stopifnot(inherits(erro, "error"), grepl("dano nao resolvido", conditionMessage(erro), fixed = TRUE))
  message("Reparos residuais e danos preservados conferidos: ", saida)
}
