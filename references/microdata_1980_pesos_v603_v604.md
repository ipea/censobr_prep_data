# Os pesos da amostra de 1980: V603 e V604

**Data:** 2026-09-12
**Status:** DECIDIDO e implementado
**Assunto:** o que fazer com os zeros de V603 (Peso de Domicílio) e com a
imputação de V604 (Peso da Pessoa) já aplicada pelo pipeline

## Decisão (2026-09-12)

1. **V603: mantido como o IBGE entrega.** Nada imputado — nem os 233.344
   estruturais, nem os 55 de espécie 1.
2. **V604: imputação revertida.** A soma voltou a 119.011.052, exata contra o
   SIDRA, e os 7 pesos fracionários desapareceram.
3. **`code_muni`: corrigido**, e a regra é que o produto de 1980 tem de casar
   com `geobr::read_municipality(year = 1980)`. Ver a seção final.

---

## O achado que organiza tudo

**Os dois pesos de 1980, exatamente como o IBGE entrega — zeros inclusive —
reproduzem as tabulações publicadas do IBGE na unidade.**

| Peso | Soma no dado do IBGE | Fonte oficial | Diferença |
|---|---:|---|---:|
| V603 (domicílio) | 25.210.639 | SIDRA t206, domicílios particulares permanentes, 1980 | **0** |
| V604 (pessoa) | 119.011.052 | SIDRA t200/t202, população residente (Amostra), 1980 | **0** |

A igualdade de V603 foi verificada em **40 células**: Brasil, 26 de 26 UFs,
as duas situações (urbana 17.770.981 / rural 7.439.658) e as 11 classes de
número de cômodos, incluindo "sem declaração" (81.968). Todas exatas, resíduo
zero. A de V604, em **20 células** (2 sexos × 2 situações × 17 grupos etários
+ idade ignorada).

Isso muda a natureza da pergunta. Os zeros não são lacunas no dado: **são parte
do estimador**. O IBGE produziu suas tabelas publicadas com esses zeros no
lugar. Qualquer imputação, por melhor motivada, faz o `censobr` deixar de
reproduzir o IBGE.

## V603 — a anatomia dos zeros

6.716.885 domicílios, 233.399 com V603 == 0 (3,47%), nenhum NA, valores
inteiros de 0 a 21.

| V201 (espécie) | domicílios | V603 == 0 |
|---|---:|---:|
| 1 — particular permanente | 6.483.541 | 55 |
| 3 — particular improvisado | 27.487 | 27.487 (100%) |
| 5 — coletivo permanente | 184.497 | 184.497 (100%) |
| 7 — coletivo improvisado | 21.360 | 21.360 (100%) |

### O zero é a sentinela de "não se aplica" do IBGE

Não é um peso igual a zero. Na republicação DBF de 2025 o `PESOD == 0` é
**solidário a outras 13 variáveis do mesmo registro**, que recebem sua própria
sentinela de NSA na mesma linha e ao mesmo tempo: TIPO, SANUSO, TPRESID,
COMODOS, COMODOR, FOGAO, COMBCOZI, TELEFONE, ILUMINA, RADIO, GELADEIR, TV,
AUTOMOVE. Outras 6 usam dígito não-zero (PAREDES=1, PISO=2, COBERTUR=8,
AGUA=8, SANESCOA=1, CONDOCUP=8). A planilha de layout do IBGE declara a
variável-irmã `PESOP` como `INTEGER, 0 - 30, NSA=0`.

O questionário de domicílio nunca foi aplicado a esses 233.344: têm **100% de
NA nas 17 variáveis substantivas do bloco**. Não há o que ponderar.

### O zero não foi criado pelo pipeline

- Na fonte (`release_legacy`, `Censo.1980.brasil.domicilios...parquet`), V603 já
  vem como string com 233.399 valores `"0"`, soma 25.210.639.
- No DBF do IBGE o campo vem literalmente `" 0"` — zero explícito, alinhado à
  direita. **Não há brancos em ESPECIE==1 em nenhuma das 26 UFs**, então a
  hipótese "o IBGE escreveu branco e nós escrevemos 0" morre na fonte.
- O publicado em v0.5.0 é idêntico ao nosso, registro a registro: bijeção
  perfeita sobre as 6.716.885 chaves `(V2, V5, V6, V601)`, zero divergências.
  Os mesmos números aparecem em v0.3.0 e v0.2.0 — três anos sem tratamento.

### Os 55 de espécie 1

São os únicos zeros dentro do universo ponderado, e são **defeito do IBGE, não
nosso**. No DBF de 2025 há 54 casos de `ESPECIE==1 & PESOD==0`, os mesmos
registros campo a campo. O 55º é Fernando de Noronha, que o DBF (26 UFs) não
carrega separadamente.

São registros completos — zero campos vazios, 1 a 11 cômodos, 14 com aluguel
declarado — e seus 160 moradores têm todos V604 > 0. Perfil fortemente não
aleatório: 29 municípios em 11 UFs (MG 14, BA 12, AM 7, SP 7, PB 6, AL 3,
RN 2, FN/MA/PI/SC 1), raramente proprietários (5,5% contra 75,3%), unipessoais
em excesso (30,9% contra 6,5%).

**Mas o decisivo é aritmético:** os 55 já estão embutidos nos 25.210.639 que
o IBGE publicou. Imputá-los levaria a soma a ~25.210.79x e quebraria de uma vez
as 40 células exatas — por um ganho de 0,00085%.

### Fernando de Noronha fecha a conta

O DBF de 2025 soma 25.210.413 em 26 UFs. A amostra preparada soma 25.210.639
porque inclui FN (69 domicílios, 226 ponderados). `25.210.413 + 226 =
25.210.639` = SIDRA. **A nossa fonte é mais completa que a republicação de 2025
do próprio IBGE**, e é por isso que bate exato.

## V604 — a imputação do pipeline quebrou a paridade

Esta é a pendência acionável, e é um defeito introduzido por nós.

Na fonte há 42 pessoas com V604 == 0, nenhum NA, e a soma é 119.011.052 —
exata contra o SIDRA. As 42 se repartem assim:

| | pessoas | onde |
|---|---:|---|
| espécie 1, domicílio com peso (V603 > 0) | 18 | buracos genuínos |
| espécie 1, domicílio sem peso | 1 | morador de um dos 55 |
| espécie 3 e 5 (improvisado/coletivo) | 23 | domicílio fora do universo |

A correção em [R/microdata_1980.R:103-119](../R/microdata_1980.R#L103-L119)
zerou os 42, e com isso:

- **a soma saiu de 119.011.052 para 119.011.203,334** — +151,334, o fim da
  paridade exata com as 20 células publicadas;
- **apareceram 7 pesos fracionários**, em 6 valores distintos (3,133333;
  3,968721; 4,078571; 4,138022; 4,950980; 5,931026), num campo que o IBGE
  declara `INTEGER`. A causa é técnica: `stats::median()` dentro de
  `group_by/summarise` sobre arrow lazy não é a mediana exata, é quantil
  aproximado por t-digest.

O peso injetado medido (151,333987802074802) é igual à diferença até o último
bit — ou seja, **toda** a divergência de 1980 contra o IBGE hoje vem desta
imputação.

## As opções

| | efeito em sum(V603) | paridade SIDRA | veredito |
|---|---|---|---|
| (a) manter os zeros | 25.210.639 | preservada | viável |
| (b) imputar os 233.344 | ~26.117.880 (+3,6%) | destruída | descartada |
| (c) zeros → NA | 25.210.639 com `na.rm` | preservada | viável, com ressalva |
| (d) imputar só os 55 | +~152 | quebrada em 40 células | não compensa |

**(b) está descartada por três motivos independentes:** destrói a paridade;
não há o que ponderar (100% de NA no bloco de domicílio); e a amostra preparada
já está truncada em coletivos — faltam 169.918 registros de espécie 5 e 7 em
relação ao DBF (todos de peso zero, então nenhuma estimativa ponderada muda,
mas contagens não ponderadas de coletivos ficam incompletas). Imputar sobre um
subconjunto truncado por critério desconhecido produziria um universo fictício.

**(c) merece discussão honesta.** A favor: no próprio parquet, 17 das 21
variáveis substantivas do bloco de domicílio já usam NA para "não aplicável", e
só 4 usam 0 (V212, V213, V602, V603) — a coerência interna que (a) invocaria já
não existe. O pipeline já converteu a sentinela 0 do IBGE em NA em V211
(Tempo de Residência), então (c) não inauguraria política nenhuma. E o
dicionário `censo_docs` documenta "não aplicável" como **campo em branco**, que
em R/Arrow é NA, não zero.

Contra, e é o que pesa mais para um *peso*: **zero é a codificação canônica de
"fora do universo" em estatística de survey**, tratada corretamente por todo
estimador, inclusive na variância. `survey::svydesign()` recusa pesos NA. E
`sum(V603)` hoje é auto-filtrante — devolve o número oficial sem o usuário
precisar escrever `V201 == 1`; com NA passaria a devolver NA sem `na.rm`,
envenenando código que hoje funciona e acerta.

## Recomendação

1. **V603: manter como está (a).** Não imputar nem os 233.344 nem os 55. O
   argumento não é fidelidade abstrata à fonte — é que a soma reproduz 40
   células publicadas do IBGE, e nenhuma das alternativas melhora nada que o
   usuário queira.
2. **V604: reverter a imputação.** É hoje a única divergência de 1980 contra o
   IBGE e introduziu pesos não-inteiros num campo inteiro. Os 42 zeros do IBGE
   são da mesma natureza dos 55 de V603: o IBGE publicou seus totais com eles
   zerados.
3. **Se a regra "ninguém sem peso" prevalecer sobre a paridade**, então no
   mínimo corrigir o defeito técnico: coletar antes da mediana (ou usar
   `data.table`) e arredondar para inteiro, para não gravar peso fracionário.
   A divergência continuaria (~+150), mas íntegra.
4. **V212 e V213 (cômodos): considerar 0 → NA.** Zero cômodos é impossível num
   domicílio real; os 233.344 zeros são 100% NSA e a conversão não perde
   informação. É decisão separada e menor, e não tem o problema de survey que
   V603 tem.
5. **Documentar V603.** O `censobr` não diz nada sobre esse peso em lugar
   nenhum — nem NEWS, nem vinheta, nem `add_labels` (que não cobre 1980). O
   dicionário só informa "Peso de Domicílio, pos 52, tam 4, N". Isso é do lado
   do consumidor e não se resolve neste repo.

## Conformidade com o dicionário — o resto está limpo

Confrontadas as 89 variáveis dos dois dicionários oficiais com as 38 colunas do
parquet de domicílios e as 99 do de pessoas: **nenhuma variável do dicionário
falta**, há **uma coluna extra** (`idpessoa`, chave do pipeline) e, em 46
categóricas comparadas valor a valor, existe **um único valor observado não
declarado em todo o banco**: `V605 == 99` (28.946 casos).

O dicionário de 1980 declara convenção de missing em três eixos: `9`/`99`
"ignorado/sem declaração" (25 variáveis), branco "não aplicável" (21) e `98`
"a ser imputado" (7). V603 e V604 são as duas únicas variáveis do layout **sem
nenhuma categoria declarada** — nem ignorado, nem não aplicável.

## Geografia: o produto de 1980 segue a malha de 1980

**Regra:** o 1980 publicado pelo `censobr` tem de ser compatível com
`geobr::read_municipality(year = 1980)`.

O `code_muni` era NA em 35.567 domicílios — 35.498 em Goiás (V2 == 52) e 69 em
Fernando de Noronha. A causa era o crosswalk
`crosswalk_tocantins_ferNoronha_1980_2010.xlsx`, que reescreve esses 53
municípios para o código **de 2010** (prefixo 17, Tocantins, e 26, Noronha).
Esses prefixos não existem na malha de 1980, então o `left_join` falhava.

A correção é não aplicar o crosswalk à geografia: `code_muni` sai do join de
`code_muni_1980` com a malha de 1980. **Os 3.991 códigos de município do dado
resolvem todos nessa malha**, inclusive os 53 do crosswalk:

- Fernando de Noronha → `2000107`, território 20, `abbrev_state` **FN**;
- os 52 futuros municípios do Tocantins → `52xxxxx`, em **Goiás**, que é onde
  estavam em 1980 (`520040 → 5200407`, Almas/GO).

O território 20 não existe em `states_censobr()`, que só traz as 27 UFs de
hoje — por isso os 69 domicílios de Noronha ficavam sem sigla, sem nome de UF
e sem região. Foi acrescentada uma linha local para o código 20, com os mesmos
rótulos que o `geobr` 1980 usa: `FN`, `Fernando de Noronha`, região 2,
`Nordeste`.

O crosswalk deixou de ser usado em `clean_microdata_1980()`. O
`download_microdata_1980()` continua trazendo o arquivo, caso se decida expor
o código de 2010 numa coluna própria.

### Resultado medido

Nas duas tabelas: **zero NA** nas 9 colunas de geografia, e **zero códigos
fora da malha `geobr` de 1980** (3.991 distintos).

### Delta contra o publicado (v0.5.0), por chave `(V2, V5, V6, V601)`

| coluna | divergem | natureza |
|---|---:|---|
| `code_muni` | 35.567 | todas de NA → valor; nenhum valor já preenchido mudou |
| `abbrev_state` / `name_state` | 69 | NA → `FN` / `Fernando de Noronha` |
| `code_region` | 0 | — |
| `V603` | 0 | intacto |
| `name_region` | 411.557 | `Centro-Oeste` (nosso) × `Centro-oeste` (publicado) |

A última linha é anterior a este trabalho: vem de `states_censobr()`, adotada
no porte para o `targets`. É divergência de grafia, não de conteúdo, e ainda
não foi decidida.
