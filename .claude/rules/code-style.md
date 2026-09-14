---
name: code-style
description: Estilo de escrita de código R, convenção de nomeação censobr, e adaptação ao targets. Aplica-se a todo R do projeto. Codifica o estilo procedural do usuário (Rogério) e barra padrões verbosos/defensivos típicos do AI-default.
paths:
  - "**/*.R"
  - "_targets.R"
---

# Estilo de código, nomeação `censobr` e adaptação a `targets`

**Status:** OBRIGATÓRIA
**Escopo:** todo código R em `censobr_prep_data` (atual e futuro). Aplica-se a todo código novo e a todo bloco tocado em `R/`.
**Complementar a:** [`memory-discipline.md`](memory-discipline.md) (regra-irmã, foco em performance/memória).

## Por que existe

Em 2026-05-03 o usuário sinalizou explicitamente que o estilo de código que o AI vinha escrevendo (verboso, defensivo, com helpers privados, comentários multi-parágrafo, mensagens com `sprintf`) era diferente do estilo dele e prejudicava legibilidade. Esta regra codifica o estilo procedural do usuário, observado nos 3 projetos de referência (Desigualdade Pobreza Bem-Estar TD-IPEA, Educação Performance, EJA), para que o código novo deste pipeline siga padrões consistentes.

A regra também codifica a convenção de nomeação `censobr` (que o consumidor expõe ao usuário final) e a adaptação correta ao `targets`.

Os 3 projetos de referência (paths em memória `reference_user_style_projects`):
- `D:\Dropbox\Artigos\4 - Publicados\Desigualdade_Pobreza_BemEstar_Decada2010_TD_IPEA\2_Scripts`
- `G:\Drives compartilhados\Dominios_Territoriais\Projeto_Educacao\Artigo_Efeitos_Performance\2_Scripts`
- `G:\Drives compartilhados\Dominios_Territoriais\Projeto_EJA\2_Scripts`

## 1. Estilo procedural

### Sem encapsulamento prematuro

- Objetos nomeados em sequência. Reatribuição em passos: `df <- df %>% ...` repetido em vez de mega-pipe.
- Sem helpers privados `.dot_prefixed` para uso único — inlinar.
- Função só quando há matemática reutilizável (`Sum`, `inverse`, `arcsinh`, `make_lorenz`).
- No mundo `targets`: 1 função pública por target. **Corpo da função = script procedural** (não quebrar em sub-funções para "encapsular" — ver seção 4).

### Comentários

- Narrativos curtos (1–3 linhas) explicando o **porquê analítico**, não **o quê** o código faz.
- Sem multi-parágrafo de design dentro do código. Sem stacktrace de investigação. Sem doc de bug.
- Doc de bug, design rejeitado, "KNOWN REGRESSION vs vX.Y", investigação anterior — vai no commit message ou em plano em `.claude/plans/`, não no código.
- Comentário inline curto à direita do item (`"upa", # ID dom 1`) é OK.

### Mensagens

- `message("Saving Basico")`, `message(uf)`. Curtas.
- Sem `sprintf("  [#68 fix] %s: renaming %d cols matching ^V\\d{2}$ -> V0xx (e.g., %s)", ...)`.

### Defensividade

- Confiar em funções idempotentes: `make.unique` é no-op se não há duplicata; `%in%` cobre NA; `as.numeric` retorna NA com warning para não-numéricos.
- Não usar `if(any(duplicated(...)))` antes de `make.unique`. Não usar `if(!is.na(uf))` antes de `uf %in% c("GO","SP1","SP2")` (`%in%` retorna FALSE para NA).
- `stop()` / `warning()` apenas quando uma invariante analítica é violada (ex.: "components do not add up to total"). Não para verificação que o R já faria.
- Sem `tryCatch` por hábito. Código falha alto.

### Formatação

- Indent 2 espaços.
- `=` alinhado verticalmente em listas de pares (`mutate`, `rename`, `select`, `summarise`):
  ```r
  rename(rendaTrab_ha    = vd4019,
         rendaTrab_ef    = vd4020,
         rendaBPC        = v5001a2,
         rendaBolsaFam   = v5002a2)
  ```
- Linha em branco dentro de listas grandes para agrupar visualmente.
- Pipe `|>` (nativo) preferido em código novo. `%>%` aceito onde já está e for cosmético.
- `library()` em bloco no topo. Sem `requireNamespace`, sem `if(!require(…))`.
- `for` é OK quando o loop é honesto. `print(i)` como progresso. `rm(tmp); gc()` por iteração.
- Drop de coluna: `df$X <- NULL` ou `mutate(X = NULL)`. Não `select(-X)` se for só uma coluna.
- `tribble()` para tabelas-literal pequenas (lookup).

### Anti-padrões observados (NÃO REPETIR)

Foram visíveis no diff antigo de `R/census_tracts_2010.R` e na versão AI-style anterior de `R/census_tracts_2022.R` (ambos refatorados em 2026-05-04). Mantemos a lista aqui como **galeria de anti-padrões a evitar** em código novo:

- ❌ Helpers `.dot_prefixed` para uso único (`.match_files_2022`, `.recode_basico_2022`).
- ❌ `vapply(..., FUN.VALUE = logical(1))` defensivo para checks que poderiam ser `sapply` ou inline.
- ❌ `if (length(hits) == 0){ stop("No CSV matched...") }` antes de operação que já falharia com erro descritivo.
- ❌ `sanity check` manual com loops de comparação para verificar coisas que não vão dar errado.
- ❌ Comentários de 5–10 linhas explicando design alternativo testado.
- ❌ `sprintf` em mensagens.
- ❌ `if (...) { ... } else { ... }` com chaves quando `if(...) ... else ...` inline serviria.

## 2. Nomeação `censobr` (canônica)

**As colunas do IBGE ficam com o nome original, em todas as edições e tabelas — nunca renomeadas para o padrão censobr.** As colunas de geografia censobr (`code_*`, `name_*`, `abbrev_state`) são **adicionais**: copiadas ou derivadas das do IBGE via `mutate()`, nunca via `rename()`, e vêm sempre no início da tabela, na ordem de `GEO_COLS_CENSOBR` (`R/support_fun.R`), aplicada por `relocate_geo_cols_censobr()` em todo `save_*`. Decisão do usuário em 2026-09-13. Esquema de nomes visível em `R/census_tracts_2022.R` (bloco de `mutate` do Basico). Aplicar literalmente, sem invenção.

### Identificadores hierárquicos (`code_*`)

`code_tract`, `code_muni`, `code_state`, `code_region`, `code_district`, `code_subdistrict`, `code_neighborhood`, `code_weighting`, `code_meso`, `code_micro`, `code_metro`, `code_favela`, `code_intermediate`, `code_immediate`, `code_aglomerado`, `code_urban_concentration`, `code_nucleo_urbano`, `code_situacao`, `code_type`.

### Nomes humanos (`name_*`)

`name_tract`, `name_muni`, `name_state`, `name_region`, `name_district`, `name_subdistrict`, `name_neighborhood`, `name_meso`, `name_micro`, `name_metro`, `name_favela`, `name_intermediate`, `name_immediate`, `name_aglomerado`, `name_urban_concentration`, `name_nucleo_urbano`.

### Outros

- Sigla de UF: `abbrev_state`.
- Métricas: snake direto (`area_km2`).
- Categorias não-id: snake direto (`situacao`).

### Variáveis V do IBGE

- **Preservadas** com prefixo de tema quando a tabela une vários arquivos IBGE: `pessoa01_V002`, `domicilio02_V135`, `entorno05_V242`. O prefixo é o sub-arquivo IBGE (Pessoa01, Domicilio02, etc.) em lowercase; as colunas não-V desses arquivos (`Situacao_setor`, `Cod_UF`…) recebem o mesmo prefixo.
- Tabelas de arquivo único (Basico, PessoaRenda…) não têm prefixo: `V001`, `Situacao_setor`.
- Não renomear V cols por hipótese de "ficar mais legível" — quebra os dicionários do IBGE que os usuários do `censobr` consultam.

### Convenção de tipos

- Cada coluna publicada tem o tipo declarado em `schemas/censobr_types.csv` (string / float64 / int32, regra mecânica descrita no CLAUDE.md), aplicado por `cast_censobr_types(x, dataset)` como último passo de todo `save_*`, depois de `code_cols_to_numeric()`.
- Não se declara tipo à mão: o CSV sai da medição de toda coluna (scan por arquivo e fatias de colunas, com `memory_limit` no duckdb). Documentado em memória `project_conventions_v0_6_0`.

### Zero invenção

Se uma coluna IBGE não tiver mapping óbvio para uma coluna censobr, ela fica só com o nome original — não se inventa `code_*`/`name_*` novo sem decisão explícita do usuário. A caixa do nome também é a do IBGE (`Cod_UF`, `Nome_da_UF`, `Var01` em 2000); diferenças de caixa entre UFs casam com a grafia do primeiro arquivo (`match_names_2000`).

## 3. Adaptação a `targets`

- `targets` exige funções, mas isso **não autoriza** quebrar lógica em sub-helpers só para "encapsular".
- Padrão: **1 função pública por target.** Corpo da função = script procedural linear (objetos nomeados, reatribuição em passos).
- Se uma operação é chamada em vários temas/anos, vira função em `R/support_fun.R` (e fica protegida — ver `minimal-changes.md`).
- Helpers definidos dentro de uma função são aceitos quando há reuso interno claro (ex.: `prep_state` dentro de `clean_tracts_2010`, chamado por UF). Mas não para coisa chamada uma vez.

## 4. Checklist antes de qualquer commit (parte estilo)

- [ ] Sem helpers `.dot_prefixed` para uso único.
- [ ] Comentários narrativos curtos. Zero docstring multi-parágrafo.
- [ ] Sem `sprintf` em `message()`.
- [ ] Nomes seguem convenção `censobr` (`code_*`, `name_*`, `abbrev_state`, V cols com prefixo de tema).
- [ ] Sem renomeação criativa de variáveis IBGE.
- [ ] V cols originais preservadas (com prefixo de tema).
- [ ] Sem `tryCatch` por hábito; sem defensividade redundante.
- [ ] `=` alinhado em listas de pares.
- [ ] 1 função pública por target; corpo procedural.

(O checklist completo de pré-commit também inclui itens de [`memory-discipline.md`](memory-discipline.md).)

## 5. Quando esta regra entra em conflito com código existente

- Código novo (refactor, novo target, novo ano): **aplicar a regra integralmente.**
- Código existente que funciona e não tem outra dívida sendo paga: **deixar como está.** Refactor de estilo é trabalho separado, não oportunista.
- Ao tocar um arquivo existente para outro motivo: aplicar a regra na função/bloco tocado, não no arquivo inteiro (ver `minimal-changes.md`).