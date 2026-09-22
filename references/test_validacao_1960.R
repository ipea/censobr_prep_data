# Testes sinteticos executados com sucesso em 22/09/2026 pelo runner isolado.
# Ver microdata_1960_validacao_etapa4_20260922.md. Sem targets ou dados reais:
# os parquets sinteticos e os CSVs ficam numa pasta exclusiva sob tmp/.
# Uso futuro, da raiz do projeto: source("references/test_validacao_1960.R")
.libPaths(c("renv/library/windows/R-4.5/x86_64-w64-mingw32", .libPaths()))
Sys.setlocale("LC_CTYPE", "Portuguese_Brazil.utf8")
library(data.table)
setDTthreads(1L)
source("R/microdata_1960_amostra_127.R", encoding = "UTF-8")
source("R/microdata_1960_amostra_25.R", encoding = "UTF-8")
source("R/microdata_1960.R", encoding = "UTF-8")
source("R/microdata_1960_validacao.R", encoding = "UTF-8")

# Cada consulta deve encontrar exatamente uma celula, nunca um teste vazio.
celula_cmp_1960 <- function(r, uf_teste, tab_teste, item_teste, sexo_teste,
                            peso_teste = "censobr_weight", medida_teste = ""){
  z <- r[uf60 == uf_teste & tabela == tab_teste & item == item_teste &
           sexo == sexo_teste & peso == peso_teste & medida == medida_teste]
  stopifnot(nrow(z) == 1L)
  z
}

ler_cmp_1960 <- function(caminho, diretorio, compilado = FALSE){
  stopifnot(is.character(caminho), length(caminho) == 1L, file.exists(caminho))
  stopifnot(identical(normalizePath(dirname(caminho), winslash = "/"),
                      normalizePath(diretorio, winslash = "/")))
  r <- fread(caminho, encoding = "UTF-8")
  obrigatorias <- c("uf60", "tabela", "item", "sexo", "medida", "valor", "publicado",
                    "dif", "dif_pct", "valor_parcial", "n_amostra", "n_pesos_ausentes",
                    "n_sem_classificacao", "peso_sem_classificacao",
                    "n_pesos_ausentes_sem_classificacao", "status_celula")
  stopifnot(nrow(r) > 0L, all(obrigatorias %in% names(r)))
  if(compilado && !"peso" %in% names(r)) r[, peso := "censobr_weight"]
  stopifnot("peso" %in% names(r))
  r[is.na(sexo), sexo := ""][is.na(medida), medida := ""]
  stopifnot(all(r$status_celula %in% c("observada", "sem_observacoes", "nao_reconstruida",
                                      "peso_ausente", "classificacao_incompleta")))
  r
}

conferir_grade_cmp_1960 <- function(r, g, pesos){
  chaves <- c("peso", "uf60", "tabela", "item", "sexo", "medida")
  esperado <- rbindlist(lapply(pesos, function(w) copy(g)[, peso := w]))
  esperado[is.na(sexo), sexo := ""][is.na(medida), medida := ""]
  stopifnot(nrow(esperado) > 0L, nrow(r) == nrow(esperado),
            !anyDuplicated(r[, ..chaves]), !anyDuplicated(esperado[, ..chaves]))
  a <- r[, c(chaves, "publicado"), with = FALSE]
  b <- esperado[, c(chaves, "valor"), with = FALSE]
  setnames(b, "valor", "referencia_teste")
  z <- merge(a, b, by = chaves, all = TRUE)
  stopifnot(nrow(z) == nrow(esperado), !anyNA(z$publicado),
            !anyNA(z$referencia_teste), all(z$publicado == z$referencia_teste))
}

dir.create("tmp", showWarnings = FALSE)
test_dir <- tempfile("validacao_1960_", tmpdir = "tmp")
dir.create(test_dir)
def_path <- "references/censo_1960_resultados_definitivos_serie_nacional.csv"
def <- fread(def_path, encoding = "UTF-8")
tabelas_pessoais <- c(32L, 33L, 34L, 37L, 40L)
grade25 <- def[nivel == "uf" & uf60 %in% UF_1960_AMOSTRA_25 &
                (tabela == 7L | (tabela %in% tabelas_pessoais & sexo %in% c("homens", "mulheres")))]
grade_comp <- def[nivel %in% c("uf", "brasil") &
                   (tabela == 7L | (tabela %in% tabelas_pessoais & sexo %in% c("homens", "mulheres")))]
grade_comp[nivel == "brasil", uf60 := 999L]
stopifnot(nrow(grade25[tabela %in% tabelas_pessoais]) == 918L,
          nrow(grade_comp[tabela %in% tabelas_pessoais]) == 1566L,
          nrow(grade25[tabela == 7L]) == 102L,
          nrow(grade_comp[tabela == 7L]) == 174L)

# SP: leitor de idade ignorada e cor 8; mulher de seis anos; homem ausente;
# visitante masculino com oito meses. RO: dois moradores presentes urbanos.
# Pesos fracionarios tornam visivel qualquer arredondamento antes da comparacao.
sp <- data.table(UF = rep(60L, 4), linha = 1:4,
                 V118 = c(5L, 1L, 1L, 1L), V202 = c(1L, 2L, 3L, 5L),
                 V204 = c(9L, 1L, 1L, 0L), V204B = c(99L, 6L, 25L, 8L),
                 V206 = c(8L, 4L, 5L, 9L), V211 = c(1L, 2L, 1L, NA_integer_),
                 censobr_upa = paste0("60-teste-", 1:4),
                 censobr_weight = c(2.25, 3.5, 5.75, 7.125),
                 censobr_weight_ibge = c(3.25, 4.5, 6.75, 8.125),
                 censobr_amostra = rep("25%", 4))
ro <- data.table(UF = c(0L, 0L), linha = 1:2, V118 = c(1L, 1L),
                 V202 = c(1L, 2L), V204 = c(1L, 1L), V204B = c(40L, 6L),
                 V206 = c(4L, 7L), V211 = c(1L, 2L),
                 censobr_upa = c("0-teste-1", "0-teste-2"),
                 censobr_weight = c(10.25, 5.5), censobr_weight_ibge = c(NA_real_, NA_real_),
                 censobr_amostra = c("1,27%", "1,27%"))
dir25 <- file.path(test_dir, "base25", "sp")
dir_sp <- file.path(test_dir, "base_comp", "sp")
dir_ro <- file.path(test_dir, "base_comp", "ro")
for(diretorio in c(dir25, dir_sp, dir_ro)) dir.create(diretorio, recursive = TRUE)
path25 <- file.path(dir25, "pessoas_pesos.parquet")
path_sp <- file.path(dir_sp, "pessoas.parquet")
path_ro <- file.path(dir_ro, "pessoas.parquet")
arrow::write_parquet(sp, path25)
arrow::write_parquet(sp, path_sp)
arrow::write_parquet(ro, path_ro)

# As funcoes publicas recebem apenas fixtures; nao devem procurar UFs em producao.
out25 <- file.path(test_dir, "relatorio25")
out_comp <- file.path(test_dir, "relatorio_comp")
r25 <- ler_cmp_1960(validate_definitivos_1960_amostra_25(path25, def_path, out_dir = out25), out25)
rc <- ler_cmp_1960(validate_1960(list(ro = path_ro, sp = path_sp), def_path, out_dir = out_comp),
                  out_comp, compilado = TRUE)
conferir_grade_cmp_1960(r25, grade25, c("censobr_weight", "censobr_weight_ibge"))
conferir_grade_cmp_1960(rc, grade_comp, "censobr_weight")
stopifnot(nrow(r25) == 2040L, nrow(rc) == 1740L)

for(r in list(r25, rc)){
  # Tabelas 33/34/37 precisam ter totais calculados, mesmo se parte dos quesitos
  # individuais nao se aplicar: os dois homens presentes somam 9.375.
  for(tab_teste in c(33L, 34L, 37L)){
    z <- celula_cmp_1960(r, 60L, tab_teste, "total", "homens")
    stopifnot(z$valor == 9.375, z$n_amostra == 2L, z$status_celula == "observada",
              z$n_pesos_ausentes == 0L, z$n_sem_classificacao == 0L,
              abs(z$dif - (9.375 - z$publicado)) < 1e-9)
  }
  z <- celula_cmp_1960(r, 60L, 32L, "residente", "homens")
  stopifnot(z$valor == 8, z$n_amostra == 2L)
  z <- celula_cmp_1960(r, 60L, 33L, "0 a 4", "homens")
  stopifnot(z$valor == 7.125, z$n_amostra == 1L)
  z <- celula_cmp_1960(r, 60L, 33L, "ignorada", "homens")
  stopifnot(z$valor == 2.25, z$n_amostra == 1L)
  z <- celula_cmp_1960(r, 60L, 37L, "pardos", "homens")
  stopifnot(z$valor == 2.25, z$n_amostra == 1L)
  for(item_teste in c("5 e mais", "sabem")){
    z <- celula_cmp_1960(r, 60L, 40L, item_teste, "homens")
    stopifnot(z$valor == 2.25, z$n_amostra == 1L, z$status_celula == "observada")
  }
  z <- r[tabela == 7L]
  stopifnot(nrow(z) > 0L, all(z$status_celula == "nao_reconstruida"),
            all(is.na(z$valor)), all(is.na(z$dif)))
  # A BA consta da referencia, mas nenhum arquivo da BA foi fornecido.
  z <- celula_cmp_1960(r, 31L, 32L, "presente", "homens")
  stopifnot(z$status_celula == "nao_reconstruida", is.na(z$valor), is.na(z$dif))
}
z <- celula_cmp_1960(r25, 60L, 40L, "sabem", "homens", "censobr_weight_ibge")
stopifnot(z$valor == 3.25, z$n_amostra == 1L)

# Zero observado em RO rural tem referencia positiva, diferentemente da UF
# que nao foi fornecida. Brasil deve reconhecer que faltam 26 UFs nos paths.
z <- celula_cmp_1960(rc, 0L, 34L, "rural", "homens")
stopifnot(z$publicado == 23324, z$valor == 0, z$valor_parcial == 0,
          z$n_amostra == 0L, z$n_sem_classificacao == 0L,
          z$status_celula == "sem_observacoes", z$dif == -23324, z$dif_pct == -100)
z <- celula_cmp_1960(rc, 999L, 32L, "presente", "homens")
stopifnot(z$status_celula == "nao_reconstruida", is.na(z$valor), is.na(z$dif),
          "motivo" %in% names(z))
stopifnot(!is.na(z$motivo), nzchar(z$motivo))

# Sem qualquer UF informada, conservar a grade sem inventar zeros observados.
out_vazio25 <- file.path(test_dir, "vazio25")
out_vazio_comp <- file.path(test_dir, "vazio_comp")
v25 <- ler_cmp_1960(validate_definitivos_1960_amostra_25(character(), def_path, out_dir = out_vazio25),
                   out_vazio25)
vc <- ler_cmp_1960(validate_1960(list(), def_path, out_dir = out_vazio_comp),
                  out_vazio_comp, compilado = TRUE)
conferir_grade_cmp_1960(v25, grade25, c("censobr_weight", "censobr_weight_ibge"))
conferir_grade_cmp_1960(vc, grade_comp, "censobr_weight")
for(r in list(v25, vc)) stopifnot(nrow(r) > 0L, all(r$status_celula == "nao_reconstruida"),
                                 all(is.na(r$valor)), all(is.na(r$dif)))

# Referencia zero: preservar a diferenca absoluta, nunca dividir por zero.
def_zero <- copy(def)
stopifnot(nrow(def_zero[nivel == "uf" & uf60 == 60L & tabela == 33L &
                         item == "ignorada" & sexo == "homens"]) == 1L,
          nrow(def_zero[nivel == "uf" & uf60 == 60L & tabela == 34L &
                         item == "rural" & sexo == "mulheres"]) == 1L)
def_zero[nivel == "uf" & uf60 == 60L & tabela == 33L & item == "ignorada" & sexo == "homens", valor := 0]
def_zero[nivel == "uf" & uf60 == 60L & tabela == 34L & item == "rural" & sexo == "mulheres", valor := 0]
zero_path <- file.path(test_dir, "referencias_zero_sinteticas.csv")
fwrite(def_zero, zero_path)
for(modo in c("25", "comp")){
  out <- file.path(test_dir, paste0("zero_", modo))
  caminho <- if(modo == "25") validate_definitivos_1960_amostra_25(list(sp = path25), zero_path, out_dir = out) else
    validate_1960(path_sp, zero_path, out_dir = out)
  r <- ler_cmp_1960(caminho, out, compilado = modo == "comp")
  z <- celula_cmp_1960(r, 60L, 33L, "ignorada", "homens")
  stopifnot(z$publicado == 0, z$valor == 2.25, z$dif == 2.25,
            is.na(z$dif_pct), z$status_celula == "observada")
  z <- celula_cmp_1960(r, 60L, 34L, "rural", "mulheres")
  stopifnot(z$publicado == 0, z$valor == 0, z$dif == 0,
            is.na(z$dif_pct), z$status_celula == "sem_observacoes")
}

# Mutacoes isoladas. Cada chamada utiliza uma pasta SP nova; ninguem modifica
# os parquets da fixture-base nem os arquivos reais.
for(cenario in c("peso_na", "peso_inf", "idade_danificada", "tipo_idade_ausente", "sexo_ausente",
                 "situacao_ausente", "cor_ausente", "alfabetizacao_ausente")){
  q <- copy(sp)
  if(cenario == "peso_na") q[linha == 1L, censobr_weight := NA_real_]
  if(cenario == "peso_inf") q[linha == 1L, censobr_weight := Inf]
  if(cenario %in% c("idade_danificada", "tipo_idade_ausente", "sexo_ausente", "situacao_ausente")){
    extra <- copy(sp[1])
    extra[, `:=`(linha = 5L, V118 = 1L, V202 = 1L, V204 = 1L, V204B = 30L,
                  V206 = 4L, V211 = 1L, censobr_upa = "60-teste-5",
                  censobr_weight = 11, censobr_weight_ibge = 12)]
    if(cenario == "idade_danificada") extra[, V204B := NA_integer_]
    if(cenario == "tipo_idade_ausente") extra[, V204 := NA_integer_]
    if(cenario == "sexo_ausente") extra[, V202 := NA_integer_]
    if(cenario == "situacao_ausente") extra[, V118 := NA_integer_]
    q <- rbind(q, extra)
  }
  if(cenario == "cor_ausente") q[linha == 1L, V206 := NA_integer_]
  if(cenario == "alfabetizacao_ausente") q[linha == 1L, V211 := NA_integer_]
  for(modo in c("25", "comp")){
    pasta <- file.path(test_dir, cenario, modo, "sp")
    dir.create(pasta, recursive = TRUE)
    entrada <- file.path(pasta, if(modo == "25") "pessoas_pesos.parquet" else "pessoas.parquet")
    arrow::write_parquet(q, entrada)
    out <- file.path(test_dir, cenario, paste0("relatorio_", modo))
    caminho <- if(modo == "25") validate_definitivos_1960_amostra_25(list(sp = entrada), def_path, out_dir = out) else
      validate_1960(entrada, def_path, out_dir = out)
    r <- ler_cmp_1960(caminho, out, compilado = modo == "comp")
    if(cenario %in% c("peso_na", "peso_inf")){
      z <- celula_cmp_1960(r, 60L, 32L, "presente", "homens")
      stopifnot(z$n_amostra == 2L, z$n_pesos_ausentes == 1L,
                z$status_celula == "peso_ausente", is.na(z$valor),
                is.na(z$dif), is.na(z$dif_pct))
      if(modo == "25"){
        z <- celula_cmp_1960(r, 60L, 32L, "presente", "homens", "censobr_weight_ibge")
        stopifnot(z$valor == 11.375, z$status_celula == "observada", z$n_pesos_ausentes == 0L)
      }
    }
    if(cenario == "idade_danificada"){
      z <- celula_cmp_1960(r, 60L, 33L, "ignorada", "homens")
      # O tipo conhecido "anos" exclui esta pessoa da declaracao "ignorada".
      stopifnot(z$valor == 2.25, z$n_amostra == 1L, z$n_sem_classificacao == 0L,
                z$status_celula == "observada")
      z <- celula_cmp_1960(r, 60L, 33L, "30 a 39", "homens")
      stopifnot(is.na(z$valor), z$valor_parcial == 0, z$n_sem_classificacao == 1L,
                z$status_celula == "classificacao_incompleta")
      for(item_teste in c("5 e mais", "sabem")){
        z <- celula_cmp_1960(r, 60L, 40L, item_teste, "homens")
        stopifnot(is.na(z$valor), is.na(z$dif), z$valor_parcial == 2.25,
                  z$n_sem_classificacao == 1L, z$status_celula == "classificacao_incompleta")
      }
      z <- celula_cmp_1960(r, 60L, 33L, "total", "homens")
      stopifnot(z$valor == 20.375, z$n_amostra == 3L, z$status_celula == "observada")
    }
    if(cenario == "tipo_idade_ausente"){
      # Sem o tipo, nao sabemos se a idade era declarada ignorada ou numerica.
      z <- celula_cmp_1960(r, 60L, 33L, "ignorada", "homens")
      stopifnot(is.na(z$valor), z$valor_parcial == 2.25, z$n_sem_classificacao == 1L,
                z$status_celula == "classificacao_incompleta")
      z <- celula_cmp_1960(r, 60L, 40L, "5 e mais", "homens")
      stopifnot(is.na(z$valor), z$valor_parcial == 2.25, z$n_sem_classificacao == 1L,
                z$status_celula == "classificacao_incompleta")
    }
    if(cenario == "sexo_ausente"){
      for(sexo_teste in c("homens", "mulheres")){
        z <- celula_cmp_1960(r, 60L, 32L, "presente", sexo_teste)
        stopifnot(is.na(z$valor), z$n_sem_classificacao == 1L,
                  z$valor_parcial == if(sexo_teste == "homens") 9.375 else 3.5,
                  z$status_celula == "classificacao_incompleta")
      }
    }
    if(cenario == "situacao_ausente"){
      for(item_teste in c("urbana", "rural")){
        z <- celula_cmp_1960(r, 60L, 34L, item_teste, "homens")
        stopifnot(is.na(z$valor), z$n_sem_classificacao == 1L,
                  z$valor_parcial == if(item_teste == "urbana") 7.125 else 2.25,
                  z$status_celula == "classificacao_incompleta")
      }
      z <- celula_cmp_1960(r, 60L, 34L, "total", "homens")
      stopifnot(z$valor == 20.375, z$status_celula == "observada")
    }
    if(cenario == "cor_ausente"){
      z <- celula_cmp_1960(r, 60L, 37L, "pardos", "homens")
      stopifnot(is.na(z$valor), z$valor_parcial == 0, z$n_sem_classificacao == 1L,
                z$status_celula == "classificacao_incompleta")
      z <- celula_cmp_1960(r, 60L, 37L, "total", "homens")
      stopifnot(z$valor == 9.375, z$status_celula == "observada")
    }
    if(cenario == "alfabetizacao_ausente"){
      z <- celula_cmp_1960(r, 60L, 40L, "sabem", "homens")
      stopifnot(is.na(z$valor), z$valor_parcial == 0, z$n_sem_classificacao == 1L,
                z$status_celula == "classificacao_incompleta")
      z <- celula_cmp_1960(r, 60L, 40L, "5 e mais", "homens")
      stopifnot(z$valor == 2.25, z$status_celula == "observada")
    }
  }
}

# Caminho e conteudo precisam concordar antes de qualquer agregacao por UF.
# Os arquivos defeituosos abaixo sao fixtures de teste, nao dados do pipeline.
for(modo in c("25", "comp")){
  nome_arquivo <- if(modo == "25") "pessoas_pesos.parquet" else "pessoas.parquet"
  original <- if(modo == "25") path25 else path_sp
  for(cenario in c("uf_repetida", "uf_desconhecida", "uf_diferente", "uf_mista", "uf_na", "arquivo_vazio")){
    q <- copy(sp)
    if(cenario == "uf_diferente") q[, UF := 31L]
    if(cenario == "uf_mista") q[linha == 1L, UF := 31L]
    if(cenario == "uf_na") q[linha == 1L, UF := NA_integer_]
    if(cenario == "arquivo_vazio") q <- q[0]
    pasta <- file.path(test_dir, "guardas", modo, cenario,
                       if(cenario == "uf_desconhecida") "zz" else "sp")
    dir.create(pasta, recursive = TRUE)
    entrada <- file.path(pasta, nome_arquivo)
    arrow::write_parquet(q, entrada)
    caminhos <- if(cenario == "uf_repetida") c(original, entrada) else entrada
    out <- file.path(test_dir, "guardas", modo, paste0("relatorio_", cenario))
    erro <- if(modo == "25") try(validate_definitivos_1960_amostra_25(caminhos, def_path, out_dir = out), silent = TRUE) else
      try(validate_1960(as.list(caminhos), def_path, out_dir = out), silent = TRUE)
    stopifnot(inherits(erro, "try-error"), length(as.character(erro)) == 1L,
              grepl("UF|vazio", as.character(erro)),
              !file.exists(file.path(out, "validacao_definitivos.csv")))
  }
}

# Cobertura nacional completa com somente 28 registros artificiais. Este bloco
# nao le nem processa UFs reais: cada unidade tem um homem de 40 anos, peso 1.25.
ufs_teste <- c(UF_1960_AMOSTRA_25, UF_1960_AMOSTRA_127)
stopifnot(length(ufs_teste) == 28L, !anyDuplicated(ufs_teste), !anyDuplicated(names(ufs_teste)))
paths_brasil <- setNames(character(length(ufs_teste)), names(ufs_teste))
mini <- copy(sp[1])
mini[, `:=`(linha = 1L, V118 = 1L, V202 = 1L, V204 = 1L, V204B = 40L,
             V206 = 4L, V211 = 1L, censobr_weight = 1.25, censobr_weight_ibge = 2.25)]
for(unidade_teste in names(ufs_teste)){
  q <- copy(mini)
  q[, `:=`(UF = as.integer(ufs_teste[[unidade_teste]]),
            censobr_upa = paste0(unidade_teste, "-mini"),
            censobr_amostra = if(unidade_teste %in% names(UF_1960_AMOSTRA_25)) "25%" else "1,27%")]
  pasta <- file.path(test_dir, "brasil_completo", unidade_teste)
  dir.create(pasta, recursive = TRUE)
  paths_brasil[unidade_teste] <- file.path(pasta, "pessoas.parquet")
  arrow::write_parquet(q, paths_brasil[[unidade_teste]])
}
out <- file.path(test_dir, "relatorio_brasil_completo")
rb <- ler_cmp_1960(validate_1960(paths_brasil, def_path, out_dir = out), out, compilado = TRUE)
conferir_grade_cmp_1960(rb, grade_comp, "censobr_weight")
stopifnot(nrow(rb) == 1740L)
for(tab_teste in c(32L, 33L, 34L, 37L, 40L)){
  item_teste <- if(tab_teste == 32L) "presente" else if(tab_teste == 40L) "5 e mais" else "total"
  z <- celula_cmp_1960(rb, 999L, tab_teste, item_teste, "homens")
  stopifnot(z$valor == 35, z$valor_parcial == 35, z$n_amostra == 28L,
            z$n_pesos_ausentes == 0L, z$n_sem_classificacao == 0L,
            z$status_celula == "observada")
}
z <- celula_cmp_1960(rb, 999L, 32L, "presente", "mulheres")
stopifnot(z$valor == 0, z$n_amostra == 0L, z$status_celula == "sem_observacoes")
z <- rb[uf60 == 999L & tabela == 7L]
stopifnot(nrow(z) == 6L, all(z$status_celula == "nao_reconstruida"), all(is.na(z$valor)))

# O Brasil nao pode somar removendo NAs nem descartar pendencias de uma UF.
# Uma classificacao incerta com peso ausente tem seu contador proprio.
for(cenario in c("peso_na", "peso_inf", "situacao_ausente", "sexo_peso_ausente",
                 "peso_e_classificacao", "idade_danificada")){
  paths_cenario <- paths_brasil
  alteradas <- if(cenario == "peso_e_classificacao") c("sp", "ro") else "sp"
  for(unidade_teste in alteradas){
    q <- copy(mini)
    q[, `:=`(UF = as.integer(ufs_teste[[unidade_teste]]),
              censobr_upa = paste0(unidade_teste, "-mini"),
              censobr_amostra = if(unidade_teste %in% names(UF_1960_AMOSTRA_25)) "25%" else "1,27%")]
    if(cenario == "peso_na") q[, censobr_weight := NA_real_]
    if(cenario == "peso_inf") q[, censobr_weight := Inf]
    if(cenario == "situacao_ausente") q[, V118 := NA_integer_]
    if(cenario == "sexo_peso_ausente") q[, `:=`(V202 = NA_integer_, censobr_weight = NA_real_)]
    if(cenario == "peso_e_classificacao" && unidade_teste == "sp") q[, censobr_weight := NA_real_]
    if(cenario == "peso_e_classificacao" && unidade_teste == "ro") q[, V202 := NA_integer_]
    if(cenario == "idade_danificada") q[, V204B := NA_integer_]
    pasta <- file.path(test_dir, "brasil_mutacoes", cenario, unidade_teste)
    dir.create(pasta, recursive = TRUE)
    paths_cenario[unidade_teste] <- file.path(pasta, "pessoas.parquet")
    arrow::write_parquet(q, paths_cenario[[unidade_teste]])
  }
  out <- file.path(test_dir, "brasil_mutacoes", paste0("relatorio_", cenario))
  r <- ler_cmp_1960(validate_1960(as.list(paths_cenario), def_path, out_dir = out), out, compilado = TRUE)
  conferir_grade_cmp_1960(r, grade_comp, "censobr_weight")
  if(cenario %in% c("peso_na", "peso_inf")){
    z <- celula_cmp_1960(r, 999L, 32L, "presente", "homens")
    stopifnot(is.na(z$valor), is.na(z$dif), z$n_amostra == 28L,
              z$n_pesos_ausentes == 1L, z$n_sem_classificacao == 0L,
              z$status_celula == "peso_ausente")
  }
  if(cenario == "situacao_ausente"){
    z <- celula_cmp_1960(r, 999L, 34L, "urbana", "homens")
    stopifnot(is.na(z$valor), z$valor_parcial == 33.75, z$n_amostra == 27L,
              z$n_sem_classificacao == 1L, z$peso_sem_classificacao == 1.25,
              z$status_celula == "classificacao_incompleta")
    z <- celula_cmp_1960(r, 999L, 34L, "rural", "homens")
    stopifnot(is.na(z$valor), z$valor_parcial == 0, z$n_amostra == 0L,
              z$n_sem_classificacao == 1L, z$status_celula == "classificacao_incompleta")
    z <- celula_cmp_1960(r, 999L, 34L, "total", "homens")
    stopifnot(z$valor == 35, z$n_amostra == 28L, z$status_celula == "observada")
  }
  if(cenario == "sexo_peso_ausente"){
    z <- celula_cmp_1960(r, 999L, 32L, "presente", "homens")
    stopifnot(is.na(z$valor), z$valor_parcial == 33.75, z$n_amostra == 27L,
              z$n_pesos_ausentes == 0L, z$n_sem_classificacao == 1L,
              z$n_pesos_ausentes_sem_classificacao == 1L, is.na(z$peso_sem_classificacao),
              z$status_celula == "classificacao_incompleta")
  }
  if(cenario == "peso_e_classificacao"){
    z <- celula_cmp_1960(r, 999L, 32L, "presente", "homens")
    stopifnot(is.na(z$valor), z$n_amostra == 27L, z$n_pesos_ausentes == 1L,
              z$n_sem_classificacao == 1L, z$peso_sem_classificacao == 1.25,
              z$n_pesos_ausentes_sem_classificacao == 0L, z$status_celula == "peso_ausente")
  }
  if(cenario == "idade_danificada"){
    z <- celula_cmp_1960(r, 999L, 33L, "ignorada", "homens")
    stopifnot(z$valor == 0, z$n_amostra == 0L, z$n_sem_classificacao == 0L,
              z$status_celula == "sem_observacoes")
    z <- celula_cmp_1960(r, 999L, 33L, "40 a 49", "homens")
    stopifnot(is.na(z$valor), z$valor_parcial == 33.75, z$n_sem_classificacao == 1L,
              z$status_celula == "classificacao_incompleta")
  }
}

# Uma referencia duplicada e erro de entrada, nao duas parcelas para somar.
repetida <- def[nivel == "uf" & uf60 == 60L & tabela == 32L & item == "presente" & sexo == "homens"]
stopifnot(nrow(repetida) == 1L)
repetida[, valor := valor + 1]
duplicado_path <- file.path(test_dir, "referencia_duplicada.csv")
fwrite(rbind(def, repetida), duplicado_path)
for(modo in c("25", "comp")){
  out <- file.path(test_dir, paste0("duplicada_", modo))
  erro <- if(modo == "25") try(validate_definitivos_1960_amostra_25(path25, duplicado_path, out_dir = out), silent = TRUE) else
    try(validate_1960(path_sp, duplicado_path, out_dir = out), silent = TRUE)
  stopifnot(inherits(erro, "try-error"), length(as.character(erro)) == 1L,
            grepl("duplicad", as.character(erro), ignore.case = TRUE))
}

# T7 usa os pesos da unidade contada e moradores estritos 1:4. Individual,
# coletivo, improvisado e casa so com visitantes nao pertencem ao universo.
dt7 <- data.table(UF = 60L, censobr_idhousehold = 1:6,
  V101 = c(1L, 1L, 1L, 9L, 2L, 3L), V102 = c(4L, 6L, 4L, NA_integer_, 5L, 4L),
  V118 = c(1L, 5L, 1L, 1L, 5L, 1L), censobr_weight = seq(10, 60, 10),
  censobr_weight_ibge = seq(11, 61, 10))
pt7 <- rbindlist(lapply(1:7, function(i) copy(mini)[, `:=`(
  UF = 60L, linha = i, censobr_idhousehold = c(1L, 1L, 2L, 3L, 4L, 5L, 6L)[i],
  V202 = c(1L, 4L, 1L, 5L, 1L, 2L, 1L)[i],
  censobr_weight = c(2, 3, 5, 7, 11, 13, 17)[i],
  censobr_weight_ibge = c(2.5, 3.5, 5.5, 7.5, 11.5, 13.5, 17.5)[i])]))
for(modo in c("25", "comp")) for(cenario in c("completo", "sem_lista", "pessoa_orfa",
  "presenca_incerta", "permanencia_incerta", "peso_dom", "peso_pes", "dom_duplicado")){
  q <- copy(pt7); h <- copy(dt7)
  if(cenario == "sem_lista") h <- rbind(h, copy(h[1L])[, `:=`(censobr_idhousehold = 7L, censobr_weight = 70)])
  if(cenario == "pessoa_orfa") q <- rbind(q, copy(q[1L])[, `:=`(linha = 8L, censobr_idhousehold = 999L, censobr_weight = 19)])
  if(cenario == "presenca_incerta") q[censobr_idhousehold == 5L, V202 := NA_integer_]
  if(cenario == "permanencia_incerta") h[censobr_idhousehold == 5L, V102 := NA_integer_]
  if(cenario == "peso_dom") h[censobr_idhousehold == 1L, censobr_weight := NA_real_]
  if(cenario == "peso_pes") q[linha == 1L, censobr_weight := Inf]
  if(cenario == "dom_duplicado") h <- rbind(h, h[1L])
  pasta <- file.path(test_dir, "t7", modo, cenario, "sp")
  dir.create(pasta, recursive = TRUE)
  entradas <- file.path(pasta, if(modo == "25") c("pessoas_pesos.parquet", "domicilios_pesos.parquet") else
    c("pessoas.parquet", "domicilios.parquet"))
  arrow::write_parquet(q, entradas[1]); arrow::write_parquet(h, entradas[2])
  out <- file.path(test_dir, "t7", modo, paste0("relatorio_", cenario))
  caminho <- if(modo == "25") try(validate_definitivos_1960_amostra_25(entradas, def_path, out_dir = out), silent = TRUE) else
    try(validate_1960(entradas, def_path, out_dir = out), silent = TRUE)
  if(cenario == "dom_duplicado"){
    stopifnot(inherits(caminho, "try-error"), grepl("domicil|duplicad", as.character(caminho)))
    next
  }
  r <- ler_cmp_1960(caminho, out, compilado = modo == "comp")
  zd <- celula_cmp_1960(r, 60L, 7L, "total", "", medida_teste = "domicilios")
  zp <- celula_cmp_1960(r, 60L, 7L, "total", "", medida_teste = "pessoas")
  stopifnot(zd$referencia_estimada, zp$referencia_estimada)
  if(cenario == "completo"){
    stopifnot(zd$valor == 60, zd$n_amostra == 2L, zd$n_sem_classificacao == 0L,
              zp$valor == 18, zp$n_amostra == 3L, zp$n_sem_classificacao == 0L)
    stopifnot(celula_cmp_1960(r, 60L, 7L, "urbana", "", medida_teste = "pessoas")$valor == 5,
              celula_cmp_1960(r, 60L, 7L, "rural", "", medida_teste = "domicilios")$valor == 50)
    if(modo == "25") stopifnot(
      celula_cmp_1960(r, 60L, 7L, "total", "", "censobr_weight_ibge", "domicilios")$valor == 62,
      celula_cmp_1960(r, 60L, 7L, "total", "", "censobr_weight_ibge", "pessoas")$valor == 19.5)
  }
  if(cenario == "sem_lista") stopifnot(zd$n_sem_classificacao == 1L, zd$valor_parcial == 60,
    zp$n_sem_classificacao == 0L, zp$n_domicilios_sem_lista == 1L, zp$valor_parcial == 18,
    zd$status_celula == "classificacao_incompleta", zp$status_celula == "classificacao_incompleta",
    is.na(zp$valor), is.na(zp$dif))
  if(cenario == "pessoa_orfa") stopifnot(zp$n_sem_classificacao == 1L, zp$valor_parcial == 18,
    zd$n_sem_classificacao == 0L, zd$n_pessoas_sem_domicilio == 1L, zd$valor_parcial == 60,
    zd$status_celula == "classificacao_incompleta", zp$status_celula == "classificacao_incompleta")
  if(cenario %in% c("presenca_incerta", "permanencia_incerta")) stopifnot(
    zd$n_sem_classificacao == 1L, zd$valor_parcial == 10, zp$n_sem_classificacao == 1L,
    zp$valor_parcial == 5, zd$status_celula == "classificacao_incompleta",
    zp$status_celula == "classificacao_incompleta")
  if(cenario == "peso_dom") stopifnot(zd$n_pesos_ausentes == 1L, zd$status_celula == "peso_ausente",
    is.na(zd$valor), zp$valor == 18, zp$status_celula == "observada")
  if(cenario == "peso_pes") stopifnot(zp$n_pesos_ausentes == 1L, zp$status_celula == "peso_ausente",
    is.na(zp$valor), zd$valor == 60, zd$status_celula == "observada")
}

# Chaves domiciliares iguais em UFs distintas nao podem se misturar. Cada par
# abaixo tem uma casa/morador de peso 1.25; basta faltar um par para T7-Brasil parar.
pares_brasil <- character()
for(unidade_teste in names(ufs_teste)){
  q <- copy(mini)[, `:=`(UF = as.integer(ufs_teste[[unidade_teste]]), censobr_idhousehold = 1L)]
  h <- copy(dt7[1L])[, `:=`(UF = as.integer(ufs_teste[[unidade_teste]]), censobr_weight = 1.25)]
  pasta <- file.path(test_dir, "t7_brasil", unidade_teste)
  dir.create(pasta, recursive = TRUE)
  entradas <- file.path(pasta, c("pessoas.parquet", "domicilios.parquet"))
  arrow::write_parquet(q, entradas[1]); arrow::write_parquet(h, entradas[2])
  pares_brasil <- c(pares_brasil, entradas)
}
for(completo in c(TRUE, FALSE)){
  entradas <- if(completo) pares_brasil else pares_brasil[-2L]
  out <- file.path(test_dir, paste0("t7_brasil_", completo))
  r <- ler_cmp_1960(validate_1960(entradas, def_path, out_dir = out), out, compilado = TRUE)
  for(medida_teste in c("domicilios", "pessoas")){
    z <- celula_cmp_1960(r, 999L, 7L, "total", "", medida_teste = medida_teste)
    if(completo) stopifnot(z$n_amostra == 28L, z$valor == 35, z$status_celula == "observada") else
      stopifnot(z$status_celula == "nao_reconstruida", is.na(z$valor))
  }
}
message("Testes sinteticos de validacao 25%/compilado passaram. Artefatos isolados: ", test_dir)
