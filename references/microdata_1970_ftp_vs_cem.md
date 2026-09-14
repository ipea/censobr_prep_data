# Microdados 1970: a fonte do produto, o que difere do FTP do IBGE e como o domicílio é construído

**Data:** 2026-09-13 (substitui a versão de 2026-09-11)
**Escopo:** amostra do Censo Demográfico de 1970 — de onde vem o produto `censobr`, em que ele difere dos arquivos do FTP do IBGE, como as tabelas de pessoas e de domicílios são construídas, e em que diferem do que foi publicado em v0.5.0.

---

## A fonte do produto

O produto de 1970 é construído a partir da versão dos microdados harmonizada
pelo **CEM (Centro de Estudos da Metrópole)**, hospedada no release
`release_legacy` deste repositório. Ela se reconhece pelas cinco colunas de
harmonização que o arquivo do IBGE não tem — `cem001`, `cem002`, `cem003`,
`cem004` e `CEM005`, a última em maiúsculas.

Os arquivos de texto do FTP do IBGE não servem de fonte porque dois deles,
Alagoas e Pernambuco, contêm 1.785 registros deslocados que tiram o peso
amostral do lugar (`microdata_1970_corrupcao_al_pe.md`). A versão do CEM não
tem o defeito.

| insumo no `release_legacy` | CSV de origem | parquet |
|---|---:|---:|
| `Censo.1970.brasil.pessoas.amostra.25porcento.parquet` | 3,9 GB | 337 MB |
| `Censo.1970.brasil.domicilios.amostra.25porcento.parquet` | 425 MB | 41 MB |
| `crosswalk_personid_hhid_1970.parquet` | 499 MB | 58 MB |

Só o arquivo de pessoas entra no produto. A tabela de domicílios do CEM e o
seu crosswalk são baixados como referência de validação: os domicílios são
derivados aqui, do arquivo de pessoas (ver abaixo).

## O FTP comparado à versão do CEM

Lidos byte a byte, os 27 arquivos do FTP e a versão do CEM são o mesmo censo
com pequenas diferenças de conjunto de registros:

| | FTP | CEM | diferença |
|---|---:|---:|---:|
| pessoas | 24.793.359 | 24.793.358 | +1 |
| domicílios derivados | 4.737.679 | 4.737.407 | +272 |
| colunas | 65 / 35 | 65 / 35 | iguais, mesma ordem |
| `sum(V054)` | 94.467.917 | 94.461.969 | +0,006% |
| `sum(weight_household)` | 17.685.043 | 17.682.112 | +0,017% |

A diferença está em duas UFs: Pernambuco tem 1.382.319 pessoas no FTP
(1.381.977 de `Damo70PE.txt` mais 342 de `Damo70FN.txt`) contra 1.382.323 no
CEM (−4), e Alagoas 412.171 contra 412.166 (+5). As outras 25 UFs batem pessoa
a pessoa. Em domicílios, PE +298 e AL −26.

O que a rota do FTP exige tratar, e a versão do CEM já traz resolvido:

- **Byte de fim de arquivo.** 25 dos 27 `.txt` terminam com o `0x1A` do DOS,
  que um leitor de largura fixa transforma num registro vazio; `Damo70PI.TXT`
  e `Damo70SP.txt` terminam em CRLF.
- **Município não resolvido.** 158 registros (0,00064%) não casam com o
  crosswalk de municípios. Em 117 deles `V001` e `V002` são perfeitamente
  legíveis (chaves como 1421122, 1426222, 1427722) e o que falta é a entrada
  no `crosswalk_munic_1970_to_2010.rda`, insumo deste repositório; só 41 têm
  os campos de fato ilegíveis. A UF é sempre conhecida, porque vem do nome do
  arquivo.
- **Peso ausente.** 1.113 pessoas ficam sem `V054` na leitura por posição
  fixa; quando a falta é no chefe, o domicílio fica sem peso — 131 em 4,7
  milhões — e `hh_income` (2) e `hh_income_per_cap` (268) ficam NA. A versão
  do CEM não tem nenhum desses casos.

Três características dos arquivos do IBGE que qualquer leitura precisa saber:
o registro **não tem campo de UF** (ela vem do nome do arquivo,
`Damo70<UF>.txt`, em caixa mista); a chave de município é
`UF × 10⁵ + (V001 mod 100) × 10³ + V002`, com duas exceções históricas —
`2531000` é a Guanabara, hoje Rio de Janeiro (1,1 milhão de pessoas), e
`3600000` é o Distrito Federal (135.571) —; e **a ordem das linhas é
semântica**, porque o registro de domicílio não existe na fonte e é derivado
da sequência de pessoas.

## Como o domicílio é construído

O arquivo de 1970 não tem identificador de domicílio. Cada registro é uma
pessoa, e o domicílio se reconstrói pela ordem: uma pessoa com `V025 = 1`
(chefe da família) em família única ou principal (`V006 ∈ {1, 2}`) abre um
domicílio, e as linhas seguintes pertencem a ele até o próximo chefe. O
produto aplica essa regra ao arquivo de pessoas do CEM, em
`derive_households_1970()`, e reproduz os 4.737.407 domicílios da tabela do
CEM em 100,000000% das 24.793.358 pessoas; o crosswalk do CEM coincide com a
derivação nas outras 24.325.194.

O `iddomicilio` que o arquivo de pessoas do CEM traz é outro espaço de
numeração — 4.803.419 valores densos — e não corresponde ao `household_id` da
tabela de domicílios (4.737.407), nem por fórmula. Dentro de cada domicílio
derivado, o bloco de características da habitação é coerente: nenhum domicílio
tem mais de um valor real em `V007`, `V008`, `V009` ou `V010`. Nos domicílios
de família única com chefe presente, o tamanho bate com `V005` (total de
pessoas da família) em 99,93% dos casos (1.074.813 de 1.075.550). Dos 736 que
excedem o `V005` do chefe, 697 (94,7%) têm mais de um chefe no mesmo bloco —
340 com dois, 195 com quatro, um com 32 — e são fronteiras perdidas; 39 têm um
único chefe; 1 domicílio é menor que o `V005`.

### Quem fica fora: os domicílios coletivos

Ficam sem `id_household` **453.643 pessoas (1,830%)**: 339.316 indivíduos em
domicílio coletivo, 114.325 pessoas de famílias que moram em coletivo e 2
residuais. Renda domiciliar per capita não tem sentido em hotel, quartel,
convento ou presídio, cujos moradores não partilham orçamento; por isso
coletivos não entram na tabela de domicílios nem recebem agregado domiciliar.

Os 339.316 têm `V006 = 0`, que o dicionário do IBGE rotula "PESSOA SÓ". Não
são moradores solitários. O questionário CD 1.01 mostra a categoria: no
quesito 4 (parentesco) a opção 9, "Individual (Em domicílio coletivo)",
existe só na coluna da 1ª pessoa, e no quesito 1 das características do
domicílio a opção é "0E Individual", ao lado de "1 Única" e do grupo
"Convivente" (2 Principal, 3E Parente, 4E Não parente). `V006 = 0` e
`V025 = 9` coincidem em 339.316 de 339.316, nos dois sentidos.

Medidos só na ordem crua do arquivo, sem nenhum identificador derivado, esses
registros formam 40.310 blocos contíguos de comprimento médio 8,4 e máximo
3.337, 392 deles com 100 pessoas ou mais, e nenhum atravessa município. Se
estivessem espalhados ao acaso — como quem mora sozinho — o comprimento médio
seria 1,014 e blocos de 100 teriam probabilidade da ordem de 10⁻¹⁸⁷. Quem mora
sozinho de fato (`V006 = 1` e `V005 = 1`, 243.192 pessoas) forma 217.013
blocos de comprimento médio 1,12 e máximo 74. O perfil fecha: idade mediana de
25 anos e 11,7% de menores de 15 nos `V006 = 0`, contra 49 anos e 1,2% em quem
mora sozinho. Dois coletivos adjacentes não são separáveis no arquivo, e não
precisam ser.

Os 114.325 com `V007 = 1` são famílias inteiras morando em estabelecimento
coletivo — todas com `V006 = 1` e parentesco de chefe a empregado. É o único
registro no arquivo de que aquele estabelecimento é coletivo, e o produto o
preserva.

### O bloco de características da habitação

`V007` a `V021` só vêm preenchidos nos registros da família única ou
principal: `V007` é não-NA se e somente se `V006 ∈ {1, 2}`, sem exceção. Os
códigos marcados com "E" no formulário são instruções de salto, e a cascata
fecha registro a registro: `V007` é NA em 1.162.064 registros (`V006 ∈ {0, 3,
4}`); `V008`, nesses mais os 114.325 de `V007 = 1` (1.276.389); `V009` a
`V020`, nesses mais os 14.212 de domicílio improvisado (1.290.601).

No banco de pessoas o bloco fica como o IBGE o gravou: as 822.746 pessoas de
famílias secundárias, em 233.855 domicílios (4,93%), têm `V007`–`V020` NA,
e não recebem o valor do domicílio em que moram — preencher a partir de outro
registro seria inventar dado. Quem precisa da condição de ocupação, água,
sanitário ou cômodos de uma pessoa de família secundária junta a tabela de
domicílios por `id_household`, onde o bloco vem da linha do chefe e vale para
o domicílio inteiro. A única alteração de valor é em `V021` (dormitórios):
vem com `0` em 61.390 registros em que o quesito foi pulado — família
secundária e individual em coletivo —; ali zero é o branco do impresso e
vira NA. Os 3.979 domicílios improvisados ficam com `V009`–`V020` NA também na
tabela de domicílios, porque o IBGE não lhes aplica o bloco.

### Os domicílios improvisados

A derivação do CEM descartava os domicílios improvisados (`V008 = 2`). São
domicílios particulares — `V007 = 0` em 14.212 de 14.212 —, com exatamente um
chefe em cada um dos 3.979, tamanho igual ao `V005` do chefe em 3.900 de 3.900
famílias únicas, cada um um bloco contíguo no arquivo. O produto os inclui:
3.979 domicílios e 14.521 pessoas, renda mediana 100 contra 200 no resto da
tabela e 3,65 moradores em média contra 5,14. Os identificadores criados não
colidem com nenhum existente.

## Diferenças em relação ao publicado em v0.5.0

A tabela de domicílios passa de 4.737.407 para 4.741.386 linhas (os
improvisados) e de 35 para 37 colunas. Nos 4.737.407 em comum:

| | v0.5.0 | produto |
|---|---|---|
| `weight_household` | `max(V054)` entre os chefes de **família**; em domicílio multifamiliar há dois ou três `V025 = 1` e o maior peso era adotado — em 46.136 domicílios, o de um chefe secundário | peso do chefe do **domicílio**, o da família única ou principal (exatamente um por domicílio em 4.741.386); `sum` 17.643.387 contra 17.682.112 |
| `V006` | média do `V006` das pessoas — 230.317 linhas (4,86%) com valores como 2,5 e 2,33; `V006 == 2` devolvia 15 domicílios | condição da família do chefe do domicílio: 1 ou 2; `V006 == 2` devolve 233.857 |
| `V003`, `V004` | média, gerando 4 códigos de distrito e 26 de situação inexistentes | valor da linha do chefe |
| `V025 = 0` (ignorado) | tratado como não-parente: fora do denominador da renda per capita e com renda zerada — 341 pessoas em 322 domicílios | conta como morador |
| `numb_families` | — | 1, 2 ou 3 famílias: 4.507.531 / 218.060 / 15.795 |
| `numb_residents` | — | `sum(V024 != 2)`; difere de `numb_dwellers` em 103.509 domicílios, que contêm as 154.719 pessoas marcadas pelo IBGE como não moradoras (`V024 = 2`, todas pensionista ou hóspede) |
| `name_region` | "Centro-oeste" | "Centro-Oeste" (220.664 domicílios) |

Os agregados somam todas as famílias do domicílio, nas duas versões:
`numb_dwellers_hhincome` é o total de parentes de todas as famílias em
100,0000% dos domicílios, e `hh_income` soma a renda de todas (se contasse só
a principal, faltariam 60.002.161).

No banco de pessoas, 14.521 pessoas ganharam `id_household`, nenhuma perdeu e
nenhuma mudou de domicílio; `V021` passa de `0` a NA nos 61.390 registros em
que o quesito foi pulado; nenhum outro valor muda.

| verificação do produto | |
|---|---:|
| pessoas | 24.793.358 |
| domicílios | 4.741.386 |
| pessoas sem `id_household` | 453.643 |
| ids órfãos / domicílios sem morador | 0 / 0 |
| `numb_dwellers` igual à contagem real | 100,000000% |
| maior domicílio | 37 moradores |
| `sum(V054)` | 94.461.969 |
| domicílios com peso zero | 4 (defeito da fonte: `V054 = 0` no chefe) |
| NA nas 9 colunas de geografia | 0 |
