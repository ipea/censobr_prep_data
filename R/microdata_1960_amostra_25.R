# Censo Demográfico de 1960 — preparação da amostra de 25%
#
# Este arquivo reconstrói, passo a passo, a amostra de 25% do Censo de 1960 a
# partir dos dezessete arquivos brutos que sobreviveram dela. Como no estágio
# irmão da amostra de 1,27%, cada função é um passo do procedimento e um target
# do pipeline, e cada uma explica antes do código qual é o problema, o que se
# faz com ele e como fica depois.
#
#
# O QUE É ESTA AMOSTRA
#
# É a amostra geral do censo: um domicílio em cada quatro, recenseado no
# Boletim de Amostra (formulário CD 2), e é dela que saíram os volumes
# definitivos. A amostra de 1,27%, preparada em R/microdata_1960_amostra_127.R,
# é uma subamostra desta — uma pasta em vinte, sorteada em 1965. As duas vieram
# no mesmo pacote, entregue por Suzana Cavenaghi: um zip com "1%/HHOLDA.txt" e
# "25%/" com dezessete arquivos comprimidos, um por unidade da federação.
#
# Sobreviveram dezessete unidades, que são exatamente aquelas cujos tomos do
# Volume I foram apurados só pelo Boletim de Amostra. Nas outras onze o censo
# apurou o Boletim Geral por completo, e de lá só resta a amostra de 1,27%.
#
#
# COMO O ARQUIVO SE PARECE
#
# Dezessete arquivos de largura fixa, 54 caracteres por linha, 18.055.053
# linhas ao todo: 3.071.284 registros de família e 14.983.769 de pessoa, em
# 13.411 pastas. Dois tipos de registro no mesmo arquivo, distinguidos pelas
# posições 9 e 10:
#
#   970020010050190          9701011000000000000000000  <- família (v003 = 00)
#   970020010150151612155089912081721006300007361423516000  <- pessoa (01 a 49)
#
# Três diferenças de layout em relação à amostra de 1,27% mudam o código:
#
#  1. Não há campo de unidade da federação. Ela vem do nome do arquivo. O
#     número da pasta não serve: ele é um bloco de numeração nacional, e os
#     seus dois primeiros dígitos erram a unidade em dois dos dezessete casos
#     (o Paraná começa em 70002 e Fernando de Noronha em 27002).
#  2. A chave do questionário é pasta e boletim, nas posições 1 a 8. O distrito
#     está no corpo do registro de família (34-35), não na chave.
#  3. O boletim é a família, não o domicílio: um domicílio com mais de uma
#     família tem um boletim por família, com números de boletim diferentes.
#
#
# EM QUE ESTADO ELE ESTÁ
#
# Muito melhor que o da amostra de 1,27%, e é justo dizer isso de saída. Os
# 993 MB só contêm dígitos, brancos e quebras de linha: nenhuma letra, nenhum
# hífen, nenhuma barra, nenhum caractere de controle. O dano de fita que marca
# o arquivo de 1,27% não existe aqui. O branco é o marcador de salto, e é
# regular: ele aparece nas variáveis do domicílio exatamente quando a espécie
# não as admite, e nas variáveis de instrução e trabalho exatamente quando a
# idade não as admite.
#
# O que há de defeito estrutural em dezoito milhões de registros cabe em doze
# linhas de read_guides/1960_amostra_25_correcoes.csv, e é de arquivo, não de
# conteúdo: em oito das dezessete unidades um bloco de pastas foi gravado à
# frente do resto, e em São Paulo, além disso, um boletim ficou partido entre o
# fim e o começo do arquivo. Nenhum registro se perdeu nem se corrompeu; o que
# se faz é devolvê-los à ordem do cadastro.
#
# Public API, na ordem dos targets: download_1960_amostra_25,
# audit_1960_amostra_25, read_1960_amostra_25, build_1960_amostra_25,
# weight_1960_amostra_25, validate_definitivos_1960_amostra_25,
# sampling_errors_1960_amostra_25, compare_127_1960_amostra_25.


# As dezessete unidades que sobreviveram, do nome do arquivo para o código de
# unidade da federação de 1960. É a única fonte da UF: o arquivo não a traz.
UF_1960_AMOSTRA_25 <- c(al = 25, ba = 31, ce = 14, df = 97, fn = 24, go = 94, mg = 40,
                        mt = 91, pb = 19, pe = 21, pr = 71, rj = 52, rn = 17, rs = 81,
                        sa = 50, se = 30, sp = 60)

# Quantas linhas cada arquivo tem. Serve de conferência: um arquivo truncado
# produziria um censo menor sem avisar.
LINHAS_1960_AMOSTRA_25 <- c(al = 397616, ba = 1911042, ce = 1008540, df = 49692, fn = 383,
                            go = 595968, mg = 2984569, mt = 273217, pb = 637612, pe = 1302368,
                            pr = 1335652, rj = 1057214, rn = 365413, rs = 1702828, sa = 116622,
                            se = 253619, sp = 4062698)


# ------------------------------------------------------------------------------
# Passo 1 — baixar os arquivos brutos
#
# Os dezessete arquivos estão no release `release_legacy` deste repositório,
# como os microdados de 1970, 1980 e 1991. Estão em gzip, e não no compress de
# 1998 em que chegaram, porque o R não decodifica LZW; a recompressão foi
# conferida byte a byte contra os originais nas dezessete unidades, e os
# arquivos de 1998 ficam guardados como prova de proveniência.
# ------------------------------------------------------------------------------
download_1960_amostra_25 <- function(){

  dest_dir <- "./data_raw/microdata/1960/amostra_25"
  dir.create(dest_dir, recursive = TRUE, showWarnings = FALSE)

  message("\nDownloading 1960 amostra de 25% (17 arquivos)...\n")

  arquivos <- paste0("Censo.1960.amostra.25porcento.", names(UF_1960_AMOSTRA_25), ".gz")
  paths <- get_release_legacy(arquivos, dest_dir)

  vazios <- paths[file.size(paths) < 1000]
  if(length(vazios) > 0) stop("arquivos vazios ou truncados: ", paste(basename(vazios), collapse = ", "))

  paths
}


# Lê um dos dezessete arquivos e devolve as linhas com as colunas de navegação.
# Usada pelos passos 2 e 3, que precisam do mesmo texto bruto.
leitura_1960_amostra_25 <- function(paths, uf){

  path <- paths[basename(paths) == paste0("Censo.1960.amostra.25porcento.", uf, ".gz")]
  con <- gzfile(path, "rt", encoding = "latin1")
  texto <- readLines(con, warn = FALSE)
  close(con)

  if(length(texto) != LINHAS_1960_AMOSTRA_25[[uf]])
    stop(uf, ": ", length(texto), " linhas; esperadas ", LINHAS_1960_AMOSTRA_25[[uf]])
  n_fora <- sum(nchar(texto) != 54)
  if(n_fora > 0) stop(uf, ": ", n_fora, " linhas nao tem 54 caracteres")

  data.table::data.table(
    linha   = seq_along(texto),
    texto   = texto,
    pasta   = substr(texto, 1, 5),
    boletim = substr(texto, 6, 8),
    ordem   = substr(texto, 9, 10),          # 00 = familia; 01 a 49 = pessoa
    chave   = substr(texto, 1, 8))
}


# ------------------------------------------------------------------------------
# Passo 2 — examinar o arquivo, por classe de defeito
#
# A amostra de 1,27% recebeu uma decisão humana por linha suspeita: eram 124
# decisões para um milhão de linhas. Aqui são dezoito milhões, e a decisão se
# registra por classe de defeito, com a contagem e as linhas de cada uma. As
# classes com poucas linhas ganham decisão individual, como lá.
#
# Os quatro testes da amostra de 1,27% não cabem todos: dois deles procuravam
# caractere estranho e marca de salto deslocada, e este arquivo não tem nem
# uma letra em 993 MB. No lugar deles entram as invariantes de estrutura, que
# o layout daqui permite testar e o de lá não permitia — o total de pessoas
# declarado no registro de família, a numeração sequencial das pessoas, a
# contiguidade do boletim, e as três redundâncias de perfuração (o número da
# pessoa repete a ordem, o dígito verificador repete o seu par, e o campo
# rotulado filler repete a nacionalidade).
#
# No fim, a cobertura: toda linha marcada precisa ter decisão em
# read_guides/1960_amostra_25_correcoes.csv, seja a sua própria, seja uma
# decisão de classe; e toda decisão precisa apontar para uma linha marcada.
# ------------------------------------------------------------------------------
audit_1960_amostra_25 <- function(paths, uf, guia_familias, guia_pessoas, correcoes){

  message("Auditing 1960 amostra de 25%: ", uf)

  x <- leitura_1960_amostra_25(paths, uf)
  marcas <- list()
  marca <- function(classe, linhas) if(length(linhas) > 0) marcas[[length(marcas) + 1]] <<-
    data.table::data.table(uf = uf, classe = classe, linha = sort(linhas))

  # caractere que nao e digito nem branco: em 993 MB nao ha nenhum, e o teste fica de sentinela
  marca("caractere_estranho", x$linha[grepl("[^0-9 ]", x$texto)])

  # valor fora do dicionario, variavel por variavel, nos dois layouts
  for(guia_path in c(guia_familias, guia_pessoas)){
    guia <- data.table::fread(guia_path, encoding = "UTF-8", colClasses = "character")
    alvo <- if(identical(guia_path, guia_familias)) x[ordem == "00"] else x[ordem != "00"]
    for(i in seq_len(nrow(guia))){
      if(guia$valores_validos[i] == "") next
      codigos  <- strsplit(guia$valores_validos[i], ";", fixed = TRUE)[[1]]
      branco_ok <- any(codigos %in% c("", "NA"))
      v <- substr(alvo$texto, as.integer(guia$inicio[i]), as.integer(guia$fim[i]))
      distintos <- unique(v)
      maus <- distintos[!(distintos %in% codigos) & !(branco_ok & trimws(distintos) == "")]
      if(length(maus) > 0) marca(paste0("valor_fora_do_dicionario_", guia$variavel[i]), alvo$linha[v %in% maus])
    }
  }

  # o boletim tem de ser um bloco contiguo que comeca pelo registro de familia
  x[, grupo := cumsum(ordem == "00")]
  por_boletim <- x[, .(n_grupos = data.table::uniqueN(grupo), n_familia = sum(ordem == "00"),
                       n_pessoas = sum(ordem != "00")), by = chave]
  marca("boletim_partido",         x$linha[x$chave %in% por_boletim[n_grupos > 1,  chave]])
  marca("boletim_sem_familia",     x$linha[x$chave %in% por_boletim[n_familia == 0, chave]])
  marca("boletim_sem_pessoa",      x$linha[x$chave %in% por_boletim[n_pessoas == 0, chave]])
  marca("boletim_com_duas_familias", x$linha[x$chave %in% por_boletim[n_familia > 1, chave]])

  # o arquivo tem de estar na ordem do cadastro: pasta, boletim, pessoa. Em nove das
  # dezessete unidades está; nas outras oito um bloco de pastas veio à frente
  x[, subordem := data.table::fifelse(ordem == "00", 0L, as.integer(ordem))]
  cadastro <- order(x$pasta, x$boletim, x$subordem)
  marca("bloco_de_pastas_deslocado", x$linha[cadastro != seq_len(nrow(x))])

  # o total de pessoas declarado no registro de familia
  fam <- x[ordem == "00", .(linha, chave, v100 = as.integer(substr(texto, 12, 13)), v101 = substr(texto, 14, 14))]
  fam[por_boletim, n_pessoas := i.n_pessoas, on = "chave"]
  marca("v100_nao_bate", fam$linha[fam$v100 != fam$n_pessoas])

  # o boletim individual e o morador de domicilio coletivo sorteado pessoa a pessoa: tem sempre uma so
  marca("individual_com_varias_pessoas", fam$linha[fam$v101 == "9" & fam$n_pessoas != 1])

  # a familia convivente vem sempre depois da principal ou de outra convivente
  fam[, anterior := data.table::shift(v101)]
  marca("convivente_sem_principal", fam$linha[fam$v101 %in% c("4", "5") & !(fam$anterior %in% c("2", "4", "5"))])

  # a numeracao das pessoas dentro do boletim e sequencial, de 01 ate o total
  pes <- x[ordem != "00", .(linha, chave, n = as.integer(ordem))]
  pes[, esperado := seq_len(.N), by = chave]
  marca("ordem_nao_sequencial", pes$linha[pes$n != pes$esperado])

  # as tres redundancias de perfuracao do registro de pessoa
  pesos <- x[ordem != "00"]
  marca("redundancia_v200", pesos$linha[substr(pesos$texto, 12, 13) != pesos$ordem])
  marca("redundancia_v201", pesos$linha[substr(pesos$texto, 14, 14) != substr(pesos$texto, 11, 11)])
  marca("redundancia_v99",  pesos$linha[substr(pesos$texto, 25, 25) != substr(pesos$texto, 24, 24)])

  # no maximo um chefe por boletim
  chefes <- pesos[substr(texto, 16, 16) == "7", .N, by = chave][N > 1]
  marca("mais_de_um_chefe", pesos$linha[pesos$chave %in% chefes$chave])

  marcadas <- if(length(marcas) > 0) data.table::rbindlist(marcas) else
    data.table::data.table(uf = character(), classe = character(), linha = integer())

  # cobertura: toda linha marcada com decisao, toda decisao apontando para linha marcada
  uf_alvo <- uf
  dec <- data.table::fread(correcoes, encoding = "UTF-8", colClasses = "character")[uf == uf_alvo]
  por_classe <- dec[linha == "", classe]
  sem_decisao <- marcadas[!(classe %in% por_classe) & !(linha %in% as.integer(dec$linha))]
  if(nrow(sem_decisao) > 0)
    stop(uf, ": ", nrow(sem_decisao), " linhas marcadas sem decisao (classes: ",
         paste(unique(sem_decisao$classe), collapse = ", "), "); primeiras: ",
         paste(head(sem_decisao$linha, 5), collapse = ", "))
  sobrando <- dec[linha != "" & !(as.integer(linha) %in% marcadas$linha)]
  if(nrow(sobrando) > 0)
    stop(uf, ": ", nrow(sobrando), " decisoes apontam para linhas que o exame nao marcou: ",
         paste(head(sobrando$linha, 5), collapse = ", "))

  classes <- if(nrow(marcadas) == 0) data.table::data.table(uf = character(), classe = character(), linhas = integer(), exemplo = integer())
             else marcadas[, .(linhas = .N, exemplo = min(linha)), by = .(uf, classe)]
  message("  ", format(nrow(x), big.mark = ".", decimal.mark = ","), " linhas | ",
          if(nrow(classes) == 0) "nenhuma classe de defeito" else
            paste(classes$classe, classes$linhas, sep = ": ", collapse = " | "))

  rm(x, pes, pesos, fam); gc(verbose = FALSE)
  classes
}


# ------------------------------------------------------------------------------
# Passo 3 — aplicar as decisões e o layout
#
# Primeiro a ordem. O cadastro de sorteio é pasta, boletim, pessoa, e é nessa
# ordem que nove dos dezessete arquivos estão. Nos outros oito um bloco de
# pastas foi gravado à frente do resto — um só corte, o resto crescente e sem
# interseção com o bloco deslocado, o que é assinatura de fita remontada, não
# de dado perdido. São Paulo tem ainda o caso extremo: o boletim da pasta 64150
# começa na última linha do arquivo e termina nas três primeiras. Ordenar por
# (pasta, boletim, ordem) resolve os dois de uma vez, e não move nada nos nove
# arquivos que já estavam certos.
#
# Depois o layout. Cada variável vira uma coluna inteira; branco onde o
# dicionário permite branco vira ausente, e o que ficou ausente é registrado em
# censobr_variaveis_anuladas, como no estágio da amostra de 1,27%. Ficam de
# fora os campos que nunca foram gravados (total de famílias, total de
# moradores e peso do domicílio, todos zerados em 100% dos registros) e as três
# redundâncias de perfuração, que o passo 2 já usou como teste de integridade.
#
# As tabelas saem em parquet por unidade da federação, com compressão leve: a
# compressão pesada do projeto entra uma vez só, no fim, quando as dezessete
# viram uma tabela nacional.
# ------------------------------------------------------------------------------
read_1960_amostra_25 <- function(paths, uf, guia_familias, guia_pessoas, correcoes, auditoria){

  message("Reading 1960 amostra de 25%: ", uf)

  x <- leitura_1960_amostra_25(paths, uf)
  uf_alvo <- uf
  dec <- data.table::fread(correcoes, encoding = "UTF-8", colClasses = "character")[uf == uf_alvo]

  # a ordem do cadastro é pasta, boletim, pessoa — é nela que nove dos dezessete arquivos
  # já estão, e é ela que a ordenação restaura nos outros oito. Nenhum registro muda de
  # conteúdo; muda a posição. Nos nove já ordenados a operação não move nada.
  x[, subordem := data.table::fifelse(ordem == "00", 0L, as.integer(ordem))]
  movidas <- sum(order(x$pasta, x$boletim, x$subordem) != seq_len(nrow(x)))
  data.table::setorder(x, pasta, boletim, subordem)

  if(movidas > 0 && nrow(dec[classe == "bloco_de_pastas_deslocado"]) == 0)
    stop(uf, ": ", movidas, " linhas fora da ordem do cadastro e nenhuma decisao para elas")
  if(is.unsorted(unique(x$pasta), strictly = TRUE)) stop(uf, ": as pastas nao ficaram crescentes")
  x[, grupo := cumsum(ordem == "00")]
  if(x[, .(k = data.table::uniqueN(grupo)), by = chave][, any(k > 1)])
    stop(uf, ": ha boletim nao contiguo depois da ordenacao")
  if(movidas > 0) message("  ordem do cadastro restaurada: ", format(movidas, big.mark = ".", decimal.mark = ","), " linhas")

  aplica_layout <- function(alvo, guia_path, pular){
    guia <- data.table::fread(guia_path, encoding = "UTF-8", colClasses = "character")
    guia <- guia[!(variavel %in% pular)]
    out <- data.table::data.table(linha = alvo$linha, UF = as.integer(UF_1960_AMOSTRA_25[[uf]]))
    anuladas <- character(nrow(alvo))
    for(i in seq_len(nrow(guia))){
      v <- substr(alvo$texto, as.integer(guia$inicio[i]), as.integer(guia$fim[i]))
      if(guia$valores_validos[i] != ""){
        codigos <- strsplit(guia$valores_validos[i], ";", fixed = TRUE)[[1]]
        fora <- !(v %in% codigos) & trimws(v) != ""
        if(any(fora)){
          anuladas[fora] <- paste(anuladas[fora], guia$variavel[i])
          v[fora] <- NA_character_
        }
      }
      data.table::set(out, j = guia$variavel[i], value = as.integer(v))
    }
    out[, censobr_variaveis_anuladas := trimws(anuladas)]
    out
  }

  # o total de famílias, o total de moradores e o peso do domicílio nunca foram gravados;
  # o número da pessoa, o dígito verificador e o filler repetem campos que já existem
  familias <- aplica_layout(x[ordem == "00"], guia_familias, c("V119", "V120", "V121", "V122"))
  pessoas  <- aplica_layout(x[ordem != "00"], guia_pessoas,  c("V200", "V201", "V99", "FILLER"))

  rm(x); gc(verbose = FALSE)

  out_dir <- file.path("./data_raw/microdata/1960/amostra_25", uf)
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  saida <- c(file.path(out_dir, "familias.parquet"), file.path(out_dir, "pessoas.parquet"))
  arrow::write_parquet(familias, saida[1], compression = "zstd", compression_level = 1)
  arrow::write_parquet(pessoas,  saida[2], compression = "zstd", compression_level = 1)

  message("  ", format(nrow(familias), big.mark = ".", decimal.mark = ","), " boletins x ", ncol(familias),
          " | ", format(nrow(pessoas), big.mark = ".", decimal.mark = ","), " pessoas x ", ncol(pessoas),
          " | anulados: ", sum(familias$censobr_variaveis_anuladas != "") + sum(pessoas$censobr_variaveis_anuladas != ""))

  rm(familias, pessoas); gc(verbose = FALSE)
  saida
}


# ------------------------------------------------------------------------------
# Passo 4 — famílias, domicílios e geografia
#
# O boletim é a família, não o domicílio. Um domicílio com mais de uma família
# tem um boletim por família, com números de boletim diferentes e a página de
# domicílio preenchida só no primeiro. V101 diz o que cada um é: 1 = domicílio
# particular único, 2 = principal de um domicílio com mais de uma família, 3 =
# coletivo, 4 = segunda família, 5 = terceira, 9 = boletim individual. Então 1,
# 2, 3 e 9 abrem domicílio; 4 e 5 entram no domicílio anterior. São 3.071.284
# boletins para 3.066.365 domicílios.
#
# O boletim individual (V101 = 9) é o morador de domicílio coletivo sorteado
# pessoa a pessoa pela Lista CD 3, com a página de domicílio em branco por
# construção e sempre uma pessoa só. São 195.445, 6,4% dos boletins, e no
# Distrito Federal 8.698 dos 14.818 — o acampamento da construção de Brasília.
# Tratá-los como domicílio infla a contagem em 6,4% e envenena qualquer média
# por domicílio, e é por isso que censobr_tipo_unidade os separa.
#
# A página de domicílio das famílias conviventes não é preenchida a partir da
# principal: fica ausente, como no estágio da amostra de 1,27%, e a decisão
# está em discussão no ipea/censobr#87.
#
# Nada de valor se altera aqui. O Código do Censo dá a cada quesito do domicílio
# um código próprio para a resposta ausente — V102 = 7, V103 = 0, V105 = 4,
# V106 = 9, V107 = 5, V108 = 7, V109 = 9, V110 = 1, V111 = 3 —, e para os dois
# campos numéricos manda, na p. 25, "não havendo indicação do número total de
# cômodos codifique-se 00" e "não havendo indicação do número de peças servindo
# de dormitório codifique-se 000". São 23.109 e 24.285 domicílios, concentrados
# por lote de perfuração, e ficam com o código do dicionário, que
# read_guides/1960_codigo_do_censo.csv traz rotulado.
#
# A geografia. V116 é o código do Código de Zonas Fisiográficas, Municípios e
# Distritos de 1960, com três correções: Alagoas vem deslocada em +200, Fernando
# de Noronha vem 2701 e o seu único município é 2401, e o Distrito Federal vem
# 9701 contra 9700 do livro — esta última não era precisa na amostra de 1,27% e
# sem ela os 14.818 domicílios de Brasília ficam sem município. Com as três, o
# casamento fecha em 100% dos 3.071.284 boletins nas dezessete unidades. V117 é
# o distrito, e o guia cobre 91,6% dos boletins; o que falta são 1.178 pares
# município-distrito de páginas do livro que a amostra de 1,27% não alcançava.
# ------------------------------------------------------------------------------
build_1960_amostra_25 <- function(paths, uf, municipios_path, distritos_path){

  message("Building households and geography in 1960 amostra de 25%: ", uf)

  in_dir   <- file.path("./data_raw/microdata/1960/amostra_25", uf)
  familias <- data.table::setDT(arrow::read_parquet(file.path(in_dir, "familias.parquet")))
  pessoas  <- data.table::setDT(arrow::read_parquet(file.path(in_dir, "pessoas.parquet")))
  data.table::setnames(pessoas, "AGE", "V204B")

  # a chave do questionario liga a pessoa a sua familia; o arquivo ja esta na ordem do cadastro
  familias[, censobr_idfamily := seq_len(.N)]
  pessoas[familias, censobr_idfamily := i.censobr_idfamily, on = c("v001", "v002")]
  if(anyNA(pessoas$censobr_idfamily)) stop(uf, ": ha pessoa sem registro de familia")

  # 1, 2, 3 e 9 abrem domicilio; 4 e 5 entram no anterior
  familias[, censobr_convivente_isolada := V101 %in% c(4, 5) & !(data.table::shift(V101) %in% c(2, 4, 5))]
  familias[, censobr_idhousehold := cumsum(!(V101 %in% c(4, 5)) | censobr_convivente_isolada)]
  pessoas[familias, censobr_idhousehold := i.censobr_idhousehold, on = "censobr_idfamily"]

  familias[, censobr_tipo_unidade := data.table::fifelse(V101 == 9, "boletim individual",
                                     data.table::fifelse(V101 == 3, "domicilio coletivo", "domicilio particular"))]

  # contagens por domicilio
  pessoas[, `:=`(censobr_n_listadas   = .N,
                 censobr_n_residentes = sum(!V202 %in% c(5, 6)),
                 censobr_n_presentes  = sum(!V202 %in% c(3, 4)),
                 censobr_n_familias   = data.table::uniqueN(censobr_idfamily)), by = censobr_idhousehold]

  # o municipio: as tres correcoes, e o codigo atual pelo crosswalk da mesma tabela
  municipios <- data.table::fread(municipios_path, encoding = "UTF-8")
  familias[, code_muni_1960 := data.table::fifelse(UF == 25L, V116 - 200L,
                               data.table::fifelse(UF == 24L, 2401L,
                               data.table::fifelse(UF == 97L, 9700L, V116)))]
  familias[, censobr_muni_corrigido := UF %in% c(25L, 24L, 97L)]
  familias[municipios, `:=`(code_muni = as.integer(i.code_muni_2010), name_muni_1960 = i.nome),
           on = c(UF = "uf60", code_muni_1960 = "cod60")]
  if(familias[is.na(name_muni_1960), .N] > 0)
    stop(uf, ": ", familias[is.na(name_muni_1960), .N], " boletins sem municipio no guia")

  # o distrito: V117 e o codigo do mesmo livro
  distritos <- data.table::fread(distritos_path, encoding = "UTF-8")
  distritos <- unique(distritos[, .(uf60, code_muni_1960, code_district_1960 = as.integer(code_district_1960),
                                    name_district_1960, tipo)])
  familias[, code_district_1960 := V117]
  familias[distritos, `:=`(name_district_1960 = i.name_district_1960, censobr_favela = i.tipo == "favela"),
           on = c(UF = "uf60", "code_muni_1960", "code_district_1960")]
  familias[is.na(censobr_favela), censobr_favela := FALSE]

  # a tabela de domicilios e a pagina do boletim que abriu o domicilio
  geo <- c("UF", "V116", "V117", "V118", "code_muni", "code_muni_1960", "name_muni_1960",
           "code_district_1960", "name_district_1960", "censobr_favela", "censobr_muni_corrigido")
  pagina <- paste0("V1", sprintf("%02d", 1:13))
  domicilios <- familias[!(V101 %in% c(4, 5)) | censobr_convivente_isolada == TRUE]
  domicilios <- domicilios[, .SD[1], by = censobr_idhousehold]
  contagens  <- pessoas[, .SD[1], by = censobr_idhousehold,
                        .SDcols = c("censobr_n_listadas", "censobr_n_residentes", "censobr_n_presentes", "censobr_n_familias")]
  domicilios[contagens, `:=`(censobr_n_listadas = i.censobr_n_listadas, censobr_n_residentes = i.censobr_n_residentes,
                             censobr_n_presentes = i.censobr_n_presentes, censobr_n_familias = i.censobr_n_familias),
             on = "censobr_idhousehold"]

  # a pessoa leva a geografia do seu domicilio e a pagina do seu proprio boletim
  leva <- c(geo, "censobr_tipo_unidade", pagina)
  pessoas[familias, (leva) := mget(paste0("i.", leva)), on = "censobr_idfamily"]

  data.table::setcolorder(domicilios, c(geo, "censobr_idhousehold", "censobr_tipo_unidade"))
  data.table::setcolorder(pessoas,    c(geo, "censobr_idhousehold", "censobr_idfamily", "censobr_tipo_unidade"))

  saida <- c(file.path(in_dir, "domicilios.parquet"), file.path(in_dir, "pessoas_geo.parquet"))
  arrow::write_parquet(domicilios, saida[1], compression = "zstd", compression_level = 1)
  arrow::write_parquet(pessoas,    saida[2], compression = "zstd", compression_level = 1)

  message("  ", format(nrow(domicilios), big.mark = ".", decimal.mark = ","), " domicilios (",
          domicilios[censobr_tipo_unidade == "boletim individual", .N], " individuais, ",
          domicilios[censobr_tipo_unidade == "domicilio coletivo", .N], " coletivos) | distrito com nome: ",
          round(100 * domicilios[!is.na(name_district_1960), .N] / nrow(domicilios), 1), "%")

  rm(familias, pessoas, domicilios); gc(verbose = FALSE)
  saida
}


# ------------------------------------------------------------------------------
# Passo 5 — o desenho e os dois pesos
#
# O desenho desta amostra é outro, e é mais simples que o da amostra de 1,27%.
# Lá sorteou-se uma pasta em vinte e a pasta entrou inteira, de modo que a
# unidade primária era a pasta. Aqui não há sorteio de pastas — todas entram —,
# e o que se sorteia é o domicílio, um em quatro, sistematicamente, pelas
# "Linhas de Amostra" impressas em intervalos regulares de quatro linhas nas
# Folhas de Coleta CD 7 e CD 8, dentro de cada setor censitário. Uma etapa só.
#
#  - censobr_upa é o domicílio: todas as suas pessoas entram ou saem juntas. No
#    boletim individual é a própria pessoa e no coletivo o grupo do boletim,
#    porque foi isso que a Lista CD 3 sorteou.
#  - censobr_estrato é pasta × situação. A seleção foi sistemática dentro do
#    setor, e o setor é, por definição, "área territorial contínua situada num
#    só quadro (urbano, suburbano ou rural), do mesmo distrito administrativo".
#    Toda pasta está num só município, e cruzá-la com V118 separa as pastas
#    mistas nas suas partes urbana e rural: é a aproximação mais fina do setor
#    que o arquivo permite.
#  - a correção de população finita é 1/4 exatamente, em todas as unidades,
#    inclusive Fernando de Noronha, onde o sorteio de um em quatro aconteceu
#    normalmente.
#
# Dois pesos, como na amostra de 1,27%.
#
# censobr_weight calibra a duas margens ao mesmo tempo, por unidade da federação,
# pelo raking de Deville-Särndal com distância logit — o mesmo solver da amostra
# de 1,27%, em raking_1960_amostra_127().
#
# A Sinopse Preliminar dá a distribuição entre municípios, que a Série Nacional
# não publica; a Série Nacional dá o nível e a estrutura demográfica, que é a
# mesma a que a amostra de 1,27% calibra. As duas margens juntas põem os dois
# estágios de 1960 na mesma régua. Com a âncora municipal sozinha, como uma
# primeira versão fazia, as dezessete unidades daqui ficavam 1,2% acima dos
# resultados definitivos enquanto as onze da amostra de 1,27% ficavam exatas —
# uma descontinuidade nas fronteiras estaduais, num banco que se apresenta como
# um censo só.
#
# As três margens: município × situação, da Sinopse, reescalada para somar o
# total definitivo da unidade; sexo × onze faixas etárias, da tabela 33; e
# sabem ler de 5 anos e mais por sexo, da tabela 40. Uma célula de sexo × idade
# sai por ser implicada — as duas primeiras margens somam a mesma população, e
# sem isso o sistema de Newton fica singular.
#
# Há uma circularidade a declarar: para estas dezessete unidades as tabelas da
# Série Nacional foram apuradas com esta mesma amostra. Calibrar a elas não
# acrescenta informação; troca a âncora da safra preliminar para a definitiva,
# que é o que alinha os dois estágios. Em consequência, a variância pelos
# resíduos da calibração, legítima na amostra de 1,27%, aqui daria zero sem
# significado e não se publica.
#
# A Serra dos Aimorés é a única unidade sem contagem completa: os tomos de Minas
# e do Espírito Santo excluem a região do litígio dos dois estados, com todas as
# letras, e não publicam tabela própria para ela. A única publicação que a traz
# é a Série Nacional, e é a ela que a região calibra — âncora que é estimativa
# publicada, não contagem completa, e isso fica dito aqui e no documento.
#
# censobr_weight_ibge reproduz o método do IBGE ao pé da letra para estas
# unidades: razão a unidade da federação × urbana/rural com peso inteiro
# sorteado para fechar o total, com semente fixa. Serve para medir quanto o
# refinamento municipal vale e para reproduzir a Série Regional inclusive nos
# seus artefatos de arredondamento.
# ------------------------------------------------------------------------------
weight_1960_amostra_25 <- function(paths, uf, municipios_path, definitivos_path,
                                  out_dir = file.path("./data_raw/microdata/1960/amostra_25", uf)){

  message("Weighting 1960 amostra de 25%: ", uf)

  arquivos <- as.character(unlist(paths, use.names = FALSE))
  path_dom <- arquivos[basename(arquivos) == "domicilios.parquet"]
  path_pes <- arquivos[basename(arquivos) == "pessoas_geo.parquet"]
  if(length(path_dom) != 1L || length(path_pes) != 1L)
    stop("informar um arquivo de domicilios e um de pessoas_geo da UF para calibrar")
  domicilios <- data.table::setDT(arrow::read_parquet(path_dom))
  pessoas    <- data.table::setDT(arrow::read_parquet(path_pes))
  codigo_uf  <- as.integer(UF_1960_AMOSTRA_25[[uf]])
  if(!nrow(domicilios) || !nrow(pessoas) || any(!domicilios$UF %in% codigo_uf) || any(!pessoas$UF %in% codigo_uf))
    stop("arquivos vazios ou com UF incompativel na calibracao")
  if(anyNA(domicilios$censobr_idhousehold) || anyDuplicated(domicilios$censobr_idhousehold))
    stop("identificadores ausentes ou duplicados nos domicilios da calibracao")
  if(any(!pessoas$censobr_idhousehold %in% domicilios$censobr_idhousehold)) stop("pessoas sem domicilio na calibracao")
  if(any(!pessoas$V202 %in% 1:6)) stop("presenca desconhecida em controles da calibracao")
  if(any(!domicilios$V118 %in% c(1, 3, 5)) || any(pessoas$V202 %in% c(1, 2, 5, 6) & !pessoas$V118 %in% c(1, 3, 5)))
    stop("situacao desconhecida em controles da calibracao")

  # as colunas de desenho: uma etapa so, o domicilio e a unidade, pasta x situacao e o estrato
  domicilios[, situacao := data.table::fifelse(V118 == 5L, "rural", "urbana")]
  domicilios[, `:=`(censobr_upa     = censobr_idhousehold,
                    censobr_estrato = paste0("UF ", UF, " - pasta ", v001, " - ", situacao),
                    censobr_fpc     = 0.25,
                    censobr_weight_desenho = 4)]

  # o universo: a contagem completa por municipio x situacao
  municipios <- data.table::fread(municipios_path, encoding = "UTF-8")
  universo <- data.table::melt(municipios[uf60 == codigo_uf, .(uf60, cod60, urbana = pop_urbana, rural = pop_rural)],
                               id.vars = c("uf60", "cod60"), variable.name = "situacao",
                               value.name = "universo", variable.factor = FALSE)

  # a Serra dos Aimores nao tem contagem completa: a sua unica publicacao e a Serie Nacional
  if(uf == "sa"){
    def <- data.table::fread(definitivos_path, encoding = "UTF-8")
    sa  <- def[tabela == 34 & uf60 == 50 & sexo == "total" & item %in% c("urbana", "rural")]
    universo <- data.table::data.table(uf60 = 50L, cod60 = 5001L, situacao = sa$item, universo = sa$valor)
    message("  ancora da Serie Nacional: urbana ", sa[item == "urbana", valor], ", rural ", sa[item == "rural", valor])
  }

  # --------------------------------------------------------------------------
  # A calibracao: tres margens, resolvidas juntas por unidade da federacao.
  # A Sinopse da a forma (a distribuicao entre municipios), a Serie Nacional da
  # a escala e a estrutura demografica -- que e a mesma a que a amostra de 1,27%
  # calibra, e e o que poe os dois estagios de 1960 na mesma regua.
  # --------------------------------------------------------------------------
  def <- data.table::fread(definitivos_path, encoding = "UTF-8")
  def <- def[nivel == "uf" & uf60 == codigo_uf]
  if(anyDuplicated(def[, .(tabela, uf60, item, sexo, medida)])) stop("chave duplicada no gabarito da calibracao")
  alvo_uf <- def[tabela == 32L & item == "presente" & sexo %in% c("homens", "mulheres"), sum(valor)]
  if(length(alvo_uf) != 1 || is.na(alvo_uf) || alvo_uf <= 0)
    stop(uf, ": sem total de presentes na Serie Nacional para a unidade ", codigo_uf)

  pessoas[, presente := V202 %in% c(1L, 2L, 5L, 6L)]
  pessoas[, sexo := data.table::fifelse(V202 %in% c(1L, 3L, 5L), "homens",
                   data.table::fifelse(V202 %in% c(2L, 4L, 6L), "mulheres", NA_character_))]
  pessoas[, idade := data.table::fifelse(V204 %in% 1 & V204B %in% 0:99, V204B,
                    data.table::fifelse(V204 %in% 0 & V204B %in% 0:99, 0L,
                    data.table::fifelse(V204 %in% 5, 100L, NA_integer_)))]
  dano <- pessoas[presente == TRUE & is.na(idade) & !V204 %in% 9]
  if(nrow(dano)) stop("idade danificada em controles da calibracao; resolver ou explicitar a politica antes do ajuste: linhas ",
                     paste(head(dano$linha, 10L), collapse = ", "))
  if(any(pessoas$presente & ((!is.na(pessoas$idade) & pessoas$idade >= 5) | pessoas$V204 %in% 9) &
         !pessoas$V211 %in% 0:4)) stop("alfabetizacao desconhecida em controles da calibracao")
  pessoas[, faixa := as.character(cut(idade, c(-1, 4, 9, 14, 19, 24, 29, 39, 49, 59, 69, Inf),
                     labels = c("0 a 4", "5 a 9", "10 a 14", "15 a 19", "20 a 24", "25 a 29",
                                "30 a 39", "40 a 49", "50 a 59", "60 a 69", "70 e mais")))]
  pessoas[V204 %in% 9, faixa := "ignorada"]
  pessoas[, sit := data.table::fifelse(V118 == 5L, "rural", "urbana")]
  pres <- pessoas[presente == TRUE]

  # margem 1: municipio x situacao, da Sinopse. A celula de situacao vira municipio
  # inteiro quando o seu fator implicito sai de [2; 8], quando o universo e menor
  # que 100 e quando uma das situacoes do universo nao foi alcancada pela amostra --
  # a ancora municipal nao se abandona, e so o municipio sem universo proprio fica
  # de fora da margem, preso as margens demograficas. Sem esse colapso a margem
  # pediria fatores de ate 27 (Itu) e nao caberia nos limites do raking.
  celulas <- domicilios[, .(pes = sum(censobr_n_presentes)), by = .(code_muni_1960, situacao)]
  celulas[universo, universo := i.universo, on = c(code_muni_1960 = "cod60", "situacao")]
  uni_muni <- universo[, .(uni_m = sum(universo, na.rm = TRUE),
                           sits = sum(!is.na(universo) & universo > 0)), by = .(code_muni_1960 = cod60)]
  celulas[uni_muni, `:=`(uni_m = i.uni_m, sits_universo = i.sits), on = "code_muni_1960"]
  celulas[, sits_amostra := .N, by = code_muni_1960]
  celulas[, fator := universo / pes]
  sobe <- celulas[is.na(fator) | universo < 100 | fator < 2 | fator > 8 |
                    sits_amostra < sits_universo, unique(code_muni_1960)]
  celulas[, `:=`(cel_mun = paste0("mun_", code_muni_1960, "_", situacao),
                 alvo_mun = as.numeric(universo),
                 nivel = "municipio x situacao")]
  celulas[code_muni_1960 %in% sobe, `:=`(cel_mun = paste0("mun_", code_muni_1960),
                                         alvo_mun = as.numeric(uni_m),
                                         nivel = "municipio")]
  celulas[is.na(alvo_mun) | alvo_mun <= 0, `:=`(cel_mun = NA_character_, nivel = "sem ancora municipal")]
  m1 <- unique(celulas[!is.na(cel_mun), .(celula = cel_mun, alvo = alvo_mun)])
  m1[, alvo := alvo * alvo_uf / sum(alvo)]
  pres[celulas, cel_mun := i.cel_mun, on = c("code_muni_1960", sit = "situacao")]

  # margem 2: sexo x faixa etaria, da tabela 33. A idade ignorada fica fora: o
  # arquivo tem quase nenhuma e a celula publicada e grande demais para caber.
  # Em unidade pequena demais para vinte e duas celulas -- so Fernando de Noronha,
  # com 76 domicilios -- fica so o total por sexo, como na amostra de 1,27%.
  m2 <- def[tabela == 33L & sexo %in% c("homens", "mulheres") & !item %in% c("total", "ignorada"),
            .(celula = paste0("sx_", sexo, "_", item), alvo = as.numeric(valor))]
  pres[, cel_sx := paste0("sx_", sexo, "_", faixa)]
  if(nrow(domicilios) < 40 * (nrow(m1) + nrow(m2))){
    m2 <- def[tabela == 32L & item == "presente" & sexo %in% c("homens", "mulheres"),
              .(celula = paste0("sx_", sexo), alvo = as.numeric(valor))]
    pres[, cel_sx := paste0("sx_", sexo)]
    message("  unidade pequena: margem de idade trocada pelo total por sexo")
  }

  # margem 3: sabem ler e escrever, 5 anos e mais, por sexo, da tabela 40
  m3 <- def[tabela == 40L & item == "sabem" & sexo %in% c("homens", "mulheres"),
            .(celula = paste0("lit_", sexo), alvo = as.numeric(valor))]
  pres[, cel_lit := data.table::fifelse(((!is.na(idade) & idade >= 5L) | V204 %in% 9L) & V211 %in% c(0L, 1L),
                                        paste0("lit_", sexo), NA_character_)]

  # as margens 1 e 2 somam quase a mesma populacao e o sistema de Newton fica
  # singular, ou perto disso: sai a menor celula municipal, que e a que menos
  # custa, e a sua populacao fica presa as margens demograficas
  alvos <- data.table::rbindlist(list(m1[-which.min(m1$alvo)], m2, m3))
  if(anyDuplicated(alvos$celula)) stop("celula duplicada nos controles da calibracao")
  if(any(!is.finite(alvos$alvo)) || any(alvos$alvo < 0)) stop("alvos da calibracao devem ser finitos e nao negativos")
  alvos <- alvos[alvo > 0]

  # X: uma linha por domicilio, uma coluna por celula, o valor e quantas pessoas
  # presentes daquele domicilio caem na celula
  longo <- data.table::rbindlist(list(
    pres[!is.na(cel_mun), .(id = censobr_idhousehold, celula = cel_mun)],
    pres[, .(id = censobr_idhousehold, celula = cel_sx)],
    pres[!is.na(cel_lit), .(id = censobr_idhousehold, celula = cel_lit)]))
  longo <- longo[, .N, by = .(id, celula)]
  vazias <- alvos[!celula %in% longo$celula]
  if(nrow(vazias) > 0)
    stop("controle positivo sem suporte amostral; nao retirar sem decisao explicita: ",
         paste(vazias$celula, collapse = ", "))
  longo <- longo[celula %in% alvos$celula]

  ids <- domicilios$censobr_idhousehold
  X <- Matrix::sparseMatrix(i = match(longo$id, ids), j = match(longo$celula, alvos$celula),
                            x = longo$N, dims = c(length(ids), nrow(alvos)), dimnames = list(NULL, alvos$celula))
  message("  calibrando ", format(nrow(alvos)), " celulas em ", format(nrow(domicilios)), " domicilios")
  # os limites do fator: a ancora municipal ja vem contida em [2; 8] pelo colapso,
  # isto e, g em [0,5; 2], e as margens demograficas pedem alguma folga em cima disso
  w <- raking_1960_amostra_127(X, alvos$alvo, rep(4, length(ids)), limites = c(0.25, 3))
  desvio <- max(abs(as.numeric(Matrix::crossprod(X, w)) - alvos$alvo) / alvos$alvo)
  if(!is.finite(desvio) || desvio > 1e-6) stop(uf, ": o raking nao convergiu, desvio relativo maximo ", signif(desvio, 3))

  domicilios[celulas, censobr_weight_nivel := i.nivel, on = c("code_muni_1960", "situacao")]
  domicilios[, `:=`(censobr_weight = w, censobr_weight_fator = w / 4)]


  # o peso do IBGE: razao a UF x situacao com peso inteiro sorteado para fechar o total
  set.seed(1960L)
  domicilios[, censobr_weight_ibge := NA_integer_]
  for(s in unique(domicilios$situacao)){
    idx   <- which(domicilios$situacao == s)
    n     <- domicilios$censobr_n_presentes[idx]
    alvo  <- universo[situacao == s, sum(universo, na.rm = TRUE)]
    r     <- alvo / sum(n)
    base  <- floor(r)
    ordem <- sample.int(length(idx))
    cum   <- cumsum(n[ordem])
    k     <- sum(cum <= alvo - base * sum(n))
    promove <- logical(length(idx))
    if(k > 0) promove[ordem[seq_len(k)]] <- TRUE
    resto <- alvo - base * sum(n) - (if(k > 0) cum[k] else 0)
    if(resto > 0){
      sobra <- ordem[-seq_len(k)]
      exato <- sobra[which(n[sobra] == resto)[1]]
      if(!is.na(exato)){ promove[exato] <- TRUE; resto <- 0 }
    }
    data.table::set(domicilios, i = idx, j = "censobr_weight_ibge", value = base + as.integer(promove))
    message("  peso IBGE ", s, ": razao ", round(r, 4), ", inteiros ", base, "/", base + 1L, ", residuo ", resto)
  }

  # a pessoa leva o peso e as colunas de desenho do seu domicilio
  leva <- c("situacao", "censobr_upa", "censobr_estrato", "censobr_fpc", "censobr_weight_desenho",
            "censobr_weight", "censobr_weight_fator", "censobr_weight_nivel", "censobr_weight_ibge")
  pessoas[, c("presente", "sexo", "idade", "faixa", "sit") := NULL]
  pessoas[domicilios, (leva) := mget(paste0("i.", leva)), on = "censobr_idhousehold"]

  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  saida <- c(file.path(out_dir, "domicilios_pesos.parquet"), file.path(out_dir, "pessoas_pesos.parquet"))
  arrow::write_parquet(domicilios, saida[1], compression = "zstd", compression_level = 1)
  arrow::write_parquet(pessoas,    saida[2], compression = "zstd", compression_level = 1)

  message("  ", data.table::uniqueN(domicilios$censobr_estrato), " estratos | peso de ",
          round(min(domicilios$censobr_weight), 3), " a ", round(max(domicilios$censobr_weight), 3),
          " (mediana ", round(stats::median(domicilios$censobr_weight), 3), ") | ancora municipal colapsada em ",
          domicilios[censobr_weight_nivel != "municipio x situacao", .N], " domicilios")

  rm(domicilios, pessoas); gc(verbose = FALSE)
  saida
}


# ------------------------------------------------------------------------------
# Passo 6 — reprodução das tabelas publicadas
#
# A pergunta é uma só: com os pesos do passo 5, esta amostra devolve o que o
# IBGE publicou? A Série Nacional traz, por unidade da federação, a condição de
# presença (tabela 32), a idade por sexo (33), a situação do domicílio (34), a
# cor (37), a alfabetização de 5 anos e mais (40) e os domicílios particulares
# (7). São seis tabelas e 34 unidades, já transcritas e com a aritmética
# fechada em references/censo_1960_resultados_definitivos_serie_nacional.csv.
#
# O que informa não é o que fecha por construção. censobr_weight calibra à
# população por município e situação, então a tabela 34 fecha por definição e a
# 32 quase, porque o universo é de presentes. O que testa de verdade são as
# tabelas que a calibração não viu: a idade por sexo, a cor, a alfabetização e
# a contagem de domicílios. Se elas saírem certas, o arquivo e os pesos estão
# certos; se saírem tortas, o erro está na leitura, não no peso.
#
# Para estas dezessete unidades há uma circularidade a declarar: as tabelas da
# Série Nacional foram apuradas com esta mesma amostra, com o método que
# censobr_weight_ibge reproduz. Então a comparação com censobr_weight_ibge mede
# o quanto a nossa leitura difere da do IBGE, e a comparação com censobr_weight
# mede quanto o refinamento municipal desloca as margens.
# ------------------------------------------------------------------------------
validate_definitivos_1960_amostra_25 <- function(paths, definitivos_path,
                                              out_dir = "./data_raw/microdata/1960/amostra_25"){

  message("Validating 1960 amostra de 25% against the Serie Nacional")

  def <- data.table::fread(definitivos_path, encoding = "UTF-8")
  pub <- def[nivel == "uf" & uf60 %in% UF_1960_AMOSTRA_25 &
    ((tabela %in% c(32L, 33L, 34L, 37L, 40L) & sexo %in% c("homens", "mulheres")) | tabela == 7L),
    .(uf60, tabela, nome, item, sexo, medida, publicado = valor)]
  pub[is.na(sexo), sexo := ""]; pub[is.na(medida), medida := ""]
  chaves <- c("uf60", "tabela", "item", "sexo", "medida")
  if(anyDuplicated(pub[, ..chaves])) stop("chave duplicada no gabarito da validacao")
  arquivos <- as.character(unlist(paths, use.names = FALSE))
  arquivos_dom <- arquivos[basename(arquivos) == "domicilios_pesos.parquet"]
  unidades_dom <- basename(dirname(arquivos_dom))
  if(anyDuplicated(unidades_dom) || any(!unidades_dom %in% names(UF_1960_AMOSTRA_25)))
    stop("UF repetida ou desconhecida nos caminhos de domicilios")
  arquivos <- arquivos[basename(arquivos) == "pessoas_pesos.parquet"]
  unidades <- basename(dirname(arquivos))
  if(anyDuplicated(unidades) || any(!unidades %in% names(UF_1960_AMOSTRA_25)))
    stop("UF repetida ou desconhecida nos caminhos de pessoas")

  medido <- list()
  for(i in seq_along(arquivos)){
    uf <- as.integer(UF_1960_AMOSTRA_25[[unidades[i]]])
    par_dom <- match(unidades[i], unidades_dom)
    p <- data.table::setDT(arrow::read_parquet(arquivos[i],
      col_select = c("UF", "V118", "V202", "V204", "V204B", "V206", "V211",
                     "censobr_weight", "censobr_weight_ibge",
                     if(!is.na(par_dom)) "censobr_idhousehold")))
    if(!nrow(p) || any(!p$UF %in% uf)) stop("arquivo pessoal vazio ou com UF incompatível com o caminho")
    if(!is.na(par_dom)){
      d <- data.table::setDT(arrow::read_parquet(arquivos_dom[par_dom],
        col_select = c("UF", "censobr_idhousehold", "V101", "V102", "V118",
                       "censobr_weight", "censobr_weight_ibge")))
      if(any(!d$UF %in% uf)) stop("arquivo domiciliar com UF incompatível com o caminho")
    }
    for(w in c("censobr_weight", "censobr_weight_ibge")){
      medido[[length(medido) + 1L]] <- tabular_pessoas_validacao_1960(
        p, pub[uf60 == uf & tabela != 7L], w)[, peso := w]
      if(!is.na(par_dom)) medido[[length(medido) + 1L]] <- tabular_domicilios_validacao_1960(
        p, d, pub[uf60 == uf & tabela == 7L], w)[, peso := w]
    }
    if(!is.na(par_dom)) rm(d)
    rm(p); gc(verbose = FALSE)
  }
  medido <- data.table::rbindlist(medido)
  grade <- data.table::rbindlist(lapply(c("censobr_weight", "censobr_weight_ibge"),
    function(w) data.table::copy(pub)[, peso := w]))
  cmp <- completar_validacao_pessoas_1960(grade, medido, c(chaves, "peso"))

  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  saida <- file.path(out_dir, "validacao_definitivos.csv")
  data.table::fwrite(cmp[order(peso, tabela, uf60, item, sexo, medida)], saida)

  resumo <- cmp[, .(celulas = .N, observadas = sum(status_celula == "observada"),
    sem_observacoes = sum(status_celula == "sem_observacoes"),
    nao_reconstruidas = sum(status_celula == "nao_reconstruida"),
    classificacao_incompleta = sum(status_celula == "classificacao_incompleta"),
    peso_ausente = sum(status_celula == "peso_ausente"), percentuais_validos = sum(is.finite(dif_pct)),
    erro_mediano_pct = if(any(is.finite(dif_pct))) median(abs(dif_pct), na.rm = TRUE) else NA_real_,
    erro_max_pct = if(any(is.finite(dif_pct))) max(abs(dif_pct), na.rm = TRUE) else NA_real_),
    by = .(peso, tabela)]
  print(resumo)
  saida
}


# ------------------------------------------------------------------------------
# Passo 7 — erros amostrais
#
# O desenho é de uma etapa: dentro de cada estrato — pasta × situação — os
# domicílios foram sorteados sistematicamente, um em quatro. A variância de um
# total é a dispersão dos totais expandidos entre os domicílios do estrato, com
# a correção de população finita de 1/4:
#
#   V = Σ_h (1 − f) · n_h/(n_h − 1) · Σ_i (w_i y_i − média_h)²,  f = 1/4
#
# É o que survey::svydesign(ids = ~censobr_upa, strata = ~censobr_estrato,
# weights = ~censobr_weight, fpc = ~censobr_fpc) daria, escrito à mão para não
# acrescentar dependência ao pipeline. O estrato com um domicílio só não mede
# variância e entra com contribuição zero; são cinco em 18.400.
#
# O efeito de desenho esperado fica perto de 1 nas variáveis de domicílio, e
# acima de 1 nas de pessoa, pela aglomeração dentro do domicílio: o domicílio
# entra inteiro ou não entra.
# ------------------------------------------------------------------------------
sampling_errors_1960_amostra_25 <- function(paths){

  message("Computing sampling errors in 1960 amostra de 25%")

  dominios <- list(
    pessoas          = quote(TRUE),
    presentes        = quote(!V202 %in% c(3L, 4L)),
    urbana           = quote(!V202 %in% c(3L, 4L) & V118 != 5L),
    rural            = quote(!V202 %in% c(3L, 4L) & V118 == 5L),
    analfabetos_15   = quote(V211 %in% c(2L, 3L) & !is.na(idade) & idade >= 15L),
    criancas_0_4     = quote(!V202 %in% c(3L, 4L) & !is.na(idade) & idade <= 4L),
    com_rendimento   = quote(V219 %in% 1:8))

  acum <- list(); n_total <- 0; N_total <- 0
  for(uf in names(UF_1960_AMOSTRA_25)){
    p <- data.table::setDT(arrow::read_parquet(
      file.path("./data_raw/microdata/1960/amostra_25", uf, "pessoas_pesos.parquet"),
      col_select = c("UF", "V118", "V202", "V204", "V204B", "V211", "V219",
                     "censobr_upa", "censobr_estrato", "censobr_weight")))
    p[, idade := data.table::fifelse(V204 == 1L, V204B,
                 data.table::fifelse(V204 == 5L, 100L + V204B, NA_integer_))]
    n_total <- n_total + nrow(p); N_total <- N_total + sum(p$censobr_weight)

    for(d in names(dominios)){
      p[, y := as.integer(eval(dominios[[d]]))]
      # o total do dominio em cada domicilio, ja expandido
      dom <- p[, .(t = sum(y * censobr_weight), n_pes = sum(y)),
               by = .(censobr_estrato, censobr_upa)]
      acum[[length(acum) + 1]] <- dom[, .(dominio = d, uf = uf, n_dom = .N,
                                          soma = sum(t), soma2 = sum(t^2),
                                          pessoas = sum(n_pes)), by = censobr_estrato]
    }
    rm(p); gc(verbose = FALSE)
  }
  e <- data.table::rbindlist(acum)

  # a variancia dentro do estrato, com correcao finita de 1/4
  e[, v := data.table::fifelse(n_dom > 1,
             (1 - 0.25) * n_dom / (n_dom - 1) * (soma2 - soma^2 / n_dom), 0)]
  r <- e[, .(estimativa = sum(soma), variancia = sum(v), pessoas = sum(pessoas),
             estratos = .N, domicilios = sum(n_dom)), by = dominio]
  r[, `:=`(erro_padrao = sqrt(variancia),
           cv_pct = round(100 * sqrt(variancia) / estimativa, 3))]
  # efeito de desenho: quantas vezes esta amostra e menos precisa que um sorteio
  # simples de pessoas do mesmo tamanho, com a mesma correcao finita
  r[, p_chapeu := estimativa / N_total]
  r[, v_srs := N_total^2 * (1 - 0.25) * p_chapeu * (1 - p_chapeu) / (n_total - 1)]
  # num dominio que e quase toda a populacao o denominador tende a zero e o
  # efeito de desenho perde sentido: fica ausente
  r[, deff := data.table::fifelse(p_chapeu < 0.98, round(variancia / v_srs, 2), NA_real_)]
  r[, c("variancia", "p_chapeu", "v_srs") := NULL]
  print(r[order(-estimativa)])

  saida <- "./data_raw/microdata/1960/amostra_25/erros_amostrais.csv"
  data.table::fwrite(r, saida)
  saida
}


# ------------------------------------------------------------------------------
# Passo 8 — a amostra de 1,27% dentro desta
#
# A amostra de 1,27% é uma subamostra desta: uma pasta em vinte, sorteada em
# 1965 do mesmo cadastro. Os dois arquivos, portanto, descrevem os mesmos
# domicílios, e casam pela chave do questionário — pasta e boletim. É a única
# validação registro a registro que existe para 1960, e nenhuma das duas
# amostras a tem sozinha.
#
# Ela serve a dois propósitos. O primeiro é alarme de erro nosso: se a chave
# casar mal, ou se o município e a situação divergirem acima de uma fração de
# um por cento, o defeito está no nosso parsing, não nas fontes. O segundo é
# medir o desacordo real entre as duas transcrições, que existe e é grande em
# algumas variáveis — a de 1,27% foi perfurada de cartões que sofreram dano de
# fita, e a de 25% não. Este passo não corrige nada: entrega a matriz de
# divergência por unidade da federação e por variável, que é o insumo da
# compilação das duas amostras.
# ------------------------------------------------------------------------------
compare_127_1960_amostra_25 <- function(paths, path_127){

  message("Comparing 1960 amostra de 25% with the 1,27% sample, record by record")

  d127 <- data.table::setDT(arrow::read_parquet(path_127))
  d127 <- d127[UF %in% UF_1960_AMOSTRA_25]
  d127[, `:=`(pasta_n = as.integer(pasta), boletim_n = as.integer(boletim))]
  vars <- c("V101", "V102", "V103", "V104", "V105", "V106", "V107",
            "V108", "V109", "V110", "V111", "V112", "V113", "V116", "V118")

  out <- list()
  for(uf in names(UF_1960_AMOSTRA_25)){
    codigo <- as.integer(UF_1960_AMOSTRA_25[[uf]])
    a <- data.table::setDT(arrow::read_parquet(
      file.path("./data_raw/microdata/1960/amostra_25", uf, "domicilios_pesos.parquet"),
      col_select = c("UF", "v001", "v002", vars)))
    b <- d127[UF == codigo, c("pasta_n", "boletim_n", vars), with = FALSE]
    if(nrow(b) == 0) next

    m <- merge(a, b, by.x = c("v001", "v002"), by.y = c("pasta_n", "boletim_n"),
               suffixes = c("_25", "_127"))
    linhas <- data.table::rbindlist(lapply(vars, function(v){
      x <- m[[paste0(v, "_25")]]; y <- m[[paste0(v, "_127")]]
      comparaveis <- !is.na(x) & !is.na(y)
      data.table(uf = uf, variavel = v, comparaveis = sum(comparaveis),
                 divergentes = sum(comparaveis & x != y))
    }))
    linhas[, `:=`(casados = nrow(m), na_127 = nrow(b), sem_par_127 = nrow(b) - nrow(m))]
    out[[length(out) + 1]] <- linhas
    rm(a, b, m); gc(verbose = FALSE)
  }
  r <- data.table::rbindlist(out)
  r[, divergencia_pct := round(100 * divergentes / comparaveis, 2)]

  saida <- "./data_raw/microdata/1960/amostra_25/comparacao_amostra_127.csv"
  data.table::fwrite(r[order(uf, variavel)], saida)

  message("  domicilios da amostra de 1,27% nas dezessete unidades: ",
          format(sum(unique(r[, .(uf, na_127)])$na_127), big.mark = ".", decimal.mark = ","),
          " | casados: ", format(sum(unique(r[, .(uf, casados)])$casados), big.mark = ".", decimal.mark = ","),
          " | sem par: ", sum(unique(r[, .(uf, sem_par_127)])$sem_par_127))
  print(r[, .(divergencia_pct = round(100 * sum(divergentes) / sum(comparaveis), 2)),
          by = variavel][order(-divergencia_pct)])
  saida
}
