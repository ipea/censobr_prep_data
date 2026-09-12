---
name: test-first-protocol
description: Validar antes de implementar em massa. Em pipeline de dados, "test-first" significa rodar smoke test em 1 UF pequena antes de processar 27.
paths:
  - "**/*"
---

# Protocolo Validação-Primeiro com Loop de Investigação

**Status:** OBRIGATÓRIA
**Escopo:** Todo o projeto `censobr_prep_data`

## Princípio

Toda mudança no pipeline deve ser **precedida por uma forma concreta de validação**. Nunca processar os 27 estados do Brasil como primeira ação — sempre rodar primeiro num subset minúsculo (1 UF pequena, 1 tabela). O fluxo correto é um **loop de investigação** até certeza absoluta, seguido de execução em massa.

Diferente de pipelines com `testthat`, aqui a validação é empírica: o output é um parquet, e a forma de "testar" é abrir o parquet e conferir colunas/linhas/tipos contra o release de referência (v0.5.0).

## O Loop de Investigação (OBRIGATÓRIO)

```
┌─────────────────────────────────────────────────┐
│  1. INVESTIGAR                                  │
│     - Ler o script legado em R_ainda_sem_targets│
│       (se for migração) ou o R/ existente       │
│     - Mapear dependências: qual download? qual  │
│       schema? qual harmonização?                │
│     - Identificar funções compartilhadas        │
│       afetadas (R/support_fun.R, etc.)          │
│                                                 │
│  2. PLANEJAR                                    │
│     - Descrever mudanças mínimas em texto       │
│     - Listar QUAIS targets serão criados/       │
│       alterados e POR QUÊ                       │
│     - Identificar parquets v0.5.0 que servirão  │
│       como referência de validação              │
│                                                 │
│  3. VALIDAR EM PEQUENO (antes de implementar    │
│     em massa)                                   │
│     - Rodar download/parsing apenas para 1 UF   │
│       pequena (RR ou AC ~poucos MB)             │
│     - Ou processar apenas 1 tabela              │
│     - Output deve abrir via arrow::read_parquet │
│       sem erro                                  │
│                                                 │
│  4. VERIFICAR                                   │
│     - Colunas presentes? Tipos corretos?        │
│     - Número de linhas faz sentido?             │
│     - Comparar com parquet de v0.5.0 (se        │
│       existe): mesmas colunas? mesma            │
│       cardinalidade?                            │
│                                                 │
│  5. DECIDIR                                     │
│     ├─ Certeza absoluta? → Ir para EXECUTAR     │
│     └─ Dúvida restante?  → Voltar ao passo 1   │
└─────────────────────────────────────────────────┘

    ▼ (só após certeza absoluta)

┌─────────────────────────────────────────────────┐
│  6. EXECUTAR EM MASSA                           │
│     - tar_make() no target completo             │
│       (todas as 27 UFs ou todas as tabelas)     │
│     - Monitorar logs em ./logs/crew_workers/    │
│     - Se travar no FTP IBGE: confirmar coress=1 │
│                                                 │
│  7. VALIDAR FINAL                               │
│     - Abrir todos os parquets de output         │
│     - tar_visnetwork() — nada órfão / pendente  │
│     - Se reproduz dataset publicado em v0.5.0:  │
│       comparar via arrow + dplyr (n linhas,     │
│       hash de colunas-chave)                    │
│                                                 │
│  8. (Apenas com aprovação) UPLOAD               │
│     - piggyback::pb_upload() para a tag-alvo    │
│     - SEM commit message com menção a AI        │
└─────────────────────────────────────────────────┘
```

## Critérios de "Certeza Absoluta" (passo 5)

Pode sair do loop APENAS quando TODOS forem verdadeiros:

- [ ] Entende a causa raiz (não apenas o sintoma — se algum bug está sendo corrigido).
- [ ] Sabe exatamente quais targets serão alterados.
- [ ] Sabe exatamente quais colunas o parquet vai ter.
- [ ] A validação em 1 UF pequena passa.
- [ ] Se reproduz dataset existente: o schema bate com v0.5.0 (ou diferenças são explicáveis).
- [ ] A mudança não afeta funções protegidas (ou tem plano aprovado).
- [ ] Não há efeitos colaterais não mapeados em outros targets.

Se QUALQUER critério não for atendido, **voltar ao passo 1**.

## Hierarquia de validação

### Nível 1: Smoke test em 1 UF pequena (OBRIGATÓRIO antes de massa)

Rodar o pipeline novo limitando a iteração a UMA UF. Proposta de implementação (Fase 0 do roadmap): variável de ambiente `CENSOBR_DEBUG="RR"` consumida por um target `states_subset` em `_targets.R`.

```r
Sys.setenv(CENSOBR_DEBUG = "RR")
targets::tar_make(names = "novo_target")
```

Tempo esperado: < 2 minutos para UF pequena. Se demora muito, algo está errado.

### Nível 2: `tar_make()` apenas do target novo

```r
targets::tar_make(names = "output_tracts_paths_2022")
```

Roda só os targets necessários (e os pais). Não recomputa o resto do pipeline.

### Nível 3: Validação contra release publicado

Para parquets que **reproduzem** datasets já em v0.5.0:

```r
ref <- arrow::read_parquet(
  "https://github.com/ipea/censobr/releases/download/v0.5.0/2010_tracts_Basico_v0.5.0.parquet"
)
new <- arrow::read_parquet("./data/tracts/2010/2010_tracts_Basico.parquet")

# Mesmas colunas?
setdiff(names(ref), names(new))  # esperado: character(0) ou diferenças explicáveis
setdiff(names(new), names(ref))

# Mesmo número de linhas?
nrow(ref); nrow(new)

# Mesmo hash em colunas-chave?
digest::digest(sort(ref$code_tract))
digest::digest(sort(new$code_tract))
```

### Nível 4: Rebuild completo (apenas antes de upload)

```r
targets::tar_destroy()      # com confirmação
unlink("./data", recursive = TRUE)
targets::tar_make()         # do zero, ~horas
```

Garante reprodutibilidade absoluta. Só rodar quando a versão estiver pronta para release.

## Regras para `Rscript` no Windows

- `Rscript -e "..."` causa segfault no Windows ao invocar `library(targets)` ou similares. **Não usar.**
- Sempre escrever código R em arquivo `.R` temporário, depois executar:
  ```bash
  cat > /tmp/run_target.R << 'EOF'
  library(targets)
  tar_make(names = "novo_target")
  EOF
  "C:/Program Files/R/R-X.Y.Z/bin/Rscript.exe" /tmp/run_target.R
  ```
- Se R der segfault: verificar processos `R*.exe` pendurados com `tasklist | grep -i R` e matar antes de re-tentar.

## Quando uma execução falha

1. **Ler a mensagem completa** — não pular o stacktrace de `targets::tar_meta(fields = error)`.
2. **Identificar o target exato** que falhou (`tar_meta` retorna `name`, `error`, `warnings`).
3. **Reproduzir isoladamente**: `tar_make(names = "<o target falho>")` — não rebuild o pipeline inteiro.
4. **Ler o output bruto**: se for download FTP, conferir `./data_raw/`; se for parsing, abrir o `.txt` ou `.xls` cru.
5. **Corrigir a causa raiz**, não o sintoma. Se for encoding ÿ, achar por que o IBGE entregou esse arquivo, não só substituir.
6. **NUNCA** editar uma função protegida (ver `minimal-changes.md`) como atalho.

## O que é proibido

- Disparar `tar_make()` em todos os 27 estados sem antes ter validado em 1 UF.
- Subir o coress acima de 1 sem ter testado se o FTP IBGE aguenta (rate-limit conhecido).
- Implementar uma migração sem ter aberto pelo menos 1 parquet de output e visto as colunas.
- Fazer "fix" iterativo cego: editar função → `tar_make` → falha → editar → `tar_make`, sem investigar.
- Rodar `tar_destroy()` para "limpar" sem entender o custo (re-download FTP de horas).
- Disparar `piggyback::pb_upload()` sem aprovação explícita do usuário e validação Nível 4.
- Commitar com targets em estado de erro.

## Exceções (não requer o loop completo)

- Correção de typo em comentário (1 linha, sem lógica).
- Atualização de URL em mensagem.
- Adicionar/remover item de `.gitignore`, `.Rbuildignore`.
- Editar `CLAUDE.md`, regras em `.claude/rules/`.

Para TUDO MAIS, o loop de investigação é **obrigatório**.