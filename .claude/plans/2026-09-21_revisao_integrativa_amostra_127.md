# Revisão integrativa das três rodadas de 1960

**Status:** CONCLUÍDO — parecer integrativo entregue; dados e código não homologados. **Data:** 2026-09-21.

## Pedido e escopo

Conciliar diagnóstico/documentos iniciais, auditorias com bloqueios preventivos e double check. Produzir um parecer único, distinguir conclusões substituídas das vigentes, verificar interfaces ainda descobertas e enumerar o que não foi avaliado. É revisão, não implementação de correções.

## Limites

Sem R/Rscript, targets, recalibração, novas variâncias, reprocessamento/publicação ou alterações em código de produção/guias/parquets. Não mexer nos projetos vizinhos. Preservar mudanças anteriores e do usuário. Scripts de diagnóstico novos somente em `tmp/integrativa127/`, sem importar código R ou executar seus efeitos laterais.

## Entregas previstas

- [x] `references/microdata_1960_amostra_127_revisao_integrativa.md`: síntese canônica das rodadas, registro reconciliado de achados, estado código/dados/testes, critérios de encerramento e limites.
- [x] Ponteiros documentais mínimos nos relatórios anteriores, preparação25, compilação, pendências e `CLAUDE.md`; sem apagar o histórico nem reescrever o pipeline.
- [x] Evidências quantitativas novas e verificadores em diretório isolado; escopo e limites registrados no parecer e nos resultados.

## Divisão e verificações

- [x] Revisor de validação: interfaces 127/25/compilado e falsas aprovações dos validadores finais.
- [x] Revisor de integridade: leitura, reparos, códigos, flags e invariantes que os auditores anteriores não cobriram.
- [x] Revisor de interfaces: DAG por inspeção, schemas, exportação, dicionários e diferenças entre código alterado e produtos gravados.
- [x] Principal: reconciliar afirmações/números das rodadas, fontes/universos, suporte de calibração e limites do desenho.
- [x] Rever achados novos sem promovê-los a decisões automáticas; rechecagem independente das grades e dos 9.395 leitores, e correção da cobertura domiciliar com join completo.
- [x] Conferir links e consistência do parecer; registrar explicitamente testes não executados e verificações parciais.

## Resultado e ressalvas

Achados novos incorporados: controle de leitores25 com universo errado compartilhado com validador; 220 referências pessoais omitidas no compilado e tabela domiciliar ausente; reparo951431 que insere zero; domicílio127134 sem lista de pessoas; dicionário não nacional/pré-cast; exportação sem aprovação; dependência de schema não declarada e renomeação sem checar sucesso (riscos estáticos).

Leitura pessoal127 reproduzida; grades/idades ignoradas rechecadas; transferência de 17/23 campos fonte127→compilado passou nas 11 UFs. Compilado→final por valores passou somente RR; tentativa nacional inconclusiva, explicitamente não aprovada. As variâncias calibradas permanecem adiadas. Nenhum R/Rscript, targets, peso novo, guia, parquet ou código de produção alterado nesta rodada.

## Critério de conclusão desta tarefa

Parecer integrativo entregue com divergências resolvidas na documentação e pendências únicas, não redundantes. Isso não equivale a homologar os microdados ou afirmar que nenhuma outra falha existe. A implementação e sua aprovação exigirão tarefa própria e autorização de execução segura de R.
