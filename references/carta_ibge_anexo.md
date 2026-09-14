# Anexo — defeitos verificados nas distribuições dos Censos Demográficos no FTP do IBGE

Cada item traz o arquivo afetado, a evidência medida e a confirmação de que o defeito persiste na distribuição vigente (verificações de 12 e 13 de setembro de 2026). A gravidade — ALTA, MÉDIA ou BAIXA — indica o impacto sobre quem usa o dado, não a dificuldade de correção. Os itens estão agrupados por edição do Censo e, dentro de cada edição, por gravidade.


## Transversais e Censo de 1960

### 1. [ALTA] O IBGE não distribui nenhum microdado do Censo de 1960 (nem 1940, nem 1950)

**Arquivos.** Inexistentes. Árvore https://ftp.ibge.gov.br/Censos/ (índice lido em 12/09/2026) contém apenas: Censo_Demografico_1970/ (2025-01-09 19:08), 1980/ (2025-01-09 19:07), 1991/ (2025-01-09 19:05), 2000/ (2016-08-17 11:09), 2010/ (2017-08-25 15:28), 2022/ (2026-08-31 09:04) e leia_me.txt (881 bytes, 2018-06-21)

**Evidência.** https://ftp.ibge.gov.br/Censos/Censo_Demografico_1960/ responde HTTP/1.1 404 Not Found (Apache/2.4.37, 12/09/2026 19:42 GMT); idem 1950/ e 1940/. Varredura recursiva de toda a árvore /Censos/ (47.748 entradas, ~1.000 índices) não devolve nenhum arquivo de 1960. Pastas adjacentes checadas e descartadas: /seculoxx/ (leia_me.txt: 'tabelas encontradas no CD-ROM Estatísticas do Século XX... conjunto de tabelas em Excel' — agregados, não microdados), /Informacoes_Gerais_e_Referencia/, /Documentos/, /Estoque/. O que o IBGE de fato publica de 1960 são os volumes impressos digitalizados na Biblioteca (ex.: https://biblioteca.ibge.gov.br/visualizacao/periodicos/68/cd_1960_v1_t9_mg.pdf → HTTP 200, application/pdf): tabulações, não registros. Consequência: quem precisa dos microdados de 1960 recorre a uma costura de duas amostras de terceiros — a de 1,27% (162.055 registros de pessoas, cobrindo 11 unidades da federação) e a extração de 5% do IPUMS feita sobre a amostra de 25% parcialmente processada (14.983.769 registros, cobrindo as outras 17); os dois conjuntos são disjuntos por UF e somam 15.145.824 pessoas, com soma de pesos 70.924.748.

**Persiste.** curl -sI nas URLs acima em 12/09/2026; crawler recursivo do índice HTML do FTP; Wayback CDX de ftp.ibge.gov.br/Censos/ — snapshot 20241109103646 lista 1991/2000/2010/2022 e o snapshot 20250122183253 já lista 1970/1980: 1960 nunca apareceu em nenhum deles

### 2. [ALTA] Toda a árvore /Censos/ tem apenas TRÊS arquivos de log de atualização; 1970, 1980, 1991, os agregados de setor de 2000 e o Censo 2022 inteiro não têm nenhum

**Arquivos.** Existem: (1) /Censos/Censo_Demografico_2000/Microdados/2_Atualizacoes_20170908.txt — 482 bytes, Last-Modified Fri, 08 Sep 2017 18:43:23 GMT, MD5 0e58f0e80a4875b2f00e2a9d97033e7d; (2) /Censos/Censo_Demografico_2010/Resultados_Gerais_da_Amostra/Microdados/1_Atualizacoes_20160311.txt — 121 bytes, MD5 7ad6737fab8535d2f69509d76a18dbb3; (3) /Censos/Censo_Demografico_2010/Resultados_do_Universo/Agregados_por_Setores_Censitarios/1_Atualizacoes_20260615.txt — 2.598 bytes, Last-Modified Mon, 15 Jun 2026 11:55:33 GMT, MD5 b8ee8516c0fe6fb04626064ae232ab03. NÃO existem para: Censo_Demografico_1970/Microdados/, 1980/Microdados/, 1991/Microdados/, 2000/Dados_do_Universo/Agregado_por_Setores_Censitarios/ e

**Evidência.** Varredura recursiva completa da árvore /Censos/ (47.748 linhas de índice) com grep por 'atualiza'. Os únicos outros acertos são nomes de arquivos de dado ('Questionario_amostra_completo_CD2022_atualizado_20220906.pdf', 'CD2022_Municipios_com_limites_atualizados...'), não logs. Os 10 arquivos leia_me/Leia_me/Leia-me encontrados são descritivos de conteúdo, não históricos de alteração — verificado abrindo /Censos/leia_me.txt, /Censos/Censo_Demografico_2000/Dados_do_Universo/leia_me.txt e /Censos/Censo_Demografico_2022/Microdados_e_Areas_de_Ponderacao/Documentacao/Leia-me.pdf (39 KB, 19/08/2026 — descreve as pastas 'Áreas de ponderação', 'Bancos de descritores', 'Divisão territorial', 'Instrumentos de coleta', 'Layout', 'Dicionário', 'Notas metodológicas'; nenhuma linha de histórico). Casos concretos de republicação sem log: os três zips de microdados de 1970/1980/1991 datados de 09/01/2025; os agregados de setor de 2022, cuja única sinalização de mudança é o sufixo do nome do arquivo (_20250417, _20260520).

**Persiste.** crawler próprio do índice HTML do FTP (1970, 1980, 1991, 2000, 2010, 2022), 12/09/2026; grep -i 'atualiza|leia.?me|errata|retific|corrig|changelog|historico' sobre o índice consolidado

### 3. [MÉDIA] Divisão Territorial do Brasil incompleta nos pacotes de microdados de 1970 e 1980

**Arquivos.** Microdados_Censo_Demografico_1970_Amostra.zip (263.170.655 bytes, 09/01/2025): a pasta 'Divisão Territorial do Brasil/' contém UM único arquivo, 'Região Sul.xls' (226.304 bytes, data interna 2013-03-26). Microdados_Censo_Demografico_1980_Amostra.zip (544.850.882 bytes, 09/01/2025): a mesma pasta contém DOIS arquivos, 'DTB - Região Centro-Oeste.xls' (168.960 bytes) e 'DTB - Região Sul.xls' (430.592 bytes)

**Evidência.** Faltam Norte, Nordeste e Sudeste nos dois pacotes (e também Centro-Oeste em 1970). Em 1970 a lacuna alcança São Paulo, Minas Gerais, Bahia, Guanabara e Rio de Janeiro, que somam a maior parte dos 27 arquivos de dado. Para contraste, o pacote de 1991 traz um arquivo único e nacional ('Divisão Territorial do Brasil/DTB Municipios 1991.xls', 681.472 bytes) e o Documentacao.zip de 2010 traz 'Unidades da Federação, Mesorregiões, microrregiões e municípios 2010.ods/.xls' também nacionais — ou seja, a forma correta existe nas outras edições.

**Persiste.** central directory dos zips remotos via HTTP Range, 12/09/2026


## 1970

### 4. [ALTA] 1.785 registros deslocados em DAMO70AL.txt e Damo70PE.txt (violam o LRECL de 76 bytes da própria documentação do IBGE)

**Arquivos.** Dentro de Microdados_Censo_Demografico_1970_Amostra.zip (263.170.655 bytes, MD5 d390dff085f7ad92775b665f91d053e3, Last-Modified 09/01/2025 22:08:30 GMT): Dados/DAMO70AL.txt (32.148.949 bytes, data no zip 14/11/2005 17:10, MD5 37094fe0b11b2a7ac5d2bb182e95e9f3, CRC-32 53b4d46a) e Dados/Damo70PE.txt (107.794.519 bytes, data no zip 16/11/2005 10:25, MD5 e1d1fa7110fe9ab0b2478742f04befac, CRC-32 bc971b5f). Referência íntegra: Dados/DAMO70AC.txt (MD5 a681e6bfce52a96e3892016e0744d913).

**Evidência.** Varredura byte a byte dos 27 arquivos: 24.793.359 registros, 1.785 anômalos (0,0072%). AL: 46 anômalos em 412.171 (comprimentos 16:6, 58:22, 94:17, 136:1 -> desvios -60, -18, +18, +60). PE: 1.739 em 1.381.977 (16:205, 54:3, 58:658, 66:1, 68:1, 94:658, 98:4, 132:1, 136:204, 154:4). Os 25 demais arquivos têm 100% das linhas com exatamente 76 caracteres. Saldo de bytes: AL -390, PE +312 -- ambos batem com o tamanho físico do arquivo (412.171x78+1-390 = 32.148.949; 1.381.977x78+1+312 = 107.794.519), ou seja, caracteres foram MOVIDOS, não criados nem destruídos. CORREÇÃO ao relatório interno: o saldo de PE é +312, não +274 (a decomposição correta tem -18:658 e 14 'outros', não -18:657 e 15).

CONSEQUÊNCIA NO PESO AMOSTRAL (V054, posições 75-76, último campo do registro), classificando os 1.785 numa leitura de largura fixa: 211 linhas fragmentárias (16 caracteres); 685 sem as posições 75-76; 215 com conteúdo não numérico em 75-76; 650 recebem PESO FALSO MAS PLAUSÍVEL, sem nenhum sinal de erro; 24 acertam por acaso. Soma 211+685+215+24+650 = 1.785. Exemplos de peso falso (posição 75-76 vs cauda verdadeira): AL linha 308489 lê "10" em vez de "04"; linha 323613 lê "27" em vez de "03"; linha 324453 lê "21" em vez de "04"; linha 337897 lê "27" em vez de "04". CORREÇÕES ao relatório: as fragmentárias são 211 e não 212 (não existe nenhuma linha de 17 a 20 caracteres), e as que perdem o peso

**Persiste.** Três provas independentes de que o arquivo servido HOJE é exatamente o que analisamos. (1) HEAD em https://ftp.ibge.gov.br/Censos/Censo_Demografico_1970/Microdados/Microdados_Censo_Demografico_1970_Amostra.zip em 12/09/2026: Content-Length 263.170.655, idêntico ao esperado; ETag "fafaa5f-62b4d37e15c97" cuja parte de tamanho (0xfafaa5f) é 263.170.655. (2) md5sum da cópia local (baixada em 05/05/2026) = d390dff085f7ad92775b665f91d053e3, exatamente o valor esperado. (3) Três requisições HTTP Range contra o FTP hoje (bytes 0-262143, 131072000-131334143 e 262908511-263170654, este último contendo o diretório central do ZIP com o CRC-32 de cada membro) -- os três trechos têm MD5 idêntico aos mesmo

### 5. [ALTA] 79 bytes de lixo binário em Damo70PE.txt, dois deles em registros de comprimento VÁLIDO (invisíveis a qualquer teste de comprimento)

**Arquivos.** Dados/Damo70PE.txt (107.794.519 bytes, MD5 e1d1fa7110fe9ab0b2478742f04befac), dentro de Microdados_Censo_Demografico_1970_Amostra.zip

**Evidência.** Varri os 27 arquivos contando bytes fora do conjunto esperado [0-9, espaço, hífen, CR, LF, 0x1A]. Vinte e seis arquivos têm ZERO bytes inesperados -- inclusive DAMO70AL.txt, cujo dano é puramente posicional. Só Damo70PE.txt tem 79 bytes inesperados, assim distribuídos: 13 caracteres de controle C0 (NUL 0x00 x1, BS 0x08 x2, TAB 0x09 x4, VT 0x0B x4, CAN 0x18 x1, ESC 0x1B x1), 33 bytes com bit alto (0x80-0xFF: 0xD0 x3, 0xC3 x2, 0xB1 x2, 0x97 x2 e mais 24 valores distintos uma vez cada) e 33 caracteres ASCII imprimíveis que não são dígito, espaço nem hífen (letras soltas E, G, K, L, M, N, R, U, V, W, X, b, i, j, v e pontuação ! " # $ % & ' ) * , ; [ ^ } ). Isso é lixo de memória, não dado -- e corrobora a hipótese de escorregamento de buffer na produção do arquivo.

O achado crítico: esses 79 bytes se espalham por 42 linhas, das quais 40 JÁ constam entre as 1.739 anômalas por comprimento -- mas DUAS têm exatamente 76 caracteres e portanto passam despercebidas por qualquer verificação de comprimento, sendo aceitas em silêncio por um leitor de largura fixa.

- Linha 34.635 (76 caracteres): as posições 75-76, que são o CAMPO DO PESO AMOSTRAL V054, contêm os bytes 0xC3 0x8C. Conteúdo: '2211060121010119555262222050300033091012-    2111-                  -     ' + 0xC3 0x8C. A linha seguinte (34.636) tem 58 caracteres, isto é, o deslocamento começa exatamente ali.

- Linha 306.296 (76 cara

**Persiste.** Mesma cadeia de prova do defeito anterior: o zip servido hoje pelo FTP é byte a byte idêntico à cópia analisada (Content-Length, MD5 e três HTTP Range conferidos em 12/09/2026, incluindo o diretório central do ZIP). A varredura de bytes foi refeita hoje sobre os 27 arquivos extraídos desse zip. Bytes exibidos em hexadecimal via od -c sobre as linhas 34.635 e 306.296.

### 6. [MÉDIA] o pacote nacional de 1970 é distribuído com a documentação e o anexo territorial de apenas UMA região (Sul)

**Arquivos.** Dentro de Microdados_Censo_Demografico_1970_Amostra.zip: 'Documentação/Documentação.doc' (163.328 bytes, data no zip 14/02/2017 09:45) e 'Divisão Territorial do Brasil/Região Sul.xls' (226.304 bytes, data no zip 26/03/2013 14:48)

**Evidência.** O zip distribui dados de 27 unidades da federação (24.793.359 registros), mas a única documentação incluída é a do DVD da Região Sul. O documento se identifica como 'INSTITUTO BRASILEIRO DE GEOGRAFIA E ESTATÍSTICA / CENSO DEMOGRÁFICO - 1970 / ARQUIVO ZONADO / CDDI/GEATE' e, em 'CARACTERÍSTICAS FÍSICAS', nomeia exclusivamente três arquivos: 'NOME DO ARQUIVO: REGIÃO SUL DAMO70PR.TXT 1.849.451 registros DAMO70SC.TXT 781.688 registros DAMO70RS.TXT 1.768.576 registros' e declara 'NÚMERO DE REGISTROS: 4.399.715 registros'. Uma busca por 'DAMO70' no documento inteiro retorna apenas DAMO70PR, DAMO70SC e DAMO70RS -- os outros 24 arquivos do pacote não são documentados. Do mesmo modo, a pasta 'Divisão Territorial do Brasil/' contém um único arquivo, 'Região Sul.xls'. O usuário que baixa o pacote nacional não recebe nem a contagem oficial de registros nem a divisão territorial das outras 24 unidades.

Dois subprodutos úteis para a carta:

(a) O documento fixa a especificação oficial: 'TAMANHO DO REGISTRO (LRECL): 76 bytes'. Logo, as 1.785 linhas anômalas violam o layout publicado pelo próprio IBGE.

(b) As contagens oficiais das três UFs documentadas (PR 1.849.451, SC 781.688, RS 1.768.576, total 4.399.715) coincidem EXATAMENTE com a minha varredura independente desses arquivos, o que valida o método de contagem usado para apurar os 1.785 registros anômalos nos

**Persiste.** Extração de 'Documentação/Documentação.doc' do zip baixado do FTP (byte a byte idêntico ao servido hoje, conforme verificação por Content-Length, MD5 e HTTP Range em 12/09/2026) e leitura do fluxo de texto do .doc em CP-1252, com busca por 'REGIÃO', 'DAMO70', 'LRECL' e 'NÚMERO DE REGISTROS'. Listagem do zip por 'unzip -l' confirma que 'Divisão Territorial do Brasil/' contém somente 'Região Sul.xls'. A listagem HTTP de https://ftp.ibge.gov.br/Censos/Censo_Demografico_1970/Microdados/ confirma que não há documentação avulsa fora do zip.

### 7. [BAIXA] Pacote de 1970 — pasta com erro de grafia e 27 arquivos de dado com três convenções de maiúsculas

**Arquivos.** Microdados_Censo_Demografico_1970_Amostra.zip — 263.170.655 bytes, Last-Modified Thu, 09 Jan 2025 22:08:30 GMT, 37 entradas

**Evidência.** A pasta dos anexos chama-se 'Arquivos Auxliares/' — falta o 'i' de Auxiliares (nos pacotes de 1980, 1991 e 2000 a mesma pasta chama-se 'Arquivos Auxiliares'). Os 27 arquivos de dado misturam três convenções: 'DAMO70AC.txt' (tudo maiúsculo), 'Damo70BA.txt' (capitalizado) e 'Damo70PI.TXT' (extensão maiúscula) — um script que monte o nome do arquivo a partir da sigla da UF falha em parte dos estados conforme a convenção que adotar. As datas internas também são heterogêneas dentro do mesmo lote (16 arquivos de 1998-01-21, 7 de 2005-11-16, 2 de 2005-11-14, 1 de 2004-11-09, 1 de 2006-10-18), embora o zip tenha sido publicado em 09/01/2025 sem nenhum log.

**Persiste.** central directory do zip remoto lido por HTTP Range em 12/09/2026


## 1980

### 8. [ALTA] A republicação em DBF perde quatro variáveis que existem na distribuição anterior: V518 (MIUFANT, município/UF anterior), V3 (mesorregião), V4 (microrregião) e V6 (distrito)

**Arquivos.** Microdados_Censo_Demografico_1980_Amostra.zip (544.850.882 bytes, MD5 1129ac8abe4dbb2d0dbaccff689f8b37, Last-Modified 2025-01-09 22:08:20 GMT) -> Dados/*/Pessoas/CD80PES{11..53}.DBF, todos os 26

**Evidência.** Cabeçalho DBF lido nos 26 arquivos de pessoa: layout idêntico em todos (61 campos, registro de 165 bytes). O bloco de migração termina em MITEMPMU: MINACION, MIUFNASC, MINASCMU, MIMUMOZN, MIANTEZN, MITEMPUF, MITEMPMU. MIUFANT não existe em nenhum dos 26 (`any(MIUFANT %in% campos) = FALSE`). Busca por MESO|MICRO|DIST|SETOR|AREA na união dos 61 campos: nenhum resultado. Na amostra anterior a V518 está preenchida em 29.378.753 registros, com 4.022 valores distintos, 17.111.136 NA (V517=8, nasceu aqui) e 5.955.024 iguais a "0" (V517=7, migrante antigo sem origem codificada). V518 é a única variável do bloco de migração que identifica a origem geográfica e não é reconstruível a partir do DBF.

**Persiste.** HEAD em https://ftp.ibge.gov.br/Censos/Censo_Demografico_1980/Microdados/Microdados_Censo_Demografico_1980_Amostra.zip em 12/09/2026: Last-Modified Thu, 09 Jan 2025 22:08:20 GMT, Content-Length 544.850.882, ETag "2079c3c2-62b4d375174bf" -- idênticos ao arquivo local baixado em 05/05/2026. Índice do diretório mostra 2025-01-09 19:08, 520M. Nenhum arquivo de log de atualização existe na pasta de 1980. Parse direto do cabeçalho dos 26 DBF extraídos do zip.

### 9. [ALTA] COMODOS (quesito 12, total de cômodos) corrompida em 47 dos 223 municípios de Goiás: médias de 43 cômodos por domicílio, 1.064 casos de dormitórios > cômodos totais, e 5.093 campos numéricos em branco

**Arquivos.** Dados/Região Centro-Oeste/Domicílios/CD80DOM52.DBF (11.440.120 bytes)

**Evidência.** Nos 47 municípios afetados (35.013 domicílios ESPECIE=1) a média de COMODOS no DBF é 42,721; nos outros 176 municípios de GO é 4,960, e na distribuição anterior dos MESMOS 47 municípios é 4,879. Domicílios com 20 cômodos ou mais: 20.109 de 35.013 (57%) no DBF contra 15 na distribuição anterior. Nacionalmente o excesso de COMODOS>=20 é 25.405 (DBF) contra 5.311 (anterior): a diferença de 20.094 está integralmente nesses 47 municípios (20.109-15=20.094). COMODOR > COMODOS, logicamente impossível: 1.064 casos no DBF, TODOS nesses 47 municípios, zero no resto do Brasil e zero na distribuição anterior. 5.093 registros com o campo numérico COMODOS literalmente em branco (nenhum outro campo de nenhum outro DBF de domicílio tem branco, exceto TPRESID em Curitiba). Casamento registro a registro por assinatura de conteúdo (21 campos, exigindo assinatura única nos dois lados): nos 47 municípios afetados, 33.139 pares e apenas 2.545 valores iguais (7,68%); em 8 municípios de GO não afetados, 7.565 pares e 7.565 iguais (100%). Bytes crus do município 52-0950 mostram COMODOS=46, 11, 72, 20 e branco em registros de ESPECIE=5 (coletivo) cujos outros 20 campos são todos a sentinela 0 -- o bloco de NSA está quebrado exatamente em COMODOS. Maiores afetados: Jaraguá (1.911 dom.), Porangatu (1.837), Gurupi (1.782), Inhumas (1.703), Porto Nacional (1.685), Itapuranga (1.653), Iporá (1.511), Itaberaí

**Persiste.** Arquivo do FTP inalterado desde 09/01/2025 (HEAD em 12/09/2026). O cabeçalho interno de todos os DBF traz a data 28/11/2011 (bytes 03 11 11 28), isto é, os arquivos foram gerados em 2011 e só empacotados em 2025 -- a corrupção vem da conversão, não do empacotamento. Comparação contra a amostra que o projeto usa (release_legacy, CSVs de 2018 convertidos em parquet), que fora dos municípios afetados bate 100% registro a registro, inclusive nas sentinelas 999999 e 99.

### 10. [ALTA] TPRESID (quesito 11, tempo de residência) corrompida em Curitiba: 7.451 valores fora do esquema de codificação do próprio IBGE, e mais ~1.100 valores plausíveis porém trocados

**Arquivos.** Dados/Região Sul/Domicílios/CD80DOM41.DBF (23.334.274 bytes), município 0690 (Curitiba)

**Evidência.** O Boletim da Amostra CD 1.01 (quesito 11, incluído no próprio pacote) e o layout definem TPRESID como prefixo + valor: 1xx = meses (100=0, 112=12, 199=ignorado), 3xx = anos (300=0, 398=98, 399=ignorado), 0 = NSA. Em 6.886.803 domicílios há 7.451 valores fora desse esquema e TODOS estão em 41-0690: 2.521 no bloco 1-99, 1.574 no bloco 113-198, 1.885 no bloco 200-299 (nenhum dos três existe na codificação) e 1.471 em branco. Restrito a ESPECIE=1: 6.959 de 60.708 domicílios (11,5%). Curitiba é o único município do Brasil com qualquer valor inválido; na distribuição anterior Curitiba tem zero. Casamento por assinatura de conteúdo (22 campos, assinatura única dos dois lados): 37.106 pares. Nos 4.078 pares em que o DBF traz valor inválido ou branco, a distribuição anterior traz valor válido em 100% dos casos (ex.: DBF 160 / anterior 107; DBF 129 / anterior 303; DBF 262 / anterior 105; DBF 48 / anterior 309). Além disso, em 1.137 pares o DBF traz valor válido mas diferente do anterior -- corrupção silenciosa. Concordância total em Curitiba: 31.869/37.106 = 85,89%. Grupo de controle (município 41-1220, mesmo método): 590 pares, 590 iguais, 100%.

**Persiste.** Arquivo do FTP inalterado desde 09/01/2025 (HEAD em 12/09/2026, Content-Length 544.850.882). Cabeçalho interno do DBF datado de 28/11/2011. Verificação contra o questionário CD 1.01 extraído do próprio zip (Instrumentos de Coleta/Boletim da Amostra.pdf), que é de fato o de 1980 (IX Recenseamento Geral do Brasil).

### 11. [ALTA] O Território de Fernando de Noronha (UF 20) está inteiramente ausente do DBF, e por isso os totais nacionais calculados a partir dele não fecham com o que o próprio IBGE publicou

**Arquivos.** Dados/ -- o pacote traz 26 pares CD80DOM/CD80PES (UF 11-16, 21-29, 31-35, 41-43, 50-53). Não há CD80DOM20.DBF nem CD80PES20.DBF

**Evidência.** Aritmética exata nas duas tabelas. Domicílios: sum(PESOD) no DBF = 25.210.413; a amostra anterior soma 25.210.639, diferença de exatamente 226, que é o peso dos 69 domicílios de Fernando de Noronha; 25.210.639 é o valor do SIDRA t206 (domicílios particulares permanentes, 1980), verificado em 40 células (Brasil, 26 UFs, 2 situações, 11 classes de cômodos). Pessoas: o DBF tem 29.378.455 registros e sum(PESOP) = 119.009.778; a amostra anterior tem 29.378.753 registros e sum(V604) = 119.011.052; a diferença é exatamente 298 pessoas e 1.274 ponderadas, que são Fernando de Noronha; 119.011.052 é o valor do SIDRA t200/t202 (população residente, Amostra, 1980). Ou seja, quem usar o DBF de 2025 fica 226 domicílios e 1.274 pessoas abaixo do total oficial do IBGE.

**Persiste.** Listagem completa do zip (79 arquivos) obtida com unzip -Z1 e conferida contra o FTP em 12/09/2026; só existem 26 UFs. A paridade com o SIDRA foi estabelecida em apuração anterior deste projeto (references/microdata_1980_pesos_v603_v604.md, 40 células para domicílios e 20 para pessoas) e reconferida aqui somando os 26 DBF.

### 12. [MÉDIA] 54 domicílios particulares permanentes (ESPECIE=1) com peso zero (PESOD=0), dentro do universo ponderado

**Arquivos.** Dados/*/Domicilios/CD80DOM{13,21,22,24,25,27,29,31,35,42}.DBF

**Evidência.** Varredura dos 6.886.803 registros de domicílio: PESOD=0 em 403.374 deles. Desses, 403.320 são exatamente o universo ESPECIE!=1 (27.487 improvisados + 328.887 coletivos permanentes + 46.946 coletivos improvisados), em que 0 é a sentinela de NSA usada solidariamente por outras 13 variáveis do mesmo registro. Sobram 54 com ESPECIE=1 e PESOD=0. São registros completos: zero campos em branco nas 26 colunas, TPRESID válido (101 a 360), COMODOS de 1 a 11, 14 com aluguel declarado (120 a 2.000 Cr$, dois com a sentinela 999999). Distribuição não aleatória: MG 14, BA 12, AM 7, SP 7, PB 6, AL 3, RN 2, PI/MA/SC 1, em 29 municípios. Efeito agregado: sum(PESOD)=25.210.413 nas 26 UFs; somado a Fernando de Noronha (226) dá 25.210.639, exato contra o SIDRA t206 -- ou seja, o IBGE publicou suas tabelas com esses 54 zerados.

**Persiste.** Mesmo arquivo verificado no FTP em 12/09/2026 (inalterado desde 09/01/2025). Contagem direta nos 26 DBF de domicílio. Na amostra preparada anterior os mesmos registros aparecem com peso zero (55 lá, porque inclui um de Fernando de Noronha que o DBF não traz), e o mesmo valor está em v0.2.0, v0.3.0 e v0.5.0 do censobr -- três distribuições sem tratamento.

### 13. [MÉDIA] 169.987 registros de domicílio coletivo (45,2% de todos os coletivos) não têm nenhum morador no arquivo de pessoas, nenhum peso e nenhum dado substantivo

**Arquivos.** Dados/*/Domicilios/CD80DOM*.DBF x Dados/*/Pessoas/CD80PES*.DBF, todas as 26 UFs

**Evidência.** Cruzamento da chave (UF, MUNIC, CONTADOM) do arquivo de domicílio com (UF, MUNIC, NDOM) do de pessoas, UF por UF: 0 pessoas órfãs (todas as 29.378.455 casam), mas 169.987 domicílios sem nenhuma pessoa. Repartição: ESPECIE=5 144.401 de 328.887 (43,9%) e ESPECIE=7 25.586 de 46.946 (54,5%); nenhum de ESPECIE=1 ou 3. Todos têm PESOD=0 e todas as 17 variáveis substantivas do bloco de domicílio na sentinela de NSA: são registros sem conteúdo algum. Os coletivos que TÊM morador somam 241.911 pessoas (esp. 5) e 23.439 (esp. 7), com 1,31 e 1,10 morador por registro -- o que sugere um registro de domicílio por pessoa amostrada; 45% deles não têm a pessoa correspondente. Essa é também a resposta à pergunta em aberto sobre os ~170 mil coletivos a menos na amostra preparada: são EXATAMENTE esses 169.987 registros. Prova independente: na amostra preparada o contador de domicílio V601 é uma sequência global que vai de 0 a 6.886.882, ou seja 6.886.883 posições = 6.886.803 (as 26 UFs do DBF) + 80 (Fernando de Noronha), com exatamente 169.998 inteiros faltando (169.987 nas 26 UFs + 11 em FN). A numeração foi feita sobre o conjunto completo e o corte veio depois. Espécies 1 e 3 batem registro a registro: 6.483.483 e 27.487 nos dois lados. Portanto o corte dos coletivos é de quem preparou a amostra, NÃO falta de dado no IBGE -- mas a assimetria interna do arquivo do IBGE (45% dos coletivos sem mor

**Persiste.** Cruzamento feito nas 26 UFs a partir dos DBF extraídos do zip do FTP (inalterado desde 09/01/2025). Contador V601 lido do parquet release_legacy. O Leiame.txt do pacote diz apenas que os dois arquivos se ligam por UF, MUNIC, CONTADOM, sem uma palavra sobre coletivos sem morador.

### 14. [MÉDIA] A pasta Arquivos Auxiliares do pacote de 1980 contém documentação dos Censos de 1991 e 2000, não de 1980

**Arquivos.** Arquivos Auxiliares/ (20 arquivos, ~18 MB) dentro de Microdados_Censo_Demografico_1980_Amostra.zip

**Evidência.** V1004.txt abre com o cabeçalho literal "CENSO DEMOGRÁFICO- 2000 / MICRODADOS DO UNIVERSO" e lista regiões metropolitanas. Composicao_das_Areas_de_Ponderacao.txt tem 215.813 linhas com códigos de setor censitário de 15 dígitos (110001505000001), a codificação de 2000 -- áreas de ponderação não existem em 1980 e o microdado de 1980 não tem identificador de setor. Doze arquivos nomeiam variáveis V4xxx, que são do questionário de 2000/2010 e não existem em 1980 (Cursos Superiores V4534 e V4535, Religião V4090, Migração V4210/V4260/V4230, ONU V4219/V4239/V4269/V4279, Municípios V4250, Municípios e País Estrangeiro V4276). CNAE Dom-Estrutura.xls traz a CNAE, criada em 1995. Ocupação - Estrutura.xls traz a CBO com grupo de base de 4 dígitos, enquanto TOCUPACA em 1980 tem 3. Atividade 91-Estrutura.xls e Ocupação 91-Estrutura.xls são de 1991. Divisão Territorial Brasileira.xls usa código de município de 7 dígitos e código de distrito de 9, posteriores a 1980. Nenhum arquivo da pasta serve para 1980.

**Persiste.** Arquivos extraídos do zip baixado do FTP (inalterado desde 09/01/2025, conferido por HEAD em 12/09/2026) e abertos um a um com readxl/readLines.

### 15. [MÉDIA] Na Documentação.xls a coluna Faixa foi destruída por conversão automática do Excel em 44 das 83 variáveis: os intervalos viraram datas

**Arquivos.** Layout/Documentação.xls (203.776 bytes), folhas Domicílio e Pessoa

**Evidência.** Lido direto do XLS do IBGE com readxl (col_types = "text"), sem intermediários. Na folha Domicílio, 17 das 24 linhas de variável trazem na coluna Faixa um serial de data do Excel em vez do intervalo: 36708 = 01/07/2000 (era "1 - 7"), 36770 = 01/09/2000 (era "1 - 9"), 36586 = 01/03/2000 (era "1 - 3"). Atingidas: SITUACAO, ESPECIE, TIPO, PAREDES, PISO, COBERTUR, AGUA, SANESCOA, CONDOCUP, FOGAO, COMBCOZI, TELEFONE, ILUMINA, RADIO, GELADEIR, TV, AUTOMOVE. Na folha Pessoa, 27 das 59: SEXO, PARENDOM, PARENFAM, FAMILIA, RELIGIAO, COR, MAEVIVA, MINACION, MINASCMU, MIMUMOZN, MIANTEZN, MITEMPUF, EDSABELE, EDSERIE, EDULGRAU (duas vezes), EDCURSNS, EDULSERI, ESTCONJ, TRUL12M, TSITDESO, TPOSICAO, TPREVID, THORTRTO, TQTSALAR, TSITULSN, TOUTRAPO -- com os seriais 36586, 36647 (01/05/2000), 36678 (01/06/2000), 36739 (01/08/2000) e 36770. O usuário fica sem a amplitude declarada de 44 variáveis, justamente as categóricas.

**Persiste.** Leitura direta de Layout/Documentação.xls extraído do zip do FTP (203.776 bytes, 09/01/2025), sem nenhuma conversão intermediária: a corrupção está no XLS distribuído.

### 16. [MÉDIA] A Documentação.xls omite 4 variáveis que estão no dado, duplica 2 linhas e nomeia errado a chave de ligação do arquivo de pessoas

**Arquivos.** Layout/Documentação.xls (folhas Início, Domicílio, Pessoa) e Leiame.txt

**Evidência.** Folha Domicílio: 24 linhas de variável para 26 campos do DBF. Faltam SANUSO (quesito 208, Instalação Sanitária - Uso, com 5 valores distintos no dado) e PESOD (o peso do domicílio, a variável sem a qual nada se estima). TIPO aparece duas vezes, idêntica. Folha Pessoa: 60 linhas para 61 campos. Faltam MITEMPMU (517, tempo de residência no município) e EDGRAU (521, grau que frequenta). EDULGRAU (524-Grau Última Série Concluída) aparece duas vezes, com rótulo e lista de categorias idênticos, exatamente na posição em que deveria estar EDGRAU -- erro de cópia. A folha Pessoa e a folha Início documentam a chave do arquivo de pessoas como CONTADOM; o campo no DBF chama-se NDOM. O Leiame.txt repete o erro. A folha Início ainda se refere a "CD80PES12.DBF" e "CD80DOM12.DBF" (Acre) como se fossem nomes genéricos.

**Persiste.** Comparação campo a campo entre os nomes do cabeçalho dos DBF (26 no de domicílio, 61 no de pessoa, layout idêntico nas 26 UFs) e as linhas de variável das duas folhas do XLS, lido com readxl. Leiame.txt extraído do zip do FTP.

### 17. [BAIXA] Sentinelas não declaradas e faixas declaradas que não correspondem ao dado

**Arquivos.** Layout/Documentação.xls x Dados/*/*/CD80{DOM,PES}*.DBF

**Evidência.** (a) CONTADOM: declarado "0 - 9999"; o máximo observado é 557.160 e 1.943.273 registros (28% do arquivo) excedem 9999. (b) ALUGUEL: declarado "0 - 999999999" sem categoria de ignorado; o valor 999999 aparece 21.052 vezes, é o máximo do arquivo e é evidentemente sentinela, mas não está documentado. (c) As 7 variáveis de rendimento do arquivo de pessoas (RPRINDIN, RPRINPRM, ROUTROCU, RAPOSENT, RALUGUEL, RDOACOES, RCAPITAL) são declaradas "0 - 999999999" em campos de 9 posições, mas o máximo observado em todas é 9.999.999 (7 dígitos) -- a faixa declarada está duas ordens de grandeza acima da real. (d) IDADEMES: declarada "0 - 99" com categorias 0 a 11; o valor 99 ocorre 28.946 vezes e é o único valor observado fora das categorias em todo o arquivo de pessoas. (e) ESPECIE declara a categoria "2 - Particular ocasional", que tem 0 registros nos 6.886.803 domicílios e nem sequer existe no Boletim CD 1.01, cujo quesito 1 só oferece 1, 3X, 5X e 7X.

**Persiste.** Tabulação exaustiva de todos os valores de todos os campos de até 3 posições nos 26 DBF de domicílio e nos 26 de pessoa (1.961 pares campo/valor), confrontada com as categorias declaradas extraídas do XLS e com o questionário CD 1.01 do próprio pacote. Arquivo do FTP inalterado desde 09/01/2025.


## 1991

### 18. [ALTA] Dicionário rotula o código 16 de MIUFPAIS como "SE" (Sergipe); o código é a Bahia — 492.708 registros mal decodificados

**Arquivos.** Documentação/Dicionário 1991.xls (180.736 bytes, 2025-01-09, aba "Layout"), dentro de Microdados_Censo_Demografico_1991_Amostra.zip; afeta a variável MIUFPAIS (bytes 404-405 de todos os 27 CD91AMOUP<UF>.DBF)

**Evidência.** A lista de categorias de MIUFPAIS ("UF/Pais de nascimento") traz 97 códigos. O rótulo "SE" aparece duas vezes: no código 15 e no código 16. A sequência é a ordem canônica das UFs (1 RO, 2 AC, 3 AM, 4 RR, 5 PA, 6 AP, 7 TO, 8 MA, 9 PI, 10 CE, 11 RN, 12 PB, 13 PE, 14 AL, 15 SE, 16 ?, 17 MG, 18 ES, 19 RJ, 20 SP, 21 PR, 22 SC, 23 RS, 24 MS, 25 MT, 26 GO, 27 DF), em que a posição 16 é a Bahia. O dado confirma: o código 16 ocorre em 492.708 registros e o código 15 em 71.122 — razão de 6,9 para 1, compatível com o peso relativo de BA e SE na emigração interna, e incompatível com dois rótulos "SE". Quem decodifica pelo dicionário oficial atribui a Sergipe 492.708 registros amostrais (cerca de 4,3 milhões de pessoas expandidas) nascidos na Bahia. É o único rótulo duplicado em todo o dicionário (verifiquei as 127 variáveis com lista de categorias; só MIUFPAIS tem duplicata).

**Persiste.** Dicionário extraído do zip atual do FTP (HEAD em 2026-09-12: Last-Modified Thu, 09 Jan 2025 22:07:17 GMT, Content-Length 673.659.331, ETag "282739c3-62b4d338d8eef" — idênticos à cópia local analisada, MD5 f41a9bf306b84a538c8dfc18b4ffcab2). Lista de categorias parseada da aba Layout com readxl; contagens dos códigos obtidas por varredura completa dos 17.045.712 registros.

### 19. [ALTA] Em 59 das 73 variáveis com código de "não aplicável" declarado, esse código nunca aparece no dado — o DBF deixa o campo em branco, estado não documentado (342.836.420 células)

**Arquivos.** Documentação/Dicionário 1991.xls (coluna "NSA") x os 27 CD91AMOUP<UF>.DBF

**Evidência.** Dos 133 campos numéricos do DBF, 73 têm código de NSA não nulo no dicionário. Em 59 deles o código declarado não ocorre em nenhum dos 17.045.712 registros; em 56 desses o campo vem inteiramente em branco. Exemplos com o número de registros em branco: IDADEMES (NSA declarado 12) 16.662.520; UVIVIDAD (100) 12.966.605; HORTRAB (99) 10.707.861; LOCTRAB (9) 10.707.861; os 18 campos de fecundidade FLDOMICH..FLVIVOST (100) 10.449.020 cada; SCDURASC (100) 9.571.433; EDCURSO (99) 4.056.861; TVPRETO/TVCORES/FREEZER/GELADEIR/MAQLAVAR/ASPIRPO (2, 4, 2, 3, 2, 2) 3.172.312 cada; EDANOEST (31), EDGRAU (6), EDSERIE (9), EDULGRAU (9), EDULSERI (10), EDCURSNS (7) 1.973.835 cada; AGUA (7), BANHEIRO (6), COMODOS, CONDOCUP (7), RADIO (2), SANUSO (3), TELEFONE (3) e mais 7 variáveis de domicílio 132.407 cada. Soma das células em branco nesses campos: 342.836.420. Em contraste, 14 variáveis usam sim o código declarado (MIULTMUD 98 em 15.461.070 registros, ALUGUEL 999998 em 132.407, RACACOR 9 em 58.245 etc.), o que mostra que a convenção existe e apenas não foi aplicada — nem documentada — na maioria dos campos. O risco prático é direto: qualquer leitor que converta branco em zero transforma 1.973.835 "não aplicável" de EDANOEST em "zero ano de estudo" e 10.707.861 de HORTRAB em "zero hora trabalhada".

**Persiste.** Varredura byte a byte dos 133 campos numéricos nos 27 DBFs (contagem de registros com o campo integralmente preenchido por espaços e tabulação completa dos valores), cruzada com as colunas NSA/Ignorado do Dicionário 1991.xls do mesmo zip. Arquivo verificado no FTP em 2026-09-12 (sem alteração desde 2025-01-09).

### 20. [ALTA] Pesos de expansão não reproduzem a população publicada em 91 municípios — desvio acima de 5% em 9 deles, pior caso -10,43% (Cavalcante/GO)

**Arquivos.** Campo PESO (bytes 224-235) dos 27 CD91AMOUP<UF>.DBF, confrontado com Arquivos Auxiliares/FRACAMO.TXT (219.199 bytes) do mesmo zip e com Censo_Demografico_1991/Populacao_Residente_Urbana_Rural/{Goias,Parana}.zip (POPS91GO.XLS, POPS91PR.XLS)

**Evidência.** Somando PESO sobre os registros de pessoa por município e comparando com o universo declarado em FRACAMO.TXT: 4.400 dos 4.491 municípios batem com precisão relativa da ordem de 1e-8 (ou seja, a calibração é municipal e exata), mas 91 municípios divergem em pelo menos 1 pessoa, 40 divergem mais de 1% e 9 mais de 5%. Os nove piores: Cavalcante/GO 5205307 (amostra 1.246 pessoas, soma dos pesos 7.305,7 contra universo 8.156, -850,3, -10,43%); Marcelândia/MT 5105580 (8.049,4 x 8.889, -9,45%); Lizarda/TO 1712405 (3.775,1 x 4.166, -9,38%); Diamante d'Oeste/PR 4107157 (8.396,2 x 9.253, -9,26%); Sapopema/PR 4126207 (7.751,4 x 7.095, +9,25%); Guamaré/RN 2404507 (5.591,9 x 6.082, -8,06%); Ponte Alta do Tocantins/TO 1717909 (7.065,4 x 7.486, -5,62%); Nova América da Colina/PR 4116604 (3.898,8 x 4.105, -5,02%); Doverlândia/GO 5207253 (9.700,3 x 10.213, -5,02%). No total nacional a soma dos pesos dá 146.815.790 contra 146.825.475 do universo (-9.685). Confirmei que o universo do FRACAMO é a população publicada, baixando as tabelas do próprio FTP: Cavalcante 6.155 rural + 2.001 urbana = 8.156; Sapopema 4.234 + 2.861 = 7.095; Diamante d'Oeste 6.377 + 2.876 = 9.253; Nova América da Colina 2.277 + 1.828 = 4.105 — todos idênticos ao FRACAMO. O total do Brasil nas mesmas tabelas (35.834.485 + 110.990.990 = 146.825.475) também coincide.

**Persiste.** Soma de PESO por município em varredura completa dos 27 DBFs do zip atual do FTP; FRACAMO.TXT extraído do mesmo zip; tabelas de população baixadas do FTP em 2026-09-12 (Goias.zip 10.158 bytes, Last-Modified 2016-08-17 14:07:43 GMT; Parana.zip do mesmo diretório). Planilha completa dos 4.491 municípios em munic_peso_desvio.csv no scratchpad.

### 21. [MÉDIA] LEIA_ME.DOC: seis linhas erradas na tabela de conferência e os 27 tamanhos em bytes descrevem um formato que não é o distribuído

**Arquivos.** LEIA_ME.DOC (55.296 bytes, 2025-01-09, dentro do zip; propriedades do documento: criado 1996-09-27, última gravação 2013-10-10 por "Tania Maria Orichio")

**Evidência.** A tabela "A disposição dos arquivos de dados, o número de bytes de cada arquivo e os números de registros de pessoas e domicílios" tem 27 linhas. Reconstruí cada linha pela aritmética de um formato ASCII de 102 bytes por domicílio + 234 bytes por pessoa (+1 ou +2 bytes de EOF): 21 das 27 batem exatamente, e NENHUMA das 27 traz o tamanho real do DBF distribuído (o erro é de cerca de 2x: RO declara 30.925.489 bytes, o CD91AMOUP11.DBF tem 59.387.382). Ou seja, os tamanhos são herdados do CD-ROM ASCII de 1996 e não foram atualizados quando o conteúdo virou DBF em 2013/2025, embora o mesmo documento afirme "Existe um arquivo de DADOS em DBF para cada Unidade da Federação". As seis linhas divergentes: (1) CD91AMOUP14 (RR) — coluna de bytes preenchida com "23.102", que é o número de pessoas; deveria ser 5.965.441. (2) CD91AMOUP24 (RN) — coluna de pessoas preenchida com "72.051", que é o número de domicílios; o valor real é 338.374, e a própria coluna de bytes do documento (86.528.719 = 72.051x102 + 338.374x234 + 1) confirma 338.374. (3) CD91AMOUP35 (SP) — declara 924.371 domicílios; o DBF contém 879.371 (diferença de exatos 45.000) e a própria coluna de bytes do documento, 880.725.590, equivale a 879.371x102 + 3.380.469x234 + 2, confirmando 879.371. (4) CD91AMOUP21 (MA) declara 134.258.659, a aritmética dá 134.258.629. (5) CD91AMOUP23 (CE) declara 181.766.445, a aritmética dá 181.776.

**Persiste.** Texto do LEIA_ME.DOC extraído do zip atual; contagens reais obtidas dos cabeçalhos DBF (registros) e de cumsum(PESSOAN == 1) (domicílios) nos 27 arquivos; tamanhos reais do índice do zip e de stat. Zip reverificado por HEAD em 2026-09-12, inalterado desde 2025-01-09.

### 22. [MÉDIA] O DBF não traz nenhum identificador de domicílio (V0102), e com ele perde-se a unidade submunicipal de amostragem

**Arquivos.** Os 27 CD91AMOUP<UF>.DBF (141 campos, 493 bytes por registro)

**Evidência.** Confirmação do que já estava em references/microdata_1991_ftp_vs_aux.md, agora sobre os 27 arquivos e não só sobre RR e AC: o layout é idêntico nos 27 (mesmos 141 campos, mesmos tipos e tamanhos, zero divergência) e nenhum deles é identificação de questionário. O arquivo é só de pessoa — as variáveis de domicílio se repetem em cada morador e não há arquivo de domicílio separado. O agrupamento pessoa->domicílio se reconstrói pelo reinício de PESSOAN (cumsum(PESSOAN == 1) dá 4.024.553 grupos, e as variáveis de domicílio são constantes dentro de cada grupo — verifiquei em RO, AM, PA, RR e AC, zero exceção), mas o código V0102 em si, cujos 4 dígitos centrais carregam o bloco submunicipal (27.819 blocos no país), não é derivável de nada que o DBF entregue. O candidato óbvio, CD107, não é chave. Consequência prática: o DBF do FTP não permite reproduzir a unidade de ponderação de 1991, e a ordem das linhas passa a ser semanticamente carregada (qualquer reordenação destrói silenciosamente a delimitação de domicílio).

**Persiste.** Leitura dos 27 cabeçalhos DBF e comparação campo a campo (nome, tipo, tamanho, decimais): 0 UFs com layout divergente. Agrupamento e constância das variáveis de domicílio verificados por varredura completa. Zip do FTP reverificado em 2026-09-12.

### 23. [MÉDIA] Dez domicílios com registros de pessoa ausentes: a numeração de morador pula, sem que os registros correspondentes existam

**Arquivos.** Dados/Região Norte/CD91AMOUP13.DBF (Amazonas) e Dados/Região Norte/CD91AMOUP15.DBF (Pará)

**Evidência.** Varrendo os 27 arquivos e comparando, em cada domicílio, o número de registros com o maior valor de PESSOAN, dez domicílios têm numeração incompleta — 2 no Amazonas e 8 no Pará — faltando 27 registros de pessoa no total. Exemplos, com o número do registro dentro do arquivo: AM, Manaus (MUNICNUM 0260), CD107 246, registros 89.707-89.709 com PESSOAN 1, 2 e 5 (faltam os moradores 3 e 4); AM, Manaus, CD107 173, registro 113.963 com PESSOAN 8 logo após o 6 (falta o 7); PA, Altamira (MUNICNUM 0060), CD107 7, PESSOAN 3, 4, 5, 8 (faltam 6 e 7); PA, Altamira, CD107 67, PESSOAN 2, 3, 4, 11 (faltam 5 a 10); PA, Altamira, CD107 22, PESSOAN 2, 3, 4, 12; PA, Medicilândia (MUNICNUM 0445), CD107 236, PESSOAN 2, 3, 4, 6. Em todos, o peso e as variáveis de domicílio são constantes no grupo, isto é, o domicílio está íntegro e faltam pessoas dele. O mesmo defeito aparece, ampliado, na versão CSV preparada da amostra, onde 12 domicílios (incluindo um em Minas Gerais, V0102 311341095, com 8 pessoas e numeração até 15) somam 35 registros faltantes.

**Persiste.** Leitura completa do campo PESSOAN (bytes 419-420) nos 27 DBFs do zip atual do FTP, agrupamento por cumsum(PESSOAN == 1) e comparação de max(PESSOAN) com o tamanho do grupo. Contexto de cada anomalia impresso com município, CD107, PARENDOM, idade, sexo, cômodos e peso. Cruzamento com a versão em CSV dos mesmos microdados (amostra preparada de 2018).

### 24. [BAIXA] Byte corrompido: um parêntese dentro do campo de renda domiciliar em um registro do Maranhão

**Arquivos.** Dados/Região Nordeste/CD91AMOUP21.DBF (166.426.556... na verdade 260.120.713 bytes), registro 335.416, offset absoluto 165.364.379

**Evidência.** Em 8,4 GB de corpo de registro há exatamente um byte que não é dígito, espaço ou ponto decimal dentro de um campo numérico: o byte 0x28 ('(') na posição 240 do registro 335.416 do arquivo do Maranhão, dentro do campo RDOMICIV (renda domiciliar, bytes 237-245). O campo lê "   (54000" onde deveria ler "    54000" — os dois registros vizinhos do mesmo domicílio (São Luís Gonzaga do Maranhão, mesorregião Centro Maranhense, microrregião Médio Mearim) trazem "    54000". Um leitor numérico devolve NA ou erro para esse registro. Varri as 321 posições de byte que pertencem a campos numéricos em todos os 17.045.712 registros: esta é a única ocorrência no país.

**Persiste.** Varredura byte a byte das posições de campos numéricos nos 27 DBFs (conjunto permitido: 0x20, 0x2E, 0x30-0x39); localização confirmada por grep binário (grep -abo) e dump do registro com dd/od. Zip do FTP reverificado por HEAD em 2026-09-12.

### 25. [BAIXA] DEMOCOMO e DEMODORM: o código de não aplicável usado no dado (99,98) não é o declarado (9999) e é indistinguível de um valor legítimo

**Arquivos.** Campos DEMOCOMO (bytes 200-206) e DEMODORM (bytes 208-214) dos 27 CD91AMOUP<UF>.DBF x Documentação/Dicionário 1991.xls

**Evidência.** O dicionário declara para ambas NSA = 9999 e Ignorado = 9999. Esse código não aparece em nenhum dos 17.045.712 registros. O código efetivamente usado é 99,98, presente em exatamente 132.407 registros em cada uma das duas variáveis — número que coincide byte a byte com a soma dos domicílios improvisados e coletivos (ESPECIE = 2: 57.505; ESPECIE = 3: 74.902), e com o número de registros em que CONDOCUP, AGUA, COMODOS e outras 11 variáveis de domicílio vêm em branco. Como 99,98 é um número válido no domínio da variável (moradores por cômodo), quem não conhecer a convenção o soma às médias: sem tratamento, a densidade média de moradores por cômodo do país sobe de cerca de 1,1 para cerca de 1,9. Os demais valores da variável são corretos e coerentes com a escala declarada de 2 decimais (verifiquei em Roraima que o campo traz "   1.33" para um domicílio de 4 moradores em 3 cômodos).

**Persiste.** Tabulação de todos os valores distintos dos dois campos nos 27 DBFs (209 e 119 valores distintos respectivamente); contagem cruzada com ESPECIE e com os campos em branco. Zip do FTP reverificado em 2026-09-12.

### 26. [BAIXA] MIUFPAIS: código 48 presente no dado sem entrada no dicionário; a lista pula os códigos 28, 48 e 57 e declara um código 100 que nunca ocorre

**Arquivos.** Documentação/Dicionário 1991.xls (lista de categorias de MIUFPAIS) x campo MIUFPAIS (bytes 404-405) dos 27 DBFs

**Evidência.** A lista de MIUFPAIS tem 97 códigos e a variável assume 97 valores distintos no dado, mas os conjuntos não coincidem: o código 48 ocorre 87 vezes e não tem rótulo (a lista salta de 47 Nicarágua para 49 Paraguai), e o código 100 (NSA) é listado mas nunca aparece — o não aplicável é representado por campo em branco (11.088.249 registros). A lista também não usa os códigos 28 e 57, que ficam como buracos entre 27 DF e 29 "Brasil sem especificação" e entre 56 "Outros América" e 58 Alemanha.

**Persiste.** Lista de categorias parseada da aba Layout do dicionário do zip atual; tabulação completa do campo nos 17.045.712 registros.

### 27. [BAIXA] Empacotamento: nomes internos do zip em CP850 sem marca UTF-8, byte de EOF do DOS solto no FRACAMO.TXT e arquivos sem quebra de linha final

**Arquivos.** Microdados_Censo_Demografico_1991_Amostra.zip (35 entradas); Arquivos Auxiliares/FRACAMO.TXT (219.199 bytes); Arquivos Auxiliares/CÓDIGO ATIVIDADE.TXT (7.788 bytes); Arquivos Auxiliares/OCUPAÇÃO PRINCIPAL.TXT (13.235 bytes)

**Evidência.** Os nomes de diretório e arquivo dentro do zip estão gravados em CP850 sem o bit 11 de UTF-8 ligado (zipinfo reporta origem MS-DOS/FAT, versão de codificação 2.1). Fora do Windows os nomes saem como mojibake: "Dados/Regi\xc6o Centro Oeste", "Documenta\x87\xc6o", "Arquivos Auxiliares/C\xe0DIGO ATIVIDADE.TXT", "Question\xa0rio da Amostra.pdf" — o que quebra extração programática por nome (a linguagem R, por exemplo, não consegue abrir as entradas por unz()). O FRACAMO.TXT termina com um byte 0x1A (Ctrl-Z, EOF do DOS) solto depois do último CRLF, que vira uma 5.220ª linha espúria de 1 caractere em qualquer leitor de texto. Os dois arquivos de códigos (CÓDIGO ATIVIDADE.TXT e OCUPAÇÃO PRINCIPAL.TXT) não têm quebra de linha após a última linha. Em outras pastas de 1991 do mesmo FTP há nomes de arquivo com espaço antes da extensão: Indice_de_Gini/Rio_Grande_do_Sul%20.zip e Sexo_Populacao_Residente/Rio_de_Janeiro%20.zip.

**Persiste.** zipinfo -v e unzip -l sobre a cópia local (idêntica à do FTP por tamanho e ETag); od -c no final do FRACAMO.TXT e dos dois TXT; listagem HTML dos diretórios Indice_de_Gini e Sexo_Populacao_Residente do FTP em 2026-09-12.

### 28. [BAIXA] IDADEANO em branco em 41 registros — terceiro estado não previsto pelo dicionário, que declara NSA e Ignorado iguais a 0 (idade válida)

**Arquivos.** Campo IDADEANO (bytes 374-376) dos 27 CD91AMOUP<UF>.DBF x Documentação/Dicionário 1991.xls

**Evidência.** O dicionário declara para IDADEANO Min 0, Max 130, NSA 0 e Ignorado 0 — ou seja, o código de ausência coincide com uma idade legítima (menores de 1 ano). No dado há ainda um terceiro estado: 41 registros com o campo inteiramente em branco. É o único campo de pessoa obrigatório com essa condição. Registro colateral de plausibilidade, não necessariamente defeito: a idade máxima observada é 127 anos e há 443 registros com 110 anos ou mais (0,0026% da amostra), com distribuição praticamente plana entre 110 e 127 (cerca de 20 a 30 registros por ano de idade) e corte seco em 127.

**Persiste.** Varredura completa do campo nos 17.045.712 registros (tabulação de valores e contagem de campos integralmente em branco), cruzada com as colunas Min/Max/NSA/Ignorado do dicionário.


## 2000

### 29. [ALTA] RN.zip contem uma copia integral e byte-identica da Paraiba, sem qualquer aviso

**Arquivos.** RN.zip (36.516.253 bytes, Last-Modified Fri, 08 Sep 2017 18:44:15 GMT, ETag "22d319d-558b1f6b40f7b") contem 6 arquivos + a pasta RN/: DOM24.txt (15.939.756), DOM25.txt (20.223.244), FAMI24.TXT (12.306.718), FAMI25.TXT (15.406.918), PES24.txt (147.777.894), PES25.txt (185.047.488). PB.zip (20.277.900 bytes, LM 08/09/2017 18:43:59 GMT) contem DOM25.txt, FAMI25.TXT, PES25.txt com os mesmos tamanhos.

**Evidência.** Identidade provada de duas formas independentes. (a) CRC32 no diretorio central dos dois zips, sem descompactar: DOM25.txt = 2313d407 em RN.zip e em PB.zip; FAMI25.TXT = da05e397 nos dois; PES25.txt = 15f63adf nos dois. (b) MD5 dos arquivos extraidos: DOM25.txt = 8c31f60b08186d5af3693eea371945d2; FAMI25.TXT = 78ada920ee7897492715619119be7c4d; PES25.txt = edca508089c47d5f83549af235bd6151 — identicos em RN/ e PB/. Volume duplicado: 117.577 domicilios + 128.391 familias + 487.848 pessoas = 733.816 registros. Varredura do campo V0102 (posicoes 1-2) linha a linha: 100% dos registros dos tres arquivos duplicados trazem UF=25 (Paraiba) e 100% dos arquivos proprios do RN trazem UF=24 — nao ha mistura dentro dos arquivos, a contaminacao e no empacotamento. Custo: 20.277.350 dos 36.515.293 bytes comprimidos de RN.zip (55,5%) e 220.677.650 dos 396.702.018 bytes descomprimidos (55,6%) sao a copia da PB. Consequencia para quem faz um glob ingenuo em RN/*.txt: os totais nacionais inflam +2,22% em domicilios, +2,26% em familias e +2,41% em pessoas, e a populacao expandida sobe de 169.872.854 para 173.317.648 (+2,03%), porque os 3.444.794 paraibanos entram duas vezes. Nada no nome dos arquivos (DOM25/FAMI25/PES25) sinaliza que sao de outra UF para quem nao decora codigos de UF.

**Persiste.** curl -sI em https://ftp.ibge.gov.br/Censos/Censo_Demografico_2000/Microdados/RN.zip em 12/09/2026: HTTP 200, Content-Length 36516253, Last-Modified Fri, 08 Sep 2017 18:44:15 GMT — identico em tamanho a copia local baixada em 11/09/2026. Mesmo HEAD feito nas 27 UFs: todos IGUAIS em tamanho e todos com Last-Modified de 08/09/2017. O log 2_Atualizacoes_20170908.txt nao menciona o assunto.

### 30. [ALTA] BA.zip tem zip dentro de zip, e o arquivo interno de pessoas vem em minusculas

**Arquivos.** BA.zip (71.183.399 bytes, LM 08/09/2017 18:43:36 GMT) contem BA/DOM29.txt (65.172.004, data interna 2003-06-11 13:25), BA/FAMI29.zip (8.523.463, 2007-03-30 14:19) e BA/PES29.zip (54.279.937, 2008-09-24 15:10). PES29.zip contem pes29.txt (605.716.747 bytes) e FAMI29.zip contem FAMI29.TXT (49.762.558 bytes), ambos sem prefixo de pasta.

**Evidência.** Das 27 UFs, a BA e a unica com segundo nivel de compactacao: nas outras 26 o zip da UF entrega direto os tres .txt. E e tambem a unica cujo arquivo de pessoas vem inteiramente em minusculas (pes29.txt); nas demais e PES<cod>.txt ou Pes<cod>.txt. Quem descompacta em uma passada so fica com a Bahia tendo apenas domicilios: perde 1.598.126 pessoas (7,88% da amostra nacional de pessoas) e 414.688 familias (7,29% das familias). O erro e silencioso — nao ha excecao, o dado simplesmente nao aparece. As datas internas mostram que os dois zips aninhados foram criados depois (2007 e 2008) que o DOM29.txt (2003), ou seja, o aninhamento veio de uma reposicao posterior, nao do empacotamento original.

**Persiste.** curl -sI em BA.zip em 12/09/2026: Content-Length 71183399, Last-Modified Fri, 08 Sep 2017 18:43:36 GMT — igual a copia local. unzip -l BA.zip e unzip -l nos dois zips internos no mesmo dia. O log de atualizacoes nao cita o assunto.

### 31. [MÉDIA] Os nomes dos arquivos nao seguem o padrao das macros SAS que o proprio IBGE distribui, e variam de UF para UF

**Arquivos.** Os 81 .txt/.TXT dentro dos 27 zips, contra "SAS/LE DOMIC.sas", "SAS/LE PESSOAS.sas" e "SAS/LE FAMILIAS.sas" de 1_Documentacao_20170908.zip.

**Evidência.** As macros oficiais abrem, respectivamente, "&PASTA.\DOM&UF..TXT", "&PASTA.\PES&UF..TXT" e "&PASTA.\FAMI&UF..TXT" — tudo maiusculo, extensao .TXT. O que o FTP entrega: domicilios como DOM<cod>.txt em 16 UFs e Dom<cod>.txt em 11 (AC, AM, AP, ES, MG, PA, RJ, RO, RR, SP, TO); pessoas como PES<cod>.txt em 15 UFs, Pes<cod>.txt em 11 e pes29.txt (tudo minusculo) na BA; familias como FAMI<cod>.TXT em 27 de 27. Isto e: nenhum dos 54 arquivos de domicilio e pessoa casa com a macro correspondente em sistema de arquivos sensivel a maiusculas (Linux, macOS case-sensitive), ja que a extensao gravada e .txt e a pedida e .TXT; e mesmo ignorando a extensao, 22 dos 54 divergem tambem no radical. So os 27 arquivos de familias casam. Como agravante de portabilidade, o arquivo auxiliar do mesmo zip de documentacao esta gravado como "Composicao das Areas de Ponderaçao.txt" — com cedilha mas sem o til de "Ponderação", em Latin-1 —, o que quebra script que monte o caminho a partir da grafia correta.

**Persiste.** unzip -l nos 27 zips e tabulacao dos radicais com sed/uniq -c em 12/09/2026; grep FILENAME nos tres .sas extraidos do zip de documentacao (Content-Length 2961444, Last-Modified 08/09/2017 18:43:23 GMT, confirmados por HEAD hoje).

### 32. [BAIXA] Byte de fim de arquivo do DOS (0x1A) cria registro-fantasma em dois arquivos de Minas Gerais

**Arquivos.** MG/Dom31.txt (105.797.373 bytes, data interna 2003-09-19 16:59) e MG/Pes31.txt (892.772.092 bytes, 2003-09-19 17:01), ambos dentro de MG.zip (104.522.854 bytes, LM 08/09/2017 18:43:54 GMT).

**Evidência.** Os ultimos 3 bytes dos dois arquivos sao 0d 0a 1a. O 0x1A (SUB, marca de EOF do CP/M-DOS) fica depois do CRLF do ultimo registro valido e produz uma linha extra de 1 caractere. Efeito medido: em Dom31.txt, 615.102 linhas das quais 615.101 tem os 170 bytes do layout e 1 tem 1 byte, com V0102 vazio; em Pes31.txt, 2.347.759 linhas das quais 1 tem 1 byte. Sao exatamente 2 registros vazios no pais inteiro — sem UF, sem municipio e sem peso (a varredura de peso invalido acusa 1 em cada um desses dois arquivos e zero nos outros 79). Conferi o ultimo bloco de bytes dos 81 arquivos: nenhum outro tem 0x1A; MG/FAMI31.TXT esta limpo. Nao ha perda de informacao, mas um leitor que conte registros acha 1 domicilio e 1 pessoa a mais em MG, e um leitor que faca coercao numerica gera NA silencioso.

**Persiste.** tail -c 4 + xxd nos 81 arquivos extraidos dos zips baixados em 11/09/2026; HEAD do MG.zip no FTP em 12/09/2026 confirma Content-Length 104522854 e Last-Modified Fri, 08 Sep 2017 18:43:54 GMT, iguais a copia local.

### 33. [BAIXA] Um registro de domicilio de Pernambuco tem 167 bytes em vez dos 170 declarados no layout

**Arquivos.** PE/DOM26.txt (38.811.625 bytes, data interna 2003-10-09 11:09), dentro de PE.zip (39.193.536 bytes, LM 08/09/2017 18:44:08 GMT). Layout declarado em "SAS/LE DOMIC.sas" do zip de documentacao: FILENAME ... LRECL=170.

**Evidência.** Linha 134.697 de PE/DOM26.txt tem 167 bytes; as outras 225.648 tem 170. O registro termina no P001 (posicoes 157-167, valor 00248351437 = peso 2,48351437) e nao traz as tres ultimas variaveis do layout: V1111 (existencia de identificacao), V1112 (iluminacao publica) e V1113 (calcamento). E um domicilio coletivo (V0201 = 3, posicao 72) com 42 moradores (V7100 = 42), em Recife, municipio 2610707, area de ponderacao 2610707999002, V0300 = 05154207. O layout do IBGE realmente preve essas tres variaveis em branco para domicilio coletivo — mas os outros 51.326 domicilios coletivos do pais foram todos gravados com as tres posicoes preenchidas de espacos, completando os 170 bytes; so dentro de PE ha 1.533 coletivos com V1111-V1113 em branco gravados com padding. Este e o UNICO registro curto entre os 5.304.710 domicilios do pais, e o unico registro fora do layout em toda a distribuicao (os arquivos de familias tem 118 bytes em 100% dos 5.691.266 registros; os de pessoas variam, mas sempre dentro dos sete comprimentos que o truncamento de brancos finais produz — 369/372/375/378/381/384/390). Impacto pratico nulo para quem usa as macros SAS do IBGE (INFILE ... MISSOVER) ou readr::read_fwf, mas quebra leitor de registro fixo.

**Persiste.** awk medindo length() em todos os 81 arquivos; inspecao campo a campo da linha 134.697 contra as linhas vizinhas; comparacao com "SAS/LE DOMIC.sas" extraido de 1_Documentacao_20170908.zip. HEAD do PE.zip em 12/09/2026: Content-Length 39193536, Last-Modified Fri, 08 Sep 2017 18:44:08 GMT.

### 34. [BAIXA] Todos os arquivos de familias (e o de pessoas de SP) terminam sem quebra de linha final

**Arquivos.** Os 27 FAMI<cod>.TXT (de AC/FAMI12.TXT, 2.173.558 bytes, a SP/FAMI35.TXT, 144.011.158 bytes) e SP/Pes35.txt (1.538.647.536 bytes, data interna 2010-04-28 08:20 — a mais recente de toda a distribuicao).

**Evidência.** Nos 27 arquivos de familias o ultimo byte e um digito de dado, nao 0x0D0A: por exemplo AC/FAMI12.TXT termina em "2313" e SP/FAMI35.TXT em "3683". Nos arquivos de domicilio e de pessoa o padrao e o oposto — todos terminam em 0d0a (com o acrescimo de 0x1A nos dois de MG). A unica excecao entre as pessoas e SP/Pes35.txt, que termina em "0  0" sem CRLF; o registro em si esta integro (369 bytes, um dos comprimentos legais). E precisamente o arquivo com data interna de 2010-04-28, isolada no lote (todos os outros PES sao de 2003), o que sugere que a inconsistencia entrou numa reposicao. Leitores tolerantes nao se incomodam, mas ferramentas que delimitam o ultimo registro pela quebra de linha perdem uma linha por arquivo — 28 registros no total.

**Persiste.** tail -c 4 + xxd nos 81 arquivos; datas internas por unzip -l nos 27 zips; HEAD do SP.zip em 12/09/2026: Content-Length 194504171, Last-Modified Fri, 08 Sep 2017 18:44:46 GMT, igual a copia local.

### 35. [BAIXA] A planilha auxiliar conta um domicilio particular a mais do que a amostra entrega, em uma area de ponderacao do Recife

**Arquivos.** "Arquivos Auxiliares/Lista das Areas de Ponderacao-Brasil.xls" (coluna "Domicilios particulares ocupados na amostra") contra PE/DOM26.txt.

**Evidência.** A coluna soma 5.253.385 no pais. A contagem direta nos 27 arquivos de domicilio dos registros com V0201 (posicao 72) igual a 1 (particular permanente, 5.221.467) ou 2 (particular improvisado, 31.917) da 5.253.384. A diferenca de 1 esta concentrada numa unica area entre as 9.336: 2610707999002, "AED 02" do Recife (tipo 70, usuario), onde a planilha diz 624 e o arquivo entrega 623 (dos 625 domicilios da area: 611 permanentes + 12 improvisados + 2 coletivos). As outras 9.335 areas batem exatamente. E a mesma area de ponderacao que abriga o unico registro truncado do pais (linha 134.697 de PE/DOM26.txt), o que sugere que algo deu errado ao gravar esse trecho do arquivo — mas nao consegui provar a ligacao: nao ha pessoa orfa em PE (todo registro de pessoa casa com um domicilio existente), entao, se um domicilio ocupado sumiu, os moradores dele sumiram junto.

**Persiste.** leitura da planilha com readxl e cruzamento por codigo de area de ponderacao em R/data.table contra contagem por awk sobre os 27 DOM, em 12/09/2026; zip de documentacao e PE.zip conferidos por HEAD no mesmo dia, ambos com Last-Modified de 08/09/2017.

### 36. [BAIXA] O proprio log de atualizacoes esta com texto repetido e frase corrompida

**Arquivos.** 2_Atualizacoes_20170908.txt (482 bytes, ISO-8859-1, CRLF, LM 08/09/2017 18:43:23 GMT).

**Evidência.** O arquivo tem 4 linhas. A frase "Foi identificado que a variavel V0300 nao estava no arquivo de domicilio." aparece duas vezes: solta logo apos a entrada de 09/03/2016 e de novo como a entrada de 08/09/2017, palavra por palavra. A entrada de 09/03/2016 esta gramaticalmente quebrada: "Foi identificado que que os arquivos de atividade e ocupacao necessitavam incompletos e que era necessario incluir novos codigos na documentacao que compatibiliza os codigos de 2000 e 1991." — com "que que" e com "necessitavam incompletos", que nao forma sentido. Alem disso o log nao registra nenhum dos defeitos de empacotamento verificados acima (duplicata da PB em RN.zip, zip aninhado na BA, 0x1A em MG, inconsistencia de nomes).

**Persiste.** curl do arquivo e leitura em CP1252 em 12/09/2026; HEAD confirma Content-Length 482 e Last-Modified Fri, 08 Sep 2017 18:43:23 GMT.


## 2010 — agregados por setor

### 37. [ALTA] Pessoa02 de SP_Capital e SP_Exceto_Capital com a numeração das 170 variáveis deslocada em +85, contrariando o dicionário oficial do próprio IBGE

**Arquivos.** SP_Capital_20260615.zip (175.587.279 bytes, Last-Modified 2026-06-15 11:41 GMT) → 'Base informaçoes setores2010 universo SP_Capital/EXCEL/pessoa02_sp1.xls' (45.099.520 bytes, data interna 2013-07-16, CRC32 58C7EC84) e '.../CSV/pessoa02_sp1.csv' (13.249.586 bytes, data interna 2026-06-15, CRC32 61FFEE9F). SP_Exceto_Capital_20260615.zip (461.345.153 bytes, Last-Modified 2026-06-15 11:45 GMT) → '.../EXCEL/pessoa02_sp2.xls' (117.155.328 bytes, 2013-07-16, CRC32 651F0276) e '.../CSV/pessoa02_sp2.csv' (34.473.156 bytes, 2026-06-15, CRC32 5F83489E). Referência canônica: Pessoa02_AC.xls (1.001.472 bytes, CRC32 FA25DD6F).

**Evidência.** Cabeçalho dos CSV atuais (15/06/2026): 172 colunas = Cod_setor + Situacao_setor + 170 colunas V contíguas de V086 a V255; zero colunas na faixa V001–V085. Idêntico nos XLS atuais: leitura direta de pessoa02_sp1.xls e pessoa02_sp2.xls devolve ncol=172, nV=170, V086..V255, enquanto Pessoa02_AC.xls devolve V001..V170. Varredura das 28 publicações (cabeçalho do Pessoa02 de cada uma, baixado do lote atual): 26 trazem V001–V170; só SP1 e SP2 trazem V086–V255. Prova aritmética refeita sobre os CSV de 15/06/2026, usando a identidade Pessoa01_Vi = Pessoa02_homens_i + Pessoa02_mulheres_i: no controle AC (874 setores) 85 de 85 identidades fecham com diferença EXATAMENTE zero usando os índices i e i+85; em SP_Capital (876 setores da amostra lida) 84 de 85 fecham com diferença exatamente zero usando os índices i+85 e i+170 (única exceção i=85, diferença 11 em 7.352, compatível com censura 'X'); sob a leitura ingênua (i e i+85) 0 de 85 fecham, porque as colunas V001–V085 simplesmente não existem no arquivo. O deslocamento é exclusivo do Pessoa02: comparando as 26 tabelas de SP1 e SP2 com as de AC no lote atual, as outras 25 têm faixa de V idêntica (domicilio01 V001–V241, pessoa03 V001–V251, entorno05 V843–V1062 etc.); só pessoa02 aparece como (170, 86, 255) contra (170, 1, 170). Contradição documental: o dicionário oficial distribuído pelo próprio IBGE ('BASE DE INFORMAÇÕES POR SETOR CENSITÁ

**Persiste.** Índice do FTP em https://ftp.ibge.gov.br/Censos/Censo_Demografico_2010/Resultados_do_Universo/Agregados_por_Setores_Censitarios/ (lido em 12/09/2026): as 28 publicações estão datadas de 2026-06-15. Leitura do diretório central dos zips remotos por HTTP Range (sem baixar os arquivos inteiros) e inflação parcial dos membros CSV para ler o cabeçalho e as primeiras centenas de linhas. Os XLS atuais foram identificados por CRC32 e tamanho no diretório central remoto e conferidos contra as cópias locais em data_raw/tracts/2010/: CRC32 idêntico, logo são os mesmos bytes que li com readxl. O log 1_Atualizacoes_20260615.txt não menciona SP nem Pessoa02 em nenhuma das suas 14 entradas.

### 38. [MÉDIA] Domicilio01 do Rio Grande do Sul é o único arquivo .xlsx de todo o lote; os outros 727 arquivos Excel são .xls

**Arquivos.** RS_20260615.zip (137.504.353 bytes, Last-Modified 2026-06-15 11:37 GMT) → 'Base informaçoes setores2010 universo RS/EXCEL/Domicilio01_RS.xlsx', 21.367.859 bytes descompactados, data interna 2024-12-11 12:41, CRC32 19AF9AC8. Os outros 25 arquivos da mesma pasta EXCEL/ são .xls ou .XLS com datas internas entre 2011-11-03 e 2013-07-16.

**Evidência.** Contagem de extensões nas 28 publicações do lote atual (diretório central de cada zip): 728 .csv, 509 .xls, 218 .XLS e 1 .xlsx. O único .xlsx é o Domicilio01_RS. Dentro da própria pasta EXCEL/ do RS convivem 4 arquivos .XLS, 21 .xls e 1 .xlsx. Consequência documentada: qualquer descoberta de arquivos que procure o padrão dominante '.xls' não encontra a tabela Domicilio01 do RS — foi exatamente o que ocorreu na versão v0.5.0 do pacote censobr, onde as 22.332 linhas do RS receberam, no lugar de Domicilio01, o conteúdo de Pessoa11 (134 colunas coincidentes bit a bit, 107 colunas em branco), com domicilio01_V001 valendo 5.205.057 em vez de 3.653.000. O log do IBGE de 11/12/2024 explica a origem ('Um novo arquivo foi gerado a partir do arquivo no formato CSV'), mas não registra a mudança de extensão.

**Persiste.** Diretório central do RS_20260615.zip lido por HTTP Range em 12/09/2026, com listagem completa dos 55 membros. Contagem de extensões feita sobre os diretórios centrais das 28 publicações do lote atual.

### 39. [MÉDIA] Entorno de CE, DF, MG, PE e RS sem as 19 colunas descritivas de geografia que as outras 23 publicações trazem

**Arquivos.** Entorno01_CE.csv, Entorno01_DF.csv, Entorno01_MG.csv, Entorno01_PE.csv, Entorno01_RS.csv (e os respectivos XLS) nos zips CE/DF/MG/PE/RS_20260615.zip. Controle: Entorno01_AC.csv em AC_20260615.zip.

**Evidência.** Cabeçalho do Entorno01 nas 28 publicações do lote atual: 222 colunas em 23 delas e 203 em CE, DF, MG, PE e RS. O número de colunas V é o mesmo nas 28 (201, de V001 a V201) — o que falta são as colunas descritivas. Em AC as não-V são 21: Cod_setor, Setor_Precoleta, Cod_Grandes Regiões, Nome_Grande_Regiao, Cod_UF, Nome_da_UF, Cod_meso, Nome_da_meso, Cod_micro, Nome_da_micro, Cod_RM, Nome_da_RM, Cod_municipio, Nome_do_municipio, Cod_distrito, Nome_do_distrito, Cod_subdistrito, Nome_do_subdistrito, Cod_bairro, Nome_do_bairro, Situacao_setor. Em CE as não-V são 2: Cod_setor e Situacao_setor. Faltam exatamente 19. Alcance: CE 13.276 + DF 4.349 + MG 32.564 + PE 12.379 + RS 22.332 = 84.900 setores, 27,4% do país; 84.900 × 19 = 1.613.100 células descritivas ausentes por tema, e os cinco temas Entorno01–05 são afetados.

**Persiste.** Cabeçalho do Entorno01 de cada uma das 28 publicações do lote 20260615, obtido por HTTP Range sobre o membro CSV dentro do zip remoto, em 12/09/2026. Comparação direta da lista de colunas não-V entre AC (222) e CE (203).

### 40. [MÉDIA] Basico: as 10 colunas decimais V003–V012 são gravadas como texto em 24 publicações e como número em MG, PR, RJ e SP_Exceto_Capital

**Arquivos.** Basico_*.XLS / Basico_*.xls das 28 publicações (todos byte-idênticos aos de 2012, não tocados na republicação de 15/06/2026) e os Basico_*.csv de 15/06/2026. Casos numéricos: Basico_MG.xls (13.747.200 bytes), Basico_PR.XLS (7.391.744), Basico_RJ.xls (11.744.256), Basico_SP2.xls (20.137.472). Casos texto: as outras 24, p.ex. Basico_AC.XLS (512.512) e Basico_RS.XLS (12.288.000).

**Evidência.** Leitura dos 28 XLS com col_types='text': em 24 publicações V003–V012 voltam como texto com vírgula decimal ('3,39'); em MG, PR, RJ e SP_Exceto_Capital voltam como número de ponto flutuante ('2.7799999999999998', '2.8300000000000001', '2.6200000000000001', '2.04'). O padrão é homogêneo dentro de cada arquivo: as 10 colunas decimais têm sempre o mesmo tipo. Divisão: 184.589 setores nas 24 publicações de texto, 125.531 nas 4 numéricas. A republicação de 15/06/2026 propagou a mesma divisão para os CSV: em 24 publicações V003–V012 saem entre aspas ('"3,39"' em AC, '"3,32"' em RS) e nas mesmas 4 saem sem aspas ('2,78' em MG, '2,83' em PR, '2,62' em RJ, '2,04' em SP2) — correspondência perfeita, 23 texto/aspas + 4 número/sem-aspas + 1 (DF) indeterminado só porque a primeira linha de dados tem V003 vazio. Consequência observada: é exatamente esta linha de fratura que produziu, na v0.5.0 do censobr, a perda de 1.800.306 valores decimais nas colunas V003–V012 — escaparam MG, RJ, PR e SP_Exceto_Capital, e SP_Capital (que é texto) quebrou. Nota importante para a carta: o VALOR está correto nos dois formatos; o defeito é a inconsistência de tipo entre arquivos da mesma tabela.

**Persiste.** Extração do Basico de cada um dos 28 zips locais e leitura com readxl::read_excel(col_types='text') em 12/09/2026. Os XLS locais foram provados byte-idênticos aos do lote atual: comparação de CRC32 membro a membro entre ES_20231030/RS_20241211/SP_Capital_20231030/SP_Exceto_Capital_20231030/GO_20250915 e os respectivos *_20260615.zip devolveu 26 de 26 XLS idênticos em cada um dos 5 estados (130/130), com todos os 26 CSV de cada um alterados. O lado CSV foi conferido diretamente no lote atual, por HTTP Range, nas 28 publicações.

### 41. [BAIXA] O log de atualização dos setores de 2010 registra uma data impossível: 15/19/2025

**Arquivos.** https://ftp.ibge.gov.br/Censos/Censo_Demografico_2010/Resultados_do_Universo/Agregados_por_Setores_Censitarios/1_Atualizacoes_20260615.txt — 2.598 bytes, Last-Modified Mon, 15 Jun 2026 11:55:33 GMT, MD5 b8ee8516c0fe6fb04626064ae232ab03, linha 7

**Evidência.** A linha 7 do arquivo é literalmente '15/19/2025' — mês 19. A entrada que a segue é a do Pessoa02 de Goiás ('as colunas referêntes às variáveis de V001 a V099 foram nomeadas omitindo um 0'), e o zip correspondente publicado pelo IBGE chamava-se GO_20250915.zip: a data correta é 15/09/2025. Como o log é o único registro público dessas correções, a data errada quebra a ordem cronológica do próprio documento (a entrada aparece entre 15/06/2026 e 11/12/2024). O mesmo arquivo tem ainda a grafia 'referêntes' e 'As colunas forma renomeadas'.

**Persiste.** download e leitura integral do log em 12/09/2026; cotejo com o nome do zip GO_20250915.zip preservado em data_raw/tracts/2010/ e com a listagem histórica do diretório

### 42. [BAIXA] Grafia irregular de nomes e extensões dentro do mesmo lote: .XLS e .xls misturados na mesma pasta, e nomes em minúsculas só em São Paulo

**Arquivos.** Todo o lote 20260615. Exemplos: AC_20260615.zip tem 10 arquivos .XLS e 16 .xls na mesma pasta EXCEL/; SP_Capital_20260615.zip usa 'pessoa01_sp1.xls', 'pessoa02_sp1.xls' (minúsculas) enquanto AC usa 'Pessoa01_AC.XLS', 'Pessoa02_AC.xls'.

**Evidência.** Nas 28 publicações: 509 arquivos com extensão .xls, 218 com .XLS, 1 com .xlsx, 728 com .csv. A mistura ocorre dentro da mesma pasta do mesmo estado (AC 10+16, BA 4+22, MG 23+3, RS 4+21+1). Quanto ao nome-base: 1.398 arquivos capitalizados, 56 inteiramente minúsculos — e os 56 estão exclusivamente em SP_Capital (30) e SP_Exceto_Capital (28). Em sistema de arquivos sensível a maiúsculas (Linux, servidores), um padrão como 'Pessoa02_*.xls' encontra 26 publicações e perde silenciosamente as duas de São Paulo.

**Persiste.** Contagem sobre os diretórios centrais dos 28 zips do lote 20260615, lidos por HTTP Range em 12/09/2026.

### 43. [BAIXA] A documentação não foi atualizada em nenhuma das três correções: continua a de 30/10/2023, com conteúdo de 2011-2012

**Arquivos.** Documentacao_Agregado_dos_Setores_2010_20231030.zip, 33 MB, Last-Modified 2023-10-30 17:16 — único arquivo do diretório que não foi republicado em 15/06/2026. Conteúdo: 'BASE DE INFORMAÇÕES POR SETOR CENSITÁRIO Censo 2010 - Universo novo.pdf' (753.731 bytes, data interna 2012-11-08) e 28 planilhas Descrição_UF.xls de 2011.

**Evidência.** O diretório do FTP tem 30 itens: 1 log, 28 zips de UF datados de 2026-06-15, e o zip de documentação datado de 2023-10-30. O dicionário continua descrevendo Pessoa02 como V001–V170 para todas as UFs (seção 6.7, 170 rótulos, nenhum acima de V170), sem ressalva para SP; não descreve a exceção de formato do Domicilio01_RS.xlsx; não menciona a ausência das colunas descritivas do Entorno em CE/DF/MG/PE/RS. Detalhe adicional do log: a entrada da correção de Goiás está datada '15/19/2025' — mês 19, data inexistente; pelo contexto e pela data interna dos arquivos, é 15/09/2025.

**Persiste.** Índice do FTP lido em 12/09/2026 (datas e tamanhos da listagem Apache); extração do PDF do zip local de documentação e conversão para texto com pdftools (201 páginas), com busca dos rótulos da seção 6.7; leitura integral de 1_Atualizacoes_20260615.txt (2.598 bytes).


## 2010 — microdados

### 44. [MÉDIA] Idades demograficamente impossíveis (115 a 139 anos) no registro de pessoas, sem crítica nem imputação

**Arquivos.** Amostra_Pessoas_*.txt nos 28 zips (AC.zip … TO.zip, todos Last-Modified 17/08/2016). Variáveis V6036 (pos. 62-64), V6033 (59-61), M6033 (442), V6040 (67). MD5 conferidos, ex.: RR.zip fed3a617e831b51071a9fcd79cd89c27, AC.zip 32b43b989ca33d91e68f901416bec0c3

**Evidência.** Varredura completa dos 20.635.472 registros de pessoa. Cauda etária: 100+ = 2.695 registros / 22.674 pessoas expandidas (compatível com os 23.760 do universo); 110+ = 141 registros / 1.326 pessoas; 115+ = 75 registros / 790 pessoas; 120+ = 61 registros / 635 pessoas. A distribuição acima de 110 anos NÃO decresce: 118 anos = 1 registro, 119 = 2, mas 120 = 7, 122 = 6, 128 = 7, 130 = 3, 132 = 3, 135 = 2, 138 = 1, 139 = 1. Há mais gente declarada com 128 anos (7) do que com 114 (4) ou 118 (1) — impossível como curva de sobrevivência e típico de erro de século no ano de nascimento (1882→1982 = 128 anos; 1890→1990 = 120; 1880→1980 = 130). Agravante: M6033 = 2 (NÃO imputado) em 100% dos 75 registros de 115+, e V6040 = 1 (idade calculada a partir de DATA de nascimento declarada) em 68 dos 75 — ou seja, o IBGE tinha a data completa e não aplicou nenhum limite superior. Máximos por UF: ES 139, SP2-RM 138, TO 134, MG 133, RS 133, BA 132, RJ 132, SC 132, PE 131, CE 130, GO 130, SP1 130. Exemplos individuais: uf=32 mun=05002 idade=139 V6040=1 M6033=2 peso=11,177; uf=35 mun=50308 idade=138 V6040=1 M6033=2 peso=22,925; uf=31 mun=06200 idade=133 peso=21,055. O próprio layout admite até 140 anos, mas o recordista mundial verificado tem 122 e o brasileiro em 2010 tinha ~114.

**Persiste.** Os 28 zips do FTP (https://ftp.ibge.gov.br/Censos/Censo_Demografico_2010/Resultados_Gerais_da_Amostra/Microdados/) têm Last-Modified: Wed, 17 Aug 2016 e Content-Length idêntico à cópia local; MD5 de RR.zip e AC.zip rebaixados do FTP == MD5 local. O único log (1_Atualizacoes_20160311.txt) não menciona idade. Além disso, a mesma cauda aparece idêntica no parquet publicado em censobr v0.5.0 (141 registros 110+, 1.326 pessoas), o que exclui artefato de leitura.

### 45. [MÉDIA] V5110 e V5120 sem códigos numéricos no layout e completamente ausentes do dicionário de variáveis

**Arquivos.** Documentacao.zip (FTP Last-Modified 13/03/2018, 10.711.779 bytes) → Documentação/Layout/Layout_microdados_Amostra.xls, planilha PESS; e Documentação/Layout/Descrição das variáveis - Microdados da amostra do Censo Demográfico 2010.doc e .pdf (ambos 02/03/2018). Dados: Amostra_Pessoas_*.txt, posições 432 (V5110) e 433 (V5120).

**Evidência.** Percorri as 358 variáveis das 4 planilhas do layout separando as linhas de categoria que começam por dígito. V5110 e V5120 são as ÚNICAS duas variáveis de todo o layout cuja lista de categorias vem sem código: aparece literalmente 'CONDIÇÃO DE CONTRIBUIÇÃO PARA INSTITUTO DE PREVIDÊNCIA OFICIAL NO TRABALHO PRINCIPAL / Contribuintes / Não contribuintes / Branco' — sem dizer se Contribuintes é 1 ou 2. Todas as outras 356 variáveis usam o padrão '1- ...', '2- ...'. Pior: 'Descrição das variáveis' (76 páginas, termina em V5100) não contém V5110 nem V5120 em lugar nenhum — grep no .doc dá 0 ocorrências para ambas, contra 1 para V5090, 1 para V5100 e 1 para V5130. Impacto: 9.151.107 registros preenchidos (86.353.839 pessoas expandidas): V5110 [1]=5.064.581 registros / 52.175.610 pessoas, [2]=4.086.526 / 34.178.229; V5120 [1]=5.073.844 / 52.258.388, [2]=4.077.263 / 34.095.451. Tive de deduzir o código cruzando com V0650 (que tem códigos): V0650=1 (contribui no trabalho principal) → V5110=1 e V5120=1; V0650=2 (contribui só em outro trabalho) → V5110=2 e V5120=1 (9.263 registros); V0650=3 (não contribui) → V5110=2 e V5120=2 (3.333.113). Logo 1=Contribuintes e 2=Não contribuintes — mas isso não está escrito em nenhum documento oficial. Quem chutar ao contrário inverte o indicador de cobertura previdenciária de 86 milhões de pessoas.

**Persiste.** O Documentacao.zip no FTP tem hoje Content-Length 10.711.779, exatamente o tamanho da cópia que abri; Last-Modified 13/03/2018 — nenhuma revisão posterior. Nenhum log registra correção de documentação.

### 46. [MÉDIA] Descrição da V1005 contaminada por resíduo de copy/paste ('1- Masculino / 2- Feminino') nas quatro planilhas do layout

**Arquivos.** Documentacao.zip → Documentação/Layout/Layout_microdados_Amostra.xls (125.440 bytes, 03/03/2016), planilhas DOMI, PESS, EMIG e MORT — a célula de descrição da V1005 (última posição de cada registro: 172, 540, 74 e 66).

**Evidência.** Nas quatro planilhas a descrição da V1005 é: 'Situação do setor / 1 - Área urbanizada / 2 - Área não urbanizada / 3 - Área urbanizada isolada / 4 - Área rural de extensão urbana / 5 - Aglomerado rural (povoado) / 6 - Aglomerado rural (núcleo) / 7 - Aglomerado rural (outros) / 8 - Área rural exclusive aglomerado rural / (linha em branco) / 1- Masculino / 2- Feminino'. A cauda 'Masculino/Feminino' é resto do conteúdo anterior da célula, não apagado quando a V1005 foi inserida em 11/03/2016. No registro de DOMICÍLIOS a contaminação é inequívoca, porque esse registro não tem nenhuma variável de sexo. Varredura: na planilha DOMI a V1005 é a única variável cuja descrição contém a palavra 'Masculino'; em PESS há V0601, V0665 e V1005; em EMIG V0303 e V1005; em MORT V0704 e V1005. A versão .ods do mesmo layout (40.138 bytes, 11/03/2016) tem as mesmas 4 ocorrências de V1005.

**Persiste.** Extraído do Documentacao.zip cuja cópia local tem exatamente o Content-Length que o FTP devolve hoje (10.711.779) e Last-Modified 13/03/2018. Os dados da V1005 em si estão corretos (valores 1 a 8 em todas as UFs, nenhum fora do domínio) — o defeito é só na descrição.

### 47. [BAIXA] Idades impossíveis de emigrantes (V0304) e ano de partida igual ao ano de nascimento em partidas pré-1950

**Arquivos.** Amostra_Emigracao_*.txt (28 arquivos, 53.777 registros). Variáveis V0304 (ano de nascimento, pos. 55-58), V0305 (ano da última partida, 59-62), M0304/M0305 (71/72).

**Evidência.** 11 emigrantes com 100 anos ou mais em 31/07/2010, distribuídos de forma impossível: 100 anos = 1, 110 = 2, 113 = 1, 120 = 1, 121 = 2, 127 = 1, 128 = 1, 129 = 2. Há mais emigrantes de 129 anos (2) do que de 100 (1). Os 8 casos de 113+ anos, todos com marcas de imputação 2222 (nada imputado), peso total ≈ 80,6 pessoas: BA mun 15403 nasc 1883 (127 anos, partiu em 2009); GO mun 00159 nasc 1881 (129, partiu 2005); GO mun 19001 nasc 1882 (128, 2008); MG mun 54606 nasc 1897 (113, 2007); SC mun 02404 nasc 1890 (120, 2010); SP2-RM mun 05708 nasc 1881 (129, 2009); SP2-RM mun 50308 nasc 1889 (121, 2009); SP2-RM mun 50308 nasc 1889 (121, 2010). Separadamente, 3 registros com ano de partida anterior a 1950 têm V0305 EXATAMENTE igual a V0304, padrão de campo preenchido com o valor errado: SP1 linha 5140 (nasc 1916 / partida 1916, Portugal), RJ linhas 2266 e 2267 (nasc 1940/partida 1940 e nasc 1946/partida 1946, mesmo domicílio, mesmo país Chile). No total 109 registros têm V0305 == V0304. Nota adicional de incoerência interna: o layout da V0304 admite 1869 a 2010, ou seja, até 141 anos, enquanto para pessoas vivas as variáveis V6033/V6036 são limitadas a 140.

**Persiste.** Mesmos 28 zips com Last-Modified 17/08/2016 e MD5 idêntico ao local; único log de atualização é de 11/03/2016 e trata só da V1005. Os 53.777 registros do bruto aparecem intactos no parquet publicado em censobr v0.5.0 (peso total 560.532,76 nos dois).

### 48. [BAIXA] Registro de mortalidade sem nenhuma informação de idade e sem marca de 'ignorado'

**Arquivos.** SP1.zip → SP1/Amostra_Mortalidade_35_outras.txt, linha 6.843 (de 14.459). Variáveis V7051 (pos. 57-59), V7052 (60-61), M7051 (64), M7052 (65).

**Evidência.** Registro completo: '35269023526902005003031444770095719027930058306027002091     22227'. Município 3526902, mês/ano do óbito = 09 (abril/2010), sexo = 1, peso = 9,5719. V7051 (idade ao falecer em anos) e V7052 (idade em meses) estão AMBOS em branco, e as quatro marcas de imputação valem 2 ('não imputado'). É o único caso entre os 111.555 registros de mortalidade do país. A regra do arquivo é: ou V7051 preenchido (107.657 registros), ou V7051 em branco com V7052 preenchido para menores de 1 ano (3.860), ou V7051=999 'ignorado' com V7052 preenchido (37). Este registro escapou das três situações — o IBGE nem imputou nem marcou como ignorado.

**Persiste.** SP1.zip no FTP: Last-Modified 17/08/2016, Content-Length 136.561.102, idêntico à cópia local. Nenhum log de atualização posterior a 11/03/2016.

### 49. [BAIXA] Arquivo de trava do LibreOffice com usuário e hostname internos do IBGE vazado dentro do Documentacao.zip oficial

**Arquivos.** Documentacao.zip → 'Documentação/Áreas de Ponderação/.~lock.Composição das Áreas de Ponderação.ods#', 108 bytes, datado 06/11/2013 12:50 no zip.

**Evidência.** Conteúdo integral do arquivo: ',IBGE/clessa,CAN00508545.ibge.gov.br,06.11.2013 09:50,file:///C:/Users/clessa/AppData/Roaming/LibreOffice/4;'. É o arquivo de trava que o LibreOffice cria enquanto uma planilha está aberta; ficou dentro do pacote publicado. Expõe o login de domínio do servidor (IBGE/clessa), o nome da estação de trabalho na rede interna (CAN00508545.ibge.gov.br) e o caminho do perfil local. Evidência direta de que o pacote de documentação foi empacotado sem qualquer higienização.

**Persiste.** O Documentacao.zip publicado hoje no FTP tem Content-Length 10.711.779 e Last-Modified 13/03/2018 — exatamente a cópia que abri e onde o arquivo de trava está presente (53 arquivos no zip).

### 50. [BAIXA] Nomes de Unidade da Federação corrompidos no arquivo oficial de contagem de áreas de ponderação

**Arquivos.** Documentacao.zip → 'Documentação/Áreas de Ponderação/Número de Áreas de Ponderação por UF.txt' (928 bytes, 17/04/2012).

**Evidência.** O arquivo lista as 27 UFs com o número de áreas de ponderação. A UF 31 aparece como 'Minas Federais' (em vez de Minas Gerais) — aparentemente contaminação de 'Distrito Federal' — e a UF 53 aparece como 'Brasília' (em vez de Distrito Federal). As demais 25 estão corretas. Os números em si estão certos: conferi as 27 contagens contra os microdados (RO 93, AC 31, AM 105, RR 28, PA 292, AP 36, TO 160, MA 321, PI 257, CE 362, RN 226, PB 281, PE 388, AL 151, SE 113, BA 690, MG 1306, ES 192, RJ 538, SP 1879 = 1246 em SP1 + 633 em SP2-RM, PR 655, SC 495, RS 826, MS 111, MT 209, GO 388, DF 51; Brasil 10.184) e todas batem exatamente com o número de códigos distintos de V0011 observados nos arquivos de domicílio.

**Persiste.** Arquivo extraído do Documentacao.zip cujo tamanho no FTP (10.711.779) e Last-Modified (13/03/2018) conferem com a cópia local.

### 51. [BAIXA] Layout remete a três arquivos de tabela de códigos que não existem no pacote de documentação

**Arquivos.** Documentacao.zip → Documentação/Layout/Layout_microdados_Amostra.xls, descrições de V6461, V6471 (planilha PESS) e V3061 (planilha EMIG); versus o conteúdo real de Documentação/Anexos Auxiliares/.

**Evidência.** A descrição da V6461 diz: 'A relação de códigos encontra-se no arquivo: “Ocupação COD_Estrutura 2010.xls”'. A da V6471 diz '“CNAEDOM2.0_Estrutura 2010.xls”'. A da V3061 diz '“Migração_Países_2010 V3061 V6224 V6256 V6266 V6366 V6606.xls”'. Nenhum desses três nomes existe entre os 53 arquivos do Documentacao.zip. Os arquivos que de fato existem chamam-se 'Ocupação COD 2010.xls', 'Atividade CNAE_DOM 2.0 2010.xls' e duas variantes de 'Migração e Deslocamento_Paises estrangeiros.xls'. Confirmei que o conteúdo está correto nos arquivos reais (435 códigos de 4 dígitos em COD 2010, 241 classes de 5 dígitos na CNAE-DOM 2.0, 199 países) e que os valores observados nos microdados são todos válidos — o problema é exclusivamente a referência quebrada, que obriga o usuário a adivinhar qual planilha usar.

**Persiste.** Listagem completa do Documentacao.zip publicado hoje (Content-Length 10.711.779, Last-Modified 13/03/2018): 53 arquivos, nenhum com os nomes citados no layout.

### 52. [BAIXA] Duas cópias concorrentes da tabela de países no mesmo pacote, com nomes que diferem só por acento e caixa

**Arquivos.** Documentacao.zip → Documentação/Anexos Auxiliares/: 'Migração e Deslocamento_Paises estrangeiros.xls' (41.472 bytes, 16/10/2012) e 'Migração e deslocamento_Países estrangeiros.xls' (29.696 bytes, 27/06/2012); idem para os dois .ods correspondentes (8.042 bytes 16/10/2012 e 19.816 bytes 28/06/2012).

**Evidência.** Os dois .xls têm a mesma planilha ('País estrangeiro'), a mesma dimensão (220x3) e a mesma lista de 199 países com código de 7 dígitos. A única diferença de conteúdo está na acentuação dos nomes de continente: um traz AFRICA/AMERICA/ASIA e o outro ÁFRICA/AMÉRICA/ÁSIA. Nada no pacote indica qual é a versão vigente, e os dois nomes de arquivo diferem apenas por 'Deslocamento' vs 'deslocamento' e 'Paises' vs 'Países' — em sistemas de arquivos case-insensitive ou com normalização Unicode diferente eles colidem. O mesmo par duplicado existe em .ods. Os códigos em si estão íntegros: os 151 códigos de país observados nos 53.777 registros de emigração estão todos na tabela (0 fora).

**Persiste.** Ambos os arquivos estão no Documentacao.zip publicado hoje no FTP (Content-Length 10.711.779, Last-Modified 13/03/2018).

### 53. [BAIXA] Revisão de 2018 da documentação não registrada em nenhum log de atualização

**Arquivos.** 1_Atualizacoes_20160311.txt (121 bytes) e Documentacao.zip (10.711.779 bytes, Last-Modified 13/03/2018), ambos em /Censos/Censo_Demografico_2010/Resultados_Gerais_da_Amostra/Microdados/.

**Evidência.** O único arquivo de log da pasta é 1_Atualizacoes_20160311.txt, com uma única linha: '11/03/2016 - a variável v1005 - SITUAÇÃO DO SETOR foi incluída nos arquivos de DOMICÍLIO, PESSOA, EMIGRAÇÃO e MORTALIDADE'. Mas o Documentacao.zip tem Last-Modified 13/03/2018 no FTP e, internamente, 'Descrição das variáveis - Microdados da amostra do Censo Demográfico 2010' (.doc 308.224 bytes e .pdf 1.260.281 bytes) gravados em 02/03/2018, e os diretórios do zip datados de 13/03/2018. Portanto houve uma revisão do dicionário de variáveis dois anos depois do último registro de log, sem nenhuma anotação — não há errata, não há segunda linha no arquivo de atualizações, e o nome do log continua congelado em 20160311. Um usuário que baixou a documentação entre 2016 e 2018 não tem como saber que existe versão nova nem o que mudou.

**Persiste.** curl -sI nos dois arquivos e listagem HTML da pasta em 12/09/2026: a pasta contém apenas 1_Atualizacoes_20160311.txt, os 28 zips de UF e Documentacao.zip. Varri também /Censos/Censo_Demografico_2010/ e todas as subpastas de Resultados_Gerais_da_Amostra procurando por atualiz|errata|leia|readme|nota|correc — só existem errata_deslocamento.pdf e errata_migracao.pdf, que tratam do texto da publicação, não dos microdados.

### 54. [BAIXA] Incoerência de nomenclatura entre o nome do zip de São Paulo e a pasta que ele contém

**Arquivos.** SP2_RM.zip (66.923.314 bytes) contém o diretório 'SP2-RM/' com Amostra_Domicilios_35_RMSP.txt etc.; SP1.zip contém 'SP1/' com sufixo '_35_outras'.

**Evidência.** Todos os 27 demais zips têm nome de arquivo igual ao nome do diretório interno (AC.zip → AC/, RR.zip → RR/). Só São Paulo foge: o zip chama-se SP2_RM.zip (underscore) e a pasta interna chama-se SP2-RM (hífen). Também é a única UF em que o nome do arquivo interno não segue o padrão 'Amostra_<registro>_<codUF>.txt', usando sufixos livres '_35_RMSP' e '_35_outras'. Isso quebra qualquer rotina de descompactação que derive o caminho a partir do nome do zip. A divisão em si está correta: SP1 tem 606 municípios (RM 00, 21 e 22) e SP2-RM tem 39 (RM 20), interseção vazia de municípios e de áreas de ponderação, somando os 645 municípios e as 1.879 áreas oficiais de SP.

**Persiste.** unzip -l nos 28 zips locais, cujos tamanhos e datas conferem com o FTP (SP2_RM.zip: Last-Modified 17/08/2016, Content-Length 66.923.314).


## 2022

### 55. [ALTA] Agregados por setor 2022 — o pacote 'xlsx' de características do domicílio 2 e 3 contém um CSV, e a versão .xlsx corrigida não existe

**Arquivos.** https://ftp.ibge.gov.br/Censos/Censo_Demografico_2022/Agregados_por_Setores_Censitarios/Agregados_por_Setor_xlsx/Agregados_por_setores_caracteristicas_domicilio2_BR_20250417.zip — 83.971.374 bytes, Last-Modified Thu, 17 Apr 2025 13:18:56 GMT. E .../Agregados_por_setores_caracteristicas_domicilio3_BR_20250417.zip — 52.708.037 bytes, 17/04/2025

**Evidência.** O zip de domicilio2 na pasta XLSX contém um único membro: 'Agregados_por_setores_caracteristicas_domicilio2_BR_20250417.csv', 783.600.353 bytes, CRC32 E8170E34, data interna 2025-04-14. O zip homônimo da pasta CSV (Agregados_por_Setor_csv/, 17/04/2025 12:52:59) contém o MESMO membro com o MESMO CRC32 E8170E34 e o mesmo tamanho — são o mesmo arquivo publicado duas vezes, uma delas na pasta errada. Idem domicilio3: membro 'Agregados_por_setores_caracteristicas_domicilio3_BR_20250417.csv', 305.046.391 bytes, CRC 2657561B. O XLSX verdadeiro só existe na versão SUPERADA de 12/11/2024 ('Agregados_por_setores_caracteristicas_domicilio2_BR.zip', 636.887.807 bytes, contendo 'Agregados_por_setores_caracteristicas_domicilio2_BR.xlsx' de 680.893.795 bytes, CRC A44442CD), que continua baixável na mesma pasta, sem nenhuma marca de estar obsoleta e sem log que explique a substituição. O problema é específico do nível setor: Agregados_por_Bairro_xlsx e Agregados_por_Municipio_xlsx trazem .xlsx corretos ('Agregados_por_bairros_caracteristicas_domicilio2_BR.xlsx', 27.857.044 bytes; 'Agregados_por_municipios_caracteristicas_domicilio2_BR.xlsx', 10.428.087 bytes), e o basico_BR_20260520 da pasta de setor também traz .xlsx (75.717.980 bytes).

**Persiste.** central directory dos zips remotos lido por HTTP Range (nome, tamanho descomprimido e CRC32 de cada membro), em 12/09/2026; HEAD para Last-Modified e Content-Length

### 56. [ALTA] V0006 do Básico troca de escala entre o preliminar e o definitivo mantendo o mesmo rótulo (proporção 0–1 apresentada como "Percentual")

**Arquivos.** Agregados_por_setores_basico_BR_20260520.zip (FTP 2026-05-20 10:37, 15 MB, MD5 local b7cde7107a14d82df0296dbb80141661) -> Agregados_por_setores_basico_BR.csv (140.970.380 bytes, 468.099 linhas, 38 colunas); dicionario_de_dados_agregados_por_setores_censitarios_20260520.xlsx (2026-05-12 18:29, 116 KB, MD5 18c6893f7f00be66900af9661ba7c90a); Agregados_preliminares_por_setores_censitarios_BR.zip (2024-03-21 08:55, 13 MB) e Dicionario_de_dados_agregados_preliminares.xlsx

**Evidência.** Preliminar (03/2024): v0006 varia de 0 a 100, média 4,235, com 271.542 dos 452.340 setores acima de 1. Definitivo (tanto 20250417 quanto 20260520): V0006 varia de 0 a 4,2542, média 0,042189, com apenas 11 dos 468.099 setores acima de 1. Razão das médias = 100,39. Os dois dicionários trazem a MESMA descrição: "Percentual de Domicílios Particulares Ocupados Imputados (Total DPO imputados / Total DPO)". Prova cruzada de que o definitivo é proporção: sum(V0006*V0007) = 3.080.906 domicílios imputados, contra sum(v0006/100*v0007) = 3.076.899 no preliminar, com correlação municipal de 1,00000 entre as duas estimativas; a taxa nacional resultante é 4,248% (compatível com o que o IBGE divulgou sobre imputação em 2022). Lido como percentual, o definitivo daria 0,04248% de imputação — 30.809 domicílios em vez de 3,08 milhões. Distribuição do definitivo: mediana 0,0193; p90 0,1092; p99 0,3365; 149.423 setores com valor exatamente 0.

**Persiste.** Baixei o dicionário atual de https://ftp.ibge.gov.br/Censos/Censo_Demografico_2022/Agregados_por_Setores_Censitarios/dicionario_de_dados_agregados_por_setores_censitarios_20260520.xlsx e o pacote preliminar de https://ftp.ibge.gov.br/Censos/Censo_Demografico_2022/Agregados_por_Setores_Censitarios_preliminares/agregados_por_setores_csv/BR/ em 2026-09-12; comparei as distribuições no CSV bruto do definitivo (data_raw/tracts/2022/csv) e no CSV preliminar, e reconstruí a contagem de imputados por município nos dois.

### 57. [MÉDIA] Microdados 2022 — o banco de descritores de Atividade grava como número os 55 códigos que começam com zero

**Arquivos.** https://ftp.ibge.gov.br/Censos/Censo_Demografico_2022/Microdados_e_Areas_de_Ponderacao/Documentacao/Bancos%20de%20descritores/Codifica%c3%a7%c3%a3o_Atividade%20CD2022.xlsx — 24.659 bytes, Last-Modified Thu, 16 Oct 2025 19:12:41 GMT, MD5 a3e7c1e75a756bdbf879bd7280700064. Par .ods: 16.298 bytes, Last-Modified Tue, 18 Aug 2026 00:05:08 GMT, MD5 cb7a3e844d60b788131a7ab76f2487e5

**Evidência.** Das 357 linhas do banco, 55 têm código iniciado por zero. No XLSX nenhuma delas preserva o zero: em xl/worksheets/sheet1.xml a célula é '<c r="C5" s="7"><v>1101</v></c>' — valor numérico, sem t="s", com máscara de exibição numFmt 164='00000' (e 165='00' para os códigos de 2 dígitos). A planilha mostra 01101 na tela, mas qualquer leitura programática (readxl, arrow, pandas) devolve 1101, que não casa com o código de atividade do microdado. Contagem: códigos com zero à esquerda = 55 no .ods contra 0 no .xlsx; 55 das 357 linhas divergem na primeira coluna (01→1, 01101→1101, 01105→1105, 08999→8999, 00→0). No .ods o valor subjacente também é float (office:value-type="float" office:value="1101"), mas o texto renderizado '01101' está gravado no <text:p>, de onde um leitor de ODS o recupera. Os outros quatro bancos de descritores não têm o problema: Ocupação (641 linhas, 21 códigos com zero à esquerda nos dois formatos, 0 divergências), País (202 linhas, 0 divergências), Município (5.574 linhas, 0) e Ensino Superior (122 linhas, 0).

**Persiste.** download dos dez arquivos (.ods e .xlsx) dos cinco bancos de descritores em 12/09/2026 e comparação célula a célula via leitura direta de content.xml (ODS) e sharedStrings.xml + sheet1.xml (XLSX); inspeção de xl/styles.xml para confirmar a máscara 00000

### 58. [MÉDIA] 11 setores com V0006 > 1 — mais domicílios imputados do que domicílios existentes

**Arquivos.** Agregados_por_setores_basico_BR.csv (do zip 20260520) e a versão anterior (20250417), colunas V0006 e V0007

**Evidência.** Conferido no CSV bruto do IBGE, linha a linha. Os 11: 150276405000050 Cumaru do Norte/PA V0006=4,2542 com V0007=59 DPO e V0002=181 domicílios no total (251 imputados); 510420305000020 Guiratinga/MT 3,8718 com 39 DPO; 520870705330075 Goiânia/GO 3,6140 com 171 DPO; 510760230000045 Rondonópolis/MT 3,5568 com 88 DPO; 354340210000122 Ribeirão Preto/SP 2,0000 com 11 DPO; 420910205000463 Joinville/SC 1,8837 com 86; 430660105100006 Dom Pedrito/RS 1,7714 com 35; 510620810000003 Nova Brasilândia/MT 1,4615 com 13; 410490705000149 Castro/PR 1,4000 com 5; 260545905000005 Fernando de Noronha/PE 1,3825 com 183; 310620005680362 Belo Horizonte/MG 1,2340 com 47. Em Cumaru do Norte o número implícito de imputados (251) supera até o total de domicílios do setor (181). Esses 11 setores respondem pela diferença de 4.007 domicílios imputados entre a contagem derivada do preliminar e a do definitivo.

**Persiste.** grep direto no CSV do zip 20260520 baixado em 2026-09-12 (linhas 25336, 106325, 319861, 444329, 447752, 455417 e outras) confirmando os valores "4,2542", "3,8718", "3,6140", "3,5568", "2,0000", "1,3825"; e comparação com o parquet construído a partir do zip 20250417 (data/tracts/2022/2022_tracts_Basico.parquet, de 04/05/2026), onde os MESMOS 11 setores com os MESMOS valores aparecem — a republicação de 20/05/2026 não os tocou.

### 59. [MÉDIA] MP0411: coluna órfã (marca de imputação de uma variável que não é distribuída) e cópia byte a byte de MP0410

**Arquivos.** Layout Microdados CD2022 - acesso Público.xlsx (FTP Last-Modified 2026-08-28 16:47, 36 KB, MD5 2c48525b2a2bcb8ec1fa87efdc3513d4), aba PESS, posição 201; e as 27 Pessoas_<UF>_publico.csv (ex.: 14_RR.zip MD5 cade737322c1c251f7949717fb87a91c)

**Evidência.** O layout público declara MP0411 = "MARCA DE IMPUTAÇÃO NA P0411", mas P0411 (religião ou culto detalhada) não existe no arquivo público — é variável exclusiva do acesso controlado. O layout tem 168 variáveis e os 27 CSVs têm exatamente as mesmas 168, na mesma ordem, e P0411 não está entre elas. Pior: MP0411 é IDÊNTICA a MP0410 nos 21.538.508 registros (identical() TRUE, 0 registros divergentes). As duas têm a mesma distribuição: 0 em 17.815.935, 1 em 814.332, 9 em 2.908.241, e ambas se alinham com P0410 no mesmo cruzamento. É uma coluna redundante que ocupa a posição 201 do arquivo de largura fixa.

**Persiste.** Layout baixado do FTP em 2026-09-12 (Documentacao/Layout e dicionário/); cabeçalho dos 27 CSVs comparado ao layout variável a variável; identidade MP0410 == MP0411 testada no parquet nacional de 21.538.508 linhas.

### 60. [MÉDIA] Código 9 presente nos dados e não declarado no layout em três marcas de imputação (MP1010, MF0190, MF0200)

**Arquivos.** Layout Microdados CD2022 - acesso Público.xlsx, abas PESS e FAMI; Pessoas_<UF>_publico.csv e Familia_<UF>_publico.csv das 27 UFs

**Evidência.** MP1010 declara apenas "0 - Não Imputado / 1 - Imputado", mas 18.787.092 registros (87,23% dos 21.538.508) trazem o valor 9 — e esses 18.787.092 são exatamente os registros em que P1010 está em branco, ou seja, 9 é "não aplicável". MF0190 e MF0200 declaram 0/1 e trazem 9 em 382.281 registros cada (5,84% dos 6.550.107). No mesmo layout, 21 outras marcas (MD0190, MD0210, MD0220, MD0230…, MP0410, MP0411) declaram explicitamente "9 - Não aplicável" — a omissão é interna e inconsistente. Bônus no mesmo bloco: o rótulo de MF0190 está grafado "MARCA DE IMPUTAÇÃO NA F019", faltando um dígito.

**Persiste.** Parser das categorias declaradas em cada rótulo do layout de 28/08/2026 confrontado com os valores observados nos parquets nacionais (265 colunas testadas nas 4 tabelas).

### 61. [MÉDIA] TXT e CSV da mesma UF e tabela não estão alinhados linha a linha

**Arquivos.** txt/14_RR.zip (FTP 2026-08-29 01:05, 3,4 MB, MD5 838e2d33b9ba6f3a9b00f2af308d53f2) x csv/14_RR.zip (MD5 cade737322c1c251f7949717fb87a91c); txt/16_AP.zip x csv/16_AP.zip (MD5 1a5199f2d42f5ff7f38a7c06660ab7eb)

**Evidência.** Roraima/Mortalidade: 1.168 registros nos dois formatos, mas só 956 (81,85%) ocupam a mesma posição; a primeira divergência é na linha 33. Amapá/Domicílios: 18.399 registros, só 14.572 (79,20%) na mesma posição; 3.827 linhas fora de lugar entre as posições 3.758 e 18.394, em 972 blocos contíguos, com deslocamentos de -2 a +5. O conteúdo é o mesmo: ordenando por (Controle, número de ordem), as 14 colunas de RR/Mortalidade e as 55 de AP/Domicílios coincidem em 100% dos registros, inclusive os decimais implícitos (D0240, D0360, peso). Nas demais combinações testadas o alinhamento é perfeito (RR: DOMI 24.133/24.133, PESS 85.928/85.928, FAMI 22.359/22.359; AP: PESS 68.236/68.236, FAMI 18.506/18.506, MORT 1.126/1.126). A causa provável está nos carimbos internos dos zips: TXT e CSV da mesma tabela foram gerados em rodadas distintas com minutos de diferença (RR Domicílios: txt 27/08/2026 11:54, csv 27/08/2026 12:12; RR Mortalidade: txt 24/06/2026 11:10, csv 24/06/2026 13:15).

**Persiste.** Baixei txt/14_RR.zip e txt/16_AP.zip do FTP em 2026-09-12, parseei pelas posições do layout público e comparei coluna a coluna com os CSVs já em data_raw; larguras das linhas (113/253/69/43) batem exatamente com a última posição declarada no layout.

### 62. [BAIXA] F0220 = 5 e F0150 = 11: categorias observadas nos dados e ausentes do layout

**Arquivos.** Familia_<UF>_publico.csv das 27 UFs; Layout Microdados CD2022 - acesso Público.xlsx, aba FAMI

**Evidência.** F0220 "Famílias conviventes secundárias, tipologia" declara 1 a 4 (casal sem filhos / casal com filhos / mulher sem cônjuge com filhos / homem sem cônjuge com filhos) e os dados trazem o valor 5 em 87 registros (223 famílias expandidas), distribuídos em 22 UFs (MT 24, AM 11, PA 12, RR 5, MS 4…), todos em famílias conviventes secundárias (F0150 em 3, 4 ou 5) com 3 a 13 pessoas. A variável paralela F0210, para famílias únicas e principais, tem uma décima categoria "Outro" — provavelmente é o que falta em F0220. F0150 "Família, identificação" declara 01 a 10 (até "Convivente - nona") e há 1 registro com o valor 11: o domicílio 7061191 do Rio de Janeiro, que tem 10 famílias conviventes (F0101 vai de F001 a F010, e o par F0101/F0150 é rigorosamente F001->2, F002->3, …, F010->11 em todo o arquivo).

**Persiste.** Comparação automática entre as categorias extraídas dos rótulos do layout de 28/08/2026 e os valores observados em todas as 265 variáveis das 4 tabelas nos parquets nacionais; inspeção do domicílio 7061191 e dos 87 registros com F0220=5.

### 63. [BAIXA] 13 variáveis com branco frequente sem a categoria "Branco"/"Não aplicável" no layout

**Arquivos.** Layout Microdados CD2022 - acesso Público.xlsx; Pessoas/Domicilios/Familia_<UF>_publico.csv

**Evidência.** Percentual de registros em branco, sem que o rótulo preveja essa possibilidade: P0260 90,314% (19.452.358 de 21.538.508), P1010 87,226%, P0380 71,297%, P1170 67,114%, P1180 66,868%, P1050 60,682%, P1070 58,741%, P1020 58,332%, F0270 30,344% (1.987.584 de 6.550.107), P0410 13,503%, P1090 13,503%, D0170 e D0180 0,988% (75.982 de 7.689.914). A omissão é inconsistente dentro do próprio documento: P0230, D0290, D0320, D0330, F0210, F0220 e outras declaram "Branco" explicitamente. Caso mais visível: P0260 "Pessoa quilombola, categoria" declara só "1 - Sim" e "2 - Não", é a única coluna 100% vazia em alguma UF (Roraima, todos os 85.928 registros) e tem só 3 valores preenchidos no Acre. Isso NÃO é perda de dado — o universo confirma 0 pessoas quilombolas em RR e no AC (Agregados_por_setores_pessoas_quilombolas_BR, pessoas_V03196 = 0 nas duas UFs) —, mas o layout não diz que a variável fica em branco onde a pergunta não se aplica. Os brancos de D0170/D0180 são os 75.982 domicílios coletivos (D0130=6), os mesmos que têm zero pessoa responsável.

**Persiste.** Cruzamento automático rótulo-por-rótulo (busca por "branco" e "não aplicável") contra a contagem de NA nos parquets nacionais; totais quilombolas por UF conferidos no agregado de setor de quilombolas (Brasil 1.317.569 no universo contra 1.324.414 na amostra pública).

### 64. [BAIXA] Dois setores do Rio Grande do Sul sem qualquer geografia no Básico

**Arquivos.** Agregados_por_setores_basico_BR.csv (zip 20260520), linhas 408755 e 408756

**Evidência.** Os setores 430000100000000 e 430000200000000 (Lagoa dos Patos e Lagoa Mirim) trazem "." em SITUACAO, CD_SIT, CD_TIPO, CD_MUN, NM_MUN, CD_DIST, CD_SUBDIST, CD_BAIRRO, CD_NU, CD_FCU, CD_AGLOM, CD_RGINT, CD_RGI e CD_CONCURB — todas as 24 colunas descritivas abaixo da UF —, embora o próprio geocódigo do setor carregue os municípios 4300001 e 4300002, que existem na tabela de municípios do IBGE. Têm área declarada (2.884,34 e 10.201,52 km²) e todas as V zeradas. São os únicos 2 setores dos 468.099 com CD_MUN vazio.

**Persiste.** grep direto nas duas linhas do CSV do zip 20260520 baixado em 2026-09-12; varredura de NA por coluna nos 468.099 setores (CD_MUN: 2 NA; CD_UF e CD_REGIAO: 0 NA).

### 65. [BAIXA] Nome de arquivo com caractere não-ASCII em UTF-8 dentro de um índice servido em ISO-8859-1

**Arquivos.** Agregados_por_setores_entorno_domic%c3%adlios_BR.zip (2025-04-17 10:02, 11 MB), em Agregados_por_Setores_Censitarios_Caracteristicas_urbanisticas_do_entorno_dos_domicilios/Agregados_por_Setor_csv/

**Evidência.** É o único dos 17 zips de agregados por setor de 2022 com caractere acentuado no nome: os bytes 0xC3 0xAD ("í" em UTF-8) aparecem percent-encoded no href, enquanto o índice Apache é servido com charset=iso-8859-1. Seus dois irmãos diretos no mesmo diretório (entorno_faces, entorno_moradores) são ASCII puro. Ao descompactar no Windows o CSV interno vira um nome com caractere não mapeável (U+F0ED, área de uso privado), que o shell e várias bibliotecas não conseguem abrir por nome. O mesmo problema aparece na árvore de diretórios: existe Quilombolas_alfabetizacao_e_caracteristicas_dos_domic%c3%adlios_Resultados_do_universo/.

**Persiste.** Leitura do índice HTML do diretório em 2026-09-12 e HEAD no zip (HTTP 200, Last-Modified Thu, 17 Apr 2025 13:02:39 GMT); inspeção do nome do arquivo extraído em disco via Python (repr mostra ).

### 66. [BAIXA] Diretório de Quilombolas duplicado no FTP, com duas publicações do mesmo produto a três dias de distância

**Arquivos.** Censos/Censo_Demografico_2022/Quilombolas_alfabetizacao_e_caracteristicas_dos_domicilios_Resultados_do_universo/ (2024-07-19 10:00) e Quilombolas_alfabetizacao_e_caracteristicas_dos_domic%c3%adlios_Resultados_do_universo/ (2024-07-22 10:00)

**Evidência.** As duas árvores têm exatamente os mesmos quatro subdiretórios (Apendices, Cartogramas, Tabelas_de_resultados, Tabelas_selecionadas) e os mesmos arquivos de índice com o mesmo tamanho (indice_de_tabelas_de_resultados.txt, 3,9 KB nas duas), diferindo apenas na data (19/07/2024 e 22/07/2024, com o índice da segunda re-datado em 21/08/2024). Nada indica qual é a versão válida, e não há nota explicando a duplicação.

**Persiste.** Listagem dos dois diretórios e de Tabelas_de_resultados em cada um, no FTP, em 2026-09-12.

### 67. [BAIXA] Agregados por setor de 2022 espalhados por três diretórios distintos do FTP

**Arquivos.** Agregados_por_Setores_Censitarios/Agregados_por_Setor_csv/ (13 zips), Agregados_por_Setores_Censitarios_Caracteristicas_urbanisticas_do_entorno_dos_domicilios/Agregados_por_Setor_csv/ (3 zips), Agregados_por_Setores_Censitarios_Rendimento_do_Responsavel/ (1 zip de setor entre 10 de outros recortes)

**Evidência.** Os 17 arquivos que compõem o agregado por setor censitário de 2022 não estão em um lugar só. O diretório que se chama "Agregados_por_Setores_Censitarios" contém 13 deles; os 3 de entorno estão em um diretório irmão; e o de renda do responsável está em um terceiro, misturado com os recortes de bairro, distrito, município e subdistrito, o que impede recuperá-lo por varredura do diretório. Além disso, o dicionário está fragmentado em três: dicionario_de_dados_agregados_por_setores_censitarios_20260520.xlsx (não cobre entorno nem renda), dicionarios_de_dados_entorno.zip e dicionario_de_dados_renda_responsavel_20260508.xlsx.

**Persiste.** Listagem completa dos três diretórios no FTP em 2026-09-12; o código de download deste projeto (R/census_tracts_2022.R) precisa de dois endpoints varridos mais uma URL fixa por causa disso.

### 68. [BAIXA] V0005 (média de moradores) perdeu precisão do preliminar para o definitivo

**Arquivos.** Agregados_preliminares_por_setores_censitarios_BR.csv (2024-03-18) x Agregados_por_setores_basico_BR.csv (zip 20260520)

**Evidência.** No preliminar a média de moradores vem com 6 casas decimais (2.677812, 2.761905, 2.673077…). No definitivo ela vem com exatamente 1 casa decimal em todos os 468.099 setores (as partes fracionárias observadas são só 0,0 a 0,9; zero valores com mais de uma casa). A média por setor é praticamente a mesma (2,7511 no preliminar, 2,7720 no definitivo), então não houve mudança de conceito — só de precisão. Consequência prática: em 13.700 dos 457.500 setores com V0007 > 0 o V0005 publicado difere em mais de 0,05 do que se calcula por V0001/V0007.

**Persiste.** Leitura dos dois CSVs e contagem das casas decimais em 2026-09-12.

### 69. [BAIXA] P0180 = 99 "Ignorado" é indistinguível da supressão de confidencialidade

**Arquivos.** Pessoas_<UF>_publico.csv das 27 UFs; Nota metodológica 03/2026

**Evidência.** Os 19.216 registros com P0180 = 99 ("Ignorado") são exatamente os mesmos 19.216 com P0150 = 9 (sexo "Ignorado") — a interseção é total, nas 27 UFs (AM 1.720, MT 1.708, PA 1.323, AC 1.262, TO 1.227, MA 1.071, RR 1.048 …, ES 301). Ou seja, o código "Ignorado" foi inteiramente consumido pela supressão local descrita na Nota 03/2026, e não restou nenhum caso de ignorado genuíno. O usuário não tem como separar um do outro, e nem o layout nem o rótulo avisam.

**Persiste.** Contagem cruzada nos 21.538.508 registros do parquet nacional da amostra pública construído a partir dos 27 CSVs de 28/08/2026.

---
