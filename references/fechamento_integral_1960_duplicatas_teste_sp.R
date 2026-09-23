.libPaths(c("renv/library/windows/R-4.5/x86_64-w64-mingw32", .libPaths()))
Sys.setlocale("LC_CTYPE", "Portuguese_Brazil.utf8")
library(data.table)
library(jsonlite)
library(digest)
setDTthreads(1L)
source("R/microdata_1960_amostra_127.R", encoding = "UTF-8")

prova_path <- "references/fechamento_integral_1960_evidencias/duplicata_sp_composta.json"
prova <- fromJSON(prova_path, simplifyVector = FALSE)
manifesto_path <- "read_guides/1960_amostra_127_duplicatas.csv"
raw_path <- "data_raw/microdata/1960/amostra_127/HHOLDA.txt"
hash_antes <- sapply(c(manifesto_path, raw_path, prova_path), function(path) digest(file = path, algo = "sha256"))
for(fonte in prova$fontes){
  stopifnot(identical(digest(file = fonte$arquivo, algo = "sha256"), fonte$sha256))
}
novas <- rbindlist(prova$decisoes)
stopifnot(nrow(novas) == 2L, all(novas$acao == "manter"), all(novas$n_antes == "2"),
          all(novas$n_manter == "2"), identical(as.integer(novas$linha), c(773911L, 773913L)))
manifesto <- as.data.table(read.csv(manifesto_path, colClasses = "character",
  strip.white = FALSE, fileEncoding = "UTF-8", stringsAsFactors = FALSE))
for(campo in names(novas)){
  comuns <- intersect(manifesto$linha, novas$linha)
  stopifnot(identical(manifesto[[campo]][match(comuns, manifesto$linha)], novas[[campo]][match(comuns, novas$linha)]))
}
dir.create("tmp/fechamento_integral_1960/duplicatas", recursive = TRUE, showWarnings = FALSE)
saida <- tempfile("teste_sp_", tmpdir = "tmp/fechamento_integral_1960/duplicatas")
dir.create(saida)
alvos <- 773909:773913
con <- file(raw_path, "rb")
texto <- sapply(alvos, function(linha){
  seek(con, where = (linha - 1) * 64, origin = "start")
  rawToChar(readBin(con, what = "raw", n = 62L))
})
close(con)
stopifnot(identical(texto, c(prova$casos[["773909"]]$cartao$original,
  sapply(prova$casos[["773909"]]$pessoas, `[[`, "original"))))
lote <- file.path(saida, "lote5.txt")
writeLines(texto, lote, useBytes = TRUE)
linhas <- read_1960_amostra_127(lote)
linhas[, linha := as.integer(alvos)]
linhas <- apply_corrections_1960_amostra_127(linhas, "read_guides/1960_amostra_127_correcoes.csv")
tabelas <- parse_1960_amostra_127(linhas,
  "read_guides/readguide_1960_amostra_127_familias.csv", "read_guides/readguide_1960_amostra_127_pessoas.csv")
antes <- copy(tabelas)
sem_novas <- file.path(saida, "sem_novas.csv")
write.csv(as.data.frame(manifesto[!linha %in% novas$linha]), sem_novas, row.names = FALSE, na = "")
erro <- tryCatch(dedup_1960_amostra_127(tabelas, file.path(saida, "antes"), sem_novas), error = identity)
stopifnot(inherits(erro, "error"), grepl("Deduplicacao suspensa", conditionMessage(erro), fixed = TRUE),
          identical(tabelas, antes))
com_novas <- file.path(saida, "com_novas.csv")
proposto <- rbindlist(list(manifesto[!linha %in% novas$linha], novas), use.names = TRUE)
write.csv(as.data.frame(proposto), com_novas, row.names = FALSE, na = "")
resultado <- dedup_1960_amostra_127(tabelas, file.path(saida, "depois"), com_novas)
stopifnot(nrow(resultado$pessoas) == 4L, nrow(resultado$familias) == 1L,
          identical(as.data.frame(resultado$pessoas[, names(antes$pessoas), with = FALSE]), as.data.frame(antes$pessoas)),
          identical(resultado$familias, antes$familias), identical(tabelas, antes),
          all(as.integer(novas$linha) %in% resultado$pessoas$linha),
          nrow(fread(file.path(saida, "depois", "duplicatas_removidas.csv"))) == 0L)
parcial <- copy(tabelas)
parcial$pessoas <- parcial$pessoas[linha != 773913L]
erro <- tryCatch(dedup_1960_amostra_127(parcial, file.path(saida, "parcial"), com_novas), error = identity)
stopifnot(inherits(erro, "error"), grepl("grupo de decisao incompleto", conditionMessage(erro), fixed = TRUE))
adulterado <- copy(tabelas)
adulterado$pessoas[linha == 773911L, texto_corrigido := paste0("00", substr(texto_corrigido, 3, 62))]
erro <- tryCatch(dedup_1960_amostra_127(adulterado, file.path(saida, "adulterado"), com_novas), error = identity)
stopifnot(inherits(erro, "error"), grepl("conteudo diverge", conditionMessage(erro), fixed = TRUE))
stopifnot(identical(hash_antes, sapply(c(manifesto_path, raw_path, prova_path), function(path) digest(file = path, algo = "sha256"))))
write_json(list(pessoas_antes = 4L, pessoas_depois = 4L, removidas = 0L,
  novos_registros_pessoais = 0L, decisoes_manter = 2L,
  negativos = c("sem_decisao", "grupo_incompleto", "texto_adulterado")),
  file.path(saida, "resultado.json"), pretty = TRUE, auto_unbox = TRUE)
message("SP773911/773913: quatro pessoas preservadas; duas decisoes temporarias; nenhuma exclusao.")
message(saida)
