# Testes isolados executados com sucesso em 22/09/2026 pelo runner autorizado.
# Ver microdata_1960_validacao_etapa4_20260922.md. Nao chama targets, nao
# recalibra pesos e escreve os CSVs apenas em uma pasta temporaria de teste.
# Uso futuro, da raiz: source("references/test_validacao_amostra_127.R")
.libPaths(c("renv/library/windows/R-4.5/x86_64-w64-mingw32", .libPaths()))
Sys.setlocale("LC_CTYPE", "Portuguese_Brazil.utf8")
library(data.table)
setDTthreads(1L)
source("R/microdata_1960_amostra_127.R", encoding = "UTF-8")

# Contrato da grade: zero amostral, quesito nao reconstruido, peso ausente,
# referencia zero com divergencia absoluta e rejeicao de chaves duplicadas.
g <- data.table(chave = c("vazio", "nao_reconstruido", "peso_na", "publicado_zero"),
                publicado = c(20, 30, 40, 0), reconstruivel = c(TRUE, FALSE, TRUE, TRUE))
z <- data.table(chave = c("peso_na", "publicado_zero"), nosso = c(NA_real_, 10),
                n_amostra = c(2L, 1L), n_pesos_ausentes = c(1L, 0L))
r <- completar_validacao_1960_amostra_127(g, z, "chave")
stopifnot(nrow(r) == nrow(g), r[chave == "vazio", status_celula] == "sem_observacoes",
          r[chave == "vazio", nosso] == 0, r[chave == "vazio", dif_pct] == -100,
          r[chave == "nao_reconstruido", status_celula] == "nao_reconstruida",
          is.na(r[chave == "nao_reconstruido", nosso]),
          r[chave == "peso_na", status_celula] == "peso_ausente",
          is.na(r[chave == "peso_na", nosso]), is.na(r[chave == "peso_na", dif_abs]),
          r[chave == "publicado_zero", dif_abs] == 10,
          is.na(r[chave == "publicado_zero", dif_pct]),
          inherits(try(completar_validacao_1960_amostra_127(rbind(g, g[1]), z, "chave"), silent = TRUE), "try-error"))
stopifnot(is.na(somar_validacao_1960_amostra_127(c(10, NA_real_))$nosso),
          somar_validacao_1960_amostra_127(c(10, NA_real_))$n_pesos_ausentes == 1L,
          is.na(somar_validacao_1960_amostra_127(c(10, Inf))$nosso),
          somar_validacao_1960_amostra_127(numeric())$n_amostra == 0L)

# Uma soma parcial nao pode continuar na coluna usada como estimativa completa.
g_parcial <- data.table(chave = "parcial", publicado = 20, reconstruivel = TRUE,
                       n_sem_classificacao = 1L)
z_parcial <- data.table(chave = "parcial", nosso = 10, n_amostra = 1L,
                       n_pesos_ausentes = 0L)
r_parcial <- completar_validacao_1960_amostra_127(g_parcial, z_parcial, "chave")
stopifnot(nrow(r_parcial) == 1L, r_parcial$status_celula == "classificacao_incompleta",
          r_parcial$n_sem_classificacao == 1L, r_parcial$valor_parcial == 10,
          is.na(r_parcial$nosso), is.na(r_parcial$dif_abs), is.na(r_parcial$dif_pct))

# O domicilio 2 tem somente visitante: fica fora do universo domiciliar ocupado
# por moradores, sem apagar a pessoa das tabelas de presentes. O registro 3 tem presenca
# desconhecida. O registro 6 declara idade ignorada; o 8 tem situacao ignorada.
p <- data.table(linha = 1:8, UF = c(0L, 0L, 0L, 0L, 3L, 60L, 60L, 60L),
  censobr_idhousehold = c(1L, 1L, 1L, 1L, 2L, 3L, 3L, 3L),
  censobr_idfamily = c(1L, 1L, 1L, 1L, 2L, 3L, 3L, 3L),
  V203 = c(7L, 1L, 2L, 0L, 7L, 7L, 0L, 1L),
  V118 = c(1L, 1L, 1L, 1L, 1L, 5L, 5L, NA_integer_),
  V202 = c(1L, 2L, NA_integer_, 3L, 5L, 1L, 2L, 1L),
  V204 = c(1L, 1L, NA_integer_, 1L, 1L, 9L, 5L, 1L),
  V204B = c(44L, 6L, NA_integer_, 50L, 10L, 99L, 3L, 30L),
  V206 = c(4L, 7L, NA_integer_, 4L, 4L, 9L, 8L, NA_integer_),
  V211 = c(1L, 2L, NA_integer_, 1L, 0L, 1L, 3L, 1L),
  V215 = c(6L, 0L, NA_integer_, 6L, 0L, 0L, 4L, 0L),
  V219 = c(5L, 3L, NA_integer_, 5L, 5L, 3L, 3L, 5L),
  V220 = c(3L, 5L, NA_integer_, 3L, 3L, 3L, 6L, 3L),
  V223 = c(2L, NA_integer_, NA_integer_, 2L, 2L, 2L, NA_integer_, 2L),
  V223B = c(111L, NA_integer_, NA_integer_, 111L, 351L, 111L, NA_integer_, 411L),
  censobr_weight = rep(10, 8), censobr_weight_1965 = rep(20, 8))
d <- data.table(UF = c(0L, 3L, 60L), censobr_idhousehold = 1:3,
  V118 = c(1L, 1L, 5L), V101 = 1L, V102 = 4L, V103 = 7L, V104 = 8L, V105 = c(9L, 9L, 4L),
  V106 = 4L, V107 = 9L, V108 = 5L, V109 = 7L, V110 = 9L,
  censobr_weight = rep(10, 3), censobr_weight_1965 = rep(20, 3))
# Esta base artificial declara as demais UFs fornecidas e vazias. Sem essa
# declaracao, UF/regiao nao fornecida deve ser nao_reconstruida, nunca zero.
tab <- list(pessoas = p, domicilios = d, ufs_fornecidas = as.integer(names(REGIAO_1960)))
dir.create("tmp", showWarnings = FALSE)
test_dir <- tempfile("validacao_1960_", tmpdir = "tmp")
dir.create(test_dir)
pre_path <- "references/censo_1960_resultados_preliminares_1965.csv"
def_path <- "references/censo_1960_resultados_definitivos_serie_nacional.csv"
pre <- validate_1965_1960_amostra_127(tab, pre_path, out_dir = test_dir)
def <- validate_definitivos_1960_amostra_127(tab, def_path, out_dir = test_dir)
stopifnot(nrow(pre) == 2L * nrow(fread(pre_path)[regiao != "Brasil"]),
          nrow(def) == 2L * nrow(fread(def_path)[nivel == "uf"]),
          !anyDuplicated(pre[, .(peso, quadro, regiao, linha, coluna)]),
          !anyDuplicated(def[, .(peso, tabela, uf60, item, sexo, medida)]))

# Impede sucesso por seletor vazio: cada assercao individual exige uma unica celula.
celula_def <- function(x, tab, uf, categoria, sx = "total", med = ""){
  z <- x[peso == "censobr_weight" & tabela == tab & uf60 == uf & item == categoria & sexo == sx & medida == med]
  stopifnot(nrow(z) == 1L)
  z
}
celula_pre <- function(x, q, reg, categoria, col){
  z <- x[peso == "censobr_weight" & quadro == q & regiao == reg & linha == categoria & coluna == col]
  stopifnot(nrow(z) == 1L)
  z
}
stopifnot(celula_def(def, 34L, 0L, "rural")$n_amostra == 0L,
          celula_def(def, 32L, 0L, "presente")$n_amostra == 2L,
          celula_def(def, 7L, 3L, "total", "", "pessoas")$n_amostra == 0L,
          celula_def(def, 7L, 3L, "total", "", "pessoas")$status_celula == "sem_observacoes",
          celula_def(def, 33L, 60L, "ignorada", "homens")$n_amostra == 1L,
          celula_def(def, 33L, 60L, "70 e mais", "mulheres")$n_amostra == 1L,
          celula_def(def, 34L, 60L, "total", "homens")$n_amostra == 2L,
          celula_def(def, 34L, 60L, "rural", "homens")$n_amostra == 1L,
          all(pre[quadro == 5L & coluna != "total", status_celula] != "nao_reconstruida"),
          all(pre[quadro == 6L & linha == "ate_500", status_celula] != "nao_reconstruida"))
stopifnot(celula_def(def, 7L, 3L, "total", "", "domicilios")$n_amostra == 0L,
          celula_def(def, 40L, 60L, "sabem", "homens")$n_amostra == 2L,
          celula_def(def, 40L, 60L, "sabem", "homens")$nosso == 20,
          celula_def(def, 40L, 60L, "5 e mais", "homens")$n_amostra == 2L,
          celula_def(def, 37L, 60L, "pardos", "mulheres")$n_amostra == 1L,
          celula_def(def, 34L, 60L, "rural", "homens")$status_celula == "classificacao_incompleta",
          celula_def(def, 34L, 60L, "total", "homens")$status_celula == "observada",
          all(def[tabela == 7L, referencia_estimada]),
          !celula_def(def, 32L, 0L, "presente")$referencia_estimada,
          nrow(pre[quadro == 5L & coluna != "total"]) > 0L,
          nrow(pre[quadro == 6L & linha == "ate_500"]) > 0L,
          celula_pre(pre, 7L, REGIAO_1960["60"], "agua_outra_sem_declaracao", "dom_total")$n_amostra == 1L)

# Dano nao vira declaracao 999 nem desaparece como se a celula estivesse completa.
tab_dano <- list(pessoas = rbind(copy(p), copy(p[8L])[, `:=`(linha = 9L, V118 = 5L, V204B = NA_integer_)]), domicilios = copy(d))
tab_dano$ufs_fornecidas <- tab$ufs_fornecidas
def_dano <- validate_definitivos_1960_amostra_127(tab_dano, def_path, out_dir = test_dir)
cel <- celula_def(def_dano, 40L, 60L, "sabem", "homens")
stopifnot(cel$n_amostra == 2L, cel$n_sem_classificacao == 1L,
          cel$status_celula == "classificacao_incompleta", cel$valor_parcial == 20,
          is.na(cel$nosso), celula_def(def_dano, 33L, 60L, "ignorada", "homens")$n_amostra == 1L)
ignorada <- celula_def(def_dano, 33L, 60L, "ignorada", "homens")
stopifnot(ignorada$n_sem_classificacao == 0L, ignorada$status_celula == "observada", ignorada$nosso == 10)

# Casa sem lista permanece pendente, nao vira casa comprovadamente sem morador.
tab_sem_lista <- list(pessoas = copy(p), domicilios = rbind(copy(d), copy(d[2L])[, censobr_idhousehold := 4L]))
tab_sem_lista$ufs_fornecidas <- tab$ufs_fornecidas
def_sem_lista <- validate_definitivos_1960_amostra_127(tab_sem_lista, def_path, out_dir = test_dir)
cel <- celula_def(def_sem_lista, 7L, 3L, "total", "", "domicilios")
stopifnot(cel$n_amostra == 1L, cel$n_sem_classificacao == 1L,
          cel$status_celula == "classificacao_incompleta", cel$valor_parcial == 10)

# Improvisado entra no total particular preliminar, mas nao em agua nem permanentes.
tab_improvisado <- list(pessoas = rbind(copy(p), copy(p[5L])[, `:=`(linha = 10L, censobr_idhousehold = 5L, V202 = 1L)]),
  domicilios = rbind(copy(d), copy(d[2L])[, `:=`(censobr_idhousehold = 5L, V102 = 6L, V103 = NA_integer_, V105 = NA_integer_)]))
tab_improvisado$ufs_fornecidas <- tab$ufs_fornecidas
pre_improvisado <- validate_1965_1960_amostra_127(tab_improvisado, pre_path, out_dir = test_dir)
def_improvisado <- validate_definitivos_1960_amostra_127(tab_improvisado, def_path, out_dir = test_dir)
stopifnot(celula_pre(pre_improvisado, 7L, REGIAO_1960["3"], "TOTAIS", "dom_total")$n_amostra == 2L,
          celula_pre(pre_improvisado, 7L, REGIAO_1960["3"], "agua_outra_sem_declaracao", "dom_total")$n_amostra == 0L,
          celula_pre(pre_improvisado, 7L, REGIAO_1960["3"], "agua_outra_sem_declaracao", "dom_total")$status_celula == "sem_observacoes",
          celula_def(def_improvisado, 7L, 3L, "total", "", "domicilios")$n_amostra == 0L)

tab_agua_perdida <- list(pessoas = copy(p), domicilios = copy(d), ufs_fornecidas = tab$ufs_fornecidas)
tab_agua_perdida$domicilios[censobr_idhousehold == 3L, V105 := NA_integer_]
pre_agua_perdida <- validate_1965_1960_amostra_127(tab_agua_perdida, pre_path, out_dir = test_dir)
cel <- celula_pre(pre_agua_perdida, 7L, REGIAO_1960["60"], "agua_outra_sem_declaracao", "dom_total")
stopifnot(cel$n_amostra == 0L, cel$n_sem_classificacao == 1L,
          cel$status_celula == "classificacao_incompleta", is.na(cel$nosso), cel$valor_parcial == 0)

# Ativo sem ramo nao e inativo; o detalhe perdido torna a comparacao parcial.
tab_ramo <- list(pessoas = copy(p), domicilios = copy(d))
tab_ramo$ufs_fornecidas <- tab$ufs_fornecidas
tab_ramo$pessoas[linha == 1L, V223B := NA_integer_]
pre_ramo <- validate_1965_1960_amostra_127(tab_ramo, pre_path, out_dir = test_dir)
cel <- celula_pre(pre_ramo, 3L, REGIAO_1960["0"], "condicoes_inativas", "total")
stopifnot(cel$n_amostra == 0L, cel$status_celula == "classificacao_incompleta")

# A duplicacao do gabarito deve falhar antes de qualquer soma que a esconda.
gab_dup <- fread(def_path)
gab_dup <- rbind(gab_dup, gab_dup[nivel == "uf"][1L])
dup_path <- file.path(test_dir, "gabarito_duplicado.csv")
fwrite(gab_dup, dup_path)
erro_dup <- try(validate_definitivos_1960_amostra_127(tab, dup_path, out_dir = test_dir), silent = TRUE)
stopifnot(inherits(erro_dup, "try-error"), grepl("chave duplicada", as.character(erro_dup)))
gab_brancos <- fread(def_path)
gab_brancos[is.na(sexo), sexo := ""]
gab_brancos[is.na(medida), medida := ""]
duplicada <- copy(gab_brancos[nivel == "uf" & tabela == 7L][1L])[, sexo := NA_character_]
dup_brancos_path <- file.path(test_dir, "gabarito_duplicado_brancos.csv")
fwrite(rbind(gab_brancos, duplicada), dup_brancos_path, na = "NA")
erro_dup <- try(validate_definitivos_1960_amostra_127(tab, dup_brancos_path, out_dir = test_dir), silent = TRUE)
stopifnot(inherits(erro_dup, "try-error"), grepl("chave duplicada", as.character(erro_dup)))

tab_parcial <- list(pessoas = copy(p), domicilios = copy(d))
def_parcial <- validate_definitivos_1960_amostra_127(tab_parcial, def_path, out_dir = test_dir)
pre_parcial <- validate_1965_1960_amostra_127(tab_parcial, pre_path, out_dir = test_dir)
stopifnot(celula_def(def_parcial, 32L, 1L, "presente")$status_celula == "nao_reconstruida",
          is.na(celula_def(def_parcial, 32L, 1L, "presente")$nosso),
          celula_pre(pre_parcial, 7L, REGIAO_1960["0"], "TOTAIS", "dom_total")$status_celula == "nao_reconstruida")

tab_so_domicilio <- list(pessoas = copy(p[UF != 0L]), domicilios = copy(d))
def_so_domicilio <- validate_definitivos_1960_amostra_127(tab_so_domicilio, def_path, out_dir = test_dir)
stopifnot(celula_def(def_so_domicilio, 32L, 0L, "presente")$status_celula == "nao_reconstruida",
          celula_def(def_so_domicilio, 7L, 0L, "total", "", "domicilios")$status_celula == "classificacao_incompleta")

# Sem o registro de presenca incerta, o rural ausente e zero observado genuino.
tab_ro <- list(pessoas = copy(p[V202 %in% 1:6]), domicilios = copy(d), ufs_fornecidas = tab$ufs_fornecidas)
def_ro <- validate_definitivos_1960_amostra_127(tab_ro, def_path, out_dir = test_dir)
cel <- celula_def(def_ro, 34L, 0L, "rural")
stopifnot(cel$n_amostra == 0L, cel$n_sem_classificacao == 0L,
          cel$status_celula == "sem_observacoes", cel$nosso == 0, cel$dif_pct == -100)
# Um peso de residente ausente tem de permanecer ausente apos o join ao
# domicilio: nao se confunde com o domicilio que tem zero residentes.
tab_na <- list(pessoas = copy(p), domicilios = copy(d))
tab_na$ufs_fornecidas <- tab$ufs_fornecidas
tab_na$pessoas[linha == 1L, censobr_weight := NA_real_]
def_na <- validate_definitivos_1960_amostra_127(tab_na, def_path, out_dir = test_dir)
stopifnot(celula_def(def_na, 7L, 0L, "total", "", "pessoas")$status_celula == "peso_ausente",
          celula_def(def_na, 7L, 0L, "total", "", "pessoas")$n_pesos_ausentes == 1L)
# Q5: duas familias no mesmo domicilio; a chefe ausente e moradora da familia 10.
# A dependente herda industria (391), nao agro do chefe da outra familia.
pq5 <- rbindlist(lapply(1:5, function(i) copy(p[1L])[, `:=`(
  linha = i, UF = 60L, censobr_idhousehold = 90L,
  censobr_idfamily = c(10L, 10L, 20L, 20L, 20L)[i],
  V203 = c(7L, 0L, 7L, 0L, 1L)[i], V202 = c(4L, 2L, 1L, 2L, 1L)[i],
  V204 = 1L, V204B = 40L, V215 = 0L,
  V220 = c(3L, 5L, 3L, 6L, 3L)[i],
  V223B = c(391L, NA_integer_, 111L, NA_integer_, 919L)[i])]))
dq5 <- copy(d[3L])[, censobr_idhousehold := 90L]
tq5 <- list(pessoas = pq5, domicilios = dq5, ufs_fornecidas = tab$ufs_fornecidas)
rq5 <- validate_1965_1960_amostra_127(tq5, pre_path, out_dir = test_dir)
for(item_q5 in c("solteiros", "TOTAIS")){
  z <- celula_pre(rq5, 5L, REGIAO_1960["60"], item_q5, "ind_mulheres")
  stopifnot(z$n_amostra == 2L, z$nosso == 20, z$n_sem_classificacao == 0L)
  z <- celula_pre(rq5, 5L, REGIAO_1960["60"], item_q5, "agro_mulheres")
  stopifnot(z$n_amostra == 1L, z$nosso == 10, z$n_sem_classificacao == 0L)
  z <- celula_pre(rq5, 5L, REGIAO_1960["60"], item_q5, "outras_homens")
  stopifnot(z$n_amostra == 1L, z$nosso == 10)
}
for(cenario in c("sem_chefe", "dois_chefes", "ramo_chefe_ausente", "chefe_visitante", "idade_ignorada")){
  t <- list(pessoas = copy(pq5), domicilios = copy(dq5), ufs_fornecidas = tab$ufs_fornecidas)
  if(cenario == "sem_chefe") t$pessoas[linha == 1L, V203 := 0L]
  if(cenario == "dois_chefes") t$pessoas <- rbind(t$pessoas, copy(pq5[1L])[, linha := 6L])
  if(cenario == "ramo_chefe_ausente") t$pessoas[linha == 1L, V223B := NA_integer_]
  if(cenario == "chefe_visitante") t$pessoas[linha == 1L, V202 := 6L]
  if(cenario == "idade_ignorada") t$pessoas[linha == 2L, V204 := 9L]
  r <- validate_1965_1960_amostra_127(t, pre_path, out_dir = test_dir)
  z <- celula_pre(r, 5L, REGIAO_1960["60"], "TOTAIS", "ind_mulheres")
  stopifnot(z$n_sem_classificacao > 0L, z$status_celula == "classificacao_incompleta",
            is.na(z$nosso), is.na(z$dif_pct))
  z <- celula_pre(r, 5L, REGIAO_1960["60"], "TOTAIS", "total")
  stopifnot(z$status_celula == if(cenario == "idade_ignorada") "classificacao_incompleta" else "observada")
}
tq5$pessoas[linha %in% c(1L, 3L), `:=`(V220 = 4L, V223B = NA_integer_)]
rq5 <- validate_1965_1960_amostra_127(tq5, pre_path, out_dir = test_dir)
z <- celula_pre(rq5, 5L, REGIAO_1960["60"], "solteiros", "inativas_mulheres")
stopifnot(z$n_amostra == 3L, z$nosso == 30, z$status_celula == "observada")

# Q6: os oito codigos validos de aluguel viram seis faixas. Codigo 9 de aluguel
# continua no total alugado, mas nao e "sem declaracao de condicao" (V103 = 0).
dq6 <- rbindlist(lapply(0:9, function(i) copy(d[3L])[, `:=`(
  censobr_idhousehold = 100L + i, V103 = if(i == 8L) 0L else 8L, V104 = i)]))
pq6 <- rbindlist(lapply(0:9, function(i) copy(p[1L])[, `:=`(
  linha = i + 1L, UF = 60L, censobr_idhousehold = 100L + i,
  censobr_idfamily = 100L + i, V203 = 7L, V202 = 1L)]))
tq6 <- list(pessoas = pq6, domicilios = dq6, ufs_fornecidas = tab$ufs_fornecidas)
rq6 <- validate_1965_1960_amostra_127(tq6, pre_path, out_dir = test_dir)
for(faixa_q6 in c("ate_500", "501_1000", "1001_2000", "2001_4000", "4001_6000", "6001_mais", "sem_declaracao")){
  for(medida_q6 in c("dom_total", "pes_total")){
    z <- celula_pre(rq6, 6L, REGIAO_1960["60"], faixa_q6, medida_q6)
    esperado <- if(faixa_q6 == "6001_mais") 3L else 1L
    stopifnot(z$n_amostra == esperado, z$nosso == 10 * esperado,
              z$status_celula == "observada", z$n_sem_classificacao == 0L)
  }
}
z <- celula_pre(rq6, 6L, REGIAO_1960["60"], "alugados", "dom_total")
stopifnot(z$n_amostra == 9L, z$nosso == 90)
for(valor_renda in c(NA_integer_, 8L)){
  tq6$domicilios[censobr_idhousehold == 109L, V104 := valor_renda]
  r <- validate_1965_1960_amostra_127(tq6, pre_path, out_dir = test_dir)
  z <- celula_pre(r, 6L, REGIAO_1960["60"], "ate_500", "dom_total")
  stopifnot(z$n_sem_classificacao == 1L, z$valor_parcial == 10,
            z$status_celula == "classificacao_incompleta", is.na(z$nosso))
  z <- celula_pre(r, 6L, REGIAO_1960["60"], "sem_declaracao", "dom_total")
  stopifnot(z$n_amostra == 1L, z$nosso == 10, z$status_celula == "observada")
}
message("Testes de validacao passaram. Artefatos isolados: ", test_dir)
