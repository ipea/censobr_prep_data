# Microlote das decisoes: nunca escreve nos originais ou nos manifestos de producao.
.libPaths(c("renv/library/windows/R-4.5/x86_64-w64-mingw32", .libPaths()))
Sys.setlocale("LC_CTYPE", "Portuguese_Brazil.utf8")
library(data.table)
library(jsonlite)
library(digest)
setDTthreads(1L)
source("R/microdata_1960_amostra_127.R", encoding = "UTF-8")
base <- "tmp/fechamento_registros_1960_20260922"
dir.create(base, recursive = TRUE, showWarnings = FALSE)
saida <- tempfile("reparos_", tmpdir = base)
dir.create(saida)
evidencias <- fromJSON("read_guides/1960_amostra_127_reparos_fonte25.json", simplifyVector = FALSE)
alvos <- as.integer(sapply(evidencias$reparos, `[[`, "linha127"))
con <- file("data_raw/microdata/1960/amostra_127/HHOLDA.txt", "rb")
texto <- character(length(alvos))
for(i in seq_along(alvos)){
  seek(con, where = (alvos[i] - 1) * 64, origin = "start")
  texto[i] <- readChar(con, 62L, useBytes = TRUE)
}
close(con)
writeLines(texto, file.path(saida, "microlote.txt"), useBytes = TRUE)
linhas <- read_1960_amostra_127(file.path(saida, "microlote.txt"))
linhas[, linha := alvos]
dec <- as.data.table(read.csv("read_guides/1960_amostra_127_correcoes.csv", colClasses = "character", fileEncoding = "UTF-8-BOM"))
for(reparo in evidencias$reparos) dec[linha == as.character(reparo$linha127),
  `:=`(decisao = "reparo_fonte25", texto_corrigido = reparo$texto_corrigido_proposto)]
dec_path <- file.path(saida, "decisoes.csv")
write.csv(dec, dec_path, row.names = FALSE, fileEncoding = "UTF-8")

# Mesmo numero de linha nao autoriza aplicar uma decisao a outro texto.
adulterada <- copy(linhas[1])
adulterada[, texto := paste0("00", substr(texto, 3, 62))]
erro <- tryCatch(apply_corrections_1960_amostra_127(adulterada, dec_path), error = identity)
stopifnot(inherits(erro, "error"), grepl("texto original", conditionMessage(erro), fixed = TRUE))

antes <- copy(linhas)
for(quantidade in c(1L, length(alvos))){
  resultado <- apply_corrections_1960_amostra_127(linhas[seq_len(quantidade)], dec_path)
  stopifnot(identical(antes, linhas), nrow(resultado) == quantidade,
            identical(resultado$texto_original, texto[seq_len(quantidade)]),
            all(resultado$censobr_diagnostico == "reparo_fonte25"))
  for(i in seq_len(quantidade)) stopifnot(resultado$texto[i] == evidencias$reparos[[i]]$texto_corrigido_proposto)
}
parseado <- parse_1960_amostra_127(resultado, "read_guides/readguide_1960_amostra_127_familias.csv",
                                  "read_guides/readguide_1960_amostra_127_pessoas.csv")
for(reparo in evidencias$reparos) for(campo in reparo$propostas){
  tabela <- if(substr(reparo$texto_original, 17, 17) == "1") parseado$familias else parseado$pessoas
  stopifnot(tabela[linha == reparo$linha127][[campo$campo]] == campo$depois)
}
fwrite(parseado$pessoas, file.path(saida, "pessoas_reparadas.csv"), bom = TRUE)
fwrite(parseado$familias, file.path(saida, "familias_reparadas.csv"), bom = TRUE)

falha_reparo <- function(manifesto, nome){
  path <- file.path(saida, paste0(nome, ".json"))
  write_json(manifesto, path, auto_unbox = TRUE, pretty = TRUE, null = "null")
  pequeno <- copy(linhas[1]); antes_pequeno <- copy(pequeno)
  erro <- tryCatch(apply_corrections_1960_amostra_127(pequeno, dec_path, path), error = identity)
  stopifnot(inherits(erro, "error"), identical(pequeno, antes_pequeno))
  message("Bloqueio de reparo: ", nome, " - ", conditionMessage(erro))
}
sem_fonte <- evidencias; sem_fonte$reparos[[1]]$fontes25_possiveis <- list()
falha_reparo(sem_fonte, "sem_fonte")
sem_decisao <- evidencias; sem_decisao$reparos <- sem_decisao$reparos[-1]
falha_reparo(sem_decisao, "sem_decisao")
duplicado <- evidencias; duplicado$reparos <- c(duplicado$reparos, duplicado$reparos[1])
falha_reparo(duplicado, "decisao_duplicada")
hash <- evidencias
for(i in seq_along(hash$fontes)) hash$fontes[[i]]$sha256 <- strrep("0", 64)
falha_reparo(hash, "hash_divergente")
literal <- evidencias; literal$reparos[[1]]$fontes25_possiveis[[1]]$texto <- strrep("0", 54)
falha_reparo(literal, "literal_divergente")
valor <- evidencias; valor$reparos[[1]]$propostas[[1]]$depois <- "1"
falha_reparo(valor, "valor_sem_apoio")
posicao <- evidencias; posicao$reparos[[1]]$propostas[[1]]$inicio <- 27L
falha_reparo(posicao, "posicao_alterada")
sem_campo <- evidencias; sem_campo$reparos[[1]]$propostas <- list()
falha_reparo(sem_campo, "sem_campos_autorizados")
message("Reparos localizados conferidos: ", saida)
