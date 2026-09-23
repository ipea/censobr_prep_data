.libPaths(c("renv/library/windows/R-4.5/x86_64-w64-mingw32", .libPaths()))
Sys.setlocale("LC_CTYPE", "Portuguese_Brazil.utf8")
library(data.table)
setDTthreads(1L)
source("R/microdata_1960_amostra_127.R", encoding = "UTF-8")

p <- data.table(linha = 1:2, UF = 60L, censobr_idhousehold = 1:2,
  censobr_idfamily = 1:2, V203 = 7L, V118 = 1L, V202 = 1L,
  V204 = 1L, V204B = 40L, V206 = 4L, V211 = 1L, V215 = 6L,
  V219 = 5L, V220 = 3L, V223 = 2L, V223B = 111L,
  censobr_weight = 10, censobr_weight_1965 = 20)
d <- data.table(UF = 60L, censobr_idhousehold = 1:2, V118 = 1L,
  V101 = 1L, V102 = 4L, V103 = 8L, V104 = c(0L, 9L), V105 = 9L,
  V106 = 4L, V107 = 9L, V108 = 5L, V109 = 7L, V110 = 9L,
  censobr_weight = 10, censobr_weight_1965 = 20)
base <- "tmp/fechamento_integral_1960/testes"
dir.create(base, recursive = TRUE, showWarnings = FALSE)
saida <- tempfile("aluguel_", tmpdir = base)
dir.create(saida)
faixas <- c("ate_500", "501_1000", "1001_2000", "2001_4000", "4001_6000", "6001_mais")
for(codigo in c(9L, 8L, NA_integer_)){
  d[2L, V104 := codigo]
  tab <- list(pessoas = p, domicilios = d, ufs_fornecidas = as.integer(names(REGIAO_1960)))
  r <- validate_1965_1960_amostra_127(tab,
    "references/censo_1960_resultados_preliminares_1965.csv", out_dir = saida)
  z <- r[quadro == 6L & regiao == REGIAO_1960["60"] & linha %in% faixas &
         coluna %in% c("dom_total", "dom_urbana", "pes_total", "pes_urbana")]
  stopifnot(nrow(z) == 48L, all(z$status_celula == "classificacao_incompleta"),
            all(z$n_sem_classificacao == 1L), all(is.na(z$nosso)), all(is.na(z$dif_pct)))
  stopifnot(all(z[linha == "ate_500", n_amostra] == 1L),
            all(z[linha != "ate_500", n_amostra] == 0L))
  total <- r[quadro == 6L & regiao == REGIAO_1960["60"] & linha == "alugados" & coluna == "dom_total"]
  stopifnot(nrow(total) == 2L, all(total$n_amostra == 2L),
            all(total$status_celula == "observada"))
  condicao <- r[quadro == 6L & regiao == REGIAO_1960["60"] & linha == "sem_declaracao" & coluna == "dom_total"]
  stopifnot(nrow(condicao) == 2L, all(condicao$n_amostra == 0L), all(condicao$nosso == 0))
}
message("Aluguel sem faixa conferido: ", saida)
