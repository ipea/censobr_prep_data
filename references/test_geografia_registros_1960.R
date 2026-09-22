# Dois registros reais e uma pasta-controle sintetica para testar apenas o finalizador.
.libPaths(c("renv/library/windows/R-4.5/x86_64-w64-mingw32", .libPaths()))
Sys.setlocale("LC_CTYPE", "Portuguese_Brazil.utf8")
library(data.table)
library(jsonlite)
library(digest)
library(arrow)
setDTthreads(1L)
source("R/microdata_1960_amostra_127.R", encoding = "UTF-8")
source("references/ler_fixtures_registros_1960.R", encoding = "UTF-8")
fixture_path <- "references/fechamento_registros_1960_evidencias/fixtures_decisoes.json"
fixture <- carregar_fixture_registros_1960(fixture_path)
hash_fixture <- digest(file = fixture_path, algo = "sha256")

base <- "tmp/fechamento_registros_1960_20260922"
dir.create(base, recursive = TRUE, showWarnings = FALSE)
saida <- tempfile("geografia_pr_", tmpdir = base)
dir.create(saida)
manifesto <- "read_guides/1960_amostra_127_geografia_fonte25.json"
geo <- fromJSON(manifesto)
fontes <- geo$fontes$arquivo
hashes <- sapply(fontes, function(path) digest(file = path, algo = "sha256"))
con <- file(fontes[1], "rb")
textos <- character(4L)
for(i in seq_along(textos)){
  seek(con, where = (geo$registros127$linha[i] - 1L) * 64, origin = "start")
  textos[i] <- readChar(con, 62L, useBytes = TRUE)
}
close(con)
stopifnot(identical(textos, geo$registros127$texto))

# A segunda pasta e ficticia e nao constitui evidencia historica. Evita estrato
# solitario neste teste, sem depender de todo o cadastro da amostra.
controle <- textos[1:2]
substr(controle, 3L, 6L) <- "7240"
substr(controle, 9L, 13L) <- "71040"
substr(controle, 56L, 62L) <- "0199999"
path <- file.path(saida, "microlote.txt")
writeLines(c(textos, controle), path, useBytes = TRUE)
linhas <- read_1960_amostra_127(path)
linhas[, linha := c(geo$registros127$linha, 2000001L, 2000002L)]
linhas <- apply_corrections_1960_amostra_127(linhas, "read_guides/1960_amostra_127_correcoes.csv")
entrada <- parse_1960_amostra_127(linhas, "read_guides/readguide_1960_amostra_127_familias.csv",
                                 "read_guides/readguide_1960_amostra_127_pessoas.csv")
vinculos <- tabela_fixture_registros_1960(fixture, "vinculos_pr3")
stopifnot(nrow(vinculos) == 3L, !anyDuplicated(vinculos$linha))
vinc_path <- file.path(saida, "vinculos.csv")
write.csv(vinculos, vinc_path, row.names = FALSE, fileEncoding = "UTF-8")
entrada <- build_families_1960_amostra_127(entrada, file.path(saida, "vinculos"), vinc_path)
antes <- copy(entrada)
finalizar <- function(x = entrada, prova = manifesto, arquivos = fontes){
  finalize_1960_amostra_127(x, "read_guides/1960_municipios.csv", "read_guides/1960_distritos.csv",
                           geografia_path = prova, fontes_geografia = arquivos)
}
resultado <- finalizar()
stopifnot(identical(antes, entrada), identical(resultado, finalizar()),
          nrow(resultado$domicilios) == 2L, nrow(resultado$pessoas) == 4L,
          resultado$domicilios[linha == 887255L, code_muni_1960] == 7240L,
          resultado$pessoas[linha == 887256L, code_muni_1960] == 7240L,
          is.na(resultado$domicilios[linha == 887255L, V116]),
          is.na(resultado$pessoas[linha == 887256L, V116]),
          resultado$pessoas[linha == 888718L, V216] == 0L,
          all(resultado$pessoas[linha %in% c(888718L, 888719L, 2000002L), V116] == 7240L),
          grepl("municipio_fonte25", resultado$domicilios[linha == 887255L, censobr_diagnostico]),
          grepl("municipio_fonte25", resultado$pessoas[linha == 887256L, censobr_diagnostico]),
          !grepl("municipio_fonte25", resultado$pessoas[linha == 888718L, censobr_diagnostico]))

falha <- function(expr, mensagem){
  erro <- tryCatch({ force(expr); NULL }, error = identity)
  stopifnot(inherits(erro, "error"), grepl(mensagem, conditionMessage(erro), fixed = TRUE))
}
falha(finalizar(prova = NULL), "requer manifesto")
falha(finalizar(arquivos = fontes[1]), "fornecidas divergem")
for(variante in c("hash", "linha", "literal", "municipio")){
  alterado <- fromJSON(manifesto, simplifyVector = FALSE)
  if(variante == "hash") alterado$fontes[[2]]$sha256 <- strrep("0", 64)
  if(variante == "linha") alterado$registros25[[2]]$linha <- 708708L
  if(variante == "literal") alterado$registros25[[2]]$texto <- alterado$registros25[[3]]$texto
  if(variante == "municipio") alterado$code_muni_1960 <- 7241L
  prova <- file.path(saida, paste0("manifesto_", variante, ".json"))
  write_json(alterado, prova, auto_unbox = TRUE, pretty = TRUE)
  esperado <- switch(variante, hash = "Hash da fonte", linha = "fora dos dois registros",
                     literal = "Linha ou texto", municipio = "fora dos dois registros")
  falha(finalizar(prova = prova), esperado)
}
alterada <- copy(entrada)
alterada$pessoas[linha == 887256L, texto_original := paste0("X", substring(texto_original, 2L))]
falha(finalizar(alterada), "Entrada municipal")
alterada <- copy(entrada)
alterada$pessoas[linha == 887256L, V116 := "7240"]
falha(finalizar(alterada), "V116 da entrada")
alterada <- copy(entrada)
alterada$pessoas[linha == 888718L, V216 := "63"]
antes_alterada <- copy(alterada)
falha(finalizar(alterada), "Resposta da entrada diverge da fonte municipal")
stopifnot(identical(alterada, antes_alterada),
          identical(alterada$pessoas$texto_original, entrada$pessoas$texto_original))
alterada <- copy(entrada)
alterada$pessoas[linha == 888718L, censobr_idfamily := 2L]
falha(finalizar(alterada), "Vinculo ou composicao")
alterada <- copy(entrada)
alterada$pessoas <- alterada$pessoas[linha != 888719L]
falha(finalizar(alterada), "Entrada municipal")

for(tipo in c("pessoas", "domicilios")){
  path <- file.path(saida, paste0(tipo, ".parquet"))
  write_parquet(resultado[[tipo]], path)
  stopifnot(identical(as.data.frame(as.data.table(read_parquet(path))), as.data.frame(resultado[[tipo]])))
}
stopifnot(identical(hashes, sapply(fontes, function(path) digest(file = path, algo = "sha256"))),
          hash_fixture == digest(file = fixture_path, algo = "sha256"))
write_json(list(registros_com_derivacao = 2L, pessoas_no_grupo_real = 3L,
                v116_original_preservado = TRUE, fontes_inalteradas = TRUE,
                linhas_controle_sinteticas = c(2000001L, 2000002L), saida = saida),
           file.path(saida, "conferencia.json"), auto_unbox = TRUE, pretty = TRUE)
message("Municipio derivado com prova local e V116 preservado: ", saida)
