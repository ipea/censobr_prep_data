# Publicar a revisão residual e separar as próximas pendências

Autorização: pedido expresso do usuário em 23/09/2026 para commit e push, seguido de explicação sobre os scripts R e listagem de pendências.

Escopo: publicar código, manifestos, testes, investigação e documentação já concluídos. Não executar R, reconstruir dados, recalcular pesos, criar release ou implementar novos consertos nesta etapa. Preservar e excluir do commit as alterações anteriores em `censobr_prep_data.Rproj` e `renv.lock`.

Sequência: conferir arquivos e assinaturas da entrega; examinar branch/remoto; preparar somente os arquivos pertinentes; verificar o conteúdo staged e os bytes das provas; criar commit e fazer push normal para `origin/main`; conferir que o hash remoto é o mesmo. Se houver divergência remota ou bloqueio, não forçar o push nem modificar histórico.

A resposta deve distinguir correções R já implementadas, consertos de software que podem ser preparados sem presumir fatos históricos e casos que ainda exigem evidência ou decisão metodológica. Os testes anteriores aprovados não são homologação dos dados completos. Planos e cadernos das rodadas anteriores permanecem como registros históricos.

Conferência anterior ao commit: 156 arquivos selecionados, sem brutos/parquets nem Rproj/renv.lock. As 129 entradas do índice de auditoria foram comparadas com o conteúdo preparado no Git. A única diferença encontrada era normalização de fim de linha em `resolucao_residuais_duplicatas_disposicoes.json`: ampliada a regra `-text` já existente para preservá-lo literalmente. Somente a entrada de `.gitattributes` no índice foi atualizada para essa alteração de empacotamento (SHA anterior `04eb487ae3ecec76d5da16009fd96ed92d000ef542d23b6efa1fa217cd7bdd02`; novo `f7fea9752918038d32f3b2f190a121bac1ae40e89a133571e1f79c4b65aa5a90`). Não se alteraram provas históricas, respostas, código R ou resultados dos testes. Os 17 avisos de espaços finais estão exclusivamente em logs originais, preservados para não invalidar suas assinaturas. O verificador deve reconhecer CRLF como final de linha, sem normalizar os arquivos de evidência.
