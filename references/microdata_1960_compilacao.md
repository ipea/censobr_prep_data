# Censo de 1960: a compilação das duas amostras

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
| `code_district_1960`, `name_district_1960`, `name_bairro_1960` | — |

Três unidades não existem mais e merecem atenção:

- **Guanabara** era o município do Rio de Janeiro como unidade da federação. Sai com `code_state_1960` = 34 e `code_state` = 33, e `code_muni` = 3304557, que é o município do Rio de Janeiro de hoje. O censo codificou a cidade por **bairro**, e é o bairro que está em `name_bairro_1960`.
- **Fernando de Noronha** era território federal: `code_state_1960` = 20, `code_state` = 26 (Pernambuco), `code_muni` = 2605459.
- **Serra dos Aimorés** era a região em litígio entre Minas e o Espírito Santo, que o censo recenseou como unidade à parte e que depois se repartiu entre os dois estados. **Nunca teve código**, e fica vazia nas colunas de estado e de município: quem a identifica é `UF` = 50 e `name_state_1960`. Os tomos de Minas e do Espírito Santo a excluem com todas as letras, e a única publicação que a traz é a Série Nacional.

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

São **18.421 estratos** e **3.066.511 unidades primárias**. Como nenhum estrato e nenhuma unidade primária mistura as duas metades, **uma chamada só descreve o país inteiro**:

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

**Os estratos das onze unidades foram refeitos aqui.** Os 75 estratos do estágio de 1,27% foram construídos sobre as 28 unidades e não sobrevivem ao corte: só 23 têm pasta nas onze que ficam, cinco atravessam a fronteira e dois caíam para uma pasta só, que não mede variância. A regra de colapso foi reexecutada sobre as onze — a unidade solitária num grupo se junta à primeira vizinha da mesma região — com uma extensão que o corte obriga: a unidade cuja região não tem vizinha entre as onze junta o grupo solitário ao maior grupo dela mesma. É o caso da **Guanabara**, cujas vizinhas, Rio de Janeiro e Minas, vêm todas da amostra de 25%. Resultado: **21 estratos em 146 pastas, o menor com duas**.

### O que os erros-padrão dizem

| domínio | estimativa | erro-padrão | CV | efeito de desenho | n efetivo |
|---|---|---|---|---|---|
| pessoas | 71.020.963 | 289.053 | 0,407% | — | — |
| presentes | 70.191.146 | 286.168 | 0,408% | — | — |
| população urbana | 31.674.004 | 262.682 | 0,829% | 838,6 | 18.061 |
| população rural | 38.517.143 | 315.365 | 0,819% | 1203,2 | 12.588 |
| analfabetos de 15 anos e mais | 16.076.203 | 102.832 | 0,640% | 181,3 | 83.540 |
| crianças de 0 a 4 anos | 9.013.658 | 45.513 | 0,505% | 56,1 | 269.979 |
| pessoas com rendimento | 44.226.803 | 183.334 | 0,415% | 429,6 | 35.256 |

Os coeficientes de variação ficam entre **0,4% e 0,83%**. Comparados com os 0,03% a 0,07% da amostra de 25% sozinha, são dez a vinte vezes maiores — e a razão está inteira nas onze unidades. A conferência contra o `survey` mede isso diretamente: num subconjunto com as onze mais Sergipe e Fernando de Noronha, a metade de 25% contribui com um erro-padrão de **1.904** e a de 1,27% com **291.275**. Praticamente todo o erro-padrão nacional vem de 1% dos registros.

O **efeito de desenho** chega a 1.203 na população rural, e não é defeito: ele compara com um sorteio simples de 15,1 milhões de pessoas, que não é o que este arquivo é. A coluna **n efetivo** diz a mesma coisa de forma legível — quantas pessoas sorteadas uma a uma dariam a mesma precisão. Para a população rural do país, cerca de **12.600**.

A **etapa dos domicílios** vale de 0,05% a 0,28% da variância, que é a ordem que o estágio de 1,27% já tinha medido. A conta à mão de `sampling_errors_1960()` e a do `survey` batem no dígito: 291.281 nos dois, para a população presente do subconjunto conferido.

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
