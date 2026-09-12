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
(`references/microdata_1991_rounds/FINAL_microdata_1991_col_mapping_gold.csv`)
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
