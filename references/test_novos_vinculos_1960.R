# Contexto completo dos novos vinculos: nenhuma pessoa e descartada para o teste passar.
.libPaths(c("renv/library/windows/R-4.5/x86_64-w64-mingw32", .libPaths()))
Sys.setlocale("LC_CTYPE", "Portuguese_Brazil.utf8")
library(data.table)
library(jsonlite)
library(arrow)
library(digest)
setDTthreads(1L)
source("R/microdata_1960_amostra_127.R", encoding = "UTF-8")
source("references/ler_fixtures_registros_1960.R", encoding = "UTF-8")
fixture_path <- "references/fechamento_registros_1960_evidencias/fixtures_decisoes.json"
fixture <- carregar_fixture_registros_1960(fixture_path)
hash_fixture <- digest(file = fixture_path, algo = "sha256")
base <- "tmp/fechamento_registros_1960_20260922"
dir.create(base, recursive = TRUE, showWarnings = FALSE)
saida <- tempfile("vinculos_r_", tmpdir = base)
dir.create(saida)
duplicatas <- rbindlist(list(
  as.data.table(read.csv("read_guides/1960_amostra_127_duplicatas.csv", colClasses = "character")),
  tabela_fixture_registros_1960(fixture, "duplicatas954")), use.names = TRUE)
for(col in setdiff(names(duplicatas), "justificativa"))
  stopifnot(duplicatas[, .(n = uniqueN(get(col))), by = linha][, all(n == 1L)])
duplicatas <- unique(duplicatas, by = "linha")
dup_path <- file.path(saida, "duplicatas.csv")
write.csv(duplicatas, dup_path, row.names = FALSE, fileEncoding = "UTF-8")
novos <- tabela_fixture_registros_1960(fixture, "vinculos166")
stopifnot(nrow(novos) == 166L, !anyDuplicated(novos$linha))
vinculos <- rbind(as.data.table(read.csv("read_guides/1960_amostra_127_vinculos.csv", colClasses = "character")), novos)
for(col in setdiff(names(vinculos), "justificativa"))
  stopifnot(vinculos[, .(n = uniqueN(get(col))), by = linha][, all(n == 1L)])
vinculos <- unique(vinculos, by = "linha")
vinc_path <- file.path(saida, "vinculos.csv")
write.csv(vinculos, vinc_path, row.names = FALSE, fileEncoding = "UTF-8")
alvos <- sort(as.integer(unlist(fixture$linhas127_contexto_vinculos166, use.names = FALSE)))
stopifnot(length(alvos) == 653L, !anyDuplicated(alvos))
raw <- "data_raw/microdata/1960/amostra_127/HHOLDA.txt"
hash <- digest(file = raw, algo = "sha256")
con <- file(raw, "rb"); texto <- character(length(alvos))
for(i in seq_along(alvos)){
  seek(con, where = (alvos[i]-1)*64, origin = "start")
  texto[i] <- readChar(con, 62L, useBytes = TRUE)
}
close(con)
path <- file.path(saida, "microlote.txt"); writeLines(texto, path, useBytes = TRUE)
linhas <- read_1960_amostra_127(path); linhas[, linha := alvos]
linhas <- apply_corrections_1960_amostra_127(linhas, "read_guides/1960_amostra_127_correcoes.csv")
entrada <- parse_1960_amostra_127(linhas, "read_guides/readguide_1960_amostra_127_familias.csv",
                                 "read_guides/readguide_1960_amostra_127_pessoas.csv")
stopifnot(nrow(entrada$familias) == 82L, nrow(entrada$pessoas) == 571L)
antes <- copy(entrada)

# Primeiro um grupo pequeno real, completo e sem familia convivente.
piloto_f <- entrada$familias[which(entrada$familias$linha == 448415L)]
piloto_p <- entrada$pessoas[which(entrada$pessoas$pasta == piloto_f$pasta &
  entrada$pessoas$boletim == piloto_f$boletim & entrada$pessoas$UF == piloto_f$UF)]
piloto <- list(familias = piloto_f, pessoas = piloto_p)
piloto <- dedup_1960_amostra_127(piloto, file.path(saida, "piloto"), dup_path)
piloto <- build_families_1960_amostra_127(piloto, file.path(saida, "piloto"), vinc_path)
stopifnot(all(piloto$pessoas[linha %in% 448410:448414, censobr_familia_origem] == "reconciliada_25"))

resultado <- dedup_1960_amostra_127(entrada, file.path(saida, "completo"), dup_path)
resultado <- build_families_1960_amostra_127(resultado, file.path(saida, "completo"), vinc_path)
stopifnot(identical(entrada, antes), nrow(resultado$familias) == 82L,
          identical(sort(resultado$pessoas$linha), sort(setdiff(entrada$pessoas$linha,
            as.integer(duplicatas[acao == "remover", linha])))))
cols <- names(entrada$pessoas)
stopifnot(identical(as.data.frame(resultado$pessoas[order(linha), ..cols]),
  as.data.frame(entrada$pessoas[linha %in% resultado$pessoas$linha][order(linha)])))
ip <- match(as.integer(novos$linha), resultado$pessoas$linha)
jf <- match(as.integer(novos$linha_familia), resultado$familias$linha)
stopifnot(!anyNA(ip), !anyNA(jf), identical(resultado$pessoas$censobr_idfamily[ip], resultado$familias$censobr_idfamily[jf]),
          all(resultado$pessoas$censobr_familia_origem[ip] == "reconciliada_25"),
          grepl(";", novos[linha == "425558", linha_pessoa_25], fixed = TRUE))
for(tipo in c("pessoas", "familias")){
  arquivo <- file.path(saida, paste0(tipo, ".parquet"))
  write_parquet(resultado[[tipo]], arquivo)
  reaberto <- as.data.table(read_parquet(arquivo))
  stopifnot(identical(as.data.frame(reaberto), as.data.frame(resultado[[tipo]])))
}
stopifnot(hash == digest(file = raw, algo = "sha256"),
          hash_fixture == digest(file = fixture_path, algo = "sha256"))
write_json(list(vinculos = nrow(novos), pessoas = nrow(resultado$pessoas), familias = nrow(resultado$familias),
  respostas_preservadas = TRUE, fonte_inalterada = TRUE, saida = saida), file.path(saida, "conferencia.json"), auto_unbox = TRUE, pretty = TRUE)
message("166 vinculos conferidos com contexto completo: ", saida)
