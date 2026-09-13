---
name: memory-discipline
description: Disciplina obrigatória de memória e performance para todo R do projeto. Codifica os padrões que evitam OOM em ETL pesado (data.table default, workers ≤ 4, gc/rm rigor, arrow como fallback). Bloqueia padrões que causaram crash em 2026-05-03.
paths:
  - "**/*.R"
  - "_targets.R"
---

# Disciplina de memória e performance

**Status:** OBRIGATÓRIA
**Escopo:** todo código R em `censobr_prep_data` (atual e futuro). Aplica-se a todo código novo e a todo bloco tocado em `R/`.
**Complementar a:** [`code-style.md`](code-style.md) (regra-irmã, foco em estilo de escrita + nomeação censobr + adaptação targets).

## Por que existe

Em 2026-05-03 o pipeline crashou OOM em `clean_tract_table_2010` (branch ENTORNO) com `furrr` workers=8 + `dplyr::left_join` chain + `purrr::map(~str_detect)` sobre colunas character. Causa estrutural: o pipeline carrega 27 UFs × até 5 sub-tabelas IBGE × até 242 colunas character em paralelo, sem `gc()`, sem `rm()` de listas intermediárias, multiplicando cópias via dplyr. Esta regra codifica os padrões que evitam reincidência.

## 1. Fonte de dados: XLS é primário, CSV é fallback documentado

Os zips IBGE de Resultados do Censo trazem o mesmo conteúdo em **dois formatos**: XLS e CSV. **Use XLS por default.**

CSVs do IBGE têm múltiplos quirks que comprometem a integridade dos dados:
- **Notação científica em códigos longos** — `Cod_setor` de 15 dígitos vira `2,3001E+14` (perda de precisão; observado em ENTORNO_CE/MG/SP/etc.).
- **Separador inconsistente** — alguns arquivos usam `;`, outros `,` (observado em PESSOA02_AC, PESSOA*_SP2, RESPONSAVEL*_SP2).
- **Aspas duplicadas malformadas** — `""V001""` em vez de `"V001"`, fazendo `fread` ler tudo como uma coluna só.
- **Headers com cells sem nome** — `readxl` gera `...242` automático que vaza no merge.

XLS preserva precisão numérica, formato de cabeçalho íntegro e estrutura uniforme. `readxl::read_excel(col_types = "text")` é o padrão; "X" do IBGE (marcador de censura) fica como texto literal e vira NA estruturado quando convertido a `as.numeric` no save.

**Quando usar CSV** (apenas como fallback explícito):
- (a) IBGE não disponibilizou XLS para essa edição/tabela.
- (b) Verificou-se que XLS daquele arquivo está corrompido E o CSV correspondente está íntegro.

Em qualquer fallback CSV, **documentar explicitamente** num comentário no código com link para o issue ou relatório, e justificar por que XLS não serve.

## 2. Motor primário: `data.table`

- Default para qualquer manipulação de dados não-trivial: `fread`, `[ , := ]`, `merge.data.table`, `set`, `setorder`, `rbindlist`.
- `dplyr` aceito apenas para: operações lazy sobre `arrow::open_dataset()`; tabelas pequenas (lookup, dicionários); blocos curtos de rename/select que já estão escritos e funcionam.
- Para CSV (fallback raro — ver seção 1), `data.table::fread(colClasses="character", na.strings=c("X","",",","."))` é preferível a `arrow::read_csv_arrow` (controle de tipos melhor).
- Para XLS (default — ver seção 1), `readxl::read_excel(col_types = "text")` preserva "X" como literal e Cod_setor full precision.

## 3. Joins

- `merge.data.table` ou `dt[dt2, on = ...]` em vez de `dplyr::*_join` em chains.
- Em chain de joins iterativos, consumir a lista liberando memória:
  ```r
  while(length(df_list) > 0){
    temp <- merge(temp, df_list[[1]], by = "code_tract", sort = FALSE)
    df_list[[1]] <- NULL
    gc(verbose = FALSE)
  }
  ```

## 4. Mutações multi-coluna

- Loop `data.table::set(dt, j = col, value = ...)` em vez de `mutate(across(...))` ou `mutate_all`.
- Coalescer múltiplos `mutate(across)` num único loop.
- `for(col in names(dt))` com early exit quando faz sentido.

## 5. Paralelismo

- `furrr::future_map` com `workers ≤ 4` por default. Documentar se um caso específico justifica mais (e a RAM aguenta).
- `_targets.R` `coress = 1` (limite de FTP IBGE) é independente disso — não confundir.

## 6. Limpeza

- `gc(verbose = FALSE)` após `rbindlist` ou `merge` grandes.
- `rm(lst); gc(verbose = FALSE)` antes de `return()` em funções que alocam listas/dataframes intermediários.
- Em `for` loops com acumulador, `rm(tmp); gc(verbose = FALSE)` por iteração.
- Drop de coluna por `df$X <- NULL` (encadeável: `df$A <- df$B <- NULL`) ou `mutate(X = NULL)`.

## 7. Escalada para `arrow`

Apenas se data.table+gc+workers≤4 não bastar. Padrão:
1. Em vez de retornar a lista de UFs concatenada, gravar 1 parquet temp por UF.
2. Consolidar via `arrow::open_dataset(temp_dir) |> dplyr::collect()` ou `arrow::concat_tables()`.
3. Limpar tempdir após gravar parquet final.

Nunca pre-emptivamente. data.table é o motor primário.

## 8. Checklist antes de qualquer commit (parte memória)

- [ ] `data.table` para todas as manipulações pesadas (não `dplyr` em data frame com >10k linhas character).
- [ ] `furrr` workers ≤ 4.
- [ ] `gc()` após `rbindlist`/`merge` grandes; `rm()` de listas intermediárias antes de `return()`.
- [ ] Em listas-fila, `lst[[1]] <- NULL` na cabeça libera memória ao consumir.
- [ ] `arrow` só como fallback quando data.table+gc não basta.
- [ ] XLS é fonte primária; uso de CSV está justificado em comentário.

(O checklist completo de pré-commit também inclui itens de [`code-style.md`](code-style.md).)

## 9. Quando esta regra entra em conflito com código existente

- Código novo (refactor, novo target, novo ano): **aplicar a regra integralmente.**
- Código existente que funciona e não é hot path de memória: **deixar como está.** Refactor de memória é trabalho separado, não oportunista.
- Ao tocar uma função existente para outro motivo: aplicar a regra na função/bloco tocado, não no arquivo inteiro (ver `minimal-changes.md`).