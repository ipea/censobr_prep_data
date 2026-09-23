# Dados ficticios, inclusive o esquema medido aqui; nada substitui o produto real.
raiz <- normalizePath(".", winslash = "/")
.libPaths(c(normalizePath("renv/library/windows/R-4.5/x86_64-w64-mingw32", winslash = "/"), .libPaths()))
Sys.setlocale("LC_CTYPE", "Portuguese_Brazil.utf8")
library(data.table)
library(dplyr)
setDTthreads(1L)
e <- new.env(parent = globalenv())
for(arquivo in c("support_fun.R", "type_convention.R", "microdata_1960_amostra_25.R",
                "microdata_1960.R", "microdata_1960_validacao.R", "microdata_1960_publicacao.R"))
  sys.source(file.path(raiz, "R", arquivo), envir = e)
e$UF_1960_AMOSTRA_25 <- c(se = 30L)
e$UF_1960_AMOSTRA_127 <- c(gb = 54L)
dir.create("tmp/correcao_scripts_r_1960_20260923", recursive = TRUE, showWarnings = FALSE)
ensaio <- tempfile("publicacao_", tmpdir = "tmp/correcao_scripts_r_1960_20260923")
dir.create(ensaio)
setwd(ensaio)
dir.create("schemas")
file.copy(file.path(raiz, "schemas/censobr_types.csv"), "schemas/censobr_types.csv")
schema_original <- digest::digest(file.path(raiz, "schemas/censobr_types.csv"), file = TRUE, algo = "sha256")
def <- fread(file.path(raiz, "references/censo_1960_resultados_definitivos_serie_nacional.csv"))
def <- def[nivel == "brasil" | (nivel == "uf" & uf60 %in% c(30L, 54L))]
fwrite(def, "definitivos.csv")

bases <- list(); paths <- character(); medicao <- list()
for(unidade in c("se", "gb")){
  dir.create(unidade)
  uf <- c(se = 30L, gb = 54L)[[unidade]]
  for(dataset in c("households", "population")){
    cols <- if(dataset == "households") e$COLUNAS_1960_DOM else e$COLUNAS_1960_PES
    z <- data.table(auxiliar = 1:2)
    for(col in cols){
      tipo <- unname(e$TIPOS_1960_FALTANTES[col])
      if(is.na(tipo)) tipo <- if(grepl("^(name_|abbrev_)|^situacao$|^censobr_(amostra|tipo_unidade|estrato|variaveis_anuladas)$", col)) "character" else "integer"
      set(z, j = col, value = as(NA, tipo))
    }
    z$auxiliar <- NULL
    z[, `:=`(UF = uf, censobr_idhousehold = uf * 1e7 + 1:2,
             censobr_weight = if(unidade == "se") 4 else 80,
             censobr_amostra = if(unidade == "se") "25%" else "1,27%",
             censobr_familia_origem = if(unidade == "se") NA_character_ else "registro",
             censobr_diagnostico = if(unidade == "se") NA_character_ else "sem_problema",
             V101 = 1L, V102 = 4L, V118 = 1L)]
    if(dataset == "population") z[, `:=`(censobr_idperson = uf * 1e7 + 1:2,
      censobr_idfamily = uf * 1e7 + 1:2, V202 = 1:2, V204 = 1L, V204B = 30:31,
      V206 = 4L, V211 = 1L, censobr_duplicata_mantida = TRUE,
      censobr_flag_conjuge_mesmo_sexo = TRUE)]
    caminho <- file.path(unidade, if(dataset == "households") "domicilios.parquet" else "pessoas.parquet")
    bases[[caminho]] <- copy(z)
    paths <- c(paths, caminho)
    arrow::write_parquet(z, caminho)
  }
}

# O esquema deste ensaio mede todas as linhas ficticias, nunca a base historica.
for(dataset in c("households", "population")){
  arquivo <- if(dataset == "households") "domicilios.parquet" else "pessoas.parquet"
  z <- rbindlist(bases[basename(names(bases)) == arquivo])
  for(col in names(z)){
    valores <- as.character(z[[col]])
    valores <- valores[!is.na(valores) & !valores %in% c("", ".")]
    numeros <- suppressWarnings(as.numeric(valores))
    nonnum <- sum(is.na(numeros))
    fracionarios <- sum(numeros %% 1 != 0, na.rm = TRUE)
    fora <- any(abs(numeros) > .Machine$integer.max, na.rm = TRUE)
    alvo <- if(grepl("^(name_|abbrev_)", col) || nonnum > 0) "string" else if(fracionarios > 0 || fora) "double" else "int32"
    if(is.logical(z[[col]])) alvo <- "int32"
    medicao[[length(medicao) + 1L]] <- data.table(dataset = paste0("1960_", dataset), coluna = col,
      tipo_alvo = alvo, n = nrow(z), nonnum = nonnum, frac = fracionarios)
  }
}
schema_fixture <- rbindlist(medicao)
checks <- 0L
recusar <- function(expr, trecho){
  erro <- tryCatch({force(expr); ""}, error = function(x) conditionMessage(x))
  if(!grepl(trecho, erro)) stop("Recusa esperada: ", trecho, "; recebida: ", erro)
  checks <<- checks + 1L
  cat("RECUSOU: ", trecho, "\n")
}
validar <- function(){
  e$validate_1960(paths, "definitivos.csv", out_dir = "validacao")
}
conferir <- function(){
  e$conferir_publicacao_1960(paths, "validacao/validacao_definitivos.csv", "definitivos.csv",
                            out_dir = "conferencia")
}
restaurar <- function(){
  gc(verbose = FALSE)
  caso <- tempfile("caso_", tmpdir = ".")
  dir.create(caso)
  for(unidade in c("se", "gb")) dir.create(file.path(caso, unidade))
  paths <<- file.path(caso, names(bases))
  for(i in seq_along(paths)) arrow::write_parquet(bases[[i]], paths[i])
  validar()
}
relatorio <- validar()
stopifnot(length(relatorio) == 1L, file.exists(paste0(relatorio, ".fontes.json")))
recusar(conferir(), "Tipos nao medidos")
fwrite(schema_fixture, "schemas/censobr_types.csv")
certificado <- conferir()
reprovado <- jsonlite::read_json(certificado, simplifyVector = TRUE)
reprovado$integridade_tecnica <- FALSE
jsonlite::write_json(reprovado, "reprovado.json", auto_unbox = TRUE, pretty = TRUE)
recusar(e$save_microdata_1960(paths, "population", "reprovado", "reprovado.json", "proibida"), "conferencia nao corresponde")
cmp <- fread(relatorio)
stopifnot(nrow(cmp) == 180L, any(cmp$dif != 0),
  nrow(cmp[status_celula == "sem_observacoes" & publicado > 0]) > 0L,
  isTRUE(jsonlite::read_json(certificado, simplifyVector = TRUE)$integridade_tecnica))
cat("PASSOU: divergencias e categorias vazias permanecem visiveis, sem veto automatico.\n")

# A releitura da exportacao deve conservar IDs, respostas e pesos sem sobrescrita.
for(dataset in c("households", "population")){
  saida <- e$save_microdata_1960(paths, dataset, "teste", certificado, out_dir = "saida")
  gravado <- as.data.table(arrow::read_parquet(saida))
  arquivo <- if(dataset == "households") "domicilios.parquet" else "pessoas.parquet"
  esperado <- rbindlist(bases[basename(names(bases)) == arquivo])
  setorder(gravado, UF, censobr_idhousehold); setorder(esperado, UF, censobr_idhousehold)
  cols <- c("UF", "censobr_idhousehold", "censobr_weight", "V101", "V102", "V118")
  if(dataset == "population") cols <- c(cols, "censobr_idperson", "censobr_idfamily", "V202", "V204", "V204B", "V206", "V211")
  stopifnot(nrow(gravado) == 4L, setequal(names(gravado), names(esperado)))
  for(col in cols) stopifnot(identical(as.numeric(gravado[[col]]), as.numeric(esperado[[col]])))
  hash_saida <- digest::digest(saida, file = TRUE, algo = "sha256")
  recusar(e$save_microdata_1960(paths, dataset, "teste", certificado, out_dir = "saida"), "ja existe")
  stopifnot(identical(hash_saida, digest::digest(saida, file = TRUE, algo = "sha256")))
}

# Cada alteracao invalida o comprovante, mesmo se o caminho do arquivo nao mudar.
fwrite(cmp[-1], relatorio)
recusar(conferir(), "desatualizada")
recusar(e$save_microdata_1960(paths, "population", "alterado", certificado, "proibida"), "Arquivos alterados")
stopifnot(!dir.exists("proibida"))
validar()
ruim <- copy(bases[["se/pessoas.parquet"]]); ruim[1, censobr_weight := 5]
arrow::write_parquet(ruim, "se/pessoas.parquet")
recusar(conferir(), "desatualizada")
recusar(e$save_microdata_1960(paths, "population", "alterado", certificado, "proibida"), "Arquivos alterados")
restaurar()
certificado <- conferir()
recusar(e$conferir_publicacao_1960(paths[-1], relatorio, "definitivos.csv", out_dir = "nao_usar"), "desatualizada")
schema_incompleto <- schema_fixture[-1]
fwrite(schema_incompleto, "schemas/censobr_types.csv")
recusar(conferir(), "Tipos nao medidos")
recusar(e$save_microdata_1960(paths, "population", "alterado", certificado, "proibida"), "Arquivos alterados")
fwrite(schema_fixture, "schemas/censobr_types.csv")

schema_invalido <- copy(schema_fixture)
schema_invalido[1, tipo_alvo := "float32"]
fwrite(schema_invalido, "schemas/censobr_types.csv")
recusar(conferir(), "Tipos nao medidos")
fwrite(schema_fixture, "schemas/censobr_types.csv")
todos <- paths
paths <- paths[basename(dirname(paths)) == "se"]
validar()
recusar(conferir(), "um par de arquivos para cada UF")
paths <- todos
validar()
certificado <- conferir()
original <- e$tabular_pessoas_validacao_1960
e$tabular_pessoas_validacao_1960 <- function(p, grade, peso) original(p, grade, peso)
recusar(conferir(), "desatualizada")
recusar(e$save_microdata_1960(paths, "population", "codigo_alterado", certificado, "proibida"), "codigo atual")
e$tabular_pessoas_validacao_1960 <- original
def_alterado <- copy(def); def_alterado[1, valor := valor + 1]
fwrite(def_alterado, "definitivos.csv")
recusar(conferir(), "desatualizada")
fwrite(def, "definitivos.csv")
recusar(e$conferir_publicacao_1960(paths, relatorio, "definitivos.csv", fontes_path = "ausente.json"), ".")

# Contraprovas de grade: trocar chave e tirar linha sao erros distintos.
for(caso in c("linha_ausente", "chave_trocada", "status_incompleto")){
  ruim <- copy(cmp)
  if(caso == "linha_ausente") ruim <- ruim[-1]
  if(caso == "chave_trocada") ruim[1, item := "categoria_inexistente"]
  if(caso == "status_incompleto") ruim[1, status_celula := "nao_reconstruida"]
  fwrite(ruim, relatorio)
  fontes <- jsonlite::read_json(paste0(relatorio, ".fontes.json"), simplifyVector = TRUE)
  fontes$relatorio_sha256 <- digest::digest(relatorio, file = TRUE, algo = "sha256")
  jsonlite::write_json(fontes, paste0(relatorio, ".fontes.json"), auto_unbox = TRUE, pretty = TRUE)
  recusar(conferir(), if(caso == "status_incompleto") "comparacoes nao calculadas" else "Grade de validacao")
  validar()
}

# As respostas iguais e as sinalizacoes de parentesco nao autorizam excluir gente.
for(caso in c("peso_negativo", "peso_negativo_fora_t7", "peso_diferente", "id_duplicado", "id_outra_uf",
              "familia_dois_domicilios", "sem_domicilio", "dano", "dano_sufixo", "origem", "coluna_extra")){
  caminho <- paths[basename(dirname(paths)) == "gb" & basename(paths) == "pessoas.parquet"]
  ruim <- copy(bases[["gb/pessoas.parquet"]])
  if(caso == "peso_negativo") ruim[1, censobr_weight := -1]
  if(caso == "peso_negativo_fora_t7") ruim[1, `:=`(censobr_weight = -1, V202 = 5L)]
  if(caso == "peso_diferente") ruim[1, censobr_weight := 81]
  if(caso == "id_duplicado") ruim[2, censobr_idperson := ruim$censobr_idperson[1]]
  if(caso == "id_outra_uf") ruim[, censobr_idperson := 30 * 1e7 + 1:2]
  if(caso == "familia_dois_domicilios") ruim[, censobr_idfamily := 54 * 1e7 + 1]
  if(caso == "sem_domicilio") ruim[1, censobr_idhousehold := 54 * 1e7 + 99]
  if(caso == "dano") ruim[1, censobr_diagnostico := "dano_salto_nao_resolvido"]
  if(caso == "dano_sufixo") ruim[1, censobr_diagnostico := "corrompida+municipio_corrigido"]
  if(caso == "origem") ruim[1, censobr_familia_origem := ""]
  if(caso == "coluna_extra") ruim[, censobr_cartao_sem_regra := "nao descartar"]
  arrow::write_parquet(ruim, caminho)
  validar()
  # O negativo residente agora e recusado antes, na propria comparacao T7.
  if(caso == "peso_negativo"){
    pesos_ruins <- fread(relatorio)[uf60 == 54L & tabela == 7L & n_pesos_ausentes > 0L]
    stopifnot(nrow(pesos_ruins) == 2L, all(pesos_ruins$medida == "pessoas"),
      all(pesos_ruins$status_celula == "peso_ausente"),
      all(is.na(pesos_ruins$valor_minimo)), all(is.na(pesos_ruins$valor_maximo)))
  }
  trecho <- switch(caso, peso_negativo = "comparacoes nao calculadas",
    peso_negativo_fora_t7 = "peso invalido", peso_diferente = "Peso pessoal diverge",
    id_duplicado = "Identificadores ausentes", id_outra_uf = "intervalo nacional",
    familia_dois_domicilios = "familia aparece", sem_domicilio = "comparacoes nao calculadas",
    dano = "dano ou vinculo", dano_sufixo = "dano ou vinculo", origem = "dano ou vinculo", coluna_extra = "Colunas compiladas")
  recusar(conferir(), trecho)
  restaurar()
}

# A declaracao dos targets e inspecionada sem executar o pipeline.
alvos <- list()
coletar_alvos <- function(x){
  if(is.call(x) && identical(x[[1]], as.name("tar_target"))){
    partes <- as.list(x)
    alvos[[as.character(partes$name)]] <<- partes$command
  }
  if(is.call(x) || is.expression(x) || is.pairlist(x)) for(parte in as.list(x)) coletar_alvos(parte)
}
coletar_alvos(parse(file.path(raiz, "_targets.R"), encoding = "UTF-8"))
stopifnot("conferencia_publicacao_1960" %in% all.names(alvos$output_microdata_1960),
  all(c("compilada_1960", "validacao_1960", "fontes_validacao_1960", "schema_tipos_1960") %in%
      all.names(alvos$conferencia_publicacao_1960)),
  grepl("fontes.json", paste(deparse(alvos$validacao_1960), collapse = "")),
  !"conferencia_publicacao_1960" %in% all.names(alvos$output_1960_amostra_127),
  identical(schema_original, digest::digest(file.path(raiz, "schemas/censobr_types.csv"), file = TRUE, algo = "sha256")))
cat("PASSOU: exportacao, releitura, grade completa, dependencias e ", checks, " recusas tecnicas.\n")
