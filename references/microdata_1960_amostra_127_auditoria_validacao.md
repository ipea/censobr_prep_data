# Amostra de 1,27% de 1960: reformulação da validação

> **Conclusões semânticas substituídas:** a [revisão integrativa](microdata_1960_amostra_127_revisao_integrativa.md) corrige interpretações de idade ignorada, cor, água, atividade, universo e origem dos controles domiciliares. A concordância R/Python descrita aqui não certifica essas interpretações. A proteção da grade127 não alcançou os validadores25/final; dados não homologados e testes R não executados.

**Data:** 2026-09-21. **Estado:** código de validação revisado; auditoria Python executada sobre os parquets existentes; testes R preparados, **não executados**. Os pesos, vínculos, exclusões e parquets de produção não foram recalculados nesta auditoria. O cálculo de variâncias está fora desta rodada.

A reformulação corrige o relatório de comparação: uma célula oficial sem observações deixa de desaparecer; um quesito que não foi reconstruído não recebe zero; um peso ausente não vira zero após uma agregação. Ela também distingue informações desconhecidas de categorias conhecidas e torna explícitas as políticas que podem fazer a validação divergir da calibração vigente. Isso permite enxergar limitações da base disponível; não demonstra que todas as margens, universos ou inferências estejam resolvidos.

## Escopo e reprodução

O script independente é [`auditoria_validacao_1960.py`](auditoria_validacao_1960.py). Ele lê apenas as colunas necessárias dos dois parquets de `data_raw/microdata/1960/amostra_127/`, com pandas/pyarrow, e usa os gabaritos versionados. Não inicia R, não chama `targets`, não calcula pesos e não modifica arquivos de produção.

Execução da raiz do projeto:

```text
python references/auditoria_validacao_1960.py --self-test
python references/auditoria_validacao_1960.py
```

As duas chamadas passaram. Antes da grade completa, o script conferiu os casos pequenos de Rondônia e dos três registros sem V202. A execução completa levou cerca de sete segundos nesta máquina. Os resultados separados estão em `data_raw/microdata/1960/amostra_127/auditoria_validacao_20260921/`:

- `preliminares_grade_completa.csv`: quatro regiões de 1965, incluindo Norte e Centro-Oeste obtido por diferença; o Brasil não é duplicado no mesmo relatório;
- `definitivos_grade_completa.csv`: as 28 UFs, com as linhas originais “70 e mais” e “ignorada” separadas;
- `universos_nao_classificados.csv`: contagens e somas de pesos por UF e motivo, sem atribuir sexo ou elegibilidade desconhecidos;
- `resumo_grade.csv`: contagem de células por tabela, peso e estado de reconstrução;
- `celulas_omitidas_validacao_anterior.csv`: omissões usando exatamente o agrupamento etário antigo, para comparar números de forma justa;
- `manifesto.json`: arquivos de entrada, tamanhos e SHA-256, escopo e política etária.

As funções `validate_1965_1960_amostra_127()` e `validate_definitivos_1960_amostra_127()` de `R/microdata_1960_amostra_127.R` foram revisadas com o mesmo contrato. O argumento opcional `out_dir` mantém o destino padrão anterior e permite testes em diretório temporário. Os targets preservam seus nomes. A busca dos consumidores encontrou suas chamadas em `_targets.R`; não encontrou código R/Python consumidor desses CSVs por posição de coluna. As colunas de identificação, `publicado`, `nosso`, `peso` e `dif_pct` permanecem disponíveis, com colunas novas de diagnóstico.

## Contrato das células

| `status_celula` | Significado | `nosso` | `n_amostra` |
|---|---|---|---|
| `observada` | Quesito reconstruído com contribuições e pesos disponíveis | Soma sem arredondar antes da comparação | Número da unidade medida |
| `sem_observacoes` | Quesito reconstruído, célula sem contribuições | 0 | 0 |
| `peso_ausente` | Há contribuições com peso NA ou não finito | NA | Inclui as contribuições sem peso |
| `nao_reconstruida` | O código não reconstrói esse quesito/coluna | NA | NA |

`n_pesos_ausentes` acompanha as agregações. Para a medida pessoas em domicílios, `n_amostra` conta **residentes**, não domicílios: um domicílio sem residentes acrescenta zero pessoas. O join ao domicílio só completa com zero a ausência de registros residentes; não substitui um total NA causado por peso ausente.

`dif_abs = nosso - publicado` também existe quando o publicado é zero. Apenas `dif_pct` fica NA nesse caso; uma divergência de zero para dez continua visível em termos absolutos. Valores não reconstruídos ou sem peso suficiente não recebem diferenças numéricas. As diferenças são calculadas antes do arredondamento de apresentação, o que pode mudar em 0,01 ponto percentual algumas comparações antigas de células pequenas.

A grade oficial é o lado preservado do join. Duplicações das chaves do gabarito ou da agregação causam erro. Os resumos contam também células vazias e não reconstruídas; os definitivos incluem o Distrito Federal.

## O que a base materializada mostra

São **897.009 pessoas e 174.245 domicílios**, os mesmos parquets disponíveis antes desta revisão. Os resultados abaixo valem **por peso**; há duas versões de peso, sem recalibração.

| Referência e grade | Observadas | Sem observações | Não reconstruídas | Total |
|---|---:|---:|---:|---:|
| Preliminares, quatro regiões | 1.762 | 2 | 456 | 2.220 |
| Definitivos, 28 UFs | 1.851 | 81 | 0 | 1.932 |

Nos preliminares, as duas células vazias são zeros publicados do quadro 4. Das 456 não reconstruídas, 288 são cruzamentos de estado conjugal por atividade/sexo do quadro 5, e 168 são as faixas de aluguel do quadro 6. Não se classificam esses quesitos como zeros amostrais.

Nos definitivos, **68 das 81 células sem observações têm valor oficial positivo**. Há seis células vazias na tabela 7, dezesseis na 33, nove na 34 e cinquenta na 37. Os números dependem da grade e das categorias declaradas: não devem ser confundidos com a contagem da auditoria anterior.

A reconciliação exata com a validação anterior é esta: a grade antiga, depois de somar “70 e mais” e “ignorada”, tinha 1.876 células esperadas por peso; o arquivo anterior preservava 1.813. Portanto, **63 células eram omitidas**, 52 com valor publicado positivo. A primeira auditoria destacou 60 omissões nas tabelas 7, 34 e 37, das quais 50 positivas; completando a tabela 33, somam-se três omissões, duas positivas: homens e mulheres de 70+ ou idade ignorada no Distrito Federal. A grade nova tem 56 linhas adicionais pela separação das faixas de idade, e também altera a classificação de cor desconhecida; por isso 63 e 81 respondem a perguntas diferentes.

Rondônia ilustra o problema de suporte. Suas 675 pessoas estão todas no urbano: V118=1 em 673 e V118=3 em duas; o código 3 é suburbano, não rural. Entre os presentes conhecidos, 666 registros recebem um total ponderado de 70.232. O total urbano publicado é 30.626: **+129,32%**. A célula rural, antes omitida, agora mostra **0 observações contra 39.606 pessoas publicadas, −100%**. O fechamento do total estadual não representa a população rural ausente.

No Distrito Federal, a célula rural também tem zero observações, contra 51.501 presentes publicados. O total estimado permanece 43.385,83, contra 139.796 publicados (−68,96%); nenhum peso foi alterado para corrigir essa diferença. As comparações de Rondônia, Acre, Roraima e Amapá continuam mostrando discrepâncias urbano/rurais importantes, apesar dos totais estaduais calibrados.

## Universos e classificações

Presença e sexo são definidos por conjuntos positivos de códigos válidos: presentes V202 em 1, 2, 5, 6; residentes em 1, 2, 3, 4; homens em 1, 3, 5; mulheres em 2, 4, 6. Nenhum `else` atribui sexo ou residência a NA. Situação: urbana em V118=1 ou 3; rural em 5; o resto permanece desconhecido. Totais do universo conhecido incluem as observações com idade, situação ou cor não classificáveis; as decomposições não ganham categorias inventadas para forçar a soma.

As linhas 855822, 951432 e 951433 não têm V202. Na comparação anterior entravam como mulheres presentes, residentes e da última faixa de idade. Seu peso final soma **221,3363**. Com presença conhecida, o total de presentes é 70.094.959,83, contra 70.095.181,16 sob aquela regra antiga. A soma de totais estaduais já arredondados pode diferir em uma unidade do arredondamento do total nacional.

O dicionário primário transcrito em `read_guides/1960_codigo_do_censo.csv` distingue V204=0 (meses), 1 (anos), 5 (mais de 99 anos) e 9 (ignorado), nas linhas 18–21. A revisão preserva essa distinção. A base contém **1.448 idades declaradas ignoradas**, das quais 1.208 são de presentes conhecidos (peso final 93.901,37), além de **11 idades não classificáveis**. NA não é transformado em 999.

A política da revisão é explícita: Q1 inclui a idade declarada ignorada na faixa final; Q2 a inclui na faixa final que diz “e ignorada” e, por convenção de divulgação, nos totais cumulativos 5+/10+/15+. Nos quadros 3, 4 e 5 e na tabela definitiva 40, o limite de idade exige idade conhecida. A tabela 33 publica 70+ e ignorada separadamente, e a validação agora preserva ambas. Essa política pode fazer a tabela 40 divergir dos controles da calibração vigente, que incluem idades ignoradas; não houve recalibração. Uma mudança dessa convenção deverá ser documentada e avaliada separadamente.

Há **151 domicílios com V101 desconhecido**, que a regra antiga incluía em particular por simples exclusão de “coletivo”. Eles ficam no diagnóstico e fora das estimativas de domicílios particulares confirmados. A revisão não resolveu o recorte de permanência/tipo V102 da tabela 7: a correspondência fina dos universos domiciliares continua pendente.

Em cor, V206=8 significa Índia e 9 ignorado (`1960_codigo_do_censo.csv`, linhas 32–37). A base contém 198 pessoas com código 8, peso final 16.501,16, e cinco com cor não classificável. Não foram convertidas automaticamente em “sem declaração”. O código 8 permanece identificado, participa dos totais e aparece no diagnóstico como categoria sem coluna publicada específica; a correspondência histórica com as categorias da tabela 37, inclusive eventual inclusão em pardos, **ainda precisa de confirmação pela fonte**. Logo, reconstrução computacional de uma célula não significa que toda sua harmonização semântica foi validada.

O diagnóstico registra também alfabetização não classificada. A grande quantidade inclui menores fora do universo do quesito e não deve ser interpretada toda como corrupção ou perda. Os motivos se sobrepõem: suas contagens não se somam para obter um número de registros defeituosos.

## Calibração, validação e testes

Fechar as 176 células etárias do quadro 1 e oito totais de leitores do quadro 2 com `censobr_weight_1965` verifica as restrições impostas ao ajuste. Não é uma validação externa dos cartões nem identifica os pesos históricos do IBGE. As discrepâncias dos outros quesitos, as células sem suporte e o confronto com fontes independentes são evidências adicionais, com limites próprios.

Nos definitivos, não se atribuiu a todas as células de uma tabela o rótulo simplificador “calibrada” ou “independente”: algumas foram restrição, algumas são somas ou complementos dessas restrições e outras não foram impostas. A coluna `referencia_estimada` sinaliza as 17 UFs cujos controles procedem da amostra de 25%; nas onze restantes segue-se a origem de contagem completa documentada no gabarito. Isso não transforma as referências estimadas em totais de universo.

[`test_validacao_amostra_127.R`](test_validacao_amostra_127.R) prepara regressões isoladas para os quatro estados de célula, referência zero, duplicação de chaves, presença/situação desconhecidas, 70+/ignorada, domicílio sem residentes e peso de residente ausente após o join. Quando a execução de R voltar a ser autorizada, escreve apenas em uma pasta temporária e não chama o pipeline. **Esses testes R não foram executados.** A revisão estática e `git diff --check` não acusaram problema de whitespace; a auditoria independente Python passou seus testes de agregação/NA e os checks dos parquets. A equivalência de execução entre a implementação R revisada e a auditoria Python continua a ser verificada em R antes de regenerar as saídas oficiais.
