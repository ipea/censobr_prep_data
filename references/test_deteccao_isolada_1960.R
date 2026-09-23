.libPaths(c("renv/library/windows/R-4.5/x86_64-w64-mingw32", .libPaths()))
Sys.setlocale("LC_CTYPE", "Portuguese_Brazil.utf8")
library(data.table)
library(digest)
setDTthreads(1L)
source("R/microdata_1960_amostra_127.R", encoding = "UTF-8")

base <- "tmp/fechamento_integral_1960/testes"
dir.create(base, recursive = TRUE, showWarnings = FALSE)
saida <- tempfile("deteccao_", tmpdir = base)
dir.create(saida)
original <- "data_raw/microdata/1960/amostra_127/linhas_problematicas.csv"
antes <- digest(file = original, algo = "sha256")
con <- file("data_raw/microdata/1960/amostra_127/HHOLDA.txt", "rt", encoding = "latin1")
texto <- readLines(con, n = 100L, warn = FALSE)
close(con)
writeLines(texto, file.path(saida, "trecho.txt"), useBytes = TRUE)
linhas <- read_1960_amostra_127(file.path(saida, "trecho.txt"))
dec <- as.data.table(read.csv("read_guides/1960_amostra_127_correcoes.csv",
                            fileEncoding = "UTF-8-BOM", colClasses = "character"))
dec <- dec[as.integer(linha) <= length(texto)]
write.csv(dec, file.path(saida, "correcoes.csv"), row.names = FALSE, fileEncoding = "UTF-8")
problemas <- detect_1960_amostra_127(linhas,
  "read_guides/readguide_1960_amostra_127_familias.csv",
  "read_guides/readguide_1960_amostra_127_pessoas.csv",
  file.path(saida, "correcoes.csv"), out_dir = saida)
stopifnot(identical(antes, digest(file = original, algo = "sha256")),
          file.exists(file.path(saida, "linhas_problematicas.csv")),
          identical(names(problemas), names(fread(file.path(saida, "linhas_problematicas.csv")))))
message("Deteccao isolada conferida: ", saida)
