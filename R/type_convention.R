# Convencao de tipos das colunas publicadas.
#
# O tipo de cada coluna esta declarado em schemas/censobr_types.csv, derivado da
# medicao de toda coluna dos 42 parquets do pipeline. A regra e mecanica, sem
# julgamento coluna a coluna:
#
#   1. nome humano (name_*, abbrev_*)            -> string
#   2. tem algum valor que nao e numero          -> string
#   3. tem algum valor com decimal               -> double
#   4. tudo inteiro e cabe em +-2.147.483.647    -> int32
#   5. tudo inteiro mas nao cabe                 -> double
#
# Nao ha int8 nem int16 na convencao, e nao e descuido: o Arrow nao promove tipo
# na aritmetica elemento a elemento, ele aborta. int8 + int8 somando 200 devolve
# "Invalid: overflow", e o proprio idioma de compor codigo -- code_state * 1e5
# mais o municipio -- estoura int8 no primeiro uso. O ganho de int32 sobre
# double ja e metade dos bytes, sem abrir esse flanco.
#
# Nao ha int64 acima de int32 porque dplyr::left_join recusa integer64 contra
# double, e esse e o join censobr x geobr publicado nas vinhetas do consumidor.
# Acima de int32 vai double, que representa inteiro exato ate 2^53.
#
# Nao ha float32 em lugar nenhum: medido, corrompe 20.635.275 dos 20.635.472
# pesos de 2010 e todos os codigos de setor.
#
# Public API: cast_censobr_types.


# Converte as colunas de `x` para o tipo declarado. Funciona tanto sobre tabela
# em memoria quanto sobre query arrow preguicosa.
cast_censobr_types <- function(x, dataset){

  conv <- data.table::fread("schemas/censobr_types.csv")
  conv <- conv[conv$dataset == dataset & conv$tipo_alvo != conv$tipo_atual, ]
  conv <- conv[conv$coluna %in% names(x), ]

  if(nrow(conv) == 0) return(x)

  para_int <- conv$coluna[conv$tipo_alvo == "int32"]
  para_dbl <- conv$coluna[conv$tipo_alvo == "double"]
  para_str <- conv$coluna[conv$tipo_alvo == "string"]

  message("  tipos: ", length(para_int), " int32, ",
          length(para_dbl), " double, ", length(para_str), " string")

  # all_of sem o prefixo dplyr:: de proposito -- o arrow nao resolve a forma
  # qualificada dentro do tidyselect
  if(length(para_int)) x <- dplyr::mutate(x, dplyr::across(all_of(para_int), as.integer))
  if(length(para_dbl)) x <- dplyr::mutate(x, dplyr::across(all_of(para_dbl), as.numeric))
  if(length(para_str)) x <- dplyr::mutate(x, dplyr::across(all_of(para_str), as.character))

  x
}
