# Plano: porte de microdata 1970/1980/1991 para o pipeline `targets`

**Status:** APROVADO Opcao A (FTP estrito, FWF parsing). 2026-05-05.
**Data:** 2026-05-05
**Audiencia:** decisao arquitetural sobre fonte do raw input.

## Contexto

Setores 100% fechados (2000/2010/2022). Microdata 1960 fechado (commit
`e5c3491`). Proximo eixo: microdata 1970/1980/1991. Os 3 anos seguem padrao
similar (V cols numericas, escola, renda, raca, geografia 6-digit muni)
diferindo no tamanho da amostra (1970: 25%, 1980: 25%, 1991: 10%).

## Investigacao realizada

### v0.5.0 baseline publicado

6 parquets em `ipea/censobr` v0.5.0:
- `1970_households_v0.5.0.parquet` + `1970_population_v0.5.0.parquet`
- `1980_households_v0.5.0.parquet` + `1980_population_v0.5.0.parquet`
- `1991_households_v0.5.0.parquet` + `1991_population_v0.5.0.parquet`

### Legacy scripts em `R_ainda_sem_targets/`

| Ano | Arquivo(s) | Padrao |
|---|---|---|
| 1970 | `microdata_sample_1970a_household_ids_and_dataset.R` (data.table, 200 linhas) + `microdata_sample_1970b.R` (60 linhas, le CSVs preparados) | **2 etapas:** (a) constroi household_id agregando pessoas; (b) le CSVs → renomeia → geo → save |
| 1980 | `microdata_sample_1980.R` (185 linhas) | le 2 CSVs → geo crosswalk via `geobr` → save |
| 1991 | `microdata_sample_1991.R` (270 linhas, com muito gc) | le 2 CSVs → geo crosswalk via `geobr` → save |

Todos os 3 chamam `add_geography_cols(year=<ano>)` (em `R/`) que tem branches
historicos (MS pertencia a MT, TO a GO em 1970/1980; cols de meso/micro em
1991).

### FTP IBGE

- `https://ftp.ibge.gov.br/Censos/Censo_Demografico_1970/Microdados/Microdados_Censo_Demografico_1970_Amostra.zip` (250 MB)
- `https://ftp.ibge.gov.br/Censos/Censo_Demografico_1980/Microdados/Microdados_Censo_Demografico_1980_Amostra.zip` (519 MB)
- `https://ftp.ibge.gov.br/Censos/Censo_Demografico_1991/Microdados/Microdados_Censo_Demografico_1991_Amostra.zip` (642 MB)

**Total download:** ~1.4 GB. **Total descompactado** (estimativa): 15-45 GB.

**Conteudo do zip 1970** (inspecionado, 263 MB → 1.94 GB descompactado, 37 entries):
- `Dados/Damo70<UF>.txt` × 27 (FWF puro, naming case-misto: `DAMO70AC.txt`, `Damo70BA.txt`, `DAMO70PI.TXT`).
- `Documentação.doc` (com layout/dicionario).
- `Instrumento de Coleta/Manual do Agente Censitario.pdf` + `Questionario da Amostra.pdf`.
- `Arquivos Auxliares/V027.txt`, `V030.txt`, ... (codigos de variaveis).
- `Divisão Territorial do Brasil/Região Sul.xls`.

Notes criticos:
- **NAO tem CSV** — eh FWF puro, preciso de layout pra parsear.
- "Damo" provavelmente eh "Domicilios + Amostra" no formato hierarquico antigo do IBGE (cada linha de domicilio seguida por linhas de pessoas inline; precisa de inspecao de bytes pra confirmar).
- Naming case inconsistente (precisa pattern-match case-insensitive).

1980 e 1991 a confirmar via inspecao analoga, mas espera-se padrao similar.

### Aux mirror local (existente)

`censoBR_aux_Dados/<ano>/microdados da amostra/`:

| Ano | households CSV | population CSV | Notes |
|---|---|---|---|
| 1970 | 425 MB **agregado** (com `household_id`, `wgthh`, etc.) | 3.9 GB raw | Households ja eh resultado do script 1970a; population eh raw 24.793.358 linhas |
| 1980 | 487 MB raw (V cols) | 5.7 GB raw | Ambos raw |
| 1991 | 537 MB raw (V cols) | 5.5 GB raw | Ambos raw |

**Total:** ~16 GB de CSVs ja existem localmente.

### Dicionarios locais (em `dicionario/`)

- `layout_<ano>.xlsx` — layout FWF original IBGE para FWF parsing.
- `domicilios<ano>_via_PedroSouza.xlsx` + `pessoas<ano>_via_PedroSouza.xlsx` — dicionarios de variaveis.
- 1970: `crosswalk_munic_1970_to_2010.rda`
- 1980: `crosswalk_tocantins_ferNoronha_1980_2010.xlsx`
- 1980: `Variaveis_Auxiliares/` (codigos complementares IBGE)
- 1970, 1991: `arquivos_auxiliares/` (txt dictionaries por variavel)

### Pipeline existente em R/

- `R/add_geography_cols.R` — branches por ano (1960, 1970, 1980, 1991, 2000, 2010, 2022). 1970/1980/1991 ja tem mapeamento.
- `R/convert_raw_to_parquet.R` — **NAO** cobre 1970/1980/1991 (apenas anos com read_guides).
- `R/schema_col_classes.R` — **NAO** cobre 1970/1980/1991.
- `read_guides/` — **NAO** tem read_guides para 1970/1980/1991 (apenas 2000+2010).

## Decisao arquitetural fundamental

O pedido foi **"baixando e abrindo direto do FTP"**. Mas a realidade do projeto
mostra:

1. **Pipeline NUNCA fez parsing FWF→CSV** para 1970/1980/1991. Os CSVs
   localmente foram gerados pelo Rogerio em 2018 (1980/1991) e
   compilados/atualizados em set/2024 (1970).
2. **Read guides nao existem** para FWF parsing desses anos.
3. **Layout files (`layout_<ano>.xlsx`) existem** mas precisam ser convertidos
   pra read_guides format.

### 3 opcoes ordenadas por esforco

#### Opcao A — FTP estrito (FWF parsing do zero)

Honra literalmente o pedido. Etapas:
1. Baixar 3 zips IBGE (1.4 GB).
2. Descompactar (15-45 GB).
3. Inspecionar formato real do conteudo (FWF txt, ou CSV?).
4. Se FWF: converter `layout_<ano>.xlsx` em `read_guide_<ano>.csv` (formato `int_pos`/`fin_pos`/`var_name`/`length`/`decimal_places`/`col_type`). Criar 3 read_guides (households + pop por ano = 6 arquivos), validar parsing.
5. Estender `convert_raw_to_parquet()` ou criar `convert_raw_to_parquet_<ano>()`.
6. Para 1970, replicar a logica de agregar pessoas → households_id (script `1970a` virou parte do pipeline).
7. Aplicar geo crosswalks via `geobr` (1980 tocantins, 1970/1991 munic codes).
8. Aplicar `add_geography_cols(year)`.
9. Validar contra v0.5.0.

**Tempo estimado:** 2-4 dias. **Riscos:**
- Encoding antigo (latin1/cp850 vs utf-8) requer testes.
- Layout files podem ter erros/imprecisoes; inferimos posicoes a tentar.
- Validacao indireta (input diferente do que gerou v0.5.0; pode haver diffs sutis em transformacoes IBGE entre versoes do raw).
- Volume de raw descompactado (multi-GB) precisa de gestao de disco.

**Pros:** 100% reproduzivel em qualquer maquina (FTP eh canonico).

#### Opcao B — Reusar CSVs locais (replica legacy)

Como microdata 1960 ja portado. Etapas:
1. Apontar pra CSVs em `censoBR_aux_Dados/<ano>/microdados da amostra/`.
2. Para 1970, executar/portar o script `1970a` que constroi household_id (ou usar o households CSV ja agregado).
3. Aplicar transformacoes dos legacy scripts: rename, geo crosswalk, `add_geography_cols`.
4. Save parquet com convencao v0.6.0.
5. Validar contra v0.5.0.

**Tempo estimado:** 2-4 horas. **Riscos:**
- Nao reproduzivel sem os CSVs locais (16 GB).
- Mas: replica o caminho que gerou v0.5.0 (validacao direta).

**Pros:** Rapido, valida bit-by-bit contra v0.5.0, ja tem todos os crosswalks/dicionarios.

#### Opcao C — Faseado (recomendado)

1. **Agora:** Opcao B. Fecha 6 parquets v0.6.0 alinhados com v0.5.0. Replica legacy.
2. **Futuro:** Opcao A em sessao dedicada (movido pra deferred priorities).
   Marcado em `project_deferred_priorities.md` como "Download FTP para
   microdata 1970-2010" (item LONG-TERM).

Justificativa: o projeto JA reconhece (em deferred priorities) que "Trazer
FWF de 2010 microdata para aux" e "Download FTP para microdata 1970-2010"
sao trabalhos LONG-TERM. Opcao A nao eh requisito do MVP. Faseando, ganhamos
parquets v0.6.0 funcionais agora, e atacamos a reprodutibilidade FTP depois
com mais rigor.

## Plano detalhado da Opcao B (recomendada)

Se aprovado, execucao em 4 fases.

### Fase 1 — Inventario + smoke test (1h)

1.1 Confirmar que CSVs locais existem nos 3 paths esperados.
1.2 Smoke test: ler 1000 linhas do menor CSV (1970 households, 425 MB) → confirmar parse sem erro, schema esperado.
1.3 Baixar baseline v0.5.0 dos 6 parquets via `gh release download` para tempdir, inspecionar schemas (colunas, tipos, nrow). Idem ao approach do 1960.
1.4 Para CADA dataset (households+population × 3 anos = 6), produzir tabela de cols esperadas em v0.6.0 baseado em v0.5.0.

### Fase 2 — Implementacao (4-6h)

2.1 Criar `R/microdata_1970.R`:
- `clean_microdata_1970(aux_paths, dataset_name)` — branch por dataset.
- Para `households`: le `Censo.1970.brasil.domicilios.amostra.25porcento.csv` (ja agregado), aplica renames do legacy 1970b lines 27-35.
- Para `population`: le `Censo.1970.brasil.pessoas.amostra.25porcento_rogerioSetembro2024.csv`, faz left_join com `crosswalk_personid_hhid.csv` para anexar `household_id`, dropa cols CEM/iddomicilio, renames.
- Em ambos: `code_state = substr(code_muni, 1, 2)` + `add_geography_cols(year=1970)`.
- Cast num_vars para numeric conforme legacy.

`save_microdata_1970(cleaned_df)` — `code_cols_to_numeric` (v0.6.0) + `write_censobr_parquet`.

2.2 Criar `R/microdata_1980.R`:
- `clean_microdata_1980(aux_paths, dataset_name)` — branch por dataset.
- Le CSV → uppercase v→V → constroi `code_muni_1980 = V2*10000 + V5` → join crosswalk tocantins/fer_noronha → join `geobr::read_municipality(1980)` para code_muni de 7 digitos → `add_geography_cols(year=1980)` → cast numeric vars.
- `save_microdata_1980` analogo.

2.3 Criar `R/microdata_1991.R`:
- `clean_microdata_1991(aux_paths, dataset_name)`.
- Le CSV → uppercase v→V → padding zeros em `V1102` (4 digits) → `code_muni6 = paste0(V1101, V1102)` → join geobr 1991 → drop code_muni6 → `add_geography_cols(year=1991)` → cast vars (lista grande de num_vars do legacy linha 213-217) → fix V7300/V7301 weight (/10^8).
- `save_microdata_1991` analogo.

2.4 Adicionar 3 blocos no `_targets.R`:
```r
# 02. microdata 1970 -----
tar_target(aux_microdata_1970_paths, c(<3 paths>), format = "file"),
tar_target(dataset_names_microdata_1970, c("households","population")),
tar_target(clean_microdata_table_1970, clean_microdata_1970(...), pattern = map(...)),
tar_target(output_microdata_1970, save_microdata_1970(...), pattern = map(...), format = "file"),

# 03. microdata 1980 ----- (idem)
# 04. microdata 1991 ----- (idem)
```

### Fase 3 — Execucao (1h por ano, ~3h total)

3.1 `tar_make(names = "output_microdata_1970")`. Volume: ~25M pessoas, ~3M domicilios. zstd-22 vai dominar tempo (~15-20 min cada parquet).
3.2 Idem 1980, 1991.

### Fase 4 — Validacao + commit (30 min)

4.1 Comparar 6 parquets vs v0.5.0 baseline:
- Linhas: match exato.
- Colunas: `setdiff` vazio em ambas direcoes.
- Tipos: `code_*` numeric (intencional v0.6.0).
4.2 Documentar diffs em `references/divergencias_v050_v060_microdata_1970_1980_1991.md`.
4.3 Commit + push.

## Estrutura proposta de funcoes (estilo procedural)

3 arquivos separados (1 por ano), cada um ~80-150 linhas. Sem helper functions
exceto onde reuso justifica (geobr lookup por exemplo, mas aqui cada ano tem
seu proprio crosswalk → inlinar). Estilo do user (procedural, sem
`.dot_prefixed`, comentarios curtos).

## Riscos da Opcao B

1. **CSVs locais nao versionados.** Mover, deletar ou modificar quebra o pipeline. Mitigacao: documentar em CLAUDE.md que `censoBR_aux_Dados/` eh dependencia opacas pra esses anos.
2. **1970 dependencia em 2 CSVs (pessoas + crosswalk_personid_hhid).** Crosswalk tem 499 MB; precisa estar em aux.
3. **Encoding latin1.** CSVs antigos podem ter encoding latin1; legacy resolve via leitura padrao do data.table/arrow. Validar no smoke test.
4. **`add_geography_cols(year)` ja foi refatorado** (commit `9a76554`). Se branches 1970/1980/1991 da funcao tem bugs, vamos achar so agora.
5. **Validacao incompleta sem download v0.5.0.** Precisa baixar 3 GB do release v0.5.0 pra validar. Usar `gh release download` com `tempdir`.

## Decisoes a confirmar com o usuario

1. **Opcao A, B, ou C?** Recomendacao do plano: **C** (B agora, A depois). Decisao do usuario.
2. **Convencao v0.6.0 `code_*` numeric?** Aplicar como nos outros anos. Default sim.
3. **Estilo das funcoes:** 3 arquivos separados (1 por ano) ou 1 unico `microdata_1970_1991.R`? Recomendacao: **3 arquivos separados** — cada ano tem dicionario, crosswalk e renames bem distintos.
4. **`add_geography_cols(year)` chamada?** Sim — branches existem em R/, e v0.5.0 obviamente as usou.

## Ordem de execucao sugerida (apos aprovacao)

1. Smoke test em 1970 (Fase 1) — confirmar premissas em UF pequena.
2. Implementar microdata_1970 (Fase 2.1) + targets (parte 2.4).
3. tar_make 1970 + validacao vs baseline (Fase 3+4 para 1970).
4. Repetir para 1980 e 1991.
5. Commit consolidado.