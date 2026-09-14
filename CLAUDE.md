# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project autonomy

This project (`censobr_prep_data`) is **always opened as a standalone workspace** — never with the parent `censobr_e_prepData/` folder. The consumer package `censobr` lives at `..\censobr\` on disk, but is treated as a separate project handled in a separate VS Code window / Claude Code session. Changes to the consumer go through PRs on `https://github.com/ipea/censobr`, not from this session.

Defense-in-depth: PreToolUse hooks in `.claude/settings.json` block any `Edit`/`Write`/`NotebookEdit` or destructive Bash command that targets `..\censobr\` (in case a path slips through by mistake). Read-only access to `..\censobr\` is allowed.

## Rules — read before any work

All rules live in [.claude/rules/](.claude/rules/) and are obligatory:

- **[scope.md](.claude/rules/scope.md)** — INVIOLÁVEL. Edits only inside `censobr_prep_data/`.
- **[recuperacao-sessao.md](.claude/rules/recuperacao-sessao.md)** — protocol to run at session start / after context compression.
- **[plan-first-workflow.md](.claude/rules/plan-first-workflow.md)** — non-trivial tasks require a written plan saved to disk before any code is written.
- **[minimal-changes.md](.claude/rules/minimal-changes.md)** — surgical edits only; protected-function list; no opportunistic refactor.
- **[test-first-protocol.md](.claude/rules/test-first-protocol.md)** — validate on 1 small UF (RR/AC) before processing 27 states; investigation loop until "absolute certainty".
- **[memory-discipline.md](.claude/rules/memory-discipline.md)** — performance/memória: XLS-first (CSV fallback), `data.table` default, `furrr` workers ≤ 4, `gc/rm` rigor, `arrow` como fallback. Triggered by 2026-05-03 OOM crash.
- **[code-style.md](.claude/rules/code-style.md)** — escrita de código: estilo procedural do usuário (sem helpers `.dot_prefixed`, comentários narrativos curtos, sem defensividade redundante), nomeação `censobr` canônica (`code_*`, `name_*`, V cols com prefixo de tema), adaptação a `targets`.

If a hook blocks an action, stop and explain to the user what would need to change — do not try to work around it.

## Memory & style discipline (sempre em contexto)

Duas regras complementares: [`memory-discipline.md`](.claude/rules/memory-discipline.md) (performance) e [`code-style.md`](.claude/rules/code-style.md) (escrita + nomeação). Os bullets abaixo são críticos para **todo** código R deste projeto e ficam em contexto a cada turno para evitar drift. Triggered pelo crash OOM de 2026-05-03 e por feedback explícito do usuário sobre estilo verboso/defensivo do AI.

**Fonte de dados (XLS é primário):**
- IBGE distribui o mesmo conteúdo em XLS e CSV. **Use XLS por default** — `readxl::read_excel(col_types = "text")`.
- CSVs IBGE têm quirks documentados: notação científica em `Cod_setor`, separadores inconsistentes, aspas duplicadas malformadas, headers `...XXX` espúrios. Detalhes na regra.
- CSV é fallback explícito apenas quando: XLS indisponível OU XLS corrompido com CSV íntegro. Documentar no código com motivo.

**Memória:**
- `data.table` é o motor primário (`fread`, `[, := ]`, `merge`, `set`, `rbindlist`). `dplyr` só sobre `arrow::open_dataset()` lazy ou tabelas pequenas.
- `furrr::future_map` com `workers ≤ 4`. `coress = 1` no `_targets.R` é independente (rate-limit FTP).
- `gc(verbose = FALSE)` após `rbindlist`/`merge` grandes; `rm(lst); gc()` antes de `return()` em funções que alocam listas. Em listas-fila, `lst[[1]] <- NULL` na cabeça libera memória ao consumir.
- `arrow` só como fallback (parquet por grupo + `open_dataset` no fim) se data.table+gc não basta. Não preempção.

**Estilo (copiar do usuário, não do AI default):** projetos canônicos: TD-IPEA, Edu-Performance, EJA — paths em memória `reference_user_style_projects`.
- Procedural, linear. Objetos nomeados em sequência. Reatribuição em passos (`df <- df %>% ...` repetido) em vez de mega-pipe.
- Sem helpers `.dot_prefixed` para uso único — inlinar. Função apenas para matemática reutilizável. No `targets`: 1 função pública por target, corpo procedural.
- Comentários narrativos curtos (1–3 linhas) sobre o **porquê analítico**. Sem multi-parágrafo de design, sem stacktrace de investigação, sem doc de bug (vai no commit/plano).
- Mensagens curtas: `message(uf)`. Sem `sprintf` em `message()`.
- Confiar em funções idempotentes: `make.unique`, `%in%` (cobre NA), `as.numeric`. Sem `if(any(duplicated(...)))` antes de `make.unique`. Sem `tryCatch` por hábito.
- `=` alinhado em listas de pares. Pipe `|>` em código novo. `library()` em bloco no topo.

**Nomeação `censobr` (canônica — zero invenção):**
- **Colunas do IBGE ficam com o nome original, sempre** (`Cod_setor`, `Nome_da_UF`, `CD_MUN`, `V0102`…); nunca renomeadas. As colunas de geografia censobr são **adicionais** (`mutate`, não `rename`) e vêm no início da tabela, na ordem de `GEO_COLS_CENSOBR` via `relocate_geo_cols_censobr()` (`R/support_fun.R`). Decisão de 2026-09-13.
- IDs censobr: `code_tract|muni|state|region|district|subdistrict|neighborhood|weighting|meso|micro|metro`. Sigla: `abbrev_state`. Nomes humanos: `name_*` análogos.
- V cols IBGE preservadas com prefixo de tema quando a tabela une vários arquivos: `pessoa01_V002`, `domicilio02_V135`, `entorno05_V242`.
- Convenção v0.6.0: `code_*` viram `numeric` (Arrow `float64`) via `code_cols_to_numeric()`.
- Nunca preencher valor de um registro a partir de outro (ex.: bloco do chefe nas famílias secundárias de 1970); zero → NA em "não se aplica" e correção de sentinela para o valor do dicionário são aceitáveis.

**Anti-padrões (NÃO repetir — visíveis no diff antigo de `R/census_tracts_2010.R` e na versão AI-style anterior de `R/census_tracts_2022.R` — ambos refatorados em 2026-05-04):**
- `mutate_all(funs(...))`, `purrr::reduce(.x, dplyr::left_join)`, `purrr::map(~str_detect)` em colunas character.
- Helpers `.dot_prefixed` para encapsular uso único (`.match_files_*`, `.recode_*`).
- `vapply(..., FUN.VALUE = ...)` defensivo onde `sapply` serviria; `if(length(...)==0) stop(...)` antes de operação que já erraria.
- Blocos de 5+ linhas comentadas explicando design alternativo testado.

**Aplicação:** integralmente em código novo. Em código existente que funciona e não é hot path, deixar — refactor de estilo é trabalho separado, não oportunista. Ao tocar uma função existente, aplicar na função/bloco tocado, não no arquivo inteiro (`minimal-changes.md`).

## What this repo is

Data-preparation companion to the [`censobr`](https://github.com/ipea/censobr) R package. It downloads raw Brazilian Census files from the IBGE FTP, parses/cleans them, and writes compressed parquet files that are uploaded as assets to GitHub Releases on `ipea/censobr`. End users never run this repo — they consume the published parquet files via the `censobr` package. The README is intentionally empty.

**Project objective:** the deliverable is the **`targets` pipeline itself, 100% reproducible**. Producing any specific `censobr` release (v0.5.0, v0.6.0, etc.) is a downstream concern handled in a separate session against the `ipea/censobr` repo.

## Data domain — two types, two axes

The pipeline produces parquets of two distinct kinds, organized along two independent axes (type × census edition):

**Type 1 — Sample microdata** (registros em nível de indivíduo/domicílio, da amostra do censo):

| Edition | Raw source | Download stage |
|---|---|---|
| 1960 | Personal compilation by the maintainer (Rogério), assembled outside this project from two complementary sources | **No download stage, ever** — `censobr` consumes the semi-prepared input as given |
| 1970, 1980, 1991 | Amostra preparada pelo CEM, hospedada no release `release_legacy` deste repo. O FTP do IBGE republicou as três edições em 01/2025 em versões que perdem variáveis (1980, 1991: sem identificador de domicílio) ou trazem registros corrompidos (1970) — ver `references/microdata_<ano>_ftp_vs_*.md` | `download_microdata_<year>()` via `get_release_legacy()`; o FTP serve só como referência de validação |
| 2000, 2010 | IBGE FTP — `https://ftp.ibge.gov.br/Censos/` | `download_microdata_<year>()` |
| 2022 | IBGE FTP — amostra de acesso público, publicada em 31/08/2026 (a versão de acesso controlado não é redistribuível) | `download_microdata_2022()` |

**Type 2 — Aggregates by census tract** (registros em nível de setor censitário; somas, proporções e médias do **universo** do censo, agregadas espacialmente — não da amostra):

| Edition | Status |
|---|---|
| 2000 | `R/census_tracts_2000.R` + block `# 08.` in `_targets.R` |
| 2010 | `R/census_tracts_2010.R` + block `# 09.` |
| 2022 | `R/census_tracts_2022.R` + block `# 10.` (definitivos) and `R/census_tracts_2022_prelim.R` + block `# 11.` (preliminares) |

No tract aggregates exist for editions before 2000.

## Pipeline stage vocabulary

The canonical sequence for processing an (edition × type) flow has **four stages**. Use these names consistently in code, plans, and discussion:

1. **download** — fetch raw files from the IBGE FTP; for 1960/1970/1980/1991 it fetches the prepared sample from the `release_legacy` release instead.
2. **abrir** (open/read) — parse raw files (fixed-width `.txt` for microdata; `.xls`/`.zip` for tracts) into R/Arrow structures.
3. **recodificar** (recode) — transform **values within columns**: e.g., `1/2` → `"Masculino"/"Feminino"`, regroup race/color categories, harmonize education codes across editions.
4. **padronizar** (standardize) — bring the **structure and metadata** into the `censobr` standard: rename columns to `censobr` convention, apply `arrow::schema()` types, attach geography columns (`code_muni`, `code_state`, `name_state`, `code_region`), write parquet via `write_censobr_parquet()` (zstd-22).

Avoid the generic term "preparar" — too vague, since every stage prepares something. "Padronizar" is preferred because there is an external specification (the `censobr` consumer) that the output must conform to.

## Pipeline orchestration (`_targets.R`)

The pipeline uses [`targets`](https://books.ropensci.org/targets/) + `tarchetypes` + `crew`. Functions in `R/` are auto-sourced via `targets::tar_source('./R')`. Common commands:

- `targets::tar_make()` — run/resume the pipeline
- `targets::tar_visnetwork()` — view the DAG
- `targets::tar_read(<name>)` — read a materialized target (e.g. `tar_read(raw_tracts_paths_2010)`)
- `targets::tar_meta(fields = warnings, complete_only = TRUE)` — inspect warnings/errors after a failed run

`coress <- 1` is hardcoded at the top of `_targets.R` to avoid rate-limiting from the IBGE FTP — do not bump it without testing FTP behavior. Inside individual cleaning functions (e.g. `clean_tracts_2010`), `furrr::future_map` parallelizes by state with its own worker count (`workers = 4` per the [memory-discipline rule](.claude/rules/memory-discipline.md); was 8, caused OOM in 2026-05-03).

Outputs land in `./data/` (gitignored); raw downloads in `./data_raw/` (gitignored); `crew` worker logs in `./logs/crew_workers/`.

## Code layout

All code lives in `R/`, sourced by `targets::tar_source('./R')`. One file per (edition × type) — `microdata_<year>.R`, `census_tracts_<year>.R` — each exposing a `download_*` → `clean_*` → `save_*` trio wired as a numbered block (`# 01.` to `# 11.`) in `_targets.R`. Shared code is in `support_fun.R`, `add_geography_cols.R`, `convert_raw_to_parquet.R`, `schema_col_classes.R`, `release_legacy.R` and `type_convention.R`.

The legacy standalone scripts that preceded the pipeline (folder `R_ainda_sem_targets/`) were removed after every edition was ported; they remain in git history up to commit `18d2ac7`.

When adding a new year or table, add the trio in `R/` and a numbered block in `_targets.R`; do not add standalone scripts.

## Shared utilities (`R/support_fun.R`)

Centralized helpers used throughout the pipeline. Reuse before reinventing:

- `download_file_censobr()` — parallel httr2 downloads with timeout/SSL handling (replaces older `RCurl`/`curl` calls).
- `unzip_censobr()` — base R `unzip()` with a `system2("unzip", ...)` fallback for files that fail.
- `list_folders(ftp)` — scrapes IBGE FTP HTML index for filenames.
- `add_state_info()` / `add_region_info()` — robust state/region code+name imputation; tolerates historical spellings (e.g. `Goyaz`, `Districto Federal`, `Guanabara`) — important for pre-1960 data.
- `dicionario_municipality` / `dicionario_state` + `rename_cols_censobr()` — fuzzy column-name standardization across heterogeneous IBGE exports.
- `write_censobr_parquet()` — the canonical writer (zstd level 22). Always use this instead of `arrow::write_parquet` directly.
- `UF_SIGLAS` — 27-state vector. Note that 2010 SP comes in two pieces: `SP_Capital` and `SP_Exceto_Capital`.
- `pick_latest_per_uf()` — when IBGE re-publishes a UF zip with new date suffix (e.g., `RS_20231030.zip` → `RS_20241211.zip`, `GO_20231030.zip` → `GO_20250915.zip`), keeps only the most recent. Used in `download_tract_2010` for FTP listing + local cleanup.
- `get_areas_ponderacao_2010()` — crosswalk `code_tract → code_weighting` (2010 weighting areas) from IBGE's `Documentacao_microdados_2010.zip`. Replaces the old `geobr` source.

`R/add_geography_cols.R` adds `code_muni`, `code_state`, `name_state`, `code_region`, etc. Pay attention to its year-specific source column map (1980→`V2`, 1991→`V1101`, 2000→`V0103`/`V0102`, 2010→`V0002`/`V0001`, 2022→`CD_MUN`). When adding a new year, extend the `case_when` blocks there.

## Read guides and schemas

- `read_guides/*.csv` — fixed-width parsing dictionaries with columns `int_pos`, `fin_pos`, `var_name`, `length`, `decimal_places`, `col_type`. Consumed by `convert_raw_to_parquet()` via `readr::read_fwf`. Decimal handling is implicit: values are divided by `10^decimal_places` post-read.
- `R/schema_col_classes.R` — `get_schema(year, dataset)` returns hardcoded `arrow::schema()` objects per (year, dataset). When opening combined parquet datasets across states, this schema enforces consistent integer widths (`int8`/`int16`/`int32`/`int64`).

## Known data quirks (don't "fix" these — they are real)

- **2010 tracts RS**: `RS_20231030.zip` is explicitly deleted in favor of `RS_20241211.zip` (see `census_tracts_2010.R:48`).
- **`ÿ` character corruption** in some 2010 xls files (e.g. `Pessoa07_CE.xls`, `Entorno05_RO.xls`) — currently stripped to empty string.
- **Goiás 2010 `Pessoa02`** (and SP) has malformed `V01`–`V09` column names (vs. `V001`–`V009` elsewhere); fix is wired in `read_single_file_tract_2010` (issue #68 — covers GO, SP1, SP2).
- `code_weighting` for 2010 tracts is read from the IBGE source file `Composição das Áreas de Ponderação.txt` inside `Documentacao_microdados_2010.zip` via `get_areas_ponderacao_2010()` in `R/support_fun.R`. (Was previously joined from `geobr::read_census_tract(year = 2010)`, but `geobr ≥1.10` no longer exposes that column.)

## Data bugs

The five `ipea/censobr` issues on 2010 tracts (#68, #70, #71, #73, #75) were fixed in this pipeline in 2026-05-03/04 (commits `57c571a`, `c51f55c`); no data issue is open. Defects found in the IBGE source files — as opposed to in our processing — are catalogued in `references/carta_ibge_levantamento.md`, which is the basis of the letter to IBGE.

## Type convention v0.6.0 — `code_*` as numeric

Decided 2026-05-03 (memory entry [`project_conventions_v0_6_0.md`](C:/Users/antro/.claude/projects/d--Dropbox-Software-R-Packages-censobr-e-prepData-censobr-prep-data/memory/project_conventions_v0_6_0.md)):

In every v0.6.0+ parquet produced by this pipeline, all columns whose name starts with `code_` are typed as `numeric` (R double / Arrow float64). Includes `code_tract`, `code_muni`, `code_state`, `code_region`, `code_weighting`, `code_meso`, `code_micro`, etc.

This is an intentional break from v0.5.0 (which had `code_tract` as string and the rest as int32). Apply via `mutate(across(starts_with("code_"), as.numeric))` at the end of the standardize step, before `write_censobr_parquet()`. Document in the consumer's NEWS when v0.6.0 ships — users comparing e.g. `code_state == "11"` (string) need to switch to `code_state == 11`.

## Validation reference

There is **no `dev` branch** on `ipea/censobr` (verified 2026-05-02 — only `main` and `gh-pages`; local Dropbox-synced clones may show stale `origin/dev` ref). The published reference is **v0.5.0** (Jun/2025, 38 parquets). v0.5.0 carries the 2010-tracts bugs fixed in May 2026 — treat it as historical baseline to measure intentional divergence after fixes, not as gold standard.

The pre-release **v0.6.0** (Sep/2025, 8 parquets) is the output of an earlier version of `R/census_tracts_2010.R` (not the current `main` HEAD). Useful as a checkpoint reference but should not be conflated with v0.5.0.

The **canonical column-by-column specification** for 2010/2022 tract parquets is the dictionary CSV from Pedro H. G. F. Souza's private repo, frozen at [`references/phgfsouza_census_tracts/`](references/phgfsouza_census_tracts/) (commit `f895871`, 2026-04-30). Read this in any port that touches setores 2010/2022 to validate output column-by-column. Coverage: 8 parquets for 2010, 9 parquets for 2022. Does NOT cover microdata or pre-2010.

## Publishing artifacts

Final parquet files are uploaded to GitHub Releases on `ipea/censobr` via `piggyback::pb_upload()` (placeholder commented at the bottom of `_targets.R`). Requires `GITHUB_TOKEN` in `~/.Renviron`. The release tag is the data version (e.g. `v0.3.0`, `v2.0.0`), not a code version.
