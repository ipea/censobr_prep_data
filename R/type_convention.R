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

  # data.frame, nao data.table: dentro de um data.table `dataset` seria a coluna
  # e nao o argumento, e o filtro deixaria passar as linhas de todas as tabelas
  conv <- data.table::fread("schemas/censobr_types.csv", data.table = FALSE)
  conv <- conv[conv$dataset == dataset & conv$coluna %in% names(x), ]

  # o tipo de partida e o da tabela que chega aqui, nao o medido no parquet
  # anterior. Numa query arrow le-se o schema do plano com zero linhas -- e nao
  # a classe em R, que esconde int8/int16 como integer
  if(inherits(x, "arrow_dplyr_query") || inherits(x, "ArrowObject")){
    sch   <- arrow::as_arrow_table(head(x, 0))$schema
    atual <- sapply(sch$fields, function(f) f$type$ToString())
    names(atual) <- names(sch)
    atual[grepl("string", atual)] <- "string"
    atual[atual == "float"] <- "float32"
  } else {
    cls   <- sapply(x, function(col) class(col)[1])
    atual <- unname(c(character = "string", integer = "int32", numeric = "double",
                      integer64 = "int64")[cls])
    names(atual) <- names(cls)
  }
  atual <- unname(atual[conv$coluna])          # NA para classe desconhecida
  keep  <- !is.na(atual) & atual != conv$tipo_alvo
  conv  <- conv[keep, ]
  atual <- atual[keep]

  if(nrow(conv) == 0) return(x)

  para_int <- conv$coluna[conv$tipo_alvo == "int32"]
  para_dbl <- conv$coluna[conv$tipo_alvo == "double"]
  para_str <- conv$coluna[conv$tipo_alvo == "string"]

  message("  tipos: ", length(para_int), " int32, ",
          length(para_dbl), " double, ", length(para_str), " string")

  # texto que vira numero: os unicos valores nao numericos sao o branco e o
  # ponto que o IBGE usa como marca de ausencia, e viram NA
  de_texto <- conv$coluna[atual == "string" & conv$tipo_alvo != "string"]

  # all_of sem o prefixo dplyr:: de proposito -- o arrow nao resolve a forma
  # qualificada dentro do tidyselect
  # o arrow (25.0) traduz if_else, %in% e str_trim, mas nao na_if nem trimws;
  # if_else sem prefixo de pacote, pelo mesmo motivo do all_of
  for(v in de_texto)
    x <- dplyr::mutate(x, !!v := if_else(stringr::str_trim(!!rlang::sym(v)) %in% c("", "."),
                                          NA_character_, stringr::str_trim(!!rlang::sym(v))))
  if(length(para_int)) x <- dplyr::mutate(x, dplyr::across(all_of(para_int), as.integer))
  if(length(para_dbl)) x <- dplyr::mutate(x, dplyr::across(all_of(para_dbl), as.numeric))
  if(length(para_str)) x <- dplyr::mutate(x, dplyr::across(all_of(para_str), as.character))

  x
}
