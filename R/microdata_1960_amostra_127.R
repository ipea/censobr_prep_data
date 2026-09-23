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
# As vizinhas de cada UF dentro da sua regiao, em ordem de preferencia (adjacencia em 1960): e a tabela da regra
# de colapso dos estratos com uma pasta so (passo 8). Fernando de Noronha nao precisa dela (estrato de certeza).
VIZINHAS_1960 <- list("0" = c(2, 91, 1), "1" = c(2, 0), "2" = c(4, 3, 1, 0, 91), "3" = c(2, 4), "4" = c(2, 6, 94, 91), "6" = c(4, 2),
                      "91" = c(94, 4, 2, 0), "94" = c(91, 4, 97), "97" = c(94, 91),
                      "10" = c(12, 14), "12" = c(10, 14, 21), "14" = c(12, 17, 19, 21), "17" = c(19, 14), "19" = c(21, 17, 14),
                      "21" = c(19, 25, 14, 12), "24" = c(21), "25" = c(21, 19),
                      "30" = c(31, 40), "31" = c(30, 40, 51), "40" = c(52, 51, 31, 50), "50" = c(51, 40), "51" = c(50, 40, 52, 31),
                      "52" = c(54, 40, 51), "54" = c(52, 40),
                      "60" = c(71), "71" = c(60, 74), "74" = c(71, 81), "81" = c(74, 71))


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
#   reparo_fonte25 campo danificado recuperado em outra fonte, com grupo completo
#                  conferido e evidencia literal em manifesto proprio.
#   corrompida     não sobrou nada legível além do tipo de registro. Todas as
#                  variáveis viram NA; a linha continua no banco, marcada.
#   cartao_uf      não é um registro: é um cartão de cabeçalho da fita, com o
#                  nome do estado em letras (BAHIA, GUANABARA). Sai do banco.
#
# Cada linha alterada guarda, na coluna censobr_diagnostico, qual decisão a
# atingiu; as demais recebem "sem_problema".
# ------------------------------------------------------------------------------
apply_corrections_1960_amostra_127 <- function(linhas, correcoes,
    evidencias_path = "read_guides/1960_amostra_127_reparos_fonte25.json"){

  message("Applying manual corrections to 1960 amostra de 1,27%")

  # read.csv, nao fread: so ele devolve as aspas dobradas e os brancos iniciais
  # exatamente como estao no arquivo
  dec <- data.table::as.data.table(utils::read.csv(correcoes, strip.white = FALSE, stringsAsFactors = FALSE,
                                                   fileEncoding = "UTF-8-BOM", colClasses = "character"))
  dec[, linha := as.integer(linha)]

  if(anyNA(dec$linha) || anyDuplicated(dec$linha) || anyDuplicated(linhas$linha))
    stop("linha invalida ou repetida nas correcoes")
  presentes <- dec[linha %in% linhas$linha]
  if(anyNA(presentes$texto_original) ||
     any(presentes$texto_original != linhas$texto[match(presentes$linha, linhas$linha)]))
    stop("texto original diverge da decisao de correcao")
  danos_pendentes <- presentes[decisao == "dano_salto_nao_resolvido"]
  if(any(!is.na(danos_pendentes$texto_corrigido) & danos_pendentes$texto_corrigido != ""))
    stop("dano nao resolvido nao autoriza alterar o texto")

  # Um reparo externo exige a fonte preservada; nao se estende a outros registros.
  externos <- presentes[decisao == "reparo_fonte25"]
  if(nrow(externos)){
    evidencia <- jsonlite::fromJSON(evidencias_path, simplifyVector = FALSE)
    ids <- as.integer(sapply(evidencia$reparos, `[[`, "linha127"))
    if(anyNA(ids) || anyDuplicated(ids) || any(!externos$linha %in% ids))
      stop("reparo fonte25 sem evidencia unica")
    reparos <- evidencia$reparos[match(externos$linha, ids)]
    if(any(sapply(reparos, function(x) !length(x$grupo127)))) stop("grupo127 ausente na evidencia do reparo")
    grupo_ids <- unique(as.integer(unlist(lapply(reparos, function(x) sapply(x$grupo127, `[[`, "linha")))))
    necessarios <- unique(c(externos$linha, ids[ids %in% grupo_ids]))
    externos <- dec[match(necessarios, linha)]
    if(anyNA(externos$linha) || any(externos$decisao != "reparo_fonte25"))
      stop("reparo fonte25 de integrante do grupo sem decisao")
    reparos <- evidencia$reparos[match(externos$linha, ids)]
    if(any(sapply(reparos, function(x) !length(x$fontes25_possiveis) || !length(x$propostas) || !length(x$grupo25))))
      stop("reparo fonte25 exige fonte literal, grupo25 e campos autorizados")
    fontes <- data.table::rbindlist(evidencia$fontes)
    fontes[, arquivo := gsub("\\", "/", arquivo, fixed = TRUE)]
    raw_path <- "data_raw/microdata/1960/amostra_127/HHOLDA.txt"
    if(sum(fontes$arquivo == raw_path) != 1L ||
       digest::digest(file = raw_path, algo = "sha256") != fontes[arquivo == raw_path, sha256])
      stop("HHOLDA alterado ou ausente na evidencia do reparo")
    arquivos <- unique(unlist(lapply(reparos, function(x) sapply(c(x$fontes25_possiveis, x$grupo25), `[[`, "arquivo"))))
    arquivos <- gsub("\\", "/", arquivos, fixed = TRUE)
    if(any(!arquivos %in% fontes$arquivo) || anyDuplicated(fontes$arquivo))
      stop("fonte do reparo nao consta da evidencia")
    raiz <- paste0(normalizePath(".", winslash = "/"), "/")
    for(arquivo in arquivos){
      if(!startsWith(normalizePath(arquivo, winslash = "/", mustWork = TRUE), raiz) ||
         digest::digest(file = arquivo, algo = "sha256") != fontes$sha256[match(arquivo, fontes$arquivo)])
        stop("fonte alterada ou fora do projeto no reparo")
      esperados <- unlist(lapply(reparos, function(x) Filter(function(y)
        gsub("\\", "/", y$arquivo, fixed = TRUE) == arquivo, c(x$fontes25_possiveis, x$grupo25))), recursive = FALSE)
      numeros <- as.integer(sapply(esperados, `[[`, "linha"))
      if(anyNA(numeros) || any(numeros < 1L)) stop("linha fonte25 invalida na evidencia do reparo")
      con <- gzfile(arquivo, open = "rt", encoding = "latin1")
      inicio <- 0L; literais <- character(length(numeros))
      while(inicio < max(numeros)){
        trecho <- readLines(con, n = 10000L, warn = FALSE)
        if(!length(trecho)) break
        idx <- which(numeros > inicio & numeros <= inicio + length(trecho))
        literais[idx] <- trecho[numeros[idx] - inicio]
        inicio <- inicio + length(trecho)
      }
      close(con)
      if(any(literais != sapply(esperados, `[[`, "texto"))) stop("literal fonte25 diverge da evidencia do reparo")
    }
    guia127 <- data.table::fread("read_guides/readguide_1960_amostra_127_pessoas.csv", encoding = "UTF-8")
    guia25 <- data.table::fread("read_guides/readguide_1960_amostra_25_pessoas.csv", encoding = "UTF-8")
    guia_f127 <- data.table::fread("read_guides/readguide_1960_amostra_127_familias.csv", encoding = "UTF-8")
    guia_f25 <- data.table::fread("read_guides/readguide_1960_amostra_25_familias.csv", encoding = "UTF-8")
    nomes_p <- c("V202", "V203", "V204", "AGE", "V205", "V206", "V207", "V208", "V209", "V299",
                 "V210", "V211", "V212", "V213", "V214", "V215", "V216", "V217", "V218", "V219",
                 "V220", "V221", "V223", "V223B", "V224")
    nomes_f <- c(paste0("V", 101:113), "V116", "V118")

    campos_evidencia <- function(textos, guia, nomes, danos_autorizados = character()){
      valores <- matrix(NA_integer_, nrow = length(textos), ncol = length(nomes), dimnames = list(NULL, nomes))
      for(j in seq_along(nomes)){
        g <- guia[variavel == nomes[j]]
        valor <- substr(textos, g$inicio, g$fim)
        vazio <- trimws(valor) == "" | (substr(valor, 1, 1) == "-" & trimws(substr(textos, g$inicio + 1L, 54L)) == "")
        codigos <- strsplit(g$valores_validos, ";", fixed = TRUE)[[1]]
        valido <- if(g$valores_validos == "") grepl("^[0-9]+$", valor) else valor %in% codigos
        if(any(!vazio & !valido) && !nomes[j] %in% danos_autorizados)
          stop("campo invalido no grupo de evidencia: ", nomes[j])
        valores[!vazio & valido, j] <- as.integer(valor[!vazio & valido])
      }
      valores
    }

    pareamento_evidencia <- function(arestas, fixo = integer()){
      n <- length(arestas); atribuidos <- integer(n)
      if(length(fixo)){
        if(!fixo[2] %in% arestas[[fixo[1]]]) return(FALSE)
        atribuidos[fixo[2]] <- fixo[1]
      }
      colocar <- function(esquerda){
        for(direita in arestas[[esquerda]]){
          if(visitados[direita] || (length(fixo) && direita == fixo[2])) next
          visitados[direita] <<- TRUE
          if(atribuidos[direita] == 0L || colocar(atribuidos[direita])){
            atribuidos[direita] <<- esquerda
            return(TRUE)
          }
        }
        FALSE
      }
      for(esquerda in seq_len(n)){
        if(length(fixo) && esquerda == fixo[1]) next
        visitados <- rep(FALSE, n)
        if(!colocar(esquerda)) return(FALSE)
      }
      TRUE
    }

    contagens_testemunhas <- list()
    contar_testemunha <- function(perfil, arquivo25, uf, ignorar){
      chave_teste <- paste(arquivo25, uf, paste(ignorar, collapse = ","), perfil, sep = "|")
      if(!is.null(contagens_testemunhas[[chave_teste]])) return(contagens_testemunhas[[chave_teste]])
      contagens <- integer(2L)
      for(amostra in seq_len(2L)){
        con <- if(amostra == 1L) file(raw_path, open = "rt", encoding = "latin1") else
          gzfile(arquivo25, open = "rt", encoding = "latin1")
        inicio <- 0L
        repeat {
          trecho <- readLines(con, n = 10000L, warn = FALSE)
          if(!length(trecho)) break
          if(amostra == 1L){
            ajustes <- dec[linha > inicio & linha <= inicio + length(trecho) & !is.na(texto_corrigido) & texto_corrigido != ""]
            if(nrow(ajustes)) trecho[ajustes$linha - inicio] <- ajustes$texto_corrigido
            pessoal <- substr(trecho, 17, 17) %in% c("2", "3") & substr(trecho, 1, 2) == uf
            corpos <- gsub("-", " ", substr(trecho, 19, 54), fixed = TRUE)
          } else {
            pessoal <- substr(trecho, 9, 10) != "00"
            corpos <- paste0(substr(trecho, 15, 24), substr(trecho, 26, 51))
          }
          if(length(ignorar)) substr(corpos, 10, 10) <- " "
          contagens[amostra] <- contagens[amostra] + sum(pessoal & corpos == perfil)
          inicio <- inicio + length(trecho)
        }
        close(con)
      }
      contagens_testemunhas[[chave_teste]] <<- contagens
      contagens
    }

    for(i in seq_along(reparos)){
      reparo <- reparos[[i]]; texto <- reparo$texto_antes
      identidade_ampliada <- identical(reparo$criterio_identidade_contexto,
                                        "grupo_completo_com_divergencias_preservadas_v1")
      if(!is.null(reparo$criterio_identidade_contexto) && !identidade_ampliada)
        stop("criterio de identidade desconhecido no reparo")
      if(reparo$texto_original != externos$texto_original[i] || texto != externos$texto_original[i])
        stop("texto anterior diverge na evidencia do reparo")
      tipo_alvo <- if(substr(texto, 17, 17) == "1") "familias" else "pessoas"
      if(!is.null(reparo$tipo) && reparo$tipo != tipo_alvo) stop("tipo do alvo diverge da evidencia")
      guia_alvo127 <- if(tipo_alvo == "familias") guia_f127 else guia127
      guia_alvo25 <- if(tipo_alvo == "familias") guia_f25 else guia25
      campos_permitidos <- if(tipo_alvo == "familias") paste0("V", 102:113) else nomes_p
      campos_alvo <- sapply(reparo$propostas, `[[`, "campo")
      if(anyDuplicated(campos_alvo)) stop("campo repetido na evidencia do reparo")
      for(campo in reparo$propostas){
        g127 <- guia_alvo127[variavel == campo$campo]; g25 <- guia_alvo25[variavel == campo$campo]
        if(nrow(g127) != 1L || nrow(g25) != 1L || !campo$campo %in% campos_permitidos ||
           g127$inicio != campo$inicio || g127$fim != campo$fim ||
           substr(texto, campo$inicio, campo$fim) != campo$antes ||
           nchar(campo$depois) != campo$fim - campo$inicio + 1L)
          stop("campo ou posicao invalida na evidencia do reparo")
        codigos <- strsplit(g127$valores_validos, ";", fixed = TRUE)[[1]]
        antes_valido <- if(g127$valores_validos == "") grepl("^[0-9]+$", campo$antes) else campo$antes %in% codigos
        depois_valido <- if(g127$valores_validos == "") grepl("^[0-9]+$", campo$depois) else campo$depois %in% codigos
        if(antes_valido && trimws(campo$antes) != "") stop("campo do reparo nao esta danificado")
        if(!depois_valido) stop("valor corrigido invalido no dicionario")
        digitos_antes <- strsplit(campo$antes, "", fixed = TRUE)[[1]]
        digitos_depois <- strsplit(campo$depois, "", fixed = TRUE)[[1]]
        if(any(grepl("^[0-9]$", digitos_antes) & digitos_antes != digitos_depois))
          stop("reparo substituiria digitos legiveis do campo danificado")
        valores <- sapply(reparo$fontes25_possiveis, function(x) substr(x$texto, g25$inicio, g25$fim))
        if(anyNA(suppressWarnings(as.integer(valores))) ||
           any(as.integer(valores) != as.integer(campo$depois)))
          stop("valor recuperado diverge da fonte25")
        substr(texto, campo$inicio, campo$fim) <- campo$depois
      }
      if(texto != reparo$texto_corrigido_proposto || texto != externos$texto_corrigido[i])
        stop("texto corrigido diverge da evidencia do reparo")

      chave <- as.integer(unlist(reparo$chave))
      if(length(chave) != 3L || anyNA(chave) || !identical(chave,
          as.integer(c(substr(texto, 1, 2), substr(texto, 9, 13), substr(texto, 14, 16)))) ||
         any(sapply(reparo$fontes25_possiveis, function(x) substr(x$texto, 1, 8) != substr(texto, 9, 16))))
        stop("chave da fonte25 diverge do alvo do reparo")
      grupo127 <- reparo$grupo127; grupo25 <- reparo$grupo25
      numeros127 <- as.integer(sapply(grupo127, `[[`, "linha"))
      if(!length(numeros127) || anyNA(numeros127) || anyDuplicated(numeros127) ||
         any(numeros127 < 1L) || !reparo$linha127 %in% numeros127)
        stop("grupo127 invalido na evidencia do reparo")
      textos127 <- sapply(grupo127, `[[`, "texto")
      textos127_antes <- textos127
      con127 <- file(raw_path, open = "rb")
      originais127 <- character(length(numeros127))
      for(j in seq_along(numeros127)){
        seek(con127, where = (numeros127[j] - 1) * 64, origin = "start")
        originais127[j] <- readChar(con127, 62L, useBytes = TRUE)
      }
      close(con127)
      anteriores <- originais127
      idx_dec <- match(numeros127, dec$linha)
      for(j in which(!is.na(idx_dec))){
        d <- dec[idx_dec[j]]
        if(d$texto_original != originais127[j]) stop("original do grupo127 diverge da decisao")
        permitidos <- c(originais127[j], d$texto_corrigido)
        idx_reparo <- match(numeros127[j], ids)
        if(!is.na(idx_reparo)) permitidos <- c(permitidos, evidencia$reparos[[idx_reparo]]$texto_antes)
        if(!textos127[j] %in% permitidos) stop("literal do grupo127 diverge da evidencia")
        if(!is.na(d$texto_corrigido) && d$texto_corrigido != "") anteriores[j] <- d$texto_corrigido
      }
      sem_dec <- which(is.na(idx_dec))
      if(any(textos127[sem_dec] != originais127[sem_dec])) stop("literal do grupo127 diverge de HHOLDA")
      textos127 <- anteriores
      textos25 <- sapply(grupo25, `[[`, "texto")
      numeros25 <- as.integer(sapply(grupo25, `[[`, "linha"))
      arquivos25 <- gsub("\\", "/", sapply(grupo25, `[[`, "arquivo"), fixed = TRUE)
      f127 <- which(substr(textos127, 17, 17) == "1"); p127 <- which(substr(textos127, 17, 17) %in% c("2", "3"))
      f25 <- which(substr(textos25, 9, 10) == "00"); p25 <- which(substr(textos25, 9, 10) != "00")
      if(length(f127) != 1L || length(f25) != 1L || length(p127) != length(p25) ||
         length(p127) != reparo$pessoas127 || length(p25) != reparo$pessoas25 ||
         anyDuplicated(numeros25) || length(unique(arquivos25)) != 1L || any(nchar(textos25) != 54L) ||
         any(substr(textos25, 1, 8) != substr(texto, 9, 16)) ||
         any(substr(textos127, 1, 2) != substr(texto, 1, 2)) || any(substr(textos127, 9, 16) != substr(texto, 9, 16)))
        stop("grupo25 ou grupo127 incompleto ou com chave divergente")
      card25 <- textos25[f25]
      ordens25 <- suppressWarnings(as.integer(substr(textos25[p25], 9, 10)))
      if(is.na(suppressWarnings(as.integer(substr(card25, 12, 13)))) ||
         as.integer(substr(card25, 12, 13)) != length(p25) || anyNA(ordens25) ||
         !identical(sort(ordens25), seq_len(length(p25))) ||
         !identical(sort(numeros25[p25]), numeros25[f25] + seq_len(length(p25))) ||
         substr(card25, 37, 54) != strrep("0", 18) ||
         any(substr(textos25[p25], 9, 11) != substr(textos25[p25], 12, 14)) ||
         any(substr(textos25[p25], 24, 24) != substr(textos25[p25], 25, 25)) ||
         any(substr(textos25[p25], 52, 54) != "000"))
        stop("estrutura, ordens ou contagens do grupo25 divergem")
      geografia127 <- textos127
      geo_parcial <- reparo$geografia_parcial_preservada
      if(length(geo_parcial)){
        if(!identidade_ampliada || anyDuplicated(sapply(geo_parcial, `[[`, "linha127")))
          stop("geografia parcial sem criterio ou repetida")
        for(g in geo_parcial){
          idx_geo <- match(as.integer(g$linha127), numeros127)
          if(is.na(idx_geo) || g$campo != "distrito" || nchar(g$antes) != 2L ||
             nchar(g$depois) != 2L || grepl("^[0-9]{2}$", g$antes) ||
             !grepl("^[0-9]{2}$", g$depois) || substr(textos127[idx_geo], 7, 8) != g$antes ||
             g$depois != substr(card25, 34, 35)) stop("geografia parcial diverge da evidencia")
          a_geo <- strsplit(g$antes, "", fixed = TRUE)[[1]]
          b_geo <- strsplit(g$depois, "", fixed = TRUE)[[1]]
          if(any(grepl("^[0-9]$", a_geo) & a_geo != b_geo)) stop("geografia substituiria digito legivel")
          substr(geografia127[idx_geo], 7, 8) <- g$depois
        }
      }
      if(any(substr(geografia127, 3, 6) != substr(card25, 30, 33)) ||
         any(substr(geografia127, 7, 8) != substr(card25, 34, 35)) ||
         any(substr(geografia127, 18, 18) != substr(card25, 36, 36)))
        stop("geografia do grupo127 diverge do grupo25")

      fam127 <- campos_evidencia(textos127[f127], guia_f127, nomes_f)
      fam25 <- campos_evidencia(textos25[f25], guia_f25, nomes_f)
      idx_reparo_f <- match(numeros127[f127], ids)
      danos_f <- if(is.na(idx_reparo_f)) character() else sapply(evidencia$reparos[[idx_reparo_f]]$propostas, `[[`, "campo")
      fam_antes <- campos_evidencia(textos127_antes[f127], guia_f127, nomes_f, danos_f)
      iguais_antes <- (is.na(fam_antes) & is.na(fam25)) | (!is.na(fam_antes) & !is.na(fam25) & fam_antes == fam25)
      dif_antes <- nomes_f[!iguais_antes[1, ]]
      iguais_f <- (is.na(fam127) & is.na(fam25)) | (!is.na(fam127) & !is.na(fam25) & fam127 == fam25)
      dif_f <- nomes_f[!iguais_f[1, ]]
      declaradas <- names(reparo$divergencias_cartao_preservadas)
      if(!setequal(dif_antes, declaradas) || any(!dif_f %in% paste0("V", 102:113)) ||
         (tipo_alvo == "familias" && length(dif_f))) stop("atributos do cartao divergem sem evidencia explicita")
      for(nome in dif_antes) if(!identical(as.integer(sapply(reparo$divergencias_cartao_preservadas[[nome]],
                                                           function(x) if(is.null(x)) NA_integer_ else x)),
                                           as.integer(c(fam_antes[1, nome], fam25[1, nome]))))
        stop("divergencia do cartao nao confere com evidencia")
      valores127 <- campos_evidencia(textos127[p127], guia127, nomes_p)
      valores25 <- campos_evidencia(textos25[p25], guia25, nomes_p)
      divergencias <- reparo$divergencias_pessoais_preservadas
      if(identidade_ampliada){
        testemunhas <- reparo$testemunhas_identidade
        linhas_t <- as.integer(sapply(testemunhas, `[[`, "linha127"))
        linhas_t25 <- as.integer(sapply(testemunhas, `[[`, "linha25"))
        if(!length(testemunhas) || anyNA(linhas_t) || anyNA(linhas_t25) ||
           anyDuplicated(linhas_t) || anyDuplicated(linhas_t25)) stop("testemunhas invalidas")
        completas <- vapply(testemunhas, function(x) !length(x$campos_ignorados), logical(1))
        alvo_parcial <- length(testemunhas) == 1L && linhas_t == reparo$linha127 &&
          identical(unlist(testemunhas[[1]]$campos_ignorados, use.names = FALSE), "V208") &&
          identical(campos_alvo, "V208") && length(p127) >= 3L
        if(sum(completas) < 2L && !alvo_parcial) stop("testemunhos insuficientes para identidade ampliada")
        for(t in testemunhas){
          a_idx <- match(as.integer(t$linha127), numeros127[p127])
          b_idx <- match(as.integer(t$linha25), numeros25[p25])
          ignorar_t <- unlist(t$campos_ignorados, use.names = FALSE)
          if(is.na(a_idx) || is.na(b_idx) ||
             (length(ignorar_t) && (!alvo_parcial || !identical(ignorar_t, "V208"))))
            stop("testemunha fora do grupo ou campo ignorado nao autorizado")
          a <- valores127[a_idx, ]; b <- valores25[b_idx, ]
          iguais <- (is.na(a) & is.na(b)) | (!is.na(a) & !is.na(b) & a == b)
          iguais[nomes_p %in% ignorar_t] <- TRUE
          if(!all(iguais)) stop("testemunha nao coincide nos campos exigidos")
          perfil_t <- gsub("-", " ", substr(textos127[p127[a_idx]], 19, 54), fixed = TRUE)
          if(length(ignorar_t)) substr(perfil_t, 10, 10) <- " "
          if(any(contar_testemunha(perfil_t, arquivos25[f25], substr(texto, 1, 2), ignorar_t) != 1L))
            stop("testemunha nao e unica nas duas fontes")
        }
        pares_declarados <- vapply(divergencias, function(x) paste(x$linha127, x$linha25, sep = "/"), character(1))
        if(anyDuplicated(pares_declarados)) stop("divergencia pessoal repetida")
        for(d in divergencias){
          a_idx <- match(as.integer(d$linha127), numeros127[p127])
          b_idx <- match(as.integer(d$linha25), numeros25[p25])
          if(is.na(a_idx) || is.na(b_idx) || d$linha127 == reparo$linha127)
            stop("divergencia pessoal aponta para alvo ou integrante ausente")
          a <- valores127[a_idx, ]; b <- valores25[b_idx, ]
          iguais <- (is.na(a) & is.na(b)) | (!is.na(a) & !is.na(b) & a == b)
          if(!setequal(nomes_p[!iguais], names(d$diferencas_preservadas)))
            stop("divergencia pessoal nao foi declarada integralmente")
          for(nome in names(d$diferencas_preservadas)){
            declarado <- as.integer(unlist(d$diferencas_preservadas[[nome]]))
            if(length(declarado) != 2L || anyNA(c(a[nome], b[nome])) ||
               !identical(declarado, as.integer(c(a[nome], b[nome]))))
              stop("divergencia pessoal nao confere com respostas legiveis")
          }
        }
      } else if(length(divergencias)) stop("divergencias pessoais sem criterio de identidade")
      arestas <- vector("list", length(p127))
      for(j in seq_along(p127)){
        linha_contexto <- numeros127[p127[j]]
        idx_reparo <- match(linha_contexto, ids)
        ignorar <- if(is.na(idx_reparo)) character() else sapply(evidencia$reparos[[idx_reparo]]$propostas, `[[`, "campo")
        for(k in seq_along(p25)){
          a <- valores127[j, ]; b <- valores25[k, ]
          iguais <- (is.na(a) & is.na(b)) | (!is.na(a) & !is.na(b) & a == b)
          iguais[nomes_p %in% ignorar] <- TRUE
          contexto_v216 <- (!is.null(reparo$correspondencias_contexto) || !is.null(reparo$criterio_adicional) ||
                             isTRUE(reparo$criterio_contexto_v216)) && linha_contexto != reparo$linha127
          if(contexto_v216 && all(c(a["V216"], b["V216"]) %in% c(0L, 63L))) iguais["V216"] <- TRUE
          if(identidade_ampliada && linha_contexto != reparo$linha127){
            autorizadas <- Filter(function(x) x$linha127 == linha_contexto && x$linha25 == numeros25[p25[k]], divergencias)
            if(length(autorizadas) == 1L) iguais[nomes_p %in% names(autorizadas[[1]]$diferencas_preservadas)] <- TRUE
          }
          if(all(iguais)) arestas[[j]] <- c(arestas[[j]], k)
        }
      }
      if(!pareamento_evidencia(arestas)) stop("composicao integral do grupo de reparo diverge")
      origens <- as.integer(sapply(reparo$fontes25_possiveis, `[[`, "linha"))
      if(any(gsub("\\", "/", sapply(reparo$fontes25_possiveis, `[[`, "arquivo"), fixed = TRUE) != arquivos25[f25]))
        stop("correspondencias apontam para outro arquivo25")
      if(tipo_alvo == "familias"){
        if(!setequal(origens, numeros25[f25])) stop("correspondencias do cartao divergem da composicao do grupo")
      } else {
        alvo_idx <- match(reparo$linha127, numeros127[p127])
        possiveis <- arestas[[alvo_idx]][sapply(arestas[[alvo_idx]], function(k) pareamento_evidencia(arestas, c(alvo_idx, k)))]
        if(!setequal(origens, numeros25[p25[possiveis]])) stop("correspondencias individuais divergem da composicao do grupo")
        for(k in possiveis){
          a <- valores127[alvo_idx, ]; b <- valores25[k, ]
          if(any(!((is.na(a) & is.na(b)) | (!is.na(a) & !is.na(b) & a == b))))
            stop("campos nao reparados ou valor recuperado divergem da pessoa25")
        }
      }
    }
  }

  linhas <- data.table::copy(linhas)
  linhas[, texto_original := texto]
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
    out <- x[, .(linha, id_arquivo, censobr_diagnostico, distrito, pasta, boletim, chave,
                 texto_original, texto_corrigido = texto)]
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
# o arquivo repete linhas de pessoa: o mesmo perfil, com todos os 54
# caracteres de dado idênticos, aparece duas vezes na mesma família — nunca
# uma logo abaixo da outra, e em ordem embaralhada. A família de id_arquivo
# 29839, por exemplo, lista as pessoas A, B, C, D, E e, algumas linhas depois,
# C, B, A, E, D. São 2.815 linhas em Pernambuco (5,1% da UF) e no máximo 1,6
# por mil em qualquer outra UF; 497 delas são perfis repetidos de cônjuges.
# Isso é forte indício agregado de cópia, não identidade individual demonstrada.
# O numerador de famílias também pula 856 números exatamente nesses
# municípios. Sem tratamento, Pernambuco fica com 5% de gente a mais e
# famílias de 7,9 pessoas em média onde as vizinhas têm 5,0.
#
# Evidências agregadas de cópia, não prova para cada pessoa. A comparação é dentro do mesmo
# questionário: a linha repetida tem a mesma chave (UF, município, distrito,
# pasta, boletim), o mesmo número a posteriori e os mesmos 54 caracteres de
# dado de outra linha da mesma família; duas famílias parecidas nunca entram
# na comparação. Irmãos de idade ignorada também podem compartilhar o perfil.
# Os fatos abaixo descrevem o padrão de dano, mas não identificam cada cópia:
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
# A regra histórica propunha excluir uma linha repetida quando:
#
#   - é chefe ou cônjuge (nenhuma família tem dois cônjuges idênticos); ou
#   - a família tem duas ou mais linhas repetidas, presumidas bloco copiado; ou
#   - é uma repetida avulsa na cauda da família, depois de todos os
#     originais, num dos três municípios danificados (2135, 2113 e 2115),
#     onde mesmo as repetidas avulsas são quatro vezes mais frequentes que
#     no resto do país, e 45 das 49 estão na cauda — onde as cópias ficam.
#
# Revisão de 22/09/2026: perfil igual apenas identifica candidatos. O manifesto
# autoriza manter/remover linhas específicas, conferidas com a multiplicidade
# da fonte25; qualquer outro perfil repetido interrompe antes das exclusões.
# ------------------------------------------------------------------------------
dedup_1960_amostra_127 <- function(tabelas, out_dir = "./data_raw/microdata/1960/amostra_127",
                                  decisoes_path = "read_guides/1960_amostra_127_duplicatas.csv"){

  message("Reviewing repeated person lines in 1960 amostra de 1,27%")

  pessoas <- data.table::copy(tabelas$pessoas)
  if(anyDuplicated(pessoas$linha)) stop("linha de pessoa duplicada na entrada da deduplicacao")
  data.table::setorder(pessoas, linha)

  # O perfil identifica candidatos; a decisao exige as linhas e textos conferidos.
  vars <- setdiff(names(pessoas), c("linha", "id_arquivo", "censobr_diagnostico", "censobr_variaveis_anuladas",
                                   "texto_original", "texto_corrigido"))
  pessoas[, conteudo := do.call(paste, c(.SD, sep = "|")), .SDcols = vars]
  pessoas[, repetida := duplicated(conteudo), by = id_arquivo]
  pessoas[, na_cauda := repetida & linha > max(linha[!repetida]), by = id_arquivo]
  pessoas[, n_repetidas := sum(repetida), by = id_arquivo]
  pessoas[, decisao_duplicata := ""]
  dec <- data.table::as.data.table(utils::read.csv(decisoes_path, strip.white = FALSE,
    stringsAsFactors = FALSE, fileEncoding = "UTF-8", colClasses = "character"))
  dec[, `:=`(linha = as.integer(linha), n_antes = as.integer(n_antes), n_manter = as.integer(n_manter))]
  if(anyNA(dec$linha) || anyDuplicated(dec$linha) || any(!dec$acao %in% c("manter", "remover")))
    stop("manifesto de duplicatas com linha ou acao invalida")
  grupos <- unique(dec[linha %in% pessoas$linha, grupo])
  dec <- dec[grupo %in% grupos]
  for(grupo_atual in grupos){
    regra <- dec[grupo == grupo_atual]
    idx <- match(regra$linha, pessoas$linha)
    if(anyNA(idx)) stop("grupo de decisao incompleto na entrada: ", grupo_atual)
    if(!all(c("texto_original", "texto_corrigido") %in% names(pessoas)) ||
       anyNA(pessoas$texto_original[idx]) || anyNA(pessoas$texto_corrigido[idx]) ||
       any(pessoas$texto_original[idx] != regra$texto_original) ||
       any(pessoas$texto_corrigido[idx] != regra$texto_corrigido))
      stop("conteudo diverge da decisao de duplicatas: ", grupo_atual)
    if(anyNA(regra$n_antes) || anyNA(regra$n_manter) || data.table::uniqueN(regra$n_antes) != 1L ||
       data.table::uniqueN(regra$n_manter) != 1L || nrow(regra) != regra$n_antes[1] ||
       sum(regra$acao == "manter") != regra$n_manter[1] || regra$n_manter[1] < 1L ||
       data.table::uniqueN(pessoas$conteudo[idx]) != 1L ||
       sum(pessoas$conteudo == pessoas$conteudo[idx[1]] & pessoas$id_arquivo == pessoas$id_arquivo[idx[1]]) != nrow(regra))
      stop("multiplicidade diverge da decisao de duplicatas: ", grupo_atual)
    pessoas[idx, decisao_duplicata := regra$acao]
  }

  # Sem decisao, a entrada permanece intacta e nao chega a exportacao.
  pendentes <- pessoas[repetida & decisao_duplicata == "",
    .(linha, id_arquivo, UF, V116, tipo, V203, AGE, V202, na_cauda, n_repetidas)]
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  data.table::fwrite(pendentes, file.path(out_dir, "duplicatas_a_revisar.csv"), bom = TRUE)
  data.table::fwrite(dec, file.path(out_dir, "duplicatas_decisoes_conferidas.csv"), bom = TRUE)
  if(nrow(pendentes)) stop("Deduplicacao suspensa: ha perfis repetidos sem decisao; nenhuma pessoa foi excluida.")
  removidas <- pessoas[decisao_duplicata == "remover",
    .(linha, id_arquivo, UF, V116, tipo, V203, AGE, V202, na_cauda, n_repetidas,
      motivo = "multiplicidade_fonte_25")]
  data.table::fwrite(removidas, file.path(out_dir, "duplicatas_removidas.csv"), bom = TRUE)
  pessoas[, censobr_duplicata_mantida := repetida & decisao_duplicata == "manter"]
  message("  linhas repetidas: ", sum(pessoas$repetida), "; removidas por decisao: ", nrow(removidas))
  pessoas <- pessoas[decisao_duplicata != "remover"]
  pessoas[, c("conteudo", "repetida", "na_cauda", "n_repetidas", "decisao_duplicata") := NULL]

  list(familias = tabelas$familias, pessoas = pessoas)
}


# ------------------------------------------------------------------------------
# Recuperar somente cartoes aprovados na fonte25, sem importar pessoas ou pesos.
# A linha HHOLDA fica ausente: a procedencia do cartao tem campos proprios.
recover_family_cards_1960_amostra_127 <- function(tabelas,
    manifesto_path = "read_guides/1960_amostra_127_cartoes_recuperados.json",
    out_dir = "./data_raw/microdata/1960/amostra_127"){

  manifesto <- jsonlite::fromJSON(manifesto_path, simplifyVector = FALSE)
  if(!identical(manifesto$versao, 1L)) stop("versao do manifesto de recuperacao invalida")
  cartoes <- manifesto$cartoes
  if(!length(cartoes)) return(tabelas)
  ids <- sapply(cartoes, `[[`, "id_recuperacao")
  todas_linhas <- unlist(lapply(cartoes, function(x) sapply(x$pessoas, `[[`, "linha")))
  chaves <- sapply(cartoes, function(x) paste(x$UF, x$pasta, x$boletim, sep = "|"))
  fontes_cartoes <- sapply(cartoes, function(x) paste(x$arquivo_25, x$linha_25, sep = "|"))
  if(anyNA(ids) || any(ids == "") || anyDuplicated(ids) || anyDuplicated(todas_linhas) ||
     anyDuplicated(chaves) || anyDuplicated(fontes_cartoes))
    stop("decisoes de recuperacao repetidas ou sobrepostas")

  familias <- data.table::copy(tabelas$familias)
  pessoas <- tabelas$pessoas
  if(anyNA(pessoas$linha) || anyDuplicated(pessoas$linha)) stop("linhas pessoais invalidas na recuperacao")
  selecionados <- sapply(cartoes, function(x)
    any(sapply(x$pessoas, `[[`, "linha") %in% pessoas$linha) ||
    any(pessoas$UF == x$UF & pessoas$pasta == x$pasta & pessoas$boletim == x$boletim, na.rm = TRUE))
  cartoes <- cartoes[selecionados]
  if(!length(cartoes)) return(tabelas)

  # A UF nao esta gravada no corpo da fonte25: vem do arquivo estadual.
  siglas_fonte25 <- c(`14`="ce", `17`="rn", `19`="pb", `21`="pe", `24`="fn",
    `25`="al", `30`="se", `31`="ba", `40`="mg", `50`="sa", `52`="rj",
    `60`="sp", `71`="pr", `81`="rs", `91`="mt", `94`="go", `97`="df")
  for(regra_fonte in cartoes){
    sigla_fonte <- unname(siglas_fonte25[as.character(regra_fonte$UF)])
    if(length(sigla_fonte) != 1L || is.na(sigla_fonte) ||
       !identical(regra_fonte$arquivo_25,
         paste0("data/release_legacy/Censo.1960.amostra.25porcento.", sigla_fonte, ".gz")))
      stop("UF diverge do arquivo estadual da recuperacao")
  }

  fontes <- data.table::rbindlist(manifesto$fontes)
  obrigatorias <- c("data_raw/microdata/1960/amostra_127/HHOLDA.txt",
    "read_guides/readguide_1960_amostra_127_familias.csv", "read_guides/readguide_1960_amostra_127_pessoas.csv",
    "read_guides/readguide_1960_amostra_25_familias.csv", "read_guides/readguide_1960_amostra_25_pessoas.csv",
    "read_guides/1960_amostra_127_correcoes.csv", "read_guides/1960_amostra_127_duplicatas.csv",
    "read_guides/1960_amostra_127_vinculos.csv", sapply(cartoes, `[[`, "arquivo_25"),
    unlist(lapply(cartoes, function(x) if(!is.null(x$reconciliacao_chave))
      x$reconciliacao_chave$prova_arquivo else character()), use.names = FALSE))
  if(anyDuplicated(fontes$arquivo) || !all(obrigatorias %in% fontes$arquivo))
    stop("fontes obrigatorias ausentes ou repetidas no manifesto")
  raiz <- paste0(normalizePath(".", winslash = "/"), "/")
  for(i in seq_len(nrow(fontes))){
    caminho <- normalizePath(fontes$arquivo[i], winslash = "/", mustWork = TRUE)
    if(!startsWith(tolower(caminho), tolower(raiz)) ||
       !identical(digest::digest(file = caminho, algo = "sha256"), fontes$sha256[i]))
      stop("fonte alterada ou fora do projeto: ", fontes$arquivo[i])
  }

  gf25 <- data.table::fread("read_guides/readguide_1960_amostra_25_familias.csv", encoding = "UTF-8")
  gp25 <- data.table::fread("read_guides/readguide_1960_amostra_25_pessoas.csv", encoding = "UTF-8")
  gf127 <- data.table::fread("read_guides/readguide_1960_amostra_127_familias.csv", encoding = "UTF-8")
  gp127 <- data.table::fread("read_guides/readguide_1960_amostra_127_pessoas.csv", encoding = "UTF-8")
  correcoes <- utils::read.csv("read_guides/1960_amostra_127_correcoes.csv", strip.white = FALSE,
    stringsAsFactors = FALSE, fileEncoding = "UTF-8", colClasses = "character")

  # O mesmo leitor confere os campos pessoais e familiares, sem apagar dano.
  campos_conferidos <- function(textos, guia){
    resultado <- data.table::data.table(registro = seq_along(textos))
    for(i in seq_len(nrow(guia))){
      var <- guia$variavel[i]
      valor <- substr(textos, guia$inicio[i], guia$fim[i])
      ausente <- trimws(valor) == "" | grepl("^- *$", valor)
      validos <- strsplit(guia$valores_validos[i], ";", fixed = TRUE)[[1]]
      validos <- validos[!validos %in% c("", "NA")]
      ruim <- if(length(validos)) !valor %in% validos else !grepl("^[0-9]+$", valor)
      if(any(ruim & !ausente)) stop("campo danificado na recuperacao: ", var)
      valor[ausente] <- NA_character_
      resultado[, (var) := valor]
    }
    resultado[, registro := NULL]
    resultado
  }

  # Releitura por arquivo; os textos no manifesto nao substituem a fonte bruta.
  literais <- list()
  raw127 <- "data_raw/microdata/1960/amostra_127/HHOLDA.txt"
  for(arquivo in c(raw127, unique(sapply(cartoes, `[[`, "arquivo_25")))){
    if(arquivo == raw127){
      alvos <- sort(unique(unlist(lapply(cartoes, function(x) sapply(x$pessoas, `[[`, "linha")))))
    } else {
      estes <- cartoes[sapply(cartoes, `[[`, "arquivo_25") == arquivo]
      alvos <- sort(unique(unlist(lapply(estes, function(x)
        c(x$linha_25, sapply(x$pessoas, `[[`, "linha_25"), x$linha_25 + x$n_pessoas + 1L)))))
    }
    con <- gzfile(arquivo, open = "rt", encoding = "latin1")
    texto <- rep(NA_character_, length(alvos)); inicio <- 0L
    tryCatch({
      while(inicio < max(alvos)){
        trecho <- readLines(con, n = 10000L, warn = FALSE)
        if(!length(trecho)) break
        idx <- which(alvos > inicio & alvos <= inicio + length(trecho))
        texto[idx] <- trecho[alvos[idx] - inicio]
        inicio <- inicio + length(trecho)
      }
    }, finally = close(con))
    literais[[arquivo]] <- setNames(texto, as.character(alvos))
  }

  novos <- vector("list", length(cartoes))
  provas_chave_conferidas <- character()
  for(i in seq_along(cartoes)){
    regra <- cartoes[[i]]
    # A chave operacional continua sendo a que HHOLDA preservou. A outra
    # numeracao e procedencia, nunca uma substituicao silenciosa de pasta/UPA.
    pasta25 <- regra$pasta; boletim25 <- regra$boletim
    reconciliacao <- regra$reconciliacao_chave
    if(!is.null(reconciliacao)){
      campos_reconciliacao <- c("modalidade", "pasta_25", "boletim_25", "comparacao_pessoal",
        "testemunhas_exatas", "prova_arquivo", "alternativas_restantes",
        "geografia_territorial_alterada", "respostas_pessoais_alteradas")
      if(!all(campos_reconciliacao %in% names(reconciliacao)) ||
         !identical(reconciliacao$modalidade, "numeracao127_preservada") ||
         !reconciliacao$comparacao_pessoal %in% c("25_campos", "24_campos_V216_preservado") ||
         !identical(reconciliacao$geografia_territorial_alterada, FALSE) ||
         !identical(reconciliacao$respostas_pessoais_alteradas, FALSE) ||
         !identical(reconciliacao$alternativas_restantes, 0L) ||
         !is.character(reconciliacao$pasta_25) || length(reconciliacao$pasta_25) != 1L ||
         !grepl("^[0-9]{5}$", reconciliacao$pasta_25) ||
         !is.character(reconciliacao$boletim_25) || length(reconciliacao$boletim_25) != 1L ||
         !grepl("^[0-9]{3}$", reconciliacao$boletim_25) ||
         paste0(reconciliacao$pasta_25, reconciliacao$boletim_25) == paste0(regra$pasta, regra$boletim))
        stop("reconciliacao de chave sem criterio localizado valido")
      prova_chave <- jsonlite::fromJSON(reconciliacao$prova_arquivo, simplifyVector = FALSE)
      casos_chave <- Filter(function(x) identical(x$id_recuperacao, regra$id_recuperacao), prova_chave$cartoes)
      if(length(casos_chave) != 1L || !identical(casos_chave[[1L]], regra))
        stop("decisao de chave diverge da prova localizada")
      # A assinatura do documento nao torna atuais suas dependencias internas.
      # A busca nacional permanece no auditor Python; aqui conferimos a versao
      # de suas fontes e a coerencia das analises, sem refazer essa busca.
      if(!identical(prova_chave$versao, 1L) ||
         !identical(prova_chave$pessoas_novas, 0L) || !identical(prova_chave$respostas_alteradas, 0L))
        stop("escopo invalido da prova de chave")
      if(!reconciliacao$prova_arquivo %in% provas_chave_conferidas){
        fontes_prova <- data.table::rbindlist(prova_chave$fontes)
        obrigatorias_prova <- c(obrigatorias[seq_len(8L)],
          vapply(prova_chave$cartoes, `[[`, character(1), "arquivo_25"))
        if(!all(c("arquivo", "sha256") %in% names(fontes_prova)) ||
           anyNA(fontes_prova$arquivo) || anyNA(fontes_prova$sha256) ||
           anyDuplicated(fontes_prova$arquivo) || !all(obrigatorias_prova %in% fontes_prova$arquivo))
          stop("fontes internas ausentes ou repetidas na prova de chave")
        for(jp in seq_len(nrow(fontes_prova))){
          caminho_prova <- normalizePath(fontes_prova$arquivo[jp], winslash = "/", mustWork = TRUE)
          if(!startsWith(tolower(caminho_prova), tolower(raiz)) ||
             !identical(digest::digest(file = caminho_prova, algo = "sha256"), fontes_prova$sha256[jp]))
            stop("fonte interna alterada na prova de chave")
        }
        provas_chave_conferidas <- c(provas_chave_conferidas, reconciliacao$prova_arquivo)
      }
      analises_chave <- Filter(function(x) identical(x$id_recuperacao, regra$id_recuperacao), prova_chave$analises)
      if(length(analises_chave) != 1L) stop("analise localizada de chave ausente ou repetida")
      analise_chave <- analises_chave[[1L]]
      linhas_regra <- vapply(regra$pessoas, `[[`, integer(1), "linha")
      linhas_analise <- vapply(analise_chave$testemunhas, `[[`, integer(1), "linha127")
      testemunhas_declaradas <- as.integer(unlist(reconciliacao$testemunhas_exatas, use.names = FALSE))
      if(length(linhas_analise) != length(linhas_regra) || anyDuplicated(linhas_analise) ||
         !setequal(linhas_analise, linhas_regra) || length(testemunhas_declaradas) < 2L ||
         anyNA(testemunhas_declaradas) || anyDuplicated(testemunhas_declaradas) ||
         !all(testemunhas_declaradas %in% linhas_analise))
        stop("analise de testemunhas incompleta na prova de chave")
      for(ap in analise_chave$testemunhas){
        pessoa_prova <- regra$pessoas[[match(ap$linha127, linhas_regra)]]
        if(!identical(ap$linha25, pessoa_prova$linha_25))
          stop("pareamento diverge da analise de testemunhas")
        if(ap$linha127 %in% testemunhas_declaradas){
          ocorrencias_uf <- Filter(function(x) identical(as.integer(x$UF), as.integer(regra$UF)),
            ap$ocorrencias25_todasUF)
          if(!identical(ap$exato25, TRUE) || !identical(ap$ocorrencias127UF, 1L) ||
             !identical(ap$ocorrencias25UF, 1L) || length(ocorrencias_uf) != 1L ||
             !identical(ocorrencias_uf[[1L]]$linha, pessoa_prova$linha_25) ||
             !identical(ocorrencias_uf[[1L]]$texto, pessoa_prova$texto_25))
            stop("testemunha sem exclusividade documentada na prova de chave")
        }
      }
      examinados_chave <- analise_chave$cartoes_examinados
      linhas_examinadas <- vapply(examinados_chave, `[[`, integer(1), "linha_cartao127")
      if(!identical(length(examinados_chave), regra$verificacoes$cartoes127_examinados) ||
         anyDuplicated(linhas_examinadas) ||
         any(vapply(examinados_chave, function(x) length(x$motivos_alternativa) != 0L, logical(1))) ||
         !identical(regra$verificacoes$alternativas_plausiveis, 0L))
        stop("alternativa remanescente ou analise incompleta na prova de chave")
      pasta25 <- reconciliacao$pasta_25; boletim25 <- reconciliacao$boletim_25
    }
    dec <- data.table::rbindlist(regra$pessoas)
    idx <- match(dec$linha, pessoas$linha)
    grupo <- pessoas[which(pessoas$UF == regra$UF & pessoas$pasta == regra$pasta & pessoas$boletim == regra$boletim)]
    if(anyNA(idx) || nrow(dec) != regra$n_pessoas ||
       !setequal(grupo$linha, dec$linha) || nrow(grupo) != nrow(dec))
      stop("composicao pessoal incompleta ou excedente: ", regra$id_recuperacao)
    if(any(familias$UF == regra$UF & familias$pasta == regra$pasta &
           familias$boletim == regra$boletim, na.rm = TRUE))
      stop("cartao ja existente na entrada: ", regra$id_recuperacao)
    if(!is.null(reconciliacao) && any(familias$UF == regra$UF & familias$pasta == pasta25 &
           familias$boletim == boletim25, na.rm = TRUE))
      stop("cartao ja existente sob a chave da fonte25: ", regra$id_recuperacao)
    if(anyNA(pessoas$texto_original[idx]) || anyNA(pessoas$texto_corrigido[idx]) ||
       any(pessoas$texto_original[idx] != dec$texto_original) ||
       any(pessoas$texto_corrigido[idx] != dec$texto_corrigido) ||
       anyNA(literais[[raw127]][as.character(dec$linha)]) ||
       any(literais[[raw127]][as.character(dec$linha)] != dec$texto_original))
      stop("conteudo pessoal diverge da recuperacao: ", regra$id_recuperacao)
    pos_correcao <- match(dec$linha, as.integer(correcoes$linha))
    diagnostico <- correcoes$decisao[pos_correcao]
    diagnostico[is.na(diagnostico)] <- "sem_problema"
    texto_esperado <- dec$texto_original
    reparo <- correcoes$texto_corrigido[pos_correcao]
    usa_reparo <- !is.na(reparo) & reparo != ""
    texto_esperado[usa_reparo] <- reparo[usa_reparo]
    if(any(dec$texto_corrigido != texto_esperado)) stop("reparo pessoal nao corresponde ao manifesto de correcoes")
    if(anyNA(pessoas$tipo[idx]) || any(pessoas$tipo[idx] != substr(dec$texto_corrigido, 17, 17)) ||
       anyNA(pessoas$id_arquivo[idx]) || any(pessoas$id_arquivo[idx] != substr(dec$texto_corrigido, 56, 62)) ||
       anyNA(pessoas$censobr_diagnostico[idx]) || any(pessoas$censobr_diagnostico[idx] != diagnostico) ||
       any(!pessoas$censobr_variaveis_anuladas[idx] %in% ""))
      stop("metadados pessoais divergem da recuperacao: ", regra$id_recuperacao)
    for(var in c("UF", "V116", "V118", "distrito", "pasta", "boletim")){
      if(anyNA(pessoas[[var]][idx]) || any(pessoas[[var]][idx] != regra[[var]]))
        stop("geografia pessoal diverge da recuperacao: ", regra$id_recuperacao)
    }
    if(anyNA(pessoas$chave[idx]) || any(pessoas$chave[idx] != paste0(regra$distrito, regra$pasta, regra$boletim)) ||
       any(substr(dec$texto_corrigido, 7, 16) != pessoas$chave[idx]))
      stop("chave pessoal diverge da recuperacao")
    raw <- literais[[regra$arquivo_25]]
    if(is.na(raw[as.character(regra$linha_25)]) ||
       raw[as.character(regra$linha_25)] != regra$texto_25 ||
       anyNA(raw[as.character(dec$linha_25)]) ||
       any(raw[as.character(dec$linha_25)] != dec$texto_25))
      stop("texto do manifesto diverge da fonte25")
    if(nchar(regra$texto_25) != 54L || any(nchar(dec$texto_25) != 54L) ||
       substr(regra$texto_25, 9, 10) != "00" ||
       as.integer(substr(regra$texto_25, 12, 13)) != nrow(dec) ||
       !setequal(dec$linha_25, regra$linha_25 + seq_len(nrow(dec))) ||
       !setequal(as.integer(substr(dec$texto_25, 9, 10)), seq_len(nrow(dec))) ||
       any(substr(dec$texto_25, 9, 10) != substr(dec$texto_25, 12, 13)) ||
       any(substr(dec$texto_25, 11, 11) != substr(dec$texto_25, 14, 14)) ||
       any(substr(dec$texto_25, 24, 24) != substr(dec$texto_25, 25, 25)))
      stop("composicao ou redundancia da fonte25 invalida")
    textos25 <- c(regra$texto_25, dec$texto_25)
    if(any(substr(textos25, 1, 8) != paste0(pasta25, boletim25)))
      stop("boletim da fonte25 divergente")
    seguinte <- raw[as.character(regra$linha_25 + nrow(dec) + 1L)]
    if(!is.na(seguinte) && substr(seguinte, 1, 8) == paste0(pasta25, boletim25))
      stop("fonte25 contem registro excedente no boletim")

    comuns <- intersect(gp127$variavel, gp25$variavel)
    p127 <- campos_conferidos(dec$texto_corrigido, gp127[variavel %in% c(comuns, "UF", "V116", "V118")])
    p25 <- campos_conferidos(dec$texto_25, gp25[variavel %in% comuns])
    for(var in names(p127)){
      if(!identical(p127[[var]], pessoas[[var]][idx]))
        stop("resposta pessoal divergente: ", var)
      if(var %in% comuns && !identical(p127[[var]], p25[[var]])){
        aceita_v216 <- !is.null(reconciliacao) &&
          identical(reconciliacao$comparacao_pessoal, "24_campos_V216_preservado") && var == "V216"
        iguais <- (!is.na(p127[[var]]) & !is.na(p25[[var]]) & p127[[var]] == p25[[var]]) |
          (is.na(p127[[var]]) & is.na(p25[[var]]))
        if(!aceita_v216 || any(!iguais & !(p127[[var]] %in% c("00", "63") & p25[[var]] %in% c("00", "63"))))
          stop("resposta pessoal divergente: ", var)
      }
    }
    if(!is.null(reconciliacao)){
      testemunhas <- as.integer(unlist(reconciliacao$testemunhas_exatas, use.names = FALSE))
      if(length(testemunhas) < 2L || anyNA(testemunhas) || anyDuplicated(testemunhas) ||
         !all(testemunhas %in% dec$linha)) stop("menos de duas testemunhas exatas na chave reconciliada")
      exatas <- Reduce(`&`, lapply(comuns, function(v)
        (!is.na(p127[[v]]) & !is.na(p25[[v]]) & p127[[v]] == p25[[v]]) |
        (is.na(p127[[v]]) & is.na(p25[[v]]))))
      if(!identical(vapply(analise_chave$testemunhas, `[[`, logical(1), "exato25"),
                    unname(exatas[match(linhas_analise, dec$linha)])))
        stop("exatidao diverge da analise de testemunhas")
      if(!all(testemunhas %in% dec$linha[exatas])) stop("testemunha declarada nao e pessoalmente exata")
      perfil24 <- setdiff(comuns, "V216")
      assinatura127 <- do.call(paste, c(p127[, ..perfil24], sep = "|"))
      assinatura25 <- do.call(paste, c(p25[, ..perfil24], sep = "|"))
      if(anyDuplicated(assinatura127) || anyDuplicated(assinatura25))
        stop("pareamento pessoal ambiguo na chave reconciliada")
    }
    campos <- campos_conferidos(regra$texto_25,
      gf25[variavel %in% c(paste0("V", 101:113), "V116", "V117", "V118")])
    if(!campos$V101 %in% c("1", "3")) stop("especie do cartao fora do escopo de recuperacao")
    if(campos$V116 != regra$V116 || campos$V117 != regra$distrito || campos$V118 != regra$V118)
      stop("geografia do cartao25 divergente")
    if(!is.na(campos$V113)) campos[, V113 := sprintf("%02d", as.integer(V113))]
    campos[, V117 := NULL]
    for(var in names(campos)){
      esperado <- regra$familias[[var]]
      if(is.null(esperado)) esperado <- NA_character_
      if(!identical(campos[[var]], esperado)) stop("campo familiar diverge da fonte25: ", var)
      guia <- gf127[variavel == var]
      validos <- setdiff(strsplit(guia$valores_validos, ";", fixed = TRUE)[[1]], c("", "NA"))
      if(length(validos) && !is.na(campos[[var]]) && !campos[[var]] %in% validos)
        stop("campo familiar incompativel com o layout127: ", var)
    }
    novos[[i]] <- cbind(data.table::data.table(linha = NA_integer_, id_arquivo = NA_character_,
      UF = regra$UF, distrito = regra$distrito, pasta = regra$pasta, boletim = regra$boletim,
      chave = paste0(regra$distrito, regra$pasta, regra$boletim),
      texto_original = NA_character_, texto_corrigido = NA_character_,
      censobr_diagnostico = "cartao_recuperado_fonte25", censobr_variaveis_anuladas = "",
      censobr_familia_origem = "recuperada_25", censobr_cartao_recuperado_id = regra$id_recuperacao,
      censobr_cartao_fonte = "amostra_25", censobr_cartao_arquivo = regra$arquivo_25,
      censobr_cartao_linha = as.integer(regra$linha_25),
      censobr_cartao_pasta_fonte25 = pasta25, censobr_cartao_boletim_fonte25 = boletim25,
      censobr_cartao_chave_reconciliada = !is.null(reconciliacao),
      censobr_cartao_criterio_identificacao = if(is.null(reconciliacao)) "25_campos_chave_igual" else reconciliacao$comparacao_pessoal,
      censobr_cartao_sha256 = fontes$sha256[match(regra$arquivo_25, fontes$arquivo)],
      censobr_cartao_unidade = if(campos$V101 == "3") "boletim_coletivo" else "boletim_particular",
      censobr_ordem_cartao = min(dec$linha) - 0.5), campos)
  }

  novos <- data.table::rbindlist(novos)
  if(!"censobr_ordem_cartao" %in% names(familias)) familias[, censobr_ordem_cartao := as.numeric(linha)]
  if(!"censobr_familia_origem" %in% names(familias)) familias[, censobr_familia_origem := "registro"]
  familias <- data.table::rbindlist(list(familias, novos), fill = TRUE)
  data.table::setorder(familias, censobr_ordem_cartao, censobr_cartao_recuperado_id)
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  jsonlite::write_json(list(manifesto = manifesto_path,
    manifesto_sha256 = digest::digest(file = manifesto_path, algo = "sha256"),
    cartoes = novos, n_pessoas_preservadas = nrow(pessoas),
    nota = "Cartoes coletivos identificam boletins, nao edificios distintos."),
    file.path(out_dir, "cartoes_recuperados_conferidos.json"), pretty = TRUE, auto_unbox = TRUE, na = "null")
  list(familias = familias, pessoas = pessoas)
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
# Pessoas cujo questionário não tem registro de família: são 1.493, em 586
# grupos (um grupo = uma chave de questionário). O número a posteriori não
# ajuda a decidir o que são, porque foi atribuído contando registros de
# família na ordem do arquivo: 585 dos 586 grupos carregam o número da
# família imediatamente anterior, e nenhum tem número próprio. Sobra o que
# está nas próprias linhas, e daí vêm dois tipos, com tratamento diferente:
#
#   - o grupo tem chefe ou cônjuge (150 grupos na versão anterior): isso
#     motivava criar uma família "registro_perdido", mas não demonstra perda
#     do cartão. A criação automática foi retirada; só vínculos com cartões
#     reais, explicitamente conferidos no manifesto, são reconciliados;
#   - o grupo não tem chefe nem cônjuge (436 grupos, 1.008 pessoas): são
#     sobretudo hóspedes (V203 = 4 em 698 delas) e pessoas presentes que não
#     moram ali (V202 = 5 ou 6 em 681), listadas num boletim à parte logo
#     depois da família — o id_arquivo 2326 tem um chefe de 50 anos sozinho
#     seguido de 26 hóspedes não moradores em dois boletins. A versão antiga
#     anexava ao registro anterior, sem prova. Essa regra foi retirada: os
#     casos pendentes são listados e interrompem a reconstrução, sem vínculo.
#
# Os parquets existentes ainda contêm "anexada_anterior"; não foram refeitos.
# A etapa de recuperacao acrescenta somente cartoes aprovados da fonte25,
# com procedencia propria; os demais casos continuam interrompendo o preparo.
#
# O domicílio. V101 diz o que a família é: 1 = único ocupante do domicílio,
# 2 = família principal de um domicílio com mais de uma, 3 = coletivo, 4 =
# segunda família, 5 = terceira. Uma família 4 ou 5 vem sempre logo depois
# da principal (345 de 345 vezes), com o boletim seguinte. Então: 1, 2 e 3
# abrem domicílio; 4 e 5 exigem compatibilidade de UF, município, distrito e
# pasta com a família anterior; conflito interrompe para revisão. O único 5
# que vem depois de um 1 (id_arquivo 121705) exige revisão, sem criar domicílio.
#
# Rondônia. 64 famílias (253 pessoas) estão gravadas com UF 03 (Roraima) e
# município 0011, que é Porto Velho: têm a mesma pasta (01/00) das 76
# famílias de Rondônia, naturalidade de Guaporé e Amazonas como elas, e
# estão no arquivo logo antes do Roraima verdadeiro (município 0310). Voltam
# para Rondônia (UF 00), marcadas em censobr_uf_corrigida.
# ------------------------------------------------------------------------------
build_families_1960_amostra_127 <- function(tabelas, out_dir = "./data_raw/microdata/1960/amostra_127",
                                           decisoes_path = "read_guides/1960_amostra_127_vinculos.csv",
                                           coincidencias_path = "read_guides/1960_amostra_127_familias_coincidentes.json",
                                           distrito_prova_path = "references/resolucao_residuais_1960_evidencias/distrito_pe_operacional.json"){

  message("Building families and households in 1960 amostra de 1,27%")

  familias <- data.table::copy(tabelas$familias)
  pessoas  <- data.table::copy(tabelas$pessoas)

  # PE22366/154: a letra X danificou um digito do distrito em dois registros.
  # Preservar ambos os textos e o valor de origem; derivar somente a chave
  # operacional, mediante prova localizada do cartao e dos seis integrantes.
  for(tab_distrito in list(familias, pessoas)){
    tab_distrito[, `:=`(censobr_distrito_original = distrito,
      censobr_distrito_fonte25 = NA_character_, censobr_distrito_recuperado = FALSE,
      censobr_distrito_prova = NA_character_, censobr_distrito_prova_sha256 = NA_character_)]
  }
  alvos_distrito <- c(238423L, 239457:239461)
  if(238422L %in% familias$linha || any(alvos_distrito %in% pessoas$linha)){
    if(is.null(distrito_prova_path) || !file.exists(distrito_prova_path))
      stop("distrito PE danificado exige prova localizada")
    prova_distrito <- jsonlite::fromJSON(distrito_prova_path, simplifyVector = FALSE)
    if(!identical(prova_distrito$versao, 1L) ||
       !identical(prova_distrito$id, "PE-22366-154-distrito") ||
       !identical(prova_distrito$acao, "derivar_distrito_preservar_textos") ||
       !identical(prova_distrito$distrito_original, "X7") ||
       !identical(prova_distrito$distrito_operacional, "07") ||
       !identical(as.integer(unlist(prova_distrito$linhas_reparadas)), c(238422L, 238423L)) ||
       !identical(as.integer(unlist(prova_distrito$linhas_vinculadas)), 239457:239461) ||
       !identical(prova_distrito$alternativas_sob_toda_chave_legivel, 0L))
      stop("decisao geografica PE fora do escopo localizado")
    fontes_distrito <- data.table::rbindlist(prova_distrito$fontes)
    obrigatorias_distrito <- c("data_raw/microdata/1960/amostra_127/HHOLDA.txt",
      "read_guides/1960_amostra_127_correcoes.csv", "data/release_legacy/Censo.1960.amostra.25porcento.pe.gz",
      prova_distrito$prova_texto, prova_distrito$prova_alternativas,
      paste0("read_guides/readguide_1960_amostra_", rep(c("127", "25"), each = 2L),
        "_", rep(c("familias", "pessoas"), 2L), ".csv"))
    if(anyDuplicated(fontes_distrito$arquivo) || !all(obrigatorias_distrito %in% fontes_distrito$arquivo))
      stop("fontes obrigatorias ausentes da prova de distrito PE")
    raiz_distrito <- paste0(normalizePath(".", winslash = "/"), "/")
    for(gd in seq_len(nrow(fontes_distrito))){
      caminho_distrito <- normalizePath(fontes_distrito$arquivo[gd], winslash = "/", mustWork = TRUE)
      if(!startsWith(tolower(caminho_distrito), tolower(raiz_distrito)) ||
         !identical(digest::digest(file = caminho_distrito, algo = "sha256"), fontes_distrito$sha256[gd]))
        stop("fonte alterada na prova de distrito PE")
    }
    texto_prova_distrito <- jsonlite::fromJSON(prova_distrito$prova_texto, simplifyVector = FALSE)
    testemunha_distrito <- Filter(function(x) identical(x$linha127, 238423L),
      texto_prova_distrito$testemunhas_verificadas)
    if(length(testemunha_distrito) != 1L ||
       !identical(testemunha_distrito[[1L]], prova_distrito$testemunha_previa_sem_V208) ||
       !identical(unlist(testemunha_distrito[[1L]]$campos_ignorados), "V208") ||
       !identical(testemunha_distrito[[1L]]$n127, 1L) || !identical(testemunha_distrito[[1L]]$n25, 1L))
      stop("distrito PE exige testemunha anterior ao reparo de V208")
    f_distrito <- familias[linha %in% 238422L]
    p_distrito <- pessoas[linha %in% alvos_distrito]
    pf_distrito <- data.table::rbindlist(list(prova_distrito$cartao127[c("linha", "original", "corrigido")]))
    pp_distrito <- data.table::rbindlist(lapply(prova_distrito$pessoas127, function(x)
      x[c("linha", "original", "corrigido")]))
    data.table::setorder(p_distrito, linha); data.table::setorder(pp_distrito, linha)
    if(nrow(f_distrito) != 1L || nrow(p_distrito) != 6L ||
       !identical(p_distrito$linha, alvos_distrito) || !identical(pp_distrito$linha, alvos_distrito) ||
       !identical(f_distrito$texto_original, pf_distrito$original) ||
       !identical(f_distrito$texto_corrigido, pf_distrito$corrigido) ||
       !identical(p_distrito$texto_original, pp_distrito$original) ||
       !identical(p_distrito$texto_corrigido, pp_distrito$corrigido))
      stop("literal ou composicao127 diverge da prova de distrito PE")
    esperados_distrito <- list(UF = "21", V116 = "2166", V118 = "5", pasta = "22366", boletim = "154")
    for(campo_distrito in names(esperados_distrito)){
      if(anyNA(f_distrito[[campo_distrito]]) || anyNA(p_distrito[[campo_distrito]]) ||
         any(f_distrito[[campo_distrito]] != esperados_distrito[[campo_distrito]]) ||
         any(p_distrito[[campo_distrito]] != esperados_distrito[[campo_distrito]]))
        stop("digito geografico legivel diverge da prova PE: ", campo_distrito)
    }
    if(f_distrito$distrito != "X7" || p_distrito[linha == 238423L, distrito] != "X7" ||
       any(p_distrito[linha != 238423L, distrito] != "07") ||
       f_distrito$chave != "X722366154" ||
       any(p_distrito$chave != paste0(p_distrito$distrito, "22366154")) ||
       nrow(familias[UF == "21" & pasta == "22366" & boletim == "154"]) != 1L ||
       nrow(pessoas[UF == "21" & pasta == "22366" & boletim == "154"]) != 6L)
      stop("chave ou quantidade diverge da prova de distrito PE")
    # Reler HHOLDA nas sete posicoes: a prova literal nao substitui o arquivo.
    raw_distrito <- file("data_raw/microdata/1960/amostra_127/HHOLDA.txt", "rb")
    literais_distrito <- c(pf_distrito$original, pp_distrito$original)
    linhas_distrito <- c(238422L, alvos_distrito)
    tryCatch({
      for(ld in seq_along(linhas_distrito)){
        seek(raw_distrito, where = (linhas_distrito[ld] - 1) * 64, origin = "start")
        if(readChar(raw_distrito, 62L, useBytes = TRUE) != literais_distrito[ld])
          stop("literal PE nao confere com HHOLDA")
      }
    }, finally = close(raw_distrito))
    origem_distrito <- gzfile("data/release_legacy/Censo.1960.amostra.25porcento.pe.gz", "rt", encoding = "latin1")
    registros_distrito <- list(); pos_distrito <- 0L
    tryCatch({
      repeat{
        bloco_distrito <- readLines(origem_distrito, n = 10000L, warn = FALSE)
        if(!length(bloco_distrito)) break
        hits_distrito <- which(substr(bloco_distrito, 1L, 8L) == "22366154")
        if(length(hits_distrito)) registros_distrito[[length(registros_distrito) + 1L]] <-
          data.table::data.table(linha = pos_distrito + hits_distrito, texto = bloco_distrito[hits_distrito])
        pos_distrito <- pos_distrito + length(bloco_distrito)
      }
    }, finally = close(origem_distrito))
    fonte25_distrito <- data.table::rbindlist(registros_distrito)
    declarada25_distrito <- data.table::rbindlist(c(list(prova_distrito$cartao25), prova_distrito$pessoas25))
    if(!identical(fonte25_distrito, declarada25_distrito) || nrow(fonte25_distrito) != 7L ||
       any(nchar(fonte25_distrito$texto) != 54L) ||
       !identical(fonte25_distrito$linha, 902374:902380) ||
       !identical(as.integer(substr(fonte25_distrito$texto, 9L, 10L)), 0:6) ||
       substr(fonte25_distrito$texto[1L], 12L, 13L) != "06" ||
       substr(fonte25_distrito$texto[1L], 34L, 35L) != "07")
      stop("cartao ou composicao25 diverge da prova de distrito PE")
    # Conferir todos os campos efetivos da entrada; nao apenas os textos.
    perfis_distrito <- function(textos, guia_path, campos, tabela = NULL){
      guia <- data.table::fread(guia_path, encoding = "UTF-8")
      resultado <- list()
      for(vd in campos){
        gd <- guia[variavel == vd]
        x <- substr(textos, gd$inicio, gd$fim)
        x[trimws(x) == "" | grepl("^- *$", x)] <- NA_character_
        if(!is.null(tabela) && !identical(x, tabela[[vd]]))
          stop("resposta efetiva diverge da prova de distrito PE: ", vd)
        resultado[[vd]] <- as.integer(x)
      }
      data.table::as.data.table(resultado)
    }
    nomes_familia_distrito <- c(paste0("V", 101:113), "V116", "V118")
    fd127 <- perfis_distrito(f_distrito$texto_corrigido, "read_guides/readguide_1960_amostra_127_familias.csv",
      nomes_familia_distrito, f_distrito)
    fd25 <- perfis_distrito(fonte25_distrito$texto[1L], "read_guides/readguide_1960_amostra_25_familias.csv", nomes_familia_distrito)
    if(!identical(fd127, fd25)) stop("cartao familiar diverge da prova de distrito PE")
    nomes_pessoa_distrito <- c("V202", "V203", "V204", "AGE", "V205", "V206", "V207", "V208", "V209", "V299",
      "V210", "V211", "V212", "V213", "V214", "V215", "V216", "V217", "V218", "V219", "V220", "V221", "V223", "V223B", "V224")
    pd127 <- perfis_distrito(p_distrito$texto_corrigido, "read_guides/readguide_1960_amostra_127_pessoas.csv", nomes_pessoa_distrito, p_distrito)
    pares_distrito <- data.table::rbindlist(lapply(prova_distrito$pares, function(x)
      list(linha127 = x$linha127, linha25 = x$linha25)))
    jp_distrito <- match(p_distrito$linha, pares_distrito$linha127)
    j25_distrito <- match(pares_distrito$linha25[jp_distrito], fonte25_distrito$linha)
    if(anyNA(jp_distrito) || anyNA(j25_distrito) || anyDuplicated(j25_distrito) ||
       !setequal(j25_distrito, 2:7)) stop("pareamento PE incompleto ou repetido")
    pd25 <- perfis_distrito(fonte25_distrito$texto[j25_distrito], "read_guides/readguide_1960_amostra_25_pessoas.csv", nomes_pessoa_distrito)
    for(vd in nomes_pessoa_distrito){
      a <- pd127[[vd]]; b <- pd25[[vd]]
      iguais <- (is.na(a) & is.na(b)) | (!is.na(a) & !is.na(b) & a == b)
      excecao <- vd == "V216" & p_distrito$linha == 239457L & a %in% 0L & b %in% 63L
      if(any(!iguais & !excecao)) stop("composicao pessoal diverge da prova de distrito PE: ", vd)
    }
    hash_distrito <- digest::digest(file = distrito_prova_path, algo = "sha256")
    for(tab_distrito in list(familias, pessoas)){
      tab_distrito[linha %in% c(238422L, 238423L), `:=`(distrito = "07", chave = "0722366154",
        censobr_distrito_fonte25 = "07", censobr_distrito_recuperado = TRUE,
        censobr_distrito_prova = distrito_prova_path, censobr_distrito_prova_sha256 = hash_distrito)]
    }
    dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
    jsonlite::write_json(list(linhas = c(238422L, 238423L), antes = "X7", operacional = "07",
      textos_alterados = FALSE, pessoas_preservadas = alvos_distrito, V216_239457_preservado = "00",
      prova = distrito_prova_path, sha256 = hash_distrito), file.path(out_dir, "distrito_pe_conferido.json"),
      pretty = TRUE, auto_unbox = TRUE)
  }
  if(anyDuplicated(familias$linha[!is.na(familias$linha)]) || anyDuplicated(pessoas$linha) ||
     anyDuplicated(familias[, .(UF, chave)])) stop("linha ou chave de familia duplicada na reconstrucao")
  if(anyNA(familias$linha)){
    if(!all(c("censobr_cartao_recuperado_id", "censobr_cartao_fonte", "censobr_cartao_linha",
              "censobr_ordem_cartao", "censobr_familia_origem") %in% names(familias)))
      stop("cartao sem linha original exige procedencia da recuperacao")
    recuperadas <- familias[is.na(linha)]
    if(anyNA(recuperadas$censobr_cartao_recuperado_id) || any(recuperadas$censobr_cartao_recuperado_id == "") ||
       anyDuplicated(recuperadas$censobr_cartao_recuperado_id) ||
       anyNA(recuperadas$censobr_ordem_cartao) || anyNA(recuperadas$censobr_cartao_linha) ||
       any(!recuperadas$censobr_cartao_fonte %in% "amostra_25") ||
       any(!recuperadas$censobr_familia_origem %in% "recuperada_25") || any(!recuperadas$V101 %in% c("1", "3")))
      stop("procedencia invalida no cartao recuperado")
  }
  if("censobr_ordem_cartao" %in% names(familias)) data.table::setorder(familias, censobr_ordem_cartao)

  # Rondonia gravada como Roraima
  familias[, censobr_uf_corrigida := UF == "03" & V116 == "0011"]
  pessoas[,  censobr_uf_corrigida := UF == "03" & V116 == "0011"]
  familias[censobr_uf_corrigida == TRUE, UF := "00"]
  pessoas[censobr_uf_corrigida == TRUE,  UF := "00"]
  message("  Rondonia: ", sum(familias$censobr_uf_corrigida), " familias e ", sum(pessoas$censobr_uf_corrigida), " pessoas devolvidas")

  # a familia e o registro de familia; a pessoa liga-se a ela pela chave
  familias[, censobr_idfamily := seq_len(.N)]
  if(!"censobr_familia_origem" %in% names(familias)) familias[, censobr_familia_origem := "registro"]
  pessoas[, censobr_familia_origem := ""]
  pessoas[familias, `:=`(censobr_idfamily = i.censobr_idfamily,
                        censobr_familia_origem = i.censobr_familia_origem), on = c("UF", "chave")]

  # Reconciliar apenas pessoas e cartoes cujo conteudo foi conferido nas duas fontes.
  dec <- data.table::as.data.table(utils::read.csv(decisoes_path, strip.white = FALSE,
    stringsAsFactors = FALSE, fileEncoding = "UTF-8", colClasses = "character"))
  dec[, `:=`(linha = as.integer(linha), linha_familia = as.integer(linha_familia))]
  if(anyNA(dec$linha) || anyNA(dec$linha_familia) || anyDuplicated(dec$linha))
    stop("manifesto de vinculos com linha invalida ou repetida")
  dec <- dec[linha %in% pessoas$linha]
  if(nrow(dec)){
    ip <- match(dec$linha, pessoas$linha); jf <- match(dec$linha_familia, familias$linha)
    if(anyNA(jf)) stop("cartao de destino do vinculo ausente na entrada")
    if(!all(c("texto_original", "texto_corrigido") %in% names(pessoas)) ||
       !all(c("texto_original", "texto_corrigido") %in% names(familias)) ||
       anyNA(pessoas$texto_original[ip]) || anyNA(pessoas$texto_corrigido[ip]) ||
       anyNA(familias$texto_original[jf]) || anyNA(familias$texto_corrigido[jf]) ||
       any(pessoas$texto_original[ip] != dec$texto_original) ||
       any(pessoas$texto_corrigido[ip] != dec$texto_corrigido) ||
       any(familias$texto_original[jf] != dec$texto_familia_original) ||
       any(familias$texto_corrigido[jf] != dec$texto_familia_corrigido))
      stop("conteudo diverge da decisao de vinculo")
    if(any(!is.na(pessoas$censobr_idfamily[ip]) &
           pessoas$censobr_idfamily[ip] != familias$censobr_idfamily[jf]))
      stop("decisao de vinculo conflita com cartao ligado diretamente")
    pessoas[ip, `:=`(censobr_idfamily = familias$censobr_idfamily[jf], censobr_familia_origem = "reconciliada_25")]
  }
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  data.table::fwrite(dec, file.path(out_dir, "vinculos_reconciliados.csv"), bom = TRUE)

  diretas <- familias[pessoas[censobr_familia_origem == "registro"], on = "censobr_idfamily",
    .(linha = i.linha, linha_familia = linha, UF = i.UF, V116_pessoa = i.V116, V116_familia = V116,
      V118_pessoa = i.V118, V118_familia = V118)]
  conflito_municipal <- diretas[is.na(V116_pessoa) | is.na(V116_familia) | V116_pessoa != V116_familia]
  data.table::fwrite(conflito_municipal, file.path(out_dir, "vinculos_diretos_a_revisar.csv"), bom = TRUE)
  if(nrow(conflito_municipal))
    stop("Reconstrucao suspensa: municipio divergente ou ausente no vinculo direto; conferir vinculos_diretos_a_revisar.csv.")
  conflito_situacao <- diretas[is.na(V118_pessoa) | is.na(V118_familia) | V118_pessoa != V118_familia]
  data.table::fwrite(conflito_situacao, file.path(out_dir, "vinculos_situacao_a_revisar.csv"), bom = TRUE)
  if(nrow(conflito_situacao))
    stop("Reconstrucao suspensa: situacao divergente ou ausente no vinculo direto; conferir vinculos_situacao_a_revisar.csv.")

  # grupos sem registro de familia
  soltas <- pessoas[is.na(censobr_idfamily)]
  grupos <- soltas[, .(linha_primeira = if(.N) min(linha) else NA_integer_,
                       tem_chefe_ou_conjuge = any(tipo == "2" | V203 %in% c("7", "8")), n = .N), by = .(UF, chave)]
  message("  pessoas sem registro de familia: ", nrow(soltas), " em ", nrow(grupos),
          " grupos; com chefe ou conjuge: ", sum(grupos$tem_chefe_ou_conjuge))

  # Nem a presenca de conjuge nem a posicao no arquivo demonstram perda do cartao.
  pendentes <- pessoas[is.na(censobr_idfamily), .(linha, id_arquivo, UF, V116, distrito, pasta, boletim, chave, tipo, V203)]
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  data.table::fwrite(pendentes, file.path(out_dir, "vinculos_a_revisar.csv"), bom = TRUE)
  if(nrow(pendentes)) stop("Reconstrucao suspensa: conferir vinculos_a_revisar.csv; o registro anterior nao e um vinculo confirmado.")

  # Um cartao sem pessoas nao demonstra domicilio vazio nem contagens conhecidas.
  sem_pessoas <- familias[!censobr_idfamily %in% pessoas$censobr_idfamily,
    .(linha, id_arquivo, UF, V116, distrito, pasta, boletim, chave, V101, V118)]
  data.table::fwrite(sem_pessoas, file.path(out_dir, "cartoes_sem_pessoas_a_revisar.csv"), bom = TRUE)
  if(nrow(sem_pessoas))
    stop("Reconstrucao suspensa: cartao familiar sem pessoas; conferir cartoes_sem_pessoas_a_revisar.csv.")

  # Conteudos familiares iguais sob chaves distintas sao um alerta proprio,
  # nao uma autorizacao para excluir ou fundir pessoas. Contagens se conservam.
  campos_pessoais_coinc <- c("V202", "V203", "V204", "AGE", "V205", "V206", "V207", "V208",
    "V209", "V299", "V210", "V211", "V212", "V213", "V214", "V215", "V216", "V217", "V218",
    "V219", "V220", "V221", "V223", "V223B", "V224")
  campos_familiares_coinc <- c("UF", "distrito", paste0("V", 101:113), "V116", "V118")
  if(!all(c(campos_pessoais_coinc, "censobr_variaveis_anuladas", "censobr_diagnostico") %in% names(pessoas)) ||
     !all(c(campos_familiares_coinc, "censobr_variaveis_anuladas", "censobr_diagnostico") %in% names(familias)))
    stop("conferencia de conteudos familiares exige campos e diagnosticos completos")
  familias_com_dano <- unique(c(
    familias[is.na(censobr_variaveis_anuladas) | censobr_variaveis_anuladas != "" |
      censobr_diagnostico %in% c("corrompida", "dano_salto_nao_resolvido"), censobr_idfamily],
    pessoas[is.na(censobr_variaveis_anuladas) | censobr_variaveis_anuladas != "" |
      censobr_diagnostico %in% c("corrompida", "dano_salto_nao_resolvido"), censobr_idfamily]))
  pessoas_coinc <- pessoas[!censobr_idfamily %in% familias_com_dano,
    c("censobr_idfamily", "linha", campos_pessoais_coinc), with = FALSE]
  pessoas_coinc[, assinatura := do.call(paste, c(.SD, sep = "|")), .SDcols = campos_pessoais_coinc]
  grupos_coinc <- pessoas_coinc[, .(composicao = paste(sort(assinatura), collapse = "~")), by = censobr_idfamily]
  cartoes_coinc <- familias[!censobr_idfamily %in% familias_com_dano,
    c("censobr_idfamily", "linha", campos_familiares_coinc), with = FALSE]
  cartoes_coinc[grupos_coinc, composicao := i.composicao, on = "censobr_idfamily"]
  cartoes_coinc[, assinatura := paste(do.call(paste, c(.SD, sep = "|")), composicao, sep = "#"),
    .SDcols = campos_familiares_coinc]
  coincidentes <- cartoes_coinc[, .(ids = list(censobr_idfamily), n_cartoes = .N), by = assinatura][n_cartoes > 1L]
  relatorio_coinc <- list(); fontes_coinc_conferidas <- FALSE
  cache_fontes_coinc <- new.env(parent = emptyenv())
  # A decisao e recalculada com os literais efetivos. Um booleano de aprovacão
  # no manifesto nao substitui cartao, geografia, ordens e composicao.
  perfil_coinc <- function(textos, amostra, tipo, campos){
    guia <- data.table::fread(paste0("read_guides/readguide_1960_amostra_", amostra,
      "_", tipo, ".csv"), encoding = "UTF-8")
    lapply(campos, function(v){
      g <- guia[variavel == v]
      if(nrow(g) != 1L) stop("campo ausente na conferencia de coincidencias: ", v)
      x <- substr(textos, g$inicio, g$fim)
      ausente <- trimws(x) == "" | grepl("^- *$", x)
      validos <- setdiff(strsplit(g$valores_validos, ";", fixed = TRUE)[[1L]], c("", "NA"))
      invalido <- if(length(validos)) !x %in% validos else !grepl("^[0-9]+$", x)
      if(any(invalido & !ausente)) stop("campo danificado na prova de coincidencias: ", v)
      x[ausente] <- NA_character_
      as.integer(x)
    }) |> stats::setNames(campos) |> data.table::as.data.table()
  }
  ler_origens_coinc <- function(arquivo){
    if(exists(arquivo, envir = cache_fontes_coinc, inherits = FALSE))
      return(get(arquivo, envir = cache_fontes_coinc, inherits = FALSE))
    fontes_deste <- unlist(lapply(disposicoes_coinc$conjuntos, function(x)
      if(identical(x$acao, "preservar_distintos_entre_fontes"))
        Filter(function(y) identical(y$arquivo, arquivo), x$fontes25) else list()), recursive = FALSE)
    chaves_deste <- unique(unlist(lapply(fontes_deste, function(x)
      substr(vapply(x$registros, `[[`, character(1), "texto"), 1L, 8L))))
    con_coinc <- gzfile(arquivo, open = "rt", encoding = "latin1")
    registros_coinc <- list(); inicio_coinc <- 0L
    tryCatch({
      repeat{
        trecho_coinc <- readLines(con_coinc, n = 10000L, warn = FALSE)
        if(!length(trecho_coinc)) break
        hit_coinc <- which(substr(trecho_coinc, 1L, 8L) %in% chaves_deste)
        if(length(hit_coinc)) registros_coinc[[length(registros_coinc) + 1L]] <-
          data.table::data.table(linha = inicio_coinc + hit_coinc, texto = trecho_coinc[hit_coinc])
        inicio_coinc <- inicio_coinc + length(trecho_coinc)
      }
    }, finally = close(con_coinc))
    lido_coinc <- data.table::rbindlist(registros_coinc)
    assign(arquivo, lido_coinc, envir = cache_fontes_coinc)
    lido_coinc
  }
  if(nrow(coincidentes)){
    if(!file.exists(coincidencias_path)) stop("conteudos familiares coincidentes sem manifesto de disposicoes")
    disposicoes_coinc <- jsonlite::fromJSON(coincidencias_path, simplifyVector = FALSE)
    if(!identical(disposicoes_coinc$versao, 1L)) stop("manifesto de coincidencias familiares invalido")
    for(ic in seq_len(nrow(coincidentes))){
      ids_coinc <- coincidentes$ids[[ic]]
      f_coinc <- familias[censobr_idfamily %in% ids_coinc]
      p_coinc <- pessoas[censobr_idfamily %in% ids_coinc]
      candidatas_coinc <- Filter(function(x)
        setequal(as.integer(unlist(x$linhas_cartoes)), f_coinc$linha), disposicoes_coinc$conjuntos)
      aprovado_coinc <- FALSE; motivo_coinc <- "sem_disposicao_localizada"
      id_coinc <- paste0("cartoes-", paste(sort(f_coinc$linha), collapse = "-"))
      if(length(candidatas_coinc) > 1L) stop("disposicoes familiares repetidas para o mesmo conjunto")
      if(length(candidatas_coinc) == 1L){
        regra_coinc <- candidatas_coinc[[1L]]; id_coinc <- regra_coinc$id
        motivo_coinc <- regra_coinc$acao
        if(identical(regra_coinc$acao, "preservar_distintos_entre_fontes")){
          origens_coinc <- regra_coinc$fontes25
          conferencias_coinc <- regra_coinc$conferencias
          if(length(origens_coinc) != nrow(f_coinc) || length(conferencias_coinc) != nrow(f_coinc) ||
             anyDuplicated(vapply(origens_coinc, function(x) paste(x$arquivo, x$linha_cartao, sep = "|"), character(1))) ||
             !all(vapply(conferencias_coinc, function(x) identical(x$suficiente_para_preservar, TRUE), logical(1))) ||
             !setequal(as.integer(vapply(conferencias_coinc, function(x) x$linha_cartao127, integer(1))), f_coinc$linha))
            stop("preservacao entre fontes exige prova de todos os boletins distintos")
          cf_coinc <- data.table::rbindlist(regra_coinc$cartoes127)
          cp_coinc <- data.table::rbindlist(regra_coinc$pessoas127)
          if(anyDuplicated(cf_coinc$linha) || anyDuplicated(cp_coinc$linha) ||
             !setequal(cp_coinc$linha, p_coinc$linha) || !setequal(cf_coinc$linha, f_coinc$linha))
            stop("composicao diverge da disposicao de conteudos familiares")
          ip_coinc <- match(cp_coinc$linha, p_coinc$linha); jf_coinc <- match(cf_coinc$linha, f_coinc$linha)
          destinos_coinc <- familias$linha[match(p_coinc$censobr_idfamily[ip_coinc], familias$censobr_idfamily)]
          if(anyNA(destinos_coinc) || any(destinos_coinc != cp_coinc$linha_cartao) ||
             anyNA(p_coinc$texto_original[ip_coinc]) || anyNA(p_coinc$texto_corrigido[ip_coinc]) ||
             anyNA(f_coinc$texto_original[jf_coinc]) || anyNA(f_coinc$texto_corrigido[jf_coinc]) ||
             any(p_coinc$texto_original[ip_coinc] != cp_coinc$texto_original) ||
             any(p_coinc$texto_corrigido[ip_coinc] != cp_coinc$texto_corrigido) ||
             any(f_coinc$texto_original[jf_coinc] != cf_coinc$texto_original) ||
             any(f_coinc$texto_corrigido[jf_coinc] != cf_coinc$texto_corrigido))
            stop("conteudo diverge da disposicao de familias coincidentes")
          if(!fontes_coinc_conferidas){
            fontes_coinc <- data.table::rbindlist(disposicoes_coinc$fontes)
            if(anyDuplicated(fontes_coinc$arquivo) ||
               !"data_raw/microdata/1960/amostra_127/HHOLDA.txt" %in% fontes_coinc$arquivo)
              stop("fontes da disposicao de familias coincidentes ausentes ou repetidas")
            raiz_coinc <- paste0(normalizePath(".", winslash = "/"), "/")
            for(jc in seq_len(nrow(fontes_coinc))){
              arquivo_coinc <- normalizePath(fontes_coinc$arquivo[jc], winslash = "/", mustWork = TRUE)
              if(!startsWith(tolower(arquivo_coinc), tolower(raiz_coinc)) ||
                 !identical(digest::digest(file = arquivo_coinc, algo = "sha256"), fontes_coinc$sha256[jc]))
                stop("fonte alterada na disposicao de familias coincidentes")
            }
            fontes_coinc_conferidas <- TRUE
          }
          if(!all(vapply(origens_coinc, `[[`, character(1), "arquivo") %in% fontes_coinc$arquivo))
            stop("fonte25 da preservacao familiar ausente das assinaturas")
          # A UF e identificada pelo arquivo, nao pelos dois primeiros digitos da pasta.
          siglas_coinc <- c(`14`="ce", `17`="rn", `19`="pb", `21`="pe", `24`="fn",
            `25`="al", `30`="se", `31`="ba", `40`="mg", `50`="sa", `52`="rj",
            `60`="sp", `71`="pr", `81`="rs", `91`="mt", `94`="go", `97`="df")
          chaves_usadas_coinc <- character()
          for(oc in origens_coinc){
            declarados_coinc <- data.table::rbindlist(oc$registros)
            if(anyDuplicated(declarados_coinc$linha) || anyNA(declarados_coinc$texto) ||
               any(nchar(declarados_coinc$texto) != 54L)) stop("literal25 invalido na prova de coincidencias")
            chave25_coinc <- unique(substr(declarados_coinc$texto, 1L, 8L))
            if(length(chave25_coinc) != 1L || chave25_coinc %in% chaves_usadas_coinc)
              stop("boletim25 repetido ou misturado na prova de coincidencias")
            chaves_usadas_coinc <- c(chaves_usadas_coinc, chave25_coinc)
            fonte_coinc <- ler_origens_coinc(oc$arquivo)
            efetivos_coinc <- fonte_coinc[substr(texto, 1L, 8L) == chave25_coinc]
            data.table::setorder(declarados_coinc, linha); data.table::setorder(efetivos_coinc, linha)
            if(!identical(declarados_coinc[, .(linha, texto)], efetivos_coinc[, .(linha, texto)]))
              stop("literal ou quantidade25 diverge da fonte de coincidencias")
            fc25_coinc <- efetivos_coinc[substr(texto, 9L, 10L) == "00"]
            pc25_coinc <- efetivos_coinc[substr(texto, 9L, 10L) != "00"]
            if(nrow(fc25_coinc) != 1L || fc25_coinc$linha != oc$linha_cartao ||
               as.integer(substr(fc25_coinc$texto, 12L, 13L)) != nrow(pc25_coinc) ||
               !identical(pc25_coinc$linha, fc25_coinc$linha + seq_len(nrow(pc25_coinc))) ||
               !identical(as.integer(substr(pc25_coinc$texto, 9L, 10L)), seq_len(nrow(pc25_coinc))) ||
               any(substr(pc25_coinc$texto, 9L, 10L) != substr(pc25_coinc$texto, 12L, 13L)) ||
               any(substr(pc25_coinc$texto, 11L, 11L) != substr(pc25_coinc$texto, 14L, 14L)) ||
               any(substr(pc25_coinc$texto, 24L, 24L) != substr(pc25_coinc$texto, 25L, 25L)))
              stop("ordens ou redundancias25 invalidas na prova de coincidencias")
            fc127_coinc <- f_coinc[paste0(pasta, boletim) == chave25_coinc]
            if(nrow(fc127_coinc) != 1L || is.na(siglas_coinc[as.character(fc127_coinc$UF)]) ||
               oc$arquivo != paste0("data/release_legacy/Censo.1960.amostra.25porcento.",
                 siglas_coinc[as.character(fc127_coinc$UF)], ".gz") ||
               fc127_coinc$distrito != substr(fc25_coinc$texto, 34L, 35L))
              stop("chave ou geografia25 diverge na prova de coincidencias")
            pc127_coinc <- p_coinc[censobr_idfamily == fc127_coinc$censobr_idfamily]
            if(nrow(pc127_coinc) != nrow(pc25_coinc) ||
               any(substr(pc127_coinc$texto_corrigido, 1L, 8L) != substr(fc127_coinc$texto_corrigido, 1L, 8L)) ||
               any(substr(pc127_coinc$texto_corrigido, 18L, 18L) != substr(fc127_coinc$texto_corrigido, 18L, 18L)))
              stop("geografia ou quantidade127 diverge na prova de coincidencias")
            familiares_coinc <- c(paste0("V", 101:113), "V116", "V118")
            if(!identical(perfil_coinc(fc127_coinc$texto_corrigido, "127", "familias", familiares_coinc),
                          perfil_coinc(fc25_coinc$texto, "25", "familias", familiares_coinc)))
              stop("respostas do cartao divergem na prova de coincidencias")
            pf127_coinc <- perfil_coinc(pc127_coinc$texto_corrigido, "127", "pessoas", campos_pessoais_coinc)
            pf25_coinc <- perfil_coinc(pc25_coinc$texto, "25", "pessoas", campos_pessoais_coinc)
            campos24_coinc <- setdiff(campos_pessoais_coinc, "V216")
            pf127_coinc[, assinatura24 := do.call(paste, c(.SD, sep = "|")), .SDcols = campos24_coinc]
            pf25_coinc[, assinatura24 := do.call(paste, c(.SD, sep = "|")), .SDcols = campos24_coinc]
            if(!identical(sort(pf127_coinc$assinatura24), sort(pf25_coinc$assinatura24)))
              stop("composicao pessoal diverge na prova de coincidencias")
            for(ac in unique(pf127_coinc$assinatura24)){
              casamento127 <- unique(pf127_coinc[assinatura24 == ac, V216])
              casamento25 <- unique(pf25_coinc[assinatura24 == ac, V216])
              if(length(casamento127) != 1L || length(casamento25) != 1L ||
                 (!identical(casamento127, casamento25) &&
                  !setequal(c(casamento127, casamento25), c(0L, 63L))))
                stop("V216 ou pareamento ambiguo na prova de coincidencias")
            }
          }
          aprovado_coinc <- TRUE
        } else if(!identical(regra_coinc$acao, "pendente")) stop("acao invalida para familias coincidentes")
      }
      relatorio_coinc[[ic]] <- list(id = id_coinc, linhas_cartoes = sort(f_coinc$linha),
        linhas_pessoas = sort(p_coinc$linha), n_pessoas = nrow(p_coinc),
        disposicao = motivo_coinc, preservacao_aprovada = aprovado_coinc,
        exclusoes = 0L, nao_e_identificacao_civil = TRUE)
    }
  }
  pendentes_coinc <- data.table::rbindlist(lapply(Filter(function(x) !x$preservacao_aprovada, relatorio_coinc),
    function(x) data.table::data.table(id = x$id, linha = x$linhas_cartoes,
      linhas_pessoas = paste(x$linhas_pessoas, collapse = ";"), motivo = x$disposicao)), fill = TRUE)
  if(!ncol(pendentes_coinc)) pendentes_coinc <- data.table::data.table(id = character(), linha = integer(),
    linhas_pessoas = character(), motivo = character())
  data.table::fwrite(pendentes_coinc, file.path(out_dir, "coincidencias_familiares_a_revisar.csv"), bom = TRUE)
  jsonlite::write_json(list(conjuntos = relatorio_coinc, familias_com_dano_fora_da_comparacao =
    familias$linha[familias$censobr_idfamily %in% familias_com_dano],
    nota = "Comparacao nao homologa dano. Preservar duas unidades entre fontes nao e provar identidade civil."),
    file.path(out_dir, "coincidencias_familiares_conferidas.json"), pretty = TRUE, auto_unbox = TRUE, na = "null")
  if(nrow(pendentes_coinc)) stop("Reconstrucao suspensa: conteudos familiares coincidentes sem disposicao comprovada; conferir coincidencias_familiares_a_revisar.csv.")

  # duas pessoas na posicao de chefe no mesmo questionario (id_arquivo 54150 e 137492)
  chefes <- pessoas[, .(n_chefes = sum(tipo == "2")), by = censobr_idfamily]
  familias[chefes, censobr_dois_chefes := i.n_chefes >= 2, on = "censobr_idfamily"]
  familias[is.na(censobr_dois_chefes), censobr_dois_chefes := FALSE]

  # o domicilio: 1, 2 e 3 abrem; 4 e 5 entram no da familia anterior
  if("censobr_ordem_cartao" %in% names(familias)) data.table::setorder(familias, censobr_ordem_cartao)
  else data.table::setorder(familias, linha)
  familias[, convivente := V101 %in% c("4", "5")]
  if(any(familias$convivente & data.table::shift(familias$censobr_familia_origem) %in% "recuperada_25"))
    stop("Reconstrucao suspensa: cartao recuperado precede familia convivente; conferir a unidade domiciliar.")
  familias[, anterior_permite := data.table::shift(V101) %in% c("2", "4", "5") &
             !is.na(UF) & UF == data.table::shift(UF) &
             !is.na(V116) & V116 == data.table::shift(V116) &
             !is.na(distrito) & distrito == data.table::shift(distrito) &
             !is.na(pasta) & pasta == data.table::shift(pasta)]
  familias[is.na(anterior_permite), anterior_permite := FALSE]
  conflito_convivente <- familias[convivente & data.table::shift(V101) %in% c("2", "4", "5") & !anterior_permite,
                                  .(linha, id_arquivo, UF, V116, distrito, pasta, boletim, V101)]
  data.table::fwrite(conflito_convivente, file.path(out_dir, "conviventes_a_revisar.csv"), bom = TRUE)
  if(nrow(conflito_convivente)) stop("Reconstrucao suspensa: familia convivente cruza geografia ou tem chave incompleta; conferir conviventes_a_revisar.csv.")
  familias[, censobr_convivente_isolada := convivente & !anterior_permite]
  isoladas <- familias[censobr_convivente_isolada == TRUE, .(linha, id_arquivo, UF, V116, distrito, pasta, boletim, V101)]
  data.table::fwrite(isoladas, file.path(out_dir, "conviventes_isoladas_a_revisar.csv"), bom = TRUE)
  if(nrow(isoladas)) stop("Reconstrucao suspensa: familia convivente sem principal confirmado; conferir conviventes_isoladas_a_revisar.csv.")
  familias[, abre := !convivente | censobr_convivente_isolada]
  familias[, censobr_idhousehold := cumsum(abre)]
  familias[, c("convivente", "anterior_permite", "abre") := NULL]
  pessoas[familias, censobr_idhousehold := i.censobr_idhousehold, on = "censobr_idfamily"]
  procedencia <- grep("^censobr_cartao_", names(familias), value = TRUE)
  if(length(procedencia)) pessoas[familias, (procedencia) := mget(paste0("i.", procedencia)), on = "censobr_idfamily"]

  message("  familias: ", nrow(familias), "; domicilios: ", data.table::uniqueN(familias$censobr_idhousehold),
          "; pessoas reconciliadas: ", sum(pessoas$censobr_familia_origem == "reconciliada_25"))

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
# Nacionalidade e vinculos exigem provas localizadas nas etapas anteriores.
# Nascimento no Brasil nao determina nacionalidade; a posicao dos fragmentos
# corrompidos nao demonstra uma familia. Esses casos bloqueiam a reconstrucao.
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
finalize_1960_amostra_127 <- function(tabelas, municipios_path, distritos_path,
                                      geografia_path = NULL, fontes_geografia = NULL){

  message("Finalizing 1960 amostra de 1,27%")

  familias <- data.table::copy(tabelas$familias)
  pessoas  <- data.table::copy(tabelas$pessoas)

  if(anyNA(pessoas$censobr_idfamily) || anyNA(pessoas$censobr_idhousehold) ||
     any(!pessoas$censobr_idfamily %in% familias$censobr_idfamily))
    stop("Finalizacao suspensa: vinculos pendentes nao podem formar um domicilio NA.")
  if(any(!familias$censobr_idfamily %in% pessoas$censobr_idfamily))
    stop("Finalizacao suspensa: cartao familiar sem pessoas; conferir integridade antes da analise.")
  for(v in intersect(c("texto_original", "texto_corrigido"), names(pessoas))) pessoas[, (v) := NULL]
  for(v in intersect(c("texto_original", "texto_corrigido"), names(familias))) familias[, (v) := NULL]

  # filhos tidos e vivos acima de 30: o dicionario de 2018 parava em 30, mas o Codigo do Censo
  # (quesitos R e S) manda registrar o numero declarado; o valor fica e a marca aponta
  for(v in c("V217", "V218")){
    fora <- !is.na(pessoas[[v]]) & as.integer(pessoas[[v]]) >= 31 & as.integer(pessoas[[v]]) <= 98
    data.table::set(pessoas, j = paste0("censobr_", tolower(v), "_fora_da_faixa"), value = fora)
  }
  data.table::setnames(pessoas, "AGE", "V204B")

  # Nacionalidade danificada so e recuperada pelas decisoes localizadas do passo 3.
  # A coluna historica permanece, mas nascimento no Brasil nao preenche a resposta.
  pessoas[, censobr_v208_imputada := FALSE]
  corrompidas <- which(pessoas$censobr_diagnostico == "corrompida")
  local <- familias[pessoas[corrompidas], on = "censobr_idfamily", .(UF, V116, V118, distrito, pasta, boletim, chave)]
  for(v in names(local)) data.table::set(pessoas, i = corrompidas, j = v, value = local[[v]])

  # Sem condicao de presenca valida, o total nao e conhecido; a pessoa continua listada.
  pessoas[, `:=`(censobr_n_listadas   = .N,
                 censobr_n_residentes = if(any(!V202 %in% as.character(1:6))) NA_integer_ else sum(V202 %in% as.character(1:4)),
                 censobr_n_presentes  = if(any(!V202 %in% as.character(1:6))) NA_integer_ else sum(V202 %in% c("1", "2", "5", "6")),
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
  principal <- familias[!(V101 %in% c("4", "5")) | censobr_convivente_isolada == TRUE]
  if("censobr_ordem_cartao" %in% names(principal)) data.table::setorder(principal, censobr_ordem_cartao)
  else data.table::setorder(principal, linha)
  principal <- principal[, .SD[1], by = censobr_idhousehold]
  domicilios <- principal[, .(censobr_idhousehold, linha, id_arquivo, UF, V116, V118, distrito, pasta, boletim, chave,
                              V101, V102, V103, V104, V105, V106, V107, V108, V109, V110, V111, V112, V113,
                              censobr_diagnostico, censobr_variaveis_anuladas, censobr_familia_origem,
                              censobr_uf_corrigida, censobr_convivente_isolada, censobr_dois_chefes)]
  procedencia <- grep("^censobr_cartao_", names(principal), value = TRUE)
  if(length(procedencia)) domicilios[, (procedencia) := principal[, .SD, .SDcols = procedencia]]
  distrito_procedencia <- grep("^censobr_distrito_", names(principal), value = TRUE)
  if(length(distrito_procedencia)) domicilios[, (distrito_procedencia) := principal[, .SD, .SDcols = distrito_procedencia]]
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

  # o municipio: V116 e o codigo do "Codigo de Municipios e Distritos" de 1960, com tres excecoes -- na
  # Guanabara V116 e o bairro (54xx) e o municipio e um so (541, convencao da DTB); Alagoas vem deslocada
  # em 200 (o Codigo da 23xx); Fernando de Noronha vem 2701 e o territorio tem um municipio, 2401
  # code_muni_1960 e o codigo da epoca; code_muni e o atual, pelo crosswalk 1960 -> 2010 da mesma tabela
  municipios <- data.table::fread(municipios_path, encoding = "UTF-8")
  domicilios[, code_muni_1960 := data.table::fifelse(UF == 54L, 541L, data.table::fifelse(UF == 25L, V116 - 200L,
                                 data.table::fifelse(UF == 24L, 2401L, V116)))]
  domicilios[, censobr_muni_corrigido := UF %in% c(54L, 25L, 24L)]
  domicilios[municipios, code_muni := as.integer(i.code_muni_2010), on = c(UF = "uf60", code_muni_1960 = "cod60")]

  # O municipio danificado deste cartao do Parana foi recuperado na fonte25.
  # A prova inclui o grupo inteiro; o codigo derivado nao substitui V116.
  if(any(domicilios$linha %in% 887255L) || any(pessoas$linha %in% 887256L)){
    if(is.null(geografia_path) || is.null(fontes_geografia))
      stop("Municipio do Parana requer manifesto e fontes de geografia.")
    geo <- jsonlite::fromJSON(geografia_path)
    g127 <- data.table::as.data.table(geo$registros127)
    g25 <- data.table::as.data.table(geo$registros25)
    fontes <- data.table::as.data.table(geo$fontes)
    if(geo$versao != 1L || geo$decisao != "PR_71038_216_municipio_fonte25" ||
       geo$code_muni_1960 != 7240L ||
       !identical(as.integer(g127$linha), c(887255L, 887256L, 888718L, 888719L)) ||
       !identical(as.integer(g25$linha), 708706:708709) ||
       !identical(g127$tipo, c("familias", "pessoas", "pessoas", "pessoas")) ||
       !identical(g127$derivar_municipio, c(TRUE, TRUE, FALSE, FALSE)) ||
       !identical(fontes$amostra, c("127", "25")))
      stop("Manifesto municipal fora dos dois registros aprovados do Parana.")
    caminhos <- normalizePath(fontes$arquivo, winslash = "/", mustWork = TRUE)
    fornecidos <- normalizePath(fontes_geografia, winslash = "/", mustWork = TRUE)
    if(!setequal(caminhos, fornecidos)) stop("Fontes municipais fornecidas divergem do manifesto.")
    for(i in seq_len(nrow(fontes))){
      if(digest::digest(file = caminhos[i], algo = "sha256") != fontes$sha256[i])
        stop("Hash da fonte municipal diverge do manifesto.")
      registros <- if(fontes$amostra[i] == "127") g127 else g25
      literais <- character(nrow(registros))
      if(fontes$amostra[i] == "127"){
        con <- file(caminhos[i], open = "rb")
        for(j in seq_len(nrow(registros))){
          seek(con, where = (registros$linha[j] - 1) * 64, origin = "start")
          literais[j] <- readChar(con, 62L, useBytes = TRUE)
        }
        close(con)
      } else {
        con <- gzfile(caminhos[i], open = "rt", encoding = "latin1")
        numero <- 0L
        while(numero < max(registros$linha)){
          trecho <- readLines(con, n = 10000L, warn = FALSE)
          if(!length(trecho)) break
          idx <- which(registros$linha > numero & registros$linha <= numero + length(trecho))
          literais[idx] <- trecho[registros$linha[idx] - numero]
          numero <- numero + length(trecho)
        }
        close(con)
      }
      if(!identical(literais, registros$texto)) stop("Linha ou texto da fonte municipal diverge.")
    }
    cartao25 <- g25$texto[1]
    if(substr(cartao25, 1, 10) != "7103821600" || substr(cartao25, 12, 13) != "03" ||
       substr(cartao25, 30, 36) != "7240075" ||
       any(substr(g127$texto, 1, 2) != "71") || any(substr(g127$texto, 7, 16) != "0771038216") ||
       any(substr(g127$texto, 18, 18) != "5") ||
       !identical(substr(g127$texto, 3, 6), c("724Z", "724Z", "7240", "7240")))
      stop("Geografia ou composicao da prova municipal diverge.")
    linhas_geo <- data.table::data.table(linha = g127$linha, texto = g127$texto,
      texto_original = g127$texto, tipo = substr(g127$texto, 17, 17),
      id_arquivo = substr(g127$texto, 56, 62), censobr_diagnostico = "prova_municipal",
      distrito = substr(g127$texto, 7, 8), pasta = substr(g127$texto, 9, 13),
      boletim = substr(g127$texto, 14, 16), chave = substr(g127$texto, 7, 16))
    esperado_geo <- parse_1960_amostra_127(linhas_geo,
      "read_guides/readguide_1960_amostra_127_familias.csv", "read_guides/readguide_1960_amostra_127_pessoas.csv")
    for(tipo_geo in c("familias", "pessoas")){
      regras <- g127[tipo == tipo_geo]
      indices_geo <- which(tabelas[[tipo_geo]]$linha %in% regras$linha)
      entrada_geo <- data.table::copy(tabelas[[tipo_geo]][indices_geo])
      linhas_entrada_geo <- entrada_geo$linha
      entrada_geo <- entrada_geo[match(regras$linha, linha)]
      if(nrow(entrada_geo) != nrow(regras) || anyNA(entrada_geo$linha) ||
         anyDuplicated(linhas_entrada_geo) ||
         !identical(entrada_geo$texto_original, regras$texto) ||
         !identical(entrada_geo$texto_corrigido, regras$texto))
        stop("Entrada municipal nao corresponde aos registros demonstrados.")
      for(campo_geo in names(geo$local)){
        if(anyNA(entrada_geo[[campo_geo]]) || any(entrada_geo[[campo_geo]] != geo$local[[campo_geo]]))
          stop("Campo geografico da entrada diverge da prova municipal: ", campo_geo)
      }
      esperado_muni <- ifelse(regras$derivar_municipio, NA_character_, "7240")
      if(!identical(as.character(entrada_geo$V116), esperado_muni))
        stop("V116 da entrada foi alterado antes da derivacao municipal.")
      respostas_geo <- esperado_geo[[tipo_geo]][match(regras$linha, linha)]
      for(campo_geo in grep("^(UF|AGE|V[0-9]{3}B?)$", names(respostas_geo), value = TRUE)){
        if(!identical(entrada_geo[[campo_geo]], respostas_geo[[campo_geo]]))
          stop("Resposta da entrada diverge da fonte municipal: ", campo_geo)
      }
    }
    familia_geo <- familias[linha == 887255L]
    domicilio_geo <- domicilios[linha == 887255L]
    membros_geo <- pessoas[censobr_idfamily == familia_geo$censobr_idfamily]
    if(nrow(familia_geo) != 1L || nrow(domicilio_geo) != 1L ||
       !setequal(membros_geo$linha, c(887256L, 888718L, 888719L)) || nrow(membros_geo) != 3L ||
       any(membros_geo$censobr_idhousehold != domicilio_geo$censobr_idhousehold))
      stop("Vinculo ou composicao familiar diverge da prova municipal.")
    domicilios[linha == 887255L, `:=`(code_muni_1960 = geo$code_muni_1960, censobr_muni_corrigido = TRUE,
      censobr_diagnostico = paste0(censobr_diagnostico, "+municipio_fonte25"))]
    pessoas[linha == 887256L, censobr_diagnostico := paste0(censobr_diagnostico, "+municipio_fonte25")]
  }

  # A inferencia antiga por consenso da pasta permanece fora dos dois registros
  # comprovados acima. Sua validade nos demais casos nao e certificada por esta prova.
  domicilios[, muni_pasta := if(data.table::uniqueN(code_muni_1960[!is.na(code_muni)]) == 1) code_muni_1960[!is.na(code_muni)][1] else NA_integer_, by = .(UF, pasta)]
  domicilios[is.na(code_muni) & !is.na(muni_pasta) & !linha %in% 887255L,
             `:=`(code_muni_1960 = muni_pasta, censobr_muni_corrigido = TRUE)]
  domicilios[municipios, `:=`(code_muni = as.integer(i.code_muni_2010), pop_urbana_muni = i.pop_urbana), on = c(UF = "uf60", code_muni_1960 = "cod60")]
  domicilios[, muni_pasta := NULL]

  # o desenho da amostra: a pasta e a unidade sorteada; o estrato e a UF cruzada com um dos quatro grupos de
  # situacao de 1965 -- cidade de 100 mil ou mais, aglomerado urbano menor, rural, mista. A UF como criterio
  # geografico vem do cadastro de pastas reconstruido pela amostra de 25%: dentro de UF x grupo as pastas
  # sorteadas caem de 20 em 20 no cadastro, com inicio proprio em cada estrato (77% dos passos exatos, 90% em
  # 19 a 21); qualquer outro recorte ajusta pior.
  domicilios[, censobr_upa := paste0(UF, "-", pasta)]

  # duas chaves de pasta que o desenho nao aceita. A correcao vai so na coluna de desenho: pasta e V116 ficam
  # como o cartao gravou. Em 54-541 o cartao perdeu os dois ultimos digitos da pasta ("541  ") e guardou o
  # distrito 18, que entre as tres pastas 541xx da Guanabara so a 54142 tem. Em 71-70382 o cartao esta integro,
  # mas a 70382 e a 70380 sao as duas urbanas de Ponta Grossa, vizinhas no cadastro e no mesmo estrato -- uma
  # pasta em vinte nao tira as duas --, ela traz 1 dos 230 boletins que o cadastro lhe da (0,4%, contra 74% da
  # 70380 e 98,7% de mediana no Parana) e o seu boletim 088 e justamente o que falta na 70380. Como unidades
  # primarias de um domicilio so, elas dobravam o erro-padrao do urbano menor do Parana e inflavam em 11% o da
  # cidade grande da Guanabara
  domicilios[trimws(censobr_upa) %in% c("54-541", "71-70382"),
             censobr_diagnostico := data.table::fifelse(censobr_diagnostico == "sem_problema",
                                    "chave_de_pasta_inferida", paste0(censobr_diagnostico, "+chave_de_pasta_inferida"))]
  domicilios[trimws(censobr_upa) == "54-541",   censobr_upa := "54-54142"]
  domicilios[trimws(censobr_upa) == "71-70382", censobr_upa := "71-70380"]

  pastas <- domicilios[, .(urbanos = sum(V118 %in% c(1, 3)), rurais = sum(V118 %in% 5),
                           grande = any(pop_urbana_muni >= 1e5, na.rm = TRUE)), by = censobr_upa]
  pastas[, grupo := data.table::fifelse(urbanos > 0 & rurais > 0, "mista", data.table::fifelse(urbanos == 0, "rural",
                    data.table::fifelse(grande, "cidade grande", "urbana menor")))]
  domicilios[pastas, grupo_pasta := i.grupo, on = "censobr_upa"]
  domicilios[, censobr_estrato := paste0("UF ", UF, " - ", grupo_pasta)]

  # estrato com uma pasta so nao mede variancia: a UF solitaria naquele grupo se junta a primeira vizinha da mesma
  # regiao (VIZINHAS_1960) que tenha pasta no grupo, ate nenhum estrato ficar com uma pasta. Fernando de Noronha
  # fica sozinho de proposito: a sua unica pasta era o cadastro inteiro (nao houve sorteio de pasta), o estrato e
  # de certeza e a etapa das pastas nao tem variancia ali -- no survey, fpc = 1 para a UF 24
  celulas <- unique(domicilios[, .(UF, grupo_pasta, censobr_upa)])[, .(pastas = .N), by = .(UF, grupo_pasta)]
  celulas[, estrato := paste0("UF ", UF, " - ", grupo_pasta)]
  repeat{
    por_estrato <- celulas[, .(pastas = sum(pastas)), by = estrato]
    solitaria <- celulas[estrato %in% por_estrato[pastas == 1, estrato] & UF != 24][1]
    if(is.na(solitaria$UF)) break
    vizinhas <- VIZINHAS_1960[[as.character(solitaria$UF)]]
    vizinha  <- celulas[UF %in% vizinhas & grupo_pasta == solitaria$grupo_pasta & UF != 24][order(match(UF, vizinhas))][1]
    if(is.na(vizinha$UF)) stop("sem vizinha com pasta no grupo para o estrato ", solitaria$estrato)
    celulas[estrato == solitaria$estrato, estrato := vizinha$estrato]
  }
  celulas[, rotulo := paste0("UF ", paste(sort(unique(UF)), collapse = "+"), " - ", grupo_pasta), by = estrato]
  domicilios[celulas, censobr_estrato := i.rotulo, on = c("UF", "grupo_pasta")]
  domicilios[, grupo_pasta := NULL]
  pessoas[domicilios, `:=`(censobr_upa = i.censobr_upa, censobr_estrato = i.censobr_estrato,
                           code_muni = i.code_muni, code_muni_1960 = i.code_muni_1960, censobr_muni_corrigido = i.censobr_muni_corrigido), on = "censobr_idhousehold"]
  domicilios[, pop_urbana_muni := NULL]

  # Os dois V116 danificados do Parana permanecem NA; a resposta literal nao foi recuperada no arquivo127.
  domicilios[is.na(V116) & !is.na(code_muni_1960) & !linha %in% 887255L,
             `:=`(V116 = code_muni_1960, censobr_muni_corrigido = TRUE)]
  pessoas[is.na(V116) & !is.na(code_muni_1960) & !linha %in% 887256L,
          `:=`(V116 = code_muni_1960, censobr_muni_corrigido = TRUE)]

  # o distrito: as posicoes 7-8 da chave sao o codigo de distrito do Codigo de Municipios e Distritos de 1960;
  # na Guanabara o par (V116, distrito) e (bairro, circunscricao ou favela), e a chave do join e o bairro
  distritos <- data.table::fread(distritos_path, encoding = "UTF-8")
  domicilios[, code_district_1960 := as.integer(distrito)]
  domicilios[, chave_muni := data.table::fifelse(UF == 54L, V116, code_muni_1960)]
  domicilios[distritos, `:=`(name_district_1960 = i.name_district_1960, name_bairro_1960 = i.name_bairro_1960, censobr_favela = i.tipo == "favela"),
             on = c(chave_muni = "code_muni_1960", code_district_1960 = "code_district_1960")]
  domicilios[is.na(censobr_favela), censobr_favela := FALSE]
  domicilios[, chave_muni := NULL]

  # o bairro e a unidade em que o censo publica a Guanabara -- a "circunscricao
  # censitaria" do tomo XII, 83 delas -- e o seu codigo e o proprio V116, que na
  # Guanabara vai de 5410 a 5591. Dois registros trazem o V116 danificado pela
  # fita (5 e 18) e ficam sem codigo de bairro, como ja ficam sem o nome.
  domicilios[, code_bairro_1960 := NA_integer_]
  domicilios[UF == 54L & V116 >= 5410L & V116 <= 5591L, code_bairro_1960 := V116]
  pessoas[domicilios, `:=`(code_district_1960 = i.code_district_1960, name_district_1960 = i.name_district_1960,
                           code_bairro_1960 = i.code_bairro_1960, name_bairro_1960 = i.name_bairro_1960,
                           censobr_favela = i.censobr_favela), on = "censobr_idhousehold"]
  message("  distritos: ", domicilios[!is.na(name_district_1960), .N], " de ", nrow(domicilios), " domicilios com nome de distrito; favelas: ",
          domicilios[censobr_favela == TRUE, .N], " domicilios")
  message("  desenho: ", data.table::uniqueN(domicilios$censobr_upa), " pastas (",
          paste(names(table(pastas$grupo)), table(pastas$grupo), collapse = ", "), ") em ",
          data.table::uniqueN(domicilios$censobr_estrato), " estratos; menor estrato com ",
          min(unique(domicilios[, .(censobr_estrato, censobr_upa)])[, .N, by = censobr_estrato]$N), " pastas")

  data.table::setcolorder(pessoas, c("UF", "V116", "V118", "code_muni", "code_muni_1960", "code_district_1960", "name_district_1960", "code_bairro_1960", "name_bairro_1960", "censobr_favela", "censobr_muni_corrigido", "censobr_idhousehold", "censobr_idfamily", "linha", "censobr_weight", "censobr_upa", "censobr_estrato"))
  data.table::setcolorder(domicilios, c("UF", "V116", "V118", "code_muni", "code_muni_1960", "code_district_1960", "name_district_1960", "code_bairro_1960", "name_bairro_1960", "censobr_favela", "censobr_muni_corrigido", "censobr_idhousehold", "linha", "censobr_weight", "censobr_upa", "censobr_estrato"))

  message("  pessoas: ", nrow(pessoas), " x ", ncol(pessoas), " | domicilios: ", nrow(domicilios), " x ", ncol(domicilios))
  list(pessoas = pessoas, domicilios = domicilios)
}


# ------------------------------------------------------------------------------
# As células da calibração aos resultados definitivos
#
# Usadas duas vezes: pelo passo 9, para calibrar, e pelo passo 11, para a
# variância pelos resíduos da calibração. Devolve a matriz X, domicílio ×
# célula, com o número de pessoas do domicílio em cada célula; os totais
# publicados (alvos, com o fator implícito de cada célula); e a ordem dos
# domicílios (hh), que é a das linhas de X.
# ------------------------------------------------------------------------------
celulas_definitivos_1960_amostra_127 <- function(pessoas, domicilios, def){

  pessoas <- data.table::copy(pessoas)
  def     <- data.table::copy(def)
  if(anyDuplicated(def[, .(tabela, uf60, item, sexo, medida)]))
    stop("chave duplicada no gabarito da calibracao")
  if(anyNA(domicilios$censobr_idhousehold) || anyDuplicated(domicilios$censobr_idhousehold))
    stop("identificadores ausentes ou duplicados nos domicilios da calibracao")
  if(any(!pessoas$censobr_idhousehold %in% domicilios$censobr_idhousehold))
    stop("pessoas sem domicilio na calibracao")
  regiao_uf <- REGIAO_1960
  faixas <- c("0 a 4", "5 a 9", "10 a 14", "15 a 19", "20 a 24", "25 a 29", "30 a 39", "40 a 49", "50 a 59", "60 a 69", "70 e mais e ignorada")
  pessoas[, regiao   := regiao_uf[as.character(UF)]]
  pessoas[, sexo     := data.table::fifelse(V202 %in% c(1, 3, 5), "homens", data.table::fifelse(V202 %in% c(2, 4, 6), "mulheres", NA_character_))]
  pessoas[, idade := data.table::fifelse(V204 %in% 1 & V204B %in% 0:99, V204B,
                    data.table::fifelse(V204 %in% 0 & V204B %in% 0:99, 0L,
                    data.table::fifelse(V204 %in% 5, 100L, NA_integer_)))]
  pessoas[, faixa    := faixas[findInterval(idade, c(0, 5, 10, 15, 20, 25, 30, 40, 50, 60, 70))]]
  pessoas[V204 %in% 9, faixa := "70 e mais e ignorada"]
  pessoas[, presente := V202 %in% c(1, 2, 5, 6)]
  if(any(pessoas$UF != 97 & !pessoas$V202 %in% 1:6))
    stop("presenca desconhecida em controles da calibracao definitiva")
  pessoas[, alfabetizacao := data.table::fifelse(V211 %in% c(0, 1), "sabem", data.table::fifelse(V211 %in% c(2, 3), "nao_sabem", NA_character_))]
  if(any(pessoas$presente & pessoas$UF != 97 & ((!is.na(pessoas$idade) & pessoas$idade >= 5) | pessoas$V204 %in% 9) &
         !pessoas$V211 %in% 0:4)) stop("alfabetizacao desconhecida em controles da calibracao definitiva")
  hh <- sort(unique(domicilios$censobr_idhousehold))
  # --- definitivos: as faixas de idade por sexo so para a UF com 8 pastas ou mais; as pequenas (RO, AC, RR, AP,
  # Fernando de Noronha, Serra dos Aimores) ficam com o total por sexo. Juntar as pequenas do Norte e Centro-Oeste
  # num "resto" com faixas de idade foi testado e rejeitado: os fatores implicitos das quatro vao de 0,7 a 1,6, e a
  # estrutura etaria conjunta so fechava inflando familias grandes de Rondonia ate 7 vezes. O DF fica fora de tudo.
  pastas_uf <- domicilios[UF != 97, .(pastas = data.table::uniqueN(censobr_upa)), by = UF]
  pastas_uf[, regiao := regiao_uf[as.character(UF)]]
  pastas_uf[, grupo := data.table::fifelse(pastas >= 8, as.character(UF), NA_character_)]
  pessoas[pastas_uf, grupo := i.grupo, on = "UF"]
  dano <- pessoas[presente == TRUE & UF != 97 & is.na(idade) & !V204 %in% 9 &
                    (!is.na(grupo) | alfabetizacao %in% "sabem" | !V211 %in% 0:4)]
  if(nrow(dano)) stop("idade danificada em controles da calibracao; resolver ou explicitar a politica antes do ajuste: linhas ",
                     paste(head(dano$linha, 10L), collapse = ", "))
  # quem sabe ler: as quatro pequenas do Norte e Centro-Oeste juntas; Noronha e Aimores sozinhas
  pessoas[, grupo_d := data.table::fifelse(!is.na(grupo), grupo, data.table::fifelse(regiao == "Norte e Centro-Oeste", "resto Norte e Centro-Oeste", as.character(UF)))]
  pessoas[, cel_a := data.table::fifelse(presente & !is.na(grupo) & !is.na(sexo) & !is.na(faixa), paste("a", grupo, sexo, faixa, sep = "|"), NA_character_)]
  pessoas[, cel_b := data.table::fifelse(presente & UF != 97 & is.na(grupo) & !is.na(sexo), paste("b", UF, sexo, sep = "|"), NA_character_)]
  # a populacao urbana so e restricao onde ha 8 pastas ou mais: com uma ou duas pastas o corte urbano/rural da UF
  # nao tem como ser reproduzido sem fatores extremos (Acre: 0,23 na pasta urbana, 6 na rural)
  ufs_c <- pastas_uf[pastas >= 8, UF]
  if(any(pessoas$presente & pessoas$UF %in% ufs_c & !pessoas$V118 %in% c(1, 3, 5)))
    stop("situacao desconhecida em controles da calibracao definitiva")
  pessoas[, cel_c := data.table::fifelse(presente & UF %in% ufs_c & V118 %in% c(1, 3), paste("c", UF, sep = "|"), NA_character_)]
  pessoas[, cel_d := data.table::fifelse(presente & UF != 97 & ((!is.na(idade) & idade >= 5) | V204 %in% 9) & alfabetizacao %in% "sabem" & !is.na(sexo), paste("d", grupo_d, sexo, sep = "|"), NA_character_)]

  def[tabela == 33 & item %in% c("70 e mais", "ignorada"), item := "70 e mais e ignorada"]
  t33 <- def[tabela == 33 & sexo != "total", .(valor = sum(valor)), by = .(uf60, item, sexo)]
  t33[pastas_uf, grupo := i.grupo, on = c(uf60 = "UF")]
  alvo_a <- t33[!is.na(grupo) & item != "total", .(celula = paste("a", grupo, sexo, item, sep = "|"), total = valor)]
  alvo_b <- t33[item == "total" & uf60 %in% pastas_uf[is.na(grupo), UF], .(celula = paste("b", uf60, sexo, sep = "|"), total = valor)]
  alvo_c <- def[tabela == 34 & item == "urbana" & sexo == "total" & uf60 %in% ufs_c, .(celula = paste("c", uf60, sep = "|"), total = valor)]
  t40 <- def[tabela == 40 & item == "sabem" & sexo != "total" & uf60 != 97]
  t40[pastas_uf, grupo := i.grupo, on = c(uf60 = "UF")]
  t40[is.na(grupo), grupo := data.table::fifelse(regiao_uf[as.character(uf60)] == "Norte e Centro-Oeste", "resto Norte e Centro-Oeste", as.character(uf60))]
  alvo_d <- t40[, .(total = sum(valor)), by = .(grupo, sexo)][, .(celula = paste("d", grupo, sexo, sep = "|"), total)]
  alvos <- rbind(alvo_a, alvo_b, alvo_c, alvo_d)
  if(anyDuplicated(alvos$celula)) stop("celula duplicada nos controles da calibracao")

  cont <- data.table::rbindlist(lapply(c("cel_a", "cel_b", "cel_c", "cel_d"), function(v) pessoas[!is.na(get(v)), .N, by = .(censobr_idhousehold, celula = get(v))]))
  if(any(!cont$celula %in% alvos$celula)) stop("celulas da amostra sem total publicado: ", paste(head(unique(cont$celula[!cont$celula %in% alvos$celula])), collapse = ", "))
  X <- Matrix::sparseMatrix(i = match(cont$censobr_idhousehold, hh), j = match(cont$celula, alvos$celula), x = cont$N,
                           dims = c(length(hh), nrow(alvos)), dimnames = list(NULL, alvos$celula))
  amostra <- as.numeric(Matrix::colSums(X))
  if(any(amostra == 0)) stop("celulas sem pessoa na amostra: ", paste(alvos$celula[amostra == 0], collapse = ", "))
  base_def <- rep(1 / 0.0127, length(hh))
  base_def[hh %in% domicilios[UF == 24, censobr_idhousehold]] <- 4
  alvos[, implicito := round(total / as.numeric(Matrix::crossprod(X, base_def)), 2)]
  list(X = X, alvos = alvos, hh = hh)
}


# ------------------------------------------------------------------------------
# Passo 9 — dois pesos calibrados: aos resultados definitivos e aos preliminares de 1965
#
# Os gabaritos. Em março de 1965 o IBGE publicou, com estes mesmos cartões,
# antes do dano da fita, os "Resultados Preliminares do Censo Demográfico",
# Série Especial, vol. II (biblioteca do IBGE, liv84480). O quadro 1 dá a
# população presente por região (Nordeste, Leste, Sul e o Brasil, de onde
# sai Norte + Centro-Oeste por diferença), situação (urbana = quadros urbano
# e suburbano, V118 = 1 ou 3; rural, V118 = 5), sexo e onze faixas de idade.
# São 176 números, transcritos e conferidos por aritmética em
# references/censo_1960_resultados_preliminares_1965.csv. Esses totais foram
# estimados com esta mesma amostra: calibrar a eles repara o dano do arquivo
# e devolve os pesos que o IBGE usou, mas não traz informação de fora.
#
# O volume nacional dos resultados definitivos (Série Nacional, vol. I, anos
# 1970) traz, por unidade da federação, a população presente por sexo e
# grupos de idade (tab. 33), por situação (tab. 34), por cor (tab. 37) e a
# alfabetização de 5 anos e mais (tab. 40), transcritas em
# references/censo_1960_resultados_definitivos_serie_nacional.csv. Para onze
# unidades da federação são contagens completas; para as dezessete restantes,
# apuradas só pelo Boletim de Amostra, são estimativas da amostra de 25%,
# vinte vezes mais precisas que esta subamostra. Calibrar a elas ancora a
# amostra no que o censo contou, por unidade da federação e não só por
# região, e torna real a redução de variância.
#
# O desenho. A amostra é de pastas (lotes de ~250 questionários), uma em
# vinte, estratificadas por unidade da federação e situação — o arquivo tem
# as 814 pastas sorteadas. O fator de expansão implícito é 79 a 80 nas
# unidades grandes; em Fernando de Noronha é 0,06, porque a sua única pasta
# era o cadastro inteiro, e no Distrito Federal é 2,5 a 4, porque o arquivo
# perdeu 80% dos seus boletins.
#
# A calibração. Cada domicílio recebe um peso único, o mesmo para todas as
# suas pessoas, tal que as somas ponderadas reproduzem exatamente as células
# do gabarito. É a calibração de Deville e Särndal com a distância "raking":
# o peso é o peso de desenho (78,74 = 1/0,0127) vezes um fator exp(x'λ), onde
# x conta quantas pessoas presentes o domicílio tem em cada célula, e λ é
# resolvido por Newton. O fator fica perto de 1 quando o arquivo está íntegro
# e afasta-se onde faltam ou sobram cartões — por isso ele também é um
# diagnóstico, gravado nas colunas *_fator.
#
# censobr_weight, o peso final, é calibrado aos definitivos, em cinco blocos
# de células, todos de pessoas presentes e nenhum com o Distrito Federal, que
# fica no peso de desenho por decisão (nenhum peso cria o que o arquivo
# perdeu), com a distância logit, que mantém cada fator entre 0,3 e 3,5, e com
# o peso de desenho de Fernando de Noronha corrigido para 4, porque a sua única
# pasta era o cadastro inteiro: (a) sexo × onze faixas de idade por unidade da federação com oito
# pastas ou mais; (b) só o total por sexo nas seis pequenas (RO, AC, RR, AP,
# Fernando de Noronha, Serra dos Aimorés); (c) população urbana, nas
# unidades com oito pastas ou mais; (d) quem sabe ler e escrever, de 5 anos
# e mais, por sexo, por unidade da federação com oito pastas ou mais, pelas
# quatro pequenas do Norte e Centro-Oeste juntas, e por Noronha e Aimorés.
# Juntar as quatro pequenas do Norte e Centro-Oeste em faixas de idade foi
# testado e rejeitado (fatores até 7 em Rondônia). A cor foi
# testada e rejeitada como restrição: no arquivo, quem ficou sem código de
# cor (dano, cinco vezes mais que o "sem declaração" publicado) faz falta aos
# pretos e pardos, e a calibração compensava inflando as famílias grandes com
# código válido, até fatores de 6.
#
# censobr_weight_1965 é o peso calibrado às 184 células de 1965 (quadro 1 e
# os que sabem ler do quadro 2, por sexo e região); serve para reproduzir a
# publicação de 1965 e para medir, contra o peso final, quanto os
# preliminares se afastam dos definitivos.
#
# O que não entra. O estado conjugal por sexo (quadro 5) foi testado e
# rejeitado: leva o fator de alguns domicílios a 18 vezes o de desenho,
# porque força os que perderam o cartão do chefe a compensar com peso o que
# falta no arquivo. Os domicílios (quadros 6 e 7 de 1965, tab. 7 dos
# definitivos) servem de validação, não de restrição. Rondônia, Amapá, Acre,
# Fernando de Noronha e o Distrito Federal têm cobertura parcial e nenhum
# peso cria o que não foi amostrado.
# ------------------------------------------------------------------------------
raking_1960_amostra_127 <- function(X, totais, d, limites = NULL,
                                  tolerancia = 1e-10, max_iter = 200L){

  # calibracao de Deville-Sarndal resolvida por Newton: g = exp(X lambda) (raking) ou, com limites (L, U), a
  # distancia logit, que mantem cada fator entre L e U -- o raking puro faz o fator crescer com o tamanho do
  # domicilio (exp da soma dos lambdas das pessoas), e nas UFs de uma pasta chegava a 9
  if(length(dim(X)) != 2L || any(dim(X) == 0L) || nrow(X) != length(d) || ncol(X) != length(totais))
    stop("dimensoes incompativeis na calibracao")
  valores <- if(inherits(X, "sparseMatrix") && "x" %in% methods::slotNames(X)) X@x else as.vector(X)
  if(any(!is.finite(valores)) || any(valores < 0)) stop("matriz de controles deve conter contagens finitas nao negativas")
  if(any(!is.finite(totais)) || any(totais <= 0)) stop("alvos da calibracao devem ser finitos e positivos")
  if(any(!is.finite(d)) || any(d <= 0)) stop("pesos de desenho devem ser finitos e positivos")
  if(length(tolerancia) != 1L || !is.finite(tolerancia) || tolerancia <= 0 ||
     length(max_iter) != 1L || !is.finite(max_iter) || max_iter < 1 ||
     max_iter > .Machine$integer.max || max_iter != floor(max_iter))
    stop("tolerancia e max_iter invalidos na calibracao")
  rotulos <- colnames(X)
  if(is.null(rotulos)) rotulos <- as.character(seq_len(ncol(X)))
  suporte <- as.numeric(Matrix::crossprod(X, d))
  if(any(!is.finite(suporte))) stop("suporte ponderado nao finito na calibracao")
  if(any(suporte == 0)) stop("controle positivo sem suporte amostral: ", paste(rotulos[suporte == 0], collapse = ", "))
  if(is.null(limites)){ g <- function(u) exp(u); dg <- function(u) exp(u) }
  else {
    if(length(limites) != 2L || any(!is.finite(limites)) || limites[1] <= 0 || limites[1] >= 1 || limites[2] <= 1)
      stop("limites devem satisfazer 0 < L < 1 < U")
    L <- limites[1]; U <- limites[2]; A <- (U - L) / ((1 - L) * (U - 1))
    fora <- totais < L * suporte - tolerancia * totais | totais > U * suporte + tolerancia * totais
    if(any(fora)) stop("alvos fora dos limites possiveis do peso: ", paste(rotulos[fora], collapse = ", "))
    # Mesma distancia logit, sem exp(u)/exp(u) quando o passo e grande.
    g  <- function(u) L + (U - L) * stats::plogis(A * u + log((1 - L) / (U - 1)))
    dg <- function(u){ s <- stats::plogis(A * u + log((1 - L) / (U - 1))); A * (U - L) * s * (1 - s) }
  }
  lambda <- rep(0, ncol(X))
  u <- as.numeric(X %*% lambda); w <- d * g(u); F <- as.numeric(Matrix::crossprod(X, w)) - totais
  erro <- max(abs(F) / totais)
  if(!is.finite(erro)) stop("residuo inicial nao finito na calibracao")
  for(it in seq_len(max_iter)){
    if(erro <= tolerancia) break
    J <- as.matrix(Matrix::crossprod(X, Matrix::Diagonal(x = d * dg(u)) %*% X))
    if(any(!is.finite(J))) stop("jacobiana nao finita na calibracao")
    passo <- tryCatch(solve(J, F), error = function(e)
      stop("sistema de calibracao singular ou numericamente inviavel: ", conditionMessage(e)))
    if(any(!is.finite(passo))) stop("passo nao finito na calibracao")
    melhorou <- FALSE
    for(k in 0:12){                                            # meio passo enquanto o desvio nao cair
      lambda_novo <- lambda - passo / 2^k
      u_novo <- as.numeric(X %*% lambda_novo); w_novo <- d * g(u_novo); F_novo <- as.numeric(Matrix::crossprod(X, w_novo)) - totais
      erro_novo <- max(abs(F_novo) / totais)
      if(all(is.finite(w_novo)) && all(w_novo > 0) && is.finite(erro_novo) && erro_novo < erro){
        melhorou <- TRUE
        break
      }
    }
    if(!melhorou) stop("calibracao nao convergiu: busca de passo sem reducao do residuo; erro ", signif(erro, 3))
    lambda <- lambda_novo; u <- u_novo; w <- w_novo; F <- F_novo; erro <- erro_novo
  }
  if(!is.finite(erro) || erro > tolerancia)
    stop("calibracao nao convergiu em ", max_iter, " iteracoes; erro ", signif(erro, 3))
  if(any(!is.finite(w)) || any(w <= 0)) stop("pesos finais nao finitos ou nao positivos")
  if(!is.null(limites) && any(w / d < L - tolerancia | w / d > U + tolerancia))
    stop("pesos finais fora dos limites da calibracao")
  message("  Newton: ", it, " iteracoes; desvio maximo ", signif(erro, 3),
          "; fator g: min ", round(min(w / d), 3), " mediana ", round(median(w / d), 3), " max ", round(max(w / d), 3))
  w
}

calibrate_1960_amostra_127 <- function(tabelas, gabarito_path, definitivos_path){

  message("Calibrating household weights to the definitive results (Serie Nacional) and to the 1965 preliminary results")

  pessoas    <- data.table::copy(tabelas$pessoas)
  domicilios <- data.table::copy(tabelas$domicilios)
  gab <- data.table::fread(gabarito_path, encoding = "UTF-8")
  def <- data.table::fread(definitivos_path, encoding = "UTF-8")[nivel == "uf"]
  if(anyDuplicated(gab[, .(quadro, regiao, linha, coluna)])) stop("chave duplicada no gabarito preliminar da calibracao")
  if(anyNA(domicilios$censobr_idhousehold) || anyDuplicated(domicilios$censobr_idhousehold))
    stop("identificadores ausentes ou duplicados nos domicilios da calibracao")
  if(any(!pessoas$censobr_idhousehold %in% domicilios$censobr_idhousehold)) stop("pessoas sem domicilio na calibracao")

  regiao_uf <- REGIAO_1960
  faixas <- c("0 a 4", "5 a 9", "10 a 14", "15 a 19", "20 a 24", "25 a 29", "30 a 39", "40 a 49", "50 a 59", "60 a 69", "70 e mais e ignorada")
  pessoas[, regiao   := regiao_uf[as.character(UF)]]
  pessoas[, situacao := data.table::fifelse(V118 %in% c(1, 3), "urbana", data.table::fifelse(V118 %in% 5, "rural", NA_character_))]
  pessoas[, sexo     := data.table::fifelse(V202 %in% c(1, 3, 5), "homens", data.table::fifelse(V202 %in% c(2, 4, 6), "mulheres", NA_character_))]
  pessoas[, idade := data.table::fifelse(V204 %in% 1 & V204B %in% 0:99, V204B,
                    data.table::fifelse(V204 %in% 0 & V204B %in% 0:99, 0L,
                    data.table::fifelse(V204 %in% 5, 100L, NA_integer_)))]
  pessoas[, faixa    := faixas[findInterval(idade, c(0, 5, 10, 15, 20, 25, 30, 40, 50, 60, 70))]]
  pessoas[V204 %in% 9, faixa := "70 e mais e ignorada"]
  pessoas[, presente := V202 %in% c(1, 2, 5, 6)]
  if(any(!pessoas$V202 %in% 1:6)) stop("presenca desconhecida em controles da calibracao preliminar")
  if(any(pessoas$presente & !pessoas$V118 %in% c(1, 3, 5)))
    stop("situacao desconhecida em controles da calibracao preliminar")
  dano <- pessoas[presente == TRUE & is.na(idade) & !V204 %in% 9]
  if(nrow(dano)) stop("idade danificada em controles da calibracao; resolver ou explicitar a politica antes do ajuste: linhas ",
                     paste(head(dano$linha, 10L), collapse = ", "))
  pessoas[, alfabetizacao := data.table::fifelse(V211 %in% c(0, 1), "sabem", data.table::fifelse(V211 %in% c(2, 3), "nao_sabem", NA_character_))]
  if(any(pessoas$presente & ((!is.na(pessoas$idade) & pessoas$idade >= 5) | pessoas$V204 %in% 9) &
         !pessoas$V211 %in% 0:4)) stop("alfabetizacao desconhecida em controles da calibracao preliminar")
  hh <- sort(unique(domicilios$censobr_idhousehold))
  d <- rep(1 / 0.0127, length(hh))

  # --- 1965: regiao x situacao x sexo x faixa (quadro 1) e quem sabe ler, por sexo e regiao (quadro 2)
  pessoas[, celula := paste("q1", regiao, situacao, sexo, faixa, sep = "|")]
  g1 <- gab[quadro == 1 & regiao != "Brasil" & linha != "TOTAIS" & coluna %in% c("urbana_homens", "urbana_mulheres", "rural_homens", "rural_mulheres")]
  g1[, celula := paste("q1", regiao, sub("_.*", "", coluna), sub(".*_", "", coluna), linha, sep = "|")]
  g2 <- gab[quadro == 2 & regiao != "Brasil" & linha == "5 e mais" & coluna %in% c("sabem_homens", "sabem_mulheres")]
  g2[, celula := paste("q2", regiao, sub("_[a-z]+$", "", coluna), sub(".*_", "", coluna), sep = "|")]
  pessoas[, celula_q2 := data.table::fifelse(presente & ((!is.na(idade) & idade >= 5) | V204 %in% 9) & alfabetizacao %in% "sabem" & !is.na(sexo), paste("q2", regiao, alfabetizacao, sexo, sep = "|"), NA_character_)]
  celulas <- c(g1$celula, g2$celula); totais <- c(g1$valor, g2$valor)
  if(anyDuplicated(celulas)) stop("celula duplicada nos controles preliminares da calibracao")
  cont <- rbind(pessoas[presente == TRUE & !is.na(situacao) & !is.na(sexo) & !is.na(faixa), .N, by = .(censobr_idhousehold, celula)],
                pessoas[!is.na(celula_q2), .N, by = .(censobr_idhousehold, celula = celula_q2)])
  if(any(!cont$celula %in% celulas)) stop("celulas da amostra sem controle preliminar publicado")
  X <- Matrix::sparseMatrix(i = match(cont$censobr_idhousehold, hh), j = match(cont$celula, celulas), x = cont$N,
                           dims = c(length(hh), length(celulas)), dimnames = list(NULL, celulas))
  message("  1965: ", length(celulas), " celulas (quadro 1: ", nrow(g1), "; quadro 2: ", nrow(g2), ")")
  w1965 <- raking_1960_amostra_127(X, totais, d)

  # --- definitivos: as celulas estao em celulas_definitivos_1960_amostra_127, que o passo 11 tambem usa
  cal <- celulas_definitivos_1960_amostra_127(tabelas$pessoas, domicilios, def)
  alvos <- cal$alvos
  message("  definitivos: ", nrow(alvos), " celulas (", paste0(alvos[, .N, by = .(bloco = substr(celula, 1, 1))][, paste(bloco, N)], collapse = ", "),
          "); razao publicado / soma pela base definitiva fora de [0,5; 2]: ", paste0(alvos[implicito < 0.5 | implicito > 2, paste0(celula, "=", implicito)], collapse = " "))
  # o peso de desenho de Fernando de Noronha e 4, nao 78,74: a sua unica pasta era o cadastro inteiro (a amostra de
  # 25% mostra uma pasta em vez de vinte), so houve a etapa de um domicilio em quatro. Nas outras unidades ficam
  # os 78,74. Os fatores ficam entre 0,3 e 3,5 (distancia logit); o raking puro dava ate 9 em Rondonia.
  d_def <- d; d_def[hh %in% domicilios[UF == 24, censobr_idhousehold]] <- 4
  w <- raking_1960_amostra_127(cal$X, alvos$total, d_def, limites = c(0.3, 3.5))

  # A base final e a usada pelo solver definitivo. O fator de 1965 conserva
  # sua base preliminar d; em Fernando de Noronha as duas bases sao diferentes.
  pesos <- data.table::data.table(censobr_idhousehold = hh, censobr_weight = w, censobr_weight_fator = w / d_def,
                                  censobr_weight_desenho = d_def, censobr_weight_1965 = w1965, censobr_weight_1965_fator = w1965 / d)
  domicilios[pesos, `:=`(censobr_weight = i.censobr_weight, censobr_weight_fator = i.censobr_weight_fator, censobr_weight_desenho = i.censobr_weight_desenho,
                        censobr_weight_1965 = i.censobr_weight_1965, censobr_weight_1965_fator = i.censobr_weight_1965_fator), on = "censobr_idhousehold"]
  pessoas[pesos,    `:=`(censobr_weight = i.censobr_weight, censobr_weight_fator = i.censobr_weight_fator, censobr_weight_desenho = i.censobr_weight_desenho,
                        censobr_weight_1965 = i.censobr_weight_1965, censobr_weight_1965_fator = i.censobr_weight_1965_fator), on = "censobr_idhousehold"]
  fator_uf <- domicilios[, .(fator = round(median(censobr_weight_fator), 2)), by = UF][order(UF)]
  message("  fator mediano do peso final por UF: ", paste0(fator_uf$UF, "=", fator_uf$fator, collapse = " "))

  pessoas[, c("regiao", "situacao", "sexo", "idade", "faixa", "presente", "alfabetizacao", "celula", "celula_q2") := NULL]
  colunas <- c("censobr_weight", "censobr_weight_fator", "censobr_weight_1965", "censobr_weight_1965_fator", "censobr_weight_desenho")
  data.table::setcolorder(pessoas,    c(names(pessoas)[seq_len(match("censobr_weight", names(pessoas)))], colunas[-1]))
  data.table::setcolorder(domicilios, c(names(domicilios)[seq_len(match("censobr_weight", names(domicilios)))], colunas[-1]))
  list(pessoas = pessoas, domicilios = domicilios)
}


# ------------------------------------------------------------------------------
# Passo 10 — reprodução dos sete quadros de 1965 (validação)
#
# As diferencas numericas comentadas abaixo sao historicas, anteriores a
# revisao de 22/09/2026. A nova validacao nao foi executada nem homologada.
# Preserva a grade regional publicada, inclusive celulas sem observacoes e
# quesitos que nao sao reconstruidos. Fechar uma margem usada na calibracao
# verifica o ajuste numerico, nao valida independentemente o arquivo: no peso
# de 1965 sao restricoes as 176 celulas do quadro 1 e oito totais de leitores
# do quadro 2. O quadro 5 NAO e restricao. Os pesos nao sao recalculados aqui.
# V202 desconhecido nao recebe sexo nem condicao de presenca. Idade declarada
# ignorada (V204=9) entra nas faixas publicadas dos quadros 1/2 e nos totais
# de atividade/renda (3/4), conforme as identidades da publicacao preliminar.
# No quadro 5, de residentes, a elegibilidade continua pendente.
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
# Estas operacoes sao compartilhadas pelas duas validacoes.
# n conta a unidade da medida (pessoas ou domicilios), mesmo depois de agregar.
# Um peso ausente/nao finito nunca se transforma em zero por sum(na.rm=TRUE).
somar_validacao_1960_amostra_127 <- function(w, n = rep.int(1L, length(w)),
                                          ausentes = as.integer(!is.finite(w))){
  faltam <- sum(ausentes)
  list(nosso = if(faltam > 0L) NA_real_ else sum(w),
       n_amostra = sum(n), n_pesos_ausentes = faltam)
}

completar_validacao_1960_amostra_127 <- function(gabarito, nosso, chaves){
  if(anyDuplicated(gabarito[, ..chaves])) stop("chave duplicada no gabarito da validacao")
  if(anyDuplicated(nosso[, ..chaves])) stop("chave duplicada na agregacao da validacao")
  comp <- merge(gabarito, nosso, by = chaves, all.x = TRUE, sort = FALSE)
  if(!"n_sem_classificacao" %in% names(comp)) comp[, n_sem_classificacao := 0L]
  comp[reconstruivel & is.na(n_amostra), `:=`(nosso = 0, n_amostra = 0L, n_pesos_ausentes = 0L)]
  comp[reconstruivel == FALSE, `:=`(nosso = NA_real_, n_amostra = NA_integer_, n_pesos_ausentes = NA_integer_, n_sem_classificacao = NA_integer_)]
  comp[, valor_parcial := nosso]
  comp[reconstruivel & n_sem_classificacao > 0L, nosso := NA_real_]
  comp[, status_celula := data.table::fifelse(!reconstruivel, "nao_reconstruida",
    data.table::fifelse(n_pesos_ausentes > 0L, "peso_ausente",
      data.table::fifelse(n_sem_classificacao > 0L, "classificacao_incompleta",
        data.table::fifelse(n_amostra == 0L, "sem_observacoes", "observada"))))]
  comp[, `:=`(dif_abs = NA_real_, dif_pct = NA_real_)]
  comp[reconstruivel & n_pesos_ausentes == 0L & n_sem_classificacao == 0L, dif_abs := nosso - publicado]
  comp[reconstruivel & n_pesos_ausentes == 0L & n_sem_classificacao == 0L & publicado != 0,
       dif_pct := 100 * (nosso / publicado - 1)]
  comp[, dif_pct := round(dif_pct, 2)]
  comp
}

# Conta registros distintos em cada pendencia; a mesma pendencia pode afetar
# varias categorias. Nao somar esta coluna entre celulas do relatorio.
pendencias_validacao_1960_amostra_127 <- function(dados, pendente, grade, geografia, por_sexo = FALSE){
  grupos <- c(geografia, if(por_sexo) "sexo")
  z <- dados[which(pendente %in% TRUE), .(n_sem_classificacao = .N), by = grupos]
  if(por_sexo){
    total <- z[, .(n_sem_classificacao = sum(n_sem_classificacao)), by = geografia][, sexo := "total"]
    z <- rbind(z[!is.na(sexo)], data.table::copy(z[is.na(sexo)])[, sexo := "homens"],
               data.table::copy(z[is.na(sexo)])[, sexo := "mulheres"], total)
    z <- z[, .(n_sem_classificacao = sum(n_sem_classificacao)), by = grupos]
  }
  # Geografia perdida pode afetar qualquer unidade, nao apenas uma linha NA.
  sem_geo <- z[is.na(get(geografia))]
  z <- z[!is.na(get(geografia))]
  if(nrow(sem_geo)){
    z <- rbind(z, data.table::rbindlist(lapply(unique(grade[[geografia]]), function(local){
      a <- data.table::copy(sem_geo); a[, (geografia) := local]; a
    })))
    z <- z[, .(n_sem_classificacao = sum(n_sem_classificacao)), by = grupos]
  }
  n <- z[grade, on = grupos, n_sem_classificacao]
  n[is.na(n)] <- 0L
  n
}

classificar_domicilios_validacao_1960_amostra_127 <- function(pessoas, domicilios){
  d <- data.table::copy(domicilios)
  lista <- pessoas[, .(n_lista = .N, n_residentes_confirmados = sum(V202 %in% 1:4),
                       n_presenca_incerta = sum(!V202 %in% 1:6)), by = censobr_idhousehold]
  d[, `:=`(n_lista = 0L, n_residentes_confirmados = 0L, n_presenca_incerta = 0L)]
  d[lista, `:=`(n_lista = i.n_lista, n_residentes_confirmados = i.n_residentes_confirmados,
               n_presenca_incerta = i.n_presenca_incerta), on = "censobr_idhousehold"]
  d[, somente_nao_moradores := n_lista > 0L & n_residentes_confirmados == 0L & n_presenca_incerta == 0L]
  d[, ocupacao_incerta := n_lista == 0L | (n_residentes_confirmados == 0L & n_presenca_incerta > 0L)]
  d
}

# Preliminares, impresso IV (PDF 8): inativos dependem do ramo do chefe da
# familia. Os codigos validos de ramo estao no Codigo, impressos 18-22.
classificar_dependencia_validacao_1960_amostra_127 <- function(pessoas){
  p <- data.table::copy(pessoas)
  ramos_validos <- c(111:123, 129, 151:153, 191, 211:216, 219, 251:256, 259, 291:292,
    311:318, 321:328, 331:337, 339, 351, 391:392, 411:418, 421:424, 429, 451:455, 459,
    511:519, 611:618, 621:622, 629, 711:718, 721:722, 729, 751:757, 759,
    811:816, 819, 851:856, 859, 911:912, 919)
  p[, grupo_proprio := NA_character_]
  p[V220 %in% c(0, 1, 4:9), grupo_proprio := "inativas"]
  p[V220 %in% 2:3 & V223B %in% ramos_validos,
    grupo_proprio := data.table::fifelse(V223B < 300, "agro", data.table::fifelse(V223B < 400, "ind", "outras"))]
  chefes <- p[V203 %in% 7 & !is.na(censobr_idfamily), .(n_chefes = .N,
    grupo_chefe = if(.N == 1L) grupo_proprio[1L] else NA_character_,
    presenca_chefe = if(.N == 1L) V202[1L] else NA_integer_,
    domicilio_chefe = if(.N == 1L) as.character(censobr_idhousehold[1L]) else NA_character_),
    by = .(UF, censobr_idfamily)]
  p[, `:=`(n_chefes = 0L, grupo_chefe = NA_character_, presenca_chefe = NA_integer_,
            domicilio_chefe = NA_character_)]
  p[chefes, `:=`(n_chefes = i.n_chefes, grupo_chefe = i.grupo_chefe,
    presenca_chefe = i.presenca_chefe, domicilio_chefe = i.domicilio_chefe), on = .(UF, censobr_idfamily)]
  p[, grupo_dependencia := grupo_proprio]
  p[V220 %in% c(0, 1, 4:9), grupo_dependencia := NA_character_]
  p[V220 %in% c(0, 1, 4:9) & n_chefes == 1L & presenca_chefe %in% 1:4 &
      !is.na(censobr_idhousehold) & domicilio_chefe == as.character(censobr_idhousehold),
    grupo_dependencia := grupo_chefe]
  p[, motivo_dependencia := data.table::fcase(
    !V220 %in% 0:9, "atividade_sem_classificacao",
    V220 %in% 2:3 & is.na(grupo_proprio), "ramo_proprio_sem_classificacao",
    V220 %in% c(0, 1, 4:9) & n_chefes == 0L, "familia_sem_chefe",
    V220 %in% c(0, 1, 4:9) & n_chefes > 1L, "familia_com_multiplos_chefes",
    V220 %in% c(0, 1, 4:9) & !presenca_chefe %in% 1:4, "chefe_sem_residencia_confirmada",
    V220 %in% c(0, 1, 4:9) & (is.na(censobr_idhousehold) | is.na(domicilio_chefe) |
      domicilio_chefe != as.character(censobr_idhousehold)), "chefe_domicilio_incompativel",
    V220 %in% c(0, 1, 4:9) & is.na(grupo_chefe), "ramo_chefe_sem_classificacao",
    default = "classificada")]
  p[, c("grupo_proprio", "grupo_chefe", "presenca_chefe", "domicilio_chefe", "n_chefes") := NULL]
  p
}

diagnosticar_universos_1960_amostra_127 <- function(pessoas, domicilios){
  p <- data.table::copy(pessoas)
  d <- classificar_domicilios_validacao_1960_amostra_127(p, domicilios)
  motivos <- list(
    geografia_nao_classificavel = !p$UF %in% as.integer(names(REGIAO_1960)),
    presenca_sexo_desconhecidos = !p$V202 %in% 1:6,
    situacao_desconhecida = !p$V118 %in% c(1, 3, 5),
    idade_declarada_ignorada = p$V204 %in% 9,
    idade_nao_classificavel = !(p$V204 %in% c(0, 1, 5, 9)) |
      (p$V204 %in% c(0, 1) & !(p$V204B %in% 0:99)),
    cor_nao_classificavel = !p$V206 %in% 4:9,
    cor_india_agregada_em_pardos = p$V206 %in% 8,
    alfabetizacao_declarada_ignorada = p$V211 %in% 4,
    alfabetizacao_sem_classificacao = !p$V211 %in% 0:4,
    atividade_sem_classificacao = !p$V220 %in% 0:9,
    ocupacao_semana_sem_classificacao = p$V220 %in% 2:3 & !p$V223 %in% 2:5,
    ativo_sem_ramo = p$V220 %in% 2:3 & is.na(p$V223B))
  if("motivo_dependencia" %in% names(p)){
    for(motivo in setdiff(unique(p$motivo_dependencia), "classificada"))
      motivos[[paste0("q5_", motivo)]] <- p$V202 %in% 1:4 & p$idade >= 15 & p$motivo_dependencia == motivo
    motivos$q5_idade_ignorada_elegibilidade_pendente <- p$V202 %in% 1:4 & p$V204 %in% 9
  }
  motivos_dom <- list(geografia_nao_classificavel = !d$UF %in% as.integer(names(REGIAO_1960)),
    tipo_domicilio_desconhecido = !d$V101 %in% c(1:5, 9),
    permanencia_desconhecida = !d$V102 %in% 4:6, sem_lista_pessoas = d$n_lista == 0L,
    presenca_residentes_incerta = d$n_presenca_incerta > 0L,
    somente_nao_moradores = d$somente_nao_moradores,
    agua_declarada_ignorada = d$V105 %in% 4,
    agua_salto_improvisado = d$V102 %in% 6 & is.na(d$V105),
    agua_sem_classificacao = !d$V102 %in% 6 & !d$V105 %in% c(0:4, 9),
    aluguel_declarado_ignorado = d$V103 %in% 8 & d$V104 %in% 9,
    aluguel_sem_classificacao = d$V103 %in% 8 & !d$V104 %in% c(0:7, 9),
    condicao_domicilio_sem_classificacao = !d$V102 %in% 6 & !d$V103 %in% c(0, 7:9))
  data.table::rbindlist(lapply(c("censobr_weight", "censobr_weight_1965"), function(peso){
    rbind(data.table::rbindlist(lapply(names(motivos), function(motivo){
      p[motivos[[motivo]], somar_validacao_1960_amostra_127(get(peso)), by = UF][,
        `:=`(peso = peso, unidade = "pessoas", motivo = motivo)]
    })), data.table::rbindlist(lapply(names(motivos_dom), function(motivo){
      d[motivos_dom[[motivo]], somar_validacao_1960_amostra_127(get(peso)), by = UF][,
        `:=`(peso = peso, unidade = "domicilios", motivo = motivo)]
    })), fill = TRUE)
  }))
}

validate_1965_1960_amostra_127 <- function(tabelas, gabarito_path,
                                        out_dir = "./data_raw/microdata/1960/amostra_127"){

  message("Comparing the seven 1965 tables with the calibrated file, with each of the two weights")

  p0 <- data.table::copy(tabelas$pessoas); d0 <- data.table::copy(tabelas$domicilios)
  gab <- data.table::fread(gabarito_path, encoding = "UTF-8")[regiao != "Brasil"]
  regiao_uf <- REGIAO_1960
  # A declaracao adicional permite informar uma UF fornecida com zero registros.
  ufs_pessoas <- unique(c(p0$UF, tabelas$ufs_fornecidas))
  ufs_domicilios <- unique(c(d0$UF, tabelas$ufs_fornecidas))
  regioes_pessoas <- names(which(tapply(as.integer(names(regiao_uf)) %in% ufs_pessoas, regiao_uf, all)))
  regioes_domicilios <- names(which(tapply(as.integer(names(regiao_uf)) %in% ufs_domicilios, regiao_uf, all)))
  p0[, regiao := regiao_uf[as.character(UF)]]
  p0[, presente := V202 %in% c(1, 2, 5, 6)]; p0[, residente := V202 %in% 1:4]
  p0[, sexo := data.table::fifelse(V202 %in% c(1, 3, 5), "homens",
                                data.table::fifelse(V202 %in% c(2, 4, 6), "mulheres", NA_character_))]
  p0[, idade := data.table::fifelse(V204 %in% 1 & V204B %in% 0:99, V204B,
                   data.table::fifelse(V204 %in% 0 & V204B %in% 0:99, 0L,
                   data.table::fifelse(V204 %in% 5, 100L, NA_integer_)))]
  p0[, idade_ignorada := V204 %in% 9]
  p0[, idade_danificada := is.na(idade) & !idade_ignorada]
  p0 <- classificar_dependencia_validacao_1960_amostra_127(p0)
  diagnostico <- diagnosticar_universos_1960_amostra_127(p0, d0)

  comp <- data.table::rbindlist(lapply(c("censobr_weight", "censobr_weight_1965"), function(peso){
  p <- data.table::copy(p0); d <- data.table::copy(d0)
  p[, w := get(peso)]; d[, w := get(peso)]

  # quadro 1: presentes por situacao, sexo e faixa etaria
  faixa1 <- c("0 a 4", "5 a 9", "10 a 14", "15 a 19", "20 a 24", "25 a 29", "30 a 39", "40 a 49", "50 a 59", "60 a 69", "70 e mais e ignorada")
  q1 <- p[presente == TRUE]; q1[, linha := faixa1[findInterval(idade, c(0, 5, 10, 15, 20, 25, 30, 40, 50, 60, 70))]]
  q1[idade_ignorada == TRUE, linha := "70 e mais e ignorada"]
  q1[, situacao := data.table::fifelse(V118 %in% c(1, 3), "urbana", data.table::fifelse(V118 %in% 5, "rural", NA_character_))]
  n1 <- rbind(q1[, somar_validacao_1960_amostra_127(w), by = .(regiao, linha)][, coluna := "total"],
              q1[, somar_validacao_1960_amostra_127(w), by = .(regiao, linha, coluna = sexo)],
              q1[!is.na(situacao), somar_validacao_1960_amostra_127(w), by = .(regiao, linha, coluna = situacao)],
              q1[!is.na(situacao), somar_validacao_1960_amostra_127(w), by = .(regiao, linha, coluna = paste0(situacao, "_", sexo)[seq_along(sexo)])])
  n1 <- rbind(n1, n1[, somar_validacao_1960_amostra_127(nosso, n_amostra, n_pesos_ausentes), by = .(regiao, coluna)][, linha := "TOTAIS"])[, quadro := 1L]

  # quadro 2: alfabetizacao, presentes de 5 anos e mais
  q2 <- p[presente == TRUE & (idade >= 5 | idade_ignorada)]
  q2[, faixa := c("5 a 6", "7 a 12", "13 a 19", "20 a 24", "25 a 29", "30 a 39", "40 a 49", "50 a 59", "60 e mais e ignorada")[findInterval(idade, c(5, 7, 13, 20, 25, 30, 40, 50, 60))]]
  q2[idade_ignorada == TRUE, faixa := "60 e mais e ignorada"]
  q2[, alf := data.table::fifelse(V211 %in% c(0, 1), "sabem", data.table::fifelse(V211 %in% c(2, 3), "nao_sabem", "sem_declaracao"))]
  q2 <- rbind(q2[, .(regiao, linha = faixa, sexo, alf, w)], q2[, .(regiao, linha = "5 e mais", sexo, alf, w)],
              q2[idade >= 10 | idade_ignorada, .(regiao, linha = "10 e mais", sexo, alf, w)],
              q2[idade >= 15 | idade_ignorada, .(regiao, linha = "15 e mais", sexo, alf, w)])
  n2 <- rbind(q2[, somar_validacao_1960_amostra_127(w), by = .(regiao, linha)][, coluna := "total"], q2[, somar_validacao_1960_amostra_127(w), by = .(regiao, linha, coluna = sexo)],
              q2[alf != "sem_declaracao", somar_validacao_1960_amostra_127(w), by = .(regiao, linha, coluna = alf)],
              q2[alf != "sem_declaracao", somar_validacao_1960_amostra_127(w), by = .(regiao, linha, coluna = paste0(alf, "_", sexo)[seq_along(sexo)])])[, quadro := 2L]

  # A publicacao conserva a idade declarada ignorada em atividade e renda.
  # Dano de idade continua pendente; nao recebe uma idade presumida.
  q3 <- p[presente == TRUE & (idade >= 10 | idade_ignorada)]
  q3[, ramo := NA_character_]
  q3[V220 %in% c(0, 1, 4:9), ramo := "condicoes_inativas"]
  q3[V220 %in% 2:3 & V223 %in% 2:5 & !is.na(V223B), ramo := data.table::fifelse(V223 %in% 4:5, "outras_atividades", data.table::fifelse(V223B < 200, "agricultura_pecuaria_silvicultura",
              data.table::fifelse(V223B < 300, "industrias_extrativas", data.table::fifelse(V223B <= 339, "industrias_transformacao",
              data.table::fifelse(V223B == 351, "industrias_construcao", data.table::fifelse(V223B %in% 411:429, "comercio_mercadorias",
              data.table::fifelse(V223B %in% 611:629, "transportes_comunicacoes_armazenagem", data.table::fifelse(V223B %in% 511:519, "prestacao_servicos", "outras_atividades"))))))))]
  q3[V220 %in% 2:3 & V223 %in% 4:5, ramo := "outras_atividades"]
  q3[, grupo := NA_character_]
  q3[V220 %in% c(0, 1, 4:9), grupo := "inativas"]
  q3[V220 %in% 2:3 & !is.na(V223B), grupo := data.table::fifelse(V223B < 300, "agro", data.table::fifelse(V223B < 400, "ind", "outras"))]
  q3[, renda := c("10001_20000", "20001_mais", "20001_mais", "sem_rendimento", "sem_declaracao", "ate_2100", "2101_3300", "3301_4500", "4501_6000", "6001_10000")[match(V219, 0:9)]]
  n3 <- rbind(q3[, somar_validacao_1960_amostra_127(w), by = .(regiao, linha = ramo)][, coluna := "total"], q3[, somar_validacao_1960_amostra_127(w), by = .(regiao, linha = ramo, coluna = sexo)],
              q3[, somar_validacao_1960_amostra_127(w), by = regiao][, `:=`(linha = "TOTAIS", coluna = "total")], q3[, somar_validacao_1960_amostra_127(w), by = .(regiao, coluna = sexo)][, linha := "TOTAIS"])[, quadro := 3L]
  n4 <- rbind(q3[, somar_validacao_1960_amostra_127(w), by = .(regiao, linha = renda)][, coluna := "total"], q3[, somar_validacao_1960_amostra_127(w), by = .(regiao, linha = renda, coluna = paste0(grupo, "_", sexo)[seq_along(sexo)])],
              q3[, somar_validacao_1960_amostra_127(w), by = regiao][, `:=`(linha = "TOTAIS", coluna = "total")], q3[, somar_validacao_1960_amostra_127(w), by = .(regiao, coluna = paste0(grupo, "_", sexo)[seq_along(sexo)])][, linha := "TOTAIS"])[, quadro := 4L]

  # quadro 5: residentes de 15 anos e mais; inativos herdam o ramo do chefe.
  q5 <- p[residente == TRUE & idade >= 15]
  q5[, linha := c("solteiros", "separados", "outros", "outros", "viuvos", "outros", "casados_civil_religioso", "casados_somente_civil", "casados_somente_religioso", "casados_sem_vinculo")[match(V215, 0:9)]]
  q5 <- rbind(q5[, .(regiao, linha, sexo, grupo_dependencia, w)],
    q5[grepl("^casados", linha), .(regiao, linha = "casados", sexo, grupo_dependencia, w)],
    q5[, .(regiao, linha = "TOTAIS", sexo, grupo_dependencia, w)])
  n5 <- rbind(q5[, somar_validacao_1960_amostra_127(w), by = .(regiao, linha)][, coluna := "total"],
    q5[!is.na(grupo_dependencia), somar_validacao_1960_amostra_127(w),
      by = .(regiao, linha, coluna = paste0(grupo_dependencia, "_", sexo)[seq_along(sexo)])])[, quadro := 5L]

  # quadros 6 e 7: domicilios particulares ocupados e residentes
  d <- classificar_domicilios_validacao_1960_amostra_127(p, d)
  d[, regiao := regiao_uf[as.character(UF)]]; d[, situacao := data.table::fifelse(V118 %in% c(1, 3), "urbana", data.table::fifelse(V118 %in% 5, "rural", NA_character_))]
  dp <- d[V101 %in% c(1, 2, 4, 5) & !somente_nao_moradores]
  res <- p[residente == TRUE, somar_validacao_1960_amostra_127(w), by = censobr_idhousehold]
  dp[, `:=`(res = 0, n_res = 0L, n_res_pesos_ausentes = 0L)]
  dp[res, `:=`(res = i.nosso, n_res = i.n_amostra, n_res_pesos_ausentes = i.n_pesos_ausentes), on = "censobr_idhousehold"]
  itens <- list(TOTAIS = quote(TRUE), proprios = quote(V103 %in% 7), alugados = quote(V103 %in% 8), outra_condicao = quote(V103 %in% 9),
                sem_declaracao = quote(V103 %in% 0),
                ate_500 = quote(V103 %in% 8 & V104 %in% 0),
                `501_1000` = quote(V103 %in% 8 & V104 %in% 1),
                `1001_2000` = quote(V103 %in% 8 & V104 %in% 2),
                `2001_4000` = quote(V103 %in% 8 & V104 %in% 3),
                `4001_6000` = quote(V103 %in% 8 & V104 %in% 4),
                `6001_mais` = quote(V103 %in% 8 & V104 %in% 5:7),
                agua_rede_geral = quote(V105 %in% c(9, 0)), agua_poco_nascente = quote(V105 %in% c(1, 2)), agua_outra_sem_declaracao = quote(V105 %in% c(3, 4)),
                fogao_lenha = quote(V107 %in% 9), fogao_carvao = quote(V107 %in% 0), fogao_gas = quote(V107 %in% 2), fogao_oleo_querosene = quote(V107 %in% 3),
                instalacao_sanitaria = quote(V106 %in% 4:7), iluminacao_eletrica = quote(V108 %in% 5), radio = quote(V109 %in% 7), geladeira = quote(V110 %in% 9))
  n67 <- data.table::rbindlist(lapply(names(itens), function(nm){ z <- dp[eval(itens[[nm]]) & (nm == "TOTAIS" | !V102 %in% 6)]
    rbind(z[, somar_validacao_1960_amostra_127(w), by = regiao][, `:=`(linha = nm, coluna = "dom_total")],
          z[, somar_validacao_1960_amostra_127(res, n_res, n_res_pesos_ausentes), by = regiao][, `:=`(linha = nm, coluna = "pes_total")],
          z[!is.na(situacao), somar_validacao_1960_amostra_127(w), by = .(regiao, situacao)][, `:=`(linha = nm, coluna = paste0("dom_", situacao))][, -"situacao"],
          z[!is.na(situacao), somar_validacao_1960_amostra_127(res, n_res, n_res_pesos_ausentes), by = .(regiao, situacao)][, `:=`(linha = nm, coluna = paste0("pes_", situacao))][, -"situacao"]) }))
  linhas_aluguel <- c("ate_500", "501_1000", "1001_2000", "2001_4000", "4001_6000", "6001_mais")
  n67[, quadro := data.table::fifelse(linha %in% c("proprios", "alugados", "outra_condicao", "sem_declaracao", linhas_aluguel), 6L, 7L)]
  n6t <- n67[linha == "TOTAIS"][, quadro := 6L]

  nosso <- rbind(n1, n2, n3, n4, n5, n67, n6t)
  grade <- gab[, .(quadro, regiao, linha, coluna, publicado = valor)]
  grade[, cobertura_geografica_completa := data.table::fifelse(quadro %in% 6:7,
    regiao %in% regioes_domicilios, regiao %in% regioes_pessoas)]
  grade[, reconstruivel := cobertura_geografica_completa]
  grade[, `:=`(n_sem_classificacao = 0L, sexo = data.table::fifelse(grepl("homens$", coluna), "homens",
                       data.table::fifelse(grepl("mulheres$", coluna), "mulheres", "total")))]
  # Contagens conservadoras por regiao/sexo; nao se presume a categoria perdida.
  marcar <- function(linhas, pendente, dados = p, por_sexo = TRUE){
    grade[linhas, n_sem_classificacao := pendencias_validacao_1960_amostra_127(dados, pendente, .SD, "regiao", por_sexo)]
  }
  presenca_incerta <- !p$V202 %in% 1:6
  # UF perdida nao recebe uma regiao presumida. O registro potencialmente
  # elegivel torna parciais as regioes possiveis, sem distribuir seu peso.
  geografia_pessoal_incerta <- is.na(p$regiao)
  for(faixa_pendente in c(FALSE, TRUE)) for(situacao_pendente in c(FALSE, TRUE)){
    marcar(grade$quadro == 1L & (grade$linha != "TOTAIS") == faixa_pendente &
             grepl("urbana|rural", grade$coluna) == situacao_pendente,
           presenca_incerta | (p$presente & (geografia_pessoal_incerta | (faixa_pendente & p$idade_danificada) |
             (situacao_pendente & !p$V118 %in% c(1, 3, 5)))))
  }
  for(alf_pendente in c(FALSE, TRUE)){
    marcar(grade$quadro == 2L & grepl("sabem", grade$coluna) == alf_pendente,
           presenca_incerta | (p$presente & (p$idade_danificada |
             ((p$idade >= 5 | p$idade_ignorada) &
               (geografia_pessoal_incerta | (alf_pendente & !p$V211 %in% 0:4))))))
  }
  base_10 <- presenca_incerta | (p$presente & (p$idade_danificada |
    (geografia_pessoal_incerta & (p$idade >= 10 | p$idade_ignorada))))
  ramo_incerto <- p$presente & (p$idade >= 10 | p$idade_ignorada) & (!p$V220 %in% 0:9 |
    (p$V220 %in% 2:3 & (!p$V223 %in% 2:5 | (is.na(p$V223B) & !p$V223 %in% 4:5))))
  grupo_incerto <- p$presente & (p$idade >= 10 | p$idade_ignorada) & (!p$V220 %in% 0:9 |
    (p$V220 %in% 2:3 & is.na(p$V223B)))
  marcar(grade$quadro == 3L & grade$linha == "TOTAIS", base_10)
  marcar(grade$quadro == 3L & grade$linha != "TOTAIS", base_10 | ramo_incerto)
  for(renda_pendente in c(FALSE, TRUE)) for(grupo_pendente in c(FALSE, TRUE)){
    marcar(grade$quadro == 4L & (grade$linha != "TOTAIS") == renda_pendente &
             (grade$coluna != "total") == grupo_pendente,
           base_10 | (renda_pendente & p$presente & (p$idade >= 10 | p$idade_ignorada) & !p$V219 %in% 0:9) |
             (grupo_pendente & grupo_incerto))
  }
  base_15 <- presenca_incerta | (p$residente & (p$idade_danificada | p$idade_ignorada |
    (geografia_pessoal_incerta & p$idade >= 15)))
  for(conjugal_pendente in c(FALSE, TRUE)) for(dependencia_pendente in c(FALSE, TRUE)){
    marcar(grade$quadro == 5L & (grade$linha != "TOTAIS") == conjugal_pendente &
      (grade$coluna != "total") == dependencia_pendente,
      base_15 | (p$residente & p$idade >= 15 &
        ((conjugal_pendente & !p$V215 %in% 0:9) |
         (dependencia_pendente & is.na(p$grupo_dependencia)))))
  }
  quesitos <- list(TOTAIS = rep(FALSE, nrow(d)), proprios = !d$V103 %in% c(0, 7:9),
    alugados = !d$V103 %in% c(0, 7:9), outra_condicao = !d$V103 %in% c(0, 7:9),
    sem_declaracao = !d$V103 %in% c(0, 7:9),
    agua_rede_geral = !d$V105 %in% c(0:4, 9), agua_poco_nascente = !d$V105 %in% c(0:4, 9),
    agua_outra_sem_declaracao = !d$V105 %in% c(0:4, 9),
    fogao_lenha = !d$V107 %in% c(0:5, 9), fogao_carvao = !d$V107 %in% c(0:5, 9),
    fogao_gas = !d$V107 %in% c(0:5, 9), fogao_oleo_querosene = !d$V107 %in% c(0:5, 9),
    instalacao_sanitaria = !d$V106 %in% 4:9, iluminacao_eletrica = !d$V108 %in% 5:7,
    radio = !d$V109 %in% 7:9, geladeira = !d$V110 %in% c(0:1, 9))
  for(nm in linhas_aluguel) quesitos[[nm]] <- !d$V103 %in% c(0, 7:9) |
    (d$V103 %in% 8 & !d$V104 %in% c(0:7, 9))
  for(nm in names(quesitos)) for(pessoas_pendentes in c(FALSE, TRUE)) for(situacao_pendente in c(FALSE, TRUE)){
    incerto <- !d$V101 %in% c(1:5, 9) | (d$V101 %in% c(1, 2, 4, 5) & !d$somente_nao_moradores &
      (d$ocupacao_incerta | is.na(d$regiao) | (pessoas_pendentes & d$n_presenca_incerta > 0L) |
       (!d$V102 %in% 6 & quesitos[[nm]]) | (situacao_pendente & !d$V118 %in% c(1, 3, 5))))
    marcar(grade$quadro %in% 6:7 & grade$linha == nm & grepl("^pes_", grade$coluna) == pessoas_pendentes &
             grepl("urbana|rural", grade$coluna) == situacao_pendente, incerto, d, FALSE)
  }
  grade[, sexo := NULL]
  comp <- completar_validacao_1960_amostra_127(grade, nosso, c("quadro", "regiao", "linha", "coluna"))
  comp[, unidade_sem_classificacao := data.table::fifelse(quadro %in% 6:7, "domicilios", "pessoas")]
  comp[, politica_classificacao := "pendencias conservadoras por regiao/sexo; repetidas nas categorias potencialmente afetadas; nao somar entre celulas"]
  comp[, politica_geografia := "UF ausente ou fora do dicionario: sem regiao atribuida; pendencia conservadora no universo potencial; peso nao distribuido entre regioes"]
  comp[, politica_idade := data.table::fifelse(quadro == 1L, "ignorada declarada na faixa final publicada",
    data.table::fifelse(quadro == 2L, "ignorada declarada na faixa final e agregados 5+/10+/15+ por convencao de divulgacao",
      data.table::fifelse(quadro %in% 3:4, "ignorada declarada incluida: identidade dos totais preliminares; idade danificada pendente",
        data.table::fifelse(quadro == 5L, "idade ignorada/danificada: inclusao pendente nesta fonte; soma conhecida parcial", "sem limite etario"))))]
  comp[, referencia_estimada := TRUE]
  comp[, politica_dependencia := data.table::fifelse(quadro == 5L,
    "ramo proprio quando codificado; inativos herdam chefe unico residente da mesma familia/domicilio; vinculo nao e certificado por esta comparacao", "nao se aplica")]
  comp[, peso := peso]
  comp
  }))
  data.table::setorder(comp, peso, quadro, regiao, linha, coluna)
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  data.table::fwrite(comp, file.path(out_dir, "calibracao_1965_validacao.csv"), bom = TRUE)
  data.table::fwrite(diagnostico, file.path(out_dir, "calibracao_1965_universos.csv"), bom = TRUE)
  resumo <- comp[, .(celulas = .N, observadas = sum(status_celula == "observada"),
    sem_observacoes = sum(status_celula == "sem_observacoes"), nao_reconstruidas = sum(status_celula == "nao_reconstruida"),
    classificacao_incompleta = sum(status_celula == "classificacao_incompleta"),
    peso_ausente = sum(status_celula == "peso_ausente"), percentuais_validos = sum(!is.na(dif_pct)),
    dif_mediana_abs = if(all(is.na(dif_pct))) NA_real_ else median(abs(dif_pct), na.rm = TRUE)), by = .(peso, quadro)]
  message(paste(capture.output(print(resumo)), collapse = "\n"))
  attr(comp, "diagnostico_universos") <- diagnostico
  comp
}


# ------------------------------------------------------------------------------
# Passo 10b — reprodução das tabelas por unidade da federação dos resultados
# definitivos (Série Nacional, vol. I), com cada um dos dois pesos. Com
# censobr_weight, as células que foram restrição fecham por construção; o que
# informa sao celulas nao impostas nem determinadas pelas restricoes, os
# dominios sem suporte e os universos nao classificaveis. A grade guarda as
# linhas "70 e mais" e "ignorada" separadas, como a fonte; a calibracao usa
# a soma delas. A tab. 40 inclui idade declarada ignorada conforme a fonte,
# sem transformar idade danificada em declarada. Este passo nao altera pesos.
# As referencias pessoais de 17 UFs e as domiciliares de todas sao estimadas.
# ------------------------------------------------------------------------------
validate_definitivos_1960_amostra_127 <- function(tabelas, definitivos_path,
                                              out_dir = "./data_raw/microdata/1960/amostra_127"){

  message("Comparing the definitive results (Serie Nacional, vol. I) with the calibrated file")

  p0 <- data.table::copy(tabelas$pessoas); d0 <- data.table::copy(tabelas$domicilios)
  ufs_pessoas <- unique(c(p0$UF, tabelas$ufs_fornecidas))
  ufs_domicilios <- unique(c(d0$UF, tabelas$ufs_fornecidas))
  def <- data.table::fread(definitivos_path, encoding = "UTF-8")[nivel == "uf"]
  def[is.na(sexo), sexo := ""]
  def[is.na(medida), medida := ""]
  if(anyDuplicated(def[, .(tabela, uf60, item, sexo, medida)])) stop("chave duplicada no gabarito da validacao")
  def <- def[, .(tabela, uf60, nome, item, sexo, medida, publicado = valor)]
  faixas <- c("0 a 4", "5 a 9", "10 a 14", "15 a 19", "20 a 24", "25 a 29", "30 a 39", "40 a 49", "50 a 59", "60 a 69", "70 e mais")
  p0[, presente := V202 %in% c(1, 2, 5, 6)]; p0[, residente := V202 %in% 1:4]
  p0[, sexo := data.table::fifelse(V202 %in% c(1, 3, 5), "homens",
                                data.table::fifelse(V202 %in% c(2, 4, 6), "mulheres", NA_character_))]
  p0[, idade := data.table::fifelse(V204 %in% 1 & V204B %in% 0:99, V204B,
                   data.table::fifelse(V204 %in% 0 & V204B %in% 0:99, 0L,
                   data.table::fifelse(V204 %in% 5, 100L, NA_integer_)))]
  p0[, idade_ignorada := V204 %in% 9]
  p0[, idade_danificada := is.na(idade) & !idade_ignorada]
  p0[, faixa := faixas[findInterval(idade, c(0, 5, 10, 15, 20, 25, 30, 40, 50, 60, 70))]]
  p0[V204 %in% 9, faixa := "ignorada"]
  p0[, situacao := data.table::fifelse(V118 %in% c(1, 3), "urbana", data.table::fifelse(V118 %in% 5, "rural", NA_character_))]
  p0[, alf := data.table::fifelse(V211 %in% 0:1, "sabem", data.table::fifelse(V211 %in% 2:3, "nao sabem", NA_character_))]
  p0[, cor := c("brancos", "pretos", "amarelos", "pardos")[match(V206, 4:7)]]
  p0[V206 %in% 8, cor := "pardos"]      # agregacao da tabela historica; V206 original permanece
  p0[V206 %in% 9, cor := "sem declaracao"]
  d0[, situacao := data.table::fifelse(V118 %in% c(1, 3), "urbana", data.table::fifelse(V118 %in% 5, "rural", NA_character_))]
  d0 <- classificar_domicilios_validacao_1960_amostra_127(p0, d0)
  # So a chave derivada de conferência perde o codigo invalido. UF original
  # permanece intacta. Uma UF valida fora da grade nao e geografia perdida.
  ufs_validas <- as.integer(names(REGIAO_1960))
  p0[, uf60 := ufs_validas[match(UF, ufs_validas)]]
  d0[, uf60 := ufs_validas[match(UF, ufs_validas)]]
  diagnostico <- diagnosticar_universos_1960_amostra_127(p0, d0)

  # os totais por sexo e por item, como as tabelas publicam
  com_totais <- function(x, p, numero_tabela){
    x <- rbind(x, x[, somar_validacao_1960_amostra_127(nosso, n_amostra, n_pesos_ausentes), by = .(tabela, uf60, item)][, sexo := "total"])
    totais <- rbind(p[presente == TRUE, somar_validacao_1960_amostra_127(w), by = .(uf60 = UF, sexo)],
                    p[presente == TRUE, somar_validacao_1960_amostra_127(w), by = .(uf60 = UF)][, sexo := "total"])
    totais[, `:=`(tabela = numero_tabela, item = "total")]
    rbind(x, totais)
  }
  comp <- data.table::rbindlist(lapply(c("censobr_weight", "censobr_weight_1965"), function(peso){
    p <- data.table::copy(p0); d <- data.table::copy(d0)
    p[, w := get(peso)]; d[, w := get(peso)]
    n32 <- rbind(p[presente == TRUE, somar_validacao_1960_amostra_127(w), by = .(uf60 = UF, sexo)][, item := "presente"],
                 p[residente == TRUE, somar_validacao_1960_amostra_127(w), by = .(uf60 = UF, sexo)][, item := "residente"])[, tabela := 32L]
    n32 <- rbind(n32, n32[, somar_validacao_1960_amostra_127(nosso, n_amostra, n_pesos_ausentes), by = .(tabela, uf60, item)][, sexo := "total"])
    n33 <- com_totais(p[presente == TRUE, somar_validacao_1960_amostra_127(w), by = .(uf60 = UF, item = faixa, sexo)][, tabela := 33L], p, 33L)
    n34 <- com_totais(p[presente == TRUE, somar_validacao_1960_amostra_127(w), by = .(uf60 = UF, item = situacao, sexo)][, tabela := 34L], p, 34L)
    n37 <- com_totais(p[presente == TRUE, somar_validacao_1960_amostra_127(w), by = .(uf60 = UF, item = cor, sexo)][, tabela := 37L], p, 37L)[sexo != "total"]
    n40 <- p[presente == TRUE & (idade >= 5 | idade_ignorada) & !is.na(alf), somar_validacao_1960_amostra_127(w), by = .(uf60 = UF, item = alf, sexo)][, tabela := 40L]
    n40 <- rbind(n40, p[presente == TRUE & (idade >= 5 | idade_ignorada), somar_validacao_1960_amostra_127(w), by = .(uf60 = UF, sexo)][, `:=`(item = "5 e mais", tabela = 40L)])
    n40 <- rbind(n40, n40[, somar_validacao_1960_amostra_127(nosso, n_amostra, n_pesos_ausentes), by = .(tabela, uf60, item)][, sexo := "total"])
    dp <- d[V101 %in% c(1, 2, 4, 5) & V102 %in% 4:5 & !somente_nao_moradores]
    res <- p[residente == TRUE, somar_validacao_1960_amostra_127(w), by = censobr_idhousehold]
    dp[, `:=`(res = 0, n_res = 0L, n_res_pesos_ausentes = 0L)]
    dp[res, `:=`(res = i.nosso, n_res = i.n_amostra, n_res_pesos_ausentes = i.n_pesos_ausentes), on = "censobr_idhousehold"]
    n7 <- rbind(dp[, somar_validacao_1960_amostra_127(w), by = .(uf60 = UF, item = situacao)][, medida := "domicilios"],
                dp[, somar_validacao_1960_amostra_127(res, n_res, n_res_pesos_ausentes), by = .(uf60 = UF, item = situacao)][, medida := "pessoas"])
    n7 <- rbind(n7, n7[, somar_validacao_1960_amostra_127(nosso, n_amostra, n_pesos_ausentes), by = .(uf60, medida)][, item := "total"])[, `:=`(tabela = 7L, sexo = "")]
    nosso <- rbind(n32, n33, n34, n37, n40, n7, fill = TRUE); nosso[is.na(medida), medida := ""]
    grade <- data.table::copy(def)[, `:=`(cobertura_geografica_completa = data.table::fifelse(tabela == 7L,
                                           uf60 %in% ufs_domicilios, uf60 %in% ufs_pessoas),
                                         n_sem_classificacao = 0L)]
    grade[, reconstruivel := cobertura_geografica_completa & tabela %in% c(7L, 32L, 33L, 34L, 37L, 40L)]
    marcar <- function(linhas, pendente, dados = p, por_sexo = TRUE){
      grade[linhas, n_sem_classificacao := pendencias_validacao_1960_amostra_127(dados, pendente, .SD, "uf60", por_sexo)]
    }
    presenca_incerta <- !p$V202 %in% 1:6
    geografia_pessoal_incerta <- is.na(p$uf60)
    presentes_sem_geografia <- p$presente & geografia_pessoal_incerta
    residentes_sem_geografia <- p$residente & geografia_pessoal_incerta
    marcar(grade$tabela == 32L & grade$item == "presente", presenca_incerta | presentes_sem_geografia)
    marcar(grade$tabela == 32L & grade$item == "residente", presenca_incerta | residentes_sem_geografia)
    marcar(grade$tabela %in% c(33L, 34L, 37L), presenca_incerta | presentes_sem_geografia)
    marcar(grade$tabela == 33L & !grade$item %in% c("total", "ignorada"),
      ((presenca_incerta | presentes_sem_geografia) & !p$idade_ignorada) | (p$presente & p$idade_danificada))
    marcar(grade$tabela == 33L & grade$item == "ignorada", ((presenca_incerta | presentes_sem_geografia) & p$idade_ignorada) |
      ((p$presente | presenca_incerta) & !p$V204 %in% c(0, 1, 5, 9)))
    marcar(grade$tabela == 34L & grade$item != "total", presenca_incerta |
      (p$presente & (geografia_pessoal_incerta | !p$V118 %in% c(1, 3, 5))))
    marcar(grade$tabela == 37L & grade$item != "total", presenca_incerta |
      (p$presente & (geografia_pessoal_incerta | !p$V206 %in% 4:9)))
    base_5 <- presenca_incerta | (p$presente & (p$idade_danificada |
      (geografia_pessoal_incerta & (p$idade >= 5 | p$idade_ignorada))))
    marcar(grade$tabela == 40L & grade$item == "5 e mais", base_5)
    marcar(grade$tabela == 40L & grade$item != "5 e mais", base_5 |
      (p$presente & (p$idade >= 5 | p$idade_ignorada) & !p$V211 %in% 0:4))
    for(pessoas_pendentes in c(FALSE, TRUE)) for(situacao_pendente in c(FALSE, TRUE)){
      incerto <- (!d$V101 %in% c(1:5, 9) | d$V101 %in% c(1, 2, 4, 5)) & !d$V102 %in% 6 & !d$somente_nao_moradores &
        (!d$V101 %in% c(1:5, 9) | !d$V102 %in% 4:5 | d$ocupacao_incerta | is.na(d$uf60) |
          (pessoas_pendentes & d$n_presenca_incerta > 0L) | (situacao_pendente & !d$V118 %in% c(1, 3, 5)))
      marcar(grade$tabela == 7L & (grade$medida == "pessoas") == pessoas_pendentes &
        (grade$item != "total") == situacao_pendente, incerto, d, FALSE)
    }
    out <- completar_validacao_1960_amostra_127(grade, nosso, c("tabela", "uf60", "item", "sexo", "medida"))
    out[, referencia_estimada := tabela == 7L | !uf60 %in% c(0, 1, 2, 3, 4, 6, 10, 12, 51, 54, 74)]
    out[, unidade_sem_classificacao := data.table::fifelse(tabela == 7L, "domicilios", "pessoas")]
    out[, politica_classificacao := "pendencias conservadoras por UF/sexo; repetidas nas categorias potencialmente afetadas; nao somar entre celulas"]
    out[, politica_geografia := "UF ausente ou fora do dicionario: sem UF atribuida; pendencia conservadora no universo potencial; UF valida fora da grade nao e perdida; peso nao distribuido entre UFs"]
    out[, politica_idade := data.table::fifelse(tabela == 33L, "70 e mais e ignorada separados conforme fonte",
      data.table::fifelse(tabela == 40L, "5 e mais inclui declarada ignorada; idade danificada gera pendencia, sem imputacao", "sem limite etario"))]
    out[, peso := peso]
    out
  }))
  data.table::setorder(comp, peso, tabela, uf60, item, sexo, medida)
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  data.table::fwrite(comp, file.path(out_dir, "calibracao_definitivos_validacao.csv"), bom = TRUE)
  data.table::fwrite(diagnostico, file.path(out_dir, "calibracao_definitivos_universos.csv"), bom = TRUE)
  resumo <- comp[, .(celulas = .N, observadas = sum(status_celula == "observada"),
    sem_observacoes = sum(status_celula == "sem_observacoes"), peso_ausente = sum(status_celula == "peso_ausente"),
    classificacao_incompleta = sum(status_celula == "classificacao_incompleta"), nao_reconstruidas = sum(status_celula == "nao_reconstruida"),
    percentuais_validos = sum(!is.na(dif_pct)),
    dif_mediana_abs = if(all(is.na(dif_pct))) NA_real_ else median(abs(dif_pct), na.rm = TRUE)), by = .(peso, tabela)]
  message(paste(capture.output(print(resumo)), collapse = "\n"))
  attr(comp, "diagnostico_universos") <- diagnostico
  comp
}


# ------------------------------------------------------------------------------
# Passo 11 — erros amostrais
#
# Revisao de 21/09/2026: calculo historico, nao certificado pela auditoria.
# A variancia apos calibracao com controles estimados e correlacionados
# ficou para depois; zero residual nao implica ausencia de erro populacional.
# Ver references/microdata_1960_amostra_127_revisao_desenho.md.
#
# O que faltava. O Volume II de 1965 promete "uma publicação especial em que
# se fará descrição detalhada do desenho da amostra e das técnicas
# utilizadas", com os erros de amostragem; ela não está na biblioteca do
# IBGE, nem no Internet Archive, nem é citada no volume definitivo. Este
# passo implementa uma aproximacao, nao reconstitui aquela publicacao.
#
# Como se calcula. A amostra é de conglomerados: sorteou-se uma pasta em
# vinte, e a pasta traz ~220 domicílios inteiros, todos parecidos entre si
# porque são vizinhos. Tratar a amostra como se fosse aleatória simples
# subestima a variância, às vezes muito. O estimador soma, dentro de cada
# estrato, a dispersão dos totais entre as pastas daquele estrato, com a
# correção de população finita da etapa que sorteia as pastas:
#
#   V_entre = soma_h (1 - f_h) n_h/(n_h-1) soma_i (t_hi - média dos t_h)^2
#
# onde t_hi é o total estimado dentro da pasta i do estrato h e f_h = 1/20.
# É o estimador de conglomerado último, o mesmo de survey::svydesign(ids =
# ~censobr_upa, strata = ~censobr_estrato, weights = ~censobr_weight, fpc =
# ~fpc), escrito à mão para não acrescentar dependência ao pipeline (o
# `survey` está no renv e serve de conferência). Fernando de Noronha é um
# estrato de certeza: a sua única pasta era o cadastro inteiro, f = 1, e a
# etapa das pastas não contribui variância ali (no survey, fpc = 1).
#
# A etapa anterior — um domicílio em quatro, no campo — entra em parte na
# dispersão entre pastas (95% dela) e em parte não; o que falta é
#
#   V_dentro = soma_i f_i (1 - 1/4) m_i/(m_i-1) soma_k (w_k y_k - média da pasta)^2
#
# somado sobre as pastas sorteadas, com m_i domicílios na pasta i e f_i a
# fração de sorteio da pasta (1/20; Noronha 1). Vale entre 0,1% e 1,2% da
# variância; entra porque custa três linhas e fecha a conta.
#
# Para `censobr_weight`, a implementacao historica usa residuos da calibracao:
# um diagnostico condicional aos controles tratados como fixos, com os dois
# termos, com y_k trocado por e_k = y_k - x_k'B, o resíduo da regressão
# ponderada de y nas células da calibração. A equivalencia da implementacao
# a um estimador adequado ainda requer verificacao independente. O zero nas
# restricoes reflete ajuste, nao a incerteza dos controles das 17 UFs.
# Para `censobr_weight_1965` ele
# não vale (os totais de 1965 vieram desta mesma amostra) e fica vazio.
#
# O efeito de desenho (deff) é a variância de desenho dividida pela de uma
# amostra aleatória simples de pessoas do mesmo tamanho, N²(1-f)P(1-P)/(n-1);
# diz quantas vezes a amostra é menos precisa do que seria se cada pessoa
# tivesse sido sorteada isoladamente. Para o total do país ele não existe.
# ------------------------------------------------------------------------------
sampling_errors_1960_amostra_127 <- function(tabelas, definitivos_path){

  message("Estimating sampling errors for the 1960 amostra de 1,27%")

  p0 <- data.table::copy(tabelas$pessoas)
  p0[, regiao := REGIAO_1960[as.character(UF)]]
  p0[, situacao := data.table::fifelse(V118 %in% c(1, 3), "urbana", data.table::fifelse(V118 %in% 5, "rural", NA_character_))]
  p0[, sexo := data.table::fifelse(V202 %in% c(1, 3, 5), "homens", "mulheres")]
  p0[, idade := data.table::fifelse(V204 %in% 1, V204B, data.table::fifelse(V204 %in% 0, 0L, 999L))]; p0[is.na(idade), idade := 999L]
  p0[, faixa := c("0 a 4", "5 a 9", "10 a 14", "15 a 19", "20 a 24", "25 a 29", "30 a 39", "40 a 49", "50 a 59", "60 a 69", "70 e mais e ignorada")[findInterval(idade, c(0, 5, 10, 15, 20, 25, 30, 40, 50, 60, 70))]]
  p0 <- p0[!(V202 %in% c(3, 4)) & !is.na(V202) & !is.na(regiao) & !is.na(situacao)]

  # o domicilio e a unidade que carrega o peso; a pasta, a que foi sorteada. O numero de pastas do estrato e o de
  # domicilios da pasta vem da amostra toda: a pasta ou o domicilio sem ninguem do dominio entra na conta com zero
  cal <- celulas_definitivos_1960_amostra_127(tabelas$pessoas, tabelas$domicilios, data.table::fread(definitivos_path, encoding = "UTF-8")[nivel == "uf"])
  hh  <- cal$hh
  dom <- tabelas$domicilios[match(hh, censobr_idhousehold), .(censobr_upa, censobr_estrato, censobr_weight, censobr_weight_1965, f = data.table::fifelse(UF == 24, 1, 1 / 20))]
  pastas   <- dom[, .(m = .N, estrato = censobr_estrato[1], f = f[1]), by = censobr_upa]
  estratos <- pastas[, .(n = .N, f = f[1]), by = estrato]

  res <- data.table::rbindlist(lapply(c("censobr_weight", "censobr_weight_1965"), function(peso){
  p <- data.table::copy(p0); p[, w := get(peso)]
  w_hh <- dom[[peso]]
  n_amostra <- nrow(p); n_populacao <- sum(p$w)
  # a projecao da calibracao, so para o peso final: e o unico com totais externos
  XtWX <- if(peso == "censobr_weight") as.matrix(Matrix::crossprod(cal$X, Matrix::Diagonal(x = w_hh) %*% cal$X)) else NULL

  # a variancia de um total, dado o valor z_k = w_k y_k (ou w_k e_k) de cada domicilio na ordem de hh
  variancia <- function(z){
    s  <- rowsum(cbind(z, z^2), dom$censobr_upa)
    pp <- pastas[match(rownames(s), censobr_upa)]
    pp[, `:=`(s1 = s[, 1], s2 = s[, 2])]
    pp[, dentro := data.table::fifelse(m > 1, f * (1 - 1 / 4) * m / (m - 1) * (s2 - s1^2 / m), 0)]
    e <- pp[, .(soma = sum(s1), soma2 = sum(s1^2), dentro = sum(dentro)), by = estrato]
    e[estratos, `:=`(n = i.n, f = i.f), on = "estrato"]
    e[, entre := data.table::fifelse(f < 1, (1 - f) * n / (n - 1) * (soma2 - soma^2 / n), 0)]
    e[, sum(entre) + sum(dentro)]
  }

  erro_padrao <- function(por){
    # pessoas de cada domicilio em cada dominio; Y e a matriz domicilio x dominio
    y <- p[, .(y = .N), by = c(por, "censobr_idhousehold")]
    y[, dominio := .GRP, by = por]
    dominios <- unique(y[, c(por, "dominio"), with = FALSE])[order(dominio)]
    Y <- Matrix::sparseMatrix(i = match(y$censobr_idhousehold, hh), j = y$dominio, x = y$y, dims = c(length(hh), nrow(dominios)))
    B <- if(is.null(XtWX)) NULL else solve(XtWX, as.matrix(Matrix::crossprod(cal$X, Matrix::Diagonal(x = w_hh) %*% Y)))
    v <- sapply(seq_len(ncol(Y)), function(j){
      yj <- as.numeric(Y[, j])
      c(variancia(w_hh * yj), if(is.null(B)) NA_real_ else variancia(w_hh * (yj - as.numeric(cal$X %*% B[, j]))))
    })
    out <- data.table::copy(dominios)
    out[, `:=`(estimativa = as.numeric(Matrix::crossprod(Y, w_hh)), variancia = v[1, ], variancia_calibrada = v[2, ])]
    out[y[, .(pessoas = sum(y)), by = dominio], pessoas := i.pessoas, on = "dominio"]

    # referencia: amostra aleatoria simples de pessoas do mesmo tamanho, N^2 (1-f) P(1-P)/(n-1)
    out[, parte := estimativa / n_populacao]
    out[, v_srs := n_populacao^2 * (1 - n_amostra / n_populacao) * parte * (1 - parte) / (n_amostra - 1)]
    out[, `:=`(erro_padrao = sqrt(variancia), cv_pct = round(100 * sqrt(variancia) / estimativa, 2),
               deff = data.table::fifelse(parte < 1 - 1e-6, round(variancia / v_srs, 1), NA_real_),
               erro_padrao_calibrado = sqrt(variancia_calibrada), cv_calibrado_pct = round(100 * sqrt(variancia_calibrada) / estimativa, 2))]
    out[, .SD, .SDcols = c(por, "estimativa", "erro_padrao", "cv_pct", "deff", "pessoas", "erro_padrao_calibrado", "cv_calibrado_pct")]
  }

  celulas <- erro_padrao(c("regiao", "situacao", "sexo", "faixa"))
  totais  <- rbind(erro_padrao(c("regiao", "situacao"))[, `:=`(sexo = "ambos", faixa = "todas")],
                   erro_padrao("regiao")[, `:=`(situacao = "ambas", sexo = "ambos", faixa = "todas")],
                   erro_padrao("situacao")[, `:=`(regiao = "Brasil", sexo = "ambos", faixa = "todas")],
                   erro_padrao(character(0))[, `:=`(regiao = "Brasil", situacao = "ambas", sexo = "ambos", faixa = "todas")],
                   fill = TRUE)
  rbind(totais, celulas, fill = TRUE)[, .(peso = peso, regiao, situacao, sexo, faixa, estimativa = round(estimativa), erro_padrao = round(erro_padrao),
                                          cv_pct, deff, pessoas, erro_padrao_calibrado = round(erro_padrao_calibrado), cv_calibrado_pct)]
  }))
  data.table::fwrite(res, "./data_raw/microdata/1960/amostra_127/erros_amostrais.csv", bom = TRUE)

  celulas <- res[peso == "censobr_weight" & faixa != "todas"]
  message("  ", nrow(res) / 2, " dominios por peso; com censobr_weight, nas 176 celulas do quadro 1 o coeficiente de variacao tem mediana ",
          round(median(celulas$cv_pct), 2), "% e maximo ", round(max(celulas$cv_pct), 1), "%; efeito de desenho mediano ", round(median(celulas$deff, na.rm = TRUE), 1),
          "; pelos residuos da calibracao, mediana ", round(median(celulas$cv_calibrado_pct), 2), "% e maximo ", round(max(celulas$cv_calibrado_pct), 1), "%")
  res
}


# Grava as duas tabelas intermediarias.
save_1960_amostra_127 <- function(tabelas, out_dir = "./data_raw/microdata/1960/amostra_127"){

  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  paths <- c(file.path(out_dir, "pessoas_1960_amostra_127.parquet"),
             file.path(out_dir, "domicilios_1960_amostra_127.parquet"))
  write_censobr_parquet(tabelas$pessoas,    paths[1])
  write_censobr_parquet(tabelas$domicilios, paths[2])
  paths
}
