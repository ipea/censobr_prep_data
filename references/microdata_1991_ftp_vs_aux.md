# Microdados 1991: a fonte do produto, a `V0102` e o que a conferência com o DBF do IBGE corrigiu

**Data:** 2026-09-13 (substitui a versão de 2026-09-11)
**Escopo:** amostra do Censo Demográfico de 1991 — de onde vem o produto `censobr`, o que é a chave `V0102`, por que a republicação em DBF do FTP não serve de fonte mas serve de validação, e o que essa validação mudou no produto.

---

## A fonte do produto

O produto de 1991 é construído a partir da **amostra preparada** — os CSVs
de 2018, hoje convertidos em parquet e hospedados no release `release_legacy`
deste repositório. A republicação em DBF que o IBGE mantém no FTP não serve
de fonte porque não traz a `V0102`, a chave que liga pessoa a domicílio, e
ela não é reconstruível. O DBF é usado apenas como referência de validação.

O zip do FTP tem 673.659.331 bytes e 27 DBFs, um por UF, em
`Dados/Regiao X/CD91AMOUP<código numérico da UF>.DBF` (`…14` é Roraima,
`…12` o Acre, `…35` São Paulo). Está comprimido em Deflate64, que o `zipfile`
do Python e o `java.util.zip` não abrem; o `unzip` 6.00 abre, e os 8,4 GB
passam no teste de CRC. Os arquivos são **em nível de pessoa** — as variáveis
do domicílio se repetem em cada morador e não há arquivo de domicílio — com
141 campos (verificados em RR e AC).

## O que é a `V0102`

"Identificação do Questionário": o número único de cada domicílio
pesquisado, presente nos dois registros. O rótulo consta do layout do IBGE
(de que o `1991_dictionary_microdata_*.html` do release `censo_docs` é
exportação) e do dicionário de Pedro Souza. É chave primária perfeita:
4.024.543 valores distintos para 4.024.543 domicílios.

Tem 9 dígitos, e o cabeçalho do **CD 1.02 — Questionário da Amostra** diz o
que são:

```
1 MUNICÍPIO   2 PASTA   3 Nº NA PASTA
4 DISTRITO  5 SUBDISTRITO  6 Nº DO SETOR  7 QUARTEIRÃO  8 FACE
9 Nº NO CD 1.07   10 Nº NO CD 1.03
```

A `V0102` é **prefixo(2) + PASTA(4) + Nº NA PASTA(3)**. O Manual do
Recenseador (PA 1.09, p. 32) resolve o que é a pasta:

> *"Nada deverá ser registrado nos campos 2 - PASTA e 3 - NÚMERO NA PASTA
> destinados para Uso do Órgão Central."*

O recenseador transcreve da Folha de Coleta só os campos 4 a 9; a pasta é
numeração atribuída centralmente, no processamento — a pasta física em que
os formulários foram arquivados. O dado confirma:

| | medido |
|---|---|
| pastas no país | 27.819 (prefixo de 6 dígitos) |
| questionários por pasta | média 144,7; mediana 154, quartis 135–171 |
| numeração interna | 1..N sem buraco em 87,1%; máximo 708, nunca 999 |
| respeita município | 6 de 27.819 cruzam |
| é unidade de ponderação? | não — 3 de 27.819 têm peso constante; R² 0,218 contra 0,210 só do município |

O prefixo de 2 dígitos **não é a UF**. Vinte e seis UFs usam prefixo igual ao
seu código; São Paulo usa dois, sem município em comum — 28 prefixos para 27
UFs:

| prefixo | municípios | domicílios | |
|---|---:|---:|---|
| 35 | 8 | 344.675 | núcleo metropolitano, inclusive a capital (260.987) |
| 36 | 564 | 534.696 | o resto do estado |

Cada série numera suas pastas a partir de 1 (SP tem 5.528 pastas, longe do
teto de 9.999) — o mesmo padrão "SP Capital / SP exceto Capital" que o IBGE
repete em 2010 nos setores. Por isso a pasta se agrupa pelo prefixo de 6
dígitos; agrupar por (UF, 4 dígitos) daria 25.815 grupos com 2.010 cruzando
município, e é o agrupamento errado.

A pasta não é geografia e não vira coluna `code_*`. A geografia submunicipal
de verdade — distrito, subdistrito, setor, quarteirão e face, campos 4 a 8 —
não está em nenhuma das duas fontes: foi suprimida na divulgação.

## Por que o DBF não serve de fonte

Os 141 campos não incluem nenhuma identificação de questionário; o mapeamento
de colunas (`microdata_1991_col_mapping.csv`) não encontra origem para a
`V0102`. O candidato óbvio, `CD107` (= `V0109`, "Número do Domicílio no CD
1.07"), não é chave: (UF, município, `V0109`) produz 1.285.449 combinações
para 4.024.543 domicílios, 632.153 delas repetidas — a pior (SP, município
5030, `V0109 = 1`) aparece 5.871 vezes.

O **agrupamento** pessoa → domicílio é reconstruível pela ordem: `PESSOAN`
(= `V0098`) reinicia em 1 a cada domicílio, e `cumsum(PESSOAN == 1)` redesenha
as fronteiras — RR dá 5.486 grupos para 5.486 domicílios, AC 9.824 para
9.824, com as variáveis de domicílio constantes dentro de cada grupo; em RO,
porém, dá 26.860 grupos para 26.850 domicílios (ver Ariquemes, abaixo). O
**código** não é reconstruível: não é município (RR tem 8 municípios e 39
pastas), não é situação do setor, não é reinício de `CD107` (320 em RR contra
39). Casar as duas fontes por impressão digital (município + `CD107` + peso +
cômodos + água + moradores) chega a 98,7% em Roraima.

A ordem das linhas é semântica nas duas fontes, e não é a mesma: em RR o DBF
começa com `CD107` = 1, 20, 30, 50… e a amostra preparada com `V0109` = 2,
12, 22, 32…. A amostra preparada tampouco está ordenada pela `V0102`: começa
por SP (prefixo 35), depois 11, 12, … 53; dentro de cada UF a `V0102` cresce
em 26 das 27, e o bloco de prefixo 36 de SP não é crescente. Qualquer
ordenação antes da delimitação de domicílio quebra a chave em silêncio —
`convert_raw_to_parquet()` ordena pelas 15 primeiras colunas.

## Os 59 registros que faltam: Ariquemes

O número de registros de cada DBF sai do tamanho descomprimido, `4545 + n ×
493 + 1`; os 27 dividem exatamente por 493.

| | DBF | produto |
|---|---:|---:|
| pessoas | 17.045.712 | 17.045.653 |

25 das 27 UFs batem exatamente. Rondônia tem −58 e a Bahia −1. Em RO a
diferença é toda de um município:

| **1100023 — Ariquemes** | DBF | produto | faltam |
|---|---:|---:|---:|
| pessoas | 8.511 | 8.453 | 58 |
| domicílios | 1.972 | 1.961 | 11 |

Os outros 22 municípios de RO batem registro a registro. O único domicílio
órfão do produto — `V0102 = 110043042`, na tabela de domicílios sem morador
na de pessoas — é desse município: 10 domicílios sumiram inteiros e 1 ficou
vazio, na preparação da amostra. Não há o inverso: nenhuma pessoa aponta para
domicílio inexistente.

## Itapipoca: um código trocado na malha de 1991 do `geobr`

A camada de 1991 do `geobr` 2.0.1 traz Itapipoca (CE) como `2306045` em vez
de `2306405` — o código que as camadas de 2000, 2010 e 2022 do próprio
`geobr` usam e que v0.5.0 publica (1.525 linhas). Sem tratamento, 1.525
domicílios ficam sem `code_muni` (4.490 municípios em vez de 4.491). Nenhuma
linha do censo tem chave `230604`, então ninguém recebe o código transposto.
`R/microdata_1991.R` corrige o caso após o join.

## O que a conferência com o DBF corrigiu no produto

O árbitro em todos os casos foi o dicionário oficial (`Dicionário 1991.xls`,
que acompanha o zip), não o DBF.

### Tipos decididos por uma lista só

O vetor `num_vars` de `R/microdata_1991.R` era diferente nos ramos de
domicílios e de pessoas, e 11 colunas saíam numéricas numa tabela e string na
outra: `V0098`, `V0102`, `V0109`, `V0111`, `V0112`, `V0209`, `V0211`, `V0212`,
`V2012`, `V2111`, `V2121` — entre elas a `V0102`, a única ponte entre as duas
tabelas. A lista agora é única: 0 colunas com tipo divergente.

### Dois sentinelas fora da faixa do dicionário

Das 132 variáveis com faixa declarada, três a violavam, pelo mesmo defeito:

| tabela | coluna | | declarado | observado | registros |
|---|---|---|---:|---:|---:|
| pessoas | `V2012` | renda domiciliar | ≤ 999999999 | 9999999999 | 552.020 |
| pessoas | `V3045` | renda familiar | ≤ 999999999 | 9999999999 | 515.649 |
| domicílios | `V2012` | renda domiciliar | ≤ 999999999 | 9999999999 | 108.050 |

O dicionário declara `999999998 = NSA` e `999999999 = Ignorado`; a amostra
preparada colapsou os dois num `9999999999` de dez dígitos. O produto grava
`999999999` nos 1.175.719 registros. A distinção NSA/Ignorado se perdeu a
montante e não é recuperável: o DBF a preserva (em RR, `RFAMILIV` tem 1 NSA e
2.375 Ignorado), a amostra preparada não. Fora do sentinela, `V3045` é
idêntica a `RFAMILIV` — dos 23.102 registros de RR, os 2.376 que diferiam são
os 2.375 sentinelas e 1 NA.

### A renda familiar per capita, reconstruída

`RFAPCAPV` (10.8 no dicionário) é a única variável substantiva do dicionário
ausente da amostra preparada; as outras quatro sem correspondência (`UFNOM`,
`MESONOM`, `MICRONOM`, `MUNICNOM`) são rótulos que o produto carrega como
`name_*`. A faixa correspondente, `RFAPCAPF` → `V3049`, sempre esteve
presente e é idêntica à do DBF.

A regra do denominador foi determinada contra o `RFAPCAPV` do IBGE, em
Roraima, no nível de pessoa:

| denominador | exato ao centavo | dentro de 1 centavo |
|---|---:|---:|
| todos os membros da família | 68,25% | 95,30% |
| excluindo pensionista e empregado doméstico | 69,43% | 96,93% |
| **excluindo pensionista, empregado e parente do empregado** | **69,49%** | **97,01%** |
| excluindo também o agregado | 64,17% | 89,51% |

O agregado conta como membro, como em 1970. Os códigos excluídos são
`V0303` (parentesco com o chefe da família) 14 e 15, e `V0302` (parentesco
com o chefe do domicílio) 14, 15 e 16 — 1991 tem a categoria 16, "parente do
empregado doméstico", que 1970 não tem. O resíduo de 3% é aritmética do IBGE:
41.000 ÷ 6 dá 6.833,33 e o DBF grava 6.833,31; a mesma conta feita nas duas
fontes é idêntica ao centavo (5.228 famílias de RR, quantis batendo em todos
os pontos).

A tabela de pessoas ganhou `numb_family_members` e `family_income_per_cap`.
`numb_family_members` é NA em 12.816 pessoas — pensionistas, empregados e
parentes de empregados cuja família não tem nenhum outro membro contado.
`family_income_per_cap` é NA em 529.499: 515.649 com renda familiar ignorada
(`V3045 = 999999999`), 1.431 com `V3045` NA e 12.419 das 12.816 sem
denominador (as outras 397 já estão entre as de renda ignorada).

## Diferenças em relação ao publicado em v0.5.0

Domicílios: 4.024.543 linhas e 58 colunas, na mesma ordem; 0 NA em
`code_muni`; 4.491 municípios; soma de pesos (`V7300`) 35.435.725. Diferem:

| coluna | linhas | natureza |
|---|---:|---|
| `V2012` | 108.050 | `9999999999` → `999999999` |
| `name_region` | 276.692 | "Centro-oeste" → "Centro-Oeste" |
| `code_muni`, `code_state`, `code_region`, `code_meso`, `code_micro`, `code_metro` | tipo | `int32` → `double` |

Pessoas: `V2012` (552.020) e `V3045` (515.649) com o sentinela do dicionário;
duas colunas novas (`numb_family_members`, `family_income_per_cap`); `V1102`
continua gravada com zeros à esquerda (4 dígitos). A geografia entra inline,
não por `add_geography_cols()`, como em 1980 e 2022.

## Para a carta ao IBGE

Da republicação em DBF: a ausência de qualquer identificação de questionário
(a `V0102`), que impede ligar pessoa a domicílio sem depender da ordem das
linhas; e a supressão da geografia submunicipal (campos 4 a 8 do CD 1.02) nas
duas divulgações. O sentinela de dez dígitos e os 59 registros de Ariquemes
são da amostra preparada, não do IBGE.
