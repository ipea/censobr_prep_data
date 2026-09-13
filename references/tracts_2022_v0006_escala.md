# A V0006 dos agregados por setor de 2022: duas escalas, um rótulo

**Data:** 2026-09-13
**Assunto:** por que a `V0006` tem mediana 0,019 no agregado definitivo e 1,96
no preliminar, e o que fazer a respeito
**Decisão:** nada no dado. Documentar.

---

## O problema

Na v0.7.0 publicamos as duas divulgações lado a lado, e a mesma variável
aparece em escalas diferentes:

| | preliminar | definitivo |
|---|---:|---:|
| mediana | 1,9608 | 0,0193 |
| máximo | 100,0000 | 4,2542 |
| setores no teto exato | 227 (em 100) | 220 (em 1) |
| setores acima do teto | 0 | **11** |

Fator 100. Quem comparar as duas tabelas sem perceber erra por duas ordens de
grandeza.

## A documentação não resolve — e é ela o problema

O IBGE descreve a `V0006`, **byte a byte igual nas duas divulgações e em todas
as safras do dicionário**, assim:

> **Percentual de Domicílios Particulares Ocupados Imputados
> (Total DPO imputados / Total DPO)**

A frase se contradiz. O substantivo **"Percentual"** pede 0–100; a fórmula
entre parênteses é uma **razão simples**, que vive em 0–1. E não há, em
nenhuma das quatro safras de dicionário verificadas, coluna de unidade, fator
de multiplicação ou nota que desempate. O único metadado de tipo existe no
dicionário do preliminar, e diz apenas `real`.

Fontes conferidas, todas com a mesma frase: o dicionário oficial do definitivo
nas safras **20241115**, **20250417** e **20260520**; o dicionário do
preliminar de **20/03/2024**; o `2022_dictionary_tracts.xlsx` do release
`censo_docs`; e a transcrição independente de Pedro Souza em
[`phgfsouza_census_tracts/`](phgfsouza_census_tracts/).

## O que decide: a aritmética

O numerador é uma **contagem de domicílios** e portanto tem de ser inteiro.
Isso permite um teste sem ambiguidade — reconstruir o numerador a partir de
`V0006` e do denominador, e ver se dá inteiro.

No definitivo, `V0006 == k / V0007` com `k` inteiro, arredondado a 4 casas:

> **457.500 de 457.500 setores com `V0007` > 0 — 100,0000%**

Os outros 10.599 setores têm `V0007 == 0` e `V0006 == 0`. **Nenhum outro
denominador funciona**: `V0002`, `V0003` e `V0001` reproduzem `V0006` em ~32%,
que é nível de acaso. E `V0007` é, literalmente, o denominador que a fórmula
declara — "Total de Domicílios Particulares Ocupados (DPPO + DPIO)".

No preliminar a mesma identidade só fecha **depois de dividir por 100**.

## A âncora externa

A **Nota metodológica n. 06** dos Agregados por Setores Censitários registra
que a imputação atingiu *"cerca de 3 milhões de domicílios, representando
4,21% do total de domicílios ocupados"*.

| leitura | domicílios imputados | taxa |
|---|---:|---:|
| definitivo como **proporção** | 3.080.906 | 4,248% |
| definitivo como percentual | 30.809 | 0,042% |
| preliminar como **percentual** | 3.076.899 | 4,243% |

O definitivo lido como percentual daria cem vezes menos imputação do que o
próprio IBGE publicou, e tornaria impossível o teto de 100% que 220 setores
atingem.

## Veredito

**É a mesma medida, publicada em duas escalas.** O preliminar honra o
substantivo do rótulo e viola a fórmula; o definitivo honra a fórmula e viola
o substantivo. Nenhum dos dois é "o certo" — o rótulo é que nunca foi preciso
o bastante para distinguir.

**Para comparar as duas divulgações, multiplique o definitivo por 100.** Não
confie no nome da variável.

Os valores estão corretos dentro da própria escala. **O erro é de
documentação, não de dado** — com uma exceção, abaixo.

## A exceção: 11 setores com V0006 > 1 no definitivo

Não é problema de escala. Nos 11, `k = V0006 × V0007` é inteiro exato (251,
151, 618, 313, 22, 162, 62, 19, 7, 253, 58) e **`k` é maior que `V0007`** —
mais domicílios imputados do que domicílios ocupados existentes. A hipótese de
que ali o valor tenha ficado em escala percentual não sobrevive:
`V0006/100 × V0007` não dá inteiro em nenhum deles.

Nenhuma outra coluna da mesma linha reproduz `k` — nem `V0001`, `V0002`,
`V0003`, `V0004`, `V0008` ou `V0009`, nem soma óbvia delas. **Fica como defeito
de fonte sem mecanismo identificado.** Três deles nem existem no preliminar, o
que elimina a contraprova externa.

## O que NÃO está afetado

- **`V0006` é a única** com problema de escala. Varridos os dois dicionários
  inteiros, só `V0005` e `V0006` não são contagem, em 3.400+ variáveis.
- **`V0005`** tem a mesma escala nas duas divulgações. O que muda é a
  **precisão**: o definitivo grava 1 casa decimal (2,8) e o preliminar 6
  (2,761905). É perda de informação na republicação, não troca de escala.
- **`V0001` a `V0004` e `V0007`** são contagens puras, razão 1,0000. A fração
  que não bate entre as duas divulgações é remalhamento, não escala — prova:
  `sum(V0007)` = 72.522.372, **idêntico nas duas**.
- **Nosso pipeline não tem participação nenhuma.** Os valores do parquet são
  byte a byte os do CSV do IBGE em 468.099 de 468.099 setores.

## Achado lateral

`V0008` (uso ocasional) e `V0009` (vagos) **só existem no definitivo** e
entraram na republicação de 20260520 — por isso não constam da transcrição de
Pedro Souza, congelada em 30/04/2026. Conferem contabilmente:
`V0003 == V0007 + V0008 + V0009` em **468.099 de 468.099** setores.

## Pendências

- `V0005` não fecha perfeitamente: nos 408.445 setores com `V0004 == 0` e
  `V0007 > 0`, onde `V0001/V0007` deveria reproduzir `V0005`, sobram **2.136
  setores (0,52%)** sem explicação. Não afeta a `V0006`.
- Não foram testados os agregados por município, distrito, subdistrito e
  bairro, que carregam a mesma `V0006` com o mesmo rótulo.
