# Os pesos da amostra de 1980: `V603` e `V604`

**Data:** 2026-09-13 (substitui a versão de 2026-09-12)
**Escopo:** o peso de domicílio (`V603`) e o peso de pessoa (`V604`) da amostra do Censo Demográfico de 1980 — o que são, por que o produto `censobr` os entrega exatamente como o IBGE, zeros inclusive, e o que a geografia de 1980 exige do produto.

---

## Os dois pesos reproduzem as tabelas publicadas do IBGE na unidade

| Peso | Soma no dado | Fonte oficial | Diferença |
|---|---:|---|---:|
| `V603` (domicílio) | 25.210.639 | SIDRA t206, domicílios particulares permanentes, 1980 | 0 |
| `V604` (pessoa) | 119.011.052 | SIDRA t200/t202, população residente (amostra), 1980 | 0 |

A igualdade de `V603` vale em 40 células: Brasil, as 26 UFs, as duas
situações (urbana 17.770.981 / rural 7.439.658) e as 11 classes de número de
cômodos, inclusive "sem declaração" (81.968). A de `V604`, em 23 marginais:
Brasil, 2 sexos, 2 situações, 17 grupos etários e idade ignorada. Todas
exatas.

A tabela 206 do SIDRA por UF soma 25.210.413; Fernando de Noronha só aparece
no total Brasil, e os 226 que faltam nas UFs são os 69 domicílios do
território, ponderados. A republicação em DBF de 2025 (26 UFs, sem Noronha)
soma os mesmos 25.210.413; a amostra preparada, que é a fonte do produto e
tem os 69, soma 25.210.639.

Os zeros, portanto, não são lacunas: são parte do estimador com que o IBGE
produziu suas tabelas. Qualquer imputação faz o produto deixar de
reproduzi-las.

## `V603`: onde estão os zeros

6.716.885 domicílios, 233.399 com `V603 = 0` (3,47%), nenhum NA, valores
inteiros de 0 a 21.

| `V201` (espécie) | domicílios | `V603 = 0` |
|---|---:|---:|
| 1 — particular permanente | 6.483.541 | 55 |
| 3 — particular improvisado | 27.487 | 27.487 (100%) |
| 5 — coletivo permanente | 184.497 | 184.497 (100%) |
| 7 — coletivo improvisado | 21.360 | 21.360 (100%) |

### O zero é a sentinela de "não se aplica" do IBGE

No DBF de 2025, `PESOD = 0` é solidário a outras **20** variáveis do mesmo
registro, que recebem sua sentinela de NSA na mesma linha: 14 recebem `0` —
TIPO, SANUSO, TPRESID, COMODOS, COMODOR, FOGAO, COMBCOZI, TELEFONE, ILUMINA,
RADIO, GELADEIR, TV, AUTOMOVE e ALUGUEL — e 6 recebem um dígito não-zero
(PAREDES = 1, PISO = 2, COBERTUR = 8, AGUA = 8, SANESCOA = 1, CONDOCUP = 8). A
planilha de layout declara a variável-irmã `PESOP` como `INTEGER, 0 - 30,
NSA=0`.

O questionário de domicílio não foi aplicado a esses 233.344 registros. No
produto, 20 das 21 variáveis substantivas do bloco são NA em todos eles;
`V603` é a única que mantém o `0`. (`V211`, tempo de residência, já vem NA da
amostra preparada — no DBF, `TPRESID` é `0`; `V212`, `V213` e `V602` passaram
a NA neste pipeline.)

### O zero não foi criado pelo pipeline

- Na fonte (`release_legacy`, `Censo.1980.brasil.domicilios…parquet`), `V603`
  vem como string com 233.399 valores `"0"`, soma 25.210.639.
- No DBF do IBGE o campo vem literalmente `" 0"`, alinhado à direita; não há
  brancos em `ESPECIE = 1` em nenhuma das 26 UFs.
- O publicado em v0.5.0 é idêntico registro a registro: bijeção sobre as
  6.716.885 chaves `(V2, V5, V6, V601)`, zero divergências. Os mesmos números
  estão em v0.3.0 e v0.2.0.

### Os 55 domicílios particulares permanentes com peso zero

São os únicos zeros dentro do universo ponderado, e vêm do IBGE: o DBF de
2025 tem 54 casos de `ESPECIE = 1` e `PESOD = 0`, os mesmos registros campo a
campo; o 55º é de Fernando de Noronha, que o DBF não carrega.

São registros completos — nenhum campo vazio, 1 a 11 cômodos; 20 têm aluguel
diferente de zero, 17 com valor real (120 a 2.000 Cr$) e 3 com a sentinela
`999999`. Dos 160 moradores, 159 têm `V604 > 0` e um tem `V604 = 0`. O perfil
não é aleatório: 29 municípios em 11 UFs (MG 14, BA 12, AM 7, SP 7, PB 6, AL
3, RN 2, FN/MA/PI/SC 1); proprietários com imóvel já pago (`V209 = 1`) em 5,5%
(3 de 55) contra 55,5% na espécie 1 (55,7% ponderado); próprio em qualquer
condição (`V209 ∈ {1, 3}`) em 7,3% contra 61,2%; unipessoais em 30,9% contra
6,5%.

O decisivo é aritmético: os 55 já estão embutidos nos 25.210.639 publicados.
Imputá-los com a média nacional de `V603` (3,888439) somaria +213,86
(0,000848%), levando a soma a cerca de 25.210.853; com a mediana do próprio
município, +188,11. Qualquer das duas quebraria 23 das 40 células que hoje
batem exatamente — Brasil, 10 das 26 UFs, as 2 situações e 10 das 11 classes
de cômodos — e o teste do consumidor `censobr`
(`tests/testthat/test_read_households.R:111`), que exige
`sum(V603) == 25210639`.

## `V604`: os 42 zeros

Na fonte há 42 pessoas com `V604 = 0`, nenhum NA, soma 119.011.052:

| | pessoas | onde |
|---|---:|---|
| espécie 1, domicílio com peso (`V603 > 0`) | 18 | zeros isolados |
| espécie 1, domicílio sem peso | 1 | morador de um dos 55 |
| espécies 3 e 5 (improvisado, coletivo) | 23 | domicílio fora do universo |

Uma versão anterior do pipeline imputava os 42 pela mediana do município,
calculada com `stats::median()` sobre `arrow` *lazy* — que não é a mediana
exata, é o quantil aproximado por t-digest. O resultado injetava
151,3239878020747824 de peso (soma 119.011.203,324) e gravava sete pesos
fracionários, com seis valores distintos (3,133333; 3,968721;
4,068571428571428; 4,138022; 4,950980; 5,931026), num campo que o IBGE declara
`INTEGER`. A imputação foi revertida: o produto tem soma 119.011.052, 42
zeros e nenhum peso fracionário.

## A decisão

`V603` e `V604` são entregues como o IBGE entrega. Nada é imputado — nem os
233.344 estruturais, nem os 55, nem os 42.

- Imputar os 233.344 levaria `sum(V603)` a cerca de 26.117.880 (+3,6%) sobre
  registros sem nenhum dado de domicílio, e sobre um conjunto de coletivos que
  a amostra preparada já traz incompleto (faltam 169.976 registros de espécie
  5 e 7 em relação ao DBF, todos de peso zero).
- Zero é a codificação canônica de "fora do universo" em estimadores de
  survey, tratada corretamente inclusive na variância; `survey::svydesign()`
  recusa pesos NA; e `sum(V603)` devolve o número oficial sem filtro. Por isso
  os zeros dos pesos não viraram NA — ao contrário das variáveis do bloco
  (`V212`, `V213`, `V602`), em que zero cômodos é impossível e o NA não perde
  informação.

## Conformidade com o dicionário

Confrontadas as 89 variáveis dos dois dicionários oficiais com as 38 colunas
do parquet de domicílios e as 99 do de pessoas: nenhuma variável do
dicionário falta; há uma coluna extra (`idpessoa`, chave do pipeline); e, em
46 categóricas comparadas valor a valor, existe um único valor observado não
declarado: `V605 = 99` (28.946 casos).

O layout de 1980 não declara categoria alguma para 26 das 89 variáveis —
`V3`, `V4`, `V5`, `V6`, `V601`, `V602`, `V212`, `V213`, `V603`, `V604`,
`V518`, `V527`, `V530`, `V532`, `V536` a `V539`, `V542`, `V544`, `V546` a
`V549`, `V557` e `V570` —, entre elas três substantivas do bloco de domicílio:
aluguel, total de cômodos e dormitórios. Pelo menos 35 variáveis usam `9`/`99`
para "ignorado", 21 usam branco para "não se aplica" e 7 usam `98` para "a
ser imputado".

## Geografia: o produto segue a malha de 1980

Regra: o 1980 do `censobr` tem de casar com
`geobr::read_municipality(year = 1980)`.

Em v0.5.0, `code_muni` era NA em 35.567 domicílios — 35.498 em Goiás e 69 em
Fernando de Noronha —, porque o crosswalk
`crosswalk_tocantins_ferNoronha_1980_2010.xlsx` reescrevia esses 53 municípios
para o código de 2010 (prefixos 17, Tocantins, e 26, Noronha), inexistentes
na malha de 1980. O produto não aplica o crosswalk à geografia: `code_muni`
sai do join de `code_muni_1980` com a malha de 1980, e os 3.991 códigos do
dado resolvem todos, inclusive os 53 — Fernando de Noronha é `2000107`,
território 20; os 52 futuros municípios do Tocantins ficam em Goiás
(`520040 → 5200407`, Almas/GO).

A malha do `geobr` para 1980 traz só `code_muni`, `name_muni`, `code_state` e
`abbrev_state`; para o código 20 a sigla é NA e "Fernando de Noronha" aparece
apenas como `name_muni`. Os rótulos `FN`, `Fernando de Noronha`, região 2 e
`Nordeste` foram criados neste pipeline, porque `states_censobr()` só traz as
27 UFs de hoje. O crosswalk deixou de ser usado em `clean_microdata_1980()`;
`download_microdata_1980()` continua a trazê-lo.

Nas duas tabelas: zero NA nas 9 colunas de geografia e zero códigos fora da
malha de 1980 (3.991 distintos).

| coluna | linhas que divergem de v0.5.0 | natureza |
|---|---:|---|
| `code_muni` | 35.567 | NA → valor; nenhum valor já preenchido mudou |
| `abbrev_state`, `name_state` | 69 | NA → `FN`, `Fernando de Noronha` |
| `code_region` | 0 | — |
| `V603` | 0 | — |
| `name_region` | 411.557 | "Centro-oeste" (v0.5.0) → "Centro-Oeste" |
