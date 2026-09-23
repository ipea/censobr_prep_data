# Correções residuais dos registros de 1960 — implementação e limites

Rodada iniciada em 22 e verificada em 23 de setembro de 2026. Esta rodada implementa decisões posteriores à [investigação anterior](investigacao_residual_registros_1960_20260922.md). A investigação foi preservada: o que naquela data era uma proposta não foi reescrito retroativamente como uma correção já aplicada.

**Situação: implementação e conferência desta rodada concluídas; a base completa não está homologada.** Passaram as últimas execuções dos 22 scripts de testes em R, em lotes sequenciais, e os 32 testes Python. As mudanças estão no código e nas listas de decisões. Os arquivos completos de pessoas e domicílios e seus pesos não foram substituídos. As pendências históricas que continuam sem prova são descritas abaixo, não tratadas como resolvidas.

## O que significa resolver um registro

Um cartão familiar é o registro que descreve a família. As pessoas têm registros separados, com respostas como idade, parentesco e escolaridade. Pasta e boletim são números históricos de arquivamento. Uma linha é a posição no arquivo bruto, não uma pessoa acrescentada.

Há duas tarefas diferentes. Uma falha do programa pode ser corrigida e testada. Uma informação que desapareceu do arquivo só pode ser recuperada se houver prova suficiente. A ordem para concluir o trabalho permite implementar correções demonstradas; não torna certo um vínculo incerto, nem autoriza excluir um possível irmão para eliminar um aviso.

## 1. Pessoas com respostas iguais: cinco pares foram preservados

Entre os conjuntos repetidos ainda sem decisão, cinco pares puderam ser esclarecidos. A comparação com a fonte de 25% confirmou duas ocorrências de cada perfil repetido dentro de uma família identificada. Acrescentei dez decisões de manter, sem excluir pessoas nem mudar suas respostas.

No Ceará, por exemplo, duas crianças da pasta 15004/boletim 034 reaparecem como duas crianças na pasta 14990/034 da outra fonte. A prova não é apenas a semelhança das crianças: concordam os nove integrantes, o cartão e a geografia. Um adulto tem perfil único nos 24 campos comparados nas duas fontes estaduais, e a diferença de numeração aparece em 144 outras famílias. A resposta sobre ano do casamento que difere entre as fontes foi preservada.

Em São Paulo e em um caso gaúcho, havia outra família que poderia ser confundida com o destino. Também localizei o grupo próprio dessa alternativa na outra fonte. Assim foi possível rejeitar a confusão sem escolher arbitrariamente qual família deveria desaparecer.

Os cinco pares, os critérios diferentes usados em cada caso e as alternativas rejeitadas estão na [nota das repetições](resolucao_residuais_duplicatas_1960.md). A lista completa passou de 6.451 para 6.461 decisões: 3.725 de manter e 2.736 de remover. Essas 2.736 remoções já estavam autorizadas antes; **não houve remoção nova nesta rodada**.

## 2. Vínculos familiares e cartões ausentes

### Duas pessoas cuja pasta estava parcialmente apagada

A pessoa 142402, no Ceará, trazia pasta `152 0`. O destino demonstrado é o cartão 142817, pasta 15290/067. Os sete integrantes já ligados ao cartão mais essa pessoa coincidem com as oito pessoas da outra fonte. Em Pernambuco, 259248 foi ligada ao cartão 259657 pela mesma combinação de chave parcialmente preservada e composição completa de sete pessoas.

O texto danificado continua disponível. Nenhuma pessoa foi anexada apenas por estar depois de determinado cartão no arquivo.

### Dois cartões recuperados para seis pessoas existentes

Na Bahia, as duas pessoas da pasta 32426/233 correspondem ao grupo 32426/006 da outra fonte. No Ceará, quatro pessoas de 15004/116 correspondem a 14990/116. A prova inclui os integrantes, o cartão, a geografia e a exclusão dos cartões concorrentes examinados.

Foram acrescentadas duas recuperações à lista anterior de trinta: agora são 32 cartões para 80 pessoas já presentes na amostra. **Não são 80 pessoas novas.** Nesta rodada, a diferença é de dois cartões para seis pessoas existentes.

Os códigos de pasta e boletim da amostra de 1,27% são mantidos. A numeração diferente da fonte de 25% fica em campos de procedência separados. Isso evita importar uma numeração de arquivamento como se ela fosse automaticamente a unidade do desenho amostral original. No Ceará, uma diferença `00`/`63` no ano do casamento também continua intacta.

### Pernambuco: distrito danificado, não duas geografias legíveis concorrentes

O cartão 238422 e a pessoa 238423 têm distrito `X7`; cinco integrantes, 239457–239461, têm `07`. Por isso a chave exata deixava os cinco sem família. A outra fonte confirma o grupo inteiro de seis pessoas, o cartão e o distrito 07. Os demais dígitos legíveis do questionário foram respeitados; não apareceu outro cartão compatível com todos eles.

A recuperação localizada passou a produzir distrito operacional `07` nos dois registros danificados e conservar `X7` nos textos originais e na marca de origem. Os cinco vínculos ficam explicitamente documentados. Não se trata de escolher por maioria entre dois distritos válidos, nem de uma regra que converta toda letra X em zero. A prova de identificação da pessoa já era válida sem usar sua nacionalidade recuperada; a correção não foi usada circularmente para provar a si mesma. O teste confirmou a conservação dessa origem até a finalização da preparação de 1,27% e rejeitou treze contraprovas. A compilação combinada tem outro esquema de colunas e não recebeu essas marcas; para Pernambuco, ela usa o ramo de 25%, não este reparo. Portanto este teste não certifica a propagação das marcas ao produto combinado. A [nota dos vínculos](resolucao_residual_vinculos_1960.md) detalha o procedimento e os casos que permaneceram sem prova.

## 3. Quatro nacionalidades recuperadas; dez danos não apagados

As nacionalidades das linhas 238423, 540394, 540399 e 540461 tinham sido deixadas ausentes porque nascer no Brasil não demonstra, sozinho, nacionalidade brasileira nata. Agora há prova localizada da pessoa e do grupo na fonte de 25%. Somente o caractere da nacionalidade foi recuperado. Escolaridade, atividade e ano do casamento que diferem entre as fontes não foram substituídos.

Outra descoberta exigia uma decisão diferente. Dez linhas guardam caracteres incompatíveis com o salto de perguntas. Transformar o trecho danificado em ausente fazia a comparação parecer igual ao branco legítimo da outra fonte. Esses casos agora recebem diagnóstico explícito de dano não resolvido. O programa rejeita a tentativa de declarar o dano e, ao mesmo tempo, apagar os caracteres com um texto substituto.

Essa classificação corrige um erro da conferência; **não recupera as respostas perdidas**. Os dez registros continuam preservados. Exemplos completos, textos antes/depois e contraprovas estão na [nota textual](resolucao_residual_texto_1960.md).

## 4. Famílias inteiras iguais agora têm uma conferência própria

A comparação anterior de pessoas repetidas não captava uma família inteira que reaparecesse sob outro boletim. A nova proteção compara geografia, atributos familiares e todos os integrantes, conservando as quantidades: dois irmãos iguais contam duas vezes.

Dos dez conjuntos encontrados, cinco têm grupos distintos corroborados nas duas fontes. Eles são preservados, sem afirmar identidade civil por nome. Outros cinco conjuntos, com onze cartões e 42 registros pessoais, continuam sem decisão suficiente e bloqueiam o processamento. A execução relê as provas; mudar apenas um indicador de “aprovado” não libera a família.

O Amazonas ilustra por que essa proteção é necessária: famílias de quatro e onze pessoas reaparecem sob outros dois boletins. A composição coincide, embora a ordem das pessoas mude. Sem outra fonte da UF, não é possível decidir qual versão excluir. Deixar o caso invisível também seria inadequado.

A busca original tratava dos integrantes ligados a cartões reais. Para não deixar os cartões recuperados fora da avaliação, uma conferência complementar comparou os 32 recuperados entre si e contra os 174.467 cartões reais. Não encontrou coincidência integral adicional. Também verificou o efeito do distrito recuperado em Pernambuco: ele não cria um novo conjunto coincidente. Isso verifica a interação dessas mudanças, sem fingir que os demais órfãos já estão reconstruídos.

## 5. O relatório não deve confundir informação perdida com zero

A relação entre os totais publicados e as faixas de idade sustenta incluir idade **declarada ignorada** nos quadros de atividade e renda. O código passou a incluí-la sem inventar uma idade. Idade danificada, presença desconhecida, atividade inválida e peso ausente conservam avisos próprios.

Também foi corrigida uma falha que fazia a conferência falhar quando uma tabela não tinha nenhum registro elegível. Agora tanto um grupo realmente vazio quanto uma entrada inteiramente vazia chegam à grade completa de referências.

A revisão dos novos testes encontrou ainda dois casos de informação incompleta: ramo de atividade com uma resposta necessária ausente e UF perdida. Eles não devem desaparecer do relatório nem produzir um zero regional aparentemente completo. Os totais conhecidos são conservados como parte conhecida, mas a estimativa completa e sua diferença em relação ao publicado ficam ausentes quando a classificação não é demonstrável. Essa mudança não corrige pesos nem atribui uma UF presumida.

Um exemplo sintético dos testes torna o efeito concreto. Há duas pessoas, com pesos 10 e 20. A primeira perde a UF; a segunda continua identificada em São Paulo. Antes, o relatório podia apresentar 20 como total completo de São Paulo e zero completo nas demais UFs. Agora conserva 20 e zero somente como partes conhecidas, avisando que a pessoa sem UF impede concluir o total regional. **Não soma o peso 10 em todas as UFs e não cria pessoas.** Se a UF é válida e apenas está fora do recorte escolhido para o relatório, ela não é tratada como informação perdida. A proteção foi estendida aos relatórios preliminares e definitivos.

**Estado conjugal continua com uma limitação documental própria:** a publicação usa residentes, não o mesmo universo de presentes dos quadros de atividade/renda. As páginas históricas novamente examinadas não esclareceram a inclusão da idade ignorada nesse quadro. A habilidade de leitura de PDF foi usada para conferir visualmente as páginas; não para presumir uma resposta que elas não dão.

## 6. O que ainda impede a reconstrução completa

Não é correto anunciar “todas as pendências resolvidas”. Permanecem repetições sem prova suficiente, pessoas sem família demonstrada e conflitos geográficos. As listas se sobrepõem: não representam parcelas que possam ser somadas como um único número de pessoas.

| Pendência ou decisão | Antes desta rodada | Depois, com os manifestos atuais |
|---|---:|---:|
| Conjuntos pessoais repetidos sem decisão | 463, envolvendo 928 linhas | 458, envolvendo 918 linhas |
| Registros pessoais sem família confirmada | 1.229 | 1.216, distribuídos em 481 grupos de chave |
| Pessoas distintas com conflito municipal ou urbano/rural | 192 | 192 |
| Cartões recuperados para pessoas existentes | 30 para 74 pessoas | 32 para 80 pessoas |
| Vínculos pessoais explicitamente documentados | 251 | 258 |
| Reparos textuais localizados | 33 | 37 |

Os treze vínculos resolvidos nesta rodada são sete ligações a cartões existentes e seis pessoas abrangidas pelos dois cartões recuperados. Continuam um cartão vazio, uma família convivente sem principal demonstrado e os cinco conjuntos de famílias coincidentes ainda não liberados. Os dez diagnósticos de dano não equivalem a dez reparos adicionais.

O inventário conta posições classificadas como registros pessoais, não pessoas identificadas por nome. Os 1.216 incluem três fragmentos indecifráveis; seus campos de chave vazios formam um agrupamento computacional, mas não demonstram uma família comum nem quantas pessoas históricas os fragmentos representam. Por isso, 481 grupos de chave não significa 481 famílias conhecidas.

Entre as 918 linhas dos conjuntos pessoais ainda pendentes, **127 constavam das exclusões históricas sem comprovação suficiente**. Não foram homologadas como duplicatas, nem demonstradas como pessoas diferentes, nem restauradas por esta rodada. O novo processamento continua bloqueado nesses casos: não se deve interpretar a conservação dos arquivos completos antigos como aprovação dessas exclusões.

Há impedimentos concretos, não apenas avisos genéricos:

- Não há a fonte de 25% de onze UFs no acervo disponível. Cinco cópias adicionais de HHOLDA, inclusive a recebida em 2012, foram conferidas e têm os mesmos bytes: nenhuma recupera os trechos perdidos.
- Na Guanabara, o cartão 616230 é um candidato forte para 611254, mas um cartão histórico ausente de outra pasta compatível não foi descartado por fonte independente. A posição no arquivo não resolve isso.
- Em Minas, a hipótese conjunta de recuperar idade, parentesco e cartão foi examinada, mas dois cartões alternativos permanecem. Usar a pessoa hipoteticamente corrigida como prova independente da própria hipótese seria circular. Belo Horizonte também conserva alternativas.
- O cartão paulista 780535 não tem suas cinco pessoas demonstradas na amostra de 1,27%. Importar pessoas da amostra maior mudaria a amostra. A família convivente 743894 conserva diferenças de classificação e não tem principal demonstrado.
- Os fragmentos 855822, 951432 e 951433 não fornecem informação suficiente para reconstruir com segurança pessoas e família.
- Em SP695175, a composição está identificada, mas isso não decide por si só a divergência urbana/rural. Confirmar identidade do grupo e escolher geografia são tarefas diferentes.

O tratamento destes casos exige outra fonte ou uma escolha metodológica explícita de trabalhar com informação incerta e avaliar seu efeito. Não deve ser apresentado como correção factual comprovada. Enquanto isso, os bloqueios preservam os registros e impedem que uma reconstrução incompleta pareça uma base homologada. Variâncias calibradas continuam adiadas, conforme a decisão anterior.

Há também um requisito de saída que não deve ser confundido com essa falta de prova: a compilação geral tem uma lista fechada de colunas e bloqueia o uso dos cartões recuperados da amostra de 1,27% enquanto sua procedência não estiver representada no esquema final. Os testes confirmam esse bloqueio; não o retiraram. Preservar essa origem na exportação, reconstruir a base e só então recalcular seus pesos continuam etapas anteriores a qualquer nova publicação dos dados.

## Como auditar

As provas novas ficam no [caderno desta implementação](resolucao_residuais_1960_evidencias/LEIAME.md). Ele reúne o inventário atual, a conciliação com cada caso anterior, textos e origens, resultados dos testes e assinaturas dos arquivos. Uma assinatura detecta mudança nos bytes; não prova, sozinha, a identidade histórica de pessoas.

Os testes usam pequenas entradas reais e sintéticas, com uma única instância de R por vez pelo executor isolado. O [resultado consolidado](resolucao_residuais_1960_evidencias/conferencia_entrega.json) exige aprovação dos 22 scripts distintos e verifica se código, provas, manifestos e dados correspondem às versões testadas. As tentativas interrompidas continuam registradas como interrompidas; não foram convertidas em baterias integralmente aprovadas. Os 32 testes Python e as oito verificações internas da conferência complementar também passaram. Não houve crash nativo do R.

A conciliação acompanha 2.536 posições do arquivo na cobertura histórica e nas decisões desta rodada; esse número não é um total de pessoas problemáticas, pois inclui cartões e marcações que se sobrepõem. Não foi executado `targets`, não houve reconstrução nacional, substituição dos parquets, reutilização de pesos por identificadores novos ou publicação nesta rodada.
