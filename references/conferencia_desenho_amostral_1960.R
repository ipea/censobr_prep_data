# Confere o cálculo de erro amostral do passo 11 contra o pacote `survey`, e mede o custo dos estimadores
# alternativos discutidos em references/microdata_1960_amostra_127_desenho_amostral.md.
#
# Não faz parte do pipeline: é um script de conferência, para rodar à mão quando o desenho mudar. É também
# o que mantém `survey` e `svrep` no renv.lock do projeto.

library(data.table)
library(targets)
library(survey)
library(svrep)

options(survey.lonely.psu = "adjust")
tab <- tar_read(tabelas_calibradas_1960_amostra_127)

pessoas <- copy(tab$pessoas)
pessoas <- pessoas[!(V202 %in% c(3, 4)) & !is.na(V202)]
pessoas[, situacao := fifelse(V118 %in% c(1, 3), "urbana", fifelse(V118 %in% 5, "rural", NA_character_))]
pessoas[, um := 1]
pessoas[, regiao := c("0"="Norte e Centro-Oeste","1"="Norte e Centro-Oeste","2"="Norte e Centro-Oeste","3"="Norte e Centro-Oeste","4"="Norte e Centro-Oeste","6"="Norte e Centro-Oeste","10"="Nordeste","12"="Nordeste","14"="Nordeste","17"="Nordeste","19"="Nordeste","21"="Nordeste","24"="Nordeste","25"="Nordeste","30"="Leste","31"="Leste","40"="Leste","50"="Leste","51"="Leste","52"="Leste","54"="Leste","60"="Sul","71"="Sul","74"="Sul","81"="Sul","91"="Norte e Centro-Oeste","94"="Norte e Centro-Oeste","97"="Norte e Centro-Oeste")[as.character(UF)]]
pessoas[, fpc := fifelse(UF == 24L, 1, 1 / 20)]            # uma pasta em vinte; em Fernando de Noronha a única pasta era o cadastro inteiro
pessoas[, ordem_cadastro := as.integer(sub(".*-", "", censobr_upa))]
setorder(pessoas, censobr_estrato, ordem_cadastro)

# 1. o mesmo desenho, pelo survey
desenho <- svydesign(ids = ~censobr_upa, strata = ~censobr_estrato, weights = ~censobr_weight,
                     fpc = ~fpc, data = pessoas)

nosso <- fread("data_raw/microdata/1960/amostra_127/erros_amostrais.csv", encoding = "UTF-8")[peso == "censobr_weight"]
por_regiao <- svyby(~um, ~regiao, desenho, svytotal)

message("total do Brasil: survey ", round(coef(svytotal(~um, desenho))), " | nosso ", nosso[regiao == "Brasil" & situacao == "ambas", estimativa])
message("erro-padrão por região, survey vs passo 11:")
for(i in seq_len(nrow(por_regiao))){
  r <- por_regiao[[1]][i]
  message("  ", r, ": ", round(SE(por_regiao)[i]), " vs ", nosso[regiao == r & situacao == "ambas", erro_padrao])
}

# 2. o custo de cada estimador, em segundos
pasta <- pessoas[, .(t = sum(censobr_weight), h = censobr_estrato[1], o = ordem_cadastro[1]), by = censobr_upa]
tempo_ultimo <- system.time({
  n <- pasta[, .N, by = h]
  v <- merge(pasta[, .(soma2 = sum(t^2), soma = sum(t)), by = h], n, by = "h")[, sum((1 - 1/20) * N / (N - 1) * (soma2 - soma^2 / N))]
})[["elapsed"]]
tempo_sd <- system.time({
  setorder(pasta, h, o)
  pasta[, .(v = if(.N > 1) .N / (2 * (.N - 1)) * sum(diff(t)^2) else 0), by = h][, sum(v)]
})[["elapsed"]]
tempo_sdr <- system.time({
  sdr <- as_sdr_design(desenho, replicates = 96, sort_variable = "ordem_cadastro", use_normal_hadamard = TRUE)
  svytotal(~um, sdr)
})[["elapsed"]]
message("custo: conglomerado último ", round(tempo_ultimo, 2), "s | diferenças sucessivas ", round(tempo_sd, 2),
        "s | pesos replicados SDR (96 réplicas) ", round(tempo_sdr, 1), "s")

# 3. a parte que falta da variância da etapa dos domicílios, que o passo 11 soma ao estimador entre pastas
pessoas[, um_w := um * censobr_weight]
dentro <- pessoas[, .(m = uniqueN(censobr_idhousehold), f = fpc[1], s1 = sum(um_w), s2 = sum(tapply(um_w, censobr_idhousehold, sum)^2)), by = censobr_upa]
v_dentro <- dentro[m > 1, sum(f * (1 - 1/4) * m / (m - 1) * (s2 - s1^2 / m))]
v_entre <- vcov(svytotal(~um, desenho))[1, 1]
message("população presente: erro-padrão entre pastas ", round(sqrt(v_entre)), " | com a etapa dos domicílios ",
        round(sqrt(v_entre + v_dentro)), " (", round(100 * (sqrt(v_entre + v_dentro) / sqrt(v_entre) - 1), 2), "% maior)")

# 4. a variância pelos resíduos da calibração, que só vale para censobr_weight (totais externos): o survey a
# calcula com calibrate() sobre as mesmas células; o passo 11 a escreve em erro_padrao_calibrado
nosso_cal <- nosso[regiao != "Brasil" & situacao == "ambas" & sexo == "ambos"]
message("erro-padrão por região, desenho vs resíduos da calibração:")
for(i in seq_len(nrow(nosso_cal))) message("  ", nosso_cal$regiao[i], ": ", nosso_cal$erro_padrao[i], " vs ", nosso_cal$erro_padrao_calibrado[i])
