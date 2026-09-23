# Entrega integrada de 1960 — 23/09/2026

## O resultado, em linguagem direta

Houve correções novas, execução sobre arquivos completos e recálculo efetivo de
pesos. Não se trata apenas de outro parecer. Mas **a base nacional corrigida ainda
não pode ser certificada**: parte dos registros da amostra de 1,27% não contém
informação suficiente para decidir a família ou quantas pessoas os registros representam.
Este documento separa o que foi feito do que uma execução não consegue decidir.

| Pedido | Resultado verificável |
|---|---|
| Resolver registros incertos | Mais nove cartões familiares comprovados, um reparo textual e duas pessoas preservadas; as incertezas restantes têm listas nominais e contraprovas. |
| Fechar as conferências | Doze linhas municipais corrigidas; Paraná inteiro conferido; causas e limites de domicílios, aluguel e idade ignorada explicitados. Algumas regras históricas de apuração continuam não identificadas. |
| Reconstruir e recalcular | Pesos novos de MT, PR e MG; 34 arquivos completos de 17 UFs conferidos. O ramo de 1,27% não foi certificado nem misturado aos arquivos novos. |
| Preparar a entrega | Código, regras de correção, provas, testes e relatórios separados por estado de aprovação. Não houve publicação de uma nova base nacional. |

“Reunir as amostras” significa escolher a fonte prevista para cada UF e juntar
essas partes em uma base nacional. **Não significa somar as duas fontes nem
contar duas vezes quem aparece nas duas.** É isso que o projeto chama de
compilação. Enquanto uma das partes necessárias não estiver correta, reunir
arquivos não resolve seu problema de origem.

## 1. Registros: o que mudou e por que

### Uma família pode estar sem cartão, sem que suas pessoas estejam faltando

O arquivo antigo tem dois tipos de registro: o cartão familiar, com as respostas
da moradia, e as linhas das pessoas. Algumas pessoas estão presentes, mas seu
cartão não está. Anexá-las ao cartão anterior só porque ele está perto pode
transferi-las para outra família ou outro município.

A busca desta rodada comprovou mais nove cartões na fonte de 25%, para **23
pessoas que já existiam** na fonte de 1,27%. Não foram importadas novas pessoas.
O conjunto de regras passa a conter **41 cartões para 103 pessoas existentes**.
Cada cartão mantém a identificação do arquivo e da linha de origem; ele não
recebe uma falsa posição no arquivo antigo.

A correspondência não se apoia apenas em idade, sexo ou proximidade. Compara o
grupo completo, a quantidade de ocorrências de cada perfil, a geografia e os
cartões concorrentes. Quando duas pessoas têm respostas iguais, a comparação
conserva as duas ocorrências. Nos casos novos, também foi preciso demonstrar a
qual família pertenciam os possíveis concorrentes. Divergências de resposta
entre versões não foram apagadas para fabricar igualdade.

### Exemplo concreto: uma idade incompleta em Minas Gerais

A linha **405458**, da pasta 40880/boletim 001, tinha o parentesco em branco e a
idade escrita como ` 9`: faltava a dezena, mas o algarismo 9 estava legível.
Escolher 9, 19 ou 79 pela composição aparentemente plausível da família seria
um palpite.

Duas outras pessoas do mesmo grupo, linhas **405457 e 405459**, estavam intactas.
Seus perfis, considerados separadamente, apareciam em vários grupos da fonte
maior; considerados juntos, identificaram um único grupo. Só depois dessa
identificação foi usado o registro correspondente da pessoa danificada. Ele
mostra parentesco **7** e idade **79**, conservando o algarismo já conhecido.

O reparo altera somente duas posições: parentesco e dezena da idade. Mantém o
tipo original do registro, a unidade da idade, a localização e as demais
respostas. O próprio alvo danificado não foi usado como testemunha de sua
identidade. Os testes recusam, entre outras coisas, usar o alvo como testemunha,
trocar um algarismo legível ou propor um valor diferente da fonte comprovada.

O manifesto passa a conter **38 reparos comprovados pela fonte de 25%**. Isso não
significa que todo texto danificado tenha sido recuperado.

### Exemplo concreto: duas respostas iguais em São Paulo não autorizam uma exclusão

As linhas **773911 e 773913**, no grupo da pasta 63788/boletim 146, tinham respostas
iguais. A fonte maior contém um grupo correspondente com quatro pessoas, incluindo
**duas ocorrências** daquele perfil. A composição completa e o cartão coincidem;
os grupos concorrentes também foram identificados em seus próprios lugares.

A decisão correta é **preservar as duas linhas**. Não é necessário saber se eram
irmãos ou qual era seu nome: a prova é a multiplicidade no grupo correspondente.
O arquivo de decisões passa a ter 6.463 linhas: 3.727 decisões de manter e 2.736
de remover. São decisões acumuladas de várias rodadas, não exclusões executadas
nesta reconstrução final.

### O que permanece sem solução documental

| Pendência | Quantidade atual | Informação que falta |
|---|---:|---|
| Respostas pessoais repetidas sem decisão | 457 grupos, 916 linhas | Prova de quantas pessoas distintas havia, ou fonte correspondente com multiplicidades confirmadas. |
| Pessoas sem cartão confirmado | 1.193 registros, 472 chaves de grupo | Cartão identificável e ligação comprovada; a lista inclui três fragmentos danificados. |
| Conflitos de município ou situação urbana/rural | 192 pessoas | Evidência que decida qual informação territorial corresponde ao registro. |
| Famílias inteiras coincidentes | 5 conjuntos, 11 cartões, 42 pessoas | Prova que diferencie repetição da gravação de famílias distintas com respostas iguais. |
| Cartão sem pessoas e convivente sem principal comprovado | 1 caso de cada | Lista familiar ou vínculo original; proximidade física não basta. |

**As listas se sobrepõem; não some essas quantidades.** “Sem solução” significa
que as fontes examinadas não identificam a resposta, não que seja impossível
encontrar outro documento no futuro.

Foram examinadas todas as 17 fontes maiores disponíveis, e não apenas alguns
casos exemplares. A busca também obteve a cópia pública do CEM em formato SAV e
comparou seus **899.861 registros** integralmente. Ela repete os campos familiares
do cartão fisicamente anterior e os mesmos danos do arquivo antigo. A ordem de
parte das pessoas muda, mas não aparece uma identificação independente. O SAV
também perde detalhe em `V210`; a equivalência da leitura numérica exige
reproduzir as conversões observadas nesse arquivo. Assim, essa cópia não fornece
a informação perdida. A [nota do CEM](fechamento_integral_1960_cem_20260923.md)
explica a comparação e seus limites.

Há também casos que não são impossibilidade absoluta, mas hipóteses ainda fora
do critério comprovado. Dois cartões do Paraná, pasta 70078/boletins 238 e 239,
para sete pessoas, dependem de aceitar uma divergência adicional de resposta
no grupo concorrente. Essa hipótese foi examinada e preservada na prova, não
descartada como se faltasse toda fonte nem aprovada apenas por ser plausível.

Para uma sequência de respostas iguais, há pelo menos duas histórias compatíveis
com os mesmos dados: duas pessoas responderam igual; ou uma pessoa foi gravada
duas vezes. Executar mais vezes o mesmo algoritmo não distingue essas histórias.
Seriam necessários boletins originais, listagens anteriores à transformação ou
outra fonte que preserve os identificadores e a composição familiar.

## 2. As conferências encontraram erros reais nas tabelas usadas pelos pesos

Um peso indica quantas pessoas ou domicílios da população uma observação da
amostra representa. O ajuste dos pesos procura reproduzir determinados totais
publicados. Se o total digitado estiver errado, fechar a conta com ele não é
evidência de correção.

### Paraná: a diferença de 4.916 habitantes tinha uma origem verificável

Os **162 municípios** foram conferidos nas 21 páginas do Quadro II da Sinopse,
incluindo as somas das onze zonas do estado. Sete linhas estavam divergentes.
O guia somava 4.272.847 habitantes; a soma correta é **4.277.763**, igual ao total
estadual publicado. Não foram criadas 4.916 pessoas nos microdados: corrigiu-se
uma tabela de referência utilizada no cálculo dos pesos.

Por exemplo, Bituruna tinha 634 habitantes urbanos no guia: era o número do
distrito-sede. Faltavam os 72 habitantes urbanos de Santo Antônio do Iratim.
O total urbano municipal correto é **706**.

### Alpinópolis: o número rural vinha da linha de outro município

O guia trazia 6.298 habitantes rurais. O fac-símile mostra **15.295**, enquanto
6.298 pertence a Alterosa, na linha seguinte. Os distritos também confirmam a
soma de Alpinópolis. Reescalar todos os municípios para um total estadual não
corrige uma distribuição municipal construída com esse número errado.

O exame aritmético das 2.770 linhas do guia encontrou cinco divergências fora do
Paraná, todas conferidas nas imagens: Alpinópolis, Itumirim, Jardinópolis,
São Bento do Sul e Coxim. As **12 linhas corrigidas** e suas páginas estão na
[nota municipal](fechamento_integral_1960_pr_20260923.md). As outras 2.758 linhas
foram preservadas integralmente. O exame aritmético nacional não equivale a uma
retranscrição visual de todos os municípios brasileiros.

O cálculo em R agora recusa município repetido, população negativa ou infinita
e total diferente da soma urbana e rural. Componentes realmente ausentes não
foram transformados em zero.

### Domicílios, aluguel e estado conjugal

Na tabela de domicílios da fonte de 25%, **206 casas e 998 moradores** têm o tipo
da moradia declarado como ignorado. Isso impede decidir se pertencem ao grupo
de domicílios particulares permanentes. Não são casas inventadas nem pessoas
sem registro. O relatório mantém a dúvida e o suplemento mostra o menor e o
maior resultado compatível com essa classificação desconhecida, usando os
pesos atuais. Esses limites **não são intervalos de confiança**.
Os limites agora são calculados pelo próprio validador em R, e não apenas por
um suplemento externo. A conferência independente refez as 204 comparações
domiciliares diretamente dos arquivos completos. As demais 1.836 comparações
não receberam limites domiciliares indevidos.

Em Sergipe, por exemplo, são duas casas e dez moradores com esse tipo ignorado.
Com o peso municipal ajustado, incluí-los poderia acrescentar aproximadamente
7,30 domicílios e 33,23 moradores ao resultado estimado. Não significa que
existam 7,30 casas na amostra: é a contribuição das duas casas depois da expansão
pelos pesos. Nesse caso, o total publicado permanece fora do intervalo, abaixo
dos dois extremos; portanto o tipo ignorado não explica sozinho a diferença.

O aluguel ignorado permanece no total de domicílios alugados, mas não recebe
uma faixa de valor inventada. A publicação inclui os sem declaração de aluguel,
porém não permite saber se ou como foram distribuídos pelas faixas. Isso é
diferente de não declarar a condição de ocupação da moradia. Outra situação antes mal descrita,
“alugado/não paga aluguel”, pode ser legítima: o manual prevê um pagamento
conjunto da residência com uma unidade comercial ou estabelecimento agrícola,
sem valor separado para a moradia.

O Quadro 5 preliminar se refere aos residentes de quinze anos ou mais, não aos
presentes usados no Quadro 2. Ainda não foi encontrada a regra de inclusão das
idades ignoradas nesse Quadro 5. Há instrução explícita na publicação
definitiva, mas não prova de que o processamento preliminar tenha seguido a
mesma convenção. Foram calculados os dois cenários, sem mudar a idade das pessoas.
Na base antiga de 1,27%, há 1.431 registros de idade declarada ignorada pertinentes
ao cenário: incluí-los altera o total ponderado brasileiro em cerca de 111.455.
Esse número é uma análise de sensibilidade da **base antiga**, não um resultado
de uma reconstrução corrigida nem uma contagem de pessoas criadas.

A [nota das conferências](fechamento_integral_1960_conferencias_20260923.md)
contém as páginas, os exemplos e os critérios. A leitura visual dos PDFs,
orientada pela habilidade de PDF, foi decisiva para confirmar números ambíguos
e identificar a instrução sobre aluguel conjunto.

## 3. O que foi reconstruído e recalculado

Foram recalculados os pesos de **Mato Grosso, Paraná e Minas Gerais**. Os novos
pesos foram reunidos às colunas completas de cada arquivo, preservando a ordem,
os identificadores e as respostas originais. As demais 14 UFs reutilizam seus
arquivos anteriormente conferidos, sem recalcular algo cujas entradas não mudaram.

O conjunto da fonte de 25% tem **34 arquivos**, 3.066.365 domicílios e 14.983.769
registros pessoais. A validação atual contém **2.040 comparações**: cada uma é
uma pergunta como “o total ponderado de determinada categoria e UF confere com
o número publicado?”. Uma comparação acrescentada ao relatório não acrescenta
uma pessoa aos dados.

Os cálculos novos tiveram uma conferência independente: os totais utilizados
foram reconstruídos a partir das fontes, os pesos foram somados diretamente
nas pessoas, e foram verificados alinhamento, positividade, limites e igualdade
entre pesos da pessoa e de seu domicílio. Um teste contra os pesos antigos do
Paraná falhou, mostrando que a conferência distingue o resultado antigo do novo.

**Limitações que esse recálculo não elimina:** Alto Garças, em MT, não tem
observações na fonte disponível; ajustar os totais estaduais não cria amostra
municipal. Os totais definitivos derivados da amostra de 25% continuam sendo
estimativas, não verdades populacionais sem incerteza. As variâncias após a
calibração continuam fora desta implementação, conforme o adiamento anterior.

A parte de 1,27% exige uma decisão comprovada sobre seus registros antes de
novos pesos finais. Ela não foi substituída por arquivos antigos com outro nome.
Na execução integral final, o R leu 1.074.328 linhas, aplicou as correções e
separou 174.467 cartões e 899.859 registros pessoais. A etapa seguinte parou
antes das exclusões por causa das repetições não decididas: 459 ocorrências
após a primeira, pertencentes aos 457 grupos do inventário. **Não foi uma falha
de memória do R nem um pedido de autorização:** é a proteção contra excluir
pessoas sem prova. O arquivo intermediário e o motivo da parada foram preservados.

Sem essa parte, também falta medir os tipos das **15 colunas de procedência** no
produto nacional real: por exemplo, quais são identificadores numéricos, textos
ou indicadores. Essa definição não foi preenchida à mão. Os percentuais já
medidos em SE/GB tampouco foram apresentados como medição nacional do dicionário.
Falta ainda comparar integralmente fonte, base reunida e arquivo final. Os
testes técnicos de exportação não substituem essas conferências dos dados reais.

## 4. Geografia: retiradas certezas indevidas, sem inventar nomes

O distrito sem nome de Livramento não pode mais ser descrito como uma divisão
interna da sede sem outra possibilidade: o IBGE registra **Seco** entre os três
distritos de 1960. Em Dois Irmãos, **Morro Reuter** também está documentado, e
aparece como código 03 no cadastro de 1970. Falta provar a ligação desses nomes
com os códigos operacionais dos cartões de 1960; nomes candidatos não viraram
recodificações automáticas.

Em Itutinga, a diferença entre amostra expandida e publicação não prova
“sobreamostragem”. A hipótese de registros vindos de Ingaí, em Itumirim, foi
testada contra todos os 489.898 grupos da fonte mineira, sem correspondência
familiar integral. Os códigos foram preservados. Em Horizontina e Tenente
Portela, o cadastro de 1970 tampouco resolve a numeração de 1960 com certeza.

As notas de [MG/MT](fechamento_integral_1960_geografia_mgmt.md),
[Dois Irmãos](fechamento_integral_1960_geografia_rs_resultado.md) e
[Horizontina/Tenente Portela](fechamento_integral_1960_geografia_rs_pares_resultado.md)
mostram a evidência e a alternativa que permanece. Código incompatível, sozinho,
não foi tratado como prova de dano físico da fita.

## 5. Desenho: cinco pastas receberam uma conferência que faltava

Uma pasta reúne boletins censitários. O código atual classifica a pasta a partir
das situações urbana/rural de seus domicílios; essa classificação participa da
formação dos grupos usados no cálculo. Por isso, um cartão com situação errada
pode afetar mais do que sua própria família.

Foram examinadas CE 15004/15290, MG 43234 e SP 60158/60718, confrontando os textos
originais, as correspondências entre fontes e os rótulos dos arquivos antigos.
Em CE 15004, a comparação anterior usava a pasta de mesmo número da outra fonte,
mas **176 dos 196 grupos** coincidem nos 24 quesitos pessoais comparados, omitindo
somente o ano do casamento (`V216`), na pasta **14990**, não na 15004 examinada.
Desses 176, **145** também coincidem no corpo familiar e na localização; 31
têm diferenças familiares. Os cartões das duas pastas são rurais, e os 145
pareamentos completos confirmam essa concordância.
A discordância anterior não pode ser interpretada como comparação do mesmo
conjunto apenas porque os códigos eram iguais. Isso corrige o diagnóstico, não
autoriza renumerar todas as pastas nem afirmar correspondência dos 20 grupos
restantes.

Nas outras quatro pastas, oito cartões explicam a divergência de classificação.
As 27 pessoas com situação discordante já estavam entre os 192 conflitos
conhecidos. O exemplo de SP 60718 é concreto: cartão e chefe dizem rural, outras
duas pessoas dizem urbano, e a outra fonte traz o cartão urbano. O grupo foi
identificado, mas contar esses registros como votos não decide qual situação
estava correta. Falta uma localização independente do boletim ou documentação
do erro ocorrido entre versões.

A [conferência das cinco pastas](fechamento_integral_1960_duplicatas_pastas_resultado.md)
contém os oito cartões e seus integrantes. Nenhuma fração amostral, estrato,
peso ou identificador foi alterado para forçar concordância. O cadastro amostral
nacional e as análises de posições e intervalos de seleção não foram
recertificados: dependem dessas correspondências e dos registros ainda incertos.

## 6. Como auditar esta entrega

As regras aplicadas ficam em `read_guides/1960_amostra_127_*`; as provas novas,
em `references/fechamento_integral_1960_evidencias/`. Elas registram arquivos,
linhas, textos antes/depois e assinaturas SHA-256. A assinatura permite conferir
que a prova se refere à mesma cópia do arquivo; não prova, sozinha, a identidade
de uma pessoa.

O [índice de artefatos](fechamento_integral_1960_entrega.json) identifica os
resultados válidos, as execuções rejeitadas e os logs. O
[inventário nominal final](fechamento_integral_1960_vinculos_limites.md) e a
[revisão independente](fechamento_integral_1960_duplicatas_revisao_final.md)
permitem chegar de cada conclusão às linhas examinadas.

Os originais, os parquets antigos, `renv.lock`, o arquivo de projeto e o esquema
de tipos foram preservados. Os arquivos novos estão em uma área separada de
trabalho; **não houve substituição silenciosa de uma versão publicada**.

### Arquivos de consulta direta

| Conteúdo | Arquivo e condição de uso |
|---|---|
| 34 arquivos completos da fonte de 25% | [Índice com caminhos e assinaturas](../tmp/fechamento_integral_1960/pesos_municipais_20260923_021933_338649_completo/indice_34_parquets_completos.json). Conferidos, não são a base nacional reunida. |
| Validação atual de 25% | [2.040 comparações com limites domiciliares](../tmp/fechamento_integral_1960/relatorios/validacao25_c2e0493926db/validacao_definitivos.csv). |
| Conferência independente dos limites | [204 comparações domiciliares](../tmp/fechamento_integral_1960/conferencias/limites_validador_20260923/t7_celulas_17ufs.csv). |
| Aluguel e demais quadros preliminares | [4.440 comparações da base antiga](../tmp/fechamento_integral_1960/relatorios/preliminar_base_antiga_c1641f26838/calibracao_1965_validacao.csv). Não são resultados de uma nova base de 1,27%. |
| Idade ignorada no Quadro 5 | [Cenários de inclusão/exclusão](../tmp/fechamento_integral_1960/relatorios/preliminar_base_antiga_c1641f26838/q5_cenarios_idade_ignorada.csv), também sobre a base antiga. |
| Execução integral de 1,27% | [Log da parada por registros sem decisão](../tmp/fechamento_integral_1960/logs/reconstrucao127_final02.log). Nenhuma exclusão feita nessa tentativa. |
| Pendências, sem dupla contagem | [Listas nominais e informação faltante](fechamento_integral_1960_evidencias/pendencias_nominais.json). |

### Verificações encerradas nesta rodada

**33 scripts de teste R aprovaram em sua execução final**, incluindo as regressões
preexistentes e os testes novos de vínculos, duplicatas, aluguel, detecção e
limites domiciliares. O teste de publicação verificou exportação,
releitura e 31 recusas técnicas. A conferência municipal portátil também passou:
12 alterações autorizadas, 2.758 linhas restantes preservadas.

Os testes tiveram duas intercorrências preservadas no índice: a recuperação
completa atingiu o prazo inicial de 300 segundos e passou quando repetida com
prazo suficiente; a nova recusa de peso negativo no validador passou a ocorrer
antes da recusa antiga na exportação. O teste foi atualizado para exigir essa
recusa antecipada e ganhou outra contraprova para manter a proteção final.
Não foi removida nenhuma exigência de integridade dos dados.

A primeira leitura completa dos parquets parou com a configuração de uma
única tarefa de entrada/saída do Arrow. Encerrado somente o processo identificado
desta tarefa, a repetição com duas tarefas de entrada/saída passou. O R continuou
isolado e com um único processo de cálculo por vez. O erro nativo de memória
mostrado pelo usuário não reapareceu nessas execuções; isso não significa que
uma chamada fora do runner isolado esteja automaticamente protegida.

O índice final reconferiu as assinaturas dos 34 arquivos completos, dos
originais protegidos e das fontes do relatório. `renv.lock`, o arquivo de
projeto e o esquema permaneceram exatamente como estavam no início desta rodada.
Não houve novo commit, push ou release nesta rodada.

**O impedimento restante não é falta de autorização para executar.** Para a
parte nacional ainda não certificada, faltam informações que distingam as
hipóteses históricas. Uma política de imputação ou de exclusão dos casos
incertos seria uma decisão metodológica diferente de corrigir fatos comprovados.
