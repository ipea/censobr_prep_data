# Segunda revisão: amostra de 1,27% de 1960

> **Parecer consolidado posterior:** a [revisão integrativa](microdata_1960_amostra_127_revisao_integrativa.md) concilia as três rodadas e prevalece nos pontos conflitantes. Corrige, entre outros, a afirmação abaixo de que todos os particulares têm residente conhecido: há um domicílio sem lista de pessoas. Acrescenta erros na calibração/validação25, omissões do compilado, reparo no RS e lacunas de exportação; não houve nova execução R ou alteração de produção.

**Data:** 2026-09-21. **Resultado:** revisão concluída; integridade e validação **não aprovadas para reprocessamento/publicação**. Há achados novos e conclusões da primeira revisão que precisam ser corrigidas.

Esta rodada não executou R, Rscript ou targets, não refez pesos/variâncias e não alterou parquets, guias de correção ou código de produção. Foram criados este parecer, o plano da revisão e verificadores/extrações isolados em `tmp/doublecheck127/` e `tmp/pdfs/`. As alterações anteriores, inclusive as do usuário, foram preservadas.

Este parecer prevalece sobre as conclusões incompatíveis das notas de auditoria anteriores, especialmente sobre idade ignorada, cor, origem das referências domiciliares e abrangência dos bloqueios. Os números dos relatórios anteriores descrevem as regras então implementadas; não constituem validação semântica definitiva.

## 1. Parecer e prioridades

O problema não se limita às 1.008 pessoas anexadas ao registro anterior ou às duplicatas. A reconstrução automática de famílias com chefe/cônjuge também produz vínculos discutíveis e chega ao compilado. Além disso, a validação reformulada reproduziu erros de interpretação em R e Python: concordância entre as duas implementações não os detectou.

| Prioridade | Achado | Evidência/alcance |
|---|---|---|
| P1 | Famílias criadas como `registro_perdido` sem provar perda do cartão | 150 grupos/485 pessoas; 141 têm cartão na mesma UF+pasta+boletim. Um caso completo foi confirmado no gzip. |
| P1 | Vínculos e exclusões já questionados continuam nos dados gravados | Reproduzidos 1.008 anexados, 70 conflitos e 31 restaurações sugeridas por multiplicidade; bloqueios não reparam o existente. |
| P1 | A nova validação exclui idade ignorada de uma tabela que a inclui expressamente | Tabela 40: 1.208 presentes, peso final 93.901,37. É uma regressão da primeira reformulação. |
| P2 | Harmonizações incorretas de cor, água e atividade | V206=8 deve integrar pardos na publicação; V105=4 é ignorado; ramo ausente não implica inatividade. |
| P2 | Universo domiciliar e origem da referência insuficientemente especificados | Tabela 7 é de particulares permanentes; quesitos domiciliares são da amostra também nas onze UFs. |
| P2 | Proteções e testes não cobrem todo o caminho | Duplicatas do gabarito são somadas antes da guarda; não há rejeição final de não convergência; testes R não executados. |
| P2 | Metadados/contagens ainda contradizem o tratamento anunciado | Presença desconhecida entra nas contagens domiciliares; Fernando de Noronha exporta base 78,74 embora o ajuste use 4. |
| P2 | Parte da evidência do desenho estava calculada incorretamente ou desatualizada | Corridas misturavam grupos; Alagoas alterava ranks. A hipótese UF×situação segue sustentada, não demonstrada. |

P1 significa impedir aceitação do tratamento atual sem reconciliação; P2 significa corrigir a interpretação/proteção antes de declarar a etapa validada. Não há recomendação de fundir famílias ou restaurar linhas em lote apenas com base nesta tabela.

## 2. Integridade: o que faltava avaliar

### 2.1 Famílias “perdidas” que já têm cartão

`R/microdata_1960_amostra_127.R:578–589` cria uma família quando encontra pessoas sem vínculo com chefe/cônjuge. A guarda acrescentada na primeira revisão só atua depois, nos órfãos remanescentes, na linha 597. O auditor anterior seleciona `anexada_anterior`, deixando `registro_perdido` fora do confronto.

Inventário completo dos 150 grupos/485 pessoas:

- 141 têm exatamente um cartão real em HHOLDA na mesma UF+pasta+boletim, mas com divergência no distrito da chave; nove não têm esse candidato.
- Nas UFs com 25%, são 91 grupos/306 pessoas; 83 têm candidato já existente em HHOLDA.
- Em 52 desses 83 grupos, todas as 131 pessoas têm perfis exatos nos 25 campos pessoais comparados. Incluindo correspondências parciais nos demais grupos, são 211 pessoas exatas nesses 83 grupos.
- Em 65 dos 83 candidatos, os 15 campos familiares comparáveis também coincidem. As diferenças restantes impedem transformar a contagem de candidatos em autorização automática de fusão.

**Caso confirmado no bruto:** BA, pasta 31962, boletim 118. As seis pessoas HHOLDA315134–315139, distrito 03, ganharam a família 174495/domicílio 49314, sem V101. Entretanto, o cartão HHOLDA315732, distrito 05, já existe. Seus 15 campos coincidem com o cartão do gzip de 25%, linha 645852, que declara sete pessoas. As seis pessoas reconstruídas coincidem integralmente com as outras seis pessoas desse boletim. A presença de cônjuge sem vínculo não demonstra perda do cartão familiar.

**Impacto no compilado:** nas onze UFs cuja contribuição vem da amostra de 1,27%, sobrevivem 59 famílias/179 pessoas dessa categoria. Destas, 58 famílias repetem UF+pasta+boletim de cartão real: Guanabara 36, Santa Catarina 11, Espírito Santo 9 e Pará 2. Essas 58 chaves repetidas foram verificadas no parquet compilado. O compilador reconhece a repetição e atribui novos identificadores (`R/microdata_1960.R:175–177`), mas isso não resolve o pertencimento familiar.

As 179 pessoas têm V101 ausente e recebem `censobr_tipo_unidade="domicilio particular"` pelo `default` do compilador, linhas 213–215. É outra inferência não validada. Sem a fonte de 25% nessas UFs, **não se conclui que os 58 pares devam todos ser fundidos**.

### 2.2 Paraná: a UPA foi corrigida, mas a família continua partida

A mudança 71-70382→71-70380 não precisa mais se apoiar apenas na regularidade de uma pasta em vinte. O conteúdo do gzip fornece evidência independente daquela hipótese de desenho:

- O cartão HHOLDA861570, gravado 70382/088, coincide nos 15 campos familiares com PR125571, pasta 70380/088, V101=1, duas pessoas.
- O chefe HHOLDA861571 corresponde a PR125572; o filho HHOLDA860877 corresponde a PR125573. Em ambos, há a diferença V216=00/63 já identificada entre fontes.
- O verdadeiro 70382/088 do gzip é outro boletim: PR126773, V101=9, uma mulher de 70 anos, PR126774.

O filho continua `anexada_anterior`, família 140428/domicílio 140251; o chefe está na família 140552/domicílio 140376. A UPA é 70380 para ambos. **Acertar a pasta do desenho não acertou o vínculo familiar.** Referência do reparo atual: `R/microdata_1960_amostra_127.R:790–801`.

### 2.3 Famílias conviventes: geografia e sequência passam, correspondência ainda não

Foram inventariados todos os 373 cartões conviventes: 345 transições 2→4, 27 transições 4→5 e uma 1→5. Não há conflito de UF/município/distrito/pasta, e os boletins são consecutivos. Portanto, não se confirmou uma falha geográfica materializada nesse conjunto.

Entretanto, entre 269 casos nas UFs com 25%, 259 têm ambos os cartões candidatos no arquivo maior. Em 37 pares, V101 difere em pelo menos um cartão; 24 pares são 1→1 no 25%, apesar de 2→4 em HHOLDA. A guarda das linhas 606–616 não avalia essa questão.

Isso **não prova 37 vínculos errados**. No caso BA32068/099–100 relido no gzip, o boletim 099 corresponde quase integralmente, mas as pessoas do 100 diferem entre fontes. É preciso examinar mudança de numeração, codificação e identidade do conjunto; a chave isolada não basta. Outros 104 conviventes não têm a fonte 25%. O teste de sucessão do boletim e da ordem das famílias tampouco está codificado na guarda, embora o inventário atual tenha passado no primeiro critério.

### 2.4 Vínculos e duplicatas: confirmações e limites

A reexecução do auditor anterior reproduziu 1.008 pessoas anexadas, 70 conflitos, 2.850 exclusões, 2.238 exclusões com multiplicidade concordante e 31 restaurações sugeridas em 28 perfis. Todas as 2.850 linhas excluídas têm cópia anterior idêntica nos 54 caracteres corrigidos dentro do mesmo `id_arquivo`; nenhuma dessas linhas está no parquet atual. A igualdade textual, sozinha, continua não provando duplicação de uma pessoa.

Foram percorridos os gzip de PB, PE, BA, MG e PR, selecionando 15 boletins. Nos registros selecionados, não houve divergência entre bruto e intermediário nos campos disponíveis, inclusive ordem/linha. Reconfirmados:

- PB19124/166: sete pessoas, incluindo duas ocorrências de cada um dos perfis de filhos com idade ignorada.
- PE21438/069: duas pessoas do perfil repetido; manter apenas uma é excessivo, restaurar todas as cópias também seria.
- MG40090: oito cartões próprios, V101=3 e duas pessoas por cartão; quinze perfis exatos e a divergência conhecida da pessoa 491763.
- Reparos BA387715/387853: persistem as evidências de alinhamento V218/V219 e a diferença residual V216 da primeira pessoa.

O confronto usa 25 campos pessoais, não distrito, V116, V118, tipo do registro nem página domiciliar. Há ausências em 2.150 das 2.238 ocorrências corroboradas, em grande parte saltos estruturais. O confronto por multiplicidade sustenta uma revisão das exclusões; não identifica civilmente pessoas. Não foram relidos no gzip todos os 28 perfis ou todas as 2.238 exclusões.

As 31 restaurações sugeridas pertencem às 17 UFs para as quais o compilado usa 25%. **Não são 31 pessoas demonstradamente ausentes do compilado.** Já as 179 pessoas de famílias reconstruídas descritas acima efetivamente chegam a ele. As duas fontes compartilham origem; não são levantamentos estatisticamente independentes.

## 3. Validação: correções à própria primeira revisão

### 3.1 Idade declarada ignorada: o volume nacional resolve a regra

O [volume nacional](fontes_1960/1960_serie_nacional_vol1_brasil.pdf), página física 12 do PDF, impressa XIII, determina a inclusão da idade ignorada no total quando a informação tem um limite mínimo de idade. Não é necessário supor idade biológica ou imputá-la: é a convenção da tabulação histórica.

A nova validação da tabela 40 exige `idade >= 5` nas linhas 1335–1336 e deixa V204=9 fora. Isso contraria a fonte. Nos parquets atuais, exclui:

| Conjunto de presentes com V204=9 | Registros | Soma do peso final |
|---|---:|---:|
| Todos | 1.208 | 93.901,37 |
| Sabem ler/escrever | 520 | 40.720,84 |
| Não sabem ler/escrever | 503 | 38.201,70 |

Essas contagens não incluem os 11 registros de idade não classificável: **dano/NA não deve virar automaticamente idade declarada ignorada**. A inclusão de V204=9 pelo calibrador era compatível com a publicação; sua equiparação adicional com idade danificada continua sendo outra questão.

Os quadros 3/4 preliminares também precisam rever o recorte. Seus totais publicados coincidem com o total 10+ do quadro 2 — no Brasil, 48.761.467 — enquanto a nova implementação inclui ignorada no Q2 e a exclui no Q3/Q4. A exclusão não deve ser apresentada como convenção histórica já comprovada. Para Q5, é preciso fechar a correspondência do universo residente 15+, além de reconstruir a atividade da qual a pessoa depende. A prova textual explícita aqui citada é a do volume definitivo; não se pressupõe identidade de todas as rotinas entre publicações.

### 3.2 Cor: V206=8 tem correspondência publicada

Na mesma página XIII, o IBGE informa que as declarações referentes a indígenas integram pardos na publicação. O código original 8 deve ser preservado no microdado, mas **a variável de comparação da tabela 37 deve agregá-lo a pardos**. A primeira revisão deixou essa correspondência pendente e o código R:1316 atribui `india`, que não encontra coluna própria no gabarito.

São 198 registros no arquivo inteiro, mas **192 presentes** no universo da tabela 37, peso final 16.044,34. Não se devem usar os 198/16.501,16 como impacto dessa tabela. A exclusão indevida pode criar falsas células sem observações, além de reduzir totais de pardos.

### 3.3 Água e atividade: R e Python concordam no erro

**Água.** R:1246 e Python: 127 incluem V105=3 ou NA em `agua_outra_sem_declaracao`, mas deixam de fora V105=4, que é explicitamente “Ignorado” no código do censo transcrito (`read_guides/1960_codigo_do_censo.csv:701`).

Nos particulares, 101 domicílios V105=4, peso 8.129,03, desaparecem dessa categoria. Em sentido contrário, entram como água ignorada 49 improvisados cujo quesito não é codificado, peso 3.844,48, e uma família secundária de tipo desconhecido, peso 75,43. Outros três NA são duráveis e requerem diagnóstico próprio. Saltos estruturais e desconhecimento não são a mesma resposta.

Em teste Python com o domicílio real da linha 303650, V105=4, a célula resultou em 0, n=0 e `sem_observacoes`, embora exista resposta ignorada codificada. Portanto, o novo status não garante por si só que um zero reflita ausência amostral: pode refletir classificação incorreta.

**Atividade.** R:1220/1224 e Python: 115/117 inferem inatividade de V223B ausente. As pessoas 388894, 761035 e 830192 têm V220=3, V223=2 e ocupações V221=863/547/323, porém ramo V223B ausente. As duas implementações as classificam como inativas em Q3/Q4; peso conjunto 260,46. Outros três elegíveis, com V220 desconhecido, também recebem inatividade por exclusão, peso 226,44. Ramo perdido não prova inatividade; a classificação precisa consultar atividade econômica e distinguir ramo desconhecido.

### 3.4 Universo domiciliar

O título da tabela domiciliar 7 é **particulares permanentes**, conferido na página física 169 do PDF nacional, impressa 132. A definição na página física 19, impressa XX, separa construções residenciais permanentes das improvisadas. A validação R:1338 seleciona apenas V101, não V102.

Há 49 improvisados particulares indevidamente incluídos: peso domiciliar 3.844,48 e 77 residentes, peso 6.069,98. Nove tipos ignorados e uma família secundária sem tipo precisam de tratamento explícito, não de presunção de permanência. Durável e rústico não devem ser confundidos com a dicotomia permanente/improvisado.

Nos [preliminares de 1965](fontes_1960/1965_resultados_preliminares_vol2.pdf), página física 7, impressa III, os quadros domiciliares excluem os ocupados apenas por não moradores presentes. R:1241–1244 mantém esses domicílios e preenche seus residentes com zero. **Impacto atual: nenhum caso**; todos os particulares selecionados possuem ao menos um residente conhecido. É falha da regra e dos testes, não uma alteração demonstrada no total atual.

### 3.5 Referência estimada depende da tabela, não só da UF

O volume nacional, páginas físicas 8–9, impressas IX–X, informa que os quesitos dos domicílios pertencem ao Boletim de Amostra CD2, não ao Boletim Geral. Logo, a classificação “universo” aplicável a determinados quesitos pessoais nas onze UFs **não pode ser estendida à tabela domiciliar 7**.

O transcritor `references/transcricao_1960_serie_nacional.py:287` atribui a fonte apenas pela UF; R:1348 repete isso em `referencia_estimada`. A revisão precisa corrigir tanto a proveniência transcrita quanto o indicador de validação, considerando tabela×UF. A tabela domiciliar 7 tem base amostral também nas onze UFs. Esta é uma lacuna adicional à incerteza dos controles pessoais das 17 UFs reconhecida anteriormente.

Isso não impede usar os definitivos como referências disponíveis. Impede tratá-los indiscriminadamente como censos completos ou como observações sem erro amostral. Também não implica que todos esses totais domiciliares sejam restrições do calibrador: atualmente não são.

### 3.6 O que fazer com células vazias

A decisão de preservar a grade oficial permanece correta. O relatório deve separar:

1. **Sem observações classificadas numa célula reconstruída:** estimativa direta 0 e n=0, com aviso de falta de suporte. Se o oficial é positivo, a diferença é mostrada; isso não demonstra população verdadeira zero. Não se conserta aumentando o peso de uma observação inexistente.
2. **Quesito não reconstruído:** NA, nunca 0. Continuam pendentes 288 cruzamentos de Q5 e 168 faixas/medidas de aluguel de Q6, por peso. `nao_reconstruida` significa não implementada, não impossibilidade histórica: V104 existe e Q5 tem regra documental de atividade do chefe para dependentes.
3. **Classificação/universo incompleto:** informar separadamente quantidade e massa ponderada não classificadas e marcar a comparação afetada. Zero de registros classificados não deve ser anunciado como ausência demonstrada de observações elegíveis.
4. **Peso inválido:** preservar NA e a contagem de pesos inválidos através das agregações.

Não recomendo inventar pessoas, transferir observações de outra geografia ou fundir categorias após olhar o erro apenas para obter fechamento. Se uma restrição tiver alvo positivo e coluna amostral nula, o ajuste deve falhar; eventual agregação tem de ter justificativa e regra documentadas. Rondônia e DF sem rural continuam exemplos reais de falta de suporte.

As 63 omissões da grade antiga, 52 com referência positiva, foram reconfirmadas. As 81 células vazias/68 positivas relatadas para a nova grade correspondem à versão anterior desta revisão semântica; **não são contagem final após corrigir cor/universos**.

## 4. Desenho e calibração: contas, evidência e incerteza

### 4.1 Os pesos gravados fecham as restrições atuais

Foi escrito um verificador separado, sem importar os auditores anteriores. Ele não resolve Newton, não estima pesos e não calcula variâncias; agrega os pesos existentes segundo as regras atuais do calibrador, deliberadamente distinguindo esse teste da aprovação dessas regras.

| Bloco | Células verificadas | Maior erro relativo absoluto |
|---|---:|---:|
| Definitivos: idade×sexo nas UFs maiores | 462 | 6,73×10⁻¹⁵ |
| Definitivos: sexo nas seis menores | 12 | 1,23×10⁻¹¹ |
| Definitivos: urbano | 21 | 6,71×10⁻¹⁵ |
| Definitivos: leitores | 48 | 1,75×10⁻¹¹ |
| Preliminares: Q1 | 176 | 1,45×10⁻¹⁴ |
| Preliminares: Q2 | 8 | 1,00×10⁻¹⁴ |

São 543 restrições definitivas e 184 preliminares, todas numericamente verificadas, com asserções de cardinalidade. Não há peso final domiciliar não finito, diferença de peso pessoa–domicílio ou alteração do peso-base do DF. Contra a base efetivamente usada no ajuste, os fatores vão de 0,3002115 a 3,4957955, dentro dos limites 0,3–3,5.

Isso **não** demonstra correção dos vínculos, recuperação dos pesos originais do IBGE ou aprovação das variâncias. Parte das regras antigas de presença/idade danificada continua no calibrador. A calibração pode fechar perfeitamente sobre uma estrutura familiar errada.

### 4.2 Fernando de Noronha e proteções do solucionador

O ajuste definitivo usa base 4 em FN; o arquivo exporta `censobr_weight_desenho=78,74015748` e calcula o fator dividindo por 78,74. Em FN o fator exportado fica 0,0477194–0,0908701: não é o fator logit contra a base 4. É inconsistência de metadados, não evidência de que o solucionador ultrapassou seus limites.

Também continua necessária a distinção entre o nominal 1/4×1/20=1/80 e a normalização convencional 1/0,0127. Uma pasta observada nas duas fontes torna a hipótese de certeza de FN plausível, mas não substitui documentação do cadastro e do mecanismo de seleção. Certeza na etapa de pastas não elimina a incerteza da etapa de 25%.

`raking_1960_amostra_127`, linhas 1017–1030, pode terminar 200 iterações sem rejeitar falta de convergência; a busca de passo também aceita o último candidato quando nenhum melhora. Não há evidência de não convergência nos pesos atuais — a tabela acima confirma o contrário. Faltam, porém, contratos explícitos para o próximo processamento: resíduos finitos dentro da tolerância, alvos/chaves válidos, viabilidade, pesos finitos e limites respeitados. A proteção contra célula amostral nula existe no construtor definitivo; não se deve supor proteção idêntica em todos os caminhos.

### 4.3 Ranks e corridas recalculados sem R

O cadastro empírico reconstruído conserva 13.411 pastas; 670 selecionadas têm correspondência nele. Sem o deslocamento duplicado de Alagoas, recontagem independente:

| Recorte candidato | Pares consecutivos comparáveis | Passo exato 20 | Percentual |
|---|---:|---:|---:|
| UF×quatro grupos | 611 | 472 | 77,25% |
| Região×quatro grupos | 654 | 474 | 72,48% |
| UF×zona×quatro grupos | 173 | 146 | 84,39% |

Há 74 pastas da Serra dos Aimorés sem zona/população urbana no guia, quatro delas selecionadas; o cálculo `zona4` as conserva como zona desconhecida, não como zona histórica identificada. Não houve empate municipal na determinação da moda.

O terceiro percentual não significa automaticamente melhor desenho: subdividir descarta a maioria dos pares, especialmente as transições que permitem testar limites. A comparação exige denominadores e fronteiras, não só o maior percentual. Reproduzir o erro histórico de Alagoas devolve exatamente os 612 pares/473 passos 20 anteriores; a correção muda esses números para 611/472. São 552/611 passos entre 19 e 21 (90,34%).

O cálculo de corridas em `references/figuras/desenho_amostral_1960.R:233–236` ordena por UF/rank e agrupa sem situação, embora os ranks reiniciem dentro de UF×situação. Isso mistura séries. Corrigindo apenas no verificador isolado, há 198 corridas ao todo, 119 com pelo menos duas pastas, das quais 102 atravessam mais de uma zona. Os números anteriores 104/97 não devem ser usados. No confronto de pares, 326 dos 441 que atravessam zonas têm passo 20 (73,92%).

A evidência continua favorecendo UF×situação como reconstrução operacional e contraria a leitura simples de cada zona como uma série independente. Não prova a lista histórica de estratos, o início aleatório, a ausência de perdas ou a probabilidade de inclusão de cada pasta. As figuras e relatórios antigos **não foram regenerados**; os novos números estão neste parecer e no JSON isolado.

As cinco divergências de composição já encontradas entre fontes — CE15004/15290, MG43234, SP60158/60718 — permanecem pendentes de investigação de registros. Não se presume que a classificação a partir dos domicílios sobreviventes reproduza a composição histórica do cadastro. A correção de PR agora tem evidência de conteúdo; a de Guanabara 54-541→54142 não recebeu uma confirmação externa equivalente nesta rodada.

### 4.4 O que permanece fora do cálculo de variância

Não foram calculadas novas variâncias calibradas, conforme a decisão do usuário. Permanecem necessárias, numa etapa posterior:

- separação entre incerteza condicional aos controles e incerteza populacional total;
- covariâncias/dependência entre subamostra e controles oriundos da amostra maior, sem presumir fontes independentes;
- confronto da linearização calibrada com implementação de referência;
- distinção entre seleção domiciliar nos particulares e seleção de pessoas nos coletivos;
- avaliação da aproximação da seleção sistemática por fórmulas de amostragem aleatória, da primeira etapa e do colapso de estratos;
- documentação de que variâncias condicionais nulas nas restrições não significam erro populacional nulo.

A [documentação oficial de `survey::svydesign`](https://r-survey.r-forge.r-project.org/pkgdown/docs/reference/svydesign.html) especifica as hipóteses das etapas/FPC e que etapas omitidas não são automaticamente estimadas. Ela não comprova que a representação adotada reconstrói o sorteio histórico. Métodos de [calibração a controles estimados](https://bschneidr.github.io/svrep/reference/calibrate_to_estimate.html) exigem informação de variância-covariância dos controles; a aplicabilidade ao caso dependente deve ser examinada, não inferida da existência de uma função.

Continuam indevidas afirmações irrestritas de que estratos mais grossos são sempre conservadores, que a primeira etapa é desprezível ou que os definitivos são vinte vezes mais precisos. A referência de 25% é muito maior, mas a precisão depende de desenho, variável, estimador e erros não amostrais. Não foi identificada nesta rodada uma fonte de totais populacionais exatos substituta para todos os controles; isso não é requisito para manter uma calibração pontual com limitações corretamente explicitadas.

## 5. Proteções, contagens e documentação

### 5.1 A verificação de duplicatas do gabarito pode ser contornada involuntariamente

R:1303 soma o gabarito por chave antes do helper que rejeita chaves repetidas em R:1136. Duas linhas iguais viram uma referência dobrada e passam pela guarda. Exemplo: duas ocorrências de 39.038 viram 78.076. O gabarito atual não tem duplicações, portanto o erro é de proteção, não um total atual comprovadamente duplicado.

O teste do helper isolado não cobre esse percurso completo. A auditoria Python não reproduz essa agregação prévia. Assim, “duplicação do gabarito sempre causa erro” foi uma conclusão ampla demais na primeira nota.

### 5.2 Contagens derivadas e rótulos ainda usam inferências por exclusão

R:716–719 calcula moradores/presentes com `!V202 %in% ...`. As três pessoas sem V202 — 855822, 951432, 951433 — entram em ambas as contagens. No arquivo, os domicílios 139382 e 154511 carregam respectivamente 10/10 e 6/6 nesses campos, incluindo essas presenças desconhecidas. A validação reformulada usa conjuntos positivos e não as conta. Logo, a política não foi propagada a todas as variáveis derivadas.

Além disso, a classificação de unidade particular por `default` no compilado afeta as 179 pessoas descritas na seção 2.1. Identificadores únicos, boas somas e ausência de joins órfãos são necessários, mas não comprovam a correção desses significados.

### 5.3 Bloquear não é reparar; teste preparado não é teste executado

O bloqueio de duplicatas interrompe diante de candidatos; não incorpora ainda um manifesto de exclusões aprovadas. O bloqueio de vínculos interrompe diante de órfãos remanescentes; não resolve famílias reconstruídas automaticamente antes dele. As saídas antigas continuam disponíveis e com os tratamentos antigos.

Os testes R permanecem **sem execução**. A inspeção constatou que suas seleções existem no gabarito atual, não havendo vacuidade materializada nos casos conferidos; faltam asserções individuais de cardinalidade e casos numéricos para água ignorada, ativo com ramo perdido, universos históricos e gabarito duplicado pelo caminho completo. O teste de domicílio sem residentes verifica pessoas, mas não verifica a exclusão do próprio domicílio.

Há ainda comentários antigos incompatíveis com o código/parecer: por exemplo, R:680–686 fala em 12 estratos e ausência do quarto grupo; R:940–956 afirma que calibrar aos preliminares devolve os pesos do IBGE e promete precisão/ganho sem as qualificações necessárias. Adendos no topo não tornam essas afirmações internamente coerentes. Nesta rodada foram apontadas, não reescritas.

## 6. Conferências que passaram

- Bruto 25 e intermediário concordam nos 15 boletins selecionados, com os limites descritos acima.
- O problema de irmãos com perfis iguais permanece confirmado; não foi descartado por “duplicata textual”.
- A guarda geográfica de conviventes não encontra conflitos reais no conjunto atual; a sequência de boletins também passa.
- IDs domiciliares materializados são únicos/não nulos; os residentes encontram domicílio. Isso não valida pertencimento.
- O teste adversarial Python de peso de residente ausente mantém total NA após o join, n=1 e um peso ausente.
- As grades preservam referências e diferenciam quesitos não reconstruídos, pesos ausentes e zeros computacionais.
- As 543+184 margens dos pesos atuais fecham numericamente e os fatores contra a base efetiva respeitam os limites.
- Q5 não deve juntar automaticamente desquitados/divorciados a separados: a definição na página física 8, impressa IV, dos preliminares exclui desquite/divórcio da categoria separados. Esses casos entram no total, não nessa linha. A suspeita levantada durante a revisão foi descartada.
- O desvio de Alagoas e o problema de corridas foram reproduzidos; a correção numérica não elimina a evidência de regularidade UF×situação.

## 7. O que não foi aprovado nem integralmente avaliado

“Double check de tudo” foi tratado como revisão das três frentes e dos próprios métodos de auditoria, incluindo interfaces com o compilado; não como certificação de cada linha de todos os censos do projeto.

Continuam abertos:

1. Manifesto registro a registro para todos os vínculos/exclusões/reparos, com alternativas, evidência, decisão e reversibilidade. Os 141 candidatos de família não são 141 fusões aprovadas.
2. Conferência no gzip de todos os perfis envolvidos nas 31 restaurações, das demais exclusões e dos casos conviventes discordantes; cobertura externa limitada nas onze UFs.
3. Validação completa das reparações manuais, imputações, filhos/idades/fecundidade, alterações geográficas e correspondência com distritos; nesta rodada foram examinados casos críticos, não todos os quesitos e todas as linhas.
4. Nova validação semântica de Q3/Q4/Q5, reconstrução dos 456 cruzamentos/medidas atualmente não implementados, e nova contagem de células vazias após correções. Não foi retranscrito visualmente todo o gabarito célula a célula.
5. Auditoria integral do pipeline de 25% e de seus pesos, validação de todas as UFs do compilado, estabilidade de identificadores após futuras reconciliações e regressões nos consumidores. Houve rastreamento dos problemas identificados, não homologação geral desses componentes.
6. Cadastro histórico completo, probabilidades de inclusão, lista de estratos/cidades grandes, perdas por pasta, fronteiras das séries sistemáticas e seleção em coletivos. O cadastro reconstruído não é documento original de sorteio.
7. Variância calibrada, incerteza dos controles e hipóteses de FPC, conforme adiamento solicitado.
8. Execução dos testes R e diagnóstico do crash nativo de Rscript. O erro não foi provocado novamente nem declarado resolvido. A revisão em Python não valida o runtime R/Arrow/BLAS.

## 8. Sequência recomendada e evidências

Primeiro, fechar regras e manifestos de reconciliação — incluindo `registro_perdido`, não só órfãos sem chefe — e distinguir decisões confirmadas das hipóteses. Em paralelo, corrigir contratos de universo/categorias/proveniência e ampliar testes. Depois, mediante autorização para R em ambiente seguro, executar testes pequenos, reconstruir vínculos/contagens, recalibrar e comparar os produtos novos com os anteriores. Variâncias calibradas ficam para a etapa posterior já combinada.

Não executar agora o pipeline como forma de “ver se fecha”: as guardas ainda são bloqueios preventivos e as saídas materializadas não incorporam as reconciliações.

Verificadores locais desta rodada, todos sem R:

```text
python -B tmp/doublecheck127/integridade_check.py
python -B tmp/doublecheck127/conviventes_check.py
python -B tmp/doublecheck127/raw_ba_convivencia.py
python -B tmp/doublecheck127/desenho_calibracao.py
```

Resultados locais: `integridade_results.json`, `conviventes_results.json`, `raw_ba_convivencia.json`, `desenho_calibracao_results.json` e `auditoria_original_reexec.json`, no mesmo diretório. São evidências de trabalho em tmp, não novos artefatos de produção/versionados; os casos e números centrais estão registrados neste parecer. Renderizações das páginas citadas: `tmp/pdfs/doublecheck-*.png`. A procedência dos PDFs/gzip encontra-se em [fontes_1960/README.md](fontes_1960/README.md).

**Conclusão:** a primeira rodada detectou problemas reais, mas não havia avaliado todas as decisões importantes, e parte de sua reformulação semântica estava errada. A rechecagem confirma tanto essas limitações quanto pontos que passaram. Não é adequado declarar preparação, consistência ou desenho amostral encerrados neste estado.
