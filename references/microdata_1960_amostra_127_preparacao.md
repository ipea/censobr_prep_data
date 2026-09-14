# Censo de 1960, amostra de 1,27% — a preparação passo a passo

Este documento acompanha o código de `R/microdata_1960_amostra_127.R` (bloco `# 01a.` de `_targets.R`). Para cada passo ele diz qual é o problema, como o problema aparece no arquivo, por que ele aparece assim, o que o código faz e como o resultado fica. Todos os números vêm da execução do pipeline em 2026-09-14; os exemplos são linhas reais do arquivo.

O estágio cobre a amostra de 1,27%. A amostra de 25% e a compilação das duas — que é o que o `censobr` distribui como microdados de 1960 — virão depois, e enquanto não vêm o `censobr` continua consumindo a compilação antiga guardada no release `release_legacy`.

## 1. De onde vêm os dados

**O arquivo.** `HHOLDA.txt`: 1.074.328 linhas de exatamente 62 caracteres, 68.756.992 bytes. Foi preservado no repositório `antrologos/ConsistenciaCenso1960Br` (pasta `Original Files`), onde em 2018 foi feito o primeiro exame de consistência; o passo 1 baixa esse arquivo, no commit `df7adcc`, e confere o tamanho. O exame de 2018 e o reexame de 2026 estão em `references/microdata_1960_amostra_127_consistencia.md`.

**O gabarito.** Em março de 1965 o IBGE publicou, com estes mesmos cartões, os *Resultados Preliminares do Censo Demográfico*, Série Especial, volume II (biblioteca digital do IBGE, `liv84480`, 50 páginas). O volume descreve como a amostra foi sorteada e traz sete quadros de resultados para o Brasil e para as regiões Nordeste, Leste e Sul. Como foi tabulado antes do dano que o arquivo sofreu depois, ele é a referência externa de tudo o que se faz aqui: os quadros 1 e 6 estão transcritos e conferidos em `references/censo_1960_resultados_preliminares_1965.csv` (seção 7).

**A história do arquivo.** Um relatório interno do IPEA de abril de 1969 (*Processamento de uma amostra do Censo Demográfico de 1960*, repositório do IPEA) mostra que naquele ano o IPEA guardava 29 caixas com cerca de 56.000 cartões perfurados de uma subamostra desta amostra, para as regiões Nordeste, Sul e Leste, e que os cartões foram gravados em fita magnética no Rio Data Centro da PUC do Rio de Janeiro. O layout descrito lá — 26 variáveis de pessoa e 13 de domicílio, na mesma ordem — é o deste arquivo. Ou seja, o arquivo é a imagem de um baralho de cartões de 62 colunas que circulou entre instituições, de cartão para fita e de fita para disco, ao longo de décadas.

**A documentação do censo.** O boletim da amostra (`Questionário 1960 - amostra.pdf`) e as *Instruções ao Recenseador* (`doc0090.pdf`) estão em `D:\Dropbox\Workshop Censo\Censos\`; são a fonte para o significado dos códigos (seção 10).

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

A pasta (posições 9 a 13) não é um detalhe: é a unidade que o IBGE sorteou (seção 7). O arquivo tem 817 pastas distintas para as 814 sorteadas — as três a mais são a pasta de Rondônia gravada em duas UFs (seção 6, passo 7) e chaves com um dígito trocado — com mediana de 223 questionários por pasta. Nenhum conglomerado inteiro se perdeu.

## 3. Por que o arquivo está assim

O arquivo foi copiado de fita e de cartão muitas vezes, e cada cópia é uma leitura física de um meio com seus erros. Não há uma causa só: há uma coleção de acidentes de tipos diferentes, e cada tipo deixa uma assinatura própria, que diz o que a correção pode e não pode fazer.

- **Um caractere errado, o resto intacto** (101 linhas). Erro de paridade numa coluna da fita, ou uma perfuração lida com um furo a mais ou a menos. Nos códigos de cartão, um furo de zona a mais transforma um dígito num caractere como `"`. A informação daquele campo está perdida, e só dela.
- **A linha deslocada uma posição** (12 linhas). Um caractere perdido ou inserido no meio do registro empurra tudo à direita. A assinatura é o hífen de salto fora do lugar (46 em vez de 47) e a linha ainda com 62 caracteres, porque o conversor completou ou cortou no fim.
- **Pedaços de dois registros misturados com brancos** (8 linhas). Típico de recuperação de erro em bloco de fita: a leitura repetida do bloco deixa no buffer metade do registro anterior e metade do novo.
- **Blocos de cartões copiados** (2.850 linhas, quase todas em três municípios de Pernambuco). Fitas e baralhos são copiados em blocos; uma releitura após erro reemite o bloco. As cópias aparecem coladas ao fim da família, em ordem permutada, e o numerador de famílias pulou 856 números exatamente nesses municípios: contou lixo que depois foi limpo, e o lixo que sobrou são as cópias.
- **Blocos de cartões perdidos** (150 famílias sem o cartão de família, quase sempre também sem o do chefe, que era o cartão seguinte). As perdas se concentram em 35 pastas — a pasta 54822 da Guanabara sozinha perdeu 32 registros de família —, que são caixas físicas de cartões.
- **Um cartão fora do lugar** (1 linha). Íntegro, mas pertencente a uma família 10.578 linhas adiante, no outro estado, na fronteira entre as caixas de Sergipe e Bahia: um cartão que caiu e foi recolocado na caixa errada.
- **Um lote inteiro com a UF errada** (64 famílias). O campo de UF era fixado na perfuradora para todo o lote; um lote de Porto Velho perfurado com a UF pré-fixada de Roraima produz dezenas de cartões com o mesmo erro e o resto perfeito.
- **Cartões de cabeçalho** (2 linhas, "BAHIA" e "GUANABARA" em letras). Não são dano: cada caixa de cartões começava com um cartão de identificação, e o programa que converteu o baralho para fita os levou junto. São a prova de que o arquivo é imagem de um baralho.

O mapa do dano por posição no arquivo confirma a origem física: o dano não está espalhado ao acaso, está em trechos.

| linhas | UF | suspeitas | cópias removidas | famílias sem registro |
|---|---|---|---|---|
| 180.001–200.000 | PB → PE | 3 | 424 | 0 |
| 200.001–220.000 | PE | 1 | 1.261 | 20 |
| 220.001–240.000 | PE | 4 | 1.048 | 0 |
| 300.001–320.000 | BA | 0 | 2 | 15 |
| 620.001–640.000 | GB | 2 | 4 | 34 |
| 640.001–660.000 | GB | 19 | 5 | 0 |
| 760.001–780.000 | SP | 11 | 0 | 1 |
| 820.001–840.000 | SP | 7 | 4 | 13 |
| 920.001–940.000 | SC | 1 | 0 | 10 |
| 1.000.001–1.020.000 | RS | 10 | 0 | 1 |

(Faixas de 20.000 linhas com dano relevante; as demais têm de zero a cinco ocorrências cada.)

**O método.** O que está implementado segue as regras dos projetos de resgate de microdados históricos: preservar o bruto; detectar por regra mecânica e explícita; decidir caso a caso num registro escrito e reproduzível; nunca alterar em silêncio, sempre com marca; reconstruir só a partir do conteúdo do próprio registro ou de invariantes estruturais, como a chave do questionário; e validar contra uma fonte externa produzida antes do dano. A regra de fidelidade é esta: imputação determinística — a que não tem alternativa — é permitida e sempre marcada; imputação por suposição não é feita.

## 4. Os quatro tipos de dano e como se veem

O passo 3 procura quatro sinais, cada um com um detector simples:

1. **Valor fora do dicionário.** Um caractere que não é código válido da variável naquela posição — um `"` onde só cabe dígito, um 7 onde só cabem 1 a 5. Detector: cada variável de cada guia de leitura, contra a lista de valores válidos.
2. **Caractere estranho.** Qualquer coisa que não seja dígito, branco, hífen ou barra invertida.
3. **Espaço no meio dos dígitos.** Um ou mais brancos entre dígitos, onde o layout não prevê branco — sinal de caractere perdido ou de linha deslocada.
4. **Estrutura quebrada.** Hífen fora das cinco posições permitidas, ou barra invertida fora da posição 55 — a linha inteira está deslocada.

Os detectores apontam 124 linhas (uma linha pode acionar mais de um): 99 com valor fora do dicionário, 43 com caractere estranho, 60 com espaço entre dígitos e 19 com estrutura quebrada. A lista sai em `data_raw/microdata/1960/amostra_127/linhas_problematicas.csv`.

Cada uma dessas 124 linhas tem uma decisão registrada em `read_guides/1960_amostra_127_correcoes.csv`, com o texto original, o texto corrigido (quando há) e a explicação. O pipeline para se alguma linha suspeita não tem decisão, se alguma decisão aponta linha que não é suspeita, ou se o texto original de uma decisão não é o que está no arquivo — assim a lista de correções nunca fica dessincronizada do arquivo.

## 5. Passo a passo

### Passo 1 — download

Baixa `HHOLDA.txt` para `data_raw/microdata/1960/amostra_127/` e confere os 68.756.992 bytes.

### Passo 2 — leitura

Lê o arquivo como texto, uma linha por registro, e para se alguma linha não tem 62 caracteres. Ao lado do texto ficam colunas de navegação — número da linha, tipo de registro, UF, município, as três partes da chave e o número a posteriori — que servem apenas para localizar cada linha nos passos seguintes.

### Passo 3 — detecção

Roda os quatro detectores da seção 4 e escreve `linhas_problematicas.csv`.

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

### Passo 6 — os cartões copiados de Pernambuco

**O problema.** Em três municípios de Pernambuco (2135, 2113 e 2115) o arquivo repete linhas de pessoa: a mesma pessoa, com a mesma chave de questionário e os mesmos 54 caracteres de dado, aparece duas vezes na mesma família. Sem tratamento Pernambuco fica com 5% de gente a mais e famílias de 7,9 pessoas onde as vizinhas têm 5,1.

**Como aparece.** A família 29839 lista as pessoas A, B, C, D, E e, logo depois, C, B, A, E, D. As linhas marcadas com `*` são as que o passo remove:

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

**Por que são cópias e não pessoas.** Duas famílias podem se parecer, mas não é disso que se trata: a comparação é dentro do mesmo questionário. Dentro de uma família, duas linhas idênticas só podem ser gêmeos de mesmo perfil ou uma cópia, e cinco fatos separam os dois casos:

1. 497 das repetidas são cônjuges, e uma família não tem duas esposas idênticas.
2. A taxa de linhas idênticas é 0,95 por mil pessoas no país inteiro, nunca acima de 1,6 por mil em nenhuma UF, e 51 por mil nos três municípios. Gêmeos não são cinquenta vezes mais comuns num município que no vizinho.
3. As repetidas formam um bloco contíguo colado ao fim da família em 97% das famílias atingidas, depois de todos os originais em 99%, e em 74% delas o bloco é exatamente todos os cartões da família menos o do chefe, em ordem embaralhada. Isso é um lote de cartões reproduzido e anexado.
4. As famílias atingidas têm 7,9 pessoas e, sem as repetidas, 4,6, igual às vizinhas.
5. A tabulação oficial de 1965, feita com estes cartões antes do dano, só reproduz o Nordeste sem as cópias: o fator de expansão implícito fica em 79,5, como no Leste (79,2) e no Sul (79,4), e não em 78,4.

**O que o código faz.** Uma linha é repetida quando tem a mesma chave e os mesmos dados de uma linha anterior da mesma família. Ela é removida quando: é chefe ou cônjuge; ou a família tem duas ou mais repetidas (o bloco copiado; dois pares de gêmeos idênticos numa só família não acontecem); ou é uma repetida avulsa na cauda da família, depois de todos os originais, num dos três municípios danificados — ali as avulsas são quatro vezes mais frequentes que no resto do país (4,2 contra 0,95 por mil) e 45 das 49 estão na cauda, onde as cópias ficam. Uma repetida fora dessas condições — uma só, de filho ou parente, em família sem outra repetição, fora dos três municípios — é gêmeo ou irmão de mesmo perfil e fica, marcada em `censobr_duplicata_mantida`.

**Como fica.** 2.850 linhas removidas: 497 cônjuges repetidos, 2.308 em blocos e 45 avulsas na cauda nos três municípios; 2.778 delas em Pernambuco. A lista, com o motivo de cada uma, está em `duplicatas_removidas.csv`. Ficam 846 repetidas marcadas, quase todas filhos pequenos. A população presente de Pernambuco cai para 4,13 milhões, e o total oficial de 1960 é 4,14 milhões.

### Passo 7 — famílias e domicílios

**A família.** Cada pessoa é ligada ao registro de família que tem a mesma UF e a mesma chave de questionário. É assim que o formulário de 1960 funcionava: um boletim por família, com a página do domicílio na frente e as pessoas atrás. Em 99,2% das linhas isso coincide com o número a posteriori; nas demais a chave corrige o número — é por aqui que as linhas realocadas e recuperadas do passo 4 chegam à família certa.

**Pessoas cujo questionário não tem registro de família.** São 2.678 pessoas em 586 grupos (um grupo = uma chave). O número a posteriori não ajuda a decidir o que são: ele foi atribuído contando registros de família na ordem do arquivo, e 585 dos 586 grupos carregam o número da família imediatamente anterior. Sobra o que está nas próprias linhas:

- **O grupo tem chefe ou cônjuge** (150 grupos, 485 pessoas): é uma família cujo registro de família — e quase sempre o chefe, que era a linha seguinte — se perdeu na fita. O grupo vira família nova, sem página de domicílio (V101 a V113 ficam NA), marcada `registro_perdido`, e ocupa linha própria na tabela de domicílios. No exemplo abaixo a família 2586 tem um chefe de 29 anos sozinho no boletim 075; o boletim 076 traz uma mulher de 60 anos codificada como cônjuge e seis filhos de 4 a 26 anos — não é a mesma família:

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

  A hipótese de anexar à família anterior os 42 cônjuges que aparecem sozinhos foi testada e descartada. Nos casais do arquivo o ano de casamento é o mesmo nos dois em 99,3% das vezes (138.075 de 139.020); nos 24 casos em que a família anterior não tem cônjuge, o ano nunca coincide — em 13 o chefe anterior declara outro casamento, em 7 é solteiro ou viúvo, em 4 é mulher. São famílias diferentes, com os cartões de família e de chefe perdidos.

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

**Rondônia.** 64 famílias (253 pessoas) estão gravadas com UF 03 (Roraima) e município 0011, que é Porto Velho. Quatro sinais independentes dizem que são de Rondônia: a pasta delas é 0100/01, a mesma das 76 famílias de Rondônia e o único valor de pasta que aparece em duas UFs em todo o arquivo; a naturalidade das pessoas é Guaporé e Amazonas, como nas famílias de Rondônia; estão nas linhas 15315 a 15631, imediatamente antes do Roraima verdadeiro (município 0310, linhas 15632 a 16090); e 0011 não é município de Roraima. Voltam para Rondônia (UF 00), marcadas em `censobr_uf_corrigida`. Abaixo, dois registros de família de Rondônia, três dos gravados como Roraima e dois do Roraima verdadeiro:

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
- **Imputações determinísticas**, duas, sempre marcadas: nacionalidade (V208) em branco em 19 registros íntegros de pessoas nascidas em UFs brasileiras (V207 de 01 a 29) vira 9, brasileiro nato, com `censobr_v208_imputada`; e as 3 pessoas das linhas corrompidas, que perderam UF, município e chave, recebem os da família a que estão presas pela posição no arquivo. Nada mais é preenchido.
- **Página de domicílio nas pessoas.** Cada pessoa leva V101 a V113 do seu próprio registro de família, como no original. Nas 373 famílias secundárias (V101 = 4 ou 5; 1.367 pessoas) essa página está em branco no arquivo e fica em branco aqui; o dicionário do `censobr` deve avisar, e a decisão sobre preencher as variáveis físicas do domicílio será discutida em issue no `ipea/censobr` (rascunho em `references/issue_familias_secundarias_1960_1970.md`).
- **Códigos.** Filhos tidos e vivos (V217, V218) só têm códigos até 30, mais 99 = ignorado; 26 valores de V217 e 2 de V218 entre 31 e 98 viram NA, marcados em `censobr_v217_fora_da_faixa` e `censobr_v218_fora_da_faixa`. O número da idade, que a sintaxe original chamava AGE, fica em V204B; V204 diz se ele está em meses (0), anos (1), acima de 99 anos (5) ou é ignorado (9).
- **Coerência entre parentes.** Três marcas, sem nenhuma correção: cônjuge do mesmo sexo do chefe (459 pessoas), filho mais velho que o chefe (130) e casamento antes dos 10 anos de idade, tomando V216 de 01 a 60 como 1901 a 1960 (1.774). Sobre esta última, ver a seção 10.
- **Tipos.** UF, o número a posteriori e todas as V viram inteiros.

### Passo 9 — pesos calibrados a 1965

Ver a seção 7. Cada domicílio recebe um peso único, o mesmo para todas as suas pessoas, tal que as somas reproduzem as 176 células do quadro 1 de 1965. O peso de desenho (78,74) fica em `censobr_weight_desenho` e o fator de calibração em `censobr_weight_fator`.

## 6. O que sai

Duas tabelas em `data_raw/microdata/1960/amostra_127/`, intermediárias — a compilação com a amostra de 25% é que produzirá os parquets do `censobr`:

| arquivo | linhas | colunas | tamanho |
|---|---|---|---|
| `pessoas_1960_amostra_127.parquet` | 897.009 | 68 | 47 MB |
| `domicilios_1960_amostra_127.parquet` | 174.245 | 36 | 7 MB |

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
| `censobr_v208_imputada`, `censobr_v217_fora_da_faixa`, `censobr_v218_fora_da_faixa`, `censobr_flag_*` | imputação, códigos anulados e marcas de coerência do passo 8 |
| `censobr_weight`, `censobr_weight_fator`, `censobr_weight_desenho` | peso calibrado, fator de calibração e peso de desenho (passo 9) |

## 7. O desenho da amostra e o gabarito de 1965

**O desenho** (Volume II, pp. 5–6). A amostra é bi-etápica. A primeira etapa é a amostra geral do censo: 25% dos domicílios, uma em cada quatro linhas da folha de coleta, mais 25% dos moradores de domicílios coletivos. Os boletins dessa amostra foram reunidos em pastas, lotes de trabalho de cerca de 250 questionários na ordem dos setores. A segunda etapa sorteou pastas inteiras, uma em vinte, sistematicamente e com início aleatório, dentro de estratos definidos por geografia e por situação (cidades de 100 mil habitantes ou mais; aglomerados urbanos menores; rurais; mistas). Foram 814 pastas, e o arquivo tem todas. O resultado é aproximadamente 1,27% da população e dos domicílios particulares. O volume promete "uma publicação especial" com o desenho detalhado e os erros de amostragem; ela não foi localizada na biblioteca do IBGE nem na web, e possivelmente nunca saiu.

**Consequências.** O peso de desenho é o inverso da fração, 78,74. Mas a seleção por estratos e a estimativa de razão que o IBGE usava dão fatores ligeiramente diferentes por estrato, e a comparação com as tabelas publicadas revela quais: dividindo a população presente publicada pela nossa contagem, o fator implícito é 79,2 no Leste, 79,4 no Sul e 79,5 no Nordeste — com o urbano em 80,0 e o rural em 78,6. Quase uniforme, com o urbano um pouco acima do rural.

**A transcrição.** Os quadros 1 (população presente por região, situação, sexo e onze faixas de idade) e 6 (domicílios particulares ocupados e pessoas residentes, por condição de ocupação e faixa de aluguel) foram lidos por OCR (Tesseract a 300 dpi e a camada de texto do PDF), transcritos e conferidos por aritmética: em cada linha, total = homens + mulheres = urbana + rural; em cada coluna, a soma das faixas = totais; alugados = soma das faixas de aluguel; totais = próprios + alugados + outra condição + sem declaração. As 870 células passam em todas as conferências; sete células ilegíveis foram resolvidas pelas restrições e estão marcadas na coluna `nota` do CSV. Norte e Centro-Oeste não têm quadros próprios: saem do Brasil menos as três regiões.

**A calibração** (passo 9). Cada domicílio recebe um peso único, calibrado pelo método de Deville e Särndal com distância "raking": peso de desenho vezes exp(x'λ), onde x conta quantas pessoas presentes o domicílio tem em cada uma das 176 células do quadro 1 (4 regiões × 2 situações × 2 sexos × 11 faixas) e λ é resolvido por Newton em poucas iterações. As 176 células são reproduzidas exatamente. O fator de calibração (`censobr_weight_fator`) fica entre 0,47 e 4,62, com mediana 1,001; por UF a mediana vai de 0,970 (Roraima) a 1,061 (Distrito Federal), e nas UFs do Nordeste, Leste e Sul fica entre 0,995 e 1,011. O fator é também um diagnóstico: afasta-se de 1 onde faltam ou sobram cartões.

**A validação pelo quadro 6.** Os domicílios particulares ocupados e as pessoas residentes, com os pesos calibrados, ficam acima do publicado em 1965: de 0,2% (Nordeste rural) a 3,9% (Leste urbano) nos domicílios, e de −2,3% (Norte e Centro-Oeste rural) a 3,8% (Leste urbano) nos residentes. Nenhuma definição de domicílio testada (com ou sem as famílias sem registro, só V101 = 1 ou 2, só com página preenchida, só com residente) muda isso: as tabulações de domicílio de 1965 partem de um universo 1,6% a 3% menor que o das pessoas presentes, mais no urbano do Leste e do Sul, por razão ainda desconhecida. Fica registrado em `data_raw/microdata/1960/amostra_127/calibracao_1965_quadro6.csv`, e é uma das perguntas para os materiais adicionais de 1960.

**Cobertura parcial.** Rondônia só tem Porto Velho (138 domicílios urbanos e 2 rurais); o Amapá tem um município, o Acre dois, Fernando de Noronha só urbano, o Distrito Federal só duas situações. Nenhum peso cria o que não foi amostrado: a calibração reproduz os totais regionais, e a estimativa para essas UFs isoladas descreve só o que foi sorteado.

## 8. Números por UF

| UF | sigla | domicilios | familias | pessoas | pessoas_por_domicilio | fator_de_calibracao | populacao_presente_calibrada |
|---|---|---|---|---|---|---|---|
| 0 | RO | 140 | 140 | 675 | 4,82 | 0,991 | 51.306 |
| 1 | AC | 476 | 476 | 2.929 | 6,15 | 0,977 | 221.417 |
| 2 | AM | 1.625 | 1.640 | 9.771 | 6,01 | 0,973 | 737.312 |
| 3 | RR | 58 | 58 | 401 | 6,91 | 0,970 | 28.990 |
| 4 | PA | 3.561 | 3.575 | 20.450 | 5,74 | 0,975 | 1.569.221 |
| 6 | AP | 210 | 210 | 1.354 | 6,45 | 0,971 | 102.098 |
| 10 | MA | 5.896 | 5.902 | 31.155 | 5,28 | 1,005 | 2.447.217 |
| 12 | PI | 2.809 | 2.816 | 16.328 | 5,81 | 1,005 | 1.274.553 |
| 14 | CE | 7.347 | 7.349 | 41.204 | 5,61 | 1,005 | 3.240.539 |
| 17 | RN | 2.778 | 2.779 | 14.639 | 5,27 | 1,005 | 1.145.328 |
| 19 | PB | 4.876 | 4.890 | 25.864 | 5,30 | 1,004 | 2.027.690 |
| 21 | PE | 10.500 | 10.513 | 52.672 | 5,02 | 1,005 | 4.131.738 |
| 24 | FN | 62 | 63 | 293 | 4,73 | 1,006 | 22.710 |
| 25 | AL | 3.093 | 3.093 | 15.707 | 5,08 | 1,004 | 1.234.833 |
| 30 | SE | 2.376 | 2.377 | 11.472 | 4,83 | 0,995 | 894.331 |
| 31 | BA | 15.402 | 15.428 | 79.920 | 5,19 | 0,995 | 6.204.792 |
| 40 | MG | 23.311 | 23.334 | 126.835 | 5,44 | 0,998 | 9.866.314 |
| 50 | Serra dos Aimorés | 872 | 874 | 4.776 | 5,48 | 0,997 | 367.108 |
| 51 | ES | 2.427 | 2.441 | 13.916 | 5,73 | 0,998 | 1.083.883 |
| 52 | RJ | 8.408 | 8.420 | 41.758 | 4,97 | 1,001 | 3.289.974 |
| 54 | GB | 8.766 | 8.807 | 37.128 | 4,24 | 1,011 | 2.952.831 |
| 60 | SP | 34.389 | 34.492 | 164.181 | 4,77 | 1,005 | 12.917.981 |
| 71 | PR | 10.074 | 10.082 | 52.540 | 5,22 | 0,999 | 4.110.768 |
| 74 | SC | 5.054 | 5.061 | 27.934 | 5,53 | 0,999 | 2.186.038 |
| 81 | RS | 13.145 | 13.181 | 66.787 | 5,08 | 1,002 | 5.231.352 |
| 91 | MT | 1.828 | 1.831 | 10.380 | 5,68 | 0,975 | 801.201 |
| 94 | GO | 4.625 | 4.647 | 25.362 | 5,48 | 0,976 | 1.932.488 |
| 97 | DF | 137 | 137 | 578 | 4,22 | 1,061 | 45.294 |

Total: 174.245 domicílios, 174.616 famílias, 897.009 pessoas.


## 9. Decisões tomadas

Todas apresentadas ao usuário com a evidência e decididas em 2026-09-14:

- **Página de domicílio das famílias secundárias:** não preencher; documentar no dicionário do `censobr` e discutir em issue com os mantenedores. O mesmo vale para 1970.
- **Cópias de Pernambuco:** remover pelo mecanismo (bloco copiado, cônjuge repetido, avulsa na cauda nos três municípios), marcar o resto.
- **Famílias sem registro:** famílias e domicílios próprios, marcadas; a hipótese de anexar cônjuges sozinhos foi testada e descartada; a amostra de 25% pode confirmar pelas mesmas chaves de questionário.
- **Imputações determinísticas:** nacionalidade e localização das linhas corrompidas, marcadas.
- **Pesos:** calibrados aos totais de 1965, e não apenas o peso de desenho.

## 10. Em aberto

- **V216 (ano do casamento) e a marca de casamento impossível.** O dicionário de 2018 lê 00 como "não tem", 01 a 60 como 1901 a 1960 e 61 a 99 como 1861 a 1899. O código 63, com 5.690 pessoas de todas as idades, casadas ou viúvas, não pode ser 1863. Das 1.774 pessoas marcadas, 1.367 são cônjuges e 1.315 têm o mesmo ano do chefe (nos casais o ano coincide em 99,3%); em 837 desses casais o ano é plausível para o chefe e impossível para a esposa. É inconsistência de origem, não dano de fita. Aguarda os materiais de 1960 que o usuário vai trazer (o boletim e as instruções ao recenseador já estão localizados).
- **O universo dos quadros 5, 6 e 7 de 1965** (seção 7).
- **As 49 repetições avulsas dos três municípios** e as 150 famílias sem registro: confirmação pela amostra de 25%.
- **Os quadros 2, 3, 4, 5 e 7 de 1965** ainda não foram transcritos; validam alfabetização, ramo de atividade, rendimento, estado conjugal e instalações do domicílio.

## 11. Como auditar

- `linhas_problematicas.csv`, `duplicatas_removidas.csv` e `calibracao_1965_quadro6.csv`, em `data_raw/microdata/1960/amostra_127/`, listam tudo que foi apontado, removido e comparado.
- `read_guides/1960_amostra_127_correcoes.csv` tem cada correção com o texto antes e depois; `references/censo_1960_resultados_preliminares_1965.csv` tem o gabarito.
- Cada passo é um alvo do `targets`: `targets::tar_read(linhas_1960_amostra_127)`, `problemas_...`, `linhas_corrigidas_...`, `tabelas_brutas_...`, `tabelas_dedup_...`, `familias_...`, `tabelas_...`, `tabelas_calibradas_...` e `output_...`. Qualquer passo pode ser aberto e conferido sem rodar os outros.
