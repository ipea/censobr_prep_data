# Microlotes inteiramente ficticios; executar pelo runner isolado de R.
.libPaths(c("renv/library/windows/R-4.5/x86_64-w64-mingw32", .libPaths()))
Sys.setlocale("LC_CTYPE", "Portuguese_Brazil.utf8")
library(data.table)
library(arrow)
library(digest)
setDTthreads(1L)
source("R/support_fun.R", encoding = "UTF-8")
source("R/microdata_1960_amostra_25.R", encoding = "UTF-8")
source("R/microdata_1960.R", encoding = "UTF-8")

procedencia <- c("censobr_cartao_recuperado_id", "censobr_cartao_fonte",
  "censobr_cartao_arquivo", "censobr_cartao_linha", "censobr_cartao_pasta_fonte25",
  "censobr_cartao_boletim_fonte25", "censobr_cartao_chave_reconciliada",
  "censobr_cartao_criterio_identificacao", "censobr_cartao_sha256", "censobr_cartao_unidade",
  "censobr_distrito_original", "censobr_distrito_fonte25", "censobr_distrito_recuperado",
  "censobr_distrito_prova", "censobr_distrito_prova_sha256")
inteiras <- c("censobr_cartao_linha", "censobr_cartao_chave_reconciliada",
              "censobr_distrito_recuperado")
falhas <- character()
conferir <- function(nome, condicao){
  message(nome, ": ", if(isTRUE(condicao)) "PASSOU" else "FALHOU")
  if(!isTRUE(condicao)) falhas <<- c(falhas, nome)
}
dir.create("tmp", showWarnings = FALSE)
saida <- tempfile("procedencia_compilacao_1960_", tmpdir = "tmp")
dir.create(saida)

# O distrito X7 deste exemplo e sintetico, nao uma correcao nova na Guanabara.
fixture <- function(tabela, uf){
  colunas <- if(tabela == "domicilios") COLUNAS_1960_DOM else COLUNAS_1960_PES
  d <- data.table(UF = rep(uf, 2L), censobr_idhousehold = 1:2, censobr_idfamily = 1:2,
    linha = 101:102, pasta = c("54001", "54002"), boletim = c("001", "002"),
    distrito = c("07", "03"), v001 = 54001:54002, v002 = 1:2,
    V101 = 1L, V116 = 5401L, V118 = 1L, V202 = 1:2, V204 = 1L, V204B = c(30L, 40L),
    code_muni = if(uf == 54L) 3304557L else 2800308L, code_muni_1960 = uf * 100L + 1L,
    censobr_estrato = paste0("UF ", uf, " - urbana"), censobr_upa = paste0(uf, "-", 54001:54002),
    censobr_weight = c(4, 8), censobr_familia_origem = "registro",
    censobr_tipo_unidade = "domicilio particular")
  derivadas <- c("censobr_linha", "censobr_amostra", "censobr_fpc", "censobr_fpc2", "censobr_usa")
  for(col in setdiff(colunas, c(names(d), derivadas, procedencia))){
    tipo <- TIPOS_1960_FALTANTES[col]
    if(is.na(tipo)) tipo <- if(grepl("^(name_|abbrev_)|^situacao$|^censobr_variaveis_anuladas$", col)) "character" else "integer"
    set(d, j = col, value = as(NA, tipo))
  }
  if(uf == 54L){
    for(col in procedencia) set(d, j = col, value = if(col %in% inteiras) NA_integer_ else NA_character_)
    d[, `:=`(censobr_distrito_original = c("X7", "03"), censobr_distrito_fonte25 = c("07", NA_character_),
      censobr_distrito_recuperado = c(TRUE, FALSE),
      censobr_distrito_prova = c("fixtures/prova_distrito.json", NA_character_),
      censobr_distrito_prova_sha256 = c(paste(rep("a", 64L), collapse = ""), NA_character_))]
  }
  d
}

entrada25 <- file.path(saida, "entrada25", "se")
entrada127 <- file.path(saida, "entrada127")
dir.create(entrada25, recursive = TRUE)
dir.create(entrada127)
paths25 <- file.path(entrada25, c("domicilios_pesos.parquet", "pessoas_pesos.parquet"))
paths127 <- file.path(entrada127, c("pessoas.parquet", "domicilios.parquet"))
dom25 <- fixture("domicilios", 30L); pes25 <- fixture("pessoas", 30L)
dom127 <- fixture("domicilios", 54L); pes127 <- fixture("pessoas", 54L)
write_parquet(dom25, paths25[1]); write_parquet(pes25, paths25[2])
write_parquet(pes127, paths127[1]); write_parquet(dom127, paths127[2])
municipios <- file.path(saida, "municipios.csv")
definitivos <- file.path(saida, "definitivos.csv")
fwrite(data.table(cod60 = c(3001L, 5401L), nome = c("Municipio ficticio SE", "Municipio ficticio GB")), municipios)
fwrite(data.table(nivel = "uf", uf60 = c(30L, 54L), nome = c("Sergipe", "Guanabara"), regiao = c("Nordeste", "Leste")), definitivos)
originais <- c(paths25, paths127, municipios, definitivos)
hashes_antes <- sapply(originais, function(p) digest(file = p, algo = "sha256"))
estratos <- data.table(UF = 54L, grupo = "urbana", censobr_estrato = "UF 54 - urbana")
comp25 <- compile_1960(paths25, paths127, estratos, "se", municipios, definitivos,
                       out_dir = file.path(saida, "compilada", "se"))
comp127 <- compile_1960(paths25, paths127, estratos, "gb", municipios, definitivos,
                        out_dir = file.path(saida, "compilada", "gb"))

for(i in 1:2){
  nome <- if(i == 1L) "domicilios" else "pessoas"
  d25 <- as.data.table(read_parquet(comp25[i]))
  d127 <- as.data.table(read_parquet(comp127[i]))
  conferir(paste(nome, "15 colunas preservadas"), all(procedencia %in% names(d25)) && all(procedencia %in% names(d127)))
  conferir(paste(nome, "UF e amostra preservadas"), all(d25$UF == 30L & d25$censobr_amostra == "25%") &&
    all(d127$UF == 54L & d127$censobr_amostra == "1,27%"))
  conferir(paste(nome, "contagem e pesos preservados"), nrow(d25) == 2L && nrow(d127) == 2L &&
    identical(d25$censobr_weight, c(4, 8)) && identical(d127$censobr_weight, c(4, 8)))
  conferir(paste(nome, "fracoes do desenho preservadas"), all(d25$censobr_fpc == 0.25 & d25$censobr_fpc2 == 1) &&
    all(d127$censobr_fpc == 0.05 & d127$censobr_fpc2 == 0.25))
  conferir(paste(nome, "chave operacional preservada"), identical(d127$v001, 54001:54002) &&
    identical(d127$v002, 1:2) && identical(d127$V117, c(7L, 3L)) && identical(d127$censobr_linha, 101:102))
  if(all(procedencia %in% names(d25)) && all(procedencia %in% names(d127))){
    conferir(paste(nome, "ausencia tipada na metade25"), all(is.na(unlist(d25[, ..procedencia]))) &&
      all(sapply(d25[, ..inteiras], is.integer)) && all(sapply(d25[, setdiff(procedencia, inteiras), with = FALSE], is.character)))
    conferir(paste(nome, "distrito literal e prova preservados"), identical(d127$censobr_distrito_original, c("X7", "03")) &&
      identical(d127$censobr_distrito_fonte25, c("07", NA_character_)) &&
      identical(d127$censobr_distrito_recuperado, c(1L, 0L)) &&
      identical(d127$censobr_distrito_prova, dom127$censobr_distrito_prova) &&
      identical(d127$censobr_distrito_prova_sha256, dom127$censobr_distrito_prova_sha256))
    combinado <- open_dataset(c(comp25[i], comp127[i])) |> dplyr::collect()
    conferir(paste(nome, "uniao Arrow sem perda"), nrow(combinado) == 4L && all(procedencia %in% names(combinado)))
  }
  if(i == 2L) conferir("respostas pessoais inalteradas", identical(d25$V202, 1:2) && identical(d127$V202, 1:2) &&
    identical(d25$V204B, c(30L, 40L)) && identical(d127$V204B, c(30L, 40L)))
}
conferir("rotulos das 15 colunas", all(procedencia %in% names(ROTULOS_1960_CENSOBR)) &&
  all(nzchar(ROTULOS_1960_CENSOBR[procedencia])))
conferir("dicionario permite saida isolada", "out_path" %in% names(formals(dicionario_1960)))
if("out_path" %in% names(formals(dicionario_1960))){
  dic_path <- dicionario_1960(list(comp127, comp25), "read_guides/readguide_1960_amostra_127_familias.csv",
    "read_guides/readguide_1960_amostra_127_pessoas.csv", out_path = file.path(saida, "dicionario.csv"))
  dic <- fread(dic_path)
  conferir("dicionario usa os microlotes recebidos", nrow(dic[coluna %in% procedencia]) == 30L &&
    !anyNA(dic[coluna %in% procedencia, rotulo]) &&
    all(dic[coluna == "censobr_distrito_recuperado", preenchido_127_pct] == 100) &&
    all(dic[coluna == "censobr_distrito_recuperado", preenchido_25_pct] == 0))
}

# Uma coluna vazia ja existente tambem precisa ter o tipo correto, inclusive
# em arquivos de uma linha; preencher um unico NA pode conservar o tipo antigo.
for(n_registros in 1:2){
  entrada_na <- file.path(saida, paste0("entrada_na_integer_", n_registros), "se")
  dir.create(entrada_na, recursive = TRUE)
  paths_na <- file.path(entrada_na, basename(paths25))
  for(i in 1:2){
    z <- copy(if(i == 1L) dom25 else pes25)[seq_len(n_registros)]
    for(col in procedencia) set(z, j = col, value = NA_integer_)
    stopifnot(all(sapply(z[, ..procedencia], is.integer)))
    write_parquet(z, paths_na[i])
  }
  hashes_na <- sapply(paths_na, function(p) digest(file = p, algo = "sha256"))
  comp_na <- compile_1960(paths_na, paths127, estratos, "se", municipios, definitivos,
    out_dir = file.path(saida, paste0("compilada_na_integer_", n_registros), "se"))
  for(i in 1:2){
    nome <- if(i == 1L) "domicilios" else "pessoas"
    z <- as.data.table(read_parquet(comp_na[i]))
    classes <- sapply(z[, ..procedencia], function(x) class(x)[1L])
    conferir(paste(nome, "NA_integer retipado", n_registros, "linhas"),
      identical(unname(classes), unname(TIPOS_1960_FALTANTES[procedencia])) &&
      nrow(z) == n_registros && all(is.na(unlist(z[, ..procedencia]))))
  }
  conferir(paste("insumos NA_integer intocados", n_registros, "linhas"),
    identical(hashes_na, sapply(paths_na, function(p) digest(file = p, algo = "sha256"))))
}

# Uma marca nova deve exigir atualizacao do esquema, nunca sumir na selecao.
ruim25 <- file.path(saida, "marca_desconhecida", "se")
dir.create(ruim25, recursive = TRUE)
ruim25_paths <- file.path(ruim25, basename(paths25))
write_parquet(copy(dom25)[, censobr_cartao_nova_marca := "prova ficticia"], ruim25_paths[1])
write_parquet(pes25, ruim25_paths[2])
nao_gravar <- file.path(saida, "saida_marca_desconhecida")
erro <- tryCatch(compile_1960(ruim25_paths, paths127, estratos, "se", municipios, definitivos, out_dir = nao_gravar), error = identity)
conferir("procedencia desconhecida bloqueia antes de gravar", inherits(erro, "error") &&
  grepl("procedencia", conditionMessage(erro), fixed = TRUE) && !dir.exists(nao_gravar))

ruim_flag <- file.path(saida, "flag_invalida")
dir.create(ruim_flag)
ruim_flag_paths <- file.path(ruim_flag, basename(paths127))
write_parquet(copy(pes127)[, censobr_distrito_recuperado := c(2L, 0L)], ruim_flag_paths[1])
write_parquet(dom127, ruim_flag_paths[2])
nao_gravar <- file.path(saida, "saida_flag_invalida")
erro <- tryCatch(compile_1960(paths25, ruim_flag_paths, estratos, "gb", municipios, definitivos, out_dir = nao_gravar), error = identity)
conferir("marca de recuperacao fora de 0 e 1 bloqueia", inherits(erro, "error") &&
  grepl("marca de procedencia", conditionMessage(erro), fixed = TRUE) && !dir.exists(nao_gravar))

ruim127 <- file.path(saida, "cartao_sem_prova")
dir.create(ruim127)
ruim127_paths <- file.path(ruim127, basename(paths127))
write_parquet(copy(pes127)[, censobr_familia_origem := "recuperada_25"], ruim127_paths[1])
write_parquet(copy(dom127)[, censobr_familia_origem := "recuperada_25"], ruim127_paths[2])
nao_gravar <- file.path(saida, "saida_cartao_sem_prova")
erro <- tryCatch(compile_1960(paths25, ruim127_paths, estratos, "gb", municipios, definitivos, out_dir = nao_gravar), error = identity)
conferir("cartao recuperado continua bloqueado no ramo127", inherits(erro, "error") &&
  grepl("procedencia no esquema final", conditionMessage(erro), fixed = TRUE) && !dir.exists(nao_gravar))
conferir("insumos intocados", identical(hashes_antes, sapply(originais, function(p) digest(file = p, algo = "sha256"))))
if(length(falhas)) stop("Falhas de procedencia: ", paste(falhas, collapse = "; "))
message("Procedencia da compilacao conferida somente em microlotes ficticios: ", saida)
