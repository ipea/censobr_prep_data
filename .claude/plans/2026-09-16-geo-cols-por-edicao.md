# Plano: as variantes históricas saem de GEO_COLS_CENSOBR

**Status:** APROVADO — pedido explícito do usuário em 2026-09-16
**Data:** 2026-09-16

## Contexto

O commit `8d731aa` acrescentou `code_bairro_1960` a `GEO_COLS_CENSOBR`
(`R/support_fun.R`) para levar o código do bairro da Guanabara ao parquet. Uma
linha. O efeito: **todos os onze alvos `output_*` do pipeline ficaram
desatualizados**, de 1970 a 2022, setores inclusive — 42 parquets para reescrever
sem que um único dado mudasse fora de 1960.

A causa é estrutural. `relocate_geo_cols_censobr()` lê um objeto global, e o
`targets` inclui esse objeto no hash de dependências de todo alvo que chama a
função — e a função é chamada em todo `save_*`, nos doze pontos. Mexer num
elemento do vetor invalida os doze.

O que torna isso desnecessário: as 14 entradas com sufixo de ano existem **numa
edição só**. `*_1960` só aparece em 1960, `*_1970` em 1970, `*_1980` em 1980.
São justamente elas que mudam; a parte transversal (`code_region` até `area_km2`)
é estável.

## Objetivo

Que acrescentar uma coluna histórica de uma edição invalide **só aquela edição**.

## Abordagem

- `GEO_COLS_CENSOBR` fica só com as colunas transversais.
- `relocate_geo_cols_censobr(df, extra = NULL)` ordena por
  `c(GEO_COLS_CENSOBR, extra)`.
- Cada edição histórica passa a sua lista, definida no seu próprio arquivo:
  `GEO_COLS_HIST_1960` (10 colunas), `GEO_COLS_HIST_1970` (3), e `"code_muni_1980"`
  inline, por ser uma só.

A ordem publicada não muda: as variantes já vinham no fim do vetor canônico, e
nenhuma tabela carrega colunas do ano de outra edição.

## Custo

Uma invalidação única de toda a camada `save_*` — que no momento é grátis, porque
o `8d731aa` já invalidou todos eles. Feita junto da corrida completa que 1960
exige de qualquer forma, não custa nada.

## Arquivos a modificar

- [ ] `R/support_fun.R` — constante e assinatura da função (função protegida; é o cerne deste plano).
- [ ] `R/microdata_1960.R` — `GEO_COLS_HIST_1960` e a chamada.
- [ ] `R/microdata_1970.R` — `GEO_COLS_HIST_1970` e as duas chamadas.
- [ ] `R/microdata_1980.R` — a chamada, com a coluna inline.
- [ ] `CLAUDE.md` — a convenção passa a descrever a separação.

## Validação

- [ ] `parse()` em tudo que mudou.
- [ ] **Teste de regressão de ordem**: para o conjunto de colunas de cada parquet publicado (1960, 1970, 1980, 1991, 2000, 2010, 2022 e os três de setores), a ordem produzida pela função nova tem de ser idêntica à da versão em `git HEAD`.
- [ ] Nenhum alvo fora de 1960/1970/1980 muda de estado por causa desta mudança (verificado depois da corrida completa).
