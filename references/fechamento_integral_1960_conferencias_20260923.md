# Conferências integrais de 1960: causas, limites e correções sustentadas

23/09/2026. Esta frente leu fontes históricas e recontou os arquivos completos de 25%; não executou R, não recalculou pesos e não alterou dados de produção. Mediante autorização posterior do executor central, acrescentou os limites T7 ao validador compartilhado. As execuções R antes/depois e a regeneração oficial ficam a cargo do executor central.

## Tabela 7: a causa está identificada e o impacto é delimitável

As **86 células incompletas por peso correspondem a 206 domicílios e 998 moradores distintos** nas 17 UFs. Todos os 206 domicílios têm `V102=7`: tipo declarado ignorado. Não há, nesse conjunto, ausência de lista de pessoas, pessoa sem domicílio, presença desconhecida, situação desconhecida ou espécie domiciliar inválida. Fernando de Noronha não tem caso.

O [Código do Censo, PDF 24/impresso 23](https://biblioteca.ibge.gov.br/visualizacao/instrumentos_de_coleta/doc231.pdf) separa `4=Durável`, `5=Rústico`, `6=Improvisado`, `7=Ignorado`. A informação perdida é precisamente a que determina se a casa pertence ao universo de particulares permanentes. Não é correto substituir 7 por 4/5, classificá-lo como improvisado ou chamá-lo de código inválido. O preenchimento de condição de ocupação/aluguel não resolve isso: o salto é ordenado quando o tipo está registrado como improvisado, não quando o tipo é ignorado.

| UF | Domicílios com tipo ignorado | Moradores | Células incompletas por peso |
|---|---:|---:|---:|
| AL | 1 | 7 | 4 |
| BA | 2 | 12 | 4 |
| CE | 11 | 60 | 6 |
| DF | 9 | 40 | 6 |
| FN | 0 | 0 | 0 |
| GO | 5 | 36 | 6 |
| MG | 2 | 12 | 6 |
| MT | 5 | 19 | 4 |
| PB | 6 | 25 | 6 |
| PE | 14 | 57 | 6 |
| PR | 32 | 127 | 6 |
| RJ | 4 | 21 | 4 |
| RN | 2 | 13 | 6 |
| RS | 12 | 50 | 6 |
| SA | 3 | 17 | 4 |
| SE | 2 | 10 | 6 |
| SP | 96 | 492 | 6 |
| Total | 206 | 998 | 86 |

O [auditor independente](fechamento_integral_1960_conferencias.py) foi reexecutado após as correções municipais de MG/MT/PR. A prova atual usa os 34 arquivos do índice `pesos_municipais_20260923_021933_338649_completo` e o relatório `relatorios/validacao25_c2e0493926db/validacao_definitivos.csv`, ambos sob `tmp/fechamento_integral_1960`. Leu as pessoas em lotes de 65.536 e somente as colunas necessárias. Conferiu exatamente as contagens das **204 células T7** (102 por peso); todas as somas conhecidas e pendentes coincidiram com o relatório integrado dentro de `1e-6`. O maior RSS observado foi 387.063.808 bytes, aproximadamente 370 MiB. O código recusa exceder 2 GiB. Os 34 hashes corresponderam ao índice aprovado e permaneceram idênticos após a leitura, assim como as assinaturas do índice e do relatório. Nenhum R foi iniciado nesta frente.

O suplemento vigente [t7_celulas_17ufs.csv](../tmp/fechamento_integral_1960/conferencias/limites_validador_20260923/t7_celulas_17ufs.csv) entrega, por UF/situação/medida/peso, a quantidade indeterminada, seu impacto ponderado e os limites:

```text
valor_minimo = contribuição dos registros seguramente elegíveis
valor_maximo = valor_minimo + peso dos registros cuja elegibilidade é indeterminada
```

São limites de classificação com pesos fixos, **não intervalos de confiança nem estimativas de erro amostral**. Os estados incompletos não são convertidos em aprovação. Uma unidade pode aparecer no total e em sua situação: não se devem somar contagens entre células.

A comparação reprodutível com o suplemento anterior confirma que só MG, MT e PR
mudaram valores ponderados. Quantidades de registros, status e referências das
204 células ficaram idênticos. O suplemento anterior fica como cronologia, não
como fonte dos limites ponderados atuais. A primeira tentativa de atualização,
na pasta `pesos_corrigidos_20260923`, parou numa checagem nova do auditor que
esperava `observada` no rural de FN sem registros: o status correto já era
`sem_observacoes`. A checagem foi corrigida, sem mudar dados ou validador; a
execução integral intermediária, ainda suplementar, foi aprovada na pasta `_02`.
A conferência final dos limites já incorporados ao validador está em
`limites_validador_20260923`, exigindo explicitamente as duas colunas.

Exemplo: SE tem duas casas incertas e dez moradores. Com `censobr_weight`, o total conhecido pode crescer, no máximo, 7,301459 domicílios e 33,234299 moradores ponderados. O número publicado de domicílios continua abaixo de ambos os extremos: diferença de +1,176371% a +1,181054%. A incerteza de tipo não explica essa diferença. Das 86 células incompletas desse peso, apenas três têm a referência publicada dentro do intervalo; nas outras 83, classificar os casos ignorados de qualquer maneira não basta para produzir igualdade. Isso não prova erro dos microdados, pois os totais publicados são estimativas de outra apuração. A maior largura relativa de intervalo é 0,230002% do publicado, nos moradores rurais do DF.

**Implementação no validador compartilhado:** `R/microdata_1960_validacao.R`
agora acrescenta `valor_minimo` e `valor_maximo`, reutilizando os contadores
existentes. O par de limites só é calculado em T7 reconstruída, quando pesos
conhecidos/pendentes são finitos e não negativos, as somas são finitas e os dois
contadores de cobertura são zero. Nos demais casos, ambos ficam ausentes. A
escolha conservadora evita apresentar um intervalo fechado quando falta lista
de pessoas ou cartão domiciliar. `valor`, diferenças e classificação incompleta
continuam preservados; nenhum tipo ignorado é atribuído a permanente. Pesos
negativos passam a ser contados como inválidos por registro em T7, antes da
soma, inclusive quando outro peso positivo mascararia o problema. A mensagem
desse status foi atualizada somente para T7. Nenhum chamador, peso ou manifesto
foi modificado por esse patch.

O teste dedicado tem 13 cenários sem Arrow: conhecido/incerto, pesos pessoais
distintos, domínio vazio, arquivo ausente, falta de lista/cartão, pesos
NA/infinito/negativo, negativo compensado por positivo, inválido fora do universo
e transbordamento da soma. O executor central registrou FAIL antes do patch,
pelas colunas ausentes (`logs/t7_limites_antes.log`), e **PASS nos 13 cenários
depois do patch** (`logs/t7_limites_depois.log`). A implementação está testada
e a saída real foi reconferida integralmente com `--require-limits`: os 204 pares
de limites coincidem com o cálculo independente dos 34 parquets. As 1.836 células
das outras tabelas têm ambos os limites ausentes. Uma regressão adicional
confirma igualdade exata de todas as 25 colunas preexistentes nas 2.040 linhas,
inclusive status, valores parciais, contribuições pendentes e diferenças. Prova:
[regressao_2040_celulas.json](../tmp/fechamento_integral_1960/conferencias/limites_validador_20260923/regressao_2040_celulas.json).
A revisão estática independente também aprovou o diff.
O SHA-256 do validador editado é
`c570e82348dd68e2fe0df239cc5e2cd99c57f1ad97b1f5bfe9a481698ca16e9b`.

## Quadro 6: nova ambiguidade comprovada na apuração dos aluguéis ignorados

As quatro páginas originais foram conferidas visualmente: [volume preliminar](https://www.ibge.gov.br/biblioteca/visualizacao/periodicos/68/cd_1960_v2_resultados_preliminares.pdf), PDF 25/33/41/49, impressos 12/22/31 e página final da tabela do Sul (posição correspondente a 40). A página do Sul não exibe número legível no fac-símile consultado. Em cada uma, a nota sob a tabela diz: “Inclusive os sem declaração de aluguel.”

Apesar disso, **a soma das seis faixas é exatamente igual ao total alugado em todas as 24 combinações diretamente publicadas**: Brasil, Nordeste, Leste e Sul, cruzados por domicílios/moradores e total/urbano/rural. As seis combinações de Norte e Centro-Oeste também fecham, mas derivam por diferença e não constituem evidência independente.

Exemplo brasileiro, quantidade de domicílios:

```text
893.896 + 567.060 + 568.795 + 539.607 + 240.104 + 217.748 = 3.027.210 alugados
```

Os algarismos conferem nas imagens; não foi identificado erro de transcrição nas parcelas do aluguel. A [aritmética completa](../tmp/fechamento_integral_1960/conferencias/q6_identidades_publicadas.csv) e os fac-símiles estão preservados. A igualdade e a nota não demonstram **como** a apuração tratou aluguel ignorado: não permitem distinguir ausência desses casos na apuração, distribuição prévia pelas faixas ou outra convenção histórica. Também não provam que uma faixa específica absorva os ignorados.

Nos 17 arquivos atuais de 25%, há 3.934 domicílios particulares ocupados confirmados com `V103=8,V104=9`; não há, nesse universo, aluguel fora dos códigos 0–7/9. O relatório antigo de 1,27% identifica 354 cartões com aluguel declarado ignorado, sem aplicar nesse contador todos os filtros de elegibilidade de Q6. Esses dois números não são estimativas do número original de casos da publicação.

**Consequência implementada pelo executor central:** `V104=9` continua no total
alugado, conserva os seis totais conhecidos sem redistribuição e torna incompleta
a comparação de cada faixa nos domínios potencialmente afetados. A linha “sem
declaração” continua se referindo a `V103=0`, condição de ocupação ignorada. O
validador preliminar agora usa `!V104 %in% 0:7` nos alugados para marcar a faixa
pendente, incluindo aluguel ignorado e aluguel conjunto sem valor isolável.
Acrescenta `politica_aluguel` ao relatório, sem reescrever V104 nem forçar o
fechamento das seis somas. O teste `references/test_validacao_amostra_127.R`
atualizado passou na bateria central, log
`tmp/fechamento_integral_1960/regressoes/20260923_022844_296649/test_validacao_amostra_127.log`.

## “Alugado / não paga aluguel” pode ser uma resposta correta

As [Instruções ao Recenseador de 1960](https://biblioteca.ibge.gov.br/visualizacao/instrumentos_de_coleta/doc94.pdf), PDF 39/impresso 41, quesito D, ordenam registrar **Alugado** no quesito C e **Não paga aluguel** no quesito D quando um pagamento único cobre residência e unidade não residencial, ou quando se trata de moradia em estabelecimento agropecuário arrendado. A imagem local foi lida diretamente, não apenas seu OCR.

Portanto `V103=8,V104=8` não é, por si só, contradição. O valor do aluguel da moradia não está isolado. A pendência de faixa é defensável, mas deve ser descrita como aluguel não isolado/sem faixa identificável, e não como dado necessariamente incoerente. Não inferir zero, aluguel gratuito ou faixa até 500. A interpretação foi incorporada aos comentários do validador e à política de aluguel do relatório, preservando o tratamento conservador das faixas.

O endereço oficial do manual foi localizado em outra publicação do próprio IBGE, [liv98624, referências bibliográficas](https://biblioteca.ibge.gov.br/visualizacao/livros/liv98624.pdf). A abertura direta de `doc94.pdf` pelo navegador de pesquisa falhou nesta sessão; a evidência visual usa a cópia local de 44 páginas, com SHA-256 registrado em `fontes_metadados.json`. Não foi afirmada igualdade de bytes entre essa cópia e o arquivo remoto inacessível.

## Quadro 5: o novo exame não autoriza resolver a idade ignorada

A busca foi ampliada além das páginas preliminares usadas nas rodadas anteriores. Foram examinados o manual de coleta, o código de codificação e o tomo definitivo do Paraná, além das introduções e tabelas preliminares. Consultas no domínio do IBGE buscaram instruções de apuração, estado conjugal, idade ignorada e subamostra de 1965; não foi localizada uma instrução de apuração do quadro preliminar 5 nem um total preliminar de residentes por idade que o identifique.

As instruções de coleta, PDF 25/impresso 27, admitem idade ignorada excepcionalmente. No quesito de estado conjugal, PDF 30/impresso 32, a coleta abrange dez anos ou mais. Isso é diferente do limite de quinze anos do quadro divulgado e não fornece sua regra de apuração. Ter V215 preenchido não demonstra elegibilidade aos quinze anos.

O [tomo definitivo do Paraná](https://www.ibge.gov.br/biblioteca/visualizacao/periodicos/68/cd_1960_v1_t14_pr.pdf), PDF 11/impresso XIII, declara que idades ignoradas integram os totais de tabulações com limite mínimo de idade. Seu quadro 3, PDF 47/impresso 6, apresenta 7.465 pessoas na linha de idade ignorada dentro do estado conjugal de quinze anos ou mais. As imagens foram conferidas. É evidência explícita para a publicação definitiva, mas não é uma instrução identificada para o processamento preliminar de 1965.

No preliminar, PDF 6/impresso II distingue os presentes dos residentes e reserva estes últimos para Q5–Q7. PDF 8/impresso IV descreve Q5 como residentes de quinze anos ou mais e explica a atividade do chefe para inativos, sem dizer o destino das idades ignoradas. O total Q5 brasileiro é 40.189.391; o total de presentes 15+ do Q2 é 40.187.590. A diferença de 1.801 mistura residentes ausentes, visitantes e, possivelmente, a convenção de idade. Ela não identifica sozinha o tratamento da idade ignorada.

Há dois mecanismos compatíveis com os totais: incluir idade ignorada e obter 1.801 de saldo residente menos visitante; ou excluir idade ignorada e obter saldo de residência maior, compensando as idades ignoradas retiradas. Sem o saldo por idade, os agregados não separam esses mecanismos. **Conclusão: conservar a pendência documental de Q5**, distinta de dano de idade e de família sem chefe. Não transportar a regra definitiva sem declarar que se trata de hipótese. Cenários suplementares com inclusão/exclusão explícitas seriam análises de sensibilidade, não validação histórica fechada.

## Demais conferências domiciliares e estado dos artefatos

As implementações Q6/Q7 existentes já cobrem condições de ocupação, as seis faixas de aluguel, água, fogão, instalação sanitária, iluminação elétrica, rádio e geladeira. Não foi encontrada célula desses quadros omitida por ausência de implementação. Isso não implica classificação suficiente: permanecem os casos sem espécie, características, lista ou vínculo demonstrado do ramo de 1,27%. Os relatórios existentes foram produzidos sobre a materialização antiga; suas contagens não devem ser promovidas a resultado da reconstrução atual.

O suplemento T7 trata exclusivamente a base completa de 25% reponderada em staging; não certifica o ramo de 1,27%, não substitui a reconstrução e não fecha variâncias. O índice histórico e os nomes/tamanhos/esquemas dos microdados ficaram intactos.

Artefatos desta frente:

- [Auditor T7](fechamento_integral_1960_conferencias.py), [extração documental](fechamento_integral_1960_conferencias_fontes.py) e [plano](fechamento_integral_1960_conferencias_plano.md).
- [Resultado T7 e hashes](../tmp/fechamento_integral_1960/conferencias/limites_validador_20260923/t7_resultado.json), [resumo de 17 UFs](../tmp/fechamento_integral_1960/conferencias/limites_validador_20260923/t7_resumo_17ufs.csv), [padrões originais](../tmp/fechamento_integral_1960/conferencias/limites_validador_20260923/t7_padrao_codigos.csv) e 17 listas de cartões `t7_registros_incerto_<uf>.csv` na pasta vigente.
- [Limites das 204 células](../tmp/fechamento_integral_1960/conferencias/limites_validador_20260923/t7_celulas_17ufs.csv), [comparação com pesos anteriores](../tmp/fechamento_integral_1960/conferencias/limites_validador_20260923/comparacao_com_pesos_anteriores.json), [identidades de aluguel](../tmp/fechamento_integral_1960/conferencias/q6_identidades_publicadas.csv), [metadados/páginas/hashes das fontes](../tmp/fechamento_integral_1960/conferencias/fontes_metadados.json) e fac-símiles PNG na pasta documental original.

A habilidade de PDF orientou a leitura por texto seguida de conferência visual. Esse procedimento permitiu detectar a regra legítima de aluguel conjunto no manual e confirmar as identidades das seis faixas sem depender apenas do OCR.
