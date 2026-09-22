# Executar apenas pelo runner isolado, apos os testes sinteticos.
# Le dados e pesos existentes; todas as saidas ficam numa pasta nova.
Sys.setlocale("LC_CTYPE", ".UTF-8")
stopifnot(l10n_info()[["UTF-8"]])
.libPaths(c("renv/library/windows/R-4.5/x86_64-w64-mingw32", .libPaths()))
library(data.table)
library(arrow)
setDTthreads(1L)
arrow::set_cpu_count(1L)
arrow::set_io_thread_count(2L)
source("R/microdata_1960_amostra_127.R", encoding = "UTF-8")
source("R/microdata_1960_amostra_25.R", encoding = "UTF-8")
source("R/microdata_1960.R", encoding = "UTF-8")
source("R/microdata_1960_validacao.R", encoding = "UTF-8")

out <- "tmp/execucao_1960_20260922/relatorios_pesos_atuais"
if(dir.exists(out)) stop("A pasta de saida ja existe; nao sobrescrever esta rodada")
dir.create(out, recursive = TRUE)
def <- "references/censo_1960_resultados_definitivos_serie_nacional.csv"
prelim <- "references/censo_1960_resultados_preliminares_1965.csv"
paths25 <- unlist(lapply(names(UF_1960_AMOSTRA_25), function(u)
  file.path("data_raw/microdata/1960/amostra_25", u,
            c("domicilios_pesos.parquet", "pessoas_pesos.parquet"))))
paths_comp <- unlist(lapply(c(names(UF_1960_AMOSTRA_25), names(UF_1960_AMOSTRA_127)), function(u)
  file.path("data_raw/microdata/1960/compilada", u, c("domicilios.parquet", "pessoas.parquet"))))
paths127 <- file.path("data_raw/microdata/1960/amostra_127",
  c("domicilios_1960_amostra_127.parquet", "pessoas_1960_amostra_127.parquet"))
inputs <- c(paths25, paths_comp, paths127, def, prelim,
  "R/microdata_1960_amostra_127.R", "R/microdata_1960_amostra_25.R",
  "R/microdata_1960.R", "R/microdata_1960_validacao.R")
stopifnot(all(file.exists(inputs)))
manifesto <- data.table(arquivo = inputs, bytes = file.info(inputs)$size,
                       md5_antes = unname(tools::md5sum(inputs)))
fwrite(manifesto, file.path(out, "entradas.csv"))

# Primeiro, duas unidades pequenas com resultados conferidos independentemente.
fn <- fread(validate_definitivos_1960_amostra_25(
  paths25[basename(dirname(paths25)) == "fn"], def, file.path(out, "teste_fn")))
z <- fn[tabela == 7L & uf60 == 24L & item == "total" & peso == "censobr_weight"]
stopifnot(nrow(z) == 2L,
  z[medida == "domicilios", n_amostra] == 62L,
  abs(z[medida == "domicilios", valor] - 276.099729) < 1e-5,
  z[medida == "pessoas", n_amostra] == 294L,
  abs(z[medida == "pessoas", valor] - 1332.499557) < 1e-5)
rr <- fread(validate_1960(paths_comp[basename(dirname(paths_comp)) == "rr"],
                         def, file.path(out, "teste_rr")))
z <- rr[tabela == 7L & uf60 == 3L & item == "total"]
stopifnot(nrow(z) == 2L, z[medida == "domicilios", n_amostra] == 58L,
  abs(z[medida == "domicilios", valor] - 4149.830114) < 1e-5,
  z[medida == "pessoas", n_amostra] == 399L,
  abs(z[medida == "pessoas", valor] - 29338.287539) < 1e-5)
rm(fn, rr, z); gc(verbose = FALSE)

validate_definitivos_1960_amostra_25(paths25, def, file.path(out, "amostra_25"))
gc(verbose = FALSE)
validate_1960(paths_comp, def, file.path(out, "compilada"))
gc(verbose = FALSE)

p <- setDT(arrow::read_parquet(paths127[2], col_select = c(
  "linha", "UF", "censobr_idhousehold", "censobr_idfamily", "V118", "V202", "V203",
  "V204", "V204B", "V206", "V211", "V215", "V219", "V220", "V223", "V223B",
  "censobr_weight", "censobr_weight_1965")))
d <- setDT(arrow::read_parquet(paths127[1], col_select = c(
  "UF", "censobr_idhousehold", "V118", "V101", "V102", "V103", "V104", "V105",
  "V106", "V107", "V108", "V109", "V110", "censobr_weight", "censobr_weight_1965")))
tab <- list(pessoas = p, domicilios = d)
r_prelim <- validate_1965_1960_amostra_127(tab, prelim, file.path(out, "amostra_127"))
rm(r_prelim); gc(verbose = FALSE)
r_def <- validate_definitivos_1960_amostra_127(tab, def, file.path(out, "amostra_127"))
rm(p, d, tab, r_def); gc(verbose = FALSE)

manifesto[, md5_depois := unname(tools::md5sum(arquivo))]
stopifnot(all(manifesto$md5_antes == manifesto$md5_depois))
fwrite(manifesto, file.path(out, "entradas.csv"))
writeLines(capture.output(sessionInfo()), file.path(out, "ambiente.txt"))
message("RELATORIOS_CONCLUIDOS_SEM_ALTERAR_ENTRADAS: ", out)
