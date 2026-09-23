# Microdados ficticios: os rotulos nao podem mudar nenhum resultado numerico.
raiz <- normalizePath(".", winslash = "/")
.libPaths(c(normalizePath("renv/library/windows/R-4.5/x86_64-w64-mingw32", winslash = "/"), .libPaths()))
Sys.setlocale("LC_CTYPE", "Portuguese_Brazil.utf8")
library(data.table)
setDTthreads(1L)

etapa <- Sys.getenv("CENSOBR_ROTULOS_ETAPA", "depois")
stopifnot(etapa %in% c("antes", "depois"))
auditoria <- file.path(raiz, "tmp/correcao_scripts_r_1960_20260923")
dir.create(auditoria, recursive = TRUE, showWarnings = FALSE)
baseline <- file.path(auditoria, "rotulos_erros_antes.rds")
portatil <- file.path(raiz, "references/correcao_scripts_r_1960_evidencias/rotulos_erros_antes.rds")
if(file.exists(portatil)) baseline <- portatil
if(etapa == "antes" && file.exists(baseline)) stop("A referencia anterior ja existe; nao sobrescrever.")

e <- new.env(parent = globalenv())
for(arquivo in c("microdata_1960_amostra_127.R", "microdata_1960_amostra_25.R", "microdata_1960.R"))
  sys.source(file.path(raiz, "R", arquivo), envir = e)
e$UF_1960_AMOSTRA_25 <- c(sp = 60L)
e$UF_1960_AMOSTRA_127 <- c(sc = 74L)

ensaio <- tempfile(paste0("rotulos_", etapa, "_"), tmpdir = auditoria)
dir.create(ensaio)
setwd(ensaio)
for(pasta in c("amostra_127", "amostra_25/sp", "compilada/sp", "compilada/sc"))
  dir.create(file.path("data_raw/microdata/1960", pasta), recursive = TRUE)

d <- data.table(UF = 60L, censobr_idhousehold = 1:4,
  censobr_upa = rep(c("pasta1", "pasta2"), each = 2L),
  censobr_estrato = "60-teste", censobr_weight = 80, censobr_weight_1965 = 100)
p <- data.table(UF = 60L, censobr_idhousehold = c(1L, 1L, 2L, 3L, 4L, 4L, 4L),
  V118 = c(1L, 1L, 5L, 1L, 5L, 5L, 5L),
  V202 = c(1L, 2L, 1L, 1L, 2L, 1L, 2L), V204 = 1L,
  V204B = c(35L, 35L, 4L, 40L, 40L, 4L, 10L), V211 = 2L,
  V219 = c(5L, 0L, 0L, 5L, 0L, 0L, 0L),
  censobr_weight = 80, censobr_weight_1965 = 100)
gabarito <- data.table(nivel = "uf", tabela = 33L, uf60 = 60L,
  item = "total", sexo = c("homens", "mulheres"), medida = "pessoas",
  valor = c(320, 240))
fwrite(gabarito, "gabarito.csv")
p_antes <- copy(p)
d_antes <- copy(d)

r127 <- e$sampling_errors_1960_amostra_127(
  list(pessoas = copy(p), domicilios = copy(d)), "gabarito.csv")
stopifnot(identical(p, p_antes), identical(d, d_antes))

p25 <- copy(p)
p25[, `:=`(censobr_weight  = 4,
           censobr_upa     = censobr_idhousehold,
           censobr_estrato = paste0("25-", ceiling(censobr_idhousehold / 2)))]
path25 <- "data_raw/microdata/1960/amostra_25/sp/pessoas_pesos.parquet"
arrow::write_parquet(p25, path25)
saida25 <- e$sampling_errors_1960_amostra_25(path25)

p25[, `:=`(censobr_usa  = censobr_idhousehold,
           censobr_fpc  = 1 / 4,
           censobr_fpc2 = 1)]
path_sp <- "data_raw/microdata/1960/compilada/sp/pessoas.parquet"
arrow::write_parquet(p25, path_sp)
p127 <- copy(p)
p127[, `:=`(UF              = 74L,
            censobr_upa     = paste0("127-", ceiling(censobr_idhousehold / 2)),
            censobr_estrato = "127-teste",
            censobr_usa     = censobr_idhousehold,
            censobr_fpc     = 1 / 20,
            censobr_fpc2    = 1 / 4)]
path_sc <- "data_raw/microdata/1960/compilada/sc/pessoas.parquet"
arrow::write_parquet(p127, path_sc)
saida_compilada <- e$sampling_errors_1960(c(path_sp, path_sc))

resultados <- list(amostra_127 = r127,
                   csv_127    = fread("data_raw/microdata/1960/amostra_127/erros_amostrais.csv"),
                   amostra_25 = fread(saida25),
                   compilada  = fread(saida_compilada))
stopifnot(r127[peso == "censobr_weight" & regiao == "Brasil" &
                situacao == "ambas" & faixa == "todas", erro_padrao_calibrado] == 0,
  r127[peso == "censobr_weight" & regiao == "Brasil" &
         situacao == "ambas" & faixa == "todas", erro_padrao] > 0)
for(x in resultados) setindexv(x, NULL)
if(etapa == "antes") saveRDS(resultados, baseline)

campos <- c("status_analise", "variancia_total_validada", "metodo_erro_padrao",
  "metodo_erro_padrao_calibrado", "incerteza_controles_incorporada", "aviso_interpretacao")
falhas <- character()
for(nome in names(resultados)){
  x <- resultados[[nome]]
  if(!all(campos %in% names(x))){
    falhas <- c(falhas, paste(nome, "sem identificacao de diagnostico provisorio"))
    next
  }
  stopifnot(all(x$status_analise == "diagnostico_provisorio"),
    all(x$variancia_total_validada == FALSE),
    all(x$metodo_erro_padrao == "aproximacao_desenho_reconstruido"),
    all(x$incerteza_controles_incorporada == FALSE),
    all(nzchar(x$aviso_interpretacao)), all(grepl("revisao", x$aviso_interpretacao, ignore.case = TRUE)))
  if(nome %in% c("amostra_127", "csv_127")){
    stopifnot(all(x[peso == "censobr_weight", metodo_erro_padrao_calibrado] ==
      "residuos_condicionados_a_controles_fixos"),
      all(x[peso == "censobr_weight_1965", metodo_erro_padrao_calibrado] == "nao_calculado"),
      all(x[peso == "censobr_weight_1965", is.na(erro_padrao_calibrado)]),
      all(grepl("zero nao significa erro populacional zero", x[peso == "censobr_weight", aviso_interpretacao])))
  } else stopifnot(all(x$metodo_erro_padrao_calibrado == "nao_calculado"))
}

if(etapa == "depois"){
  anteriores <- readRDS(baseline)
  for(nome in names(resultados)){
    x <- resultados[[nome]][, names(anteriores[[nome]]), with = FALSE]
    setindexv(x, NULL)
    anterior <- anteriores[[nome]]
    stopifnot(identical(names(x), names(anterior)), identical(nrow(x), nrow(anterior)),
      identical(class(x), class(anterior)))
    for(coluna in names(anterior)){
      if(!identical(x[[coluna]], anterior[[coluna]]))
        stop("Valores ou tipo alterados: ", nome, " / ", coluna)
    }
    if(!identical(x, anterior)) message("Valores identicos; referencia interna da tabela difere: ", nome)
    message("Valores anteriores preservados: ", nome)
  }
}
setwd(raiz)
if(length(falhas)) stop(paste(falhas, collapse = "; "))
message("Rotulos conferidos nas tres funcoes, no retorno e nos CSVs; residuos zero permanecem diagnosticos.")
