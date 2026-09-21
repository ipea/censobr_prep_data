# O estimador de diferencas sucessivas (Wolter v2) para a amostra de 1960, e os
# totais da Guanabara por bairro e por circunscricao calculados com ele.
#
# As duas etapas de 1960 sao sistematicas: uma linha em quatro na Folha de
# Coleta, uma pasta em vinte no cadastro, com inicio aleatorio. Amostra
# sistematica com um unico inicio nao tem estimador de variancia nao-viesado, e
# o que o survey faz -- tratar as unidades primarias do estrato como sorteadas
# independentemente -- ignora que a lista estava ordenada por zona, municipio e
# setor. Como pastas vizinhas na lista sao vizinhas no mapa, isso superestima a
# variancia.
#
# O estimador de diferencas sucessivas compara cada unidade primaria com a
# vizinha na ordem do cadastro em vez de com a media do estrato:
#
#   V_SD = Sum_h (1 - f1) n_h / (2 (n_h - 1)) Sum_i (t_hi - t_h,i-1)^2
#
# E o "v2" de Wolter, o que o Census Bureau usa na ACS e o que o IBGE recomenda
# para a PNAD. A opcao esta documentada na secao 13.4 de
# microdata_1960_amostra_127_desenho_amostral.md; este script a implementa.
#
# Nao faz parte do pipeline: e script de analise, para rodar a mao.

library(data.table)
library(survey)
library(svrep)

options(survey.lonely.psu = "adjust")

# ------------------------------------------------------------------------------
# O estimador
#
# Recebe a tabela inteira e um vetor de dominio, nunca a tabela ja filtrada: a
# pasta que nao tem ninguem do dominio entra com total zero, e precisa entrar,
# porque e a ordem do cadastro que da sentido a diferenca sucessiva.
#
# Devolve os dois erros-padrao lado a lado. A segunda etapa entra nos dois pela
# mesma formula do conglomerado ultimo -- f1 (1 - f2) ... -- porque a ordem do
# cadastro descreve o sorteio das pastas, nao o dos domicilios dentro delas.
#
# Serve as duas metades do compilado. Nas dezessete da amostra de 25% a unidade
# primaria e o domicilio e censobr_upa sobe na ordem do cadastro (pasta,
# boletim), que e a ordem da Folha de Coleta; nas onze da de 1,27% e a pasta, e
# censobr_upa e o proprio numero dela.
# ------------------------------------------------------------------------------
successive_differences_1960 <- function(p, dominio){

  p[, y := as.integer(dominio)][is.na(y), y := 0L]

  usa <- p[, .(t = sum(y * censobr_weight)),
           by = .(censobr_estrato, censobr_upa, censobr_usa, censobr_fpc, censobr_fpc2)]
  upa <- usa[, .(t = sum(t), f1 = censobr_fpc[1]), by = .(censobr_estrato, censobr_upa)]
  setorder(upa, censobr_estrato, censobr_upa)

  # conglomerado ultimo: cada pasta contra a media do estrato
  v_uc <- upa[, .(n = .N, soma = sum(t), soma2 = sum(t^2), f1 = f1[1]), by = censobr_estrato
              ][, sum(fifelse(n > 1, (1 - f1) * n / (n - 1) * (soma2 - soma^2 / n), 0))]

  # diferencas sucessivas: cada pasta contra a vizinha na ordem do cadastro
  v_sd <- upa[, .(n = .N, d2 = sum(diff(t)^2), f1 = f1[1]), by = censobr_estrato
              ][, sum(fifelse(n > 1, (1 - f1) * n / (2 * (n - 1)) * d2, 0))]

  # a variante circular de Fay-Train, que e a que os pesos replicados do svrep
  # implementam: fecha a lista somando (t_1 - t_n)^2 e dispensa o n/(n-1)
  v_sdr <- upa[, .(n = .N, d2 = sum(diff(t)^2) + (t[1] - t[.N])^2, f1 = f1[1]),
               by = censobr_estrato][, sum(fifelse(n > 1, (1 - f1) * 0.5 * d2, 0))]

  # a etapa dos domicilios, so onde ela existe
  v_2 <- usa[censobr_fpc2 < 1, .(m = .N, soma = sum(t), soma2 = sum(t^2),
                                 f1 = censobr_fpc[1], f2 = censobr_fpc2[1]),
             by = .(censobr_estrato, censobr_upa)
             ][, sum(fifelse(m > 1, f1 * (1 - f2) * m / (m - 1) * (soma2 - soma^2 / m), 0))]

  estimativa <- sum(upa$t)
  data.table(estimativa   = estimativa,
             ep_uc        = sqrt(v_uc + v_2),
             ep_sd        = sqrt(v_sd + v_2),
             ep_sdr       = sqrt(v_sdr + v_2),
             cv_uc        = 100 * sqrt(v_uc + v_2) / estimativa,
             cv_sd        = 100 * sqrt(v_sd + v_2) / estimativa,
             upas         = nrow(upa),
             upas_dominio = sum(upa$t > 0),
             etapa2_pct   = 100 * v_2 / (v_uc + v_2))
}


# ------------------------------------------------------------------------------
# 1. A Guanabara
#
# Sai inteira da amostra de 1,27%: 41 pastas num estrato so, e nenhum estrato
# dela atravessa a fronteira da unidade da federacao, de modo que a UF sozinha
# descreve o desenho. O parquet publicado da o mesmo, com
# filter(name_state_1960 == "Guanabara").
# ------------------------------------------------------------------------------
gb <- setDT(arrow::read_parquet("./data_raw/microdata/1960/compilada/gb/pessoas.parquet",
  col_select = c("code_bairro_1960", "name_bairro_1960", "code_district_1960",
                 "name_district_1960", "censobr_favela", "V202", "censobr_estrato",
                 "censobr_upa", "censobr_usa", "censobr_fpc", "censobr_fpc2",
                 "censobr_weight")))

# V202 traz sexo e condicao de presenca no mesmo algarismo: 3 e 4 sao os ausentes
gb[, presente := as.integer(!V202 %in% c(3L, 4L))]
gb[, tipo := fifelse(censobr_favela == 1, "favela", "circunscricao")]

message("Guanabara: ", nrow(gb), " pessoas, ", uniqueN(gb$censobr_upa), " pastas, ",
        uniqueN(gb$censobr_estrato), " estrato")

total <- successive_differences_1960(gb, gb$presente)
print(total)


# ------------------------------------------------------------------------------
# 2. A conferencia contra os pesos replicados do svrep
#
# A secao 13.4 documenta a via dos pesos replicados: svrep::as_sdr_design()
# constroi os pesos de diferencas sucessivas a partir de um desenho de uma
# etapa. Ela nao devolve o numero da formula de Wolter, e a diferenca nao e
# ruido de replicacao -- o svrep da 157.972 com 96, 192, 384 e 768 replicas,
# sempre o mesmo numero. O que ele implementa e o SDR de Fay-Train, que trata a
# lista como circular: soma (t_1 - t_n)^2, a diferenca entre a primeira pasta do
# cadastro e a ultima, e dispensa o fator n/(n-1). Na Guanabara esse termo vale
# 15,3% da soma das diferencas e sobe o erro-padrao em 6%.
#
# A coluna ep_sdr reproduz esse numero no digito, e e por ela que a conferencia
# passa. O default e ep_sd, a formula de Wolter, porque a primeira e a ultima
# pasta do cadastro nao sao vizinhas em coisa nenhuma: a diferenca entre elas e
# a de um par qualquer, e conta-la infla a variancia sem justificativa de
# desenho. O termo circular e artefato da construcao de Hadamard, nao hipotese
# sobre o sorteio.
# ------------------------------------------------------------------------------
gb_ord <- gb[order(censobr_estrato, censobr_upa)]

d1 <- svydesign(ids = ~censobr_upa, strata = ~censobr_estrato, weights = ~censobr_weight,
                fpc = ~censobr_fpc, data = gb_ord)
sdr <- as_sdr_design(d1, replicates = 96, sort_variable = "censobr_upa",
                     use_normal_hadamard = TRUE)

t_sdr <- svytotal(~presente, sdr)
message("populacao presente: ", round(coef(t_sdr)),
        " | svrep ", round(SE(t_sdr)), " | ep_sdr ", round(total$ep_sdr),
        " | ep_sd (Wolter) ", round(total$ep_sd),
        " | a etapa dos domicilios vale ", round(total$etapa2_pct, 2), "% da variancia")


# ------------------------------------------------------------------------------
# 3. Os totais por bairro e por circunscricao
#
# O bairro e a Circunscricao Censitaria em que o tomo XII do Volume I publica a
# cidade; o que o censo chamou de distrito na Guanabara e a circunscricao (ate
# 40) ou a favela (41 e acima) dentro do bairro.
# ------------------------------------------------------------------------------
bairros <- gb[!is.na(name_bairro_1960), unique(name_bairro_1960)]
por_bairro <- rbindlist(lapply(bairros, function(b)
  cbind(name_bairro_1960 = b,
        successive_differences_1960(gb, gb$presente & gb$name_bairro_1960 == b))))
setorder(por_bairro, -estimativa)
print(por_bairro, nrows = 50)

pares <- unique(gb[!is.na(name_bairro_1960) & !is.na(name_district_1960),
                   .(name_bairro_1960, name_district_1960, tipo)])
por_distrito <- rbindlist(lapply(seq_len(nrow(pares)), function(i)
  cbind(pares[i], successive_differences_1960(
    gb, gb$presente & gb$name_bairro_1960 == pares$name_bairro_1960[i] &
        gb$name_district_1960 == pares$name_district_1960[i]))))
setorder(por_distrito, -estimativa)
print(por_distrito, nrows = 60)

message("\nbairros de uma pasta so: ", sum(por_bairro$upas_dominio == 1), " de ", nrow(por_bairro),
        " | ganho mediano do SD nos de duas ou mais: ",
        round(100 * (1 - median(por_bairro[upas_dominio > 1, ep_sd / ep_uc])), 1), "%")
