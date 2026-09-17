# Reconstroi read_guides/1960_distritos.csv a partir da transcricao integral do
# Codigo de Zonas Fisiograficas, Municipios e Distritos de 1960
# (references/fontes_1960/1960_codigo_zonas_municipios_distritos.html).
#
# O guia anterior vinha de OCR (Tesseract) das paginas escaneadas, e o '4'
# datilografado do livro saia como 'h' ou 'L': 19% dos nomes de distrito estavam
# corrompidos ("Padras Negros" por Pedras Negras, "Bon Espctança esnerccareqscvas"
# por Boa Esperanca) e 720 pares municipio-distrito nao tinham nome nenhum. A
# transcricao integral cobre as 313 paginas e resolve os dois problemas.
#
# A Guanabara tem estrutura propria e fica como estava: o censo codificou a
# cidade por bairro (5410 a 5591), e dentro do bairro por circunscricao (codigos
# ate 40) ou favela (41 e acima). Aquelas paginas ja tinham sido transcritas a
# vista, nao por OCR, e os nomes estao bons.
#
# Roda da raiz do projeto:  Rscript references/gera_distritos_1960.R

library(data.table)

fonte_html <- "references/fontes_1960/1960_codigo_zonas_municipios_distritos.html"
saida      <- "read_guides/1960_distritos.csv"

# --- a transcricao, ja parseada por references/parse_cadastro_1960.py ---------
novo <- fread("references/fontes_1960/1960_cadastro_territorial.csv", encoding = "UTF-8")
guia <- fread(saida, encoding = "UTF-8")
muni <- fread("read_guides/1960_municipios.csv", encoding = "UTF-8")

message("transcricao: ", nrow(novo), " distritos em ", uniqueN(novo$code_muni_1960), " municipios")

# a unidade da federacao e o nome do municipio vem do crosswalk, que e a
# autoridade para os dois -- o cabecalho da pagina nao serve, porque so a
# primeira pagina de cada estado o traz e o codigo se arrasta para as seguintes
# (5,74% de acerto contra a divisao territorial).
#
# O codigo 541 esta duas vezes no crosswalk: e Anhanga, no Para, e e tambem o
# codigo que o nosso estagio da amostra de 1,27% inventou para o municipio do
# Rio de Janeiro ao reduzir os bairros da Guanabara (5410 a 5591) a um so
# municipio. No livro 541 e Anhanga e nada mais, entao a linha sintetica sai
# do join -- sem isso os tres distritos de Anhanga saem rotulados como Rio de
# Janeiro.
cw <- muni[!(uf60 == 54 & cod60 == 541)]
novo[, uf60 := NA_integer_]
novo[cw, `:=`(uf60 = i.uf60, name_muni_1960 = i.nome), on = c(code_muni_1960 = "cod60")]

gb <- novo$code_muni_1960 >= 5410 & novo$code_muni_1960 <= 5591

# Rafard (6311) esta no livro e nao no crosswalk, que pula de 6310 a 6312: a
# unidade vem do municipio de codigo mais proximo, que e o vizinho de pagina.
# Os bairros da Guanabara tambem faltam no crosswalk, e nao entram aqui porque
# tem tratamento proprio mais abaixo.
faltantes <- unique(novo[is.na(uf60) & !gb, code_muni_1960])
if(length(faltantes) > 0){
  vizinho <- cw[, .(cod60, uf60)][order(cod60)]
  novo[is.na(uf60) & !gb, uf60 := vizinho[.(code_muni_1960), uf60, on = "cod60", roll = "nearest"]]
  message("sem crosswalk, unidade pelo municipio vizinho: ",
          paste(faltantes, collapse = ", "))
}
message("Guanabara na transcricao: ", sum(gb), " linhas; no guia anterior: ",
        guia[uf60 == 54, .N])

# --- fora da Guanabara: a transcricao substitui ------------------------------
fora <- novo[!gb, .(uf60, code_muni_1960, name_muni_1960,
                    code_district_1960, name_district_1960,
                    name_bairro_1960 = NA_character_, tipo = "distrito",
                    zona_cod, zona, pagina,
                    fonte = "Transcricao integral do Codigo de Zonas Fisiograficas, Municipios e Distritos de 1960")]

# --- Guanabara: os nomes ja transcritos a vista ficam; o que faltar entra -----
antiga_gb <- guia[uf60 == 54, .(uf60, code_muni_1960, name_muni_1960, code_district_1960,
                                name_district_1960, name_bairro_1960, tipo, zona_cod, zona,
                                pagina, fonte)]
nova_gb <- novo[gb]
nova_gb[antiga_gb, ja_tem := TRUE, on = c("code_muni_1960", "code_district_1960")]

# a mesma unidade pode reaparecer com o codigo danificado, e ai o par nao casa
# mas o nome casa: a Mare, favela de Bonsucesso, saiu da transcricao integral
# com o codigo lido como um so algarismo ("4"), e o transcritor anotou que nao
# se deve completa-lo pela sequencia. A leitura visual das mesmas paginas ja a
# traz em 49, entre a Baixa do Sapateiro (48) e a Entrada do Galeao (50).
nova_gb[antiga_gb, ja_tem := TRUE, on = c("code_muni_1960", "name_district_1960")]
falta_gb <- nova_gb[is.na(ja_tem)]
message("Guanabara: ", nrow(falta_gb), " pares que a transcricao tem e o guia nao")

if(nrow(falta_gb) > 0){
  # o bairro e o nome da linha de "municipio" da transcricao; a circunscricao
  # leva o codigo no nome, como o guia ja fazia
  bairros <- unique(nova_gb[, .(code_muni_1960, bairro = name_muni_1960)])
  falta_gb[bairros, bairro := i.bairro, on = "code_muni_1960"]
  falta_gb <- falta_gb[, .(uf60 = 54L, code_muni_1960,
                           name_muni_1960 = "Rio de Janeiro",
                           code_district_1960,
                           name_district_1960 = fifelse(code_district_1960 <= 40,
                                                        sprintf("Circunscrição %02d", code_district_1960),
                                                        name_district_1960),
                           name_bairro_1960 = bairro,
                           tipo = fifelse(code_district_1960 <= 40, "circunscrição", "favela"),
                           zona_cod, zona, pagina,
                           fonte = "Transcricao integral do Codigo de Zonas Fisiograficas, Municipios e Distritos de 1960")]
}

# --- o que a transcricao nao tem, o guia anterior preenche --------------------
#
# Tres casos medidos: Prudentopolis (7194) e Pedreiras (1044) nao estao na
# transcricao, e a Serra dos Aimores (5001) aparece la como municipio sem linha
# de distrito, porque o livro a trata como regiao. O guia anterior os tem, por
# leitura visual ou pela regra de que o distrito 01 e a sede.
#
# O uf60 do guia anterior nao se aproveita: vinha do OCR e esta errado em
# centenas de linhas -- municipios do Amazonas marcados como Acre, por exemplo --,
# e por isso elas nunca casavam com o dado. Vem do crosswalk, como o resto.
r <- rbindlist(list(fora, antiga_gb, falta_gb), use.names = TRUE, fill = TRUE)

resto <- guia[uf60 != 54 & !is.na(name_district_1960) & name_district_1960 != ""]
resto[, uf60 := NULL]
resto[cw, `:=`(uf60 = i.uf60, name_muni_1960 = i.nome), on = c(code_muni_1960 = "cod60")]
resto <- resto[!is.na(uf60)]
resto[r, ja := TRUE, on = c("uf60", "code_muni_1960", "code_district_1960")]
resto <- unique(resto[is.na(ja)], by = c("uf60", "code_muni_1960", "code_district_1960"))
resto[, ja := NULL]
message("do guia anterior, que a transcricao nao tem: ", nrow(resto), " pares")

r <- rbindlist(list(r, resto), use.names = TRUE, fill = TRUE)

# --- Brasilia: a numeracao impressa do livro nao foi a que o censo usou -------
#
# A pagina 313 e um documento emendado a mao. Os codigos datilografados -- 9701
# Cidade de Brasilia, 9702 Planaltina, 9703 Taguatinga, 9704 Sobradinho, 9705
# Zona Rural -- foram riscados e substituidos por 01 a 06 manuscritos, com a
# linha do Nucleo Bandeirante acrescentada a mao entre as duas primeiras. O
# transcritor anota que as emendas nao tem autoria, data nem assinatura.
#
# O arquivo bruto mostra que os codificadores ignoraram a emenda: V116 = 9701
# nos 14.818 registros do Distrito Federal, e os distritos sao 01, 03, 05 e 07
# -- a convencao impar do resto do pais, aplicada aos quatro lugares da relacao
# datilografada. Sao quatro distritos, e nao seis: o Nucleo Bandeirante esta
# dentro da Cidade de Brasilia e "Zona Rural" e situacao do domicilio, que vai
# em V118.
#
# Tres medidas fixam qual nome cabe a cada codigo:
#
#  1. O distrito 03 tem 54,2% de nascidos em Goias, contra 15% a 23% nos outros
#     tres. E Planaltina, a cidade goiana antiga incorporada ao Distrito Federal.
#  2. A Sinopse Preliminar do Censo de 1970 do Distrito Federal publica, no seu
#     quadro 1, a populacao recenseada em 1960 por regiao administrativa, e a
#     soma fecha nos 141.742 da Serie Nacional: Brasilia 92.761 (Plano Piloto
#     71.728 mais Nucleo Bandeirante 21.033), Taguatinga 27.315, Sobradinho
#     10.217, Planaltina 4.651, Paranoa 3.576, Jardim 1.677, Gama 811 e
#     Brazlandia 734. A nossa ordem de tamanho e a mesma -- 07 = 25.386,
#     05 = 8.235, 03 = 2.972 --, com razoes de 0,93, 0,81 e 0,64.
#  3. A ordem da pagina impressa poria Taguatinga em 05 e Sobradinho em 07, o
#     que daria 8.235 contra 27.315 e 25.386 contra 10.217: razoes de 0,30 e
#     2,49. A publicacao desmente.
#
# Vale a ordem alfabetica depois da sede, que e a regra do livro em 96,4% dos
# municipios com tres distritos ou mais.
#
# O Nucleo Bandeirante, a linha acrescentada a mao, nao e distrito: e o quadro
# suburbano da Cidade de Brasilia. A tabela de 1970 da Brasilia em 1960 como
# Plano Piloto (71.728) mais Nucleo Bandeirante (21.033), e o nosso distrito 01
# se reparte em urbano 67.160, suburbano 21.306 e rural 14.734 -- o suburbano
# fica a 1,3% do Nucleo Bandeirante. "Zona Rural", a outra linha manuscrita, e
# situacao do domicilio e vai em V118: as quatro cidades satelites foram todas
# recenseadas no quadro rural, e a Sinopse Preliminar do Brasil confirma, dando
# a populacao urbana do Distrito Federal como 89.698, toda na sede municipal,
# contra os 88.466 que somamos em urbano mais suburbano.
brasilia <- data.table(
  uf60 = 97L, code_muni_1960 = 9700L, name_muni_1960 = "Brasília",
  code_district_1960 = c(1L, 3L, 5L, 7L),
  name_district_1960 = c("Cidade de Brasília", "Planaltina", "Sobradinho", "Taguatinga"),
  name_bairro_1960 = NA_character_, tipo = "distrito",
  zona_cod = NA_integer_, zona = NA_character_, pagina = 313L,
  fonte = "Codigo de Zonas Fisiograficas de 1960 p. 313 (relacao datilografada, antes da emenda manuscrita), na convencao impar; ordem conferida contra a populacao de 1960 por regiao administrativa da Sinopse Preliminar do Censo de 1970 do Distrito Federal, quadro 1")
r <- r[code_muni_1960 != 9700L]
r <- rbindlist(list(r, brasilia), use.names = TRUE, fill = TRUE)
message("Brasilia: ", nrow(brasilia), " distritos, no lugar das ", 6, " linhas da emenda manuscrita")

setorder(r, uf60, code_muni_1960, code_district_1960)

# nenhum par pode aparecer duas vezes: o join do pipeline e por (uf60,
# code_muni_1960, code_district_1960) e duplicata multiplicaria linhas
dup <- r[, .N, by = .(uf60, code_muni_1960, code_district_1960)][N > 1]
if(nrow(dup) > 0){
  message("  ", nrow(dup), " pares duplicados na transcricao; fica a primeira ocorrencia")
  r <- unique(r, by = c("uf60", "code_muni_1960", "code_district_1960"))
}

fwrite(r, saida)
message("gravado: ", saida, " -- ", nrow(r), " linhas (antes: ", nrow(guia), ")")
message("  com nome de distrito: ", r[!is.na(name_district_1960) & name_district_1960 != "", .N])
message("  favelas: ", r[tipo == "favela", .N], " | circunscricoes: ", r[tipo == "circunscrição", .N])
