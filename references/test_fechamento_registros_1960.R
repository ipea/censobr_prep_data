# Regressao integrada em microlotes, sempre chamada pelo runner isolado.
.libPaths(c("renv/library/windows/R-4.5/x86_64-w64-mingw32", .libPaths()))
Sys.setlocale("LC_CTYPE", "Portuguese_Brazil.utf8")
library(data.table)
setDTthreads(1L)
source("references/test_integridade_amostra_127.R", encoding = "UTF-8")
source("references/test_contagens_registros_1960.R", encoding = "UTF-8")
message("Regressao integrada dos registros aprovada")
