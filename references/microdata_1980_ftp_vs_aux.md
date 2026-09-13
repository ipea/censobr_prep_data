# Microdados 1980: a fonte do produto e os defeitos do DBF do IBGE

**Data:** 2026-09-13 (substitui a versão de 2026-09-11)
**Escopo:** amostra do Censo Demográfico de 1980 — o que o produto `censobr` contém, de onde vem, e o que a republicação do IBGE em DBF (FTP, 01/2025) perde.

---

## A fonte do produto

O produto de 1980 é construído a partir da **amostra preparada** — os CSVs de
2018, hoje convertidos em parquet e hospedados no release `release_legacy`
deste repositório. A republicação em DBF que o IBGE colocou no FTP em 2025
não serve de fonte: perde um território inteiro e quatro variáveis, e a
origem municipal dos migrantes não é recuperável a partir dela. O DBF é
usado apenas como referência de validação.

Todos os números abaixo foram medidos nos 52 DBFs do zip do FTP (26 de
pessoas e 26 de domicílios), nos parquets do `release_legacy` e nos parquets
publicados em v0.5.0.

## O que a republicação em DBF perde

### Fernando de Noronha inteiro

O zip traz 26 unidades da federação — `11 12 13 14 15 16 21 22 23 24 25 26
27 28 29 31 32 33 35 41 42 43 50 51 52 53` — e **não existe `CD80PES20` nem
`CD80DOM20`**: o Território de Fernando de Noronha (UF 20) está ausente. A
soma dos registros de pessoas do FTP é **29.378.455**, contra **29.378.753**
na amostra preparada — diferença de exatamente **298**, que são os registros
com `V2 == "20"`; o mesmo ocorre com os **69** domicílios do território. As
outras 26 UFs batem registro a registro (RO 116.536 = 116.536, SP 6.206.465 =
6.206.465, e assim por diante), então Fernando de Noronha não foi realocado
para dentro de Pernambuco: sumiu.

### Quatro variáveis

Os 26 arquivos de pessoas têm assinatura de coluna idêntica (61 campos, 165
bytes por registro) e os 26 de domicílios também (26 campos, 53 bytes). Em
nenhum deles existem:

| Variável | O que é | Na amostra preparada |
|---|---|---|
| `V518` | UF e/ou município de residência anterior | presente (NA em 58,2% — ver abaixo) |
| `V3` | Mesorregião | 0% NA |
| `V4` | Microrregião | 0% NA |
| `V6` | Distrito | 0% NA |

O bloco de migração do DBF termina em `MITEMPMU` (= `V517`); a variável
seguinte da amostra preparada, `MIUFANT` (= `V518`), não está lá. O
identificador sequencial `idpessoa` também não está, mas é reconstruível:
na amostra preparada ele é exatamente `1:29378753` na ordem do arquivo.

`V518` é **a única variável que dá o município de residência anterior**. A
UF de nascimento (`V512`) está no DBF e dá origem em resolução de UF; a
origem em resolução **municipal** é irrecuperável sem a `V518`.

### A documentação que acompanha o DBF

A `Documentação.xls` de 2025 não tem entrada para as variáveis 517, 518 nem
521, em duas lacunas separadas: a planilha de pessoas salta de `MITEMPUF`
(516) direto para `EDSABELE` (519), e no lugar da 521 repete a linha de
`EDULGRAU` (524). Ela documenta 60 entradas, 59 nomes distintos, para 61
campos presentes no DBF. Dessas três, `V517` e `V521` estão no dado; `V518`
não.

Nota sobre o dicionário deste repositório: `microdata_1980_col_mapping.csv`
registra `MIUFANT → V518`; a coluna existe na amostra preparada, não no DBF.

## O que o DBF tem a mais

Em variáveis, nada. Em registros de domicílio, sim: nas mesmas 26 UFs o DBF
tem **6.886.803** registros contra **6.716.816** da amostra preparada
(6.716.885 menos os 69 de Fernando de Noronha) — **169.987 a mais**,
distribuídos por todas as UFs (cerca de 2,6% em cada). Em Rondônia, lidos
linha a linha, a diferença está inteiramente em `ESPECIE` 5 e 7 (domicílios
coletivos); as espécies 1 e 3 batem exato (24.492 e 844). O número coincide
com o dos registros de domicílio coletivo que, no próprio DBF, não têm nenhum
morador no arquivo de pessoas, nenhum peso e nenhum dado substantivo (ver
`carta_ibge_levantamento.md`): a amostra preparada não os carrega.

## Como ler a `V518` no produto

A `V518` é um código de 6 caracteres, `UF(2) + município(4)`, e tem três
estados, definidos pela variável `V517` (tempo de residência no município):

| Estado | Registros | % | `V517` |
|---|---:|---:|---|
| `NA` | 17.111.136 | 58,2% | `8` (nasceu no município) em 100% dos casos — e todos nasceram na UF onde moram e têm `V513 = 1` |
| `"0"` | 5.955.024 | 20,3% | `7` (10 anos ou mais) em 5.907.024; `9` (sem declaração) em 48.000 |
| código | 6.312.593 | 21,5% | `0` a `6` (menos de 10 anos) em 6.304.634; `9` em 7.959 |

Três consequências para quem usa a variável:

- **`"0"` não significa "não migrou".** É o migrante antigo (dez anos ou
  mais no município), cuja origem o IBGE não codificou. Nesse grupo, 61,5%
  nasceram na UF onde moram, **34,5%** em outra UF brasileira e 4,0% no
  exterior ou sem declaração.
- **`NA` e `V517 == 8` são a mesma seleção**, nos dois sentidos, sem
  exceção. Para o estoque de migrantes tanto faz `V517 != 8` quanto
  `!is.na(V518)`; o que não se pode fazer é tratar `"0"` como não-migrante.
- **A partição por `V517` não é exata**: 55.959 registros têm `V517 = 9`
  (sem declaração) e caem ora no grupo `"0"`, ora no grupo com código.

Os códigos: a `V518` tem **4.020** valores distintos. 3.991 são os mesmos
3.991 municípios de `code_muni_1980` (`V2 × 10000 + V5`), e nunca coincidem
com o município atual da própria linha (0 casos em 6.312.593). Os outros 29
cobrem **468.308 registros (7,42% dos que têm código)**: 26 valores `UF +
0000` (todas as UFs menos o DF; 421.888 registros), mais `540000` (2.922),
`800000` (42.965, dos quais 31.223 com `V511 = 6`, estrangeiro) e `990000`
(533). Portanto os prefixos observados são `11` a `53` **mais `54`, `80` e
`99`**; uma guarda escrita só para 11–53 falha em 46.420 registros, e um
filtro `V518 %in% code_muni_1980` descarta em silêncio 7,4% dos migrantes com
origem parcialmente conhecida.

Dois cuidados de codificação: o prefixo de UF da `V518` usa os códigos
modernos (11–53), enquanto `V512` (UF de nascimento) usa a numeração
sequencial de 1980 (1 = RO … 14 = FN … 27 = DF) — cruzar as duas sem traduzir
produz resultado silenciosamente errado. E o `"0"` é a string de um
caractere; `"000000"` não ocorre.

## Diferenças do produto em relação ao publicado em v0.5.0

A tabela de domicílios tem 6.716.885 linhas nas duas versões e as mesmas
colunas, menos uma. Cinco diferenças são deliberadas:

1. **`code_micro` corrigida.** Em v0.5.0, `code_micro` e `code_meso` recebiam
   ambas a `V3`: eram idênticas em 6.716.885 de 6.716.885 linhas, com 89
   valores distintos, enquanto a `V4` tem 361. Quem usava `code_micro`
   agregava por mesorregião. O produto usa `code_micro = V4`.
2. **`Observation` removida.** Era uma coluna de anotação do crosswalk de
   Tocantins e Fernando de Noronha que vazou para o produto, preenchida nas
   35.567 linhas de 53 municípios.
3. **`code_muni` sem NA.** Em v0.5.0, 35.567 domicílios ficavam sem
   `code_muni` (3.938 valores distintos), porque o crosswalk reescrevia os 52
   municípios que viriam a formar o Tocantins e Fernando de Noronha para os
   códigos de 2010, inexistentes na malha de 1980. O produto usa a malha de
   1980 (`geobr::read_municipality(year = 1980)`): Fernando de Noronha é
   `2000107`, no território 20, e os futuros municípios do Tocantins continuam
   em Goiás (`52xxxxx`). Os 3.991 códigos do dado resolvem todos; 0 NA.
4. **`V212`, `V213` e `V602` fora do universo viram NA.** Nas 233.344 linhas
   com `V201 != "1"` (domicílio não particular permanente) essas três colunas
   passam a NA. As outras 26 colunas `V*` são idênticas às de v0.5.0 após
   ordenação.
5. **Ordem das linhas.** O produto preserva a ordem da amostra preparada, que
   começa em Rondônia. Em v0.5.0 as 35.567 linhas casadas pelo crosswalk (69
   de Fernando de Noronha e 35.498 de Goiás) vinham içadas para o topo.

Os pesos (`V603` e `V604`) e a decisão sobre seus zeros estão em
`microdata_1980_pesos_v603_v604.md`.

## O que daqui vai para a carta ao IBGE

Quatro dos itens de 1980 em `carta_ibge_levantamento.md` saem desta
apuração: Fernando de Noronha ausente do DBF; as quatro variáveis perdidas na
republicação; a `Documentação.xls` que omite variáveis presentes no dado; e os
169.987 registros de domicílio coletivo sem morador.
