# Resolver as pendências residuais dos registros de 1960

Status: IMPLEMENTAÇÃO E CONFERÊNCIA DESTA RODADA CONCLUÍDAS em 23/09/2026. O pedido de eliminar todas as pendências não foi integralmente satisfeito: persistem impedimentos históricos sem prova suficiente. Os registros intermediários de progresso abaixo são cronológicos; prevalece o fechamento ao final.

## Objetivo e limite

Implementar as decisões sustentadas pelas provas, aprofundar as alternativas restantes e dar a cada pendência uma disposição verificável. A ordem do usuário autoriza implementação e testes proporcionais; não autoriza inventar fatos históricos nem chamar uma hipótese de correção comprovada. Casos que exigirem fontes inexistentes ou uma escolha metodológica sem fundamento único continuarão identificados como impedimentos reais, não ocultados para terminar o processamento. Variâncias permanecem adiadas. Não publicar dados nem reutilizar pesos por identificadores reconstruídos.

## Base preservada

Partir do commit 790d9d7 e da investigação adicional não commitada. Preservar seus relatórios e provas como registro histórico. Preservar integralmente as alterações preexistentes do usuário em censobr_prep_data.Rproj e renv.lock. Arquivos brutos e parquets completos não serão substituídos enquanto existir impedimento de integridade. Nenhuma alteração no projeto consumidor ou nos projetos de pesquisa vizinhos.

## Sequência

1. Conferir e implementar os dois vínculos demonstrados e os dois pares cuja preservação foi comprovada, com testes antes/depois e provas externas preservadas.
2. Examinar recuperação fora de chave, nacionalidade, Guanabara, geografia, convivente, cartão vazio, Belo Horizonte e fragmentos; aplicar apenas conclusões que resistam às alternativas. Evidências apenas parcialmente concordantes não autorizam copiar respostas da fonte maior.
3. Incorporar à conferência os conteúdos familiares coincidentes sob chaves distintas e os danos textuais que estavam artificialmente classificados como iguais, sem excluir famílias por coincidência.
4. Ajustar os universos de atividade/renda pela evidência publicada, conservando a distinção entre idade declarada ignorada e idade danificada. Estado conjugal deve continuar explicitamente separado se não houver prova adicional.
5. Executar testes pequenos sequenciais e recontar todo o inventário com os manifestos novos. Conferir efeitos sobre a recuperação de cartões e suas assinaturas; não modificar assinaturas apenas para contornar uma inconsistência.
6. Produzir nota narrativa do antes/depois, decisões aplicadas, casos ainda não demonstráveis e consequências para reconstrução/pesos. Reconstrução e pesos só prosseguem se os requisitos de integridade forem satisfeitos.

## Coordenação e validação

Três frentes com propriedade delimitada: duplicatas; vínculos; texto. R/microdata_1960_amostra_127.R só pode ser alterado em funções expressamente atribuídas, sem refatoração geral. Agente principal integra validação/universos, executa R sequencialmente e confere independência e cobertura. Auditores Python e SQLite usam leitura sequencial/índice read-only.

Testes R somente pelo runner references/rodar_r_isolado_1960.py com --windows-arch --locale-c, primeiro um teste mínimo, sem Rscript -e, targets, alterações globais ou encerramento de processos alheios. A restrição de não executar R na rodada anterior era própria da investigação; esta rodada inclui implementação e testes já autorizados. Nenhum tar_make ou avaliação de _targets.R para evitar execução incidental. Testes devem demonstrar rejeição de contraprovas, não só aceitação dos exemplos positivos.

## Progresso da execução

- Teste mínimo R (contagens) aprovado pelo runner isolado. Nenhum crash nativo.
- Atividade/renda: teste novo demonstrou exclusão indevida da idade declarada ignorada; ajuste passou com contraprovas de idade danificada, presença desconhecida, atividade/renda inválidas e peso ausente. Descoberta e corrigida também falha de agrupamento quando uma tabela não tem elegíveis; teste cobre todos menores de cinco e entrada inteiramente vazia.
- Texto: teste antes confirmou bloqueios antigos; teste depois aprovou quatro reparos de nacionalidade e dez diagnósticos explícitos de dano sem apagar caracteres, com seis contraprovas. Logs em tmp/resolver_residuais_1960_20260922/texto_antes.log e texto_depois.log. Reparo geográfico não está implicitamente autorizado pelo reparo de nacionalidade.
- Duplicatas: além dos dois pares RS, duas alternativas SP/RS foram excluídas por composição própria, e o caso CE recebeu prova composta. O padrão cearense possui 145 famílias no total, 144 além do alvo. Aplicação e testes desta frente em andamento; recontar depois de todos os arquivos estabilizarem.
- Vínculos: dois destinos completos no manifesto; recuperação de BA e CE em implementação, preservando pasta/boletim127 e registrando chave25 separadamente. RS não passou a hipótese de segunda pessoa rara: perfil24 tem oito ocorrências25 e pelo menos duas127.
- Nova guarda de famílias coincidentes e manifesto próprio: cinco conjuntos com preservação corroborada entre fontes; cinco ainda pendentes, sem exclusão. Verificação runtime adicional das fontes25 em implementação.
- Conferidas outras cinco cópias HHOLDA no acervo, inclusive recebimento datado de 2012: todas têm exatamente os mesmos bytes. Páginas PDF8/24 de estado conjugal novamente lidas e vistas; não esclareceram idade ignorada. Prova em tmp/resolver_residuais_1960_20260922/fontes_adicionais.

Ainda faltam: estabilizar arquivos das frentes, segunda leitura integral dos novos manifestos, atualizar assinaturas da recuperação somente após revalidação, baterias R sequenciais, inventário atualizado, cobertura/disposição por caso e nota narrativa final. Não marcar o pedido completo enquanto houver esses passos implementáveis; não chamar impedimentos de fonte de correções concluídas.

### Integração adicional

- Cinco pares pessoais aplicados: 6.461 decisões, 3.725 manter/2.736 remover; nenhuma remoção nova. Dois vínculos e dois cartões (32 para80p) revalidados pelo auditor independente e teste R BA/CE: 6p preservadas,11contraprovas bloqueadas,exit0.
- Inventário01:458conjuntos/918linhas,1.221semfamília,192conflitos; anterior ao novo PE abaixo. Não usar como inventário final.
- PE238422/238423: prova localizada permite distrito operacional X7→07, sem alterar textos, e cinco vínculos239457–239461. Manifesto vínculos agora258. Implementação build/teste pelo agente vínculos; root propagou marcas^censobr_distrito_ para domicílios emfinalize e adicionou targets deprova/fontes sem executar targets.
- Revisão independente descobriu ramo V223 ausente e UF ausente/inválida escondidos pelos validadores. q34ANTES demonstrou10falhas; correção validate1965 passou24contraprovas adicionais no DEPOIS. DefinitivosANTES demonstrou8falhas e18controles; correção em implementação pelo agente texto. Não extrapolar para outros anos.
- Revisão independente recover pediu fontes internas da prova, análises e mapeamento UF→arquivo. Agente duplicatas autorizado somente recover+testes. Reauditoria Python integral BA/CE em andamento com CSV258, gerando NOVA prova cartoes_fora_chave_final.json; preservar inicial. Depois mudar referências/SHA nas duas novas regras e manifesto, rerodar checker independente e baterias. Não atualizar hash isolado de prova antiga.
- Novos scripts root: verificar_resolucao_residuais_1960.py (bateria sequencial), consolidar_resolucao_residuais_1960.py (antes/depois e caderno), conferir_integracao_residuais_1960.py (revalidação de32cartões). Nota narrativa+LEIAME em rascunho, explicitamente EM CONFERÊNCIA; finalizar somente com execução e inventário finais.
- Regras de propriedade: root não altera R enquanto agentes em funções distintas; R só em janelas congeladas. Ao retomar, consultar status e sessões. Provas JSON novas dependentes de hashes receberam -text em .gitattributes.

## Fechamento verificado — 23/09/2026

- Decisões aplicadas e testadas: cinco pares preservados (dez linhas, zero remoções novas); sete vínculos a cartões existentes; dois cartões recuperados para seis pessoas existentes; quatro nacionalidades; distrito operacional PE 07 em dois registros, preservando X7 e a procedência. Dez danos textuais identificados sem respostas fabricadas. Guardas de famílias inteiras e de validação incompleta implementadas.
- Prova BA/CE vigente: `cartoes_fora_chave_fechada.json`, produzida com as 258 linhas do CSV e sua procedência estabilizada. Os 30 cartões anteriores ficaram intactos; conferidos 32 cartões / 80 pessoas e 112 textos da fonte de 25%. Não se atualizaram provas anteriores para apagar a cronologia.
- Testes: 22 scripts R distintos com última execução aprovada, em lotes sequenciais `bateria_final_03`, `bateria_legados_01`, `bateria_integridade_01`; 32 testes Python; oito verificações internas da auditoria adicional. Interrupções anteriores preservadas: índice automático criado pelo próprio teste PE, fixture antigo incompleto e recusa do Windows a regravar um arquivo do teste. Corrigidos os cenários de teste sem enfraquecer as guardas. Nenhum crash nativo do R. Consolidação valida hashes da versão efetivamente entregue, incluindo os sete scripts Python.
- Auditoria nacional refeita no índice fechado: dez conjuntos, 21 cartões / 54 registros pessoais. Conferência complementar dos 32 recuperados contra todos os 174.467 cartões reais e entre si: zero coincidências integrais adicionais. Distrito PE tampouco cria uma coincidência; só foi derivado em memória nesta auditoria independente. Isso não equivale a reconstrução integral em R.
- Inventário final independente: 458 conjuntos pessoais / 918 linhas pendentes (127 exclusões históricas ainda sem prova); 1.216 registros pessoais em 481 grupos de chave sem família, incluindo três fragmentos cuja chave vazia não demonstra família comum; 192 pessoas com conflito geográfico; um cartão vazio; uma convivente sem principal; cinco conjuntos de famílias coincidentes ainda bloqueados. Listas se sobrepõem. A conciliação cobre 2.536 posições e preserva, como tais, as classificações históricas dos casos.
- Relatório narrativo: `references/resolucao_residuais_registros_1960_20260922.md`; caderno: `references/resolucao_residuais_1960_evidencias/LEIAME.md`. Incluem exemplos, antes/depois, critérios, contraprovas e limites. A documentação de estado conjugal não resolveu o tratamento da idade ignorada.
- Brutos e parquets completos conferidos por SHA-256 e intocados. Nenhum recálculo dos pesos de 1,27%, avaliação de `_targets.R`, `tar_make`, release, commit ou push nesta rodada. Rproj e renv.lock mantêm as alterações preexistentes do usuário (0/1 e 224/143 linhas no diff, respectivamente).
- Próximas etapas não realizadas: obter prova adicional ou decidir explicitamente um tratamento metodológico da incerteza; preservar procedência no esquema combinado antes de liberar cartões recuperados; reconstruir a base e recalcular pesos somente com requisitos satisfeitos. Não escolher respostas, excluir pessoas ou reaproveitar pesos por novos IDs para contornar os impedimentos. Variâncias continuam adiadas.
