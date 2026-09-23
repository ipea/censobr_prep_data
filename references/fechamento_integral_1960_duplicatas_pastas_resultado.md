# Cinco pastas divergentes no diagnóstico do desenho — 23/09/2026

## Resultado

As cinco divergências receberam confronto nominal entre os brutos, o índice de decisões atual, os domicílios materializados e os estratos exportados. **Não foi demonstrado reparo de V118 nem identificado o desenho histórico.** Há, porém, uma correção determinada da interpretação anterior: comparar CE15004 da subamostra à pasta numericamente igual da fonte25 não compara o conjunto correspondente comprovado. Há correspondência documentada CE15004→CE14990. Isso exige uma tabela de correspondência no diagnóstico do cadastro, não renumerar a UPA127.

As outras quatro pastas têm oito cartões que determinam a classificação divergente. Todos têm situações pessoais internamente contraditórias. As 27 pessoas discordantes pertencem ao inventário vigente de 192 conflitos geográficos; duas delas também têm conflito municipal. Não são 27 pendências novas nem 29 pessoas distintas. Identificar a família não escolhe qual fonte registrou corretamente a situação.

Nenhum arquivo de dados, manifesto congelado, guia, UPA, ID, estrato, fração, peso ou solver foi alterado. Nenhum R foi executado nesta investigação. Os estratos materializados abaixo são históricos: as guardas atuais interrompem a reconstrução antes de exportar novamente essas famílias contraditórias.

## Reprodução e evidência permanente

Executar `python references/fechamento_integral_1960_duplicatas_pastas.py`. O script usa os leitores já existentes e lê os parquets por lotes, preservando os dados. Reconta a classificação literal, registra todos os pareamentos completos de 24 campos nas pastas examinadas e conserva os textos dos oito cartões decisivos e seus integrantes. A execução desta rodada ficou abaixo de 250 MB de RAM residente.

O [índice de evidências](fechamento_integral_1960_evidencias/pastas_desenho.json) contém os hashes das fontes, a causa por pasta e os cinco arquivos nominais `pasta_desenho_UF_PASTA.json`. A saída conjunta de trabalho está em `tmp/fechamento_integral_1960/duplicatas/pastas/conferencia.json`. O índice SQLite é insumo computacional datado, não uma nova fonte histórica; os textos decisivos estão embutidos nas evidências permanentes. O inventário de conflitos usado é o [inventário final portátil](fechamento_integral_1960_evidencias/inventario_final.json).

Foram lidos os dicionários das duas amostras: `V118` ocupa a posição18 na127 e36 no cartão25; os códigos válidos são1 urbano,3 suburbano e5 rural. A comparação de composição preserva as multiplicidades e omite **somente V216**, registrando separadamente se todos os25 quesitos pessoais coincidem. Essa busca nesta nota é limitada às seis pastas delimitadas — as cinco investigadas e CE14990 —, não constitui uma nova prova de unicidade nacional.

## Camadas que efetivamente divergem

U significa situação1/3, R situação5. Cartão familiar e domicílio materializado não são unidades intercambiáveis: a diferença de contagem pode incluir conviventes e decisões anteriores. Não foi interpretada automaticamente como perda ou duplicação.

| Pasta127 | Cartões127 brutos e índice atual | Domicílios127 antigos e estrato exportado | Cartões25 de mesmo número | Domicílios25, legado e leitura atual |
|---|---:|---|---:|---|
| CE15004 | 0U+196R |195R; `UF 14 - rural`|8U+158R|8U+158R; mista|
| CE15290 |5U+224R|5U+224R; `UF 14 - mista`|0U+229R|229R; rural|
| MG43234 |161U+1R|161U+1R; `UF 40 - mista`|183U+0R|183U; urbana menor|
| SP60158 |226U+1R|222U+1R; `UF 60 - mista`|267U+0R|265U; cidade grande|
| SP60718 |173U+1R|172U+1R; `UF 60 - mista`|273U+0R|272U; cidade grande|

Os municípios são Mombaça1544, Barbalha1641, Barão de Cocais4522 e São Paulo6234, respectivamente; o cartão695175 traz7234, ausente no guia da UF60. As populações urbanas usadas pelo guia são3905,7098,7626 e3300218. A regra R vigente classifica como mista quando há ambas as situações; só nas pastas exclusivamente urbanas usa o limiar de100mil. Portanto, a diferença não decorre de município modal versus `any()`, do limiar ou do colapso posterior de estratos.

### CE15004: comparar a pasta de mesmo número era inadequado

Dos196 cartões reais127,176 grupos têm composição24 correspondente, com multiplicidade, exclusivamente em CE14990 dentre as pastas examinadas. Nenhum corresponde à CE15004 da25. Desses176,145 também coincidem integralmente nos15 campos familiares e no distrito; essa contagem reproduz a prova anterior de145 famílias, não é uma nova regra de promoção. Os outros31 têm diferenças familiares, e20 cartões não têm grupo completo24 identificado neste confronto. Esses resíduos impedem declarar equivalência registro a registro de toda a pasta.

CE14990 tem203 cartões brutos, todos rurais; o legado tem202 domicílios, todos rurais. Logo, os grupos efetivamente pareados concordam na classificação rural, ao contrário do pareamento apenas numérico15004→15004. A recuperação já aprovada do boletim116 conserva a pasta12715004 e usa o cartão25 da14990, com quatro pessoas já existentes; o cartão recuperado também é rural e não muda o grupo. Os196 cartões do índice não incluem esse cartão externo, que está listado separadamente na evidência.

A conclusão determinada é sobre a comparação: **não tratar a discordância15004→15004 como diferença de composição do mesmo conjunto sem aplicar a correspondência demonstrada**. Não se provou que toda numeração de pasta nacional tenha o mesmo tipo de mudança, nem se recalcularam ranks, corridas ou cadastro. UPA e IDs127 permanecem preservados.

### Os oito cartões decisivos nas outras quatro pastas

| Pasta/boletim | Cartão127 | Cartão25 | V118 cartão127/25 | Situações das pessoas127 | Pessoas no inventário de conflitos |
|---|---:|---:|---|---|---|
| CE15290/116 |143119|915647|1/5|3U+5R|143121,143122,143123,143124,143127|
| CE15290/117 |143128|915656|1/5|4U+4R|143131,143132,143134,143135|
| CE15290/118 |143137|915665|1/5|2U+2R|143139,143140|
| CE15290/174 |143477|916006|1/5|1U+2R|143479,143480|
| CE15290/225 |143763|916292|1/5|2U+6R|143765,143766,143767,143768,143769,143771|
| MG43234/005 |486736|2173139|5/1|4U+1R|486738,486739,486740,486741|
| SP60158/119 |695175|1525598|5/1|2U+1R|661580,661581; também conflito municipal|
| SP60718/176 |676491|1866270|5/1|2U+1R|676493,676494|

**CE15290:** nos boletins116–118, a composição completa dos25 quesitos pessoais coincide e a única diferença familiar é V118. No225, a composição24 coincide e quatro pessoas diferem apenas em V21600/63. No174, o chefe também diverge em V2021/2, e duas pessoas diferem em V21600/63. Os cinco cartões têm situação pessoal heterogênea na127, independentemente da comparação com25. O cenário em que a127 errou o cartão e o cenário em que a25 errou seu cartão, acompanhada por erros em algumas linhas127, são ambos compatíveis com os textos disponíveis. Nenhum documento independente localiza esses boletins no quadro urbano ou rural.

**MG43234:** o cartão rural e seu chefe não reproduzem a família inteira da25. O chefe486737 difere do chefe25 em14 quesitos pessoais, incluindo idade29/61; três das outras quatro pessoas diferem em V21600/63, e a restante coincide. Também há diferenças no corpo domiciliar, registradas literalmente. Não se pode substituir o cartão nem chamar a discordância de simples erro de um dígito de situação. O pertencimento/corpo concorrente e a situação correta continuam sem demonstração suficiente.

**SP60158:** as três pessoas coincidem integralmente entre fontes, mas duas estão fisicamente afastadas do cartão no HHOLDA; o vínculo por chave as reúne e reproduz o grupo25. O cartão difere em V1065/4, V1111/2, V1124/8, V1167234/6234 e V1185/1. A correspondência pessoal já havia sido identificada na investigação residual anterior.6234 é candidato municipal forte e7234 não consta como município da UF60; isso não transforma em demonstradas a situação e as três respostas domiciliares concorrentes. Não se promove o cartão25 inteiro. O parquet antigo já exibia `code_muni_1960=6234`, mas conservara V1185; essa harmonização anterior não é comprovação da situação rural nem uma decisão atual de reconstrução.

**SP60718:** três pessoas coincidem em todos os25 quesitos, o corpo familiar coincide e a única diferença do cartão é V118. Na127, cartão e chefe são rurais; as outras duas pessoas são urbanas. A coincidência identifica o grupo, não a direção do erro. Contar as repetições como votos independentes é injustificado, e pertencer ao município de São Paulo não exclui ruralidade. A alternativa urbana e a alternativa rural continuam documentalmente indistinguíveis.

## Consequência delimitada para o desenho e a entrega

A regra `finalize_1960_amostra_127()` em `R/microdata_1960_amostra_127.R` usa V118 dos domicílios e depois propaga os rótulos. Antes disso, as guardas dos vínculos diretos interrompem município ou situação divergentes. Esta investigação, portanto, descreve por que os arquivos antigos classificaram essas pastas assim; não autoriza exportar esses rótulos como uma reconstrução novamente aprovada.

Falta, para decidir as situações, uma fonte independente que localize o boletim/setor no quadro urbano, suburbano ou rural — ou documentação verificável do erro/recodificação ocorrido entre os arquivos. Maioria de pessoas, tamanho da amostra, menor erro-padrão, regularidade do intervalo20 e concordância de controles não substituem essa fonte. Para CE15004, já existe evidência bastante para corrigir a interpretação do pareamento numérico; a investigação do cadastro deve incorporar a correspondência demonstrada e deixar os resíduos explícitos antes de recontar ranks/corridas. Nada disso identifica probabilidades, reinícios, FPC ou variâncias.
