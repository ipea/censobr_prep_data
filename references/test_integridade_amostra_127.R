# Testes isolados, sem targets, downloads ou escrita nos dados de producao.
# Execucao autorizada e conferida em 22/09/2026; usar o runner isolado
# references/rodar_r_isolado_1960.py, nao R/targets diretamente.
.libPaths(c("renv/library/windows/R-4.5/x86_64-w64-mingw32", .libPaths()))
Sys.setlocale("LC_CTYPE", "Portuguese_Brazil.utf8")
library(data.table)
setDTthreads(1L)
source("R/microdata_1960_amostra_127.R", encoding = "UTF-8")

dir.create("tmp", showWarnings = FALSE)
saida <- tempfile("integridade_127_", tmpdir = "tmp")
dir.create(saida)

familias <- data.table(linha = 1L, id_arquivo = "1", UF = "19", V116 = "1901",
                      distrito = "01", pasta = "19124", boletim = "166", chave = "0119124166",
                      V101 = "1", V118 = "1")
pessoas <- data.table(linha = 2:3, id_arquivo = "1", UF = "19", V116 = "1901",
                     distrito = "01", pasta = "19124", boletim = "166", chave = "0119124166",
                     tipo = "3", V203 = "9", AGE = "99", V204 = "9", V202 = c("1", "2"), V118 = "1",
                     censobr_diagnostico = "sem_problema", censobr_variaveis_anuladas = "")

# Este fixture e sintetico, nao uma transcricao de HHOLDA. A conferencia de
# familias inteiras exige o esquema completo: os quesitos que nao participam
# deste cenario ficam explicitamente ausentes, sem simular texto corrompido ou
# desativar a guarda. Os dois perfis originais continuam distintos por V202.
campos_fixture_pessoas <- c("V202", "V203", "V204", "AGE", "V205", "V206", "V207", "V208",
  "V209", "V299", "V210", "V211", "V212", "V213", "V214", "V215", "V216", "V217", "V218",
  "V219", "V220", "V221", "V223", "V223B", "V224")
for(campo in setdiff(campos_fixture_pessoas, names(pessoas))) pessoas[, (campo) := NA_character_]
for(campo in setdiff(paste0("V", 101:113), names(familias))) familias[, (campo) := NA_character_]
familias[, `:=`(censobr_diagnostico = "sem_problema", censobr_variaveis_anuladas = "")]
stopifnot(length(campos_fixture_pessoas) == 25L,
  all(campos_fixture_pessoas %in% names(pessoas)), all(paste0("V", 101:113) %in% names(familias)),
  identical(pessoas$V202, c("1", "2")), all(pessoas$AGE == "99"), all(pessoas$V204 == "9"))

# Dois pares de filhos de idade ignorada: perfis iguais nao autorizam excluir.
# Cada cenario conserva seus relatorios; nenhuma chamada reabre a saida de
# outra contraprova. Isso tambem evita disputa pela regravacao de arquivo recente.
saida_repetidas <- file.path(saida, "dedup_repetidas")
repetidas <- rbind(pessoas, copy(pessoas)[, linha := 4:5])
antes <- copy(repetidas)
erro <- tryCatch(dedup_1960_amostra_127(list(familias = familias, pessoas = repetidas), saida_repetidas),
                 error = function(e) conditionMessage(e))
stopifnot(is.character(erro), grepl("Deduplicacao suspensa", erro), identical(antes, repetidas),
          nrow(fread(file.path(saida_repetidas, "duplicatas_a_revisar.csv"))) == 2L,
          !file.exists(file.path(saida_repetidas, "duplicatas_removidas.csv")))

# Sem repeticoes, a salvaguarda nao bloqueia nem altera a cardinalidade.
limpas <- dedup_1960_amostra_127(list(familias = familias, pessoas = pessoas), file.path(saida, "dedup_limpas"))
stopifnot(nrow(limpas$pessoas) == 2L)
ligadas <- build_families_1960_amostra_127(limpas, file.path(saida, "build_limpas"))
stopifnot(all(ligadas$pessoas$censobr_idfamily == 1L),
          all(ligadas$pessoas$censobr_familia_origem == "registro"))

# Um boletim sem registro proprio nao pertence automaticamente ao anterior,
# nem quando a geografia coincide. Tambem cobre orfao antes da primeira familia.
for(linha_orfa in c(0L, 4L)){
  saida_orfa <- file.path(saida, paste0("orfa_", linha_orfa))
  orfa <- copy(pessoas[1])[, `:=`(linha = linha_orfa, boletim = "167", chave = "0119124167")]
  entrada <- rbind(pessoas, orfa)
  antes <- copy(entrada)
  erro <- tryCatch(build_families_1960_amostra_127(list(familias = familias, pessoas = entrada), saida_orfa),
                   error = function(e) conditionMessage(e))
  stopifnot(is.character(erro), grepl("Reconstrucao suspensa", erro), identical(antes, entrada),
            fread(file.path(saida_orfa, "vinculos_a_revisar.csv"))$linha == linha_orfa)
}

# A presenca de conjuge nao demonstra que um cartao se perdeu.
saida_orfa_conjuge <- file.path(saida, "orfa_conjuge")
orfa <- copy(pessoas[1])[, `:=`(linha = 4L, boletim = "167", chave = "0119124167", V203 = "8")]
entrada <- rbind(pessoas, orfa)
antes <- copy(entrada)
erro <- tryCatch(build_families_1960_amostra_127(list(familias = familias, pessoas = entrada), saida_orfa_conjuge),
                 error = function(e) conditionMessage(e))
stopifnot(is.character(erro), length(erro) == 1L, grepl("Reconstrucao suspensa", erro),
          identical(antes, entrada), nrow(fread(file.path(saida_orfa_conjuge, "vinculos_a_revisar.csv"))) == 1L)

# Familia secundaria nao atravessa pasta so porque a linha anterior e principal.
saida_convivente_pasta <- file.path(saida, "convivente_pasta")
principal <- copy(familias)[, V101 := "2"]
secundaria <- copy(familias)[, `:=`(linha = 4L, id_arquivo = "2", pasta = "19125",
                                    chave = "0119125166", V101 = "4")]
filha <- copy(pessoas[1])[, `:=`(linha = 5L, id_arquivo = "2", pasta = "19125", chave = "0119125166")]
erro <- tryCatch(build_families_1960_amostra_127(list(familias = rbind(principal, secundaria),
                                                    pessoas = rbind(pessoas, filha)), saida_convivente_pasta),
                 error = function(e) conditionMessage(e))
stopifnot(is.character(erro), grepl("familia convivente", erro),
          nrow(fread(file.path(saida_convivente_pasta, "conviventes_a_revisar.csv"))) == 1L)

# Chave de questionario igual nao autoriza atribuir outro municipio a pessoa.
familia_outro_muni <- copy(familias)[, V116 := "1902"]
erro <- tryCatch(build_families_1960_amostra_127(list(familias = familia_outro_muni,
                                                    pessoas = pessoas), file.path(saida, "municipio")),
                 error = function(e) conditionMessage(e))
stopifnot(is.character(erro), length(erro) == 1L, grepl("municipio.*vinculo direto", erro),
          nrow(fread(file.path(saida, "municipio", "vinculos_diretos_a_revisar.csv"))) == 2L)

# V101=4/5 sem principal compativel nao comprova domicilio independente.
familia_isolada <- copy(familias)[, V101 := "5"]
erro <- tryCatch(build_families_1960_amostra_127(list(familias = familia_isolada,
                                                    pessoas = pessoas), file.path(saida, "isolada")),
                 error = function(e) conditionMessage(e))
stopifnot(is.character(erro), length(erro) == 1L, grepl("convivente sem principal", erro),
          nrow(fread(file.path(saida, "isolada", "conviventes_isoladas_a_revisar.csv"))) == 1L)

# Selecionar poucos registros reais sem carregar HHOLDA inteiro. As linhas
# originais sao restauradas apos a leitura do pequeno arquivo de teste.
lote_integridade_127 <- function(alvos){
  alvos <- sort(unique(alvos))
  con <- file("data_raw/microdata/1960/amostra_127/HHOLDA.txt", open = "rt", encoding = "latin1")
  on.exit(close(con))
  texto <- character(length(alvos)); inicio <- 0L
  while(inicio < max(alvos)){
    trecho <- readLines(con, n = 10000L, warn = FALSE)
    stopifnot(length(trecho) > 0L)
    selecionadas <- which(alvos > inicio & alvos <= inicio + length(trecho))
    texto[selecionadas] <- trecho[alvos[selecionadas] - inicio]
    inicio <- inicio + length(trecho)
  }
  stopifnot(length(texto) == length(alvos), all(nchar(texto) == 62L))
  path <- tempfile("lote_", tmpdir = saida, fileext = ".txt")
  writeLines(texto, path, useBytes = TRUE)
  linhas <- read_1960_amostra_127(path)
  linhas[, linha := alvos]
  linhas <- apply_corrections_1960_amostra_127(linhas, "read_guides/1960_amostra_127_correcoes.csv")
  parse_1960_amostra_127(linhas, "read_guides/readguide_1960_amostra_127_familias.csv",
                        "read_guides/readguide_1960_amostra_127_pessoas.csv")
}

# PB: dois pares indistinguiveis continuam duas pessoas cada, nao uma.
pb <- lote_integridade_127(168800:168807)
pb_antes <- copy(pb$pessoas)
pb_ok <- dedup_1960_amostra_127(pb, file.path(saida, "pb"))
stopifnot(nrow(pb_ok$pessoas) == 7L, identical(pb_antes, pb$pessoas),
          all(c(168802L, 168804L, 168805L, 168806L) %in% pb_ok$pessoas$linha),
          all(pb_ok$pessoas$V204 == "9"), all(pb_ok$pessoas$AGE == "99"),
          nrow(fread(file.path(saida, "pb", "duplicatas_removidas.csv"))) == 0L)

# PE: quatro ocorrencias do perfil de um ano representam multiplicidade dois.
# Os outros seis perfis repetidos deste boletim foram conferidos no gzip.
pe <- lote_integridade_127(195136:195153)
pe_ok <- dedup_1960_amostra_127(pe, file.path(saida, "pe"))
perfil <- pe_ok$pessoas[V202 == "1" & V203 == "9" & V204 == "1" & AGE == "01"]
stopifnot(nrow(pe_ok$pessoas) == 9L, nrow(perfil) == 2L,
          identical(sort(perfil$linha), c(195142L, 195145L)),
          !any(195146:195153 %in% pe_ok$pessoas$linha),
          nrow(fread(file.path(saida, "pe", "duplicatas_removidas.csv"))) == 8L)
pe_invertido <- list(familias = copy(pe$familias), pessoas = copy(pe$pessoas[.N:1L]))
pe_invertido <- dedup_1960_amostra_127(pe_invertido, file.path(saida, "pe_invertido"))
stopifnot(identical(sort(pe_invertido$pessoas$linha), sort(pe_ok$pessoas$linha)))

# A decisao nao pode ser transferida a uma linha cujo conteudo mudou.
adulterado <- list(familias = copy(pb$familias), pessoas = copy(pb$pessoas))
adulterado$pessoas[linha == 168805L, texto_original := paste0("00", substr(texto_original, 3, 62))]
erro <- tryCatch(dedup_1960_amostra_127(adulterado, file.path(saida, "adulterado")),
                 error = function(e) conditionMessage(e))
stopifnot(is.character(erro), length(erro) == 1L, grepl("conteudo.*decisao", erro))
incompleto <- list(familias = copy(pb$familias), pessoas = copy(pb$pessoas[linha != 168805L]))
erro <- tryCatch(dedup_1960_amostra_127(incompleto, file.path(saida, "incompleto")),
                 error = function(e) conditionMessage(e))
stopifnot(is.character(erro), length(erro) == 1L, grepl("grupo.*incompleto", erro))
excedente <- list(familias = copy(pb$familias),
                 pessoas = rbind(pb$pessoas, copy(pb$pessoas[linha == 168805L])[, linha := 168808L]))
erro <- tryCatch(dedup_1960_amostra_127(excedente, file.path(saida, "excedente")),
                 error = function(e) conditionMessage(e))
stopifnot(is.character(erro), length(erro) == 1L, grepl("multiplicidade.*decisao", erro))

# Uma decisao aprovada nao libera exclusoes parciais se outro perfil ficou pendente.
mistura <- list(familias = pe$familias, pessoas = rbind(pe$pessoas, repetidas, fill = TRUE))
antes <- copy(mistura$pessoas)
erro <- tryCatch(dedup_1960_amostra_127(mistura, file.path(saida, "mistura")),
                 error = function(e) conditionMessage(e))
stopifnot(is.character(erro), length(erro) == 1L, grepl("Deduplicacao suspensa", erro),
          identical(mistura$pessoas, antes),
          !file.exists(file.path(saida, "mistura", "duplicatas_removidas.csv")))

# BA: a reconciliacao usa o cartao real, sem alterar distrito ou outros dados.
ba_a <- lote_integridade_127(c(302253:302261, 302453:302459))
ba_a_antes <- copy(ba_a$pessoas)
ba_a <- build_families_1960_amostra_127(ba_a, file.path(saida, "ba_a"))
destino <- ba_a$familias[linha == 302453L]
menina <- ba_a$pessoas[linha == 302261L]
stopifnot(nrow(destino) == 1L, nrow(menina) == 1L, nrow(ba_a$familias) == 2L,
          menina$censobr_idfamily == destino$censobr_idfamily, menina$distrito == "01",
          menina$V116 == "3138", menina$censobr_familia_origem == "reconciliada_25",
          nrow(ba_a$pessoas[censobr_idfamily == destino$censobr_idfamily]) == 7L,
          destino$V102 == "5")

# 118 tem sete pessoas; 124 tem treze. Mover so os seis criaria oito no118.
ba_b <- lote_integridade_127(c(315134:315139, 315168:315180, 315732:315733, 315736))
ba_b_antes <- copy(ba_b$pessoas)
ba_b <- build_families_1960_amostra_127(ba_b, file.path(saida, "ba_b"))
f118 <- ba_b$familias[linha == 315732L]
f124 <- ba_b$familias[linha == 315168L]
stopifnot(nrow(f118) == 1L, nrow(f124) == 1L, nrow(ba_b$familias) == 2L,
          nrow(ba_b$pessoas) == 20L,
          nrow(ba_b$pessoas[censobr_idfamily == f118$censobr_idfamily]) == 7L,
          nrow(ba_b$pessoas[censobr_idfamily == f124$censobr_idfamily]) == 13L,
          !any(ba_b$pessoas$censobr_familia_origem == "registro_perdido"),
          ba_b$pessoas[linha == 315736L, distrito] == "05",
          f124$distrito == "03", nrow(fread(file.path(saida, "ba_b", "vinculos_reconciliados.csv"))) == 7L)
alterado <- lote_integridade_127(c(302253:302261, 302453:302459))
alterado$familias[linha == 302453L, texto_original := paste0("00", substr(texto_original, 3, 62))]
erro <- tryCatch(build_families_1960_amostra_127(alterado, file.path(saida, "cartao_alterado")),
                 error = function(e) conditionMessage(e))
stopifnot(is.character(erro), length(erro) == 1L, grepl("conteudo.*vinculo", erro))

# Nao deixar pessoas sem domicilio chegarem ao agrupamento NA da finalizacao.
sem_vinculo <- list(familias = copy(ba_a$familias), pessoas = copy(ba_a$pessoas))
sem_vinculo$pessoas[linha == 302261L, `:=`(censobr_idfamily = NA_integer_, censobr_idhousehold = NA_integer_)]
erro <- tryCatch(finalize_1960_amostra_127(sem_vinculo, "nao_deve_ser_lido", "nao_deve_ser_lido"),
                 error = function(e) conditionMessage(e))
stopifnot(is.character(erro), length(erro) == 1L, grepl("vinculos pendentes", erro))

# Tres reparos restritos: nenhum campo posterior e preenchido por arrastamento.
reparos <- lote_integridade_127(c(387715L, 387853L, 951431L))$pessoas
rs <- reparos[linha == 951431L]
stopifnot(nrow(rs) == 1L, rs$V212 == "6", rs$V213 == "2", rs$V214 == "00",
          rs$V215 == "0", substr(rs$texto_corrigido, 39, 54) == strrep(" ", 16),
          substr(rs$texto_corrigido, 55, 62) == "\\0155539")
ba_rep <- reparos[linha %in% c(387715L, 387853L)][order(linha)]
stopifnot(nrow(ba_rep) == 2L, all(ba_rep$V218 == "00"), all(ba_rep$V219 == "3"),
          identical(ba_rep$V220, c("4", "1")), all(ba_rep$V216 == "00"))

# Conferir todas as decisoes aprovadas, sem materializar a UF ou o pais inteiro.
manifesto <- read.csv("read_guides/1960_amostra_127_duplicatas.csv", colClasses = "character")
stopifnot(nrow(manifesto) > 0L, !anyDuplicated(manifesto$linha))
amplo <- lote_integridade_127(as.integer(manifesto$linha))
amplo_ok <- dedup_1960_amostra_127(amplo, file.path(saida, "manifesto_completo"))
manter <- sort(as.integer(manifesto$linha[manifesto$acao == "manter"]))
remover <- sort(as.integer(manifesto$linha[manifesto$acao == "remover"]))
stopifnot(nrow(amplo$pessoas) == nrow(manifesto), nrow(amplo_ok$pessoas) == length(manter),
          identical(sort(amplo_ok$pessoas$linha), manter),
          nrow(fread(file.path(saida, "manifesto_completo", "duplicatas_removidas.csv"))) == length(remover))

# Expansao conservadora dos vinculos: todos os moradores e cartoes dos 28
# boletins conferidos, nao apenas as 74 pessoas deslocadas. Nenhum campo bruto
# muda e nenhuma pessoa/familia e criada ou excluida.
linhas_vinculos <- c(
  101863:101866, 102085:102087, 102976:102980,
  209262:209269, 209383:209388, 209612, 209663:209667,
  216197:216202, 216215:216216, 216241:216242, 216249:216255,
  315181:315184, 315535:315538, 315629:315641, 315737:315738,
  315759:315760, 315762:315765, 426964:426965, 427252:427259,
  427286:427289, 572027, 572108:572115, 673340, 673440:673446,
  781682:781686, 781721:781722, 781839:781841, 781872:781873,
  781935, 781984:781986, 781989:781990, 781996:781998,
  782011:782015, 782022:782023, 829766, 829772:829775,
  835275:835276, 835551:835553, 835598:835599, 835627:835629,
  842765:842766, 842799:842801, 964086, 965267:965271,
  1032423:1032425, 1032746:1032748, 1032794:1032804)
vinculos <- lote_integridade_127(as.integer(linhas_vinculos))
vinculos_antes <- list(familias = copy(vinculos$familias), pessoas = copy(vinculos$pessoas))
vinculos <- dedup_1960_amostra_127(vinculos, file.path(saida, "vinculos_ampliados_dedup"))
vinculos <- build_families_1960_amostra_127(vinculos, file.path(saida, "vinculos_ampliados_build"))
dec_vinculos <- read.csv("read_guides/1960_amostra_127_vinculos.csv", colClasses = "character")
dec_vinculos <- dec_vinculos[as.integer(dec_vinculos$linha) %in% vinculos$pessoas$linha, ]
stopifnot(length(linhas_vinculos) == 180L, nrow(vinculos$pessoas) == 152L,
          nrow(vinculos$familias) == 28L, nrow(dec_vinculos) == 74L,
          sum(vinculos$pessoas$censobr_familia_origem == "reconciliada_25") == 74L)
cols_pessoa <- names(vinculos_antes$pessoas)
cols_familia <- names(vinculos_antes$familias)
stopifnot(identical(as.data.frame(vinculos$pessoas[, ..cols_pessoa]), as.data.frame(vinculos_antes$pessoas)),
          identical(as.data.frame(vinculos$familias[, ..cols_familia]), as.data.frame(vinculos_antes$familias)))
ip <- match(as.integer(dec_vinculos$linha), vinculos$pessoas$linha)
jf <- match(as.integer(dec_vinculos$linha_familia), vinculos$familias$linha)
stopifnot(length(ip) == 74L, length(jf) == 74L, !anyNA(ip), !anyNA(jf),
          identical(vinculos$pessoas$censobr_idfamily[ip], vinculos$familias$censobr_idfamily[jf]))

# Evidencias dos microlotes, nao uma nova base certificada. IDs de familia
# sao locais ao teste; linha e texto_original identificam o arquivo de origem.
fwrite(pb$pessoas, file.path(saida, "pb_pessoas_antes.csv"), bom = TRUE)
fwrite(pb_ok$pessoas, file.path(saida, "pb_pessoas_depois.csv"), bom = TRUE)
fwrite(pe$pessoas, file.path(saida, "pe_pessoas_antes.csv"), bom = TRUE)
fwrite(pe_ok$pessoas, file.path(saida, "pe_pessoas_depois.csv"), bom = TRUE)
fwrite(ba_a_antes, file.path(saida, "ba_031_pessoas_antes.csv"), bom = TRUE)
fwrite(ba_a$pessoas, file.path(saida, "ba_031_pessoas_depois.csv"), bom = TRUE)
fwrite(ba_a$familias, file.path(saida, "ba_031_cartoes.csv"), bom = TRUE)
fwrite(ba_b_antes, file.path(saida, "ba_118_124_pessoas_antes.csv"), bom = TRUE)
fwrite(ba_b$pessoas, file.path(saida, "ba_118_124_pessoas_depois.csv"), bom = TRUE)
fwrite(ba_b$familias, file.path(saida, "ba_118_124_cartoes.csv"), bom = TRUE)
fwrite(reparos, file.path(saida, "tres_reparos.csv"), bom = TRUE)
fwrite(amplo$pessoas, file.path(saida, "manifesto_pessoas_antes.csv"), bom = TRUE)
fwrite(amplo_ok$pessoas, file.path(saida, "manifesto_pessoas_depois.csv"), bom = TRUE)
fwrite(vinculos_antes$pessoas, file.path(saida, "vinculos_ampliados_pessoas_antes.csv"), bom = TRUE)
fwrite(vinculos$pessoas, file.path(saida, "vinculos_ampliados_pessoas_depois.csv"), bom = TRUE)
fwrite(vinculos$familias, file.path(saida, "vinculos_ampliados_cartoes.csv"), bom = TRUE)

message("Testes de integridade concluidos; diagnosticos em ", saida)
