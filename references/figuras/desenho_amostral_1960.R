# Refaz a investigação do desenho amostral da amostra de 1,27% de 1960 e grava as figuras e os números
# citados em references/microdata_1960_amostra_127_desenho_amostral.md. Roda da raiz do projeto, depois do
# pipeline (tar_make dos alvos de 1960), com a compilação antiga em data/release_legacy/:
#   Rscript references/figuras/desenho_amostral_1960.R
# Não faz parte do pipeline.

library(data.table)
library(targets)
library(arrow)
library(dplyr, warn.conflicts = FALSE)
library(ggplot2)
library(scales)
library(ragg)

source("R/microdata_1960_amostra_127.R")
options(width = 200)
dir_fig <- "references/figuras/desenho_amostral_1960"
dir.create(dir_fig, recursive = TRUE, showWarnings = FALSE)
salva <- function(nome, g, w = 9, h = 5) ggsave(file.path(dir_fig, nome), g, device = agg_png, width = w, height = h, units = "in", dpi = 150, bg = "white")
tema <- theme_minimal(base_size = 11) + theme(panel.grid.minor = element_blank(), plot.title.position = "plot", strip.text = element_text(face = "bold"))
cores_grupo <- c("cidade grande" = "#b2182b", "urbana menor" = "#ef8a62", "mista" = "#67a9cf", "rural" = "#2166ac")
UF_NOME <- c("0" = "Rondônia", "1" = "Acre", "2" = "Amazonas", "3" = "Roraima", "4" = "Pará", "6" = "Amapá", "10" = "Maranhão", "12" = "Piauí",
             "14" = "Ceará", "17" = "Rio Grande do Norte", "19" = "Paraíba", "21" = "Pernambuco", "24" = "Fernando de Noronha", "25" = "Alagoas",
             "30" = "Sergipe", "31" = "Bahia", "40" = "Minas Gerais", "50" = "Serra dos Aimorés", "51" = "Espírito Santo", "52" = "Rio de Janeiro",
             "54" = "Guanabara", "60" = "São Paulo", "71" = "Paraná", "74" = "Santa Catarina", "81" = "Rio Grande do Sul", "91" = "Mato Grosso",
             "94" = "Goiás", "97" = "Distrito Federal")

# ---------------------------------------------------------------------------------------------------------
# A. o que a amostra de 1,27% diz sozinha
# ---------------------------------------------------------------------------------------------------------
tab <- tar_read(tabelas_calibradas_1960_amostra_127)
p <- copy(tab$pessoas); d <- copy(tab$domicilios)
p[, grupo := sub(".* - ", "", censobr_estrato)]; d[, grupo := sub(".* - ", "", censobr_estrato)]
p[, regiao := REGIAO_1960[as.character(UF)]]
p[, presente := !(V202 %in% c(3, 4)) & !is.na(V202)]
p[, situacao := fifelse(V118 %in% c(1, 3), "urbana", fifelse(V118 %in% 5, "rural", NA_character_))]

pastas <- d[, .(UF = UF[1], grupo = grupo[1], pasta = as.integer(pasta[1]), boletins = .N, muni = code_muni_1960[1]), by = censobr_upa]
pastas[p[, .(pessoas = .N), by = censobr_upa], pessoas := i.pessoas, on = "censobr_upa"]
cat("\nA1 pastas:", nrow(pastas), "| boletins por pasta: mediana", median(pastas$boletins), "quartis", quantile(pastas$boletins, c(.25, .75)),
    "max", max(pastas$boletins), "| com menos de 100 boletins:", pastas[boletins < 100, .N], "| pessoas por pasta: mediana", median(pastas$pessoas), "\n")
cat("A2 pastas com numero impar:", pastas[pasta %% 2 == 1, .N], "de", nrow(pastas), "\n")
tabA <- pastas[, .(pastas = .N, cidade_grande = sum(grupo == "cidade grande"), urbana_menor = sum(grupo == "urbana menor"),
                   mista = sum(grupo == "mista"), rural = sum(grupo == "rural"), boletins_mediana = as.numeric(median(boletins))), by = UF][order(UF)]
tabA[, nome := UF_NOME[as.character(UF)]]
cat("\nA3 pastas sorteadas por UF e grupo:\n"); print(tabA[, .(UF, nome, pastas, cidade_grande, urbana_menor, mista, rural, boletins_mediana)])

# fig01: os numeros das pastas sorteadas, por grupo, em quatro UFs
sel <- pastas[UF %in% c(21, 31, 40, 60)]
sel[, nome := factor(UF_NOME[as.character(UF)], levels = UF_NOME[c("21", "31", "40", "60")])]
sel[, grupo := factor(grupo, levels = rev(names(cores_grupo)))]
g <- ggplot(sel, aes(pasta, grupo, colour = grupo)) + geom_point(shape = 124, size = 5) +
  facet_wrap(~nome, ncol = 1, scales = "free_x") + scale_colour_manual(values = cores_grupo) +
  labs(x = "número da pasta (a numeração da amostra de 25%, que é a ordem do cadastro)", y = NULL,
       title = "As pastas sorteadas, pelo número: cada grupo de situação é uma sequência própria",
       subtitle = "Um traço por pasta sorteada. As de cidade grande caem numa grade regular; os outros grupos têm grades próprias, intercaladas.") +
  tema + theme(legend.position = "none")
salva("fig01_pastas_sorteadas.png", g, 10, 6.5)

# o espacamento entre numeros consecutivos de pastas sorteadas, dentro de UF x grupo
setorder(pastas, UF, grupo, pasta)
pastas[, dif := c(NA, diff(pasta)), by = .(UF, grupo)]
cat("\nA4 espacamento entre numeros de pastas sorteadas consecutivas, dentro de UF x grupo (so a amostra de 1,27%):\n")
print(pastas[!is.na(dif), .(pares = .N, exato_40 = sum(dif == 40), pct_40 = round(100 * mean(dif == 40)), pct_40_a_46 = round(100 * mean(dif %in% c(40, 42, 44, 46))),
                          mediana = as.numeric(median(dif))), by = grupo][order(-pct_40)])
cat("A4 dentro de UF sem separar grupo:", pastas[order(UF, pasta)][, .(dif = c(NA, diff(pasta))), by = UF][!is.na(dif), round(100 * mean(dif == 40))], "% exatamente 40\n")
cat("\nA5 municipios com 4+ pastas de cidade grande: espacamentos entre numeros consecutivos\n")
cg <- pastas[grupo == "cidade grande"][order(UF, muni, pasta)][, if(.N >= 4) .(n = .N, espacamentos = paste(diff(pasta), collapse = " ")), by = .(UF, muni)]
print(cg[order(-n)])
g <- ggplot(pastas[!is.na(dif) & dif <= 160], aes(dif, fill = grupo)) + geom_histogram(binwidth = 2, boundary = 1) +
  geom_vline(xintercept = 40, colour = "black", linetype = 2) + facet_wrap(~grupo, scales = "free_y") + scale_fill_manual(values = cores_grupo) +
  labs(x = "diferença entre os números de duas pastas sorteadas consecutivas (mesma UF, mesmo grupo)", y = "pares de pastas",
       title = "Só com a amostra de 1,27%: o pico em 40 (vinte pastas pares) nas cidades grandes",
       subtitle = "Tracejado: 40. Nos outros grupos a grade existe, mas os números das pastas do grupo estão intercalados com os dos demais.") +
  tema + theme(legend.position = "none")
salva("fig02_espacamento_127.png", g, 9, 5)

# os pesos implicitos: o publicado em 1965 dividido pela contagem do arquivo
gab <- fread("references/censo_1960_resultados_preliminares_1965.csv", encoding = "UTF-8")
pub <- gab[quadro == 1 & linha == "TOTAIS" & coluna %in% c("urbana", "rural", "total"), .(regiao, situacao = fifelse(coluna == "total", "ambas", coluna), publicado = valor)]
cont <- rbind(p[presente & !is.na(situacao), .(arquivo = .N), by = .(regiao, situacao)], p[presente == TRUE, .(arquivo = .N), by = regiao][, situacao := "ambas"],
              p[presente & !is.na(situacao), .(arquivo = .N), by = situacao][, regiao := "Brasil"], data.table(regiao = "Brasil", situacao = "ambas", arquivo = p[presente == TRUE, .N]), use.names = TRUE)
imp <- merge(pub, cont, by = c("regiao", "situacao"))[, fator := round(publicado / arquivo, 1)]
cat("\nA6 fator de expansao implicito (publicado em 1965 / contagem do arquivo), nominal = 80:\n"); print(imp[order(regiao, situacao)])

# ---------------------------------------------------------------------------------------------------------
# B. o cadastro de pastas reconstruído a partir da amostra de 25%
# ---------------------------------------------------------------------------------------------------------
d25 <- open_dataset("data/release_legacy/Censo.1960.brasil.domicilios.amostraCompilada.censobr.parquet") |>
  filter(censobr_source == 2) |> select(uf, v001, v116, v118) |> collect() |> as.data.table()
mun <- fread("read_guides/1960_municipios.csv", encoding = "UTF-8")
cad <- d25[, .(boletins = .N, urb = sum(v118 %in% c(1, 3)), rur = sum(v118 %in% 5)), by = .(uf, pasta = v001)]
mmoda <- d25[, .N, by = .(uf, pasta = v001, v116)][order(-N)][, .SD[1], by = .(uf, pasta)][, .(uf, pasta, muni = v116)]
cad <- merge(cad, mmoda, by = c("uf", "pasta"))
cad[uf == 25, muni := muni - 200L]; cad[uf == 24, muni := 2401L]          # as mesmas correcoes de codigo do pipeline
cad[mun, `:=`(zona = i.zona_fisiografica, pop_urb = i.pop_urbana, pop_tot = i.pop_total), on = c(uf = "uf60", muni = "cod60")]
cad[, grupo := fifelse(urb > 0 & rur > 0, "mista", fifelse(urb == 0, "rural", fifelse(pop_urb >= 1e5 & !is.na(pop_urb), "cidade grande", "urbana menor")))]
setorder(cad, uf, pasta); cad[, rank_uf := seq_len(.N), by = uf]
cad[, sorteada := paste(uf, pasta) %in% paste(pastas$UF, pastas$pasta)]
cad[, regiao := REGIAO_1960[as.character(uf)]]
rm(d25); invisible(gc(verbose = FALSE))
cat("\nB1 cadastro:", nrow(cad), "pastas em", uniqueN(cad$uf), "UFs | boletins por pasta: mediana", median(cad$boletins), "quartis", quantile(cad$boletins, c(.25, .75)),
    "| composicao:", cad[, .N, by = grupo][order(-N)][, paste0(grupo, " = ", N, collapse = "; ")], "\n")
tabB <- merge(cad[, .(cadastro = .N, pasta_min = min(pasta), pasta_max = max(pasta), passo_numeracao = as.integer(median(diff(sort(pasta))))), by = uf],
              pastas[, .(sorteadas = .N), by = .(uf = UF)], by = "uf")
tabB[, razao := round(cadastro / sorteadas, 1)]; tabB[, nome := UF_NOME[as.character(uf)]]
cat("\nB2 cadastro x sorteadas por UF:\n"); print(tabB[order(uf), .(uf, nome, cadastro, sorteadas, razao, pasta_min, pasta_max, passo_numeracao)])
cat("B2 razao: mediana", median(tabB$razao), "min", min(tabB$razao), "max", max(tabB$razao), "| sorteadas encontradas no cadastro:", sum(cad$sorteada), "de", pastas[UF %in% cad$uf, .N], "\n")
cat("B2 boletins por pasta, sorteadas dentro do cadastro (25%): mediana", cad[sorteada == TRUE, median(boletins)], "| nao sorteadas:", cad[sorteada == FALSE, median(boletins)], "\n")

# o cadastro e ordenado por zona fisiografica, nao por situacao
tabZ <- cad[!is.na(zona), .(pastas = .N, zonas = uniqueN(zona), mudancas_de_zona = sum(zona[-1] != zona[-.N]), mudancas_de_grupo = sum(grupo[-1] != grupo[-.N]),
                            municipios = uniqueN(muni), mudancas_de_municipio = sum(muni[-1] != muni[-.N])), by = uf][order(-pastas)]
tabZ[, nome := UF_NOME[as.character(uf)]]
cat("\nB3 ordem do cadastro: mudancas ao percorrer as pastas pelo numero\n"); print(tabZ[, .(uf, nome, pastas, zonas, mudancas_de_zona, municipios, mudancas_de_municipio, mudancas_de_grupo)])

# fig03: o cadastro da Bahia, com as sorteadas
ba <- cad[uf == 31]; ba[, grupo := factor(grupo, levels = rev(names(cores_grupo)))]
g <- ggplot(ba, aes(rank_uf, grupo)) + geom_point(data = ba[sorteada == FALSE], colour = "grey78", shape = 124, size = 3) +
  geom_point(data = ba[sorteada == TRUE], aes(colour = grupo), shape = 124, size = 7) + scale_colour_manual(values = cores_grupo) +
  labs(x = paste0("posição da pasta no cadastro da Bahia (", nrow(ba), " pastas, na ordem do número)"), y = NULL,
       title = "O cadastro reconstruído: todas as pastas da Bahia (cinza) e as sorteadas (cor)",
       subtitle = "As pastas dos quatro grupos estão intercaladas ao longo de todo o cadastro; dentro de cada grupo, as sorteadas caem de 20 em 20.") +
  tema + theme(legend.position = "none")
salva("fig03_cadastro_bahia.png", g, 11, 4)

# fig04: as zonas fisiograficas sao blocos contiguos (Sao Paulo)
sp <- cad[uf == 60 & !is.na(zona)][, bloco := rleid(zona)]
zs <- sp[, .(ini = min(rank_uf), fim = max(rank_uf), pastas = .N), by = .(zona, bloco)]
zs[zs[, .(primeiro = min(ini)), by = zona][order(primeiro)][, ordem := .I], ordem := i.ordem, on = "zona"]
g <- ggplot(zs) + geom_segment(aes(x = ini, xend = fim, y = ordem, yend = ordem), linewidth = 2.2, colour = "grey25") +
  labs(x = paste0("posição no cadastro de São Paulo (", nrow(sp), " pastas, na ordem do número)"), y = "zona fisiográfica, na ordem em que aparece",
       title = "O cadastro é ordenado por zona fisiográfica: cada zona é um bloco contíguo de pastas",
       subtitle = paste0("Cada segmento é um bloco de pastas consecutivas da mesma zona: ", nrow(zs), " blocos para ", uniqueN(zs$zona), " zonas.")) + tema
salva("fig04_zonas_sao_paulo.png", g, 9, 6)

# a pergunta central: em que estrato o sorteio de 1 em 20 foi feito? Dentro do estrato certo, os ranks das
# sorteadas formam uma progressao aritmetica de razao 20.
cad[, urbana3 := fifelse(grupo %in% c("cidade grande", "urbana menor"), "urbana", grupo)]
espac <- function(nome, chave){
  x <- copy(cad); x[, h := do.call(paste, c(.SD, sep = " | ")), .SDcols = chave]
  setorder(x, h, uf, pasta); x[, r := seq_len(.N), by = h]
  s <- x[sorteada == TRUE][order(h, r)][, d := c(NA, diff(r)), by = h]
  list(tabela = data.table(estratificacao = nome, estratos = uniqueN(x$h), pares = s[!is.na(d), .N], pct_20 = round(100 * s[!is.na(d), mean(d == 20)], 1),
                           pct_19a21 = round(100 * s[!is.na(d), mean(d %in% 19:21)], 1), d_mediano = s[!is.na(d), median(d)]),
       s = s, x = x)
}
cands <- list(espac("unidade da federação, sem situação", "uf"), espac("região, sem situação", "regiao"), espac("zona fisiográfica, sem situação", c("uf", "zona")),
              espac("região × situação (4 grupos)", c("regiao", "grupo")), espac("UF × urbana/rural/mista (3 grupos)", c("uf", "urbana3")),
              espac("UF × situação (4 grupos)", c("uf", "grupo")), espac("zona × situação (4 grupos)", c("uf", "zona", "grupo")), espac("UF × município", c("uf", "muni")))
tabC <- rbindlist(lapply(cands, `[[`, "tabela"))[order(-pct_20)]
cat("\nB4 teste das estratificacoes candidatas:\n"); print(tabC)
dist <- rbindlist(lapply(cands[c(1, 4, 6)], function(k) k$s[!is.na(d), .(estratificacao = k$tabela$estratificacao, d)]))
dist[, estratificacao := factor(estratificacao, levels = c("unidade da federação, sem situação", "região × situação (4 grupos)", "UF × situação (4 grupos)"))]
g <- ggplot(dist[d <= 60], aes(d)) + geom_histogram(binwidth = 1, boundary = 0.5, fill = "grey30") + geom_vline(xintercept = 20, colour = "firebrick", linetype = 2) +
  facet_wrap(~estratificacao, ncol = 1, scales = "free_y") + scale_x_continuous(breaks = seq(0, 60, 10)) +
  labs(x = "espaçamento entre duas pastas sorteadas consecutivas, em posições do cadastro do estrato candidato", y = "pares de pastas",
       title = "Qual era o estrato? O espaçamento entre sorteadas só vira 20 quando o estrato cruza UF e situação",
       subtitle = "Sorteio sistemático de uma em vinte dentro do estrato certo produz espaçamentos exatamente iguais a 20.") + tema
salva("fig06_espacamentos_candidatos.png", g, 9, 7)

# UF x situacao, de perto: distribuicao dos espacamentos, por grupo, e exemplos
s <- cands[[6]]$s; x <- cands[[6]]$x
cat("\nB5 UF x situacao: distribuicao dos espacamentos:\n"); print(s[!is.na(d), .N, by = d][order(-N)][1:10])
cat("\nB5 UF x situacao, por grupo:\n"); print(s[!is.na(d), .(pares = .N, exato_20 = sum(d == 20), pct_20 = round(100 * mean(d == 20)), pct_19a21 = round(100 * mean(d %in% 19:21))), by = grupo][order(-pct_20)])
cat("\nB5 exemplos de estratos (ranks das sorteadas no cadastro do estrato):\n")
for(hh in c("31 | cidade grande", "31 | rural", "31 | mista", "31 | urbana menor", "60 | cidade grande", "60 | rural", "40 | rural", "21 | mista", "81 | cidade grande")){
  ss <- s[h == hh]; if(!nrow(ss)) next
  cat(sprintf("%-20s cadastro %4d sorteadas %3d | inicio %3d | ranks: %s\n", hh, x[h == hh, .N], nrow(ss), min(ss$r), paste(head(ss$r, 16), collapse = " ")))
}
por_h <- s[, .(sorteadas = .N, cadastro = x[h == .BY$h, .N], pares = sum(!is.na(d)), exato_20 = sum(d == 20, na.rm = TRUE), inicio = min(r)), by = h][, pct := round(100 * exato_20 / pmax(pares, 1))]
cat("\nB5 estratos UF x situacao:", nrow(por_h), "com sorteadas |", por_h[sorteadas >= 3, .N], "com 3+ sorteadas, dos quais", por_h[sorteadas >= 3 & pct >= 80, .N],
    "com 80%+ de espacamentos exatos e", por_h[sorteadas >= 3 & pct == 100, .N], "perfeitos | inicios (posicao da 1a sorteada) entre", min(por_h$inicio), "e", max(por_h$inicio),
    "; inicios > 20:", por_h[inicio > 20, .N], "\n")
cat("B5 razao cadastro/sorteadas por estrato: mediana", round(median(por_h$cadastro / por_h$sorteadas), 1), "| quartis", paste(round(quantile(por_h$cadastro / por_h$sorteadas, c(.25, .75)), 1), collapse = " e "), "\n")
cat("\nB5 os estratos de pior ajuste (3+ sorteadas):\n"); print(por_h[sorteadas >= 3][order(pct)][1:8])

# fig05: a progressao aritmetica em seis estratos
ex <- s[h %in% c("31 | cidade grande", "31 | rural", "31 | mista", "60 | cidade grande", "40 | rural", "21 | mista")][order(h, r)]
ex[, i := seq_len(.N), by = h]; ex[, ref := r[1] + 20 * (i - 1), by = h]
ex[, rotulo := paste0(UF_NOME[as.character(uf)], ", ", grupo, " (", sapply(h, function(k) x[h == k, .N]), " no cadastro)")]
g <- ggplot(ex, aes(i, r)) + geom_line(aes(y = ref), colour = "firebrick", linetype = 2) + geom_point(size = 1.8) +
  facet_wrap(~rotulo, scales = "free", ncol = 3) +
  labs(x = "ordem da pasta sorteada dentro do estrato (1ª, 2ª, 3ª…)", y = "posição da pasta no cadastro do estrato",
       title = "Dentro de cada estrato UF × situação, as sorteadas andam de vinte em vinte",
       subtitle = "Pontos: as pastas sorteadas. Tracejado: a reta de inclinação 20 que parte da primeira sorteada — o início aleatório da série.") + tema
salva("fig05_progressao_estratos.png", g, 10, 6)

# a definicao operacional de "cidade grande"
mista <- cad$urb > 0 & cad$rur > 0; rural <- cad$urb == 0
g4 <- function(grande) fifelse(mista, "mista", fifelse(rural, "rural", fifelse(grande & !is.na(grande), "cidade grande", "urbana menor")))
testa_def <- function(nome, gg){ x <- copy(cad); x[, grupo := gg]; x[, h := paste(uf, grupo)]; setorder(x, h, uf, pasta); x[, r := seq_len(.N), by = h]
  s <- x[sorteada == TRUE][order(h, r)][, d := c(NA, diff(r)), by = h][!is.na(d)]
  data.table(definicao = nome, estratos = uniqueN(x$h), pares = nrow(s), pct_20 = round(100 * mean(s$d == 20), 1), pct_19a21 = round(100 * mean(s$d %in% 19:21), 1)) }
tabD <- rbindlist(list(testa_def("população urbana do município ≥ 100 mil", g4(cad$pop_urb >= 1e5)), testa_def("população urbana ≥ 200 mil", g4(cad$pop_urb >= 2e5)),
                       testa_def("população urbana ≥ 50 mil", g4(cad$pop_urb >= 5e4)), testa_def("população total do município ≥ 100 mil", g4(cad$pop_tot >= 1e5)),
                       testa_def("sem separar cidade grande (3 grupos)", fifelse(mista, "mista", fifelse(rural, "rural", "urbana")))))[order(-pct_20)]
cat("\nB6 definicao de cidade grande:\n"); print(tabD)
cat("B6 municipios com pop urbana >= 100 mil no Anuario:", mun[pop_urbana >= 1e5, .N], "| com pasta de cidade grande na amostra:", pastas[grupo == "cidade grande", uniqueN(paste(UF, muni))], "\n")

# a zona nao e estrato: os pares de sorteadas consecutivas que atravessam a fronteira de uma zona continuam
# espacados de 20, e as corridas de espacamento 20 atravessam zonas
s6 <- cands[[6]]$s[order(h, r)][, mesma_zona := zona == shift(zona), by = h][!is.na(d)]
cat("\nB7 pares de sorteadas consecutivas (UF x situacao) na mesma zona:", s6[mesma_zona == TRUE, .N], "pares,", round(100 * s6[mesma_zona == TRUE, mean(d == 20)], 1),
    "% exatos | em zonas diferentes:", s6[mesma_zona == FALSE, .N], "pares,", round(100 * s6[mesma_zona == FALSE, mean(d == 20)], 1), "% exatos (se a zona fosse estrato, ~5%)\n")
cat("B7 Guanabara, numeros das pastas de cidade grande:", paste(sort(pastas[UF == 54 & grupo == "cidade grande", pasta]), collapse = " "), "\n")
blocos <- cad[!is.na(zona)][, .(blocos = uniqueN(rleid(zona)), zonas = uniqueN(zona)), by = uf][order(-zonas)]
cat("B7 blocos contiguos de zona no cadastro (blocos = zonas se toda zona e um bloco so):\n"); print(blocos[1:6])
for(u in c(60, 40, 31)){ z <- cad[uf == u & !is.na(zona)][, bloco := rleid(zona)][, .(ini = min(rank_uf), fim = max(rank_uf), pastas = .N, cidade_grande = sum(grupo == "cidade grande")), by = .(zona, bloco)]
  cat("B7 UF", u, "zonas em mais de um bloco:\n"); print(z[zona %in% z[, .N, by = zona][N > 1, zona]]) }
x6 <- cands[[6]]$s[order(uf, r)]
series <- x6[, .(pastas = .N, grupos = uniqueN(grupo), zonas = uniqueN(zona)), by = .(uf, serie = cumsum(is.na(d) | d != 20))]
cat("\nB7 corridas de espacamento exatamente 20 (dentro de UF x situacao):", nrow(series), "| com 2+ pastas:", series[pastas >= 2, .N],
    "| mediana de pastas por corrida:", median(series[pastas >= 2]$pastas), "| corridas que atravessam mais de uma zona:", series[pastas >= 2 & zonas > 1, .N], "\n")

# ---------------------------------------------------------------------------------------------------------
# C. os pesos
# ---------------------------------------------------------------------------------------------------------
w <- d$censobr_weight; f <- d$censobr_weight_fator
cat("\nC1 peso calibrado: min", round(min(w), 1), "p1", round(quantile(w, .01), 1), "mediana", round(median(w), 1), "p99", round(quantile(w, .99), 1), "max", round(max(w), 1),
    "| fator: min", round(min(f), 2), "max", round(max(f), 2), "| desenho:", round(d$censobr_weight_desenho[1], 2), "\n")
cat("C1 fator mediano por UF (os 5 maiores):\n"); print(d[, .(fator_mediano = round(median(censobr_weight_fator), 3), domicilios = .N), by = UF][order(-fator_mediano)][1:5])
g <- ggplot(d[censobr_weight <= 160], aes(censobr_weight)) + geom_histogram(binwidth = 1, fill = "grey30") + geom_vline(xintercept = 1 / 0.0127, colour = "firebrick", linetype = 2) +
  annotate("text", x = 1 / 0.0127 + 2, y = Inf, label = "peso de desenho 78,74", hjust = 0, vjust = 1.5, colour = "firebrick") +
  labs(x = "peso calibrado do domicílio (censobr_weight)", y = "domicílios", title = "Os pesos calibrados ficam perto do peso de desenho",
       subtitle = paste0("98% dos domicílios entre ", round(quantile(w, .01), 1), " e ", round(quantile(w, .99), 1), "; o eixo está cortado em 160 (máximo ", round(max(w), 1), ").")) + tema
salva("fig07_pesos.png", g, 9, 4.5)

# ---------------------------------------------------------------------------------------------------------
# D. os erros amostrais
# ---------------------------------------------------------------------------------------------------------
e <- fread("data_raw/microdata/1960/amostra_127/erros_amostrais.csv", encoding = "UTF-8")
cel <- e[faixa != "todas" & !is.na(deff)]
cel[, cv_aas := cv_pct / sqrt(deff)]
cat("\nD1 176 celulas: cv mediano", median(cel$cv_pct), "max", max(cel$cv_pct), "| deff mediano", median(cel$deff), "quartis", quantile(cel$deff, c(.25, .75)), "max", max(cel$deff), "\n")
cat("D1 deff mediano por faixa:\n"); print(cel[, .(deff_mediano = median(deff), cv_mediano = median(cv_pct)), by = faixa])
g <- ggplot(cel, aes(cv_aas, cv_pct, colour = regiao, shape = situacao)) + geom_abline(linetype = 3, colour = "grey50") +
  geom_abline(intercept = log10(2), linetype = 3, colour = "grey50") + geom_abline(intercept = log10(4), linetype = 3, colour = "grey50") +
  annotate("text", x = 0.55, y = c(0.6, 1.2, 2.4), label = c("deff = 1", "deff = 4", "deff = 16"), hjust = 0, size = 3, colour = "grey30") +
  geom_point(size = 2) + scale_x_log10() + scale_y_log10() +
  labs(x = "CV que a célula teria numa amostra aleatória simples de pessoas do mesmo tamanho (%)", y = "CV pelo desenho de pastas (%)",
       title = "As 176 células do quadro 1: o erro real é 2 a 4 vezes o de uma amostra aleatória simples", colour = NULL, shape = NULL) + tema
salva("fig08_deff_celulas.png", g, 9, 5.5)

# os estimadores alternativos, nos cinco totais-exemplo
p[, idade := fifelse(V204 %in% 1, V204B, fifelse(V204 %in% 0, 0L, 999L))]; p[is.na(idade), idade := 999L]
p[, pasta_n := suppressWarnings(as.integer(pasta))]
p[, y_construcao := as.numeric(presente & V223B %in% 351)]
p[, y_renda_alta := as.numeric(presente & V219 %in% c(0, 1, 2))]
p[, y_analfabeto := as.numeric(presente & idade >= 15 & V211 %in% c(2, 3))]
p[, y_solteiro := as.numeric(presente & idade >= 15 & V215 %in% 0)]
p[, y_ne_urbana := as.numeric(presente & regiao == "Nordeste" & V118 %in% c(1, 3))]
vars <- c("y_construcao", "y_renda_alta", "y_analfabeto", "y_solteiro", "y_ne_urbana")
rotulos <- c(y_construcao = "operários da construção civil", y_renda_alta = "rendimento acima de Cr$ 10 mil", y_analfabeto = "analfabetos de 15 anos e mais",
             y_solteiro = "solteiros de 15 anos e mais", y_ne_urbana = "população urbana do Nordeste")
tp <- p[, c(list(UF = UF[1], estrato = censobr_estrato[1], grupo = grupo[1], pasta_n = pasta_n[1]), lapply(.SD, function(y) sum(y * censobr_weight))), by = censobr_upa, .SDcols = vars]
n_amostra <- p[presente == TRUE, .N]; N <- sum(p$censobr_weight[p$presente])
v_ultimo <- function(t, h, ordem = NULL, sd = FALSE, fpc = 1 - 1 / 20){
  dt <- data.table(t = t, h = h, o = if(is.null(ordem)) seq_along(t) else ordem)
  if(!sd) v <- dt[, .(v = if(.N > 1) .N / (.N - 1) * sum((t - mean(t))^2) else NA_real_), by = h]
  else { setorder(dt, h, o); v <- dt[, .(v = if(.N > 1) .N / (2 * (.N - 1)) * sum(diff(t)^2) else NA_real_), by = h] }
  fpc * sum(v$v, na.rm = TRUE)
}
h47 <- tp$estrato; h16 <- paste(REGIAO_1960[as.character(tp$UF)], tp$grupo, sep = " - ")
# variancia pos-calibracao: residuo da regressao dos totais por domicilio nas 184 celulas calibradas
faixas <- c("0 a 4", "5 a 9", "10 a 14", "15 a 19", "20 a 24", "25 a 29", "30 a 39", "40 a 49", "50 a 59", "60 a 69", "70 e mais e ignorada")
p[, sexo := fifelse(V202 %in% c(1, 3, 5), "homens", fifelse(V202 %in% c(2, 4, 6), "mulheres", NA_character_))]
p[, faixa := faixas[findInterval(idade, c(0, 5, 10, 15, 20, 25, 30, 40, 50, 60, 70))]]
p[, celula := paste("q1", regiao, situacao, sexo, faixa, sep = "|")]
p[, celula_q2 := fifelse(presente & idade >= 5 & V211 %in% c(0, 1) & !is.na(sexo), paste("q2", regiao, "sabem", sexo, sep = "|"), NA_character_)]
g1 <- gab[quadro == 1 & regiao != "Brasil" & linha != "TOTAIS" & coluna %in% c("urbana_homens", "urbana_mulheres", "rural_homens", "rural_mulheres")]
g1[, celula := paste("q1", regiao, sub("_.*", "", coluna), sub(".*_", "", coluna), linha, sep = "|")]
g2 <- gab[quadro == 2 & regiao != "Brasil" & linha == "5 e mais" & coluna %in% c("sabem_homens", "sabem_mulheres")]
g2[, celula := paste("q2", regiao, sub("_[a-z]+$", "", coluna), sub(".*_", "", coluna), sep = "|")]
celulas <- c(g1$celula, g2$celula)
cont <- rbind(p[presente & !is.na(situacao) & !is.na(sexo), .N, by = .(censobr_idhousehold, celula)], p[!is.na(celula_q2), .N, by = .(censobr_idhousehold, celula = celula_q2)])
hh <- sort(unique(d$censobr_idhousehold))
X <- Matrix::sparseMatrix(i = match(cont$censobr_idhousehold, hh), j = match(cont$celula, celulas), x = cont$N, dims = c(length(hh), length(celulas)))
wd <- d[match(hh, censobr_idhousehold), censobr_weight]
yh <- p[, lapply(.SD, sum), by = censobr_idhousehold, .SDcols = vars][match(hh, censobr_idhousehold)]
XtW <- Matrix::t(X) %*% Matrix::Diagonal(x = wd); XtWX <- as.matrix(XtW %*% X)
hd <- d[match(hh, censobr_idhousehold), .(h = censobr_estrato, upa = censobr_upa)]
res <- rbindlist(lapply(vars, function(v){
  t <- tp[[v]]; Y <- sum(t); parte <- Y / N
  B <- solve(XtWX, as.numeric(XtW %*% yh[[v]])); ee <- yh[[v]] - as.numeric(X %*% B)
  te <- data.table(hd, we = wd * ee)[, .(t = sum(we)), by = .(h, upa)]
  data.table(total = rotulos[v], estimativa = round(Y), pastas_com = sum(t > 0),
             adotado = sqrt(v_ultimo(t, h47)), sem_fpc = sqrt(v_ultimo(t, h47, fpc = 1)), regiao_16 = sqrt(v_ultimo(t, h16)),
             dif_sucessivas = sqrt(v_ultimo(t, h47, ordem = tp$pasta_n, sd = TRUE)), residuos_calibracao = sqrt(v_ultimo(te$t, te$h)),
             aas = sqrt(N^2 * (1 - n_amostra / N) * parte * (1 - parte) / (n_amostra - 1)))
}))
res[, `:=`(cv_pct = round(100 * adotado / estimativa, 2), deff = round((adotado / aas)^2, 1))]
cat("\nD2 erros-padrao (milhares) dos cinco totais, por estimador:\n")
print(res[, .(total, estimativa, pastas_com, adotado = round(adotado / 1e3), sem_fpc = round(sem_fpc / 1e3), regiao_16 = round(regiao_16 / 1e3), dif_sucessivas = round(dif_sucessivas / 1e3),
              residuos_calibracao = round(residuos_calibracao / 1e3), aas = round(aas / 1e3), cv_pct, deff)])
long <- melt(res[, .(total, adotado, sem_fpc, regiao_16, dif_sucessivas, residuos_calibracao, aas)], id.vars = c("total", "adotado"), variable.name = "estimador", value.name = "ep")
long[, razao := ep / adotado]
long[, estimador := factor(estimador, levels = c("sem_fpc", "regiao_16", "dif_sucessivas", "residuos_calibracao", "aas"),
                           labels = c("sem correção finita", "estratos região × situação", "diferenças sucessivas", "resíduos da calibração", "se fosse aleatória simples"))]
long[, total := factor(total, levels = rotulos)]
g <- ggplot(long, aes(total, razao, fill = estimador)) + geom_col(position = position_dodge(width = 0.8), width = 0.75) + geom_hline(yintercept = 1, linetype = 2) +
  scale_fill_brewer(palette = "Set2") + scale_x_discrete(labels = label_wrap(16)) +
  labs(x = NULL, y = "erro-padrão relativo ao estimador adotado", fill = NULL, title = "Os estimadores alternativos, em cinco totais: o que cada um muda",
       subtitle = "1 = conglomerado último com correção finita e 47 estratos (o adotado). Barras abaixo de 1 são erros menores.") + tema + theme(legend.position = "bottom")
salva("fig09_estimadores.png", g, 10, 5.5)

# a componente da primeira etapa (1 domicilio em 4), contra a medida pela segunda
N60 <- 70119071; n25 <- 0.25 * N60
cat("\nD3 CV da primeira etapa para uma proporcao P (amostra de 25%, deff 1) contra o CV mediano das celulas:\n")
for(P in c(0.5, 0.2, 0.05, 0.01)){ cv1 <- sqrt((1 - 0.25) / n25 * (1 - P) / P); cat(sprintf("  P = %-5.2f  cv1 = %.4f%%   razao de variancias V1/V2 = %.5f\n", P, 100 * cv1, (cv1 / (median(cel$cv_pct) / 100))^2)) }

# estratos do pipeline
pe <- unique(d[, .(censobr_estrato, censobr_upa)])[, .N, by = censobr_estrato]
cat("\nE1 estratos:", nrow(pe), "| de UF:", pe[grepl("^UF ", censobr_estrato), .N], "| de regiao:", pe[!grepl("^UF ", censobr_estrato), .N], "| pastas por estrato: min", min(pe$N), "mediana", median(pe$N), "max", max(pe$N), "\n")
cat("E1 estratos de regiao (colapsados):", pe[!grepl("^UF ", censobr_estrato)][order(censobr_estrato), paste0(censobr_estrato, " (", N, ")", collapse = "; ")], "\n")
cat("\nfiguras em", dir_fig, ":", paste(list.files(dir_fig), collapse = ", "), "\n")
