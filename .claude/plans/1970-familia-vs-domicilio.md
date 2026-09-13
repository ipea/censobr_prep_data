# Plano: separar familia de domicilio nos microdados de 1970

**Status:** CONCLUÍDO
**Data:** 2026-09-13

## Contexto

O produto publicado de 1970 tem 4.737.407 domicilios e 468.164 pessoas (1,888%)
sem `id_household`. A decomposicao exata desse residuo e:

| grupo | pessoas | domicilios |
|---|---|---|
| A. individuo em domicilio coletivo (V006==0 / V025==9) | 339.316 | 40.310 |
| B. familia morando em domicilio coletivo (V007==1) | 114.325 | 21.723 |
| C. domicilio IMPROVISADO (V008==2) | 14.212 | 3.979 |
| D. familia secundaria dentro de improvisado (V008 em branco) | 311 | -- |

40.310 + 21.723 + 3.979 = 66.012 = 4.803.419 - 4.737.407.

A e B sao domicilios coletivos e ficam de fora por decisao editorial: renda
domiciliar per capita nao tem sentido sociologico para hotel, quartel, convento
ou presidio, cujos moradores nao partilham orcamento. Ja estao corretamente
excluidos no produto publicado -- nada a fazer.

C e D nao sao coletivos. Sao domicilios particulares (V007==0 em 14.212/14.212)
de tipo improvisado. Saem por uma regra deliberada do script legado
`R_ainda_sem_targets/microdata_sample_1970a_household_ids_and_dataset.R`:

    # (5.2) Assigning NA to improvised households
    CensusData[mean_v008 %in% 2, household_id := NA_real_]

Excluir improvisados enviesa qualquer analise distributiva: e exatamente a
populacao mais precaria que some do banco de domicilios.

## Objetivo

Passar de 4.737.407 para 4.741.386 domicilios (+3.979) e de 468.164 para
453.643 pessoas sem `id_household`, preservando integralmente os 4.737.407
domicilios ja publicados.

## Evidencia ja levantada

1. A derivacao legada foi reimplementada e reproduz o publicado em
   **100,000000%** (24.793.358 de 24.793.358 pessoas; 4.737.407 domicilios).
2. Removendo apenas `mean_v008 %in% 2`: +3.979 domicilios, +14.521 pessoas,
   **0 colisoes** de id, **100,000000%** dos ids antigos preservados.
3. Os grupos improvisados sao coerentes: tamanho do grupo == V005 do chefe em
   **3.900 de 3.900** casos de familia unica; exatamente 1 chefe em cada um dos
   3.979; cada grupo e um bloco contiguo unico no arquivo.
4. `iddomicilio` da fonte e bijecao perfeita com `id_household` publicado
   (0 violacoes nos dois sentidos sobre 24.325.194 pessoas).
5. V009-V020 sao NA nos 14.212: o IBGE pula o bloco de caracteristicas da
   habitacao para improvisado. Nao e corrupcao; a linha de domicilio e valida
   com esses campos vazios.

## Abordagem

Aditiva, para nao tocar no que ja esta certo. Manter a rota atual
(parquets do CEM no release_legacy + crosswalk) e acrescentar:

- 3.979 linhas na tabela de domicilios, com os agregados calculados pelas
  formulas do script legado;
- `id_household` para 14.521 pessoas no banco de pessoas.

Formulas legadas a replicar (linhas 113-145 do script legado):

    nonrelative      = (v025 == 0 | v025 >= 7)
    numberRelatives  = sum(1 - nonrelative), by household
    age              = 0 se v026 em (1,2); v027 se v026 em (3,4)
    totalIncome      = v041, zerado se v041 == 9999, se nonrelative, ou se age <= 9
    hh_income        = sum(totalIncome), by household  -- NA para nonrelative
    hh_income_per_cap= hh_income / numberRelatives
    weight_household = max(v054 onde v025 == 1), by household
    V001..V021       = mean(., na.rm = TRUE), by household
    numb_dwellers    = .N
    numb_dwellers_hhincome = numberRelatives

## Arquivos a modificar

- [ ] `R/microdata_1970.R` -- acrescentar a derivacao dos improvisados;
      corrigir a nota do cabecalho (o maior bloco e 3.337, nao 1.281).

Nenhuma funcao protegida e tocada.

## Validacao

- [ ] As formulas reproduzem as 35 colunas do publicado em 1 UF pequena (AC/RR)
      antes de qualquer escrita.
- [ ] Apos o rebuild: 4.741.386 domicilios; 453.643 pessoas sem id_household.
- [ ] Os 4.737.407 domicilios antigos identicos em todas as colunas.
- [ ] Zero orfaos (pessoa apontando para domicilio inexistente) e zero
      domicilios vazios.
- [ ] `numb_dwellers` == contagem real de pessoas em 100%.
- [ ] sum(weight_household) permanece proximo de 17,68 milhoes (os improvisados
      pesam pouco); documentar o novo valor.

## Resultado medido

| | antes | depois |
|---|---:|---:|
| domicilios | 4.737.407 | 4.741.386 |
| pessoas sem id_household | 468.164 | 453.643 (1,830%) |
| ids orfaos | 0 | 0 |
| domicilios sem morador | -- | 0 |
| numb_dwellers == contagem real | -- | 100,000000% |
| sum(V054) | 94.461.969 | 94.461.969 |
| sum(weight_household) | 17.682.112 | 17.696.820 |

Pessoas: 14.521 ganharam id_household, zero perderam, zero mudaram. Nos
4.737.407 domicilios em comum, 33 das 34 colunas identicas ao publicado; a
34a e name_region, diferenca de grafia ("Centro-oeste" -> "Centro-Oeste")
anterior a esta mudanca, ja presente no build v0.6.0, com code_region
identico em 100%.

## Fora de escopo

- Domicilios coletivos (grupos A e B): decisao editorial e ficar de fora.
- Requantificar ou reimputar qualquer variavel existente.


---

# Fase 2 -- familia versus domicilio (2026-09-13)

Auditoria com 14 agentes (7 medicoes + 7 refutacoes adversariais, 361 chamadas
de ferramenta) sobre a distincao entre variavel de familia e variavel de
domicilio. Defeitos confirmados e decisoes tomadas pelo usuario:

| # | defeito | escala | decisao |
|---|---|---|---|
| 1 | `weight_household` usa `max(V054)` entre os chefes de FAMILIA | 46.136 dom., +0,3029% | corrigir: peso do chefe do domicilio |
| 2 | `V006` na tabela de domicilios e media de variavel de familia | 230.394 linhas (4,86%) | V006 = valor do chefe principal, E nova coluna `numb_families` |
| 3 | `numb_dwellers` conta os NAO MORADORES (V024 == 2) | 154.719 pessoas, 103.509 dom. | manter, e publicar `numb_residents` ao lado |
| 4 | bloco V007-V021 ausente para familias secundarias no banco de pessoas | 822.746 pessoas, 233.855 dom. | propagar dentro do domicilio |
| 5 | `V021 == 0` e marcador de nao-aplicavel | 61.390 registros | virar NA, depois receber o valor do domicilio |
| 6 | `V025 == 0` (IGNORADO) tratado como nao-parente | 341 pessoas, 322 dom. | passa a contar como morador |
| 7 | `V003`/`V004` por `mean()` geram distrito e situacao inexistentes | 4 e 26 linhas | resolvido: bloco vem da linha do chefe |

Nao sao defeitos, ficam documentados:

- a regra `age <= 9` do script legado e codigo morto: o IBGE so pergunta renda
  para 10 anos e mais (cabecalho do quesito 20), e V041 e NA em 100% das
  7.194.144 pessoas de ate 9 anos. Fica no codigo por paridade com o CEM;
- 1970 nao tem codigo para parente de empregado domestico. O destino provavel e
  `6-AGREGADO`, que a regra trata como parente: o filho da empregada entra no
  denominador do per capita enquanto a mae e a renda dela ficam fora. Nao e
  corrigivel com os dados de 1970; de 1980 em diante o IBGE separa;
- 22 domicilios tem V006 internamente inconsistente na fonte (10 com familia
  secundaria sem principal, 12 com principal sem secundaria).

## Mudanca de arquitetura

A tabela de domicilios deixa de ser lida pronta do CEM e passa a ser derivada do
arquivo de pessoas em `derive_households_1970()`. A derivacao legada reproduz os
4.737.407 domicilios do CEM em 100,000000% das 24.793.358 pessoas, o que autoriza
a troca; sem ela nao havia como corrigir 1, 2, 3 e 7.

O bloco estrutural do domicilio (V001-V004, V006-V021) passa a vir da linha do
chefe em vez de `mean()`. E equivalente -- zero domicilios tem mais de um valor
em V007 a V020 -- e resolve o defeito 7 de graca.

## Fora de 1970, achado pela auditoria (nao tratado nesta fase)

- **2000, GRAVE**: `V0300` e int32 na tabela de familias e string nas de
  domicilios e pessoas. Um join direto casa ZERO linhas, em silencio.
- **1991**: `V0102` e numeric em domicilios e character em pessoas; e a chave que
  o consumidor usa (`code_state`, `code_muni`, `V0109`) colapsa 4.024.543
  domicilios em 1.285.449 combinacoes.
- **1991**: um domicilio orfao no produto -- 4.024.543 linhas de domicilio contra
  4.024.542 `V0102` distintos no banco de pessoas. O orfao e `V0102 = 110043042`.
- `id_household` nao tem contrato entre edicoes: existe so em 1970;
  `censobr_idhousehold` em 1960; 1980, 1991 e 2000 nao tem coluna nomeada.
