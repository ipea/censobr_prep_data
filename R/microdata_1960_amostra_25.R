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
# audit_1960_amostra_25, read_1960_amostra_25, build_1960_amostra_25.


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
# O "Ignorado" do questionário. O Código do Censo dá a cada quesito do domicílio
# um código próprio de ignorado — V102 = 7, V103 = 0, V105 = 4, V106 = 9,
# V107 = 5, V108 = 7, V109 = 9, V110 = 1 —, e esses ficam como estão, porque são
# categorias do dicionário. O exemplar do Código que temos se interrompe no
# quesito J e não cobre cômodos nem dormitórios, que são campos numéricos; neles
# o ignorado foi gravado como zero, e zero não é uma categoria que o usuário
# enxergue: 23.109 domicílios com zero cômodos abrigam 121.769 pessoas, média de
# 5,28, acima da média do país. Viram ausente, marcado em
# censobr_comodos_ignorado.
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

  # o ignorado dos campos numericos veio como zero -- ver o cabecalho deste passo
  familias[, censobr_comodos_ignorado := V112 == 0 | V113 == 0]
  familias[is.na(censobr_comodos_ignorado), censobr_comodos_ignorado := FALSE]
  familias[V112 == 0, V112 := NA_integer_]
  familias[V113 == 0, V113 := NA_integer_]

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
  leva <- c(geo, "censobr_tipo_unidade", "censobr_comodos_ignorado", pagina)
  pessoas[familias, (leva) := mget(paste0("i.", leva)), on = "censobr_idfamily"]

  data.table::setcolorder(domicilios, c(geo, "censobr_idhousehold", "censobr_tipo_unidade"))
  data.table::setcolorder(pessoas,    c(geo, "censobr_idhousehold", "censobr_idfamily", "censobr_tipo_unidade"))

  saida <- c(file.path(in_dir, "domicilios.parquet"), file.path(in_dir, "pessoas_geo.parquet"))
  arrow::write_parquet(domicilios, saida[1], compression = "zstd", compression_level = 1)
  arrow::write_parquet(pessoas,    saida[2], compression = "zstd", compression_level = 1)

  message("  ", format(nrow(domicilios), big.mark = ".", decimal.mark = ","), " domicilios (",
          domicilios[censobr_tipo_unidade == "boletim individual", .N], " individuais, ",
          domicilios[censobr_tipo_unidade == "domicilio coletivo", .N], " coletivos) | distrito com nome: ",
          round(100 * domicilios[!is.na(name_district_1960), .N] / nrow(domicilios), 1), "% | comodos ignorados: ",
          domicilios[censobr_comodos_ignorado == TRUE, .N])

  rm(familias, pessoas, domicilios); gc(verbose = FALSE)
  saida
}
