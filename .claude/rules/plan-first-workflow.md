---
name: plan-first-workflow
description: Para tarefas não-triviais neste pipeline, planejar antes de escrever código. Planos sobrevivem à compressão de contexto.
paths:
  - "**/*"
---

# Fluxo Plano-Primeiro

**Status:** OBRIGATÓRIA
**Escopo:** Todo o projeto `censobr_prep_data`

## Princípio

Para qualquer tarefa não-trivial, **planejar antes de escrever código**. Planos sobrevivem à compressão de contexto. Salvar todo plano em disco.

## O Protocolo

1. **Entrar em modo plano** — usar `EnterPlanMode`.
2. **Consultar fontes** — ler `CLAUDE.md`, regras em `.claude/rules/`, estado do `_targets/meta/`, último release do `ipea/censobr`.
3. **Investigar** — ler o código afetado (`R/`, `_targets.R`), mapear dependências.
4. **Redigir o plano** — quais mudanças, em quais arquivos, em que ordem; quais targets serão adicionados/alterados; impacto no schema dos parquets.
5. **Salvar em disco** — em `~/.claude/plans/` (padrão Claude Code) ou em `.claude/plans/` no projeto.
6. **Apresentar ao usuário** — aguardar aprovação via `ExitPlanMode`.
7. **Implementar** — seguir o plano aprovado, respeitando o loop de investigação (`test-first-protocol.md`).

## O que é não-trivial (REQUER plano)

- Acrescentar uma edição ou tabela nova ao pipeline (trio `download_*`/`clean_*`/`save_*` em `R/` + bloco em `_targets.R`).
- Adicionar / remover / renomear `tar_target` em `_targets.R`.
- Modificar funções compartilhadas em `R/support_fun.R`, `R/add_geography_cols.R`, `R/convert_raw_to_parquet.R`, `R/schema_col_classes.R` (ver lista de funções protegidas em `minimal-changes.md`).
- Alterar `read_guides/*.csv` (afeta parsing fwf).
- Mudar a lista `tar_option_set(packages = ...)` em `_targets.R` (afeta reprodutibilidade).
- Mudar a versão alvo do release (`versao_dados`) ou a política de upload.
- Mudar schemas Arrow em `schema_col_classes.R::get_schema()`.
- Recodificações ou harmonizações que mudem valores em colunas.
- Qualquer mudança que afete 2+ arquivos `.R`.
- Preparação para upload via `piggyback::pb_upload()`.

## O que é trivial (SEM plano necessário)

- Corrigir typo em comentário ou string de mensagem.
- Atualizar `.gitignore`, `.Rbuildignore`.
- Editar `CLAUDE.md`, `MEMORY.md` (se existir), regras em `.claude/rules/`.
- Adicionar `# TODO:` pontual em código já existente.

## Formato do plano em disco

```markdown
# Plano: [título curto]

**Status:** RASCUNHO | APROVADO | CONCLUÍDO
**Data:** YYYY-MM-DD

## Contexto
[Por que essa mudança é necessária — qual gap em v0.6.0 fecha,
qual bug do v0.5.0 corrige, etc.]

## Objetivo
[O que será produzido — quais novos parquets, quais novos targets]

## Abordagem
[Como — mudanças mínimas, reuso de funções existentes]

## Arquivos a modificar
- [ ] `_targets.R` — adicionar bloco `# 0X. <nome>`
- [ ] `R/<arquivo>.R` — funções `download_*`, `clean_*`, `save_*`
- [ ] `R/schema_col_classes.R` — schema novo se necessário

## Validação
- [ ] Smoke test com 1 UF pequena (RR/AC)
- [ ] `tar_make()` do alvo novo passa
- [ ] Output parquet abre via `arrow::read_parquet()` com colunas esperadas
- [ ] (Se for re-produção de dataset existente) Comparação contra v0.5.0 documentada
```

## Gestão de contexto

- Preferir auto-compressão a `/clear`.
- Salvar contexto importante em `MEMORY.md` (se houver) ou em comentários no plano antes de perdê-lo.
- `/clear` apenas quando o contexto estiver genuinamente poluído.
- Ao final de tarefas longas, atualizar `CLAUDE.md` ou notas no plano com descobertas (ex.: "Pessoa07_CE.xls tem caractere ÿ — tratado em…").
- NUNCA perder estado de um plano aprovado — ele está em disco.

## Regra de ouro

> **Nenhuma linha de código no pipeline `R/` deve ser escrita sem que exista um plano (aprovado ou trivial) e uma forma concreta de validação (smoke test em 1 UF ou comparação contra release publicado) que a justifique.**