# Teste de identidade conjunta anterior ao reparo; somente fixtures em tmp.
.libPaths(c("renv/library/windows/R-4.5/x86_64-w64-mingw32", .libPaths()))
Sys.setlocale("LC_CTYPE", "Portuguese_Brazil.utf8")
library(data.table)
library(jsonlite)
library(digest)
setDTthreads(1L)
source("R/microdata_1960_amostra_127.R", encoding = "UTF-8")
base_mg <- "tmp/fechamento_integral_1960/vinculos"
proposta_mg <- fromJSON("references/fechamento_integral_1960_evidencias/cartao_composto_40-40880-001.json",
  simplifyVector = FALSE)
proposta_mg$reparo_proposto <- fromJSON(
  "references/fechamento_integral_1960_evidencias/mg405458_identidade.json", simplifyVector = FALSE)$reparo_aprovado
saida_mg <- tempfile("teste_mg_", tmpdir = base_mg)
dir.create(saida_mg)
dec_mg <- read.csv("read_guides/1960_amostra_127_correcoes.csv", strip.white = FALSE,
  stringsAsFactors = FALSE, fileEncoding = "UTF-8", colClasses = "character")
idx_mg <- match("405458", dec_mg$linha)
stopifnot(!is.na(idx_mg))
dec_mg$decisao[idx_mg] <- "reparo_fonte25"
dec_mg$texto_corrigido[idx_mg] <- proposta_mg$reparo_proposto$texto_corrigido_proposto
correcoes_mg <- file.path(saida_mg, "correcoes.csv")
write.csv(dec_mg, correcoes_mg, row.names = FALSE, na = "", fileEncoding = "UTF-8")
fontes_mg <- proposta_mg$fontes
for(i in seq_along(fontes_mg))
  if(fontes_mg[[i]]$arquivo == "read_guides/1960_amostra_127_correcoes.csv")
    fontes_mg[[i]] <- list(arquivo = correcoes_mg, sha256 = digest(file = correcoes_mg, algo = "sha256"))
evidencia_mg <- list(versao = 1L, fontes = fontes_mg, reparos = list(proposta_mg$reparo_proposto))
gravar_mg <- function(x, nome){
  path <- file.path(saida_mg, paste0(nome, ".json"))
  write_json(x, path, auto_unbox = TRUE, pretty = TRUE, null = "null", na = "null", digits = NA)
  path
}
evidencia_path_mg <- gravar_mg(evidencia_mg, "reparo")
textos_mg <- vapply(proposta_mg$reparo_proposto$grupo127, `[[`, character(1), "texto")
alvos_mg <- vapply(proposta_mg$reparo_proposto$grupo127, `[[`, integer(1), "linha")
lote_mg <- file.path(saida_mg, "microlote.txt")
writeLines(textos_mg, lote_mg, useBytes = TRUE)
entrada_mg <- read_1960_amostra_127(lote_mg)
entrada_mg[, linha := alvos_mg]
antes_mg <- copy(entrada_mg)

# Antes da implementação, falha por critério desconhecido/cartão127 ausente.
corrigido_mg <- apply_corrections_1960_amostra_127(entrada_mg, correcoes_mg, evidencia_path_mg)
stopifnot(identical(entrada_mg, antes_mg), corrigido_mg[linha == 405458L, tipo] == "3",
  substr(corrigido_mg[linha == 405458L, texto], 20L, 20L) == "7",
  substr(corrigido_mg[linha == 405458L, texto], 22L, 23L) == "79",
  identical(corrigido_mg[linha != 405458L, texto], entrada_mg[linha != 405458L, texto]))
antigo_mg <- strsplit(entrada_mg[linha == 405458L, texto], "", fixed = TRUE)[[1L]]
novo_mg <- strsplit(corrigido_mg[linha == 405458L, texto], "", fixed = TRUE)[[1L]]
stopifnot(identical(which(antigo_mg != novo_mg), c(20L, 22L)))
parsed_mg <- parse_1960_amostra_127(corrigido_mg,
  "read_guides/readguide_1960_amostra_127_familias.csv", "read_guides/readguide_1960_amostra_127_pessoas.csv")
stopifnot(nrow(parsed_mg$familias) == 0L, parsed_mg$pessoas[linha == 405458L, V203] == "7",
  parsed_mg$pessoas[linha == 405458L, AGE] == "79", parsed_mg$pessoas[linha == 405458L, tipo] == "3")

prova_mg <- proposta_mg
prova_mg$fontes <- fontes_mg
prova_path_mg <- file.path(saida_mg, "cartao_prova.json")
prova_mg$cartoes[[1L]]$prova_composta <- list(modalidade = "grupos_proprios24_V216_00_63_preservado",
  prova_arquivo = prova_path_mg, cartoes_decisivos = list(405480L, 405486L))
write_json(prova_mg, prova_path_mg, auto_unbox = TRUE, pretty = TRUE, null = "null", na = "null", digits = NA)
manifesto_mg <- list(versao = 1L, fontes = c(fontes_mg, list(list(arquivo = prova_path_mg,
  sha256 = digest(file = prova_path_mg, algo = "sha256")))), cartoes = prova_mg$cartoes)
manifesto_path_mg <- gravar_mg(manifesto_mg, "cartao_manifesto")
recuperado_mg <- recover_family_cards_1960_amostra_127(parsed_mg, manifesto_path_mg,
  file.path(saida_mg, "cartao"), correcoes_path = correcoes_mg)
stopifnot(nrow(recuperado_mg$familias) == 1L, nrow(recuperado_mg$pessoas) == 3L,
  identical(recuperado_mg$pessoas, parsed_mg$pessoas), is.na(recuperado_mg$familias$linha),
  recuperado_mg$pessoas[linha == 405458L, tipo] == "3")

negativas_mg <- 0L
exigir_erro_mg <- function(reparo, nome){
  altered <- evidencia_mg
  altered$reparos <- list(reparo)
  path <- gravar_mg(altered, nome)
  # As consultas do teste positivo podem criar indices secundarios em entrada_mg.
  # Cada recusa recebe uma copia nova anterior a essas consultas: conferimos
  # inclusive os atributos dessa entrada, alem de nenhum texto ser reparado.
  entrada_caso <- copy(antes_mg)
  antes_caso <- copy(entrada_caso)
  erro <- tryCatch(apply_corrections_1960_amostra_127(entrada_caso, correcoes_mg, path), error = identity)
  stopifnot(inherits(erro, "error"), identical(entrada_caso, antes_caso),
    identical(entrada_caso$texto, textos_mg))
  negativas_mg <<- negativas_mg + 1L
  message(nome, ": ", conditionMessage(erro))
}
alterado_mg <- proposta_mg$reparo_proposto
alterado_mg$testemunhas_identidade <- alterado_mg$testemunhas_identidade[1L]
exigir_erro_mg(alterado_mg, "uma_testemunha")
alterado_mg <- proposta_mg$reparo_proposto
alterado_mg$testemunhas_identidade[[2L]]$linha127 <- 405458L
alterado_mg$testemunhas_identidade[[2L]]$linha25 <- 567047L
exigir_erro_mg(alterado_mg, "alvo_como_testemunha_circular")
alterado_mg <- proposta_mg$reparo_proposto
alterado_mg$testemunhas_identidade[[1L]]$campos_ignorados <- list("AGE")
exigir_erro_mg(alterado_mg, "testemunha_nao_intacta")
alterado_mg <- proposta_mg$reparo_proposto
alterado_mg$propostas[[2L]]$depois <- "78"
exigir_erro_mg(alterado_mg, "troca_digito_legivel")
alterado_mg <- proposta_mg$reparo_proposto
alterado_mg$propostas[[1L]]$depois <- "8"
exigir_erro_mg(alterado_mg, "parentesco_fora_da_fonte")
alterado_mg <- proposta_mg$reparo_proposto
alterado_mg$geografia_parcial_preservada <- list(list(linha127 = 405458L, campo = "distrito", antes = "01", depois = "02"))
exigir_erro_mg(alterado_mg, "geografia_nao_autorizada")
alterado_mg <- proposta_mg$reparo_proposto
alterado_mg$grupo127 <- alterado_mg$grupo127[-1L]
exigir_erro_mg(alterado_mg, "grupo_incompleto")

write_json(list(cartoes = 1L, pessoas = 3L, pessoas_novas = 0L,
  posicoes_reparadas = c(20L, 22L), REC_TYPE_preservado = "3", contraprovas = negativas_mg),
  file.path(saida_mg, "conferencia.json"), auto_unbox = TRUE, pretty = TRUE)
message("MG reparo e cartao com testemunhos conjuntos independentes: ", saida_mg)
