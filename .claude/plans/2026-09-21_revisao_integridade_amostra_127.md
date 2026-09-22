# Revisão da integridade e validação da amostra de 1,27% de 1960

**Status:** AUDITORIA E PATCHES ENTREGUES — reconciliação dos registros e execução R pendentes. Escopo solicitado pelo usuário em 21/09/2026.

## Escopo e limites

1. Conferir vínculos de família e exclusões como duplicatas contra o bruto e, onde disponível, a amostra de 25%. Separar evidência, hipótese e caso não resolvido.
2. Reformular a validação: preservar a grade oficial, contar observações, distinguir ausência de suporte de quesito não reconstruído e impedir que códigos desconhecidos ganhem sexo ou universo por exclusão lógica.
3. Aprofundar o desenho: documentar as duas fases, a reconstrução dos estratos e a natureza estimada dos controles das 17 UFs. Manter os referenciais disponíveis; não substituir por supostos totais de universo inexistentes.

O usuário adiou o cálculo das variâncias após calibração. Nenhum R/Rscript será executado: houve crashes nativos repetidos. Não executar targets, regenerar parquets, mudar pesos materializados, publicar ou alterar projetos vizinhos. `censobr_prep_data.Rproj` e `renv.lock` já estavam modificados e serão preservados.

## Ordem e arquivos

- [x] Auditoria reproduzível, independente em Python, de vínculos e duplicatas: `references/auditoria_vinculos_duplicatas_1960.py` e relatório próprio. PB conferida primeiro, depois todas as ocorrências delimitadas, sem reescrever o bruto.
- [x] Auditoria independente da validação: `references/auditoria_validacao_1960.py`, relatório próprio, regressões em memória e smoke check em RO antes da grade regional/UF completa.
- [x] Mudanças pontuais em `R/microdata_1960_amostra_127.R`: validações de 1965 e definitivos; salvaguardas de integridade nos vínculos/exclusões, sem introduzir vínculos por conjectura. Implementação R ainda não executada.
- [x] Documentar decisões de vínculos/reparos que ainda precisam de evidência. A ambiguidade não foi apagada por uma escolha arbitrária.
- [x] Nota metodológica própria e correções pontuais em `references/microdata_1960_amostra_127_desenho_amostral.md`.
- [x] `references/auditoria_classificacao_pastas_1960.py`: confronto das regras e das fontes. Correção pontual em `references/figuras/desenho_amostral_1960.R` da subtração repetida de 200 no código de Alagoas: o legado já tem 2306. Esse script não faz parte do DAG; não foi executado e as figuras não foram regeneradas.
- [x] Atualizar preparação, consistência, pendências e aviso de estado no `CLAUDE.md` para separar o estado materializado das correções ainda não executadas.

## Dependências e impacto

O arquivo R é consumido pelos targets da amostra de 1,27%; calibração também é reutilizada pela amostra de 25%. Não alterar a matemática compartilhada de calibração. Mudanças na validação invalidariam somente seus targets e consumidores; mudanças em leitura/deduplicação/vínculos invalidariam o encadeamento posterior da amostra de 1,27% e a compilação de 1960. Nenhum target será invalidado manualmente. Não alterar `_targets.R`, funções compartilhadas, schemas ou dicionários de parsing nesta rodada. CSVs de validação poderão ganhar colunas de diagnóstico; os parquets existentes não mudarão nesta sessão.

## Verificação e critério de entrega

- [x] Demonstrar os defeitos com registros existentes e casos mínimos, antes da edição.
- [x] Executar auditorias Python contra os artefatos atuais e conferir totais/resultados conhecidos. As três auditorias foram reconferidas pelo agente principal.
- [x] Revisar diff e consumidores; preparar testes R isolados. Delimitadores lexicais balanceados nos arquivos R revisados/testes, sem equivaler a parsing R. `git diff --check` sem erros; testes R não executados.
- [x] Declarar explicitamente: verificação independente não equivale a executar a implementação R.
- [x] Registrar como pendente a execução R autorizada em UF pequena, seguida dos targets afetados e conferência dos parquets. A base NÃO está corrigida.

## Divisão do trabalho

Agente de preparação: script/relatório de vínculos. Agente de consistência: script/relatório da validação. Agente de desenho: nota metodológica e documento original do desenho. Agente principal: código R, testes de regressão, documentação de preparação/consistência/pendências e integração.

## Decisão de integridade durante a investigação

A amostra de 25% corrobora dois filhos legítimos excluídos na PB (linhas 168805–168806) e oito boletins coletivos próprios para 16 pessoas de MG anexadas à pasta anterior. A revisão não trocará a heurística refutada por outra hipótese. Enquanto não houver uma reconciliação versionada e testada, a deduplicação salvará os candidatos e interromperá antes de excluir; a reconstrução salvará os órfãos sem chefe/cônjuge e interromperá antes de anexar ao anterior. São bloqueios preventivos deliberados, não a resolução das pendências. As tabelas existentes continuam disponíveis para a auditoria da validação.

Os testes isolados terão diretório de diagnóstico parametrizável para não sobrescrever CSVs de produção. A execução desses testes em R permanece pendente. Os dois bloqueios afetam somente uma futura reconstrução da amostra de 1,27%, não iniciam processos nem invalidam targets nesta sessão.

## Resultados já conferidos

- Auditoria Python: 1.008 anexadas, 70 conflitos geográficos; 497 pessoas com perfil exato em 25% (135 com cartão já existente em HHOLDA, 362 com cartão preservado só em 25%). Há 61 divergências V116 nos vínculos diretos, parte explicada por correções geográficas conhecidas — não receberam bloqueio indiscriminado.
- Deduplicação: 2.238 exclusões corroboradas; 28 perfis exigem 31 restaurações de multiplicidade. Não desfazer toda a deduplicação. Os intermediários de 25% foram usados como outra cópia dos registros, não como verdade sem erros ou fonte estatisticamente independente.
- Reparos 387715 e 387853: correspondentes de 25% sustentam V218=00 e V219=3, enquanto o reparo atual deslocou o dígito. O CSV de correções permanece inalterado até incorporar decisões com proveniência e testar.
- Testes R preparados: `references/test_integridade_amostra_127.R` e `references/test_validacao_amostra_127.R`; não executados.
- A conferência independente de pastas encontrou zero divergências entre moda e `any()` em cada fonte, mas sete entre a classificação do script legado e a base atual: duas por ajuste municipal duplicado em AL e cinco por composição urbana/rural diferente. A correção do ajuste AL no script de figuras é justificada por essa verificação anterior em pequena escala; os percentuais/figuras históricos não serão tratados como recalculados.
- Validação Python: 2.220 células regionais de 1965 por peso (456 não reconstruídas); 1.932 células definitivas por peso (81 sem observações, 68 com publicado positivo). A revisão da grade antiga completa corrigiu a primeira contagem parcial: 63 omissões, 52 positivas, incluindo três da tabela 33 além das 60 inicialmente apontadas nas tabelas 7/34/37.

## Continuação necessária

1. Incorporar decisões versionadas de multiplicidade e vínculos com proveniência, preservando originais; conferir os gzip de 25% nos casos que dependem desses intermediários. Resolver ou manter explícitos os casos sem evidência. Só então substituir os bloqueios preventivos por tratamento aprovado.
2. Rever os dois reparos da BA no registro de correções, preservando a divergência V216 não explicada pelo deslocamento.
3. Confirmar harmonização de V206=8 com a tabela definitiva 37, recorte domiciliar V102 e política de idades ignoradas; os diagnósticos atuais tornam essas limitações visíveis, não as encerram.
4. Com nova autorização para R e ambiente estável, executar os dois testes isolados em `tmp/`, comparar R com as auditorias Python, depois os targets afetados e os parquets. Não iniciar pelo pipeline completo.
5. Investigar as cinco diferenças de composição de pastas; corrigir o agrupamento das corridas no script de investigação e refazer seus diagnósticos/figuras quando R puder ser retomado.
6. Variâncias após calibração permanecem fora desta rodada, por decisão expressa do usuário.
