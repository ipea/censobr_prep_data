# Conferências integrais de 1960 — plano da frente documental

Data: 23/09/2026. Execução autorizada pelo usuário no plano integral; esta frente não executa R nem modifica o pipeline.

1. Reexaminar a definição do universo do quadro 5 nas fontes do IBGE, ampliando a busca documental e separando idade declarada ignorada de idade danificada.
2. Decompor as 86 células incompletas da tabela 7 por peso nas 17 UFs de 25%, lendo somente colunas necessárias e pessoas em lotes. Confrontar as contagens com o relatório integrado existente.
3. Conferir os códigos de aluguel e as demais lacunas domiciliares, documentando o que é recuperável e o que permanece não identificável.
4. Registrar páginas, URLs, quantidades e recomendações mínimas em nota própria; entregar ao executor central os pontos que requerem implementação/testes.

Arquivos de trabalho exclusivos: `references/fechamento_integral_1960_conferencias*` e `tmp/fechamento_integral_1960/conferencias/`. Nenhum parquet, referência histórica ou script de produção será sobrescrito nesta frente.

## Ampliação autorizada: limites T7 na saída do validador

Após o recálculo municipal de MT/PR/MG pelo agente principal, o suplemento foi
regenerado nas 17 UFs com novo índice/relatório, preservando a primeira execução
como cronologia. O agente principal autorizou ampliar a frente para uma alteração
isolada em `R/microdata_1960_validacao.R`, sem executar R nesta frente.

- Acrescentar `valor_minimo` e `valor_maximo` à comparação T7, iguais à contribuição
  conhecida e à soma conhecida+indeterminada, somente quando os pesos relevantes
  forem finitos/não negativos e os dois contadores de cobertura forem zero.
- Deixar os dois limites NA para cobertura insuficiente, pesos inválidos,
  tabela não T7 ou célula não reconstruída. Manter os status e as diferenças
  existentes; os limites não são intervalos de confiança ou variâncias.
- Detectar peso negativo nos mesmos contadores de pesos inválidos do tabulador
  domiciliar. Sem isso, cancelamentos poderiam mascarar um limite incorreto.
- Reutilizar as métricas já somadas no Brasil pelo validador compilado; nenhum
  ajuste em R/microdata_1960.R, no ramo127, nos pesos, fontes ou manifestos.
- Criar teste sintético sem Arrow em `fechamento_integral_1960_conferencias_test_t7.R`:
  casos conhecidos/incertos, pesos pessoais distintos, domínio vazio, arquivo
  ausente, falta de lista/cartão, NA/Inf/negativo relevante, peso inválido fora
  do universo, soma potencialmente transbordada e demais tabelas preservadas.
  O executor central roda antes e depois; a edição de produção aguarda a falha
  anterior. Depois, ele regenera o relatório das 17 UFs, e Python reconfere as 204
  células contra os 34 parquets já estabilizados.

Dependências afetadas: relatórios de validação25 e compilada, inclusive a assinatura
de código que protege a conferência técnica de publicação. Isso invalida relatórios
anteriores para essa conferência; não altera parquets de microdados ou pesos. Os
targets de validação/publicação não serão executados por esta frente.
