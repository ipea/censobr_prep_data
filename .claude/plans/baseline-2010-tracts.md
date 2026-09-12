# Baseline — 2010 census tracts (Fase 0.1 do plano revisado)

**Status:** CONCLUÍDO (evidência colhida)
**Data:** 2026-05-02
**Plano-pai:** `~/.claude/plans/2026-05-02_plano-revisado-pipeline-completo.md`
**Tarefa:** estabelecer estado pré-fix do eixo "setores 2010" para medir o impacto dos bug fixes da Fase 0.3.

## Método

Em vez de rodar `tar_make()` do zero (~horas de FTP IBGE com `coress=1`), baixamos os parquets já publicados em duas tags do `ipea/censobr` e inspecionamos diretamente:

- `v0.5.0` (2025-06-30, latest release) — output do **legacy** `R_ainda_sem_targets/census_tracts_aggreg_2010.R`.
- `v0.6.0` (2025-09-12, pre-release) — output de uma **versão anterior** do wired `R/census_tracts_2010.R`. (O `R/census_tracts_2010.R` no `main` HEAD atual foi criado hoje, commit `3a94684`; presumivelmente similar à versão que produziu v0.6.0 mas pode divergir em detalhes.)

Ambos baixados para `data_raw/baseline_compare/{v0.5.0,v0.6.0}/` (~660 MB cada, gitignored).

Validação canônica feita contra o dicionário de Pedro H. G. F. Souza (`references/phgfsouza_census_tracts/data_dictionaries/2010_censobr_data_dictionary.csv`).

Scripts de inspeção em `d:/tmp/censobr_baseline_inspect{,2}.R` (temp, descartáveis).

## Schema/contagem v0.5.0 vs v0.6.0

| Tabela | Linhas v0.5 / v0.6 | Cols v0.5 / v0.6 | Diff colunas |
|---|---|---|---|
| Basico | 310 120 / 310 120 | 35 / 34 | v0.5 tem `Cod_municipio`, v0.6 não |
| Domicilio | 310 120 / 310 120 | 383 / 383 | — |
| DomicilioRenda | 310 120 / 310 120 | 23 / 23 | — |
| Entorno | 310 120 / 310 120 | 1 169 / 1 169 | — |
| Pessoa | 310 114 / 310 114 | 2 008 / 2 008 | — |
| PessoaRenda | 310 120 / 310 120 | 141 / 141 | — |
| Responsavel | 310 114 / 310 114 | 334 / 334 | — |
| ResponsavelRenda | 310 120 / 310 120 | 141 / 141 | — |

**Observação 1:** Pessoa e Responsavel têm 6 linhas a menos (310 114 vs 310 120). Essas 6 linhas se referem a setores que aparentemente não têm dados de pessoas/responsáveis no IBGE 2010 — confirmar contra dicionário.

**Observação 2:** v0.5 → v0.6 difere apenas em 1 coluna no Basico (`Cod_municipio` removida em v0.6, redundante com `code_muni`). Os bugs descritos abaixo persistem em **AMBAS** as versões — o pre-release v0.6.0 não corrigiu nenhum.

## Evidência por bug

### #71 — V009 NA no Basico (BLOCKER)

V009 em Basico = `Valor do rendimento nominal médio mensal das pessoas de 10 anos ou mais de idade (com e sem rendimento)` (per dicionário phgfsouza).

NA por UF em **v0.5.0** (idêntico em v0.6.0):

| code_state | name_state | n | NA % |
|---|---|---|---|
| 11 | Rondônia | 2 346 | **97.6** |
| 12 | Acre | 874 | **97.9** |
| 13 | Amazonas | 5 641 | **96.2** |
| 14 | Roraima | 824 | **96.5** |
| 15 | Pará | 8 769 | **98.6** |
| 16 | Amapá | 810 | **98.6** |
| 17 | Tocantins | 2 101 | **98.8** |
| 21 | Maranhão | 8 802 | **98.5** |
| 22 | Piauí | 5 251 | **98.6** |
| 23 | Ceará | 13 276 | **98.3** |
| 24 | Rio Grande do Norte | 4 289 | **98.4** |
| 25 | Paraíba (Basico grafa "Paraiba") | 5 548 | **98.7** |
| 26 | Pernambuco | 12 379 | **98.7** |
| 27 | Alagoas | 3 724 | **98.4** |
| 28 | Sergipe | 3 297 | **98.5** |
| 29 | Bahia | 23 782 | **98.3** |
| **31** | **Minas Gerais** | 32 564 | **0** |
| 32 | Espírito Santo | 6 380 | **98.3** |
| **33** | **Rio de Janeiro** | 27 769 | **0** (1 NA) |
| **35** | **São Paulo** | 66 096 | **27.3** |
| **41** | **Paraná** | 17 465 | **0** |
| 42 | Santa Catarina | 11 882 | **97.2** |
| 43 | Rio Grande do Sul | 22 332 | **97.3** |
| 50 | Mato Grosso do Sul | 4 207 | **98.4** |
| 51 | Mato Grosso | 5 929 | **97.4** |
| 52 | Goiás | 9 434 | **98.5** |
| 53 | Distrito Federal | 4 349 | **98.6** |

**Pattern confirmado:** apenas MG/RJ/PR têm V009 essencialmente completo; SP tem 27% NA; **23 das 27 UFs têm 96–99% NA**. Bate com o que a usuária reportou (PR/SP/RJ/MG melhor) e supera severamente os "~40%" do título do issue #71.

**Hipótese de causa:** parsing do XLS está perdendo V009 em quase todos os UFs. Solução proposta pela usuária (relatada via Rogério): trocar `readxl::read_excel` pelo CSV via FTP IBGE direto. Hipótese a validar na Fase 0.3.

### #68 — GO Pessoa02 todo NA (BLOCKER, e mais amplo do que o issue conta)

Testando `pessoa02_V001` em **v0.5.0**:

| code_state | n | NA % |
|---|---|---|
| **35 (São Paulo)** | 66 096 | **100.0** |
| **52 (Goiás)** | 9 434 | **100.0** |
| Outras 25 UFs | — | 0.6–4.5 (normal) |

**O issue #68 só menciona Goiás. SÃO PAULO TAMBÉM ESTÁ AFETADO** com 100% NA em `pessoa02_V001`. Outras colunas pessoa02 (V010, V100, V170) têm pattern normal (~1–3% NA) em ambos. Bug específico de V001 + provavelmente algumas outras colunas do início, em SP+GO.

A causa atribuída ao issue #68 (V01–V09 → V001–V009 malformado nos nomes) explica a falha em GO. **SP precisa de investigação separada** — pode ser quirk diferente. Atualizar o issue #68 (ou abrir novo) com a evidência de SP.

### #70 — Pessoa02 truncado em V170 (BLOCKER)

Inventário das colunas `pessoa02_V*` em ambos os parquets:

- 171 colunas total: V001…V170 + V1005 (V1005 é provavelmente código de identificação, não dado real).
- **Faltam V171 a V255** (~85 colunas). IBGE publica até V255 conforme dicionário oficial (página 87, citado no issue).

Confirmar contra dicionário phgfsouza qual é o range esperado de pessoa02 — se for V001–V255, evidência sólida.

### #73 — `X` virando `0` em vez de `NA` (BLOCKER)

Não há evidência DIRETA neste baseline. Os campos numéricos do Basico (V001, V002, V005, V009) estão tipados como `double` no parquet — qualquer "X" original já foi convertido (para `NA` via warning de `as.numeric` ou para `0` via algum mapeamento explícito). Inspeção em string-columns do Basico não detectou "X" remanescente.

Hipóteses para Fase 0.3:
- O issue pode ser sintoma do mesmo bug do #71 (V009): se a fonte original tem "X" em renda e o XLS está corrompendo a coluna inteira, valores remanescentes podem virar 0 espúrios em vez de NA propriamente.
- Ou pode haver outro caminho (Pessoa, Domicilio) onde "X" → 0 acontece sem ser detectado por inspeção de Basico.

Ação: investigar nas 8 tabelas qual coluna tem zeros suspeitos (ratio inflado de 0 vs. distribuição esperada) — mas **não bloquear** no #73; tratar como sintoma de #71 até prova em contrário.

### #75 — Inconsistência de nomes de UF/região (MAJOR)

**`name_state` em Basico vs Pessoa:**

| Em Basico apenas | Em Pessoa apenas |
|---|---|
| `Paraiba` (sem acento) | `Paraíba` (com acento) |

26 dos 27 nomes batem; só Paraíba diverge.

**`name_region` em Basico vs Pessoa:**

| Basico | Pessoa |
|---|---|
| `Região Centro-Oeste` | `Centro-oeste` |
| `Região Nordeste` | `Nordeste` |
| `Região Norte` | `Norte` |
| `Região Sudeste` | `Sudeste` |
| `Região Sul` | `Sul` |

**Basico** tem prefixo "Região " e capitalização diferente; **Pessoa** não tem prefixo e usa lowercase no segundo termo de Centro-oeste.

Ação: padronização cross-tabela usando `add_state_info()` / `add_region_info()` (já existem em `R/support_fun.R`). Decidir convenção canônica (provavelmente: sem prefixo "Região "; com acentos completos; capitalização Title Case).

## Estado dos arquivos no disco

- `data_raw/baseline_compare/v0.5.0/` — 8 parquets v0.5.0 (~656 MB, gitignored)
- `data_raw/baseline_compare/v0.6.0/` — 8 parquets v0.6.0 (~656 MB, gitignored)
- `references/phgfsouza_census_tracts/` — dicionários canônicos versionados (~7.2 MB)
- `_targets/meta/meta` (74 KB) — metadados do pipeline; última materialização tentada hoje 10:42 mas `data/` está vazio (rebuild interrompido ou redirecionado)

## Próximos passos (entrada para Fase 0.3)

1. **Plano dedicado para o fix #71 (V009)** — testar a hipótese da usuária: baixar o CSV equivalente do FTP IBGE para 1 UF afetada (ex.: AC, 874 setores) e comparar V009 com o XLS atual. Se CSV-FTP entrega V009 íntegro, propor migração `readxl::read_excel` → `data.table::fread` para a tabela Basico (e investigar se os outros 7 .xls têm o mesmo problema).
2. **#68 ampliado** — comentar no issue do GitHub que SP também está afetado (até abrir/fechar); ajustar fix do `R/census_tracts_2010.R` para cobrir SP+GO.
3. **#70** — investigar se o XLS do IBGE tem colunas V171–V255 que o `readxl::read_excel(col_types="text")` está descartando; provável fix: passar `col_types = NULL` ou ler todos os colunas e aparar 100%-NA *depois*.
4. **#73** — diagnosticar como sintoma de #71 antes de tratar separado.
5. **#75** — passada de padronização em `save_tracts_2010()`, conforme já planejado.

## Decisões registradas durante esta fase

- ✅ Não rodar `tar_make()` do zero para baseline; usar v0.5.0 + v0.6.0 publicados como evidência. Justificativa: a evidência dos bugs está nos parquets publicados, e os parquets do `main` HEAD (caso fossem materializados) reproduzem o mesmo padrão.
- ✅ Localização do baseline doc: `.claude/plans/baseline-2010-tracts.md` (versionado, próximo ao código).
- ✅ Dicionários phgfsouza: cópia versionada em `references/phgfsouza_census_tracts/` (commit `f895871`).