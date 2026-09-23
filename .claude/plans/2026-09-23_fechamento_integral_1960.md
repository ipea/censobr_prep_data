# Fechamento integral de 1960

Data: 23/09/2026. Status: ENTREGA TÉCNICA ENCERRADA COM BLOQUEIO FACTUAL DA BASE
NACIONAL; os quatro passos não foram declarados integralmente concluídos.
Execução autorizada expressamente pelo usuário, sem pedidos de aprovação rotineira.

## Objetivo e limites

Executar os quatro passos solicitados: resolver registros, fechar conferências,
reconstruir os arquivos e recalcular os pesos necessários, preparar a entrega.
Não encerrar após um piloto. Os testes pequenos são proteção interna antes das
execuções integrais, não o resultado final pretendido.

O usuário autorizou prosseguir sem confirmações rotineiras. Essa autorização
não transforma evidência insuficiente em certeza: não excluir pessoas, inventar
respostas, escolher famílias ou atribuir geografia para forçar o processamento.
Se restar uma impossibilidade factual, demonstrá-la por caso e concluir tudo que
não dependa dela. Variâncias calibradas permanecem fora da implementação adiada.
Não publicar release de dados nem alterar o repositório consumidor.

## Sequência

1. Reexaminar todas as pendências, em três frentes paralelas: duplicatas,
   vínculos/textos/geografia e conferências documentais. Conciliar a cobertura
   nominal com o inventário anterior; testar provas novas, não repetir conclusões.
2. Integrar somente decisões sustentadas por textos originais, multiplicidades
   e identificação verificável. Validar antes/depois, incluindo contraprovas.
   Novas decisões entram em manifestos e mantêm a origem de cada correção.
3. Executar o caminho real da amostra127 em área separada; relatórios e produtos
   novos ficam em `tmp/fechamento_integral_1960/`. Acrescentar saída configurável
   à detecção se necessário para não sobrescrever o relatório original.
   Recalcular pesos somente depois de estabilizar registros e universos.
4. Aproveitar os 34 arquivos completos da amostra25 já recalibrados quando suas
   entradas e regras continuarem válidas; não refazer trabalho idêntico sem motivo.
   Executar as conferências nacionais novas e medir o esquema nas colunas reais
   completas, nunca definir tipos à mão ou chamar dados antigos de corrigidos.
5. Conferir integridade, cobertura, contagens, pesos, procedência e assinaturas;
   gerar caderno auditável e explicação narrativa com exemplos antes/depois.
   Distinguir produtos finais, diagnósticos e qualquer limitação irredutível.

## Arquivos e execução

- Frentes: `references/fechamento_integral_1960_{duplicatas,vinculos,conferencias}*`.
- Produção: somente blocos necessários nos scripts de 1960, seus testes e
  manifestos correspondentes. Não refatorar funções compartilhadas.
- R sequencial, exclusivamente pelo runner isolado com `--windows-arch
  --locale-c`; nenhum `Rscript -e`, alteração de ambiente global ou pacote.
- Não avaliar `_targets.R` indiscriminadamente, invalidar outros anos ou remover
  bloqueios para produzir uma base que não satisfaça suas próprias invariantes.
- Python em fluxo/SQLite e R com liberação de objetos; verificar recursos antes
  de execuções grandes. Não encerrar processos de outras tarefas.
- Preservar HHOLDA, os parquets atuais, `renv.lock` e Rproj. Registrar hashes.

## Validação

Cada alteração terá teste que distingue erro anterior de comportamento correto,
mais regressões pertinentes. As novas provas serão relidas independentemente
nas fontes atuais. A execução integral usará os mesmos caminhos de produção,
com saídas isoladas. Falha prevista por falta de prova não será contabilizada
como reconstrução aprovada; tampouco será confundida com crash do R.

## Marco anterior

O commit `fa5c9521fcd42154c72d8e6de08388276789fefc` foi publicado e confirmado
em `origin/main` antes desta investigação. Rproj e renv.lock ficaram intactos.

## Ampliação da conferência de pendências — durante a execução

A lista histórica `references/microdata_1960_pendencias.md` registra também
4.916 habitantes faltantes na soma municipal do Paraná, dois pares de distritos
gaúchos com numeração ambígua e oito pares sem nome. Estes pontos não podem ser
omitidos do fechamento. A soma do Paraná afeta a distribuição dos pesos25:
conferir os 162 municípios contra as 21 páginas da Sinopse; se houver correção
comprovada, atualizar somente as células demonstradas e recalcular PR em área
separada, refazendo sua validação e o índice dos arquivos completos. Para os
distritos, procurar evidência documental adicional e separar nome ausente de
identificador ou geografia efetivamente corrompidos. Não reduzir limiares de
decisão amostral só para fazer um caso passar.

Foi obtida a cópia pública CEM de 2012 em SAV. Ela será comparada integralmente
com HHOLDA antes de se decidir se acrescenta informação; origem institucional
diferente não prova independência dos registros.

Na leitura de Itutinga, apareceu soma municipal inconsistente em Itumirim.
A varredura aritmética das2.770linhas do guia revelou cinco divergências
fora do Paraná: Alpinópolis, Itumirim, Jardinópolis, São Bento do Sul e Coxim.
Conferir as publicações antes de alterar números; recalcular também qualquer
UF25 cujo controle efetivamente mudar. Acrescentar à função de pesos uma guarda
curta para totais municipais inconsistentes, negativos ou chaves repetidas,
sem mudar solver, regras de colapso ou admitir imputação automática.

## Resultado executado e verificado

- Investigação nominal de todas as listas conhecidas, incluindo as cinco pastas
  do desenho, os distritos pendentes e a cópia pública CEM. Esta última não
  acrescenta identificação independente aos registros danificados.
- Nove cartões novos/23 pessoas já existentes, reparo MG405458 e preservação do
  par paulista incorporados. Totais dos manifestos: 41 cartões/103 pessoas,
  38 reparos, 6.463 decisões de repetição. Provas operacionais portáteis,
  revisão independente de 410 vínculos de hash e inventário nominal final.
- Guia municipal: 12 linhas corrigidas; Paraná162 conferido nos fac-símiles,
  cinco casos adicionais e aritmética das2.770linhas. Baseline histórico portátil.
- MT/PR/MG recalculados de fato e conferidos independentemente. Novo índice dos
  34 arquivos completos, com as outras14UFs preservadas. Relatório2040 completo
  e limites T7 implementados no R, conferidos nas204comparações domiciliares.
- Reconstrução127 final executada desdeHHOLDA: 174.467cartões/899.859registros
  pessoais após correções. Parada antes de excluir as459ocorrências extras dos
  457grupos sem decisão. Não houve novo peso127 nem base nacional certificada.
- 33scriptsR passaram em suas execuções finais; teste publicação com31recusas.
  Recuperação41 integral passou após ampliar prazo300s. Intercorrência Arrow
  I/O1 resolvida localmente comI/O2; não reapareceu o crash nativo de memória.
- Originais, 34parquets, Rproj, renv e esquema reconferidos porhash. Nenhum
  commit/push/release novo. Sem alteração do repositório consumidor.

Entrega narrativa: `references/fechamento_integral_1960_entrega.md`.
Índice com SHA-256 por arquivo: `references/fechamento_integral_1960_entrega.json`.
As pendências factuais, a medição nacional dos15campos de procedência e as
variâncias anteriormente adiadas não foram convertidas em conclusão favorável.
