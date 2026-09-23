# Nova investigação dos registros de 1960: o que avançou e o que ainda não podemos decidir

Esta nota compara os arquivos de duas amostras históricas do Censo de 1960: a de **1,27%** e a de **25%**. Quando falamos em “outra fonte”, estamos falando do outro arquivo histórico usado nessa comparação, não de uma população nova a acrescentar ao arquivo.

Um **cartão familiar** é o registro que descreve a família; **pasta e boletim** são códigos históricos usados para organizar e identificar os questionários. Os **quesitos** são os campos ou respostas que comparamos, como idade e escolaridade. E “linha” indica a posição de um registro no arquivo bruto: localizar uma linha ou vinculá-la a uma família não significa adicionar uma pessoa. Chamamos de **testemunho** uma correspondência de respostas completas suficientemente específicas para ajudar a identificar o grupo; não se trata de uma pessoa que prestou um novo depoimento.

## Resultado principal

**A investigação anterior ainda não havia esgotado caminhos importantes.** A busca adicional encontrou dois vínculos familiares bem demonstrados, novas correspondências escondidas por diferenças de numeração, dez danos textuais que precisavam de classificação mais clara e coincidências entre famílias inteiras que a busca de repetições pessoais não examinava. Também reduziu uma dúvida sobre quem deve entrar nas tabelas de atividade e renda.

Esta rodada **investigou e documentou; não aplicou novas correções**. Não alterou os arquivos brutos, as listas de decisões, o código de produção, os parquets ou os pesos. Não executou R, não publicou dados e não fez novo commit ou push. A autorização de publicação anterior já havia sido atendida no commit `790d9d7`; esta entrega é uma nova investigação.

O inventário anterior foi refeito a partir do arquivo bruto e ficou idêntico: continuam registrados na produção 463 conjuntos pessoais repetidos sem decisão, 1.229 registros sem família confirmada, 50 conflitos municipais e 145 de situação urbana/rural, envolvendo 192 pessoas distintas; um cartão sem pessoas e uma família convivente sem principal demonstrado. **As descobertas abaixo não devem ser subtraídas dessas contagens como se já tivessem sido implementadas.** Há, além disso, novos alertas que não cabiam naquele inventário.

## 1. Um ponto realmente não examinado: famílias inteiras com conteúdos iguais

A procura anterior de repetições pessoais agrupava registros que compartilhavam o identificador do arquivo e outros códigos. Isso permitia examinar dois filhos com respostas iguais dentro de um mesmo grupo, mas não uma família inteira que reaparecesse sob outro número de boletim e outro identificador.

A nova busca retirou esses identificadores **somente da comparação**, sem apagá-los dos dados. Conferiu simultaneamente UF, município, distrito, situação, os quinze campos familiares e todos os 25 quesitos de cada pessoa. Conservou as quantidades: dois irmãos iguais continuam sendo duas ocorrências. Foram comparados **174.425 cartões não vazios cujos grupos não tinham campos inválidos**, considerando as pessoas já ligadas a cartões reais no índice atual. A comparação não incluiu os grupos ainda sem família confirmada nem os cartões reconstruídos a partir da outra fonte. Os cartões vazios ou com dano que impede essa comparação também não foram declarados aprovados. Portanto, a busca não certifica as composições que ainda dependem de resolver vínculos.

Foram encontrados **dez conjuntos de conteúdos familiares coincidentes, envolvendo 21 cartões e 54 registros pessoais**. Cinco conjuntos têm apenas uma pessoa por cartão; três têm duas; um tem quatro; outro tem onze. Isso não significa 54 duplicações comprovadas. Algumas respostas são comuns; outras podem ter sido repetidas já na fonte histórica. Nenhuma dessas 54 linhas pertence aos 928 registros dos 463 conjuntos pessoais anteriormente pendentes.

### O caso mais preocupante está no Amazonas

Na pasta 02104, a família do boletim 248 tem quatro pessoas; a do 249 tem onze. Logo depois, os boletins 250 e 251 apresentam, respectivamente, as mesmas composições de quatro e onze pessoas, com os mesmos atributos familiares e geográficos.

| Primeiro grupo no arquivo | Grupo com conteúdo coincidente | O que coincide |
|---|---|---|
| Cartão 8443, boletim 248; pessoas 8444–8447 | Cartão 8460, boletim 250; pessoas 8461–8464 | Cartão e quatro conjuntos completos de respostas pessoais. |
| Cartão 8448, boletim 249; pessoas 8449–8459 | Cartão 8465, boletim 251; pessoas 8466–8476 | Cartão e onze conjuntos completos de respostas pessoais. |

No segundo par, reaparecem, por exemplo, o chefe de 60 anos, a cônjuge de 45 e os outros nove integrantes, com as mesmas respostas detalhadas. Uma segunda leitura confirmou que os textos coincidem fora dos campos de boletim e identificador. **A ordem das pessoas muda:** o trecho de 17 registros — dois cartões e quinze pessoas — não reaparece na mesma sequência. É a composição de duas famílias que reaparece, sob outra identificação.

Esse padrão é um indício sério de repetição de grupos e não deveria ficar invisível. Mas a fonte de 25% do Amazonas não está disponível. Não há, nesta rodada, prova externa que autorize escolher qual grupo retirar. A conduta adequada é registrar uma pendência própria, preservar as duas versões e exigir uma decisão documentada antes de qualquer exclusão ou cálculo que suponha serem pessoas distintas sem ressalva. Não se deve reutilizar a antiga regra “respostas iguais, então excluir”.

O Maranhão apresenta também dois casais com respostas completas iguais. Nos casos de Minas e São Paulo, a fonte de 25% mantém boletins distintos e traz concordâncias ou divergências próprias de cada grupo. Esses casos reforçam que a igualdade de conteúdo, sozinha, não fornece uma regra universal de exclusão.

Provas: [famílias coincidentes](investigacao_residual_1960_evidencias/familias_coincidentes.json), [segunda conferência Amazonas/Maranhão](investigacao_residual_1960_evidencias/duplicatas_qc_blocos_am_ma.json) e [auditor nacional](investigacao_familias_repetidas_1960.py).

## 2. Dois vínculos agora têm prova integral

O exemplo do Ceará mostra o que mudou na busca. A pessoa da linha 142402 tinha pasta escrita como `152 0`: um dígito havia desaparecido. A busca por chave exata não encontrava família. A nova busca conservou todos os caracteres legíveis, além de distrito, município e boletim. Encontrou um único cartão compatível: 142817, pasta 15290, boletim 067.

O cartão já tinha sete pessoas. Ao acrescentar à comparação a pessoa 142402, **as oito pessoas coincidem nos 25 quesitos com as oito da outra fonte**. O cartão e o distrito também coincidem. Assim:

```text
7 pessoas já ligadas ao cartão 142817
+ a pessoa 142402, cuja pasta perdeu um dígito
= 8 pessoas que conferem com o grupo completo da outra fonte
```

Não se criou uma oitava pessoa: ela já está no arquivo e estava sem família confirmada. Tampouco se escolheu apenas uma criança parecida; seu perfil individual aparece milhares de vezes na outra fonte. O que identifica o destino é a chave parcialmente preservada combinada com a família inteira.

Em Pernambuco ocorre o mesmo com 259248, pasta `22 34`: o único cartão compatível é 259657, pasta 22934/069. A pessoa pendente mais os seis integrantes já ligados coincidem com as sete pessoas da fonte de 25%. Ambos os casos foram conferidos novamente por leitura independente dos textos originais.

**Proposta pronta para uma próxima implementação:** vínculos 142402 → 142817 e 259248 → 259657, com a origem individual e a chave original preservadas. Uma eventual pasta derivada corrigida deve ficar identificada como derivação, não substituir silenciosamente os caracteres históricos. Detalhes e linhas da outra fonte estão na [nota dos vínculos](investigacao_residual_vinculos_1960.md).

## 3. Algumas diferenças de chave são padrões de numeração entre as cópias

Não se tratava apenas de dígitos isoladamente errados. Em diversas pastas, grupos inteiros aparecem sob outra numeração. Por exemplo, no Rio Grande do Sul a família de dez pessoas da pasta 82894/boletim 010 aparece na outra fonte como 82892/190. Os dois filhos com respostas repetidas têm duas ocorrências na fonte de 25%. Há evidência nova para **manter ambos**, não retirar um.

Uma segunda família gaúcha fornece a mesma evidência para outro par. Sob o critério mais restritivo, são **dois conjuntos, quatro linhas a manter e nenhuma remoção nova**. As quatro linhas são 1009572, 1009575, 1014154 e 1014156. Outros candidatos ganharam evidência contextual, mas ainda têm ressalvas sobre testemunhos pessoais, cartões alternativos ou distrito.

A busca por composição inteira encontrou 13 alternativas fora da chave. O estudo de 1.702 cartões vizinhos mostrou padrões envolvendo 145 famílias no Ceará, 93 em São Paulo, 57 em Pernambuco e dois grupos de 42 e 17 no Rio Grande do Sul. Os critérios e as ressalvas estão na [nota das repetições](investigacao_residual_duplicatas_1960.md). Não são autorizações para renumerar automaticamente todas essas famílias.

Houve também três novos caminhos de recuperação de cartões ausentes: CE 14990/116, BA 32426/006 e RS 82892/201. Foram examinados 19, 240 e 10 cartões alternativos, respectivamente; nenhum permaneceu sob os critérios examinados. **Esses três caminhos ainda não são recuperações aprovadas.** O caso baiano tem as duas pessoas exatas e únicas nas duas fontes. No Ceará, permanece uma diferença no ano do casamento, campo V216, que não foi substituída; no caso gaúcho, há apenas uma pessoa com perfil completo único nas duas fontes. Ainda é necessária uma implementação explícita que aceite e documente a diferença de chave e trate essas ressalvas; a prova não deve ser inserida no recuperador antigo fingindo que as chaves são iguais.

Outro padrão merece trabalho próprio antes dos pesos: entre 142 cartões da pasta gaúcha 82588, 101 grupos coincidem em 24 quesitos com a pasta 82586 da outra fonte, e 55 coincidem nos 25 completos. O distrito muda de 05 para 03. Isso não diz qual numeração ou distrito histórico deve prevalecer. **Reconhecer as pessoas e escolher a geografia usada no desenho amostral são decisões diferentes.**

Existe uma contraprova que impede atalhos: em São Paulo, dois grupos de municípios diferentes têm as mesmas duas combinações completas de respostas pessoais. Nem sempre “encontrei todas as respostas” significa “encontrei a família correta”.

## 4. Dez danos de texto precisavam ser explicitados

Uma classificação anterior dizia que certos registros eram iguais à fonte de 25% “nos campos comuns”. Em dez casos, essa igualdade só aparecia depois que os campos danificados viravam ausentes. Na outra fonte, os campos estavam legitimamente em branco porque a pergunta não se aplicava.

Exemplo real: na linha 760807 há um hífen de salto de perguntas, mas também um dígito 9 adiante. Apagar ambos como se toda a região estivesse originalmente em branco produz uma coincidência que o texto preservado não demonstra. O novo auditor conserva os caracteres sobreviventes durante a busca.

As dez linhas são 760807, 760919, 760923, 760925, 761056, 761057, 761058, 806791, 806800 e 806801. Elas **não sustentaram os 33 reparos, os 30 cartões recuperados, os vínculos ou as decisões de duplicatas aprovados anteriormente**, conforme o cruzamento com os cinco manifestos. Portanto, não se demonstrou uma invalidação dessas decisões. Demonstrou-se uma classificação incompleta na auditoria e a necessidade de manter aqueles campos como dano não resolvido, sem confundir ausência com resposta recuperada.

Outras conclusões foram refinadas:

- **São Paulo, cartão 695175:** as três pessoas correspondentes estão preservadas, não apenas uma. O grupo completo confere. Continuam divergências de município, situação e atributos habitacionais; não faltam duas pessoas a criar.
- **Guanabara, linha 611254:** é uma pessoa, não um cartão. A chave parcialmente preservada aponta para um único cartão compatível, 616230. O contexto é coerente, mas não há fonte de 25% da UF para a mesma confirmação externa usada no Ceará e em Pernambuco.
- **Nacionalidade em Serra dos Aimorés:** os grupos das três pessoas 540394, 540399 e 540461 têm identificação fortalecida por outras pessoas com respostas completas únicas. Há propostas mais fortes, mas seria necessário declarar um critério de identificação familiar que admita divergências de respostas de terceiros sem substituí-las. Não são correções aplicadas.
- **Pernambuco, linha 238423:** a nacionalidade ausente tem um único candidato pelos demais campos pessoais legíveis. Mas a pessoa e seu cartão têm distrito parcialmente ilegível, `X7`, enquanto a outra fonte e os demais integrantes indicam `07`. O reparo da nacionalidade depende de uma prova conjunta do distrito e dos vínculos, não de ignorar esse dano geográfico.
- **Minas, linha 405458:** um reparo conjunto de parentesco e idade permitiria que as três pessoas coincidissem integralmente com as três da fonte de 25% e permitiria examinar a recuperação de seu cartão ausente. Contudo, dois dos 289 cartões alternativos examinados não puderam ser excluídos. O raciocínio conjunto foi examinado; não foi aprovado circularmente usando um reparo incerto como prova do cartão e vice-versa.
- **Fragmentos 855822, 951432 e 951433:** as buscas de trechos completos, deslocados e parcialmente coincidentes não demonstraram uma reconstrução. Parecidos não viraram pessoas ou famílias atribuídas.

Todos os 124 registros textuais anteriormente suspeitos foram revisitados, não apenas os 14 resíduos da última seleção. Detalhes: [investigação textual](investigacao_residual_texto_1960.md).

## 5. Uma conferência publicada esclarece parte da idade ignorada

A dúvida anterior sobre os quadros 3 e 4 não precisava depender apenas de encontrar uma frase no manual. Na publicação preliminar, o total de presentes menos os menores de 10 anos é exatamente 48.761.467 — o total publicado de atividade e renda. Essa subtração conserva a faixa que inclui expressamente as idades ignoradas.

A relação foi conferida por sexo em Brasil, Nordeste, Leste e Sul, com inspeção das páginas originais. Há evidência interna forte para incluir idade **declarada** ignorada nesses dois universos de comparação, sem inventar uma idade e sem incluir idade danificada como se fosse ignorada declarada. O código atual ainda sinaliza essa inclusão como pendente; não foi alterado nesta rodada.

Isso **não resolve o quadro 5**, sobre estado conjugal, cujo universo é de residentes. A [nota documental](investigacao_residual_fontes_1960.md) apresenta a conta, as páginas, o código afetado, os testes e o limite da conclusão.

## 6. O que a investigação adicional não resolveu

O cartão paulista 780535 continua sem seu grupo de cinco pessoas demonstrado na amostra de 1,27%; não se podem importar cinco pessoas da amostra de 25% para preencher a lacuna. A família convivente 743894 tem sete pessoas identificadas, mas classificação e dados familiares discordantes entre as cópias. Belo Horizonte 40090/004 conserva sete cartões alternativos não excluídos pelo critério atual. As diferenças que impedem cada confirmação agora estão explicitadas na nota de vínculos.

Não surgiu uma fonte mais íntegra ao voltar às cópias preservadas. O HHOLDA recebido é idêntico ao local; os 17 arquivos da amostra de 25% coincidem com as cópias preservadas descomprimidas. O arquivo público e sua cópia derivada diferem do local apenas na convenção de fim de linha. O catálogo atual do IPUMS continua indicando as mesmas onze UFs ausentes, não uma fonte adicional para preenchê-las. Isso elimina essas alternativas específicas, não prova inexistência de outras fitas ou acervos. Referências e assinaturas estão na nota documental.

## 7. Alcance da palavra “exaustiva” e próximo passo

Esta rodada cobriu integralmente as listas conhecidas, procurou fora das chaves e das UFs, examinou todas as 17 fontes locais de 25%, diagnosticou as diferenças pessoa a pessoa e acrescentou a busca nacional de famílias inteiras. Nos contextos das duplicatas e na procura dos adultos do cartão vazio 780535, testou também uma correspondência hipotética que admitia divergência no ano do casamento e em mais um campo; esse teste não abrangeu todos os alvos nem transformou a hipótese em correção. O caderno inclui todos os casos sem candidato, não só exemplos favoráveis.

**Não equivale a esgotar qualquer reconstrução imaginável.** Não há busca de todas as possíveis divisões e fusões de famílias, de qualquer número de caracteres alterados, nem acesso a fontes não preservadas. Esses limites são importantes: se uma pesquisa falha sob determinado critério, isso não prova que a pessoa não existiu.

O passo seguinte está agora mais bem delimitado:

1. Incorporar as decisões de prova mais direta: os dois vínculos de chave incompleta e a preservação dos dois pares gaúchos, com testes antes/depois.
2. Acrescentar ao controle de integridade as coincidências entre famílias inteiras e os dez danos textuais explicitados. O Amazonas precisa de tratamento próprio; não deve desaparecer sob o rótulo genérico de duplicata pessoal.
3. Avaliar separadamente os critérios ampliados para chaves renumeradas, cartões ausentes e grupos reconhecíveis apesar de respostas divergentes. Preservar cada divergência e sua origem.
4. Ajustar os universos de atividade/renda conforme a evidência publicada. Continuar distinguindo a pendência de estado conjugal.
5. Só depois conciliar o inventário de registros aptos, a geografia e a elegibilidade para reconstrução e revisão dos pesos. Mostrar ou documentar a pendência não corrige os pesos automaticamente.

### Como auditar esta entrega

O [caderno e índice de evidências](investigacao_residual_1960_evidencias/LEIAME.md) reúne cobertura por linha, candidatos, razões contrárias, assinaturas e comandos. A [segunda conferência independente](investigacao_residual_1960_evidencias/qc_independente.json) releu textos nas fontes, verificou composições e quantidades e conciliou a cobertura com o inventário original. Os auditores e testes Python são separados do pipeline. As habilidades de leitura de PDF influenciaram a conferência visual das tabelas históricas, não a alteração de registros.

Não houve novo erro do Rscript nesta rodada porque **R não foi executado**; isso não é um novo teste do ambiente R. Os dados completos e os pesos permanecem na versão anterior. O resultado desta entrega é evidência adicional e uma lista de decisões melhor fundamentada, não a homologação de toda a amostra.
