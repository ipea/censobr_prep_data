# Regenera schemas/censobr_types.csv medindo toda coluna dos parquets em data/.
# Rodar da raiz do projeto, depois de qualquer mudanca de colunas e ANTES do
# tar_make() que grava os parquets finais (o cast le este CSV). Leva ~30 min.
#
# Por arquivo e em fatias de 40 colunas, com memoria e threads limitadas: uma
# consulta sobre o 2010_population inteiro (251 colunas x 20,6 M linhas) esgota
# a RAM da maquina.
library(duckdb)
library(data.table)

con <- dbConnect(duckdb())
dbExecute(con, "SET memory_limit = '10GB'")
dbExecute(con, "SET threads = 8")

fs <- list.files("data", pattern = "_v[0-9]+\\.[0-9]+\\.[0-9]+\\.parquet$", recursive = TRUE, full.names = TRUE)
fs <- fs[!grepl("release_legacy", fs)]
chave <- function(p) sub("\\.publico$", "", sub("_v[0-9]+\\.[0-9]+\\.[0-9]+\\.parquet$", "", basename(p)))
cat(length(fs), "arquivos\n")

# 1. medicao: n nao nulos, valores nao numericos, decimais, zeros a esquerda, min, max
scan <- list()
for (p in fs) {
  desc  <- dbGetQuery(con, sprintf("describe select * from read_parquet('%s')", p))
  cols  <- desc$column_name
  types <- desc$column_type
  for (ch in split(seq_along(cols), ceiling(seq_along(cols) / 40))) {
    exprs <- character(0)
    for (i in ch) {
      cn <- sprintf('"%s"', cols[i])
      if (grepl("VARCHAR", types[i])) {
        exprs <- c(exprs, sprintf(paste(
          "count(%s) as n_%d,",
          "coalesce(sum(case when %s is not null and trim(%s) not in ('', '.') and try_cast(%s as double) is null then 1 else 0 end), 0) as nonnum_%d,",
          "coalesce(sum(case when try_cast(%s as double) <> floor(try_cast(%s as double)) then 1 else 0 end), 0) as frac_%d,",
          "coalesce(sum(case when regexp_matches(%s, '^0[0-9]') then 1 else 0 end), 0) as lz_%d,",
          "min(try_cast(%s as double)) as mn_%d, max(try_cast(%s as double)) as mx_%d"),
          cn, i, cn, cn, cn, i, cn, cn, i, cn, i, cn, i, cn, i))
      } else if (grepl("DOUBLE|FLOAT|INTEGER|BIGINT|SMALLINT|TINYINT|DECIMAL|HUGEINT", types[i])) {
        exprs <- c(exprs, sprintf(paste(
          "count(%s) as n_%d, 0 as nonnum_%d,",
          "coalesce(sum(case when %s <> floor(%s) then 1 else 0 end), 0) as frac_%d, 0 as lz_%d,",
          "min(%s)::double as mn_%d, max(%s)::double as mx_%d"),
          cn, i, i, cn, cn, i, i, cn, i, cn, i))
      } else {
        exprs <- c(exprs, sprintf("count(%s) as n_%d, NULL::bigint as nonnum_%d, NULL::bigint as frac_%d, NULL::bigint as lz_%d, NULL::double as mn_%d, NULL::double as mx_%d",
                                  cn, i, i, i, i, i, i))
      }
    }
    r <- dbGetQuery(con, sprintf("select %s from read_parquet('%s')", paste(exprs, collapse = ", "), p))
    scan[[length(scan) + 1]] <- rbindlist(lapply(ch, \(i) data.table(
      dataset = chave(p), coluna = cols[i], tipo_atual = types[i],
      n = r[[paste0("n_", i)]], nonnum = r[[paste0("nonnum_", i)]], frac = r[[paste0("frac_", i)]],
      lz = r[[paste0("lz_", i)]], mn = r[[paste0("mn_", i)]], mx = r[[paste0("mx_", i)]])))
  }
  message(chave(p), ": ", length(cols), " colunas")
}
dbDisconnect(con, shutdown = TRUE)
s <- rbindlist(scan)

# 2. regra. Branco e ponto sao marcas de ausencia e nao contam como texto.
s[, tipo_atual := fcase(grepl("VARCHAR", tipo_atual), "string",
                        tipo_atual == "DOUBLE",   "double",
                        tipo_atual == "INTEGER",  "int32",
                        tipo_atual == "BIGINT",   "int64",
                        tipo_atual == "SMALLINT", "int16",
                        tipo_atual == "TINYINT",  "int8",
                        tipo_atual == "FLOAT",    "float32",
                        default = tolower(tipo_atual))]
s[, humana := grepl("^(name_|abbrev_)", coluna) | coluna == "situacao"]
s[, tipo_alvo := fcase(humana, "string",
                       n == 0, tipo_atual,
                       nonnum > 0, "string",
                       frac > 0, "double",
                       mn >= -2147483647 & mx <= 2147483647, "int32",
                       default = "double")]
s[n == 0 & tipo_atual %in% c("int8", "int16", "int64", "float32"), tipo_alvo := "double"]

# 3. mesma coluna nas tabelas de microdados do mesmo ano: tipo mais permissivo
s[, ano := substr(dataset, 1, 4)]
s[, micro := !grepl("tracts", dataset)]
ordem <- c(int32 = 1, double = 2, string = 3)
s[micro == TRUE, tipo_alvo := names(ordem)[max(ordem[tipo_alvo])], by = .(ano, coluna)]

print(table(s$tipo_atual, s$tipo_alvo))
fwrite(s[, .(dataset, coluna, tipo_atual, tipo_alvo, n, nonnum, frac, lz, mn, mx)], "schemas/censobr_types.csv")
cat("gravado:", nrow(s), "linhas; mudam de tipo:", sum(s$tipo_atual != s$tipo_alvo), "\n")
