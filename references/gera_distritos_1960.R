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
# primeira pagina de cada estado o traz
novo[muni, `:=`(uf60 = i.uf60, name_muni_1960 = i.nome), on = c(code_muni_1960 = "cod60")]

gb <- novo$code_muni_1960 >= 5410 & novo$code_muni_1960 <= 5591
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
resto[muni, `:=`(uf60 = i.uf60, name_muni_1960 = i.nome), on = c(code_muni_1960 = "cod60")]
resto <- resto[!is.na(uf60)]
resto[r, ja := TRUE, on = c("uf60", "code_muni_1960", "code_district_1960")]
resto <- unique(resto[is.na(ja)], by = c("uf60", "code_muni_1960", "code_district_1960"))
resto[, ja := NULL]
message("do guia anterior, que a transcricao nao tem: ", nrow(resto), " pares")

r <- rbindlist(list(r, resto), use.names = TRUE, fill = TRUE)
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
