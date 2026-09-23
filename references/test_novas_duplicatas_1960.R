# Teste dos conjuntos decididos, nao da base inteira. Executar somente pelo
# runner references/rodar_r_isolado_1960.py, com --windows-arch --locale-c.
.libPaths(c("renv/library/windows/R-4.5/x86_64-w64-mingw32", .libPaths()))
Sys.setlocale("LC_CTYPE", "Portuguese_Brazil.utf8")
library(data.table)
library(digest)
library(arrow)
library(jsonlite)
setDTthreads(1L)
source("R/microdata_1960_amostra_127.R", encoding = "UTF-8")
source("references/ler_fixtures_registros_1960.R", encoding = "UTF-8")
fixture_path <- "references/fechamento_registros_1960_evidencias/fixtures_decisoes.json"
fixture <- carregar_fixture_registros_1960(fixture_path)

raiz_saida <- "tmp/fechamento_registros_1960_20260922/duplicatas"
dir.create(raiz_saida, recursive = TRUE, showWarnings = FALSE)
saida <- tempfile("teste_r_", tmpdir = raiz_saida)
dir.create(saida)
raw_path <- "data_raw/microdata/1960/amostra_127/HHOLDA.txt"
historico_path <- "data_raw/microdata/1960/amostra_127/duplicatas_removidas.csv"
producao_path <- "read_guides/1960_amostra_127_duplicatas.csv"
correcoes_path <- "read_guides/1960_amostra_127_correcoes.csv"
fontes_preservadas <- c(raw_path, historico_path, producao_path, correcoes_path,
  fixture_path,
  "data_raw/microdata/1960/amostra_127/pessoas_1960_amostra_127.parquet",
  "data_raw/microdata/1960/amostra_127/domicilios_1960_amostra_127.parquet",
  "read_guides/readguide_1960_amostra_127_familias.csv",
  "read_guides/readguide_1960_amostra_127_pessoas.csv",
  "read_guides/1960_amostra_127_reparos_fonte25.json")
stopifnot(all(file.exists(fontes_preservadas)))
hash_antes <- sapply(fontes_preservadas, function(path) digest(file = path, algo = "sha256"))

# A mesma suite serve antes e depois da promocao dos candidatos: sobreposicoes
# precisam concordar em acao, quantidade e textos; nao acrescentar outra copia.
manifesto <- as.data.table(read.csv(producao_path, colClasses = "character",
  strip.white = FALSE, fileEncoding = "UTF-8", stringsAsFactors = FALSE))
candidatos <- tabela_fixture_registros_1960(fixture, "duplicatas954")
stopifnot(!anyDuplicated(manifesto$linha), !anyDuplicated(candidatos$linha),
          nrow(candidatos) == 1908L, uniqueN(candidatos$grupo) == 954L,
          sum(candidatos$acao == "remover") == 490L,
          setequal(names(manifesto), names(candidatos)))
comuns <- intersect(manifesto$linha, candidatos$linha)
campos_decisao <- c("acao", "n_antes", "n_manter", "texto_original", "texto_corrigido")
for(campo in campos_decisao){
  stopifnot(identical(manifesto[[campo]][match(comuns, manifesto$linha)],
                      candidatos[[campo]][match(comuns, candidatos$linha)]))
}
novos <- candidatos[!linha %in% manifesto$linha]
manifesto <- rbindlist(list(manifesto, novos), use.names = TRUE)
setorder(manifesto, linha)
stopifnot(nrow(manifesto) == 6463L, !anyDuplicated(manifesto$linha),
          sum(manifesto$acao == "remover") == 2736L,
          sum(manifesto$acao == "manter") == 3727L,
          all(manifesto$acao %in% c("manter", "remover")))
decisoes_path <- file.path(saida, "manifesto_conciliado.csv")
write.csv(as.data.frame(manifesto), decisoes_path, row.names = FALSE,
          fileEncoding = "UTF-8", na = "")
message("Manifesto temporario: 6463 linhas; 2736 remover; 3727 manter; sobrepostas: ", length(comuns))

# Ler os literais de HHOLDA em blocos. Os numeros de linha continuam sendo os
# localizadores originais, mesmo quando o arquivo temporario tem so duas linhas.
lote_novas_duplicatas_1960 <- function(alvos){
  alvos <- sort(unique(as.integer(alvos)))
  stopifnot(length(alvos) > 0L, !anyNA(alvos), all(alvos > 0L))
  con <- file(raw_path, open = "rt", encoding = "latin1")
  on.exit(close(con))
  texto <- character(length(alvos)); inicio <- 0L
  while(inicio < max(alvos)){
    trecho <- readLines(con, n = 10000L, warn = FALSE)
    stopifnot(length(trecho) > 0L)
    idx <- which(alvos > inicio & alvos <= inicio + length(trecho))
    texto[idx] <- trecho[alvos[idx] - inicio]
    inicio <- inicio + length(trecho)
  }
  stopifnot(all(nchar(texto) == 62L))
  path <- tempfile("lote_", tmpdir = saida, fileext = ".txt")
  writeLines(texto, path, useBytes = TRUE)
  linhas <- read_1960_amostra_127(path)
  linhas[, linha := alvos]
  linhas <- apply_corrections_1960_amostra_127(linhas, correcoes_path)
  tabelas <- parse_1960_amostra_127(linhas,
    "read_guides/readguide_1960_amostra_127_familias.csv",
    "read_guides/readguide_1960_amostra_127_pessoas.csv")
  stopifnot(nrow(tabelas$pessoas) == length(alvos), nrow(tabelas$familias) == 0L,
            identical(tabelas$pessoas$linha, alvos),
            identical(tabelas$pessoas$texto_original, texto))
  tabelas
}

# Dois filhos de cinco anos, com respostas iguais e dois registros na fonte25.
piloto <- lote_novas_duplicatas_1960(c(164631L, 164633L))
antes <- copy(piloto)
piloto_ok <- dedup_1960_amostra_127(piloto, file.path(saida, "piloto"),
                                  decisoes_path = decisoes_path)
colunas_originais <- names(antes$pessoas)
stopifnot(identical(piloto, antes), nrow(piloto_ok$pessoas) == 2L,
          identical(piloto_ok$pessoas$linha, c(164631L, 164633L)),
          all(piloto_ok$pessoas$AGE == "05"), all(piloto_ok$pessoas$V203 == "9"),
          identical(as.data.frame(piloto_ok$pessoas[, .SD, .SDcols = colunas_originais]),
                    as.data.frame(antes$pessoas)),
          nrow(fread(file.path(saida, "piloto", "duplicatas_removidas.csv"))) == 0L)
message("Piloto aprovado: linhas 164631 e 164633 mantidas; dois filhos de cinco anos.")

# Erros precisam interromper a etapa sem modificar a entrada ou excluir pessoas.
incompleto <- copy(piloto)
incompleto$pessoas <- incompleto$pessoas[1L]
antes_incompleto <- copy(incompleto)
erro <- tryCatch(dedup_1960_amostra_127(incompleto, file.path(saida, "incompleto"),
  decisoes_path = decisoes_path), error = identity)
stopifnot(inherits(erro, "error"), grepl("grupo de decisao incompleto", conditionMessage(erro), fixed = TRUE),
          identical(incompleto, antes_incompleto),
          !file.exists(file.path(saida, "incompleto", "duplicatas_removidas.csv")))
message("Bloqueio aprovado: grupo incompleto.")
for(campo in c("texto_original", "texto_corrigido")){
  adulterado <- copy(piloto)
  set(adulterado$pessoas, i = 1L, j = campo,
      value = paste0("00", substr(adulterado$pessoas[[campo]][1L], 3, 62)))
  antes_adulterado <- copy(adulterado)
  destino <- file.path(saida, paste0("adulterado_", campo))
  erro <- tryCatch(dedup_1960_amostra_127(adulterado, destino,
    decisoes_path = decisoes_path), error = identity)
  stopifnot(inherits(erro, "error"), grepl("conteudo diverge", conditionMessage(erro), fixed = TRUE),
            identical(adulterado, antes_adulterado),
            !file.exists(file.path(destino, "duplicatas_removidas.csv")))
  message("Bloqueio aprovado: ", campo, " adulterado.")
}

# Somente apos o piloto, examinar todas as linhas abrangidas pelas decisoes.
amplo <- lote_novas_duplicatas_1960(as.integer(manifesto$linha))
antes_amplo <- copy(amplo)
amplo_ok <- dedup_1960_amostra_127(amplo, file.path(saida, "todos_decididos"),
                                 decisoes_path = decisoes_path)
manter <- sort(as.integer(manifesto$linha[manifesto$acao == "manter"]))
remover <- sort(as.integer(manifesto$linha[manifesto$acao == "remover"]))
colunas_originais <- names(antes_amplo$pessoas)
esperadas <- antes_amplo$pessoas[match(manter, linha)]
retidas_originais <- amplo_ok$pessoas[, .SD, .SDcols = colunas_originais]
setorder(retidas_originais, linha)
diagnostico <- fread(file.path(saida, "todos_decididos", "duplicatas_removidas.csv"))
stopifnot(identical(amplo, antes_amplo), nrow(amplo$pessoas) == 6463L,
          nrow(amplo_ok$pessoas) == 3727L, identical(sort(amplo_ok$pessoas$linha), manter),
          nrow(diagnostico) == 2736L, identical(sort(diagnostico$linha), remover),
          identical(as.data.frame(retidas_originais), as.data.frame(esperadas)),
          identical(amplo_ok$familias, antes_amplo$familias),
          nrow(fread(file.path(saida, "todos_decididos", "duplicatas_a_revisar.csv"))) == 0L)

# Verificar explicitamente cada acao, sem inferir sucesso apenas dos totais.
conferencia <- copy(manifesto)
conferencia[, linha := as.integer(linha)]
setorder(conferencia, linha)
conferencia[, `:=`(retida_observada = linha %in% amplo_ok$pessoas$linha,
                   removida_observada = linha %in% diagnostico$linha)]
stopifnot(all(conferencia$retida_observada == (conferencia$acao == "manter")),
          all(conferencia$removida_observada == (conferencia$acao == "remover")),
          all(xor(conferencia$retida_observada, conferencia$removida_observada)))
conferencia[, V216_antes := antes_amplo$pessoas$V216[match(linha, antes_amplo$pessoas$linha)]]
conferencia[, V216_depois := amplo_ok$pessoas$V216[match(linha, amplo_ok$pessoas$linha)]]
stopifnot(identical(conferencia[retida_observada == TRUE, V216_antes],
                    conferencia[retida_observada == TRUE, V216_depois]))

# Estas tres linhas estavam no registro historico de exclusoes. As fontes
# demonstram duas ocorrencias, portanto a nova decisao conserva os dois registros.
historico <- fread(historico_path)
restauracoes <- c(211049L, 392256L, 217736L)
stopifnot(all(restauracoes %in% historico$linha), all(restauracoes %in% manter),
          all(restauracoes %in% amplo_ok$pessoas$linha), !any(restauracoes %in% remover))
for(linha_restaurada in restauracoes){
  grupo_restaurado <- manifesto$grupo[match(as.character(linha_restaurada), manifesto$linha)]
  linhas_grupo <- as.integer(manifesto$linha[manifesto$grupo == grupo_restaurado])
  stopifnot(length(linhas_grupo) == 2L,
            all(linhas_grupo %in% amplo_ok$pessoas$linha),
            all(manifesto$acao[manifesto$grupo == grupo_restaurado] == "manter"))
  message("Restauracao conferida: linha ", linha_restaurada, "; grupo ", grupo_restaurado,
          "; duas ocorrencias mantidas, nenhuma resposta alterada.")
}
stopifnot(amplo_ok$pessoas[linha == 217736L, V204] == "9",
          amplo_ok$pessoas[linha == 217736L, AGE] == "99")

# Inverter tanto o manifesto quanto a entrada nao pode mudar as decisoes.
ordem_path <- file.path(saida, "manifesto_ordem_invertida.csv")
write.csv(as.data.frame(manifesto[nrow(manifesto):1L]), ordem_path, row.names = FALSE,
          fileEncoding = "UTF-8", na = "")
invertido <- list(familias = copy(amplo$familias), pessoas = copy(amplo$pessoas[nrow(amplo$pessoas):1L]))
antes_invertido <- copy(invertido)
invertido_ok <- dedup_1960_amostra_127(invertido, file.path(saida, "ordem_invertida"),
                                     decisoes_path = ordem_path)
stopifnot(identical(invertido, antes_invertido),
          identical(as.data.frame(invertido_ok$pessoas), as.data.frame(amplo_ok$pessoas)),
          identical(sort(fread(file.path(saida, "ordem_invertida", "duplicatas_removidas.csv"))$linha), remover))
message("Ordem invertida aprovada: mesmas retencoes, exclusoes, respostas e marcas.")

# Parquets auxiliares contem apenas linhas decididas; nao sao a base reconstruida.
arquivos_saida <- file.path(saida, c("entrada_6463.parquet", "retidas_3727.parquet",
  "removidas_2736.parquet", "acoes_conferidas_6463.parquet"))
removidas_integrais <- antes_amplo$pessoas[match(remover, linha)]
write_parquet(antes_amplo$pessoas, arquivos_saida[1L], compression = "zstd")
write_parquet(amplo_ok$pessoas, arquivos_saida[2L], compression = "zstd")
write_parquet(removidas_integrais, arquivos_saida[3L], compression = "zstd")
write_parquet(conferencia, arquivos_saida[4L], compression = "zstd")
tabelas_esperadas <- list(antes_amplo$pessoas, amplo_ok$pessoas, removidas_integrais, conferencia)
for(i in seq_along(arquivos_saida)){
  reaberta <- as.data.frame(read_parquet(arquivos_saida[i]))
  stopifnot(identical(reaberta, as.data.frame(tabelas_esperadas[[i]])))
}
hash_depois <- sapply(fontes_preservadas, function(path) digest(file = path, algo = "sha256"))
stopifnot(identical(hash_antes, hash_depois), identical(amplo, antes_amplo))
indice <- list(
  escopo = "Somente linhas com decisao; nao reconstrucao integral nem pesos.",
  entrada = 6463L, retidas = 3727L, removidas = 2736L,
  novas_decisoes = 1908L, novos_grupos = 954L, novas_remocoes = 490L,
  restauracoes_contra_regra_antiga = restauracoes,
  acoes_individuais_conferidas = TRUE, respostas_e_V216_preservados = TRUE,
  entrada_preservada = TRUE, ordem_independente = TRUE,
  negativos = c("grupo_incompleto", "texto_original_adulterado", "texto_corrigido_adulterado"),
  manifesto_temporario = decisoes_path,
  fontes_preservadas = data.frame(arquivo = fontes_preservadas, sha256 = unname(hash_depois)),
  arquivos = data.frame(arquivo = arquivos_saida,
    sha256 = sapply(arquivos_saida, function(path) digest(file = path, algo = "sha256"))))
write_json(indice, file.path(saida, "indice_conferencia.json"), auto_unbox = TRUE, pretty = TRUE)
message("Conferencia aprovada: 6463 entradas, 3727 retidas, 2736 removidas; todas as acoes verificadas.")
message("Saidas auxiliares: ", saida)
