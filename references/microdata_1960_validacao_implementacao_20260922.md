# O que mudou na conferência de 1960

**Atualização posterior no mesmo dia:** esta nota documenta a primeira implementação. Depois, o erro nativo foi diagnosticado, os testes passaram e os quatro relatórios com os dados/pesos existentes foram gerados em área separada. A tabela 7, as faixas de aluguel e a conferência de estado conjugal também foram implementadas. A correção do universo de leitores passou ao cálculo dos pesos de 25%, com recálculos separados documentados. O estado vigente, os arquivos e os limites estão na [nota de execução](execucao_correcao_1960_20260922.md); as afirmações abaixo sobre tarefas ainda não executadas são históricas. Os dados completos de 1,27% continuam sem reconstrução aprovada.

Implementação de 22/09/2026, autorizada após o parecer integrativo. **O código foi alterado; os relatórios de produção ainda não foram recalculados.** R/Rscript continuam suspensos devido às falhas nativas observadas. Nenhum peso, pessoa, vínculo familiar ou parquet foi modificado nesta etapa.

## O problema que esta etapa resolve

Antes, os validadores de 25% e do arquivo combinado começavam pelas categorias encontradas nos microdados. Uma categoria sem pessoas podia desaparecer antes de ser comparada com a publicação. Também faltavam os totais por sexo das tabelas de idade, situação e cor.

Agora a lista de comparações vem da publicação. Para cada comparação, o código procura o que é possível calcular nos arquivos fornecidos. Não encontrar pessoas é diferente de não receber o arquivo ou não conseguir interpretar seus códigos.

No combinado, a lista pessoal examinada tem **1.566 comparações**, e não 1.346. As 220 que antes faltavam não recebem todas zero: 174 são totais que precisam ser calculados, e 46 são categorias que antes não apareciam. O valor de cada uma depende dos registros e da possibilidade de classificá-los.

**Isso não significa que o programa inventava 220 pessoas rurais em Rondônia.** As 220 são linhas de conferência ausentes, espalhadas por diferentes UFs, tabelas e pelo Brasil. Duas delas são as comparações de homens rurais e mulheres rurais de Rondônia. Acrescentar essas linhas ao relatório não acrescenta ninguém aos microdados: mostra que a amostra tem zero observações nesses grupos, embora a publicação registre população rural.

Os relatórios de 25% e do combinado também passam a mostrar as referências domiciliares da tabela 7, mas como **cálculo ainda não implementado**, não como zero. Por isso seus tamanhos esperados são:

| Relatório | Comparações pessoais | Referências domiciliares ainda não calculadas | Total de linhas |
|---|---:|---:|---:|
| 25%, para cada peso | 918 | 102 | 1.020 |
| 25%, seus dois pesos | 1.836 | 204 | 2.040 |
| Combinado, UFs e Brasil | 1.566 | 174 | 1.740 |

Essas contagens foram reconferidas na referência transcrita. São requisitos dos testes, **não contagens de uma nova execução do R**.

## Como ler cada resultado

Uma “célula” é uma comparação específica: por exemplo, homens rurais de Rondônia na tabela 34. `status_celula` informa o que foi possível fazer:

| Código no relatório | Significado | Resultado completo |
|---|---|---|
| `observada` | Há registros classificáveis e seus pesos permitem a soma. | Soma calculada. |
| `sem_observacoes` | A comparação foi calculada, mas nenhum registro pertence à categoria e não há pendência que possa mudar essa classificação. | Zero observado, não população zero. |
| `classificacao_incompleta` | Há registros que podem pertencer à comparação, mas falta informação para decidir. | Ausente; soma conhecida em `valor_parcial`. |
| `peso_ausente` | Há registros pertencentes à comparação com peso ausente ou não finito. | Ausente; não se descarta silenciosamente o peso problemático. |
| `nao_reconstruida` | O cálculo não foi implementado ou faltam arquivos para fazê-lo. | Ausente, nunca zero. |

`n_amostra` conta registros cuja participação está confirmada. `n_sem_classificacao` conta pendências que podem afetar aquela comparação. Nas comparações domiciliares de 1,27%, essa contagem é de domicílios problemáticos, mesmo quando a medida comparada é pessoas: não sabemos quantas pessoas faltam em uma lista perdida. A coluna `unidade_sem_classificacao` explicita essa diferença. Uma mesma pessoa ou domicílio pode ser pendente em mais de uma categoria: **não se devem somar essas contagens entre linhas para contar unidades distintas**. Se existem simultaneamente pesos problemáticos e classificação incompleta, o rótulo dá prioridade ao problema de peso conhecido; as duas contagens permanecem visíveis.

Em 25% e no combinado, `valor` é o resultado completo; em 1,27%, o nome anterior `nosso` foi preservado. `valor_parcial` guarda a soma dos registros classificados. Sem pendências, ela coincide com o resultado completo. Havendo peso problemático nesses registros, até essa soma parcial fica ausente. As diferenças contra a publicação só são calculadas quando o resultado completo está disponível. Com referência publicada igual a zero, a diferença absoluta continua válida, mas a percentual fica ausente.

Em 25% e no combinado, `peso_sem_classificacao` informa a soma dos pesos dos registros pendentes. `n_pesos_ausentes_sem_classificacao` registra quantos desses pesos também não puderam ser usados. A amostra de 1,27% mantém, adicionalmente, seu diagnóstico de universos separado. As contagens de pendências de 1,27% são conservadoras: podem sinalizar várias categorias sem atribuir a pessoa a nenhuma delas.

## Dois exemplos concretos

**Rondônia rural.** A recontagem independente, somente leitura, confirmou novamente que não há pessoas rurais no arquivo combinado de RO. Existem 305 homens e 361 mulheres presentes, todos em situação urbana/suburbana. Quando o novo validador for executado, a comparação rural masculina deverá mostrar zero observado contra 23.324 publicados; a feminina, zero contra 16.282. Ambas deverão permanecer no relatório, com diferença de −100%. Isso mostra uma limitação da amostra; não autoriza fabricar moradores rurais ou transferir pessoas de categoria.

**Leitores de idade declarada ignorada em São Paulo.** A comparação da tabela 40 passa a seguir a convenção da publicação: incluir esses leitores no total de cinco anos e mais, sem lhes inventar uma idade. A recontagem seletiva confirmou 2.080 homens, com soma de pesos 8.153,188102289, e 2.092 mulheres, com soma 8.218,110569485, antes excluídos da comparação. Esses valores precisam entrar na conferência com os pesos atuais. Portanto, uma diferença que antes aparecia como zero pode passar a ser positiva. **A calibração ainda não foi corrigida nem refeita:** essa divergência é justamente uma informação que o relatório não deve esconder.

Idade declarada ignorada não se confunde com idade danificada. Um registro com unidade “anos” e número perdido não recebe a classificação “idade declarada ignorada”. Pode tornar incompleta uma faixa numérica ou um total com idade mínima, mas continua incluído no total de presentes quando sua condição de presença é conhecida.

As fontes, códigos e registros desses exemplos estão no [caderno de validação](parecer_1960_evidencias/validacao.md). Esse caderno descreve o estado anterior e a evidência que motivou a correção; seus antigos números de linha de código não acompanham os deslocamentos causados pela implementação.

## Outras proteções da implementação

- Totais de presentes nas tabelas 33, 34 e 37 são calculados sem exigir que idade, situação ou cor estejam conhecidas. Uma pessoa com cor perdida não desaparece do total geral por sexo.
- Cor de código 8 entra em “pardos” somente na comparação com a categoria publicada. O código original não é alterado.
- Os validadores de 25% e do combinado leem exclusivamente os caminhos recebidos. Uma UF não fornecida fica pendente; não é buscada escondidamente no diretório de produção. Arquivos vazios, UFs repetidas ou incompatíveis com o caminho são rejeitados.
- O total do Brasil só é calculado quando todas as 28 UFs estiverem disponíveis para aquela comparação. Um teste com RO e SP não é apresentado como estimativa nacional.
- Referências com chaves repetidas são rejeitadas antes de somar. A medida “pessoas” ou “domicílios” integra a chave da tabela 7.
- As somas de 25% e do combinado não são arredondadas antes da comparação. Pequenas diferenças continuam visíveis.
- `referencia_estimada` continua distinguindo referências estimadas de contagens do universo. No Brasil há uma composição de contagens e estimativas; o marcador é verdadeiro porque o total não é integralmente uma contagem do universo. Os domicílios da tabela 7 são referências estimadas em todas as UFs.

Os resumos contam também as comparações incompletas, não calculadas e sem observações. A mediana das diferenças considera somente percentuais calculáveis: uma mediana pequena **não é um certificado do conjunto** quando há comparações pendentes.

## Ajustes próprios da amostra de 1,27%

A comparação da água passa a reconhecer o código explícito “ignorado” junto com “outra forma de abastecimento”, conforme a categoria publicada. Um branco por salto do questionário não recebe automaticamente esse significado. Nas atividades, não ter ramo registrado deixa de significar automaticamente “inativo”: a condição de atividade precisa ser conferida; um ativo sem ramo permanece como pendência nas categorias que exigem ramo.

A comparação domiciliar distingue uma lista existente com somente visitantes de um domicílio cuja lista de pessoas está ausente. O segundo caso não pode virar “zero moradores” sem ressalva. A tabela 7 definitiva restringe a comparação aos domicílios particulares permanentes; a dúvida sobre o tipo de construção continua visível.

Há limites que permanecem explícitos: os cruzamentos conjugais e as faixas de aluguel ainda não reconstruídos continuam na lista como não calculados. Nos quadros preliminares 3 a 5, a inclusão de idades ignoradas/danificadas ainda não foi resolvida para essa fonte; a soma conhecida é identificada como parcial quando esses casos podem afetá-la. Isso não aplica silenciosamente à fonte preliminar uma convenção conferida apenas para a definitiva.

## Onde conferir a implementação

- [Cálculos compartilhados de tabulação e comparação](../R/microdata_1960_validacao.R).
- [Validador de 25%](../R/microdata_1960_amostra_25.R), função `validate_definitivos_1960_amostra_25`.
- [Validador combinado](../R/microdata_1960.R), função `validate_1960`.
- [Validadores de 1,27%](../R/microdata_1960_amostra_127.R), funções `validate_1965_1960_amostra_127` e `validate_definitivos_1960_amostra_127`.
- [Testes de 25% e combinado](test_validacao_1960.R) e [testes de 1,27%](test_validacao_amostra_127.R).
- [Plano e limites autorizados](../.claude/plans/2026-09-22_implementar_validacao_1960.md).

As assinaturas anteriores continuam válidas. Os validadores de 25% e combinado ganharam `out_dir` opcional para testes isolados e continuam retornando um caminho de CSV. Não houve alteração do grafo de targets, dos nomes dos arquivos de saída nem do esquema dos microdados.

## O que foi verificado — e o que falta

Foram conferidos os caminhos reais esperados pelo pipeline, as quantidades e a unicidade das referências, os exemplos seletivos de RO/SP por leitura independente em Python e as alterações por revisão estática. Essa revisão encontrou e corrigiu um problema de seleção de coluna lógica em data.table. A conferência textual de delimitadores e `git diff --check` não substitui um teste funcional.

**Os testes R foram preparados, mas não executados.** Eles usam bases artificiais pequenas e saídas isoladas sob `tmp/`, sem chamar `_targets.R`. A próxima verificação funcional, quando R voltar a ser autorizado e o problema dos crashes estiver tratado, começa por esses testes. Só depois cabe gerar novos relatórios com os pesos já gravados.

Os CSVs de produção continuam antigos. O script histórico `parecer_1960_evidencias/conferir_exemplos.py` ainda verifica, entre outras coisas, a ausência da linha rural no relatório antigo; essa verificação deverá deixar de passar depois da regeneração correta. Ele não é o teste de aceitação da implementação nova.

Esta entrega **não homologa os dados**, não resolve os vínculos e as exclusões discutidos no parecer, não corrige os pesos já calibrados e não calcula variâncias calibradas. Também não cria uma trava de exportação dependente de aprovação da validação. Essas são etapas distintas e continuam pendentes.
