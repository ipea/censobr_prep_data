# O que a nova investigação dos vínculos permitiu estabelecer

Esta nota descreve **candidatos a correção**, antes de sua incorporação pelo
pipeline. Ela não certifica que a base completa já foi reconstruída e não transforma
uma dúvida documental em certeza apenas por dar um nome à dúvida.

## O inventário foi ampliado, não reduzido aos casos conhecidos

O ponto de partida eram 1.339 pessoas em 526 grupos sem cartão confirmado,
depois dos 29 cartões recuperados anteriormente. A conferência incluiu também
63 pessoas cujo município divergia do cartão já associado e outras 193 com
divergência na situação urbana/rural. Há três sobreposições: são **1.592 pessoas
distintas**, não 1.595. As três linhas de texto inutilizado continuam explicitamente
no inventário; não desapareceram da contagem por ficarem fora do índice de busca.

Além das pessoas, foram investigados o cartão de São Paulo sem pessoas ligadas
e a família convivente de São Paulo sem família principal comprovada.

## Primeiro resultado: 33 vínculos com concordância integral

Em 33 casos, um único cartão de cada fonte possui as mesmas respostas e distrito,
e o conjunto inteiro de pessoas coincide, inclusive o número de ocorrências de
cada combinação de respostas. Foram verificadas as pessoas já ligadas ao cartão
por outras chaves: nenhuma pessoa adicional ficou escondida nessa comparação.

São seis pessoas ainda sem cartão confirmado, seis com conflito de município e
21 com conflito de situação. Não se troca um destino direto já existente por
outro: nos 27 conflitos, a evidência confirma o próprio cartão já indicado.

Um exemplo concreto é a linha **124861**, do Ceará. Ela informa município 1520,
mas sua chave aponta para o cartão 127064, que informa 1522. Na fonte de 25%, o
cartão e a composição inteira desse grupo correspondem ao cartão 127064. Isso
permite confirmar o vínculo familiar; **não exige substituir silenciosamente o
1520 que a pessoa traz**. A informação original e a divergência precisam continuar
visíveis. O mesmo raciocínio vale para diferenças na situação urbana/rural.

## Segundo resultado: 133 vínculos cujo grupo é identificável, mas cujas fontes discordam

Exigir que todas as respostas das duas fontes sejam iguais confundiria dois
problemas: descobrir a que família pertence uma pessoa e decidir qual resposta
de uma variável está correta. É possível estabelecer o primeiro sem resolver o
segundo, desde que exista evidência suficiente de que se trata do mesmo grupo.

A proposta exige chave, espécie, município, situação e distrito do cartão
concordantes; estrutura e contagens da fonte25 íntegras; composição e número de
pessoas iguais em 24 quesitos; e pelo menos duas pessoas com todos os 25 quesitos
iguais, cujos perfis são únicos dentro da UF na127. A única diferença pessoal
admitida para **identificar o grupo**, nunca para mudar a resposta, é V216=00 em
uma fonte e 63 na outra. As divergências de atributos habitacionais V102–V113
também ficam documentadas e preservadas na127. Espécie ou geografia do próprio
cartão divergente impede essa proposta.

Depois de conciliar os candidatos de duplicatas, 57 grupos, abrangendo 133
pessoas do inventário, passaram por essas condições: 102 pessoas sem cartão,
quatro conflitos municipais e 27 conflitos de situação. São disjuntos dos 33
casos anteriores. A proposta **não considera 00 e 63 equivalentes** e não copia
respostas da25 para a127.

Há um exemplo importante entre os filhos. A linha **425558**, em Minas Gerais,
pasta41384/boletim224, descreve um filho do sexo masculino de 12 anos. Na25,
duas pessoas do mesmo cartão possuem respostas compatíveis: linhas898627 e
898631. O conjunto completo e suas multiplicidades confirmam o grupo familiar,
mas não permitem dizer qual dos dois registros individuais é a mesma pessoa.
Por isso, ambas as origens ficam listadas, separadas por ponto e vírgula; não se
exclui um suposto irmão duplicado nem se escolhe arbitrariamente uma identidade.

## Cartões ausentes: a busca adicional não resolveu todos

Havia 71 grupos/164 pessoas com composição pessoal exata na25, mas sem cartão127
confirmado. A revisão das alternativas foi repetida após as novas decisões de
duplicatas. Uma proposta identifica o grupo próprio de um cartão alternativo
quando há pareamento único em 24 quesitos, pelo menos duas testemunhas pessoais
exatas e nenhuma diferença restante além de V216=00/63. Mesmo assim, só **um
cartão adicional, para duas pessoas**, ficou sem alternativa remanescente sob
essa proposta: Paraná, pasta70380/boletim148, pessoas861116 e861117.

### Por que o caso do Paraná pode avançar, sob revisão explícita

O cartão da fonte25 está na linha **125840**. Seus dois registros pessoais,
linhas125841 e125842, correspondem integralmente aos dois registros já existentes
na127, em ordem inversa: 861117 e861116. Município7145, distrito01 e situação1
também coincidem. O cartão é da espécie3, um boletim coletivo; recuperá-lo não
criaria pessoas nem demonstraria que há um edifício fisicamente distinto.

Antes de recuperar esse cartão, era necessário afastar duas alternativas:
cartões127 **860662**, boletim019, e **860762**, boletim050, da mesma pasta70380.
Ambos têm seis pessoas próprias, presentes nos respectivos boletins da25. No
primeiro, três dessas seis pessoas coincidem em todos os quesitos, e duas dessas
combinações completas de respostas só aparecem uma vez em toda a127 do Paraná:
linhas860663 e860668. No segundo, duas pessoas coincidem integralmente e também
têm combinações únicas na UF: 860763 e860764. Todos os demais integrantes têm
correspondência individual única em 24 quesitos; só V216 diverge, de00 na127
para63 na25. Os quinze campos familiares e o distrito de cada cartão coincidem.

Isso distingue duas questões: as respostas de V216 continuam discordantes, mas
os dois cartões alternativos são identificáveis como pertencentes a seus próprios
grupos de seis pessoas, e não ao grupo de duas pessoas do boletim148. As respostas
discordantes não precisam ser modificadas para fazer essa identificação.

A adaptação mínima proposta no auditor de recuperação é admitir essa prova
adicional **apenas** quando a discordância da composição pessoal for o único
impedimento à identificação do grupo próprio de um cartão alternativo. Devem
continuar bloqueantes a multiplicidade ambígua, qualquer diferença pessoal fora
de V216=00→63, menos de duas testemunhas integrais únicas na UF, diferença no
cartão ou na geografia, fonte25 incompleta e duplicata não decidida. O grupo alvo
continua sujeito à igualdade integral dos 25 quesitos; não se relaxa o critério
para as pessoas que receberão o cartão recuperado.

Esta descrição registra uma proposta, não sua aplicação. Prova literal completa:
`tmp/fechamento_registros_1960_20260922/vinculos/alternativas_integral_02/grupos_proprios.jsonl`,
entradas860662 e860762; cartão candidato e origem das duas pessoas em
`resultado.json`, seção `sob_proposta_para_revisao`. A busca foi refeita após os
954 grupos candidatos de duplicatas; alterações posteriores nos manifestos de
produção exigem uma nova auditoria com seus próprios hashes, não a reutilização
silenciosa desses resultados históricos.

**Verificação posterior autorizada.** O critério adicional foi implementado
somente na identificação do grupo próprio dos cartões alternativos. O padrão de
`own_group_proof` continua estrito; apenas a auditoria de recuperação ativa
`permitir_contexto=True`. A suíte ampliada tem 37 testes, todos aprovados, além
dos 12 testes de vínculos. O piloto atualizado PR70380/148, em
`.../vinculos/recuperacao_pr_piloto_01/`, aprovou um cartão para duas pessoas em
49,9 segundos, com as fontes inalteradas. Essa execução não modificou manifestos
de produção, não executou R e não reconstruiu a base completa.

O manifesto do piloto conserva o hash do auditor efetivamente executado,
`b0e7cd965dbbc31457409142a67b67b62e3a9b0928964a6feb76ff40d273429d`.
Depois de o piloto terminar, o parâmetro explícito foi acrescentado para preservar
o contrato estrito dos outros chamadores; a versão entregue para reauditoria
integral tem hash
`b78400fa4de86d191ad0a68c97b7439bac4588cc3ecc23c27220b1cb058fbd56`.
O integrador deve usar a nova auditoria integral para renovar as evidências e
promover o cartão; o piloto, sozinho, não é essa promoção.

O caso de Belo Horizonte, pasta40090/004, continua sem aprovação. A nova prova
afasta 11 alternativas, incluindo o cartão de boletim064: seis de suas oito
pessoas coincidem integralmente e duas diferem somente em V216. Mas ainda
restam sete alternativas. No boletim021, por exemplo, há também diferenças em
V212 e V214. A regra não foi ampliada só para fazer esse caso passar.

## Dois problemas de São Paulo que não admitem uma solução inventada

**Família convivente, linhas743894–743901.** Os sete registros pessoais do
boletim61344/016 coincidem integralmente nas duas fontes. Entretanto, o cartão
é espécie5 na127 e espécie1 na25. O cartão anterior, boletim015, é espécie1 na127
e espécie9 na25; também há discordância na presença dos dados habitacionais.
Portanto, não se trata apenas de localizar uma família principal desaparecida:
as fontes discordam sobre a classificação dos próprios cartões. Nenhum cartão
foi transformado em principal ou recebeu dados habitacionais por suposição.

**Cartão sem pessoas, linha780535, boletim63936/230.** A25 apresenta cinco
pessoas nesse boletim, enquanto a127 não tem nenhuma pessoa com essa chave.
As três pessoas fisicamente seguintes na127 pertencem ao boletim243 e coincidem
com as três pessoas desse outro boletim na25. Logo, anexá-las ao230 só porque
vêm logo depois é incorreto. Os adultos do230 não tiveram perfil integral exato
encontrado em outra parte da UF127; os perfis infantis coincidem com numerosos
registros e não identificam, sozinhos, uma pessoa. Isso não autoriza criar cinco
pessoas na127 nem apagar o cartão230.

A conferência final do código identificou uma lacuna adicional: o cartão sem
pessoas não tinha bloqueio próprio, embora continuasse pendente na investigação.
Foi acrescentada uma guarda em `build_families`, com o relatório
`cartoes_sem_pessoas_a_revisar.csv`, e outra na entrada de `finalize` para impedir
que dados antigos com IDs já atribuídos contornem essa verificação. Também foi
acrescentado o bloqueio de divergência ou ausência de V118 nos vínculos diretos
ainda não reconciliados, com `vinculos_situacao_a_revisar.csv`. As decisões
expressas de vínculo continuam aceitas sem substituir respostas pessoais.

O teste `references/test_guardas_familias_situacao_1960.R` usa o cartão780535,
uma família de controle íntegra e a família cearense142520–142529. Nesta última,
a pessoa142523 conserva situação1, enquanto o cartão informa5; com a decisão
real de vínculo o grupo passa, sem essa decisão deve parar. Há também variantes
explicitamente sintéticas com V118 ausente e uma entrada antiga com cartão vazio.
O integrador reproduziu as cinco faltas antes da alteração; a execução posterior
foi aprovada pelo ambiente R isolado: os cinco cenários foram bloqueados e os
dois controles positivos continuaram válidos, com a entrada preservada.
Logs: `tmp/fechamento_registros_1960_20260922/guardas_familias_antes_01.log` e
`guardas_familias_depois_01.log`; o segundo terminou com código0, sem crash.

## Como auditar

O script é `references/auditoria_pendencias_vinculos_1960.py`; a suíte
`references/test_auditoria_pendencias_vinculos_1960.py` contém 12 testes, incluindo
contagens, multiplicidades, respostas diferentes, fonte incompleta, pessoas
ligadas por outras chaves, pareamento ambíguo e testemunhas insuficientes.
Houve pilotoMG antes das ampliações, sem execução de R nesta auditoria.

As saídas abaixo são novas e separadas; os originais não foram sobrescritos:

- `tmp/fechamento_registros_1960_20260922/vinculos/integral_02/`: inventário completo,
  razões caso a caso e literais das duas fontes. A contagem por UF/pasta/boletim
  não é a mesma definição dos 526 grupos por chave completa, que inclui distrito.
- `.../existentes_proposta_integral_01/resultado.json`: evidência dos 133 vínculos
  condicionais, incluindo diferenças preservadas e decisões de duplicatas usadas.
- `.../alternativas_integral_02/`: revisão das 71 chaves/164 pessoas, cartões
  próprios examinados, alternativas descartadas e remanescentes.
- `.../entrega_02/`: CSV de 33 vínculos estritos, CSV de 133 condicionais, duas
  origens do caso425558, índice e cópias das decisões/guias anteriores, preservadas
  antes das próximas alterações do projeto.

A tentativa `alternativas_mg_01` foi interrompida por lentidão de uma consulta na
visão temporária; somente o processo desta auditoria foi encerrado. A consulta
foi ajustada para usar os índices existentes, sem alterar o arquivoSQLite fonte.
O piloto aprovado é `alternativas_mg_02`, seguido das ampliações integrais.

Os casos sem fonte25 disponível, com chaves destruídas, com respostas ou contagens
incompatíveis ou com alternativas ainda não afastadas permanecem como incerteza
real. O inventário completo permite decidir um tratamento explícito e medir seu
impacto; ele não é justificativa para exclusão automática ou vínculo presumido.
