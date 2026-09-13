# Registros corrompidos nos microdados da amostra do Censo 1970 (Alagoas e Pernambuco)

**Data:** 2026-09-13 (substitui a versão de 2026-09-12)
**Escopo:** dois dos 27 arquivos de microdados da amostra do Censo Demográfico de 1970 distribuídos no FTP do IBGE contêm registros deslocados. Este documento descreve o defeito, sua extensão e sua consequência. Todos os números vêm de contagem byte a byte dos arquivos.

---

## O defeito

`DAMO70AL.txt` (Alagoas) e `Damo70PE.txt` (Pernambuco) contêm registros em que
um bloco de caracteres foi movido de lugar: alguns registros ficaram mais
longos e outros mais curtos, na mesma proporção. São **1.785 registros** em
24.793.359 linhas dos 27 arquivos — 0,0072% da amostra nacional. O CRC do zip
confere: o defeito está no arquivo tal como distribuído.

A consequência é séria e silenciosa. O peso amostral é o último campo do
registro (posições 75–76), e o deslocamento o tira do lugar. Numa leitura por
posição fixa — a única que o layout prevê — os 1.785 registros se repartem
assim:

| | registros |
|---|---:|
| perdem o peso: as posições 75–76 caem fora do campo (685) ou não contêm número (215) | 900 |
| recebem um peso **falso** | 650 |
| acertam por acaso | 24 |
| linhas fragmentárias, que não são registros de pessoa e entram na tabela como se fossem | 211 |

Os 650 pesos falsos não são indistinguíveis dos verdadeiros: só 185 (28,5%)
caem na faixa de pesos comuns (1 a 13, os únicos com mil casos ou mais no
país). Os outros 465 (71,5%) assumem valores raros ou inexistentes — o peso 27
aparece 192 vezes, contra 32 ocorrências reais em todo o Brasil; o 19 aparece
116 vezes contra 143 reais; o 59, 26 vezes contra 2; e 49 e 99 aparecem 5 e 2
vezes sem existir na amostra. Um usuário atento vê o sinal na distribuição;
um usuário que confia no layout não vê nada.

## Os arquivos

Origem: `https://ftp.ibge.gov.br/Censos/Censo_Demografico_1970/Microdados/Microdados_Censo_Demografico_1970_Amostra.zip`
(263.170.655 bytes, MD5 `d390dff085f7ad92775b665f91d053e3`).

| Arquivo | Bytes | Data no zip | MD5 | Linhas | Anômalas |
|---|---:|---|---|---:|---:|
| `Dados/DAMO70AL.txt` | 32.148.949 | 2005-11-14 17:10 | `37094fe0b11b2a7ac5d2bb182e95e9f3` | 412.171 | **46** |
| `Dados/Damo70PE.txt` | 107.794.519 | 2005-11-16 10:25 | `e1d1fa7110fe9ab0b2478742f04befac` | 1.381.977 | **1.739** |
| `Dados/DAMO70AC.txt` (íntegro, para comparação) | 4.669.861 | 1998-01-21 10:43 | `a681e6bfce52a96e3892016e0744d913` | 59.870 | 0 |

Os outros 25 arquivos têm 100% das linhas com exatamente 76 caracteres.

## Como o defeito se manifesta

O registro da amostra de 1970 tem 76 caracteres — 54 variáveis, posições 1 a
76, sem lacunas. Nos dois arquivos afetados aparecem linhas de 16, 54, 58, 66,
68, 94, 98, 132, 136 e 154 caracteres. Os desvios se concentram em ±18 e ±60,
e os ganhos compensam as perdas:

| Arquivo | −60 | −18 | +18 | +60 | outros | saldo em bytes |
|---|---:|---:|---:|---:|---:|---:|
| Alagoas | 6 | 22 | 17 | 1 | 0 | −390 |
| Pernambuco | 205 | 658 | 658 | 204 | 14 | +312 |

Em Pernambuco o pareamento é exato em −18 contra +18 (658 de cada) e quase
exato em −60 contra +60 (205 contra 204); os 14 restantes têm desvios de −22,
−10, −8, +22, +56 e +78. O tamanho total de cada arquivo se conserva quase
inteiramente: caracteres foram movidos, não criados nem destruídos. A
aritmética fecha com o tamanho físico — `412.171 × 78 + 1 − 390 = 32.148.949`
e `1.381.977 × 78 + 1 + 312 = 107.794.519`, com 78 = 76 caracteres mais CR e
LF, e o `+1` é o byte `0x1A` de fim de arquivo.

Um registro alongado (Alagoas, linha 273.198, byte 21.309.366):

```
273197   76 |2466140100610049255212222030201034041013-    -                      -     04|
273198   94 |2466140100610049255212222030201032081013-    -                      -                 -     04|
273199   76 |2466140120610019655211222070201034031013-    -                      -     05|
```

A linha tem 18 caracteres a mais inseridos no meio da região de
preenchimento. O início está correto — o prefixo `2466140` é o das vizinhas —
e o fim também: o peso `04` está lá, mas nas posições 93–94 em vez de 75–76.

Um registro encurtado (Alagoas, linha 273.226, byte 21.311.568):

```
273225   76 |2466140120310019255212222040100014191013-    22059910060272231224143-     05|
273226   58 |2466140140101014741013-    2205999999910-         06000004|
273227   76 |2466140100310019155212222030100014353013-    22059940060272231224243-     04|
```

Faltam 18 caracteres do miolo; o começo e o fim continuam no lugar.

## O padrão

O defeito não é ruído aleatório. Três regularidades:

**Concentração no arquivo.** Em Alagoas, as 46 ocorrências estão entre 66,3% e
88,5% do arquivo (linhas 273.198 a 364.635) e nenhuma nos dois primeiros
terços — por decil, `0 0 0 0 0 0 6 6 34 0`. Em Pernambuco, 1.731 das 1.739
estão nos primeiros 60%.

**Pareamento em Alagoas.** As 46 anomalias formam 23 pares: uma linha de
comprimento errado e, adiante, outra que compensa a diferença. A composição:
17 pares de 94 → 58 caracteres (saldo zero); 1 par de 16 → 136 (saldo zero); e
5 pares de 16 → 58, em que as duas linhas são curtas, cada par deixa −78 e os
cinco somam exatamente os −390 do arquivo. A linha de 16 caracteres é a mais
curta de todas (−60), e em 6 dos 23 pares ela é o primeiro membro. A distância
entre os dois membros vai de 1 a 400 linhas — 1, 6, 7, 27, 27, 27, 28, 28, 28,
28, 32, 50, 53, 150, 237, 290, 290, 290, 290, 290, 290, 290, 400 —, e os
registros entre eles têm 76 caracteres e conteúdo plausível.

**Alinhamento com fronteiras de 4 KB.** A chance de uma linha começar a até 76
bytes de um múltiplo de 4.096 é 2 × 76 / 4.096 = 3,71% em teoria, e mede
3,7591% em Alagoas, 3,7585% em Pernambuco e 3,7597% nos 27 arquivos. Entre as
linhas anômalas a frequência é 37,0% em Alagoas (17 de 46) e 23,4% em
Pernambuco (407 de 1.739) — enriquecimento de 9,8× e 6,2×.

Lixo binário quase não há. Alagoas não tem nenhum byte de controle fora de CR
e LF; Pernambuco tem 13 em 107 MB, excluído o `0x1A` final: 1 NUL, 2 BS, 4
TAB, 4 VT, 1 CAN e 1 ESC.

## O que o padrão indica

Transferência de blocos de tamanho fixo, com conservação do total,
concentrada em regiões do arquivo e alinhada a 4 KB, é a assinatura de um
processo de cópia ou conversão com buffer em que a fronteira de escrita
escorregou — leitura de registros de tamanho fixo com comprimento
desencontrado, ou transferência que tratou alguns blocos de forma diferente.
Não é possível determinar, a partir do arquivo, em qual etapa isso ocorreu.

As datas dentro do zip dizem duas coisas. Nove arquivos são do lote de
novembro de 2005 — AL, BA, CE, PB, MA, RN, SE, FN e PE — e sete deles estão
íntegros, portanto a data não distingue os afetados. Os 16 arquivos datados de
janeiro de 1998 estão todos limpos. E a versão desses mesmos dados harmonizada
pelo CEM (Centro de Estudos da Metrópole) não apresenta o defeito. Existiu,
portanto, uma cópia íntegra dos dois arquivos.

## O peso é recuperável da cauda da linha

Como o início e o fim do registro sobrevivem ao deslocamento, o peso amostral
pode ser lido dos dois últimos caracteres. Dos 1.785 registros, 211 são
fragmentos de 16 caracteres — 3 a 10 das 54 variáveis preenchidas, sem sexo,
idade nem parentesco — e devem ser descartados. Nos 1.574 restantes (40 em
Alagoas, 1.534 em Pernambuco) o peso é legível na cauda em 1.568; em 6 a cauda
também é ilegível. Os pesos assim recuperados reproduzem a distribuição
nacional — moda 4, com 882 casos (35 em AL, 847 em PE), depois 3 com 535 e 5
com 99 —, enquanto a leitura nas posições 75–76 devolvia valores como 27, 10,
19 e 21. Só o peso se recupera: o miolo continua deslocado, e as demais
variáveis desses 1.574 registros seguem sem confiabilidade.

## Como conferir

Contando bytes — `LF` marca a linha, `CR` é descontado —, e não com um leitor
de texto. Os leitores usuais mascaram o defeito: `readr::read_lines` trunca a
linha de 58 caracteres de Pernambuco no byte NUL, devolvendo 20 caracteres e
perdendo 37 sem alterar a contagem de linhas; `readr::read_fwf`, lendo direto
do arquivo, inventa um registro em Pernambuco — parte a linha 108.812 em 20 e
37 caracteres e devolve 1.381.979 linhas em vez de 1.381.977. Em Alagoas, que
não tem bytes de controle, `read_lines` serve:

```r
library(readr)
linhas <- read_lines("Dados/DAMO70AL.txt", locale = locale(encoding = "ISO-8859-1"))
linhas <- linhas[nchar(linhas) > 1]      # descarta o 0x1A de fim de arquivo
table(nchar(linhas))
#      16      58      76      94     136
#       6      22  412125      17       1
```

Num arquivo íntegro, como `DAMO70AC.txt`, a tabela tem uma única entrada, `76`.

## No produto

O produto de 1970 do `censobr` não é construído a partir desses arquivos. Usa
a versão harmonizada pelo CEM, hospedada no release `release_legacy` deste
repositório, que não tem o defeito — ver `microdata_1970_ftp_vs_cem.md`.

## Pedido ao IBGE

Se existir cópia anterior de `DAMO70AL.txt` e `Damo70PE.txt` — em particular
da leva de janeiro de 1998, íntegra nos outros arquivos —, sua
redisponibilização resolve o problema na origem e dispensa qualquer remendo
por parte dos usuários.
