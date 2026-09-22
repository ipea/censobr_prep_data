# Censo de 1960: a compilação das duas amostras

> **Parecer vigente — 21/09/2026:** a [revisão integrativa](microdata_1960_amostra_127_revisao_integrativa.md) prevalece sobre afirmações incompatíveis abaixo. O validador compilado ainda omite 220 referências pessoais previstas e não cobre a tabela domiciliar7; o universo de alfabetização25 está incorreto. Schemas e contagens conferem, mas isso não homologa o conteúdo. Exportação e dicionário têm pendências; nenhum parquet foi regenerado nesta revisão.

Este documento explica a tabela de 1960 que o `censobr` distribui: de onde vem cada registro, como os pesos foram feitos, o que dá para estimar com ela e o que não dá.

É o terceiro e último estágio de 1960. Os dois anteriores estão em [`microdata_1960_amostra_127_preparacao.md`](microdata_1960_amostra_127_preparacao.md) e [`microdata_1960_amostra_25_preparacao.md`](microdata_1960_amostra_25_preparacao.md), com os respectivos guias de desenho amostral. Quem quiser só usar o dado pode ficar neste; quem quiser auditar precisa dos três.

---

## 1. O censo de 1960 tem duas amostras, não uma

O Censo Demográfico de 1960 foi recenseado com dois formulários: o Boletim Geral, aplicado a todo mundo, e o **Boletim de Amostra** (formulário CD 2), aplicado a **um domicílio em cada quatro**, sorteado sistematicamente pelas "Linhas de Amostra" impressas nas Folhas de Coleta. Essa é a **amostra de 25%**, e é dela que saíram os volumes publicados do censo.

Em 1965, para adiantar resultados, o IBGE sorteou dentro dela uma **subamostra de 1,27%** — uma pasta de trabalho em cada vinte, com a pasta entrando inteira. É a amostra que sobreviveu completa.

Os microdados da amostra de 25% sobreviveram para **dezessete** unidades da federação; os da de 1,27%, para as **vinte e oito**. Esta compilação junta as duas.

## 2. A partição, e por que não há alternativa

Nas dezessete unidades em que as duas existem, **a amostra de 1,27% é subamostra da de 25%**: os mesmos questionários, sorteados uma pasta em vinte do mesmo cadastro. Os dois arquivos descrevem os mesmos domicílios e casam pela chave do questionário. Empilhar os registros contaria a mesma gente duas vezes.

A compilação é, portanto, uma **partição por unidade da federação**:

| | unidades | domicílios | pessoas | população expandida |
|---|---|---|---|---|
| amostra de 25% | 17 | 3.066.365 | 14.983.769 | 57.304.420 |
| amostra de 1,27% | 11 | 31.022 | 162.041 | 12.886.726 |
| **compilado** | **28** | **3.097.387** | **15.145.810** | **70.191.146** |

As onze que vêm da amostra de 1,27% são **Rondônia, Acre, Amazonas, Roraima, Pará, Amapá, Maranhão, Piauí, Espírito Santo, Guanabara e Santa Catarina**. A coluna `censobr_amostra` diz, registro a registro, de qual metade ele vem.

Duas medições confirmam que a partição é limpa: as pastas das duas metades **não têm um número em comum**, e nenhum estrato ou unidade primária de amostragem mistura as duas.

## 3. As duas âncoras, e por que as onze são as melhores

As onze unidades não são um resto arbitrário. São **exatamente aquelas cujos tomos do Volume I foram apurados pelo Boletim Geral completo** — o censo inteiro, não a amostra. Nas outras dezessete o IBGE apurou tudo pelo Boletim de Amostra.

Isso dá à compilação uma propriedade que nenhum dos dois estágios tinha sozinho:

- nas **onze**, os pesos calibram a uma **contagem completa**, que é informação externa de verdade;
- nas **dezessete**, os pesos calibram a tabelas que foram estimadas com esta mesma amostra. A calibração alinha a âncora, mas não acrescenta informação, e a variância pelos resíduos da calibração não se publica. A circularidade está declarada.

Os dois pesos foram refeitos para ficarem na mesma régua: os dois estágios calibram aos **resultados definitivos da Série Nacional, vol. I**, por unidade da federação. O resultado aparece na seção 7.

**Dois problemas conhecidos se resolvem pela própria partição.** O Distrito Federal, que na amostra de 1,27% tem 137 domicílios e ficava no peso de desenho, ~60% abaixo do publicado, vem da amostra de 25%, onde tem 14.797 e fecha. E **Alto Garças**, em Mato Grosso, cuja pasta 91008 se perdeu inteira na amostra de 25%, tem a sua população redistribuída pelos demais municípios do estado, que fecha — contada, ainda que no lugar errado.

## 4. Os identificadores

Os três identificadores — `censobr_idhousehold`, `censobr_idfamily`, `censobr_idperson` — são **refeitos aqui e são únicos no país**. Não podiam vir prontos: na amostra de 25% a numeração reinicia em 1 em cada unidade da federação, e a chave do questionário, que é única nas dezessete, tem 58 repetições nas onze — todas pares de um registro íntegro com uma família reconstruída pelo estágio de 1,27%.

A regra é `UF × 10.000.000 + sequência dentro da unidade`, determinística na ordem do cadastro (pasta, boletim). Cabe em int32 nos três níveis; o maior é São Paulo, com 3.319.710 pessoas.

A chave do questionário continua nas colunas `v001` (pasta) e `v002` (boletim), que são estáveis entre versões e ligam de volta ao arquivo bruto.

## 5. A geografia

Cada unidade territorial aparece **duas vezes**: como era em 1960 e como é hoje. É a mesma regra que o município já seguia.

| 1960 | hoje |
|---|---|
| `code_state_1960`, `abbrev_state_1960`, `name_state_1960` | `code_state`, `abbrev_state`, `name_state` |
| `name_region_1960` — Norte, Nordeste, Leste, Sul, Centro-Oeste, as cinco regiões em que os volumes de 1960 publicam | `code_region`, `name_region` |
| `code_muni_1960`, `name_muni_1960` | `code_muni` |
| `code_district_1960`, `name_district_1960`, `code_bairro_1960`, `name_bairro_1960` | — |

Três unidades não existem mais e merecem atenção:

- **Guanabara** era o município do Rio de Janeiro como unidade da federação. Sai com `code_state_1960` = 34 e `code_state` = 33, e `code_muni` = 3304557, que é o município do Rio de Janeiro de hoje. O censo **não codificou a cidade por distrito**: codificou por bairro, e dentro do bairro por circunscrição ou favela. O bairro está em `code_bairro_1960` (5410 a 5591) e `name_bairro_1960`, e é ele a *Circunscrição Censitária* em que o tomo XII do Volume I publica a cidade — 9 zonas e 83 circunscrições. O que está em `code_district_1960` é a circunscrição, com código até 40, ou a favela, com 41 e acima: o livro as numera numa sequência só dentro do bairro, sob o título "Circunscrições e favelas", e `censobr_favela` diz qual é qual. Quem quiser as favelas filtra por `censobr_favela == 1` e lê o código e o nome nas colunas de distrito. Os nomes ficam **como o IBGE os publicou**: o livro escreve o prefixo "Favela do" em quinze das 147 e não escreve nas outras, e a grafia não foi uniformizada.

  A conferência contra o tomo XII fecha: a nossa população presente dá 3.281.908 contra 3.307.163 publicados (−0,76%), e o quadro rural bate ao dígito, 83.317 dos dois lados. A estrutura também: o guia tem as 9 zonas com a Baía de Guanabara repartida em Orla Norte, Central e Sul, e 85 bairros, que são as 83 circunscrições mais a Zona Rural e a População em trânsito.
- **Fernando de Noronha** era território federal: `code_state_1960` = 20, `code_state` = 26 (Pernambuco), `code_muni` = 2605459.
- **Serra dos Aimorés** era a região em litígio entre Minas e o Espírito Santo, que o censo recenseou como unidade à parte e que depois se repartiu entre os dois estados. **Nunca teve código**, e fica vazia nas colunas de estado e de município: quem a identifica é `UF` = 50 e `name_state_1960`. Os tomos de Minas e do Espírito Santo a excluem com todas as letras, e a única publicação que a traz é a Série Nacional.

### Os nomes de distrito, e por que a numeração impressa nem sempre serve

O nome de cada distrito vem do *Código de Zonas Fisiográficas, Municípios e Distritos* de 1960, que é o manual que os codificadores do censo usaram. Em setembro de 2026 o guia foi refeito a partir da **transcrição integral** das suas 313 páginas, no lugar do OCR anterior — que corrompia 19% dos nomes e deixava 720 pares sem nome nenhum.

A transcrição revelou um problema que o OCR escondia: **em alguns municípios a numeração impressa no livro não é a que o censo usou**, e o guia vinha pondo cada nome no distrito seguinte. São duas situações, e cada uma tem a sua assinatura:

1. **O livro pula números e o arquivo não.** Campos traz dezoito distritos numerados 01, 05, 07 … 41, sem 03, 25 e 27; o arquivo traz os mesmos dezoito numerados 01, 03, 05 … 35, sem pular. São sete municípios.
2. **Os códigos não sobem junto com as linhas.** Palmeira das Missões lista os cinco distritos em ordem alfabética mas dá a Coronel Finzito, o segundo, o código 09 — o próximo livre, por ter sido criado depois. Aqui a numeração está completa, sem buraco, de modo que a primeira assinatura não acusa. São trinta municípios.

Cada caso foi decidido pela medida, contra a **Sinopse Preliminar de 1960** — o volume que o IBGE publicou por estado em 1961-62 com a população de cada distrito do país. A transcrição do seu quadro II está em `references/censo_1960_sinopse_preliminar_distritos.csv`, e a conferência em `references/auditoria_distritos_1960.R`. Duas medidas independentes: a população de cada distrito e a parcela dele que o censo classificou no quadro urbano ou suburbano. A segunda é mais forte, porque é razão interna e não depende do nível do peso.

**O peso é o de desenho, e não o final.** O `censobr_weight` da amostra de 25% é calibrado, entre outras margens, a município × situação da própria Sinopse Preliminar: usá-lo para validar contra ela seria circular. O `censobr_weight_desenho` vale 4 para todos, de modo que a população é a contagem crua vezes quatro e a parcela urbana é a proporção crua. Os dois pesos dão o mesmo veredicto — em Campos, 7,4% contra 7,8% de erro de população —, mas só o de desenho se defende.

Resultado: **trinta municípios corrigidos e sete confirmados**, com separações largas. Em Campos a leitura sequencial erra 0,7 ponto percentual na parcela urbana dos dezoito distritos e a do livro erra 4,3, chegando a 61,8 em Guarus — poria 5% de urbanos onde a publicação traz 67%. Em Novo Hamburgo, 0,6 contra 57,5. Do outro lado, em Virginópolis o livro erra 2,6 e a ordem das linhas 25,3.

O padrão é geográfico e faz sentido, porque a codificação do censo era estadual: vinte dos vinte e três municípios do segundo grupo são do Rio Grande do Sul, e os cinco em que a numeração impressa vale são do Ceará, de Minas e de São Paulo.

**Brasília é um caso à parte.** A sua página no livro é emendada à mão: os códigos datilografados — 9701 Cidade de Brasília, 9702 Planaltina, 9703 Taguatinga, 9704 Sobradinho, 9705 Zona Rural — foram riscados e substituídos por 01 a 06 manuscritos, com a linha do Núcleo Bandeirante acrescentada a mão, sem autoria nem data. O arquivo bruto diz qual versão os codificadores usaram: `V116` = 9701 nos 14.818 registros, e os distritos são 01, 03, 05 e 07. **São quatro, e não seis.** Quais quatro, fixou-se pelo quadro 1 da Sinopse Preliminar de **1970** do Distrito Federal, a única publicação encontrada que abre o DF por localidade: 01 Cidade de Brasília, 03 Planaltina, 05 Sobradinho, 07 Taguatinga. O Núcleo Bandeirante não é distrito — é o quadro suburbano da Cidade de Brasília, e os nossos 21.306 suburbanos ficam a 1,3% dos 21.033 que a publicação lhe dá.

**O que sobra sem nome:** 8 pares e 561 domicílios, 0,018% do compilado, listados com o motivo de cada um em `read_guides/1960_distritos_pendentes.csv`. Em três deles o arquivo traz um distrito que nenhuma publicação de 1960 lista, e a aritmética mostra ser uma repartição interna da sede — nomeá-lo seria invenção. Os outros cinco são registros isolados com dano de fita. Dois municípios ficaram sem decisão, Horizontina e Tenente Portela, porque os distritos que trocariam de nome têm quase o mesmo tamanho e quase a mesma parcela urbana.

## 6. O desenho amostral, e como calcular erro-padrão

O compilado é de **duas etapas** nas duas metades, com frações diferentes:

| | 17 unidades (25%) | 11 unidades (1,27%) |
|---|---|---|
| `censobr_estrato` | pasta × situação | unidade da federação × grupo de situação da pasta |
| `censobr_upa` — 1ª etapa | o domicílio | a pasta |
| `censobr_fpc` | 0,25 | 0,05 |
| `censobr_usa` — 2ª etapa | o domicílio | o domicílio |
| `censobr_fpc2` | 1 (não há segunda etapa) | 0,25 |
| `censobr_weight_desenho` | 4 | 78,74 |

São **18.421 estratos** e **3.066.510 unidades primárias**. Como nenhum estrato e nenhuma unidade primária mistura as duas metades, **uma chamada só descreve o país inteiro**:

```r
library(survey)
options(survey.lonely.psu = "adjust")

d <- svydesign(ids     = ~censobr_upa + censobr_usa,
               strata  = ~censobr_estrato,
               weights = ~censobr_weight,
               fpc     = ~censobr_fpc + censobr_fpc2,
               data    = pessoas)

svytotal(~um, d)                      # um total, com erro-padrão
svymean(~alfabetizado, d)             # uma proporção
svyby(~um, ~name_state, d, svytotal)  # por unidade da federação
```

Nas dezessete a segunda etapa tem `fpc2` = 1 e não contribui: sobra o estimador de uma etapa, que é o do estágio da amostra de 25%. Nas onze, a primeira etapa é o estimador de conglomerado último e a segunda acrescenta o termo da etapa dos domicílios.

**Os estratos das onze unidades foram refeitos aqui.** Os 75 estratos do estágio de 1,27% foram construídos sobre as 28 unidades e não sobrevivem ao corte: só 23 têm pasta nas onze que ficam, cinco atravessam a fronteira e dois caíam para uma pasta só, que não mede variância. A regra de colapso foi reexecutada sobre as onze — a unidade solitária num grupo se junta à primeira vizinha da mesma região — com uma extensão que o corte obriga: a unidade cuja região não tem vizinha entre as onze junta o grupo solitário ao maior grupo dela mesma. É o caso da **Guanabara**, cujas vizinhas, Rio de Janeiro e Minas, vêm todas da amostra de 25%. Resultado: **21 estratos em 145 pastas, o menor com duas**.

### O que os erros-padrão dizem

| domínio | estimativa | erro-padrão | CV | efeito de desenho | n efetivo |
|---|---|---|---|---|---|
| pessoas | 71.020.963 | 283.078 | 0,399% | — | — |
| presentes | 70.191.146 | 280.575 | 0,400% | — | — |
| população urbana | 31.674.004 | 256.709 | 0,810% | 800,9 | 18.911 |
| população rural | 38.517.143 | 315.319 | 0,819% | 1202,8 | 12.592 |
| analfabetos de 15 anos e mais | 16.076.203 | 103.704 | 0,645% | 184,4 | 82.136 |
| crianças de 0 a 4 anos | 9.013.658 | 45.474 | 0,505% | 56,0 | 270.461 |
| pessoas com rendimento | 44.226.803 | 182.119 | 0,412% | 423,9 | 35.730 |

**Estes números mudaram em 21/09/2026**, e vale dizer por quê, porque duas correções se somaram em sentidos opostos. A primeira é um defeito de cálculo: `sampling_errors_1960()` acumulava os agregados por estrato dentro do laço por unidade da federação, o que partia em doze pedaços os seis estratos que a regra de colapso construiu **atravessando** a fronteira da UF; nove desses pedaços ficavam com uma pasta só e não contribuíam variância nenhuma — exatamente o que o colapso existia para evitar. Corrigido, o erro-padrão da população presente subia de 286.168 para 291.693. A segunda é uma correção de dado: duas chaves de pasta danificadas eram tratadas como unidades primárias próprias, com **um domicílio cada**, e uma delas caía num estrato de quarenta pastas da Guanabara. Devolvidas às suas pastas, o erro-padrão desceu para **280.574**. O efeito da segunda é nacional e não local: uma unidade primária com um domicílio só pesa na soma de quadrados muito além do seu tamanho.

Os coeficientes de variação ficam entre **0,4% e 0,82%**. Comparados com os 0,03% a 0,07% da amostra de 25% sozinha, são dez a vinte vezes maiores — e a razão está inteira nas onze unidades. A conferência contra o `survey` mede isso diretamente: num subconjunto com as onze mais Sergipe e Fernando de Noronha, a metade de 25% contribui com um erro-padrão de **1.904** e a de 1,27% com **280.139**. Praticamente todo o erro-padrão nacional vem de 1% dos registros.

O **efeito de desenho** chega a 1.203 na população rural, e não é defeito: ele compara com um sorteio simples de 15,1 milhões de pessoas, que não é o que este arquivo é. A coluna **n efetivo** diz a mesma coisa de forma legível — quantas pessoas sorteadas uma a uma dariam a mesma precisão. Para a população rural do país, cerca de **12.600**.

A **etapa dos domicílios** vale de 0,05% a 0,28% da variância, que é a ordem que o estágio de 1,27% já tinha medido. A conta à mão de `sampling_errors_1960()` e a do `survey` batem no dígito: 280.146 nos dois, para a população presente do subconjunto conferido.

## 7. O que a validação diz

As cinco tabelas por unidade da federação da Série Nacional, vol. I, reproduzidas com `censobr_weight`. O erro mediano por metade e por tabela:

| tabela | 17 unidades (25%) | 11 unidades (1,27%) |
|---|---|---|
| 32 condição de presença | 0,003% | 0,022% |
| 33 idade × sexo | 0,000% | 0,000% |
| 34 situação do domicílio | 0,288% | 0,824% |
| 37 cor | 0,132% | **13,49%** |
| 40 alfabetização de 5 anos e mais | 0,137% | 0,171% |

**A população presente das onze unidades fecha exatamente — 0,000% em todas as onze.** E, pela primeira vez, o Brasil fecha:

| tabela | compilado | publicado | diferença |
|---|---|---|---|
| 32 população presente | **70.191.146** | **70.191.370** | **−0,0003%** |
| 33 idade × sexo | 70.191.147 | 70.191.370 | 0,000% |
| 34 situação | 70.191.146 | 70.191.370 | 0,000% |
| 37 cor | 70.191.146 | 70.191.370 | 0,000% |

São **224 pessoas** de diferença em setenta milhões, resíduo de arredondamento das dezessete unidades. Nenhuma das duas amostras fechava o país sozinha: a de 25% não tem onze unidades, e a de 1,27% deixava o Distrito Federal 60% abaixo.

O que os números não calibrados dizem é mais informativo que o que fecha por construção. Na metade de 25%, a cor erra 0,13% e a alfabetização 0,14% sem que nada as obrigue a fechar — é a evidência de que a leitura do arquivo está certa. A situação do domicílio erra 0,29% por construção, porque a margem municipal vem da Sinopse Preliminar, cujo corte urbano/rural difere ligeiramente do dos definitivos.

## 8. Limitações e cuidados

Quatro delas são grandes o bastante para mudar o que se pode perguntar ao dado.

**1. A cor não é confiável nas onze unidades.** A amostra de 1,27% foi perfurada de cartões que sofreram dano de fita, e o dano atinge a variável de cor: agregando as onze, os amarelos saem 36% abaixo do publicado, os pretos 7,6% abaixo e os pardos 3,0% acima. Por isso a cor foi rejeitada como margem de calibração naquele estágio. Nas dezessete unidades da amostra de 25% ela erra 0,13% e é confiável.

**2. O corte urbano/rural não é confiável em Rondônia, Acre, Amapá e Roraima.** Nessas quatro o sorteio de 1965 não alcançou pasta rural, ou alcançou pouquíssimas: a população urbana sai 148% acima do publicado em Rondônia e 141% no Acre. O **total** da unidade está certo — a calibração garante —, mas a sua repartição entre urbano e rural não. Nenhum peso cria o que não foi amostrado.

**3. As onze unidades dominam o erro-padrão de qualquer estimativa nacional.** Elas são **1% dos registros e 18% da população**: a amostra é vinte vezes menor ali e sofre um segundo estágio de conglomeração. Um coeficiente de variação nacional é da ordem do da amostra de 1,27%, não do da de 25%.

**4. Não estime abaixo do município.** O guia de leitura anota isso na própria `V116`: não há representatividade nessa escala. O distrito está na tabela porque é informação do registro, não porque sirva de domínio de estimação. E não estime nada para **Alto Garças**, que não tem um domicílio sorteado.

Mais três, menores:

- **Os erros-padrão são do desenho.** Não cobrem erro de cobertura, de resposta nem de transcrição. O último não é desprezível: as duas amostras transcreveram os mesmos questionários de forma independente nas dezessete unidades, e discordam em 8,65% no tipo de construção e 3,48% na instalação sanitária. Um intervalo de confiança de 0,03% não diz nada sobre isso.
- **A página do domicílio das famílias secundárias fica ausente**, nos dois estágios, por decisão explícita (`ipea/censobr#87`). Em 1960 o boletim era por família: as características do domicílio foram perguntadas uma vez, no boletim da família principal. Para tê-las por pessoa, junte a tabela de pessoas à de domicílios.
- **O boletim individual só existe na metade de 25%.** São 195.445 registros de moradores de domicílios coletivos, amostrados pessoa a pessoa, que `censobr_tipo_unidade` separa. Na amostra de 1,27% o código não aparece — ora os boletins faltam, ora foram recodificados como domicílio particular —, então nas onze unidades a categoria está ausente por construção, não por realidade.

## 9. O que muda em relação à compilação que o `censobr` distribuía

A compilação anterior, de 2019/2024, fazia a mesma partição por unidade da federação, e nisso acertava. O que muda:

| | antes | agora |
|---|---|---|
| domicílios | 3.097.328 | 3.097.387 |
| pessoas | 15.145.824 | 15.145.810 |
| população expandida | 70.924.748 | **70.191.146** (publicado: 70.191.370) |
| âncora dos pesos | população municipal preliminar (25%) e estadual (1,27%) | resultados definitivos da Série Nacional, nas duas metades |
| auditoria de dano | nenhuma no lado de 25% | as duas metades auditadas, com as marcas em coluna |
| desenho amostral | `censobr_estrato` = código do município, `censobr_upa` = domicílio ou município | estrato e unidade primária do desenho real, com correção de população finita nas duas etapas |
| geografia | unidade da federação e nome do município | estado, região, município e distrito, em 1960 e hoje |

A diferença de população — 733.602 pessoas, 1,03% — é a distância entre a safra preliminar e os resultados definitivos, que a calibração nova removeu.

O conjunto de colunas mudou bastante: 26 colunas novas nos domicílios e 32 nas pessoas, 8 renomeadas em cada. O inventário coluna a coluna está em [`microdata_1960_compilacao_dicionario.csv`](microdata_1960_compilacao_dicionario.csv), com o nome antigo ao lado de cada uma.

### O dicionário publicado

Os dois dicionários HTML que o `censobr` distribui no release `censo_docs` foram refeitos a partir dos publicados, em [`censo_docs/`](censo_docs/), pelo gerador [`gera_dicionario_1960.py`](gera_dicionario_1960.py) — que usa os antigos como molde, guardados em [`censo_docs/molde/`](censo_docs/molde/): o cabeçalho, o CSS, a largura das colunas e o rodapé saem intactos, e só as linhas da tabela são refeitas, com as mesmas classes de estilo.

Agora eles documentam **todas** as colunas das duas tabelas, na ordem do arquivo — 66 e 98, contra 35 e 66 antes. O que mudou:

- **Entraram** 36 variáveis nos domicílios e 41 nas pessoas: a geografia do `censobr`, as duas épocas de cada unidade territorial, o tipo de unidade, as colunas de desenho das duas etapas, os quatro pesos e as marcas de auditoria.
- **Saíram** `V200` e `V201` — número e dígito verificador da pessoa, redundâncias de perfuração que o estágio da amostra de 25% já usara como teste de leitura e descartara.
- **Foram renomeadas** oito nas duas tabelas, mais `V204b`→`V204B` e `V223b`→`V223B`. E `V001`–`V004` e `V100` passam a `v001`–`v004` e `v100`, em minúsculas: é como o layout original distingue a chave do questionário das variáveis do formulário, e os dois estágios preservaram a distinção.
- **As seis listas longas que o arquivo antigo remetia a abas de Excel que a exportação para HTML não levou** — "Ver aba V207", V210, V214, V216, V221, V223B — passam a vir impressas, do *Código do Censo* transcrito em `read_guides/1960_codigo_do_censo.csv`. São 640 códigos que o dicionário publicado prometia e não entregava; a ocupação habitual sozinha tem 248.
- **Três erros de código corrigidos**, conferidos no *Código do Censo*: em `V215`, os códigos 7 e 8 tinham o mesmo rótulo ("Somente Casamento") e o 6 vinha pela metade — são "Somente casamento civil", "Somente casamento religioso" e "Casamento civil e religioso". Mais os erros de digitação "Peças Servindo Domitório", "Cananalização" e "Total de Comodos".
- **O zero de `V112` e `V113` ganhou linha própria**: não é ausência, é o código que o questionário manda usar quando não há indicação do número de cômodos ou de dormitórios (*Código do Censo*, p. 25).
- Em `V101`, o dicionário de domicílios passa a dizer que **os códigos 4 e 5 não ocorrem naquela tabela**: o domicílio leva o código da família principal, e as famílias conviventes só aparecem na tabela de pessoas.

## 10. O que sai

Duas tabelas, em `./data/microdata_sample/1960/`:

- **`1960_households_<versão>.parquet`** — 3.097.387 domicílios, 66 colunas.
- **`1960_population_<versão>.parquet`** — 15.145.810 pessoas, 98 colunas.

Ligam-se por `censobr_idhousehold`. Os parquets por unidade da federação ficam ao lado, em `data_raw/microdata/1960/compilada/<uf>/`, para auditoria, junto com a validação e os erros amostrais.

## 11. Fontes

- IBGE, *Censo Demográfico de 1960 — Brasil*, Série Nacional vol. I, em [`fontes_1960/1960_serie_nacional_vol1_brasil.pdf`](fontes_1960/1960_serie_nacional_vol1_brasil.pdf) — a âncora dos pesos das duas metades, transcrita em [`censo_1960_resultados_definitivos_serie_nacional.csv`](censo_1960_resultados_definitivos_serie_nacional.csv).
- IBGE, *Censo Demográfico de 1960*, Série Regional, Volume I, seção *Amostragem* — o método de estimativa que `censobr_weight_ibge` reproduz.
- IBGE, *Resultados Preliminares do Censo Demográfico de 1960*, Série Especial vol. II, março de 1965 — o desenho da subamostra de 1,27%.
- IBGE, Serviço Nacional de Recenseamento, *Código do Censo Demográfico — 1960* — a autoridade dos códigos de todas as variáveis.
- Os dois documentos dos estágios, e os seus guias de desenho amostral.
- A conferência do desenho compilado contra o `survey`: [`conferencia_desenho_compilado_1960.R`](conferencia_desenho_compilado_1960.R).
