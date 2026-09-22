# Implementação da conferência completa de 1960

**Status:** CONCLUÍDO quanto ao código e à preparação dos testes — execução funcional suspensa. Implementação solicitada pelo usuário em 22/09/2026.

## Escopo e limites

Corrigir os relatórios das duas amostras e da compilação, preservando todas as comparações esperadas, calculando os totais pessoais ausentes e separando zero observado, cálculo não implementado e classificação incompleta. Corrigir apenas as regras de comparação já documentadas no parecer integrativo. Não executar R/Rscript, targets, calibração, variâncias, exportação ou publicação. Nenhum parquet, peso, vínculo, duplicata ou guia de leitura será alterado. As guardas de integridade existentes permanecem.

## Arquivos e ordem

1. Preparar testes pequenos em `references/test_validacao_1960.R` e atualizar `references/test_validacao_amostra_127.R` antes das respectivas implementações. Rondônia rural, totais pessoais, idade ignorada versus danificada, pesos ausentes e referência zero são casos obrigatórios.
2. Em `R/microdata_1960_amostra_127.R`, corrigir a comparação definitiva e os erros conhecidos da preliminar; tornar explícitas as limitações de classificação e impedir duplicações do gabarito antes de agregar.
3. Acrescentar em `R/microdata_1960_validacao.R` somente cálculos de tabulação e conferência reutilizados pelos validadores de 25% e compilado. Adaptar `R/microdata_1960_amostra_25.R` e `R/microdata_1960.R` apenas nas funções de validação para usar os caminhos recebidos, guardar a grade oficial inteira e publicar contagens/status, sem arredondar as somas antes da comparação.
4. Registrar a entrega e os testes ainda não executados em uma nota auditável e atualizar o aviso de estado em `CLAUDE.md`.

## Contrato analítico

- Grade pessoal completa: tabelas 32, 33, 34, 37 e 40, homens e mulheres. Na compilação completa, 1.566 linhas; na amostra de 25%, 918 por peso. Totais das tabelas 33/34/37 são calculados diretamente sobre presentes, não preenchidos com zero.
- Domicílios na amostra de 25%/compilada: manter também as referências da tabela 7, mas marcar como não calculadas nesta etapa, sem inventar estimativas.
- Soma ponderada e número de registros distinguem falta de observações de falta de cálculo. Pesos não finitos impedem estimativa válida. Referência zero permite diferença absoluta, não percentual.
- Diagnóstico identifica pessoas fora das classificações, sem recodificar os dados. Células potencialmente afetadas não recebem rótulo inequívoco de ausência de observações.
- A tabela 40 inclui idade declarada ignorada conforme a convenção da fonte; idade danificada não recebe esse código. V206=8 entra em pardos somente para comparar com a tabela publicada.
- Controles estimados continuam identificados; concordância com controle não certifica ausência de erro amostral.
- Preservar os nomes de colunas e retornos existentes quando possível; novas colunas são do relatório, não do microdado. Nenhum target novo ou mudança no grafo de `_targets.R`.

## Verificação e limite da entrega

Revisão estática independente, conferência de caminhos/dependências e testes de regressão preparados. As evidências históricas já medidas são referência, não prova de execução do novo R. A proibição de executar R impede completar os testes funcionais nesta sessão; não apresentar o código como homologado nem os relatórios antigos como regenerados. A futura execução começa pelas pequenas bases artificiais em diretório de teste, sem chamar `_targets.R`.

## Entrega e conferências

- Implementados os quatro validadores (preliminar/definitivo de 1,27%, definitivo de 25% e combinado), dois cálculos compartilhados em arquivo próprio e os testes sintéticos. Preservadas as interfaces anteriores; `out_dir` adicional em 25%/combinado permite isolar testes.
- Preparados casos de grade completa, falta de UF, Brasil completo com 28 registros artificiais e Brasil parcial, propagação nacional de pesos/classificações pendentes, entradas incompatíveis, referência zero/duplicada e universos corrigidos. Os testes foram desenvolvidos em paralelo aos cálculos compartilhados e antes da adaptação dos respectivos validadores; não houve ciclo de execução R vermelho/verde, devido à suspensão explícita.
- Reconferidas em leitura independente as 918/1.566 comparações pessoais, 102/174 domiciliares, os caminhos materializados esperados e os exemplos RO/SP. RO: zero rural; SP: 2.080 leitores homens e 2.092 mulheres de idade declarada ignorada, com pesos omitidos 8.153,188102289 e 8.218,110569485.
- Revisão estática independente identificou e corrigiu seleção de coluna lógica em data.table; normalização das chaves vazias também foi revisada. Conferência de delimitadores em seis arquivos R e links locais da nota; `git diff --check` restrito aos arquivos tocados sem erro (avisos de conversão LF/CRLF apenas). Isso não equivale a parse nem execução R.
- Documentação: `references/microdata_1960_validacao_implementacao_20260922.md`; aviso de estado em `CLAUDE.md`. Relatórios existentes continuam antigos. Não alterados calibradores, pesos, variâncias, vínculos, guias, parquets, `_targets.R`, exportação ou projetos vizinhos.

Pendências analíticas mantidas visíveis: tabela 7 em 25%/combinado ainda não calculada; cruzamentos conjugais e aluguel não reconstruídos na preliminar127; inclusão das idades ignoradas nos quadros preliminares 3–5 ainda exige convenção específica da fonte. Contagens de classificação pendente no127 são conservadoras e não somáveis entre células. Nenhuma homologação ou autorização para retomar R foi inferida.
