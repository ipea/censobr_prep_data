# Censo 1960, amostra de 1,27%: o que o repositório `ConsistenciaCenso1960Br` faz, o que reproduz e o que precisa mudar

**Data:** 2026-09-14 (segundo exame; substitui a versão do mesmo dia)
**Status:** este documento é o **diagnóstico**. A implementação está em
`microdata_1960_amostra_127_preparacao.md` e em `R/microdata_1960_amostra_127.R`,
e em alguns pontos ela foi além do que este exame propunha, porque em seguida
entraram duas fontes novas: o Volume II dos *Resultados Preliminares* de 1965,
que é uma tabulação destes mesmos cartões feita antes do dano, e o Boletim de
Amostra CD 2 com as *Instruções ao Recenseador*. Onde os dois documentos
divergirem, vale o de preparação; as divergências estão assinaladas abaixo
como **[revisto]**.
**Escopo:** exame do repositório `antrologos/ConsistenciaCenso1960Br` (2018), que produz a versão consistida da amostra de 1,27% do Censo de 1960 usada como insumo do `censobr` para as 11 UFs sem amostra de 25% (RO, AC, AM, RR, PA, AP, MA, PI, ES, GB, SC). Dois exames no mesmo dia: o primeiro, feito à mão; o segundo, com cinco lentes independentes (layout, diagnósticos manuais, banco de pessoas, estrutura de domicílios, ponte com o censobr), cada uma remedida por um verificador com a instrução de refutá-la. Onde o segundo exame corrigiu o primeiro, vale o segundo. Todos os números vêm de medições sobre `Original Files/HHOLDA.txt`, sobre os arquivos auxiliares, sobre a reprodução integral do `README.Rmd` e sobre os parquets `amostraCompilada` do `release_legacy`. Scripts em `D:/tmp/c1960/_review/`.

---

## O insumo

`HHOLDA.txt`: 1.074.328 linhas de exatamente 62 caracteres, formato fixo,
hierárquico — 174.467 registros de família (caractere 17 = 1), 174.472 de
chefe (= 2) e 725.389 de outros moradores (= 3); 899.861 pessoas. Nas
posições 55–62 há um identificador `\NNNNNNN` acrescentado depois da
gravação, que muda exatamente quando o registro é de família.

O layout adotado é o das sintaxes SPSS/SAS que acompanhavam o arquivo; o
`dicionario_60_last.doc` descreve o layout da amostra de 25%, com as mesmas
categorias.

## O que o repositório faz

1. Lê o arquivo como texto, troca todo hífen por espaço e separa famílias de
   pessoas pelo caractere 17.
2. Aplica o layout (`Auxiliary Files/Census1960_input_Sample_1.27.xlsx`) e
   testa cada valor contra a lista de códigos válidos.
3. Detecta três tipos de problema: valor fora do dicionário; caractere que
   não é dígito, espaço ou barra (43 linhas); 1 a 3 espaços entre dígitos
   (61 linhas).
4. Diagnostica à mão as 29 linhas de família e 93 de pessoa marcadas
   (`check_line_by_line.xlsx`): 103 "ok" (valores isolados inválidos viram
   NA, `cem_diagnosis = 2`), 10 registros inteiramente corrompidos (zerados,
   `= 4`) e 9 recuperáveis por remoção de espaços e recomposição (`= 1`).
5. Constrói o domicílio por `V101` (1 único, 2 principal, 3 coletivo abrem
   domicílio; 4 e 5 herdam o ID anterior), copia UF, `V116` e `V118` entre
   pessoa e domicílio, marca as discordâncias que restam (299 pessoas), e
   recria o banco de domicílios pelo máximo das variáveis das pessoas.
6. Atribui peso uniforme `cem_wgt = 1/0,0127` e grava: pessoas
   899.861 × 58, domicílios 174.094 × 26.

## Reprodução

O `README.Rmd` roda do começo ao fim em 1,6 min (código extraído com
`knitr::purl`; só o `setwd` e os `source()` remotos precisaram ser
apontados para os arquivos locais). Os CSVs produzidos são **idênticos aos
publicados**: mesmas dimensões, mesmas colunas, zero células diferentes. O
que se descreve abaixo, portanto, está no produto publicado.

## Defeitos do dado que o procedimento não trata

### D1. Pernambuco tem 2.815 linhas de pessoa duplicadas (5,08% da UF) — e os 856 IDs pulados são o rastro delas

**[revisto]** A preparação remove 2.850 linhas, não 2.815, e por um critério
que segue a forma do defeito em vez de contar linhas iguais: sai a repetida
que é chefe ou cônjuge, a que está em família com duas ou mais repetidas (o
bloco copiado) e a avulsa na cauda da família nos três municípios
danificados. Ficam 846 repetidas marcadas. A prova de que são cópias ganhou
um argumento externo: a tabulação de 1965, feita antes do dano, só reproduz o
Nordeste sem elas — fator de expansão 79,5 como nas outras regiões, contra
78,4 com elas. Ver o passo 6 do documento de preparação.

Linha idêntica (posições 1–54) a outra linha da mesma família, nunca
adjacente, em ordem embaralhada (família 29839: A, B, C, D, E e depois C, B,
A, E, D): 3.694 no país, 2.815 em PE; nas outras 26 UFs, no máximo 1,64 por
mil (compatível com gêmeos e irmãos de mesmo perfil). Todas são registros
tipo 3 — nenhum registro de família ou de chefe se repete — e 497 são
cônjuges duplicados, o que não existe legitimamente. Em PE, 2.782 das 2.815
estão em três municípios (`V116` 2135, 2113 e 2115: 2.345, 348 e 89 linhas),
exatamente os três municípios de PE que têm IDs pulados (653 + 147 + 28 =
828 dos 856). As famílias de PE seguidas de ID pulado têm 7,94 pessoas
brutas e 4,64 sem as duplicatas; as demais famílias de PE, 5,06 e 5,05. Em
817 delas o salto ocorre antes e depois, em 12 trechos de até 186 famílias.
Nas 828 fronteiras com salto o questionário seguinte é o +1 em 817 casos —
igual às fronteiras normais —, ou seja, nenhum questionário sorteado falta:
o ID a posteriori pulava onde havia lixo, e o lixo que sobrou são as cópias.
Sem as duplicatas a população implícita de PE cai de 4,37 para 4,14 milhões
(oficial 4,14). Fora de PE, 8 dos 23 saltos coincidem com dano local
(registro corrompido, dois chefes, duplicatas).

Não atinge o produto do `censobr`: PE vem da amostra de 25%. Atinge quem usa
o CSV da amostra de 1,27% para o país inteiro.

### D2. Três "registros corrompidos" são pessoas legíveis de outras famílias, deslocadas no arquivo; dois são cartões de cabeçalho de UF

- Linha 194609 (`\212135072103211531 291 08542092000052-`): tirando os 4
  caracteres iniciais e 2 espaços, é uma filha de 8 anos do questionário
  0721032115 — a família ID 32581, 15.594 linhas adiante. Linhas 388894 e
  388895 pertencem ao questionário 0121536245 (ID 30823). Hoje as três estão
  no produto como pessoas toda-NA na família e na UF erradas (IDs 29831 e
  62104).
- Linha 951430 é o registro de família do questionário 0181076017 (ID
  158808, que tem 3 pessoas e nenhum registro de família); 951431 é uma
  pessoa do 6016; 293556 (`31 1 807316080…`, marcada "ok" e dissonante) é do
  questionário 0731608050, família ID 48357, 10.578 linhas adiante.
- Linhas 293555 (`31   M   1BA33HIA`) e 611249 (`54   M   4GU35ANABARA`) são
  cartões de cabeçalho de UF (Bahia, Guanabara) que sobreviveram na fita —
  estão nas transições 30→31 e 52→54 —, não pessoas. No produto contam como
  moradores (toda-NA) das famílias 46690 e 97157.
- Irrecuperáveis de fato: 855822, 951432, 951433.

### D3. Duas linhas deslocadas em um caractere escapam aos três detectores

Os 611.196 hífens do arquivo caem em cinco posições (47: 335.282; 33:
143.995; 36: 130.647; 20: 1.209; 21: 49) — o primeiro caractere de um campo,
seguido de brancos: é a marca de "não se aplica daqui em diante" (`V221`
depois de `V220`; `V211` depois de `V210`; `V214` depois de `V213`; `V102`
depois de coletivo; `V103` depois de improvisado). Só 14 hífens estão fora
dessas posições, em 12 linhas; 10 delas estão entre as 122 diagnosticadas e
2 não: 387715 e 387853 (BA, `V116` 3399), com hífen em 46 e barra em 55 — um
dígito perdido entre 38 e 44 puxou `V219`/`V220` uma casa para a esquerda.
Tudo passa no dicionário porque branco é válido de 46 a 54, e as duas entram
no produto com valores errados e `cem_diagnosis = 3`. Um detector estrutural
— hífen só em {20, 21, 33, 36, 47} e barra só em 55 — pega essas duas, as 9
receitas e 5 das corrompidas. A linha 830335, marcada "ok", tem a assinatura
das receitas (barra ausente, 55 caracteres de dado, hífen em 48) e ficou sem
reparo: como o README exclui `test_barra` da lista de variáveis
problemáticas, a perda de `V220` é silenciosa.

### D4. Famílias sem registro de família e sem chefe, além dos 5 casos visíveis

Os caracteres 7–16, que o relatório declara indecifráveis, são a
identificação do questionário: pela ordem das variáveis do SAS e pelas
larguras do dicionário da amostra de 25%, **distrito (7–8), pasta (9–13) e
boletim (14–16)** — 7–8 tem 54 valores (97% ímpares; 1 a 33 por município),
(UF, 9–13) tem 817 valores, cada um dentro de um município, com mediana de
203 famílias, e 14–16 é o número do questionário, único dentro da pasta. A
chave é igual entre o registro de família e suas pessoas em 173.029 dos
174.467 IDs (99,2%). (O primeiro exame cortou em 7–10 / 11–12 / 13–16; esse
corte não é aninhado — (UF, 7–10) abrange até 22 municípios — e fica
substituído.)

Com a chave:

- Dos 5 IDs com dois chefes, 3 são famílias cujo registro de família se
  perdeu (29831, 32581, 136463 — o segundo chefe tem outro questionário); em
  54150 e 137492 os dois chefes têm o mesmo questionário: dupla codificação,
  não família perdida. (O primeiro exame generalizou os cinco.)
- Outras 1.670 pessoas, em 435 IDs, têm questionário diferente do da
  família e nenhum chefe. Não é corrupção de dígitos (o número da pessoa fica
  estritamente entre o da família e o da família seguinte em 1.534 de
  1.537) nem "folha de continuação" (o bloco anterior tem de 0 a 14 pessoas,
  85 vezes só o chefe; e o número K+1 nunca é registro de família). São
  dois perfis: **restos de famílias cujo registro de família e chefe se
  perderam** — 166 grupos têm cônjuge, e em 91 o ID já tinha um (família
  32404, PE: cônjuges de 36, 42 e 37 anos em quatro questionários) — e
  **listas de hóspedes e empregados não moradores** (`V203` = 4 em 42,4% da
  cauda contra 3,3% dos não-chefes; `V202` 5/6 em 40,8% contra 0,9%; ID
  2326: chefe de 50 anos sozinho mais 26 hóspedes não moradores em dois
  questionários). Hoje todos são membros da família anterior, e
  `cem_num_moradores` dessas famílias é 8,18 contra 5,17.

### D5. Rondônia: só Porto Velho urbano, e 64 famílias gravadas como Roraima

RO (`uf` 00) tem 76 famílias e 422 pessoas, todas urbanas, de um único
município (`V116` 0011). Outras 64 famílias (253 pessoas), gravadas com
`uf` 03 e `V116` 0011, são de Rondônia: mesma pasta 0100/01 de RO (o único
valor de pasta que aparece em duas UFs em todo o arquivo), naturalidade
Guaporé/Amazonas como em RO, linhas 15315–15631 imediatamente antes do RR
verdadeiro (`uf` 03, `V116` 0310, 58 famílias, linhas 15632–16090). A
compilação do `censobr` já reatribui esses 253 registros a RO (`uf_pess ==
3 & v116_pess == 11 → 0`), o que explica os 140 domicílios de RO no
produto; o repositório de consistência não. E RO continua sem nenhuma pessoa
rural: a pós-estratificação por UF × urbano/rural que a compilação faz
(exata em AC, AM, RR, PA, AP, MA, PI, SC contra a SIDRA t/1288) não tem
linha rural a ponderar em RO, e a soma de pesos de RO fica em 30.842 — a
população urbana — contra 70.783 no total oficial. A diferença, 39.941, é
exatamente o que falta na soma dos pesos da fonte 1 (12.959.822 contra
12.999.763). Cobertura igualmente parcial em AP (1 município), AC (2), FN
(293 pessoas, só urbanas), DF (só `V118` 1 e 3).

## Defeitos do procedimento

### P1. `v101` no banco de domicílios é 4 ou 5 em todos os 346 domicílios com famílias conviventes

O banco final agrega as pessoas por `max()`: nos 318 domicílios com duas
famílias `v101` sai 4 e nos 28 com três sai 5, em vez de 2 (principal). Só 3
domicílios ficam com 2. A compilação do `censobr` toma o valor do primeiro
morador e não herda o erro (96 domicílios diferem entre os dois, todos por
isso). Correção: agregar pelo registro da família principal (mínimo ou
primeiro).

### P2. `cem_num_pessoas` e `cem_num_moradores` estão com os rótulos trocados no dicionário

No código, `cem_num_moradores = n()` (todas as linhas, inclusive os 6.517
não moradores presentes, `V202` 5/6, e os 9 registros toda-NA) e
`cem_num_pessoas = soma(V203 em 0–3, 7–9)`, que exclui hóspedes, empregados
e ignorados. O dicionário diz o contrário. `pessoas < moradores` em 15.982
domicílios, nunca o inverso; somas 875.853 e 899.861.

### P3. Códigos e rótulos

- `V217`/`V218` (filhos tidos e vivos): todas as fontes param em 30 (mais 99);
  o xlsx acrescenta 31–98 sem fonte e deixa passar 26 registros com 31 a 97
  filhos tidos (homem de 62 anos com 97, RS) e 2 com filhos vivos > 30
  (**[revisto]** o Código do Censo, quesitos R e S, manda registrar o número
  declarado, sem teto; os valores ficam no arquivo preparado, marcados). O
  código 02, ausente da SPSS e do `.doc` e presente no SAS, era indispensável
  (45.323 e 55.686 registros). O 99 é "ignorado" (6.471 e 6.221 pessoas) e
  não está documentado; entra nas médias se não for excluído.
- `V204` (tipo de idade): 5 (144 pessoas, "acima de 99 anos") e 9 (1.473,
  ignorado) são códigos do IBGE, presentes também na amostra de 25%; a
  observação do xlsx os atribui à sintaxe SPSS, que só tem 0 e 1. O
  dicionário diz que `v204b` = 999 quando ignorado; é 99.
- `V210` (lugar de residência anterior): a sintaxe SPSS o lê em uma coluna
  (30–30); o xlsx corrige para duas (31–32), como o SAS e o `.doc` —
  correto; se a SPSS fosse seguida, 254.911 registros (28%) receberiam a
  dezena do código.
- `V216` (ano de casamento): SPSS e `.doc` omitem o 59 e rotulam 58 como 1959;
  o xlsx corrige (13.040 registros salvos) mas mantém "62 = antes de 1964"
  (é antes de 1864, como o dicionário final diz). **[revisto]** O Boletim de
  Amostra (quesito Q) e as *Instruções ao Recenseador* (p. 31) resolvem a
  variável: é o ano do casamento ou do início da união com o cônjuge com quem
  a pessoa vive na data do censo, e 00 é "não vive com cônjuge". **[revisto
  de novo]** O *Código do Censo Demográfico – 1960* (quesito Q, p. 8) dá a
  regra completa: 61 = casados em 1900, 62 = casados antes de 1864, 63 =
  ignorado, e 64 a 99 = 1864 a 1899 — o dicionário final estava certo, salvo
  o 63, que não é ano (5.690 pessoas de todas as idades, casadas e viúvas).
  A marca de casamento impossível segue essa regra. Ela é, quase sempre,
  erro na idade e não no ano: 1.315 dos 1.367 cônjuges marcados têm o mesmo
  ano do chefe, porque é o ano do casal.
- `V214` (curso): 71/72 seguem o SAS (71 Estatística, 72 Artes domésticas)
  contra SPSS e `.doc`; o 89 vem de um documento citado na observação e não
  disponível no repositório — 23 registros.
- `V208` (nacionalidade) em branco em 22 registros, 19 deles bem formados,
  com naturalidade brasileira: viram NA; são imputáveis como 9.
- `V112`/`V113` = 00 (cômodos e dormitórios zerados juntos) em 839
  domicílios particulares: o código existe também na amostra de 25%; é do
  IBGE, não corrupção.

### P4. Diagnósticos manuais: o que não foi visto

- 17 registros de família particulares com branco em `V103`–`V111` sem
  hífen de salto (perda em posição) entram como "ok" e as variáveis perdidas
  não são listadas em `cem_problematic_vars_list_dom` (16 delas ficam com a
  lista vazia).
- Entre as 76 pessoas "ok", 3 têm dois ou mais campos inválidos (405458,
  704089, 780540); em 405458 a idade `" 9"` é 09 recuperável (irmãos ao
  lado).
- As 9 receitas reconstruídas ficam coerentes com a família vizinha;
  830192 continua com `V223B` inválida; o `insert_pos` do xlsx é ignorado
  pelo código; a linha 199617 reparada fica byte a byte igual à 199618.
- Os 9 registros toda-NA (`cem_diagnosis = 4`) contam em
  `cem_num_moradores` e a família 155539 fica com dois filhos de 3 e 6 anos
  sem chefe.

### P5. Coerência intrafamiliar não é testada

Tudo com `cem_diagnosis = 3`: 478 cônjuges com o mesmo sexo do chefe
(0,34%; 236 H–H, 211 M–M); 135 filhos mais velhos que o chefe (pais
codificados como filhos: filho de 95 anos com chefe de 36); 108 pais/sogros
mais novos que o chefe; 217 casados antes de nascer e 1.778 casados com
menos de 10 anos pelo ano de casamento; 55 casados de 12–14 anos. São dados
originais e não devem ser corrigidos, mas merecem flags e uma tabela no
dicionário. Heaping de idade (Whipple 144 no país, 197 em AL, 119 no RS),
excesso de centenários e razão de sexo 99,7 têm o perfil esperado de 1960 e
não indicam defeito de gravação.

### P6. Coletivos e conviventes

Os 836 registros de coletivo (`V101` = 3) trazem sempre exatamente um chefe
e uma composição de família (cônjuge 17,8%, filho 36,9%; mediana 3 pessoas,
máximo 20): na amostra de 1,27% o registro do coletivo é a família do
responsável, não os residentes do estabelecimento — o rótulo do dicionário
sugere o contrário. `V101` = 4 vem sempre depois de um 2 (345/345) e com
questionário consecutivo (345/345); 5 depois de 4 em 27/28; o caso restante
(ID 121705, um 5 depois de 1, registro com só `V101` preenchido) é tratado
pela regra de herança como convivente de um "domicílio único". "Boletim
individual" (`V101` = 9, `V203` = 6) nunca ocorre.

## A passagem para o insumo do `censobr` (compilação, fora do repositório)

Scripts em `censoBR_aux_Dados/1960/microdados da amostra/Criando a amostra
compilada/`. Medido contra `release_legacy`, `censobr_source == 1`
(162.055 pessoas, 30.963 domicílios, 11 UFs):

- Valores das 38 colunas `v*` comuns idênticos pessoa a pessoa; a ordem é a
  do insumo por `cem_idindividuo`; `uf` ← `uf_pess` com os 253 recodes de
  RO; `v116` ← `v116_pess` com 6 recodes manuais que só existem no script.
- Peso: `cem_wgt` uniforme (78,74) é substituído por pós-estratificação UF ×
  urbano/rural às populações oficiais (21 valores distintos), exata onde há
  os dois estratos; RO fica só com o urbano (D5).
- IDs: `censobr_idhousehold`/`idfamily` são ranks de `factor(character)` —
  ordem lexicográfica (1, 10, 100, …), não numérica nem por UF.
- Desenho declarado (`censobr_estrato = uf`, `upa = v116`, `usa =
  idhousehold`) é convenção: RO, RR e AP têm uma única UPA no estrato.
- Perdem-se `uf_dom`, `v116_dom`, `v118_dom`, `cem_wgt` e as três flags
  `cem_dissonant_*` (57 pessoas nas 11 UFs); ficam 100% NA para a fonte 1
  `v001`–`v004`, `v100`, `v117`, `v200`, `v201` e `code_muni_1960`; `min_id`
  é resíduo. As 10 linhas toda-NA e os 2 cartões de UF passam ao insumo.

## O que fazer, por ordem

1. **Reparos no dado** (repositório de consistência): deduplicar `rec = 3`
   por (ID, caracteres 1–54), pelo menos em PE (D1); recuperar 194609,
   388894, 388895, 951430, 951431 e 293556 e reatribuí-las aos seus
   questionários, excluir os dois cartões de UF (D2); detector estrutural de
   hífen/barra e reparo de 387715, 387853 e 830335 (D3); abrir família nova
   dentro do ID quando o questionário muda e há chefe ou cônjuge, e marcar
   as caudas de não moradores (D4); reatribuir a RO os 64 registros de
   `uf` 03/`V116` 0011 (D5).
2. **Procedimento**: `v101` pelo registro principal (P1); rótulos de
   `cem_num_*` e, de preferência, três contagens explícitas — listados,
   residentes (`V202` ≠ 5/6), presentes (P2); `V217`/`V218` limitados a
   0–30 + 99 e 99 documentado como ignorado, `v204b` = 99, rótulo de
   `V216` = 62 (P3); listar as variáveis em branco fora de salto (P4); flags
   de coerência intrafamiliar (P5); rótulo dos coletivos (P6).
   **[revisto]** `V217`/`V218` acima de 30 continuam anulados, mas não por
   serem códigos inválidos: o questionário pede o número de filhos por
   extenso, então qualquer número é resposta possível — o que os desqualifica
   é a implausibilidade (um homem de 62 anos com 97 filhos), e por isso eles
   viram NA com marca própria, no passo 8, em vez de entrarem na lista de
   correções.
2b. **[revisto] Pesos e erro amostral.** O exame tratava o peso como
   pós-estratificação a ser feita na compilação. Com o Volume II de 1965 em
   mãos, a preparação já calibra o peso de cada domicílio às 176 células do
   quadro 1 e às 8 do quadro 2, e publica os erros-padrão pelo desenho real
   da amostra — pastas sorteadas uma em vinte, dentro de estratos de região e
   situação. Isso também corrige o desenho declarado na compilação antiga
   (estrato = UF, unidade primária = município), que não corresponde ao
   sorteio e subestima a variância.

3. **Compilação**: decidir RO — recalibrar ao total (70.783 sobre 675
   pessoas) ou manter 30.842 e avisar que RO cobre só Porto Velho urbano;
   IDs por rank numérico; carregar `cem_iddomicilio`, `cem_idindividuo` e as
   flags de dissonância como colunas de rastreio; dropar `min_id`; documentar
   os recodes de `v116` e a reatribuição RO/RR.
