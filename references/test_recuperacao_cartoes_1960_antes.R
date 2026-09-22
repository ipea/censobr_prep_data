# Contrato minimo: a etapa explicita de recuperacao deve existir antes do replay.
.libPaths(c("renv/library/windows/R-4.5/x86_64-w64-mingw32", .libPaths()))
library(data.table)
setDTthreads(1L)
Sys.setlocale("LC_CTYPE", "English_United States.utf8")
source("R/microdata_1960_amostra_127.R", encoding = "UTF-8")
stopifnot(exists("recover_family_cards_1960_amostra_127", mode = "function"))
message("Etapa de recuperacao disponivel")
