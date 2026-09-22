# Leitura exclusiva da fixture versionada; nao aplica decisoes em producao.
carregar_fixture_registros_1960 <- function(path =
  "references/fechamento_registros_1960_evidencias/fixtures_decisoes.json"){
  fixture <- jsonlite::fromJSON(path, simplifyVector = FALSE)
  stopifnot(identical(fixture$versao, 1L))
  fixture
}

tabela_fixture_registros_1960 <- function(fixture, nome){
  fonte <- fixture[[nome]]
  colunas <- unlist(fonte$colunas, use.names = FALSE)
  stopifnot(length(colunas) > 0L, !anyDuplicated(colunas),
            "justificativa" %in% colunas, length(fonte$linhas) > 0L)
  linhas <- lapply(fonte$linhas, function(linha){
    stopifnot(length(linha) == length(colunas), all(vapply(linha, is.character, logical(1))))
    unlist(linha, use.names = FALSE)
  })
  tabela <- data.table::as.data.table(do.call(rbind, linhas))
  data.table::setnames(tabela, colunas)
  justificativas <- unlist(fonte$justificativas, use.names = FALSE)
  indices <- as.integer(tabela$justificativa) + 1L
  stopifnot(!anyNA(indices), all(indices >= 1L & indices <= length(justificativas)))
  tabela[, justificativa := justificativas[indices]]
  tabela[]
}
