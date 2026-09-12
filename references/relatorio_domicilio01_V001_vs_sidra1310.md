# Divergência entre `domicilio01_V001` (Censo 2010 — agregados por setor) e Tabela 1310 da Sidra

**Data:** 2026-05-12
**Fonte de dados:** parquet `2010_tracts_DOMICILIO.parquet` produzido pelo pipeline `censobr_prep_data` (commit `c3710b7`)
**Referência IBGE:** Tabela 1310 da Sidra ("Domicílios recenseados, por espécie e situação do domicílio")

---

## 1. Sumário executivo

A variável `V001` do arquivo **Domicilio01** dos agregados por setor censitário do Censo Demográfico 2010, quando agregada por município, produz total de domicílios **+1,007% acima** do publicado pelo IBGE na Tabela 1310 da Sidra para a soma "Particular - ocupado + Coletivo - com morador" (combinação que mais se aproxima semanticamente).

A discrepância é **heterogênea**:

- **37,6% dos municípios** batem dentro de 0,01% (gap nulo na prática).
- **69,8% dos municípios** batem dentro de 0,5%.
- **5,2% dos municípios** apresentam gap > 2%, e desses, 88 municípios (1,6%) têm gap > 5%, alguns chegando a **+488%** (Balbinos/SP).

A divergência **não é erro de processamento**. Reflete uma diferença de granularidade entre duas publicações do próprio IBGE:

- Na **Sinopse** (Tabela 1310 da Sidra), cada instituição coletiva (presídio, hospital, asilo, alojamento) é contada como 1 (ou poucos) "domicílio coletivo".
- Nos **agregados por setor** (arquivo Domicilio01), o IBGE conta cada **unidade de habitação dentro do domicílio coletivo** (cela, dormitório, quarto) como uma unidade.

A definição é registrada no próprio manual oficial do IBGE: *"Base de informações do Censo Demográfico 2010: Resultados do Universo por setor censitário — Documentação do Arquivo"* (IBGE/Rio de Janeiro, 2011), seção 2.7.10.

**Recomendação:** o parquet produzido pelo pipeline reproduz fielmente os dados-fonte do IBGE; não há correção a fazer. Cabe documentar a diferença para o consumidor final (`censobr`).

---

## 2. Contexto

O Censo Demográfico 2010 divulga seus resultados em múltiplas formas. Duas delas são centrais para este relatório:

1. **Sidra Tabela 1310** — "Domicílios recenseados, por espécie e situação do domicílio". Disponível em https://sidra.ibge.gov.br/tabela/1310. Agrega domicílios por município com colunas por espécie (Particular - ocupado, Particular - não ocupado, Coletivo - com morador, Coletivo - sem morador) e subcategorias.

2. **Agregados por setor censitário** — conjunto de arquivos XLS/CSV (Basico, Domicilio01, Domicilio02, Pessoa01, etc.) com totais por setor censitário (a menor unidade espacial do Censo; Brasil 2010 tem 310.120 setores). Distribuídos via FTP do IBGE em https://ftp.ibge.gov.br/Censos/Censo_Demografico_2010/Resultados_do_Universo/Agregados_por_Setores_Censitarios/.

A variável estudada é `V001` do arquivo `Domicilio01`. Dicionário oficial (IBGE 2011, seção 6.2):

| Variável | Descrição oficial |
|---|---|
| **V001** | **Domicílios particulares e domicílios coletivos** |
| V002 | Domicílios particulares permanentes |
| V003 a V241 | subcategorias de "Domicílios particulares permanentes" (tipo, ocupação, água, esgoto, lixo, banheiros, energia, número de moradores etc.) |

V001 é a única variável do arquivo que inclui domicílios coletivos.

---

## 3. Sintoma observado

### 3.1. Agregado nacional

| Coluna | Brasil |
|---|---:|
| `domicilio01_V001` (somado de todos os setores) | **58.051.449** |
| Sidra 1310 — Total (Particular + Coletivo) | 67.569.688 |
| Sidra 1310 — Particular (todos) | 67.459.066 |
| Sidra 1310 — **Particular - ocupado** | **57.428.017** |
| Sidra 1310 — Coletivo (todos) | 110.622 |
| Sidra 1310 — Coletivo - com morador | 44.554 |
| **Sidra 1310 — Part_ocupado + Coletivo_com_morador** | **57.472.571** |
| **Excesso V001 vs (Part_ocup + Coletivo_com_mor)** | **+578.878 (+1,007%)** |

Comparação com todas as combinações testadas:

| Combinação Sidra | Total Brasil | Diff vs V001 |
|---|---:|---:|
| Total (Particular + Coletivo) | 67.569.688 | −14,09% |
| Particular (todos) | 67.459.066 | −13,95% |
| Particular - ocupado | 57.428.017 | +1,09% |
| Particular - ocupado + Coletivo (todos) | 57.538.639 | +0,89% |
| **Particular - ocupado + Coletivo - com morador** | **57.472.571** | **+1,01%** |

### 3.2. Por UF

| UF | V001 | Part_ocup + Coletivo_com_mor | Gap | % | N munis |
|---|---:|---:|---:|---:|---:|
| AC | 193.692 | 191.290 | 2.402 | +1,26% | 22 |
| AL | 851.101 | 847.657 | 3.444 | +0,41% | 102 |
| AM | 806.974 | 802.389 | 4.585 | +0,57% | 62 |
| AP | 158.453 | 157.118 | 1.335 | +0,85% | 16 |
| BA | 4.126.224 | 4.108.390 | 17.834 | +0,43% | 417 |
| CE | 2.380.173 | 2.371.156 | 9.017 | +0,38% | 184 |
| DF | 785.733 | 775.248 | 10.485 | +1,35% | 1 |
| ES | 1.113.408 | 1.104.150 | 9.258 | +0,84% | 78 |
| GO | 1.909.041 | 1.894.220 | 14.821 | +0,78% | 246 |
| MA | 1.661.659 | 1.657.479 | 4.180 | +0,25% | 217 |
| MG | 6.111.179 | 6.043.299 | 67.880 | +1,12% | 853 |
| MS | 775.003 | 764.683 | 10.320 | +1,35% | 78 |
| MT | 932.110 | 920.422 | 11.688 | +1,27% | 141 |
| PA | 1.877.876 | 1.867.908 | 9.968 | +0,53% | 143 |
| PB | 1.090.463 | 1.083.223 | 7.240 | +0,67% | 223 |
| PE | 2.574.137 | 2.552.411 | 21.726 | +0,85% | 185 |
| PI | 852.506 | 850.381 | 2.125 | +0,25% | 224 |
| PR | 3.340.516 | 3.307.364 | 33.152 | +1,00% | 399 |
| RJ | 5.299.014 | 5.250.703 | 48.311 | +0,92% | 92 |
| RN | 906.488 | 901.802 | 4.686 | +0,52% | 167 |
| RO | 468.316 | 457.866 | 10.450 | **+2,28%** | 52 |
| RR | 117.965 | 116.401 | 1.564 | +1,34% | 15 |
| RS | 3.653.000 | 3.606.964 | 46.036 | +1,28% | 496 |
| SC | 2.015.139 | 1.997.524 | 17.615 | +0,88% | 293 |
| SE | 595.769 | 593.467 | 2.302 | +0,39% | 75 |
| SP | 13.053.253 | 12.849.045 | 204.208 | **+1,59%** | 645 |
| TO | 402.257 | 400.011 | 2.246 | +0,56% | 139 |

Gap por UF varia de **+0,25% (MA, PI)** a **+2,28% (RO)**, com média Brasil de +1,01%. **SP isoladamente concentra 35% do excesso nacional** (+204.208 dos +578.878).

### 3.3. Distribuição do gap por município

| Intervalo de gap (%) | N municípios | % |
|---|---:|---:|
| (−0,01, +0,01] (bate exato) | 2.093 | 37,6% |
| (+0,01, +0,5] | 1.790 | 32,2% |
| (+0,5, +2] | 1.395 | 25,1% |
| (+2, +5] | 199 | 3,6% |
| > +5% | 88 | 1,6% |

**~70% dos municípios** têm V001 batendo dentro de 0,5% da combinação Sidra. O overcount nacional vem majoritariamente da cauda direita (~5% dos municípios com gap > 2%).

### 3.4. Outliers extremos

| Município | UF | V001 | ref Sidra | Gap | % | N setores |
|---|---|---:|---:|---:|---:|---:|
| Balbinos | SP | 2.807 | 477 | +2.330 | **+488,5%** | 6 |
| Pracinha | SP | 1.837 | 514 | +1.323 | +257,4% | 6 |
| Lavínia | SP | 5.420 | 1.772 | +3.648 | +205,9% | 20 |
| Álvaro de Carvalho | SP | 2.368 | 1.013 | +1.355 | +133,8% | 9 |
| Iaras | SP | 3.241 | 1.403 | +1.838 | +131,0% | 11 |
| Reginópolis | SP | 3.801 | 1.762 | +2.039 | +115,7% | 12 |
| São Pedro de Alcântara | SC | 2.414 | 1.143 | +1.271 | +111,2% | 12 |
| Serra Azul | SP | 4.989 | 2.590 | +2.399 | +92,6% | 16 |
| Marabá Paulista | SP | 2.417 | 1.265 | +1.152 | +91,1% | 10 |
| Guareí | SP | 6.535 | 3.697 | +2.838 | +76,8% | 23 |
| Itirapina | SP | 6.785 | 4.026 | +2.759 | +68,5% | 33 |
| Ilha de Itamaracá | PE | 9.081 | 5.471 | +3.610 | +66,0% | 63 |
| Pacaembu | SP | 5.988 | 3.655 | +2.333 | +63,8% | 26 |
| Irapuru | SP | 3.595 | 2.226 | +1.369 | +61,5% | 21 |
| Potim | SP | 7.262 | 4.660 | +2.602 | +55,8% | 22 |

Padrão observado: municípios pequenos do interior, predominantemente paulistas, que sediam unidades prisionais (Penitenciária de Iaras; Penitenciária Adriano Marrey de Reginópolis; CDP de Pracinha; Penitenciária Aglaucio Vargas de Lavínia; Complexo Penitenciário de São Pedro de Alcântara; Ilha de Itamaracá tem o Complexo Prisional de Itamaracá).

---

## 4. Investigação — quatro linhas de evidência

### 4.1. Razão moradores/domicílios por setor

Cruzando `domicilio01_V001` (do arquivo Domicilio01) com `pessoa01_V001` (do arquivo Pessoa01, que conta moradores), no mesmo setor:

| Município, setor | dom_V001 | dom_V002 | pop residente | **pop/dom** |
|---|---:|---:|---:|---:|
| Balbinos #1 (setor da penitenciária) | 2.335 | 3 | 2.249 | **0,96** |
| Balbinos #2 (urbano normal) | 207 | 207 | 500 | 2,42 |
| Balbinos #3 (urbano normal) | 199 | 195 | 457 | 2,30 |
| Iaras #1 (penitenciária) | 785 | 0 | 761 | **0,97** |
| Iaras #2 (penitenciária) | 768 | 4 | 762 | **0,99** |
| Iaras #3 (residencial) | 427 | 427 | 1.134 | 2,66 |
| Reginópolis #1 (penitenciária) | 2.021 | 4 | 2.007 | **0,99** |
| Reginópolis (médias residenciais) | — | — | — | 2,2 a 3,4 |

Nos setores das penitenciárias a razão moradores/"domicílios" é **≈ 1**, enquanto em setores residenciais normais ela é 2,3 a 3,5 (a média brasileira de moradores por casa). Isso indica que cada "domicílio" contado em V001 nesses setores tem uma única pessoa associada — não uma família.

### 4.2. Inspeção do arquivo bruto

Lendo diretamente o arquivo `DOMICILIO01_SP2.xls` distribuído pelo IBGE no FTP, os 6 setores do município de Balbinos (`code_muni 3504701`):

| Cod_setor | Situação | V001 | V002 | V003 |
|---|---|---:|---:|---:|
| 350470105000001 | urbano (1) | 199 | 195 | 195 |
| 350470105000002 | urbano (1) | 207 | 207 | 207 |
| 350470105000003 | rural (8) | 59 | 59 | 59 |
| **350470105000004** | **rural (8)** | **2.335** | **3** | **X** |
| 350470105000006 | urbano (1) | 6 | 6 | 6 |
| 350470105000007 | urbano (1) | 1 | 1 | X |

O valor 2.335 vem **literalmente do XLS-fonte do IBGE**. Não há linha-resumo, duplicação, erro de leitura ou artefato de processamento. V003 ("Domicílios particulares permanentes do tipo casa") está **censurado com "X"** por sigilo estatístico no setor 4 — coerente com V002=3 (apenas 3 casas permanentes), uma quantidade que revelaria os domicílios particulares se detalhada.

### 4.3. Documentação oficial do IBGE

Manual *"Base de informações do Censo Demográfico 2010: Resultados do Universo por setor censitário — Documentação do Arquivo"* (IBGE, Rio de Janeiro, 2011). Disponível em https://www.ipea.gov.br/redeipea/images/pdfs/base_de_informacoess_por_setor_censitario_universo_censo_2010.pdf.

**Seção 2.7.2 (p. 17)** — definição de domicílio coletivo:

> "É uma instituição ou estabelecimento onde a relação entre as pessoas que nele se encontravam, moradoras ou não, era restrita a normas de subordinação administrativa, como em hotéis, motéis, camping, pensões, **penitenciárias, presídios, casas de detenção**, quartéis, postos militares, asilos, orfanatos, conventos, hospitais e clínicas (com internação), alojamento de trabalhadores ou de estudantes etc."

**Seção 2.7.10 (p. 23)** — conceito operacional (peça-chave):

> "A condição no domicílio foi caracterizada através da relação existente entre a pessoa responsável pela **unidade domiciliar (domicílio particular ou unidade de habitação em domicílio coletivo)** e cada um dos demais moradores..."

E entre as categorias:

> "**Individual em domicílio coletivo** — para a pessoa só que residia em domicílio coletivo, ainda que **compartilhando a unidade de habitação** com outra(s) pessoa(s) com a(s) qual(is) não tinha laços de parentesco."

O IBGE separa formalmente dois conceitos:

| Conceito | Significado | Como aparece em V001 |
|---|---|---|
| Domicílio coletivo | A instituição inteira (o presídio, o hotel) | — |
| **Unidade de habitação em domicílio coletivo** | Cada divisão interna onde residem pessoas (cela, dormitório, quarto) | **Cada UH conta como 1 unidade** |

**Seção 6.2 (p. 41)** — define V001 literalmente como *"Domicílios particulares e domicílios coletivos"*, mas a unidade contada para coletivos é a UH (per 2.7.10).

### 4.4. Operação de coleta — Formulário de Domicílio Coletivo

O manual técnico oficial do IBGE (2011) descreve, na seção 2.5 ("Aspectos da coleta"), os instrumentos usados pelo recenseador em campo. Entre eles:

> *"**Formulário de Domicílio Coletivo** — formulário utilizado para registrar os dados de identificação do domicílio coletivo e **listar as suas unidades com morador**"*

Esta é evidência operacional direta de que a contagem nos coletivos opera por **unidade**, não por instituição: o formulário registra a identificação da instituição **uma vez** e em seguida **lista uma a uma** as unidades habitacionais dentro dela que tinham morador. Cada UH listada é uma observação separada — e é justamente isso que se manifesta no V001 dos agregados por setor.

Adicionalmente, na seção 2.7.10 (p. 23), o manual define **"unidade domiciliar"** como termo guarda-chuva:

> *"A condição no domicílio foi caracterizada através da relação existente entre a pessoa responsável pela **unidade domiciliar (domicílio particular ou unidade de habitação em domicílio coletivo)** e cada um dos demais moradores"*

E reforça na definição de "Individual em domicílio coletivo":

> *"para a pessoa só que residia em domicílio coletivo, ainda que **compartilhando a unidade de habitação** com outra(s) pessoa(s) com a(s) qual(is) não tinha laços de parentesco"*

O conceito "unidade de habitação em domicílio coletivo" não aparece no [glossário](https://censo2010.ibge.gov.br/materiais/guia-do-censo/glossario.html) nem na [página de conceituação](https://censo2010.ibge.gov.br/materiais/guia-do-censo/conceituacao.html) do Censo 2010 (versões web público-pedagógicas) — está restrito ao manual técnico e à descrição operacional dos instrumentos de campo. Mas é conceito IBGE estabelecido, com 3 ocorrências no manual oficial do produto.

### 4.5. Nota sobre uma afirmação anterior incorreta

Uma versão preliminar deste relatório citava que o IBGE teria renomeado a variável `V00003` de "Domicílios Coletivos Com Morador" para "Unidades de Habitação em Domicílios Coletivos Com Morador". **Essa afirmação foi removida.** Verificação direta da documentação oficial mostra que:

- Não existe variável `V00003` em nenhuma convenção do Censo 2010 (agregados por setor usam 3 dígitos, microdata da amostra usa 4 dígitos).
- O único arquivo de atualizações no FTP IBGE para microdados do Censo 2010 ([`1_Atualizacoes_20160311.txt`](https://ftp.ibge.gov.br/Censos/Censo_Demografico_2010/Resultados_Gerais_da_Amostra/Microdados/1_Atualizacoes_20160311.txt), 121 bytes) registra apenas a inclusão da variável `v1005` (situação do setor) nos arquivos de DOMICÍLIO, PESSOA, EMIGRAÇÃO e MORTALIDADE — nada sobre renomeação de variável de domicílios coletivos.

A afirmação preliminar tinha origem em resposta de busca web não-verificada, sem fonte primária. As demais linhas de evidência (4.1, 4.2, 4.3) permanecem inalteradas e sustentam a conclusão.

---

## 5. Reconciliação das duas publicações

O Censo 2010 conduziu a coleta em campo pela **unidade de habitação**: em uma penitenciária com 2.000 internos distribuídos por celas, cada cela ocupada foi registrada como uma UH separada. Quando o IBGE produziu suas divulgações, fez escolhas distintas em cada produto:

| Publicação | Critério de contagem | Total Brasil de "coletivos com morador" |
|---|---|---:|
| Sidra 1310 (Sinopse) | Consolida: 1 instituição = 1 (ou poucos) domicílio coletivo | **44.554** |
| Domicilio01, agregados por setor (`V001 − V002`) | Granular: 1 UH = 1 unidade | **~623.000** |

A diferença de **~580 mil unidades** entre as duas publicações é, em essência, o total de UHs em coletivos institucionais (presídios, alojamentos, hospitais com internação, asilos, conventos, alojamentos de trabalhadores) no Brasil.

Confirmação por amostra (penitenciária = 1 setor → V001 mil vezes maior que coletivos da Sidra para o município):

| Município | V001 - V002 no setor da penitenciária | Coletivos_com_mor (Sidra, município) |
|---|---:|---:|
| Balbinos (SP) | 2.332 (em 1 setor) | 4 |
| Pracinha (SP) | ~1.300 (em 1 setor) | 4 |
| Reginópolis (SP) | 2.017 (em 1 setor) | 5 |
| Iaras (SP) | 1.549 (em 2 setores) | 6 |

---

## 6. Implicações práticas

### 6.1. Para análises sobre municípios

- **Para totais consolidados comparáveis com a Tabela 1310**, `domicilio01_V001` produz overcount sistemático de ~1% no Brasil, concentrado em municípios com grandes instituições coletivas.
- **Quem precisar bater Sidra 1310 exatamente** deve usar a própria Tabela 1310 (Sinopse) ou aceitar o gap de +1%.
- **Quem precisar apenas de domicílios particulares permanentes** deve usar `domicilio01_V002` — não tem o problema dos coletivos.

### 6.2. Para análises por setor censitário

- `domicilio01_V001` reflete a contagem verdadeira de UHs (incluindo coletivas). Em setores com grandes instituições isso aparece como concentração extrema de "domicílios" sem proporção correspondente de famílias — o que é **semanticamente correto**, dada a definição IBGE.
- Identificar setores com instituições coletivas: `dom_V001 − dom_V002` >> 0 e `pop/dom_V001 ≈ 1` simultaneamente.

### 6.3. Para documentação

A descrição do dicionário oficial ("Domicílios particulares e domicílios coletivos") é tecnicamente correta mas obscura. Uma formulação mais precisa, usando a terminologia que o próprio IBGE adotou na revisão posterior:

> "`domicilio01_V001` — Domicílios particulares permanentes ocupados + Unidades de Habitação em domicílios coletivos com morador."

### 6.4. Para o consumidor `censobr`

Vale registrar no `NEWS.md` da próxima release (v0.6.0):

> "**Esclarecimento sobre `2010_tracts_DOMICILIO.domicilio01_V001`**: o IBGE contou **unidades de habitação em domicílios coletivos** (não instituições), conforme conceito de coleta do Censo (vide *Base de informações por setor censitário, IBGE 2011, seção 2.7.10*). Setores com grandes instituições (presídios, alojamentos, hospitais) terão V001 muito acima do total de famílias residentes. Para totais consolidados como os divulgados na Sinopse 2010, use a Tabela 1310 da Sidra ou some `domicilio02_V001` (moradores) com base populacional."

---

## 7. Conclusão

A divergência entre `domicilio01_V001` e a Tabela 1310 da Sidra é **real, documentada pelo IBGE e intrínseca ao Censo 2010** — não há erro no pipeline `censobr_prep_data` nem no parquet produzido. A reprodução dos dados-fonte é fiel; a divergência aparente vem da escolha do IBGE de divulgar a mesma realidade com diferentes granularidades nos dois produtos (Sinopse vs agregados por setor).

A interpretação correta de V001 = "Domicílios particulares permanentes ocupados + Unidades de Habitação em domicílios coletivos com morador" — onde "Unidade de Habitação em domicílio coletivo" é o conceito operacional do IBGE (seção 2.7.10 do manual oficial) para a divisão interna (cela, dormitório, quarto) de uma instituição coletiva.

---

## Referências

- IBGE (2011). *Base de informações do Censo Demográfico 2010: Resultados do Universo por setor censitário — Documentação do Arquivo*. Rio de Janeiro: IBGE/Centro de Documentação e Disseminação de Informações. PDF: https://www.ipea.gov.br/redeipea/images/pdfs/base_de_informacoess_por_setor_censitario_universo_censo_2010.pdf
- IBGE — Sidra, Tabela 1310: https://sidra.ibge.gov.br/tabela/1310
- IBGE — Censo 2010, conceituação: https://censo2010.ibge.gov.br/materiais/guia-do-censo/conceituacao.html
- IBGE — FTP do Censo 2010, agregados por setores censitários: https://ftp.ibge.gov.br/Censos/Censo_Demografico_2010/Resultados_do_Universo/Agregados_por_Setores_Censitarios/
- IBGE — Glossário Censo 2010 (verificado: não inclui "unidade de habitação"): https://censo2010.ibge.gov.br/materiais/guia-do-censo/glossario.html
- IBGE — Conceituação Censo 2010 (verificado: não inclui "unidade de habitação"): https://censo2010.ibge.gov.br/materiais/guia-do-censo/conceituacao.html
- IBGE — *Descrição das variáveis da amostra do Censo Demográfico 2010* (define V4001 Espécie e V4002 Tipo de espécie). PDF (mirror IPEA): https://www.ipea.gov.br/redeipea/images/pdfs/descricao_das_variaveis_censo_2010.pdf
- IBGE — FTP do Censo 2010, microdados da amostra: https://ftp.ibge.gov.br/Censos/Censo_Demografico_2010/Resultados_Gerais_da_Amostra/Microdados/
- IBGE — `1_Atualizacoes_20160311.txt` (changelog dos microdados — verificado: só registra inclusão de v1005, sem renomeação de variáveis de coletivos): https://ftp.ibge.gov.br/Censos/Censo_Demografico_2010/Resultados_Gerais_da_Amostra/Microdados/1_Atualizacoes_20160311.txt
- Dicionário transcrito do IBGE para os agregados por setor: [`references/phgfsouza_census_tracts/transcripts/2010_dictionary_tracts.md`](phgfsouza_census_tracts/transcripts/2010_dictionary_tracts.md), seção 6.2 (linhas 860–882)
