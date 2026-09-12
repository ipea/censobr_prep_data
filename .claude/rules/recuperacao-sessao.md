---
name: recuperacao-sessao
description: Protocolo de recuperação após compressão de contexto ou início de nova sessão neste projeto (pipeline de preparação de dados do censobr).
paths:
  - "**/*"
---

# Protocolo de recuperação de sessão

**Após compressão de contexto ou início de nova sessão, execute este protocolo antes de qualquer ação substantiva.**

## Quando ativar

- Após qualquer compressão automática de contexto.
- No início de qualquer nova sessão Claude Code neste projeto.
- Quando o usuário diz "continue de onde parou", "retoma", ou similar.
- Quando o contexto parece incompleto, contraditório ou confuso.

## Passos

1. **Ler `CLAUDE.md`** na raiz do projeto:
   `D:\Dropbox\Software\R_Packages\censobr_e_prepData\censobr_prep_data\CLAUDE.md`

2. **Ler `.claude/rules/scope.md`** — a regra inviolável de escopo (read-only em `..\censobr\`).

3. **Verificar plano de roadmap mais recente:**
   - `~/.claude/plans/` (planos do harness Claude Code)
   - `.claude/plans/` no projeto (se existir)
   Ler o plano mais recente e identificar o status (Fase 0.0, 1.x, 2.x, etc.).

4. **Verificar estado do pipeline `targets`:**
   ```r
   targets::tar_meta(fields = c("name", "type", "warnings", "error"), complete_only = FALSE)
   ```
   Identificar: quais targets estão `built`, `pending`, ou com `error`. Se houver erro, qual.

5. **Verificar releases do consumidor `ipea/censobr`:**
   ```bash
   gh release list --repo ipea/censobr --limit 5
   gh release view v0.6.0 --repo ipea/censobr --json assets --jq '.assets[].name' 2>/dev/null
   ```
   Comparar com o conjunto de targets no `_targets.R` — o que já foi publicado em v0.6.0 vs o que ainda falta.

6. **Verificar git status** (se o repo já estiver em git — pode não estar):
   ```bash
   git status 2>/dev/null && git log --oneline -5 2>/dev/null
   ```

7. **Declarar entendimento ao usuário** em 3–5 frases:
   - Em qual fase do roadmap o projeto está.
   - O que foi concluído na sessão anterior (se for retomada).
   - Qual a próxima ação esperada.
   **Pedir confirmação antes de continuar.**

## Prioridade de fontes (em caso de divergência)

1. **Estado do `_targets/meta/`** — específico, datado, é o que o pipeline efetivamente computou.
2. **Releases no `ipea/censobr` (GitHub)** — fonte de verdade do que está publicado.
3. **Plano mais recente em `~/.claude/plans/`** — visão de longo prazo, pode estar à frente do que foi executado.
4. **`CLAUDE.md`** — convenções e estrutura do projeto.
5. **`.claude/rules/`** — regras inviolaveis (escopo, mudanças mínimas, etc.).

Se houver divergência, **trustar o que está mais próximo da execução** (`_targets/meta/` > release publicado > plano > docs) e atualizar as fontes superiores em seguida.

## O que NÃO fazer ao retomar

- ✗ Pular o protocolo achando que se lembra do estado.
- ✗ Disparar `tar_destroy()` ou `tar_invalidate()` sem confirmar com o usuário.
- ✗ Republicar/sobrescrever um release no GitHub sem aprovação explícita.
- ✗ Editar arquivos em `..\censobr\` (proibido por hook — ver `.claude/rules/scope.md`).
- ✗ Reescrever um script de `R_ainda_sem_targets/` sem antes confirmar para qual ano/dataset/tabela ele está sendo migrado.