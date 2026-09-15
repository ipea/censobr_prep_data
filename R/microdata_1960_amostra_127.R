# Censo Demográfico de 1960 — preparação da amostra de 1,27%
#
# Este arquivo reconstrói, passo a passo, a amostra de 1,27% do Censo de 1960
# a partir do único arquivo bruto que existe dela. Cada função abaixo é um
# passo do procedimento e um target do pipeline; cada uma explica, antes do
# código, qual é o problema, como ele se parece no arquivo, o que se faz com
# ele e como fica depois. A intenção é que qualquer pessoa consiga ler este
# arquivo de cima a baixo e conferir cada decisão sem precisar rodar nada.
#
#
# DE ONDE VEM O DADO
#
# O IBGE não distribui microdados do Censo de 1960 — é a única edição desde
# 1960 sem arquivo no FTP. O que existe são duas amostras que circularam entre
# pesquisadores:
#
#  - a amostra de 25%, oficial, que nunca foi processada por completo: só 17
#    unidades da federação foram digitalizadas, e o IBGE não a distribui;
#  - a amostra de 1,27%, sorteada em 1965 a partir da anterior, com todas as
#    unidades da federação, usada no Volume 2 dos Resultados Preliminares do
#    Censo (IBGE, 1965). É dela que trata este arquivo.
#
# A cópia da amostra de 1,27% chegou ao Centro de Estudos da Metrópole por
# doação (Telles e Wood → Costa Ribeiro e Cardoso → CEM), sem nenhuma via
# oficial, e foi consistida por Rogério Barbosa em 2018 no repositório
# https://github.com/antrologos/ConsistenciaCenso1960Br. O arquivo bruto,
# HHOLDA.txt, está lá, e é de lá que este pipeline o baixa (commit df7adcc,
# de 21/08/2018). Os passos abaixo refazem aquela consistência com o que se
# aprendeu depois: o exame de 14/09/2026 está em
# references/microdata_1960_amostra_127_consistencia.md.
#
#
# COMO O ARQUIVO SE PARECE
#
# HHOLDA.txt tem 1.074.328 linhas, todas de exatamente 62 caracteres, sem
# separador. Cada linha é um registro, e há dois tipos de registro no mesmo
# arquivo, um em cima do outro:
#
#   00001101000140511114741 400000   \0000001   <- registro de família
#   0000110100014051211175942170910200... \0000001   <- pessoa: o chefe
#   0000110100014051311284942170910200... \0000001   <- pessoa: outro morador
#
# O caractere 17 diz o tipo: 1 = registro de família (traz as características
# do domicílio: tipo, água, luz, cômodos...), 2 = pessoa na posição de chefe,
# 3 = qualquer outra pessoa. Os caracteres 1-2 são a unidade da federação
# (códigos de 1960: 00 Rondônia ... 97 Distrito Federal), 3-6 o município,
# e 7-16 a identificação do questionário: distrito (7-8), pasta (9-13) e
# número do boletim dentro da pasta (14-16). Essa identificação é a mesma no
# registro de família e nas pessoas dele — é a chave que liga uma coisa à
# outra. As posições 55-62 trazem uma barra invertida e um número de sete
# dígitos, \0000001, que NÃO estava na fita original: foi acrescentado depois,
# por quem converteu o arquivo, contando um a um os registros de família. Ele
# serve de referência de leitura, mas não é confiável como identificador —
# pula números e, quando o registro de família de uma família se perdeu,
# gruda as pessoas dela na família anterior. Por isso o pipeline reconstrói
# as famílias pela chave do questionário, e guarda esse número só como
# rastreio (id_arquivo).
#
# Um hífen no meio da linha, sempre no primeiro caractere de um campo e
# seguido de brancos, é a marca de "não se aplica daqui em diante": aparece
# depois da ocupação (posição 47), depois do lugar de residência anterior
# (33), depois do grau do curso (36), e nos registros de família de
# domicílios coletivos (20) e improvisados (21). Não é lixo; é o formulário
# dizendo que as perguntas seguintes não foram feitas.
#
#
# O QUE PODE ESTAR ERRADO NUMA LINHA
#
# A fita de 1965 foi lida, convertida de EBCDIC para ASCII e copiada várias
# vezes ao longo de cinquenta anos. Sobraram quatro tipos de dano, todos
# raros (124 linhas em 1.074.328), mas que precisam ser vistos um a um:
#
#  1. um valor que não existe no dicionário de códigos — um "7" onde só cabem
#     1, 2 ou 3; quase sempre um único caractere trocado, o resto da linha
#     intacto;
#  2. um caractere que não é dígito, branco, hífen nem barra — letras, sinais,
#     bytes de controle; a linha 293555 traz a palavra BAHIA escrita no meio;
#  3. um ou mais brancos inseridos entre dois dígitos, que empurram tudo o que
#     vem depois para a direita — a linha fica com os campos deslocados e
#     valores válidos em posições erradas; quase sempre basta tirar os brancos
#     e o registro volta a fazer sentido;
#  4. um hífen ou uma barra fora do lugar em que deveriam estar — sinal de que
#     um caractere se perdeu ou sobrou em algum ponto anterior da linha, mesmo
#     quando todos os campos parecem válidos (branco é um valor válido em quase
#     todo campo, então um deslocamento de uma casa passa despercebido pelos
#     três primeiros testes).
#
# Os quatro testes marcam as linhas suspeitas; a decisão sobre cada uma é
# humana e está escrita em read_guides/1960_amostra_127_correcoes.csv, linha a
# linha: o texto original, o texto corrigido (quando há correção), o tipo de
# decisão e uma explicação em prosa. O código só aplica o que está lá. Se
# aparecer uma linha suspeita sem decisão escrita, o pipeline para e diz qual.
#
#
# O QUE ESTE ESTÁGIO PRODUZ
#
# Duas tabelas intermediárias em parquet — pessoas e domicílios da amostra de
# 1,27% —, mais um registro de tudo o que foi alterado. Elas alimentam o
# estágio seguinte, que junta esta amostra com a de 25% e produz as tabelas
# publicadas de 1960.
#
# Public API, na ordem dos targets: download_1960_amostra_127,
# read_1960_amostra_127, detect_1960_amostra_127,
# apply_corrections_1960_amostra_127, parse_1960_amostra_127.


# ------------------------------------------------------------------------------
# As quatro regiões em que o IBGE publicou os Resultados Preliminares de 1965,
# nos códigos de UF de 1960. Norte e Centro-Oeste só aparecem somados, e o
# volume não os separa; aqui vão juntos pelo mesmo motivo.
REGIAO_1960 <- c("0" = "Norte e Centro-Oeste", "1" = "Norte e Centro-Oeste", "2" = "Norte e Centro-Oeste", "3" = "Norte e Centro-Oeste",
                 "4" = "Norte e Centro-Oeste", "6" = "Norte e Centro-Oeste", "91" = "Norte e Centro-Oeste", "94" = "Norte e Centro-Oeste", "97" = "Norte e Centro-Oeste",
                 "10" = "Nordeste", "12" = "Nordeste", "14" = "Nordeste", "17" = "Nordeste", "19" = "Nordeste", "21" = "Nordeste", "24" = "Nordeste", "25" = "Nordeste",
                 "30" = "Leste", "31" = "Leste", "40" = "Leste", "50" = "Leste", "51" = "Leste", "52" = "Leste", "54" = "Leste",
                 "60" = "Sul", "71" = "Sul", "74" = "Sul", "81" = "Sul")


# Passo 1 — baixar o arquivo bruto
#
# O arquivo tem 68.756.992 bytes e vem do repositório de 2018, num commit fixo,
# para que o download seja sempre o mesmo. Se o tamanho não bater, o pipeline
# para: um arquivo truncado produziria um censo menor sem avisar.
# ------------------------------------------------------------------------------
download_1960_amostra_127 <- function(){

  dest_dir <- "./data_raw/microdata/1960/amostra_127"
  dir.create(dest_dir, recursive = TRUE, showWarnings = FALSE)

  message("\nDownloading 1960 amostra de 1,27% (HHOLDA.txt)...\n")

  url <- paste0("https://raw.githubusercontent.com/antrologos/ConsistenciaCenso1960Br/",
                "df7adcc/Original%20Files/HHOLDA.txt")
  dest <- file.path(dest_dir, "HHOLDA.txt")

  if(!file.exists(dest)) download_file_censobr(file_url = url, dest_dir = dest_dir, max_active = 1)

  if(file.size(dest) != 68756992) stop("HHOLDA.txt veio com ", file.size(dest), " bytes; esperados 68.756.992")

  dest
}


# ------------------------------------------------------------------------------
# Passo 2 — ler as linhas sem mexer em nada
#
# Lemos o arquivo como texto, uma linha por registro, e guardamos cada linha
# inteira, com hífens e tudo. Ao lado dela, só o que é preciso para navegar:
# o número da linha (que vira o identificador de rastreio de cada registro),
# o tipo de registro, a unidade da federação, o município, a chave do
# questionário e o número acrescentado a posteriori.
#
# Nada é alterado aqui. A única checagem é que todas as linhas tenham 62
# caracteres — se alguma não tiver, o arquivo não é o que se espera.
# ------------------------------------------------------------------------------
read_1960_amostra_127 <- function(path){

  message("Reading 1960 amostra de 1,27%")

  texto <- readLines(path, encoding = "latin1", warn = FALSE)

  n_fora <- sum(nchar(texto) != 62)
  if(n_fora > 0) stop(n_fora, " linhas nao tem 62 caracteres")

  linhas <- data.table::data.table(
    linha      = seq_along(texto),
    texto      = texto,
    tipo       = substr(texto, 17, 17),     # 1 familia, 2 chefe, 3 outro morador
    uf         = substr(texto,  1,  2),
    v116       = substr(texto,  3,  6),     # municipio
    distrito   = substr(texto,  7,  8),
    pasta      = substr(texto,  9, 13),
    boletim    = substr(texto, 14, 16),
    chave      = substr(texto,  7, 16),     # identificacao do questionario
    id_arquivo = substr(texto, 56, 62))

  message("  ", format(nrow(linhas), big.mark = ".", decimal.mark = ","), " linhas: ",
          format(sum(linhas$tipo == "1"), big.mark = ".", decimal.mark = ","), " registros de familia, ",
          format(sum(linhas$tipo != "1"), big.mark = ".", decimal.mark = ","), " de pessoas")

  linhas
}


# ------------------------------------------------------------------------------
# Passo 3 — encontrar as linhas suspeitas
#
# O layout (posição inicial e final de cada variável, e a lista de códigos que
# ela aceita) está em read_guides/readguide_1960_amostra_127_familias.csv e
# _pessoas.csv. Foi transcrito das sintaxes SPSS e SAS que acompanhavam o
# arquivo — o dicionário em .doc que veio junto descreve outro layout, o da
# amostra de 25% — com duas correções documentadas na coluna "observacao":
# a sintaxe SPSS lia o lugar de residência anterior (V210) em uma só coluna,
# e omitia o código 59 do ano de casamento (V216).
#
# Para cada variável de cada linha, o valor é válido quando está na lista de
# códigos, ou é branco onde branco é permitido, ou é a marca de salto (hífen
# seguido de brancos). Os quatro testes descritos no cabeçalho marcam a linha;
# o resultado vai para uma tabela pequena, com a linha inteira à vista, que é
# também gravada em CSV para leitura humana em
# data_raw/microdata/1960/amostra_127/linhas_problematicas.csv.
#
# Depois de marcar, confere-se a cobertura das decisões manuais: toda linha
# suspeita precisa ter uma decisão em 1960_amostra_127_correcoes.csv, e toda
# decisão precisa apontar para uma linha suspeita (a exceção é a decisão
# "realocada", que é sobre uma linha íntegra no lugar errado).
# ------------------------------------------------------------------------------
detect_1960_amostra_127 <- function(linhas, guia_familias, guia_pessoas, correcoes){

  message("Detecting problems in 1960 amostra de 1,27%")

  gf <- data.table::fread(guia_familias, encoding = "UTF-8")
  gp <- data.table::fread(guia_pessoas,  encoding = "UTF-8")

  # teste 1: valor fora do dicionario. Devolve, por linha, os nomes das
  # variaveis com valor invalido, separados por espaco ("" quando nenhuma)
  fora_do_dicionario <- function(texto, guia){
    invalidas <- rep("", length(texto))
    for(i in seq_len(nrow(guia))){
      if(guia$variavel[i] %in% c("BARRA", "ID")) next
      v <- substr(texto, guia$inicio[i], guia$fim[i])
      largura <- guia$fim[i] - guia$inicio[i] + 1
      salto <- substr(v, 1, 1) == "-" & trimws(substr(v, 2, largura)) == ""
      if(guia$valores_validos[i] == ""){
        ruim <- grepl("[^0-9 ]", v) & !salto        # campo livre: so digitos
      } else {
        codigos <- strsplit(guia$valores_validos[i], ";", fixed = TRUE)[[1]]
        branco_ok <- any(codigos %in% c("", "NA"))
        codigos <- codigos[!codigos %in% c("", "NA")]
        ruim <- !(v %in% codigos) & !salto & !(branco_ok & trimws(v) == "")
      }
      invalidas[ruim] <- paste(invalidas[ruim], guia$variavel[i])
    }
    trimws(invalidas)
  }

  fam <- linhas$tipo == "1"
  linhas[, det_dicionario := ""]
  linhas[fam == TRUE,  det_dicionario := fora_do_dicionario(texto, gf)]
  linhas[fam == FALSE, det_dicionario := fora_do_dicionario(texto, gp)]

  # teste 2: caractere que nao e digito, branco, hifen nem barra
  linhas[, det_caractere := grepl("[^0-9 \\\\-]", texto)]

  # teste 3: um a tres brancos entre dois digitos (deslocamento)
  linhas[, det_espaco := grepl("[0-9] {1,3}[0-9]", texto)]

  # teste 4: hifen fora das cinco posicoes de salto, ou barra fora da posicao 55
  pos_hifen <- gregexpr("-", linhas$texto, fixed = TRUE)
  linhas[, det_estrutura := sapply(pos_hifen, function(p) any(p > 0 & !p %in% c(20, 21, 33, 36, 47))) |
                             substr(texto, 55, 55) != "\\" |
                             grepl("\\\\", substr(texto, 1, 54))]

  problemas <- linhas[det_dicionario != "" | det_caractere | det_espaco | det_estrutura,
                      .(linha, tipo, uf, v116, chave, id_arquivo, texto,
                        det_dicionario, det_caractere, det_espaco, det_estrutura)]
  linhas[, c("det_dicionario", "det_caractere", "det_espaco", "det_estrutura") := NULL]

  message("  ", nrow(problemas), " linhas suspeitas (",
          sum(problemas$tipo == "1"), " de familia, ", sum(problemas$tipo != "1"), " de pessoa)")

  dir.create("./data_raw/microdata/1960/amostra_127", recursive = TRUE, showWarnings = FALSE)
  data.table::fwrite(problemas, "./data_raw/microdata/1960/amostra_127/linhas_problematicas.csv", bom = TRUE)

  # cobertura das decisoes manuais
  # read.csv, nao fread: so ele devolve as aspas dobradas e os brancos iniciais
  # exatamente como estao no arquivo
  dec <- data.table::as.data.table(utils::read.csv(correcoes, strip.white = FALSE, stringsAsFactors = FALSE,
                                                   fileEncoding = "UTF-8-BOM", colClasses = "character"))
  dec[, linha := as.integer(linha)]
  sem_decisao <- setdiff(problemas$linha, dec$linha)
  sem_suspeita <- setdiff(dec[decisao != "realocada", linha], problemas$linha)
  if(length(sem_decisao))  stop("linhas suspeitas sem decisao em 1960_amostra_127_correcoes.csv: ", paste(sem_decisao, collapse = ", "))
  if(length(sem_suspeita)) stop("decisoes sobre linhas que nenhum teste marcou: ", paste(sem_suspeita, collapse = ", "))
  if(any(dec$texto_original != linhas$texto[dec$linha])) stop("o texto original de alguma decisao nao bate com o arquivo")

  problemas
}


# ------------------------------------------------------------------------------
# Passo 4 — aplicar as decisões escritas
#
# read_guides/1960_amostra_127_correcoes.csv tem uma linha por linha suspeita e
# seis tipos de decisão:
#
#   valor_isolado  um ou poucos valores fora do dicionário, o resto coerente.
#                  Nada muda aqui; no passo 6 esses valores viram NA e a
#                  variável fica anotada.
#   reparo         a linha estava deslocada (brancos a mais, barra ausente) e
#                  foi recomposta; "texto_corrigido" mostra como ficou. O que
#                  se perdeu de fato vira NA.
#   recuperada     a linha estava marcada como irrecuperável em 2018, mas
#                  contém um registro legível de outra família — a chave do
#                  questionário diz de qual. "texto_corrigido" traz o registro
#                  recomposto e o número da família certa.
#   realocada      a linha está íntegra, mas gravada longe da sua família; a
#                  chave do questionário a devolve ao lugar. Nada muda no texto.
#   corrompida     não sobrou nada legível além do tipo de registro. Todas as
#                  variáveis viram NA; a linha continua no banco, marcada.
#   cartao_uf      não é um registro: é um cartão de cabeçalho da fita, com o
#                  nome do estado em letras (BAHIA, GUANABARA). Sai do banco.
#
# Cada linha alterada guarda, na coluna censobr_diagnostico, qual decisão a
# atingiu; as demais recebem "sem_problema".
# ------------------------------------------------------------------------------
apply_corrections_1960_amostra_127 <- function(linhas, correcoes){

  message("Applying manual corrections to 1960 amostra de 1,27%")

  # read.csv, nao fread: so ele devolve as aspas dobradas e os brancos iniciais
  # exatamente como estao no arquivo
  dec <- data.table::as.data.table(utils::read.csv(correcoes, strip.white = FALSE, stringsAsFactors = FALSE,
                                                   fileEncoding = "UTF-8-BOM", colClasses = "character"))
  dec[, linha := as.integer(linha)]

  linhas <- data.table::copy(linhas)
  linhas[, censobr_diagnostico := "sem_problema"]
  linhas[dec, censobr_diagnostico := i.decisao, on = "linha"]

  # reparo e recuperada: o texto corrigido substitui o original
  com_texto <- dec[texto_corrigido != ""]
  linhas[com_texto, texto := i.texto_corrigido, on = "linha"]

  # corrompida: so o tipo de registro sobrevive; o resto vira branco
  linhas[censobr_diagnostico == "corrompida",
         texto := paste0(strrep(" ", 16), substr(texto, 17, 17), strrep(" ", 37), "\\", substr(texto, 56, 62))]

  # cartao_uf: nao e registro
  linhas <- linhas[censobr_diagnostico != "cartao_uf"]

  # as colunas de navegacao sao refeitas a partir do texto corrigido
  linhas[, `:=`(tipo       = substr(texto, 17, 17),
                uf         = substr(texto,  1,  2),
                v116       = substr(texto,  3,  6),
                distrito   = substr(texto,  7,  8),
                pasta      = substr(texto,  9, 13),
                boletim    = substr(texto, 14, 16),
                chave      = substr(texto,  7, 16),
                id_arquivo = substr(texto, 56, 62))]

  message("  ", paste(names(table(linhas$censobr_diagnostico)), table(linhas$censobr_diagnostico), collapse = "; "))

  linhas
}


# ------------------------------------------------------------------------------
# Passo 5 — separar as variáveis
#
# Agora sim o layout é aplicado: cada variável vira uma coluna, ainda como
# texto (para não perder zeros à esquerda antes de decidir os tipos). Três
# regras transformam valor em NA, e a coluna censobr_variaveis_anuladas
# registra, por registro, quais variáveis tinham valor inválido:
#
#  - branco onde o dicionário permite branco: não se aplica -> NA;
#  - hífen de salto: não se aplica daqui em diante -> NA;
#  - valor fora do dicionário (o "valor_isolado" das decisões): NA, anotado.
#
# Saem duas tabelas: familias (um registro por questionário de família) e
# pessoas. Ambas guardam a linha de origem, a chave do questionário, o número
# a posteriori e o diagnóstico.
# ------------------------------------------------------------------------------
parse_1960_amostra_127 <- function(linhas, guia_familias, guia_pessoas){

  message("Parsing 1960 amostra de 1,27%")

  aplica_layout <- function(x, guia){
    out <- x[, .(linha, id_arquivo, censobr_diagnostico, distrito, pasta, boletim, chave)]
    anuladas <- rep("", nrow(x))
    for(i in seq_len(nrow(guia))){
      var <- guia$variavel[i]
      if(var %in% c("BARRA", "ID", "REC_TYPE")) next
      v <- substr(x$texto, guia$inicio[i], guia$fim[i])
      largura <- guia$fim[i] - guia$inicio[i] + 1
      salto <- substr(v, 1, 1) == "-" & trimws(substr(v, 2, largura)) == ""
      branco <- trimws(v) == ""
      if(guia$valores_validos[i] == ""){
        ruim <- grepl("[^0-9 ]", v) & !salto
      } else {
        codigos <- strsplit(guia$valores_validos[i], ";", fixed = TRUE)[[1]]
        codigos <- codigos[!codigos %in% c("", "NA")]
        ruim <- !(v %in% codigos) & !salto & !branco
      }
      v[salto | branco | ruim] <- NA_character_
      anuladas[ruim] <- paste(anuladas[ruim], var)
      out[, (var) := v]
    }
    out[, censobr_variaveis_anuladas := trimws(anuladas)]
    out
  }

  gf <- data.table::fread(guia_familias, encoding = "UTF-8")
  gp <- data.table::fread(guia_pessoas,  encoding = "UTF-8")

  familias <- aplica_layout(linhas[tipo == "1"], gf)
  pessoas  <- aplica_layout(linhas[tipo != "1"], gp)
  pessoas[, tipo := linhas[tipo != "1", tipo]]          # 2 chefe, 3 outro morador

  message("  familias: ", format(nrow(familias), big.mark = ".", decimal.mark = ","), " x ", ncol(familias),
          " | pessoas: ", format(nrow(pessoas), big.mark = ".", decimal.mark = ","), " x ", ncol(pessoas),
          " | registros com valor anulado: ",
          sum(familias$censobr_variaveis_anuladas != "") + sum(pessoas$censobr_variaveis_anuladas != ""))

  list(familias = familias, pessoas = pessoas)
}


# ------------------------------------------------------------------------------
# Passo 6 — as linhas duplicadas de Pernambuco
#
# O problema. Em três municípios de Pernambuco (códigos 2135, 2113 e 2115)
# o arquivo repete linhas de pessoa: a mesma pessoa, com todos os 54
# caracteres de dado idênticos, aparece duas vezes na mesma família — nunca
# uma logo abaixo da outra, e em ordem embaralhada. A família de id_arquivo
# 29839, por exemplo, lista as pessoas A, B, C, D, E e, algumas linhas depois,
# C, B, A, E, D. São 2.815 linhas em Pernambuco (5,1% da UF) e no máximo 1,6
# por mil em qualquer outra UF; 497 delas são cônjuges repetidos, o que não
# existe legitimamente. É o rastro de um defeito de cópia da fita — o mesmo
# que fez o numerador de famílias pular 856 números exatamente nesses
# municípios. Sem tratamento, Pernambuco fica com 5% de gente a mais e
# famílias de 7,9 pessoas em média onde as vizinhas têm 5,0.
#
# A prova de que são cópias, e não pessoas. A comparação é dentro do mesmo
# questionário: a linha repetida tem a mesma chave (UF, município, distrito,
# pasta, boletim), o mesmo número a posteriori e os mesmos 54 caracteres de
# dado de outra linha da mesma família; duas famílias parecidas nunca entram
# na comparação. Dentro de uma família, duas linhas idênticas só podem ser
# gêmeos de mesmo perfil ou uma cópia, e cinco fatos separam os dois casos:
# 497 das repetidas são cônjuges; a taxa de linhas idênticas é 0,95 por mil
# no país e 51 por mil em três municípios de Pernambuco; as repetidas formam
# um bloco contíguo colado ao fim da família (99% das famílias atingidas),
# que em 74% delas é exatamente todos os cartões da família menos o do
# chefe, em ordem embaralhada; as famílias atingidas têm 7,9 pessoas e, sem
# as repetidas, 4,6, igual às vizinhas; e a tabulação oficial de 1965
# (Resultados Preliminares, Série Especial, vol. II), feita com estes mesmos
# cartões antes do dano, só reproduz o Nordeste sem as cópias — o fator de
# expansão implícito fica em 79,5, como nas outras regiões, e não em 78,4.
#
# A solução segue a forma do defeito. Uma linha repetida é removida quando:
#
#   - é chefe ou cônjuge (nenhuma família tem dois cônjuges idênticos); ou
#   - a família tem duas ou mais linhas repetidas: é o bloco copiado (dois
#     pares de gêmeos idênticos numa só família não acontecem); ou
#   - é uma repetida avulsa na cauda da família, depois de todos os
#     originais, num dos três municípios danificados (2135, 2113 e 2115),
#     onde mesmo as repetidas avulsas são quatro vezes mais frequentes que
#     no resto do país, e 45 das 49 estão na cauda — onde as cópias ficam.
#
# Uma linha repetida fora dessas condições — uma só, de filho ou parente,
# numa família sem outra repetição, fora dos três municípios — é gêmeo ou
# irmão de mesmo perfil e fica, marcada em censobr_duplicata_mantida. As
# linhas removidas, com o motivo de cada uma, ficam registradas em
# data_raw/microdata/1960/amostra_127/duplicatas_removidas.csv.
# ------------------------------------------------------------------------------
dedup_1960_amostra_127 <- function(tabelas){

  message("Removing duplicated person lines (Pernambuco) in 1960 amostra de 1,27%")

  pessoas <- data.table::copy(tabelas$pessoas)

  # as variaveis que descrevem a pessoa: tudo menos linha, id e diagnostico
  vars <- setdiff(names(pessoas), c("linha", "id_arquivo", "censobr_diagnostico", "censobr_variaveis_anuladas"))
  pessoas[, conteudo := do.call(paste, c(.SD, sep = "|")), .SDcols = vars]

  # repetida: mesma chave de questionario e mesmos 54 caracteres de dado de uma linha anterior da mesma familia
  pessoas[, repetida := duplicated(conteudo), by = id_arquivo]

  # o bloco copiado foi anexado ao fim da familia: fica depois da ultima linha original
  pessoas[, na_cauda := repetida & linha > max(linha[!repetida]), by = id_arquivo]
  pessoas[, n_repetidas := sum(repetida), by = id_arquivo]
  pessoas[, municipio_danificado := UF %in% "21" & V116 %in% c("2135", "2113", "2115")]

  pessoas[, remover := repetida & (V203 %in% c("7", "8") | n_repetidas >= 2 | (na_cauda & municipio_danificado))]
  pessoas[, censobr_duplicata_mantida := repetida & !remover]

  removidas <- pessoas[remover == TRUE, .(linha, id_arquivo, UF, V116, tipo, V203, AGE, V202, na_cauda, n_repetidas,
                                          motivo = data.table::fifelse(V203 %in% c("7", "8"), "conjuge_ou_chefe_repetido",
                                                   data.table::fifelse(n_repetidas >= 2, "bloco_copiado", "avulsa_na_cauda_municipio_danificado")))]
  data.table::fwrite(removidas, "./data_raw/microdata/1960/amostra_127/duplicatas_removidas.csv", bom = TRUE)

  message("  linhas repetidas: ", sum(pessoas$repetida), "; removidas: ", nrow(removidas),
          " (", paste(names(table(removidas$motivo)), table(removidas$motivo), collapse = ", "),
          "; Pernambuco: ", sum(removidas$UF %in% "21"), "); mantidas com marca: ", sum(pessoas$censobr_duplicata_mantida))

  pessoas <- pessoas[remover == FALSE]
  pessoas[, c("conteudo", "repetida", "na_cauda", "n_repetidas", "municipio_danificado", "remover") := NULL]

  list(familias = tabelas$familias, pessoas = pessoas)
}


# ------------------------------------------------------------------------------
# Passo 7 — reconstruir famílias e domicílios
#
# A família. Cada pessoa é ligada ao registro de família que tem a mesma
# unidade da federação e a mesma chave de questionário (distrito, pasta,
# boletim). É assim que o formulário de 1960 funcionava: um boletim por
# família, com a página de domicílio na frente e as pessoas atrás. Em 99,2%
# dos casos isso coincide com o número acrescentado a posteriori; nos outros
# a chave corrige o número — as linhas realocadas e recuperadas do passo 4
# voltam para a família certa por aqui.
#
# Pessoas cujo questionário não tem registro de família: são 2.678, em 586
# grupos (um grupo = uma chave de questionário). O número a posteriori não
# ajuda a decidir o que são, porque foi atribuído contando registros de
# família na ordem do arquivo: 585 dos 586 grupos carregam o número da
# família imediatamente anterior, e nenhum tem número próprio. Sobra o que
# está nas próprias linhas, e daí vêm dois tipos, com tratamento diferente:
#
#   - o grupo tem chefe ou cônjuge (150 grupos): é uma família cujo registro
#     de família — e quase sempre o chefe, que era a linha seguinte — se
#     perdeu na fita. Três grupos ainda têm o chefe; 147 têm só cônjuge, e
#     em 87 deles a família anterior já tem o seu próprio cônjuge, o que
#     exclui a hipótese de ser a mesma família. Vira família nova, sem página
#     de domicílio (V101 a V113 ficam NA), marcada "registro_perdido";
#   - o grupo não tem chefe nem cônjuge (436 grupos, 1.008 pessoas): são
#     sobretudo hóspedes (V203 = 4 em 698 delas) e pessoas presentes que não
#     moram ali (V202 = 5 ou 6 em 681), listadas num boletim à parte logo
#     depois da família — o id_arquivo 2326 tem um chefe de 50 anos sozinho
#     seguido de 26 hóspedes não moradores em dois boletins. Ficam na família
#     anterior (o registro de família imediatamente acima na ordem do
#     arquivo), marcadas "anexada_anterior".
#
# Nos dois casos a marca fica na pessoa e na família, e a decisão pode ser
# revista pelo usuário sem reler o arquivo.
#
# O domicílio. V101 diz o que a família é: 1 = único ocupante do domicílio,
# 2 = família principal de um domicílio com mais de uma, 3 = coletivo, 4 =
# segunda família, 5 = terceira. Uma família 4 ou 5 vem sempre logo depois
# da principal (345 de 345 vezes), com o boletim seguinte. Então: 1, 2 e 3
# abrem domicílio; 4 e 5 entram no domicílio da família anterior. O único 5
# que vem depois de um 1 (id_arquivo 121705) abre domicílio próprio, marcado.
#
# Rondônia. 64 famílias (253 pessoas) estão gravadas com UF 03 (Roraima) e
# município 0011, que é Porto Velho: têm a mesma pasta (01/00) das 76
# famílias de Rondônia, naturalidade de Guaporé e Amazonas como elas, e
# estão no arquivo logo antes do Roraima verdadeiro (município 0310). Voltam
# para Rondônia (UF 00), marcadas em censobr_uf_corrigida.
# ------------------------------------------------------------------------------
build_families_1960_amostra_127 <- function(tabelas){

  message("Building families and households in 1960 amostra de 1,27%")

  familias <- data.table::copy(tabelas$familias)
  pessoas  <- data.table::copy(tabelas$pessoas)

  # Rondonia gravada como Roraima
  familias[, censobr_uf_corrigida := UF == "03" & V116 == "0011"]
  pessoas[,  censobr_uf_corrigida := UF == "03" & V116 == "0011"]
  familias[censobr_uf_corrigida == TRUE, UF := "00"]
  pessoas[censobr_uf_corrigida == TRUE,  UF := "00"]
  message("  Rondonia: ", sum(familias$censobr_uf_corrigida), " familias e ", sum(pessoas$censobr_uf_corrigida), " pessoas devolvidas")

  # a familia e o registro de familia; a pessoa liga-se a ela pela chave
  familias[, censobr_idfamily := seq_len(.N)]
  familias[, censobr_familia_origem := "registro"]
  pessoas[familias, censobr_idfamily := i.censobr_idfamily, on = c("UF", "chave")]
  pessoas[, censobr_familia_origem := data.table::fifelse(is.na(censobr_idfamily), "", "registro")]

  # grupos sem registro de familia
  soltas <- pessoas[is.na(censobr_idfamily)]
  grupos <- soltas[, .(linha_primeira = min(linha),
                       tem_chefe_ou_conjuge = any(tipo == "2" | V203 %in% c("7", "8")), n = .N), by = .(UF, chave)]
  message("  pessoas sem registro de familia: ", nrow(soltas), " em ", nrow(grupos),
          " grupos; com chefe ou conjuge: ", sum(grupos$tem_chefe_ou_conjuge))

  # com chefe ou conjuge: familia nova, sem pagina de domicilio
  novas <- grupos[tem_chefe_ou_conjuge == TRUE]
  if(nrow(novas)){
    novas[, censobr_idfamily := nrow(familias) + seq_len(.N)]
    fam_novas <- novas[, .(linha = linha_primeira, UF, chave,
                           distrito = substr(chave, 1, 2), pasta = substr(chave, 3, 7), boletim = substr(chave, 8, 10),
                           censobr_idfamily, censobr_diagnostico = "registro_perdido",
                           censobr_familia_origem = "registro_perdido", censobr_uf_corrigida = FALSE)]
    primeira <- soltas[novas, on = c("UF", "chave"), mult = "first"][, .(UF, chave, id_arquivo, V116, V118)]
    fam_novas[primeira, `:=`(id_arquivo = i.id_arquivo, V116 = i.V116, V118 = i.V118), on = c("UF", "chave")]
    familias <- data.table::rbindlist(list(familias, fam_novas), fill = TRUE)
    pessoas[novas, `:=`(censobr_idfamily = i.censobr_idfamily, censobr_familia_origem = "registro_perdido"), on = c("UF", "chave")]
  }

  # sem chefe nem conjuge: ficam na familia do registro de familia anterior, na ordem do arquivo
  registros <- familias[censobr_familia_origem == "registro", .(linha, censobr_idfamily)][order(linha)]
  ainda <- which(is.na(pessoas$censobr_idfamily))
  idx <- findInterval(pessoas$linha[ainda], registros$linha)
  pessoas[ainda, `:=`(censobr_idfamily = registros$censobr_idfamily[idx], censobr_familia_origem = "anexada_anterior")]

  # duas pessoas na posicao de chefe no mesmo questionario (id_arquivo 54150 e 137492)
  chefes <- pessoas[, .(n_chefes = sum(tipo == "2")), by = censobr_idfamily]
  familias[chefes, censobr_dois_chefes := i.n_chefes >= 2, on = "censobr_idfamily"]
  familias[is.na(censobr_dois_chefes), censobr_dois_chefes := FALSE]

  # o domicilio: 1, 2 e 3 abrem; 4 e 5 entram no da familia anterior
  data.table::setorder(familias, linha)
  familias[, convivente := V101 %in% c("4", "5")]
  familias[, anterior_permite := data.table::shift(V101) %in% c("2", "4", "5")]
  familias[, censobr_convivente_isolada := convivente & !anterior_permite]
  familias[, abre := !convivente | censobr_convivente_isolada]
  familias[, censobr_idhousehold := cumsum(abre)]
  familias[, c("convivente", "anterior_permite", "abre") := NULL]
  pessoas[familias, censobr_idhousehold := i.censobr_idhousehold, on = "censobr_idfamily"]

  message("  familias: ", nrow(familias), " (", sum(familias$censobr_familia_origem == "registro_perdido"),
          " sem registro); domicilios: ", data.table::uniqueN(familias$censobr_idhousehold),
          "; pessoas anexadas a familia anterior: ", sum(pessoas$censobr_familia_origem == "anexada_anterior"))

  list(familias = familias, pessoas = pessoas)
}


# ------------------------------------------------------------------------------
# Passo 8 — tabelas finais
#
# Domicílios. Uma linha por domicílio, com as características da página de
# domicílio da família principal (V101 a V113) e três contagens de nomes
# inequívocos, porque a versão de 2018 trocou os rótulos das suas duas:
#
#   censobr_n_listadas    todas as pessoas listadas no domicílio;
#   censobr_n_residentes  as que moram ali (exclui V202 = 5 ou 6, os
#                         presentes que não moram);
#   censobr_n_presentes   as que estavam presentes (exclui V202 = 3 ou 4,
#                         os moradores ausentes).
#
# Página de domicílio nas pessoas. Cada pessoa leva V101 a V113 do seu
# próprio registro de família, exatamente como no original. Nas famílias
# secundárias (V101 = 4 ou 5) essa página é toda em branco no arquivo — o
# recenseador só a preenchia no boletim da família principal — e fica em
# branco aqui também: preencher com a página da família principal seria
# inventar dado. Quem precisar dela junta as duas tabelas por
# censobr_idhousehold.
#
# Peso. A amostra de 1,27% foi sorteada com probabilidade igual para todos,
# então cada pessoa representa 1/0,0127 = 78,74 pessoas. É o peso que este
# estágio entrega; a calibração às populações oficiais por UF e situação, e
# a decisão sobre Rondônia (só Porto Velho urbano foi amostrado), são do
# estágio da compilação.
#
# Códigos. Filhos tidos e vivos (V217, V218) só têm códigos até 30, mais 99 =
# ignorado; os 28 registros com 31 a 98 viram NA, marcados. Idade: V204 diz
# se a idade está em meses (0), anos (1), acima de 99 anos (5) ou ignorada
# (9); o número em si, que a sintaxe original chamava AGE, fica em V204B.
#
# Imputações determinísticas. Duas, e só porque a dedução não tem
# alternativa: nacionalidade em branco em 19 registros íntegros de pessoas
# nascidas em unidades da federação brasileiras (V207 de 01 a 29) vira 9,
# brasileiro nato, marcada em censobr_v208_imputada; e as 3 pessoas das
# linhas corrompidas, que perderam UF, município e chave, recebem os da
# família a que estão presas pela posição no arquivo (censobr_diagnostico
# já as identifica). Nada mais é preenchido: a página de domicílio das
# famílias secundárias, por exemplo, fica em branco (ver abaixo).
#
# Coerência entre parentes. Três marcas, sem nenhuma correção — são dados
# originais, e o usuário decide: cônjuge do mesmo sexo do chefe; filho mais
# velho que o chefe; casamento antes dos 10 anos de idade (inclusive antes
# do nascimento).
#
# Desenho da amostra. Duas colunas dizem como a amostra foi sorteada, sem as
# quais qualquer erro-padrão sai subestimado: censobr_upa é a pasta, que é a
# unidade que o IBGE sorteou (uma em vinte), e censobr_estrato é a região
# cruzada com o tipo de situação da pasta — urbana, rural ou mista. São 817
# pastas em 12 estratos, o menor com 18 pastas. O quarto grupo do desenho
# original, cidades de 100 mil habitantes e mais, não entra: a população
# municipal não pode ser deduzida da própria amostra (o cálculo acusaria 216
# municípios acima de 100 mil, quando o Brasil de 1960 tinha cerca de trinta).
# Estratos mais grossos que os do IBGE superestimam levemente a variância, que
# é o lado seguro do erro; a fração de 1/20 da segunda etapa também não entra
# como correção de população finita, pelo mesmo motivo.
#
# Tipos. Todas as variáveis do IBGE viram inteiros; a chave do questionário e
# as marcas ficam como estão.
# ------------------------------------------------------------------------------
finalize_1960_amostra_127 <- function(tabelas, municipios_path){

  message("Finalizing 1960 amostra de 1,27%")

  familias <- data.table::copy(tabelas$familias)
  pessoas  <- data.table::copy(tabelas$pessoas)

  # filhos tidos e vivos acima de 30: o dicionario de 2018 parava em 30, mas o Codigo do Censo
  # (quesitos R e S) manda registrar o numero declarado; o valor fica e a marca aponta
  for(v in c("V217", "V218")){
    fora <- !is.na(pessoas[[v]]) & as.integer(pessoas[[v]]) >= 31 & as.integer(pessoas[[v]]) <= 98
    data.table::set(pessoas, j = paste0("censobr_", tolower(v), "_fora_da_faixa"), value = fora)
  }
  data.table::setnames(pessoas, "AGE", "V204B")

  # imputacoes deterministicas, sempre marcadas: quem nasceu no Brasil (V207 de 01 a 29)
  # e brasileiro nato (V208 = 9); a linha corrompida esta presa a uma familia e tem a localizacao dela
  pessoas[, censobr_v208_imputada := is.na(V208) & V207 %in% sprintf("%02d", 1:29) & censobr_diagnostico != "corrompida"]
  pessoas[censobr_v208_imputada == TRUE, V208 := "9"]
  corrompidas <- which(pessoas$censobr_diagnostico == "corrompida")
  local <- familias[pessoas[corrompidas], on = "censobr_idfamily", .(UF, V116, V118, distrito, pasta, boletim, chave)]
  for(v in names(local)) data.table::set(pessoas, i = corrompidas, j = v, value = local[[v]])

  # contagens por domicilio
  pessoas[, `:=`(censobr_n_listadas   = .N,
                 censobr_n_residentes = sum(!V202 %in% c("5", "6")),
                 censobr_n_presentes  = sum(!V202 %in% c("3", "4")),
                 censobr_n_familias   = data.table::uniqueN(censobr_idfamily)), by = censobr_idhousehold]

  # coerencia entre parentes, dentro da familia
  pessoas[, idade_anos := data.table::fifelse(V204 == "1", as.integer(V204B),
                          data.table::fifelse(V204 == "5", 100L + as.integer(V204B), NA_integer_))]
  pessoas[, `:=`(sexo_chefe  = V202[tipo == "2"][1],
                 idade_chefe = idade_anos[tipo == "2"][1]), by = censobr_idfamily]
  pessoas[, censobr_flag_conjuge_mesmo_sexo := V203 == "8" & !is.na(sexo_chefe) & !is.na(V202) &
            (V202 %in% c("1", "3", "5")) == (sexo_chefe %in% c("1", "3", "5"))]
  pessoas[, censobr_flag_filho_mais_velho := V203 == "9" & !is.na(idade_anos) & !is.na(idade_chefe) & idade_anos > idade_chefe]
  # quesito Q do Codigo do Censo: 01-60 = 1901-1960, 61 = 1900, 62 = antes de 1864 (fica 1863), 63 = ignorado, 64-99 = 1864-1899
  pessoas[, ano_casamento := data.table::fifelse(as.integer(V216) %in% 1:60, 1900L + as.integer(V216),
                             data.table::fifelse(as.integer(V216) %in% 61, 1900L,
                             data.table::fifelse(as.integer(V216) %in% 62, 1863L,
                             data.table::fifelse(as.integer(V216) %in% 64:99, 1800L + as.integer(V216), NA_integer_))))]
  pessoas[, censobr_flag_casamento_impossivel := !is.na(ano_casamento) & !is.na(idade_anos) & (ano_casamento - (1960L - idade_anos)) < 10]
  pessoas[, c("idade_anos", "sexo_chefe", "idade_chefe", "ano_casamento") := NULL]
  for(v in grep("^censobr_flag_", names(pessoas), value = TRUE)) data.table::set(pessoas, i = which(is.na(pessoas[[v]])), j = v, value = FALSE)

  pessoas[, censobr_weight := 1 / 0.0127]

  # a tabela de domicilios: a pagina de domicilio da familia principal
  principal <- familias[!(V101 %in% c("4", "5")) | censobr_convivente_isolada == TRUE][order(linha)]
  principal <- principal[, .SD[1], by = censobr_idhousehold]
  domicilios <- principal[, .(censobr_idhousehold, linha, id_arquivo, UF, V116, V118, distrito, pasta, boletim, chave,
                              V101, V102, V103, V104, V105, V106, V107, V108, V109, V110, V111, V112, V113,
                              censobr_diagnostico, censobr_variaveis_anuladas, censobr_familia_origem,
                              censobr_uf_corrigida, censobr_convivente_isolada, censobr_dois_chefes)]
  contagens <- pessoas[, .SD[1], by = censobr_idhousehold,
                       .SDcols = c("censobr_n_listadas", "censobr_n_residentes", "censobr_n_presentes", "censobr_n_familias")]
  domicilios[contagens, `:=`(censobr_n_listadas = i.censobr_n_listadas, censobr_n_residentes = i.censobr_n_residentes,
                             censobr_n_presentes = i.censobr_n_presentes, censobr_n_familias = i.censobr_n_familias),
             on = "censobr_idhousehold"]
  domicilios[, censobr_weight := 1 / 0.0127]

  # a pessoa leva a pagina de domicilio do seu proprio registro de familia, como no original
  pessoas[familias, `:=`(V101 = i.V101, V102 = i.V102, V103 = i.V103, V104 = i.V104, V105 = i.V105, V106 = i.V106,
                         V107 = i.V107, V108 = i.V108, V109 = i.V109, V110 = i.V110, V111 = i.V111, V112 = i.V112, V113 = i.V113),
          on = "censobr_idfamily"]

  # tipos: variaveis do IBGE e o numero a posteriori viram inteiros
  para_inteiro <- function(dt) for(v in grep("^(UF|id_arquivo|V[0-9]{3}B?)$", names(dt), value = TRUE)) data.table::set(dt, j = v, value = as.integer(dt[[v]]))
  para_inteiro(pessoas); para_inteiro(domicilios)
  data.table::setnames(pessoas, "tipo", "censobr_tipo_registro")

  # o municipio: V116 e o codigo da divisao territorial de 1960, com tres excecoes -- a Guanabara vem
  # codificada por distrito (54xx) e e um municipio so (541); Alagoas vem deslocada em 200; Fernando
  # de Noronha vem 2701 e e o unico municipio do territorio (2401)
  # code_muni_1960 e o codigo da epoca; code_muni e o atual, pelo crosswalk 1960 -> 2010 da mesma tabela
  municipios <- data.table::fread(municipios_path, encoding = "UTF-8")
  domicilios[, code_muni_1960 := data.table::fifelse(UF == 54L, 541L, data.table::fifelse(UF == 25L, V116 - 200L,
                                 data.table::fifelse(UF == 24L, 2401L, V116)))]
  domicilios[, censobr_muni_corrigido := UF %in% c(54L, 25L, 24L)]
  domicilios[municipios, code_muni := as.integer(i.code_muni_2010), on = c(UF = "uf60", code_muni_1960 = "cod60")]

  # codigo sem par na divisao territorial, numa pasta cujas demais familias sao todas de um so municipio:
  # e erro de perfuracao (7234 por 6234 em Sao Paulo, 724Z por 7240 no Parana) e o municipio da pasta o corrige
  domicilios[, muni_pasta := if(data.table::uniqueN(code_muni_1960[!is.na(code_muni)]) == 1) code_muni_1960[!is.na(code_muni)][1] else NA_integer_, by = .(UF, pasta)]
  domicilios[is.na(code_muni) & !is.na(muni_pasta), `:=`(code_muni_1960 = muni_pasta, censobr_muni_corrigido = TRUE)]
  domicilios[municipios, `:=`(code_muni = as.integer(i.code_muni_2010), pop_urbana_muni = i.pop_urbana), on = c(UF = "uf60", code_muni_1960 = "cod60")]
  domicilios[, muni_pasta := NULL]

  # o desenho da amostra: a pasta e a unidade sorteada; o estrato e a regiao cruzada com um dos quatro
  # grupos de situacao de 1965 -- cidade de 100 mil ou mais, aglomerado urbano menor, rural, mista
  domicilios[, censobr_upa := paste0(UF, "-", pasta)]
  pastas <- domicilios[, .(urbanos = sum(V118 %in% c(1, 3)), rurais = sum(V118 %in% 5),
                           grande = any(pop_urbana_muni >= 1e5, na.rm = TRUE)), by = censobr_upa]
  pastas[, grupo := data.table::fifelse(urbanos > 0 & rurais > 0, "mista", data.table::fifelse(urbanos == 0, "rural",
                    data.table::fifelse(grande, "cidade grande", "urbana menor")))]
  domicilios[pastas, censobr_estrato := paste(REGIAO_1960[as.character(UF)], i.grupo, sep = " - "), on = "censobr_upa"]
  pessoas[domicilios, `:=`(censobr_upa = i.censobr_upa, censobr_estrato = i.censobr_estrato,
                           code_muni = i.code_muni, code_muni_1960 = i.code_muni_1960, censobr_muni_corrigido = i.censobr_muni_corrigido), on = "censobr_idhousehold"]
  domicilios[, pop_urbana_muni := NULL]
  message("  desenho: ", data.table::uniqueN(domicilios$censobr_upa), " pastas (",
          paste(names(table(pastas$grupo)), table(pastas$grupo), collapse = ", "), ") em ",
          data.table::uniqueN(domicilios$censobr_estrato), " estratos; menor estrato com ",
          min(unique(domicilios[, .(censobr_estrato, censobr_upa)])[, .N, by = censobr_estrato]$N), " pastas")

  data.table::setcolorder(pessoas, c("UF", "V116", "V118", "code_muni", "code_muni_1960", "censobr_muni_corrigido", "censobr_idhousehold", "censobr_idfamily", "linha", "censobr_weight", "censobr_upa", "censobr_estrato"))
  data.table::setcolorder(domicilios, c("UF", "V116", "V118", "code_muni", "code_muni_1960", "censobr_muni_corrigido", "censobr_idhousehold", "linha", "censobr_weight", "censobr_upa", "censobr_estrato"))

  message("  pessoas: ", nrow(pessoas), " x ", ncol(pessoas), " | domicilios: ", nrow(domicilios), " x ", ncol(domicilios))
  list(pessoas = pessoas, domicilios = domicilios)
}


# ------------------------------------------------------------------------------
# Passo 9 — pesos calibrados aos Resultados Preliminares de 1965
#
# O gabarito. Em março de 1965 o IBGE publicou, com estes mesmos cartões,
# antes do dano da fita, os "Resultados Preliminares do Censo Demográfico",
# Série Especial, vol. II (biblioteca do IBGE, liv84480). O quadro 1 dá a
# população presente por região (Nordeste, Leste, Sul e o Brasil, de onde
# sai Norte + Centro-Oeste por diferença), situação (urbana = quadros urbano
# e suburbano, V118 = 1 ou 3; rural, V118 = 5), sexo e onze faixas de idade.
# São 176 números, transcritos e conferidos por aritmética em
# references/censo_1960_resultados_preliminares_1965.csv.
#
# O desenho. A amostra é de pastas (lotes de ~250 questionários), uma em
# vinte, estratificadas por geografia e situação — o arquivo tem as 814
# pastas sorteadas. O fator de expansão implícito nas tabelas de 1965 é
# 79 a 80, quase uniforme, com o urbano um pouco acima do rural.
#
# A calibração. Cada domicílio recebe um peso único, o mesmo para todas as
# suas pessoas, tal que as somas ponderadas reproduzem exatamente as 176
# células do quadro 1 e as 8 do quadro 2 que contam quem sabe ler e
# escrever, por sexo e região. É a calibração de Deville e Särndal com a distância
# "raking": o peso é o peso de desenho (78,74 = 1/0,0127) vezes um fator
# exp(x'λ), onde x conta quantas pessoas presentes o domicílio tem em cada
# célula, e λ é resolvido por Newton. O fator fica perto de 1 quando o
# arquivo está íntegro e afasta-se onde faltam ou sobram cartões — por isso
# ele também é um diagnóstico, gravado em censobr_weight_fator.
#
# A reprodução dos sete quadros, inclusive o 6, é o passo 10.
#
# O que não entra. O estado conjugal por sexo (quadro 5) foi testado e
# rejeitado: leva o fator de alguns domicílios a 18 vezes o de desenho,
# porque força os que perderam o cartão do chefe a compensar com peso o que
# falta no arquivo. Os quadros 6 e 7 (domicílios e residentes) implicam um
# fator 1,6% a 3,9% menor que o das pessoas presentes, diferença ainda sem
# explicação. Todos servem de validação (passo 10), não de restrição. Rondônia, Amapá,
# Acre, Fernando de Noronha e o Distrito Federal têm cobertura parcial e
# nenhum peso cria o que não foi amostrado: a calibração só reproduz os
# totais regionais publicados.
# ------------------------------------------------------------------------------
calibrate_1960_amostra_127 <- function(tabelas, gabarito_path){

  message("Calibrating household weights to the 1965 preliminary results (quadro 1)")

  pessoas    <- data.table::copy(tabelas$pessoas)
  domicilios <- data.table::copy(tabelas$domicilios)
  gab <- data.table::fread(gabarito_path, encoding = "UTF-8")

  # as celulas do quadro 1: regiao x situacao x sexo x faixa de idade
  regiao_uf <- REGIAO_1960
  faixas <- c("0 a 4", "5 a 9", "10 a 14", "15 a 19", "20 a 24", "25 a 29", "30 a 39", "40 a 49", "50 a 59", "60 a 69", "70 e mais e ignorada")
  pessoas[, regiao   := regiao_uf[as.character(UF)]]
  pessoas[, situacao := data.table::fifelse(V118 %in% c(1, 3), "urbana", data.table::fifelse(V118 %in% 5, "rural", NA_character_))]
  pessoas[, sexo     := data.table::fifelse(V202 %in% c(1, 3, 5), "homens", data.table::fifelse(V202 %in% c(2, 4, 6), "mulheres", NA_character_))]
  pessoas[, idade    := data.table::fifelse(V204 %in% 1, V204B, data.table::fifelse(V204 %in% 0, 0L, 999L))]   # meses -> 0; 100+, ignorada, NA -> ultima faixa
  pessoas[is.na(idade), idade := 999L]
  pessoas[, faixa    := faixas[findInterval(idade, c(0, 5, 10, 15, 20, 25, 30, 40, 50, 60, 70))]]
  pessoas[, presente := !(V202 %in% c(3, 4))]
  pessoas[, celula   := paste("q1", regiao, situacao, sexo, faixa, sep = "|")]

  g1 <- gab[quadro == 1 & regiao != "Brasil" & linha != "TOTAIS" & coluna %in% c("urbana_homens", "urbana_mulheres", "rural_homens", "rural_mulheres")]
  g1[, celula := paste("q1", regiao, sub("_.*", "", coluna), sub(".*_", "", coluna), linha, sep = "|")]

  # quadro 2: quem sabe ler e escrever, por sexo, entre as pessoas presentes de 5 anos e mais (V211 0 e 1); so "sabem"
  # entra como restricao -- "nao sabem" ja fica determinado pelo quadro 1 menos "sabem" menos os sem declaracao
  g2 <- gab[quadro == 2 & regiao != "Brasil" & linha == "5 e mais" & coluna %in% c("sabem_homens", "sabem_mulheres")]
  g2[, celula := paste("q2", regiao, sub("_[a-z]+$", "", coluna), sub(".*_", "", coluna), sep = "|")]
  pessoas[, alfabetizacao := data.table::fifelse(V211 %in% c(0, 1), "sabem", data.table::fifelse(V211 %in% c(2, 3), "nao_sabem", NA_character_))]
  pessoas[, celula_q2 := data.table::fifelse(presente & idade >= 5 & alfabetizacao %in% "sabem" & !is.na(sexo), paste("q2", regiao, alfabetizacao, sexo, sep = "|"), NA_character_)]

  celulas <- c(g1$celula, g2$celula); totais <- c(g1$valor, g2$valor)

  # X: uma linha por domicilio, uma coluna por celula, com o numero de pessoas do domicilio em cada celula
  cont <- rbind(pessoas[presente == TRUE & !is.na(situacao) & !is.na(sexo), .N, by = .(censobr_idhousehold, celula)],
                pessoas[!is.na(celula_q2), .N, by = .(censobr_idhousehold, celula = celula_q2)])
  hh <- sort(unique(domicilios$censobr_idhousehold))
  X <- Matrix::sparseMatrix(i = match(cont$censobr_idhousehold, hh), j = match(cont$celula, celulas), x = cont$N,
                            dims = c(length(hh), length(celulas)))
  amostra <- as.numeric(Matrix::colSums(X))
  message("  celulas: ", length(celulas), " (quadro 1: ", nrow(g1), "; quadro 2: ", nrow(g2), "); sem pessoa na amostra: ", sum(amostra == 0),
          "; fator implicito (publicado / amostra x 78,74): min ", round(min(totais / amostra / 78.74), 3), " max ", round(max(totais / amostra / 78.74), 3))

  # raking de Deville-Sarndal: g = exp(X lambda), resolvido por Newton
  d <- rep(1 / 0.0127, length(hh)); lambda <- rep(0, length(celulas))
  for(it in 1:100){
    w <- d * as.numeric(exp(X %*% lambda))
    F <- as.numeric(Matrix::crossprod(X, w)) - totais
    if(max(abs(F) / totais) < 1e-10) break
    J <- as.matrix(Matrix::crossprod(X, Matrix::Diagonal(x = w) %*% X))
    lambda <- lambda - solve(J, F)
  }
  message("  Newton: ", it, " iteracoes; desvio maximo ", signif(max(abs(F) / totais), 3),
          "; fator g: min ", round(min(w / d), 3), " mediana ", round(median(w / d), 3), " max ", round(max(w / d), 3))

  pesos <- data.table::data.table(censobr_idhousehold = hh, censobr_weight = w, censobr_weight_fator = w / d)
  domicilios[pesos, `:=`(censobr_weight = i.censobr_weight, censobr_weight_fator = i.censobr_weight_fator), on = "censobr_idhousehold"]
  pessoas[pesos,    `:=`(censobr_weight = i.censobr_weight, censobr_weight_fator = i.censobr_weight_fator), on = "censobr_idhousehold"]
  domicilios[, censobr_weight_desenho := 1 / 0.0127]
  pessoas[,    censobr_weight_desenho := 1 / 0.0127]

  pessoas[, c("regiao", "situacao", "sexo", "idade", "faixa", "presente", "celula", "alfabetizacao", "celula_q2") := NULL]
  list(pessoas = pessoas, domicilios = domicilios)
}


# ------------------------------------------------------------------------------
# Passo 10 — reprodução dos sete quadros de 1965 (validação)
#
# Com os pesos calibrados, recompõe cada célula dos quadros 2, 3, 4, 5 e 7
# a partir das variáveis do arquivo e a compara com o valor publicado. Os
# quadros 1, 2 (alfabetização por sexo) e 5 (estado conjugal por sexo) são
# restrições da calibração e fecham por construção; o resto mede duas
# coisas ao mesmo tempo: se a leitura dos códigos está certa (V211, V215,
# V219, V223B, V105 a V110, pelo Boletim de Amostra CD 2) e se o universo
# tabulado em 1965 é o mesmo do arquivo. Sai em
# data_raw/microdata/1960/amostra_127/calibracao_1965_validacao.csv, uma
# linha por célula com o publicado, o nosso e a diferença relativa.
#
# O que se sabe das diferenças que restam: no quadro 5 as colunas de
# atividade classificam os inativos pela "atividade de que dependem" (a da
# pessoa que os sustenta), informação que o arquivo não tem — só os totais
# por estado conjugal comparam; nos quadros 6 e 7 os domicílios e residentes
# publicados são 1,6% a 3,9% menores que os do arquivo, uniformemente por
# item, o que aponta um universo menor na tabulação de 1965 e não erro de
# leitura; no quadro 3 os ramos seguem o Código do Censo de 1960
# (read_guides/1960_codigo_do_censo.csv, quesito X), e os desempregados e os
# de ocupação ignorada na última semana (quesito W = 4 e 5) contam em "outras
# atividades" — com isso sete ramos ficam entre -0,4% e +0,7% e as "outras"
# em -1,7%; sem isso as "outras" ficam 6% abaixo e os demais ramos todos
# acima. A construção civil (classe 351) continua 6% abaixo do publicado e
# não há regra do Código que a complete: energia e água (391, 392), pedras e
# materiais de construção (252) e conservação de habitações (514) foram
# testados e desajustam outras linhas mais do que consertam esta.
# ------------------------------------------------------------------------------
validate_1965_1960_amostra_127 <- function(tabelas, gabarito_path){

  message("Comparing the seven 1965 tables with the calibrated file")

  p <- data.table::copy(tabelas$pessoas); d <- data.table::copy(tabelas$domicilios)
  gab <- data.table::fread(gabarito_path, encoding = "UTF-8")[regiao != "Brasil"]
  regiao_uf <- REGIAO_1960
  p[, regiao := regiao_uf[as.character(UF)]]
  p[, presente := !(V202 %in% 3:4)]; p[, residente := !(V202 %in% 5:6)]; p[, sexo := data.table::fifelse(V202 %in% c(1, 3, 5), "homens", "mulheres")]
  p[, idade := data.table::fifelse(V204 %in% 1, V204B, data.table::fifelse(V204 %in% 0, 0L, 999L))]; p[is.na(idade), idade := 999L]
  p[, w := censobr_weight]

  # quadro 1: presentes por situacao, sexo e faixa etaria
  faixa1 <- c("0 a 4", "5 a 9", "10 a 14", "15 a 19", "20 a 24", "25 a 29", "30 a 39", "40 a 49", "50 a 59", "60 a 69", "70 e mais e ignorada")
  q1 <- p[presente == TRUE]; q1[, linha := faixa1[findInterval(idade, c(0, 5, 10, 15, 20, 25, 30, 40, 50, 60, 70))]]
  q1[, situacao := data.table::fifelse(V118 %in% c(1, 3), "urbana", "rural")]
  n1 <- rbind(q1[, .(nosso = sum(w)), by = .(regiao, linha)][, coluna := "total"], q1[, .(nosso = sum(w)), by = .(regiao, linha, coluna = sexo)],
              q1[, .(nosso = sum(w)), by = .(regiao, linha, coluna = situacao)], q1[, .(nosso = sum(w)), by = .(regiao, linha, coluna = paste0(situacao, "_", sexo))])
  n1 <- rbind(n1, n1[, .(nosso = sum(nosso)), by = .(regiao, coluna)][, linha := "TOTAIS"])[, quadro := 1L]

  # quadro 2: alfabetizacao, presentes de 5 anos e mais
  q2 <- p[presente == TRUE & idade >= 5]
  q2[, faixa := c("5 a 6", "7 a 12", "13 a 19", "20 a 24", "25 a 29", "30 a 39", "40 a 49", "50 a 59", "60 e mais e ignorada")[findInterval(idade, c(5, 7, 13, 20, 25, 30, 40, 50, 60))]]
  q2[, alf := data.table::fifelse(V211 %in% c(0, 1), "sabem", data.table::fifelse(V211 %in% c(2, 3), "nao_sabem", "sem_declaracao"))]
  q2 <- rbind(q2[, .(regiao, linha = faixa, sexo, alf, w)], q2[, .(regiao, linha = "5 e mais", sexo, alf, w)],
              q2[idade >= 10, .(regiao, linha = "10 e mais", sexo, alf, w)], q2[idade >= 15, .(regiao, linha = "15 e mais", sexo, alf, w)])
  n2 <- rbind(q2[, .(nosso = sum(w)), by = .(regiao, linha)][, coluna := "total"], q2[, .(nosso = sum(w)), by = .(regiao, linha, coluna = sexo)],
              q2[alf != "sem_declaracao", .(nosso = sum(w)), by = .(regiao, linha, coluna = alf)],
              q2[alf != "sem_declaracao", .(nosso = sum(w)), by = .(regiao, linha, coluna = paste0(alf, "_", sexo))])[, quadro := 2L]

  # quadros 3 e 4: ramo (V223B) e rendimento (V219), presentes de 10 anos e mais
  q3 <- p[presente == TRUE & idade >= 10]
  q3[, ramo := data.table::fifelse(is.na(V223B), "condicoes_inativas", data.table::fifelse(V223 %in% 4:5, "outras_atividades", data.table::fifelse(V223B < 200, "agricultura_pecuaria_silvicultura",
              data.table::fifelse(V223B < 300, "industrias_extrativas", data.table::fifelse(V223B <= 339, "industrias_transformacao",
              data.table::fifelse(V223B == 351, "industrias_construcao", data.table::fifelse(V223B %in% 411:429, "comercio_mercadorias",
              data.table::fifelse(V223B %in% 611:629, "transportes_comunicacoes_armazenagem", data.table::fifelse(V223B %in% 511:519, "prestacao_servicos", "outras_atividades")))))))))]
  q3[, grupo := data.table::fifelse(is.na(V223B), "inativas", data.table::fifelse(V223B < 300, "agro", data.table::fifelse(V223B < 400, "ind", "outras")))]
  q3[, renda := c("10001_20000", "20001_mais", "20001_mais", "sem_rendimento", "sem_declaracao", "ate_2100", "2101_3300", "3301_4500", "4501_6000", "6001_10000")[match(V219, 0:9)]]
  q3[is.na(renda), renda := "sem_declaracao"]
  n3 <- rbind(q3[, .(nosso = sum(w)), by = .(regiao, linha = ramo)][, coluna := "total"], q3[, .(nosso = sum(w)), by = .(regiao, linha = ramo, coluna = sexo)],
              q3[, .(nosso = sum(w)), by = regiao][, `:=`(linha = "TOTAIS", coluna = "total")], q3[, .(nosso = sum(w)), by = .(regiao, coluna = sexo)][, linha := "TOTAIS"])[, quadro := 3L]
  n4 <- rbind(q3[, .(nosso = sum(w)), by = .(regiao, linha = renda)][, coluna := "total"], q3[, .(nosso = sum(w)), by = .(regiao, linha = renda, coluna = paste0(grupo, "_", sexo))],
              q3[, .(nosso = sum(w)), by = regiao][, `:=`(linha = "TOTAIS", coluna = "total")], q3[, .(nosso = sum(w)), by = .(regiao, coluna = paste0(grupo, "_", sexo))][, linha := "TOTAIS"])[, quadro := 4L]

  # quadro 5: estado conjugal (V215), residentes de 15 anos e mais; so os totais por linha sao comparaveis
  q5 <- p[residente == TRUE & idade >= 15]
  q5[, linha := c("solteiros", "separados", "outros", "outros", "viuvos", "outros", "casados_civil_religioso", "casados_somente_civil", "casados_somente_religioso", "casados_sem_vinculo")[match(V215, 0:9)]]
  q5[is.na(linha), linha := "outros"]
  q5 <- rbind(q5[, .(regiao, linha, w)], q5[grepl("^casados", linha), .(regiao, linha = "casados", w)], q5[, .(regiao, linha = "TOTAIS", w)])
  n5 <- q5[, .(nosso = sum(w)), by = .(regiao, linha)][, `:=`(coluna = "total", quadro = 5L)]

  # quadros 6 e 7: domicilios particulares ocupados e residentes
  d[, regiao := regiao_uf[as.character(UF)]]; d[, situacao := data.table::fifelse(V118 %in% c(1, 3), "urbana", "rural")]
  dp <- d[!(V101 %in% 3)]
  res <- p[residente == TRUE, .(res = sum(w)), by = censobr_idhousehold]; dp[res, res := i.res, on = "censobr_idhousehold"]; dp[is.na(res), res := 0]
  itens <- list(TOTAIS = quote(TRUE), proprios = quote(V103 %in% 7), alugados = quote(V103 %in% 8), outra_condicao = quote(V103 %in% 9),
                agua_rede_geral = quote(V105 %in% c(9, 0)), agua_poco_nascente = quote(V105 %in% c(1, 2)), agua_outra_sem_declaracao = quote(V105 %in% 3 | is.na(V105)),
                fogao_lenha = quote(V107 %in% 9), fogao_carvao = quote(V107 %in% 0), fogao_gas = quote(V107 %in% 2), fogao_oleo_querosene = quote(V107 %in% 3),
                instalacao_sanitaria = quote(V106 %in% 4:7), iluminacao_eletrica = quote(V108 %in% 5), radio = quote(V109 %in% 7), geladeira = quote(V110 %in% 9))
  n67 <- data.table::rbindlist(lapply(names(itens), function(nm){ z <- dp[eval(itens[[nm]])]
    rbind(z[, .(linha = nm, coluna = "dom_total", nosso = sum(censobr_weight)), by = regiao], z[, .(linha = nm, coluna = "pes_total", nosso = sum(res)), by = regiao],
          z[, .(linha = nm, coluna = paste0("dom_", situacao), nosso = sum(censobr_weight)), by = .(regiao, situacao)][, -"situacao"],
          z[, .(linha = nm, coluna = paste0("pes_", situacao), nosso = sum(res)), by = .(regiao, situacao)][, -"situacao"]) }))
  n67[, quadro := data.table::fifelse(linha %in% c("proprios", "alugados", "outra_condicao"), 6L, 7L)]
  n6t <- n67[linha == "TOTAIS"][, quadro := 6L]

  nosso <- rbind(n1, n2, n3, n4, n5, n67, n6t)
  comp <- merge(gab[, .(quadro, regiao, linha, coluna, publicado = valor)], nosso[, .(quadro, regiao, linha, coluna, nosso = round(nosso))], by = c("quadro", "regiao", "linha", "coluna"))
  comp[, dif_pct := round(100 * (nosso / publicado - 1), 2)]
  data.table::setorder(comp, quadro, regiao, linha, coluna)
  data.table::fwrite(comp, "./data_raw/microdata/1960/amostra_127/calibracao_1965_validacao.csv", bom = TRUE)
  resumo <- comp[, .(celulas = .N, dif_mediana_abs = round(median(abs(dif_pct)), 2), dif_max_abs = round(max(abs(dif_pct)), 1)), by = quadro]
  message(paste(capture.output(print(resumo)), collapse = "\n"))
  comp
}


# ------------------------------------------------------------------------------
# Passo 11 — erros amostrais
#
# O que faltava. O Volume II de 1965 promete "uma publicação especial em que
# se fará descrição detalhada do desenho da amostra e das técnicas
# utilizadas", com os erros de amostragem; ela não está na biblioteca do
# IBGE, nem no Internet Archive, nem é citada no volume definitivo. Este
# passo calcula o que ela teria dado.
#
# Como se calcula. A amostra é de conglomerados: sorteou-se uma pasta em
# vinte, e a pasta traz ~220 domicílios inteiros, todos parecidos entre si
# porque são vizinhos. Tratar a amostra como se fosse aleatória simples
# subestima a variância, às vezes muito. O estimador correto soma, dentro de
# cada estrato, a dispersão dos totais entre as pastas daquele estrato:
#
#   V = soma_h  n_h/(n_h-1) * soma_i (t_hi - média dos t_h)^2
#
# onde t_hi é o total estimado dentro da pasta i do estrato h. É o estimador
# de conglomerado último, com reposição — o mesmo de survey::svydesign(ids =
# ~censobr_upa, strata = ~censobr_estrato, weights = ~censobr_weight), aqui
# escrito à mão para não acrescentar dependência ao pipeline.
#
# O efeito de desenho (deff) é essa variância dividida pela de uma amostra
# aleatória simples de pessoas do mesmo tamanho, N²(1-f)P(1-P)/(n-1); diz
# quantas vezes a amostra é menos precisa do que seria se cada pessoa tivesse
# sido sorteada isoladamente. Para o total do país ele não existe, porque uma
# amostra de tamanho fixo estima esse total sem erro por construção.
# ------------------------------------------------------------------------------
sampling_errors_1960_amostra_127 <- function(tabelas){

  message("Estimating sampling errors for the 1960 amostra de 1,27%")

  p <- data.table::copy(tabelas$pessoas)
  p[, regiao := REGIAO_1960[as.character(UF)]]
  p[, situacao := data.table::fifelse(V118 %in% c(1, 3), "urbana", data.table::fifelse(V118 %in% 5, "rural", NA_character_))]
  p[, sexo := data.table::fifelse(V202 %in% c(1, 3, 5), "homens", "mulheres")]
  p[, idade := data.table::fifelse(V204 %in% 1, V204B, data.table::fifelse(V204 %in% 0, 0L, 999L))]; p[is.na(idade), idade := 999L]
  p[, faixa := c("0 a 4", "5 a 9", "10 a 14", "15 a 19", "20 a 24", "25 a 29", "30 a 39", "40 a 49", "50 a 59", "60 a 69", "70 e mais e ignorada")[findInterval(idade, c(0, 5, 10, 15, 20, 25, 30, 40, 50, 60, 70))]]
  p <- p[!(V202 %in% c(3, 4)) & !is.na(V202) & !is.na(regiao) & !is.na(situacao)]

  # a pasta que nao tem ninguem do dominio entra na conta com total zero: e por isso
  # que o numero de pastas do estrato vem da amostra toda, e nao do dominio
  pastas_estrato <- unique(p[, .(censobr_estrato, censobr_upa)])[, .(n = .N), by = censobr_estrato]
  n_amostra <- nrow(p); n_populacao <- sum(p$censobr_weight)

  erro_padrao <- function(por){
    pasta <- p[, .(t = sum(censobr_weight)), by = c(por, "censobr_estrato", "censobr_upa")]
    estr  <- pasta[, .(soma = sum(t), soma2 = sum(t^2)), by = c(por, "censobr_estrato")]
    estr[pastas_estrato, n := i.n, on = "censobr_estrato"]
    estr[, v := n / (n - 1) * (soma2 - soma^2 / n)]
    out <- estr[, .(estimativa = sum(soma), variancia = sum(v)), by = por]
    out[p[, .(pessoas = .N), by = por], pessoas := i.pessoas, on = por]

    # referencia: amostra aleatoria simples de pessoas do mesmo tamanho, N^2 (1-f) P(1-P)/(n-1)
    out[, parte := estimativa / n_populacao]
    out[, v_srs := n_populacao^2 * (1 - n_amostra / n_populacao) * parte * (1 - parte) / (n_amostra - 1)]
    out[, `:=`(erro_padrao = sqrt(variancia), cv_pct = round(100 * sqrt(variancia) / estimativa, 2),
               deff = data.table::fifelse(parte < 1, round(variancia / v_srs, 1), NA_real_))]
    out[, .SD, .SDcols = c(por, "estimativa", "erro_padrao", "cv_pct", "deff", "pessoas")]
  }

  celulas <- erro_padrao(c("regiao", "situacao", "sexo", "faixa"))
  totais  <- rbind(erro_padrao(c("regiao", "situacao"))[, `:=`(sexo = "ambos", faixa = "todas")],
                   erro_padrao("regiao")[, `:=`(situacao = "ambas", sexo = "ambos", faixa = "todas")],
                   erro_padrao("situacao")[, `:=`(regiao = "Brasil", sexo = "ambos", faixa = "todas")],
                   fill = TRUE)
  brasil <- p[, .(regiao = "Brasil", situacao = "ambas", sexo = "ambos", faixa = "todas", estimativa = sum(censobr_weight))]
  res <- rbind(brasil, totais, celulas, fill = TRUE)[, .(regiao, situacao, sexo, faixa, estimativa = round(estimativa),
                                                         erro_padrao = round(erro_padrao), cv_pct, deff, pessoas)]
  data.table::fwrite(res, "./data_raw/microdata/1960/amostra_127/erros_amostrais.csv", bom = TRUE)

  message("  ", nrow(res), " dominios; nas 176 celulas do quadro 1 o coeficiente de variacao tem mediana ",
          round(median(celulas$cv_pct), 2), "% e maximo ", round(max(celulas$cv_pct), 1),
          "%; efeito de desenho mediano ", round(median(celulas$deff, na.rm = TRUE), 1))
  res
}


# Grava as duas tabelas intermediarias.
save_1960_amostra_127 <- function(tabelas){

  out_dir <- "./data_raw/microdata/1960/amostra_127"
  paths <- c(file.path(out_dir, "pessoas_1960_amostra_127.parquet"),
             file.path(out_dir, "domicilios_1960_amostra_127.parquet"))
  write_censobr_parquet(tabelas$pessoas,    paths[1])
  write_censobr_parquet(tabelas$domicilios, paths[2])
  paths
}
