# Idade declarada ignorada entra em atividade/renda, sem virar idade inventada.
.libPaths(c("renv/library/windows/R-4.5/x86_64-w64-mingw32", .libPaths()))
Sys.setlocale("LC_CTYPE", "Portuguese_Brazil.utf8")
library(data.table)
setDTthreads(1L)
source("R/microdata_1960_amostra_127.R", encoding = "UTF-8")

p <- data.table(linha = 1:4, UF = 60L, censobr_idhousehold = 1:4,
  censobr_idfamily = 1:4, V203 = 7L, V118 = 1L,
  V202 = c(1L, 2L, 3L, 1L), V204 = c(9L, 1L, 9L, 1L),
  V204B = c(99L, 10L, 99L, 9L), V206 = 4L, V211 = 1L,
  V215 = 0L, V219 = c(5L, 3L, 5L, 5L), V220 = c(3L, 5L, 3L, 3L),
  V223 = 2L, V223B = 111L, censobr_weight = c(10, 20, 30, 40),
  censobr_weight_1965 = c(20, 40, 60, 80))
d <- data.table(UF = 60L, censobr_idhousehold = 1:4,
  V118 = 1L, V101 = 1L, V102 = 4L, V103 = 7L, V104 = 8L, V105 = 9L,
  V106 = 4L, V107 = 9L, V108 = 5L, V109 = 7L, V110 = 9L,
  censobr_weight = c(10, 20, 30, 40), censobr_weight_1965 = c(20, 40, 60, 80))
tab <- list(pessoas = p, domicilios = d, ufs_fornecidas = as.integer(names(REGIAO_1960)))
dir.create("tmp", showWarnings = FALSE)
test_dir <- tempfile("idade_q34_", tmpdir = "tmp")
dir.create(test_dir)
gabarito <- "references/censo_1960_resultados_preliminares_1965.csv"
celula <- function(resultado, quadro_atual, linha_atual = "TOTAIS", coluna_atual = "total", peso_atual = "censobr_weight"){
  z <- resultado[quadro == quadro_atual & linha == linha_atual & coluna == coluna_atual &
    peso == peso_atual & regiao == REGIAO_1960["60"]]
  stopifnot(nrow(z) == 1L)
  z
}
antes <- copy(p)
r <- validate_1965_1960_amostra_127(tab, gabarito, out_dir = test_dir)
for(q in 3:4) for(peso_atual in c("censobr_weight", "censobr_weight_1965")){
  z <- celula(r, q, peso_atual = peso_atual)
  stopifnot(z$n_amostra == 2L, z$n_sem_classificacao == 0L,
    z$status_celula == "observada", z$nosso == if(peso_atual == "censobr_weight") 30 else 60,
    grepl("ignorada declarada incluida", z$politica_idade))
}
stopifnot(identical(p, antes), celula(r, 3L, "agricultura_pecuaria_silvicultura", "homens")$nosso == 10,
  celula(r, 4L, "ate_2100", "agro_homens")$nosso == 10,
  celula(r, 5L)$status_celula == "classificacao_incompleta",
  celula(r, 5L)$n_sem_classificacao == 2L)

for(cenario in c("idade_danificada", "atividade_danificada", "renda_danificada", "peso_ausente", "presenca_danificada")){
  t <- list(pessoas = copy(p), domicilios = copy(d), ufs_fornecidas = tab$ufs_fornecidas)
  if(cenario == "idade_danificada") t$pessoas[linha == 1L, V204 := NA_integer_]
  if(cenario == "atividade_danificada") t$pessoas[linha == 1L, V220 := NA_integer_]
  if(cenario == "renda_danificada") t$pessoas[linha == 1L, V219 := NA_integer_]
  if(cenario == "peso_ausente") t$pessoas[linha == 1L, censobr_weight := NA_real_]
  if(cenario == "presenca_danificada") t$pessoas[linha == 1L, V202 := NA_integer_]
  z <- validate_1965_1960_amostra_127(t, gabarito, out_dir = test_dir)
  if(cenario %in% c("idade_danificada", "presenca_danificada")) for(q in 3:4){
    s <- celula(z, q)
    stopifnot(s$n_amostra == 1L, s$n_sem_classificacao == 1L,
      s$valor_parcial == 20, is.na(s$nosso), s$status_celula == "classificacao_incompleta")
  }
  if(cenario == "atividade_danificada"){
    stopifnot(celula(z, 3L)$nosso == 30, celula(z, 4L)$nosso == 30,
      celula(z, 3L, "agricultura_pecuaria_silvicultura", "homens")$n_sem_classificacao == 1L,
      celula(z, 4L, "TOTAIS", "agro_homens")$n_sem_classificacao == 1L)
  }
  if(cenario == "renda_danificada"){
    stopifnot(celula(z, 4L)$nosso == 30,
      celula(z, 4L, "ate_2100")$n_sem_classificacao == 1L,
      is.na(celula(z, 4L, "ate_2100")$nosso))
  }
  if(cenario == "peso_ausente") for(q in 3:4){
    s <- celula(z, q)
    stopifnot(s$n_amostra == 2L, s$n_pesos_ausentes == 1L,
      s$status_celula == "peso_ausente", is.na(s$nosso))
  }
}
# Os grupos vazios precisam chegar a grade, sem erro de comprimento no paste0.
menores <- list(pessoas = copy(p), domicilios = copy(d), ufs_fornecidas = tab$ufs_fornecidas)
menores$pessoas[, `:=`(V204 = 1L, V204B = 4L)]
z <- validate_1965_1960_amostra_127(menores, gabarito, out_dir = test_dir)
for(q in 2:5){
  s <- if(q == 2L) celula(z, q, "5 e mais") else celula(z, q)
  stopifnot(s$n_amostra == 0L, s$n_sem_classificacao == 0L,
    s$status_celula == "sem_observacoes", s$nosso == 0)
}
vazio <- list(pessoas = copy(p[0L]), domicilios = copy(d[0L]), ufs_fornecidas = tab$ufs_fornecidas)
z <- validate_1965_1960_amostra_127(vazio, gabarito, out_dir = test_dir)
stopifnot(nrow(z) > 0L, all(z$n_amostra == 0L), all(z$nosso == 0),
  all(z$status_celula == "sem_observacoes"))

# Contraprovas adicionais: uma classificacao perdida nao pode parecer zero.
# Acumular os resultados permite mostrar todas as falhas ANTES da correcao.
falhas_adicionais <- character()
conferir_adicional <- function(nome, passou){
  passou <- isTRUE(passou)
  message("Contraprova adicional ", nome, ": ", if(passou) "PASSOU" else "FALHOU")
  if(!passou) falhas_adicionais <<- c(falhas_adicionais, nome)
}
base_adicional <- function(){
  list(pessoas = copy(p[linha %in% 1:2]), domicilios = copy(d[censobr_idhousehold %in% 1:2]),
       ufs_fornecidas = tab$ufs_fornecidas)
}
t <- base_adicional()
t$pessoas[linha == 1L, V223 := NA_integer_]
z <- validate_1965_1960_amostra_127(t, gabarito, out_dir = test_dir)
for(peso_atual in c("censobr_weight", "censobr_weight_1965")){
  fator <- if(peso_atual == "censobr_weight") 1 else 2
  a <- celula(z, 3L, "agricultura_pecuaria_silvicultura", "homens", peso_atual)
  o <- celula(z, 3L, "outras_atividades", "homens", peso_atual)
  conferir_adicional(paste("V223_ausente_ramos", peso_atual),
    a$n_sem_classificacao == 1L && o$n_sem_classificacao == 1L &&
      a$status_celula == "classificacao_incompleta" && o$status_celula == "classificacao_incompleta" &&
      is.na(a$nosso) && is.na(o$nosso) && is.na(a$dif_pct) && is.na(o$dif_pct))
  conferir_adicional(paste("V223_ausente_totais_preservados", peso_atual),
    celula(z, 3L, peso_atual = peso_atual)$nosso == 30 * fator &&
      celula(z, 4L, peso_atual = peso_atual)$nosso == 30 * fator &&
      celula(z, 4L, "ate_2100", "agro_homens", peso_atual)$nosso == 10 * fator)
}
for(cenario in c("pessoa_UF_ausente", "pessoa_UF_invalida", "domicilio_UF_ausente", "domicilio_UF_invalida")){
  t <- base_adicional()
  nova_uf <- if(grepl("ausente$", cenario)) NA_integer_ else 999L
  if(grepl("^pessoa", cenario)) t$pessoas[linha == 1L, UF := nova_uf] else
    t$domicilios[censobr_idhousehold == 1L, UF := nova_uf]
  z <- validate_1965_1960_amostra_127(t, gabarito, out_dir = test_dir)
  for(peso_atual in c("censobr_weight", "censobr_weight_1965")){
    fator <- if(peso_atual == "censobr_weight") 1 else 2
    if(grepl("^pessoa", cenario)){
      s <- z[quadro %in% 3:4 & linha == "TOTAIS" & coluna == "total" & peso == peso_atual]
    } else {
      s <- z[quadro %in% 6:7 & linha == "TOTAIS" & coluna %in% c("dom_total", "pes_total") & peso == peso_atual]
    }
    conferir_adicional(paste(cenario, peso_atual), nrow(s) > 0L &&
      all(s$n_sem_classificacao == 1L) && all(s$status_celula == "classificacao_incompleta") &&
      all(is.na(s$nosso)) && all(is.na(s$dif_abs)) && all(is.na(s$dif_pct)) &&
      all(s[regiao == REGIAO_1960["60"], valor_parcial] == 20 * fator) &&
      all(s[regiao != REGIAO_1960["60"], valor_parcial] == 0))
  }
  diagnostico <- attr(z, "diagnostico_universos")
  unidade_esperada <- if(grepl("^pessoa", cenario)) "pessoas" else "domicilios"
  conferir_adicional(paste(cenario, "diagnostico_explicito"),
    nrow(diagnostico[unidade == unidade_esperada & motivo == "geografia_nao_classificavel"]) == 2L &&
      all(diagnostico[unidade == unidade_esperada & motivo == "geografia_nao_classificavel", n_amostra] == 1L))
}
# Uma UF perdida nao torna elegivel quem os demais campos excluem do universo.
for(cenario in c("pessoa_menor10", "pessoa_ausente", "domicilio_coletivo", "domicilio_so_visitante")){
  t <- base_adicional()
  if(grepl("^pessoa", cenario)) t$pessoas[linha == 1L, UF := NA_integer_] else
    t$domicilios[censobr_idhousehold == 1L, UF := NA_integer_]
  if(cenario == "pessoa_menor10") t$pessoas[linha == 1L, `:=`(V204 = 1L, V204B = 9L)]
  if(cenario == "pessoa_ausente") t$pessoas[linha == 1L, V202 := 3L]
  if(cenario == "domicilio_coletivo") t$domicilios[censobr_idhousehold == 1L, V101 := 3L]
  if(cenario == "domicilio_so_visitante") t$pessoas[linha == 1L, V202 := 5L]
  pessoas_antes <- copy(t$pessoas); domicilios_antes <- copy(t$domicilios)
  z <- validate_1965_1960_amostra_127(t, gabarito, out_dir = test_dir)
  stopifnot(identical(t$pessoas, pessoas_antes), identical(t$domicilios, domicilios_antes))
  for(peso_atual in c("censobr_weight", "censobr_weight_1965")){
    fator <- if(peso_atual == "censobr_weight") 1 else 2
    if(grepl("^pessoa", cenario)){
      s <- z[quadro %in% 3:4 & linha == "TOTAIS" & coluna == "total" & peso == peso_atual]
    } else {
      s <- z[quadro %in% 6:7 & linha == "TOTAIS" & coluna %in% c("dom_total", "pes_total") & peso == peso_atual]
    }
    conferir_adicional(paste(cenario, "fora_do_universo", peso_atual), all(s$n_sem_classificacao == 0L) &&
      all(s[regiao == REGIAO_1960["60"], nosso] == 20 * fator) &&
      all(s[regiao != REGIAO_1960["60"], nosso] == 0) &&
      all(s[regiao != REGIAO_1960["60"], status_celula] == "sem_observacoes"))
  }
}
if(length(falhas_adicionais)) stop("Contraprovas adicionais falharam: ", paste(falhas_adicionais, collapse = "; "))
message("Idade ignorada q3/q4 e contraprovas aprovadas: ", test_dir)
