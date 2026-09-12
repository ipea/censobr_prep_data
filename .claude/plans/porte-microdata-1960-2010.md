# Plano: trazer os microdados de 1960 a 2010 para o `targets`

**Status:** RASCUNHO — aguardando decisões do usuário
**Data:** 2026-09-11

## Contexto

Hoje o pipeline `targets` produz 22 dos 38 parquets publicados em v0.6.0 — só os
setores (2000, 2010, 2022) — mais os 4 novos de microdados 2022. Os **15
parquets de microdados de 1960 a 2010 não são reproduzíveis por `tar_make()`**:
saíram dos scripts legados em `R_ainda_sem_targets/`, que leem CSVs preparados
manualmente e carregam paths absolutos de outra máquina (`R:/Dropbox/...`).

Como o objetivo declarado do projeto é o pipeline 100% reprodutível, esse é o
buraco central. O 1960 chegou a ser portado (commit `e5c3491`) e foi
**comentado** no `_targets.R` pelo Rafa em 27/jul, porque os dados não existiam
na máquina dele — o sintoma exato do problema.

## Objetivo

Um bloco `targets` por edição (1960, 1970, 1980, 1991, 2000, 2010), no formato
do 2022: `download_*` → `clean_*` → `save_*`, saída
`<ano>_<tabela>_<data_version>.parquet`, e nenhuma dependência de pasta local.

15 parquets: 1960 (2), 1970 (2), 1980 (2), 1991 (2), 2000 (3), 2010 (4).

## Achado principal: só DUAS edições precisam de `release_legacy`

Levantamento de 2026-09-11, um agente por edição, com HEAD nas URLs do FTP:

| Edição | Tabelas | Fonte canônica | Precisa `release_legacy`? | Volume |
|---|---|---|---|---|
| 1960 | households, population | **só o compilado do Rogério** | **SIM** | 434 MB (2 arquivos) |
| 1970 | households, population | FTP IBGE (zip 263 MB, FWF) | não¹ | — |
| 1980 | households, population | aux CSV (decidido) | **SIM** | 5,83 GiB ⚠️ |
| 1991 | households, population | FTP IBGE (zip 674 MB, DBF) | não² | — |
| 2000 | households, population, families | FTP IBGE (27 zips, 891 MB) | não | — |
| 2010 | households, population, mortality, emigration | FTP IBGE (28 zips, 1,1 GB) | não | — |

¹ exceto `crosswalk_munic_1970_to_2010.rda` (49 KB) — cabe no repo ou no release.
² a rota FTP perde `V0102` (ver decisão B).

**Ou seja: 4 das 6 edições ficam 100% reprodutíveis a partir do FTP.** O
`release_legacy` existe para 1960 e 1980 — exatamente as duas edições cujo dado
bom não está no FTP.

## O `release_legacy`

Release do próprio repo hospedando os insumos que não existem no FTP do IBGE,
de onde o `download_*` baixa. Resolve a dependência do Dropbox e destrava o
1960 na máquina do Rafa.

Conteúdo proposto:

| Arquivo | Hoje | Proposta |
|---|---:|---|
| 1960 domicílios (`.fst`) | 82,8 MB | converter para parquet (~25-40 MB) e eliminar a dependência do pacote `fst` |
| 1960 pessoas (`.parquet`) | 331,2 MB | como está |
| 1980 domicílios (`.csv`) | 464,8 MB | converter para parquet |
| 1980 pessoas (`.csv`) | **5,37 GiB** | **converter para parquet** (~0,5 GB) |
| `crosswalk_tocantins_ferNoronha_1980_2010.xlsx` | 11 KB | como está |
| `crosswalk_munic_1970_to_2010.rda` | 49 KB | como está |

⚠️ **O CSV de pessoas de 1980 não cabe como asset**: o GitHub limita 2 GiB por
arquivo e ele tem 5,37 GiB. Repacotar para parquet resolve tamanho e tempo de
leitura de uma vez.

**Eu não crio nem publico release nenhuma.** O que este plano entrega é (a) os
arquivos repacotados, prontos, e (b) a função `download_*` que os consome. O
upload é do usuário.

## Blockers transversais já identificados

1. **`convert_raw_to_parquet()` está quebrado para 2000/2010.**
   - `cols_integer64 <- subset(dic, decimal_places == 0 & length > 8)` nunca
     casa (nos read guides `decimal_places` é `NA` ou `> 0`, nunca `0`), então
     `V0011` (13 dígitos) cai em `as.integer` e estoura int32 → **`code_weighting`
     100% NA**. Confirmado por dry-run em RR: 165 de 165 NAs.
   - `code_muni` sai com **5 dígitos** em vez de 7 (`add_geography_cols` usa
     `V0002` sozinho; o correto é `V0001` + `V0002`). Dry-run RR: `50` em vez de
     `1400050`.
   - A coluna `length` dos read guides **não é a largura do campo** — é o número
     de dígitos da parte inteira. A largura real é `fin_pos - int_pos + 1`.
     Divergem em 19 linhas somando as 4 tabelas de 2010.
2. **`get_schema(2010, "households")` e `(2010, "mortality")` não existem** —
   caem fora de todos os `if` e erram com `object 'sss' not found`.
3. **`add_geography_cols`, ramo 1980: `code_micro` recebe `V3`** (mesorregião),
   e `V4` (microrregião) é ignorada. O dado publicado está errado nessa coluna.
4. **Ordem das linhas é semântica em 1970 e 1991.** O `household_id` de 1970
   nasce de `na.locf` sobre a sequência original do IBGE, e a delimitação de
   domicílio de 1991 é `cumsum(V0098 == 1)`. Qualquer reordenação quebra a
   paridade — em particular, não usar `convert_raw_to_parquet()`, que faz
   `setorderv` nas 15 primeiras colunas.
5. **Memória.** Nenhuma edição cabe em RAM inteira: 2010 population projeta
   ~37,6 GB; 1970 são 24,8M × 54; 1991 SP sozinho dá 4-5 GB em `read.dbf`.
   Todas exigem staging por UF com `rm` + `gc()` entre elas, e consolidação
   lazy com `arrow::open_dataset()`.
6. **Quirks de arquivo em 2000:** `RN.zip` contém uma cópia byte-idêntica dos 3
   arquivos da **PB** (um glob ingênuo duplica a Paraíba inteira, silenciosamente),
   e `BA.zip` traz **zips aninhados** (`PES29.zip`, `FAMI29.zip`) — sem segunda
   passada de unzip, a Bahia some de population e families.

## Decisões (2026-09-11)

| # | Decisão | Status |
|---|---|---|
| A | 1980: repacotar os CSVs do aux para parquet | **APROVADA** |
| B | 1991: FTP (perde `V0102`) ou `release_legacy` | **PENDENTE** — ver seção abaixo |
| C | 1970: FTP, reimplementando a derivação do `household_id` | **APROVADA** |
| D | 2000/2010: parsing inline por ano; `convert_raw_to_parquet()` fica intocada | **APROVADA** ("por enquanto") |
| E | 1980: corrigir `code_micro` (recebe `V3`; deve receber `V4`) | **APROVADA** — verificado: `code_micro == code_meso` em 6.716.885 de 6.716.885 linhas; 89 valores distintos onde `V4` tem 361 |
| F | 1980: dropar a coluna `Observation` | **APROVADA** |
| G | 1960: converter o input `.fst` para parquet | **APROVADA** |

### Decisão B — o que é a `V0102` de 1991 e por que ela importa

`V0102` = **"Identificação do Questionário"**: o número único de cada
domicílio pesquisado, presente nos registros de domicílio e de pessoa. É a
chave que liga pessoa a domicílio. 4.024.543 valores distintos para
4.024.543 domicílios — chave primária perfeita.

Tem 9 dígitos com estrutura: `UF(2) + bloco(4) + domicílio(3)`. O bloco do
meio é uma unidade **submunicipal** — 27.819 blocos no país, ~145 domicílios
cada, quase todos contidos num único município. É o mais próximo de unidade
de amostragem/ponderação que 1991 oferece.

**Por que a rota FTP perde:** o zip do FTP traz 27 DBFs em nível de pessoa
(`CD91AMOUP<UF>.DBF`, 141 campos), sem arquivo de domicílio e sem nenhum
campo de identificação de questionário. O mapping gold de 12 agentes não
encontra origem para `V0102` em nenhum dos 141 campos.

**O que dá para reconstruir:** o *agrupamento* pessoa→domicílio, 100%, via
`cumsum(PESSOAN == 1)` na ordem original do DBF (RR: 5.486 grupos = 5.486
domicílios; AC: 9.824 = 9.824; variáveis de domicílio constantes dentro de
cada grupo). **O que não dá:** o código em si e, com ele, o bloco
submunicipal. Casamento por impressão digital (município + `CD107` + peso +
cômodos + água + nº de pessoas) chega a 98,7% em RR e tende a piorar em SP.

Opções:
1. FTP + chave sintética (`iddomicilio` por `cumsum`): reprodutível, mas os
   códigos mudam vs v0.5.0 e o bloco submunicipal some.
2. FTP + crosswalk de 4 M linhas no `release_legacy`: recupera ~99%.
3. **`release_legacy` para 1991, como 1960 e 1980** — CSVs do aux repacotados
   em parquet (~0,5-1 GB). Preserva `V0102` exatamente. Coerente com o
   princípio já adotado para 1980: quando a versão preparada é melhor que a
   do FTP, ela é a canônica.

### Correção sobre os quirks de 2000

Verificado com `unzip -v` e CRC-32: **`RN.zip` traz RN *e* PB** (6 arquivos,
não 3). Os arquivos `*25*` dentro dele são byte-idênticos aos de `PB.zip`
(mesmos CRC: `2313d407`, `da05e397`, `15f63adf`). Nada está faltando; o risco
é **duplicar** a Paraíba (+487.848 pessoas, +117.577 domicílios, +128.391
famílias — inflação de 2,4% no total nacional, silenciosa). `BA.zip` traz
`DOM29.txt` direto e **`PES29.zip` / `FAMI29.zip` aninhados**; o `pes29.txt`
interno vem em minúsculas. Sem segunda passada de unzip, a Bahia
(1.598.126 pessoas, 7,9% do país) some. Os parquets publicados estão
corretos (24 = 390.126, 25 = 487.848, 29 = 1.598.126) — quem os montou tratou
isso à mão. Achado lateral: `2000_population` publicado tem **1 linha
fantasma** com `code_state = "\032"` (byte EOF do DOS).

## Ordem de execução e situação

1. **1960** — ✅ **FEITO**. `R/microdata_1960.R` com `download_` do
   `release_legacy`, bloco `# 01.` reativado. Saída idêntica à build de maio
   (3.097.328 × 35 e 15.145.824 × 66, primeiras 5.000 linhas iguais).
2. **1980** — ✅ **FEITO**. `R/microdata_1980.R` reescrito pela rota do aux.
   households 6.716.885 × 38 e population 29.378.753 × 99, distribuição por UF
   e somas idênticas ao publicado; `code_micro` corrigida (361 valores),
   `Observation` removida, `V518` preservada.
3. **1991** — ✅ households / ⏳ population. `R/microdata_1991.R` pela rota do
   `release_legacy` (decisão B = opção 3). households bate **exatamente** com o
   publicado: 4.024.543 × 58, `V0102` com 4.024.543 distintos, 0 NAs em
   `code_muni`, 4.491 municípios, mesma soma de pesos. Inclui a correção do
   Itapipoca (ver `references/microdata_1991_ftp_vs_aux.md`).
4. **2010** — ✅ **FEITO**. FTP puro, `R/microdata_2010.R`. As 4 tabelas com
   linhas e colunas idênticas ao aux (6.192.332 × 83, 20.635.472 × 251,
   111.555 × 26, 53.777 × 26), distribuição por UF idêntica, e
   **`sum(V0010)` = 190.755.799 = a população oficial do Censo 2010**.
   `code_weighting` com 0 NAs — o bug do `convert_raw_to_parquet()` não
   acontece porque o parsing é inline.
5. **2000** — ⏳ families e households prontos, population construindo.
   `R/microdata_2000.R`, FTP. **Restaura as 24 colunas** que faltavam no aux:
   190 colunas contra 169, batendo com v0.5.0. Fecha o item MAJOR dos
   deferred priorities.
6. **1970** — código escrito (`R/microdata_1970.R`), execução pendente.

### Os dois defeitos de empacotamento de 2000, confirmados no arquivo

- **`RN.zip` traz seis arquivos, não três**: os do Rio Grande do Norte
  (código 24) e uma cópia integral da Paraíba (código 25), byte a byte igual à
  de `PB.zip`. Nada falta; o risco é duplicar a PB (+487.848 pessoas,
  inflação de 2,4% no total nacional, silenciosa). Tratado por um filtro que
  só aceita, de cada pasta de UF, o arquivo cujo código bate com o da própria
  UF.
- **`BA.zip` tem zip dentro de zip** (`PES29.zip`, `FAMI29.zip`), e o arquivo
  interno vem em minúsculas (`pes29.txt`). Sem o laço de descompactação, a
  Bahia entra só com domicílios e somem 1.598.126 pessoas. Tratado.

### 1970: o que a investigação resolveu

- **O registro FWF não tem campo de UF** — ela vem do nome do arquivo. O
  código de UF de 1970 sai do próprio `crosswalk_munic_1970_to_2010.rda`
  (coluna `state_1970`), sem depender do CSV aux.
- **A chave de município** é `uf*1e5 + (V001 %% 100)*1e3 + V002`, que resolve
  95% das linhas. As exceções são apenas duas, e estão no crosswalk:
  `2531000` = Guanabara → Rio de Janeiro (1.104.952 pessoas) e `3600000` =
  Distrito Federal → Brasília (135.571). Uma cascata de três chaves cobre as
  24.793.358 linhas.
- **A ordem dos arquivos é alfabética pelo nome em maiúsculas** (AC..SP) —
  confirmado: a primeira linha do CSV aux é Acre com `V001=11, V002=101`,
  idêntica à primeira linha de `DAMO70AC.txt`; a última é São Paulo, com
  `idpessoa` = 24.793.358.
- **O read guide não existia** e foi montado do `layout_1970.xlsx`: 54
  variáveis, posições 1 a 76, sem buraco nem sobreposição, e o registro do
  FWF tem exatamente 76 caracteres. A soma estimada de linhas dos 27 arquivos
  dá 24.793.358, o número exato esperado.
- `idpessoa` é a própria ordem da linha, então o `household_id` derivado se
  aplica ao registro de pessoas **por posição**, sem join.

### Conteúdo final do `release_legacy` (pronto em `data/release_legacy/`)

| Arquivo | Tamanho |
|---|---:|
| `Censo.1960.brasil.domicilios.amostraCompilada.censobr.parquet` | 22,6 MB |
| `Censo.1960.brasil.pessoas.amostraCompilada.censobr.parquet` | 243,0 MB |
| `Censo.1980.brasil.domicilios.amostra.25porcento.parquet` | 37,4 MB |
| `Censo.1980.brasil.pessoas.amostra.25porcento.parquet` | 446,4 MB |
| `Censo.1991.brasil.domicilios.amostra.10porcento.parquet` | 66,6 MB |
| `Censo.1991.brasil.pessoas.amostra.10porcento.parquet` | 595,9 MB |
| `crosswalk_tocantins_ferNoronha_1980_2010.xlsx` | 11 KB |

Total ~1,4 GB, todos abaixo do limite de 2 GiB por asset. O CSV de pessoas de
1980, que tinha 5,37 GiB e não caberia, virou 446 MB.

## Validação (por edição)

- Smoke test em RR ou AC antes das 27 UFs (`test-first-protocol`).
- Contagem de linhas contra o parquet publicado em v0.6.0 e/ou contra o aux.
- `setdiff` de colunas nos dois sentidos contra o publicado.
- Nenhuma coluna 100% NA que não seja NA na origem.
- Soma dos pesos contra a população conhecida do censo do ano.
- Divergências intencionais documentadas em `references/`.
