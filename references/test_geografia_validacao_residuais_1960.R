# Contraprovas geograficas dos resultados definitivos de 1960; runner isolado.
.libPaths(c("renv/library/windows/R-4.5/x86_64-w64-mingw32", .libPaths()))
Sys.setlocale("LC_CTYPE", "Portuguese_Brazil.utf8")
library(data.table)
setDTthreads(1L)
source("R/microdata_1960_amostra_127.R", encoding = "UTF-8")

p <- data.table(linha = 1:2, UF = 60L, censobr_idhousehold = 1:2,
  censobr_idfamily = 1:2, V203 = 7L, V118 = 1L, V202 = 1L,
  V204 = 1L, V204B = c(30L, 10L), V206 = 4L, V211 = 1L,
  V215 = 0L, V219 = 5L, V220 = 3L, V223 = 2L, V223B = 111L,
  censobr_weight = c(10, 20), censobr_weight_1965 = c(20, 40))
d <- data.table(UF = 60L, censobr_idhousehold = 1:2,
  V118 = 1L, V101 = 1L, V102 = 4L, V103 = 7L, V104 = 8L, V105 = 9L,
  V106 = 4L, V107 = 9L, V108 = 5L, V109 = 7L, V110 = 9L,
  censobr_weight = c(10, 20), censobr_weight_1965 = c(20, 40))
base <- function() list(pessoas = copy(p), domicilios = copy(d),
  ufs_fornecidas = as.integer(names(REGIAO_1960)))
def_path <- "references/censo_1960_resultados_definitivos_serie_nacional.csv"
dir.create("tmp", showWarnings = FALSE)
test_dir <- tempfile("geografia_def_", tmpdir = "tmp")
dir.create(test_dir)
falhas <- character()
conferir <- function(nome, condicao){
  passou <- isTRUE(condicao)
  message("Contraprova geografia definitiva ", nome, ": ", if(passou) "PASSOU" else "FALHOU")
  if(!passou) falhas <<- c(falhas, nome)
}
validar <- function(t, gabarito = def_path){
  pa <- copy(t$pessoas); da <- copy(t$domicilios)
  z <- validate_definitivos_1960_amostra_127(t, gabarito, out_dir = test_dir)
  stopifnot(identical(t$pessoas, pa), identical(t$domicilios, da))
  z
}
parcial_correto <- function(s, fator){
  nrow(s) > 0L && all(s$n_sem_classificacao == 1L) &&
    all(s$status_celula == "classificacao_incompleta") && all(is.na(s$nosso)) &&
    all(is.na(s$dif_abs)) && all(is.na(s$dif_pct)) &&
    all(s[uf60 == 60L, valor_parcial] == 20 * fator) &&
    all(s[uf60 != 60L, valor_parcial] == 0)
}
completo_correto <- function(s, fator){
  nrow(s) > 0L && all(s$n_sem_classificacao == 0L) &&
    all(s[uf60 == 60L, nosso] == 20 * fator) &&
    all(s[uf60 != 60L, nosso] == 0) &&
    all(s[uf60 != 60L, status_celula] == "sem_observacoes")
}

for(cenario in c("pessoa_UF_ausente", "pessoa_UF_invalida", "domicilio_UF_ausente", "domicilio_UF_invalida")){
  t <- base(); uf_ruim <- if(grepl("ausente$", cenario)) NA_integer_ else 999L
  if(grepl("^pessoa", cenario)) t$pessoas[linha == 1L, UF := uf_ruim] else
    t$domicilios[censobr_idhousehold == 1L, UF := uf_ruim]
  z <- validar(t)
  for(peso_atual in c("censobr_weight", "censobr_weight_1965")){
    fator <- if(peso_atual == "censobr_weight") 1 else 2
    if(grepl("^pessoa", cenario)){
      s <- z[peso == peso_atual & sexo %in% c("total", "homens") &
        ((tabela == 32L & item %in% c("presente", "residente")) |
         (tabela %in% c(33L, 34L, 37L) & item == "total") |
         (tabela == 40L & item %in% c("5 e mais", "sabem")) |
         (tabela == 34L & item == "urbana") |
         (tabela == 37L & item == "brancos"))]
    } else {
      s <- z[peso == peso_atual & tabela == 7L & item %in% c("total", "urbana") &
        medida %in% c("domicilios", "pessoas")]
    }
    conferir(paste(cenario, peso_atual), parcial_correto(s, fator))
    if(grepl("^pessoa", cenario)){
      # O sexo masculino preservado nao pode criar pendencias femininas.
      mulheres <- z[peso == peso_atual & tabela == 32L & sexo == "mulheres"]
      conferir(paste(cenario, "mulheres_sem_dano", peso_atual), nrow(mulheres) > 0L &&
        all(mulheres$n_sem_classificacao == 0L) && all(mulheres$nosso == 0))
    }
  }
}

# UF desconhecida nao muda presenca, residencia, idade nem tipo de domicilio.
for(cenario in c("menor5", "ausente", "visitante", "coletivo", "improvisado", "so_visitante")){
  t <- base()
  if(cenario %in% c("menor5", "ausente", "visitante")) t$pessoas[linha == 1L, UF := NA_integer_] else
    t$domicilios[censobr_idhousehold == 1L, UF := NA_integer_]
  if(cenario == "menor5") t$pessoas[linha == 1L, V204B := 4L]
  if(cenario == "ausente") t$pessoas[linha == 1L, V202 := 3L]
  if(cenario == "visitante") t$pessoas[linha == 1L, V202 := 5L]
  if(cenario == "coletivo") t$domicilios[censobr_idhousehold == 1L, V101 := 3L]
  if(cenario == "improvisado") t$domicilios[censobr_idhousehold == 1L, V102 := 6L]
  if(cenario == "so_visitante") t$pessoas[linha == 1L, V202 := 5L]
  z <- validar(t)
  for(peso_atual in c("censobr_weight", "censobr_weight_1965")){
    fator <- if(peso_atual == "censobr_weight") 1 else 2
    if(cenario == "menor5") s <- z[peso == peso_atual & tabela == 40L & item == "5 e mais" & sexo == "total"]
    if(cenario == "ausente") s <- z[peso == peso_atual & tabela == 32L & item == "presente" & sexo == "total"]
    if(cenario == "visitante") s <- z[peso == peso_atual & tabela == 32L & item == "residente" & sexo == "total"]
    if(cenario %in% c("coletivo", "improvisado", "so_visitante"))
      s <- z[peso == peso_atual & tabela == 7L & item == "total" & medida %in% c("domicilios", "pessoas")]
    conferir(paste(cenario, "fora_do_universo", peso_atual), completo_correto(s, fator))
  }
}

# UF valida, mas fora desta grade deliberadamente parcial, nao e UF perdida.
gab_reduzido <- file.path(test_dir, "gabarito_apenas_SP.csv")
fwrite(fread(def_path)[nivel == "uf" & uf60 == 60L], gab_reduzido)
t <- base(); t$pessoas[linha == 1L, UF := 0L]; t$domicilios[censobr_idhousehold == 1L, UF := 0L]
z <- validar(t, gab_reduzido)
for(peso_atual in c("censobr_weight", "censobr_weight_1965")){
  fator <- if(peso_atual == "censobr_weight") 1 else 2
  s <- z[peso == peso_atual & ((tabela == 32L & item == "presente" & sexo == "total") |
    (tabela == 7L & item == "total" & medida == "domicilios"))]
  conferir(paste("UF_valida_fora_da_grade", peso_atual), completo_correto(s, fator))
}
if(length(falhas)) stop("Contraprovas geograficas definitivas falharam: ", paste(falhas, collapse = "; "))
message("Geografia dos resultados definitivos conferida: ", test_dir)
