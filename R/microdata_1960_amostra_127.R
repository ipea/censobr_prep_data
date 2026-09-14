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
# A solução. Uma linha é considerada cópia quando repete, dentro da mesma
# família (mesmo id_arquivo), todas as variáveis de uma linha anterior. A
# cópia é removida em dois casos, que juntos cobrem as cópias de Pernambuco e
# poupam coincidências legítimas noutros lugares:
#
#   - quando a pessoa repetida é chefe ou cônjuge (nenhuma família tem dois
#     chefes ou dois cônjuges idênticos);
#   - quando a família tem duas ou mais linhas repetidas (uma cópia em bloco).
#
# Uma única linha repetida de filho ou outro parente, numa família sem outra
# repetição, pode ser gêmeos com o mesmo perfil: fica no banco, marcada em
# censobr_duplicata_mantida. As linhas removidas ficam registradas em
# data_raw/microdata/1960/amostra_127/duplicatas_removidas.csv.
# ------------------------------------------------------------------------------
dedup_1960_amostra_127 <- function(tabelas){

  message("Removing duplicated person lines (Pernambuco) in 1960 amostra de 1,27%")

  pessoas <- data.table::copy(tabelas$pessoas)

  # as variaveis que descrevem a pessoa: tudo menos linha, id e diagnostico
  vars <- setdiff(names(pessoas), c("linha", "id_arquivo", "censobr_diagnostico", "censobr_variaveis_anuladas"))
  pessoas[, conteudo := do.call(paste, c(.SD, sep = "|")), .SDcols = vars]

  pessoas[, repetida := duplicated(conteudo), by = id_arquivo]
  pessoas[, n_repetidas_familia := sum(repetida), by = id_arquivo]
  pessoas[, remover := repetida & (V203 %in% c("7", "8") | n_repetidas_familia >= 2)]

  pessoas[, censobr_duplicata_mantida := repetida & !remover]

  removidas <- pessoas[remover == TRUE, .(linha, id_arquivo, UF, V116, tipo, V203, AGE, V202)]
  data.table::fwrite(removidas, "./data_raw/microdata/1960/amostra_127/duplicatas_removidas.csv", bom = TRUE)

  message("  linhas repetidas: ", sum(pessoas$repetida), "; removidas: ", nrow(removidas),
          " (Pernambuco: ", sum(removidas$UF == "21"), "); mantidas com marca: ", sum(pessoas$censobr_duplicata_mantida))

  pessoas <- pessoas[remover == FALSE]
  pessoas[, c("conteudo", "repetida", "n_repetidas_familia", "remover") := NULL]

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
# Coerência entre parentes. Três marcas, sem nenhuma correção — são dados
# originais, e o usuário decide: cônjuge do mesmo sexo do chefe; filho mais
# velho que o chefe; casamento antes dos 10 anos de idade (inclusive antes
# do nascimento).
#
# Tipos. Todas as variáveis do IBGE viram inteiros; a chave do questionário e
# as marcas ficam como estão.
# ------------------------------------------------------------------------------
finalize_1960_amostra_127 <- function(tabelas){

  message("Finalizing 1960 amostra de 1,27%")

  familias <- data.table::copy(tabelas$familias)
  pessoas  <- data.table::copy(tabelas$pessoas)

  # filhos tidos e vivos fora da faixa do dicionario
  for(v in c("V217", "V218")){
    fora <- !is.na(pessoas[[v]]) & as.integer(pessoas[[v]]) >= 31 & as.integer(pessoas[[v]]) <= 98
    data.table::set(pessoas, j = paste0("censobr_", tolower(v), "_fora_da_faixa"), value = fora)
    data.table::set(pessoas, i = which(fora), j = v, value = NA_character_)
  }
  data.table::setnames(pessoas, "AGE", "V204B")

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
  pessoas[, ano_casamento := data.table::fifelse(as.integer(V216) %in% 1:60, 1900L + as.integer(V216), NA_integer_)]
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

  data.table::setcolorder(pessoas, c("UF", "V116", "V118", "censobr_idhousehold", "censobr_idfamily", "linha", "censobr_weight"))
  data.table::setcolorder(domicilios, c("UF", "V116", "V118", "censobr_idhousehold", "linha", "censobr_weight"))

  message("  pessoas: ", nrow(pessoas), " x ", ncol(pessoas), " | domicilios: ", nrow(domicilios), " x ", ncol(domicilios))
  list(pessoas = pessoas, domicilios = domicilios)
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
