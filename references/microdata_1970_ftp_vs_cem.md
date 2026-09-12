# Microdados 1970: FWF do FTP IBGE × versão publicada (CEM)

**Data:** 2026-09-11
**Motivo:** documentar por que o porte de 1970 não atinge paridade exata com
os parquets publicados, e quanto é a diferença

---

## Conclusão

O produto publicado de 1970 **não vem do FWF do FTP do IBGE**. Vem da versão
harmonizada pelo **CEM (Centro de Estudos da Metrópole)** — o CSV auxiliar traz
cinco colunas `cem001`–`cem005` que não existem no arquivo do IBGE.

São duas versões do mesmo censo, com pequenas diferenças de conjunto de
registros. A rota do FTP (que é a reprodutível) chega a **+2 pessoas** e
**+275 domicílios** em relação ao publicado — 0,000008% e 0,006%.

## Números

| | Porte (FTP) | Publicado (CEM) | Δ |
|---|---:|---:|---:|
| population, linhas | 24.793.360 | 24.793.358 | **+2** |
| households, linhas | 4.737.682 | 4.737.407 | **+275** |
| colunas | 65 / 35 | 65 / 35 | iguais, mesma ordem |
| `sum(V054)` | 94.467.917 | 94.461.969 | +0,006% |
| `sum(weight_household)` | 17.685.053 | 17.682.112 | +0,017% |

A diferença se concentra em **duas UFs**:

| UF | population (porte) | population (publicado) | Δ |
|---|---:|---:|---:|
| PE (26) | 1.382.320 | 1.382.323 | −3 |
| AL (27) | 412.171 | 412.166 | +5 |

As outras 25 UFs batem exatamente, pessoa a pessoa. Em households a mesma
concentração: PE +301 e AL −26.

## O que o porte trata

1. **Byte de fim de arquivo do DOS.** Cada um dos 27 `.txt` termina com um
   `0x1A` que o `read_fwf` transforma num registro todo vazio. Descontados os
   27, o total da rota FTP dá **24.793.358 — exatamente o publicado**. São
   descartados com contagem no log, como em 2000.
2. **Registros com `V001`/`V002` corrompidos.** 156 pessoas (0,0006%) têm
   microrregião/município ilegíveis e a chave não resolve no crosswalk. O
   município fica `NA`, mas a **UF é preservada** — ela vem do nome do
   arquivo, não do registro, então é conhecida com certeza.
3. **Registros sem peso.** `V054` falta em 1.114 das 24,8 milhões de pessoas.
   Quando falta justamente no chefe, o domicílio fica sem peso: são **131
   domicílios** em 4,7 milhões. O valor emitido é `NA`, não `NaN`. Idem
   `hh_income` (2) e `hh_income_per_cap` (268). O publicado não tem nenhum
   desses casos — mais um sinal de que a versão CEM passou por limpeza.

## Armadilhas do 1970 que o porte resolveu

- **O registro não tem campo de UF.** Ela vem do nome do arquivo
  (`Damo70<UF>.txt`, em caixa mista), e o código de UF de 1970 sai do próprio
  `crosswalk_munic_1970_to_2010.rda`.
- **A chave de município** é `uf*1e5 + (V001 %% 100)*1e3 + V002`, que resolve
  95% das linhas. As exceções estão no crosswalk: `2531000` = Guanabara → Rio
  de Janeiro (1,1 milhão de pessoas) e `3600000` = Distrito Federal →
  Brasília (135.571). Uma cascata de três chaves cobre o resto.
- **A ordem das linhas é semântica.** O registro de domicílio não existe na
  fonte: é derivado das pessoas por `na.locf` sobre a ordem original. Os
  arquivos entram em ordem alfabética do nome em maiúsculas (AC..SP) — a
  primeira linha do produto é Acre com `V001=11, V002=101`, idêntica à
  primeira de `DAMO70AC.txt`, e a última é São Paulo.
- **Atribuições em passos, não `fifelse`.** Na renda e no peso, quando a
  condição é `NA` o valor inicial tem que ficar de pé — que é o que o script
  original fazia. Com `fifelse` o `NA` se propaga e zera o peso do domicílio
  inteiro. Foi o que fez `weight_household` sair `NaN` na primeira tentativa.

## Decisão tomada (2026-09-12): 1970 migra para o `release_legacy`

A rota do FTP foi abandonada. O motivo não foi a divergência de 2 pessoas e
275 domicílios, e sim a **corrupção de origem em `DAMO70AL.txt` e
`Damo70PE.txt`**: 1.785 registros deslocados, dos quais 1.573 só têm o peso
recuperável e seguem com o miolo fora de lugar
(ver [microdata_1970_corrupcao_al_pe.md](microdata_1970_corrupcao_al_pe.md)).
A versão CEM não tem esse defeito.

O custo estimado de ~4 GB **não se confirmou**: em parquet zstd os três
insumos somam **436 MB**.

| insumo no `release_legacy` | CSV de origem | parquet |
|---|---:|---:|
| `Censo.1970.brasil.domicilios.amostra.25porcento.parquet` | 425 MB | 41 MB |
| `Censo.1970.brasil.pessoas.amostra.25porcento.parquet` | 3,9 GB | 337 MB |
| `crosswalk_personid_hhid_1970.parquet` | 499 MB | 58 MB |

### O crosswalk é indispensável

Chegou-se a supor que ele fosse dispensável, porque o arquivo de pessoas traz
`iddomicilio` e `idpessoa`. **Não é.** O `iddomicilio` das pessoas é outro
espaço de numeração — 4.803.419 valores densos de 1 a 4.803.419 — e não casa
com o `household_id` dos domicílios (4.737.407): 99,9% não resolvem. Nem por
fórmula: `(iddomicilio * 100 + V003) * 10 + V004` acerta os primeiros
registros e erra em 72% do total.

### Os identificadores do CEM também vêm de `na.locf`, e têm falha

Medido nas primeiras 6 milhões de linhas do CSV de pessoas: **8.038 blocos**
em que a fronteira nunca foi encontrada, o maior com **1.281 pessoas** num só
`iddomicilio`. O perfil é sempre o mesmo — `V006 == 0` (unipessoal), `V007`
inteiramente NA, nenhum chefe, `V005 == 1`. Entre eles, 65% têm mais de um
morador.

Duas verificações delimitam o problema:

- **o bloco de domicílio é coerente**: zero domicílios com mais de um valor
  real em V007, V008, V009 ou V010 (medir isso exige ignorar NA — essas
  variáveis só vêm preenchidas na primeira pessoa, o que é justamente o motivo
  de existir o `na.locf`);
- **os identificadores não-blob estão certos**: em domicílios de família única
  com chefe presente, o tamanho bate com `V005` (total de pessoas da família)
  em **99,93%** dos casos (1.074.813 de 1.075.550); 736 maiores, 1 menor.

O defeito **não chega ao produto**, porque o vínculo só vale quando resolve na
tabela de domicílios. É a regra que o pipeline aplica: 468.164 pessoas (1,888%)
ficam com `id_household = NA` e **zero** ids órfãos — idêntico ao publicado.

### Paridade verificada

| | nosso | publicado v0.5.0 |
|---|---:|---:|
| pessoas | 24.793.358 | 24.793.358 |
| domicílios | 4.737.407 | 4.737.407 |
| colunas (nomes e ordem) | 65 / 35 | idênticos |
| `id_household` NA | 468.164 | 468.164 |
| ids órfãos | 0 | 0 |
| máximo de moradores | 37 | 37 |
| `sum(V054)` | 94.461.969 | 94.461.969 |
| `sum(weight_household)` | 17.682.112 | 17.682.112 |
| NA nas 9 colunas de geografia | 0 | — |

### Risco residual

Os **736 domicílios** (0,07%) em que o tamanho excede o `V005` do chefe. Podem
ser famílias secundárias legítimas ou fronteiras perdidas menores; os dois
casos não foram separados.
