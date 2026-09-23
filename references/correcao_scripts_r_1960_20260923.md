# O que foi corrigido nos scripts de 1960

Rodada de 23/09/2026, posterior ao commit `91372a35`. Escopo: corrigir o que ja estava suficientemente definido, sem escolher respostas historicas por suposicao, reconstruir a base nacional ou recalcular seus pesos.

## 1. A informacao sobre a origem da correcao nao pode desaparecer

Antes, a preparacao podia conservar a origem de um cartao familiar recuperado e a prova de um distrito corrigido. Entretanto, a compilacao selecionava uma lista fechada de colunas que nao incluia essas informacoes. Ao juntar as duas amostras, essa memoria da correcao desaparecia.

Agora, as listas de pessoas e domicilios conservam as 15 colunas ja existentes de origem e prova. Nao foram inventados novos campos de resposta do IBGE. As marcas de sim/nao ficam em 1/0; quando uma informacao nao se aplica, a coluna existe com valor ausente e tipo consistente entre arquivos. Uma nova marca de origem desconhecida provoca interrupcao, em vez de ser descartada silenciosamente.

A bateria anterior de pesos revelou um detalhe adicional: uma coluna textual inteira vazia podia continuar numerica quando ja existia na entrada. A primeira correcao nao bastava, pois o data.table reaproveitava o tipo da coluna. Foi criada uma contraprova com uma e duas linhas, nas duas tabelas; a segunda falhou antes da correcao. Agora a substituicao do vetor inteiro conserva o tipo esperado, sem preencher nenhuma resposta ausente.

Exemplo ilustrativo: um distrito originalmente escrito como `X7` pode ter recebido `07` como codigo operacional mediante confronto documentado com a outra fonte. O arquivo deve permitir encontrar tanto `X7` como o codigo recuperado e o caminho da prova. Conservar apenas `07` esconderia como se chegou a ele. O teste verifica justamente essa preservacao; ele nao altera os registros reais de Pernambuco.

O dicionario tambem recebeu os rotulos desses campos e passou a ler os arquivos que a funcao efetivamente recebe. Antes, ignorava os caminhos recebidos e procurava arquivos fixos de Sergipe e Guanabara. Esses dois representantes continuam sendo usados: seus percentuais de preenchimento nao sao uma medicao nacional.

**Limite importante:** o bloqueio de cartoes recuperados no ramo de 1,27% da compilacao continua ativo. Nenhum dos 32 cartoes atualmente aprovados pertence as onze UFs desse ramo. Esta rodada nao autoriza novos casos nem insere esses cartoes artificialmente na compilacao.

## 2. Exportar passa a exigir uma conferencia dos mesmos arquivos

Antes, `save_microdata_1960()` podia gravar o arquivo final sem consultar o resultado da validacao. Isso foi reproduzido com um arquivo ficticio: a exportacao ocorreu sem qualquer conferencia. O gravador tambem ignorava o resultado de `file.rename()`, que informa se a instalacao da saida realmente funcionou.

Agora, `validate_1960()` grava, junto ao relatorio, um comprovante das assinaturas SHA-256 dos insumos e da regra de comparacao. Uma assinatura identifica o conteudo exato de um arquivo; nao prova que a interpretacao historica de suas respostas esteja certa.

A nova funcao `conferir_publicacao_1960()` exige o par de pessoas e domicilios de cada UF, a grade completa das tabelas examinadas, identificadores e vinculos coerentes, pesos principais validos e tipos declarados para todas as colunas. O gravador exige o resultado dessa conferencia e volta a comparar as assinaturas antes de escrever. O fluxo foi ligado aos targets de 1960, sem executar o pipeline. O target de validacao acompanha os dois arquivos (relatorio e comprovante); a funcao conserva seu retorno anterior, um unico caminho de CSV.

Exemplo ficticio: hoje um relatorio foi calculado com peso 80; depois o arquivo recebeu peso 81, mantendo o mesmo nome. O relatorio antigo nao aprova esse novo arquivo. E necessario conferir novamente. Se uma pessoa aponta para um domicilio inexistente, ou a mesma familia aponta para dois domicilios, a entrega tambem e interrompida.

**Uma diferenca de total nao e automaticamente uma falha de integridade.** Se a referencia publicada registra moradores rurais e a pequena amostra nao contem nenhum, a comparacao continua aparecendo como sem observacoes. Nao se acrescenta pessoa, nao se aumenta peso e nao se exclui a comparacao. O teste confirma que uma grade completa com diferencas numericas pode passar na conferencia tecnica.

A escrita usa uma pasta temporaria exclusiva, conserva temporarios quando falha e nao substitui uma versao ja existente. So retorna o caminho depois de confirmar a instalacao de um unico parquet.

**Esta conferencia nao e uma aprovacao cientifica da base.** Ela nao comprova que todas as exclusoes historicas ou interpretacoes familiares tenham sido resolvidas; nao homologa pesos, desenho ou variancias. Permanecem as guardas da preparacao e as pendencias registradas nas rodadas anteriores.

## 3. Os resultados de variancia passam a declarar suas limitacoes

As tres funcoes de erros amostrais agora identificam seus resultados como diagnosticos provisorios. Informam que a variancia total nao foi validada e que a incerteza dos totais estimados usados como controle nao foi incorporada.

No calculo residual da amostra de 1,27%, o texto esclarece que os controles foram tratados como fixos. Nas outras saidas, nao se apresenta esse calculo como realizado. Nenhuma formula ou coluna numerica anterior foi alterada.

Exemplo ficticio incluido no teste: o erro-padrao pelo desenho e positivo, mas o erro residual condicionado aos controles e zero. O zero continua sendo mostrado, acompanhado da limitacao; nao e interpretado como prova de ausencia de erro populacional.

## O que foi testado

Todos os testes R usam o executor isolado com arquitetura Windows informada apenas ao processo filho. Uma instancia por vez, sem `Rscript -e`, sem `targets`, sem mudar pacotes ou o ambiente global. Os dados dos testes sao ficticios e ficam em pastas exclusivas sob `tmp`.

- `test_procedencia_compilacao_1960.R`: antes demonstrou a perda das colunas; depois conferiu preservacao, tipos, leitura conjunta pelo Arrow, rotulos, rejeicao de marca desconhecida e manutencao do bloqueio de cartao recuperado no ramo127. Respostas e pesos permaneceram iguais.
- `test_exportacao_sem_conferencia_1960.R`: antes exportou sem aprovacao; depois recusou antes de criar a pasta de saida.
- `test_rotulos_erros_1960.R`: comparacao exata de todas as colunas anteriores em quatro saidas (retorno e CSV de 1,27%, CSV de 25% e CSV combinado). O resultado anterior foi preservado em RDS, sem regeneracao.
- `test_publicacao_1960.R`: exportacao e releitura de quatro domicilios e quatro pessoas ficticios, grade de 180 comparacoes para duas UFs mais Brasil, divergencias legitimas, 30 recusas tecnicas esperadas e leitura das dependencias por parse de `_targets.R`.
- `test_validacao_1960.R` e `test_pesos_1960.R`: repeticao das baterias anteriores pertinentes. A primeira conserva a conferencia de 1.566 comparacoes pessoais e 174 domiciliares da grade nacional, usando microdados ficticios.

Resultados finais e tentativas interrompidas: [caderno de evidencias](correcao_scripts_r_1960_evidencias/LEIAME.md). Falhas do proprio teste foram corrigidas sem alterar resultados para faze-lo passar: tipos inadequados na primeira fixture, locale na leitura do R, comparacao de ponteiros internos do data.table e tentativa de regravar parquet ainda mapeado no Windows. Neste ultimo caso, as contraprovas passaram a usar novos arquivos de entrada a cada restauracao. Nao houve queda nativa do Rscript. Uma tentativa de imprimir o log encontrou caractere nao suportado pelo console Python; as execucoes seguintes usaram `python -X utf8`.

## O que ainda falta, e o que nao foi alterado

O arquivo `schemas/censobr_types.csv` nao foi preenchido a mao. A regra do projeto exige medir as colunas completas do produto real; medir um exemplo pequeno nao substitui isso. A nova conferencia recusa um esquema que ainda nao declare as novas colunas. O esquema sintetico usado no teste existe somente dentro da pasta do teste.

Portanto, **codigo corrigido nao significa arquivo final pronto para publicacao**. Ainda faltam resolver as pendencias historicas de registros, reconstruir os produtos afetados quando isso for seguro, revisar/recalcular os pesos correspondentes e medir os tipos do produto real. O aprofundamento das variancias continua adiado. Os inventarios detalhados permanecem na [nota residual anterior](resolucao_residuais_registros_1960_20260922.md).

Nao foram alterados brutos, manifestos de decisoes, parquets de producao, pesos reais ou funcoes compartilhadas de outros anos. As alteracoes preexistentes em `renv.lock` e no Rproj foram preservadas. Sem release, commit ou push nesta rodada.

As assinaturas do bruto `HHOLDA.txt` e dos dois parquets atuais da amostra de 1,27% foram novamente calculadas e coincidem com as registradas antes desta rodada. Seus valores estao no caderno de evidencias.
