> **Arquivo histórico da versão de 21/09/2026.** Texto preservado para rastreabilidade. A exposição vigente é a [versão narrativa e ilustrada](microdata_1960_amostra_127_revisao_integrativa.md), reescrita em 22/09/2026. Este anexo conserva a linguagem técnica e a numeração anteriores; não é uma nova rodada de testes.

> **Atualização documental de 23/09/2026, restrita às cinco pastas da seção de desenho:** a [investigação nominal](fechamento_integral_1960_duplicatas_pastas_resultado.md) identifica uma comparação inadequada CE15004→15004: a correspondência demonstrada em145 famílias aponta para CE14990, também rural. Nas outras quatro pastas, oito cartões com situação pessoal contraditória explicam o rótulo misto antigo;27 pessoas são parte dos192 conflitos já inventariados, não novos casos. Não há prova independente que escolha V118 correto, e nenhum estrato, UPA, ID ou fração foi alterado. O corpo histórico abaixo foi preservado. [Evidência permanente](fechamento_integral_1960_evidencias/pastas_desenho.json).

# Revisão integrativa de 1960: preparação, consistência, validação e desenho

**Data:** 21/09/2026. **Parecer:** revisão documental e diagnóstica concluída; os tratamentos e os produtos **não estão homologados**. Não foram executados R, Rscript ou targets, nem alterados código de produção, guias, pesos, variâncias ou parquets nesta rodada.

Este é o ponto de entrada vigente para conciliar as três rodadas: diagnóstico dos documentos iniciais; auditorias e bloqueios preventivos; double check. A presente integração reexaminou suas conclusões e as interfaces com a amostra de 25% e o compilado. Não são três implementações concluídas, nem três fontes estatisticamente independentes.

Os relatórios anteriores ficam preservados como histórico. **Em caso de conflito, prevalecem as decisões e os limites deste parecer.** Os detalhes dos casos continuam nos relatórios vinculados abaixo; números de universos distintos não devem ser somados.

## 1. Conclusão executiva

A preocupação inicial estava correta: a integridade não podia ser deduzida de chaves únicas, códigos válidos ou margens calibradas que fecham. A revisão também havia deixado interfaces relevantes sem avaliação. Foram encontrados agora:

1. **Um erro compartilhado pelo calibrador e pelo validador de 25%.** Eles excluem leitores com idade declarada ignorada de um controle cuja convenção publicada os inclui. As 34 células estaduais de leitores fecham com diferença zero, mas deixam de fora 9.395 leitores presentes, peso 36.562,0023. É concordância de duas regras incorretas, não aprovação independente.
2. **Omissões persistentes no validador final:** 220 das 1.566 referências pessoais previstas não aparecem; 210 são positivas. A proteção nova de 1,27% não foi propagada para 25%/compilado. Os validadores finais também não comparam as 168 referências estaduais da tabela domiciliar 7.
3. **Um reparo de texto que criou três valores errados, todos individualmente válidos:** HHOLDA 951431, RS. O erro fica na amostra de 1,27%; o compilado utiliza a fonte de 25% para o RS.
4. **Uma conclusão anterior excessiva sobre cobertura domiciliar:** há um domicílio particular sem nenhuma pessoa listada. Ele não pode ser equiparado a domicílio ocupado exclusivamente por visitantes, nem sustentar a frase de que todos os particulares têm residente conhecido.
5. **Uma lacuna de aceitação do pipeline:** os CSVs de validação são ramos paralelos; os targets de exportação não dependem de aprovação deles. O dicionário, por sua vez, descreve preenchimento de SE/GB como se representasse as duas partes nacionais e usa tipos anteriores ao cast final.

As pendências de vínculos, duplicatas, universos de comparação e identificação histórica do desenho continuam abertas. Os bloqueios preventivos reduzem o risco de repetir duas regras antigas, mas **não corrigem os arquivos existentes nem cobrem toda a reconstrução familiar**.

## 2. O que cada camada realmente demonstra

| Camada | Estado verificado | O que não demonstra |
|---|---|---|
| Fonte HHOLDA | 1.074.328 linhas, todas com 62 caracteres; 124 decisões de leitura únicas e texto original correspondente | Que todos os reparos sejam corretos, que o arquivo esteja completo ou que as pessoas sejam duplicatas civis |
| Leitura pessoal materializada de 1,27% | 897.009 pessoas; reprodução independente de 25 campos coincide, exceto as 19 imputações V208 identificadas | Que as decisões aplicadas ao texto ou os vínculos estejam corretos |
| Domicílios materializados de 1,27% | 174.245 registros, 815 UPAs e 75 estratos analíticos na revisão anterior; todas as pessoas encontram domicílio | Pertencimento correto; há um domicílio sem pessoa listada |
| Código de 1,27% alterado na auditoria | Bloqueios antes da deduplicação antiga e da anexação posicional dos órfãos remanescentes; grade de validação ampliada | Correção retroativa; bloqueio da criação das 150 famílias; aprovação semântica ou execução dos novos testes R |
| Pesos de 1,27% já gravados | 543 restrições definitivas e 184 preliminares recompostas na rodada anterior, com resíduos numéricos muito pequenos | Universos corretos, probabilidades históricas exatas, validade da variância ou integridade familiar |
| Compilação existente | 28 UFs: 15.145.810 pessoas e 3.097.387 domicílios; contagens e schemas finais conferidos | Validação nacional de cada valor ou equivalência com o código atualmente editado |
| Execução e publicação | Nenhuma execução R ou publicação nesta revisão | Estado de um rebuild futuro; identidade do release remoto com estes arquivos locais |

**Correções apenas no código, dados corrigidos e testes executados são estados diferentes.** Aqui não houve nova correção de produção. As modificações anteriores no worktree, inclusive `.Rproj` e `renv.lock`, foram preservadas.

## 3. Registro conciliado de integridade

### I1. Vínculos: separar os três mecanismos

- **Anexação ao anterior:** 1.008 pessoas, 436 grupos originais. Há 70 conflitos geográficos: 48 de pasta, 30 de distrito e 26 de V116, com sobreposição; dois destes últimos são bairros da Guanabara, portanto não se deve anunciar 26 conflitos municipais. Não há conflito de UF nesse conjunto. As 70 não são o universo inteiro de vínculos duvidosos.
- **Criação de família com chefe/cônjuge:** 150 grupos/485 pessoas receberam `registro_perdido`. Destes, 141 têm um cartão candidato existente na mesma UF+pasta+boletim, com distrito divergente; nove não têm esse candidato. Isso derruba a afirmação de 150 cartões comprovadamente perdidos, mas não autoriza fundir todos os 141. Nas UFs do compilado que usam 1,27%, chegam 59 famílias/179 pessoas; 58 famílias têm candidato. Os 179 têm V101 ausente e são classificados pelo compilador como particulares por default.
- **Famílias conviventes:** 373 encadeamentos foram inventariados. A regra de proximidade tem evidência favorável, mas não constitui identidade comprovada. Em 37 pares comparáveis há diferenças de V101 entre cópias; não são 37 vínculos comprovadamente errados. O único 1→5 isolado e a sucessão de boletins precisam continuar no contrato de validação.

O bloqueio novo está depois da criação das famílias sintéticas (`R/microdata_1960_amostra_127.R:578–597`). Renumerar chaves na compilação não reconcilia uma família duplicada ou partida. Também foram encontrados 61 conflitos de V116 entre pessoa e cartão diretamente ligado, em parte associados a reparos geográficos; não se deve rejeitá-los todos sem examinar a origem da diferença.

Casos prioritários já rastreados: MG 40090 anexado a 40050; BA 31606/031 e 072; BA 31962/118; PR 70380/088, cuja correção de pasta tem apoio no conteúdo bruto de 25%, mas cuja família continua partida. Os detalhes e linhas estão no [double check](microdata_1960_amostra_127_doublecheck.md) e na [auditoria de vínculos](microdata_1960_amostra_127_auditoria_vinculos.md).

**Fechamento exigido:** manifesto de decisão por grupo, com cartão original, candidatos, campos concordantes/divergentes, fonte, regra, resultado e indeterminação. Não usar proximidade, chefe/cônjuge ou coincidência de chave como prova suficiente; preservar os casos não resolvidos sem inventar unidade familiar.

### I2. Duplicatas: multiplicidade, não igualdade de perfil

O total histórico removido é 2.850 linhas. O confronto com 25% separou 2.238 com multiplicidade corroborada, 39 exclusões em 28 perfis com excesso de remoção, 555 sem perfil exato, quatro em que 25% tem multiplicidade maior que HHOLDA e 14 sem fonte de 25%. Essas classes somam 2.850, mas **não significam 2.850 decisões igualmente resolvidas**.

Nos 28 perfis, o saldo sugerido é **31 restaurações, não 39**. Irmãos legítimos com idade ignorada podem ter os mesmos códigos; ausência de diferenças observáveis não é unicidade de pessoa. As 31 estão nas 17 UFs em que o compilado usa 25%, logo não são 31 pessoas ausentes do produto compilado. O total hipotético 897.040 só valeria se nada mais mudasse.

Foram consultados os brutos de 25% para boletins selecionados, não para todas as 2.238 exclusões corroboradas ou todos os 28 perfis. As cópias compartilham origem; não são testemunhos independentes de identidade civil. **Fechamento:** decisão por perfil e multiplicidade, com casos PB 19124/166, PE 21438/069 e BA 31712/057 como regressões obrigatórias; manter indistinguíveis em caso de dúvida.

### I3. Reparos de texto: achado novo e hipóteses restantes

Na linha HHOLDA 951431, o reparo em `read_guides/1960_amostra_127_correcoes.csv:99` insere um zero no prefixo preservado. O fragmento original sem espaços concorda com o bruto RS 252042, pasta 81076/016, ordem 03, até V215; o texto corrigido é que desloca:

| Campo | Parquet 1,27% atual | Fragmento original / bruto 25% |
|---|---:|---:|
| V212 | 0 | 6 |
| V213 | 6 | 2 |
| V214 | 20 | 00 |

Os três valores errados são códigos válidos; `censobr_variaveis_anuladas` fica vazio. A leitura implementa fielmente o reparo errado. O compilado do RS usa 25% e não reproduz este defeito. Não houve edição do guia nesta revisão.

Permanecem os dois reparos BA 387715 e 387853, nos quais a comparação anterior sustenta V218=0/V219=3, mas não resolve automaticamente a diferença em V216. Em HHOLDA 388894, a justificativa diz que V221–V224 se perderam, porém V221=863/V223=2 foram preservados; o bruto PE comparável tem V221=989. Em HHOLDA 830192, V216=56 no fragmento e 57 no bruto SP é divergência entre cópias, não deslocamento demonstrado. Não escolher uma fonte silenciosamente.

Os 17 textos reparados/recuperados foram confrontados com 25%; oito coincidem integralmente nos campos comparados. Os demais incluem truncamentos e divergências, não nove reparos comprovadamente errados. Narrativas sobre perfuradora, perda de cartão ou repetição de buffer continuam hipóteses de mecanismo quando não há prova direta.

**Verificações positivas novas:** as 19 imputações V208 têm candidato de 25% com os outros 24 campos pessoais exatos e V208=9; são **18 brancos e um caractere R**, não 19 brancos. A lista reproduzida de variáveis anuladas coincide com a flag gravada. As 13 linhas com dígitos depois do salto já eram decisões `valor_isolado`, com anulação dos campos atingidos. As lacunas examinadas do layout familiar não contêm informação nova: coluna 32 somente zero/branco e posições 35–54 corrigidas em branco.

### I4. Contagens, cobertura e flags não são certificados

A integração corrigiu uma conclusão do double check: dos 173.259 particulares, existe **um sem pessoa listada**: domicílio 127134, linha 780535, SP 63936/230, V101=1/V102=5, peso 78,740157. Entre os particulares com lista, não foi encontrado caso sem residente conhecido. Ausência de lista é informação insuficiente sobre ocupação, não zero residente demonstrado. As contagens NaN não devem virar zero sem registrar essa distinção.

Continuam três pessoas de presença desconhecida incorporadas às contagens domiciliares antigas por negação de códigos, nos domicílios 139382 e 154511. Uma flag FALSE significa “a regra não demonstrou contradição”, inclusive se lhe faltavam dados, não “consistência examinada e aprovada”. HHOLDA 85316 mantém V207=29 e V208=1, semanticamente contraditórios, sem prova para corrigir uma das respostas.

Passaram invariantes específicos: tipo 2 compatível com V203=7; idade em meses até 11; V204=9 sempre com V204B=99; não moradores presentes com V203 em 4/6. Não equivalem a uma auditoria demográfica completa. **Fechamento:** contagens em ambos os sentidos pessoa↔domicílio, estado “não avaliável” nas regras pertinentes e documentação precisa de flags e imputações.

## 4. Validação: um contrato único, aplicado a três camadas

### V1. Omissão de referências ainda presente fora de 1,27%

Rechecagem independente por conjuntos de chaves do gabarito e dos CSVs existentes, usando o peso final:

| Camada | Referências pessoais esperadas | Reportadas | Omitidas | Omitidas positivas |
|---|---:|---:|---:|---:|
| 25%, 17 UFs | 918 | 807 | 111 | 102 |
| Compilado, 28 UFs e Brasil | 1.566 | 1.346 | 220 | 210 |

Em 25%, faltam 102 totais por sexo não construídos nas tabelas 33/34/37 e nove categorias de Fernando de Noronha, estas com referência zero. No compilado, faltam 174 totais e 46 categorias; 36 categorias têm valor oficial positivo. O rural de Rondônia continua omitido: 23.324 homens e 16.282 mulheres publicados. Os joins preservam `medido`, não o gabarito (`R/microdata_1960_amostra_25.R:779`; `R/microdata_1960.R:411`).

Isso não é o mesmo universo das contagens antigas de 1,27%. Na primeira auditoria havia 63 referências definitivas omitidas, 52 positivas; os valores 60/50 usavam um recorte sem três células da tabela 33: FN/mulheres=0, DF/homens=360 e DF/mulheres=359. Na grade ampliada de 1,27%, a classificação provisória era 81 vazias/68 positivas, sobre 1.932 referências definitivas, e 2 vazias/456 não reconstruídas, sobre 2.220 preliminares por peso. **Esses números descrevem as regras então implementadas e precisam ser refeitos depois dos acertos semânticos.** Não somá-los às 220 omissões do compilado.

### V2. Idade: erro de calibração compartilhado com o teste

A [Série Nacional](fontes_1960/1960_serie_nacional_vol1_brasil.pdf), página física 12, impressaXIII, estabelece a inclusão das idades ignoradas nos totais com limite mínimo. O calibrador de 25% converte V204=9 em idadeNA e exige idade conhecida≥5 para leitores (`R/microdata_1960_amostra_25.R:568–574,621`). O validador 25 e o compilado repetem esse filtro (: 767–768 e `R/microdata_1960.R:395–396`).

As 34 células estaduais de leitores no CSV 25 têm diferença arredondada zero. Foram encontrados, por dois verificadores independentes, **9.395 leitores presentes com V204=9, peso 36.562,002299**, fora do controle: SP sozinho tem 4.172/peso 16.371,298672. O problema é de universo, não de convergência. O calibrador 25 **tem** guarda de convergência (: 651–652); não transferir a crítica do solucionador 127 indiscriminadamente.

O calibrador 127 inclui os declarados ignorados nessa margem, mas sua validação recém-reformulada os exclui. Logo, não basta consertar uma função de validação: calibradores e validadores precisam compartilhar o **significado documentado** do controle, com provas independentes desse significado.

| Universo materializado | Presentes V204=9 | Peso final | Leitores nesse conjunto |
|---|---:|---:|---:|
| Amostra 127 integral | 1.208 | 93.901,3733 | 520 |
| Parte 127 do compilado | 105 | 9.886,0341 | 49 |
| Parte 25 do compilado | 20.892 | 81.182,3820 | 9.395 |
| Compilado inteiro | 20.997 | 91.068,4160 | 9.444 |

No compilado há ainda quatro presentes de GB com V204=1/V204B ausente, peso 374,440915, indevidamente tratados como idade declarada ignorada na tabela 33. São dano/não classificação, não V204=9. Incluir a declaração ignorada nos limites mínimos **não autoriza incluir qualquer idade danificada**.

### V3. Harmonizações e universos pendentes, sem generalizar entre funções

| Comparação | Decisão conciliada | Alcance/ação pendente |
|---|---|---|
| Cor, tabela 37 | V206=8 integra pardos para comparação publicada, preservando código 8 no microdado | A reformulação 127 errou; **25% e compilado já fazem isso corretamente**. Na127 integral são 192 presentes/peso 16.044,34 |
| Água, quadro 7 preliminar | V105=4 é ignorado; ausência estrutural não é ignorado | 101 particulares com código 4/peso 8.129,03 omitidos; 49 improvisados com salto e uma secundária sem tipo incluídos numericamente em `agua_outra_sem_declaracao` por terem V105 ausente |
| Atividade, quadros 3/4 | Ausência de ramo não implica inatividade; conferir V220 | Três ativos com ramo perdido, peso 260,46; outros três sem V220 foram classificados por default. Conferir também inclusão de idade declarada ignorada nos limites mínimos |
| Estado conjugal, quadro 5 | Manter separação de desquite e divórcio segundo a fonte | Suspeita anterior de que divorciados deveriam integrar “separados” foi **descartada**, não é correção pendente |
| Domicílios, tabela 7 definitiva | Universo publicado: particulares permanentes | 49 improvisados na 127 integral indevidamente incluídos, com 77 residentes; nove tipos ignorados e uma secundária sem tipo exigem política explícita |
| Quadros domiciliares preliminares | Excluir ocupação comprovada somente por não moradores presentes | Não confundir com o domicílio sem lista de pessoas de I4 |
| Referência estimada | Identificar por tabela/quesito e UF | Nas 17 UFs os controles definitivos pertinentes são estimados; **quesitos domiciliares vêm da amostra também nas outras 11**, pois eram exclusivos do CD 2 |
| Células não reconstruídas | Incompletude visível, não comparação concluída | 288 cruzamentos do quadro 5 e 168 do quadro 6 preliminar; avaliar dependência da atividade do chefe e V104/aluguel, não declarar indisponibilidade sem investigação |

Fontes visuais: Série Nacional, páginas físicas 12/XIII, 19/XX e 169/132; [Preliminares de 1965](fontes_1960/1965_resultados_preliminares_vol2.pdf), físicas 7/III e 8/IV. As confirmações de cor e idade substituem interpretações da primeira reformulação; a evidência sobre divorciados elimina uma suspeita, em vez de aumentar artificialmente a lista de erros.

A tabela domiciliar 7 sequer entra nos validadores 25/final (: 777/: 409). Suas **168 referências estaduais** estão fora da aprovação final, apesar da exportação de domicílios. Não somá-las à grade pessoal de 1.566 como se já houvesse uma especificação única implementada.

### V4. O que fazer com células sem observações

Não eliminar, imputar pessoas ou recalibrar silenciosamente para fazê-las desaparecer. O contrato proposto é:

| Estado | Valor/diagnóstico de validação | Consequência |
|---|---|---|
| Referência positiva, nenhum caso elegível | n=0; soma observada 0; diferença absoluta e−100% visíveis; `sem_suporte` | Não é zero populacional demonstrado. Se for controle de calibração, coluna auxiliar toda zero não pode atingir alvo positivo: interromper ou redefinir domínio/margem com justificativa aprovada |
| Referência zero e n=0 | Diferença absoluta 0; percentualNA; estado explícito | Pode haver concordância de totais, mas não prova isolada de zero estrutural |
| Regra não implementada | EstimativaNA; `nao_reconstruido` | Contar no denominador de cobertura, fora da aprovação de conteúdo |
| Caso existente, classificação impossível | Quantificar casos/peso não classificáveis e a perda do universo | Não converter em ignorado declarado, inativo ou categoria residual |
| Peso ausente/não finito | `peso_invalido`, sem soma silenciosa com `na.rm` | Bloquear aceitação da estimativa afetada |

Para suporte insuficiente, as opções são agregar categorias substantivamente compatíveis, trocar a margem, limitar o domínio de inferência ou manter a lacuna declarada. Cada opção muda a pergunta ou a informação usada; não é reparo determinístico. Em Rondônia, a ausência de rural não é solucionável multiplicando pesos urbanos. Os totais amostrais publicados continuam úteis como referência; sua incerteza não justifica esconder discrepâncias de cobertura.

Antes de calcular erro, exigir grade completa, chaves únicas **antes de agregação**, universos documentados, balanço de classificados/não classificados e contagem das células testadas. A proteção 127 contra duplicata do gabarito vem depois de uma soma que pode ocultá-la; não há duplicata materializada no gabarito conferido, mas falta proteção end-to-end.

## 5. Desenho e calibração: conclusão conciliada

### D1. Reconstrução plausível, não identificação histórica completa

Está documentada a seleção sistemática de aproximadamente 1/4, por domicílio particular e pessoa em coletivos, e a posterior formação/seleção de pastas, aproximadamente uma em 20. Pasta como conglomerado da subamostra tem respaldo. **UF×quatro grupos de situação** é uma reconstrução operacional favorecida pelos dados, não prova dos limites e reinícios históricos. Os 75 estratos colapsados são uma escolha analítica, não o cadastro original do sorteio.

Na série empírica corrigida UF×grupo, 611 intervalos são comparáveis: 472 exatamente 20 (77,25%) e 552 entre 19 e 21 (90,34%). As análises regionais/zonais usam conjuntos diferentes de pares; a maior proporção de uma não prova desenho melhor. Das 198 corridas por UF×grupo, 119 têm pelo menos duas selecionadas e 102 atravessam zonas. O script de figuras ainda agrupa corridas só por UF e não foi reexecutado; figuras antigas não são evidência atualizada.

Duas das sete divergências iniciais de classificação de pastas eram a recodificação repetida de Alagoas, corrigida no script apenas. Restam cinco diferenças de composição entre fontes: CE 15004/15290, MG 43234, SP 60158/60718. O cadastro empírico de 13.411 pastas é reconstruído de produto legado, não a lista histórica preservada. A hipótese de nenhuma pasta perdida continua sem certificação externa.

O produto nominal 25%×5%=1,25%, com inverso 80. Usar 1/0,0127≈78,740157 é convenção do arquivo, não probabilidade exata recuperada. A seleção certa de Fernando de Noronha também é hipótese: o ajuste usa base 4, mas os metadados exportados indicam 78,74 e fator sobre essa base. Os fatores reais de ajuste, usando a base efetiva, ficaram entre 0,3002115 e 3,4957955; não se confirmou violação dos limites logit nos pesos salvos.

### D2. Três questões que não podem ser confundidas

1. **Aritmética:** os pesos 127 gravados atendem às 543 restrições definitivas e 184 preliminares recompostas sob as regras atuais; maiores resíduos relativos aproximadamente 1,75×10⁻¹¹ e 1,46×10⁻¹⁴. Isso passou. Não foi ajustado peso novo.
2. **Semântica:** as margens podem estar erradas apesar desse fechamento, como demonstrado agora na alfabetização 25. A checagem completa das demais margens 25, das margens municipais e da Sinopse não foi encerrada por este trabalho.
3. **Inferência:** controles estimados não viram totais populacionais conhecidos por falta de alternativa. Mantê-los é uma decisão válida do projeto, desde que identificados como referenciais estimados e sem interpretar variância residual zero como ausência de erro populacional.

A representação `survey` precisa corresponder às unidades e frações assumidas. Apenas enumerar níveis aninhados não recupera a seleção cronológica; sem FPC, `svydesign` usa variância no nível superior com reposição, e com menos FPCs que níveis assume seleção completa nos níveis restantes. Conferir argumentos e hipóteses, não apenas igualdade de fórmulas. [Documentação oficial de `svydesign`](https://r-survey.r-forge.r-project.org/pkgdown/docs/reference/svydesign.html).

**Variâncias após calibração continuam adiadas, por decisão do usuário.** Não foi calculada nem certificada uma aproximação “conservadora”, uma contribuição desprezível da primeira seleção ou um ganho de precisão de 20 vezes. Quando retomadas, será necessário tratar incerteza dos controles e dependência entre amostra e controles; métodos para controles estimados exigem informação de variância/covariância, não apenas os totais pontuais. A existência de uma rotina não resolve a ausência desses insumos nem prova sua adequação a esta relação de subamostragem. [Documentação de `calibrate_to_estimate`](https://bschneidr.github.io/svrep/reference/calibrate_to_estimate.html).

O solucionador compartilhado `raking_1960_amostra_127()` carece da rejeição final de não convergência e da aceitação explícita do backtracking; é proteção latente, não falha numérica demonstrada nos pesos existentes. O fluxo 25 acrescenta uma verificação de convergência depois de chamar esse solucionador; não há dois solucionadores independentes. Buscar documentação original das probabilidades, séries e cadastro continua pendência; não encontrar publicação de variâncias não prova que nunca existiu.

## 6. Interfaces, exportação e reprodutibilidade

Por inspeção de `_targets.R`, `output_1960_amostra_127` e `output_microdata_1960` não dependem de um resultado aprovado de validação. No compilado, a exportação depende diretamente de `compilada_1960` (: 381–386). Os validadores escrevem CSV e retornam caminho; não produzem critério de aceitação que bloqueie saída. **Target concluído, CSV gerado e dado aprovado são três afirmações distintas.**

Os argumentos `paths` dos validadores 25/final são ignorados nas leituras, que usam diretórios fixos (`R/microdata_1960_amostra_25.R:735`; `R/microdata_1960.R:366`). Um teste com caminho temporário pode ler produção e passar indevidamente. Essa interface precisa ser testada antes de testes semânticos em fixtures serem aceitos como prova.

O dicionário é construído somente com SE e GB (`R/microdata_1960.R:613–620`), embora rotule percentuais como `preenchido_25_pct` e `preenchido_127_pct`. Os metadados nacionais mostram 35 percentuais coluna×parte domiciliares e 62 pessoais divergentes. Exemplo: `code_bairro_1960` aparece com 100% na parte 127, mas o preenchimento nacional dessa parte é 28,3% nos domicílios e 22,9% nas pessoas. Isso não é perda de dados: é descrição inadequada do denominador.

O dicionário também registra classes antes do cast final: há sete divergências de tipos nos domicílios e 13 nas pessoas, como `censobr_favela` descrita como logical e exportada int32. Os arquivos finais, entretanto, têm 67/99 colunas e não divergem dos tipos declarados no schema. Conferir schema é diferente de conferir descrição. Não usar percentuais de SE/GB como evidência de completude de todas as UFs.

| Interface de valores | Cobertura efetivamente concluída | Resultado |
|---|---|---|
| Fonte 127→compilado | 11 UFs usadas, 31.022 domicílios e 162.041 pessoas; 17 campos domiciliares e 23 pessoais de pesos, flags e contagens | Zero divergências; mapeamentos de idhousehold/idfamily bijetivos por UF |
| Compilado→final | Somente RR: 58 domicílios e 401 pessoas; 25/33 colunas, respectivamente | Zero divergências, considerando os casts deliberados |
| Desenho no compilado de origem 127 | Mesmas 11 UFs; cinco campos | Sem nulos; FPC1=0,05 e FPC2=0,25, verificação de preenchimento, não prova histórica |
| Contagens e schema final | Metadados dos 28 parquets por tabela e dos dois finais | Somas exatas e nenhuma divergência do schema |

**Não foi concluída uma comparação nacional célula a célula compilado→final.** A tentativa nacional não retornou resultado utilizável e não conta como teste aprovado. Fonte 25→compilado teve somente o recorte de idade ignorada examinado pelo revisor de validação, não todas as colunas. Preservação fiel também preserva erros anteriores.

Dois riscos adicionais foram identificados por inspeção, sem reprodução de falha: `schemas/censobr_types.csv` é lido em `R/type_convention.R:35` sem dependência de arquivo declarada no DAG; uma alteração isolada no CSV não está rastreada dessa forma. Em `R/microdata_1960.R:339–342`, o retorno de `file.rename()` é ignorado, o temporário é removido e o caminho final é retornado. Se a renomeação falhar com destino já existente, há risco de devolver o arquivo antigo após descartar o novo. Não houve teste de invalidação ou falha de gravação nesta revisão. Ambos precisam integrar o fechamento de reprodutibilidade, sem confundi-los com corrupção comprovada dos arquivos atuais.

## 7. O que ainda não foi avaliado integralmente

O escopo agora é mais amplo, mas a expressão “revisão de tudo” não pode significar ausência garantida de falhas. Esta lista é o limite explícito, não itens considerados implicitamente aprovados:

- Identidade e pertencimento de todas as famílias/conviventes, inclusive coletivos; resolução dos casos sem 25% e das divergências entre cópias.
- Conferência em bruto de todas as exclusões corroboradas, de todas as decisões `valor_isolado` e de toda correção municipal/distrital. Os diagnósticos de flags e parsing são abrangentes; a verdade histórica de cada edição não é.
- Parsing independente de todos os campos familiares comparado ao parquet, e consistência demográfica de todas as variáveis: ocupação/ramo, migração/naturalidade, escolaridade, renda/aluguel, fecundidade, parentesco e seus saltos. Foram conferidas regras/casos específicos, não o conjunto completo desses domínios.
- Origem, transcrição e compatibilidade de **cada** célula dos controles definitivos, preliminares e municipais da Sinopse, inclusive arredondamentos, limites territoriais e totais entre publicações. As páginas e tabelas críticas citadas foram conferidas; não houve dupla transcrição integral de todas as fontes.
- Reconstrução dos cruzamentos preliminares ainda ausentes; incorporação da tabela domiciliar na validação 25/final; harmonização completa das margens 25 além do erro de alfabetização confirmado.
- Cadastro histórico das pastas, ordenação e probabilidades conjuntas; coletivos, estratos solitários, inferência em domínios pequenos e a hipótese de certeza de FN. A hipótese operacional não é identificação completa.
- Dependência entre estimativas de controle e subamostra; variâncias após calibração, expressamente adiadas. Sem necessidade de interromper as correções de integridade por causa desse adiamento.
- Comparação nacional completa fonte→compilado→final, reversibilidade de IDs após reconciliação e efeito das mudanças futuras em todas as colunas de geografia/flags. O smoke test RR e os schemas não fecham esse item.
- Execução dos testes R novos, equivalência das implementações depois de corrigidos universos, rebuild seguro, estado remoto publicado e causa dos crashes Rscript. Nenhum desses foi investigado por nova execução nesta rodada.

## 8. Ordem de encerramento proposta

Esta é uma sequência de trabalho futuro, não autorização nem execução de mudanças:

1. **Reconciliação de integridade:** manifestos separados de vínculos, multiplicidades e reparos, com indeterminações explícitas. Incluir I1–I4 e não alterar automaticamente todos os candidatos.
2. **Contrato de universos/controles:** uma especificação por tabela, referência, UF, declaração ignorada, salto e código danificado; incluir a alfabetização 25. Manter valores originais e variáveis auxiliares de comparação separadas.
3. **Testes independentes de semântica e interface:** provas numéricas de casos reais e sintéticos, cardinalidade não vazia, gabarito completo/único antes da soma, células sem suporte, peso ausente, caminhos temporários, famílias sem lista e flags não avaliáveis.
4. **Implementação mínima autorizada e execução segura em pequeno:** apenas após resolver a restrição de R; falhar antes/passar depois nos casos estabelecidos, depois conferir os recortes necessários. Nenhum rebuild integral como primeira tentativa.
5. **Validação materializada e aceitação:** balanço bruto→exclusões/restaurações→pessoas/famílias/domicílios, comparação 25 e compilado, cobertura de todas as referências, divergências justificadas, metadados/dicionário e exportação condicionada ao resultado aprovado.
6. **Documentação do desenho e, em etapa própria, variâncias:** atualizar figuras a partir das séries corretas; manter hipóteses identificadas. Só depois retomar a inferência calibrada se o usuário decidir.

Critério de fechamento desta revisão: parecer único, divergências conciliadas e limites verificáveis. Critério de homologação futura: decisões aprovadas, implementação e testes efetivamente executados, produtos novos auditados. **O primeiro foi atendido; o segundo não.**

## 9. Evidência e reprodução desta rodada

Verificadores próprios, sem importar os auditores de produção, sob `tmp/integrativa127/` (diretório local ignorado pelo Git):

- `integridade_leitura.py` / `.json`: linhas, decisões, layouts, invariantes e 25 campos pessoais de 897.009 registros; confronto dos 17 reparos e 19 imputações com intermediários 25.
- `integridade_reparos_gzip.py` / `.json`: conferência pontual dos brutos RS/PE/SP, incluindo a prova do zero inserido em 951431.
- `validacao_interfaces.py` / `_results.json`, `_metrics.csv`, `validacao_omitidas_*.csv`: grades 25/final, leitura seletiva dos 28 parquets compilados e conferência das idades ignoradas nos 17 arquivos-fonte 25.
- `rechecagem_principal.py` / `_results.json`: reprodução independente das omissões por conjuntos de chaves, soma dos 9.395 leitores diretamente nas fontes 25 e cobertura domiciliar com join preservando todos os domicílios. Asserções explícitas contra testes vazios.
- `interfaces_exportacao.py` / `interfaces_resultados.json`: smoke test RR até o final, transferência de campos selecionados das 11 UFs fonte 127 ao compilado, schemas, contagens e metadados. O JSON é resumo normalizado das execuções concluídas, não stdout integral. Compilado→final nacional não concluído; não tratá-lo como teste passado.

Os verificadores são evidência diagnóstica, não substitutos de testes R. As leituras dos PDFs relevantes foram visuais, incluindo cabeçalhos e notas dos universos; a habilidade de PDF orientou essa conferência e ajudou a distinguir convenção publicada de interpretação do código. Documentos web acima foram consultados somente para limites do software/métodos, não como prova da amostragem de 1960.

Relatórios anteriores: [preparação](microdata_1960_amostra_127_preparacao.md), [consistência](microdata_1960_amostra_127_consistencia.md), [desenho original](microdata_1960_amostra_127_desenho_amostral.md), [auditoria de vínculos](microdata_1960_amostra_127_auditoria_vinculos.md), [auditoria de validação](microdata_1960_amostra_127_auditoria_validacao.md), [revisão do desenho](microdata_1960_amostra_127_revisao_desenho.md) e [double check](microdata_1960_amostra_127_doublecheck.md). O [plano desta integração](../.claude/plans/2026-09-21_revisao_integrativa_amostra_127.md) registra o escopo e os limites de execução.
