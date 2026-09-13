---
name: minimal-changes
description: Toda alteração no pipeline deve ser mínima, cirúrgica e planejada. Sem refactor oportunista. Funções compartilhadas têm proteção extra.
paths:
  - "**/*"
---

# Mudanças Mínimas e Cirúrgicas

**Status:** OBRIGATÓRIA
**Escopo:** Todo o projeto `censobr_prep_data`

## Princípio

Toda alteração no código deve ser **mínima, cirúrgica e planejada**. Nunca modificar mais do que o estritamente necessário para o objetivo imediato. Não "aproveitar" para fazer correções ou melhorias em áreas não solicitadas.

Pipeline de dados que produz parquets versionados é particularmente sensível: refactor oportunista pode mudar valores ou ordenação de linhas silenciosamente, quebrando a paridade entre releases.

## Antes de editar qualquer arquivo

1. **Investigar**: ler o código existente, entender o fluxo, mapear dependências (qual target usa esta função? qual parquet ela afeta?).
2. **Planejar**: descrever em texto as mudanças ANTES de editar — quais linhas e POR QUÊ.
3. **Verificar dependências**: toda função alterada → quem a chama? toda coluna adicionada → quem a consome no consumidor `censobr`?
4. **Medir impacto**: quantos targets ficam invalidados? Vai ser preciso re-rodar o pipeline inteiro?

## Regras de edição

- **Uma mudança por vez**: não misturar fix de bug com feature nova.
- **Sem refactor oportunista**: se não foi pedido, não refatorar.
- **Sem "melhorias" cosméticas**: não renomear variáveis, adicionar comentários ou reorganizar código que não faz parte da tarefa.
- **Sem editar funções protegidas** sem plano aprovado pelo usuário (ver tabela abaixo).
- **Validar antes de editar em massa**: smoke test em 1 UF antes de processar 27 (ver `test-first-protocol.md`).

## Ordem obrigatória de implementação

```
1. INVESTIGAR o problema (ler código, entender dependências)
2. PLANEJAR as mudanças mínimas (texto descritivo)
3. CRIAR um caminho de validação (smoke test 1 UF, ou comparação)
4. RODAR a validação (deve falhar antes da mudança, passar depois)
5. FAZER a edição mínima no arquivo real
6. RODAR tar_make() no(s) target(s) afetado(s)
7. ABRIR o parquet de output e conferir colunas/linhas/tipos
8. (Se aplicável) Comparar contra release publicado em v0.5.0
```

## Funções protegidas

As seguintes funções afetam **múltiplos targets ou múltiplos anos** — não devem ser alteradas sem plano aprovado:

| Função / arquivo | Local | Impacto |
|---|---|---|
| `download_file_censobr()` | [R/support_fun.R](../../R/support_fun.R) | Toda ingestão de dados via FTP |
| `unzip_censobr()` | [R/support_fun.R](../../R/support_fun.R) | Toda extração de zips IBGE |
| `add_geography_cols()` | [R/add_geography_cols.R](../../R/add_geography_cols.R) | Geo cols em todos os anos (1960–2022) |
| `add_state_info()` / `add_region_info()` | [R/support_fun.R](../../R/support_fun.R) | Codificação de UF/região em tudo |
| `convert_raw_to_parquet()` | [R/convert_raw_to_parquet.R](../../R/convert_raw_to_parquet.R) | Núcleo de parsing fwf de microdados |
| `write_censobr_parquet()` | [R/support_fun.R](../../R/support_fun.R) | Política de compressão zstd-22 |
| `get_schema()` | [R/schema_col_classes.R](../../R/schema_col_classes.R) | Schemas Arrow de microdados |
| `_targets.R` (estrutura geral) | [_targets.R](../../_targets.R) | Orquestração do pipeline |
| `read_guides/*.csv` | [read_guides/](../../read_guides/) | Dicionários fwf por ano/dataset |
| `UF_SIGLAS` | [R/support_fun.R](../../R/support_fun.R) | Iteração por UF em todos os pipelines |

## Anti-padrões proibidos

- Editar 3+ arquivos `R/` em uma única mudança sem plano aprovado.
- Alterar `add_geography_cols()` para resolver problema de um ano específico (refatorar por baixo do tapete).
- Modificar `support_fun.R` E o pipeline de um ano ao mesmo tempo (mistura camada compartilhada com lógica específica).
- Re-rodar `tar_destroy()` sem entender o que vai recomputar (gargalo de FTP IBGE).
- Fazer "fix" iterativo cego: editar → tar_make → falha → editar → tar_make sem entender a causa raiz.
- Adicionar pacote em `tar_option_set(packages = ...)` sem necessidade comprovada (afeta reprodutibilidade).
- **Introduzir paths absolutos** (`R:/`, `C:/Users/`) em qualquer arquivo `R/` ou `_targets.R`.
- Mexer em código de `..\censobr\` (proibido por hook — ver `scope.md`).

## Escopo por subdiretório

| Subdiretório | O que pode mudar | Cuidado |
|---|---|---|
| `R/` | Funções no pipeline `targets` ativo | Reprodutibilidade. Tudo aqui é executado por `tar_source()`. |
| `read_guides/` | Adicionar dicionários novos | NÃO alterar dicionários existentes sem plano (afeta parsing). |
| `_targets.R` | Adicionar/remover targets | Mudanças aqui invalidam dependências em cascata. |
| `.claude/` | Rules, hooks, settings | Versionado para o time. |
| `..\censobr\` | **NADA** | Read-only. Hook bloqueia. |

## Checklist antes de qualquer commit

- [ ] Mudança é mínima e focada em UM objetivo.
- [ ] Nenhuma função protegida foi alterada sem plano aprovado.
- [ ] Validação concreta executada (smoke test, comparação, leitura do parquet).
- [ ] `tar_make()` no(s) target(s) afetado(s) passa.
- [ ] Sem paths absolutos novos em `R/` ou `_targets.R`.
- [ ] Sem menção a AI/Claude no commit, código ou docs.