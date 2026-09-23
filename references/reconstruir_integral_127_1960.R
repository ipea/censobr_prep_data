.libPaths(c("renv/library/windows/R-4.5/x86_64-w64-mingw32", .libPaths()))
Sys.setlocale("LC_CTYPE", "Portuguese_Brazil.utf8")
library(data.table)
library(jsonlite)
library(digest)
library(arrow)
setDTthreads(1L)
arrow::set_cpu_count(1L)
source("R/support_fun.R", encoding = "UTF-8")
source("R/microdata_1960_amostra_127.R", encoding = "UTF-8")

base <- "tmp/fechamento_integral_1960/reconstrucao127"
dir.create(base, recursive = TRUE, showWarnings = FALSE)
saida <- tempfile(paste0(format(Sys.time(), "%Y%m%d_%H%M%S"), "_"), tmpdir = base)
dir.create(saida)
message("Saida isolada: ", saida)
gf <- "read_guides/readguide_1960_amostra_127_familias.csv"
gp <- "read_guides/readguide_1960_amostra_127_pessoas.csv"
dec <- "read_guides/1960_amostra_127_correcoes.csv"
raw <- "data_raw/microdata/1960/amostra_127/HHOLDA.txt"
entradas <- c(raw, gf, gp, dec, "R/microdata_1960_amostra_127.R",
              "read_guides/1960_amostra_127_duplicatas.csv",
              "read_guides/1960_amostra_127_reparos_fonte25.json")
assinaturas <- data.table(arquivo = entradas,
                         sha256 = sapply(entradas, function(x) digest(file = x, algo = "sha256")))
fwrite(assinaturas, file.path(saida, "entradas.csv"))

linhas <- read_1960_amostra_127(raw)
problemas <- detect_1960_amostra_127(linhas, gf, gp, dec, out_dir = saida)
linhas <- apply_corrections_1960_amostra_127(linhas, dec)
tabelas <- parse_1960_amostra_127(linhas, gf, gp)
rm(linhas, problemas); gc(verbose = FALSE)
saveRDS(tabelas, file.path(saida, "registros_parseados_antes_dedup.rds"), compress = FALSE)
write_json(list(etapa = "parse_integral", pessoas = nrow(tabelas$pessoas),
                familias = nrow(tabelas$familias), reconstruida = FALSE),
           file.path(saida, "estado.json"), auto_unbox = TRUE, pretty = TRUE)

# Uma pendencia de identidade impede o calculo, nao autoriza descartar registros.
tabelas <- dedup_1960_amostra_127(tabelas, out_dir = saida)
saveRDS(tabelas, file.path(saida, "registros_deduplicados.rds"), compress = FALSE)
write_json(list(etapa = "deduplicacao_integral", pessoas = nrow(tabelas$pessoas),
                familias = nrow(tabelas$familias), reconstruida = FALSE),
           file.path(saida, "estado.json"), auto_unbox = TRUE, pretty = TRUE)
tabelas <- recover_family_cards_1960_amostra_127(tabelas, out_dir = saida)
tabelas <- build_families_1960_amostra_127(tabelas, out_dir = saida)
geo_path <- "read_guides/1960_amostra_127_geografia_fonte25.json"
geo <- fromJSON(geo_path)
tabelas <- finalize_1960_amostra_127(tabelas, "read_guides/1960_municipios.csv",
  "read_guides/1960_distritos.csv", geo_path, geo$fontes$arquivo)
saveRDS(tabelas, file.path(saida, "registros_conferidos_antes_pesos.rds"), compress = FALSE)
tabelas <- calibrate_1960_amostra_127(tabelas,
  "references/censo_1960_resultados_preliminares_1965.csv",
  "references/censo_1960_resultados_definitivos_serie_nacional.csv")
validate_1965_1960_amostra_127(tabelas,
  "references/censo_1960_resultados_preliminares_1965.csv", out_dir = saida)
validate_definitivos_1960_amostra_127(tabelas,
  "references/censo_1960_resultados_definitivos_serie_nacional.csv", out_dir = saida)
paths <- save_1960_amostra_127(tabelas, out_dir = saida)
write_json(list(etapa = "reconstrucao_e_pesos", reconstruida = TRUE,
  publicacao_homologada = FALSE, arquivos = paths,
  pessoas = nrow(tabelas$pessoas), domicilios = nrow(tabelas$domicilios)),
  file.path(saida, "estado.json"), auto_unbox = TRUE, pretty = TRUE)
message("Arquivos reconstruidos em area separada: ", saida)
