# Evidencia de grupo e campos danificados; executado somente pelo runner isolado.
.libPaths(c("renv/library/windows/R-4.5/x86_64-w64-mingw32", .libPaths()))
Sys.setlocale("LC_CTYPE", "Portuguese_Brazil.utf8")
library(data.table)
library(jsonlite)
library(digest)
setDTthreads(1L)
source("R/microdata_1960_amostra_127.R", encoding = "UTF-8")

dir.create("tmp/fechamento_registros_1960_20260922", recursive = TRUE, showWarnings = FALSE)
saida_guardas <- tempfile("guardas_reparo_", tmpdir = "tmp/fechamento_registros_1960_20260922")
dir.create(saida_guardas)
prova_guardas <- fromJSON("read_guides/1960_amostra_127_reparos_fonte25.json", simplifyVector = FALSE)
dec_guardas <- as.data.table(read.csv("read_guides/1960_amostra_127_correcoes.csv",
  colClasses = "character", fileEncoding = "UTF-8-BOM"))
for(r in prova_guardas$reparos) dec_guardas[linha == as.character(r$linha127),
  `:=`(decisao = "reparo_fonte25", texto_corrigido = r$texto_corrigido_proposto)]
dec_guardas_path <- file.path(saida_guardas, "decisoes.csv")
write.csv(dec_guardas, dec_guardas_path, row.names = FALSE, fileEncoding = "UTF-8")
alvo_guardas <- prova_guardas$reparos[[1]]
writeLines(alvo_guardas$texto_original, file.path(saida_guardas, "alvo.txt"), useBytes = TRUE)
entrada_guardas <- read_1960_amostra_127(file.path(saida_guardas, "alvo.txt"))
entrada_guardas[, linha := as.integer(alvo_guardas$linha127)]

rejeitar_grupo <- function(prova, nome, padrao, entrada = entrada_guardas){
  path <- file.path(saida_guardas, paste0(nome, ".json"))
  write_json(prova, path, auto_unbox = TRUE, pretty = TRUE, null = "null")
  antes <- copy(entrada)
  erro <- tryCatch(apply_corrections_1960_amostra_127(entrada, dec_guardas_path, path), error = identity)
  stopifnot(inherits(erro, "error"), identical(entrada, antes),
            grepl(padrao, conditionMessage(erro), fixed = TRUE))
  message("Guarda de grupo: ", nome, " - ", conditionMessage(erro))
}

raw_hash <- prova_guardas
i_raw <- which(sapply(raw_hash$fontes, `[[`, "arquivo") == "data_raw/microdata/1960/amostra_127/HHOLDA.txt")
raw_hash$fontes[[i_raw]]$sha256 <- strrep("0", 64)
rejeitar_grupo(raw_hash, "hash_hholda", "HHOLDA")

sem_grupo <- prova_guardas; sem_grupo$reparos[[1]]$grupo127 <- list()
rejeitar_grupo(sem_grupo, "grupo127_omitido", "grupo127")

literal127 <- prova_guardas
literal127$reparos[[1]]$grupo127[[1]]$texto <- paste0("99", substr(literal127$reparos[[1]]$grupo127[[1]]$texto, 3, 62))
rejeitar_grupo(literal127, "literal_grupo127", "grupo127")

incompleto25 <- prova_guardas; incompleto25$reparos[[1]]$grupo25 <- incompleto25$reparos[[1]]$grupo25[-3]
rejeitar_grupo(incompleto25, "grupo25_incompleto", "grupo25")

mesmo_grupo_outra_pessoa <- prova_guardas
mesmo_grupo_outra_pessoa$reparos[[1]]$fontes25_possiveis <- list(mesmo_grupo_outra_pessoa$reparos[[1]]$grupo25[[3]])
rejeitar_grupo(mesmo_grupo_outra_pessoa, "outra_pessoa_mesmo_grupo", "correspondencias")

outro_boletim <- prova_guardas
outro_boletim$reparos[[1]]$fontes25_possiveis <- outro_boletim$reparos[[2]]$fontes25_possiveis
rejeitar_grupo(outro_boletim, "outro_boletim", "chave")

legivel <- prova_guardas
legivel$reparos[[1]]$propostas <- c(legivel$reparos[[1]]$propostas,
  list(list(campo = "V209", inicio = 29L, fim = 29L,
    antes = substr(alvo_guardas$texto_original, 29, 29),
    depois = substr(alvo_guardas$texto_original, 29, 29))))
rejeitar_grupo(legivel, "campo_legivel", "danificado")

antes_guardas <- copy(entrada_guardas)
ok_guardas <- apply_corrections_1960_amostra_127(entrada_guardas, dec_guardas_path)
stopifnot(identical(entrada_guardas, antes_guardas), nrow(ok_guardas) == 1L,
          ok_guardas$texto == alvo_guardas$texto_corrigido_proposto)

ids_guardas <- as.integer(sapply(prova_guardas$reparos, `[[`, "linha127"))
idx_parcial <- match(803760L, ids_guardas)
if(!is.na(idx_parcial)){
  parcial <- prova_guardas
  i_campo <- which(sapply(parcial$reparos[[idx_parcial]]$propostas, `[[`, "campo") == "V112")
  parcial$reparos[[idx_parcial]]$propostas[[i_campo]]$depois <- "17"
  path <- file.path(saida_guardas, "cartao_parcial.txt")
  writeLines(parcial$reparos[[idx_parcial]]$texto_original, path, useBytes = TRUE)
  entrada_parcial <- read_1960_amostra_127(path)
  entrada_parcial[, linha := 803760L]
  rejeitar_grupo(parcial, "digito_legivel_em_campo_parcial", "digitos legiveis", entrada_parcial)
}

cartoes_guardas <- Filter(function(x) substr(x$texto_original, 17, 17) == "1", prova_guardas$reparos)
if(length(cartoes_guardas)){
  path <- file.path(saida_guardas, "cartoes.txt")
  writeLines(sapply(cartoes_guardas, `[[`, "texto_original"), path, useBytes = TRUE)
  entrada_cartoes <- read_1960_amostra_127(path)
  entrada_cartoes[, linha := as.integer(sapply(cartoes_guardas, `[[`, "linha127"))]
  antes_cartoes <- copy(entrada_cartoes)
  resultado_cartoes <- apply_corrections_1960_amostra_127(entrada_cartoes, dec_guardas_path)
  stopifnot(identical(entrada_cartoes, antes_cartoes), nrow(resultado_cartoes) == length(cartoes_guardas),
            identical(resultado_cartoes$texto_original, entrada_cartoes$texto),
            identical(resultado_cartoes$texto, sapply(cartoes_guardas, `[[`, "texto_corrigido_proposto")))
  parseado_cartoes <- parse_1960_amostra_127(resultado_cartoes,
    "read_guides/readguide_1960_amostra_127_familias.csv", "read_guides/readguide_1960_amostra_127_pessoas.csv")
  stopifnot(nrow(parseado_cartoes$familias) == length(cartoes_guardas), nrow(parseado_cartoes$pessoas) == 0L)
  for(reparo in cartoes_guardas) for(campo in reparo$propostas)
    stopifnot(parseado_cartoes$familias[linha == reparo$linha127][[campo$campo]] == campo$depois)
}
message("Guardas adicionais dos reparos conferidas: ", saida_guardas)
