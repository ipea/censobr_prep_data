# Pendências dos registros de 1960: investigação e correções comprovadas

**Status:** RODADA IMPLEMENTADA E TESTADA; entrega Git autorizada em conclusão. Persistem pendências factuais que não podem ser encerradas sem evidência ou política adicional. Não equivale a homologação dos registros.

**Resultado final da rodada:** integrados 954 conjuntos/1.908 linhas (490 remoções novas e três restaurações contra a regra histórica), 169 vínculos novos, 33 reparos/40 campos, derivação municipal explícita no Paraná e 30 cartões para 74 pessoas existentes. Bloqueios adicionais para cartão sem pessoas e situação divergente; retirada da imputação geral de nacionalidade; contagens desconhecidas preservadas como NA. Inventário integral: 463 conjuntos/928 linhas; 1.229 registros sem família; 50 conflitos municipais e 145 de situação, envolvendo 192 pessoas distintas; um cartão sem pessoas e uma convivente isolada. Listas sobrepostas; os três fragmentos não formam uma família demonstrada.

**Validação concluída:** 150 testes Python e 13 suítes R pelo runner, sem novos crashes; fontes e parquets completos inalterados. Auditoria completa renovada dos cartões e conferência independente dos 30 cartões/74 pessoas aprovadas; os 29 anteriores são preservados. Evidências portáteis em `references/fechamento_registros_1960_evidencias/`; relatório narrativo `references/fechamento_registros_1960_20260922.md`. O restante deste plano conserva o histórico das propostas intermediárias.

**Entrega autorizada:** depois desta rodada, fazer commit e push do trabalho revisado para o repositório deste projeto. Conferir o diff e os testes; excluir dados brutos, saídas temporárias e mudanças de ambiente não relacionadas (`renv.lock`/Rproj). Não publicar release nem substituir a base completa.

**Preservação no Git:** os manifestos conferem hashes de quatro guias e das listas de decisões. Os guias existentes têm finais de linha LF/CRLF/mistos. `.gitattributes` fixa esses arquivos como `-text`, preservando exatamente os bytes usados na conferência em qualquer checkout. Versionar os bytes atuais dos quatro guias, sem alterar posição, código, valor ou outra informação do dicionário. Isso evita que a conversão automática do Git invalide a prova; não é uma revisão dos layouts.

## Escopo

Concluir a investigação das pendências dos registros, nesta ordem: supostas duplicatas, vínculos familiares, texto e regras de inclusão pertinentes. Implementar correções demonstradas, preservar os registros e as dúvidas quando a fonte não permite decidir. Não confundir inventário completo com solução factual completa. Pesos, variâncias, publicação e substituição dos parquets atuais ficam fora desta etapa.

Ponto de partida: 1.417 conjuntos repetidos/2.836 linhas sem decisão; 1.339 pessoas/526 grupos sem cartão confirmado após 29 cartões recuperados; 63 conflitos municipais em vínculos diretos; uma família convivente sem principal demonstrado. As listas se sobrepõem. Três registros severamente corrompidos exigem investigação explícita. Não somar os totais como pessoas distintas.

## Procedimento

1. Auditoria reprodutível de todas as repetições, comparando grupos inteiros, quantidades e pessoas enumeradas na fonte25. Concordância isolada de respostas não prova duplicação. Gerar propostas separadas antes de editar decisões.
2. Conciliar vínculos com as decisões sobre multiplicidade. Procurar cartões próprios, conflitos geográficos, alterações de chave e família principal de conviventes. Recuperar da fonte25 apenas sob o contrato aprovado; não igualar códigos distintos para fechar correspondências.
3. Inventariar todos os reparos de texto e campos inválidos, confrontar os casos com fontes preservadas e identificar o que realmente se perdeu. Distinguir informação ignorada declarada de dano ao registro. Examinar regras de inclusão documentalmente sustentadas.
4. Testes pequenos antes de mudar produção; aplicar somente decisões individualizadas com literais e procedência. Rever a suficiência dos testes de leitura dos manifestos e dos bloqueios. Um único R de cada vez, exclusivamente pelo runner isolado, sem targets nem mudanças globais.
5. Conferir todas as decisões por segunda leitura, reabrir as saídas e conciliar linhas antes/depois. Relatório narrativo com exemplos, impacto, lista completa de resíduos e indicação do que falta para qualquer decisão não comprovável.

## Arquivos e coordenação

- Auditorias novas `references/auditoria_pendencias_{duplicatas,vinculos,texto}_1960.py`, respectivos testes e resultados novos sob `tmp/fechamento_registros_1960_20260922/`.
- Alterações comprovadas em `read_guides/1960_amostra_127_{duplicatas,vinculos,correcoes}.csv` ou manifesto de cartões, somente após conciliação e revisão principal.
- Ajustes mínimos e testes em `R/microdata_1960_amostra_127.R`, se necessários para aplicar/proteger essas decisões. Não alterar funções compartilhadas, schema final, pacotes ou `_targets.R` sem necessidade específica demonstrada.
- Nota narrativa de fechamento e atualização do estado mais recente. Histórico e tentativas preservados; nada em fontes brutas nem no pacote consumidor.

Três frentes de auditoria independentes executam leitura de baixo consumo. Apenas o agente principal altera produção e executa R, evitando concorrência e sobreposição de edições. A reconstrução final não será liberada pela simples classificação de casos como incertos. Se uma escolha metodológica nova for indispensável, apresentar opções concretas e seus efeitos, sem excluir dados para terminar.

## Descoberta e teste de contagens

## Integração das decisões comprovadas

Segunda leitura independente conferiu 3.501 literais e composições de 199 conjuntos repetidos (398 linhas, 15 remoções) e 33 vínculos (25 cartões). Serão integrados depois de testes pequenos contra os candidatos. As diferenças V216=00/63 permanecem respostas diferentes; uma camada separada investiga se grupos podem ser identificados preservando a divergência, sem alterar códigos nem presumir identidade civil. Diferenças habitacionais não identificadoras só podem ser consideradas separadamente da quantidade de pessoas, mantendo espécie/geografia/chaves e composição integral.

Foram propostos 17 reparos pessoais estritos, com evidência familiar completa: 11 V208 antes preenchidos por regra geral agora teriam origem localizada na25; seis outros campos antes inválidos seriam recuperados. Novo `read_guides/1960_amostra_127_reparos_fonte25.json` preserva a prova. A integração exige teste antes/depois e bloqueios para fonte/linha/campo alterados. `apply_corrections_1960_amostra_127` verificará textos e procedência antes de aplicar o diagnóstico novo `reparo_fonte25`. Dois targets de arquivos (evidências/fontes) serão acrescentados como dependências da correção, sem avaliar targets. Não muda o schema; o diagnóstico e a linha histórica permitem localizar a evidência.

`finalize_1960_amostra_127` usava `!V202 %in% ...`, que inclui NA como residente e presente. Teste novo `references/test_contagens_registros_1960.R` reproduziu a falha em 4 pessoas/2 pastas reais, com uma ausência sintética inserida só na cópia. Correção mínima: quando existe V202 ausente/inválido no domicílio, totais de residentes/presentes ficam NA, enquanto o número de pessoas listadas continua exato. Não muda respostas nem schema; casos com classificação completa devem permanecer idênticos. Log anterior `tmp/fechamento_registros_1960_20260922/contagens_antes_01.log` registra falha esperada sem crash nativo.
