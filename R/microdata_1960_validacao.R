# Calculos compartilhados pelos relatorios de 25% e da compilacao.
# As classificacoes abaixo existem so na conferencia; nao alteram microdados.
tabular_pessoas_validacao_1960 <- function(p, grade, peso){
  idade <- data.table::fifelse(p$V204 %in% 1 & p$V204B %in% 0:99, p$V204B,
    data.table::fifelse(p$V204 %in% 0 & p$V204B %in% 0:99, 0L,
      data.table::fifelse(p$V204 %in% 5, 100L, NA_integer_)))
  faixa <- as.character(cut(idade, c(-1, 4, 9, 14, 19, 24, 29, 39, 49, 59, 69, Inf),
    labels = c("0 a 4", "5 a 9", "10 a 14", "15 a 19", "20 a 24", "25 a 29",
               "30 a 39", "40 a 49", "50 a 59", "60 a 69", "70 e mais")))
  faixa[p$V204 %in% 9] <- "ignorada"
  cinco_mais <- idade >= 5
  cinco_mais[p$V204 %in% 9] <- TRUE
  x <- data.table::data.table(
    sexo = data.table::fifelse(p$V202 %in% c(1, 3, 5), "homens",
      data.table::fifelse(p$V202 %in% c(2, 4, 6), "mulheres", NA_character_)),
    presente = data.table::fifelse(p$V202 %in% 1:6, p$V202 %in% c(1, 2, 5, 6), NA),
    residente = data.table::fifelse(p$V202 %in% 1:6, p$V202 %in% 1:4, NA),
    faixa = faixa,
    idade_ignorada = data.table::fifelse(p$V204 %in% c(0, 1, 5, 9), p$V204 %in% 9, NA),
    situacao = data.table::fifelse(p$V118 %in% c(1, 3), "urbana",
      data.table::fifelse(p$V118 %in% 5, "rural", NA_character_)),
    cor = c("4" = "brancos", "5" = "pretos", "6" = "amarelos", "7" = "pardos",
            "8" = "pardos", "9" = "sem declaracao")[as.character(p$V206)],
    alfabetizacao = c("0" = "sabem", "1" = "sabem", "2" = "nao sabem",
                      "3" = "nao sabem", "4" = "sem declaracao")[as.character(p$V211)],
    cinco_mais = cinco_mais, w = as.numeric(p[[peso]]))
  # Reduzir por classificacao evita repetir a varredura de milhoes de pessoas.
  z <- x[, .(n = .N, soma = sum(w[is.finite(w)]),
             faltam = sum(!is.finite(w))),
    by = .(sexo, presente, residente, faixa, idade_ignorada, situacao, cor, alfabetizacao, cinco_mais)]
  rm(x); gc(verbose = FALSE)
  out <- data.table::copy(grade)
  out[, `:=`(valor_parcial = NA_real_, n_amostra = 0L, n_pesos_ausentes = 0L,
             n_sem_classificacao = 0L, peso_sem_classificacao = 0,
             n_pesos_ausentes_sem_classificacao = 0L,
             n_domicilios_sem_lista = 0L, n_pessoas_sem_domicilio = 0L)]
  for(i in seq_len(nrow(out))){
    tab <- out$tabela[i]; item <- out$item[i]
    pertence <- if(tab == 32L && item == "residente") z$residente else z$presente
    pertence <- pertence & z$sexo == out$sexo[i]
    if(tab == 33L && item != "total"){
      pertence <- pertence & (if(item == "ignorada") z$idade_ignorada else z$faixa == item)
    }
    if(tab == 34L && item != "total") pertence <- pertence & z$situacao == item
    if(tab == 37L && item != "total") pertence <- pertence & z$cor == item
    if(tab == 40L){
      pertence <- pertence & z$cinco_mais
      if(item != "5 e mais") pertence <- pertence & z$alfabetizacao == item
    }
    conhecidos <- which(pertence); pendentes <- which(is.na(pertence))
    faltam <- sum(z$faltam[conhecidos]); faltam_pendentes <- sum(z$faltam[pendentes])
    out[i, `:=`(valor_parcial = if(faltam > 0L) NA_real_ else sum(z$soma[conhecidos]),
                n_amostra = sum(z$n[conhecidos]), n_pesos_ausentes = faltam,
                n_sem_classificacao = sum(z$n[pendentes]),
                peso_sem_classificacao = if(faltam_pendentes > 0L) NA_real_ else sum(z$soma[pendentes]),
                n_pesos_ausentes_sem_classificacao = faltam_pendentes)]
  }
  rm(z); gc(verbose = FALSE)
  out
}


# Serie Nacional, vol. I, impresso 132 (PDF 169): particulares permanentes.
# Recontar moradores pelos codigos 1:4; contagens gravadas podem incluir NA.
tabular_domicilios_validacao_1960 <- function(p, d, grade, peso){
  if(anyNA(d$censobr_idhousehold) || anyDuplicated(d[, .(UF, censobr_idhousehold)]))
    stop("chave domiciliar ausente ou duplicada na validacao")
  h <- d[, .(UF, censobr_idhousehold, V101, V102, V118, w = as.numeric(get(peso)))]
  lista <- p[!is.na(censobr_idhousehold), .(n_lista = .N,
    residentes = sum(V202 %in% 1:4), incertos = sum(!V202 %in% 1:6)),
    by = .(UF, censobr_idhousehold)]
  h[, `:=`(n_lista = 0L, residentes = 0L, incertos = 0L)]
  h[lista, `:=`(n_lista = i.n_lista, residentes = i.residentes, incertos = i.incertos),
    on = .(UF, censobr_idhousehold)]
  h[, particular := data.table::fifelse(V101 %in% c(1:5, 9), V101 %in% c(1, 2, 4, 5), NA)]
  h[, permanente := data.table::fifelse(V102 %in% 4:6, V102 %in% 4:5, NA)]
  h[, ocupado := data.table::fifelse(residentes > 0L, TRUE,
    data.table::fifelse(n_lista > 0L & incertos == 0L, FALSE, NA))]
  h[, situacao := data.table::fifelse(V118 %in% c(1, 3), "urbana",
    data.table::fifelse(V118 %in% 5, "rural", NA_character_))]
  x <- p[, .(UF, censobr_idhousehold,
    residente = data.table::fifelse(V202 %in% 1:6, V202 %in% 1:4, NA),
    w = as.numeric(get(peso)))]
  x <- merge(x, h[, .(UF, censobr_idhousehold, particular, permanente, situacao,
                       domicilio_encontrado = TRUE)], by = c("UF", "censobr_idhousehold"),
             all.x = TRUE, sort = FALSE)
  out <- data.table::copy(grade)
  out[, `:=`(valor_parcial = NA_real_, n_amostra = 0L, n_pesos_ausentes = 0L,
    n_sem_classificacao = 0L, peso_sem_classificacao = 0,
    n_pesos_ausentes_sem_classificacao = 0L,
    n_domicilios_sem_lista = 0L, n_pessoas_sem_domicilio = 0L)]
  for(i in seq_len(nrow(out))){
    item <- out$item[i]
    universo_dom <- h$particular & h$permanente
    universo_pes <- x$residente & x$particular & x$permanente
    if(item != "total"){
      universo_dom <- universo_dom & h$situacao == item
      universo_pes <- universo_pes & x$situacao == item
    }
    # Nao existe peso/n de moradores para uma lista ausente. Manter a falha de
    # cobertura separada de pessoas classificadas, sem fabricar uma pessoa.
    sem_lista <- sum(h$n_lista == 0L & (universo_dom %in% TRUE | is.na(universo_dom)))
    sem_dom <- sum(is.na(x$domicilio_encontrado) & (x$residente %in% TRUE | is.na(x$residente)))
    if(out$medida[i] == "domicilios"){
      pertence <- universo_dom & h$ocupado; w <- h$w
    } else {
      pertence <- universo_pes; w <- x$w
    }
    conhecidos <- which(pertence); pendentes <- which(is.na(pertence))
    faltam <- sum(!is.finite(w[conhecidos]) | w[conhecidos] < 0)
    faltam_pendentes <- sum(!is.finite(w[pendentes]) | w[pendentes] < 0)
    out[i, `:=`(valor_parcial = if(faltam > 0L) NA_real_ else sum(w[conhecidos]),
      n_amostra = length(conhecidos), n_pesos_ausentes = faltam,
      n_sem_classificacao = length(pendentes),
      peso_sem_classificacao = if(faltam_pendentes > 0L) NA_real_ else sum(w[pendentes]),
      n_pesos_ausentes_sem_classificacao = faltam_pendentes,
      n_domicilios_sem_lista = sem_lista, n_pessoas_sem_domicilio = sem_dom)]
  }
  rm(h, x, lista); gc(verbose = FALSE)
  out
}


completar_validacao_pessoas_1960 <- function(grade, medido, chaves){
  if(anyDuplicated(grade[, ..chaves])) stop("chave duplicada no gabarito da validacao")
  if(nrow(medido) && anyDuplicated(medido[, ..chaves]))
    stop("chave duplicada na agregacao da validacao")
  comp <- data.table::copy(grade)
  comp[, `:=`(valor_parcial = NA_real_, n_amostra = NA_integer_,
    n_pesos_ausentes = NA_integer_, n_sem_classificacao = NA_integer_,
    peso_sem_classificacao = NA_real_, n_pesos_ausentes_sem_classificacao = NA_integer_,
    n_domicilios_sem_lista = NA_integer_, n_pessoas_sem_domicilio = NA_integer_)]
  metricas <- c("valor_parcial", "n_amostra", "n_pesos_ausentes", "n_sem_classificacao",
               "peso_sem_classificacao", "n_pesos_ausentes_sem_classificacao",
               "n_domicilios_sem_lista", "n_pessoas_sem_domicilio")
  if(nrow(medido)) comp[medido, (metricas) := mget(paste0("i.", metricas)), on = chaves]
  comp[, reconstruivel := !is.na(n_amostra)]
  comp[, status_celula := "nao_reconstruida"]
  comp[reconstruivel == TRUE, status_celula := "observada"]
  comp[reconstruivel & n_amostra == 0L, status_celula := "sem_observacoes"]
  comp[reconstruivel & (n_sem_classificacao > 0L | n_domicilios_sem_lista > 0L |
                        n_pessoas_sem_domicilio > 0L), status_celula := "classificacao_incompleta"]
  comp[reconstruivel & n_pesos_ausentes > 0L, status_celula := "peso_ausente"]
  comp[, `:=`(valor = NA_real_, dif = NA_real_, dif_pct = NA_real_)]
  comp[status_celula %in% c("observada", "sem_observacoes"), valor := valor_parcial]
  comp[, dif := valor - publicado]
  comp[is.finite(publicado) & publicado != 0, dif_pct := 100 * dif / publicado]
  # Limites de classificacao a pesos fixos, nao intervalos de confianca.
  # Cobertura incompleta ou peso invalido nao permite fechar os dois extremos.
  comp[, `:=`(valor_minimo = NA_real_, valor_maximo = NA_real_)]
  comp[tabela == 7L & reconstruivel & n_pesos_ausentes == 0L &
    n_pesos_ausentes_sem_classificacao == 0L & n_domicilios_sem_lista == 0L &
    n_pessoas_sem_domicilio == 0L & is.finite(valor_parcial) & valor_parcial >= 0 &
    is.finite(peso_sem_classificacao) & peso_sem_classificacao >= 0 &
    is.finite(valor_parcial + peso_sem_classificacao),
    `:=`(valor_minimo = valor_parcial, valor_maximo = valor_parcial + peso_sem_classificacao)]
  comp[, motivo := data.table::fcase(
    !reconstruivel & uf60 == 999L, "faltam UFs para calcular o Brasil completo",
    !reconstruivel & tabela == 7L, "par de arquivos de domicilios e pessoas da UF nao fornecido",
    !reconstruivel, "arquivo de pessoas da UF nao fornecido",
    status_celula == "classificacao_incompleta" & (n_domicilios_sem_lista > 0L | n_pessoas_sem_domicilio > 0L),
      "vinculos/listas incompletos; contadores de domicilios e pessoas separados, sem imputar moradores",
    status_celula == "classificacao_incompleta", "ha registros que podem pertencer a esta comparacao, mas faltam codigos validos",
    status_celula == "peso_ausente" & tabela == 7L, "ha pesos ausentes, nao finitos ou negativos",
    status_celula == "peso_ausente", "ha pesos ausentes ou nao finitos",
    status_celula == "sem_observacoes", "nenhum registro observado nesta categoria; nao significa populacao zero",
    default = "comparacao calculada")]
  comp[, unidade_sem_classificacao := data.table::fifelse(tabela == 7L, medida, "pessoas")]
  comp[, referencia_estimada := tabela == 7L | uf60 == 999L |
         !uf60 %in% c(0, 1, 2, 3, 4, 6, 10, 12, 51, 54, 74)]
  # T7 vem do CD2 em todas as UFs (Serie Nacional, impresso X/PDF 9), inclusive
  # onde a apuracao pessoal foi pelo universo; o metadado generico por UF nao basta.
  comp[, politica_idade := data.table::fifelse(tabela == 40L,
    "5 e mais inclui idade declarada ignorada; idade danificada permanece pendente",
    data.table::fifelse(tabela == 33L, "idade declarada ignorada separada de idade danificada", "sem limite etario"))]
  comp
}
