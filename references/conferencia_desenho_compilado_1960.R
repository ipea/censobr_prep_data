# Confere o erro amostral do desenho compilado de 1960 contra o pacote `survey`.
#
# O compilado é de duas etapas nas duas metades, com fracções diferentes: nas
# dezessete unidades da amostra de 25% sorteia-se o domicílio (1/4) e a segunda
# etapa é degenerada (fpc2 = 1); nas onze da de 1,27% sorteia-se a pasta (1/20) e
# dentro dela o domicílio (1/4). Como nenhum estrato e nenhuma unidade primária
# mistura as duas metades, uma chamada só de svydesign descreve o país inteiro.
#
# Não faz parte do pipeline: é script de conferência, para rodar à mão quando o
# desenho mudar. Roda sobre um subconjunto de unidades porque o survey carrega a
# tabela inteira na memória, e 15,1 milhões de linhas não cabem.

library(data.table)
library(survey)
options(survey.lonely.psu = "adjust")

unidades <- c("ro", "ac", "am", "rr", "pa", "ap", "ma", "pi", "es", "gb", "sc", "se", "fn")

pessoas <- rbindlist(lapply(unidades, function(u)
  setDT(arrow::read_parquet(file.path("data_raw/microdata/1960/compilada", u, "pessoas.parquet"),
        col_select = c("UF", "censobr_amostra", "V118", "V202", "censobr_estrato", "censobr_upa",
                       "censobr_usa", "censobr_fpc", "censobr_fpc2", "censobr_weight")))))
pessoas <- pessoas[!V202 %in% c(3, 4)]
pessoas[, um := 1]
pessoas[, urbana := as.integer(V118 != 5)]

# 1. o desenho de duas etapas, pelo survey
desenho <- svydesign(ids = ~censobr_upa + censobr_usa, strata = ~censobr_estrato,
                     weights = ~censobr_weight, fpc = ~censobr_fpc + censobr_fpc2,
                     data = pessoas)
t_survey <- svytotal(~um, desenho)
message("população presente: ", round(coef(t_survey)), " | erro-padrão survey ", round(SE(t_survey)))

# 2. a mesma conta à mão, na fórmula do sampling_errors_1960()
usa <- pessoas[, .(t = sum(um * censobr_weight)),
               by = .(censobr_estrato, censobr_upa, censobr_usa, censobr_fpc, censobr_fpc2)]
upa <- usa[, .(t = sum(t), f1 = censobr_fpc[1]), by = .(censobr_estrato, censobr_upa)]
v_entre <- upa[, .(n = .N, soma = sum(t), soma2 = sum(t^2), f1 = f1[1]), by = censobr_estrato
               ][, sum(fifelse(n > 1, (1 - f1) * n / (n - 1) * (soma2 - soma^2 / n), 0))]
v_dentro <- usa[censobr_fpc2 < 1, .(m = .N, soma = sum(t), soma2 = sum(t^2),
                                    f1 = censobr_fpc[1], f2 = censobr_fpc2[1]),
                by = .(censobr_estrato, censobr_upa)
                ][, sum(fifelse(m > 1, f1 * (1 - f2) * m / (m - 1) * (soma2 - soma^2 / m), 0))]
message("à mão: entre unidades primárias ", round(sqrt(v_entre)),
        " | com a etapa dos domicílios ", round(sqrt(v_entre + v_dentro)),
        " | a etapa dos domicílios vale ", round(100 * v_dentro / (v_entre + v_dentro), 2), "% da variância")

# 3. quanto cada metade pesa na variância nacional: as onze unidades são 1% dos
#    registros e 18% da população, e é delas que vem quase todo o erro-padrão
por_metade <- pessoas[, .(registros = .N, expandido = round(sum(censobr_weight))), by = censobr_amostra]
print(por_metade)
for(a in c("25%", "1,27%")){
  d <- subset(desenho, censobr_amostra == a)
  message("  ", a, ": erro-padrão ", round(SE(svytotal(~um, d))))
}

# 4. a população urbana, que é o domínio em que a cobertura parcial das onze
#    unidades mais aparece (Rondônia só tem pasta urbana; o Acre, duas)
message("população urbana: ", round(coef(svytotal(~urbana, desenho))),
        " | erro-padrão ", round(SE(svytotal(~urbana, desenho))))
