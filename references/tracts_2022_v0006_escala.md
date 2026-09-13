# A `V0006` dos agregados por setor de 2022: proporção no definitivo, percentual no preliminar

**Data:** 2026-09-13 (substitui a versão anterior do mesmo dia)
**Escopo:** Censo Demográfico 2022, agregados por setores censitários, tabela Básico — a `V0006` (domicílios particulares ocupados imputados sobre o total de ocupados) é publicada pelo IBGE em duas escalas, sob o mesmo rótulo, nas divulgações preliminar e definitiva. Os valores estão certos dentro de cada escala; o defeito é de documentação — com uma exceção de 11 setores.

---

## O que se observa

| | preliminar | definitivo |
|---|---:|---:|
| setores | 452.340 | 468.099 |
| setores com `V0007 > 0` | 441.101 | 457.500 |
| mediana de `V0006` | 1,9608 | 0,0193 |
| máximo | 100,0000 | 4,2542 |
| setores no teto exato | 227 (em 100) | 220 (em 1) |
| setores acima do teto | 0 | 11 |

Fator 100 entre as duas. Quem comparar as tabelas pelo nome da variável erra
por duas ordens de grandeza.

## O rótulo

O IBGE descreve a `V0006` com a mesma frase nas duas divulgações e em todas
as safras do dicionário:

> **Percentual de Domicílios Particulares Ocupados Imputados
> (Total DPO imputados / Total DPO)**

O substantivo "percentual" pede 0–100; a fórmula entre parênteses é uma
razão, que vive em 0–1. Não há coluna de unidade, fator de multiplicação nem
nota que desempate; o único metadado de tipo está no dicionário do preliminar
e diz `real`. Fontes conferidas, todas com a mesma frase: o dicionário do
definitivo nas safras 20241115, 20250417 e 20260520; o do preliminar de
20/03/2024; o `2022_dictionary_tracts.xlsx` do release `censo_docs`; e a
transcrição de Pedro Souza em `phgfsouza_census_tracts/`.

## O que decide a escala

O numerador é uma contagem de domicílios e tem de ser inteiro. Reconstruído
o numerador `k` a partir de `V0006` e do denominador, a leitura certa é a que
dá inteiro **e** `k ≤ V0007`.

**Definitivo**, nos 457.500 setores com `V0007 > 0`:

| leitura | `k` inteiro (a 4 casas) | e `k ≤ V0007` |
|---|---:|---:|
| `V0006` como proporção, `k = V0006 × V0007` | 457.500 (100%) | 457.489 |
| `V0006` como percentual, `k = V0006 / 100 × V0007` | 138.846 (30,35%) | 138.846 |

Os 138.846 da leitura percentual são quase só os 138.824 setores com
`V0006 = 0`, que passam em qualquer leitura. Nenhum outro denominador
funciona: `V0002`, `V0003` e `V0001` reproduzem `V0006` em 32,56%, 32,37% e
34,47% dos setores; excluídos os 149.423 com `V0006 = 0`, caem para 2,59%,
2,60% e 5,67%, enquanto `V0007` segue em 100%. E `V0007` é o denominador que
a fórmula declara — "Total de Domicílios Particulares Ocupados (DPPO +
DPIO)".

**Preliminar**, nos 441.101 setores com `V0007 > 0`: como o percentual tem 4
casas sobre 0–100, as duas leituras dão `k` inteiro em 441.101 de 441.101; o
que decide é a restrição `k ≤ V0007` — vale em 169.559 (38,44%) lendo como
proporção e em 441.101 (100%) lendo como percentual.

## A âncora externa

A Nota metodológica n. 06 dos Agregados por Setores Censitários registra que
a imputação atingiu "cerca de 3 milhões de domicílios, representando 4,21% do
total de domicílios ocupados". `sum(V0007)` é 72.522.372 nas duas
divulgações.

| leitura | domicílios imputados | taxa |
|---|---:|---:|
| definitivo como **proporção** | 3.080.911 | 4,25% |
| definitivo como percentual | cerca de 30,8 mil | 0,04% |
| preliminar como **percentual** | 3.076.899 | 4,24% |

O definitivo lido como percentual daria cem vezes menos imputação do que o
IBGE publicou e tornaria impossível o teto que 220 setores atingem.

## Veredito

É a mesma medida em duas escalas: o preliminar honra o substantivo do rótulo
e viola a fórmula; o definitivo honra a fórmula e viola o substantivo. Para
comparar as duas divulgações, multiplica-se o definitivo por 100. O produto
grava os valores como o IBGE os publica, em cada tabela na sua escala.

## A exceção: 11 setores com `V0006 > 1` no definitivo

Nos 11, `V0006` é `k / V0007` arredondado a 4 casas com `k` inteiro (251,
151, 618, 313, 22, 162, 62, 19, 7, 253, 58) **maior que `V0007`** — mais
domicílios imputados do que domicílios ocupados. O produto `V0006 × V0007` só
é inteiro exato em 2 deles (354340210000122: 2,0000 × 11 = 22;
410490705000149: 1,4000 × 5 = 7); nos demais é inteiro a menos do
arredondamento. A hipótese de escala percentual nesses setores não sobrevive:
`V0006 / 100 × V0007` não dá inteiro em nenhum.

Em 2 dos 11 o `k` é reproduzido por outras colunas da linha — no setor
354340210000122, `k = 22 = V0002 = V0003 + V0004 = V0001 − V0002`; no
430660105100006, `k = 62 = V0001 − V0003` —, sem mecanismo comum. Três dos 11
não existem no preliminar (150276405000050, 354340210000122,
410490705000149); nos 8 presentes, com o mesmo `V0007`, o preliminar dá
`k ≤ V0007` e o definitivo dá `k > V0007` (setor 510420305000020,
`V0007 = 39`: `k` = 151 no definitivo, 17 no preliminar). O defeito está na
republicação definitiva.

## O que não está afetado

- A documentação dos setores de 2022 está partida em cinco arquivos: 3.400
  códigos `V` no dicionário do definitivo (`V00001`–`V03950`), 105 nos três
  de entorno e 6 no de renda do responsável — 3.511, contra as 3.501
  variáveis temáticas que a Nota metodológica n. 06 declara. Além de `V0005`
  e `V0006`, não são contagens `V06003` (variância do número de moradores),
  `V06004` (rendimento nominal médio mensal), `V06005` (variância do
  rendimento) e `V06006` (rendimento nominal mediano). `V0006` é a única do
  Básico com problema de escala.
- `V0005` tem a mesma escala nas duas divulgações; o que muda é a precisão —
  o definitivo grava 1 casa decimal (2,8) e o preliminar 6 (2,761905). A
  identidade `V0005 = V0001 / V0007` fecha em 100,0000% dos 408.445 setores
  com `V0004 = 0` e `V0007 > 0`; os 2.136 que pareciam não fechar são empates
  exatos — `|V0005 − V0001/V0007| = 0,05000000` a 17 dígitos — em que o IBGE
  arredonda para cima e o `round()` do R arredonda meio-para-par.
- `V0001` a `V0004` e `V0007` são contagens, razão 1,0000 entre as
  divulgações; a fração de setores que não bate é remalhamento (452.340
  contra 468.099 setores), com `sum(V0007)` idêntica.
- `V0008` (uso ocasional) e `V0009` (vagos) existem só no definitivo, desde a
  republicação 20260520 — por isso não constam da transcrição de Pedro Souza,
  congelada em 30/04/2026. `V0003 = V0007 + V0008 + V0009` em 468.099 de
  468.099 setores.
- O pipeline não altera valor: parquet e CSV do IBGE são iguais em valor — o
  CSV grava texto com vírgula decimal ("0,0923"), o parquet grava `double` —
  em 468.099 de 468.099 setores para `V0001`–`V0009` e `code_tract`, sem NA e
  sem `X`.

Não foram testados os agregados por município, distrito, subdistrito e
bairro, que carregam a mesma `V0006` com o mesmo rótulo.

## Para a carta ao IBGE

O rótulo da `V0006`, idêntico nas duas divulgações, não diz a escala, e a
escala mudou entre elas; e os 11 setores do definitivo com mais domicílios
imputados do que ocupados.
