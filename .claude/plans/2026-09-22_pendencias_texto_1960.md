# Auditoria das pendências de texto de 1960

**Status:** Auditoria CONCLUÍDA; extensão geográfica implementada e em validação pelo coordenador.

Subtarefa do fechamento integrativo. A auditoria não modifica produção; a extensão R limitada, autorizada depois, está descrita ao final. Nenhuma fonte bruta, parquet, peso ou targets foi alterado por esta frente.

1. Inventariar todas as linhas de HHOLDA com falhas estruturais/códigos inválidos e reconciliar com as decisões de texto vigentes.
2. Para cada decisão, registrar campos antes/depois e dano remanescente. Conferir os boletins correspondentes da fonte25 quando chave íntegra permite busca, preservando divergências entre cópias.
3. Investigar explicitamente 855822, 951432, 951433, reparos antigos e os códigos V216=00/63. Não promover coincidência parcial a identidade nem completar campos por hipótese.
4. Conferir páginas pertinentes das publicações sobre universos/idade ignorada, sem transplantar convenções entre fontes.
5. Entregar script reproduzível, testes pequenos, inventário em pasta nova de tmp e nota narrativa auditável. Nenhuma exclusão por conveniência e nenhuma execução R.

Validação: testes sintéticos de leitura, dano e divergências; piloto com poucos casos antes do inventário completo; hashes antes/depois das fontes. Scripts e relatórios desta auditoria não integram o pipeline.

## Extensão autorizada: município dos dois registros do Paraná

Autorizada pelo coordenador após a auditoria, em 22/09/2026. Alterar somente o bloco geográfico de `finalize_1960_amostra_127`, acrescentando parâmetros opcionais para manifesto e fontes. Um manifesto versionado em `read_guides` registra as duas fontes, seus hashes e os oito textos dos grupos correspondentes. O finalizador deve verificar essas fontes, as linhas e o vínculo familiar antes de derivar `code_muni_1960 = 7240` para o domicílio. A propagação à pessoa permanece a já existente; `V116` não é preenchido nesses dois registros. O diagnóstico identifica a derivação e permite localizar a prova pelo número da linha, sem novas colunas de publicação.

Criar primeiro teste R de microlote: dados e fontes corretos; fonte, linha, texto ou vínculo incompatíveis; falta de manifesto; reexecução sem mutar a entrada. Não executar R nesta subtarefa. O coordenador integra as dependências em targets e executa o teste isolado. Nenhuma outra inferência municipal ou regra de nacionalidade será alterada por esta subtarefa.

Resultado da auditoria: inventário de 124 suspeitas, decisão homogênea dos 47 candidatos, 33 reparos propostos em 40 campos e 14 casos sem aprovação por essa regra; dois registros PR com prova geográfica separada. As três linhas totalmente corrompidas foram pesquisadas nas 17 fontes preservadas, sem identidade demonstrada. Vinte e dois testes Python passaram. Nota narrativa: `references/fechamento_texto_registros_1960_20260922.md`.

Implementação geográfica: manifesto versionado, verificação de fonte/linha/texto/geografia/composição e comparação de todas as respostas ao parser do literal127. O primeiro teste coordenado detectou criação de autoíndice na entrada; a consulta foi isolada por cópia. Três vínculos candidatos ao cartão887255 foram entregues para conferência independente, sem promoção por esta frente. Não foram introduzidas colunas novas no esquema publicado.
