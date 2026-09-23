# Limites de classificacao a pesos fixos: nao sao IC nem variancias.
# Executar pelo runner isolado; nao le nem grava microdados reais.
.libPaths(c("renv/library/windows/R-4.5/x86_64-w64-mingw32", .libPaths()))
Sys.setlocale("LC_CTYPE", "Portuguese_Brazil.utf8")
library(data.table)
setDTthreads(1L)
source("R/microdata_1960_validacao.R", encoding = "UTF-8")

grade <- CJ(uf60 = 60L, tabela = 7L, item = c("total", "urbana", "rural"),
            sexo = "", medida = c("domicilios", "pessoas"))
grade[, publicado := 100]
grade <- rbind(grade, copy(grade[1L])[, uf60 := 31L],
  data.table(uf60 = 60L, tabela = 32L, item = "presente", sexo = "homens",
             medida = "", publicado = 100))
chaves <- c("uf60", "tabela", "item", "sexo", "medida")
d <- data.table(UF = 60L, censobr_idhousehold = 1:3, V101 = 1L,
  V102 = c(4L, 7L, 6L), V118 = 1L, censobr_weight = c(10, 20, 30))
p <- data.table(UF = 60L, censobr_idhousehold = c(1L, 1L, 2L, 3L), V202 = 1L,
  V118 = 1L, V204 = 1L, V204B = 30L, V206 = 4L, V211 = 1L,
  censobr_weight = c(2, 3, 7, 11))

cenarios <- c("tipo_ignorado", "completo", "sem_lista", "sem_cartao", "peso_dom_na",
  "peso_dom_inf", "peso_dom_negativo", "peso_pes_negativo", "peso_incerto_na",
  "peso_incerto_inf", "peso_incerto_negativo", "peso_fora_universo", "soma_infinita")
for(cenario in cenarios){
  h <- copy(d); q <- copy(p)
  if(cenario == "completo") h[censobr_idhousehold == 2L, V102 := 4L]
  if(cenario == "sem_lista") h <- rbind(h, copy(h[1L])[, censobr_idhousehold := 4L])
  if(cenario == "sem_cartao") q <- rbind(q, copy(q[1L])[, censobr_idhousehold := 4L])
  if(cenario == "peso_dom_na") h[censobr_idhousehold == 1L, censobr_weight := NA_real_]
  if(cenario == "peso_dom_inf") h[censobr_idhousehold == 1L, censobr_weight := Inf]
  if(cenario == "peso_dom_negativo") h[censobr_idhousehold == 1L, censobr_weight := -1]
  if(cenario == "peso_pes_negativo") q[1L, censobr_weight := -1]
  if(cenario == "peso_incerto_na") h[censobr_idhousehold == 2L, censobr_weight := NA_real_]
  if(cenario == "peso_incerto_inf") h[censobr_idhousehold == 2L, censobr_weight := Inf]
  if(cenario == "peso_incerto_negativo") h[censobr_idhousehold == 2L, censobr_weight := -1]
  if(cenario == "peso_fora_universo"){
    h[censobr_idhousehold == 3L, censobr_weight := -100]
    q[censobr_idhousehold == 3L, censobr_weight := Inf]
  }
  if(cenario == "soma_infinita") h[censobr_idhousehold %in% 1:2, censobr_weight := 1e308]
  medido <- rbindlist(list(
    tabular_domicilios_validacao_1960(q, h, grade[uf60 == 60L & tabela == 7L], "censobr_weight"),
    tabular_pessoas_validacao_1960(q, grade[tabela == 32L], "censobr_weight")))
  comp <- completar_validacao_pessoas_1960(grade, medido, chaves)
  stopifnot(all(c("valor_minimo", "valor_maximo") %in% names(comp)))
  zd <- comp[uf60 == 60L & tabela == 7L & item == "total" & medida == "domicilios"]
  zp <- comp[uf60 == 60L & tabela == 7L & item == "total" & medida == "pessoas"]
  stopifnot(nrow(zd) == 1L, nrow(zp) == 1L,
    all(is.na(comp[tabela != 7L | uf60 == 31L]$valor_minimo)),
    all(is.na(comp[tabela != 7L | uf60 == 31L]$valor_maximo)))
  if(cenario %in% c("tipo_ignorado", "peso_fora_universo")){
    stopifnot(zd$valor_minimo == 10, zd$valor_maximo == 30,
      zp$valor_minimo == 5, zp$valor_maximo == 12,
      zd$n_sem_classificacao == 1L, zp$n_sem_classificacao == 1L,
      is.na(zd$valor), is.na(zp$valor), is.na(zd$dif), is.na(zp$dif),
      zd$status_celula == "classificacao_incompleta", zp$status_celula == "classificacao_incompleta")
  }
  if(cenario == "tipo_ignorado"){
    vazias <- comp[uf60 == 60L & tabela == 7L & item == "rural"]
    stopifnot(nrow(vazias) == 2L, all(vazias$valor_minimo == 0), all(vazias$valor_maximo == 0),
      all(vazias$status_celula == "sem_observacoes"))
  }
  if(cenario == "completo") stopifnot(zd$valor_minimo == 30, zd$valor_maximo == 30,
    zp$valor_minimo == 12, zp$valor_maximo == 12,
    zd$status_celula == "observada", zp$status_celula == "observada")
  if(cenario %in% c("sem_lista", "sem_cartao")) stopifnot(
    is.na(zd$valor_minimo), is.na(zd$valor_maximo), is.na(zp$valor_minimo), is.na(zp$valor_maximo),
    zd$status_celula == "classificacao_incompleta", zp$status_celula == "classificacao_incompleta")
  if(cenario %in% c("peso_dom_na", "peso_dom_inf", "peso_dom_negativo")) stopifnot(
    is.na(zd$valor_minimo), is.na(zd$valor_maximo), zd$n_pesos_ausentes == 1L,
    zd$status_celula == "peso_ausente", zp$valor_minimo == 5, zp$valor_maximo == 12)
  if(cenario == "peso_pes_negativo") stopifnot(is.na(zp$valor_minimo), is.na(zp$valor_maximo),
    zp$n_pesos_ausentes == 1L, zp$status_celula == "peso_ausente",
    zd$valor_minimo == 10, zd$valor_maximo == 30)
  if(cenario %in% c("peso_incerto_na", "peso_incerto_inf", "peso_incerto_negativo")) stopifnot(
    is.na(zd$valor_minimo), is.na(zd$valor_maximo), zd$n_pesos_ausentes_sem_classificacao == 1L,
    zd$status_celula == "classificacao_incompleta", zp$valor_minimo == 5, zp$valor_maximo == 12)
  if(cenario == "soma_infinita") stopifnot(is.na(zd$valor_minimo), is.na(zd$valor_maximo))
}
message("Limites T7: 13 cenarios sinteticos passaram; sem IC ou variancias.")
