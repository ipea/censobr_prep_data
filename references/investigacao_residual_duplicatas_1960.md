# Repetições ainda pendentes: a busca fora das chaves mudou o diagnóstico

Esta é uma investigação nova, não uma nova rodada de exclusões. Nenhum registro, manifesto de produção ou peso foi modificado. O ponto de partida são os **463 conjuntos repetidos, com 928 linhas**, que continuaram sem decisão na rodada anterior.

## O achado principal: algumas famílias foram numeradas de maneira diferente nas duas cópias

Antes, a busca exigia encontrar a família sob o mesmo número de pasta e boletim. A pasta reúne questionários; o boletim é o número do registro familiar dentro dela. O cartão familiar contém as respostas sobre a família e o domicílio; as linhas seguintes contêm respostas pessoais. Isso falha quando a mesma composição familiar aparece em outra numeração. Não basta, entretanto, procurar uma criança de mesmo sexo e idade em outra casa: milhares de crianças podem compartilhar essas respostas. Nesta rodada procurei a **composição inteira**, incluindo adultos, crianças, quantidades e cartão familiar.

Exemplo concreto: no Rio Grande do Sul, o cartão **1009568** está na pasta **82894**, boletim **010**. Há dez pessoas ligadas a ele. Na fonte de 25%, a composição aparece no cartão **1277280**, pasta **82892**, boletim **190**. Os atributos do cartão, município, distrito e situação urbana/rural concordam. Três pessoas têm todos os 25 campos exatos e esses perfis aparecem uma única vez na UF de 1,27%. Duas outras pessoas diferem apenas no quesito sobre ano do casamento, 00/63, preservado sem alteração.

As linhas repetidas **1009572 e 1009575** encontram **duas ocorrências distintas**, 1277288 e 1277289, na fonte de 25%. Portanto, existe evidência nova para propor manter ambas. Isso não identifica civilmente cada criança, nem autoriza trocar os números originais da pasta e do boletim. É uma proposta documental a revisar antes de incorporar à lista de decisões.

O segundo candidato forte é **RS82974/221 → RS82976/100**: seis pessoas, cartão e geografia concordantes, duas testemunhas pessoais exatas e únicas na UF. As linhas **1014154 e 1014156** correspondem às duas ocorrências da fonte de 25%, **1331893 e 1331894**. Também aqui a proposta é manter as duas, não excluir uma. O balanço restritivo dessas duas propostas é: **dois conjuntos, quatro linhas a manter, nenhuma remoção e nenhuma restauração contra a exclusão histórica**. As quatro já não estavam na lista histórica de removidos; o que falta é documentar formalmente por que devem permanecer.

Esses deslocamentos não são fatos isolados. Nas pastas envolvidas foram examinados **1.702 cartões com pessoas ligadas**, pesquisando suas composições nas fontes de 25%. Surgiram 1.531 coincidências de composição por 24 campos, ainda sem homologação. Entre elas, os seguintes padrões também têm corpo do cartão e geografia exatos:

| Padrão entre as duas cópias | Famílias encontradas sob esse padrão |
|---|---:|
| CE15004 → CE14990, mesmo boletim |145|
| SP63788, boletim acrescido de17 |93|
| PE21604, boletim acrescido de38 |57|
| RS82974 → RS82976, boletim reduzido de121 |42|
| RS82894 → RS82892, boletim acrescido de180 |17|

Esses são números observados de coincidências sob critérios explícitos, não regras para renumerar toda a pasta. As assinaturas dessa exploração ignoram V216 e admitem que repetições ainda não decididas contenham de uma até todas as ocorrências127. Por isso a tabela não prova, sozinha, que toda correspondência esteja correta. Ela mostra que seria inadequado tratar todos os desacordos de chave como famílias diferentes ou como erros isolados de digitação.

O caso do Ceará ilustra a utilidade da composição: **131528/131530**, na família15004/034, encontram duas ocorrências em14990/034; os nove integrantes e o cartão conferem, salvo V21600/63 no chefe. Nenhuma pessoa exata é individualmente única na UF, portanto o candidato não passa a regra mais restritiva das duas testemunhas únicas. Mas a composição integral, a geografia e as145 famílias com o mesmo deslocamento são evidências adicionais que precisam ser apreciadas em conjunto. Não seriam descobertas por uma busca presa à chave antiga.

Esse resultado não significa que exista outra cópia da família inteira no Ceará. Uma busca adicional varreu **toda a UF**, inclusive fora das pastas selecionadas: o adulto131522 é único também pela assinatura de 24 campos, e nenhuma outra família completa compatível apareceu nos agrupamentos atuais ou físicos. O adulto não conta como testemunha exata entre as fontes porque seu ano de casamento difere. Os oito registros infantis coincidentes têm perfis individuais que se repetem de24 a305 vezes na UF. É a combinação familiar, e não a singularidade de cada criança, que fornece a evidência. Os números e os agrupamentos testados estão na [checagem de colisões familiares](investigacao_residual_1960_evidencias/duplicatas_colisoes_familias.json).

## Treze alternativas fora de chave não significam treze correções

A busca nacional leu **18.055.053 linhas das 17 fontes estaduais disponíveis**. Para todos os conjuntos legíveis, pesquisou as respostas sem exigir pasta, boletim, município ou UF iguais. Conservou integralmente as alternativas que conciliavam os 24 campos de todas as pessoas e suas quantidades. Foram 30 alternativas de composição integral: 17 na chave original e 13 fora dela. As 13 envolvem 12 contextos de 1,27%, pois um contexto tem duas alternativas. “Contexto” significa aqui todas as pessoas encontradas sob uma mesma chave, não uma família historicamente certificada.

O [caderno dos13 candidatos](investigacao_residual_1960_evidencias/duplicatas_fora_chave.json) contém todos os textos127 e25, linhas, comparações e razões contrárias. Seu balanço é:

| Alternativa fora de chave | Evidência favorável | Por que não aplicar automaticamente |
|---|---|---|
| CE15004/034 →14990/034 |9 pessoas; cartão/geografia; padrão145 famílias |Sem duas testemunhas individualmente únicas na UF; avaliar prova composta.|
| PE21604/118 →21604/156 |16 pessoas; cartão/geografia; duas testemunhas únicas; padrão+38 |Existe outro cartão127 sob156, que precisa ser explicado separadamente.|
| RJ52688/203 →52686/143 |Grupo e corpo do cartão concordam |Distrito05 na127 e03 na25.|
| SP63788/146 →63788/140 |Composição compatível se uma repetição for retirada |Cartão diverge; outra família127 tem essa composição. Não selecionar esta opção só porque sugere excluir.|
| SP63788/146 →63788/163 |Composição, cartão e geografia; duas ocorrências do perfil repetido |Sem duas testemunhas únicas; já existe cartão127 sob163. A vizinhança mostra esse cartão correspondendo ao boletim25 180.|
| SP63788/181 →63788/198 |Composição, cartão e geografia; duas testemunhas únicas |Existe cartão127 sob198; a vizinhança o relaciona a215, não ao grupo-alvo.|
| RS82192/031 →82192/039 |Composição, cartão e geografia; duas testemunhas únicas |Existe cartão127 sob039; a vizinhança o relaciona a250.|
| RS82894/010 →82892/190 |10 pessoas e todos os requisitos restritivos acima |Candidato forte para preservar as duas pessoas; ainda não aplicado.|
| RS82974/221 →82976/100 |6 pessoas e todos os requisitos restritivos acima |Candidato forte para preservar as duas pessoas; ainda não aplicado.|
| RS83078/143 →83080/143 |Composição e corpo do cartão concordam |Distrito03 na127 e05 na25.|
| RS83078/059 →83082/167 |12 pessoas exatas e corpo do cartão concordante |Distrito03 na127 e05 na25.|
| GB54182/006 → CE14820/048 |Até a composição pode coincidir |UF, município, distrito e cartão discordam; não identifica a família.|
| GB54182/046 → SP60864/158 |Composição compatível |UF e geografia discordam; não identifica a família.|

Os dois últimos casos são controles negativos reais. Igualdade de respostas não garante identidade, nem mesmo quando se considera um pequeno grupo inteiro com muitos códigos genéricos ou ignorados. A busca individual encontrou perfis em outra chave da própria UF para182 conjuntos e em outra UF para46. Essas contagens se sobrepõem: não são182 ou46 famílias identificadas.

## O que escondia o rótulo “outros integrantes divergentes”

Na rodada anterior, 182 conjuntos foram classificados assim. Eles pertencem a 157 contextos familiares. Agora os campos divergentes foram explicitados, pessoa a pessoa. Além da comparação literal, fiz um ensaio deliberadamente mais permissivo: cada pessoa poderia diferir em 00/63 no ano do casamento e em **no máximo um outro campo**. As pessoas precisavam ser emparelhadas uma a uma, sem usar a mesma pessoa da fonte de 25% para explicar dois integrantes da fonte de 1,27%. Somente cópias de perfis ainda pendentes poderiam ficar sem correspondente.

Esse ensaio não declara que as diferenças estejam certas ou erradas, tampouco autoriza corrigi-las. Ele pergunta: “Mesmo admitindo uma divergência adicional, o grupo inteiro fecha?” Dos182 conjuntos:

- **105** admitem esse emparelhamento hipotético integral;
- **53** não o admitem, mesmo relaxando a exigência;
- **24** pertencem a contextos nos quais há mais pessoas na fonte25 do que na127, exigindo outra explicação além de uma suposta cópia repetida.

Considerando todas as categorias residuais,117 dos400 contextos legíveis admitem esse ensaio;108 exigem efetivamente divergências adicionais. Eles abrangem169 conjuntos repetidos. As quantidades mínima e máxima de ocorrências de cada perfil repetido coincidiram sob essa hipótese específica. Isso significa estabilidade **dentro da hipótese**, não demonstração histórica da hipótese.

Nos emparelhamentos mínimos dos contextos ligados aos182 conjuntos, os campos adicionais mais frequentes são condição de atividade17 vezes, ocupação13, idade10, ramo de atividade9 e posição na ocupação8. Não contei o mesmo contexto novamente por conter vários conjuntos repetidos. Há padrões recorrentes, mas os significados dos códigos impedem tratá-los como equivalências:

| Divergência observada | Ocorrências no emparelhamento mínimo | Significado no guia transcrito |
|---|---:|---|
| V220: 4 → 5 |9|Afazeres domésticos versus estudante.|
| V220: 4 → 1 |5|Afazeres domésticos versus sem ocupação.|
| V221: 989 → 998 |5|Trabalhador braçal sem especificação versus outras ocupações/mal definidas.|
| V223B: 333 → 328 |4|Indústrias do vestuário versus indústrias têxteis.|
| V224: 0 → 6 |4|Membro de família/instituição versus empregado particular.|
| V224: 7 → 6 |4|Trabalhador por conta própria versus empregado particular.|
| V211: 1 → 3 |4|Sabe ler e não frequenta escola versus não sabe ler e não frequenta escola.|

Por exemplo, a pessoa **194957**, PE21438/041 na fonte de 1,27%, tem V220 = 4; o candidato **38053** da fonte de 25% tem V220 = 5, mantendo os outros campos pessoais. Seria incorreto apresentar a troca “afazeres domésticos → estudante” como simples limpeza de texto ou equivalência entre códigos. Também não seria correto escolher a resposta da fonte de 25% apenas por ser a amostra maior. Para demonstrar qual resposta histórica deve prevalecer seria necessário outro fundamento. O emparelhamento mínimo é um instrumento de investigação e pode conter alternativas; não recebe o nome de identidade comprovada.

Os significados acima estão na transcrição local [código do censo](../read_guides/1960_codigo_do_censo.csv), quesitosV211,V220,V221,V223B,V224. Não se consultaram PDFs nem se introduziu nova regra de recodificação nesta frente.

## Os15 conjuntos com divergência adicional no ano do casamento

São 15 conjuntos em **nove contextos**, não 15 famílias independentes. Em vários deles a divergência está em um pai ou cônjuge e afeta a aprovação das repetições de outros integrantes. A comparação por 24 campos não resolve qual das respostas de casamento é correta.

| Contexto127 | Diferença adicional emV216 encontrada |
|---|---|
| PE21278/099 |35 →63|
| PE21278/210 |45 →63|
| PE21362/009 |43 →63|
| BA31724/211 |13 →43|
| MG41556/184 |21 →63 em duas pessoas|
| MG42498/195 |46 →49|
| SP61240/150 |30 →63|
| SP66232/179 |35 →63|
| PR70038/260 |27 →63 em duas pessoas|

O código 63 significa ano ignorado. Assim, a tabela mistura perda de informação, como 35 → 63, com duas respostas substantivas incompatíveis, como 13 → 43. Não há uma transformação única que explique todos os casos. O cartão, os demais integrantes e as quantidades devem ser examinados separadamente; não se deve ampliar silenciosamente a antiga exceção 00/63 para “qualquer ano”.

## Outra pergunta que o inventário anterior não cobria: famílias inteiras repetidas

A investigação das famílias vizinhas também perguntou se duas famílias diferentes da fonte de 1,27% competiam pelo mesmo grupo na fonte de 25%. Entre as1.531 coincidências, houve um único caso amplo: os cartões paulistas773909 e773767 apontavam para o cartão25 3827227. Mas o primeiro exige reduzir quatro pessoas para três e diverge no cartão; o segundo tem três pessoas e cartão concordante. Quando se exigem simultaneamente cartão, geografia e quantidades exatos, não há colisão muitos-para-um nesse recorte. Isso não era uma busca nacional de todas as famílias repetidas.

Por essa razão, a frente integradora abriu uma busca nacional separada, sem usar pasta, boletim ou identificador interno como parte da assinatura. Fiz a segunda leitura independente dos achados do Amazonas e Maranhão. **Confirmou-se que o problema merece uma categoria própria**, porque não é igual ao de dois irmãos de respostas coincidentes dentro de uma família.

No Amazonas, duas composições sucessivas da pasta02104 reaparecem: uma com quatro pessoas nos boletins248 e250; outra com onze pessoas nos boletins249 e251. Os cartões e os dados pessoais são literalmente iguais depois de retirar apenas o boletim e o identificador interno. **As pessoas foram reordenadas**: não se trata de17 linhas copiadas na mesma sequência. Por exemplo,8445 corresponde a8463, enquanto8447 corresponde a8462. O grupo de onze pessoas também foi reordenado. Essa distinção impede atribuir, sem prova, uma história específica de copiar e colar ao arquivo.

Há forte evidência de repetição do conteúdo de dois grupos inteiros, muito diferente de dois perfis infantis comuns. Contudo, a fonte de25% do Amazonas não está disponível nesta cópia local. Não se excluiu um dos grupos nem se escolheu o menor boletim como “verdadeiro”. O que se demonstrou foi a repetição dos conteúdos e seus limites, não quantos boletins históricos deveriam sobreviver.

No Maranhão, os cartões69946/70362, pasta10820 e boletins155/236, possuem duas pessoas com os mesmos dados detalhados: casal de23 e19 anos, condições de presença1/2, respostas migratórias e casamento60 coincidentes; o homem tem ocupação323 e ramo113. Não são simplesmente dois registros com tudo ignorado. Ainda assim, a igualdade de um casal e de um cartão é evidência menos forte que a coincidência das duas composições amazonenses, e não determina exclusão por si só. Falta a fonte25 da UF para a mesma contraprova.

A [conferência independente de Amazonas e Maranhão](investigacao_residual_1960_evidencias/duplicatas_qc_blocos_am_ma.json) conserva20 pares posicionais, seus textos e as correspondências corretas sem exigir a mesma ordem. Ela também registra o que **não** coincide quando se tenta indevidamente comparar apenas pela posição física. O inventário nacional ampliado e as contraprovas de Minas Gerais/São Paulo pertencem ao relatório integrador; não devem ser somados mecanicamente aos463 conjuntos individuais.

## Cobertura, arquivos e limites

O [inventário caso a caso dos463 conjuntos](investigacao_residual_1960_evidencias/duplicatas_cobertura463.json) conserva a categoria anterior, todas as linhas127, as127 exclusões antigas ainda não comprovadas, contagens de ocorrências nacionais, alternativas completas e diferenças mínimas na chave. O [ensaio de um campo](investigacao_residual_1960_evidencias/duplicatas_hipotese_um_campo.json) guarda os emparelhamentos e intervalos hipotéticos; a [pesquisa das1.702 famílias vizinhas](investigacao_residual_1960_evidencias/duplicatas_vizinhancas1702.json) guarda cada par de cartões e as linhas pessoais.

Há176 conjuntos sem a fonte25 da própria UF. Eles não foram declarados resolvidos porque uma composição parecida apareceu em outra UF. O conjunto951432/951433 continua marcado como texto corrompido; a igualdade criada ao apagar campos ilegíveis não entrou como prova de identidade.

“Exaustivo” aqui tem limites verificáveis: todas as17 fontes locais, todas as chaves e todas as ocorrências compatíveis com a busca global24 foram examinadas. Todas as composições residuais na própria chave receberam diagnóstico de diferenças e ensaio integral de até um campo adicional. **Não** se realizou busca global de qualquer distância, de todas as divisões ou fusões possíveis de famílias, nem se obteve fonte ausente. A lista de exemplos de ocorrências individuais é limitada aos12 primeiros por grupo, mas seus totais e as alternativas de composição inteira não são truncados.

Foram aprovados oito testes Python, incluindo leitura de todos os307 registros pessoais de Fernando de Noronha para conferir a assinatura rápida contra o guia, preservação das quantidades, rejeição de falso emparelhamento que disputaria a mesma pessoa25 e confirmação de que o achado amazonense não é uma cópia ordenada. O pilotoRN examinou dois conjuntos antes da varredura nacional. O pilotoDF teve zero conjuntos e, por isso, **não** foi usado como validação suficiente.

Reprodução, com uma pasta de saída nova:

```powershell
python -m unittest discover -s references -p test_investigacao_residual_duplicatas_1960.py
python references/investigacao_residual_duplicatas_1960.py --uf 17 --out tmp/NOVO_PILOTO_DUP
python references/investigacao_residual_duplicatas_1960.py --out tmp/NOVA_BUSCA_DUP
python references/investigacao_residual_duplicatas_1960.py --deepen tmp/NOVA_BUSCA_DUP
python references/investigacao_residual_duplicatas_1960.py --neighborhood tmp/NOVA_BUSCA_DUP
python references/investigacao_residual_duplicatas_1960.py --relaxed tmp/NOVA_BUSCA_DUP
python references/investigacao_residual_duplicatas_1960.py --summarize tmp/NOVA_BUSCA_DUP
python references/investigacao_residual_duplicatas_1960.py --household-collisions tmp/NOVA_BUSCA_DUP
python references/investigacao_residual_duplicatas_1960.py --independent-blocks tmp/NOVA_BUSCA_DUP
```

O auditor reutiliza o índice de 1,27% somente para leitura. O ensaio de emparelhamento usa NumPy/SciPy já instalados, sem instalar pacotes. Os dados atuais e os pesos permanecem como antes; uma incorporação posterior deve passar por conferência independente e decisão explícita sobre os critérios ampliados.
