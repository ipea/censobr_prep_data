# Somente parse e inspecao: nao avaliar _targets.R nem carregar targets.
Sys.setlocale("LC_CTYPE", "Portuguese_Brazil.utf8")
expressoes <- parse("_targets.R", encoding = "UTF-8")
alvos <- list()
ler_chamadas <- function(x){
  if(is.call(x) && identical(x[[1L]], as.name("tar_target"))){
    partes <- as.list(x)
    alvos[[as.character(partes$name)]] <<- partes$command
  } else if(is.call(x) || is.expression(x) || is.pairlist(x)){
    for(i in seq_along(x)) ler_chamadas(x[[i]])
  }
}
ler_chamadas(expressoes)
novos <- c("coincidencias_familias_1960_amostra_127", "fontes_coincidencias_1960_amostra_127",
  "distrito_pe_1960_amostra_127", "fontes_distrito_pe_1960_amostra_127")
stopifnot(all(novos %in% names(alvos)),
  identical(alvos$coincidencias_familias_1960_amostra_127,
    "read_guides/1960_amostra_127_familias_coincidentes.json"),
  identical(alvos$distrito_pe_1960_amostra_127,
    "references/resolucao_residuais_1960_evidencias/distrito_pe_operacional.json"))
dependencias_familias <- all.names(alvos$familias_1960_amostra_127)
stopifnot(all(novos %in% dependencias_familias),
  "decisoes_vinculos_1960_amostra_127" %in% dependencias_familias,
  "tabelas_recuperadas_1960_amostra_127" %in% dependencias_familias,
  "fontes_recuperacao_1960_amostra_127" %in% all.names(alvos$tabelas_recuperadas_1960_amostra_127))
message("Dependencias residuais conferidas por parse, sem avaliar o pipeline.")
