# Caderno da implementação residual de 1960

Este caderno registra a rodada de implementação iniciada em 22 e verificada em 23/09/2026. Comece pelo [relatório narrativo](../resolucao_residuais_registros_1960_20260922.md). Não confundir este caderno com a [investigação anterior](../investigacao_residual_1960_evidencias/LEIAME.md), que permanece como registro histórico.

**Conferência desta rodada concluída:** 22 scripts de testes R com última execução aprovada e 32 testes Python aprovados, além das oito verificações internas da auditoria complementar. O inventário e as decisões estão conciliados. Isso não homologa toda a amostra: os casos sem prova permanecem bloqueados.

## Provas por assunto

- [Cinco pares pessoais preservados](../resolucao_residuais_duplicatas5_1960_evidencias.json), [alternativas SP/RS](../resolucao_residuais_duplicatas_alternativos_1960_evidencias.json) e [critério composto CE](../resolucao_residuais_duplicatas_ce_1960_evidencias.json).
- [Disposição de cada um dos 463 conjuntos anteriormente pendentes](../resolucao_residuais_duplicatas_disposicoes.json).
- [Manifesto de famílias com conteúdos coincidentes](../../read_guides/1960_amostra_127_familias_coincidentes.json), incluindo as que continuam bloqueadas.
- [Dois vínculos de chave parcialmente ilegível](vinculos_chaves_incompletas.json).
- [Prova vigente dos dois cartões fora de chave](cartoes_fora_chave_fechada.json), produzida após estabilizar o CSV dos vínculos. A [prova inicial](cartoes_fora_chave.json) e a [intermediária](cartoes_fora_chave_final.json) preservam as assinaturas anteriores como cronologia; não são a versão usada atualmente pelo manifesto.
- [Investigação do distrito pernambucano](distrito_pe_proposta.json) e [decisão operacional localizada](distrito_pe_operacional.json), com textos originais preservados.
- [Quatro nacionalidades e diferenças pessoais preservadas](texto_propostas.json).
- [Separação dos grupos paulistas e limite da hipótese da Guanabara](texto_disposicao_sp_gb.json).
- [Por que o segundo testemunho gaúcho não é exclusivo](segunda_testemunha_rs.json) e [conferência dos 199 alvos em 80 famílias, nenhuma unipessoal](conferencia199_unipessoais.json).

As notas de [duplicatas](../resolucao_residuais_duplicatas_1960.md), [vínculos](../resolucao_residual_vinculos_1960.md) e [texto](../resolucao_residual_texto_1960.md) explicam antes, motivo da correção, resultado e limites. “Perfil” significa o conjunto de respostas comparadas; “testemunha” significa um registro suficientemente específico para sustentar uma correspondência, não uma identificação civil.

## Inventário e conciliação

- [Inventário atual](inventario_atual.json): recontagem independente dos registros com os manifestos atuais, incluindo as pendências; não é uma reconstrução em R.
- [Antes/depois por registro](cobertura_antes_depois.json): quais casos receberam decisão e quais mantêm impedimentos. As classificações descritivas do caderno anterior são identificadas como históricas, não como uma nova busca global.
- [Conferência dos 32 cartões recuperados](integracao_cartoes.json): verifica os 30 anteriores, os dois novos, as fontes e os textos.
- [Coincidências familiares reconferidas](familias_reconferidas.json): busca nos 174.425 cartões presentes no índice examinado, incluindo famílias de uma pessoa; os dez conjuntos coincidem com os do manifesto. Essa busca usa os integrantes já ligados a cartões reais no índice, não todos os órfãos nem cartões sintéticos recuperados.
- [Conferência complementar dos cartões recuperados e do distrito](coincidencias_operacionais.json): comparação dos 32 recuperados entre si e contra os 174.467 cartões reais. Oito cartões reais compartilham território e atributos familiares com algum recuperado; nenhum compartilha também a composição pessoal inteira. A recuperação do distrito em PE tampouco cria coincidência. Oito verificações internas conferem ordem, quantidades, campos e danos. Não é uma reconstrução completa em R.
- [Cópias adicionais e documentação histórica](fontes_adicionais.json): cinco cópias de HHOLDA com os mesmos bytes e páginas examinadas sem resposta para a dúvida sobre idade ignorada no quadro de estado conjugal.

Os 1.216 registros pessoais sem família, as 918 linhas de perfis repetidos pendentes e as 192 pessoas com conflito geográfico **não são listas independentes**. A mesma linha pode aparecer em mais de uma. Os três fragmentos indecifráveis estão incluídos no primeiro total; agrupá-los pela chave vazia não demonstra que sejam uma família. A conciliação não apaga casos nem certifica as 127 exclusões históricas ainda sem comprovação.

## Como repetir os testes

Todos os diretórios de saída devem ser novos. Os testes produzem microlotes em `tmp`, não substituem os parquets completos e não executam o pipeline nacional.

```powershell
python references/verificar_resolucao_residuais_1960.py --out tmp/NOVA_BATERIA_RESIDUAL
python references/verificar_testes_python_residuais_1960.py --out tmp/NOVA_BATERIA_PYTHON
python references/conferir_integracao_residuais_1960.py --out tmp/NOVA_CONFERENCIA_INTEGRADA
python references/inventario_final_registros_1960.py tmp/NOVO_INVENTARIO_RESIDUAL
python references/conferir_coincidencias_operacionais_residuais_1960.py --index tmp/resolver_residuais_1960_20260922/cartoes_reauditoria_fechada/indice127.sqlite --out tmp/NOVA_CONFERENCIA_OPERACIONAL
```

A bateria executa apenas um R por vez, pelo [executor isolado](../rodar_r_isolado_1960.py), informando arquitetura e locale somente ao processo filho. Não executar `Rscript -e`, `_targets.R` ou `tar_make()` para reproduzir estes testes.

As provas requerem os arquivos brutos locais, os 17 arquivos disponíveis da fonte de 25%, os guias e os manifestos na versão identificada. Os recortes aqui guardados não substituem essas fontes. Um resultado negativo de busca documenta o critério pesquisado; não prova que a pessoa ou família histórica não existiu.

## Resultados, tentativas anteriores e versões

O [resultado consolidado](conferencia_entrega.json) reúne os 22 scripts distintos aprovados, os caminhos dos registros de execução e as assinaturas dos brutos e parquets preservados. As execuções foram sequenciais, em três lotes documentados:

- [Primeiro lote](bateria_01.json): onze scripts passaram; o teste de integridade parou na regravação do arquivo. O relatório mantém `aprovado=false`.
- [Continuação com dez testes antigos](bateria_02.json): todos passaram.
- [Repetição isolada da integridade](bateria_03.json): passou após completar o exemplo fictício e separar as pastas de saída.
- [Testes Python](bateria_python.json) e [registro da execução](testes_python.log): 32 testes, zero falhas e zero erros.

A consolidação usa a última execução fornecida de cada script, na ordem cronológica dos três lotes acima, e exige saída zero e assinaturas compatíveis com a entrega. Confere também os sete arquivos de testes Python. Os testes usam exemplos pequenos reais e fictícios: verificam que as decisões são aplicadas corretamente e que alterações indevidas são recusadas. Passar nesses testes não resolve a falta de informação histórica dos casos bloqueados.

As demonstrações anteriores de falha e as primeiras tentativas ficam separadas dos resultados aprovados. Uma tentativa do teste de PE comparou uma tabela antes e depois de o próprio teste criar um índice automático de consulta; a diferença era esse índice, não os dados. O ponto da cópia foi corrigido, mantendo a comparação estrita. Outro teste antigo de integridade montava uma tabela fictícia sem todos os campos exigidos pela nova conferência de famílias; o exemplo foi completado sem remover verificações. Em uma tentativa seguinte, o Windows recusou a regravação de um relatório recém-criado pelo mesmo teste. Os cenários receberam pastas próprias, preservando todos os diagnósticos; não se comprovou qual processo impediu a abertura, portanto não se atribui a causa ao sincronizador. Nenhuma dessas interrupções foi uma queda nativa de memória do R.

Exemplos auditáveis dessas etapas: [diagnóstico do teste PE](antes_distrito_pe_diagnostico.log), [esquema incompleto do teste antigo](antes_test_integridade_amostra_127.log), [ramo de atividade e geografia antes da correção](antes_geografia_ramo_antes.log) e [geografia nos resultados definitivos antes da correção](antes_geografia_definitivos_antes.log). A lista completa de registros anteriores está no resultado consolidado; os arquivos com prefixo `antes_` não são apresentados como aprovação final.

O [índice de arquivos](indice.json) registra tamanho e assinatura SHA-256 da versão entregue. A assinatura permite detectar mudança nos bytes, inclusive em finais de linha; não comprova, por si só, a identidade histórica das famílias. As provas antigas não tiveram suas assinaturas atualizadas para parecer contemporâneas às mudanças posteriores.

## O que não foi publicado ou reconstruído

As mudanças desta rodada são de código, decisões localizadas e auditoria. Não houve importação de pessoas da amostra maior, substituição dos arquivos completos, recálculo de pesos ou nova publicação. Os casos sem informação suficiente continuam visíveis e bloqueantes. As categorias de pendências se sobrepõem; suas contagens não devem ser somadas como pessoas distintas.
