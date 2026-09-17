# Auditoria dos nomes de distrito de 1960
#
# O guia read_guides/1960_distritos.csv tira os nomes do Codigo de Zonas
# Fisiograficas, Municipios e Distritos de 1960, que e o manual que os
# codificadores do censo usaram. Em alguns municipios os numeros impressos no
# livro nao sao os que aparecem no arquivo: em Campos o livro numera os 18
# distritos 01, 05, 07 ... 41, pulando 03, 25 e 27, e o arquivo os numera 01,
# 03, 05 ... 35, sem pular. Sao os mesmos 18 lugares com numeracao diferente, e
# o guia estava pondo cada nome no distrito seguinte.
#
# Este script decide qual numeracao vale, municipio a municipio, contra a
# Sinopse Preliminar de 1960 -- o volume que o IBGE publicou por estado em
# 1961-62 com a populacao de cada distrito do pais. A transcricao do quadro II
# esta em references/censo_1960_sinopse_preliminar_distritos.csv.
#
# SOBRE O PESO, QUE E A PARTE DELICADA
#
# O censobr_weight da amostra de 25% e calibrado, entre outras margens, a
# "municipio x situacao urbana/rural da Sinopse Preliminar". Usa-lo para
# validar contra a Sinopse e circular. A circularidade nao alcanca a reparticao
# entre distritos, porque a calibracao opera no nivel do municipio, mas alcanca
# duas coisas: o total do municipio bate por construcao, e a parcela urbana de
# cada distrito sofre, porque domicilios urbanos e rurais do mesmo municipio
# recebem fatores diferentes.
#
# Por isso a auditoria roda com censobr_weight_desenho, o peso do sorteio, sem
# calibracao alguma -- 4 para todos na amostra de 25%, de modo que a populacao
# e a contagem crua vezes quatro e a parcela urbana e a proporcao crua. Medido
# em 2026-09-17: os dois pesos dao o mesmo veredicto (em Campos, 7,4% contra
# 7,8% de erro de populacao e 0,6 ponto nos dois na parcela urbana), porque os
# fatores de calibracao em Campos vao de 3,63 a 4,20 e nao produzem a diferenca
# entre errar 7% e errar 44%. Mas o peso de desenho e o que se pode defender.
#
# Roda da raiz do projeto:  Rscript references/auditoria_distritos_1960.R

library(data.table)

sin  <- fread("references/censo_1960_sinopse_preliminar_distritos.csv", encoding = "UTF-8")
cad  <- fread("references/fontes_1960/1960_cadastro_territorial.csv", encoding = "UTF-8")
pes  <- setDT(arrow::read_parquet("./data/microdata_sample/1960/1960_population_v1.0.0.parquet",
        col_select = c("code_muni_1960", "code_district_1960", "V202", "V118",
                       "censobr_weight_desenho", "censobr_amostra")))
dom  <- setDT(arrow::read_parquet("./data/microdata_sample/1960/1960_households_v1.0.0.parquet",
        col_select = c("code_muni_1960", "code_district_1960")))

# --- 1. a transcricao se valida sozinha ---------------------------------------
# Cada linha tem de fechar urbana + rural = total, e a soma dos distritos tem de
# dar o total do municipio. Isso e interno a publicacao: nao depende de peso.
sin[, fecha := pop_urbana + pop_rural == pop_total]
somas <- merge(sin[ordem > 0, .(distritos = sum(pop_total)), by = code_muni_1960],
               sin[ordem == 0, .(code_muni_1960, municipio = pop_total)], by = "code_muni_1960")
message("transcricao: ", nrow(sin), " linhas, ", sin[fecha == TRUE, .N], " fechando urbana + rural")
message("municipios em que a soma dos distritos fecha o municipio: ",
        somas[distritos == municipio, .N], " de ", nrow(somas))

# --- 2. quais municipios o arquivo consegue arbitrar ---------------------------
# So faz sentido auditar onde o livro pula um numero. Onde ele numera 01, 03,
# 05 ... sem pular, cada codigo corresponde a uma posicao so e nao ha como o
# nome escorregar -- desde que todo codigo do arquivo seja impar e caiba na
# faixa, o que se confere aqui.
fora_gb <- cad[(code_muni_1960 < 5410 | code_muni_1960 > 5591) & code_muni_1960 != 9700]
livro <- fora_gb[order(code_muni_1960, code_district_1960),
                 .(n = .N, cods = list(code_district_1960),
                   pula = !identical(code_district_1960, seq(1L, by = 2L, length.out = .N))),
                 by = code_muni_1960]
arquivo <- dom[(code_muni_1960 < 5410 | code_muni_1960 > 5591) & code_muni_1960 != 9700,
               .(dom = .N, cods_a = list(sort(unique(code_district_1960)))), by = code_muni_1960]
message("\ncodigos de distrito do arquivo fora da Guanabara: ",
        dom[(code_muni_1960 < 5410 | code_muni_1960 > 5591) & code_muni_1960 != 541,
            uniqueN(paste(code_muni_1960, code_district_1960))],
        ", dos quais impares: ",
        dom[(code_muni_1960 < 5410 | code_muni_1960 > 5591) & code_muni_1960 != 541 &
            code_district_1960 %% 2 == 1, uniqueN(paste(code_muni_1960, code_district_1960))])

x <- merge(livro[pula == TRUE], arquivo, by = "code_muni_1960")
x[, usa_fora_do_livro := mapply(function(a, b) any(!(b %in% a)), cods, cods_a)]
x[, usa_fora_da_sequencia := mapply(function(a, b) any(!(b %in% seq(1L, by = 2L, length.out = length(a)))),
                                    cods, cods_a)]
x[, veredicto := fifelse(usa_fora_do_livro & !usa_fora_da_sequencia, "sequencial",
                  fifelse(!usa_fora_do_livro & usa_fora_da_sequencia, "livro",
                   fifelse(usa_fora_do_livro & usa_fora_da_sequencia, "ambiguo", "o arquivo nao arbitra")))]
message("\nmunicipios em que o livro pula e que estao no arquivo: ", nrow(x))
print(x[, .(municipios = .N, domicilios = sum(dom)), by = veredicto][order(-domicilios)])

# --- 3. o teste, so onde a Sinopse foi transcrita ------------------------------
# Duas medidas independentes: a populacao de cada distrito e a parcela dele que
# o censo classificou no quadro urbano ou suburbano (V118 em 1 ou 3). A segunda
# e mais forte, porque e uma razao interna e nao depende do nivel do peso.
alvos <- intersect(sin[, unique(code_muni_1960)], x[veredicto == "sequencial", code_muni_1960])
saida <- list()
for(m in alvos){
  s <- sin[code_muni_1960 == m & ordem > 0][order(ordem)]
  s[, urb := 100 * pop_urbana / pop_total]
  l <- cad[code_muni_1960 == m][order(code_district_1960)]
  a <- pes[code_muni_1960 == m & !(V202 %in% 3:4),
           .(pop = sum(censobr_weight_desenho),
             urb = 100 * sum(censobr_weight_desenho[V118 %in% c(1, 3)]) / sum(censobr_weight_desenho)),
           by = .(cod = code_district_1960)][order(cod)]

  # sequencial: o k-esimo codigo do arquivo e o k-esimo nome da lista
  seq_ <- data.table(pub = s$pop_total, nos = a$pop, pub_urb = s$urb, nos_urb = a$urb)
  # livro: o codigo impresso ao lado de cada nome
  liv_ <- merge(data.table(cod = l$code_district_1960, pub = s$pop_total, pub_urb = s$urb),
                data.table(cod = a$cod, nos = a$pop, nos_urb = a$urb), by = "cod")

  saida[[as.character(m)]] <- data.table(
    municipio = s$name_muni_1960[1], distritos = nrow(s),
    seq_pop = round(100 * median(abs(seq_$nos / seq_$pub - 1)), 1),
    seq_urb = round(median(abs(seq_$nos_urb - seq_$pub_urb)), 1),
    seq_urb_pior = round(max(abs(seq_$nos_urb - seq_$pub_urb)), 1),
    liv_pop = round(100 * median(abs(liv_$nos / liv_$pub - 1)), 1),
    liv_urb = round(median(abs(liv_$nos_urb - liv_$pub_urb)), 1),
    liv_urb_pior = round(max(abs(liv_$nos_urb - liv_$pub_urb)), 1),
    liv_nomeia = nrow(liv_))
}
message("\nos municipios a corrigir, com censobr_weight_desenho")
message("seq_* e a leitura sequencial, liv_* a do livro; pop em %, urb em pontos percentuais")
print(rbindlist(saida)[order(-distritos)])

# Nos municipios de dois distritos a coluna liv_ sai sobre um distrito so -- a
# sede, que e 01 nas duas leituras. Nao e comparacao: a leitura do livro
# simplesmente deixa o outro distrito sem nome. Ali o que decide e a contagem,
# e o teste abaixo: se o nosso codigo 01 sozinho ja e a sede publicada, o
# codigo seguinte e outro distrito e nao uma reparticao da sede.
message("\no codigo 01 sozinho e a sede publicada?")
for(m in alvos){
  s <- sin[code_muni_1960 == m & ordem > 0][order(ordem)]
  a <- pes[code_muni_1960 == m & !(V202 %in% 3:4),
           .(pop = sum(censobr_weight_desenho)), by = .(cod = code_district_1960)][order(cod)]
  message(sprintf("  %-22s sede %8d | codigo 01 %8d | razao %.2f",
          s$name_muni_1960[1], s$pop_total[1], round(a$pop[1]), a$pop[1] / s$pop_total[1]))
}
