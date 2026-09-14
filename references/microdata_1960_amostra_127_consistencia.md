# Censo 1960, amostra de 1,27%: o que o repositório `ConsistenciaCenso1960Br` faz, o que reproduz e o que deixa em aberto

**Data:** 2026-09-14
**Escopo:** exame do repositório `antrologos/ConsistenciaCenso1960Br` (11 commits, 19–21/08/2018), que produz a versão consistida da amostra de 1,27% do Censo de 1960 usada como insumo do `censobr` para as UFs sem amostra de 25%. Todos os números vêm de medições sobre `Original Files/HHOLDA.txt` e sobre os arquivos auxiliares, feitas hoje, e da reprodução integral do `README.Rmd`.

---

## O insumo

`HHOLDA.txt`: 1.074.328 linhas de exatamente 62 caracteres, hierárquico —
174.467 registros de família (caractere 17 = 1), 174.472 de chefe (= 2) e
725.389 de outros moradores (= 3); 899.861 pessoas, 1,28% de uma população
de cerca de 70,1 milhões. Nas posições 55–62 há um identificador `\NNNNNNN`
acrescentado depois da gravação original, que muda exatamente quando o
registro é de família (174.467 valores distintos, nenhum sem registro de
família, nenhum com dois).

O layout usado é o das sintaxes SPSS/SAS que acompanhavam o arquivo; o
`dicionario_60_last.doc` descreve outro layout, o da amostra de 25% (17
unidades: RN, AL, BA, CE, PB, PE, SE, FN, GO, MT, DF, SA, MG, RJ, PR, SP e
RS), com as mesmas categorias.

## O que o repositório faz

1. Lê o arquivo como texto, troca todo hífen por espaço e separa famílias de
   pessoas pelo caractere 17.
2. Aplica o layout (`Auxiliary Files/Census1960_input_Sample_1.27.xlsx`) e
   testa cada valor contra a lista de códigos válidos do dicionário.
3. Detecta três tipos de problema: valor fora do dicionário; caractere que não
   é dígito, espaço ou barra (43 linhas, 7 de família); 1 a 3 espaços entre
   dígitos (61 linhas, 20 de família).
4. Diagnostica à mão as 29 linhas de família e 93 de pessoa assim marcadas
   (`Auxiliary Files/check_line_by_line.xlsx`): 103 "ok" (só valores isolados
   inválidos, que viram NA), 10 registros inteiramente corrompidos (zerados e
   marcados com `cem_diagnosis = 4`) e 9 recuperáveis por remoção de espaços
   e recomposição do comprimento (`cem_diagnosis = 1`).
5. Constrói o domicílio a partir de `V101` (1 único, 2 principal, 3 coletivo
   abrem domicílio; 4 e 5, famílias conviventes, herdam o ID anterior),
   copia UF, `V116` e `V118` entre pessoa e domicílio quando falta de um
   lado, e marca as discordâncias que restam (3 em UF, 44 em `V116`, 280 em
   `V118`; 299 pessoas).
6. Atribui peso uniforme `cem_wgt = 1/0,0127` e grava: pessoas 899.861 × 58
   colunas, domicílios 174.094 × 26 (os 174.467 registros de família menos
   373 famílias conviventes).

## Reprodução

O `README.Rmd` roda do começo ao fim em 1,6 min (código extraído com
`knitr::purl`; só foi preciso trocar o `setwd` de um Mac e apontar os
`source()` para os arquivos locais em vez do GitHub). Os CSVs produzidos são
**idênticos aos publicados no repositório**: 899.861 × 58 e 174.094 × 26,
mesmas colunas, zero células diferentes.

## O que confere

Comprimento das linhas, contagens por tipo de registro, unicidade e
sequência dos IDs, conteúdo das posições 32 e 35–54 dos registros de
família (só 1 e 2 linhas fora do esperado), contagens dos três detectores e
dos diagnósticos manuais — tudo como o relatório descreve.

## O que o relatório descreve de forma imprecisa ou deixa em aberto

### 1. Os hífens não estão "no final das linhas": são marca de salto

São 611.196 hífens em 611.193 linhas, sempre no primeiro caractere de um
campo e seguidos de brancos, em cinco posições: 47 (335.282 — `V221`,
ocupação, depois de `V220`), 33 (143.995 — `V211`, depois de `V210`), 36
(130.647 — `V214`, depois de `V213`), 20 (1.209 — `V102`, depois de
`V101` = 3, coletivo) e 21 (49 — `V103`, depois de `V102` = 6, improvisado).
É o "não se aplica daqui em diante" do formulário. Trocar por espaço é
coerente com o dicionário, que aceita branco nesses campos, e não perde
valor; mas apaga a distinção entre salto e branco genuíno (`V211` branco
sem hífen ocorre 3 vezes) e o texto do relatório não diz o que o hífen é.

### 2. Os caracteres 7–16 não são indecifráveis: são a identificação do questionário

O relatório os declara ignorados por falta de documentação. Medidos, têm
estrutura estável:

| posições | conteúdo medido |
|---|---|
| 7–10 | 261 valores, cada um dentro de uma única UF (260 de 261), de 1 a 5.177 famílias, até 22 municípios |
| 11–12 | aninhado em 7–10: 946 pares (7–10, 11–12), 923 dentro de um único município, mediana de 203 famílias |
| 13–16 | número sequencial do questionário dentro do par; (7–16) é único por família |

O conjunto 7–16 é igual entre o registro de família e os de suas pessoas em
99,75% dos IDs — é uma chave de domicílio original, independente do ID
acrescentado a posteriori. Os nomes exatos (pasta, boletim, identificação,
como no dicionário da amostra de 25%) não são determináveis com a
documentação disponível, mas a chave funciona sem eles.

### 3. Os "5 casos" de chefe a mais são cinco famílias com o registro de família perdido

O relatório registra que há 174.472 chefes para 174.467 famílias e para. A
chave 7–16 mostra o que são: cinco IDs (29831, 32581, 54150, 136463,
137492) contêm um segundo chefe cujo questionário é outro — o registro de
família dele se perdeu (num caso, virou a linha corrompida
`\212135072103211531 291 08542092000052-`). As cerca de 30 pessoas dessas
cinco famílias estão no banco com o ID e as características de domicílio
(`V101`–`V113`) do domicílio anterior, e as cinco famílias faltam na tabela
de domicílios. São separáveis: dentro do ID, a mudança de 7–16 acompanhada
de um registro tipo 2 abre uma família nova.

Outros 432 IDs têm pessoas (1.676) sob um número de questionário diferente
do da família, mas sem chefe — 192 com o número seguinte (folha de
continuação), 44 com número menor. Tratá-las como membros da família, como
o ID faz, é a leitura natural; vale marcá-las.

### 4. Os IDs pulam 856 números, todos em Pernambuco

Os IDs vão de 1 a 175.323, mas só 174.467 existem: 856 números ausentes,
849 deles isolados, 828 logo após um registro de Pernambuco (a primeira
sequência de 5 ausentes começa exatamente no primeiro ID de PE). Pessoas por
família em PE (5,28) igualam a média nacional (5,16), o que não sugere
famílias perdidas — mais provavelmente linhas vazias removidas depois de
numerar. Como o ID foi criado a posteriori, isso deveria constar da
documentação.

### 5. O peso uniforme é uma suposição, não uma medição

`cem_wgt = 1/0,0127` para todos apoia-se em "totais muito semelhantes" aos
oficiais, sem conferência por UF. A fração realizada é 1,28% no total;
conferir por UF exige as populações de 1960, que estão no material da
compilação, não neste repositório.

### 6. A unidade de sorteio não é visível na numeração

Dentro de cada par (7–10, 11–12) os questionários presentes formam
sequências consecutivas de comprimento mediano 22 (10% isolados, 10% com
191 ou mais), sem tamanho fixo. O "sorteio de lotes de questionários" do
Volume 2 dos Resultados Preliminares não se reconstrói a partir do arquivo.

### 7. Miúdos

Códigos de UF inválidos em 5 linhas (branco, 18, 33, 34), todas de registros
corrompidos, tratados por NA e cópia do domicílio. O `.doc` da amostra de
25% diz que o registro de domicílio é o que tem o campo IDENTIFICAÇÃO
zerado; neste arquivo o tipo está no caractere 17, como nas sintaxes.

## Para a etapa seguinte (compilação com a amostra de 25%)

- Na tabela de domicílios do produto `censobr`, RO (`uf` = 0) tem 140
  domicílios e RR (`uf` = 3) tem 58; neste insumo há 76 registros de família
  em RO e 122 em RR. Como domicílio ≤ família, 140 não pode vir daqui:
  conferir a passagem 1,27% → produto para essas duas UFs.
- Chave 7–16, cinco famílias a separar, hífens e IDs pulados são o que
  levar da consistência para a compilação.
