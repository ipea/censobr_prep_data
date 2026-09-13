# Inventário de variáveis — microdata 1970

**Data:** 2026-05-06  |  **Fase:** 1 (verificação tripla concluída)
**Status:** APROVADO — pronto para Fase 2 (pipeline R).

## Particularidade do 1970 vs 1980/1991

**Diferente dos Censos de 1980 e 1991, o IBGE 2025 do Censo 1970 publica os microdados já no vocabulário antigo (V-codes V001-V054).** Não houve renomeação para nomes descritivos. Logo:

- Não há tradução descritivo→V-code a fazer (como 1991 exigiu).
- Não há mismatch de schema (como 1980 com `ALUGUEL` mudando V-code).
- Verificação tripla é direta: A (layout_1970.xlsx) + B (Pedro Souza pessoas) + v0.5.0 schemas.

## Fontes consultadas

- **A — layout_1970.xlsx** em `censoBR_aux_Dados/1970/microdados da amostra/dicionario/`. Sheet `Population` traz 54 V-vars com posições FWF (DESDE/TAM) cobrindo chars 1-76 do registro. Sheet `Households` traz 20 vars (subset da Population) sem posições.
- **B — pessoas1970_via_PedroSouza.xlsx**. Mesmas vars com Label, Descrição, Categorias detalhadas.
- **B' — domicilios_fixed1970_via_PedroSouza.xlsx**. 30 rows, apenas 3 cols (Ano, Variável, Label) — versão menos detalhada para o subset domicílio. **Households é derivado da Population via agregação** — não há schema independente.
- **v0.5.0 schemas** baixados do release `ipea/censobr` v0.5.0:
  - `1970_population_v0.5.0.parquet`: 65 colunas (54 V-cols + 9 geo + 2 IDs)
  - `1970_households_v0.5.0.parquet`: 35 colunas (20 V-cols + 9 geo + 1 ID + 5 derivadas)

**Auxiliar D (consultar para ambiguidades):**
- `arquivos_auxliares/V027.txt`, `V030.txt`, `V039.txt`, `V044.txt`, `V045.txt`, `V050.txt` — categorias detalhadas por variável
- `Censo 1970 - Dicionário da Amostra - Pessoas - Versão IBGE.doc` — dicionário oficial IBGE (binário .doc)
- `Documentação.doc` dentro do zip FTP (extraído em `data_raw/microdata/1970/docs/`)
- `crosswalk_munic_1970_to_2010.rda` — tabela de equivalência município 1970 → 2010 (deriva `code_muni`)

## Sumário executivo

- **54 V-codes** documentados em A (layout) com posições FWF.
- **54/54 confirmados em B** (Pedro Souza pessoas).
- **54/54 presentes em v0.5.0** (population: todas; households: 20 das 54, V005 e V022-V054 são pessoa-only).
- **Cobertura 100% triple-verified.** Evidência `A+B+v050` em todas as 54 vars.

## Mapping completo (54 V-codes)

| V-code | Descrição (A/B) | Posição FWF | Em v050 pop | Em v050 hh | Evidência |
|---|---|---|---|---|---|
| `V001` | CODIGO DA MICRORREGIÃO | 1-3 (3c) | Y | Y | A+B+v050 |
| `V002` | CODIGO DO MUNICÍPIO | 4-6 (3c) | Y | Y | A+B+v050 |
| `V003` | CODIGO DO DISTRITO | 7-8 (2c) | Y | Y | A+B+v050 |
| `V004` | CODIGO DA SITUAÇÃO DO DOMICILIO | 9-9 (1c) | Y | Y | A+B+v050 |
| `V005` | TOTAL DE PESSOAS DA FAMILIA | 10-11 (2c) | Y | N | A+B+v050 |
| `V006` | CONDIÇÃO DA FAMÍLIA | 12-12 (1c) | Y | Y | A+B+v050 |
| `V007` | ESPÉCIE DO DOMICÍLIO | 13-13 (1c) | Y | Y | A+B+v050 |
| `V008` | TIPO DO DOMICÍLIO | 14-14 (1c) | Y | Y | A+B+v050 |
| `V009` | CONDIÇÃO DE OCUPAÇÃO | 15-15 (1c) | Y | Y | A+B+v050 |
| `V010` | ALUGUEL OU PRESTAÇÃO MENSAL (SALÁRIO MÍNIMO VIGENTE NA ÉPOCA: CR$36.161,60) | 16-16 (1c) | Y | Y | A+B+v050 |
| `V011` | TEMPO DE RESIDÊNCIA EM MESES OU ANOS | 17-17 (1c) | Y | Y | A+B+v050 |
| `V012` | FORMA DE ABASTECIMENTO DE ÁGUA | 18-18 (1c) | Y | Y | A+B+v050 |
| `V013` | TIPO DE INSTALAÇÃO SANITARIA | 19-19 (1c) | Y | Y | A+B+v050 |
| `V014` | POSSUI ILUMINAÇÃO ELÉTRICA | 20-20 (1c) | Y | Y | A+B+v050 |
| `V015` | FOGÃO | 21-21 (1c) | Y | Y | A+B+v050 |
| `V016` | RÁDIO | 22-22 (1c) | Y | Y | A+B+v050 |
| `V017` | POSSUI GELADEIRA | 23-23 (1c) | Y | Y | A+B+v050 |
| `V018` | TELEVISÃO | 24-24 (1c) | Y | Y | A+B+v050 |
| `V019` | AUTOMOVEL | 25-25 (1c) | Y | Y | A+B+v050 |
| `V020` | TOTAL DE CÔMODOS | 26-27 (2c) | Y | Y | A+B+v050 |
| `V021` | NÚMERO DE DORMITÓRIOS | 28-29 (2c) | Y | Y | A+B+v050 |
| `V022` | CODIGO DO INFORMANTE | 30-30 (1c) | Y | N | A+B+v050 |
| `V023` | SEXO | 31-31 (1c) | Y | N | A+B+v050 |
| `V024` | CONDIÇÃO DE PRESENÇA (NORMALMENTE SÓ SÃO TABULADOS OS MORADORES DE CÓDIGO 1 E 2) | 32-32 (1c) | Y | N | A+B+v050 |
| `V025` | PARENTESCO OU RELAÇÃO COM O CHEFE DA FAMÍLIA | 33-33 (1c) | Y | N | A+B+v050 |
| `V026` | TIPO DE IDADE | 34-34 (1c) | Y | N | A+B+v050 |
| `V027` | IDADE EM MESES OU ANOS | 35-36 (2c) | Y | N | A+B+v050 |
| `V028` | POSSUI RELIGIÃO | 37-37 (1c) | Y | N | A+B+v050 |
| `V029` | CODIGO DA NACIONALIDADE | 38-38 (1c) | Y | N | A+B+v050 |
| `V030` | CODIGO DA NATURALIDADE | 39-40 (2c) | Y | N | A+B+v050 |
| `V031` | TEMPO DE RESIDÊNCIA NESTA UF | 41-41 (1c) | Y | N | A+B+v050 |
| `V032` | TEMPO DE RESIDENCIA NESTE MUNICIPIO | 42-42 (1c) | Y | N | A+B+v050 |
| `V033` | UF QUE RESIDIA ANTES DE MUDAR-SE PARA ESTE MUNICÍPIO | 43-44 (2c) | Y | N | A+B+v050 |
| `V034` | SITUAÇÃO DA RESIDENCIA NO MUNICÍPIO ONDE MORAVA ANTERIORMENTE | 45-45 (1c) | Y | N | A+B+v050 |
| `V035` | ALFABETIZAÇÃO | 46-46 (1c) | Y | N | A+B+v050 |
| `V036` | FREQUENTA A ESCOLA | 47-47 (1c) | Y | N | A+B+v050 |
| `V037` | ULTIMA SERIE QUE CONCLUIU COM APROVAÇÃO NESTE CURSO QUE FREQUENTOU ANTERIOMENTE | 48-48 (1c) | Y | N | A+B+v050 |
| `V038` | ULTIMO GRAU CONCLUIDO COM APROVAÇÃO | 49-49 (1c) | Y | N | A+B+v050 |
| `V039` | ESPECIE DE CURSO CONCLUIDO | 50-51 (2c) | Y | N | A+B+v050 |
| `V040` | ESTADO CONJUGAL | 52-52 (1c) | Y | N | A+B+v050 |
| `V041` | RENDIMENTO MEDIO MENSAL | 53-56 (4c) | Y | N | A+B+v050 |
| `V042` | MUNICÍPIO ONDE TRABALHA OU ESTUDA | 57-57 (1c) | Y | N | A+B+v050 |
| `V043` | SITUAÇÃO PRINCIPAL DE EMPREGO | 58-58 (1c) | Y | N | A+B+v050 |
| `V044` | OCUPAÇÃO PRINCIPAL | 59-61 (3c) | Y | N | A+B+v050 |
| `V045` | CLASSIFICAÇÃO DE ATIVIDADE | 62-64 (3c) | Y | N | A+B+v050 |
| `V046` | POSIÇÃO NA OCUPAÇÃO | 65-65 (1c) | Y | N | A+B+v050 |
| `V047` | OCUPAÇÃO QUE EXERCIA NA ULTIMA SEMANA DE REFERENCIA DA PESQUISA (25/08/1970 A 31/08/1970) | 66-66 (1c) | Y | N | A+B+v050 |
| `V048` | TEMPO OU HORA DE TRABALHO NA ULTIMA SEMANA | 67-67 (1c) | Y | N | A+B+v050 |
| `V049` | HÁ QUANTO TEMPO PROCURA TRABALHO | 68-68 (1c) | Y | N | A+B+v050 |
| `V050` | QUANTIDADE DE FILHOS NASCIDOS VIVOS ATE A DATA DO CENSO | 69-70 (2c) | Y | N | A+B+v050 |
| `V051` | QUANTIDADE DE FILHOS NASCIDOS MORTOS | 71-71 (1c) | Y | N | A+B+v050 |
| `V052` | QUANTIDADE DE FILHOS NASCIDOS NO ANO ANTERIOR AO CENSO | 72-72 (1c) | Y | N | A+B+v050 |
| `V053` | QUANTIDADE DE FILHOS QUE NASCERAM VIVOS E CONTINUAM VIVOS | 73-74 (2c) | Y | N | A+B+v050 |
| `V054` | PESO DA PESSOA | 75-76 (2c) | Y | N | A+B+v050 |

**Observação V005:** presente em population (`TOTAL DE PESSOAS DA FAMILIA` por linha-pessoa) mas excluída de households (em households o equivalente é `numb_dwellers`, calculado por agregação — count de pessoas por household_id).

## Colunas em v0.5.0 não-V (derivadas no pipeline)

### Colunas geográficas (9, comuns aos 2 datasets)

Adicionadas via `add_geography_cols(year=1970)` usando `code_muni` derivado pelo crosswalk munic 1970→2010:

| Coluna | Origem |
|---|---|
| `code_muni` | crosswalk 1970→2010 a partir do nome do município (auxiliar `municipio_1970.xls`) ou via heurística IBGE |
| `code_muni_1970` | código do município no esquema histórico 1970 (mantém valor original) |
| `code_state` | substr(code_muni, 1, 2) |
| `name_state` | fcase canônico de code_state |
| `name_state_1970` | fcase histórico (MS pertencia a MT, TO a GO em 1970) |
| `abbrev_state` | fcase canônico (`SP`, `RJ`, ...) |
| `abbrev_state_1970` | fcase histórico (TO=GO, MS=MT) |
| `code_region` | substr(code_state, 1, 1) |
| `name_region` | fcase regional |

### Identificadores

- `id_person` (population only): identificador único da pessoa.
- `id_household` (population + households): identificador único do domicílio. **Construído pelo script legacy `microdata_sample_1970a` via lógica de chefia** (V025=1 + V006 em c(1,2) → início de novo household).

### Derivadas em households (5)

Calculadas durante a agregação pessoa→domicílio:

- `weight_household` = peso do chefe (V054 onde V025=1)
- `numb_dwellers` = count de pessoas no household
- `numb_dwellers_hhincome` = count de pessoas que contribuem renda (chefe + parentes adultos)
- `hh_income` = sum(V041 das pessoas válidas, com X→0 e nonrelative→0)
- `hh_income_per_cap` = hh_income / numb_dwellers_hhincome

## Estratégia de pipeline 1970 (Fase 2)

```
1. download_microdata_1970(): baixa zip FTP, descompacta 27 arquivos Damo70<UF>.txt
2. clean_microdata_1970(dataset_name):
   - Para cada UF: ler FWF via posições do layout_1970.xlsx Population sheet (54 vars, chars 1-76)
   - Empilhar via rbindlist
   - if dataset='population': resultado é direto (1 row = 1 pessoa)
   - if dataset='households': aplicar lógica de chefia do legacy 1970a:
     - flag inicial: V025=1 & V006 em c(1,2) → 1 (novo household)
     - V006=0 → NA (excluir): não é quem mora sozinho, e sim "Individual em
       domicílio coletivo". O dicionário do IBGE rotula "pessoa só", mas no
       vocabulário do censo "só" quer dizer sem laços de parentesco no
       domicílio, não morando sozinho — a definição do IBGE é "para a pessoa
       só que residia em domicílio coletivo, ainda que compartilhando a
       unidade de habitação com outra(s) pessoa(s) com a(s) qual(is) não tinha
       laços de parentesco". V006=0 ⟺ V025=9 em 339.316/339.316
     - V007=1 (collective) → NA (excluir)
     - V008=2 (improvisado) → **entra** (a regra 5.2 do legacy o excluía)
     - household_id via na.locf(idhh_locality)
     - Agregar por household_id: numb_dwellers, hh_income, weight_household, etc.
   - Aplicar add_geography_cols(year=1970)
3. save_microdata_1970(): code_cols_to_numeric (v0.6.0) + write_censobr_parquet
```

**Lógica de chefia complexa** está nas linhas 56-110 de `R_ainda_sem_targets/microdata_sample_1970a_household_ids_and_dataset.R`. Portar essa lógica é o passo crítico para gerar households de 1970.

## Decisões pendentes — nenhuma

Mapping triplo confirmado em 100% das vars. 9 geo cols + 5 derivadas hh + 2 IDs documentados. Pronto para Fase 2.