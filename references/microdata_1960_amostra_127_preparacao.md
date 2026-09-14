# Censo de 1960, amostra de 1,27% — a preparação passo a passo

Este documento acompanha o código de `R/microdata_1960_amostra_127.R` (bloco `# 01a.` de `_targets.R`). Para cada passo ele diz qual é o problema, como o problema aparece no arquivo, o que o código faz e como o resultado fica. Todos os números vêm da execução do pipeline em 2026-09-14; os exemplos são linhas reais do arquivo.

O estágio cobre a amostra de 1,27%. A amostra de 25% e a compilação das duas — que é o que o `censobr` distribui como microdados de 1960 — virão depois, e enquanto não vêm o `censobr` continua consumindo a compilação antiga guardada no release `release_legacy`.

## 1. De onde vêm os dados

O arquivo é `HHOLDA.txt`: 1.074.328 linhas de exatamente 62 caracteres, 68.756.992 bytes. Ele foi preservado no repositório `antrologos/ConsistenciaCenso1960Br` (pasta `Original Files`), onde em 2018 foi feito o primeiro exame de consistência; o passo 1 do pipeline baixa esse arquivo, no commit `df7adcc`, e confere o tamanho. O exame de 2018 e o reexame de 2026 estão em `references/microdata_1960_amostra_127_consistencia.md`; este documento descreve o que foi implementado a partir deles.

## 2. Como o arquivo é

Cada linha é um cartão. As posições têm significado fixo:

| posições | conteúdo |
|---|---|
| 1–2 | unidade da federação, nos códigos de 1960 (0 = Rondônia, 1 = Acre, ... 97 = Distrito Federal; ver a tabela da seção 9) |
| 3–6 | município |
| 7–16 | chave do questionário: distrito (7–8), pasta (9–13) e boletim (14–16) |
| 17 | tipo de registro: 1 = família (a página do domicílio), 2 = chefe, 3 = as demais pessoas |
| 18–54 | as variáveis, conforme o tipo de registro (`read_guides/readguide_1960_amostra_127_familias.csv` e `..._pessoas.csv`) |
| 55 | uma barra invertida |
| 56–62 | número da família, acrescentado a posteriori por quem organizou o arquivo |

As primeiras seis linhas do arquivo, com uma régua de posições em cima:

```
                  1         2         3         4         5         6  
         1234567890123456789012345678901234567890123456789012345678901234
      1  0000110100014051111478950580206002                    \0000001
      2  0000110100014051212716057149191415200400000076-       \0000001
      3  0000110100014051312311657159191508210000000035-       \0000001
      4  0000110100014052111482940580206001                    \0000002
      5  000011010001405221271245704919041732000000008318728145\0000002
      6  0000110100014053111478949579208004                    \0000003
```

A linha 1 é o registro de família número 1 (posição 17 = 1); a linha 2 é o chefe dessa família (17 = 2); a linha 3, outra pessoa (17 = 3). Na linha 4 começa a família 2. O número das posições 56–62 sobe a cada registro de família.

Um hífen no meio dos dados quer dizer "daqui em diante não se aplica": a partir dele o resto da linha fica em branco. Ele só pode aparecer em cinco posições — 20, 21, 33, 36 e 47 — que são as perguntas a partir das quais o questionário permitia pular (crianças não respondem sobre trabalho, por exemplo). Nas linhas 2 e 3 acima o hífen está na posição 47.

## 3. Os quatro tipos de dano e como se veem

O arquivo foi copiado de fita, e a cópia deixou marcas. O passo 3 procura quatro sinais, cada um com um detector simples:

1. **Valor fora do dicionário.** Um caractere que não é código válido da variável naquela posição — um `"` onde só cabe dígito, um 7 onde só cabem 1 a 5. Detector: cada variável de cada guia de leitura, contra a lista de valores válidos.
2. **Caractere estranho.** Qualquer coisa que não seja dígito, branco, hífen ou barra invertida.
3. **Espaço no meio dos dígitos.** Um ou mais brancos entre dígitos, onde o layout não prevê branco — sinal de caractere perdido ou de linha deslocada.
4. **Estrutura quebrada.** Hífen fora das cinco posições permitidas, ou barra invertida fora da posição 55 — a linha inteira está deslocada.

Os detectores apontam 124 linhas (uma linha pode acionar mais de um): 99 com valor fora do dicionário, 43 com caractere estranho, 60 com espaço entre dígitos e 19 com estrutura quebrada. A lista sai em `data_raw/microdata/1960/amostra_127/linhas_problematicas.csv`.

Cada uma dessas 124 linhas tem uma decisão registrada em `read_guides/1960_amostra_127_correcoes.csv`, com o texto original, o texto corrigido (quando há) e a explicação. O pipeline para se alguma linha suspeita não tem decisão, se alguma decisão aponta linha que não é suspeita, ou se o texto original de uma decisão não é o que está no arquivo — assim a lista de correções nunca fica dessincronizada do arquivo.

## 4. Passo a passo

### Passo 1 — download

Baixa `HHOLDA.txt` para `data_raw/microdata/1960/amostra_127/` e confere os 68.756.992 bytes.

### Passo 2 — leitura

Lê o arquivo como texto, uma linha por registro, e para se alguma linha não tem 62 caracteres. Ao lado do texto ficam colunas de navegação — número da linha, tipo de registro, UF, município, as três partes da chave e o número a posteriori — que servem apenas para localizar cada linha nos passos seguintes.

### Passo 3 — detecção

Roda os quatro detectores da seção 3 e escreve `linhas_problematicas.csv`.

### Passo 4 — correções

Aplica as decisões do arquivo de correções. Há seis tipos, e abaixo há um exemplo real de cada, com o texto antes e depois:

- **valor_isolado** (101 linhas): um ou poucos valores fora do dicionário num registro coerente. O texto não muda; o valor vira NA no passo 5, e o nome da variável anulada fica em `censobr_variaveis_anuladas`.
- **reparo** (12 linhas): um caractere perdido ou sobrando deslocou parte da linha; o texto é reconstruído devolvendo cada campo à sua posição.
- **recuperada** (5 linhas): a linha parecia ilegível, mas tirando brancos e fragmentos ela se lê inteira e pertence a uma família identificável pela chave do questionário.
- **realocada** (1 linha): o texto está íntegro, mas a chave do questionário mostra que a pessoa pertence a outra família; só muda a família.
- **corrompida** (3 linhas): ilegível de fato. Os campos de dado ficam em branco; só o tipo de registro fica, para que a pessoa continue contada no domicílio.
- **cartao_uf** (2 linhas): cartões de cabeçalho da fita, com o nome do estado em letras; não são pessoas e saem do arquivo.

**Linha 9817 — valor_isolado.** 2018: um ou poucos valores fora do dicionário, o resto do registro é coerente; esses valores viram NA.

```
                  1         2         3         4         5         6  
         1234567890123456789012345678901234567890123456789012345678901234
antes    02024301021102572117128571"912183110085404048352425156\0001403
depois   (texto mantido; só o valor apontado vira NA na leitura)
```

**Linha 387715 — reparo.** 2026: um caractere perdido entre as posições 38 e 44 puxou V219/V220 uma casa para a esquerda (hífen de salto em 46, não em 47). Inserido um branco na posição 45: V219 fica NA, V220 e o salto voltam ao lugar. A posição 46 (V220 perdido, V219 = 4) seria igualmente compatível; não há como decidir entre as duas.

```
                  1         2         3         4         5         6  
         1234567890123456789012345678901234567890123456789012345678901234
antes    313399073378603435291205705920001821000000034-        \0061919
depois   31339907337860343529120570592000182100000003 4-       \0061919
```

**Linha 194609 — recuperada.** 2026: a linha começa com três brancos e uma barra e tem dois brancos a mais; tirando-os, é uma filha de 8 anos com todos os campos válidos, do questionário 0721032115 — a família ID 32581, 15.594 linhas adiante. Reatribuída a ela.

```
                  1         2         3         4         5         6  
         1234567890123456789012345678901234567890123456789012345678901234
antes       \212135072103211531 291 08542092000052-             0029831
depois   21213507210321153129108542092000052-                  \0032581
```

**Linha 951430 — recuperada.** 2026: entre os fragmentos lê-se, sem os espaços, '8182620181076017 1 1 1 4 7 8 9 4': UF 81, município 8262, questionário 0181076017, registro de família, urbano, domicílio único, tipo 4, condição 7, aluguel 8, água 9, sanitário 4. V107–V113 perderam-se. É o registro de família que faltava à família ID 158808 (3 pessoas).

```
                  1         2         3         4         5         6  
         1234567890123456789012345678901234567890123456789012345678901234
antes    182 1000000008371 323326\81 82620181 07 601 71 11 478940155539
depois   818262018107601711147894                              \0158808
```

**Linha 293556 — realocada.** 2026: a linha está íntegra, mas o questionário 0731608050 é o da família ID 48357 (Bahia, município 3138), 10.578 linhas adiante; estava presa à família anterior (Sergipe). A chave do questionário a devolve à família certa; nada muda no texto.

```
                  1         2         3         4         5         6  
         1234567890123456789012345678901234567890123456789012345678901234
antes    31 1 80731608050352911557059200031100000000034-       \0046690
depois   (texto mantido; a linha muda de família pela chave do questionário)
```

**Linha 855822 — corrompida.** 2018: registro inteiro ilegível; todas as variáveis viram NA.

```
                  1         2         3         4         5         6  
         1234567890123456789012345678901234567890123456789012345678901234
antes    91 5 6542 692000311 0000000003332321 1 60\60643301 644\0140406
depois   (todos os campos de dado ficam em branco; só o tipo de registro fica)
```

**Linha 293555 — cartao_uf.** 2026: cartão de cabeçalho da fita ('BAHIA' em letras, na fronteira Sergipe→Bahia), não é pessoa. Excluído.

```
                  1         2         3         4         5         6  
         1234567890123456789012345678901234567890123456789012345678901234
antes    31   M       1BA33HIA                                 \0046690
depois   (linha excluída)
```


Depois do passo 4 o arquivo tem 1.074.326 linhas (as duas de cabeçalho saíram), e cada linha carrega em `censobr_diagnostico` o tipo de decisão que a tocou (ou `sem_problema`).

### Passo 5 — layout

Aplica os guias de leitura e separa duas tabelas, `familias` (174.467 linhas) e `pessoas` (899.859 linhas), ainda em texto. Um campo fica NA quando está em branco, quando está depois de um hífen de salto ou quando tem valor fora do dicionário.

### Passo 6 — as linhas duplicadas de Pernambuco

**O problema.** Em três municípios de Pernambuco (2135, 2113 e 2115) o arquivo repete linhas de pessoa: a mesma pessoa, com os 54 caracteres de dado idênticos, aparece duas vezes na mesma família, nunca uma logo abaixo da outra e em ordem embaralhada. É o rastro de um defeito de cópia da fita — o mesmo que fez o numerador de famílias pular 856 números exatamente nesses municípios. Sem tratamento Pernambuco fica com 5% de gente a mais.

**Como aparece.** A família 29839 lista as pessoas A, B, C, D, E e, algumas linhas depois, C, B, A, E, D. As linhas marcadas com `*` são as que o passo remove:

```
                  1         2         3         4         5         6  
         1234567890123456789012345678901234567890123456789012345678901234
 194616  2121130521438002151478384680203002                    \0029839
 194617  212113052143800225171375720920003110095404045332321177\0029839
 194618  2121130521438002352812654209200031100954040434-       \0029839
 194619  2121130521438002351911457209200031100000000031-       \0029839
 194620  21211305214380023519103572092000-                     \0029839
 194621  21211305214380023519101572092000-                     \0029839
 194622  21211305214380023529001572092000-                     \0029839
*194623  21211305214380023519103572092000-                     \0029839
*194624  2121130521438002351911457209200031100000000031-       \0029839
*194625  2121130521438002352812654209200031100954040434-       \0029839
*194626  21211305214380023529001572092000-                     \0029839
*194627  21211305214380023519101572092000-                     \0029839
```

**O que o código faz.** Uma linha é cópia quando repete, dentro da mesma família, todas as variáveis de uma linha anterior. A cópia é removida em dois casos: quando a pessoa repetida é chefe ou cônjuge (nenhuma família tem dois cônjuges idênticos), ou quando a família tem duas ou mais linhas repetidas (uma cópia em bloco). Uma única linha repetida de filho ou outro parente, numa família sem outra repetição, pode ser gêmeos com o mesmo perfil e fica, marcada em `censobr_duplicata_mantida`.

**Como fica.** 2.805 linhas removidas, 2.733 delas em Pernambuco (497 eram cônjuges repetidos); a lista está em `duplicatas_removidas.csv`. 891 linhas repetidas ficam marcadas — 775 são filhos, a maioria com menos de 10 anos. A população implícita de Pernambuco cai para 4,15 milhões, em linha com as UFs vizinhas.

### Passo 7 — famílias e domicílios

**A família.** Cada pessoa é ligada ao registro de família que tem a mesma UF e a mesma chave de questionário. É assim que o formulário de 1960 funcionava: um boletim por família, com a página do domicílio na frente e as pessoas atrás. Em 99,2% das linhas isso coincide com o número a posteriori; nas demais a chave corrige o número — é por aqui que as linhas realocadas e recuperadas do passo 4 chegam à família certa.

**Pessoas cujo questionário não tem registro de família.** São 2.678 pessoas em 586 grupos (um grupo = uma chave). O número a posteriori não ajuda a decidir o que são: ele foi atribuído contando registros de família na ordem do arquivo, e 585 dos 586 grupos carregam o número da família imediatamente anterior. Sobra o que está nas próprias linhas:

- **O grupo tem chefe ou cônjuge** (150 grupos, 485 pessoas): é uma família cujo registro de família — e quase sempre o chefe, que era a linha seguinte — se perdeu na fita. Três grupos ainda têm o chefe; 147 têm só cônjuge, e em 87 deles a família anterior já tem o seu próprio cônjuge, o que exclui a hipótese de ser a mesma família. O grupo vira família nova, sem página de domicílio (V101 a V113 ficam NA), marcada `registro_perdido`. No exemplo abaixo a família 2586 tem um chefe de 29 anos sozinho no boletim 075; o boletim 076 traz uma mulher de 60 anos codificada como cônjuge e seis filhos de 4 a 26 anos — não é a mesma família:

```
                  1         2         3         4         5         6  
         1234567890123456789012345678901234567890123456789012345678901234
  17985  0404320504246075151578379680202001                    \0002586   familia 2586 (registro)
  17986  040432050424607525171295717920003110065703037334322117\0002586   familia 2586 (registro)
  17987  040432050424607635191265717920003110000000007334322117\0002586   familia 174468 (registro_perdido)
  17988  040432050424607635191185717920003110000000006334322117\0002586   familia 174468 (registro_perdido)
  17989  0404320504246076352816057179200031100731110834-       \0002586   familia 174468 (registro_perdido)
  17990  0404320504246076352912157179200031100000000034-       \0002586   familia 174468 (registro_perdido)
  17991  0404320504246076352911457179200031100000000034-       \0002586   familia 174468 (registro_perdido)
  17992  04043205042460763529108571792000311-                  \0002586   familia 174468 (registro_perdido)
  17993  04043205042460763529104571792000-                     \0002586   familia 174468 (registro_perdido)
```

- **O grupo não tem chefe nem cônjuge** (436 grupos, 1.008 pessoas): são sobretudo hóspedes (V203 = 4 em 698 delas) e pessoas presentes que não moram ali (V202 = 5 ou 6 em 681), listadas num boletim à parte logo depois da família. Ficam na família anterior, marcadas `anexada_anterior`. A família 2326 é um chefe de 50 anos sozinho seguido de 26 hóspedes não moradores em dois boletins:

```
                  1         2         3         4         5         6  
         1234567890123456789012345678901234567890123456789012345678901234
  16182  0404130104192016111478954580202001                    \0002326   registro
  16183  040413010419201621171505407912071757800000003327127180\0002326   registro
  16184  04041301041920173154106541792000311-                  \0002326   anexada_anterior
  16185  040413010419201731641295717920001644165901018319128145\0002326   anexada_anterior
  16186  0404130104192017316412054179200017210000000034-       \0002326   anexada_anterior
  16187  040413010419201731641255717920001721000000009319128145\0002326   anexada_anterior
  16188  040413010419201731641255717920001721000000009319124216\0002326   anexada_anterior
  16189  040413010419201731641255417920001732000000007319124216\0002326   anexada_anterior
  16190  0404130104192017316413854179200015200652050534-       \0002326   anexada_anterior
   ... e mais 19 linhas de hóspedes (V203 = 4), todas anexadas à família anterior
```

**O domicílio.** V101 diz o que a família é: 1 = único ocupante do domicílio, 2 = família principal de um domicílio com mais de uma, 3 = coletivo, 4 = segunda família, 5 = terceira. Uma família 4 ou 5 vem sempre logo depois da principal, com o boletim seguinte. Então 1, 2 e 3 abrem domicílio; 4 e 5 entram no domicílio da família anterior. O único 5 que vem depois de um 1 (família de número a posteriori 121705) abre domicílio próprio, marcado em `censobr_convivente_isolada`.

Registros de família nas linhas 5648 (V101 = 2) e 5651 (V101 = 4):

| linha | tipo | V101 | V203 | idade | familia | domicilio |
|---|---|---|---|---|---|---|
| 5649 | 2 | 2 | 7 | 33 | 789 | 789 |
| 5650 | 3 | 2 | 2 | 23 | 789 | 789 |
| 5652 | 2 | 4 | 7 | 38 | 790 | 789 |
| 5653 | 3 | 4 | 9 | 9 | 790 | 789 |
| 5654 | 3 | 4 | 9 | 3 | 790 | 789 |
| 5655 | 3 | 4 | 9 | 1 | 790 | 789 |
| 5656 | 3 | 4 | 8 | 27 | 790 | 789 |
| 5657 | 3 | 4 | 9 | 5 | 790 | 789 |

**Rondônia.** 64 famílias (253 pessoas) estão gravadas com UF 03 (Roraima) e município 0011, que é Porto Velho: têm a mesma pasta das 76 famílias de Rondônia, naturalidade de Guaporé e Amazonas como elas, e estão no arquivo logo antes do Roraima verdadeiro (município 0310). Voltam para Rondônia (UF 00), marcadas em `censobr_uf_corrigida`. Abaixo, dois registros de família de Rondônia, três dos gravados como Roraima e dois do Roraima verdadeiro:

```
                  1         2         3         4         5         6  
         1234567890123456789012345678901234567890123456789012345678901234
      1  0000110100014051111478950580206002                    \0000001
      4  0000110100014052111482940580206001                    \0000002
  15316  0300110100014127111481950570204001                    \0002193
  15321  0300110100014140111498943570205002                    \0002194
  15326  0300110100014141111498954580205001                    \0002195
  15632  0303100103002079111581060580203002                    \0002257
  15638  0303100103002080111485940570206003                    \0002258
```

**Como fica.** 174.467 registros de família mais 150 famílias sem registro dão 174.617 famílias (uma delas tem registro mas nenhuma pessoa). São 174.245 domicílios: 173.899 com uma família, 318 com duas e 27 com três. Duas famílias têm duas pessoas na posição de chefe (números 54150 e 137492), marcadas em `censobr_dois_chefes`; 148 não têm chefe (as 147 sem registro e com cônjuge, e uma com registro cujas pessoas não incluem o chefe).

### Passo 8 — tabelas finais

- **Contagens por domicílio**, com nomes inequívocos (a versão de 2018 trocava os rótulos das suas duas): `censobr_n_listadas` (todas as pessoas listadas), `censobr_n_residentes` (exclui V202 = 5 ou 6, presentes que não moram ali), `censobr_n_presentes` (exclui V202 = 3 ou 4, moradores ausentes) e `censobr_n_familias`.
- **Peso.** A amostra foi sorteada com probabilidade igual para todos; cada pessoa representa 1/0,0127 = 78,74 pessoas (`censobr_weight`). A calibração às populações oficiais e a decisão sobre Rondônia (só Porto Velho urbano foi amostrado) são do estágio da compilação.
- **Códigos.** Filhos tidos e vivos (V217, V218) só têm códigos até 30, mais 99 = ignorado; 26 valores de V217 e 2 de V218 entre 31 e 98 viram NA, marcados em `censobr_v217_fora_da_faixa` e `censobr_v218_fora_da_faixa`. O número da idade, que a sintaxe original chamava AGE, fica em V204B; V204 diz se ele está em meses (0), anos (1), acima de 99 anos (5) ou é ignorado (9).
- **Coerência entre parentes.** Três marcas, sem nenhuma correção: cônjuge do mesmo sexo do chefe (459 pessoas), filho mais velho que o chefe (130) e casamento antes dos 10 anos de idade, tomando V216 de 01 a 60 como 1901 a 1960 (1.774).
- **Página de domicílio nas pessoas.** Cada pessoa leva V101 a V113 do seu próprio registro de família, como no original. Nas famílias secundárias (V101 = 4 ou 5) essa página está em branco no arquivo e fica em branco aqui; preencher com a página da família principal seria inventar dado. Quem precisa dela junta as tabelas por `censobr_idhousehold`.
- **Tipos.** UF, o número a posteriori e todas as V viram inteiros. As três pessoas das linhas corrompidas ficam com UF, município e chave em branco; a família e o domicílio delas vêm da posição no arquivo.

## 5. O que sai

Duas tabelas em `data_raw/microdata/1960/amostra_127/`, intermediárias — a compilação com a amostra de 25% é que produzirá os parquets do `censobr`:

| arquivo | linhas | colunas | tamanho |
|---|---|---|---|
| `pessoas_1960_amostra_127.parquet` | 897.054 | 65 | 24 MB |
| `domicilios_1960_amostra_127.parquet` | 174.245 | 34 | 2,7 MB |

As colunas do IBGE (UF, V116, V118, V101–V113, V202–V224) ficam com os nomes dos guias de leitura. As colunas `censobr_*`:

| coluna | o que é |
|---|---|
| `censobr_idhousehold`, `censobr_idfamily` | identificadores do domicílio e da família reconstruídos no passo 7 |
| `linha`, `id_arquivo`, `distrito`, `pasta`, `boletim`, `chave` | onde a linha está no arquivo e a chave do questionário |
| `censobr_tipo_registro` | 2 = chefe, 3 = demais pessoas |
| `censobr_diagnostico`, `censobr_variaveis_anuladas` | a decisão do passo 4 que tocou a linha e as variáveis anuladas |
| `censobr_duplicata_mantida` | linha repetida que ficou (passo 6) |
| `censobr_familia_origem` | `registro`, `registro_perdido` ou `anexada_anterior` (passo 7) |
| `censobr_uf_corrigida`, `censobr_convivente_isolada`, `censobr_dois_chefes` | as três situações do passo 7 |
| `censobr_n_*` | contagens por domicílio |
| `censobr_v217_fora_da_faixa`, `censobr_v218_fora_da_faixa`, `censobr_flag_*` | códigos anulados e marcas de coerência do passo 8 |
| `censobr_weight` | 78,74 |

## 6. Números por UF

| UF | sigla | domicilios | familias | pessoas | pessoas_por_domicilio | populacao_implicita |
|---|---|---|---|---|---|---|
| 0 | RO | 140 | 140 | 675 | 4,82 | 53.150 |
| 1 | AC | 476 | 476 | 2.929 | 6,15 | 230.630 |
| 2 | AM | 1.625 | 1.640 | 9.771 | 6,01 | 769.370 |
| 3 | RR | 58 | 58 | 401 | 6,91 | 31.575 |
| 4 | PA | 3.561 | 3.575 | 20.450 | 5,74 | 1.610.236 |
| 6 | AP | 210 | 210 | 1.354 | 6,45 | 106.614 |
| 10 | MA | 5.896 | 5.902 | 31.155 | 5,28 | 2.453.150 |
| 12 | PI | 2.809 | 2.816 | 16.328 | 5,81 | 1.285.669 |
| 14 | CE | 7.347 | 7.349 | 41.204 | 5,61 | 3.244.409 |
| 17 | RN | 2.778 | 2.779 | 14.639 | 5,27 | 1.152.677 |
| 19 | PB | 4.876 | 4.890 | 25.864 | 5,30 | 2.036.535 |
| 21 | PE | 10.500 | 10.513 | 52.717 | 5,02 | 4.150.945 |
| 24 | FN | 62 | 63 | 293 | 4,73 | 23.071 |
| 25 | AL | 3.093 | 3.093 | 15.707 | 5,08 | 1.236.772 |
| 30 | SE | 2.376 | 2.377 | 11.472 | 4,83 | 903.307 |
| 31 | BA | 15.402 | 15.428 | 79.920 | 5,19 | 6.292.913 |
| 40 | MG | 23.311 | 23.334 | 126.835 | 5,44 | 9.987.008 |
| 50 | Serra dos Aimorés | 872 | 874 | 4.776 | 5,48 | 376.063 |
| 51 | ES | 2.427 | 2.441 | 13.916 | 5,73 | 1.095.748 |
| 52 | RJ | 8.408 | 8.420 | 41.758 | 4,97 | 3.288.031 |
| 54 | GB | 8.766 | 8.807 | 37.128 | 4,24 | 2.923.465 |
| 60 | SP | 34.389 | 34.492 | 164.180 | 4,77 | 12.927.559 |
| 71 | PR | 10.074 | 10.082 | 52.540 | 5,22 | 4.137.008 |
| 74 | SC | 5.054 | 5.061 | 27.934 | 5,53 | 2.199.528 |
| 81 | RS | 13.145 | 13.181 | 66.785 | 5,08 | 5.258.661 |
| 91 | MT | 1.828 | 1.831 | 10.380 | 5,68 | 817.323 |
| 94 | GO | 4.625 | 4.647 | 25.362 | 5,48 | 1.997.008 |
| 97 | DF | 137 | 137 | 578 | 4,22 | 45.512 |

Total: 174.245 domicílios, 174.616 famílias, 897.054 pessoas (3 delas com UF ilegível).


## 7. Decisões que ficam em aberto

- V208 (nacionalidade) em branco não é imputada.
- O critério de remoção de duplicatas (chefe ou cônjuge repetido, ou família com duas ou mais repetições) deixa 891 linhas repetidas no banco, marcadas.
- As 150 famílias sem registro entram na tabela de domicílios como domicílios próprios, com V101 a V113 em branco.
- A marca de casamento impossível depende de ler V216 de 01 a 60 como ano de 1901 a 1960; os códigos 61 a 99 não são usados.
- Os pesos por UF e situação, e o tratamento de Rondônia, ficam para a compilação.

## 8. Como auditar

- `linhas_problematicas.csv` e `duplicatas_removidas.csv`, em `data_raw/microdata/1960/amostra_127/`, listam tudo que foi apontado e removido.
- `read_guides/1960_amostra_127_correcoes.csv` tem cada correção com o texto antes e depois.
- Cada passo é um alvo do `targets`: `targets::tar_read(linhas_1960_amostra_127)`, `problemas_...`, `linhas_corrigidas_...`, `tabelas_brutas_...`, `tabelas_dedup_...`, `familias_...`, `tabelas_...` e `output_...`. Qualquer passo pode ser aberto e conferido sem rodar os outros.
