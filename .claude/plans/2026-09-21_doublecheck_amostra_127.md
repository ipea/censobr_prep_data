# Segunda revisão independente — amostra de 1,27% de 1960

**Status:** REVISÃO CONCLUÍDA; correções e homologação pendentes. Solicitada pelo usuário em 21/09/2026 após a primeira auditoria. Parecer em `references/microdata_1960_amostra_127_doublecheck.md`.

## Escopo

Conferir as três frentes (integridade, validação e desenho), os próprios patches e métodos de auditoria, a força da evidência e as lacunas não examinadas. Incluir o impacto no compilado de 1960. A revisão não autoriza novas alterações no pipeline, nas decisões de tratamento ou nos parquets.

## Limites

Não executar R/Rscript/targets, recalibrar, calcular novas variâncias calibradas, publicar, modificar pesos ou projetos vizinhos. Preservar todas as alterações anteriores, inclusive as do usuário em Rproj e renv.lock. Usar verificadores Python isolados em `tmp/doublecheck127/` quando necessários; guardar o parecer em `references/microdata_1960_amostra_127_doublecheck.md`.

## Verificações

- [x] Revisão independente das validações R/Python, testes e significado de zero/NA; erros semânticos compartilhados e guarda contornada por agregação identificados.
- [x] Releitura de casos de referência no bruto de 25%: 15 boletins em cinco UFs, sem divergências bruto/intermediário nos campos examinados.
- [x] Levantamento de decisões não examinadas: 150 famílias reconstruídas, 373 conviventes, reparos selecionados, chaves e correção PR; demais decisões explicitamente abertas.
- [x] Fonte histórica para cor, universo etário e domiciliar; páginas relevantes conferidas visualmente. A primeira revisão errou a regra de idade ignorada na tabela 40.
- [x] Revisão da evidência do desenho; ranks/corridas recalculados em Python, sem atualizar figuras. Cadastro/estratos históricos não certificados.
- [x] Calibração: 543 margens definitivas e 184 preliminares verificadas com pesos gravados; nenhuma nova variância/peso calculado. Verificador rechecado por outro agente.
- [x] Impacto no compilado rastreado: 179 pessoas em famílias reconstruídas nas onze UFs; limites dos bloqueios e contradições documentais enumerados.
- [x] Parecer entregue por gravidade, com confirmações, itens não avaliados e recomendações; sem declarar aprovação integral.

## Resultado e limites

Produção preservada; nenhum R/Rscript/targets executado. Novos achados exigem reconciliação de famílias, correções semânticas da validação e de proveniência dos controles domiciliares. Os testes R seguem sem execução por causa dos crashes relatados; a causa do crash não foi diagnosticada nesta revisão. Variâncias calibradas permanecem adiadas. O parecer enumera a cobertura parcial de decisões manuais, do pipeline de 25%, das fontes e dos consumidores; não autoriza fusões/exclusões em lote nem reprocessamento.

## Divisão

Revisor independente de validação; revisor independente de integridade; agente principal em fontes históricas, desenho e integração. Não há edição concorrente de arquivos de produção nesta rodada.
