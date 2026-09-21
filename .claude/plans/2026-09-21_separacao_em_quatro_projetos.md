# Plano: separar `censobr_prep_data` nos quatro projetos que ele virou

**Status:** CONCLUÍDO (21/09/2026)
**Data:** 2026-09-21
**Alvo:** `D:\Dropbox\Software\R_Packages\censobr_e_prepData\` — o pipeline e três projetos novos ao lado dele

## Contexto

O repositório nasceu em maio de 2026 como o pipeline `targets` que produz os parquets do `censobr` (24 commits até 12/05). Em setembro, a reconstrução de 1960 trouxe 98 commits em sete dias — e, a partir de 18/09, quatro frentes de trabalho que **não são o pipeline** passaram a morar em `references/`, `data_raw/` e `tmp/`, sem nunca terem sido commitadas: um artigo, uma monografia histórica, um estudo de migração com mapas e a reconstrução cartográfica da Guanabara. Hoje `references/` tem 489 arquivos e 1,9 GB; `tmp/` tem 8.894 arquivos e 2,2 GB e **não está no `.gitignore`** — um `git add -A` levaria tudo isso para `ipea/censobr_prep_data`, que é público.

O inventário (21/09, só leitura) mostra **quatro projetos e um documento transversal**, com dependência numa direção só:

```
                     ┌──────────────────────────┐
                     │  P1  censobr_prep_data    │  produz data/ e data_raw/microdata/
                     │      (o pipeline)         │  lê: nada dos outros
                     └─────────────┬────────────┘
                                   │ parquets, tabelas do estágio, read_guides
              ┌────────────────────┼──────────────────────┐
              ▼                    ▼                      │
   ┌────────────────────┐  ┌───────────────────┐          │
   │ P2 pesquisa sobre  │  │ P4 cartografia da │──────────┘ (só read_guides/1960_distritos, a confirmar)
   │ a amostra de 1960  │◄─┤ Guanabara 1960    │  produz tracado_v9/v10
   │ artigo, migração,  │  └───────────────────┘
   │ viabilidade        │
   └────────────────────┘
   ┌────────────────────┐
   │ P3 história da     │  lê: nada de P1, P2 ou P4 — só as próprias fontes
   │ apuração de 1960   │
   └────────────────────┘
```

**Nada no pipeline cita os outros três** (`grep` em `R/` e `_targets.R`: zero ocorrências). O pipeline depende, em `references/`, de exatamente três arquivos: as duas transcrições (`censo_1960_resultados_preliminares_1965.csv`, `censo_1960_resultados_definitivos_serie_nacional.csv`) e `microdata_1960_compilacao_dicionario.csv`. Tudo o mais em `references/` é documentação do pipeline ou pertence a outro projeto.

## Decisões já tomadas (21/09)

| decisão | escolha |
|---|---|
| a cartografia da Guanabara | **projeto próprio** (P4) |
| a história da apuração | **projeto próprio** (P3) — o usuário a distinguiu da pesquisa estatística |
| os quatro guias de 1960 | **ficam com o pipeline**: citam o código 17–25 vezes cada; são a documentação dele |
| a carta ao IBGE | **fica com o pipeline**: é o registro dos defeitos que o pipeline achou, dirigido ao fornecedor |
| forma | **repositórios e workspaces distintos**, como já é entre `censobr` e `censobr_prep_data` |
| histórico | não há o que preservar — os arquivos que saem nunca foram commitados; novos repositórios começam limpos |

## O que é cada projeto

### P1 — `censobr_prep_data` (fica onde está, mantém o remoto `ipea/censobr_prep_data`)

O que **permanece**, além de `_targets.R`, `R/`, `read_guides/`, `schemas/`, `renv`, `.claude/` e `CLAUDE.md`:

| grupo | arquivos (em `references/`) |
|---|---|
| insumos do pipeline | as duas transcrições e o dicionário da compilação; `censo_1960_sinopse_preliminar_distritos.csv` |
| geradores de insumo | `transcricao_1960_serie_nacional.py`, `transcricao_1960_sinopse_preliminar.py`, `parse_cadastro_1960.py`, `gera_distritos_1960.R`, `auditoria_distritos_1960.R`, `1960_distritos_leitura_visual*.txt`, `folha_contato_codigo_1960.py`, `gera_dicionario_1960.py`, `gera_planilha_1960.R` |
| documentação do pipeline (1960) | `microdata_1960_amostra_127_{preparacao,desenho_amostral,consistencia}.md`, o `.pdf`, `microdata_1960_amostra_25_{preparacao,desenho_amostral}.md`, `microdata_1960_compilacao.md`, `microdata_1960_pendencias.md`, `issue_familias_secundarias_1960_1970.md`; `conferencia_desenho_*_1960.R`; `estimador_diferencas_sucessivas_1960.R` (citado pelo §13.4); `figuras/desenho_amostral_1960.R`, `figuras/facsimiles_1960.py`, `figuras/desenho_amostral_1960/` |
| documentação do pipeline (outras edições) | `microdata_19{70,80,91}_*.{md,csv}`, `microdata_2022_acesso_publico_vs_controlado.md`, `relatorio_*.md`, `tracts_2022_v0006_escala.md` |
| fontes primárias do pipeline | `fontes_1960/` **raiz** (8 PDFs, README, `1960_cadastro_territorial.csv`, o HTML do Código de Zonas) e `fontes_1960/sinopse_preliminar_1960/` (ignorada; lida por `gera_distritos_1960.R`) |
| artefatos de release | `censo_docs/` (dicionários), `phgfsouza_census_tracts/` (especificação externa) |
| a carta ao IBGE | `carta_ibge.md`, `carta_ibge_anexo.md`, `carta_ibge_levantamento.md`, `auditoria_dos_relatorios.md` |
| dados | `data/` inteiro; `data_raw/` menos as três pastas de cartografia; `data_raw/serie_nacional_1960/` (cache da transcrição) |
| planos | `2026-09-16-geo-cols-por-edicao.md`, `2026-09-16-microdados-2022-p0115.md`, `2026-09-21_revisao_desenho_amostral_1960.md` |

### P2 — pesquisa sobre a amostra de 1960 (nome provisório: `censo1960_amostra`)

O artigo e os estudos estatísticos que **consomem** os parquets e as tabelas do estágio. Todos os scripts declaram "Não faz parte do pipeline" no cabeçalho.

| grupo | arquivos |
|---|---|
| o artigo | `references/artigo/artigo_censo_1960.{md,qmd,tex,pdf}`; a parte dele do `referencias.bib` (39 chaves) |
| a migração intraurbana | `references/artigo/migracao_intraurbana_1960.{qmd,tex,pdf}`, `_revisado.pdf`, `_files/`; `migracao_intraurbana_1960.R`, `_malhas.R`, `_bairros.R`; `cartografia_df_1960.py`; `figuras/migracao_intraurbana_1960/` |
| os estudos de apoio | `demonstracao_1960.R`, `identificacao_estrato_1960.R`, `viabilidade_subestadual_1960.{R,md}`; `figuras/artigo_censo_1960.R` + `figuras/artigo_censo_1960/` |
| dados próprios | `data_raw/cartografia_1960_estudo/` (960 KB) e `data_raw/cartografia_sp_1980/` (7,3 MB), escritos pelos scripts de migração → viram o `data/` deste projeto |
| planos | `2026-09-18-artigo-censo-1960.md`, `2026-09-19-artigo-censo-1960-reframe.md`, `2026-09-20-migracao-intraurbana-1960.md` |

**Consome**: de P1, `data/microdata_sample/1960/`, `data_raw/microdata/1960/{compilada,amostra_127}/`, `data/release_legacy/`, `read_guides/` (rótulos); de P4, `tracado_v9`.

### P3 — a história da apuração do Censo de 1960 (nome provisório: `censo1960_historia`)

A monografia em Quarto e o seu aparato de fontes. **Não lê nada de P1** (o `.qmd` e o script de figuras não tocam `data/` nem `data_raw/`): é o mais independente dos quatro.

| grupo | arquivos |
|---|---|
| a monografia | `references/artigo/historia_censo_1960.{qmd,tex,pdf}` (148 KB de `.qmd`, 13,6 MB de PDF); a parte dela do `referencias.bib` (68 chaves) |
| o aparato | `censo_1960_historia_{cronologia,fontes}.csv`, `historia_censo_1960_{buscas_manuais,roteiros_entrevista}.md`, `historia_censo_1960_checa.py`; `figuras/historia_censo_1960.R` + `figuras/historia_censo_1960/` (63 arquivos, 15 MB) |
| fontes | `references/fontes_1960/historia/` (1,5 GB, 124 arquivos, inclusive `grandes/`) |
| material de trabalho hoje em `tmp/` | `tmp/historia_1960/` (**1,4 GB, 585 arquivos, com 6 `.py` e 3 `.R`** — OCR de jornais, digests, `monta_figuras.py`; o `.qmd` cita `tmp/historia_1960/ocr_jornais` e `digests/`); `tmp/pdfs/` (189 MB — dono a confirmar por conteúdo) |
| planos | `2026-09-20-historia-censo-1960.md` |

### P4 — a cartografia da Guanabara em 1960 (nome provisório: `guanabara1960_cartografia`)

Uma base geográfica versionada (v5 → v10), com QA por navegador e ferramentas em Python. Produz o traçado que P2 consome.

| grupo | arquivos |
|---|---|
| o projeto | `references/cartografia_guanabara_1960/` (150 arquivos: scripts, JSON de controle, templates HTML, logs `.md` por versão) |
| crosswalks | `crosswalk_bairros_guanabara_1960_v9.csv`, `censo_1960_sinopse_preliminar_gb_quadro_ii.csv` (a confirmar por `grep` na Fase 0) |
| dados | `data_raw/cartografia_guanabara_1960/` (1,3 GB: `fontes/`, `preparacao/`, `tracado_v9/`…) → o `data/` deste projeto |
| scratch em `tmp/` | `tmp/cartografia_browser_qa*/`, `tmp/cartografia_libs/`, os 14+ `tmp/chrome-v10-*/` — scratch descartável; o que for reutilizável vai para um `tmp/` **ignorado** de P4 |
| planos | os sete de `2026-09-15-*` e `2026-09-16-reconstrucao-v10.md` |

**Consome** de P1, provavelmente, `read_guides/1960_distritos.csv` (códigos de bairro) — confirmar na Fase 0.

### Arquivos com dono a decidir por `grep` (Fase 0)

`crosswalk_bairros_rio_zonas_1960.csv`, `crosswalk_bairros_guanabara_1960_v9.csv`, `censo_1960_sinopse_preliminar_gb_quadro_ii.csv`, `tmp/pdfs/`. Regra: o arquivo vai para o projeto cujos scripts o leem; se dois leem, fica com quem o produz e o outro consome pela via de dados.

---

## Abordagem

### Onde ficam

Três pastas novas, **irmãs do pipeline**, sob `D:\Dropbox\Software\R_Packages\censobr_e_prepData\`, ao lado de `censobr/` e `censobr_prep_data/`. É o padrão que já existe. Se depois P2 e P3 quiserem morar em `Dropbox\Artigos\`, o contrato de dados abaixo torna a mudança uma linha.

### O contrato de dados entre projetos

Hoje os scripts de pesquisa usam caminhos relativos à raiz do pipeline (`data_raw/microdata/1960/compilada`, `read_guides/...`). Depois da separação, cada projeto consumidor declara onde está o produtor por variável de ambiente, com um default para o layout de pastas irmãs:

```r
# no topo de cada script de P2 e P4 que lê o pipeline
prep <- Sys.getenv("CENSOBR_PREP_DATA", "../censobr_prep_data")
cart <- Sys.getenv("GUANABARA_1960_CARTOGRAFIA", "../guanabara1960_cartografia")   # só em P2
```

e os caminhos viram `file.path(prep, "data_raw/microdata/1960/compilada")`. Sem pacote, sem helper — duas linhas no estilo do usuário. Um `.Renviron` em cada projeto fixa as variáveis para a máquina. O consumidor **nunca escreve** no produtor: os scripts de migração, que hoje gravam `data_raw/cartografia_1960_estudo/` dentro do pipeline, passam a gravar no `data/` de P2.

### O escopo de cada workspace (hooks)

O mecanismo de `.claude/hooks/check-scope.ps1` já existe e bloqueia edições em `../censobr/` por um padrão de caminho (`$forbiddenPattern`, linha 47). Cada projeto novo recebe uma cópia com o padrão ajustado:

| projeto | pode editar | só lê |
|---|---|---|
| P1 | a si mesmo | `censobr/` (como hoje) |
| P2 | a si mesmo | `censobr/`, `censobr_prep_data/`, `guanabara1960_cartografia/` |
| P3 | a si mesmo | os outros três |
| P4 | a si mesmo | `censobr/`, `censobr_prep_data/` |

Regras (`.claude/rules/`) copiadas por pertinência: `scope.md` (adaptada) e `code-style.md` em todos; `memory-discipline.md` em P2 (processa 15 milhões de linhas); `plan-first-workflow.md` em P4 (obra de várias rodadas); `test-first-protocol.md` e `minimal-changes.md` só em P1, que são do pipeline. Cada projeto ganha um `CLAUDE.md` curto: o que é, o que consome, o contrato de dados, o que é read-only.

### O `.bib`

`referencias.bib` tem 124 entradas. O artigo usa 39, a história 68, a migração 17; só 4 chaves são comuns a artigo e história e 1 às demais. Divide-se em três arquivos, um por documento, duplicando as 5 chaves compartilhadas — mais simples do que um `.bib` partilhado entre repositórios.

---

## Fases

**Fase 0 — manifesto, antes de mover qualquer coisa.** Um script (só leitura) que, para cada arquivo de `references/`, `data_raw/`, `tmp/` e `.claude/plans/`, diz quem o lê (`grep` de referências cruzadas em `.R`, `.py`, `.qmd`, `.md`, `_targets.R`) e o classifica em P1–P4 pela regra acima. Saída: `manifesto_separacao.csv` com uma linha por arquivo e uma coluna `destino`. **Todo arquivo tem exatamente um destino; nenhum fica sem.** Resolve os quatro ambíguos e confirma que `_targets.R` continua achando os três `references/` de que depende.

**Fase 1 — o pipeline fica limpo e commitado.** (a) `tmp/` entra no `.gitignore` de P1 — hoje não está e é o maior risco do repositório. (b) O estado atual do pipeline (código de hoje + guias revisados) é commitado como baseline, **só com o "sim" do usuário**. (c) `references/fontes_1960/README.md` perde a seção de `historia/`; as exceções de `.gitignore` para `historia/grandes/` saem.

**Fase 2 — nascem os três projetos.** Para cada um: pasta, `git init`, `.gitignore` (dados e scratch fora), `CLAUDE.md`, `.claude/settings.json` + hooks com o padrão ajustado, regras pertinentes, `.Renviron` com as variáveis do contrato. Nenhum remoto é criado — é decisão do usuário, e o artigo é rascunho de submissão.

**Fase 3 — a mudança.** `mv` por manifesto (os arquivos são não rastreados; não há `git mv` a fazer). As pastas grandes — `fontes_1960/historia/` (1,5 GB), `data_raw/cartografia_guanabara_1960/` (1,3 GB), `tmp/historia_1960/` (1,4 GB) — movem no mesmo disco, o que é instantâneo; o Dropbox reindexa. Os planos vão para o `.claude/plans/` do seu projeto. O `.bib` é dividido.

**Fase 4 — os caminhos.** Nos scripts movidos: o contrato de dados no topo, e cada `data_raw/...`, `data/...`, `read_guides/...` do pipeline vira `file.path(prep, ...)`; as gravações dos scripts de migração passam para o `data/` de P2. Nos `.qmd`: caminhos de figuras e fontes ajustados (a história cita `references/fontes_1960/historia/` e `tmp/historia_1960/`, que passam a ser `fontes/` e `trabalho/` dela). Em `historia_censo_1960_checa.py`, os `arquivo_local` do catálogo.

**Fase 5 — o pipeline registra a separação.** `CLAUDE.md` de P1 ganha uma seção "Projetos vizinhos": os três, o que cada um consome, e que a dependência é numa direção só. A memória do harness recebe o mesmo (os projetos novos começam com memória vazia; as memórias de estilo e de conduta do usuário — `feedback_*`, `user_role`, `reference_user_style_projects` — são copiadas para cada um).

## Verificação

1. **O pipeline não dependia de nada que saiu.** `targets::tar_outdated()` em P1, depois da Fase 3, devolve vazio, e `tar_make()` termina em "skipped" para todos os alvos. Se algum alvo invalidar, um arquivo movido era insumo — volta.
2. **Nenhum arquivo em dois lugares, nenhum sem lugar.** `comm` entre a lista de arquivos antes (Fase 0) e a união dos quatro projetos depois: iguais.
3. **P2 reproduz as suas saídas.** `Rscript demonstracao_1960.R` e `viabilidade_subestadual_1960.R` rodam da nova raiz e os CSVs que gravam são idênticos aos de antes da mudança (guardar cópia na Fase 0). `quarto render` do artigo e da migração passam.
4. **P3 fecha sozinho.** `python historia_censo_1960_checa.py` passa (todo `arquivo_local` existe, todo `sha256` bate) e `quarto render historia_censo_1960.qmd` passa — sem `CENSOBR_PREP_DATA` definida, o que prova que não lê o pipeline.
5. **P4 roda a auditoria da v10** (`auditar_v10.py`) da nova raiz.
6. **`git status` em P1** mostra só as deleções esperadas (as pastas que saíram) e nada de `tmp/`; `du -sh references/` cai de 1,9 GB para a ordem de 60 MB.
7. **Os hooks funcionam nos quatro sentidos**: um `Edit` de teste em `../censobr_prep_data/README.md` a partir de P2 é bloqueado.

## Decisões da execução (21/09, Fase 0 → 2)

| decisão | escolha do usuário |
|---|---|
| nomes das pastas | **`censo1960_artigos`** (P2), **`censo1960_historia`** (P3), **`guanabara1960_cartografia`** (P4) |
| commit de linha de base (Fase 1b) | **não** — a mudança segue sem commit; o `git status` de P1 mistura as modificações de hoje com as deleções da separação |
| scratch da cartografia em `tmp/` | pergunta mal formulada (jargão); **nada é apagado** — tudo vai para o `tmp/` ignorado de P4, e a decisão de apagar fica para depois, com explicação em linguagem comum |
| Fase 0 | manifesto com 13.384 arquivos e nenhum sem destino, em `2026-09-21_separacao_manifesto.csv`; `tmp/` entrou no `.gitignore` de P1; a exceção `historia/grandes/` saiu; `references/__pycache__` apagado |
| `fontes_1960/README.md` | não tinha seção de história — nada a tirar |
| `.bib` | dividido pelas chaves que cada `.qmd` cita: 20 entradas para P2, 65 para P3, 3 em comum; 42 entradas que nenhum `.qmd` cita (fontes de hemeroteca) vão com a história |

## Fora de escopo

- Criar remotos no GitHub ou fazer qualquer `push` — decisão do usuário, depois.
- Commits além do baseline da Fase 1, e esse só com autorização explícita.
- Renomear ou reescrever os scripts de pesquisa além dos caminhos (estilo, estrutura, `here`) — o plano move, não refatora.
- Tocar em `../censobr/`.
- Os nomes das pastas são provisórios: `censo1960_amostra`, `censo1960_historia`, `guanabara1960_cartografia`. Confirmar antes da Fase 2; depois disso, renomear custa um `mv` e três `.Renviron`.

---

# Registro da execução (21/09/2026)

**Status: CONCLUÍDO.** Os quatro projetos existem, cada um com repositório (`git init`, sem remoto), workspace, `CLAUDE.md`, hooks e regras; nenhum arquivo ficou sem lugar e o pipeline não dependia de nada que saiu.

## O que ficou diferente do planejado

| ponto do plano | o que aconteceu |
|---|---|
| Fase 1b, commit de linha de base | **não feito**, por decisão do usuário; o `git status` de P1 mistura as modificações do dia com as da separação — que, como nada do que saiu era rastreado, não aparecem como deleções |
| scratch da cartografia (`tmp/`) | **nada apagado** — a pergunta foi mal formulada (jargão) e a decisão ficou para depois; tudo foi para o `tmp/` ignorado de P4 (os 24 perfis de navegador, o QA por navegador das rodadas v5–v8 e `cartografia_libs`, que os scripts importam) |
| `fontes_1960/README.md` | não tinha seção de história; nada a tirar |
| P3 (história) | a quarta figura embutida não existia com o nome citado: as figuras do desenho amostral foram **renumeradas no mesmo dia** (`fig07_pesos` → `fig08_pesos`, `fig03_cadastro_bahia` → `fig04`, `fig05_progressao` → `fig07`); o artigo e a história citavam os nomes antigos — corrigidos nos `.qmd` e as figuras copiadas com os nomes novos |
| `historia_censo_1960_checa.py` | achava a raiz por `parents[1]` mais um segmento literal `references`; corrigido para a pasta do próprio script |
| P4 (cartografia) | `CLAUDE.md` afirmava que os scripts leem `read_guides/`; não leem — só os diários o mencionam; corrigido |
| `.bib` | dividido pelas chaves citadas: 20 entradas em P2, 107 em P3 (65 do `.qmd` + 42 fontes de hemeroteca citadas pelas tabelas da história), 3 em comum; nenhuma chave de nenhum documento ficou sem entrada |
| verificação 6 | `references/` caiu para 344 MB — não para "~60 MB" como o plano estimou — porque os 306 MB das Sinopses (ignoradas) ficam; sem elas, 39 MB |

## As verificações

| # | o que | resultado |
|---|---|---|
| 1 | `tar_outdated()` em P1 depois da mudança | **um** alvo, `comparacao_127_1960_amostra_25`, com `depend = TRUE` e `file = FALSE`: o seu único insumo alterado é o parquet de 1,27% regerado **de manhã** pela correção das chaves de pasta, numa `tar_make` por nome que não o incluiu. A separação não invalidou nada |
| 2 | nenhum arquivo em dois lugares, nenhum sem lugar | 13.383 dos 13.384 do "antes" exatamente onde o manifesto mandou (o 13.384º é o cache apagado); nos projetos novos só os 25 arquivos de esqueleto não vieram do pipeline |
| 3 | P2 reproduz as saídas | `viabilidade_subestadual_1960.R` e `demonstracao_1960.R` rodam da raiz nova com o `.Renviron`, gravam em `data/`; contra as cópias de antes, mudaram 1 linha na viabilidade (o domínio da Guanabara) e 2 em cada demonstração — o rastro da correção das chaves de pasta da manhã, que baixou a variância do estrato da Guanabara, e não da mudança |
| 4 | P3 fecha sozinho | `historia_censo_1960_checa.py`: 116 fontes, 147 eventos, 65 chaves citadas, 107 no `.bib`, todo `arquivo_local` presente com `sha256` batendo — **ok**, sem `CENSOBR_PREP_DATA` |
| 5 | P4 roda a auditoria | `auditar_v10.py` sai com código 0 da raiz nova (é auditoria por asserção, não grava nada); os 66 scripts compilam |
| 6 | `git status` de P1 | só as modificações do dia; nada de `tmp/`; `references/` de 1,9 GB para 344 MB |
| 7 | hooks | nos três projetos, `Edit` em `../censobr_prep_data/README.md` e `R/x.R` é **bloqueado** e `CLAUDE.md` local é permitido |

## O que fica para o usuário decidir

- **Apagar ou não o `tmp/` da cartografia** (595 MB): os 24 perfis de navegador são cache de sessões encerradas (sem valor); as cinco pastas de QA são as capturas de tela das rodadas v5–v8 (o registro visual do que foi conferido); `cartografia_libs/` são as bibliotecas Python que os scripts importam (reinstaláveis com `pip`, mas sem elas os scripts não rodam).
- **Remotos e `push`** dos três repositórios novos — nenhum foi criado; o artigo é rascunho de submissão.
- **O commit de P1** com as mudanças do dia (código, guias, `.gitignore`, `CLAUDE.md`).
- Duas menções históricas a `data_raw/` em diários da cartografia (`CORRECAO_V7.md:14` e o plano de 15/09, linha 47) ficaram como estavam: descrevem onde as coisas *estavam*.
