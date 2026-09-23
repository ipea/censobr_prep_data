# Distrito derivado, sem reescrever os sete registros; runner isolado, nunca targets.
.libPaths(c("renv/library/windows/R-4.5/x86_64-w64-mingw32", .libPaths()))
Sys.setlocale("LC_CTYPE", "Portuguese_Brazil.utf8")
library(data.table)
library(jsonlite)
library(digest)
setDTthreads(1L)
source("R/microdata_1960_amostra_127.R", encoding = "UTF-8")
base_pe <- "tmp/resolucao_residuais_registros_1960_20260922"
dir.create(base_pe, recursive = TRUE, showWarnings = FALSE)
saida_pe <- tempfile("distrito_pe_", tmpdir = base_pe)
dir.create(saida_pe)
prova_path_pe <- "references/resolucao_residuais_1960_evidencias/distrito_pe_operacional.json"
prova_pe <- fromJSON(prova_path_pe, simplifyVector = FALSE)
alvos_pe <- c(238422L, 238423L, 239457:239461)
raw_path_pe <- "data_raw/microdata/1960/amostra_127/HHOLDA.txt"
hashes_pe <- vapply(c(raw_path_pe, prova_path_pe, "read_guides/1960_amostra_127_vinculos.csv"),
  function(x) digest(file = x, algo = "sha256"), character(1))
raw_pe <- file(raw_path_pe, "rb")
textos_pe <- character(length(alvos_pe))
for(i in seq_along(alvos_pe)){
  seek(raw_pe, where = (alvos_pe[i] - 1) * 64, origin = "start")
  textos_pe[i] <- readChar(raw_pe, 62L, useBytes = TRUE)
}
close(raw_pe)
path_pe <- file.path(saida_pe, "microlote.txt")
writeLines(textos_pe, path_pe, useBytes = TRUE)
linhas_pe <- read_1960_amostra_127(path_pe)
linhas_pe[, linha := alvos_pe]
linhas_pe <- apply_corrections_1960_amostra_127(linhas_pe,
  "read_guides/1960_amostra_127_correcoes.csv")
entrada_pe <- parse_1960_amostra_127(linhas_pe,
  "read_guides/readguide_1960_amostra_127_familias.csv",
  "read_guides/readguide_1960_amostra_127_pessoas.csv")
# Antes: cinco pessoas nao encontram a chave literal do cartao; nenhuma e criada.
pendentes_antes_pe <- entrada_pe$pessoas[!paste(UF, chave) %in% paste(entrada_pe$familias$UF, entrada_pe$familias$chave), linha]
stopifnot(identical(pendentes_antes_pe, 239457:239461), nrow(entrada_pe$pessoas) == 6L,
  entrada_pe$familias$distrito == "X7", entrada_pe$pessoas[linha == 238423L, distrito] == "X7",
  substr(entrada_pe$pessoas[linha == 238423L, texto_original], 28L, 28L) == " ",
  entrada_pe$pessoas[linha == 238423L, V208] == "9",
  identical(unlist(prova_pe$testemunha_previa_sem_V208$campos_ignorados), "V208"),
  prova_pe$testemunha_previa_sem_V208$n127 == 1L, prova_pe$testemunha_previa_sem_V208$n25 == 1L)
antes_pe <- copy(entrada_pe)
depois_pe <- build_families_1960_amostra_127(entrada_pe, file.path(saida_pe, "depois"))
stopifnot(identical(entrada_pe, antes_pe), nrow(depois_pe$familias) == 1L,
  nrow(depois_pe$pessoas) == 6L, uniqueN(depois_pe$pessoas$censobr_idfamily) == 1L,
  all(depois_pe$pessoas$distrito == "07"), depois_pe$familias$distrito == "07",
  depois_pe$familias$censobr_distrito_original == "X7",
  depois_pe$pessoas[linha == 238423L, censobr_distrito_original] == "X7",
  sum(depois_pe$pessoas$censobr_distrito_recuperado) == 1L,
  depois_pe$familias$censobr_distrito_recuperado,
  all(depois_pe$pessoas[linha %in% 239457:239461, censobr_familia_origem] == "reconciliada_25"),
  depois_pe$pessoas[linha == 239457L, V216] == "00",
  all(depois_pe$pessoas$pasta == "22366"), depois_pe$familias$pasta == "22366")
preservados_pe <- setdiff(names(antes_pe$pessoas), c("distrito", "chave"))
stopifnot(identical(as.data.frame(depois_pe$pessoas[, ..preservados_pe]),
                    as.data.frame(antes_pe$pessoas[, ..preservados_pe])),
  identical(depois_pe$familias$texto_original, antes_pe$familias$texto_original),
  identical(depois_pe$familias$texto_corrigido, antes_pe$familias$texto_corrigido))

negativas_pe <- 0L
falha_pe <- function(x, nome, prova = prova_path_pe, padrao = NULL){
  antes <- copy(x)
  erro <- tryCatch(build_families_1960_amostra_127(x, file.path(saida_pe, nome),
    distrito_prova_path = prova), error = identity)
  stopifnot(inherits(erro, "error"), identical(x, antes))
  if(!is.null(padrao)) stopifnot(grepl(padrao, conditionMessage(erro), fixed = TRUE))
  negativas_pe <<- negativas_pe + 1L
  message(nome, ": ", conditionMessage(erro))
}
falha_pe(entrada_pe, "sem_prova", prova = NULL, padrao = "exige prova localizada")
for(campo in c("UF", "boletim", "distrito", "V208", "V216")){
  x <- copy(entrada_pe)
  n <- if(campo == "V216") 239457L else 238423L
  valor <- switch(campo, UF = "14", boletim = "153", distrito = "X8", V208 = NA_character_, V216 = "63")
  x$pessoas[linha == n, (campo) := valor]
  falha_pe(x, paste0("alteracao_", campo))
}
ausente_pe <- copy(entrada_pe); ausente_pe$pessoas <- ausente_pe$pessoas[linha != 239457L]
falha_pe(ausente_pe, "composicao_faltante")
extra_pe <- copy(entrada_pe)
extra_pe$pessoas <- rbind(extra_pe$pessoas, copy(extra_pe$pessoas[1L])[, linha := 1999999L])
falha_pe(extra_pe, "composicao_excedente")
cartao_extra_pe <- copy(entrada_pe)
cartao_extra_pe$familias <- rbind(cartao_extra_pe$familias,
  copy(cartao_extra_pe$familias)[, `:=`(linha = 1999998L, distrito = "17", chave = "1722366154")])
falha_pe(cartao_extra_pe, "cartao_concorrente")
texto_pe <- copy(entrada_pe)
texto_pe$pessoas[linha == 238423L, texto_original := paste0("14", substr(texto_original, 3L, 62L))]
falha_pe(texto_pe, "literal_uf_alterado")
for(campo in c("distrito_operacional", "testemunha", "fonte")){
  documento <- prova_pe
  if(campo == "distrito_operacional") documento$distrito_operacional <- "17"
  if(campo == "testemunha") documento$testemunha_previa_sem_V208$campos_ignorados <- list()
  if(campo == "fonte") documento$fontes[[1L]]$sha256 <- strrep("0", 64L)
  caminho <- file.path(saida_pe, paste0("prova_", campo, ".json"))
  write_json(documento, caminho, pretty = TRUE, auto_unbox = TRUE, null = "null", na = "null")
  falha_pe(entrada_pe, paste0("prova_", campo), prova = caminho)
}

# Controle FICTICIO so no microlote: segunda pasta evita estrato solitario.
# Nao e uma familia historica nem integra o manifesto/prova.
para_final_pe <- copy(depois_pe)
controle_f_pe <- copy(depois_pe$familias)
controle_f_pe[, `:=`(linha = 2000001L, pasta = "22368", chave = "0722368154",
  censobr_idfamily = 2L, censobr_idhousehold = 2L, censobr_distrito_original = "07",
  censobr_distrito_recuperado = FALSE, censobr_distrito_fonte25 = NA_character_,
  censobr_distrito_prova = NA_character_, censobr_distrito_prova_sha256 = NA_character_)]
controle_p_pe <- copy(depois_pe$pessoas[linha == 238423L])
controle_p_pe[, `:=`(linha = 2000002L, pasta = "22368", chave = "0722368154",
  censobr_idfamily = 2L, censobr_idhousehold = 2L, censobr_distrito_original = "07",
  censobr_distrito_recuperado = FALSE, censobr_distrito_fonte25 = NA_character_,
  censobr_distrito_prova = NA_character_, censobr_distrito_prova_sha256 = NA_character_)]
para_final_pe$familias <- rbind(para_final_pe$familias, controle_f_pe)
para_final_pe$pessoas <- rbind(para_final_pe$pessoas, controle_p_pe)
final_pe <- finalize_1960_amostra_127(para_final_pe, "read_guides/1960_municipios.csv", "read_guides/1960_distritos.csv")
marcas_pe <- grep("^censobr_distrito_", names(depois_pe$familias), value = TRUE)
stopifnot(all(marcas_pe %in% names(final_pe$pessoas)), all(marcas_pe %in% names(final_pe$domicilios)),
  final_pe$domicilios[linha == 238422L, code_district_1960] == 7L,
  all(final_pe$pessoas[linha %in% alvos_pe, code_district_1960] == 7L),
  final_pe$domicilios[linha == 238422L, censobr_distrito_original] == "X7",
  final_pe$pessoas[linha == 238423L, censobr_distrito_original] == "X7",
  final_pe$domicilios[linha == 238422L, censobr_upa] == "21-22366",
  all(final_pe$pessoas[linha %in% alvos_pe, censobr_upa] == "21-22366"),
  final_pe$pessoas[linha == 239457L, V216] == 0L)
stopifnot(identical(hashes_pe, vapply(names(hashes_pe), function(x) digest(file = x, algo = "sha256"), character(1))))
write_json(list(pessoas = 6L, vinculos_completados = 5L, distritos_operacionais_recuperados = 2L,
  textos_alterados = 0L, pessoas_novas = 0L, V216_preservado = TRUE, contraprovas_bloqueadas = negativas_pe,
  marcas_preservadas_na_finalizacao = TRUE, controle_finalizacao_ficticio = TRUE),
  file.path(saida_pe, "conferencia.json"), pretty = TRUE, auto_unbox = TRUE)
message("Distrito PE recuperado com textos e UPA preservados: ", saida_pe)
