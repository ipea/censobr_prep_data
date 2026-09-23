.libPaths(c("renv/library/windows/R-4.5/x86_64-w64-mingw32", .libPaths()))
Sys.setlocale("LC_CTYPE", "Portuguese_Brazil.utf8")
library(data.table)
library(jsonlite)
library(digest)
setDTthreads(1L)
source("R/microdata_1960_amostra_127.R", encoding = "UTF-8")
prova_path <- "references/resolucao_residuais_duplicatas5_1960_evidencias.json"
prova <- fromJSON(prova_path, simplifyVector = FALSE)
manifesto_path <- "read_guides/1960_amostra_127_duplicatas.csv"
raw_path <- "data_raw/microdata/1960/amostra_127/HHOLDA.txt"
fontes <- c(prova_path, manifesto_path, raw_path,
  "data/release_legacy/Censo.1960.amostra.25porcento.rs.gz")
hash_antes <- sapply(fontes, function(path) digest(file = path, algo = "sha256"))
for(fonte in prova$fontes){
  stopifnot(identical(digest(file = fonte$arquivo, algo = "sha256"), fonte$sha256))
}
linhas_alvo <- c(131528L, 131530L, 774112L, 774116L, 986867L, 986870L,
                1009572L, 1009575L, 1014154L, 1014156L)
manifesto <- as.data.table(read.csv(manifesto_path, colClasses = "character",
  strip.white = FALSE, fileEncoding = "UTF-8", stringsAsFactors = FALSE))
novas <- manifesto[linha %in% as.character(linhas_alvo)]
stopifnot(nrow(novas) == 10L, all(novas$acao == "manter"), all(novas$n_manter == "2"),
          all(novas$n_antes == "2"), uniqueN(novas$grupo) == 5L,
          identical(sort(as.integer(novas$linha)), linhas_alvo),
          nrow(manifesto) == 6463L, sum(manifesto$acao == "manter") == 3727L,
          sum(manifesto$acao == "remover") == 2736L)

dir.create("tmp/resolver_residuais_1960_20260922/duplicatas", recursive = TRUE, showWarnings = FALSE)
saida <- tempfile("teste_r_", tmpdir = "tmp/resolver_residuais_1960_20260922/duplicatas")
dir.create(saida)
alvos <- sort(unique(unlist(lapply(prova$casos_completos, function(caso){
  c(sapply(caso$cartoes127, `[[`, "linha"), sapply(caso$pessoas127, `[[`, "linha"))
}))))
texto <- character(length(alvos)); inicio <- 0L
con <- file(raw_path, open = "rt", encoding = "latin1")
while(inicio < max(alvos)){
  trecho <- readLines(con, n = 10000L, warn = FALSE)
  stopifnot(length(trecho) > 0L)
  idx <- which(alvos > inicio & alvos <= inicio + length(trecho))
  texto[idx] <- trecho[alvos[idx] - inicio]
  inicio <- inicio + length(trecho)
}
close(con)
stopifnot(all(nchar(texto) == 62L), length(texto) == 51L)
lote <- file.path(saida, "lote51.txt")
writeLines(texto, lote, useBytes = TRUE)
linhas <- read_1960_amostra_127(lote)
linhas[, linha := as.integer(alvos)]
linhas <- apply_corrections_1960_amostra_127(linhas, "read_guides/1960_amostra_127_correcoes.csv")
tabelas <- parse_1960_amostra_127(linhas,
  "read_guides/readguide_1960_amostra_127_familias.csv",
  "read_guides/readguide_1960_amostra_127_pessoas.csv")
antes <- copy(tabelas)
stopifnot(nrow(tabelas$pessoas) == 46L, nrow(tabelas$familias) == 5L)

# Antes da decisao explicita, os mesmos pares devem interromper sem exclusoes.
antigo_path <- file.path(saida, "manifesto_sem_novas.csv")
write.csv(as.data.frame(manifesto[!linha %in% as.character(linhas_alvo)]), antigo_path,
  row.names = FALSE, fileEncoding = "UTF-8", na = "")
erro <- tryCatch(dedup_1960_amostra_127(tabelas, file.path(saida, "antes"), antigo_path), error = identity)
stopifnot(inherits(erro, "error"), grepl("Deduplicacao suspensa", conditionMessage(erro), fixed = TRUE),
          identical(tabelas, antes), !file.exists(file.path(saida, "antes", "duplicatas_removidas.csv")))

resultado <- dedup_1960_amostra_127(tabelas, file.path(saida, "depois"), manifesto_path)
stopifnot(nrow(resultado$pessoas) == 46L, identical(tabelas, antes),
          identical(as.data.frame(resultado$pessoas[, names(antes$pessoas), with = FALSE]),
                    as.data.frame(antes$pessoas)),
          identical(resultado$familias, antes$familias),
          all(linhas_alvo %in% resultado$pessoas$linha),
          sum(resultado$pessoas$censobr_duplicata_mantida) == 5L,
          nrow(fread(file.path(saida, "depois", "duplicatas_removidas.csv"))) == 0L)

# Um recorte com uma so linha do par nao pode satisfazer a decisao de duas.
parcial <- copy(tabelas)
parcial$pessoas <- parcial$pessoas[linha != linhas_alvo[2L]]
erro <- tryCatch(dedup_1960_amostra_127(parcial, file.path(saida, "parcial"), manifesto_path), error = identity)
stopifnot(inherits(erro, "error"), grepl("grupo de decisao incompleto", conditionMessage(erro), fixed = TRUE))
adulterado <- copy(tabelas)
adulterado$pessoas[linha == linhas_alvo[1L], texto_corrigido := paste0("00", substr(texto_corrigido, 3, 62))]
erro <- tryCatch(dedup_1960_amostra_127(adulterado, file.path(saida, "adulterado"), manifesto_path), error = identity)
stopifnot(inherits(erro, "error"), grepl("conteudo diverge", conditionMessage(erro), fixed = TRUE))
stopifnot(identical(hash_antes, sapply(fontes, function(path) digest(file = path, algo = "sha256"))))
write_json(list(entrada_pessoas = 46L, retidas = 46L, removidas = 0L, novas_decisoes = 10L,
  pares_preservados = 5L, resposta_original_preservada = TRUE,
  negativos = c("sem_manifesto", "grupo_incompleto", "texto_adulterado"),
  fontes = data.frame(arquivo = fontes, sha256 = unname(hash_antes))),
  file.path(saida, "resultado.json"), auto_unbox = TRUE, pretty = TRUE)
message("Cinco pares mantidos: 46 pessoas do microlote preservadas, nenhuma exclusao.")
message(saida)
