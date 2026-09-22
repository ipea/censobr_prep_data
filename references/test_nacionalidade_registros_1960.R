# Nascer no Brasil nao preenche, por si so, resposta ausente de nacionalidade.
.libPaths(c("renv/library/windows/R-4.5/x86_64-w64-mingw32", .libPaths()))
Sys.setlocale("LC_CTYPE", "Portuguese_Brazil.utf8")
library(data.table)
library(arrow)
setDTthreads(1L)
source("R/microdata_1960_amostra_127.R", encoding = "UTF-8")
saida <- tempfile("nacionalidade_", tmpdir = "tmp/fechamento_registros_1960_20260922")
dir.create(saida)
alvos <- c(391267:391269, 399791:399793)
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
linhas <- apply_corrections_1960_amostra_127(linhas, "read_guides/1960_amostra_127_correcoes.csv")
entrada <- parse_1960_amostra_127(linhas, "read_guides/readguide_1960_amostra_127_familias.csv",
                                 "read_guides/readguide_1960_amostra_127_pessoas.csv")
entrada <- build_families_1960_amostra_127(entrada, file.path(saida, "vinculos"))
completa <- finalize_1960_amostra_127(entrada, "read_guides/1960_municipios.csv", "read_guides/1960_distritos.csv")
entrada$pessoas[1, `:=`(V207 = "20", V208 = NA_character_)]
antes <- copy(entrada)
resultado <- finalize_1960_amostra_127(entrada, "read_guides/1960_municipios.csv", "read_guides/1960_distritos.csv")
stopifnot(identical(antes, entrada), nrow(resultado$pessoas) == 4L,
          is.na(resultado$pessoas$V208[1]), !any(resultado$pessoas$censobr_v208_imputada),
          identical(completa$pessoas[2], resultado$pessoas[2]))
write_parquet(resultado$pessoas, file.path(saida, "pessoas.parquet"))
reaberto <- as.data.table(read_parquet(file.path(saida, "pessoas.parquet")))
stopifnot(is.na(reaberto$V208[1]), !any(reaberto$censobr_v208_imputada))
message("Nacionalidade ausente preservada: ", saida)
