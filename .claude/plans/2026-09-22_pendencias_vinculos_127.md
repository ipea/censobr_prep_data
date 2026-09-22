# Auditoria integral das pendências de vínculo

**Status:** AUDITORIA E CANDIDATURAS ENTREGUES; incorporação a cargo da revisão integradora.

## Escopo

Reconciliar as 1.339 pessoas/526 grupos restantes, os 63 conflitos municipais
diretos e a família convivente isolada. Não modificar fontes, manifestos atuais,
código R, targets, pesos ou parquets. Candidatos são separados de decisões aplicadas.

## Estratégia

1. Reusar índice literal127 em SQLite, somente leitura, verificando os hashes
   das fontes e as decisões atuais que o geraram.
2. Conferir lista inteira de pendências e recuperar os registros completos dos
   respectivos boletins. Conservar casos corrompidos e UFs sem fonte25 na lista.
3. Testar funções de comparação em exemplos sintéticos e executar microlote MG.
4. Comparar cada boletim com a fonte25: cartão, estrutura, composição integral,
   multiplicidades, códigos inválidos, pessoas já vinculadas e geografia.
5. Somente composição integral exata e cartão único concordante permitem propor
   novo vínculo; diferença de município pessoal permanece explícita, não corrigida.
   Perfis iguais têm multiplicidade, não identidade civil ou exclusão automática.
6. Para cartões ausentes, conciliar auditoria de recuperação anterior e buscar
   evidências adicionais; não tratar códigos diferentes como equivalentes.
7. Registrar diferenças, alternativas e lacunas concretas, com localizadores e
   literais, e conciliar com novas decisões de duplicatas antes de qualquer aplicação.

## Arquivos

- `references/auditoria_pendencias_vinculos_1960.py`
- `references/test_auditoria_pendencias_vinculos_1960.py`
- Saídas exclusivas sob `tmp/fechamento_registros_1960_20260922/vinculos/`.

## Validação

Testes negativos de composição, multiplicidade, fonte incompleta, conflito de
vínculo e município; piloto pequeno antes da varredura integral; cobertura exata
das listas de origem; hashes antes/depois. Sem execuções R nesta subtarefa.

## Resultado

Inventário ampliado a1.592pessoas únicas, cobrindo1.339pendentes+63conflitosmunicipais
+193situação (trêssobreposições), trêsregistroscorrompidos explícitos, umcartãovazio
eumaconvivente. 33vínculos estritos; 133condicionais poridentificaçãodegrupo24campos
semrecodificarV216 ouatributoshabitacionais. Seminterseção entreessaslistas e
semtrocadeumdestinodireto poroutro. Umcasocomduasorigensindividuais preserva ambas,
domesmocartão25. 71grupos/164pessoassemcartaoforamreexaminados: somente1cartão/2p
sobpropostaadicional; BHseguependente. Dozetestes passaram e houvepilotosMG.

Entrega: `tmp/fechamento_registros_1960_20260922/vinculos/entrega_02/`.
Nota narrativa: `references/fechamento_vinculos_1960_evidencias.md`.
Originais/manifestosdeprodução/R/targets/pesos nãoalteradospor esta subtarefa.

## Extensão autorizada pela revisão integradora

Após a entrega dos candidatos, o integrador solicitou revisão independente dos
reparos e autorizou editar exclusivamente `apply_corrections_1960_amostra_127`.
As guardas devem verificar dano antes/validade depois, HHOLDA e literais completos
dos grupos, chave e correspondências possíveis na fonte25, contagens e ordens.
Diferenças V216=00/63 em integrantes de contexto e V102 no caso documentado não
são recodificadas. Teste separado `test_reparos_fonte25_guardas_1960.R`; execução R
somente pelo integrador, nunca por esta subtarefa. O código R é reservado durante
as edições para não se sobrepor a execuções de outras suítes.

## Extensão da prova do grupo próprio, aprovada pelo integrador

Somente `own_group_proof` do auditor Python poderá reconhecer um grupo já ligado
a um cartão alternativo por correspondência única em 24 quesitos, quando a única
divergência estrita for a composição pessoal. Exigir diferenças exclusivamente
V216=00 na127/63 na25, dois perfis integrais exatos únicos na UF127 e todas as
guardas anteriores de cartão, geografia, estrutura e duplicatas. Registrar pares
e diferenças sem recodificá-los. O alvo da recuperação continua exigindo todos os
25 quesitos iguais. Criar testes adversos antes da edição; piloto PR70380/148
somente após confirmação de estabilidade dos 33 reparos de texto pelo integrador.
Não executar R nem reauditoria integral nesta subtarefa.

Concluído: 37 testes de recuperação e 12 de vínculos aprovados; piloto atualizado
PR70380/148 aprovou um cartão para duas pessoas, fontes inalteradas. O padrão
`permitir_contexto=False` preserva os chamadores históricos e a auditoria de
recuperação ativa explicitamente o critério adicional. Resultados/hashes estão na
nota narrativa. Nenhum manifesto de produção foi promovido por esta subtarefa.

## Duas guardas adicionais, aprovadas pelo integrador

A revisão final identificou ausência de bloqueio próprio para cartões familiares
sem pessoas e para divergências de situação V118 nos vínculos diretos ainda não
reconciliados. Criar teste real antes de editar: cartão780535, controle391267–391269
e família142520–142529, cuja decisão142523 deve continuar válida e preservar1/5.
O integrador executa o teste anterior; somente após essa execução será acrescentado
o bloqueio em `build_families`, com relatórios de linhas, e a guarda de cartão vazio
na entrada de `finalize`, para dados antigos com IDs. Não mudar respostas,
manifestos, targets, contagens ou esquema. Não executar R nesta subtarefa.

O teste anterior reproduziu as cinco lacunas pelo runner do integrador. Patch
entregue: V118 direto não reconciliado, cartão sem pessoas em build e cartão vazio
em entrada antiga de finalize. O código geográfico do integrador foi preservado.
`git diff --check` aprovado; execução R posterior a cargo do integrador.
Posterior conferida no log `guardas_familias_depois_01.log`: cinco bloqueios e
dois controles positivos aprovados, código0; nenhum R executado por esta subtarefa.
