# Le os34arquivos completos explicitamente conferidos; nunca muda os microdados.
.libPaths(c("renv/library/windows/R-4.5/x86_64-w64-mingw32", .libPaths()))
Sys.setlocale("LC_CTYPE", ".UTF-8")
library(data.table)
library(arrow)
setDTthreads(1L)
arrow::set_cpu_count(1L)
arrow::set_io_thread_count(2L)
source("R/microdata_1960_validacao.R", encoding = "UTF-8")
source("R/microdata_1960_amostra_25.R", encoding = "UTF-8")
indice <- Sys.getenv("CENSOBR_INDICE25_INTEGRAL")
stopifnot(nzchar(indice), file.exists(indice))
manifesto <- jsonlite::fromJSON(indice)
arquivos <- manifesto$arquivos
stopifnot(nrow(arquivos) == 34L, setequal(arquivos$uf, names(UF_1960_AMOSTRA_25)),
  !anyDuplicated(paste(arquivos$uf, arquivos$arquivo)))
paths <- arquivos$caminho
antes <- vapply(paths, function(p) digest::digest(file = p, algo = "sha256"), character(1))
stopifnot(identical(unname(antes), arquivos$sha256))
fontes <- c("R/microdata_1960_validacao.R", "R/microdata_1960_amostra_25.R",
  "references/censo_1960_resultados_definitivos_serie_nacional.csv", indice)
hashes <- vapply(fontes, function(p) digest::digest(file = p, algo = "sha256"), character(1))
destino <- tempfile("validacao25_", tmpdir = "tmp/fechamento_integral_1960/relatorios")
dir.create(destino, recursive = TRUE)
saida <- validate_definitivos_1960_amostra_25(paths,
  "references/censo_1960_resultados_definitivos_serie_nacional.csv", out_dir = destino)
atual <- fread(saida, encoding = "UTF-8")
chaves <- c("uf60", "tabela", "item", "sexo", "medida", "peso")
stopifnot(nrow(atual) == 2040L, !anyDuplicated(atual[, ..chaves]),
  all(atual[, .N, by = uf60]$N == 120L))
anterior <- fread("tmp/execucao_1960_20260922/validacao25_novos_17ufs_20260922_101103_802707/relatorio_novo/validacao_definitivos.csv")
setorderv(atual, chaves)
setorderv(anterior, chaves)
recalculadas <- as.integer(UF_1960_AMOSTRA_25[manifesto$ufs_recalculadas_nesta_rodada])
colunas_anteriores <- names(anterior)
stopifnot(isTRUE(all.equal(as.data.frame(atual[!uf60 %in% recalculadas, ..colunas_anteriores]),
  as.data.frame(anterior[!uf60 %in% recalculadas]), tolerance = 0, check.attributes = FALSE)))
stopifnot(all(c("valor_minimo", "valor_maximo") %in% names(atual)),
  all(is.finite(atual[tabela == 7L]$valor_minimo)),
  all(is.finite(atual[tabela == 7L]$valor_maximo)),
  all(atual[tabela == 7L]$valor_maximo >= atual[tabela == 7L]$valor_minimo),
  all(is.na(atual[tabela != 7L]$valor_minimo)),
  all(is.na(atual[tabela != 7L]$valor_maximo)))
fwrite(merge(anterior[uf60 %in% recalculadas], atual[uf60 %in% recalculadas], by = chaves,
  suffixes = c("_antes", "_depois")), file.path(destino, "ufs_recalculadas_antes_depois.csv"))
fwrite(atual[, .(celulas = .N), by = .(peso, tabela, status_celula)],
  file.path(destino, "resumo_status.csv"))
depois <- vapply(paths, function(p) digest::digest(file = p, algo = "sha256"), character(1))
stopifnot(identical(antes, depois),
  identical(hashes, vapply(fontes, function(p) digest::digest(file = p, algo = "sha256"), character(1))))
jsonlite::write_json(list(status = "CONFERIDO_NAO_PUBLICADO", indice = indice,
  arquivos_conferidos = 34L, linhas = 2040L, ufs_inalteradas = 17L - length(recalculadas),
  fontes = as.list(hashes), microdados_sha256 = as.list(antes)),
  file.path(destino, "estado.json"), auto_unbox = TRUE, pretty = TRUE)
message("VALIDACAO25_COMPLETA: ", destino)
