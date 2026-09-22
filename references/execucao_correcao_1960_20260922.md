# O que foi executado e o que ainda impede fechar os dados de 1960

Esta nota acompanha a execução autorizada em 22/09/2026. Os arquivos em `data_raw/` e os arquivos publicados em `data/` não foram substituídos. Uma correção no programa, um teste aprovado e um arquivo completo corrigido são três coisas diferentes; as seções abaixo distinguem essas situações.

**Adendo posterior, autorizado pelo usuário:** a [recuperação de cartões](recuperacao_cartoes_1960_20260922.md) implementou e conferiu 29 cartões da fonte25 para 72 pessoas já presentes na127, em arquivos separados. Ela substitui a pendência de autorização mencionada no histórico abaixo, mas não resolve todos os vínculos: restam 1.339 pessoas em 526 grupos da lista anterior, além das demais pendências. O exemplo BH40090/004 continua não aprovado. Os parquets completos127 e seus pesos não foram refeitos.

## Resultado dos cinco pedidos

| Pedido | Resultado efetivamente entregue | O que não está concluído |
|---|---|---|
| Investigar o erro do R | Falha mínima reproduzida; causa identificada e execução isolada corrigida e testada. | Isso não prova a causa de todos os episódios antigos nem altera a instalação global. |
| Testar e gerar relatórios atuais | Suítes pequenas aprovadas; quatro relatórios completos gerados com entradas preservadas. | Esses relatórios descrevem os arquivos antigos, não uma base integral corrigida. |
| Corrigir registros | Três reparos de texto, 82 vínculos com cartões existentes e decisões explícitas para 4.543 linhas repetidas implementados e testados; posteriormente, 29 cartões recuperados da fonte25 para 72 pessoas, em recorte separado. | Há casos sem prova suficiente; a reconstrução integral de 1,27% está bloqueada. |
| Completar conferências | Domicílios, faixas de aluguel e estado conjugal implementados e testados. | Códigos desconhecidos, famílias não resolvidas e algumas convenções de idade ainda impedem resultados completos. |
| Rever e recalcular pesos | Regras corrigidas; pesos de 25% recalculados nas 17 UFs, com 34 cópias completas conferidas em arquivos separados. | 1,27% aguarda resolução dos registros e decisões sobre reconstrução. |

**Portanto, a execução avançou, mas o conjunto dos cinco pedidos ainda não está encerrado.** Não há base completa nova homologada nem publicação. “Área separada” ou *staging* significa apenas uma pasta de trabalho que não substitui os dados atuais.

Os logs, relatórios e tabelas antes/depois ligados nesta nota estão em `tmp/`, que não é versionado no Git. Devem ser preservados enquanto esta auditoria estiver aberta; não são cópias de segurança nem uma publicação. O código, os testes e os manifestos de decisões ficam em `R/`, `references/` e `read_guides/`.

## O erro do R deixou de ocorrer nos testes controlados

Foi possível reproduzir e explicar a falha sem usar os dados do censo. O pacote `cli`, carregado por outros pacotes, falhava no encerramento quando o processo não recebia a informação da arquitetura do Windows. O executor de testes passou a consultar e fornecer a arquitetura verdadeira apenas ao processo que inicia. R, pacotes, configuração global e `renv.lock` não foram alterados.

A explicação, os testes com e sem a informação e o comando para repetir estão no [diagnóstico do Rscript](diagnostico_rscript_1960_20260922.md). Depois desse ajuste, as suítes pequenas de integridade, validação e pesos terminaram com código de saída zero. O relatório completo também terminou normalmente. Não se está apenas escondendo a janela de erro: uma execução que falhe continua sendo reprovada.

## Os relatórios com os pesos atuais foram gerados

São relatórios novos sobre **os arquivos que já existiam**, incluindo seus problemas ainda não corrigidos. Não houve reconstrução geral nem troca de pesos nesta etapa. O [registro de entradas](../tmp/execucao_1960_20260922/relatorios_pesos_atuais/entradas.csv) contém nomes, tamanhos e verificações de conteúdo antes/depois; todos permaneceram iguais durante a execução. O [log](../tmp/execucao_1960_20260922/30_relatorios_pesos_atuais.log) termina com saída zero.

| Relatório | Conferências por peso | Com registros e classificação suficiente | Sem registros nessa categoria | Classificação ainda incompleta |
|---|---:|---:|---:|---:|
| [Amostra de 25%, resultados definitivos](../tmp/execucao_1960_20260922/relatorios_pesos_atuais/amostra_25/validacao_definitivos.csv) | 1.020 | 923 | 11 | 86 |
| [Arquivo combinado, resultados definitivos](../tmp/execucao_1960_20260922/relatorios_pesos_atuais/compilada/validacao_definitivos.csv) | 1.740 | 1.528 | 50 | 162 |
| [Amostra de 1,27%, resultados preliminares](../tmp/execucao_1960_20260922/relatorios_pesos_atuais/amostra_127/calibracao_1965_validacao.csv) | 2.220 | 303 | 0 | 1.917 |
| [Amostra de 1,27%, resultados definitivos](../tmp/execucao_1960_20260922/relatorios_pesos_atuais/amostra_127/calibracao_definitivos_validacao.csv) | 1.932 | 1.571 | 80 | 281 |

Nas duas amostras existem dois pesos e, portanto, duas versões de cada conferência. As quantidades da tabela são por peso, não devem ser somadas como se fossem pessoas. No arquivo combinado há apenas o peso final. Nenhuma conferência ficou ausente por falta de implementação: todas estão no relatório; algumas ainda não admitem um resultado completo por problemas dos registros ou por uma convenção de classificação pendente.

**Exemplo concreto: Rondônia rural.** O relatório agora mostra que a amostra contém zero homens e zero mulheres classificados como pessoas presentes da área rural, enquanto a publicação apresenta 23.324 homens e 16.282 mulheres. São 39.606 habitantes na referência, mas nenhuma pessoa rural observada na amostra utilizada. Nenhuma pessoa foi criada para preencher essa diferença. Aumentar os pesos de pessoas urbanas também não produz uma observação rural.

**Exemplo de resultado incompleto.** Uma pessoa com código danificado pode pertencer a mais de uma categoria possível. O relatório preserva a soma das pessoas seguramente classificadas em `valor_parcial`, mas não a apresenta como o total completo. Uma única pessoa nessas condições pode afetar diversas conferências; por isso 1.917 conferências incompletas não significam 1.917 pessoas defeituosas. A regra regional é conservadora e está descrita no próprio relatório.

## As conferências de domicílios, aluguel e estado conjugal foram ampliadas

A tabela de domicílios particulares permanentes foi implementada também na amostra de 25% e no arquivo combinado. Os moradores são recontados pela lista de pessoas, separando ausência de lista, código desconhecido e domicílio que contém somente visitantes.

Antes de processar todas as UFs, duas conferências reais pequenas passaram: Fernando de Noronha tinha 62 domicílios particulares permanentes e 294 moradores na amostra de 25%; Roraima tinha 58 domicílios e 399 moradores no arquivo combinado. As somas com os pesos atuais também coincidiram com a apuração independente desses exemplos.

Para aluguel, agora são calculadas as seis faixas publicadas. A linha “sem declaração” refere-se à **condição de ocupação** do domicílio, não a uma sétima faixa de aluguel. Para estado conjugal, a atividade dos inativos pode ser obtida pela atividade do chefe da mesma família, quando esse chefe é identificado sem ambiguidade. Chefes não localizados na lista ou múltiplos, ramo desconhecido e idade de elegibilidade ainda não definida continuam assinalados; não se escolhe um chefe qualquer para completar o quadro. Um chefe que consta da lista como morador temporariamente ausente é uma situação diferente e pode ser usado nessa conferência.

As páginas originais, as regras e os testes estão na [nota das conferências completadas](microdata_1960_validacao_etapa4_20260922.md). Ela também explica por que as referências domiciliares são estimadas por amostra mesmo nas UFs com apuração pessoal pelo universo, e registra dois metadados inadequados no CSV histórico de referência.

## Correções dos registros: decisões aplicáveis e testadas

As decisões de duplicatas e vínculos passaram a exigir a linha original e o texto esperado. Uma decisão deixa de valer se o conteúdo da entrada mudou. O pipeline acompanha os arquivos de decisão, para não reutilizar resultados antigos após uma revisão desses arquivos. Nenhum registro é ligado à família anterior apenas por proximidade; a presença de um cônjuge também não basta para inventar uma nova família.

Os casos concretos da Paraíba, Pernambuco, Bahia e Rio Grande do Sul passaram nos testes com trechos reais do arquivo bruto. Em seguida, a conferência de repetições foi ampliada a 642 boletins de dez UFs. Foram comparados os textos originais e 25 quesitos pessoais com a fonte de 25%, exigindo cartão único, contagens coerentes e ordens pessoais válidas.

O [manifesto de duplicatas](../read_guides/1960_amostra_127_duplicatas.csv) registra 4.543 linhas, correspondentes a 2.266 conjuntos de respostas repetidas. Dessas linhas, 2.246 podem ser removidas com apoio da outra fonte e 2.297 devem permanecer. Isso conserva **31 registros pessoais que a regra antiga excluía indevidamente**. Não é uma regra de apagar todos os que dão respostas iguais: a quantidade comprovada de pessoas é preservada, mesmo quando não é possível distinguir seus perfis.

Exemplo: no boletim da Paraíba, os dois pares de filhos com respostas iguais e idade ignorada continuam sendo quatro pessoas. Em um boletim de Pernambuco, quatro ocorrências do mesmo perfil de menino de um ano correspondem a **dois meninos** na fonte de 25%; ficam duas, não uma nem quatro. Quando cópias são idênticas, escolher as primeiras linhas é somente uma convenção reproduzível de armazenamento, não uma identificação de qual menino seria qual.

O [manifesto de vínculos](../read_guides/1960_amostra_127_vinculos.csv) contém **82 correções comprovadas**. Entre os oito casos iniciais da Bahia, a menina da linha 302261 passa para o cartão 302453. As seis pessoas das linhas 315134–315139 passam para o cartão 315732; a menina 315736 passa para o cartão 315168. Os dois últimos destinos ficam com sete e treze pessoas, respectivamente. O distrito da menina não foi copiado do cartão: a divergência original ficou preservada.

A ampliação aprovou outras 74 pessoas, em 28 cartões reais de oito UFs. Cada destino foi confirmado pela composição familiar inteira e pelos quesitos pessoais na fonte de 25%, não pela posição da linha no arquivo. O teste incluiu todas as 152 pessoas desses grupos familiares: continuaram sendo 152 pessoas e 28 famílias, sem exclusões, criações ou mudanças nas respostas originais. Outras 55 candidatas que passaram pelo primeiro confronto não foram aprovadas: seis tinham situação urbana/rural divergente, uma dependia de outra pessoa não distinguível e 48 tinham distrito do cartão não confirmado. A [nota da ampliação](../tmp/execucao_1960_20260922/integridade_127_vinculos_entrega.md) explica os filtros e permite localizar cada registro.

Três reparos de texto foram corrigidos, limitando a mudança aos campos comprovados: RS951431, BA387715 e BA387853. No RS, escolaridade foi restaurada sem preencher os dezesseis espaços em branco posteriores. Os testes também impedem usar um manifesto quando o texto original ou a quantidade de ocorrências diverge da evidência conferida.

O [teste completo dos casos aprovados](../tmp/execucao_1960_20260922/integridade_127_vinculos_depois_01.log) passou, incluindo os 82 vínculos, as 4.543 linhas do manifesto de duplicatas e os três reparos. As [tabelas antes/depois](../tmp/integridade_127_bea074296e09/) permitem conferir os resultados. O mesmo teste, antes de acrescentar as 74 novas decisões, interrompia nos vínculos sem confirmação. Isso demonstra as correções implementadas; **não significa que o parquet completo já foi substituído**.

Ainda há impedimentos reais para reconstruir e aprovar toda a amostra de 1,27%:

- 1.417 conjuntos de respostas repetidas sem decisão, envolvendo 2.836 linhas. Dentro deles estão 573 exclusões antigas ainda sem comprovação; outras repetições já eram mantidas pelo procedimento anterior.
- 1.411 pessoas em 555 grupos sem cartão de família confirmado.
- 63 vínculos diretos com município divergente ou ausente. Não foram “corrigidos” copiando o município da família.
- Um cartão de família convivente em São Paulo sem família principal comprovada. A posição no arquivo não basta para decidir se deve abrir outro domicílio.

Listas e contagens estão em [pendências após a ampliação](../tmp/execucao_1960_20260922/integridade_127_pendencias_final.json) e [conflitos de vínculo](../tmp/execucao_1960_20260922/integridade_127_guardas_vinculos.json). Esses grupos não devem ser somados sem verificar sobreposições. O programa interrompe antes da exportação integral; não simplesmente avisa e prossegue.

Isso não significa que toda informação para os casos restantes inexista, nem que se tenham esgotado todas as formas possíveis de reconstrução. Parte dos vínculos tem candidatos na fonte de 25%, mas ainda há perfis não únicos, respostas ou geografia divergentes e composição familiar sem confirmação integral. Outra parte está em UFs sem essa fonte disponível. Ficaram fora desta implementação os casos em que o cartão familiar existe somente na fonte de 25%: recriar esse cartão em 1,27%, com sua origem explicitamente marcada, exige uma regra de reconstrução diferente de remapear pessoas para cartões já existentes no arquivo. Essa decisão não foi tomada silenciosamente. Nas repetições pendentes, manter todas ou excluir as excedentes também não demonstra, por si só, quantas pessoas distintas existiam.

## Pesos de 25% recalculados nas 17 UFs, em área separada

O piloto de **Fernando de Noronha e Sergipe** terminou normalmente e gravou novos parquets em [pesos25_piloto_20260922_092755](../tmp/execucao_1960_20260922/pesos25_piloto_20260922_092755/). Os pesos de produção permanecem intactos. Antes do ajuste, a quantidade de presentes em cada domicílio foi conferida diretamente pela lista de pessoas. Depois, foram conferidos os identificadores, os limites dos pesos e todas as somas usadas no ajuste. Os treze arquivos de entrada e código permaneceram com o mesmo conteúdo durante o piloto.

Em Sergipe, **25 leitores com idade declarada ignorada** não entravam antes na conta usada para ajustar os pesos. A regra agora os inclui, conforme a convenção da tabela publicada; idade danificada continua sendo um problema diferente e não é convertida automaticamente em ignorada.

| Leitores em Sergipe, com os pesos aplicados | Pesos antigos, conta corrigida | Referência publicada | Novos pesos |
|---|---:|---:|---:|
| Homens | 103.326,57 | 103.279 | 103.279 |
| Mulheres | 115.237,18 | 115.189 | 115.189 |

Aqui houve recálculo, não somente mudança na apresentação da diferença. Os 44.059 pesos domiciliares de Sergipe mudaram entre aproximadamente −0,757% e +0,259%; 146 totais de controle foram satisfeitos dentro da tolerância numérica. Em Fernando de Noronha, foram ajustados 75 domicílios a quatro controles. Os [controles de Sergipe](../tmp/execucao_1960_20260922/pesos25_piloto_20260922_092755/diagnosticos/se/controles.csv), a [comparação de pesos](../tmp/execucao_1960_20260922/pesos25_piloto_20260922_092755/diagnosticos/se/pesos_domicilios_antes_depois.csv) e o [log do piloto](../tmp/execucao_1960_20260922/preparacao_piloto_pesos25_01.log) estão preservados.

Essas referências são elas próprias estimativas da amostra de 25%. Fazer o ajuste reproduzi-las não transforma seus valores em totais populacionais conhecidos nem prova ausência de erro amostral.

Os pesos completos de 1,27% não devem ser recalculados sobre vínculos e multiplicidades ainda sem resolução. Variâncias dos pesos calibrados continuam adiadas, conforme combinado.

### Como as outras 15 UFs foram recalculadas

A conferência prévia examinou 14.983.769 pessoas e 3.066.365 domicílios das 17 UFs, sem exceções nas chaves, classificações e contagens verificadas. Confirmou 9.395 leitores presentes com idade declarada ignorada. Isso permite tentar os ajustes, mas não prova que todos os controles poderão ser satisfeitos. O [registro dessa conferência](../tmp/execucao_1960_20260922/preflight_25_classificacoes_LEIA_ME.md) explicita as verificações e seus limites.

Foi preparado um executor que usa apenas as colunas necessárias ao cálculo, uma UF por vez, conservando os arquivos completos. A primeira tentativa foi bloqueada antes de iniciar R, por haver apenas cerca de 1 GiB livre; esse [bloqueio inicial](../tmp/execucao_1960_20260922/pesos25_reduzido_20260922_094717_846529/resultados/se_nao_iniciado.json) foi preservado. Quando a memória voltou a ficar disponível, uma nova tentativa reproduziu **exatamente todas as colunas e os 146 controles** do piloto completo de SE. O pico desse processo foi aproximadamente 442 MiB. Não foi necessário encerrar outro trabalho nem relaxar as proteções.

Só então foram processadas as outras 15 UFs. Todas terminaram com saída zero, sem alterações nas entradas e sem afrouxar controles ou limites. SP, o maior caso, usou aproximadamente 2,32 GiB no pico e deixou pelo menos 10,07 GiB livres durante a execução. A [raiz dos recálculos](../tmp/execucao_1960_20260922/pesos25_reduzido_20260922_095713_201741/) contém saídas auxiliares, pesos com identificadores, diagnósticos antes/depois, logs por UF e [resumo das 15 UFs](../tmp/execucao_1960_20260922/pesos25_reduzido_20260922_095713_201741/resumo_restantes.json).

No conjunto das 17 UFs, foram calculados pesos para 3.066.365 domicílios, transmitidos às 14.983.769 pessoas listadas. Os pesos novos ficaram entre 1,000047 e 11,754717, dentro dos limites estabelecidos de 1 a 12. Em relação aos pesos antigos, as mudanças extremas foram aproximadamente −4,17% e +5,57%, ambas em SP. A coluna alternativa de pesos inteiros do método IBGE não mudou. Os [resultados por UF](../tmp/execucao_1960_20260922/pesos25_reduzido_20260922_095713_201741/resumo_metricas_pesos.json) permitem conferir cada faixa, controle e diferença.

Uma [conferência independente](../tmp/execucao_1960_20260922/qc_pesos25_independente_resultado.json) refez os 5.039 totais usados nos ajustes diretamente a partir das pessoas, sem reutilizar a matriz montada pelo programa R. Todos conferiram dentro da tolerância. Também verificou todas as linhas quanto às chaves, contagens, quatro colunas de pesos e transmissão do peso do domicílio à pessoa. Isso confirma a execução numérica e a correspondência entre os arquivos; não é uma prova histórica de cada vínculo familiar da fonte de 25% nem torna verdadeiros os totais estimados da referência.

Em SP, por exemplo, os pesos antigos, aplicados à contagem corrigida de leitores, davam 4.097.859,19 homens, diante de 4.089.706 na referência. Os novos pesos reproduzem 4.089.706 dentro da precisão numérica. Para as mulheres, a soma passou de 3.565.911,11 para 3.557.693, que é a referência publicada. A correção incluiu 4.172 leitores presentes de idade declarada ignorada nessa UF; não lhes atribuiu uma idade inventada. Essa é uma mudança efetiva nos pesos, distinta de apenas tornar a divergência visível.

Essas saídas reduzidas não contêm todas as respostas dos questionários e continuam identificadas como auxiliares. Sua reunião às colunas completas dos arquivos brutos foi concluída e conferida, como descrito abaixo. A [nota dos pesos](microdata_1960_pesos_piloto_20260922.md) reúne os resultados, limites e comandos reproduzíveis.

### As cópias completas de 25% estão disponíveis

O [índice dos 34 parquets completos](../tmp/execucao_1960_20260922/pesos25_completo_15_fixo_01/indice_34_parquets_completos.json) aponta exatamente os dois arquivos de cada uma das 17 UFs: 3.066.365 domicílios, com 48 colunas, e 14.983.769 pessoas, com 71 colunas. FN vem do piloto completo; SE e as outras 15 UFs vêm da recomposição conferida. Não é necessário juntar pastas manualmente nem escolher entre tentativas pelo nome: o índice registra os caminhos, contagens e verificações de conteúdo dos arquivos aprovados.

Antes de gerar as 15 UFs, SE foi recomposto e comparado integralmente ao piloto completo, com igualdade de valores, campos ausentes, tipos e ordem. Nas demais UFs, a conferência exigiu igualdade de todas as respostas originais, das nove colunas calculadas, das chaves e da ordem; as saídas foram reabertas para nova comparação. Ao construir o índice, os 34 arquivos novos e os 68 originais de entrada/comparação foram reconferidos por seus identificadores de conteúdo. Os originais permaneceram iguais. Nenhuma coluna do questionário foi copiada do arquivo ponderado antigo para completar uma falta: a base da recomposição foi o arquivo bruto atual.

Uma trava do Windows impediu a renomeação de pastas em duas tentativas iniciais. Elas foram preservadas e excluídas do índice. A execução final não move pastas: cada UF recebe `APROVADO.json` somente após todas as conferências. A existência de uma pasta ou parquet isolado não prova aprovação. A causa externa das travas não foi demonstrada; nenhuma permissão ou processo alheio foi alterado. Os 16 testes do contrato final passaram, incluindo falha após escrita sem aprovação. As 15 UFs terminaram em aproximadamente três minutos, com pico observado de memória de cerca de 446 MiB no processo Python.

São cópias completas **em área separada**, não substituições dos dados atuais nem arquivos publicados. A recomposição preserva campos e tipos, mas não replica metadados R serializados que descreviam a tabela anterior; essa diferença está registrada nos manifestos. A etapa de publicação e padronização final do pacote não foi executada.

### Relatório integrado com os pesos novos

O [novo relatório de validação de 25%](../tmp/execucao_1960_20260922/validacao25_novos_17ufs_20260922_101103_802707/relatorio_novo/validacao_definitivos.csv) reúne as 17 UFs, sem substituir o relatório dos pesos antigos. Tem 2.040 resultados: 1.846 com observações e classificação suficiente, 172 com classificação incompleta e 22 sem observações. Como há dois pesos, isso corresponde a 923, 86 e 11 resultados por peso. Nenhuma UF ficou de fora; não há chave repetida, cálculo não implementado ou peso ausente.

As 172 conferências incompletas pertencem à tabela de domicílios. **A mudança dos pesos não fez desaparecer essas pendências.** A verificação comparou as indicações de problemas e as contagens em cada resultado antes/depois: permaneceram iguais, não apenas seus totais. O relatório integrado também coincide exatamente com a reunião dos relatórios posteriores de cada UF. Os 75 arquivos de entrada/código/gabaritos usados nessa geração permaneceram iguais durante a execução. [Resumo e comparações](../tmp/execucao_1960_20260922/validacao25_novos_17ufs_20260922_101103_802707/resumo_leitura.json) permitem auditar isso.

### O que foi corrigido nos metadados de Fernando de Noronha

Na amostra de 1,27%, o cálculo definitivo de FN já partia de peso 4, mas a coluna que descrevia essa base dizia aproximadamente 78,74. O programa agora grava base 4 e calcula o multiplicador final em relação a 4. O diagnóstico também usa essa base: um peso final 4 corresponde a multiplicador 1, não a 0,05. O peso preliminar de 1965 manteve sua própria base anterior; não foi redesenhado nessa correção. Os testes de FN e de outra UF passaram, incluindo leitura e gravação de arquivos sintéticos, em [teste final dos pesos](../tmp/execucao_1960_20260922/pesos_diagnostico_fn_depois_01.log). Isso corrige o código e sua descrição; os parquets reais de 1,27% ainda não foram regravados.

## Sequência necessária para encerrar

1. Resolver os casos de 1,27% listados acima com evidência suficiente sobre família e quantidade de pessoas. Separar o exame dos candidatos ainda ambíguos da decisão de reconstruir cartões ausentes usando outra fonte, com procedência explícita. Quando não for possível decidir, preservar a indeterminação: não excluir pessoas, criar famílias ou mudar municípios por suposição.
2. Confirmar os universos ainda pendentes nas tabelas preliminares, inclusive o tratamento da idade declarada ignorada nos cálculos com idade mínima. A convenção dos resultados definitivos não deve ser transplantada automaticamente para outra publicação. As escolhas de controles/agregações/reescala do método vigente não foram substituídas por outra proposta; a conferência numérica não é uma avaliação de todas as alternativas de desenho.
3. Somente após essas decisões, reconstruir 1,27% em área separada, conferir contagens e respostas antes/depois, recalcular seus pesos e refazer as conferências. A compilação final e qualquer substituição/publicação devem aguardar essa aprovação conjunta.

Acertar uma tabela aos totais de referência não substitui essas verificações. Sobretudo, eliminar casos duvidosos só para o programa terminar mudaria a amostra e exigiria uma justificativa metodológica que esta execução não inventou.
