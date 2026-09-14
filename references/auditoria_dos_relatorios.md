# Fatos corrigidos sobre os dados do IBGE e sobre o produto

**Data:** 2026-09-13
**O que é:** a documentação técnica deste repositório fazia 748 afirmações numéricas sobre os arquivos do IBGE e sobre o produto `censobr`. Cada uma foi refeita contra os dados; 113 estavam erradas. Este documento registra **o que é verdadeiro**, item a item, para ser lido sozinho — sem depender dos textos onde os erros estavam. Cada item diz de que dado se trata, o fato correto com o número, e o que ele muda; entre parênteses, o que se afirmava antes. Os erros que eram só de redação, sem conteúdo de dado, estão listados no fim.

Convenção: **[IBGE]** marca um fato sobre os arquivos que o IBGE distribui; **[produto]** marca um fato sobre os parquets que este pipeline produz ou publicou.

---

## Censo 1970 — microdados da amostra

### Os arquivos corrompidos de Alagoas e Pernambuco (FTP do IBGE)

Dois dos 27 arquivos de texto do FTP, `DAMO70AL.txt` e `Damo70PE.txt`, contêm 1.785 registros deslocados: blocos de caracteres mudam de lugar e o peso, que ocupa as duas últimas posições, deixa de cair onde o layout manda.

- **[IBGE] Como as anomalias se pareiam em Alagoas.** As 46 linhas anômalas formam 23 pares. Um par é uma linha de comprimento errado seguida, adiante, de outra que compensa parte da diferença. A composição é: 17 pares de 94 → 58 caracteres (saldo zero), 1 par de 16 → 136 (saldo zero) e 5 pares de 16 → 58 — estes são curta seguida de curta, deixam −78 caracteres cada e somam exatamente os −390 do arquivo. A linha de 16 caracteres é a **mais curta** (−60), não uma linha alongada; em 6 dos 23 pares o primeiro membro é a curta. (Afirmava-se que cada par era "uma alongada seguida de uma encurtada que restaura o saldo".)
- **[IBGE] Distância entre os membros de cada par:** de 1 a **400** linhas — os 23 intervalos são 1, 6, 7, 27, 27, 27, 28, 28, 28, 28, 32, 50, 53, 150, 237, 290, 290, 290, 290, 290, 290, 290 e 400. (Afirmava-se "de 1 a 440".)
- **[IBGE] Bytes de controle em Pernambuco.** `Damo70PE.txt` tem **13** bytes de controle fora de CR/LF, excluído o `0x1A` de fim de arquivo: 1 NUL, 2 BS, 4 TAB, 4 VT, 1 CAN e 1 ESC. (Afirmava-se 9, "1 NUL e 4 TAB" — soma que nem fechava.)
- **[IBGE] Frequência de fim de linha em posição inesperada.** A expectativa teórica de um byte CR ou LF cair em posição qualquer é 2 × 76 / 4096 = 3,7109%; a medida é 3,7591% em AL, 3,7585% em PE e 3,7597% nos 27 arquivos. Nas linhas anômalas a taxa é 37,0% em AL (17 de 46) e 23,4% em PE (407 de 1.739) — enriquecimento de 9,8× e 6,2×. (Afirmava-se que 3,71% era medida, e 10× / 6,3×.)
- **[IBGE] Contagens.** Dos 1.785 registros deslocados, 211 são fragmentários (comprimento < 54) e **1.574** não são (40 em AL, 1.534 em PE). Desses 1.574, o peso foi recuperado dos dois últimos caracteres em 1.568; em 6 a cauda também é ilegível. Não existe a contagem "1.573" que aparecia em dois documentos.
- **[IBGE] Os pesos recuperados** reproduzem a distribuição real: moda 4 com **882** casos (35 em AL, 847 em PE), depois 3 com 535 e 5 com 99.
- **[produto] Leitores de arquivo e o que cada um faz com esses registros.** `readr::read_lines` **trunca** a linha de 58 caracteres no NUL, devolvendo 20 caracteres — os outros 37 somem e a contagem de linhas não muda (PE: 1.381.977 linhas, AL: 412.171, iguais à contagem por bytes). `readr::read_fwf` **inventa** um registro: parte a linha 108.812 de PE em 20 + 37 caracteres e devolve 1.381.979. Por isso a contagem confiável é a contagem de bytes. (Afirmava-se que `read_lines` "ganhava uma linha" em PE.)
- **[IBGE] Os 650 pesos falsos da leitura por posição fixa não são invisíveis.** Lidos na posição errada, 650 registros recebem um peso numérico sem sinal de erro individual — mas só 185 deles (28,5%) caem na faixa de pesos comuns (1 a 13, os únicos com mil ou mais casos no país). Os outros 465 (71,5%) assumem valores raros ou inexistentes: o peso 27 aparece 192 vezes contra 32 ocorrências reais em todo o Brasil; 19 aparece 116 vezes contra 143 reais; 59, 26 vezes contra 2; 49 e 99 aparecem 5 e 2 vezes e não existem na amostra. Há sinal distribucional forte. (Afirmava-se "plausíveis, sem nenhum sinal de erro".)

### O FTP comparado à versão preparada pelo CEM

- **[IBGE] Byte de fim de arquivo.** 25 dos 27 arquivos terminam com o `0x1A` do DOS; `Damo70PI.TXT` e `Damo70SP.txt` terminam em CRLF. (Afirmava-se 27.)
- **[produto] Totais da rota FTP, byte a byte:** 24.793.359 pessoas — **um** a mais que as 24.793.358 do produto, não paridade exata; 4.737.679 domicílios (+272); soma dos pesos domiciliares 17.685.043 (+2.931, 0,017%). Pernambuco: 1.382.319 pessoas (1.381.977 do arquivo de PE mais 342 de Fernando de Noronha), 4 a menos que o produto; em domicílios, PE +298 e AL −26. Na leitura por posição fixa, 1.113 pessoas ficam sem peso. (Os números anteriores — 24.793.360, +275, −3, +301, 17.685.053, 1.114 — traziam o registro inventado pelo `read_fwf`.)
- **[produto] Registros sem município resolvido na rota FTP:** 158 (0,00064%), dos quais **117 têm `V001` e `V002` perfeitamente legíveis** (chaves como 1421122, 1426222, 1427722) e só não têm entrada no `crosswalk_munic_1970_to_2010.rda` — insumo nosso, não do IBGE. Apenas 41 têm os campos de fato ilegíveis. (Afirmava-se 156, todos "corrompidos".)
- **[produto] Blocos do `iddomicilio` do CEM sem fronteira de domicílio:** 8.037 dos 8.038 têm o mesmo perfil; o bloco 102432 (9 pessoas) tem chefe, `V006 = 3` e `V005 = 2` nas duas últimas linhas.
- **[produto] Os 736 domicílios de família única cujo tamanho excede o `V005` do chefe** (0,07% de 1.075.550) são fronteiras perdidas, não famílias secundárias — o conjunto já exclui `V006 ∈ {3,4}` por construção. 697 deles (94,7%) têm mais de um chefe no mesmo bloco (340 com dois, 195 com quatro, um com 32); só 39 têm um único chefe.
- **[produto] As cinco colunas de harmonização do CEM** chamam-se `cem001`, `cem002`, `cem003`, `cem004` e `CEM005` — a quinta em maiúsculas.

---

## Censo 1980 — microdados da amostra

Os fatos sobre a republicação em DBF (Fernando de Noronha ausente, quatro variáveis perdidas, a `V518`, as cinco diferenças do produto em relação à v0.5.0) estão consolidados em `microdata_1980_ftp_vs_aux.md`, reescrito em 13/09/2026. Resumo do que mudou de número ali:

- **[IBGE]** O DBF do FTP não contém Fernando de Noronha: 26 UFs, 29.378.455 pessoas contra 29.378.753 da amostra preparada (298 = `V2 == "20"`), 69 domicílios a menos.
- **[IBGE]** `V518` tem **4.020** códigos distintos: 3.991 municípios mais 29 códigos de origem parcial (`UF+0000` em 26 UFs, `540000`, `800000`, `990000`), cobrindo 468.308 registros (7,42% dos que têm código). Os prefixos observados são 11–53 mais 54, 80 e 99. (Afirmava-se 3.991 códigos, prefixos só em 11–53.)
- **[IBGE]** A partição por `V517` não é exata: 55.959 registros têm `V517 = 9` (sem declaração) — 48.000 com `V518 = "0"` e 7.959 com código.
- **[IBGE]** No grupo `V518 = "0"`, **34,5%** nasceram em outra UF (2.053.342 de 5.955.024); 61,5% na mesma UF; 4,0% no exterior ou sem declaração. (Afirmava-se 35,9%, calculado sobre um denominador que excluía estrangeiros sem dizer.)
- **[IBGE]** `V517 != 8` e `!is.na(V518)` selecionam exatamente as mesmas 12.267.617 linhas: o `NA` de `V518` é biunívoco com `V517 = 8` (17.111.136 nos dois sentidos).
- **[IBGE]** `V518` é a única variável que dá o **município** de residência anterior; a UF de nascimento (`V512`) está no DBF e dá origem em resolução de UF. (Afirmava-se que "nada mais no DBF carrega origem geográfica".)
- **[IBGE]** O DBF de domicílios tem, nas mesmas 26 UFs, 169.987 registros a mais que a amostra preparada; 169.976 deles são de `ESPECIE` 5 (144.390) e 7 (25.586). A diferença líquida total, com Fernando de Noronha de um lado só, é 169.918.
- **[IBGE]** A `Documentação.xls` de 2025 não tem entrada para as variáveis 517, 518 e 521, em duas lacunas separadas (517–518, e 521, cujo lugar é ocupado por uma repetição da 524).
- **[produto]** `code_muni` tem 0 NA e 3.991 valores distintos no produto (v0.5.0: 35.567 NA, 3.938 distintos). `V212`, `V213` e `V602` são NA nas 233.344 linhas fora do universo (`V201 != "1"`). São cinco as diferenças em relação à v0.5.0, não três. Em v0.5.0, as 35.567 linhas casadas pelo crosswalk (69 de FN, 35.498 de GO; 53 municípios) vinham içadas para o topo — não "53 linhas".

### Os pesos `V603` e `V604`

- **[IBGE] Os 55 domicílios particulares permanentes com peso zero.** São proprietários em 5,5% (3 de 55, com `V209 = 1`, "já pago") contra 55,5% no conjunto da espécie 1 (55,7% ponderado); com próprio = `V209 ∈ {1,3}`, 7,3% contra 61,2%. **Vinte** têm aluguel diferente de zero: 17 valores reais (120 a 2.000 Cr$) e **3** sentinelas `999999`. Dos 160 moradores, 159 têm `V604 > 0` e um tem `V604 = 0`. (Afirmava-se "5,5% contra 75,3%", "14 com aluguel", "dois com a sentinela", "todos os 160".)
- **[IBGE] A sentinela de "não se aplica" no DBF é solidária em 20 variáveis** de domicílio, não 13: **14** recebem `0` — TIPO, SANUSO, TPRESID, COMODOS, COMODOR, FOGAO, COMBCOZI, TELEFONE, ILUMINA, RADIO, GELADEIR, TV, AUTOMOVE e **ALUGUEL** — e 6 recebem um dígito não-zero (PAREDES = 1, PISO = 2, COBERTUR = 8, AGUA = 8, SANESCOA = 1, CONDOCUP = 8). Esse mesmo erro (13) está na carta ao IBGE.
- **[IBGE] O layout de 1980 não declara categoria alguma para 26 das 89 variáveis** — `V3`, `V4`, `V5`, `V6`, `V601`, `V602`, `V212`, `V213`, `V603`, `V604`, `V518`, `V527`, `V530`, `V532`, `V536` a `V539`, `V542`, `V544`, `V546` a `V549`, `V557`, `V570` — incluindo três substantivas do bloco de domicílio: aluguel (`V602`), total de cômodos (`V212`) e dormitórios (`V213`). Pelo menos 35 variáveis usam `9`/`99` para "ignorado" (21 usam branco para "não se aplica" e 7 usam `98` para "a ser imputado"). (Afirmava-se que só `V603` e `V604` não declaravam categoria, e "25 variáveis" com 9/99.)
- **[produto] A conversão de `V211` de 0 para NA não foi feita neste pipeline:** a fonte `release_legacy` já entrega `V211` com 233.344 NA e nenhum zero; no DBF do IBGE, `TPRESID` é 0 nesses registros. A conversão ocorreu na amostra preparada, a montante.
- **[produto] Estado atual do bloco de domicílio fora do universo:** 20 das 21 variáveis substantivas usam NA nas 233.344 linhas; `V603` é a única que mantém 0. `V212`, `V213` e `V602` passaram a NA nos commits `d6ff527` e `30d26ec` (12/09/2026).
- **[produto] Se os 55 fossem imputados** com a média nacional de `V603` (3,888439), a soma subiria +213,86 (0,000848%), para cerca de 25.210.853; com a mediana do próprio município, +188,11. Isso quebraria 23 das 40 células que hoje batem exatamente com o SIDRA (Brasil, 10 das 26 UFs afetadas, 2 situações, 10 das 11 classes de cômodos). O consumidor `censobr` tem um teste — `tests/testthat/test_read_households.R:111` — que exige `sum(V603) == 25210639`; a imputação o quebraria. (Afirmava-se "+~152", "quebraria as 40 células" e "o censobr não diz nada sobre esse peso em lugar nenhum".)
- **[produto] A imputação de `V604` que foi revertida** injetava 151,3239878020747824 de peso (soma 119.011.203,324) e produzia sete pesos fracionários com seis valores distintos — 3,133333; 3,968721; 4,068571428571428; 4,138022; 4,950980; 5,931026. (Afirmava-se 151,334 e 4,078571.)
- **[produto] A paridade de `V604` com o SIDRA** foi verificada em 23 marginais — Brasil, 2 sexos, 2 situações, 17 grupos etários e idade ignorada — todas exatas. A tabela 206 do SIDRA por UF soma 25.210.413, e Fernando de Noronha aparece só no total Brasil: os 226 que faltam por UF são FN.
- **[produto] Fernando de Noronha na geografia.** `geobr::read_municipality(year = 1980)` devolve só `code_muni`, `name_muni`, `code_state` e `abbrev_state`; para o código 20, `abbrev_state` é NA e "Fernando de Noronha" aparece apenas como `name_muni` de 2000107. Os rótulos FN / Fernando de Noronha / região 2 / Nordeste foram criados neste pipeline, não herdados do geobr.
- **[produto]** A amostra preparada é mais completa que o DBF num sentido só: tem os 69 domicílios de FN que o DBF não tem, mas não tem os 169.976 registros de domicílios coletivos (espécies 5 e 7) que o DBF tem.

---

## Censo 1991 — microdados da amostra

Vários destes fatos foram aprofundados em 13/09/2026 e estão em `microdata_1991_ftp_vs_aux.md`; aqui ficam as correções de número.

- **[produto] O produto difere do publicado em v0.5.0.** `name_region` muda de "Centro-oeste" para "Centro-Oeste" em 276.692 linhas (todas as do Centro-Oeste); as seis colunas `code_*` chegaram a sair como `double` e, com a convenção de tipos de 13/09/2026, voltam a `int32`, como em v0.5.0. As outras 51 colunas são idênticas: 4.024.543 linhas, 58 colunas na mesma ordem, 0 NA em `code_muni`, 4.491 municípios, soma de pesos 35.435.725. (Afirmava-se "nenhuma divergência".)
- **[IBGE] O DBF do FTP tem 17.045.712 registros de pessoa; a amostra preparada, 17.045.653.** A diferença de 59 está em Rondônia (+58, todas no município de Ariquemes) e na Bahia (+1); as outras 25 UFs batem exatamente. A reconstrução do agrupamento pessoa → domicílio pela ordem da pessoa (`PESSOAN == 1`) funciona em RR e AC, mas em RO dá 26.860 grupos para 26.850 domicílios. (Afirmava-se "100%".)
- **[IBGE] Os dois primeiros dígitos da `V0102` não são a UF.** São Paulo aparece sob dois prefixos: 35 (344.675 domicílios, 8 municípios do núcleo metropolitano) e 36 (534.696 domicílios, 564 municípios), sem município em comum — 28 prefixos para 27 UFs. Os 4 dígitos seguintes são a **pasta** de arquivamento (campo 2 do CD 1.02, "para uso do Órgão Central"), e os 3 últimos o número do questionário na pasta. Agrupando pelo prefixo de 6 dígitos há 27.819 pastas e 6 cruzam município; agrupando por (UF, 4 dígitos) haveria 25.815 e 2.010 — este segundo agrupamento é o errado.
- **[produto] O arquivo preparado não está ordenado pela `V0102`:** começa por SP (35), depois 11, 12, … 53; dentro de cada UF a `V0102` cresce em 26 das 27, e o bloco de prefixo 36 de SP não é crescente.
- **[IBGE] Os DBFs se chamam `CD91AMOUP<código numérico da UF>.DBF`** — `…14` é Roraima, `…12` o Acre, `…35` São Paulo — não `<sigla>`.
- **[produto]** O release `v0.6.0` de `ipeaGIT/censobr` contém um único asset, `censobr_0.6.0.tar.gz`, e nenhum parquet; os parquets `v0.6.0` que existiam em `data/` eram saída deste pipeline. Itapipoca (CE) é publicada com o código correto 2306405 em v0.5.0 (1.525 linhas).
- O rótulo "Identificação do Questionário" para `V0102` consta de dois documentos (o layout do IBGE, de que o HTML do `censo_docs` é exportação, e o dicionário do Pedro Souza), não de "quatro fontes independentes".

---

## Censo 2010 — agregados por setor censitário

### O deslocamento de nomes no `Pessoa02` de São Paulo (FTP do IBGE)

O IBGE publica o tema Pessoa02 de São Paulo com os nomes das 170 variáveis deslocados em +85: a coluna chamada `V086` contém o que deveria ser `V001`.

- **[IBGE] O defeito sobrevive à republicação de 15/06/2026.** O log `1_Atualizacoes_20250915.txt` não existe mais (HTTP 404); foi substituído por `1_Atualizacoes_20260615.txt`, junto com a republicação das 27 UFs como `*_20260615.zip`. O log novo registra apenas a correção do `Cod_setor` nos CSVs; `pessoa02_sp1.csv` dessa publicação continua com 172 colunas e `V086`–`V255` contíguas. A carta ao IBGE deve citar a publicação de 15/06/2026.
- **[IBGE] SP1 e SP2 não são "RMSP e interior".** `SP1` é um único município, São Paulo capital (3550308, 18.363 setores); `SP2` são os outros 644, inclusive Guarulhos (1.705 setores) e Osasco. As pastas do zip chamam-se `SP_Capital` e `SP_Exceto_Capital`. O dicionário do IBGE se contradiz: em dois trechos diz "município de São Paulo" e na nota de rodapé 3 diz "Região Metropolitana".
- **[IBGE] A censura por `X` é simétrica.** Cada uma das 170 colunas de Pessoa02 e as colunas `V002`–`V085` de Pessoa01 têm 20 (AC), 157 (SP1) e 1.222 (SP2) células `X`. A única coluna sem nenhuma célula `X` é `Pessoa01_V001`, que o IBGE preserva como variável estrutural. Por isso 84 das 85 identidades aritméticas entre os dois arquivos fecham com zero — não por estarem isentas de censura — e a 85ª, a de `V001`, difere exatamente pela soma de `Pessoa01_V001` nos setores censurados: 247 em AC, 4.070 em SP1, 87.098 em SP2 (média de 12,3 / 25,9 / 71,3 alfabetizados por setor censurado). A taxa de censura não cresce com o tamanho da UF: AC 2,29%, SP1 0,85%, SP2 2,56%; no Quadro 1 do IBGE, PB 0,6%, SC 4,5%, AC 2,3%, SP 2,1%, Brasil 2,0%.
- **[produto] Setor a setor, a identidade fecha com diferença exatamente zero** em 100% dos setores não censurados: 854 de 854 em AC, 18.206 de 18.206 em SP1, 46.511 de 46.511 em SP2. As diferenças de 0,04% a 0,33% só aparecem quando se agrega por UF — a agregação não contorna a censura, é ela que a torna visível. No parquet final, `pessoa02_V_i + pessoa02_V_(i+85) = pessoa01_V_i` vale para as 85 categorias em todos os 66.096 setores de SP (18.363 + 47.733, o mesmo total que o Quadro 1 do IBGE publica), dos quais 1.379 (2,1%, também igual ao Quadro 1) estão suprimidos dos dois lados.
- **[produto] O deslocamento é exclusivo de `PESSOA02_SP1` e `PESSOA02_SP2`**, verificado em todas as 28 publicações e todos os temas. O padrão de numeração de `ENTORNO02`–`ENTORNO05` (colunas começando em 202, 422, 623, 843) é desenho do IBGE, idêntico nas 28. `DOMICILIO02_RO` tem 241 colunas `V` contra 132 nas outras 26 UFs, sem deslocamento.
- **[produto] A correção elimina 85 colunas espúrias**, não 86: sem ela, a união dos nomes de Pessoa02 dá 256 colunas (`V001`–`V255` + `V1005`); com ela, 171. Nenhum parquet publicado ou construído teve 256 colunas `pessoa02_V*`: todos têm 2.008 colunas, 310.114 linhas e exatamente 171. Desde 13/09/2026 a `Situacao_setor` de cada subarquivo fica com o nome do IBGE em vez de virar `V1005`, e o `Cod_setor` também fica: a tabela passa a 2.010 colunas, com 170 `pessoa02_V*` e `pessoa02_Situacao_setor`.
- **[produto] Na v0.5.0**, SP tem `pessoa02_V001`–`V085` 100% NA e `V086`–`V170` com os valores que deveriam ser `V001`–`V085`; não existem colunas `V171`–`V255`, e `V086`–`V170` estão preenchidas em todas as UFs (NA entre 0,59% e 4,45%).
- **[produto]** O produto cartesiano que apareceu num `merge` do `data.table` veio de linhas-resumo do IBGE com `code_tract` NA (o `data.table` casa NA com NA; o `left_join` antigo as descartava em silêncio) — não tem relação com o deslocamento de Pessoa02.

### O que a v0.5.0 publicada tinha, e o produto atual

- **[produto] `Basico`, colunas `V003`–`V012`.** Na v0.5.0 o preenchimento ia de 0,723% (RN, `V003`) a 9,223% (RR, `V007`), mediana 2,00%, com 48 das 240 combinações arquivo × coluna acima de 3%. Quatro arquivos-fonte estavam íntegros — MG (32.564 setores, 99,76%), RJ (27.769, 99,79%), PR (17.465, 99,89%) e SP_Exceto_Capital (47.733, 99,63%), somando 125.531 setores — e 24 estavam quebrados (184.589 setores). No produto atual o preenchimento é 99,85% (mínimo 97,94%). Onde a v0.5.0 tem valor, ele é idêntico ao atual em 100,00% das 12 colunas. Os valores sobreviventes de `V003` na v0.5.0 são 19 distintos e não contíguos — 1 a 13, 15, 16, 20, 23, 36, 54 —, todos inteiros exatos.
- **[IBGE → produto] Os decimais estão intactos nos arquivos do IBGE.** `Basico_AC.xls` traz "3,39" em `V003` e `BASICO_AC.csv` traz "3,39" na mesma célula; 856 das 874 linhas do Acre têm decimais nos dois formatos. A perda de decimais na v0.5.0 foi na leitura, do nosso lado, e não é um caso de "arquivo fora do formato dominante" do IBGE.
- **[IBGE] `Domicilio01_V001`** é "domicílios particulares **e** coletivos" (dicionário do IBGE, §6.2); "domicílios particulares permanentes" é a `V002`. No RS, `V001` = 3.653.000 e `V002` = 3.599.604.
- **[produto] `Domicilio`:** as 241 células divergentes entre v0.5.0 e o atual estão **todas** no RS; nas outras 26 UFs a paridade é 9.750 de 9.750 (26 × 375 colunas).
- **[IBGE] `Entorno` em CE, DF, MG, PE e RS:** faltam as 19 colunas descritivas de geografia em todos os cinco temas (2 colunas não-V contra 21). Em `Entorno01` e `Entorno03` (201 `V`) isso é 203 colunas contra 222; em `Entorno02`, `04` e `05` (220 `V`), 222 contra 241.
- **[produto] Tabelas de renda:** `DomicilioRenda` tem 15 colunas `V` × 310.120 setores = 4.651.800 células; `PessoaRenda` e `ResponsavelRenda`, 133 × 310.120 = 41.245.960 cada; 0 diferenças em relação à v0.5.0. (Os totais de colunas dos parquets são 23 e 141, incluindo geografia.)
- **[produto] `Responsavel` no ES:** a v0.5.0 tem 695.420 células NA (6.380 setores × 109 colunas); o produto atual tem 684.613 valores que lá são NA.
- **[produto] Nomes e tipos na v0.5.0.** A v0.5.0 **já** publicava os 19 nomes canônicos (`code_muni`, `name_muni`, `code_state`, …, `Basico_V1005`); a única coluna com nome do IBGE era `Cod_municipio`, ao lado de `code_muni`. O que mudou depois foi a **remoção** de `Cod_municipio` (35 → 34 colunas) e a padronização dos valores de `name_state`, `name_region` e `abbrev_state`. Em 13/09/2026 a política se inverteu: o produto mantém todas as colunas de geografia do IBGE com o nome original (`Cod_setor`, `Cod_Grandes Regiões`, `Cod_UF`, `Nome_da_UF`, `Cod_municipio`, …, `Situacao_setor`) e acrescenta as censobr no início — o Básico passa a 54 colunas (22 censobr + 32 do IBGE), sem `Basico_V1005`; a situação do setor está em `Situacao_setor` e na cópia `code_situacao`. `name_region` na v0.5.0 é "Região Norte", "Região Sul" etc., com acento. **Todas** as 11 colunas `code_*` da v0.5.0 são string — nenhuma inteira —, e a pré-release v0.6.0 do GitHub também; a orientação de migração é `"11"` → `11` para todas as `code_*`.
- **[produto] As cinco issues de 2010, o que cada uma era de fato.** #73 (`X` virando 0): **não se reproduz** — em 17.631 células `X` de seis tabelas, a v0.5.0 tem NA em 100%; o script que a gerou já convertia `X` em NA. #68 (Goiás): os nomes malformados são `V01`–`V99`, não `V01`–`V09`; na v0.5.0, GO tem 99 das 171 colunas `pessoa02_V*` 100% NA e 72 com dado — não "todo NA"; SP1/SP2 não pertencem ao #68, seu NA vem do deslocamento +85. #71 (`V009` de renda): NA de 96,21% (AM) a 98,81% (TO) em **23** das 27 UFs, inclusive o Distrito Federal (98,60%); as exceções são MG, RJ, PR (0%) e SP (27,35%); e não é só `V009` — `V003` a `V012` têm o mesmo perfil. A coluna `table_name` e as colunas `...` do Entorno (com exatamente 1 valor não-NA em 310.120 linhas, 99,99968% de NA) foram corrigidas no commit `6a1e66f`. O rename canônico foi ativado no commit `3555121` (03/05/2026), trocando duas condições.

---

## Censo 2022 — agregados por setor censitário

### A `V0006` do `Básico`: proporção no definitivo, percentual no preliminar

- **[produto] A identidade `V0005 = V0001 / V0007` fecha em 100,0000%** dos 408.445 setores com `V0004 = 0` e `V0007 > 0`. Os 2.136 casos que pareciam não fechar são empates exatos — `|V0005 − V0001/V0007| = 0,05000000` verificado a 17 dígitos — em que o IBGE arredonda para cima e o `round()` do R arredonda meio-para-par. Não há setor sem explicação.
- **[IBGE] O teste que decide a escala** não é a identidade de inteiro `V0006 × V0007 = k` — ela fecha nas duas leituras (441.101 de 441.101). É a restrição `k ≤ V0007`: lendo `V0006` como proporção ela vale em 38,44% (169.559 de 441.101); lendo como percentual, em 100,00%. Os denominadores alternativos reproduzem `V0006` em 32,56% (`V0002`), 32,37% (`V0003`) e 34,47% (`V0001`); excluídos os 149.423 setores com `V0006 = 0`, que passam em qualquer denominador, caem para 2,59%, 2,60% e 5,67%, enquanto `V0007` segue em 100,00%.
- **[IBGE] Os 11 setores com `V0006 > 1`.** Em todos, `V0006` é `k / V0007` arredondado a 4 casas com `k` inteiro; o produto `V0006 × V0007` só é inteiro exato em 2 (354340210000122: 2,0000 × 11 = 22; 410490705000149: 1,4000 × 5 = 7). Em 2 dos 11 o `k` é reproduzido por outras colunas da mesma linha: no setor 354340210000122, `k = 22 = V0002 = V0003 + V0004 = V0001 − V0002`; no 430660105100006, `k = 62 = V0001 − V0003`. Três dos 11 não existem no preliminar (150276405000050, 354340210000122, 410490705000149); nos 8 presentes, com o mesmo `V0007`, o preliminar dá `k ≤ V0007` e o definitivo dá `k > V0007` (setor 510420305000020, `V0007 = 39`: `k` = 151 no definitivo, 17 no preliminar) — o defeito está na republicação definitiva.
- **[IBGE] A documentação dos setores de 2022 está partida em cinco arquivos** — 3.400 códigos `V` no dicionário do definitivo (`V00001`–`V03950`), 105 nos três de entorno, 6 no de renda do responsável — 3.511 no total, contra as 3.501 variáveis temáticas que a Nota metodológica n. 06 declara. Além de `V0005` e `V0006`, não são contagens: `V06003` (variância do número de moradores), `V06004` (rendimento nominal médio mensal), `V06005` (variância do rendimento) e `V06006` (rendimento nominal mediano).
- **[produto]** Parquet e CSV do IBGE são iguais **em valor** — o CSV grava texto com vírgula decimal ("0,0923"), o parquet grava double — em 468.099 de 468.099 setores para `V0001`–`V0009` e `code_tract`, sem NA e sem `X`.

---

## Censo 2022 — microdados da amostra de acesso público

- **[produto]** Os quatro parquets somam **280** colunas (60 + 173 + 28 + 19), das quais 260 são variáveis do IBGE e 5 × 4 são geografia.
- **[IBGE]** Sete variáveis têm decimais: os quatro pesos (13 decimais) e `D0240` (moradores por dormitório, 2 inteiros e 2 decimais), `D0360` e `F0260` (rendimentos per capita, 9 inteiros e 2 decimais).
- **[produto]** `code_weighting` existe só nos produtos de 2000 e 2010. 1970, 1980 e 1991 não a têm, e 1960 não tem `code_muni` (não há crosswalk 1960 → 2010; desde 13/09/2026 tem `code_state`, `abbrev_state`, `name_state`, `code_region`, `name_region` e `name_muni`, além de `code_muni_1960`). A ausência em 2022 rompe com 2000/2010, não com "todas as edições".
- **[produto]** O pipeline grava apenas `2022_<tabela>.publico_<versão>.parquet`; nenhum arquivo `.controlado` é produzido aqui, e o consumidor, no HEAD do GitHub, ainda grava o nome sem sufixo.
- **[produto]** Tamanhos em disco (v0.7.0): households 144.295.923 bytes (137,61 MiB), population 639.194.018 (609,58 MiB), families 95,08 MiB, mortality 5,50 MiB.
- **[IBGE]** O controle `D0100` é uma sequência nacional **com lacunas**: vai de 1 a 7.806.723 com 116.809 valores ausentes (1,50%) — exatamente os domicílios eliminados pela subamostra de 50% e pela supressão global. Na versão de acesso controlado, seis variáveis da tabela de pessoas excedem 32 bits (a área de ponderação e os cinco códigos de país `P0510`, `P0590`, `P0630`, `P0830`, `P1150`), não só uma.

---

## Correções só de redação, sem conteúdo de dado

Aplicadas ou a aplicar nos textos; listadas para completar os 113.

- 1980: "omite a linha de três variáveis" → são duas lacunas; "preenchida" → "presente" (`V518` é NA em 58,2%); a conferência do DBF cobriu os 52 arquivos, não só Rondônia.
- 1980, pesos: o parêntese "20 células (2 sexos × 2 situações × 17 grupos + ignorada)" era aritmeticamente incoerente — são 23 marginais; o link `R/microdata_1980.R:103-119` apontava para código já substituído.
- 1991: "quatro fontes independentes" → dois documentos.
- 2010, Pessoa02: a frase "é falsificável: um único corte que não fechasse derrubaria a hipótese" convive com um corte que não fecha e é explicado; a formulação sustentada pela evidência é "84 fecham exatos e o 85º é explicado exato pela censura"; "64.717 de 64.717" precisa do denominador (66.096 setores, 1.379 suprimidos); o item que mandava registrar "256 → 171 colunas" em outro documento era resíduo já retratado.
- 2010, defeitos v0.5.0: dois parágrafos contradiziam a caixa de correção do próprio documento; "13 colunas" → 12; "~98%" → 99,85%; as colunas vizinhas casam com `PUB_V003` em 0,38% (`V001`) e 1,07% (`V002`), não "0,28% ou 0,00%".
- 2010, divergências: "99,9999%" → 99,99968%; "fix de 1 linha" → duas condições; "86 colunas" → 85.
- 2022, setores: "byte a byte" → igualdade de valor; "~32%" vale para `V0002` e `V0003`, não para `V0001` (34,47%).
- 2022, microdados: "265 colunas" → 280; tamanhos 137,3 e 609,8 MB não correspondiam a nenhum arquivo.
- 1970: "cem001–cem005" → a quinta é `CEM005`.
