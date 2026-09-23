# Publicar as correcoes tecnicas dos scripts de 1960

Autorizacao expressa do usuario em 23/09/2026: fazer commit e push da rodada de correcoes dos scripts. Destino conferido: branch `main`, remoto `origin` em `ipea/censobr_prep_data`.

Escopo: codigo, testes, nota narrativa, plano de implementacao e caderno de evidencias ja concluidos. Nao executar R/targets, reconstruir dados, recalcular pesos, criar release ou mudar regras de tratamento dos casos historicos. Excluir as alteracoes preexistentes em `censobr_prep_data.Rproj` e `renv.lock`.

Conferencia: comparar as 39 entradas do indice com os arquivos locais e com os objetos preparados no Git. Para textos, aceitar exclusivamente a normalizacao de finais de linha prevista no proprio indice; o baseline RDS deve conservar seus bytes. Confirmar codigo zero nas seis ultimas baterias pertinentes e ausencia de dados completos no commit. Preservar logs originais, inclusive espacos finais e tentativas interrompidas.

Sequencia: selecionar caminhos explicitos; conferir conteudo staged e hashes; verificar o remoto; criar commit; fazer push normal para `origin/main`; comparar o hash remoto com o commit local. Nao forcar push, reescrever historico ou incluir alteracoes alheias se houver divergencia.

As frases de ausencia de commit/push na nota da implementacao e no caderno descrevem o momento anterior a este pedido. Esses registros e suas assinaturas permanecem intactos. Esta publicacao do codigo nao homologa a base completa nem libera a publicacao de dados.
