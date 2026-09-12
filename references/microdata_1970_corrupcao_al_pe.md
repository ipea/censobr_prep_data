# Registros corrompidos nos microdados da amostra do Censo 1970 (Alagoas e Pernambuco)

**Data:** 2026-09-12
**Autor:** equipe do `censobr` / `censobr_prep_data`
**Assunto:** 1.785 registros deslocados em dois dos 27 arquivos de microdados da
amostra do Censo Demográfico de 1970 distribuídos no FTP do IBGE

---

## Resumo

Dois dos 27 arquivos de microdados da amostra do Censo 1970 — `DAMO70AL.txt`
(Alagoas) e `Damo70PE.txt` (Pernambuco) — contêm registros em que um bloco de
caracteres foi deslocado: alguns ficaram mais longos e outros, mais curtos, na
mesma proporção. São **1.785 registros** em 24.793.359, ou 0,0072% da amostra
nacional.

O defeito está no arquivo tal como distribuído: o CRC do `.zip` confere.

A consequência prática é séria e silenciosa. O peso amostral é o último campo do
registro (posições 75-76), e o deslocamento o tira do lugar. Numa leitura por
posição fixa — que é como esses arquivos são lidos — dos 1.785 registros:

- **899** perdem o peso (as posições 75-76 caem fora do campo);
- **650** recebem **um peso falso, mas plausível** — sem nenhum sinal de erro;
- 24 acertam por acaso;
- e outras **212 linhas fragmentárias**, que não são registros de pessoa,
  entram na tabela como se fossem.

## Identificação dos arquivos

Origem: `https://ftp.ibge.gov.br/Censos/Censo_Demografico_1970/Microdados/Microdados_Censo_Demografico_1970_Amostra.zip`
(263.170.655 bytes, MD5 `d390dff085f7ad92775b665f91d053e3`)

| Arquivo | Bytes | Data no zip | MD5 | Registros | Anômalos |
|---|---:|---|---|---:|---:|
| `Dados/DAMO70AL.txt` | 32.148.949 | 2005-11-14 17:10 | `37094fe0b11b2a7ac5d2bb182e95e9f3` | 412.171 | **46** |
| `Dados/Damo70PE.txt` | 107.794.519 | 2005-11-16 10:25 | `e1d1fa7110fe9ab0b2478742f04befac` | 1.381.977 | **1.739** |
| `Dados/DAMO70AC.txt` (referência, íntegro) | 4.669.861 | 1998-01-21 10:43 | `a681e6bfce52a96e3892016e0744d913` | 59.870 | 0 |

Os outros 25 arquivos têm **100% das linhas com exatamente 76 caracteres**.

## Como o defeito se manifesta

O registro da amostra de 1970 tem 76 caracteres (layout de 54 variáveis,
posições 1 a 76, sem lacunas). Nos dois arquivos afetados aparecem linhas de
16, 20, 54, 58, 66, 68, 94, 98, 132, 136 e 154 caracteres.

Os desvios se concentram em **±18 e ±60**, e os ganhos compensam as perdas:

| Arquivo | −60 | −18 | +18 | +60 | outros | saldo em bytes |
|---|---:|---:|---:|---:|---:|---:|
| Alagoas | 6 | 22 | 17 | 1 | 0 | −390 |
| Pernambuco | 205 | 657 | 658 | 204 | 15 | +274 |

Em Pernambuco o pareamento é quase exato (657 contra 658, e 205 contra 204);
os 15 restantes se distribuem por desvios menores (−56, −22, −10, −8, +22, +56
e +78). O tamanho total do arquivo praticamente se conserva. **Caracteres foram
movidos, não criados nem destruídos.**

### Exemplo — registro alongado (Alagoas, linha 273.198, byte 21.309.366)

```
273197   76 |2466140100610049255212222030201034041013-    -                      -     04|
273198   94 |2466140100610049255212222030201032081013-    -                      -                 -     04|
273199   76 |2466140120610019655211222070201034031013-    -                      -     05|
```

A linha 273.198 tem 18 caracteres a mais (`                 -`) inseridos no meio
da região de preenchimento. **O início do registro está correto** — o prefixo
`2466140` é o mesmo das vizinhas — **e o fim também**: o peso `04` está lá, mas
nas posições 93-94 em vez de 75-76.

### Exemplo — registro encurtado (Alagoas, linha 273.226, byte 21.311.568)

```
273225   76 |2466140120310019255212222040100014191013-    22059910060272231224143-     05|
273226   58 |2466140140101014741013-    2205999999910-         06000004|
273227   76 |2466140100310019155212222030100014353013-    22059940060272231224243-     04|
```

Faltam 18 caracteres do miolo. O começo (`2466140`) e o fim continuam no lugar.

## Padrão da ocorrência

O defeito **não é ruído aleatório**. Três regularidades:

1. **Concentração espacial.** Em Alagoas, todas as 46 ocorrências estão entre
   66,3% e 88,5% do arquivo (linhas 273.198 a 364.635); não há nenhuma nos
   primeiros dois terços — a distribuição por decil é `0 0 0 0 0 0 6 6 34 0`.
   Em Pernambuco, 1.731 das 1.739 estão nos primeiros 60%.

2. **Pareamento regular em Alagoas.** Cada linha alongada é seguida de uma
   encurtada 27 a 28 registros adiante — `273198:94 → 273226:58`,
   `282441:16 → 282469:58`, `285803:16 → 285831:58`, `308489:94 → 308516:58`.
   Os registros entre as duas continuam com 76 caracteres e conteúdo plausível.

3. **Alinhamento com fronteiras de 4 KB.** Das linhas anômalas, 37,0% em
   Alagoas (17 de 46) e 12,8% em Pernambuco (223 de 1.739) começam a até 76
   bytes de um múltiplo de 4.096 — contra 3,7% esperados por acaso.
   Enriquecimento de 10× e 3,5×.

Praticamente não há lixo binário: Alagoas não tem nenhum byte de controle fora
de CR/LF; Pernambuco tem 9 em 107 MB (1 NUL e 4 TAB).

## O que isso sugere, e o que não dá para afirmar

O conjunto — transferência de blocos fixos de caracteres, com conservação do
total, concentrada em regiões do arquivo e alinhada a 4 KB — é compatível com
**um processo de cópia ou conversão com buffer em que a fronteira de escrita
escorregou**: leitura de registros de tamanho fixo com comprimento
desencontrado, ou uma transferência que tratou alguns blocos de forma diferente.
Os 4 KB são a assinatura da unidade de entrada e saída.

**Não é possível determinar, a partir do arquivo, qual etapa produziu o
defeito** — conversão de fita para disco, transferência ou edição posterior.

Uma hipótese que **testamos e descartamos**: a de que os dois arquivos seriam os
republicados pelo IBGE em novembro de 2005. As datas dentro do zip mostram que
**nove** arquivos são daquele lote (AL, BA, CE, PB, MA, RN, SE, FN e PE) e
**sete estão íntegros**. A data, por si, não distingue os afetados.

Dois indícios de que existe ou existiu cópia boa:

- os 16 arquivos datados de **janeiro de 1998** estão todos limpos;
- a versão harmonizada pelo **CEM (Centro de Estudos da Metrópole)**, usada em
  outros produtos, não apresenta o defeito.

## Como reproduzir a verificação

```r
library(readr)
linhas <- read_lines("Dados/DAMO70AL.txt", locale = locale(encoding = "ISO-8859-1"))
linhas <- linhas[nchar(linhas) > 1]      # descarta o 0x1A de fim de arquivo
table(nchar(linhas))
#      16      58      76      94     136
#       6      22  412125      17       1
```

Num arquivo íntegro, como `DAMO70AC.txt`, a tabela tem uma única entrada: `76`.

## O que fizemos no `censobr_prep_data`

Como o início e o fim do registro sobrevivem ao deslocamento, o peso amostral é
recuperável dos dois últimos caracteres da linha. No pipeline:

1. o arquivo é lido linha a linha, e o vetor é entregue ao parser de largura
   fixa — ler direto do arquivo faz o `readr::read_fwf` **inserir uma linha
   inexistente** em Pernambuco (posição 108.813), o que desalinharia os
   identificadores de domicílio e de pessoa, que são posicionais em 1970;
2. **212 linhas fragmentárias** são descartadas — têm de 16 a 20 caracteres e
   de 3 a 10 das 54 variáveis preenchidas, sem sexo, idade nem parentesco;
3. nos **1.573 registros** deslocados restantes, o peso é lido da cauda da
   linha (40 em AL, 1.533 em PE);
4. em **6 deles** a cauda também é ilegível; entram na imputação geral, que dá
   a mediana do setor e, na falta, a do município.

Evidência de que a recuperação acerta: a distribuição dos pesos recuperados
reproduz a real (moda 4, com 881 casos, depois 3 com 535 e 5 com 99), enquanto
a leitura nas posições 75-76 devolvia valores como 27, 10, 19 e 21. E a soma
nacional dos pesos, que estava 5.948 acima da versão de referência, passou a
ficar 1.853 abaixo — o erro caiu a um terço.

**Ressalva importante:** nesses 1.573 registros **apenas o peso é confiável**. O
miolo continua deslocado, então as demais variáveis deles seguem suspeitas. São
0,006% dos registros, concentrados em Pernambuco.

## Pedido ao IBGE

Se houver cópia anterior de `DAMO70AL.txt` e `Damo70PE.txt` — em particular da
leva de janeiro de 1998, que está íntegra nos outros arquivos —, a
redisponibilização resolveria o problema na origem e tornaria desnecessário
qualquer remendo por parte dos usuários.
