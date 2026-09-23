# Microlote de oito cartoes candidatos; executar somente pelo runner isolado.
.libPaths(c("renv/library/windows/R-4.5/x86_64-w64-mingw32", .libPaths()))
Sys.setlocale("LC_CTYPE", "Portuguese_Brazil.utf8")
library(data.table)
library(jsonlite)
library(digest)
setDTthreads(1L)
source("R/microdata_1960_amostra_127.R", encoding = "UTF-8")

base_composta <- "tmp/fechamento_integral_1960/vinculos"
pacote_path_composta <- Sys.getenv("CENSOBR_TEST_COMPOSTA_PACOTE",
  unset = "references/fechamento_integral_1960_evidencias/cartoes_compostos.json")
pacote_composta <- fromJSON(pacote_path_composta, simplifyVector = FALSE)
provas_composta <- lapply(unlist(pacote_composta$arquivos_provas), fromJSON, simplifyVector = FALSE)
pacote_composta$analises <- unlist(lapply(provas_composta, `[[`, "analises"), recursive = FALSE)
pacote_composta$provas_compostas <- list()
for(prova in provas_composta)
  pacote_composta$provas_compostas[names(prova$provas_compostas)] <- prova$provas_compostas
pacote_composta$cartoes <- Filter(function(x)
  x$id_recuperacao != "40-40880-001" &&
    identical(x$prova_composta$modalidade, "grupos_proprios24_V216_00_63_preservado"), pacote_composta$cartoes)
stopifnot(length(pacote_composta$cartoes) == 8L,
  sum(vapply(pacote_composta$cartoes, `[[`, integer(1), "n_pessoas")) == 20L)
saida_composta <- tempfile("teste_r_", tmpdir = base_composta)
dir.create(saida_composta)
id_composta <- vapply(pacote_composta$cartoes, `[[`, character(1), "id_recuperacao")
pacote_composta$analises <- Filter(function(x) x$id_recuperacao %in% id_composta,
  pacote_composta$analises)
decisivos_composta <- sort(unique(as.integer(unlist(lapply(pacote_composta$cartoes,
  function(x) x$prova_composta$cartoes_decisivos)))))
pacote_composta$provas_compostas <- pacote_composta$provas_compostas[as.character(decisivos_composta)]
pacote_composta$contraprovas_MG40880 <- NULL
gravar_composta <- function(prova, nome){
  path_prova <- file.path(saida_composta, paste0(nome, "_prova.json"))
  for(i in seq_along(prova$cartoes)){
    prova$cartoes[[i]]$prova_composta$prova_arquivo <- path_prova
  }
  write_json(prova, path_prova, auto_unbox = TRUE, pretty = TRUE,
    null = "null", na = "null", digits = NA)
  manifesto <- list(versao = 1L, fontes = c(prova$fontes, list(list(
    arquivo = path_prova, sha256 = digest(file = path_prova, algo = "sha256")))),
    cartoes = prova$cartoes)
  path_manifesto <- file.path(saida_composta, paste0(nome, "_manifesto.json"))
  write_json(manifesto, path_manifesto, auto_unbox = TRUE, pretty = TRUE,
    null = "null", na = "null", digits = NA)
  path_manifesto
}

alvos_composta <- sort(as.integer(unlist(lapply(pacote_composta$cartoes,
  function(x) vapply(x$pessoas, `[[`, integer(1), "linha")))))
con_composta <- file("data_raw/microdata/1960/amostra_127/HHOLDA.txt", "rb")
textos_composta <- character(length(alvos_composta))
for(i in seq_along(alvos_composta)){
  seek(con_composta, where = (alvos_composta[i] - 1) * 64, origin = "start")
  textos_composta[i] <- readChar(con_composta, 62L, useBytes = TRUE)
}
close(con_composta)
lote_composta <- file.path(saida_composta, "microlote.txt")
writeLines(textos_composta, lote_composta, useBytes = TRUE)
linhas_composta <- read_1960_amostra_127(lote_composta)
linhas_composta[, linha := alvos_composta]
linhas_composta <- apply_corrections_1960_amostra_127(linhas_composta,
  "read_guides/1960_amostra_127_correcoes.csv")
entrada_composta <- parse_1960_amostra_127(linhas_composta,
  "read_guides/readguide_1960_amostra_127_familias.csv",
  "read_guides/readguide_1960_amostra_127_pessoas.csv")
stopifnot(nrow(entrada_composta$familias) == 0L, nrow(entrada_composta$pessoas) == 20L)
antes_composta <- copy(entrada_composta)

negativas_composta <- 0L
exigir_erro_composta <- function(prova, nome){
  manifesto <- gravar_composta(prova, nome)
  erro <- tryCatch(recover_family_cards_1960_amostra_127(entrada_composta, manifesto,
    file.path(saida_composta, nome)), error = identity)
  stopifnot(inherits(erro, "error"), identical(entrada_composta, antes_composta),
    grepl("prova composta", conditionMessage(erro), fixed = TRUE))
  negativas_composta <<- negativas_composta + 1L
  message(nome, ": ", conditionMessage(erro))
}

# Antes da implementação, esta contraprova deve falhar: o campo era ignorado.
adulterada_composta <- pacote_composta
adulterada_composta$provas_compostas[[1L]]$ocorrencias_grupo24_na25 <-
  rep(adulterada_composta$provas_compostas[[1L]]$ocorrencias_grupo24_na25, 2L)
exigir_erro_composta(adulterada_composta, "grupo_nao_unico")

manifesto_composta <- gravar_composta(pacote_composta, "correta")
depois_composta <- recover_family_cards_1960_amostra_127(entrada_composta, manifesto_composta,
  file.path(saida_composta, "correta"))
stopifnot(identical(entrada_composta, antes_composta),
  identical(depois_composta$pessoas, antes_composta$pessoas),
  nrow(depois_composta$familias) == 8L,
  all(is.na(depois_composta$familias$linha)), all(is.na(depois_composta$familias$id_arquivo)))

adulterada_composta <- pacote_composta
adulterada_composta$provas_compostas[[1L]]$pessoas25 <-
  adulterada_composta$provas_compostas[[1L]]$pessoas25[-1L]
exigir_erro_composta(adulterada_composta, "membro_fonte_ausente")

adulterada_composta <- pacote_composta
adulterada_composta$provas_compostas[[1L]]$pessoas127 <-
  c(adulterada_composta$provas_compostas[[1L]]$pessoas127,
    adulterada_composta$provas_compostas[[1L]]$pessoas127[1L])
exigir_erro_composta(adulterada_composta, "multiplicidade_excedente")

adulterada_composta <- pacote_composta
adulterada_composta$provas_compostas[[1L]]$pares_nova_busca[[1L]]$diferencas <- list(AGE = list(20L, 21L))
exigir_erro_composta(adulterada_composta, "outro_quesito_omitido")

adulterada_composta <- pacote_composta
adulterada_composta$provas_compostas[[1L]]$ocorrencias_grupo24_na127[[1L]]$cartao <- 1L
exigir_erro_composta(adulterada_composta, "grupo127_de_outro_cartao")

adulterada_composta <- pacote_composta
adulterada_composta$provas_compostas[[1L]]$ocorrencias_grupo24_na25[[1L]]$chave <- "00000000"
exigir_erro_composta(adulterada_composta, "chave25_de_outro_grupo")

adulterada_composta <- pacote_composta
adulterada_composta$analises[[1L]]$cartoes_examinados[[1L]]$motivos_depois <- list("concorrente")
exigir_erro_composta(adulterada_composta, "alternativa_remanescente")

adulterada_composta <- pacote_composta
adulterada_composta$provas_compostas[[1L]]$cartao127$corrigido <-
  paste0(substr(adulterada_composta$provas_compostas[[1L]]$cartao127$corrigido, 1L, 17L), "9",
    substr(adulterada_composta$provas_compostas[[1L]]$cartao127$corrigido, 19L, 62L))
exigir_erro_composta(adulterada_composta, "geografia_cartao_adulterada")

adulterada_composta <- pacote_composta
adulterada_composta$fontes[[1L]]$sha256 <- paste(rep("0", 64L), collapse = "")
# A assinatura externa também falha legitimamente antes do leitor específico.
manifesto_falso_composta <- gravar_composta(adulterada_composta, "fonte_adulterada")
erro_fonte_composta <- tryCatch(recover_family_cards_1960_amostra_127(entrada_composta,
  manifesto_falso_composta, file.path(saida_composta, "fonte_adulterada")), error = identity)
stopifnot(inherits(erro_fonte_composta, "error"))

write_json(list(cartoes = 8L, pessoas_preservadas = 20L, pessoas_novas = 0L,
  respostas_modificadas = 0L, contraprovas = negativas_composta + 1L),
  file.path(saida_composta, "conferencia.json"), pretty = TRUE, auto_unbox = TRUE)
message("Prova composta e oito cartoes conferidos: ", saida_composta)
