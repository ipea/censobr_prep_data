# Registros de 1960: o que a investigação adicional do texto encontrou

22/09/2026. Esta nota trata dos danos de texto, das respostas ainda ausentes e de três inferências geográficas. **Não aplica novas correções, não reconstrói a base e não muda pesos.** Ela complementa, e nos pontos explicitados corrige, o [fechamento anterior](fechamento_texto_registros_1960_20260922.md).

## O resultado principal

A busca mais ampla trouxe evidência que não estava clara no fechamento anterior. Há caminhos novos para identificar famílias com parte do número do questionário apagada; o caso paulista antes descrito como tendo apenas uma pessoa diretamente ligada tem, na verdade, suas três pessoas preservadas no arquivo; e algumas respostas ausentes têm correspondência muito mais forte quando examinamos o grupo inteiro.

Também apareceu uma omissão importante no inventário de texto: **dez registros chamados de “iguais à fonte25” só pareciam iguais depois que caracteres danificados eram transformados em ausência**. Essa conclusão não invalida as decisões já aprovadas: nenhum desses dez registros, nem seus cinco boletins, foi usado nos manifestos atuais de reparos, vínculos, cartões recuperados ou duplicatas. Mas eles precisam continuar visíveis como danos de texto, não como respostas conferidas.

O número de pendências não deve ser obtido somando as listas desta nota. Por exemplo, 760807 aparece entre os dez danos e no contexto do reparo ainda não aprovado de 760804. A pessoa 611254 tem problema de texto, de chave e de pertencimento familiar; continua sendo uma pessoa, não três ocorrências a acrescentar ao inventário.

## O que foi pesquisado desta vez

Foram revisitadas as **124 decisões textuais**, não apenas os 47 candidatos selecionados anteriormente. A busca percorreu os **18.055.053 registros das 17 fontes de 25% disponíveis** e todas as linhas de HHOLDA. Houve 90 buscas dos campos pessoais legíveis desses 124 casos, mais 81 buscas de integrantes que ajudam a conferir seus grupos; 92 perfis da fonte25 foram procurados de volta em HHOLDA. Os cartões familiares dos casos examinados foram comparados dentro dos seus grupos, não pesquisados globalmente apenas por características genéricas de moradia.

Na busca pessoal ampliada, o município e o número do questionário não foram usados para excluir candidatos logo de início. Isso permite encontrar uma pessoa cujo número do questionário esteja apagado ou errado. Depois, os candidatos precisam passar pela conferência do questionário, da geografia, do cartão e dos demais integrantes. **Uma coincidência de respostas não é automaticamente uma identificação.**

Foram conservados até os dígitos que sobreviveram dentro de um campo danificado. Em `0Z`, por exemplo, o zero ainda precisa ser zero no candidato. Um `9` depois de um sinal de salto não é apagado silenciosamente para obter uma coincidência. As contagens de candidatos são completas sob essas condições; os exemplos armazenados são limitados quando há milhares deles.

Um piloto na pequena fonte de Serra dos Aimorés antecedeu a busca integral. Os quatro testes iniciais passaram; a conferência final ampliada passou em sete testes. As fontes e os guias foram conferidos por assinatura digital antes e depois; nenhum deles foi modificado. Não foi executado R.

## 1. Dez igualdades aparentes escondiam dano

Imagine duas fichas para comparar. Na primeira, o campo contém um sinal de salto e, mais adiante, um `9` solto. Na segunda, aquele trecho está legitimamente em branco porque a pergunta não se aplicava. Se o programa transforma o trecho defeituoso da primeira ficha em `NA` — marca de informação ausente — e também lê o branco da segunda como `NA`, ambas acabam com a mesma aparência. **O programa não demonstrou que as duas fichas diziam a mesma coisa: apenas perdeu a distinção entre dano e pergunta não aplicável.**

Isso ocorreu no rótulo dado aos seguintes registros:

| Linhas de HHOLDA | Questionário paulista | O que ainda se vê no texto |
|---|---|---|
| 760807 | 61852/154 | Um `9` depois do hífen de salto |
| 760919, 760923, 760925 | 61852/172 | Um `9` perto do fim de cada trecho pessoal |
| 761056, 761057, 761058 | 61852/192 | Um `6` perto do fim de cada trecho pessoal |
| 806791 | 64810/118 | Um `9` depois do hífen de salto |
| 806800, 806801 | 64810/119 | Um `9` depois do hífen de salto |

O inventário antigo já guardava os textos e os códigos inválidos. A omissão foi classificá-los entre os 22 casos com candidato “igual nos campos comuns”, sem levar para a conclusão principal a distinção entre igualdade de respostas e igualdade produzida pela leitura como ausentes. A passagem dos 47 candidatos não abrangia esses dez, porque eles já tinham recebido o rótulo de igualdade.

**Como deveria ficar:** preservar o registro e o texto bruto; declarar quais campos não podem ser interpretados; não usar esses campos como testemunho de identidade. Uma eventual remoção dos caracteres excedentes precisa ser uma reparação localizada, justificada e registrada, não um efeito invisível da conversão para números.

A busca nos cinco manifestos vigentes encontrou **zero dependências** desses dez registros. Portanto, não há fundamento para desfazer os 33 reparos, os 30 cartões recuperados, os 251 vínculos ou as decisões de duplicatas por causa desse achado. Também não se conclui que os dez registros inteiros estejam errados: o dano é localizado, e as respostas legíveis continuam preservadas.

## 2. As quatro nacionalidades ausentes

O campo de nacionalidade é V208. O candidato da fonte25 contém `9`, brasileiro nato, nos quatro casos. O preenchimento geral a partir do lugar de nascimento continua injustificado. A novidade está na qualidade da correspondência individual e familiar, não numa regra do tipo “nasceu no Brasil, então preencher”.

### Pernambuco: 238423

A pessoa tem as outras respostas pessoais legíveis iguais às de PE 902375. A busca sem exigir chave encontrou **um único candidato em todas as 17 fontes**. O cartão 238422 e essa pessoa trazem distrito `X7`; os cinco outros integrantes do questionário 22366/154 trazem `07`, e a fonte25 também traz `07`.

Antes, isso aparecia como “conflito de distrito”. A formulação mais precisa é **distrito parcialmente ilegível no cartão e no chefe**, com indicação localizada de `07` em outra cópia e nos demais integrantes. Não é uma divergência entre dois distritos validamente declarados. As seis pessoas se correspondem; uma filha tem a diferença já conhecida entre os códigos 00 e 63 do ano de casamento, que deve ser preservada, não convertida em igualdade.

O caminho possível é uma prova conjunta da geografia derivada e do vínculo, seguida da reparação localizada da nacionalidade. Ela não é idêntica ao critério já aplicado no Paraná: aqui não há duas outras pessoas com perfis completos únicos nas duas bases, pois os demais integrantes têm respostas comuns a muitas crianças. A singularidade global do próprio alvo em seus campos legíveis é uma evidência diferente, que precisa ser explicitada.

### Serra dos Aimorés: 540394, 540399 e 540461

Nos questionários 50048/043 e 50048/051, os cartões e as quantidades de pessoas concordam. Em cada grupo há **três outros integrantes cujas respostas completas aparecem uma única vez na amostra de 1,27% e uma única vez em todas as fontes25 pesquisadas**. Esses integrantes fornecem apoio independente à identificação do grupo.

As divergências que impediram o reparo anterior pertencem a outras pessoas: em 540397, a última série e o grau do curso diferem da fonte25; em 540458, difere a atividade não econômica. Isso é diferente de uma nacionalidade desconhecida. É possível que duas cópias do mesmo questionário tenham respostas diferentes em alguns campos, sem que deixem de representar o mesmo grupo.

Por outro lado, as respostas pessoais isoladas não identificam todos os alvos de modo único: 540394 tem dois candidatos nas 17 fontes, um em Serra dos Aimorés e outro em Minas; 540399 tem quatro, dois em Serra dos Aimorés e dois no Rio de Janeiro. O número correto do questionário e a composição familiar são, portanto, partes indispensáveis da prova. 540461 tem um único candidato na busca nacional.

**Proposta de avaliação:** estes três reparos merecem uma decisão localizada baseada na identificação do grupo, conservando as respostas escolares e de atividade divergentes. Não estão aprovados pelo critério antigo, que só admitia a diferença 00/63 no contexto. Ampliar esse critério deve ser uma decisão explícita, não uma mudança silenciosa do que “igual” significa.

## 3. Família paulista 695175: as três pessoas estão preservadas

O cartão 695175, questionário 60158/119, declara município 7234 e situação rural. A fonte25 declara município 6234 e situação urbana. A nota anterior enfatizava que só o chefe 695176 estava diretamente ligado ao cartão e dizia que havia uma pessoa contra três na fonte25. **Isso não significa que as outras duas pessoas estejam ausentes de HHOLDA.**

| Pessoa na fonte25 de SP | Pessoa preservada em HHOLDA | Resultado das respostas pessoais |
|---:|---:|---|
| 1525599 | 695176 | Todos os 25 campos iguais |
| 1525600 | 661580 | Todos os 25 campos iguais |
| 1525601 | 661581 | Todos os 25 campos iguais |

As duas últimas pessoas estão mais de 33 mil linhas antes do cartão e trazem o mesmo número de questionário, município 6234 e situação urbana. Os três perfis da fonte25 têm, cada um, uma única ocorrência exata em toda HHOLDA. A frente de vínculos também confirmou a composição completa e a regularidade das três ordens na fonte25. Na busca inversa entre as fontes25, o perfil de 661581 aparece duas vezes; isso não desfaz a correspondência do grupo, mas impede dizer que todo integrante é individualmente único nas duas fontes.

O problema restante é, portanto, **identidade familiar bem sustentada, com respostas geográficas e domiciliares divergentes**, não duas pessoas perdidas. O município derivado 6234 ganha apoio direto da fonte e das três pessoas. A situação urbana/rural ainda não pode ser resolvida por votação entre os registros: o cartão e o chefe dizem rural, os outros dois integrantes e a outra cópia dizem urbano. As diferenças de instalação sanitária, televisão e número de cômodos também devem continuar explícitas.

## 4. Três números de questionário parcialmente apagados

Em 142402 e 259248, a busca anterior não encontrava candidatos pela chave porque a chave continha espaços. A nova busca pessoal encontrou 6.049 candidatos para a primeira pessoa e 101 para a segunda. Isso mostra por que idade, sexo e outras respostas comuns não bastam para ligar alguém a uma família.

A frente de vínculos examinou os caracteres legíveis do número do questionário e encontrou, em cada caso, um único cartão127 compatível: 142817, pasta 15290/067, para 142402; e 259657, pasta 22934/069, para 259248. A busca global desta frente confirma uma ocorrência compatível na fonte25 em cada uma dessas chaves. A prova da composição completa pertence ao caderno de vínculos; aqui fica documentado que “sem candidato pela chave danificada” não equivalia a “sem candidato em outra fonte”.

Na Guanabara, **611254 é uma pessoa, não um cartão familiar**. O texto conserva pasta `541  `, boletim `101` e distrito `18`. O cartão imediatamente anterior, 611250, pertence ao boletim **290** e não identifica essa pessoa. Procurar apenas perto dela perpetuaria uma associação inadequada.

Em toda Guanabara, há três cartões com pasta começando por 541 e boletim 101. Só **616230, pasta 54142/101**, tem distrito 18; os outros têm distritos 41 e 26. A pessoa danificada está codificada como cônjuge de 31 anos. O chefe 616231 também tem 31 anos; ambos registram casamento no ano 55 e dois filhos tidos e vivos. Duas crianças já estão ligadas ao cartão. Esse contexto favorece o candidato, mas não é uma identificação civil e não há fonte25 de Guanabara disponível para confirmação equivalente à paulista.

Assim, a inferência de pasta 54142 não deve ser justificada pela mera posição da linha. Seu fundamento potencial é a chave parcialmente preservada e o único cartão compatível, acompanhado das respostas familiares. O texto literal `541  ` e a condição de inferência devem continuar visíveis.

## 5. Os demais 14 resíduos da seleção anterior, sem selecionar só exemplos favoráveis

O quadro conserva os 14 identificadores para permitir confronto direto com a rodada anterior. O cartão 887255 já recebeu uma decisão geográfica separada naquela rodada: não constitui um décimo quarto reparo ainda aberto a somar aos demais.

| Linha-alvo | O que impede encerrar pelo critério vigente | O que a nova busca acrescentou |
|---:|---|---|
| 162537 | Campo de cor contém `3`, fora do dicionário; a composição não coincide | Preservar o dígito `3` não dá candidato. Há duas meninas de cinco anos no lado127 e, na25, só uma menina correspondente e um menino de nove anos. Não trocar sexo e idade para forçar a composição. |
| 238423 | Distrito parcialmente danificado e nacionalidade ausente | Candidato pessoal único nas 17 fontes; avaliar geografia e reparo conjuntamente, como explicado acima. |
| 405458 | Falta o cartão familiar em HHOLDA; relação com chefe e parte da idade estão ausentes | MG 567047 é o único candidato nacional pelos campos legíveis, com relação 7 e idade 79, conservando o 9 da idade ` 9`. O grupo tem três pessoas nas duas fontes. Reparação e recuperação de cartão teriam de ser provadas juntas, sem raciocínio circular. |
| 540394, 540399 | Respostas escolares de outro integrante divergem | Três testemunhos pessoais completos únicos nas duas fontes para o grupo; conservar a divergência escolar. |
| 540461 | Atividade de outro integrante diverge | Três testemunhos pessoais completos únicos; conservar a divergência de atividade. |
| 760804 | Outro integrante, 760807, está danificado | A resposta `0Z` tem 788 candidatos pessoais compatíveis em SP quando a chave é ignorada. O grupo é indispensável. O 9 sobrevivente de 760807 não tem candidato que o preserve; não apagá-lo implicitamente para aprovar 760804. |
| 806984 | Há dano em 806986, outro integrante | O alvo tem candidato único nacional, SP 430096, rendimento 8. Mas 806986 conserva um 9 no campo de rendimento depois de salto, enquanto a fonte25 tem branco; isso é divergência, não igualdade. |
| 830335 | Há seis pessoas em HHOLDA contra oito na fonte25 | O perfil da pessoa25 faltante 927349 não foi encontrado integralmente em HHOLDA; o perfil 927352 ocorre 35 vezes, sem pessoa na chave 65548/119. Não escolher uma criança de outra família só pelas respostas comuns. |
| 887255 | Município literal `724Z` | A decisão geográfica PR 7240 já foi tratada separadamente; não reabrir como se a outra nota não existisse. |
| 951430 | Cartão fragmentado e três pessoas preservadas contra sete na fonte25 | Dos quatro perfis faltantes, dois não aparecem inteiros em HHOLDA e dois são comuns a 15 e 722 pessoas, respectivamente. Isso não completa a família. |
| 951431 | Pessoa parcial de outro boletim, sem cartão familiar em HHOLDA | Seis candidatos pessoais no RS; só um na chave 81076/016. As outras duas pessoas desse boletim não têm perfil completo encontrado em HHOLDA. Não confundir os boletins 016 e 017. |
| 962975 | Divergência no número de filhos de outro integrante | No chefe 962976, filhos tidos e vivos são 2/2 em HHOLDA e 3/3 na fonte25. Não usar a própria moradia a reparar para apagar essa diferença. |
| 1070216 | Rendimento do chefe diverge | 1070217 tem código 5 contra 4 na fonte25, além das diferenças 00/63 em filhos. O campo doméstico ausente continua sem aprovação pelo critério vigente. |

“Não encontrado” nesse quadro significa perfil integral sob as respostas preservadas, em todas as linhas127, e não inexistência da pessoa histórica. Diferenças de resposta, fragmentação ou perda de uma fonte podem impedir esse encontro.

O caso mineiro 405458 foi aprofundado conjuntamente com a frente de vínculos. Uma simulação, sem alterar o registro, de relação com chefe 7 e idade 79 faz as três pessoas coincidirem integralmente com a fonte25. Mas a recuperação do cartão não foi aprovada: foram examinados 289 cartões alternativos e não se conseguiu excluir completamente dois, 405480 e 405486, dos boletins 005 e 006. Seus próprios grupos ainda têm diferenças de respostas e não fornecem as duas testemunhas integrais únicas exigidas pela prova atual. A [evidência de recuperação](investigacao_residual_1960_evidencias/vinculos_recuperacao.json) conserva separadamente o texto vigente, a proposta simulada e as alternativas. Isso fecha a investigação dessa hipótese sob o critério declarado, não a incerteza histórica.

## 6. Fragmentos: a busca aproximada trouxe pistas, não pessoas reconstruídas

Para 855822, a busca anterior exigia a coincidência de uma possível cauda de 35 dígitos. Esta rodada procurou também trechos contíguos de 16 ou mais caracteres, sem fixar sua posição no corpo pessoal. Foram testadas separadamente a remoção dos espaços do primeiro fragmento, o prefixo de 951430 e, como hipótese mais fraca, a extração apenas dos dígitos de 951433.

O fragmento 855822 tem **três coincidências de 34 dos 35 dígitos**, todas em SP: linhas25 219679, 645158 e 3864497. Elas diferem justamente no primeiro código, que poderia representar a relação com o chefe. A parte curta posterior da linha parece começar por SP/município 6433/distrito 01/pasta 644, mas os cartões desses três candidatos têm municípios 6422, 6549 e 6302. Nenhum cartão25 de SP corresponde simultaneamente a município 6433, distrito 01 e pasta começando por 644.

Isso impede apresentar qualquer um dos três como reconstrução comprovada. Também impede somar o primeiro e o segundo fragmento como se certamente fossem uma pessoa: eles podem vir de registros diferentes. Pedaços longos de respostas muito padronizadas coincidem em muitas pessoas; uma sequência com muitos zeros não é uma impressão digital individual.

O fragmento 951433 não teve uma coincidência contígua informativa de 16 caracteres nessa busca. A linha 951432 conserva praticamente apenas a UF e o tipo de registro, insuficientes para localizar uma pessoa. Os indícios anteriores sobre a cauda que pode pertencer à pessoa RS 252041 e o começo do cartão 81076/017 continuam pistas de mistura de registros, não uma contagem comprovada de quantas pessoas se perderam.

## Como auditar e o que esta investigação não encerra

O [caderno principal](investigacao_residual_texto_1960_evidencias.json) contém as 124 linhas originais e atuais, o melhor candidato anterior quando havia um, a classificação da busca nova, todos os 14 resíduos com seus grupos literais, os dez casos de igualdade artificial, testemunhos e contagens das consultas globais. O [complemento](investigacao_residual_texto_1960_complementos.json) demonstra o cruzamento sem dependências nos manifestos e registra os cartões que contradizem a fusão dos fragmentos de 855822.

Os resultados completos, incluindo as contagens por chave que seriam extensas no caderno, estão em `tmp/investigacao_residual_1960_20260922/texto/completa01/investigacao_texto.json`, com assinatura no caderno portátil. Para repetir:

```powershell
python -m unittest discover -s references -p test_investigacao_residual_texto_1960.py
python references/investigacao_residual_texto_1960.py --uf sa --out tmp/novo_piloto_texto
python references/investigacao_residual_texto_1960.py --out tmp/nova_busca_texto
python references/consolidar_investigacao_residual_texto_1960.py --entrada tmp/nova_busca_texto/investigacao_texto.json --out tmp/novo_caderno_texto.json
```

Os caminhos de saída precisam ser novos. A consolidação usa também os grupos congelados da rodada precedente, cuja origem está registrada; o JSON portátil permite auditar as conclusões sem depender apenas de uma sessão temporária.

Não foram testadas todas as substituições concebíveis de letras, dígitos e posições: isso geraria candidatos arbitrários e não equivaleria a prova. Não há confirmação pela fonte25 para as UFs cujo arquivo não está disponível. Uma pessoa pode permanecer com uma resposta ausente, mas deve ser distinguida de uma pessoa de família desconhecida ou de um fragmento cujo conteúdo e quantidade de pessoas representadas nem sequer são demonstráveis. **Exaustividade de uma busca definida não transforma esses limites históricos em certeza.**
