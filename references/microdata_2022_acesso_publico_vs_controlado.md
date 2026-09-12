# Microdados da amostra do Censo 2022: acesso público × controlado

**Data:** 2026-09-11
**Fonte:** FTP do IBGE, Notas metodológicas 03/2026 e 05/2026, e os dois arquivos
de layout oficiais (`Layout Microdados CD2022 - acesso {Público,Controlado}.xlsx`)
**Motivo:** fundamentar o porte da amostra pública de 2022 para o pipeline
(`R/microdata_2022.R`, bloco `# 06.` do `_targets.R`)

---

## 1. O que o IBGE publicou

Em **31/08/2026** o IBGE divulgou os microdados da amostra do Censo 2022, pela
primeira vez em **CSV** além do TXT de largura fixa. São quatro registros —
**Domicílios, Pessoas, Família e Mortalidade**. Não há registro de emigração
(que existia em 2010).

FTP: `https://ftp.ibge.gov.br/Censos/Censo_Demografico_2022/Microdados_e_Areas_de_Ponderacao/`

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
separador `;`, com header, vazio como `NA`.

## 2. Os três níveis de acesso

| Nível | Geografia máxima | Obtenção | Pode ser redistribuído? |
|---|---|---|---|
| 1 — Público | **Unidade da Federação** | download direto do FTP, sem cadastro | **sim** |
| 2 — Controlado | **Área de Ponderação** | gov.br + CNPJ institucional + Termo de Compromisso assinado | **não** |
| 3 — Restrito | base completa, sem subamostragem | projeto aprovado por comitê; presencial na Sala de Acesso a Dados Restritos (Rio) | não |

**O nível 2 é rastreável por pessoa.** Cada pesquisador autorizado recebe uma
versão personalizada dos arquivos, identificada por uma sequência numérica
exclusiva e sigilosa. O Termo veda "publicar ou disponibilizar os arquivos em
repositórios, plataformas de armazenamento em nuvem ou outros ambientes
acessíveis a terceiros".

**Consequência para o `censobr`:** só o nível 1 pode virar asset de release. O
nível 2 é tratado no consumidor por `censobr::import_microdata22_controlado()`,
que o próprio pesquisador roda sobre o zip que recebeu do IBGE, gravando no
cache local sem redistribuir nada.

## 3. Tratamentos de confidencialidade no nível público

Da Nota metodológica 03/2026 (não desfazer nenhum deles — são a fonte):

- **Subamostra de 50%** dos domicílios em setores com fração amostral de 100%
  (~116 mil domicílios, ~1,5% do total), com reponderação.
- **Idade recodificada em faixas quinquenais**, com topo em 80 anos ou mais.
- **Supressão local** de sexo e idade em registros de risco, e por arrasto das
  variáveis de fecundidade que dependem do sexo. Aparece como `P0150 = 9` e
  `P0180 = 99` — em RR são 1.048 pessoas (1,2%).
- **Supressão global** de ~50 domicílios que seguiram com risco alto.
- **Variáveis semi-identificadoras com muitas categorias** ficaram fora do
  público (ocupação, atividade, religião detalhada, municípios de
  nascimento/residência anterior/trabalho/estudo, área do curso superior).
- **Pesos recalibrados.** No público a calibração garante coincidência com o
  SIDRA apenas para **população total no nível de UF**; no controlado, para
  população total e por sexo no nível de área de ponderação. Qualquer outro
  indicador pode divergir das tabulações oficiais.

## 4. Comparação dos dois layouts (verificada variável a variável)

Método: os dois xlsx foram achatados (`var`, `nome`, posições, `INT`, `DEC`,
`TIPO`) e comparados por `merge` nas variáveis comuns.

**Resultado:**

- **256 variáveis comuns.** Em todas as 256: mesmo rótulo, mesmas categorias,
  mesma largura (`INT`), mesmos decimais (`DEC`), mesmo tipo. **Zero divergência
  semântica.**
- **A posição FWF difere em 248 das 256.** Os dois são arquivos físicos
  distintos — reaproveitar as posições de um para ler o outro corromperia
  tudo. É a razão de o pipeline ler o **CSV**, que traz header, e não o TXT.

| Registro | Público | Controlado |
|---|---|---|
| DOMI (`households`) | 55 | 64 |
| PESS (`population`) | 168 | 210 |
| FAMI (`families`) | 23 | 31 |
| MORT (`mortality`) | 14 | 25 |

### 4.1. A armadilha do peso amostral

| | Público | Controlado |
|---|---|---|
| Domicílios | `D0110` | `D0111` |
| Pessoas | `P0110` | `P0111` |
| Família | `F0110` | `F0111` |
| Mortalidade | `M0110` | `M0111` |

Mesma variável conceitual (3 inteiros + 13 decimais), código diferente. Código
que espere `P0111` não acha peso nenhum no arquivo público, e vice-versa.

### 4.2. O que só existe no controlado

- **Geografia fina:** `*0030` mesorregião, `*0040` microrregião, `*0050` região
  geográfica intermediária, `*0060` região geográfica imediata, `*0070`
  concentração urbana, `*0080` município, `*0090` área de ponderação.
- **Versões contínuas do que o público traz categorizado:** `P0181` (idade em
  anos) e `P0190` (idade em meses) contra `P0180` (faixa); idem `D0181`,
  `M0171`, `F0181`.
- **Sexo sem supressão:** `P0160` (o `P0150`, presente nos dois, é a versão
  tratada) e `D0171`.
- **Códigos detalhados:** `P0970` ocupação, `P0980` atividade, `P0411` religião,
  `P0500`/`P0580`/`P0620`/`P0820`/`P1140` municípios de nascimento, moradia
  anterior, moradia há 5 anos, estudo e trabalho, `P0510`/`P0590`/`P0630`/
  `P0830`/`P1150` os países correspondentes, `P0750` área do curso superior,
  `P1030` atividade principal, `P1040` grandes grupos ocupacionais, `M0151`
  mês/ano do óbito.
- **As marcas de imputação** dessas variáveis (`MP0181`, `MP0500`, …).

## 5. Tipagem adotada no pipeline

Regra derivada do layout público, igual à que o consumidor documentou para o
controlado (`R/schema_col_classes.R`, ramo `year == 2022`):

- `DEC > 0` → `double()` — são 7 variáveis: os 4 pesos (13 decimais) e
  `D0240`, `D0360`, `F0260` (2 decimais sobre 9 inteiros).
- senão, inteiro dimensionado por `INT`: `<= 2` → `int8()`, `3-4` → `int16()`,
  `5-9` → `int32()`.
- **Não há `INT >= 10` no layout público**, logo não há `int64()` — ao
  contrário do controlado, onde a área de ponderação estoura 32 bits.
- `F0101` e `M0101` → `string()`: carregam letra no valor (`"F001"`, `"M001"`).
  `P0101` parece com elas mas é contagem, fica inteiro.

Os tipos conferem, variável a variável, com os que o consumidor verificou
empiricamente contra os dados do controlado, em todas as 256 variáveis comuns.

Declarar o schema também evita que o `arrow` tipe como `null` as colunas que
estão em branco no primeiro bloco do primeiro arquivo que lê.

## 6. Geografia no parquet público

Como o público para na UF, o pipeline anexa apenas:

`code_region`, `name_region`, `code_state`, `abbrev_state`, `name_state`

derivadas de `*0020` via `states_censobr()`, com `code_*` em `numeric`
(convenção v0.6.0). **Não há `code_muni` nem `code_weighting`** — uma quebra de
expectativa em relação a todas as edições de 1960 a 2010.

Por isso a geografia entra inline em `save_microdata_2022()` e não via
`add_geography_cols()`: aquela função pressupõe uma coluna de município, a
coluna de origem muda de nome conforme a tabela (`D0020`/`P0020`/`F0020`/`M0020`),
e o ramo `year == 2022` dela já pertence aos setores (`CD_MUN`).

## 7. Validação

Parquets nacionais produzidos pelo pipeline em 2026-09-11:

| Tabela | Arquivo | Linhas | Colunas |
|---|---:|---:|---:|
| households | 137,3 MB | 7.689.914 | 60 (55 + 5 geo) |
| population | 609,8 MB | 21.538.508 | 173 (168 + 5 geo) |
| families | 95,1 MB | 6.550.107 | 28 (23 + 5 geo) |
| mortality | 5,5 MB | 430.961 | 19 (14 + 5 geo) |

- **Linhas idênticas às dos CSVs brutos** nas 4 tabelas (conferido com `wc -l`).
- **Pesos batem com o SIDRA (tabela 4709) nas 27 UFs, diferença de 0%.** Brasil:
  `sum(P0110)` = **203.080.756**, exatamente a população divulgada do Censo 2022.
  Roraima, a menor UF: 636.707. É a confirmação simultânea de schema, leitura e
  calibração.
- **Nenhuma coluna 100% NA** em nenhuma tabela — a tipagem do schema está
  correta nas 265 colunas.
- Supressões preservadas: `P0150 = 9` em 19.216 pessoas.

## 8. `Controle` é único nacionalmente

Verificado no parquet nacional: **7.689.914 valores distintos de `D0100` para
7.689.914 domicílios**. Logo o join domicílio↔pessoa (`D0100` ↔ `P0100`) não
precisa da UF na chave, e `(P0100, P0101)` identifica a pessoa. As faixas de
valores se sobrepõem entre UFs, mas não há colisão — é uma sequência nacional.

## 9. Padrão de nome

Decidido em 2026-09-11, e é o que o pipeline grava:

```
2022_<tabela>.publico_<data_version>.parquet
2022_<tabela>.controlado_<data_version>.parquet
```

O sufixo de modalidade entra no **token da tabela**, não como um quarto campo:
o nome segue com três campos separados por `_` (ano, tabela, versão), do mesmo
jeito que todas as outras edições. Pontos já fazem parte do padrão — a própria
versão tem dois.

Marcar as **duas** modalidades, e não só a controlada, é deliberado: quem já
importou a amostra controlada tem no cache um arquivo com o nome sem sufixo, e
um asset público sem marcação colidiria exatamente com ele — mesmo nome, mas
com o peso em `*0110` em vez de `*0111` e sem a geografia fina.
