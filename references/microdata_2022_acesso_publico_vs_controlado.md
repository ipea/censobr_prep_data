# Microdados da amostra do Censo 2022: o acesso público, o acesso controlado e o produto

**Data:** 2026-09-13 (substitui a versão de 2026-09-11)
**Escopo:** a amostra do Censo Demográfico 2022 publicada pelo IBGE em 31/08/2026 — os três níveis de acesso, os tratamentos de confidencialidade do nível público, as diferenças entre os dois layouts oficiais, e o que o produto `censobr` contém.
**Fontes:** FTP do IBGE; Notas metodológicas 03/2026 e 05/2026; `Layout Microdados CD2022 - acesso {Público,Controlado}.xlsx`.

---

## O que o IBGE publicou

Em 31/08/2026 o IBGE divulgou os microdados da amostra do Censo 2022, pela
primeira vez em CSV além do TXT de largura fixa. São quatro registros —
Domicílios, Pessoas, Família e Mortalidade. Não há registro de emigração,
que existia em 2010.

`https://ftp.ibge.gov.br/Censos/Censo_Demografico_2022/Microdados_e_Areas_de_Ponderacao/`

```
Microdados_de_acesso_Publico/
    csv/    27 zips por UF (11_RO.zip … 53_DF.zip) + Todas_as_UFs.zip (1,0 GB)
    txt/    idem, em largura fixa
Areas_de_Ponderacao/    tabelas_ods.zip, tabelas_xlsx.zip
Documentacao/           Leia-me.pdf, layouts, dicionário de variáveis,
                        notas metodológicas, instrumentos de coleta,
                        bancos de descritores, divisão territorial
```

Dentro de cada zip: `{Domicilios,Familia,Mortalidade,Pessoas}_<código UF>_publico.csv`,
separador `;`, com cabeçalho, vazio como NA.

## Os três níveis de acesso

| nível | geografia máxima | obtenção | redistribuível? |
|---|---|---|---|
| 1 — público | Unidade da Federação | download do FTP, sem cadastro | sim |
| 2 — controlado | área de ponderação | gov.br + CNPJ institucional + Termo de Compromisso | não |
| 3 — restrito | base completa, sem subamostragem | projeto aprovado por comitê; presencial na Sala de Acesso a Dados Restritos (Rio) | não |

O nível 2 é rastreável por pessoa: cada pesquisador autorizado recebe uma
versão personalizada dos arquivos, identificada por sequência numérica
exclusiva e sigilosa, e o Termo veda "publicar ou disponibilizar os arquivos
em repositórios, plataformas de armazenamento em nuvem ou outros ambientes
acessíveis a terceiros". Só o nível 1 pode virar asset de release, e é o
único que este pipeline produz.

## Tratamentos de confidencialidade no nível público

Da Nota metodológica 03/2026 — são a fonte, e o produto não desfaz nenhum:

- **Subamostra de 50%** dos domicílios em setores com fração amostral de
  100% (cerca de 116 mil domicílios, 1,5% do total), com reponderação.
- **Idade em faixas quinquenais**, com topo em 80 anos ou mais.
- **Supressão local** de sexo e idade em registros de risco, e por arrasto
  das variáveis de fecundidade que dependem do sexo: `P0150 = 9` e
  `P0180 = 99`. No produto, `P0150 = 9` em 19.216 pessoas (1.048 em RR,
  1,2%).
- **Supressão global** de cerca de 50 domicílios que seguiram com risco alto.
- **Variáveis semi-identificadoras com muitas categorias** ficaram fora do
  público: ocupação, atividade, religião detalhada, municípios de
  nascimento, residência anterior, trabalho e estudo, área do curso superior.
- **Pesos recalibrados.** No público a calibração garante coincidência com o
  SIDRA só para a população total no nível de UF; no controlado, para
  população total e por sexo no nível de área de ponderação. Qualquer outro
  indicador pode divergir das tabulações oficiais.

O controle de domicílio `D0100` é uma sequência nacional com lacunas: vai de
1 a 7.806.723, com 7.689.914 valores presentes e 116.809 ausentes (1,50%) —
os domicílios eliminados pela subamostra e pela supressão global. Como é
única no país, o join domicílio ↔ pessoa (`D0100` ↔ `P0100`) não precisa da
UF, e `(P0100, P0101)` identifica a pessoa.

## Os dois layouts, variável a variável

Os dois xlsx foram achatados (`var`, `nome`, posições, `INT`, `DEC`, `TIPO`)
e comparados nas variáveis comuns.

| registro | público | controlado |
|---|---:|---:|
| DOMI (`households`) | 55 | 64 |
| PESS (`population`) | 168 | 210 |
| FAMI (`families`) | 23 | 31 |
| MORT (`mortality`) | 14 | 25 |

- **256 variáveis comuns**, todas com o mesmo rótulo, as mesmas categorias,
  a mesma largura, os mesmos decimais e o mesmo tipo.
- **A posição no TXT difere em 248 das 256.** São arquivos físicos
  distintos; as posições de um não leem o outro. O pipeline lê o CSV, que
  tem cabeçalho.
- **O peso tem código diferente:** `D0110`, `P0110`, `F0110`, `M0110` no
  público; `D0111`, `P0111`, `F0111`, `M0111` no controlado. Mesma variável
  (3 inteiros + 13 decimais). Código que espere `P0111` não acha peso no
  arquivo público.
- **Só no controlado:** a geografia fina (`*0030` mesorregião, `*0040`
  microrregião, `*0050` região intermediária, `*0060` região imediata,
  `*0070` concentração urbana, `*0080` município, `*0090` área de
  ponderação); as versões contínuas do que o público traz em faixa (`P0181`
  idade em anos, `P0190` em meses, contra `P0180`; idem `D0181`, `M0171`,
  `F0181`); sexo sem supressão (`P0160`, `D0171`; o `P0150` dos dois é a
  versão tratada); os códigos detalhados (`P0970` ocupação, `P0980`
  atividade, `P0411` religião, `P0500`/`P0580`/`P0620`/`P0820`/`P1140`
  municípios, `P0510`/`P0590`/`P0630`/`P0830`/`P1150` países, `P0750` área
  do curso, `P1030`, `P1040`, `M0151` mês/ano do óbito); e as marcas de
  imputação dessas variáveis (`MP0181`, `MP0500`, …).
- No controlado, seis variáveis da tabela de pessoas excedem 32 bits: a
  área de ponderação e os cinco códigos de país. No público, nenhuma
  variável tem `INT ≥ 10`.

## O que o produto contém

Quatro parquets nacionais, `2022_<tabela>.publico_<versão>.parquet` — o
sufixo de modalidade entra no token da tabela, e o nome mantém os três
campos separados por `_` das outras edições. Nenhum arquivo `.controlado` é
produzido aqui.

| tabela | bytes (v0.7.0) | MiB | linhas | colunas |
|---|---:|---:|---:|---:|
| households | 144.295.923 | 137,61 | 7.689.914 | 60 (55 + 5) |
| population | 639.194.018 | 609,58 | 21.538.508 | 173 (168 + 5) |
| families | 99.697.955 | 95,08 | 6.550.107 | 28 (23 + 5) |
| mortality | 5.762.231 | 5,50 | 430.961 | 19 (14 + 5) |

280 colunas ao todo: 260 variáveis do IBGE e 5 de geografia em cada tabela —
`code_region`, `name_region`, `code_state`, `abbrev_state`, `name_state`,
derivadas de `*0020`, com `code_*` em `numeric`. Não há `code_muni` nem
`code_weighting`, porque o público para na UF. `code_weighting` existe nos
produtos de 2000 e 2010; 1970, 1980 e 1991 não a têm, e 1960 não tem
`code_muni` (só `code_muni_1960` e `name_muni`, pela malha de 1960). A geografia entra inline em `save_microdata_2022()`, não
por `add_geography_cols()` — a coluna de origem muda de nome por tabela
(`D0020`/`P0020`/`F0020`/`M0020`) e o ramo `year == 2022` daquela função
pertence aos setores (`CD_MUN`).

Tipos: na leitura do CSV o pipeline declara o schema derivado do layout
público (`R/schema_col_classes.R`, ramo `year == 2022`), o que evita que o
`arrow` tipe como `null` as colunas em branco no primeiro bloco do primeiro
arquivo lido. No parquet publicado vale a convenção de tipos do produto
(`schemas/censobr_types.csv`): `double` nas sete variáveis com decimais — os
quatro pesos (13 decimais), `D0240` (moradores por dormitório, 2 inteiros e 2
decimais), `D0360` e `F0260` (rendimentos per capita, 9 inteiros e 2
decimais) —; `int32` em todas as demais, que são inteiras e cabem; `string`
em `F0101` e `M0101`, que carregam letra no valor (`"F001"`, `"M001"`),
enquanto `P0101` é contagem e fica inteira. Não há `int8`/`int16` no produto.

Verificações:

- linhas idênticas às dos CSVs brutos nas quatro tabelas;
- `sum(P0110)` = 203.080.756, a população divulgada do Censo 2022; bate com
  o SIDRA (tabela 4709) nas 27 UFs com diferença 0 (RR, a menor: 636.707);
- nenhuma coluna 100% NA em nenhuma tabela;
- 7.689.914 valores distintos de `D0100` para 7.689.914 domicílios.
