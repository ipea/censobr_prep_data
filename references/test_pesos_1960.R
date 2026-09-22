# Testes sinteticos; executar somente depois de autorizar o ambiente R.
# Nao chama targets, nao le microdados reais e nao recalibra pesos publicados.
# Da raiz: source("references/test_pesos_1960.R", encoding = "UTF-8")
.libPaths(c("renv/library/windows/R-4.5/x86_64-w64-mingw32", .libPaths()))
Sys.setlocale("LC_CTYPE", "Portuguese_Brazil.utf8")
library(data.table)
setDTthreads(1L)
library(Matrix)
source("R/microdata_1960_amostra_127.R", encoding = "UTF-8")
source("R/microdata_1960_amostra_25.R", encoding = "UTF-8")
source("R/microdata_1960.R", encoding = "UTF-8")

erro_pesos <- function(expr, trecho){
  e <- tryCatch(force(expr), error = identity)
  stopifnot(inherits(e, "error"), grepl(trecho, conditionMessage(e), fixed = TRUE))
}

# Duas celulas independentes e um domicilio fora dos controles.
X <- sparseMatrix(i = c(1L, 2L, 3L, 4L), j = c(1L, 1L, 2L, 2L),
                  x = 1, dims = c(5L, 2L), dimnames = list(NULL, c("a", "b")))
d <- rep(4, 5)
for(limites in list(NULL, c(0.25, 3))){
  w <- raking_1960_amostra_127(X, c(12, 4), d, limites)
  stopifnot(max(abs(as.numeric(crossprod(X, w)) - c(12, 4))) < 1e-8,
            all(is.finite(w)), all(w > 0), w[5] == d[5],
            max(abs(w - c(6, 6, 2, 2, 4))) < 1e-8)
}
stopifnot(identical(raking_1960_amostra_127(X, c(8, 8), d), d))

# Alvo positivo sem suporte, limite impossivel e controles contraditorios.
X_vazio <- cbind(X, rural = 0)
erro_pesos(raking_1960_amostra_127(X_vazio, c(8, 8, 1), d), "sem suporte")
erro_pesos(raking_1960_amostra_127(X, c(25, 8), d, c(0.25, 3)), "fora dos limites")
X_singular <- sparseMatrix(i = c(1L, 2L, 1L, 2L), j = c(1L, 1L, 2L, 2L), x = 1)
erro_pesos(raking_1960_amostra_127(X_singular, c(10, 11), c(4, 4)), "singular")
# Cada alvo cabe no seu intervalo isolado, mas juntos exigiriam peso negativo.
X_conjunto <- sparseMatrix(i = c(1L, 2L, 2L), j = c(1L, 1L, 2L), x = 1)
erro_pesos(raking_1960_amostra_127(X_conjunto, c(1, 2), c(1, 1), c(0.25, 3)), "calibracao")
erro_pesos(raking_1960_amostra_127(X, c(12, 4), d, max_iter = 1L), "nao convergiu")
erro_pesos(raking_1960_amostra_127(X, c(NA_real_, 4), d), "alvos")
erro_pesos(raking_1960_amostra_127(X, c(0, 4), d), "alvos")
erro_pesos(raking_1960_amostra_127(X, c(12, 4), c(4, 4, 4, 4, Inf)), "pesos de desenho")
erro_pesos(raking_1960_amostra_127(X, c(12, 4), d, c(1, 3)), "limites")
erro_pesos(raking_1960_amostra_127(X, c(12, 4), d[-1]), "dimensoes")
X_ruim <- X; X_ruim@x[1] <- NA_real_
erro_pesos(raking_1960_amostra_127(X_ruim, c(12, 4), d), "matriz")

# RO pequena usa total por sexo e leitores, sem inventar controle rural.
# Os dois leitores declaram idade ignorada; nao sao idades danificadas.
p <- data.table(linha = 1:4, UF = 0L, censobr_idhousehold = 1:4, V118 = 1L,
                V202 = c(1L, 2L, 1L, 2L), V204 = c(9L, 9L, 1L, 1L),
                V204B = c(99L, 99L, 30L, 40L), V211 = c(1L, 1L, 3L, 3L))
h <- data.table(UF = 0L, censobr_idhousehold = 1:4, censobr_upa = "0-00001")
def <- data.table(tabela = c(33L, 33L, 40L, 40L), uf60 = 0L,
                  item = c("total", "total", "sabem", "sabem"),
                  sexo = c("homens", "mulheres", "homens", "mulheres"),
                  medida = "", valor = c(8, 8, 4, 4))
cal <- celulas_definitivos_1960_amostra_127(p, h, def)
stopifnot(ncol(cal$X) == 4L,
          identical(as.numeric(colSums(cal$X)), c(2, 2, 1, 1)),
          !any(grepl("^c\\|", cal$alvos$celula)))
p_dano <- copy(p); p_dano[linha == 1L, V204 := NA_integer_]
erro_pesos(celulas_definitivos_1960_amostra_127(p_dano, h, def), "idade danificada")
erro_pesos(celulas_definitivos_1960_amostra_127(p, h, rbind(def, def[1])), "duplicada")
erro_pesos(celulas_definitivos_1960_amostra_127(p, rbind(h, h[1]), def), "domicilios")
p_orfao <- copy(p); p_orfao[linha == 1L, censobr_idhousehold := 99L]
erro_pesos(celulas_definitivos_1960_amostra_127(p_orfao, h, def), "sem domicilio")
p_pres <- copy(p); p_pres[linha == 1L, V202 := NA_integer_]
erro_pesos(celulas_definitivos_1960_amostra_127(p_pres, h, def), "presenca desconhecida")
p_alf <- copy(p); p_alf[linha == 1L, V211 := NA_integer_]
erro_pesos(celulas_definitivos_1960_amostra_127(p_alf, h, def), "alfabetizacao desconhecida")
p_sit <- copy(p); p_sit[linha == 1L, V118 := NA_integer_]
h_oito <- data.table(UF = 0L, censobr_idhousehold = 1:8, censobr_upa = paste0("0-", 1:8))
erro_pesos(celulas_definitivos_1960_amostra_127(p_sit, h_oito, def), "situacao desconhecida")
p_menor <- copy(p); p_menor[linha == 3L, `:=`(V204B = 2L, V211 = NA_integer_)]
stopifnot(ncol(celulas_definitivos_1960_amostra_127(p_menor, h, def)$X) == 4L)

# Calibrador completo de 1,27%, apenas quatro registros artificiais. Os controles
# preliminares ja fecham no peso-base; os definitivos de FN fecham no peso 4.
dir.create("tmp/execucao_1960_20260922", recursive = TRUE, showWarnings = FALSE)
pasta_controles <- tempfile("controles_pesos_", tmpdir = "tmp/execucao_1960_20260922")
dir.create(pasta_controles)
pp <- copy(p)[, `:=`(UF = 24L, censobr_weight = 1 / 0.0127)]
hh <- copy(h)[, `:=`(UF = 24L, censobr_upa = "24-27002", censobr_weight = 1 / 0.0127)]
gab <- data.table(quadro = c(1L, 1L, 1L, 1L, 2L, 2L), regiao = "Nordeste",
  linha = c("70 e mais e ignorada", "70 e mais e ignorada", "30 a 39", "40 a 49", "5 e mais", "5 e mais"),
  coluna = c("urbana_homens", "urbana_mulheres", "urbana_homens", "urbana_mulheres", "sabem_homens", "sabem_mulheres"),
  valor = 1 / 0.0127)
gab_path <- file.path(pasta_controles, "preliminares.csv")
def_path <- file.path(pasta_controles, "definitivos.csv")
fwrite(gab, gab_path)
fwrite(copy(def)[, `:=`(uf60 = 24L, nivel = "uf")], def_path)
diagnostico_fn <- celulas_definitivos_1960_amostra_127(pp, hh, fread(def_path))
stopifnot(all(diagnostico_fn$alvos$implicito == 1))
cal127 <- calibrate_1960_amostra_127(list(pessoas = pp, domicilios = hh), gab_path, def_path)
stopifnot(nrow(cal127$pessoas) == 4L, nrow(cal127$domicilios) == 4L,
          all(abs(cal127$pessoas$censobr_weight - 4) < 1e-8),
          all(cal127$pessoas$censobr_weight_desenho == 4),
          all(cal127$domicilios$censobr_weight_desenho == 4),
          all(abs(cal127$pessoas$censobr_weight_fator - 1) < 1e-8),
          all(abs(cal127$domicilios$censobr_weight_fator - 1) < 1e-8),
          all(abs(cal127$pessoas$censobr_weight_1965 - 1 / 0.0127) < 1e-8),
          all(abs(cal127$pessoas$censobr_weight_1965_fator - 1) < 1e-8),
          all(pp$censobr_weight == 1 / 0.0127), identical(pp$V204, p$V204))
pp[linha == 1L, V204 := NA_integer_]
erro_pesos(calibrate_1960_amostra_127(list(pessoas = pp, domicilios = hh), gab_path, def_path), "idade danificada")
pp[linha == 1L, V204 := 9L]
for(col in c("V202", "V118", "V211")){
  ruim <- copy(pp); set(ruim, i = 1L, j = col, value = NA_integer_)
  trecho <- c(V202 = "presenca desconhecida", V118 = "situacao desconhecida", V211 = "alfabetizacao desconhecida")[[col]]
  erro_pesos(calibrate_1960_amostra_127(list(pessoas = ruim, domicilios = hh), gab_path, def_path), trecho)
}
# Fora de FN a base final continua 1/0,0127; nenhum peso de 1965 muda.
gab_normal <- copy(gab)[, regiao := "Norte e Centro-Oeste"]
def_normal <- copy(def)[, `:=`(valor = c(2, 2, 1, 1) / 0.0127, nivel = "uf")]
gab_normal_path <- file.path(pasta_controles, "preliminares_normal.csv")
def_normal_path <- file.path(pasta_controles, "definitivos_normal.csv")
fwrite(gab_normal, gab_normal_path); fwrite(def_normal, def_normal_path)
diagnostico_normal <- celulas_definitivos_1960_amostra_127(p, h, copy(def_normal))
stopifnot(all(diagnostico_normal$alvos$implicito == 1))
cal_normal <- calibrate_1960_amostra_127(
  list(pessoas = copy(p)[, censobr_weight := 1 / 0.0127],
       domicilios = copy(h)[, censobr_weight := 1 / 0.0127]), gab_normal_path, def_normal_path)
stopifnot(all(cal_normal$pessoas$censobr_weight_desenho == 1 / 0.0127),
          all(abs(cal_normal$pessoas$censobr_weight - 1 / 0.0127) < 1e-8),
          all(abs(cal_normal$pessoas$censobr_weight_fator - 1) < 1e-8),
          all(abs(cal_normal$pessoas$censobr_weight_1965 - 1 / 0.0127) < 1e-8))

# O contrato do staging e aditivo, sem trocar as ordens de retorno publicas.
stopifnot("out_dir" %in% names(formals(weight_1960_amostra_25)),
          "out_dir" %in% names(formals(compile_1960)),
          "out_dir" %in% names(formals(save_1960_amostra_127)))

# Bloco de I/O separado, depois do teste seguro de Arrow: habilitar explicitamente.
if(identical(Sys.getenv("CENSOBR_TEST_PESOS_ARROW"), "1")){
  source("R/support_fun.R", encoding = "UTF-8")
  dir.create("tmp/execucao_1960_20260922", recursive = TRUE, showWarnings = FALSE)
  pasta_teste <- tempfile("pesos_sinteticos_", tmpdir = "tmp/execucao_1960_20260922")
  entrada <- file.path(pasta_teste, "entrada", "fn")
  saida <- file.path(pasta_teste, "pesos", "fn")
  dir.create(entrada, recursive = TRUE)
  p25 <- copy(p)[, `:=`(UF = 24L, code_muni_1960 = 2401L,
                       code_muni = 2000107L, censobr_idfamily = censobr_idhousehold)]
  h25 <- copy(h)[, `:=`(UF = 24L, V118 = 1L, v001 = 27002L, v002 = 1:4,
                       code_muni_1960 = 2401L, code_muni = 2000107L,
                       censobr_n_presentes = 1L, linha = 101:104)]
  entradas <- c(file.path(entrada, "pessoas_geo.parquet"), file.path(entrada, "domicilios.parquet"))
  arrow::write_parquet(p25, entradas[1])
  arrow::write_parquet(h25, entradas[2])
  hash_antes <- tools::md5sum(entradas)
  municipios <- file.path(pasta_teste, "municipios.csv")
  definitivos <- file.path(pasta_teste, "definitivos.csv")
  fwrite(data.table(uf60 = 24L, cod60 = 2401L, pop_urbana = 16L, pop_rural = 0L), municipios)
  def25 <- rbind(copy(def)[, uf60 := 24L],
                 data.table(tabela = 32L, uf60 = 24L, item = "presente",
                            sexo = c("homens", "mulheres"), medida = "", valor = 8))
  def25[, `:=`(nivel = "uf", nome = "Fernando de Noronha", regiao = "Nordeste")]
  fwrite(def25, definitivos)
  novos <- weight_1960_amostra_25(entradas, "fn", municipios, definitivos, out_dir = saida)
  np <- as.data.table(arrow::read_parquet(novos[2]))
  nd <- as.data.table(arrow::read_parquet(novos[1]))
  message("Destino sintetico: ", saida, "; caminhos: ", paste(novos, collapse = ", "))
  stopifnot(identical(basename(novos), c("domicilios_pesos.parquet", "pessoas_pesos.parquet")),
            all(normalizePath(dirname(novos), winslash = "/") == normalizePath(saida, winslash = "/")),
            identical(tools::md5sum(entradas), hash_antes),
            nrow(np) == 4L, nrow(nd) == 4L, all(abs(np$censobr_weight - 4) < 1e-8),
            np[V204 == 9L & V211 == 1L, sum(censobr_weight)] == 8)

  # Uma idade danificada deve parar, nao ser promovida ao mesmo grupo de V204=9.
  p25[linha == 1L, V204 := NA_integer_]
  arrow::write_parquet(p25, entradas[1])
  erro_pesos(weight_1960_amostra_25(entradas, "fn", municipios, definitivos,
                                  out_dir = file.path(pasta_teste, "nao_gravar", "fn")), "idade danificada")
  stopifnot(!dir.exists(file.path(pasta_teste, "nao_gravar", "fn")))
  p25[linha == 1L, V204 := 9L]
  for(caso in c("presenca", "situacao_pessoa", "situacao_domicilio", "alfabetizacao")){
    ruim_p <- copy(p25); ruim_d <- copy(h25)
    if(caso == "presenca") ruim_p[linha == 1L, V202 := NA_integer_]
    if(caso == "situacao_pessoa") ruim_p[linha == 1L, V118 := NA_integer_]
    if(caso == "situacao_domicilio") ruim_d[1L, V118 := NA_integer_]
    if(caso == "alfabetizacao") ruim_p[linha == 1L, V211 := NA_integer_]
    local <- file.path(pasta_teste, caso); dir.create(local)
    arqs <- file.path(local, c("domicilios.parquet", "pessoas_geo.parquet"))
    arrow::write_parquet(ruim_d, arqs[1]); arrow::write_parquet(ruim_p, arqs[2])
    trecho <- if(grepl("situacao", caso)) "situacao desconhecida" else paste(caso, "desconhecida")
    erro_pesos(weight_1960_amostra_25(arqs, "fn", municipios, definitivos,
                                    out_dir = file.path(local, "saida")), trecho)
    stopifnot(!dir.exists(file.path(local, "saida")))
  }

  # A compilacao deve ler este par sintetico, nao os arquivos reais de FN.
  entrada_comp <- file.path(pasta_teste, "entrada_compilacao", "fn")
  dir.create(entrada_comp, recursive = TRUE)
  comp_inputs <- file.path(entrada_comp, basename(novos))
  for(tabela in c("dom", "pes")){
    z <- if(tabela == "dom") nd else np
    cols <- if(tabela == "dom") COLUNAS_1960_DOM else COLUNAS_1960_PES
    for(col in setdiff(cols, c(names(z), "censobr_linha"))){
      texto <- grepl("^(name_|abbrev_)|^situacao$|^censobr_(estrato|tipo_unidade|amostra|diagnostico|variaveis_anuladas|familia_origem|tipo_registro|weight_nivel)$", col)
      set(z, j = col, value = if(texto) NA_character_ else NA_integer_)
    }
    z[, `:=`(v001 = 27002L, v002 = 1:4)]
    arrow::write_parquet(z, comp_inputs[if(tabela == "dom") 1L else 2L])
  }
  hash_pesos <- tools::md5sum(c(novos, comp_inputs))
  compilados <- compile_1960(list(comp_inputs[2], comp_inputs[1]), character(), NULL, "fn", municipios,
                             definitivos, out_dir = file.path(pasta_teste, "compilada", "fn"))
  cp <- as.data.table(arrow::read_parquet(compilados[2]))
  stopifnot(identical(basename(compilados), c("domicilios.parquet", "pessoas.parquet")),
            nrow(cp) == 4L, all(cp$UF == 24L), all(abs(cp$censobr_weight - 4) < 1e-8),
            identical(tools::md5sum(c(novos, comp_inputs)), hash_pesos))
  salvo127 <- save_1960_amostra_127(list(pessoas = np, domicilios = nd),
                                   out_dir = file.path(pasta_teste, "amostra_127"))
  stopifnot(identical(basename(salvo127), c("pessoas_1960_amostra_127.parquet", "domicilios_1960_amostra_127.parquet")),
            nrow(arrow::read_parquet(salvo127[1])) == 4L)
  message("I/O sintetico de pesos conferido em ", pasta_teste)
}

message("Testes sinteticos de pesos passaram; nenhuma base real foi recalibrada.")
