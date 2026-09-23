.libPaths(c("renv/library/windows/R-4.5/x86_64-w64-mingw32", .libPaths()))
Sys.setlocale("LC_CTYPE", "Portuguese_Brazil.utf8")
library(data.table)
library(arrow)
library(digest)
library(jsonlite)
setDTthreads(1L)
arrow::set_cpu_count(1L)
source("R/microdata_1960_amostra_127.R", encoding = "UTF-8")

base <- "tmp/fechamento_integral_1960/relatorios"
dir.create(base, recursive = TRUE, showWarnings = FALSE)
saida <- tempfile("preliminar_base_antiga_", tmpdir = base)
dir.create(saida)
paths <- file.path("data_raw/microdata/1960/amostra_127",
  c("pessoas_1960_amostra_127.parquet", "domicilios_1960_amostra_127.parquet"))
entradas <- c(paths, "R/microdata_1960_amostra_127.R",
              "references/censo_1960_resultados_preliminares_1965.csv")
hashes <- data.table(arquivo = entradas,
  sha256 = sapply(entradas, function(x) digest(file = x, algo = "sha256")))
p <- as.data.table(read_parquet(paths[1L], col_select = c(
  "linha", "UF", "censobr_idhousehold", "censobr_idfamily", "V118", "V202", "V203",
  "V204", "V204B", "V206", "V211", "V215", "V219", "V220", "V223", "V223B",
  "censobr_weight", "censobr_weight_1965")))
d <- as.data.table(read_parquet(paths[2L], col_select = c(
  "UF", "censobr_idhousehold", "V118", "V101", "V102", "V103", "V104", "V105",
  "V106", "V107", "V108", "V109", "V110", "censobr_weight", "censobr_weight_1965")))
r <- validate_1965_1960_amostra_127(list(pessoas = p, domicilios = d),
  "references/censo_1960_resultados_preliminares_1965.csv", out_dir = saida)
resumo <- r[, .N, by = .(peso, quadro, status_celula)]
fwrite(resumo, file.path(saida, "resumo_validacao.csv"))

# Estes cenarios mudam so a convencao de elegibilidade, nunca a idade declarada.
p <- classificar_dependencia_validacao_1960_amostra_127(p)
p[, regiao := unname(REGIAO_1960[as.character(UF)])]
p[, idade := fifelse(V204 %in% 1 & V204B %in% 0:99, as.numeric(V204B),
             fifelse(V204 %in% 0 & V204B %in% 0:99, 0,
             fifelse(V204 %in% 5, 100, NA_real_)))]
p <- p[V202 %in% 1:4 & (idade >= 15 | V204 %in% 9)]
p[, estado := c("solteiros", "separados", "outros", "outros", "viuvos", "outros",
  "casados_civil_religioso", "casados_somente_civil", "casados_somente_religioso",
  "casados_sem_vinculo")[match(V215, 0:9)]]
p[, idade_declarada_ignorada := V204 %in% 9]
cenarios <- list()
for(peso in c("censobr_weight", "censobr_weight_1965")){
  z <- p[, .(regiao, estado, grupo_dependencia, idade_declarada_ignorada, w = get(peso))]
  z <- rbind(z, copy(z)[, regiao := "Brasil"])
  total <- z[, .(regiao, estado = "TOTAIS", grupo_dependencia = "total", idade_declarada_ignorada, w)]
  estados <- z[, .(regiao, estado, grupo_dependencia = "total", idade_declarada_ignorada, w)]
  grupos <- z[, .(regiao, estado = "TOTAIS", grupo_dependencia, idade_declarada_ignorada, w)]
  z <- rbind(total, estados, grupos, z)
  cenarios[[peso]] <- z[, .(
    n_idade_conhecida = sum(!idade_declarada_ignorada),
    n_idade_ignorada = sum(idade_declarada_ignorada),
    excluindo_idade_ignorada = sum(w[!idade_declarada_ignorada]),
    incluindo_idade_ignorada = sum(w),
    acrescimo_se_incluida = sum(w[idade_declarada_ignorada])),
    by = .(regiao, estado, grupo_dependencia)][, peso := peso]
  rm(z, total, estados, grupos); gc(verbose = FALSE)
}
cenarios <- rbindlist(cenarios)
conferencia <- merge(cenarios[estado == "TOTAIS" & grupo_dependencia == "total"],
  r[quadro == 5L & linha == "TOTAIS" & coluna == "total",
    .(regiao, peso, n_amostra, valor_parcial)], by = c("regiao", "peso"))
stopifnot(nrow(conferencia) == 8L,
  all(conferencia$n_idade_conhecida == conferencia$n_amostra),
  all(abs(conferencia$excluindo_idade_ignorada - conferencia$valor_parcial) < 1e-6))
fwrite(cenarios, file.path(saida, "q5_cenarios_idade_ignorada.csv"))
fwrite(conferencia, file.path(saida, "q5_conferencia_com_validador.csv"))
hashes[, sha256_depois := sapply(arquivo, function(x) digest(file = x, algo = "sha256"))]
stopifnot(all(hashes$sha256 == hashes$sha256_depois))
fwrite(hashes, file.path(saida, "entradas.csv"))
write_json(list(base = "parquets antigos: nao reconstruidos", pesos = "antigos, nao recalculados",
  finalidade = "validacao atualizada e sensibilidade de Q5, sem homologar a base",
  celulas = nrow(r), fontes_inalteradas = TRUE,
  q5 = "inclusao/exclusao explicitas; nenhum cenario certificado como regra historica"),
  file.path(saida, "estado.json"), auto_unbox = TRUE, pretty = TRUE)
message("Relatorio e cenarios concluidos sobre a base antiga: ", saida)
