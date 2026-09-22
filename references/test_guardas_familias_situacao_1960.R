# Cartao vazio e conflito de situacao: registros reais e variantes identificadas.
.libPaths(c("renv/library/windows/R-4.5/x86_64-w64-mingw32", .libPaths()))
Sys.setlocale("LC_CTYPE", "Portuguese_Brazil.utf8")
library(data.table)
library(jsonlite)
library(digest)
setDTthreads(1L)
source("R/microdata_1960_amostra_127.R", encoding = "UTF-8")

base_guardas <- "tmp/fechamento_registros_1960_20260922"
dir.create(base_guardas, recursive = TRUE, showWarnings = FALSE)
saida_guardas <- tempfile("familias_situacao_", tmpdir = base_guardas)
dir.create(saida_guardas)
alvos_guardas <- c(142520:142529, 391267:391269, 780535L)
raw_guardas <- "data_raw/microdata/1960/amostra_127/HHOLDA.txt"
hash_guardas <- digest(file = raw_guardas, algo = "sha256")
con <- file(raw_guardas, "rb")
texto_guardas <- character(length(alvos_guardas))
for(i in seq_along(alvos_guardas)){
  seek(con, where = (alvos_guardas[i] - 1) * 64, origin = "start")
  texto_guardas[i] <- readChar(con, 62L, useBytes = TRUE)
}
close(con)
path_guardas <- file.path(saida_guardas, "microlote.txt")
writeLines(texto_guardas, path_guardas, useBytes = TRUE)
linhas_guardas <- read_1960_amostra_127(path_guardas)
linhas_guardas[, linha := alvos_guardas]
linhas_guardas <- apply_corrections_1960_amostra_127(linhas_guardas,
  "read_guides/1960_amostra_127_correcoes.csv")
entrada_guardas <- parse_1960_amostra_127(linhas_guardas,
  "read_guides/readguide_1960_amostra_127_familias.csv",
  "read_guides/readguide_1960_amostra_127_pessoas.csv")
controle_guardas <- list(familias = entrada_guardas$familias[linha == 391267L],
                        pessoas = entrada_guardas$pessoas[linha %in% 391268:391269])
controle_antes <- copy(controle_guardas)
controle_ok <- build_families_1960_amostra_127(controle_guardas, file.path(saida_guardas, "controle"))
stopifnot(identical(controle_guardas, controle_antes), nrow(controle_ok$familias) == 1L,
          nrow(controle_ok$pessoas) == 2L)

# A decisao real confirma o vinculo, sem converter a situacao urbana da pessoa em rural.
situacao_guardas <- list(familias = entrada_guardas$familias[linha == 142520L],
                        pessoas = entrada_guardas$pessoas[linha %in% 142521:142529])
stopifnot(situacao_guardas$familias$V118 == "5",
          situacao_guardas$pessoas[linha == 142523L, V118] == "1")
situacao_antes <- copy(situacao_guardas)
situacao_ok <- build_families_1960_amostra_127(situacao_guardas,
  file.path(saida_guardas, "situacao_aprovada"))
stopifnot(identical(situacao_guardas, situacao_antes), nrow(situacao_ok$pessoas) == 9L,
          situacao_ok$pessoas[linha == 142523L, V118] == "1",
          situacao_ok$familias$V118 == "5",
          situacao_ok$pessoas[linha == 142523L, censobr_familia_origem] == "reconciliada_25")
cols_guardas <- names(situacao_guardas$pessoas)
stopifnot(identical(as.data.frame(situacao_ok$pessoas[, ..cols_guardas]),
                    as.data.frame(situacao_guardas$pessoas)))

dec_guardas <- as.data.table(read.csv("read_guides/1960_amostra_127_vinculos.csv",
  colClasses = "character", fileEncoding = "UTF-8-BOM"))
sem_decisao_path <- file.path(saida_guardas, "vinculos_sem_142523.csv")
write.csv(dec_guardas[linha != "142523"], sem_decisao_path, row.names = FALSE, fileEncoding = "UTF-8")

# Registrar todas as lacunas antes de falhar, permitindo conferir o estado anterior ao patch.
resultados_guardas <- logical()
verificar_bloqueio <- function(nome, entrada, padrao, funcao, arquivo = NULL, linhas = integer()){
  antes <- copy(entrada)
  resultado <- tryCatch(funcao(entrada), error = identity)
  passou <- inherits(resultado, "error") && grepl(padrao, conditionMessage(resultado), fixed = TRUE)
  stopifnot(identical(antes, entrada))
  if(passou && !is.null(arquivo)){
    stopifnot(file.exists(arquivo))
    relatorio <- fread(arquivo)
    stopifnot(setequal(relatorio$linha, linhas))
  }
  message(nome, ": ", if(passou) "bloqueado corretamente" else "GUARDA AUSENTE OU DIVERGENTE",
          if(inherits(resultado, "error")) paste0(" - ", conditionMessage(resultado)) else "")
  passou
}

com_vazio <- copy(controle_guardas)
com_vazio$familias <- rbind(com_vazio$familias, entrada_guardas$familias[linha == 780535L])
resultados_guardas["cartao_vazio"] <- verificar_bloqueio("cartao_vazio", com_vazio,
  "cartao familiar sem pessoas", function(x) build_families_1960_amostra_127(x,
    file.path(saida_guardas, "vazio")),
  file.path(saida_guardas, "vazio", "cartoes_sem_pessoas_a_revisar.csv"), 780535L)

resultados_guardas["situacao_sem_decisao"] <- verificar_bloqueio("situacao_sem_decisao", situacao_guardas,
  "situacao divergente ou ausente", function(x) build_families_1960_amostra_127(x,
    file.path(saida_guardas, "situacao"), sem_decisao_path),
  file.path(saida_guardas, "situacao", "vinculos_situacao_a_revisar.csv"), 142523L)

for(lado in c("pessoas", "familias")){
  ausente <- copy(situacao_guardas)
  ausente[[lado]][linha == if(lado == "pessoas") 142523L else 142520L, V118 := NA_character_]
  nome <- paste0("situacao_ausente_", lado)
  resultados_guardas[nome] <- verificar_bloqueio(nome, ausente,
    "situacao divergente ou ausente", function(x) build_families_1960_amostra_127(x,
      file.path(saida_guardas, nome), sem_decisao_path))
}

# Entrada antiga que ja tenha IDs nao contorna a mesma guarda ao finalizar.
retro <- copy(controle_ok)
vazio_retro <- copy(entrada_guardas$familias[linha == 780535L])
vazio_retro[, `:=`(censobr_idfamily = 2L, censobr_idhousehold = 2L,
                   censobr_familia_origem = "registro", censobr_uf_corrigida = FALSE,
                   censobr_convivente_isolada = FALSE, censobr_dois_chefes = FALSE)]
retro$familias <- rbind(retro$familias, vazio_retro, fill = TRUE)
resultados_guardas["finalizacao_cartao_vazio"] <- verificar_bloqueio("finalizacao_cartao_vazio", retro,
  "cartao familiar sem pessoas", function(x) finalize_1960_amostra_127(x,
    "NAO_DEVE_SER_LIDO", "NAO_DEVE_SER_LIDO"))

write_json(as.list(resultados_guardas), file.path(saida_guardas, "conferencia.json"),
  auto_unbox = TRUE, pretty = TRUE)
stopifnot(hash_guardas == digest(file = raw_guardas, algo = "sha256"))
stopifnot(all(resultados_guardas))
message("Cartao vazio e situacao: guardas e respostas conferidas em ", saida_guardas)
