# Inventário de colunas — microdata 1980

**Data:** 2026-05-05  |  **Fase:** 1 (verificação tripla concluída + decisões aprovadas)
**Status:** APROVADO 2026-05-05 — pronto para Fase 2 (pipeline).

## Decisões aprovadas pelo usuário (2026-05-05)

1. **V598 (Situação da pessoa)** = recoding binário urbano/rural derivado de V198 (Situação do Domicílio do DBF dom). Pipeline: `V598 <- ifelse(V198 %in% c(1, 3), 0L, 1L)` (0=urbano, 1=rural). Cross-tab em sample de 50k linhas v0.5.0 confirma 100% match: V198∈{1} → V598=0; V198∈{5,7} → V598=1.
2. **SANUSO → V208 e PESOD → V603** aceitos com 2-source verification (B+C concordam; A doc IBGE 2025 silenciou).
3. **JOIN dom→pes para 23 vars** aplicar (preserva paridade v0.5.0 que denormaliza vars de domicílio em pessoas).

**Cobertura final v0.5.0:** 100%.
- Households 29/29: 26 mapeados FTP + 3 deriváveis via geobr (V3/V4/V6).
- Population 89/89: 62 mapeados + 23 JOIN_FROM_HH + 3 geobr + 1 V598 derivada de V198.

## Fontes consultadas (verificação tripla)

- **A** — `Layout/Documentação.xls` extraído do zip `Microdados_Censo_Demografico_1980_Amostra.zip` no FTP IBGE (versão 2025-01-09).
  Sheets: `Pessoa` (60 vars) + `Domicílio` (25 vars). Na coluna *Rótulo* o IBGE 2025 inclui o V-code histórico no formato `NNN-Descrição` para a maioria das variáveis.
- **B** — `domicilios1980_via_PedroSouza.xlsx` (29 vars) + `pessoas1980_via_PedroSouza.xlsx` (67 vars), em `censoBR_aux_Dados/1980/microdados da amostra/dicionario/`.
- **C** — `layout_1980.xlsx`, mesma pasta. Sheets `Households` (43 var-rows com posições FWF) + `Population` (52 var-rows).
- **v0.5.0** — schemas dos parquets `1980_households_v0.5.0.parquet` (29 V-cols) + `1980_population_v0.5.0.parquet` (89 V-cols), baixados do release `ipea/censobr` v0.5.0.

**Auxiliar D** (consultar quando 3 fontes divergirem):
- `Variaveis_Auxiliares/V*.txt` — V211, V512, V525, V530, V542, V550-V554
- `Variaveis_Auxiliares/Censo 1980 - Códigos do Censo de 1980.pdf` + `... Códigos Complementares.pdf`
- `Censo 1980 - Dicionário da Amostra - Versão IBGE.doc`

## Sumário executivo

- **Households:** 26 colunas no DBF FTP, **todas mapeadas** para V-codes em B/C/v050.
  - Cobertura v0.5.0: 26/29 V-cols (89.7%).
  - 3 V-cols faltantes (V3, V4, V6 = mesorregião/microrregião/distrito) — **deriváveis via `geobr::read_municipality(year=1980)`** crosswalk.
- **Population:** 62 colunas no DBF FTP, **todas mapeadas** para V-codes.
  - Cobertura v0.5.0: 62/89 V-cols (69.7%).
  - 27 V-cols faltantes (23 via JOIN com domicílios, 3 deriváveis geo, 1 REAL_DROPPED).

**Achado central:** ZERO variáveis genuinamente novas no IBGE 2025. Todas as 11 colunas inicialmente flagged como `TRULY_NEW` são RENAMES de V-codes existentes (V-codes mudaram, descrição idêntica).

**Anomalia documental:** IBGE 2025 omitiu da `Documentação.xls`:
- `SANUSO` no DBF dom (mapeia a V208 por B+C+v050) — verificação 2 fontes (A silenciou)
- `PESOD` no DBF dom (mapeia a V603 por B+C+v050) — verificação 2 fontes (A silenciou)

**Aliases:** DBF pessoa usa `NDOM` como nome de coluna ao invés de `CONTADOM` (que aparece na doc). Pipeline trata como sinônimo.

## Households — mapping completo

Total: **26** colunas FTP → V-code. Verificação por evidência:

| evidence   |   count |
|:-----------|--------:|
| A+B+C+v050 |      20 |
| B+C+v050   |       6 |

| col DBF (FTP) | V-code | evidência | notas |
|---|---|---|---|
| `UF` | `V2` | B+C+v050 | IDENTIFIER (convencao IBGE/Pedro Souza) |
| `MUNIC` | `V5` | B+C+v050 | IDENTIFIER |
| `CONTADOM` | `V601` | B+C+v050 | IDENTIFIER |
| `SITUACAO` | `V198` | A+B+C+v050 | Situação do Domicílio |
| `ESPECIE` | `V201` | A+B+C+v050 | Espécie do Domicílio |
| `TIPO` | `V202` | A+B+C+v050 | Tipo do domicílio |
| `PAREDES` | `V203` | A+B+C+v050 | Paredes |
| `PISO` | `V204` | A+B+C+v050 | Piso |
| `COBERTUR` | `V205` | A+B+C+v050 | Cobertura |
| `AGUA` | `V206` | A+B+C+v050 | Abastecimento de água |
| `SANESCOA` | `V207` | A+B+C+v050 | Escoadouro |
| `SANUSO` | `V208` | B+C+v050 | MAPPED_WITH_CAVEAT: A doc silenciou; B='Uso', C=208 'Uso', v050 tem V208 |
| `CONDOCUP` | `V209` | A+B+C+v050 | Condição de Ocupação |
| `ALUGUEL` | `V602` | B+C+v050 | RENAME: A doc IBGE 2025 numera como V210, mas B+C+v050 = V602; descrição idêntica 'Aluguel ou Prestação Mensal'. Manter V602 (paridade v050). |
| `TPRESID` | `V211` | A+B+C+v050 | Tempo de Residência |
| `COMODOS` | `V212` | A+B+C+v050 | Total de Cômodos |
| `COMODOR` | `V213` | A+B+C+v050 | Cômodos servindo de dormitório |
| `FOGAO` | `V214` | A+B+C+v050 | Para cozinhar usa |
| `COMBCOZI` | `V215` | A+B+C+v050 | Combustível usado na cozinha |
| `TELEFONE` | `V216` | A+B+C+v050 | Telefone |
| `ILUMINA` | `V217` | A+B+C+v050 | Iluminação Elétrica |
| `RADIO` | `V218` | A+B+C+v050 | Rádio |
| `GELADEIR` | `V219` | A+B+C+v050 | Geladeira |
| `TV` | `V220` | A+B+C+v050 | Televisão |
| `AUTOMOVE` | `V221` | A+B+C+v050 | Automóvel |
| `PESOD` | `V603` | B+C+v050 | MAPPED_WITH_CAVEAT: A doc silenciou; B+C+v050 todos têm V603 (Peso de Domicílio) |

## Population — mapping completo

Total: **62** colunas FTP → V-code. Verificação por evidência:

| evidence   |   count |
|:-----------|--------:|
| A+B+C+v050 |      37 |
| B+C+v050   |      13 |
| A+B+v050   |      12 |

| col DBF (FTP) | V-code | evidência | notas |
|---|---|---|---|
| `UF` | `V2` | B+C+v050 | IDENTIFIER |
| `MUNIC` | `V5` | B+C+v050 | IDENTIFIER |
| `CONTADOM` | `V601` | B+C+v050 | IDENTIFIER |
| `SEXO` | `V501` | A+B+v050 | Sexo (C nao tem) |
| `PARENDOM` | `V503` | A+B+v050 | Relação c/chefe domicílio (C nao tem) |
| `PARENFAM` | `V504` | A+B+v050 | Relação com o chefe (C nao tem) |
| `FAMILIA` | `V505` | A+B+v050 | Família a que pertence (C nao tem) |
| `RELIGIAO` | `V508` | A+B+v050 | Religião (C nao tem) |
| `COR` | `V509` | A+B+v050 | Cor (C nao tem) |
| `MAEVIVA` | `V510` | A+B+v050 | Tem mãe viva (C nao tem) |
| `MINACION` | `V511` | A+B+v050 | Nacionalidade (C nao tem) |
| `MIUFNASC` | `V512` | A+B+v050 | UF de Nascimento (C nao tem) |
| `MINASCMU` | `V513` | A+B+C+v050 | Nasceu neste município |
| `MIMUMOZN` | `V514` | A+B+C+v050 | Neste município morou |
| `MIANTEZN` | `V515` | A+B+C+v050 | Município anterior morava |
| `MITEMPUF` | `V516` | A+B+C+v050 | Tempo Residência UF Atual |
| `MITEMPMU` | `V517` | A+B+C+v050 | Tempo residência Município atual |
| `MIUFANT` | `V518` | A+B+C+v050 | UF do Município anterior |
| `EDSABELE` | `V519` | A+B+C+v050 | Sabe ler e escrever |
| `EDSERIE` | `V520` | A+B+C+v050 | Série que freqüenta |
| `EDGRAU` | `V521` | A+B+C+v050 | Grau que freqüenta |
| `EDCURSNS` | `V522` | A+B+C+v050 | Curso não seriado |
| `EDULSERI` | `V523` | A+B+C+v050 | Última série concluída |
| `EDULGRAU` | `V524` | A+B+C+v050 | Grau da última série concluída |
| `EDCURSTP` | `V525` | A+B+C+v050 | Tipo do último curso concluído |
| `ESTCONJ` | `V526` | A+B+C+v050 | Estado conjugal |
| `TMUNTRAB` | `V527` | A+B+C+v050 | UF do Município trabalha/estuda |
| `TRUL12M` | `V528` | A+B+C+v050 | Trabalhou nos últimos 12 meses |
| `TSITDESO` | `V529` | A+B+C+v050 | Ocupação atual |
| `TOCUPACA` | `V530` | A+B+C+v050 | Ocupação/cargo últimos 12 meses |
| `TATIVIDA` | `V532` | A+B+C+v050 | Finalidade/Ramo do negócio |
| `TPOSICAO` | `V533` | A+B+C+v050 | Posição no estabelecimento |
| `TPREVID` | `V534` | A+B+C+v050 | Contribuição previdência |
| `THORTRAB` | `V535` | A+B+C+v050 | Horas trabalhadas ocup. principal |
| `THORTRTO` | `V536` | A+B+C+v050 | Horas trabalhadas em todas as ocupações |
| `RPRINDIN` | `V607` | B+C+v050 | RENAME: A=V537; B='Rendimento bruto ocup. principal', C='Rendimento médio mensal bruto recebido em dinheiro na ocupação principal'. Mesma var. |
| `RPRINPRM` | `V608` | B+C+v050 | RENAME: A=V538; B='Rendimento prod/merc ocup princ', C='Rendimento médio mensal bruto auferido pelo recebimento de produtos ou mercadorias na ocupação principal'. |
| `ROUTROCU` | `V609` | B+C+v050 | RENAME: A=V539; B='Renda dinh bruto outras ocupação', C='Renda em dinheiro bruto outras ocupações'. |
| `TQTSALAR` | `V540` | A+B+C+v050 | Quantos salários recebe |
| `TSITULSN` | `V541` | A+B+C+v050 | Na última semana estava |
| `TOUTRAOC` | `V542` | A+B+C+v050 | Ocupação não habitual ex |
| `TOUTRAAT` | `V544` | A+B+C+v050 | Finalidade estab. não habitual |
| `TOUTRAPO` | `V545` | A+B+C+v050 | Posição no estab. não habitual |
| `RAPOSENT` | `V610` | B+C+v050 | RENAME: A=V546; B='Rendimento recebido aposentado'. |
| `RALUGUEL` | `V611` | B+C+v050 | RENAME: A=V547; B='Rendimento recebido aluguel'. |
| `RDOACOES` | `V612` | B+C+v050 | RENAME: A=V548; B='Rendimento recebido de doações'. |
| `RCAPITAL` | `V613` | B+C+v050 | RENAME: A=V549; B='Rendimento recebido outros ren.'. |
| `FLNAVIVH` | `V550` | A+B+C+v050 | Filhos tidos nascidos vivos (homens) |
| `FLNAVIVM` | `V551` | A+B+C+v050 | Filhas tidas nascidas vivas (mulheres) |
| `FLNAMORH` | `V552` | A+B+C+v050 | Filhos tidos nascidos mortos |
| `FLNAMORM` | `V553` | A+B+C+v050 | Filhas tidas nascidas mortas |
| `FLVIVOSH` | `V554` | A+B+C+v050 | Filhos vivos na data da pesquisa |
| `FLVIVOSM` | `V555` | A+B+C+v050 | Filhas vivas na data da pesquisa |
| `FLUVIMES` | `V556` | A+B+C+v050 | Mês nascimento últ filho nasc vivo |
| `FLUVIANO` | `V557` | A+B+C+v050 | Ano nasc últ filho nasc vivo |
| `IDADEMES` | `V605` | B+C+v050 | RENAME: A=V560; B+C='Idade em meses' (score 1.00 similaridade) |
| `IDADEANO` | `V606` | B+C+v050 | RENAME: A=V561; B+C='Idade em anos' (score 1.00) |
| `FLUVIDAD` | `V570` | A+B+C+v050 | Idade do último filho |
| `PESOP` | `V604` | B+C+v050 | RENAME: A=V586 'Peso Pessoa'; B+C='Peso da Pessoa' (V604) |
| `RPRINCIF` | `V680` | A+B+v050 | Classe rend bruto ocup. principal (C nao tem) |
| `RTOTALF` | `V681` | A+B+v050 | Classe de renda total (C nao tem) |
| `RTOTOCUF` | `V682` | A+B+v050 | Classe rend bruto todas as ocupações (C nao tem) |

## V-cols em v0.5.0 ausentes no FTP IBGE 2025

Variáveis que existiam em v0.5.0 mas o DBF do FTP IBGE 2025 não traz diretamente.

### Households (3 vars)

| V-code v0.5.0 | categoria | tratamento |
|---|---|---|
| `V3` | DERIVE_GEO | Derivar de `code_muni` via `geobr::read_municipality(year=1980)` |
| `V4` | DERIVE_GEO | Derivar de `code_muni` via `geobr::read_municipality(year=1980)` |
| `V6` | DERIVE_GEO | Derivar de `code_muni` via `geobr::read_municipality(year=1980)` |

### Population (27 vars)

| V-code v0.5.0 | categoria | tratamento |
|---|---|---|
| `V198` | JOIN_FROM_HOUSEHOLDS | Vem do DBF dom; pipeline faz LEFT JOIN via `(UF, MUNIC, CONTADOM)` e propaga essa col em pessoa |
| `V201` | JOIN_FROM_HOUSEHOLDS | Vem do DBF dom; pipeline faz LEFT JOIN via `(UF, MUNIC, CONTADOM)` e propaga essa col em pessoa |
| `V202` | JOIN_FROM_HOUSEHOLDS | Vem do DBF dom; pipeline faz LEFT JOIN via `(UF, MUNIC, CONTADOM)` e propaga essa col em pessoa |
| `V203` | JOIN_FROM_HOUSEHOLDS | Vem do DBF dom; pipeline faz LEFT JOIN via `(UF, MUNIC, CONTADOM)` e propaga essa col em pessoa |
| `V204` | JOIN_FROM_HOUSEHOLDS | Vem do DBF dom; pipeline faz LEFT JOIN via `(UF, MUNIC, CONTADOM)` e propaga essa col em pessoa |
| `V205` | JOIN_FROM_HOUSEHOLDS | Vem do DBF dom; pipeline faz LEFT JOIN via `(UF, MUNIC, CONTADOM)` e propaga essa col em pessoa |
| `V206` | JOIN_FROM_HOUSEHOLDS | Vem do DBF dom; pipeline faz LEFT JOIN via `(UF, MUNIC, CONTADOM)` e propaga essa col em pessoa |
| `V207` | JOIN_FROM_HOUSEHOLDS | Vem do DBF dom; pipeline faz LEFT JOIN via `(UF, MUNIC, CONTADOM)` e propaga essa col em pessoa |
| `V208` | JOIN_FROM_HOUSEHOLDS | Vem do DBF dom; pipeline faz LEFT JOIN via `(UF, MUNIC, CONTADOM)` e propaga essa col em pessoa |
| `V209` | JOIN_FROM_HOUSEHOLDS | Vem do DBF dom; pipeline faz LEFT JOIN via `(UF, MUNIC, CONTADOM)` e propaga essa col em pessoa |
| `V211` | JOIN_FROM_HOUSEHOLDS | Vem do DBF dom; pipeline faz LEFT JOIN via `(UF, MUNIC, CONTADOM)` e propaga essa col em pessoa |
| `V212` | JOIN_FROM_HOUSEHOLDS | Vem do DBF dom; pipeline faz LEFT JOIN via `(UF, MUNIC, CONTADOM)` e propaga essa col em pessoa |
| `V213` | JOIN_FROM_HOUSEHOLDS | Vem do DBF dom; pipeline faz LEFT JOIN via `(UF, MUNIC, CONTADOM)` e propaga essa col em pessoa |
| `V214` | JOIN_FROM_HOUSEHOLDS | Vem do DBF dom; pipeline faz LEFT JOIN via `(UF, MUNIC, CONTADOM)` e propaga essa col em pessoa |
| `V215` | JOIN_FROM_HOUSEHOLDS | Vem do DBF dom; pipeline faz LEFT JOIN via `(UF, MUNIC, CONTADOM)` e propaga essa col em pessoa |
| `V216` | JOIN_FROM_HOUSEHOLDS | Vem do DBF dom; pipeline faz LEFT JOIN via `(UF, MUNIC, CONTADOM)` e propaga essa col em pessoa |
| `V217` | JOIN_FROM_HOUSEHOLDS | Vem do DBF dom; pipeline faz LEFT JOIN via `(UF, MUNIC, CONTADOM)` e propaga essa col em pessoa |
| `V218` | JOIN_FROM_HOUSEHOLDS | Vem do DBF dom; pipeline faz LEFT JOIN via `(UF, MUNIC, CONTADOM)` e propaga essa col em pessoa |
| `V219` | JOIN_FROM_HOUSEHOLDS | Vem do DBF dom; pipeline faz LEFT JOIN via `(UF, MUNIC, CONTADOM)` e propaga essa col em pessoa |
| `V220` | JOIN_FROM_HOUSEHOLDS | Vem do DBF dom; pipeline faz LEFT JOIN via `(UF, MUNIC, CONTADOM)` e propaga essa col em pessoa |
| `V221` | JOIN_FROM_HOUSEHOLDS | Vem do DBF dom; pipeline faz LEFT JOIN via `(UF, MUNIC, CONTADOM)` e propaga essa col em pessoa |
| `V3` | DERIVE_GEO | Derivar de `code_muni` via `geobr::read_municipality(year=1980)` |
| `V4` | DERIVE_GEO | Derivar de `code_muni` via `geobr::read_municipality(year=1980)` |
| `V598` | REAL_DROPPED | REAL DROPPED — IBGE 2025 não publica. v0.5.0 tinha (B+C confirmam). Pipeline preserva NA. |
| `V6` | DERIVE_GEO | Derivar de `code_muni` via `geobr::read_municipality(year=1980)` |
| `V602` | JOIN_FROM_HOUSEHOLDS | Vem do DBF dom; pipeline faz LEFT JOIN via `(UF, MUNIC, CONTADOM)` e propaga essa col em pessoa |
| `V603` | JOIN_FROM_HOUSEHOLDS | Vem do DBF dom; pipeline faz LEFT JOIN via `(UF, MUNIC, CONTADOM)` e propaga essa col em pessoa |

## Estratégia de pipeline 1980 (Fase 2)

Após aprovação do inventário acima:

```
1. download_microdata_1980(): baixa zip, descompacta DBFs em data_raw/microdata/1980/
2. clean_microdata_1980(dataset_name):
   - read DBFs por UF (foreign::read.dbf), stack via rbindlist
   - apply mapping CSV: rename ftp_col -> v_code (modulo aliases NDOM=CONTADOM em pessoa)
   - if dataset='population': LEFT JOIN com clean_households via (UF, MUNIC, CONTADOM) -> propaga V198, V201-V221, V602, V603
   - add V3 (Mesorregião), V4 (Microrregião), V6 (Distrito) via geobr crosswalk de code_muni
   - V598 -> NA_real_ (REAL_DROPPED de IBGE 2025)
   - apply add_geography_cols(year=1980)
3. save_microdata_1980(): code_cols_to_numeric (v0.6.0) + write_censobr_parquet
```

Mapping table machine-readable: `references/microdata_1980_col_mapping.csv` (88 linhas: 26 dom + 62 pes).

## Decisões pendentes do usuário

1. **V598 (Situação da pessoa) — REAL_DROPPED:** preservar como NA no parquet ou descartar coluna?
2. **SANUSO + PESOD com 2 fontes:** aceitar mapping V208/V603 (B+C concordam) ou exigir confirmação manual no .doc?
3. **JOIN dom→pes para 23 vars:** aplicar (preserva paridade v0.5.0 que denormaliza) ou manter normalizado IBGE 2025 (consumidor pode juntar via UF+MUNIC+CONTADOM)?
4. **Continuar para 1991** com mesma metodologia, ou pausar pra você revisar 1980 em detalhe primeiro?
