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
- Censos anteriores a 1991 (decisão de 2026-09-14): o município leva **duas** colunas — `code_muni` no formato atual, o mesmo de 1991, 2000, 2010 e 2022 (sete dígitos), e `code_muni_<ano>` com o código vigente no censo (`code_muni_1960`, `code_muni_1970`, `code_muni_1980`). Para 1960 o crosswalk é `read_guides/1960_municipios.csv`.
- V cols IBGE preservadas com prefixo de tema quando a tabela une vários arquivos: `pessoa01_V002`, `domicilio02_V135`, `entorno05_V242`.
- Tipos: cada coluna tem o tipo declarado em `schemas/censobr_types.csv`, aplicado por `cast_censobr_types()` no fim de todo `save_*` (string / float64 / int32, pela regra mecânica da seção "Type convention"). `code_cols_to_numeric()` continua antes dele.
- Fidelidade ao dado (revisão de 2026-09-14): imputação **determinística** — dedução sem alternativa a partir do próprio registro ou de invariante estrutural (chave do questionário, posição na família) — é permitida e sempre marcada em coluna `censobr_*`; imputação por suposição não. A página de domicílio das famílias secundárias (1960: V101 = 4/5; 1970: V007–V021) **não** é preenchida a partir da família principal — decisão explícita, em discussão no issue `ipea/censobr#87` (texto em `references/issue_familias_secundarias_1960_1970.md`). Zero → NA em "não se aplica" e correção de sentinela para o valor do dicionário são aceitáveis.

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
| 1960 | Duas amostras. A de 1,27% (`HHOLDA.txt`, preservado no repositório `antrologos/ConsistenciaCenso1960Br`) é preparada passo a passo em `R/microdata_1960_amostra_127.R` (bloco `# 01a.`; documento didático em `references/microdata_1960_amostra_127_preparacao.md` e guia introdutório do desenho amostral em `references/microdata_1960_amostra_127_desenho_amostral.md`, com as figuras e a engenharia reversa refeitas por `references/figuras/desenho_amostral_1960.R`; correções em `read_guides/1960_amostra_127_correcoes.csv`; dois pesos calibrados: `censobr_weight`, o final, aos resultados definitivos por UF (Série Nacional vol. I, tabelas 33, 34 e 40 transcritas em `references/censo_1960_resultados_definitivos_serie_nacional.csv` por `references/transcricao_1960_serie_nacional.py`; 543 células; DF no peso de desenho; distância logit com fatores entre 0,3 e 3,5; Fernando de Noronha com peso de desenho 4), e `censobr_weight_1965` aos quadros 1 e 2 dos Resultados Preliminares de 1965 (`references/censo_1960_resultados_preliminares_1965.csv`), ambos validados contra os sete quadros de 1965 e as tabelas definitivas; códigos de todas as variáveis transcritos do *Código do Censo Demográfico – 1960* em `read_guides/1960_codigo_do_censo.csv` (autoridade; `1960_amostra_127_codigos.csv` guarda a correspondência com as quadrículas do Boletim); municípios pela divisão territorial de 1960 com população do Anuário em `read_guides/1960_municipios.csv` (`code_muni_1960` e `code_muni` atual) e distritos, bairros, circunscrições e favelas em `read_guides/1960_distritos.csv` (`code_district_1960`, `name_district_1960`, `name_bairro_1960`, `censobr_favela`), conferidos contra o *Código de Zonas Fisiográficas, Municípios e Distritos* de 1960 (V116 é o código oficial; Guanabara traz o bairro; Alagoas e Fernando de Noronha corrigidos); erros amostrais pelo desenho de pastas em `censobr_upa`/`censobr_estrato`, com correção de população finita de 1/20 (1 em Fernando de Noronha, cuja pasta era o cadastro inteiro), mais o termo da etapa dos domicílios e, para `censobr_weight`, a variância pelos resíduos das 543 células da calibração (`erro_padrao_calibrado`), tudo conferido contra o `survey` em `references/conferencia_desenho_amostral_1960.R`; 75 estratos = UF × {cidade grande, urbana menor, mista, rural}, juntando a UF solitária num grupo à primeira vizinha da mesma região (`VIZINHAS_1960`) — a UF como critério geográfico foi demonstrada pelo cadastro de pastas reconstruído a partir da amostra de 25%). A de 25% é preparada em `R/microdata_1960_amostra_25.R` (bloco `# 01b.`, branching por unidade da federação): dezessete arquivos de largura fixa no `release_legacy`, 18.055.053 linhas, auditoria por classe de defeito com as decisões em `read_guides/1960_amostra_25_correcoes.csv` (oito unidades têm um bloco de pastas gravado à frente do resto e São Paulo tem um boletim partido; a ordenação por pasta, boletim e pessoa restaura a ordem do cadastro), guias de leitura próprios (`readguide_1960_amostra_25_familias.csv` e `_pessoas.csv`), e famílias, domicílios e geografia no passo 4 — 3.071.284 boletins em 3.066.365 domicílios, `censobr_tipo_unidade` separando os 195.445 boletins individuais e os 16.763 coletivos, município fechando em 100% com três correções (Alagoas −200, Fernando de Noronha 2701→2401 e Distrito Federal 9701→9700, esta só necessária aqui) e distrito nomeado em 91,6%, com os 1.178 pares que faltam em `read_guides/1960_amostra_25_distritos_pendentes.csv`. O zero de `V112`/`V113` é o código de resposta ausente do próprio questionário e fica como valor — o *Código do Censo* manda, na p. 25, codificar `00` e `000` quando não há indicação, e `read_guides/1960_codigo_do_censo.csv` passou a trazer os quesitos L, M e N, que a primeira transcrição não alcançava (o exemplar usado terminava no quesito J; a cópia completa está em `references/fontes_1960/1960_codigo_do_censo_demografico.pdf`). O desenho é de uma etapa — `censobr_upa` = domicílio, `censobr_estrato` = pasta × situação (18.400 estratos), `censobr_fpc` = 1/4 — com dois pesos: `censobr_weight`, calibrado por `raking_1960_amostra_127()` (Deville-Särndal, distância logit, fatores entre 0,25 e 3) a três margens por unidade da federação — município × situação da Sinopse Preliminar, reescalada para somar o total definitivo da UF, mais sexo × onze faixas etárias (tabela 33) e sabem ler de 5 anos e mais por sexo (tabela 40) dos resultados definitivos: a Sinopse dá a forma municipal, que a Série Nacional não publica, e a Série Nacional dá a escala, que é a mesma a que a amostra de 1,27% calibra, o que remove o viés de 1,2% da safra preliminar e evita a descontinuidade nas fronteiras estaduais do banco compilado (peso de 1,00 a 11,77, mediana 3,93; colapso da margem municipal que nunca abandona a âncora, 9.958 domicílios, registrado em `censobr_weight_nivel`; saem a menor célula municipal e a faixa de idade ignorada, e Fernando de Noronha, com 75 domicílios, fica só com o total por sexo; Serra dos Aimorés calibra inteiramente à Série Nacional por não ter contagem completa; a circularidade — as tabelas das dezessete foram apuradas com esta mesma amostra — fica declarada e a variância pelos resíduos não se publica), e `censobr_weight_ibge`, que reproduz o método publicado com peso inteiro 3/4/5 e semente fixa à Sinopse. Alto Garças é o único município inteiramente ausente da amostra — perdeu-se a pasta 91008, a única falha na sequência das 211 de Mato Grosso — e a sua população se redistribui pelo estado, que fecha. A validação reproduz as tabelas 32, 33, 34, 37 e 40 da Série Nacional com erro mediano de 0,003% na condição de presença e 0,000% na idade por sexo (margens da calibração), 0,13% na cor e 0,14% na alfabetização (que não são) e 0,29% na situação (o corte urbano/rural da Sinopse difere do dos definitivos), contra 1,2% sistemáticos de `censobr_weight_ibge`; os erros amostrais dão CV de 0,027% a 0,067% e efeito de desenho de 1,31 a 3,22, e a comparação registro a registro com a amostra de 1,27% casa 143.077 dos 143.223 domicílios (99,90%) — com o município divergindo em 0,10% e a situação em 0,64%, contra 8,65% no tipo de construção, que é desacordo entre as duas transcrições. Documentos em `references/microdata_1960_amostra_25_preparacao.md` e `_desenho_amostral.md`. **A compilação das duas** é o bloco `# 01c.`, em `R/microdata_1960.R`, e é ela que produz os dois parquets que o `censobr` distribui (substituiu o bloco `# 01.`, que só renomeava colunas da compilação antiga do `release_legacy`). É uma **partição por unidade da federação**, e não uma fusão: nas dezessete em que as duas existem a de 1,27% é subamostra da de 25% e empilhar duplicaria gente. Dezessete unidades vêm da amostra de 25% e onze da de 1,27% (RO, AC, AM, RR, PA, AP, MA, PI, ES, GB, SC), que são exatamente aquelas apuradas pelo Boletim Geral completo — ali a calibração se ancora em contagem completa, e não na própria amostra. Resultado: **3.097.387 domicílios e 15.145.810 pessoas**, expandindo **70.191.146 presentes contra 70.191.370 publicados** (−0,0003%) — a primeira vez que os microdados de 1960 fecham o Brasil. A partição resolve sozinha dois problemas dos estágios: o Distrito Federal, que na amostra de 1,27% ficava no peso de desenho e 60% abaixo, vem da de 25%; e Alto Garças se redistribui por Mato Grosso, que fecha. Os três identificadores são refeitos aqui e são únicos no país (`UF × 10.000.000 + sequência`), porque na amostra de 25% a numeração reinicia em cada unidade e a chave do questionário tem 58 repetições nas onze. O desenho compilado é de **duas etapas** nas duas metades — `censobr_upa`/`censobr_fpc` (domicílio e 1/4 nas dezessete, pasta e 1/20 nas onze) e `censobr_usa`/`censobr_fpc2` (domicílio; 1 nas dezessete, onde não há segunda etapa, e 1/4 nas onze) — com 18.421 estratos e 3.066.511 unidades primárias, e nenhum estrato ou unidade primária mistura as duas metades, de modo que **uma chamada só de `svydesign` descreve o país**. Os 75 estratos da amostra de 1,27% foram refeitos sobre as onze (só 23 sobreviviam ao corte, dois com uma pasta), dando 21 estratos em 146 pastas. A geografia traz a unidade de 1960 e a de hoje lado a lado (`code_state_1960`/`code_state`, `name_region_1960`, `code_muni_1960`/`code_muni`): Guanabara 34→33, Fernando de Noronha 20→26, Serra dos Aimorés sem código nos dois. Todos os pesos das duas metades vão na tabela, com NA do lado que não os tem. Validação em `validate_1960()`: a população presente fecha **exatamente nas onze unidades** e o Brasil fecha nas tabelas 33, 34 e 37. Três limitações a declarar: a **cor não é confiável nas onze** (dano de fita; amarelos 36% abaixo), o **corte urbano/rural não é confiável em RO, AC, AP e RR** (o sorteio não alcançou pasta rural), e as onze unidades são 1% dos registros e 18% da população, **dominando o erro-padrão de qualquer estimativa nacional**. Documento em `references/microdata_1960_compilacao.md`, dicionário coluna a coluna em `references/microdata_1960_compilacao_dicionario.csv` e conferência contra o `survey` em `references/conferencia_desenho_compilado_1960.R` | `download_1960_amostra_127()` para a de 1,27%; a compilação antiga não tem download |
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

### Detecting republication (IBGE FTP)

`checa_ftp_censobr()` runs at the top of `_targets.R`, on the script's evaluation, and therefore on every `tar_make()`. For each of the seven IBGE FTP sources it fetches what the server is serving right now — url, file, date and size of every file, from a single request to the Apache index (a lone file URL goes by HEAD) — compares it with the fingerprint cached in `./data_raw/ftp_fingerprints/`, and calls `tar_invalidate()` on the download target of the source that changed, and only on that one. It always prints a line (`FTP: 7 fontes conferidas, nenhuma mudanca`): if that line ever stops appearing, the check stopped running, and that is how you notice.

Without this the pipeline is blind to republication: `raw_*_paths_*` is `format = 'file'` and `targets` compares the hash of the local files, which does not change when IBGE swaps theirs — which is how the 14/09/2026 republication of the 2022 microdata (new variable `P0115`) went unnoticed for two days. The addresses of the seven sources (`microdata_2000|2010|2022`, `tracts_2000|2010|2022|2022_prelim`) live in `FTP_CENSOBR` (`R/support_fun.R`), used by the check and by the download functions, which call `ftp_fingerprint_censobr()` themselves for the listing. If the FTP does not answer, the fingerprint falls back to the cached one, so an unreachable server never blocks a `tar_make()` that needs no download.

The check lives outside the DAG on purpose. A sentinel target with `cue = tar_cue(mode = "always")` gives the same guarantee structurally, and was tried first, but nothing downstream of an always-run target can be declared up to date in advance, so `tar_outdated()` and `tar_visnetwork()` painted all 25 FTP-fed targets as outdated for good. Outside the DAG the graph only goes blue when there is real work. The cost is that the guarantee now rests on a side effect during the evaluation of `_targets.R`, which `targets` does not document as supported (measured to work on 2026-09-16); the printed line is the canary.

Expect ~9 HTTP requests on every `tar_make()`, `tar_outdated()` or `tar_visnetwork()`, even when nothing is to be downloaded.

The sources that do not come from the FTP — 1960/1970/1980/1991 from `release_legacy`, 1960 sample from `antrologos/ConsistenciaCenso1960Br` — are not checked.

## Code layout

All code lives in `R/`, sourced by `targets::tar_source('./R')`. One file per (edition × type) — `microdata_<year>.R`, `census_tracts_<year>.R` — each exposing a `download_*` → `clean_*` → `save_*` trio wired as a numbered block (`# 01.` to `# 11.`) in `_targets.R`. Shared code is in `support_fun.R`, `add_geography_cols.R`, `convert_raw_to_parquet.R`, `schema_col_classes.R`, `release_legacy.R` and `type_convention.R`.

The legacy standalone scripts that preceded the pipeline (folder `R_ainda_sem_targets/`) were removed after every edition was ported; they remain in git history up to commit `18d2ac7`.

When adding a new year or table, add the trio in `R/` and a numbered block in `_targets.R`; do not add standalone scripts.

## Shared utilities (`R/support_fun.R`)

Centralized helpers used throughout the pipeline. Reuse before reinventing:

- `download_file_censobr()` — parallel httr2 downloads with timeout/SSL handling (replaces older `RCurl`/`curl` calls).
- `unzip_censobr()` — base R `unzip()` with a `system2("unzip", ...)` fallback for files that fail. Skips a zip whose extraction is already on disk intact (every entry present with the declared size), so a download target can re-run without re-extracting tens of GB.
- `FTP_CENSOBR` / `ftp_fingerprint_censobr(fonte)` — the registry of IBGE FTP addresses and the remote fingerprint (file, date, size) that makes the pipeline notice republication. See "Detecting republication" below.
- `add_state_info()` / `add_region_info()` — robust state/region code+name imputation; tolerates historical spellings (e.g. `Goyaz`, `Districto Federal`, `Guanabara`) — important for pre-1960 data.
- `dicionario_municipality` / `dicionario_state` + `rename_cols_censobr()` — fuzzy column-name standardization across heterogeneous IBGE exports.
- `write_censobr_parquet()` — the canonical writer (zstd level 22). Always use this instead of `arrow::write_parquet` directly.
- `GEO_COLS_CENSOBR` / `relocate_geo_cols_censobr()` — the fixed order of the censobr geography columns, moved to the front of every table in every `save_*` (works on data.frame, data.table and arrow lazy queries).
- `UF_SIGLAS` — 27-state vector. Note that 2010 SP comes in two pieces: `SP_Capital` and `SP_Exceto_Capital`.
- `pick_latest_per_uf()` — when IBGE re-publishes a UF zip with new date suffix (e.g., `RS_20231030.zip` → `RS_20241211.zip`, `GO_20231030.zip` → `GO_20250915.zip`), keeps only the most recent. Used in `download_tract_2010` for FTP listing + local cleanup.
- `get_areas_ponderacao_2010()` — crosswalk `code_tract → code_weighting` (2010 weighting areas) from IBGE's `Documentacao_microdados_2010.zip`. Replaces the old `geobr` source.

`R/add_geography_cols.R` adds `code_muni`, `code_state`, `name_state`, `code_region`, etc. Pay attention to its year-specific source column map (1980→`V2`, 1991→`V1101`, 2000→`V0103`/`V0102`, 2010→`V0002`/`V0001`, 2022→`CD_MUN`). When adding a new year, extend the `case_when` blocks there.

## Read guides and schemas

- `read_guides/*.csv` — fixed-width parsing dictionaries with columns `int_pos`, `fin_pos`, `var_name`, `length`, `decimal_places`, `col_type`. Consumed by `convert_raw_to_parquet()` via `readr::read_fwf`. Decimal handling is implicit: values are divided by `10^decimal_places` post-read.
- `R/schema_col_classes.R` — `get_schema(year, dataset)` returns hardcoded `arrow::schema()` objects per (year, dataset), used only when **reading** raw files (it keeps integer widths consistent across states). The **published** types come from `schemas/censobr_types.csv` via `cast_censobr_types()` — see "Type convention" below.

## Known data quirks (don't "fix" these — they are real)

- **2010 tracts RS**: `RS_20231030.zip` is explicitly deleted in favor of `RS_20241211.zip` (see `census_tracts_2010.R:48`).
- **2000 tracts zips store filenames in latin-1**: read in R they come out as invalid multibyte strings, and `nchar`/`grepl`/`file.info` all abort on them. `unzip_censobr()` detects this with `validUTF8()` and goes straight to extraction instead of trying to compare what is already on disk.
- **`ÿ` character corruption** in some 2010 xls files (e.g. `Pessoa07_CE.xls`, `Entorno05_RO.xls`) — currently stripped to empty string.
- **Goiás 2010 `Pessoa02`** (and SP) has malformed `V01`–`V09` column names (vs. `V001`–`V009` elsewhere); fix is wired in `read_single_file_tract_2010` (issue #68 — covers GO, SP1, SP2).
- `code_weighting` for 2010 tracts is read from the IBGE source file `Composição das Áreas de Ponderação.txt` inside `Documentacao_microdados_2010.zip` via `get_areas_ponderacao_2010()` in `R/support_fun.R`. (Was previously joined from `geobr::read_census_tract(year = 2010)`, but `geobr ≥1.10` no longer exposes that column.)

## Data bugs

The five `ipea/censobr` issues on 2010 tracts (#68, #70, #71, #73, #75) were fixed in this pipeline in 2026-05-03/04 (commits `57c571a`, `c51f55c`); no data issue is open. Defects found in the IBGE source files — as opposed to in our processing — are catalogued in `references/carta_ibge_levantamento.md`, which is the basis of the letter to IBGE.

## Type convention — one declared type per column (`schemas/censobr_types.csv`)

Decided 2026-09-13 (memory entry [`project_conventions_v0_6_0.md`](C:/Users/antro/.claude/projects/d--Dropbox-Software-R-Packages-censobr-e-prepData-censobr-prep-data/memory/project_conventions_v0_6_0.md)); supersedes the 2026-05-03 rule "`code_*` always float64".

Every column of every published parquet has its type declared in `schemas/censobr_types.csv` (13.347 rows: dataset, coluna, tipo_atual, tipo_alvo and the measured stats), applied by `cast_censobr_types(x, dataset)` (`R/type_convention.R`) as the last step of every `save_*`, after `code_cols_to_numeric()`. The rule is mechanical, derived from measuring every value: `name_*`/`abbrev_*`/`situacao` → string; any non-numeric value → string; any decimal → float64; integral values that fit ±2.147.483.647 → int32; otherwise float64. No int8/int16 (Arrow aborts with `Invalid: overflow` on element-wise arithmetic), no int64 (dplyr refuses joins of integer64 with double, which breaks the geobr joins), no float32 (corrupts weights). **No bool either**: 1960 is the first edition with logical columns — `censobr_favela`, `censobr_muni_corrigido`, the coherence flags — and they come out as 1 and 0 under the rule. Decided 2026-09-16; the published dictionary documents them as 1 = Sim, 0 = Não. The declared type for these 15 columns moved once, and the reason is worth knowing: while the parquet still held BOOLEAN, duckdb had nothing numeric to measure and the column fell to the default, float64; once they were written as 0 and 1, the same mechanical rule measures integers that fit and declares int32. The regeneration of 2026-09-16 therefore carries int32 for them, while the parquets on disk keep float64 until 1960 is next rebuilt — the values are the same either way. Leading zeros of text codes are dropped (`V0300` of 2000, `V1102` of 1991 become int32). Columns with the same name in the microdata tables of a year share the type, so joins match. The schema is regenerated by `schemas/derive_censobr_types.R` (run from the project root, ~30 min) whenever a table gains or changes columns, before the `tar_make()` that writes the final parquets; never edit types by hand.

`code_*` columns therefore come out as int32 when they fit (`code_muni`, `code_state`, `code_district`…) and float64 when they do not (`code_tract`, `code_weighting`, `code_subdistrict`, `code_neighborhood`). Users comparing `code_state == "11"` (string, as in v0.5.0) need `code_state == 11`.

## Validation reference

There is **no `dev` branch** on `ipea/censobr` (verified 2026-05-02 — only `main` and `gh-pages`; local Dropbox-synced clones may show stale `origin/dev` ref). The published reference is **v0.5.0** (Jun/2025, 38 parquets). v0.5.0 carries the 2010-tracts bugs fixed in May 2026 — treat it as historical baseline to measure intentional divergence after fixes, not as gold standard.

The pre-release **v0.6.0** (Sep/2025, 8 parquets) is the output of an earlier version of `R/census_tracts_2010.R` (not the current `main` HEAD). Useful as a checkpoint reference but should not be conflated with v0.5.0.

The **canonical column-by-column specification** for 2010/2022 tract parquets is the dictionary CSV from Pedro H. G. F. Souza's private repo, frozen at [`references/phgfsouza_census_tracts/`](references/phgfsouza_census_tracts/) (commit `f895871`, 2026-04-30). Read this in any port that touches setores 2010/2022 to validate output column-by-column. Coverage: 8 parquets for 2010, 9 parquets for 2022. Does NOT cover microdata or pre-2010.

## Row order is not stable between runs (measured 2026-09-16)

The microdata tables are written by streaming from an arrow dataset over the per-UF files (`arrow::write_dataset` in every `save_microdata_*`), and the scanner hands batches to the writer in whatever order they finish. Two runs over the same input therefore give the same records in a different order, and a different byte count: 2022 mortality came out at 5.763.064 and 5.760.102 bytes, 2022 households at 144.134.232 and 144.163.906. The content is identical — same rows, same values, verified by sorting.

What this costs: a rebuild cannot be verified by checksum (compare content, sorted by a key), a re-published asset always looks changed, and row order shifts between releases, so nothing downstream may rely on position. What it does not touch: any analysis that treats the file as a set of records.

Pinning `arrow::set_cpu_count(1)` fixes the order only on small tables (measured: mortality yes, households no — the scanner keeps its own I/O pool). Pinning `set_io_thread_count(1)` as well pushes households from 27 s to over 15 minutes, so it is not a real option. Making the order deterministic would mean writing UF by UF in an explicit loop, appending row groups; not done, and not needed for content reproducibility.

The tract tables go through `write_censobr_parquet()` on a materialized data.table, whose order comes from the code's own `fread`/`rbindlist` sequence; they were not measured.

## Publishing artifacts

Final parquet files are uploaded to GitHub Releases on `ipea/censobr` via `piggyback::pb_upload()` (placeholder commented at the bottom of `_targets.R`). Requires `GITHUB_TOKEN` in `~/.Renviron`. The release tag is the data version (e.g. `v0.3.0`, `v2.0.0`), not a code version.
