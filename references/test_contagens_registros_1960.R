# Microlote real e variantes sinteticas: dado ausente nao e morador presente.
.libPaths(c("renv/library/windows/R-4.5/x86_64-w64-mingw32", .libPaths()))
Sys.setlocale("LC_CTYPE", "Portuguese_Brazil.utf8")
library(data.table)
library(jsonlite)
library(digest)
library(arrow)
setDTthreads(1L)
source("R/microdata_1960_amostra_127.R", encoding = "UTF-8")

dir.create("tmp/fechamento_registros_1960_20260922", recursive = TRUE, showWarnings = FALSE)
saida <- tempfile("contagens_", tmpdir = "tmp/fechamento_registros_1960_20260922")
dir.create(saida)
alvos <- c(391267:391269, 400682:400683)
con <- file("data_raw/microdata/1960/amostra_127/HHOLDA.txt", "rb")
texto <- character(length(alvos))
for(i in seq_along(alvos)){
  seek(con, where = (alvos[i] - 1) * 64, origin = "start")
  texto[i] <- readChar(con, 62L, useBytes = TRUE)
}
close(con)
stopifnot(all(nchar(texto, type = "bytes") == 62L))
path <- file.path(saida, "microlote.txt")
writeLines(texto, path, useBytes = TRUE)
linhas <- read_1960_amostra_127(path)
linhas[, linha := alvos]
linhas <- apply_corrections_1960_amostra_127(linhas, "read_guides/1960_amostra_127_correcoes.csv")
entrada <- parse_1960_amostra_127(linhas, "read_guides/readguide_1960_amostra_127_familias.csv",
                                 "read_guides/readguide_1960_amostra_127_pessoas.csv")
entrada <- recover_family_cards_1960_amostra_127(entrada, out_dir = file.path(saida, "recuperacao"))
entrada <- build_families_1960_amostra_127(entrada, file.path(saida, "vinculos"))
antes <- copy(entrada)
completa <- finalize_1960_amostra_127(entrada, "read_guides/1960_municipios.csv", "read_guides/1960_distritos.csv")
stopifnot(identical(antes, entrada))
alvo <- entrada$pessoas[linha == 400682L, censobr_idhousehold]
stopifnot(completa$domicilios[censobr_idhousehold == alvo, censobr_n_listadas] == 2L,
          completa$domicilios[censobr_idhousehold == alvo, censobr_n_residentes] == 0L,
          completa$domicilios[censobr_idhousehold == alvo, censobr_n_presentes] == 2L)

for(valor in c(NA_character_, "7")){
  incompleta <- copy(entrada)
  incompleta$pessoas[linha == 400682L, V202 := valor]
  preservada <- copy(incompleta)
  resultado <- finalize_1960_amostra_127(incompleta, "read_guides/1960_municipios.csv", "read_guides/1960_distritos.csv")
  dom <- resultado$domicilios[censobr_idhousehold == alvo]
  stopifnot(identical(preservada, incompleta), nrow(resultado$pessoas) == 4L,
            dom$censobr_n_listadas == 2L,
            is.na(dom$censobr_n_residentes), is.na(dom$censobr_n_presentes),
            all(is.na(resultado$pessoas[censobr_idhousehold == alvo, censobr_n_residentes])),
            all(is.na(resultado$pessoas[censobr_idhousehold == alvo, censobr_n_presentes])),
            identical(completa$domicilios[censobr_idhousehold != alvo], resultado$domicilios[censobr_idhousehold != alvo]))
  write_parquet(resultado$domicilios, file.path(saida, paste0("domicilios_", if(is.na(valor)) "NA" else valor, ".parquet")))
  reaberto <- as.data.table(read_parquet(file.path(saida, paste0("domicilios_", if(is.na(valor)) "NA" else valor, ".parquet"))))
  stopifnot(is.na(reaberto[censobr_idhousehold == alvo, censobr_n_residentes]),
            is.na(reaberto[censobr_idhousehold == alvo, censobr_n_presentes]))
}
message("Contagens desconhecidas preservadas, demais registros iguais: ", saida)
