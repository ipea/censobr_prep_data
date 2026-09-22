# Fechamento da investigação de perfis repetidos em HHOLDA

**Status:** AUDITORIA ENTREGUE; integração e463grupos sem comprovação permanecem explícitos. Subtarefa autorizada da investigação dos registros em22/09/2026.

## Estratégia e limites

Reconciliar todos os 1.417 conjuntos ainda sem decisão (2.836 linhas), incluindo as duas linhas corrompidas que a busca anterior de cartões não indexava. A lista anterior é somente o inventário de entrada; seus arquivos de origem e sua atualidade serão conferidos. Nenhum manifesto de produção, arquivo bruto, parquet ou código R será alterado por esta subtarefa.

Não tratar igualdade de respostas pessoais como prova de duplicação. Conferir no gzip25 a família inteira, quantidades, ordens e estrutura; confrontar cartão, geografia e composição com HHOLDA após decisões já aprovadas. Uma multiplicidade só será proposta se todos os perfis e sua quantidade puderem ser conciliados sem apagar respostas diferentes ou colapsar pessoas de contextos distintos. Preservar múltiplos filhos com respostas iguais quando a fonte documentar múltiplos registros. Se a fonte não existir, estiver danificada ou divergir, registrar a incerteza concreta sem renomeá-la como solução.

## Arquivos e validação

- Auditoria em `references/auditoria_pendencias_duplicatas_1960.py`, reutilizando leitores literais já testados.
- Testes em `references/test_auditoria_pendencias_duplicatas_1960.py`, com adversários: irmãos iguais, diferença fora do perfil, código inválido, grupo incompleto, cartão/ordinal incoerente e falta de fonte.
- Piloto com poucos grupos reais antes da varredura integral.
- Resultados em novas pastas de `tmp/fechamento_registros_1960_20260922/duplicatas/`, com evidência literal e ações candidatas linha a linha. Nenhuma promoção automática para produção.
- Baixo consumo: leitura sequencial de gzip, SQLite para índice127, uma UF por vez, conferência de hashes antes/depois. Não executar R, targets ou pesos.

## Resultado e refinamentos autorizados durante a investigação

O índiceSQLite não precisou ser criado: três leituras sequenciais deHHOLDA selecionam somente os contextos necessários, em baixa memória. A varredura de1.417grupos passou após o pilotoPB. Foram produzidas três classes disjuntas:199grupos exatos;447com grupo inteiro por24campos e diferençaV21600/63 preservada;308com a mesma evidência e atributos domiciliares divergentes preservados. As classes adicionais foram solicitadas/revisadas pela integração, sem declarar equivalência semântica00/63. Município/distrito/situação/espécie/chave permanecem invariantes.31testes passaram.

Total954grupos/1.908linhas,490remoções e3restaurações propostas;463grupos/928linhas e127exclusões históricas sem prova permanecem no inventário residual enumerável, sem aprová-los por simples renomeação. Nota detalhada e caminhos em `references/pendencias_duplicatas_1960_20260922.md`.

Subtarefa adicional solicitada pela integração: revisão independente dos17reparos de texto. Releitura literal das fontes e enumeração de todas as bijeções nos15grupos; todos passaram, com apenas uma bijeção por grupo e nenhum campo válido alterado. Script `references/revisao_independente_reparos_1960.py`. Nenhum manifesto de produção ouR foi editado nesta subtarefa.

## Teste R entregue à integração, sem execução nesta subtarefa

Preparar `references/test_novas_duplicatas_1960.R`: combinar em CSV temporário as decisões atuais com os três conjuntos candidatos, conferindo sobreposições sem duplicá-las. Primeiro ler e testar somente as duas linhas PB164631/164633; depois as6.451linhas abrangidas pelos manifestos conciliados. Conferir2.736remoções e3.715retenções, respostas/textos/V216 preservados, ordem independente, erros de entrada incompleta/adulterada e as três restaurações contra o registro histórico de exclusões. Reabrir somente parquets auxiliares emtmp e conferir hashes das fontes. O agente de integração executará o arquivo exclusivamente pelo runner isolado; este agente não executaráR.
