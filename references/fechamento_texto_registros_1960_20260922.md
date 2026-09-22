# Registros de 1960: fechamento da conferência de texto

Data: 22/09/2026. Esta frente examina o texto das linhas e as respostas que podem ser recuperadas. Não recalcula pesos e não substitui a base completa. A aplicação dos reparos ao pipeline pertence à integração principal da mesma rodada.

## Resultado em linguagem direta

Foram relidas **todas as 1.074.328 linhas de HHOLDA**. Todas têm 62 caracteres. Os testes de código, caracteres, espaços, estrutura e chave apontaram 124 linhas; todas já tinham uma decisão registrada. Isso fecha a cobertura desses testes, **não prova que todo código numericamente válido represente a resposta verdadeira**.

Na **passagem final, com o mesmo critério aplicado aos 47 candidatos**, foram selecionadas propostas para **40 campos em 33 registros: 24 pessoas e nove cartões familiares**. Quinze são nacionalidades pessoais que o procedimento anterior preenchia por regra geral; agora há uma origem individual e conferível para cada preenchimento. Os demais são nove outros campos pessoais e 16 campos domiciliares. Nenhuma proposta acrescenta ou exclui pessoas. A aplicação e a revisão independente pertencem à integração principal; selecionar uma proposta não certifica a base inteira.

Separadamente, há prova localizada de município para dois registros do Paraná, conservando o código literal danificado e indicando o município na coluna derivada. Um desses dois registros também está entre os casos que o reparador de respostas comum deixou pendentes: **não se devem somar as listas como se fossem pessoas distintas**.

Exemplo: na linha **760742**, a idade aparece como `0 `: um zero seguido de espaço. Não é uma declaração válida de zero ano. No boletim paulista **61852/143**, a fonte25 contém a pessoa correspondente, linha **2591609**, com idade `08`. O cartão, as cinco pessoas do boletim, sua composição e todas as outras respostas conferem. A proposta é preencher somente a posição perdida: `0 ` passa a `08`; não se deduz a idade pela idade dos pais ou de irmãos.

Outro exemplo: em **710182–710184**, o campo de procedência contém a letra `Z`. No boletim **62478/193**, as cinco pessoas e o cartão conferem nas duas fontes, inclusive as pessoas em ordens diferentes. As linhas25 **2990285, 2990287 e 2990286**, nessa ordem de correspondência, têm código `0`. Corrigir `Z` para `0` não significa trocar toda letra por zero: a autorização fica limitada a essas linhas e à prova preservada.

### O conjunto final e os limites da decisão

O alvo do reparo precisa coincidir em todos os seus outros campos legíveis. Em um campo parcialmente danificado, até os dígitos que sobreviveram devem ser conservados: não se troca `3 ` por `25`, por exemplo. As fontes precisam ter cartão único, mesma identidade geográfica e questionário, grupo pessoal completo, mesmas quantidades e multiplicidades. A contagem declarada, as ordens e as redundâncias da fonte25 são conferidas.

Diferenças 00/63 no ano do casamento de **outros integrantes** podem ser preservadas e documentadas ao identificar o grupo; não se alteram esses valores. Também pode haver diferença em uma característica não identificadora do cartão, como tipo construtivo da moradia, quando se está recuperando uma resposta pessoal. Isso não vale para substituir respostas legíveis do próprio cartão-alvo. E dano transformado em ausência no leitor não serve como prova de igualdade a uma pergunta legitimamente não aplicável na outra fonte.

Os nove cartões selecionados são:

| Linha HHOLDA | Campos recuperáveis | Cartão25 |
|---:|---|---:|
| 607903 | Condição de ocupação e rádio, V103/V109 | RJ 965228 |
| 803760 | V103, V104, V105, V108, V109, V110 e V112 | SP 390707 |
| 994324 | Geladeira, V110 | RS 963039 |
| 1002257 | Geladeira, V110 | RS 1061434 |
| 1002771 | Geladeira, V110 | RS 1109881 |
| 1005344 | Fogão, V107 | RS 1164782 |
| 1005687 | Aluguel, V104 | RS 1165130 |
| 1005952 | Geladeira, V110 | RS 1169039 |
| 1026174 | Geladeira, V110 | RS 1625794 |

O cartão 803760, por exemplo, não recebeu características copiadas da casa vizinha. Os sete campos são recuperáveis porque seu próprio cartão na fonte25 foi identificado pelo conjunto familiar, e **todos os demais campos familiares legíveis coincidem**. No Rio de Janeiro, a mesma prova permite recuperar renda V219=9 da pessoa **607904**, correspondente à linha25 **965229**. As demais 23 pessoas estão descritas nas passagens abaixo.

**Quatorze dos 47 candidatos não passaram pelo mecanismo comum**, e todos têm motivo explícito. Oito têm composição pessoal que não fecha sem aceitar diferenças adicionais ou mascarar dano: 162537, 540394, 540399, 540461, 760804, 806984, 962975 e 1070216. O caso 238423 tem conflito de distrito. O caso 405458 não tem cartão127 único. Os casos 830335, 951430 e 951431 têm quantidades diferentes entre os grupos, e 951431 também não tem cartão127 único. O caso 887255 tem município danificado; sua evidência de geografia foi tratada separadamente e não serve de autorização para o reparador genérico ignorar divergências geográficas.

O arquivo consolidado de seleção é `texto/selecao_final02/selecao_final_reparos.json`, sob a raiz temporária indicada no fim desta nota. Ele contém **todos os 47 casos**, as 33 propostas e os 14 resíduos, com literais, motivos e a correspondência integral. As passagens intermediárias descritas a seguir mostram a evolução da prova; a seleção final é esta, não uma soma das rodadas.

## O inventário inteiro, não apenas os exemplos

As 124 decisões anteriores se distribuem em 101 problemas de valor isolado, 12 reparos, cinco recuperações de fragmentos, dois cabeçalhos de estado, uma pessoa realocada e três linhas classificadas como corrompidas. O inventário registra para cada linha: texto original, texto corrigido vigente, campos alterados, dano ainda observado, candidatos na fonte25 e composição completa do boletim.

Entre os 119 casos que não são cabeçalhos nem linhas integralmente corrompidas, 22 têm candidato igual nos campos comuns; 47 têm candidato compatível, mas com algum campo ausente ou danificado; 22 têm diferenças em respostas legíveis; 28 não têm candidato encontrado pela chave. **“Candidato” significa um registro a conferir, não uma pessoa identificada nem um reparo autorizado.**

Na **primeira prova**, que ainda exigia igualdade de todas as respostas do contexto, 17 dos 47 candidatos passaram e trinta não passaram. Ela exigia cartão existente e único em cada fonte; município, distrito e situação concordantes; todas as pessoas e suas multiplicidades; ordens completas e contagem declarada na fonte25; preservação de todos os campos legíveis. Só as exclusões de duplicatas já aprovadas foram aplicadas à comparação, sem excluir pessoas novas para fazer o grupo coincidir. A distinção posterior entre identidade do grupo e diferença de resposta levou à passagem final homogênea descrita acima.

### Os 17 reparos da primeira seleção

| Linha HHOLDA | Campo | Antes | Depois | Linha25 |
|---:|---|---|---|---:|
| 224345 | V208, nacionalidade | `R` | `9` | PE 584876 |
| 228629 | V208 | branco | `9` | PE 645003 |
| 445777 | V208 | branco | `9` | MG 1323844 |
| 710182 | V209, procedência | `Z` | `0` | SP 2990285 |
| 710183 | V209 | `Z` | `0` | SP 2990287 |
| 710184 | V209 | `Z` | `0` | SP 2990286 |
| 760742 | AGE, número da idade | `0 ` | `08` | SP 2591609 |
| 766772 | V208 | branco | `9` | SP 3694493 |
| 793783 | V209 | `Z` | `0` | SP 188047 |
| 827521 | V208 | branco | `9` | SP 856736 |
| 831654 | V208 | branco | `9` | SP 939012 |
| 983242 | V208 | branco | `9` | RS 699426 |
| 997505 | V208 | branco | `9` | RS 999434 |
| 1019901 | V208 | branco | `9` | RS 1470021 |
| 1020372 | V208 | branco | `9` | RS 1470498 |
| 1023596 | V208 | branco | `9` | RS 1540998 |
| 1066496 | V204, unidade da idade | `/` | `0` | GO 516169 |

No último caso, `0` significa idade expressa em meses, não uma declaração de que a pessoa tinha zero ano. O número da idade permanece `04`: quatro meses, conforme o registro25. V208=9 significa brasileiro nato. V209=0 tem seu significado original no dicionário; não se reinterpretou esse código.

O arquivo versionado de propostas é `read_guides/1960_amostra_127_reparos_fonte25.json`. Sua igualdade integral com as 17 aprovações da auditoria foi conferida, incluindo literais, campos, posições e grupos. Essa conferência pelo autor do script não substitui a revisão independente da integração.

### Aprofundamento: respostas diferentes no contexto não são a mesma pessoa ausente

A prova de identificação foi aprofundada em uma segunda passagem, sem alterar os códigos divergentes. É preciso distinguir duas perguntas: “estas duas fontes descrevem o mesmo boletim e as mesmas pessoas?” e “todas as respostas são iguais?”. Uma diferença de resposta não demonstra, sozinha, que se trata de outra pessoa. Para essa passagem, o alvo do reparo continua exigindo igualdade das outras 24 variáveis; as diferenças dos demais integrantes são enumeradas, não convertidas em igualdade nos dados.

Foram preparados **quatro candidatos adicionais de nacionalidade**: HHOLDA 541238 (SA 35447), 963286 (RS 462139), 998640 (RS 1000578) e 1019837 (RS 1469959). Os quatro têm cartão único, composição integral, quantidade declarada, ordens e geografia conferidas. Os conflitos pessoais no restante do grupo se limitam a V216=00/63. No caso 541238, o cartão também difere em tipo de domicílio, V102=5/4; a proposta conserva o 5 original e não repara essa resposta. O manifesto adicional guarda todas essas diferenças. Nenhum código V216 é alterado. Esses candidatos foram encaminhados para revisão independente antes da aplicação.

A mesma conferência foi estendida aos outros campos, para não deixar um tipo de dano menos investigado que a nacionalidade. Dois candidatos adicionais têm a mesma qualidade de prova, sem outros campos pessoais danificados no contexto:

| Linha HHOLDA | Campo e alteração limitada | Fonte25 | Composição |
|---:|---|---|---|
| 675159 | Ocupação V221: ` 21` → `921` | SP 1843286 | Cartão e três pessoas |
| 706676 | Naturalidade V207: `0'` → `05` | SP 2938398 | Cartão e oito pessoas |

Um terceiro candidato, **760804**, permitiria V218 `0Z` → `00`, conforme SP 2591673. Contudo, outro integrante do mesmo grupo, **760807**, contém ruído depois do hífen de salto. O leitor transforma seus campos danificados em ausentes, enquanto a fonte25 tem campos legitimamente não aplicáveis. Essa coincidência de ausências **não é uma igualdade de conteúdo demonstrada**. O candidato 760804 foi, por isso, encaminhado com ressalva, não no mesmo conjunto dos dois anteriores.

Essa passagem chegou a **23 propostas pessoais: 15 nacionalidades e oito outros campos**. A aplicação homogênea do critério aos 47 candidatos, sem privilegiar apenas os primeiros exemplos, encontrou ainda a pessoa do Rio de Janeiro e os nove cartões descritos no resultado final. A aplicação efetivamente realizada deve ser conferida no manifesto e no registro de integração; esta nota não transforma candidatos em alterações por antecipação.

## O que não deve ser “consertado” trocando uma resposta legível

**Ano de casamento, códigos 00 e 63.** O Código do Censo, página impressa 8/PDF 9, define 00 como ausência de cônjuge ou de convivência com ele; 63 significa informação ignorada. A página foi conferida visualmente. Os códigos não são sinônimos. Há candidatos que coincidem nas demais respostas, mas divergem nesse campo. O inventário conserva a diferença e não troca a resposta da amostra de 1,27% pela da amostra de 25% para fazer uma prova passar.

**Linha 830192, São Paulo.** O fragmento preservado permite ler V216=56; o candidato da fonte de 25%, linha 927191, tem 57. Não foi demonstrado que o 56 seja erro de deslocamento. Portanto, não se propõe alterar o ano por preferência pela outra cópia. Os campos perdidos posteriores também não são completados automaticamente.

**Linha 388894, Pernambuco.** O texto corrigido preserva `8632` nas posições 47–50: ocupação V221=863 e V223=2. A explicação antiga dizia que V221–V224 se perderam, o que não descreve o texto aplicado. O correto é registrar que V221 e V223 foram preservados e que V223B/V224 ficaram sem recuperação. O candidato da fonte de 25%, linha 101778, diverge em V221=989 e V216=63; essas divergências não autorizam apagar 863 ou substituir por 989. Corrigir a explicação é distinto de modificar respostas.

**Nacionalidade preenchida por regra geral.** A revisão anterior encontrou 19 preenchimentos: 18 brancos e um `R`, não 19 brancos. Todos têm candidato individual na fonte de 25% com as outras 24 variáveis pessoais comuns concordantes e V208=9; a presente releitura dos gzip confirmou as diferenças localizadas. Onze passaram na prova estrita e quatro adicionais na conferência de identidade descrita acima. Os quatro ainda sem proposta aprovada são HHOLDA 238423, 540394, 540399 e 540461. Seus candidatos são, respectivamente, PE 902375 e SA 34601, 34598, 34663. Em 238423 há conflito de distrito. No grupo de 540394/540399, outro integrante difere em escolaridade: HHOLDA 540397 versus SA 34603, V212=1/4 e V213=1/2. No grupo de 540461, HHOLDA 540458 versus SA 34667 difere em V220=1/5. Não se alteram essas respostas para fazer a prova passar. A recomendação é não manter uma regra aberta que preencha qualquer futura ausência de V208 apenas por V207 indicar nascimento no Brasil: decisões localizadas tornam a base auditável. HHOLDA 85316, por exemplo, contém V207=29 e V208=1; não se escolheu silenciosamente qual resposta estaria errada.

## As três linhas corrompidas: o contexto foi investigado

Não se concluiu simplesmente que “não têm chave”. Foram examinadas as vizinhanças em HHOLDA, os boletins correspondentes na fonte de 25% e uma hipótese explícita de recuperação de fragmento. A busca percorreu os **18.055.053 registros preservados nas 17 fontes estaduais da amostra de 25%**, além de HHOLDA.

**855822.** Está entre o final de São Paulo e o início do Paraná. Começa com 91, mas contém outro fragmento iniciado por 60; esse 91 não é prova de que a pessoa seja de Mato Grosso. Removidos os espaços do primeiro trecho, há 35 dígitos que poderiam ser uma cauda completa de V203 até V224. Essa hipótese foi pesquisada como hipótese, não aplicada como correção: nenhuma correspondência literal foi encontrada em HHOLDA nem nas 17 fontes de 25%. Uma busca separada com V216=63 também não encontrou correspondência; isso não equipara 63 a 00. O boletim paulista imediatamente anterior, 66274/209, possui nove pessoas legíveis em HHOLDA e nove na fonte de 25%. Não existe prova para acrescentar-lhe uma décima pessoa só pela posição da linha corrompida. A ausência de coincidência nessa busca limitada não prova que a pessoa histórica não tenha existido.

**951432 e 951433.** A primeira preserva praticamente apenas 81 e o marcador de tipo 3. A segunda contém números e sinais sem alinhamento demonstrado. Os dois menores que aparecem depois delas pertencem aos boletins RS 82402/101 e 82402/103; as composições desses boletins já conferem integralmente, com sete e cinco pessoas. Assim, estar ao lado deles não identifica a família dos fragmentos.

Há outras perdas possíveis na mesma região danificada do arquivo. O boletim RS 81076/016 conserva uma pessoa em HHOLDA, enquanto a fonte de 25% tem três. O boletim 017 conserva três, enquanto a fonte de 25% tem sete — não três. Só essas duas possibilidades já impedem usar a quantidade de fragmentos como solução automática.

Além disso, uma linha pode misturar trechos de mais de um registro: **951430**, hoje usada para recuperar um cartão familiar, começa por `1821000000008371323326` antes da barra. Essa cauda de 22 dígitos é compatível com a cauda da pessoa RS 252041 do boletim 016, exceto novamente V216 00/63. A linha 951431 começa com o trecho curto `34-` antes de sua parte pessoal recuperada, compatível com mais de um fim de registro inativo. Essas pistas mostram dano misturado, mas não demonstram quantas pessoas completas devem ser criadas nem a identidade dos dois fragmentos restantes.

**Tratamento justificado neste ponto:** preservar os textos e as linhas, explicitar a falta de pertencimento e de respostas e impedir que posição física, sexo ausente ou presença ausente sejam convertidos em vínculos e contagens conhecidos. Não há proposta comprovada para reconstruir essas três linhas integralmente. Sua conservação separada de uma base analítica aprovada não pode ser apresentada como desaparecimento das pessoas ou como população de peso zero.

## Outras correções de registros avaliadas

Também foram localizadas no parquet atual as correções que não passam pelo manifesto de texto:

- **Município pelo consenso da pasta:** fora das recodificações geográficas próprias de Guanabara, Alagoas e Fernando de Noronha, há dois domicílios afetados. HHOLDA 695175, SP, pasta 60158/distrito 11, preserva V116=7234, mas recebe code_muni_1960=6234. HHOLDA 887255, PR, pasta 71038/distrito 07, tem `724Z` no texto bruto e 7240 no resultado. Concordância das demais famílias da pasta é evidência contextual, não uma licença para corrigir municípios desconhecidos de qualquer futura entrada.
- **Pasta do Paraná:** a mudança da unidade primária de amostragem (UPA) 70382 para 70380 na linha 861570 tem evidência de conteúdo independente da regularidade do desenho. O cartão corresponde a PR 125571, pasta 70380/088; o verdadeiro 70382/088 é PR 126773, com outra composição. As pessoas candidatas são PR 125572/125573, e a diferença 00/63 permanece registrada. Acertar a pasta não basta para provar os vínculos pessoais.
- **Pasta da Guanabara:** HHOLDA 611254 tem pasta literal `541  `, distrito 18, e recebe UPA 54142. É uma inferência pelo contexto das pastas preservadas; não foi encontrada uma confirmação externa equivalente à do Paraná, pois não há fonte de 25% de Guanabara. A marca de inferência deve permanecer explícita. O dado literal não deve ser sobrescrito como se 54142 estivesse legível no cartão.

Esses itens foram avaliados e classificados; não se confundem com os 33 reparos de texto da seleção final.

A conferência direta dos gzip acrescentou um limite importante ao caso paulista: o cartão SP 1525598, pasta 60158/119, confirma município 6234 e distrito 11, mas tem **situação urbana**, enquanto HHOLDA 695175 e seu chefe 695176 declaram **rural**. Os cartões ainda divergem em instalação sanitária, televisão e quantidade de cômodos. Há uma pessoa diretamente ligada pela chave em HHOLDA, contra três na fonte25. O chefe coincide nos 25 campos pessoais com SP 1525599, mas isso não permite tratar o conjunto como se somente um dígito do município estivesse errado. A atribuição derivada de município tem apoio contextual; não é prova de que todas as informações geográficas e domiciliares foram resolvidas.

No caso paranaense, o cartão PR 708706, pasta 71038/216, confirma 7240, distrito 07 e situação rural, e todos os demais campos familiares coincidem. O grupo tem três pessoas nas duas fontes, mas há uma diferença V216=00/63 em um integrante. O alvo pessoal **887256** coincide nos 25 campos pessoais com PR 708707. Duas outras pessoas, 888718/888719, já trazem município 7240. Assim, a prova permite propor o município **derivado** 7240 para o cartão 887255 e a pessoa 887256, com a origem no cartão25, conservando `724Z` no registro da informação original. Essa prova está separada dos reparos comuns, para não usar o consenso da pasta como substituto da correspondência demonstrada.

### Implementação localizada da geografia paranaense

Foi preparado o manifesto versionado `read_guides/1960_amostra_127_geografia_fonte25.json`. O bloco geográfico do finalizador passou a conferir os hashes dos dois arquivos brutos, os oito textos localizados, a geografia e o pertencimento das três pessoas ao cartão. Só então deriva `code_muni_1960=7240` e acrescenta o diagnóstico `municipio_fonte25`. Nos dois registros danificados, a coluna numérica V116 continua ausente; o texto bruto `724Z` permanece na fonte e no manifesto. Isso distingue “sabemos o município por outra fonte” de “o arquivo original continha 7240”. A antiga regra por consenso da pasta permanece fora destes dois casos e não recebe uma certificação geral por causa desta prova.

A conferência encontrou também uma dependência anterior: a construção das famílias bloqueia vínculos diretos quando o município do cartão está ausente. Por isso foram entregues **três vínculos explícitos** ao cartão 887255, um para cada pessoa do grupo, em `inferencias04/vinculos_geografia_pr.csv`. Eles conservam as respostas e não enfraquecem essa guarda. Sua promoção compete à integração após conferência independente.

O teste `references/test_geografia_registros_1960.R` verifica o grupo real e entradas incompatíveis, origem divergente, repetição da execução e preservação dos dados. Uma segunda pasta fictícia está identificada apenas como controle do teste, para não exigir a execução de todo o desenho amostral. Nenhum dado desse controle é uma proposta histórica. A execução R é responsabilidade da integração pelo processo isolado; esta frente não executou R.

## Regras de inclusão: o que a publicação preliminar realmente esclarece

Foi usada a habilidade de leitura de PDF, com extração de texto e inspeção visual das páginas pertinentes. No volume preliminar de 1965, página III/PDF 7, os domicílios são particulares ocupados, excluindo os ocupados apenas por visitantes. Na página IV/PDF 8, o estado conjugal usa pessoas com 15 anos ou mais, e pessoas não economicamente ativas são classificadas pela atividade do chefe da família; o uso de residentes está especificado na página II/PDF 6. A seção de aluguel na página seguinte distingue condição de ocupação e faixas de aluguel. Essas definições já fundamentam a implementação da etapa 4; não demandam mudar as respostas pessoais.

A leitura integral das notas introdutórias e a busca no texto da publicação **não encontraram uma regra explícita de inclusão das idades ignoradas nos totais dos quadros 3–5**, ao contrário da convenção expressa encontrada nos resultados definitivos. Há categorias explícitas de idade ignorada nos quadros 1–2, o que não resolve sozinho 3–5. Portanto, não se pode declarar encerrada essa questão documental importando a instrução de outra publicação. Idade ignorada declarada e idade danificada continuam sendo situações diferentes.

## Como conferir a auditoria

Código:

- `references/auditoria_pendencias_texto_1960.py`: inventário completo, candidatos e literais. Cinco testes em `test_auditoria_pendencias_texto_1960.py` passaram; o piloto de três casosRS antecedeu a varredura integral.
- `references/conferir_reparos_texto_1960.py`: prova integral dos 47 candidatos; 11 testes em `test_conferir_reparos_texto_1960.py` passaram. Eles incluem irmãos de respostas iguais, multiplicidade, correspondência alternativa, campo obrigatório versus branco legítimo, recusa de substituir resposta legível e recusa de equiparar 00 a 63.
- `references/investigar_fragmentos_corrompidos_1960.py`: contextos e busca dos fragmentos; não produz registros reconstruídos.
- `references/conferir_inferencias_registros_1960.py`: oito nacionalidades restantes e as duas inferências municipais; produz quatro candidatos localizados e conserva as diferenças do contexto.
- `references/fechar_reparos_texto_1960.py`: passagem final homogênea dos 47 candidatos, com dependências conjuntas e conservação dos dígitos legíveis. Seis testes adicionais em `test_fechar_reparos_texto_1960.py` passaram; somados às outras duas suítes, são 22 testes Python nesta frente.

Resultados congelados desta frente em `tmp/fechamento_registros_1960_20260922/texto/`:

- `completo01/resumo.json`, `casos.json`, `suspeitas.json`, `contexto_corrompidas.json`;
- `provas03/provas_reparo.json`: 17 aprováveis e 30 retidos, com grupos e propostas exatas;
- `fragmentos01/fragmentos.json`: registros e hipóteses pesquisados, contagens e hashes.
- `inferencias03/inferencias.json` e `candidatos_nacionalidade_adicionais.json`: confronto dos oito casos e quatro propostas adicionais com releitura literal de todos os integrantes.
- `provas_contexto01/provas_reparo.json`: extensão aos outros campos, permitindo investigar separadamente as diferenças V216 do contexto. A marca automática de candidato não basta para aprovar 760804, pela ressalva de dano em outro integrante descrita acima.
- **`selecao_final02/selecao_final_reparos.json`: seleção final única dos 47 casos; 33 propostas de reparo e 14 resíduos.**
- `inferencias04/candidatos_geografia_pr.json`: duas propostas de geografia derivada, com prova individual e familiar; não substituem silenciosamente o texto V116.

Os scripts recusam sobrescrever a pasta de saída. Hashes das fontes lidas foram conferidos antes e depois; fontes brutas e parquets não foram modificados por esta frente. As seleções finais usam o inventário congelado e suas respostas anteriores, sem misturá-lo silenciosamente às correções que a integração possa ter promovido depois. Continuam exigindo a identidade das fontes brutas e dos guias usados. As rodadas iniciais ficam preservadas como histórico; **selecao_final02** é a decisão final homogênea, e o manifesto geográfico separado contém a prova dos dois registros do Paraná.

**Limite de encerramento:** uma resposta legível divergente entre cópias pode ser preservada com a divergência documentada. Uma resposta perdida pode continuar ausente, sem destruir a pessoa. Mas vínculos desconhecidos e a quantidade de pessoas representada por fragmentos misturados não se tornam conhecidos porque a investigação terminou. Os arquivos desta frente permitem distinguir esses três resultados em vez de anunciar que todo dano desapareceu.
