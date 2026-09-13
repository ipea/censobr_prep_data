# Microdados 1980: DBF do FTP IBGE × amostra preparada

**Data:** 2026-09-11
**Motivo:** decidir qual é a fonte canônica do porte de 1980 para o `targets`

---

## Conclusão

A **amostra preparada** (CSVs de 2018, hoje convertidos em parquet no
`release_legacy`) é a fonte canônica. A republicação em DBF que o IBGE colocou
no FTP em 2025 **perde quatro variáveis** e não ganha nenhuma.

## O que o DBF do FTP perde

Verificado abrindo `CD80PES11.DBF` (Rondônia) direto: **61 colunas**, e o bloco
de migração termina em `MITEMPMU`:

```
MINACION  MIUFNASC  MINASCMU  MIMUMOZN  MIANTEZN  MITEMPUF  MITEMPMU
MIUFANT existe? FALSE
```

| Variável | O que é | No DBF | Na amostra preparada |
|---|---|---|---|
| `V518` | **UF e/ou município anterior** | ausente | preenchida |
| `V3` | Mesorregião | ausente | 0% NA |
| `V4` | Microrregião | ausente | 0% NA |
| `V6` | Distrito | ausente | 0% NA |

Some ainda o `idpessoa`, que é identificador sequencial e se reconstrói — mas
com valores diferentes dos publicados.

### Por que a `V518` é a perda que pesa

`V518` é o **único item do bloco de migração que identifica geograficamente a
origem**. As vizinhas dizem se a pessoa nasceu no município (`V513`), se morava
em zona urbana ou rural aqui (`V514`) e lá (`V515`), e há quantos anos mora na
UF (`V516`) e no município (`V517`) — mas só a `V518` diz **de onde veio**.

É um código de 6 dígitos, `UF(2) + Município(4)`, no mesmo espaço de códigos do
município atual. Duas provas empíricas nos 29,4 milhões de registros
publicados:

- os 3.991 códigos distintos da `V518` são **exatamente** o mesmo conjunto dos
  3.991 valores de `code_muni_1980`;
- a `V518` **nunca** é igual ao município atual da própria linha: 0
  coincidências em 6.312.593 registros.

**Não é reconstruível** a partir do DBF: nada mais lá carrega a origem
geográfica.

### A armadilha do `"0"`

`V517` é o filtro, e a partição é exata:

| Estado da `V518` | Registros | % | Quem é |
|---|---:|---:|---|
| `NA` | 17.111.136 | 58,2% | `V517 = 8` ("nasceu aqui"); 100,00% nasceram na UF onde moram |
| `"0"` | 5.955.024 | 20,3% | `V517 = 7` (10 anos ou mais): **migrantes antigos, origem não codificada** — 35,9% nasceram em outra UF |
| código | 6.312.593 | 21,5% | `V517` de 0 a 6: migrantes recentes |

Ou seja, `"0"` **não** significa "não migrou". Quem quiser o estoque de
migrantes usa `V517 != 8`, não `V518 != NA`. E `"0"` é a string de um
caractere, não `"000000"` — qualquer `substr(V518, 1, 2)` precisa de guarda.

Outro detalhe: o prefixo de UF da `V518` usa o codespace moderno 11–53,
enquanto a `V512` (naturalidade) usa a codificação sequencial de 1980 (1=RO …
27=DF). Cruzar as duas sem traduzir produz resultado silenciosamente errado.

## Nota sobre as referências internas

Os arquivos de maio (`references/microdata_1980_col_mapping.csv`) marca `MIUFANT → V518` com evidência
"A+B+C+v050", sugerindo que a coluna existiria no DBF. **Está errado** — a
verificação direta no DBF mostra que não existe. O que ocorreu é que a
documentação XLS do IBGE 2025 omite a linha de três variáveis (`V517`, `V518`,
`V521`); na reconciliação manual as três foram restauradas em bloco, mas só
`V517` e `V521` estão de fato no dado.

## Divergências intencionais vs o publicado

O porte para o `targets` introduz três diferenças deliberadas em relação aos
parquets de v0.5.0/v0.6.0:

1. **`code_micro` corrigida.** O ramo 1980 de `add_geography_cols()` atribui
   `V3` tanto a `code_meso` quanto a `code_micro`, e ignora `V4`. Medido no
   publicado: `code_micro == code_meso` em 6.716.885 de 6.716.885 linhas, com
   89 valores distintos onde `V4` tem 361. Quem usa `code_micro` hoje está
   agregando por mesorregião. O porte usa `code_micro = V4`.
2. **`Observation` removida.** Coluna de nota de trabalho do crosswalk de
   Tocantins/Fernando de Noronha, vazada para o produto por um `left_join` que
   só removia a outra coluna. Preenchida em 53 municípios.
3. **Ordem das linhas.** O porte preserva a ordem da amostra preparada
   (começa em Rondônia). O publicado começa em Fernando de Noronha: o
   `left_join` do crosswalk, no script legado, içou as 53 linhas casadas para o
   topo. Conteúdo idêntico — verificado por distribuição por UF, somas de
   colunas numéricas e comparação após ordenação.

Fora isso, households bate exatamente: 6.716.885 linhas, mesmas colunas na
mesma ordem, `code_muni` com 35.567 NAs e 3.938 valores distintos nos dois.
