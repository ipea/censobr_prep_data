# Plano: porte da amostra PÚBLICA do Censo 2022 para o pipeline `targets`

**Status:** CONCLUÍDO em 2026-09-11 — 4 parquets nacionais construídos e validados
**Data:** 2026-09-11

## Contexto

O IBGE publicou em 31/08/2026 os microdados da amostra do Censo 2022 sob um
modelo de **três níveis de acesso** (Notas metodológicas 03/2026):

| Nível | Geografia máxima | Obtenção | Redistribuível |
|---|---|---|---|
| 1 — Público | **UF** | FTP aberto | **sim** |
| 2 — Controlado | Área de Ponderação | gov.br + termo de confidencialidade, arquivo *fingerprintado* por pesquisador | **não** |
| 3 — Restrito | base completa | Sala de Acesso a Dados Restritos (Rio) | não |

O consumidor `censobr` já trata o nível 2 com
`R/import_microdata22_controlado.R`: o próprio pesquisador importa o zip que
recebeu do IBGE e a função grava parquets no cache local, sem redistribuição.

Este plano trata do **nível 1**: o único que pode virar asset de release do
`ipeaGIT/censobr`. Fecha o item deferred "Microdata 2022 (issue #65)".

## Diferença entre os dois layouts (verificada, não presumida)

Comparação dos dois arquivos oficiais `Layout Microdados CD2022 - acesso
{Público,Controlado}.xlsx`, variável a variável:

- **256 variáveis comuns.** Em TODAS as 256: mesmo rótulo, mesmas categorias,
  mesma largura (INT), mesmos decimais (DEC), mesmo tipo. Zero divergências.
- **Mas a posição FWF difere em 248 das 256.** Os dois layouts são arquivos
  físicos distintos — reaproveitar posições do controlado corromperia tudo.
  Daí a decisão de ler o CSV (com header), não o TXT: a diferença de posição
  some e os nomes de coluna vêm do próprio arquivo.
- **Peso amostral muda de nome entre modalidades:** público `*0110`,
  controlado `*0111` (ambos 3 inteiros + 13 decimais). Mesma variável
  conceitual, código diferente — é a maior armadilha do porte.
- Só no controlado: 7 cols de geografia fina (`*0030`–`*0090`: meso, micro,
  RGInt, RGI, concentração urbana, município, área de ponderação), as versões
  contínuas do que o público traz categorizado (`P0181`/`P0190` idade em anos
  e meses vs `P0180` faixa; `D0181`, `M0171`, `F0181`), os códigos detalhados
  (`P0970` ocupação, `P0980` atividade, `P0411` religião, municípios/países de
  nascimento/residência anterior/trabalho/estudo, `P0750` área do curso) e as
  marcas de imputação correspondentes.

Contagem de variáveis por registro:

| Registro | Público | Controlado |
|---|---|---|
| DOMI (households) | 55 | 64 |
| PESS (population) | 168 | 210 |
| FAMI (families) | 23 | 31 |
| MORT (mortality) | 14 | 25 |

Tratamentos de confidencialidade já aplicados pelo IBGE no nível público
(subamostra de 50% em setores de fração 100%, idade em faixas quinquenais com
topo 80+, supressão local de sexo/idade, supressão global de ~50 domicílios,
recalibração dos pesos): **não desfazer nem "corrigir"**. Em RR, 1.048 pessoas
(1,2%) vêm com `P0150 = 9` e `P0180 = 99` — é supressão, não erro.

## Objetivo

4 parquets nacionais em `./data/microdata_sample/2022/`, no padrão de nome do
repo (`<ano>_<tabela>_<data_version>`) com o sufixo de modalidade decidido em
2026-09-11:

`2022_households.publico_v0.6.0.parquet`, `2022_population.publico_v0.6.0.parquet`,
`2022_families.publico_v0.6.0.parquet`, `2022_mortality.publico_v0.6.0.parquet`.

O `.publico` distingue da amostra de acesso controlado, que tem as mesmas 4
tabelas com colunas diferentes. O consumidor monta o nome por `paste0()`, nunca
o interpreta, então o ponto não quebra parser nenhum.

## Abordagem

Fonte: `ftp.ibge.gov.br/Censos/Censo_Demografico_2022/Microdados_e_Areas_de_Ponderacao/Microdados_de_acesso_Publico/csv/`
— 27 zips por UF (`11_RO.zip` … `53_DF.zip`, ~1,0 GB no total), cada um com
`{Domicilios,Familia,Mortalidade,Pessoas}_<codigo_uf>_publico.csv`
(separador `;`, com header, `na = ""`).

**Lazy do início ao fim.** `arrow::open_delim_dataset()` sobre os 27 CSVs da
tabela, schema declarado, cols de geografia por `mutate`, gravação por
streaming. Nada de 27M linhas × 168 colunas em RAM (regra memory-discipline).

**Um único target por tabela** (não o par `clean_`/`save_` das outras
edições): um target intermediário obrigaria o `targets` a serializar ~5 GB de
Pessoas para `_targets/objects/`. O ganho de granularidade não paga o custo.

## Arquivos a modificar

- [ ] `R/microdata_2022.R` (novo) — `download_microdata_2022()` e
      `save_microdata_2022(raw_paths, dataset_name)`.
- [ ] `R/schema_col_classes.R` — adicionar ramo `year == 2022` a `get_schema()`
      com os 4 schemas do layout PÚBLICO. Regra de tipagem (a mesma que o
      consumidor documentou para o controlado): `DEC > 0` → `float64()`;
      senão `INT <= 2` → `int8()`, `3-4` → `int16()`, `5-9` → `int32()`.
      O layout público não tem `INT >= 10`, então não há `int64()`.
      Exceção: `F0101`/`M0101` carregam letras (`"F001"`, `"M001"`) → `string()`.
- [ ] `_targets.R` — preencher o bloco `# 06. microdata 2022`.

## Decisões

1. **CSV, não TXT.** As posições FWF divergem entre layouts; o CSV traz header.
2. **Códigos brutos preservados** (`D0110`, `P0150`, …), como nas outras
   edições e como o consumidor faz no cache do controlado. Sem recodificação:
   rótulos são responsabilidade do `add_labels_*` no consumidor.
3. **Geografia inline**, não via `add_geography_cols()`: o público só tem
   região e UF, e o nome da coluna de origem muda por tabela
   (`D0020`/`P0020`/`F0020`/`M0020`) — algo que a assinatura `(arrw, year)`
   daquela função não expressa. Além disso `year == 2022` já está ocupado lá
   por `CD_MUN` (setores). Produz: `code_region`, `name_region`, `code_state`,
   `abbrev_state`, `name_state`, à frente das demais.
4. **`code_*` numeric (v0.6.0)** aplicado na criação da coluna
   (`as.numeric(P0020)`), não via `code_cols_to_numeric()` — que é `dplyr`
   sobre data.frame e quebraria o lazy.
5. **Supressões do IBGE mantidas** (sexo 9, idade 99).

## Validação — resultado

- [x] Smoke test em RR antes das 27
- [x] `tar_make()` dos 4 alvos passa, sem warning próprio
- [x] Reconstruído em 2026-09-11 com **arrow 25.0.0** (após `renv::restore()`)
      e com o nome novo: mesmas linhas, colunas e pesos da build com arrow 23
- [x] Linhas batem exatamente com os CSVs brutos:

| Tabela | Parquet | Linhas | vs CSV | Colunas |
|---|---:|---:|---|---:|
| households | 137,3 MB | 7.689.914 | OK | 60 (55+5) |
| population | 609,8 MB | 21.538.508 | OK | 173 (168+5) |
| families | 95,1 MB | 6.550.107 | OK | 28 (23+5) |
| mortality | 5,5 MB | 430.961 | OK | 19 (14+5) |

- [x] 27 UFs presentes, zero NA em `abbrev_state`
- [x] **Pesos batem com o SIDRA (t/4709) em todas as 27 UFs, diferença 0%.**
      Brasil: 203.080.756 = população oficial do Censo 2022
- [x] Nenhuma coluna 100% NA em nenhuma das 4 tabelas — a tipagem do schema
      está correta em todas as 265 colunas
- [x] `code_*` em `double` (v0.6.0); `F0101`/`M0101` em `string`; pesos em `double`
- [x] Supressões do IBGE preservadas: `P0150 = 9` em 19.216 pessoas
- [x] **`Controle` é único nacionalmente**: 7.689.914 valores distintos para
      7.689.914 domicílios — o join domicílio↔pessoa não precisa da UF na chave
      (o plano supunha o contrário)
- [x] Sem baseline v0.5.0: 2022 microdata é dataset novo, não há paridade a medir

## Riscos

1. **Colisão de nome no cache do consumidor.** `import_microdata22_controlado()`
   grava `2022_population_<release>.parquet` no cache — exatamente o nome que
   um asset público do release teria. Um sobrescreve o outro, e os dois têm
   colunas diferentes (`P0111` + geografia fina vs `P0110`). É decisão do lado
   do consumidor (PR em `ipeaGIT/censobr`), mas precisa ser resolvida antes de
   publicar o release.
2. **Volume.** ~9 GB de CSV extraído; Pessoas nacional ~27M linhas. zstd-22
   sobre isso é demorado. Medir no smoke test antes de rodar as 27 UFs.
3. **`Controle` (`*0100`) provavelmente só é único dentro da UF** — join
   domicílio↔pessoa no consumidor precisa de (UF, Controle). Verificar e
   documentar.
