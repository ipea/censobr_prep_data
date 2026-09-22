# Teste isolado: somente microlotes e copias em tmp; nunca targets ou producao.
# Executar exclusivamente pelo runner references/rodar_r_isolado_1960.py.
.libPaths(c("renv/library/windows/R-4.5/x86_64-w64-mingw32", .libPaths()))
Sys.setlocale("LC_CTYPE", "Portuguese_Brazil.utf8")
library(data.table)
library(jsonlite)
library(digest)
library(arrow)
setDTthreads(1L)
source("R/microdata_1960_amostra_127.R", encoding = "UTF-8")
stopifnot(exists("recover_family_cards_1960_amostra_127", mode = "function"))
invisible(parse("R/microdata_1960.R", encoding = "UTF-8"))
invisible(parse("_targets.R", encoding = "UTF-8"))

dir.create("tmp/recuperacao_cartoes_1960_20260922", recursive = TRUE, showWarnings = FALSE)
saida <- tempfile("teste_", tmpdir = "tmp/recuperacao_cartoes_1960_20260922")
dir.create(saida)
manifesto_path <- Sys.getenv("CENSOBR_TEST_CARTOES_MANIFESTO",
  unset = "read_guides/1960_amostra_127_cartoes_recuperados.json")
raw_path <- "data_raw/microdata/1960/amostra_127/HHOLDA.txt"
hash_antes <- digest(file = raw_path, algo = "sha256")
manifesto <- fromJSON(manifesto_path, simplifyVector = FALSE)
ids <- sapply(manifesto$cartoes, function(x) x$id_recuperacao)
stopifnot(!anyDuplicated(ids), length(ids) > 0L)
numero_pessoas <- sapply(manifesto$cartoes, function(x) x$n_pessoas)
ufs_piloto <- sapply(manifesto$cartoes, function(x) x$UF)
elegiveis <- which(numero_pessoas >= 2L & numero_pessoas <= 4L)
if(!length(elegiveis)) elegiveis <- seq_along(ids)
indice_piloto <- elegiveis[order(ufs_piloto[elegiveis] != "40", numero_pessoas[elegiveis], ids[elegiveis])][1L]
regra_piloto <- manifesto$cartoes[[indice_piloto]]
linhas_piloto <- sort(as.integer(sapply(regra_piloto$pessoas, function(x) x$linha)))
n_piloto <- length(linhas_piloto)
message("Piloto aprovado selecionado: ", regra_piloto$id_recuperacao, "; pessoas: ", n_piloto)

# Fixture sintetico testa so o bloqueio anterior a geografia/compilacao.
# A UF ficticia serve para escolher o ramo127; nao modifica nenhum dado real.
ambiente_compilacao <- new.env(parent = globalenv())
sys.source("R/microdata_1960.R", envir = ambiente_compilacao, keep.source = FALSE)
ambiente_compilacao$UF_1960_AMOSTRA_25 <- c(mg = 40L)
fixture_guarda <- data.table(UF = 1L, censobr_familia_origem = "recuperada_25")
fixture_paths <- file.path(saida, c("fixture_guarda_pessoas.parquet", "fixture_guarda_domicilios.parquet"))
for(path in fixture_paths) write_parquet(fixture_guarda, path)
erro <- tryCatch(ambiente_compilacao$compile_1960(paths_25 = character(), paths_127 = fixture_paths,
  estratos = NULL, unidade = "ac", municipios_path = "nao_deve_ser_lido",
  definitivos_path = "nao_deve_ser_lido", out_dir = file.path(saida, "compilacao_proibida")), error = identity)
stopifnot(inherits(erro, "error"), grepl("procedencia no esquema final", conditionMessage(erro), fixed = TRUE),
          !dir.exists(file.path(saida, "compilacao_proibida")))

# A leitura e por blocos, mas os localizadores continuam os de HHOLDA.
lote_recuperacao_127 <- function(alvos){
  alvos <- sort(unique(as.integer(alvos)))
  stopifnot(length(alvos) > 0L, !anyNA(alvos), all(alvos > 0L))
  con <- file(raw_path, open = "rt", encoding = "latin1")
  on.exit(close(con))
  texto <- character(length(alvos)); inicio <- 0L
  while(inicio < max(alvos)){
    trecho <- readLines(con, n = 10000L, warn = FALSE)
    stopifnot(length(trecho) > 0L)
    selecionadas <- which(alvos > inicio & alvos <= inicio + length(trecho))
    texto[selecionadas] <- trecho[alvos[selecionadas] - inicio]
    inicio <- inicio + length(trecho)
  }
  stopifnot(all(nchar(texto) == 62L))
  path <- tempfile("lote_", tmpdir = saida, fileext = ".txt")
  writeLines(texto, path, useBytes = TRUE)
  linhas <- read_1960_amostra_127(path)
  linhas[, linha := alvos]
  linhas <- apply_corrections_1960_amostra_127(linhas, "read_guides/1960_amostra_127_correcoes.csv")
  parse_1960_amostra_127(linhas, "read_guides/readguide_1960_amostra_127_familias.csv",
                        "read_guides/readguide_1960_amostra_127_pessoas.csv")
}

exigir_erro_recuperacao <- function(entrada, nome, path = manifesto_path){
  antes <- copy(entrada)
  erro <- tryCatch(recover_family_cards_1960_amostra_127(entrada, path, file.path(saida, nome)),
                   error = identity)
  stopifnot(inherits(erro, "error"), identical(entrada, antes))
  message("Bloqueio confirmado: ", nome, " — ", conditionMessage(erro))
  invisible(conditionMessage(erro))
}

# O exemplo inicial MG004 permanece pendente se a auditoria nao o aprovou.
if(!"40-40090-004" %in% ids){
  mg_pendente <- lote_recuperacao_127(491756:491757)
  mg_depois <- recover_family_cards_1960_amostra_127(mg_pendente, manifesto_path, file.path(saida, "mg_004_pendente"))
  stopifnot(identical(mg_depois, mg_pendente), nrow(mg_depois$familias) == 0L, nrow(mg_depois$pessoas) == 2L)
  erro <- tryCatch(build_families_1960_amostra_127(mg_depois, file.path(saida, "mg_004_sem_vinculo")), error = identity)
  stopifnot(inherits(erro, "error"), grepl("vinculos_a_revisar", conditionMessage(erro), fixed = TRUE))
  message("MG40090/004 continua pendente: duas pessoas preservadas, nenhum cartao acrescentado.")
}

# Testar somente uma decisao efetivamente aprovada, sem impor o exemplo inicial.
piloto <- lote_recuperacao_127(linhas_piloto)
antes <- copy(piloto)
stopifnot(nrow(piloto$familias) == 0L, nrow(piloto$pessoas) == n_piloto,
          all(piloto$pessoas$pasta == regra_piloto$pasta), all(piloto$pessoas$boletim == regra_piloto$boletim))
recuperado <- recover_family_cards_1960_amostra_127(piloto, manifesto_path, file.path(saida, "piloto"))
origem_cols <- c("censobr_cartao_recuperado_id", "censobr_cartao_fonte", "censobr_cartao_arquivo",
                 "censobr_cartao_linha", "censobr_cartao_sha256", "censobr_cartao_unidade")
stopifnot(identical(piloto, antes), identical(recuperado$pessoas, antes$pessoas),
          nrow(recuperado$familias) == 1L, all(origem_cols %in% names(recuperado$familias)),
          is.na(recuperado$familias$linha), is.na(recuperado$familias$id_arquivo),
          is.na(recuperado$familias$texto_original), is.na(recuperado$familias$texto_corrigido),
          recuperado$familias$censobr_ordem_cartao == min(linhas_piloto) - 0.5,
          recuperado$familias$censobr_cartao_linha == regra_piloto$linha_25,
          recuperado$familias$censobr_cartao_unidade == if(regra_piloto$familias$V101 == "3") "boletim_coletivo" else "boletim_particular",
          recuperado$familias$V101 == regra_piloto$familias$V101,
          recuperado$familias$censobr_familia_origem == "recuperada_25",
          !is.na(recuperado$familias$censobr_cartao_recuperado_id),
          nzchar(recuperado$familias$censobr_cartao_recuperado_id))
ligado <- build_families_1960_amostra_127(recuperado, file.path(saida, "piloto_vinculado"))
stopifnot(nrow(ligado$pessoas) == n_piloto, nrow(ligado$familias) == 1L,
          uniqueN(ligado$pessoas$censobr_idfamily) == 1L,
          uniqueN(ligado$pessoas$censobr_idhousehold) == 1L,
          all(ligado$pessoas$censobr_idfamily == ligado$familias$censobr_idfamily),
          all(ligado$pessoas$censobr_familia_origem == "recuperada_25"),
          all(origem_cols %in% names(ligado$pessoas)),
          identical(as.data.frame(ligado$pessoas[, names(antes$pessoas), with = FALSE]),
                    as.data.frame(antes$pessoas)))
for(col in origem_cols) stopifnot(all(ligado$pessoas[[col]] == ligado$familias[[col]]))

# Um lote parcial ou com pessoa adicional nao representa a composicao aprovada.
faltante <- copy(piloto); faltante$pessoas <- faltante$pessoas[-1L]
exigir_erro_recuperacao(faltante, "pessoa_faltante")
excedente <- copy(piloto)
excedente$pessoas <- rbind(excedente$pessoas, copy(excedente$pessoas[1L])[, linha := 1074329L])
exigir_erro_recuperacao(excedente, "pessoa_excedente")
for(col in c("texto_original", "texto_corrigido", "chave", "V116", "V118", "distrito", "pasta", "boletim", "V202",
             "tipo", "id_arquivo", "censobr_diagnostico", "censobr_variaveis_anuladas")){
  alterado <- copy(piloto)
  set(alterado$pessoas, i = 1L, j = col, value = "ADULTERADO")
  exigir_erro_recuperacao(alterado, paste0("pessoa_alterada_", col))
}
existente <- copy(piloto)
existente$familias <- copy(recuperado$familias)[, `:=`(linha = 1074331L, id_arquivo = "TESTE")]
exigir_erro_recuperacao(existente, "cartao_ja_existente")
exigir_erro_recuperacao(recuperado, "replay_sem_duplicar_cartao")

# Um cartao recuperado nao autoriza anexar uma familia secundaria.
boletim_secundario <- if(regra_piloto$boletim == "999") "998" else "999"
secundaria <- copy(recuperado$familias)
secundaria[, `:=`(linha = 1074332L, id_arquivo = "TESTE", V101 = "4", boletim = boletim_secundario,
                   chave = paste0(distrito, pasta, boletim_secundario), censobr_ordem_cartao = 1074332,
                   censobr_familia_origem = "registro")]
for(col in origem_cols) set(secundaria, j = col, value = NA)
pessoa_secundaria <- copy(piloto$pessoas[1L])
pessoa_secundaria[, `:=`(linha = 1074333L, boletim = boletim_secundario, chave = paste0(distrito, pasta, boletim_secundario))]
entrada <- list(familias = rbind(recuperado$familias, secundaria, fill = TRUE),
                pessoas = rbind(piloto$pessoas, pessoa_secundaria))
erro <- tryCatch(build_families_1960_amostra_127(entrada, file.path(saida, "convivente")), error = identity)
stopifnot(inherits(erro, "error"), grepl("convivente", conditionMessage(erro), ignore.case = TRUE))

# Alterar uma copia do manifesto jamais muda os arquivos historicos.
gravar_manifesto_teste <- function(x, nome){
  path <- file.path(saida, paste0(nome, ".json"))
  write_json(x, path, auto_unbox = TRUE, pretty = TRUE, null = "null", na = "null", digits = NA)
  path
}
for(campo in c("texto_25", "linha_25", "n_pessoas", "UF", "V116", "V118", "distrito", "pasta", "boletim")){
  alterado <- manifesto
  alterado$cartoes[[indice_piloto]][[campo]] <- if(campo %in% c("linha_25", "n_pessoas")) -1L else "ADULTERADO"
  path <- gravar_manifesto_teste(alterado, paste0("manifesto_", campo))
  exigir_erro_recuperacao(piloto, paste0("manifesto_", campo), path)
}
for(campo in c("texto_original", "texto_corrigido", "texto_25", "linha", "linha_25")){
  alterado <- manifesto
  alterado$cartoes[[indice_piloto]]$pessoas[[1L]][[campo]] <- if(grepl("^linha", campo)) -1L else "ADULTERADO"
  path <- gravar_manifesto_teste(alterado, paste0("manifesto_pessoa_", campo))
  exigir_erro_recuperacao(piloto, paste0("manifesto_pessoa_", campo), path)
}
for(v in c("2", "4", "5", "9")){
  alterado <- manifesto
  alterado$cartoes[[indice_piloto]]$familias$V101 <- v
  path <- gravar_manifesto_teste(alterado, paste0("manifesto_V101_", v))
  exigir_erro_recuperacao(piloto, paste0("manifesto_V101_", v), path)
}
alterado <- manifesto
alterado$fontes[[1L]]$sha256 <- strrep("0", 64L)
exigir_erro_recuperacao(piloto, "hash_fonte_incorreto", gravar_manifesto_teste(alterado, "hash_incorreto"))
alterado <- manifesto
alterado$cartoes <- c(alterado$cartoes, alterado$cartoes[indice_piloto])
exigir_erro_recuperacao(piloto, "decisao_duplicada", gravar_manifesto_teste(alterado, "decisao_duplicada"))
alterado <- manifesto
alterado$cartoes[[indice_piloto]]$pessoas <- c(alterado$cartoes[[indice_piloto]]$pessoas,
                                             alterado$cartoes[[indice_piloto]]$pessoas[1L])
exigir_erro_recuperacao(piloto, "pessoa_repetida_manifesto", gravar_manifesto_teste(alterado, "pessoa_repetida_manifesto"))

# Sem decisao, o recuperador nao adivinha e o vinculador continua bloqueado.
vazio <- manifesto; vazio$cartoes <- list()
sem_decisao <- recover_family_cards_1960_amostra_127(piloto,
  gravar_manifesto_teste(vazio, "sem_decisao"), file.path(saida, "sem_decisao"))
stopifnot(identical(sem_decisao, piloto))
erro <- tryCatch(build_families_1960_amostra_127(sem_decisao, file.path(saida, "sem_decisao_build")), error = identity)
stopifnot(inherits(erro, "error"), grepl("vinculos_a_revisar", conditionMessage(erro), fixed = TRUE))

# Depois do piloto, conferir todas as decisoes sem reconstruir a amostra toda.
alvos <- as.integer(unlist(lapply(manifesto$cartoes, function(x) lapply(x$pessoas, function(p) p$linha))))
stopifnot(length(alvos) > 0L, !anyDuplicated(alvos))
amplo <- lote_recuperacao_127(alvos)
amplo_antes <- copy(amplo)
amplo_ok <- recover_family_cards_1960_amostra_127(amplo, manifesto_path, file.path(saida, "todos_recuperados"))
stopifnot(identical(amplo, amplo_antes), identical(amplo_ok$pessoas, amplo_antes$pessoas),
          nrow(amplo_ok$familias) == length(manifesto$cartoes),
          all(is.na(amplo_ok$familias$linha)), all(is.na(amplo_ok$familias$id_arquivo)),
          !anyDuplicated(amplo_ok$familias$censobr_cartao_recuperado_id),
          all(amplo_ok$familias$V101 %in% c("1", "3")))
todos_ligados <- build_families_1960_amostra_127(amplo_ok, file.path(saida, "todos_vinculados"))
stopifnot(nrow(todos_ligados$pessoas) == length(alvos),
          all(todos_ligados$pessoas$censobr_familia_origem == "recuperada_25"),
          uniqueN(todos_ligados$pessoas$censobr_idfamily) == length(ids),
          uniqueN(todos_ligados$pessoas$censobr_idhousehold) == length(ids))
for(i in seq_along(manifesto$cartoes)){
  decisao <- manifesto$cartoes[[i]]
  grupo <- todos_ligados$pessoas[censobr_cartao_recuperado_id == decisao$id_recuperacao]
  stopifnot(nrow(grupo) == decisao$n_pessoas,
            identical(sort(grupo$linha), sort(as.integer(sapply(decisao$pessoas, function(x) x$linha)))),
            all(grupo$censobr_cartao_linha == decisao$linha_25),
            all(grupo$censobr_cartao_arquivo == decisao$arquivo_25))
}

# A ordem do manifesto nao e informacao historica nem pode decidir vinculos.
invertido <- manifesto; invertido$cartoes <- rev(invertido$cartoes)
invertido_ok <- recover_family_cards_1960_amostra_127(amplo,
  gravar_manifesto_teste(invertido, "decisoes_invertidas"), file.path(saida, "decisoes_invertidas"))
stopifnot(identical(invertido_ok$pessoas, amplo_ok$pessoas),
          identical(as.data.frame(invertido_ok$familias[order(censobr_cartao_recuperado_id)]),
                    as.data.frame(amplo_ok$familias[order(censobr_cartao_recuperado_id)])))

# Reabrir a evidencia: localizador do cartao ausente, localizadores pessoais preservados.
write_parquet(todos_ligados$pessoas, file.path(saida, "pessoas_vinculadas.parquet"))
write_parquet(todos_ligados$familias, file.path(saida, "cartoes_recuperados.parquet"))
p_reabertas <- as.data.table(read_parquet(file.path(saida, "pessoas_vinculadas.parquet")))
f_reabertas <- as.data.table(read_parquet(file.path(saida, "cartoes_recuperados.parquet")))
stopifnot(nrow(p_reabertas) == length(alvos), nrow(f_reabertas) == length(ids),
          identical(sort(p_reabertas$linha), sort(alvos)), all(is.na(f_reabertas$linha)),
          all(is.na(f_reabertas$id_arquivo)),
          identical(as.data.frame(p_reabertas[, ..origem_cols]), as.data.frame(todos_ligados$pessoas[, ..origem_cols])),
          identical(as.data.frame(f_reabertas[, ..origem_cols]), as.data.frame(todos_ligados$familias[, ..origem_cols])))

# Contexto real: Paracatu/pasta40358, cartao391267 e pessoas391268:391269.
# Cartao e composicao coincidem com25; Paracatu e Cambui sao do grupo urbano menor.
contextos <- list("40-40654-177" = 391267:391269, "40-41514-157" = 391267:391269)
contexto_linhas <- contextos[[regra_piloto$id_recuperacao]]
if(is.null(contexto_linhas)) stop("Selecionar contexto real de segunda pasta antes de testar finalize: ", regra_piloto$id_recuperacao)
contexto <- lote_recuperacao_127(contexto_linhas)
n_contexto <- nrow(contexto$pessoas)
com_contexto <- lote_recuperacao_127(c(contexto_linhas, linhas_piloto))
stopifnot(nrow(com_contexto$familias) == 1L, nrow(com_contexto$pessoas) == n_piloto + n_contexto,
          all(com_contexto$pessoas$UF == regra_piloto$UF), uniqueN(com_contexto$pessoas$pasta) == 2L)
com_contexto <- recover_family_cards_1960_amostra_127(com_contexto, manifesto_path, file.path(saida, "contexto"))
com_contexto <- build_families_1960_amostra_127(com_contexto, file.path(saida, "contexto_vinculado"))
final <- finalize_1960_amostra_127(com_contexto, "read_guides/1960_municipios.csv", "read_guides/1960_distritos.csv")
dom_recuperado <- final$domicilios[censobr_cartao_recuperado_id %in% regra_piloto$id_recuperacao]
pes_recuperadas <- final$pessoas[linha %in% linhas_piloto]
stopifnot(nrow(final$pessoas) == n_piloto + n_contexto, nrow(final$domicilios) == 2L,
          uniqueN(final$domicilios$censobr_upa) == 2L,
          nrow(dom_recuperado) == 1L, nrow(pes_recuperadas) == n_piloto,
          is.na(dom_recuperado$linha), is.na(dom_recuperado$id_arquivo),
          dom_recuperado$V101 == as.integer(regra_piloto$familias$V101),
          dom_recuperado$censobr_cartao_linha == regra_piloto$linha_25,
          dom_recuperado$censobr_cartao_unidade == regra_piloto$unidade,
          dom_recuperado$censobr_n_listadas == n_piloto,
          dom_recuperado$censobr_n_residentes == sum(!piloto$pessoas$V202 %in% c("5", "6")),
          dom_recuperado$censobr_n_presentes == sum(!piloto$pessoas$V202 %in% c("3", "4")),
          all(pes_recuperadas$censobr_familia_origem == "recuperada_25"),
          all(final$pessoas$censobr_weight == 1 / 0.0127),
          all(final$domicilios$censobr_weight == 1 / 0.0127),
          final$domicilios[linha %in% contexto$familias$linha, .N] == 1L)
for(var in paste0("V", 101:113)){
  valor <- regra_piloto$familias[[var]]
  esperado <- if(is.null(valor)) NA_integer_ else as.integer(valor)
  stopifnot(identical(dom_recuperado[[var]], esperado))
}
for(col in origem_cols) stopifnot(all(pes_recuperadas[[col]] == dom_recuperado[[col]]))
write_parquet(final$pessoas, file.path(saida, "piloto_final_pessoas.parquet"))
write_parquet(final$domicilios, file.path(saida, "piloto_final_domicilios.parquet"))
final_p_reaberto <- as.data.table(read_parquet(file.path(saida, "piloto_final_pessoas.parquet")))
final_d_reaberto <- as.data.table(read_parquet(file.path(saida, "piloto_final_domicilios.parquet")))
stopifnot(nrow(final_p_reaberto) == n_piloto + n_contexto, nrow(final_d_reaberto) == 2L,
          identical(as.data.frame(final_p_reaberto[, ..origem_cols]), as.data.frame(final$pessoas[, ..origem_cols])),
          identical(as.data.frame(final_d_reaberto[, ..origem_cols]), as.data.frame(final$domicilios[, ..origem_cols])),
          is.na(final_d_reaberto[censobr_cartao_recuperado_id %in% regra_piloto$id_recuperacao, linha]))

fwrite(ligado$pessoas, file.path(saida, "piloto_pessoas.csv"), bom = TRUE)
fwrite(ligado$familias, file.path(saida, "piloto_cartao.csv"), bom = TRUE)
stopifnot(identical(hash_antes, digest(file = raw_path, algo = "sha256")))
message("Piloto, manifesto completo e ataques aprovados; evidencia em ", saida)
