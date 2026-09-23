# Dois cartoes sem mudar pasta/UPA nem pessoas; executar pelo runner isolado.
.libPaths(c("renv/library/windows/R-4.5/x86_64-w64-mingw32", .libPaths()))
Sys.setlocale("LC_CTYPE", "Portuguese_Brazil.utf8")
library(data.table)
library(jsonlite)
library(digest)
setDTthreads(1L)
source("R/microdata_1960_amostra_127.R", encoding = "UTF-8")
base_fonte <- "tmp/resolucao_residuais_registros_1960_20260922"
dir.create(base_fonte, recursive = TRUE, showWarnings = FALSE)
saida_fonte <- tempfile("cartoes_chaves_", tmpdir = base_fonte)
dir.create(saida_fonte)
manifesto_path_fonte <- "read_guides/1960_amostra_127_cartoes_recuperados.json"
manifesto_fonte <- fromJSON(manifesto_path_fonte, simplifyVector = FALSE)
ids_fonte <- c("14-15004-116", "31-32426-233")
regras_fonte <- Filter(function(x) x$id_recuperacao %in% ids_fonte, manifesto_fonte$cartoes)
prova_path_fonte <- unique(vapply(regras_fonte, function(x) x$reconciliacao_chave$prova_arquivo, character(1)))
stopifnot(length(prova_path_fonte) == 1L)
prova_fonte <- fromJSON(prova_path_fonte, simplifyVector = FALSE)
stopifnot(length(regras_fonte) == 2L, identical(regras_fonte, prova_fonte$cartoes))
alvos_fonte <- sort(as.integer(unlist(lapply(regras_fonte, function(x) sapply(x$pessoas, `[[`, "linha")))))
stopifnot(length(alvos_fonte) == 6L)
raw_fonte <- "data_raw/microdata/1960/amostra_127/HHOLDA.txt"
hashes_fonte <- vapply(c(raw_fonte, manifesto_path_fonte, prova_path_fonte), function(x)
  digest(file = x, algo = "sha256"), character(1))
con_fonte <- file(raw_fonte, "rb")
textos_fonte <- character(length(alvos_fonte))
for(i in seq_along(alvos_fonte)){
  seek(con_fonte, where = (alvos_fonte[i] - 1) * 64, origin = "start")
  textos_fonte[i] <- readChar(con_fonte, 62L, useBytes = TRUE)
}
close(con_fonte)
lote_path_fonte <- file.path(saida_fonte, "microlote.txt")
writeLines(textos_fonte, lote_path_fonte, useBytes = TRUE)
linhas_fonte <- read_1960_amostra_127(lote_path_fonte)
linhas_fonte[, linha := alvos_fonte]
linhas_fonte <- apply_corrections_1960_amostra_127(linhas_fonte,
  "read_guides/1960_amostra_127_correcoes.csv")
entrada_fonte <- parse_1960_amostra_127(linhas_fonte,
  "read_guides/readguide_1960_amostra_127_familias.csv",
  "read_guides/readguide_1960_amostra_127_pessoas.csv")
stopifnot(nrow(entrada_fonte$familias) == 0L, nrow(entrada_fonte$pessoas) == 6L)
antes_fonte <- copy(entrada_fonte)
depois_fonte <- recover_family_cards_1960_amostra_127(entrada_fonte,
  manifesto_path_fonte, file.path(saida_fonte, "depois"))
stopifnot(identical(entrada_fonte, antes_fonte), identical(depois_fonte$pessoas, antes_fonte$pessoas),
          nrow(depois_fonte$familias) == 2L, all(depois_fonte$familias$censobr_cartao_chave_reconciliada),
          all(is.na(depois_fonte$familias$linha)), all(is.na(depois_fonte$familias$texto_original)))
stopifnot(depois_fonte$familias[UF == "14", pasta] == "15004",
          depois_fonte$familias[UF == "14", censobr_cartao_pasta_fonte25] == "14990",
          depois_fonte$familias[UF == "31", boletim] == "233",
          depois_fonte$familias[UF == "31", censobr_cartao_boletim_fonte25] == "006",
          depois_fonte$pessoas[linha == 132194L, V216] == "00")
ligado_fonte <- build_families_1960_amostra_127(depois_fonte, file.path(saida_fonte, "vinculado"))
stopifnot(nrow(ligado_fonte$pessoas) == 6L, nrow(ligado_fonte$familias) == 2L,
  uniqueN(ligado_fonte$pessoas$censobr_idfamily) == 2L,
  identical(as.data.frame(ligado_fonte$pessoas[, names(antes_fonte$pessoas), with = FALSE]),
            as.data.frame(antes_fonte$pessoas)))

negativas_fonte <- 0L
exigir_erro_fonte <- function(x, nome, manifesto = manifesto_path_fonte, padrao = NULL){
  antes <- copy(x)
  erro <- tryCatch(recover_family_cards_1960_amostra_127(x, manifesto,
    file.path(saida_fonte, nome)), error = identity)
  stopifnot(inherits(erro, "error"), identical(x, antes))
  if(!is.null(padrao)) stopifnot(grepl(padrao, conditionMessage(erro), fixed = TRUE))
  negativas_fonte <<- negativas_fonte + 1L
  message(nome, ": ", conditionMessage(erro))
}
for(campo in c("V216", "distrito", "pasta")){
  alterado <- copy(entrada_fonte)
  alterado$pessoas[linha == 132194L, (campo) := switch(campo, V216 = "63", distrito = "99", pasta = "14990")]
  exigir_erro_fonte(alterado, paste0("nao_substituir_", campo))
}
faltante_fonte <- copy(entrada_fonte)
faltante_fonte$pessoas <- faltante_fonte$pessoas[linha != 132194L]
exigir_erro_fonte(faltante_fonte, "membro_faltante")
extra_fonte <- copy(entrada_fonte)
extra_fonte$pessoas <- rbind(extra_fonte$pessoas, copy(extra_fonte$pessoas[1L])[, linha := 1999999L])
exigir_erro_fonte(extra_fonte, "membro_excedente")
for(usar_chave25 in c(FALSE, TRUE)){
  existente <- copy(entrada_fonte)
  existente$familias <- copy(depois_fonte$familias[UF == "14"])[, linha := 1999998L]
  if(usar_chave25) existente$familias[, pasta := censobr_cartao_pasta_fonte25]
  exigir_erro_fonte(existente, paste0("cartao_existente_", usar_chave25), padrao = "cartao ja existente")
}
exigir_erro_fonte(depois_fonte, "repeticao_sem_cartoes_novos")
gravar_fonte <- function(x, nome){
  path <- file.path(saida_fonte, paste0(nome, ".json"))
  write_json(x, path, auto_unbox = TRUE, pretty = TRUE, null = "null", na = "null", digits = NA)
  path
}
indice_ce_fonte <- which(sapply(manifesto_fonte$cartoes, `[[`, "id_recuperacao") == ids_fonte[1L])
uma_fonte <- manifesto_fonte
uma_fonte$cartoes[[indice_ce_fonte]]$reconciliacao_chave$testemunhas_exatas <- list(132193L)
exigir_erro_fonte(entrada_fonte, "uma_testemunha", gravar_fonte(uma_fonte, "uma_testemunha"),
  "decisao de chave diverge")
sem_prova_fonte <- manifesto_fonte
sem_prova_fonte$fontes <- Filter(function(x) x$arquivo != prova_path_fonte, sem_prova_fonte$fontes)
exigir_erro_fonte(entrada_fonte, "prova_sem_hash", gravar_fonte(sem_prova_fonte, "prova_sem_hash"),
  "fontes obrigatorias ausentes")
modo_fonte <- manifesto_fonte
modo_fonte$cartoes[[indice_ce_fonte]]$reconciliacao_chave$geografia_territorial_alterada <- TRUE
exigir_erro_fonte(entrada_fonte, "alterar_geografia", gravar_fonte(modo_fonte, "alterar_geografia"),
  "reconciliacao de chave")

# Adulterar prova e manifesto juntos, com assinatura externa correta, nao pode
# contornar as conferencias internas. Os arquivos falsos ficam somente em tmp.
gravar_conjunto_fonte <- function(prova, nome){
  novo_path <- file.path(saida_fonte, paste0(nome, "_prova.json"))
  for(j in seq_along(prova$cartoes))
    prova$cartoes[[j]]$reconciliacao_chave$prova_arquivo <- novo_path
  write_json(prova, novo_path, auto_unbox = TRUE, pretty = TRUE, null = "null", na = "null", digits = NA)
  conjunto <- manifesto_fonte
  for(regra in prova$cartoes){
    j <- which(vapply(conjunto$cartoes, function(x) x$id_recuperacao == regra$id_recuperacao, logical(1)))
    stopifnot(length(j) == 1L)
    conjunto$cartoes[[j]] <- regra
  }
  conjunto$fontes <- Filter(function(x) x$arquivo != prova_path_fonte, conjunto$fontes)
  conjunto$fontes[[length(conjunto$fontes) + 1L]] <- list(arquivo = novo_path,
    sha256 = digest(file = novo_path, algo = "sha256"))
  gravar_fonte(conjunto, paste0(nome, "_manifesto"))
}
hash_interno_falso <- prova_fonte
hash_interno_falso$fontes[[1L]]$sha256 <- paste(rep("0", 64L), collapse = "")
exigir_erro_fonte(entrada_fonte, "fonte_interna_falsa",
  gravar_conjunto_fonte(hash_interno_falso, "fonte_interna_falsa"), "fonte interna alterada")

unica_falsa <- prova_fonte
unica_falsa$analises[[1L]]$testemunhas[[1L]]$ocorrencias127UF <- 2L
exigir_erro_fonte(entrada_fonte, "testemunha_nao_exclusiva",
  gravar_conjunto_fonte(unica_falsa, "testemunha_nao_exclusiva"), "testemunha sem exclusividade")

alternativa_falsa <- prova_fonte
alternativa_falsa$analises[[1L]]$cartoes_examinados[[1L]]$motivos_alternativa <- list("contraprova_pendente")
exigir_erro_fonte(entrada_fonte, "alternativa_nao_zerada",
  gravar_conjunto_fonte(alternativa_falsa, "alternativa_nao_zerada"), "alternativa remanescente")

exata_falsa <- prova_fonte
indice_nao_exato <- which(vapply(exata_falsa$analises[[1L]]$testemunhas,
  function(x) x$linha127 == 132194L, logical(1)))
exata_falsa$analises[[1L]]$testemunhas[[indice_nao_exato]]$exato25 <- TRUE
exigir_erro_fonte(entrada_fonte, "exatidao_falsa",
  gravar_conjunto_fonte(exata_falsa, "exatidao_falsa"), "exatidao diverge")

uf_falsa <- prova_fonte
uf_falsa$cartoes[[1L]]$arquivo_25 <- "data/release_legacy/Censo.1960.amostra.25porcento.ba.gz"
exigir_erro_fonte(entrada_fonte, "fonte_de_outra_uf",
  gravar_conjunto_fonte(uf_falsa, "fonte_de_outra_uf"), "UF diverge do arquivo estadual")

analise_ausente <- prova_fonte
analise_ausente$analises <- analise_ausente$analises[-1L]
exigir_erro_fonte(entrada_fonte, "analise_ausente",
  gravar_conjunto_fonte(analise_ausente, "analise_ausente"), "analise localizada de chave ausente")
stopifnot(identical(hashes_fonte, vapply(names(hashes_fonte), function(x)
  digest(file = x, algo = "sha256"), character(1))))
write_json(list(cartoes_recuperados = 2L, pessoas_preservadas = 6L, pessoas_novas = 0L,
  pasta127_preservada = TRUE, respostas_preservadas = TRUE, contraprovas_bloqueadas = negativas_fonte),
  file.path(saida_fonte, "conferencia.json"), pretty = TRUE, auto_unbox = TRUE)
message("Cartoes BA/CE conferidos sem importar numeracao25: ", saida_fonte)
