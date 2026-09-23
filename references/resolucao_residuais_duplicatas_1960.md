# Repetições: o que esta rodada resolveu e o que continua sem prova

Data: 22 de setembro de 2026. Esta nota descreve a implementação posterior à investigação. O [relatório investigativo anterior](investigacao_residual_duplicatas_1960.md) continua preservado como registro do que se sabia naquele momento; suas propostas não devem ser confundidas com decisões já aplicadas naquela data.

## Resultado concreto

Foram acrescentadas **dez decisões de manter, relativas a cinco pares de registros pessoais**. Nenhuma pessoa foi excluída nesta rodada. Também não houve nova restauração de pessoa anteriormente excluída: essas dez linhas já não constavam das exclusões históricas. O que mudou foi a existência de uma decisão explícita, fundamentada e conferível, para que a etapa de duplicatas não as trate como pendência sem explicação.

A lista completa de decisões contém agora 6.461 linhas: 3.725 para manter e 2.736 para remover. Estes são totais do **manifesto de decisões**, não o número de pessoas no censo. A função de exclusão de duplicatas não foi flexibilizada: igualdade de respostas continua insuficiente para apagar uma pessoa.

O problema original é simples de imaginar. Dois filhos podem ter o mesmo sexo, a mesma idade declarada — ou idade ignorada — e as mesmas respostas a todas as perguntas disponíveis. Apagar o segundo porque seu texto coincide com o primeiro pode apagar um irmão legítimo. Nesta revisão, a existência de **duas ocorrências na outra cópia**, dentro de uma composição familiar corroborada, fundamenta manter ambas; não permite dizer qual ocorrência é qual pessoa por nome, pois os arquivos não fornecem nomes.

## Como chegamos às cinco decisões

“Pasta e boletim” são números de arquivamento do questionário. “Cartão familiar” é a linha com informações da família e do domicílio. “Composição” significa o conjunto de respostas de **todos** os integrantes, contando quantas vezes cada perfil aparece. Duas ocorrências idênticas contam como duas, não uma.

| Família no arquivo de 1,27% | Família localizada na cópia de 25% | Linhas pessoais agora formalmente mantidas | Linhas correspondentes na fonte de 25% |
|---|---|---|---|
| CE, pasta 15004, boletim 034 | CE, 14990/034 | 131528 e 131530 | 701187 e 701188 |
| SP, 63788/181 | SP, 63788/198 | 774112 e 774116 | 3827584 e 3827585 |
| RS, 82192/031 | RS, 82192/039 | 986867 e 986870 | 786676 e 786677 |
| RS, 82894/010 | RS, 82892/190 | 1009572 e 1009575 | 1277288 e 1277289 |
| RS, 82974/221 | RS, 82976/100 | 1014154 e 1014156 | 1331893 e 1331894 |

Nos dois últimos casos, as famílias têm respectivamente dez e seis pessoas. O cartão, o município, o distrito, a situação urbana/rural e a composição inteira conferem. Há respectivamente três e duas pessoas cujas respostas são exatas nas duas cópias e cujo perfil ocorre uma única vez na UF de 1,27%. Esses integrantes funcionam como pontos de apoio para localizar a família; não se tomou apenas a semelhança das duas crianças como prova.

Em São Paulo e no primeiro caso gaúcho havia uma objeção adicional: já existia outro cartão de 1,27% com o número do boletim encontrado na fonte de 25%. Portanto, era necessário conferir se estávamos roubando a correspondência de outra família. A revisão localizou também **o grupo próprio desse outro cartão**:

- O cartão paulista 774208, boletim 198, contém cinco pessoas e corresponde ao boletim 215 da fonte de 25%, com composição integral e três pontos de apoio exclusivos. Não corresponde à família-alvo de sete pessoas, que aparece no boletim 198 da outra cópia.
- O cartão gaúcho 986881, boletim 039, contém nove pessoas e corresponde ao boletim 250 da fonte de 25%, com composição integral e três pontos de apoio exclusivos. Não corresponde à família-alvo de quatorze pessoas, encontrada no boletim 039 da outra cópia.

Assim, os números de arquivamento se deslocam, mas os dois grupos continuam distinguíveis. Os textos integrais de ambos os grupos, inclusive as alternativas rejeitadas, estão na [prova dos cartões alternativos](resolucao_residuais_duplicatas_alternativos_1960_evidencias.json). Nenhum número de pasta ou boletim foi reescrito.

### Por que o caso do Ceará exigiu uma justificativa diferente

No Ceará, exigir sempre duas pessoas de perfil exato e exclusivo teria rejeitado uma combinação documental mais informativa. O adulto da linha 131522 é único na UF de 1,27% e também na fonte estadual de 25% **quando se comparam 24 campos pessoais**. O campo deixado fora dessa comparação é V216, o ano do casamento: nesse adulto, aparece 00 numa cópia e 63 na outra. A diferença foi preservada, não corrigida nem considerada equivalente.

Além desse adulto, concordam os nove integrantes, suas quantidades, o cartão familiar e a geografia. Não foi encontrada outra família compatível na fonte de 25%, inclusive admitindo uma ou duas ocorrências para o perfil infantil repetido. Tampouco apareceu outra família de 1,27% contendo esse adulto de perfil exclusivo.

A localização também é corroborada por **145 famílias** com composição de 24 campos, cartão e geografia conferidos, nas quais pasta 15004 na cópia de 1,27% corresponde a pasta 14990 na cópia de 25%, mantendo o boletim. Esse número inclui o caso-alvo: são **144 outras famílias**. Seus textos foram relidos nas fontes. O contexto mais amplo tinha 176 coincidências de composição, mas 31 divergiam no cartão e não foram usadas como corroboradoras integrais.

Essa combinação justifica, **neste caso**, conservar as duas ocorrências infantis. Ela não demonstra uma regra universal de renumeração, não valida o ano do casamento e não estabelece identidade civil. Os testes recusam o caso se faltar a exclusividade do adulto em qualquer das fontes, aparecer outra composição familiar candidata, divergir o cartão ou desaparecer a correspondência contextual. A [prova específica do Ceará](resolucao_residuais_duplicatas_ce_1960_evidencias.json) contém os critérios e os textos das 145 famílias.

## Uma proteção nova: coincidência de famílias inteiras

O problema não se limita a dois irmãos dentro de uma família. A auditoria nacional encontrou dez conjuntos nos quais **cartões diferentes e seus integrantes** têm as mesmas respostas, embora pasta, boletim ou identificador interno difiram. São 21 cartões e 54 pessoas. Esses conjuntos não devem ser somados mecanicamente ao inventário de pares pessoais, pois são outro tipo de comparação.

O novo [manifesto de coincidências familiares](../read_guides/1960_amostra_127_familias_coincidentes.json) trata cada conjunto explicitamente. A proteção implementada na reconstrução familiar não apaga nem funde registros: compara cartão, geografia e composição, relê os textos da fonte de 25% e interrompe a execução se a coincidência continuar sem disposição comprovada.

| Disposição | Conjuntos | Cartões | Pessoas | Significado |
|---|---:|---:|---:|---|
| Preservar distintos entre fontes | 5 | 10 | 12 | A outra cópia conserva boletins separados e a composição de cada um é corroborada. |
| Permanecer pendente, com bloqueio | 5 | 11 | 42 | Não há contraprova integral suficiente para homologar ou excluir. |

Os cinco casos de preservação são MG41848/115 e 127; PE22060/020 e 039; BA31374/035 e 087; BA31608/143 e 201; BA31608/250 e 251. “Preservar distintos entre fontes” quer dizer conservar a separação documentada nos arquivos. **Não significa provar que dois indivíduos de mesmo perfil são duas pessoas civis diferentes, nem que a coleta nunca repetiu questionários.**

Continuam bloqueados:

- **Amazonas, pasta 02104:** as famílias de quatro pessoas dos boletins 248/250 e de onze pessoas dos boletins 249/251 têm composição repetida. Os integrantes foram reordenados; não são dezessete linhas copiadas na mesma sequência. A fonte estadual de 25% não está disponível nesta cópia local. Não se escolheu arbitrariamente qual metade apagar.
- **Maranhão, 10820/155 e 236:** os cartões e o casal têm respostas detalhadas coincidentes, mas falta a fonte estadual de 25% para contraprova.
- **São Paulo, 60118/109, 116 e 220:** há boletins separados na fonte de 25%, porém as respostas dos cartões e, em parte, dos integrantes divergem. Existirem números diferentes não basta para aprovar a correspondência.
- **Pernambuco, 21322/167 e 179:** há divergências no cartão e no ano do casamento que excedem a diferença controlada 00/63. Não foram convertidas em equivalências.

Um manifesto adulterado não pode liberar esses casos apenas mudando o rótulo “pendente” ou um indicador para “verdadeiro”: a função confere os textos e respostas nas fontes efetivas. Os guias de leitura e as fontes têm assinaturas SHA-256, que funcionam como uma identificação exata da versão dos arquivos usada na prova.

## As pendências que não foram disfarçadas de solução

O [registro nominal das disposições](resolucao_residuais_duplicatas_disposicoes.json) contém todos os 463 conjuntos do inventário inicial. Cinco receberam a decisão de preservação acima; **458 conjuntos, abrangendo 918 linhas, continuam sem decisão factual suficiente** nesse inventário. Entre essas linhas, 127 haviam sido excluídas pela regra histórica sem prova ainda suficiente. Esta rodada não as certifica como duplicatas nem como irmãos distintos.

As categorias anteriores dos 458 pendentes são: 176 sem fonte estadual de 25%; 182 com divergências em outros integrantes; 55 sem correspondência do perfil repetido nos 24 campos na chave antiga; 15 com divergência adicional no ano do casamento; 13 com divergência geográfica; 12 com mais ocorrências na fonte de 25%; três com divergência de espécie/geografia do cartão; um sem cartão único na fonte de 25%; e um de texto corrompido. As categorias descrevem o motivo anterior e preservam o histórico: **não substituem a recontagem integrada após os novos reparos de texto e vínculo desta rodada**.

Os oito candidatos fora de chave que não viraram decisão abrangem sete contextos: dois são coincidências entre UFs diferentes, três divergem no distrito, um é a família pernambucana 21604/118 com cartão concorrente ainda não explicado integralmente, e dois são alternativas para SP63788/146. Neste último, uma alternativa reduziria o número de pessoas, mas diverge no cartão; a outra preservaria duas ocorrências, porém não tem os pontos de apoio exclusivos exigidos e compete com outro cartão. Não foi escolhida a alternativa que favorece excluir.

O ensaio que permite mais um campo divergente nos integrantes continua sendo uma **hipótese investigativa**, não uma autorização de edição. Diferenças como “afazeres domésticos” versus “estudante”, ou um ano de casamento específico versus outro, não viraram simples trocas de códigos. Buscar todas as fontes locais por 24 campos não exclui a possibilidade de existir um correspondente com outro campo danificado; esse limite continua explícito.

## Como conferir e testar

A [prova consolidada dos cinco pares](resolucao_residuais_duplicatas5_1960_evidencias.json) reúne as dez decisões, as 51 linhas originais dos cinco cartões e 46 integrantes, e referências assinadas às provas complementares. Os relatórios históricos foram preservados. As decisões de preservação não alteram respostas, vínculos, geografia ou pesos.

Passaram **19 testes Python novos**: cinco de preservação inicial, cinco dos grupos alternativos, quatro do critério composto do Ceará e cinco das disposições familiares. Também passaram os oito testes da investigação anterior. Testes negativos cobrem perda de integrante, geografia divergente, falta de pontos de apoio exclusivos e alteração de ano de casamento fora do critério.

Dois testes R novos passaram na execução sequencial controlada pela integração, sem reconstruir o censo inteiro:

- [Duplicatas](test_resolucao_duplicatas_1960.R): microlote real de 51 linhas; antes da decisão, deve bloquear; depois, deve conservar as 46 pessoas. Também verifica grupo parcial e texto adulterado.
- [Famílias coincidentes](test_resolucao_familias_coincidentes_1960.R): microlote real de 75 linhas; cinco conjuntos devem ser preservados e cinco bloqueados. Testa manifesto ausente de disposições, assinatura inválida, texto127 e texto25 adulterados e tentativa de liberar pendências mudando apenas ação/indicadores.

A frente de investigação não executou R paralelamente; as execuções acima foram feitas pela integração, uma por vez. Os resultados consolidados e a recontagem estão no [caderno da implementação](resolucao_residuais_1960_evidencias/LEIAME.md). O manifesto de cartões recuperados foi reauditado após estabilizar as decisões dependentes; a [prova vigente](resolucao_residuais_1960_evidencias/cartoes_fora_chave_fechada.json) preserva as assinaturas atuais, sem desligar a conferência nem reescrever provas anteriores.
