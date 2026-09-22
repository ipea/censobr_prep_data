# 1960 microdata sample -- a compilacao das duas amostras.
#
# A amostra de 1,27% e subamostra da de 25% nas dezessete unidades em que as
# duas existem: uma pasta em vinte do mesmo cadastro, casando pela chave do
# questionario. Juntar registro a registro duplicaria gente. A compilacao e,
# portanto, uma particao por unidade da federacao -- dezessete vem da amostra de
# 25% e onze da de 1,27% -- e as pastas das duas metades nao tem um numero em
# comum, o que confirma que a particao e limpa.
#
# As onze sao exatamente aquelas cujos tomos do Volume I foram apurados pelo
# Boletim Geral completo. Ali a calibracao se ancora em contagem completa, que e
# informacao externa; nas dezessete as tabelas publicadas sairam desta mesma
# amostra, e a circularidade fica declarada nos documentos de cada estagio.
#
# Dois problemas que os dois estagios deixaram em aberto se resolvem aqui pela
# propria particao: o Distrito Federal, que na amostra de 1,27% ficava no peso
# de desenho e ~60% subestimado, vem da de 25%, onde fecha; e Alto Garcas, sem
# domicilio sorteado na de 25%, tem a populacao redistribuida por Mato Grosso.
#
# O compilado expande 70.191.146 presentes contra 70.191.370 publicados.
#
# Public API: estratos_1960, compile_1960, save_microdata_1960.


# As onze unidades que so a amostra de 1,27% cobre.
UF_1960_AMOSTRA_127 <- c(ro = 0, ac = 1, am = 2, rr = 3, pa = 4, ap = 6,
                         ma = 10, pi = 12, es = 51, gb = 54, sc = 74)

# O codigo IBGE de cada unidade em 1960 e o de hoje. Guanabara (34) e Fernando
# de Noronha (20) existiram como unidade da federacao e tem codigo proprio na
# numeracao da epoca; hoje o territorio de uma e o municipio do Rio de Janeiro e
# o da outra um distrito estadual de Pernambuco. A Serra dos Aimores nunca teve
# codigo -- era o litigio MG/ES, que o censo tratou como unidade a parte e que
# depois se repartiu entre os dois estados -- e por isso fica NA nos dois, com o
# UF do censo (50) como unico identificador.
UF_1960_CODIGOS <- data.table::data.table(
  UF                = c(  0,   1,   2,   3,   4,   6,  10,  12,  14,  17,  19,  21,  24,  25,
                         30,  31,  40,  50,  51,  52,  54,  60,  71,  74,  81,  91,  94,  97),
  code_state_1960   = c( 11,  12,  13,  14,  15,  16,  21,  22,  23,  24,  25,  26,  20,  27,
                         28,  29,  31,  NA,  32,  33,  34,  35,  41,  42,  43,  51,  52,  53),
  code_state        = c( 11,  12,  13,  14,  15,  16,  21,  22,  23,  24,  25,  26,  26,  27,
                         28,  29,  31,  NA,  32,  33,  33,  35,  41,  42,  43,  51,  52,  53),
  abbrev_state_1960 = c("RO","AC","AM","RR","PA","AP","MA","PI","CE","RN","PB","PE","FN","AL",
                        "SE","BA","MG",  NA,"ES","RJ","GB","SP","PR","SC","RS","MT","GO","DF"))

# O crosswalk de municipios traz, nas tres unidades que nao existem mais, o
# codigo da malha de 1960 do geobr, que nao e codigo de hoje. O territorio da
# Guanabara e o do municipio do Rio de Janeiro e o de Fernando de Noronha e o do
# distrito estadual de Pernambuco: e o codigo deles que entra em code_muni.
MUNI_1960_ATUAL <- data.table::data.table(
  code_muni      = c(3099901L, 2000107L, 99L),
  code_muni_novo = c(3304557L, 2605459L, NA_integer_))

# A ordem das colunas publicadas: geografia, identificacao, a chave do
# questionario, o questionario na ordem do formulario, as contagens, o desenho,
# os pesos e as marcas de auditoria.
COLUNAS_1960_DOM <- c(
  "code_region", "name_region", "code_state", "abbrev_state", "name_state",
  "code_muni", "code_muni_1960", "name_muni_1960",
  "code_district_1960", "name_district_1960", "code_bairro_1960", "name_bairro_1960",
  "name_region_1960", "code_state_1960", "abbrev_state_1960", "name_state_1960",
  "censobr_idhousehold", "censobr_amostra", "censobr_tipo_unidade",
  "v001", "v002", "v003", "v004", "v100",
  "V101", "V102", "V103", "V104", "V105", "V106", "V107", "V108", "V109", "V110",
  "V111", "V112", "V113", "UF", "V116", "V117", "V118", "situacao",
  "censobr_n_listadas", "censobr_n_residentes", "censobr_n_presentes", "censobr_n_familias",
  "censobr_estrato", "censobr_upa", "censobr_fpc", "censobr_usa", "censobr_fpc2",
  "censobr_weight", "censobr_weight_fator", "censobr_weight_desenho",
  "censobr_weight_nivel", "censobr_weight_ibge", "censobr_weight_1965", "censobr_weight_1965_fator",
  "censobr_favela", "censobr_muni_corrigido", "censobr_uf_corrigida",
  "censobr_diagnostico", "censobr_variaveis_anuladas", "censobr_familia_origem",
  "censobr_convivente_isolada", "censobr_dois_chefes", "censobr_linha")

COLUNAS_1960_PES <- c(
  "code_region", "name_region", "code_state", "abbrev_state", "name_state",
  "code_muni", "code_muni_1960", "name_muni_1960",
  "code_district_1960", "name_district_1960", "code_bairro_1960", "name_bairro_1960",
  "name_region_1960", "code_state_1960", "abbrev_state_1960", "name_state_1960",
  "censobr_idperson", "censobr_idfamily", "censobr_idhousehold",
  "censobr_amostra", "censobr_tipo_unidade",
  "v001", "v002", "v003", "v004",
  "V101", "V102", "V103", "V104", "V105", "V106", "V107", "V108", "V109", "V110",
  "V111", "V112", "V113", "UF", "V116", "V117", "V118", "situacao",
  "V202", "V203", "V204", "V204B", "V205", "V206", "V207", "V208", "V209", "V299",
  "V210", "V211", "V212", "V213", "V214", "V215", "V216", "V217", "V218", "V219",
  "V220", "V221", "V223", "V223B", "V224",
  "censobr_n_listadas", "censobr_n_residentes", "censobr_n_presentes", "censobr_n_familias",
  "censobr_estrato", "censobr_upa", "censobr_fpc", "censobr_usa", "censobr_fpc2",
  "censobr_weight", "censobr_weight_fator", "censobr_weight_desenho",
  "censobr_weight_nivel", "censobr_weight_ibge", "censobr_weight_1965", "censobr_weight_1965_fator",
  "censobr_favela", "censobr_muni_corrigido", "censobr_uf_corrigida",
  "censobr_diagnostico", "censobr_variaveis_anuladas", "censobr_tipo_registro",
  "censobr_duplicata_mantida", "censobr_familia_origem", "censobr_v208_imputada",
  "censobr_v217_fora_da_faixa", "censobr_v218_fora_da_faixa",
  "censobr_flag_conjuge_mesmo_sexo", "censobr_flag_filho_mais_velho",
  "censobr_flag_casamento_impossivel", "censobr_linha")

# As colunas que so uma das metades tem, e o tipo com que a outra as recebe --
# um parquet por unidade com esquema diferente impediria o open_dataset de ler
# as 28 como uma tabela so.
TIPOS_1960_FALTANTES <- c(
  name_muni_1960 = "character", name_bairro_1960 = "character",
  code_bairro_1960 = "integer",
  v003 = "integer", v004 = "integer", v100 = "integer",
  censobr_weight_nivel = "character", censobr_weight_ibge = "integer",
  censobr_weight_1965 = "numeric", censobr_weight_1965_fator = "numeric",
  censobr_uf_corrigida = "logical", censobr_diagnostico = "character",
  censobr_familia_origem = "character", censobr_dois_chefes = "logical",
  censobr_tipo_registro = "character", censobr_duplicata_mantida = "logical",
  censobr_v208_imputada = "logical", censobr_v217_fora_da_faixa = "logical",
  censobr_v218_fora_da_faixa = "logical", censobr_flag_conjuge_mesmo_sexo = "logical",
  censobr_flag_filho_mais_velho = "logical", censobr_flag_casamento_impossivel = "logical")


# ------------------------------------------------------------------------------
# Os estratos das onze unidades
#
# O estrato da amostra de 1,27% foi construido sobre as 28 unidades e nao
# sobrevive ao corte: dos 75, so 23 tem pasta nas onze que ficam, cinco
# atravessam a fronteira das dezessete e dois caem para uma pasta so, que nao
# mede variancia. A regra de colapso do passo 8 daquele estagio -- a unidade
# solitaria num grupo se junta a primeira vizinha da mesma regiao, por
# VIZINHAS_1960 -- e reexecutada aqui sobre as onze, com uma extensao que o
# corte obriga: a unidade cuja regiao nao tem nenhuma vizinha entre as onze
# junta o grupo solitario ao maior grupo dela mesma. E o caso da Guanabara, cujo
# unico grupo rural tem uma pasta e cujas vizinhas -- Rio de Janeiro e Minas --
# vem todas da amostra de 25%.
#
# Os pesos nao mudam: as celulas da calibracao sao por unidade da federacao, e
# cada uma das onze ja reproduz o seu total publicado exatamente.
# ------------------------------------------------------------------------------
estratos_1960 <- function(path_127_dom){

  message("Restratifying the 1,27% sample over the eleven units")

  d <- data.table::setDT(arrow::read_parquet(path_127_dom,
         col_select = c("UF", "censobr_upa", "censobr_estrato")))
  d <- d[UF %in% UF_1960_AMOSTRA_127]
  d[, grupo := sub("^.* - ", "", censobr_estrato)]

  celulas <- unique(d[, .(UF, grupo, censobr_upa)])[, .(pastas = .N), by = .(UF, grupo)]
  celulas[, estrato := paste0("UF ", UF, " - ", grupo)]
  repeat{
    por_estrato <- celulas[, .(pastas = sum(pastas)), by = estrato]
    solitaria <- celulas[estrato %in% por_estrato[pastas == 1, estrato]][1]
    if(is.na(solitaria$UF)) break
    vizinhas <- VIZINHAS_1960[[as.character(solitaria$UF)]]
    vizinha  <- celulas[UF %in% vizinhas & grupo == solitaria$grupo][order(match(UF, vizinhas))][1]
    if(is.na(vizinha$UF))
      vizinha <- celulas[UF == solitaria$UF & estrato != solitaria$estrato][order(-pastas)][1]
    if(is.na(vizinha$UF)) stop("sem estrato vizinho para ", solitaria$estrato)
    celulas[estrato == solitaria$estrato, estrato := vizinha$estrato]
  }
  celulas[, rotulo := paste0("UF ", paste(sort(unique(UF)), collapse = "+"), " - ",
                             paste(sort(unique(grupo)), collapse = "+")), by = estrato]

  message("  ", data.table::uniqueN(celulas$rotulo), " estratos em ", sum(celulas$pastas),
          " pastas; menor estrato com ", min(celulas[, .(p = sum(pastas)), by = rotulo]$p), " pastas")
  celulas[, .(UF, grupo, censobr_estrato = rotulo)]
}


# ------------------------------------------------------------------------------
# A compilacao, uma unidade da federacao por vez
#
# Cada unidade vem de uma amostra so, e o branch grava um parquet harmonizado
# por unidade. A harmonizacao e a uniao das colunas das duas metades, com NA do
# lado que nao tem: censobr_weight_ibge e censobr_weight_nivel so nas dezessete,
# censobr_weight_1965 e as marcas de dano da fita so nas onze.
#
# Tres coisas se reconstroem aqui, e nao podiam vir prontas dos estagios:
#
#  - os identificadores. censobr_idhousehold reinicia em 1 em cada unidade na
#    amostra de 25% -- 3.066.365 domicilios com 740.936 valores distintos --, e
#    a chave do questionario, unica nas dezessete, tem 58 repeticoes nas onze,
#    todas pares de um registro integro com uma familia reconstruida. O
#    identificador global e UF x 10.000.000 + sequencia dentro da unidade, que
#    cabe em int32 nos tres niveis (o maior e Sao Paulo, 3.319.710 pessoas).
#
#  - o desenho em duas etapas. Nas dezessete sorteia-se o domicilio, um em
#    quatro, e a segunda etapa e degenerada (fpc2 = 1); nas onze sorteia-se a
#    pasta, uma em vinte, e dentro dela o domicilio, um em quatro. Os rotulos de
#    estrato e de unidade primaria das duas metades nao colidem, entao uma
#    chamada so de svydesign descreve o pais inteiro.
#
#  - a geografia do censobr, que nenhum dos dois estagios tem: o estado de hoje
#    e o de 1960 em colunas separadas, como a regra do municipio ja manda.
# ------------------------------------------------------------------------------
compile_1960 <- function(paths_25, paths_127, estratos, unidade, municipios_path, definitivos_path,
                         out_dir = file.path("./data_raw/microdata/1960/compilada", unidade)){

  message("Compiling 1960: ", unidade)

  do_25 <- unidade %in% names(UF_1960_AMOSTRA_25)
  uf60  <- as.integer(if(do_25) UF_1960_AMOSTRA_25[[unidade]] else UF_1960_AMOSTRA_127[[unidade]])

  if(do_25){
    arquivos <- as.character(unlist(paths_25, use.names = FALSE))
    arquivos <- arquivos[basename(dirname(arquivos)) == unidade]
    path_dom <- arquivos[basename(arquivos) == "domicilios_pesos.parquet"]
    path_pes <- arquivos[basename(arquivos) == "pessoas_pesos.parquet"]
    if(length(path_dom) != 1L || length(path_pes) != 1L)
      stop("informar um par de arquivos com pesos por UF na compilacao: ", unidade)
    dom <- data.table::setDT(arrow::read_parquet(path_dom))
    pes <- data.table::setDT(arrow::read_parquet(path_pes))
    amostra <- "25%"
  } else {
    dom <- data.table::setDT(arrow::open_dataset(paths_127[2]) |> dplyr::filter(UF == uf60) |> dplyr::collect())
    pes <- data.table::setDT(arrow::open_dataset(paths_127[1]) |> dplyr::filter(UF == uf60) |> dplyr::collect())
    if(any(dom$censobr_familia_origem %in% "recuperada_25") ||
       any(pes$censobr_familia_origem %in% "recuperada_25"))
      stop("Compilacao suspensa: cartoes recuperados exigem procedencia no esquema final; conservar intermediarios.")
    data.table::setindex(dom, NULL); data.table::setindex(pes, NULL)
    amostra <- "1,27%"
    munis <- data.table::fread(municipios_path, encoding = "UTF-8")[, .(cod60, nome)]

    # a chave do questionario no formato da amostra de 25%: o distrito e V117, e
    # os digitos de controle nao existem no arquivo de 1,27%
    for(x in list(dom, pes)){
      x[, `:=`(v001 = as.integer(pasta), v002 = as.integer(boletim), V117 = as.integer(distrito),
               situacao = data.table::fifelse(V118 == 5L, "rural", "urbana"),
               censobr_tipo_unidade = data.table::fcase(V101 == 3L, "domicilio coletivo",
                                                        V101 == 9L, "boletim individual",
                                                        default = "domicilio particular"),
               grupo = sub("^.* - ", "", censobr_estrato))]
      x[estratos, censobr_estrato := i.censobr_estrato, on = c("UF", "grupo")]
      x[, grupo := NULL]
      # o nome do municipio: o estagio de 1,27% nao o produz, e a coluna ficaria
      # vazia nas onze unidades
      x[munis, name_muni_1960 := i.nome, on = c(code_muni_1960 = "cod60")]
    }
  }
  if(!nrow(dom) || !nrow(pes) || any(!dom$UF %in% uf60) || any(!pes$UF %in% uf60))
    stop("arquivos vazios ou com UF incompativel na compilacao")
  if(anyNA(dom$censobr_idhousehold) || anyDuplicated(dom$censobr_idhousehold))
    stop("identificadores ausentes ou duplicados nos domicilios da compilacao")
  if(any(!pes$censobr_idhousehold %in% dom$censobr_idhousehold)) stop("pessoas sem domicilio na compilacao")
  dom[, censobr_amostra := amostra]
  pes[, censobr_amostra := amostra]

  # os identificadores globais, deterministicos na ordem do cadastro
  data.table::setorder(dom, v001, v002)
  dom[, id_novo := uf60 * 10000000L + seq_len(.N)]
  pes[dom, id_novo := i.id_novo, on = "censobr_idhousehold"]
  familias <- unique(pes[, .(censobr_idfamily)])[order(censobr_idfamily)][, idfam_novo := uf60 * 10000000L + seq_len(.N)]
  pes[familias, idfam_novo := i.idfam_novo, on = "censobr_idfamily"]
  dom[, `:=`(censobr_idhousehold = id_novo, id_novo = NULL)]
  pes[, `:=`(censobr_idhousehold = id_novo, censobr_idfamily = idfam_novo,
             id_novo = NULL, idfam_novo = NULL)]
  data.table::setorder(pes, censobr_idhousehold, linha)
  pes[, censobr_idperson := uf60 * 10000000L + seq_len(.N)]

  # o desenho em duas etapas
  if(do_25){
    dom[, `:=`(censobr_upa = censobr_idhousehold, censobr_fpc = 0.25,
               censobr_usa = censobr_idhousehold, censobr_fpc2 = 1)]
  } else {
    # a pasta do desenho, e nao a do cartao: em dois registros o estagio de 1,27% devolveu uma chave
    # danificada a pasta certa, e e essa que a unidade primaria tem de seguir. v001 continua com o que
    # o cartao gravou, e censobr_diagnostico marca os dois
    dom[, pasta_desenho := as.integer(sub("^.*-", "", trimws(censobr_upa)))]
    dom[, `:=`(censobr_upa = pasta_desenho, censobr_fpc = 0.05,
               censobr_usa = censobr_idhousehold, censobr_fpc2 = 0.25)]
    dom[, pasta_desenho := NULL]
  }
  # as colunas de desenho descem do domicilio inteiras: as antigas saem antes,
  # senao a pasta em texto da amostra de 1,27% impoe o tipo a coluna nova
  leva <- c("censobr_upa", "censobr_fpc", "censobr_usa", "censobr_fpc2", "censobr_estrato")
  pes[, intersect(leva, names(pes)) := NULL]
  pes[dom, (leva) := mget(paste0("i.", leva)), on = "censobr_idhousehold"]

  # a geografia do censobr: o estado de hoje e o de 1960, e a regiao das duas epocas
  def <- data.table::fread(definitivos_path, encoding = "UTF-8")
  def <- unique(def[nivel == "uf", .(UF = uf60, name_state_1960 = nome, name_region_1960 = regiao)])
  ufs <- data.table::as.data.table(states_censobr())
  ufs <- ufs[, .(code_state = as.integer(code_state), abbrev_state, name_state,
                 code_region = as.integer(code_region), name_region)]
  for(x in list(dom, pes)){
    x[UF_1960_CODIGOS, `:=`(code_state_1960 = i.code_state_1960, code_state = i.code_state,
                            abbrev_state_1960 = i.abbrev_state_1960), on = "UF"]
    x[def, `:=`(name_state_1960 = i.name_state_1960, name_region_1960 = i.name_region_1960), on = "UF"]
    x[ufs, `:=`(abbrev_state = i.abbrev_state, name_state = i.name_state,
                code_region = i.code_region, name_region = i.name_region), on = "code_state"]
    x[MUNI_1960_ATUAL, code_muni := i.code_muni_novo, on = "code_muni"]
    data.table::setnames(x, "linha", "censobr_linha")
  }

  # esquema uniforme: a metade que nao tem a coluna recebe NA do tipo declarado
  tabelas <- list(dom, pes)
  alvos   <- list(COLUNAS_1960_DOM, COLUNAS_1960_PES)
  for(i in 1:2)
    for(col in setdiff(alvos[[i]], names(tabelas[[i]])))
      data.table::set(tabelas[[i]], j = col, value = as(NA, TIPOS_1960_FALTANTES[[col]]))

  saida <- out_dir
  dir.create(saida, recursive = TRUE, showWarnings = FALSE)
  saida <- c(file.path(saida, "domicilios.parquet"), file.path(saida, "pessoas.parquet"))
  arrow::write_parquet(dom[, .SD, .SDcols = COLUNAS_1960_DOM], saida[1],
                       compression = "zstd", compression_level = 1)
  arrow::write_parquet(pes[, .SD, .SDcols = COLUNAS_1960_PES], saida[2],
                       compression = "zstd", compression_level = 1)

  message("  ", format(nrow(dom), big.mark = "."), " domicilios, ",
          format(nrow(pes), big.mark = "."), " pessoas, ",
          data.table::uniqueN(dom$censobr_estrato), " estratos")
  rm(dom, pes); gc(verbose = FALSE)
  saida
}


# ------------------------------------------------------------------------------
# A gravacao
#
# Os 28 parquets por unidade viram um arquivo so, por streaming: a tabela de
# pessoas tem 15,1 milhoes de linhas e nao passa pela memoria. E o idioma de
# save_microdata_1970(), com zstd-22 entrando uma vez so, aqui.
# ------------------------------------------------------------------------------

# As colunas de geografia que so 1960 tem: a divisao territorial da epoca e o
# bairro da Guanabara. Saem logo depois das transversais de GEO_COLS_CENSOBR,
# na ordem daqui. Moram neste arquivo, e nao na constante compartilhada, para
# que mexer nelas invalide 1960 e mais nada.
GEO_COLS_HIST_1960 <- c("code_muni_1960", "name_muni_1960",
                        "code_district_1960", "name_district_1960",
                        "code_bairro_1960", "name_bairro_1960",
                        "name_region_1960",
                        "code_state_1960", "abbrev_state_1960", "name_state_1960")

save_microdata_1960 <- function(paths, dataset_name, data_version){

  message("Saving microdata 1960: ", dataset_name)

  arquivo <- switch(dataset_name, households = "domicilios.parquet", population = "pessoas.parquet")
  arrw <- arrow::open_dataset(paths[basename(paths) == arquivo])
  arrw <- relocate_geo_cols_censobr(arrw, GEO_COLS_HIST_1960)
  arrw <- cast_censobr_types(arrw, paste0("1960_", dataset_name))

  out_dir <- "./data/microdata_sample/1960"
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  temp_dir <- file.path(out_dir, paste0("tmp_", dataset_name))
  unlink(temp_dir, recursive = TRUE)

  arrow::write_dataset(arrw,
                       path               = temp_dir,
                       format             = "parquet",
                       compression        = "zstd",
                       compression_level  = 22,
                       min_rows_per_group = 1e6L,
                       max_rows_per_group = 1e6L,
                       basename_template  = "part-{i}.parquet")

  dest_file <- paste0(out_dir, "/1960_", dataset_name, "_", data_version, ".parquet")
  file.rename(file.path(temp_dir, "part-0.parquet"), dest_file)
  unlink(temp_dir, recursive = TRUE)

  dest_file
}


# ------------------------------------------------------------------------------
# A validacao: o pais inteiro contra a Serie Nacional
#
# As cinco tabelas por unidade da federacao do volume nacional -- condicao de
# presenca (32), idade por sexo (33), situacao (34), cor (37) e alfabetizacao de
# 5 anos e mais (40) -- reproduzidas com censobr_weight nas 28 unidades, mais a
# linha do Brasil, que nenhum dos dois estagios podia fechar sozinho.
#
# O que a comparacao informa e diferente em cada metade. Nas dezessete as
# tabelas foram apuradas com esta mesma amostra, e o que se mede e a nossa
# leitura; nas onze elas vem do Boletim Geral completo, e a comparacao e contra
# contagem externa de verdade.
# ------------------------------------------------------------------------------
validate_1960 <- function(paths, definitivos_path,
                          out_dir = "./data_raw/microdata/1960/compilada"){

  message("Validating the 1960 compilation against the Serie Nacional")

  def <- data.table::fread(definitivos_path, encoding = "UTF-8")
  def[nivel == "brasil", uf60 := 999L]
  pub <- def[nivel %in% c("uf", "brasil") &
    ((tabela %in% c(32L, 33L, 34L, 37L, 40L) & sexo %in% c("homens", "mulheres")) | tabela == 7L),
    .(uf60, tabela, nome, item, sexo, medida, publicado = valor)]
  pub[is.na(sexo), sexo := ""]; pub[is.na(medida), medida := ""]
  chaves <- c("uf60", "tabela", "item", "sexo", "medida")
  if(anyDuplicated(pub[, ..chaves])) stop("chave duplicada no gabarito da validacao")
  ufs <- c(UF_1960_AMOSTRA_25, UF_1960_AMOSTRA_127)
  arquivos <- as.character(unlist(paths, use.names = FALSE))
  arquivos_dom <- arquivos[basename(arquivos) == "domicilios.parquet"]
  unidades_dom <- basename(dirname(arquivos_dom))
  if(anyDuplicated(unidades_dom) || any(!unidades_dom %in% names(ufs)))
    stop("UF repetida ou desconhecida nos caminhos de domicilios")
  arquivos <- arquivos[basename(arquivos) == "pessoas.parquet"]
  unidades <- basename(dirname(arquivos))
  if(anyDuplicated(unidades) || any(!unidades %in% names(ufs)))
    stop("UF repetida ou desconhecida nos caminhos de pessoas")

  medido <- list()
  for(i in seq_along(arquivos)){
    uf <- as.integer(ufs[[unidades[i]]])
    par_dom <- match(unidades[i], unidades_dom)
    p <- data.table::setDT(arrow::read_parquet(arquivos[i],
      col_select = c("UF", "V118", "V202", "V204", "V204B", "V206", "V211", "censobr_weight",
                     if(!is.na(par_dom)) "censobr_idhousehold")))
    if(!nrow(p) || any(!p$UF %in% uf)) stop("arquivo pessoal vazio ou com UF incompatível com o caminho")
    medido[[length(medido) + 1L]] <- tabular_pessoas_validacao_1960(
      p, pub[uf60 == uf & tabela != 7L], "censobr_weight")
    if(!is.na(par_dom)){
      d <- data.table::setDT(arrow::read_parquet(arquivos_dom[par_dom],
        col_select = c("UF", "censobr_idhousehold", "V101", "V102", "V118", "censobr_weight")))
      if(any(!d$UF %in% uf)) stop("arquivo domiciliar com UF incompatível com o caminho")
      medido[[length(medido) + 1L]] <- tabular_domicilios_validacao_1960(
        p, d, pub[uf60 == uf & tabela == 7L], "censobr_weight")
      rm(d)
    }
    rm(p); gc(verbose = FALSE)
  }
  medido <- data.table::rbindlist(medido)

  # Uma soma de algumas UFs nao pode ser apresentada como o Brasil inteiro.
  if(nrow(medido) && all(unname(ufs) %in% medido$uf60)){
    brasil <- medido[, .(valor_parcial = sum(valor_parcial), n_amostra = sum(n_amostra),
      n_pesos_ausentes = sum(n_pesos_ausentes), n_sem_classificacao = sum(n_sem_classificacao),
      peso_sem_classificacao = sum(peso_sem_classificacao),
      n_pesos_ausentes_sem_classificacao = sum(n_pesos_ausentes_sem_classificacao),
      n_domicilios_sem_lista = sum(n_domicilios_sem_lista),
      n_pessoas_sem_domicilio = sum(n_pessoas_sem_domicilio),
      n_ufs = data.table::uniqueN(uf60)), by = .(tabela, item, sexo, medida)]
    brasil <- brasil[n_ufs == length(ufs)][, `:=`(uf60 = 999L, n_ufs = NULL)]
    medido <- data.table::rbindlist(list(medido, brasil), use.names = TRUE, fill = TRUE)
    rm(brasil)
  }
  cmp <- completar_validacao_pessoas_1960(pub, medido, chaves)
  cmp[, amostra := data.table::fifelse(uf60 == 999L, "compilado",
    data.table::fifelse(uf60 %in% UF_1960_AMOSTRA_25, "25%", "1,27%"))]

  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  saida <- file.path(out_dir, "validacao_definitivos.csv")
  data.table::fwrite(cmp[order(tabela, uf60, item, sexo, medida)], saida)
  resumo <- cmp[, .(celulas = .N, observadas = sum(status_celula == "observada"),
    sem_observacoes = sum(status_celula == "sem_observacoes"),
    nao_reconstruidas = sum(status_celula == "nao_reconstruida"),
    classificacao_incompleta = sum(status_celula == "classificacao_incompleta"),
    peso_ausente = sum(status_celula == "peso_ausente"), percentuais_validos = sum(is.finite(dif_pct)),
    erro_mediano_pct = if(any(is.finite(dif_pct))) median(abs(dif_pct), na.rm = TRUE) else NA_real_,
    erro_max_pct = if(any(is.finite(dif_pct))) max(abs(dif_pct), na.rm = TRUE) else NA_real_),
    by = .(amostra, tabela)]
  print(resumo[order(amostra, tabela)])
  saida
}


# ------------------------------------------------------------------------------
# Os erros amostrais do desenho compilado
#
# Uma formula so cobre as duas metades, porque o desenho compilado e de duas
# etapas em toda parte:
#
#   V = Sum_h (1 - f1) n_h/(n_h - 1) Sum_i (t_i - media_h)^2
#     + Sum_i  f1 (1 - f2) m_i/(m_i - 1) Sum_k (t_k - media_i)^2
#
# Nas dezessete a unidade primaria e o domicilio, f1 = 1/4 e a segunda etapa e
# degenerada (um domicilio por unidade primaria, f2 = 1): sobra o primeiro
# termo, que e o estimador de uma etapa do estagio da amostra de 25%. Nas onze a
# unidade primaria e a pasta, f1 = 1/20 e f2 = 1/4: e o estimador de conglomerado
# ultimo da amostra de 1,27% mais o termo da etapa dos domicilios.
#
# O desequilibrio entre as metades e enorme e precisa ser dito: as onze unidades
# sao 1% dos registros e 18% da populacao, e dominam a variancia de qualquer
# estimativa nacional.
# ------------------------------------------------------------------------------
sampling_errors_1960 <- function(paths){

  message("Computing sampling errors in the 1960 compilation")

  dominios <- list(
    pessoas        = quote(TRUE),
    presentes      = quote(!V202 %in% c(3L, 4L)),
    urbana         = quote(!V202 %in% c(3L, 4L) & V118 != 5L),
    rural          = quote(!V202 %in% c(3L, 4L) & V118 == 5L),
    analfabetos_15 = quote(V211 %in% c(2L, 3L) & idade >= 15L),
    criancas_0_4   = quote(!V202 %in% c(3L, 4L) & idade <= 4L),
    com_rendimento = quote(V219 %in% 1:8))

  entre <- list(); dentro <- list(); n_total <- 0; N_total <- 0
  for(u in c(names(UF_1960_AMOSTRA_25), names(UF_1960_AMOSTRA_127))){
    p <- data.table::setDT(arrow::read_parquet(
      file.path("./data_raw/microdata/1960/compilada", u, "pessoas.parquet"),
      col_select = c("V118", "V202", "V204", "V204B", "V211", "V219", "censobr_estrato",
                     "censobr_upa", "censobr_usa", "censobr_fpc", "censobr_fpc2", "censobr_weight")))
    p[, idade := data.table::fifelse(V204 == 1L, V204B,
                 data.table::fifelse(V204 == 5L, 100L + V204B, NA_integer_))]
    n_total <- n_total + nrow(p); N_total <- N_total + sum(p$censobr_weight)

    for(d in names(dominios)){
      # a idade ignorada deixa o dominio NA, e um NA num domicilio zeraria a
      # unidade inteira: quem nao entra no dominio entra como zero
      p[, y := as.integer(eval(dominios[[d]]))][is.na(y), y := 0L]
      # o total do dominio na unidade secundaria e na primaria, ja expandido
      usa <- p[, .(t = sum(y * censobr_weight), n_pes = sum(y)),
               by = .(censobr_estrato, censobr_upa, censobr_usa, censobr_fpc, censobr_fpc2)]
      upa <- usa[, .(t = sum(t), n_pes = sum(n_pes), f1 = censobr_fpc[1]),
                 by = .(censobr_estrato, censobr_upa)]
      entre[[length(entre) + 1]] <- upa[, .(dominio = d, n_upa = .N, soma = sum(t), soma2 = sum(t^2),
                                            pessoas = sum(n_pes), f1 = f1[1]), by = censobr_estrato]
      dentro[[length(dentro) + 1]] <- usa[censobr_fpc2 < 1, .(dominio = d, n_usa = .N, soma = sum(t),
                                            soma2 = sum(t^2), f1 = censobr_fpc[1], f2 = censobr_fpc2[1]),
                                          by = .(censobr_estrato, censobr_upa)]
    }
    rm(p); gc(verbose = FALSE)
  }
  e <- data.table::rbindlist(entre)
  # seis estratos da metade de 1,27% atravessam a fronteira da UF, porque a regra de colapso juntou a unidade
  # solitaria a uma vizinha; o laco acima os parte num pedaco por UF, e nove desses pedacos ficam com uma pasta
  # so, sem medir variancia -- exatamente o que o colapso existia para evitar. Somar os pedacos os reconstitui
  e <- e[, .(n_upa = sum(n_upa), soma = sum(soma), soma2 = sum(soma2), pessoas = sum(pessoas), f1 = f1[1]),
         by = .(dominio, censobr_estrato)]
  dd <- data.table::rbindlist(dentro)

  e[, v := data.table::fifelse(n_upa > 1, (1 - f1) * n_upa / (n_upa - 1) * (soma2 - soma^2 / n_upa), 0)]
  dd[, v := data.table::fifelse(n_usa > 1, f1 * (1 - f2) * n_usa / (n_usa - 1) * (soma2 - soma^2 / n_usa), 0)]

  r <- merge(e[, .(estimativa = sum(soma), v_entre = sum(v), estratos = .N, upas = sum(n_upa),
                   pessoas = sum(pessoas)), by = dominio],
             dd[, .(v_dentro = sum(v)), by = dominio], by = "dominio", all.x = TRUE)
  r[is.na(v_dentro), v_dentro := 0]
  r[, `:=`(erro_padrao = sqrt(v_entre + v_dentro),
           cv_pct = round(100 * sqrt(v_entre + v_dentro) / estimativa, 3))]
  # efeito de desenho: quantas vezes o compilado e menos preciso que um sorteio
  # simples de pessoas do mesmo tamanho. Aqui ele e enorme, e nao por defeito: a
  # metade de 1,27% e 1% dos registros e 18% da populacao, e o peso dela e vinte
  # vezes maior. n_efetivo diz a mesma coisa de modo mais legivel -- quantas
  # pessoas sorteadas uma a uma dariam a mesma precisao.
  r[, p_chapeu := estimativa / N_total]
  r[, v_srs := N_total^2 * p_chapeu * (1 - p_chapeu) / (n_total - 1)]
  r[, deff := data.table::fifelse(p_chapeu < 0.98, round((v_entre + v_dentro) / v_srs, 1), NA_real_)]
  r[, n_efetivo := round(n_total / deff)]
  r[, parte_dentro_pct := round(100 * v_dentro / (v_entre + v_dentro), 2)]
  r[, c("v_entre", "v_dentro", "p_chapeu", "v_srs") := NULL]
  print(r[order(-estimativa)])

  saida <- "./data_raw/microdata/1960/compilada/erros_amostrais.csv"
  data.table::fwrite(r, saida)
  saida
}


# ------------------------------------------------------------------------------
# O dicionario das colunas publicadas
#
# Uma linha por coluna das duas tabelas: o que a coluna e, de onde vem, quanto
# dela esta preenchido em cada metade e qual era o nome correspondente na
# compilacao antiga. E o artefato de revisao dos nomes -- eles so se fixam
# depois dela -- e vira a base do dicionario que o censobr publica.
# ------------------------------------------------------------------------------
ROTULOS_1960_CENSOBR <- c(
  code_region = "Regiao de hoje, do IBGE",
  name_region = "Nome da regiao de hoje",
  code_state = "Unidade da federacao de hoje: Guanabara entra como Rio de Janeiro (33) e Fernando de Noronha como Pernambuco (26); a Serra dos Aimores, repartida entre MG e ES, fica vazia",
  abbrev_state = "Sigla da unidade da federacao de hoje",
  name_state = "Nome da unidade da federacao de hoje",
  code_muni = "Municipio no codigo de hoje, sete digitos",
  code_muni_1960 = "Municipio no codigo da divisao territorial de 1960",
  name_muni_1960 = "Nome do municipio em 1960",
  code_district_1960 = "Distrito no codigo do Codigo de Zonas Fisiograficas, Municipios e Distritos de 1960",
  name_district_1960 = "Nome do distrito em 1960",
  code_bairro_1960 = "Bairro no codigo do Codigo de Zonas Fisiograficas de 1960, de 5410 a 5591: e a circunscricao censitaria em que o tomo XII publica a Guanabara",
  name_bairro_1960 = "Bairro, so na Guanabara, onde o censo codificou a cidade por bairro",
  name_region_1960 = "Regiao em que os volumes de 1960 publicam: Norte, Nordeste, Leste, Sul, Centro-Oeste",
  code_state_1960 = "Unidade da federacao no codigo do IBGE em 1960: Guanabara 34, Fernando de Noronha 20; a Serra dos Aimores nunca teve codigo",
  abbrev_state_1960 = "Sigla da unidade da federacao em 1960",
  name_state_1960 = "Nome da unidade da federacao em 1960, como a Serie Nacional a publica",
  censobr_idhousehold = "Identificador do domicilio, unico no pais",
  censobr_idfamily = "Identificador da familia, unico no pais: o boletim de 1960 era por familia",
  censobr_idperson = "Identificador da pessoa, unico no pais",
  censobr_amostra = "De qual das duas amostras o registro vem: 25% ou 1,27%",
  censobr_tipo_unidade = "Domicilio particular, domicilio coletivo ou boletim individual",
  situacao = "Urbana (quadro urbano ou suburbano) ou rural",
  censobr_n_listadas = "Pessoas listadas no boletim",
  censobr_n_residentes = "Moradores residentes do domicilio",
  censobr_n_presentes = "Pessoas presentes no domicilio",
  censobr_n_familias = "Familias no domicilio",
  censobr_estrato = "Estrato do desenho amostral",
  censobr_upa = "Unidade da primeira etapa: o domicilio na amostra de 25%, a pasta na de 1,27%",
  censobr_fpc = "Fracao de sorteio da primeira etapa: 1/4 na amostra de 25%, 1/20 na de 1,27%",
  censobr_usa = "Unidade da segunda etapa: o domicilio",
  censobr_fpc2 = "Fracao de sorteio da segunda etapa: 1 na amostra de 25%, onde nao ha segunda etapa, e 1/4 na de 1,27%",
  censobr_weight = "Peso final, calibrado aos resultados definitivos da Serie Nacional",
  censobr_weight_fator = "Razao entre o peso final e o peso de desenho",
  censobr_weight_desenho = "Base do ajuste definitivo: 4 na amostra de 25% e em FN; 1/0,0127 nas demais UFs da amostra de 1,27%",
  censobr_weight_nivel = "Nivel em que a ancora municipal ficou na calibracao; so na amostra de 25%",
  censobr_weight_ibge = "Peso inteiro do metodo publicado pelo IBGE; so na amostra de 25%",
  censobr_weight_1965 = "Peso calibrado aos Resultados Preliminares de 1965; so na amostra de 1,27%",
  censobr_weight_1965_fator = "Razao entre o peso1965 e sua base historica 1/0,0127, inclusive em FN; so na amostra de 1,27%",
  censobr_favela = "Registro em favela, so na Guanabara",
  censobr_muni_corrigido = "Codigo de municipio corrigido na leitura",
  censobr_uf_corrigida = "Unidade da federacao corrigida na leitura; so na amostra de 1,27%",
  censobr_diagnostico = "Diagnostico do dano de fita no registro; so na amostra de 1,27%",
  censobr_variaveis_anuladas = "Variaveis cujo valor saiu do dicionario e foi anulado",
  censobr_familia_origem = "Como a familia foi reconstruida; so na amostra de 1,27%",
  censobr_convivente_isolada = "Familia convivente sem a principal no arquivo",
  censobr_dois_chefes = "Domicilio com dois registros na posicao de chefe; so na amostra de 1,27%",
  censobr_tipo_registro = "Chefe ou demais pessoas; so na amostra de 1,27%",
  censobr_duplicata_mantida = "Linha repetida mantida com marca; so na amostra de 1,27%",
  censobr_v208_imputada = "Nacionalidade imputada deterministicamente; so na amostra de 1,27%",
  censobr_v217_fora_da_faixa = "Filhos tidos fora da faixa do dicionario",
  censobr_v218_fora_da_faixa = "Filhos vivos fora da faixa do dicionario",
  censobr_flag_conjuge_mesmo_sexo = "Conjuge do mesmo sexo do chefe",
  censobr_flag_filho_mais_velho = "Filho mais velho incompativel com a idade do chefe",
  censobr_flag_casamento_impossivel = "Ano de casamento incompativel com a idade",
  censobr_linha = "Linha do registro no arquivo de origem",
  v001 = "Pasta: o lote de trabalho de ~250 questionarios, e a unidade sorteada na amostra de 1,27%",
  v002 = "Boletim dentro da pasta",
  v003 = "Ordem da pessoa no boletim; vazio na amostra de 1,27%",
  v004 = "Digito verificador; vazio na amostra de 1,27%",
  v100 = "Total de pessoas declarado no registro de familia; vazio na amostra de 1,27%",
  V204B = "Idade, em anos ou em meses conforme V204",
  UF = "Unidade da federacao no codigo do proprio censo de 1960")

# O nome correspondente na compilacao publicada ate aqui, onde havia um.
NOMES_1960_ANTIGOS <- c(
  censobr_amostra = "censobr_source", situacao = "censobr_urban",
  censobr_n_presentes = "censobr_npersons", censobr_n_residentes = "censobr_ndwellers",
  censobr_n_familias = "censobr_nfamilies", censobr_diagnostico = "censobr_diag_households",
  censobr_variaveis_anuladas = "censobr_diag_households_vars", name_muni_1960 = "name_muni")

dicionario_1960 <- function(paths, guia_familias, guia_pessoas){

  message("Writing the 1960 column dictionary")

  guias <- data.table::rbindlist(list(data.table::fread(guia_familias, encoding = "UTF-8"),
                                      data.table::fread(guia_pessoas,  encoding = "UTF-8")),
                                 fill = TRUE)
  guias <- unique(guias[, .(coluna = variavel, rotulo_ibge = rotulo)])

  linhas <- list()
  for(tab in c("domicilios", "pessoas")){
    for(u in c("se", "gb")){
      d <- data.table::setDT(arrow::read_parquet(
        file.path("./data_raw/microdata/1960/compilada", u, paste0(tab, ".parquet"))))
      preenchido <- d[, lapply(.SD, function(x) round(100 * mean(!is.na(x)), 1))]
      linhas[[paste(tab, u)]] <- data.table::data.table(
        tabela = data.table::fifelse(tab == "domicilios", "households", "population"),
        coluna = names(d),
        tipo   = sapply(d, function(x) class(x)[1]),
        metade = data.table::fifelse(u == "se", "preenchido_25_pct", "preenchido_127_pct"),
        valor  = as.numeric(unlist(preenchido)))
      rm(d); gc(verbose = FALSE)
    }
  }
  x <- data.table::rbindlist(linhas)
  x <- data.table::dcast(x, tabela + coluna + tipo ~ metade, value.var = "valor")
  x[, ordem := data.table::fifelse(tabela == "households",
                                   match(coluna, COLUNAS_1960_DOM), match(coluna, COLUNAS_1960_PES))]

  x[guias, rotulo := i.rotulo_ibge, on = "coluna"]
  x[is.na(rotulo), rotulo := ROTULOS_1960_CENSOBR[coluna]]
  x[, nome_antigo := NOMES_1960_ANTIGOS[coluna]]
  x[coluna %in% c("censobr_idhousehold", "censobr_idfamily", "censobr_idperson",
                  "censobr_weight", "censobr_upa", "censobr_estrato", "code_muni_1960",
                  "code_region", "name_region", "code_state", "abbrev_state", "name_state",
                  "UF") | grepl("^[Vv][0-9]", coluna), nome_antigo := coluna]
  x[, situacao_vs_publicado := data.table::fcase(
      is.na(nome_antigo), "nova",
      nome_antigo == coluna, "mantida",
      default = "renomeada")]

  data.table::setcolorder(x, c("tabela", "ordem", "coluna", "tipo", "rotulo",
                               "preenchido_25_pct", "preenchido_127_pct",
                               "nome_antigo", "situacao_vs_publicado"))
  saida <- "./references/microdata_1960_compilacao_dicionario.csv"
  data.table::fwrite(x[order(tabela, ordem)], saida)

  print(x[, .N, by = .(tabela, situacao_vs_publicado)][order(tabela, situacao_vs_publicado)])
  faltam <- x[is.na(rotulo), unique(coluna)]
  if(length(faltam)) message("  sem rotulo: ", paste(faltam, collapse = ", "))
  saida
}
