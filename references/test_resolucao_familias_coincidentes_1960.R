.libPaths(c("renv/library/windows/R-4.5/x86_64-w64-mingw32", .libPaths()))
Sys.setlocale("LC_CTYPE", "Portuguese_Brazil.utf8")
library(data.table)
library(jsonlite)
library(digest)
setDTthreads(1L)
source("R/microdata_1960_amostra_127.R", encoding = "UTF-8")
manifesto_path <- "read_guides/1960_amostra_127_familias_coincidentes.json"
manifesto <- fromJSON(manifesto_path, simplifyVector = FALSE)
stopifnot(identical(manifesto$versao, 1L), length(manifesto$conjuntos) == 10L,
  sum(vapply(manifesto$conjuntos, function(x) x$acao == "preservar_distintos_entre_fontes", logical(1))) == 5L)
fontes <- unique(c(manifesto_path, vapply(manifesto$fontes, `[[`, character(1), "arquivo"),
  "read_guides/1960_amostra_127_vinculos.csv", "read_guides/1960_amostra_127_correcoes.csv"))
hash_antes <- sapply(fontes, function(path) digest(file = path, algo = "sha256"))
dir.create("tmp/resolver_residuais_1960_20260922/duplicatas", recursive = TRUE, showWarnings = FALSE)
saida <- tempfile("teste_familias_r_", tmpdir = "tmp/resolver_residuais_1960_20260922/duplicatas")
dir.create(saida)
alvos <- sort(unique(as.integer(unlist(lapply(manifesto$conjuntos, function(x)
  c(unlist(x$linhas_cartoes), unlist(x$linhas_pessoas)))))))
stopifnot(length(alvos) == 75L)
texto <- character(length(alvos)); inicio <- 0L
con <- file("data_raw/microdata/1960/amostra_127/HHOLDA.txt", open = "rt", encoding = "latin1")
while(inicio < max(alvos)){
  trecho <- readLines(con, n = 10000L, warn = FALSE)
  stopifnot(length(trecho) > 0L)
  idx <- which(alvos > inicio & alvos <= inicio + length(trecho))
  texto[idx] <- trecho[alvos[idx] - inicio]
  inicio <- inicio + length(trecho)
}
close(con)
stopifnot(all(nchar(texto) == 62L))
lote_path <- file.path(saida, "lote75.txt")
writeLines(texto, lote_path, useBytes = TRUE)
linhas <- read_1960_amostra_127(lote_path)
linhas[, linha := alvos]
linhas <- apply_corrections_1960_amostra_127(linhas, "read_guides/1960_amostra_127_correcoes.csv")
todas <- parse_1960_amostra_127(linhas,
  "read_guides/readguide_1960_amostra_127_familias.csv",
  "read_guides/readguide_1960_amostra_127_pessoas.csv")
stopifnot(nrow(todas$familias) == 21L, nrow(todas$pessoas) == 54L)
resultados <- list()
for(i in seq_along(manifesto$conjuntos)){
  regra <- manifesto$conjuntos[[i]]
  tabelas <- list(familias = copy(todas$familias[linha %in% unlist(regra$linhas_cartoes)]),
                  pessoas = copy(todas$pessoas[linha %in% unlist(regra$linhas_pessoas)]))
  antes <- copy(tabelas)
  destino <- file.path(saida, regra$id)
  retorno <- tryCatch(build_families_1960_amostra_127(tabelas, destino,
    coincidencias_path = manifesto_path), error = identity)
  if(regra$acao == "preservar_distintos_entre_fontes"){
    stopifnot(!inherits(retorno, "error"), nrow(retorno$pessoas) == nrow(antes$pessoas),
      nrow(retorno$familias) == nrow(antes$familias),
      setequal(retorno$pessoas$linha, antes$pessoas$linha),
      all(retorno$pessoas$texto_original[match(antes$pessoas$linha, retorno$pessoas$linha)] == antes$pessoas$texto_original),
      all(retorno$pessoas$texto_corrigido[match(antes$pessoas$linha, retorno$pessoas$linha)] == antes$pessoas$texto_corrigido),
      nrow(fread(file.path(destino, "coincidencias_familiares_a_revisar.csv"))) == 0L)
  } else {
    stopifnot(inherits(retorno, "error"), grepl("conteudos familiares coincidentes", conditionMessage(retorno), fixed = TRUE),
      nrow(fread(file.path(destino, "coincidencias_familiares_a_revisar.csv"))) == nrow(antes$familias))
  }
  stopifnot(identical(tabelas, antes))
  resultados[[i]] <- list(id = regra$id, acao = regra$acao,
    bloqueado = inherits(retorno, "error"), n_pessoas_preservadas_na_entrada = nrow(antes$pessoas))
}

# Contraprovas: nenhuma delas pode transformar igualdade em autorizacao.
boa <- manifesto$conjuntos[[which(vapply(manifesto$conjuntos, function(x)
  229398L %in% unlist(x$linhas_cartoes), logical(1)))]]
tabelas_boa <- list(familias = copy(todas$familias[linha %in% unlist(boa$linhas_cartoes)]),
                    pessoas = copy(todas$pessoas[linha %in% unlist(boa$linhas_pessoas)]))
vazio <- manifesto; vazio$conjuntos <- list()
vazio_path <- file.path(saida, "manifesto_vazio.json")
write_json(vazio, vazio_path, auto_unbox = TRUE)
erro <- tryCatch(build_families_1960_amostra_127(tabelas_boa, file.path(saida, "sem_disposicao"),
  coincidencias_path = vazio_path), error = identity)
stopifnot(inherits(erro, "error"), grepl("conteudos familiares coincidentes", conditionMessage(erro), fixed = TRUE))
falso_hash <- manifesto; falso_hash$fontes[[1L]]$sha256 <- paste(rep("0", 64L), collapse = "")
hash_path <- file.path(saida, "manifesto_hash_adulterado.json")
write_json(falso_hash, hash_path, auto_unbox = TRUE)
erro <- tryCatch(build_families_1960_amostra_127(tabelas_boa, file.path(saida, "hash_adulterado"),
  coincidencias_path = hash_path), error = identity)
stopifnot(inherits(erro, "error"), grepl("fonte alterada", conditionMessage(erro), fixed = TRUE))
alterada <- copy(tabelas_boa)
alterada$pessoas[1L, texto_original := paste0("00", substr(texto_original, 3L, 62L))]
erro <- tryCatch(build_families_1960_amostra_127(alterada, file.path(saida, "texto_adulterado"),
  coincidencias_path = manifesto_path), error = identity)
stopifnot(inherits(erro, "error"), grepl("conteudo diverge", conditionMessage(erro), fixed = TRUE))
acao_falsa <- manifesto; acao_falsa$conjuntos[[1L]]$acao <- "preservar_distintos_entre_fontes"
acao_path <- file.path(saida, "manifesto_acao_adulterada.json")
write_json(acao_falsa, acao_path, auto_unbox = TRUE)
alvo_am <- manifesto$conjuntos[[1L]]
tabelas_am <- list(familias = copy(todas$familias[linha %in% unlist(alvo_am$linhas_cartoes)]),
                   pessoas = copy(todas$pessoas[linha %in% unlist(alvo_am$linhas_pessoas)]))
erro <- tryCatch(build_families_1960_amostra_127(tabelas_am, file.path(saida, "acao_adulterada"),
  coincidencias_path = acao_path), error = identity)
stopifnot(inherits(erro, "error"), grepl("preservacao entre fontes exige prova", conditionMessage(erro), fixed = TRUE))

# Nem assinatura correta do arquivo fonte nem booleanos no manifesto dispensam
# conferir o conteudo literal e as respostas do cartao na fonte efetiva.
literal_falso <- manifesto
iboa <- which(vapply(literal_falso$conjuntos, function(x) x$id == boa$id, logical(1)))
literal <- literal_falso$conjuntos[[iboa]]$fontes25[[1L]]$registros[[1L]]$texto
literal_falso$conjuntos[[iboa]]$fontes25[[1L]]$registros[[1L]]$texto <-
  paste0(substr(literal, 1L, 53L), if(substr(literal, 54L, 54L) == "0") "1" else "0")
literal_path <- file.path(saida, "manifesto_literal25_adulterado.json")
write_json(literal_falso, literal_path, auto_unbox = TRUE)
erro <- tryCatch(build_families_1960_amostra_127(tabelas_boa, file.path(saida, "literal25_adulterado"),
  coincidencias_path = literal_path), error = identity)
stopifnot(inherits(erro, "error"), grepl("literal ou quantidade25 diverge", conditionMessage(erro), fixed = TRUE))

booleans_falsos <- manifesto
isp <- which(vapply(booleans_falsos$conjuntos, function(x) 660406L %in% unlist(x$linhas_cartoes), logical(1)))
booleans_falsos$conjuntos[[isp]]$acao <- "preservar_distintos_entre_fontes"
for(j in seq_along(booleans_falsos$conjuntos[[isp]]$conferencias)){
  booleans_falsos$conjuntos[[isp]]$conferencias[[j]]$suficiente_para_preservar <- TRUE
  booleans_falsos$conjuntos[[isp]]$conferencias[[j]]$motivos <- list()
}
boolean_path <- file.path(saida, "manifesto_booleans_adulterados.json")
write_json(booleans_falsos, boolean_path, auto_unbox = TRUE)
alvo_sp <- manifesto$conjuntos[[isp]]
tabelas_sp <- list(familias = copy(todas$familias[linha %in% unlist(alvo_sp$linhas_cartoes)]),
                   pessoas = copy(todas$pessoas[linha %in% unlist(alvo_sp$linhas_pessoas)]))
erro <- tryCatch(build_families_1960_amostra_127(tabelas_sp, file.path(saida, "booleans_adulterados"),
  coincidencias_path = boolean_path), error = identity)
stopifnot(inherits(erro, "error"), grepl("respostas do cartao divergem", conditionMessage(erro), fixed = TRUE))
stopifnot(identical(hash_antes, sapply(fontes, function(path) digest(file = path, algo = "sha256"))))
write_json(list(conjuntos = resultados, preservacoes = 5L, bloqueios = 5L,
  exclusoes = 0L, nao_e_identidade_civil = TRUE,
  negativos = c("sem_disposicao", "hash_adulterado", "texto_adulterado", "acao_adulterada",
                "literal25_adulterado", "booleans_adulterados")),
  file.path(saida, "resultado.json"), pretty = TRUE, auto_unbox = TRUE)
message("Coincidencias familiares: cinco preservacoes entre fontes, cinco bloqueios, zero exclusoes.")
message(saida)
