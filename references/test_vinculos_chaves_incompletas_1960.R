# Dois vinculos reais: antes/depois, texto preservado e contraprovas.
# Executar somente pelo runner isolado; nunca targets.
.libPaths(c("renv/library/windows/R-4.5/x86_64-w64-mingw32", .libPaths()))
Sys.setlocale("LC_CTYPE", "Portuguese_Brazil.utf8")
library(data.table)
library(jsonlite)
library(digest)
setDTthreads(1L)
source("R/microdata_1960_amostra_127.R", encoding = "UTF-8")

base_chaves <- "tmp/resolucao_residuais_registros_1960_20260922"
dir.create(base_chaves, recursive = TRUE, showWarnings = FALSE)
saida_chaves <- tempfile("vinculos_chaves_", tmpdir = base_chaves)
dir.create(saida_chaves)
prova_path_chaves <- "references/resolucao_residuais_1960_evidencias/vinculos_chaves_incompletas.json"
prova_chaves <- fromJSON(prova_path_chaves, simplifyVector = FALSE)
stopifnot(length(prova_chaves$casos) == 2L,
          setequal(sapply(prova_chaves$casos, `[[`, "linha"), c(142402L, 259248L)))
alvos_chaves <- sort(unique(unlist(lapply(prova_chaves$casos, function(x)
  c(x$linha_familia, sapply(x$pessoas127, `[[`, "linha"))))))
stopifnot(length(alvos_chaves) == 17L)
raw_chaves <- "data_raw/microdata/1960/amostra_127/HHOLDA.txt"
hash_raw_chaves <- digest(file = raw_chaves, algo = "sha256")
hash_prova_chaves <- digest(file = prova_path_chaves, algo = "sha256")
con_chaves <- file(raw_chaves, "rb")
textos_chaves <- character(length(alvos_chaves))
for(i in seq_along(alvos_chaves)){
  seek(con_chaves, where = (alvos_chaves[i] - 1) * 64, origin = "start")
  textos_chaves[i] <- readChar(con_chaves, 62L, useBytes = TRUE)
}
close(con_chaves)
lote_path_chaves <- file.path(saida_chaves, "microlote.txt")
writeLines(textos_chaves, lote_path_chaves, useBytes = TRUE)
linhas_chaves <- read_1960_amostra_127(lote_path_chaves)
linhas_chaves[, linha := alvos_chaves]
linhas_chaves <- apply_corrections_1960_amostra_127(linhas_chaves,
  "read_guides/1960_amostra_127_correcoes.csv")
entrada_chaves <- parse_1960_amostra_127(linhas_chaves,
  "read_guides/readguide_1960_amostra_127_familias.csv",
  "read_guides/readguide_1960_amostra_127_pessoas.csv")
stopifnot(nrow(entrada_chaves$familias) == 2L, nrow(entrada_chaves$pessoas) == 15L)
antes_chaves <- copy(entrada_chaves)
dec_chaves <- as.data.table(read.csv("read_guides/1960_amostra_127_vinculos.csv",
  colClasses = "character", fileEncoding = "UTF-8", strip.white = FALSE))
novas_linhas_chaves <- c("142402", "259248")
stopifnot(nrow(dec_chaves[linha %in% novas_linhas_chaves]) == 2L)

exigir_erro_chaves <- function(x, nome, padrao, dec_path = "read_guides/1960_amostra_127_vinculos.csv"){
  antes <- copy(x)
  erro <- tryCatch(build_families_1960_amostra_127(x, file.path(saida_chaves, nome), dec_path), error = identity)
  stopifnot(inherits(erro, "error"), grepl(padrao, conditionMessage(erro), fixed = TRUE), identical(x, antes))
  message(nome, ": ", conditionMessage(erro))
}

# Reproduzir a falta das duas decisoes anteriores, sem editar o manifesto real.
sem_path_chaves <- file.path(saida_chaves, "manifesto_antes.csv")
write.csv(dec_chaves[!linha %in% novas_linhas_chaves], sem_path_chaves,
  row.names = FALSE, fileEncoding = "UTF-8")
exigir_erro_chaves(entrada_chaves, "antes_sem_decisoes", "vinculos_a_revisar", sem_path_chaves)
pendentes_chaves <- fread(file.path(saida_chaves, "antes_sem_decisoes", "vinculos_a_revisar.csv"))
stopifnot(setequal(pendentes_chaves$linha, as.integer(novas_linhas_chaves)))

depois_chaves <- build_families_1960_amostra_127(entrada_chaves,
  file.path(saida_chaves, "depois_com_decisoes"))
stopifnot(identical(entrada_chaves, antes_chaves), nrow(depois_chaves$pessoas) == 15L,
          nrow(depois_chaves$familias) == 2L)
cols_chaves <- names(entrada_chaves$pessoas)
stopifnot(identical(as.data.frame(depois_chaves$pessoas[, ..cols_chaves]),
                    as.data.frame(entrada_chaves$pessoas)))
for(caso in prova_chaves$casos){
  dest <- depois_chaves$familias[linha == caso$linha_familia, censobr_idfamily]
  membros <- depois_chaves$pessoas[censobr_idfamily == dest]
  stopifnot(nrow(membros) == caso$n_pessoas,
            setequal(membros$linha, as.integer(sapply(caso$pessoas127, `[[`, "linha"))),
            membros[linha == caso$linha, censobr_familia_origem] == "reconciliada_25",
            membros[linha == caso$linha, pasta] == substr(caso$pessoas127[[1L]]$corrigido, 9L, 13L))
}

# A prova e literal: uma resposta ou destino adulterado nao herda a autorizacao.
texto_alterado_chaves <- copy(entrada_chaves)
texto_alterado_chaves$pessoas[linha == 142402L, texto_corrigido := paste0(substr(texto_corrigido, 1L, 21L), "05", substr(texto_corrigido, 24L, 62L))]
exigir_erro_chaves(texto_alterado_chaves, "texto_alterado", "conteudo diverge")
destino_ausente_chaves <- copy(entrada_chaves)
destino_ausente_chaves$familias <- destino_ausente_chaves$familias[linha != 142817L]
exigir_erro_chaves(destino_ausente_chaves, "destino_ausente", "cartao de destino")
dec_errada_chaves <- copy(dec_chaves)
dec_errada_chaves[linha == "142402", linha_familia := "259657"]
dec_errada_path_chaves <- file.path(saida_chaves, "destino_errado.csv")
write.csv(dec_errada_chaves, dec_errada_path_chaves, row.names = FALSE, fileEncoding = "UTF-8")
exigir_erro_chaves(entrada_chaves, "destino_errado", "conteudo diverge", dec_errada_path_chaves)

stopifnot(hash_raw_chaves == digest(file = raw_chaves, algo = "sha256"),
          hash_prova_chaves == digest(file = prova_path_chaves, algo = "sha256"))
write_json(list(vinculos = 2L, pessoas_preservadas = 15L, familias = 2L,
  texto_e_respostas_preservados = TRUE, antes_bloqueado = TRUE, contraprovas_bloqueadas = 3L),
  file.path(saida_chaves, "conferencia.json"), pretty = TRUE, auto_unbox = TRUE)
message("Dois vinculos de chave incompleta conferidos: ", saida_chaves)
