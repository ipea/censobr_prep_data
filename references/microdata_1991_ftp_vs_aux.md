# Microdados 1991: DBF do FTP IBGE × amostra preparada

**Data:** 2026-09-11
**Motivo:** decidir qual é a fonte canônica do porte de 1991 para o `targets`

---

## Conclusão

A **amostra preparada** (CSVs de 2018, hoje convertidos em parquet no
`release_legacy`) é a fonte canônica. A republicação em DBF do FTP perde a
`V0102` — a chave que liga pessoa a domicílio — e ela não é reconstruível.

## O que é a `V0102`

**"Identificação do Questionário"**: o número único de cada domicílio
pesquisado, presente nos dois registros. Rótulo idêntico em quatro fontes
independentes (layout_1991.xlsx, dicionários do Pedro Souza para domicílios e
pessoas, e o `1991_dictionary_microdata_*.html` do release `censo_docs`).

É chave primária perfeita: **4.024.543 valores distintos para 4.024.543
domicílios**, zero repetição.

Tem 9 dígitos com estrutura interna `UF(2) + bloco(4) + domicílio(3)`. O bloco
do meio é uma unidade **submunicipal**: 27.819 blocos no país, média de 144,7
domicílios amostrados cada, e só 6 blocos cruzam mais de um município. É o mais
próximo de unidade de amostragem/ponderação que 1991 oferece — coerente com o
nome dos próprios arquivos do IBGE, `CD91AMOUP` (AMOstra / Unidade de
Ponderação).

## Por que o FTP perde

O zip do FTP (673.659.331 bytes) traz 27 DBFs, um por UF
(`Dados/Regiao X/CD91AMOUP<UF>.DBF`), **em nível de pessoa** — as variáveis do
domicílio se repetem em cada morador, e não há arquivo de domicílio separado.

Os 141 campos do DBF (verificados em RR e AC) não incluem nenhuma identificação
de questionário. O mapping gold construído por consenso de 12 agentes
(`references/microdata_1991_col_mapping.csv`)
não encontra origem para `V0102` em nenhum deles.

O candidato óbvio, `CD107` (= `V0109`, "Número do Domicílio no CD 1.07"), **não
é chave**: a combinação (UF, município, `V0109`) produz 1.285.449 casos para
4.024.543 domicílios, com 632.153 combinações repetidas — a pior delas (SP,
município 5030, `V0109 = 1`) aparece 5.871 vezes.

## O que dá e o que não dá para reconstruir

**Dá (100%):** o *agrupamento* pessoa→domicílio. No DBF, `PESSOAN` (a ordem da
pessoa, = `V0098`) reinicia em 1 a cada domicílio, então `cumsum(PESSOAN == 1)`
redesenha as fronteiras. Testado: RR dá 5.486 grupos para 5.486 domicílios reais,
AC dá 9.824 para 9.824, e todas as variáveis de domicílio ficam constantes
dentro de cada grupo — zero exceção.

**Não dá:** o código em si, e com ele o bloco submunicipal. Não é derivável de
nada que o DBF entregue: não é município (RR tem 8 municípios e 39 blocos), não
é situação do setor, e não é o reinício de `CD107` (320 blocos em RR contra 39
reais). Casar os dois arquivos por impressão digital (município + `CD107` +
peso + cômodos + água + nº de moradores) chega a 98,7% em Roraima, e tende a
piorar em São Paulo.

## Uma advertência para quem for pela rota FTP no futuro

A ordem das linhas do DBF é **semântica**: a delimitação de domicílio depende
dela. E a ordem do DBF não é a mesma do CSV preparado (em RR o DBF começa com
`CD107` = 1, 20, 30, 50…, e o CSV com `V0109` = 2, 12, 22, 32…, porque o CSV
está ordenado pela `V0102`). Qualquer `setorderv` antes da delimitação quebra
tudo em silêncio — em particular, `convert_raw_to_parquet()` ordena pelas 15
primeiras colunas.

## Itapipoca (CE): um bug na malha de 1991 do geobr

A camada de 1991 do `geobr` 2.0.1 traz Itapipoca com **dois dígitos trocados**:
`2306045` em vez de `2306405`. O código correto é `2306405` — é o que as camadas
de 2000, 2010 e 2022 do próprio `geobr` usam, e o que v0.5.0/v0.6.0 publicam.

Sem tratamento, **1.525 domicílios ficam sem `code_muni`** (4.490 municípios em
vez de 4.491). Verificado que não houve casamento *errado*: nenhuma linha do
censo tem chave `230604`, então ninguém recebeu o código transposto.

`R/microdata_1991.R` corrige o caso explicitamente após o join. Com a correção,
households bate exatamente com o publicado: 4.024.543 linhas, 58 colunas,
0 NAs em `code_muni`, 4.491 municípios distintos, mesma soma de pesos
(35.435.725).

## Divergência intencional vs o publicado

Nenhuma, em households. As duas diferenças de processo são internas:

1. A geografia entra inline, não por `add_geography_cols()` — mesma política
   adotada em 2022 e 1980, e necessária para os `code_*` saírem em `numeric`
   (convenção v0.6.0) sem o `as.integer` intermediário daquela função.
2. `V1102` é gravada com zeros à esquerda (4 dígitos), como em v0.5.0.


---

## Correções feitas a partir da conferência com o DBF (2026-09-13)

O DBF do FTP foi aberto localmente — o `unzip` 6.00 do sistema descomprime
Deflate64, que o `zipfile` do Python e o `java.util.zip` não suportam, e o zip
inteiro passa no teste de CRC nos 8,4 GB. Ele **não** vira fonte: serve de
referência de validação. Nesse papel revelou três defeitos, e o árbitro em todos
foi o **dicionário oficial** (`Dicionário 1991.xls`, que acompanha o zip), não o
DBF.

### 1. Os tipos eram decididos por duas listas escritas à mão

Em `R/microdata_1991.R` o vetor `num_vars` era diferente nos ramos `households` e
`population`, e as 11 colunas que apareciam num e não no outro saíam numéricas
numa tabela e string na outra: `V0098`, `V0102`, `V0109`, `V0111`, `V0112`,
`V0209`, `V0211`, `V0212`, `V2012`, `V2111`, `V2121`.

Entre elas está a **`V0102`, a única ponte entre as duas tabelas** — o join só
casava com cast explícito. Agora a lista é única e o que existir na tabela é
convertido: **0 colunas com tipo divergente**, contra 11 antes.

### 2. Dois sentinelas fora da faixa do dicionário

Varri as 132 variáveis de 1991 que têm faixa declarada no dicionário. Exatamente
três casos a violam, e são o mesmo defeito:

| tabela | coluna | | declarado | observado | registros |
|---|---|---|---:|---:|---:|
| pessoas | `V2012` | Renda domiciliar | ≤ 999999999 | 9999999999 | 552.020 |
| pessoas | `V3045` | Renda familiar | ≤ 999999999 | 9999999999 | 515.649 |
| domicílios | `V2012` | Renda domiciliar | ≤ 999999999 | 9999999999 | 108.050 |

São **1.175.719 registros**. O dicionário declara `999999998 = NSA` e
`999999999 = Ignorado`; a fonte do CEM colapsou os dois num `9999999999` de dez
dígitos. Restaurado o código do dicionário. A distinção NSA/Ignorado já se
perdera a montante e não é recuperável: o DBF ainda a preserva (em RR,
`RFAMILIV` tem 1 NSA e 2.375 Ignorado), o CSV preparado não.

Fora do sentinela, `V3045` é **idêntica** a `RFAMILIV`: dos 23.102 registros de
RR, apenas 2.376 diferiam, e são exatamente os 2.375 sentinelas mais 1 NA.

### 3. A renda familiar per capita não vinha, e foi reconstruída

`RFAPCAPV` (10.8 no dicionário) é a **única variável substantiva** do dicionário
ausente do produto — o mapping gold de 12 agentes a marca `CANNOT_MAP` por
unanimidade. As outras quatro sem mapeamento (`UFNOM`, `MESONOM`, `MICRONOM`,
`MUNICNOM`) são rótulos de nome, que o produto já carrega como `name_*`. A faixa
correspondente, `RFAPCAPF` → `V3049`, sempre esteve presente e é idêntica à do
DBF.

A regra foi determinada por teste, não por suposição. Em Roraima, contra o
`RFAPCAPV` publicado pelo IBGE, no nível de pessoa:

| denominador | exato ao centavo | dentro de 1 centavo |
|---|---:|---:|
| todos os membros da família | 68,25% | 95,30% |
| excluindo pensionista e empregado doméstico | 69,43% | 96,93% |
| **excluindo pensionista, empregado e parente do empregado** | **69,49%** | **97,01%** |
| excluindo também o agregado | 64,17% | 89,51% |

Excluir o agregado **piora** — ele conta como membro, como em 1970. Os códigos
excluídos são `V0303` (parentesco com o chefe da família) 14 e 15, e `V0302`
(parentesco com o chefe do domicílio) 14, 15 e 16. Note que 1991 **tem** a
categoria 16, "Parente do empregado doméstico", que 1970 não tem.

O resíduo de 3% não é nosso: é aritmética do IBGE. 41000 ÷ 6 deveria dar
6.833,33 e o DBF grava **6.833,31**. Fazendo a mesma conta nas duas fontes, o
resultado é **idêntico ao centavo** — 5.228 famílias de RR, quantis batendo em
todos os pontos.

Colunas novas: `family_income_per_cap` e `numb_family_members`.

## O que são os 4 dígitos do meio da `V0102`: a PASTA

O cabeçalho do **CD 1.02 — Questionário da Amostra** tem dez campos de
identificação:

```
1 MUNICÍPIO   2 PASTA   3 Nº NA PASTA
4 DISTRITO  5 SUBDISTRITO  6 Nº DO SETOR  7 QUARTEIRÃO  8 FACE
9 Nº NO CD 1.07   10 Nº NO CD 1.03
```

A `V0102` de 9 dígitos é **prefixo(2) + PASTA(4) + Nº NA PASTA(3)**.

O **Manual do Recenseador (PA 1.09, p. 32)** resolve o que ela é:

> *"Nada deverá ser registrado nos campos 2 - PASTA e 3 - NÚMERO NA PASTA
> destinados para Uso do Órgão Central."*

O recenseador não preenche esses campos — transcreve da Folha de Coleta apenas
os campos 4 a 9. A pasta é numeração atribuída **centralmente, no
processamento**: é a pasta física onde os formulários de papel foram arquivados.

O dado confirma o documento:

| | medido |
|---|---|
| questionários por pasta | mediana **154**, quartis 135–171 |
| numeração interna | 1..N sem buraco em **87,1%**; máximo 708, nunca chega ao teto de 999 |
| respeita município | **6 de 27.819** cruzam, porque o arquivamento era por município |
| é unidade de ponderação? | **não** — 3 de 27.819 têm peso constante; R² 0,218 contra 0,210 só do município |

O prefixo de 2 dígitos também **não é a UF**. Vinte e seis UFs usam prefixo igual
ao seu código; São Paulo usa dois, com divisão limpa e nenhum município nos dois:

| prefixo | municípios | domicílios | |
|---|---:|---:|---|
| 35 | 8 | 344.675 | núcleo metropolitano, incluindo a capital (260.987) |
| 36 | 564 | 534.696 | o resto do estado |

Cada série numera suas pastas a partir de 1. Não é estouro de dígito: SP tem
5.528 pastas, longe do teto de 9.999. São duas séries de processamento — o mesmo
padrão "SP Capital / SP exceto Capital" que o IBGE repete em 2010 nos setores.

**Consequência: a pasta não deve virar coluna `code_*`.** Não é geografia. E a
geografia submunicipal de verdade — distrito, subdistrito, setor, quarteirão e
face, campos 4 a 8 do mesmo cabeçalho — **não está em nenhuma das duas fontes**,
tendo sido suprimida na divulgação dos microdados.

## O incidente de Ariquemes

O DBF tem 59 registros de pessoa a mais que o produto. Derivei o número de
registros de cada um dos 27 DBFs do tamanho descomprimido — `4545 + n × 493 + 1`,
e os 27 dividem exatamente por 493, o que confirma o layout uniforme. O resultado:

| | DBF | produto |
|---|---:|---:|
| total | 17.045.712 | 17.045.653 |

**25 das 27 UFs batem exatamente.** RO tem −58 e BA −1. E em RO a diferença é
toda de um município:

| **1100023 — Ariquemes** | DBF | produto | falta |
|---|---:|---:|---:|
| pessoas | 8.511 | 8.453 | **58** |
| domicílios | 1.972 | 1.961 | **11** |

Os outros 22 municípios de RO batem registro a registro. O domicílio órfão do
produto — `V0102 = 110043042`, presente na tabela de domicílios sem nenhum
morador no banco de pessoas — é desse mesmo município. Ou seja: 10 domicílios
sumiram inteiros e 1 ficou na tabela vazio. É um incidente único e localizado na
preparação do CEM, não uma diferença de critério de divulgação.

Não há o problema inverso: zero pessoas apontam para domicílio inexistente.
