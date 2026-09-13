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

### Os blocos grandes do `iddomicilio` são domicílios coletivos

Numa primeira leitura, medida só nas primeiras 6 milhões de linhas do CSV de
pessoas, esses blocos pareciam falha do `na.locf`: 8.038 deles, o maior com
1.281 pessoas num só `iddomicilio`, todos com `V006 == 0`, `V007` inteiramente
NA, nenhum chefe e `V005 == 1`. **Não são falha.** Medido no arquivo inteiro,
são 40.310 blocos com 339.316 pessoas, o maior com **3.337** — e o perfil é o
de domicílio coletivo, não o de fronteira perdida:

- `V006 == 0` ⟺ `V025 == 9` em 339.316/339.316, e `V025 == 9` não aparece em
  mais nenhum registro dos 24.793.358;
- 40.309 dos 40.310 blocos são 100% compostos por eles;
- idade mediana de **25 anos** e **11,7%** de menores de 15 — perfil de quartel
  e internato. Quem mora sozinho de fato (`V006 == 1`, `V005 == 1`,
  `V025 == 1`) são 243.142 pessoas com mediana de **49 anos** e 1,2% de
  menores, e já estão no produto como domicílios unipessoais.

O dicionário do IBGE rotula `V006 = 0` como "PESSOA SÓ", o que induz ao erro.
No vocabulário do censo "só" quer dizer sem laços de parentesco no domicílio,
não morando sozinho: a definição da categoria é *"Individual em domicílio
coletivo — para a pessoa só que residia em domicílio coletivo, ainda que
compartilhando a unidade de habitação com outra(s) pessoa(s) com a(s) qual(is)
não tinha laços de parentesco"*. Dicionário e questionário concordam.

Não dá para separar dois coletivos adjacentes nas linhas do arquivo, e não faz
falta: coletivos ficam fora do banco de domicílios por decisão editorial, já
que renda domiciliar per capita não significa nada em hotel, quartel, convento
ou presídio, cujos moradores não partilham orçamento.

Duas verificações delimitam o problema:

- **o bloco de domicílio é coerente**: zero domicílios com mais de um valor
  real em V007, V008, V009 ou V010 (medir isso exige ignorar NA — essas
  variáveis só vêm preenchidas na primeira pessoa, o que é justamente o motivo
  de existir o `na.locf`);
- **os identificadores não-blob estão certos**: em domicílios de família única
  com chefe presente, o tamanho bate com `V005` (total de pessoas da família)
  em **99,93%** dos casos (1.074.813 de 1.075.550); 736 maiores, 1 menor.

O vínculo só vale quando resolve na tabela de domicílios. Ficam com
`id_household = NA` **453.643 pessoas (1,830%)** — 339.316 indivíduos em
domicílio coletivo, 114.325 pessoas de famílias que moram em coletivo e 2
residuais — com **zero** ids órfãos.

### Família e domicílio: os agregados foram refeitos

A tabela de domicílios deixou de ser lida pronta do CEM e passou a ser derivada
do arquivo de pessoas. A troca se justifica porque a derivação legada reproduz
os 4.737.407 domicílios do CEM em **100,000000%** das 24.793.358 pessoas — e
sem refazer os agregados não havia como corrigir o que segue.

`V005`, `V006` e `V025` são variáveis de **família**; `numb_dwellers`,
`hh_income` e `weight_household` são de **domicílio**. O produto confundia as
duas coisas em quatro pontos:

| defeito | escala | correção |
|---|---:|---|
| `weight_household` usava `max(V054)` entre os chefes de **família**. Em domicílio multifamiliar há dois ou três `V025 == 1`, e o `max` adotava sistematicamente o maior — nunca o do chefe do domicílio | 46.136 domicílios; `sum` inflado em **+0,3029%** | passa a ser o peso do chefe da família única/principal, que é exatamente 1 por domicílio em 4.741.386 de 4.741.386 |
| `V006` era a **média** do `V006` das pessoas. Quem filtrasse `V006 == 2` para achar domicílio multifamiliar encontrava **15 linhas** em vez de 233.855 | 230.317 linhas (4,86%) com valores como 2,5 e 2,33, inexistentes no dicionário | passa a ser a condição da família do chefe do domicílio: só 1 ou 2 |
| `V003` e `V004` também saíam de `mean()`, gerando código de distrito e situação urbano/rural que não existem | 4 e 26 linhas | o bloco estrutural passa a vir da linha do chefe |
| `V025 == 0` é **IGNORADO**, não não-parente, e era excluído do denominador da renda per capita — a pessoa saía do denominador *e* tinha a renda zerada | 341 pessoas em 322 domicílios; mediana do per capita 45,98 contra 40,00 | volta a contar como morador |

Duas colunas novas, que o produto não tinha:

- **`numb_families`** — quantas famílias moram no domicílio: 4.507.531 com uma,
  218.060 com duas, 15.795 com três. O máximo em 1970 é três.
- **`numb_residents`** — `sum(V024 != 2)`. `numb_dwellers` conta linhas do
  domicílio, inclusive as **154.719 pessoas que o IBGE marca como NÃO MORADOR**
  (`V024 == 2`, todas pensionista ou hóspede). As duas diferem em 103.509
  domicílios (2,18%), onde a média de moradores cai de 6,78 para 5,29.

Os agregados já somavam **todas** as famílias do domicílio, e isso foi
confirmado: `numb_dwellers_hhincome` é o total de parentes de todas as famílias
em **100,0000%** dos casos, e `hh_income` soma a renda de todas elas (se contasse
só a principal, perderiam-se 60.002.161 em renda).

### O bloco de características da habitação, completado

`V007`–`V021` só vinham preenchidos nos registros da família única ou principal:
**`V007` não-NA ⟺ `V006 ∈ {1,2}`**, sem uma única exceção. A razão está no
formulário: os códigos marcados com **E** no impresso (`0E Individual`,
`3E Parente`, `4E Não parente` em Família; `1E` em Espécie; `2E` em Tipo) são
instruções de **salto**. A cascata fecha registro a registro:

```
V007 NA      = V006 ∈ {0,3,4}                 = 1.162.064
V008 NA      = isso + os 114.325 de V007==1   = 1.276.389
V009–V020 NA = isso + os 14.212 improvisados  = 1.290.601
```

O efeito no produto era que **822.746 pessoas de famílias secundárias, em
233.776 domicílios (4,93%), não tinham condição de ocupação, água, sanitário,
cômodos nem dormitórios** — embora morem num domicílio cujas características
foram registradas, no registro dos vizinhos de domicílio. Como o bloco é do
domicílio e não da família — zero domicílios têm mais de um valor em `V007`–`V020`
— ele é completado por domicílio. Taxa de preenchimento de `V009` para família
secundária: de **0,00%** para **99,97%**.

`V021` recebeu tratamento próprio: vinha `0` em 61.390 registros de família
secundária e de individual em coletivo, e ali zero não é número de dormitórios,
é o branco do impresso. Vira `NA` antes do preenchimento, e depois recebe o
valor do domicílio.

O marcador `V007 == 1` das 114.325 pessoas de famílias que moram em domicílio
coletivo é preservado — é o único registro no arquivo de que aquele
estabelecimento é coletivo, já que o boletim "Individual" não descreve domicílio
nenhum. Por isso o preenchimento é por `coalesce`, não por substituição.

### Paridade verificada

| | nosso | publicado v0.5.0 | |
|---|---:|---:|---|
| pessoas | 24.793.358 | 24.793.358 | |
| domicílios | 4.741.386 | 4.737.407 | +3.979 improvisados |
| colunas (nomes e ordem) | 65 / 35 | idênticos | |
| `id_household` NA | 453.643 | 468.164 | −14.521 improvisados |
| ids órfãos | 0 | 0 | |
| domicílios sem morador | 0 | — | |
| `numb_dwellers` == contagem real | 100,000000% | — | |
| máximo de moradores | 37 | 37 | |
| `sum(V054)` | 94.461.969 | 94.461.969 | |
| `sum(weight_household)` | 17.643.387 | 17.682.112 | −38.725 (peso do chefe do domicílio) |
| domicílios com peso zero | 4 | 4 | defeito da fonte: `V054 == 0` em 4 chefes |
| NA nas 9 colunas de geografia | 0 | — | |

Contra a tabela do CEM, nos 4.737.407 domicílios em comum, divergem apenas as
colunas que deviam divergir, e nas escalas previstas: `v006` em 233.776,
`wgthh` em 46.118, `numb_dwellers_hhincome` em 321 e `hhIncomePerCap` em 314 —
este último exatamente o número previsto de forma independente para a correção
do `V025 == 0`. `numb_dwellers` é idêntico em 100%. `v003` difere em 6 e `v004`
em 33, que são os domicílios cujo `mean()` produzia código inexistente.

Também mudou `name_region`, por grafia: v0.5.0 traz "Centro-oeste" e o pipeline
produz "Centro-Oeste" nos 220.162 domicílios da região (4,647%); `code_region`
bate em 100%. É anterior a esta mudança — já estava no build v0.6.0.

Integridade após o rebuild: **zero** órfãos, **zero** domicílios sem morador,
`numb_dwellers` igual à contagem real em **100,000000%**, e o bloco do domicílio
preenchido em todos os moradores de 4.737.407 domicílios (contra 4.503.631
antes). Os 3.979 restantes são os improvisados, para os quais o IBGE não coletou
o bloco.

### Os domicílios improvisados entram (divergência intencional)

A derivação do CEM anula o id de quem mora em domicílio improvisado — a regra
`(5.2) Assigning NA to improvised households`, que testa `mean(v008) == 2` em
`R_ainda_sem_targets/microdata_sample_1970a_household_ids_and_dataset.R`. São
3.979 domicílios e 14.521 pessoas. Mas improvisado é domicílio particular, e
excluí-lo enviesa qualquer análise distributiva: some justamente a população
mais precária. A evidência de que os grupos são sólidos:

- `V007 == 0` (particular) em 14.212/14.212;
- exatamente **um** chefe em cada um dos 3.979 grupos;
- o tamanho do grupo bate com o `V005` do chefe em **3.900 de 3.900** famílias
  únicas; nos 79 grupos com família secundária, o tamanho é sempre ≥ `V005`;
- cada grupo é um bloco contíguo único no arquivo.

`V009`–`V020` saem NA: o IBGE não aplica o bloco de características da
habitação a domicílio improvisado. Renda mediana de 100 contra 200 no resto da
tabela, e média de 3,65 moradores contra 5,14 — coerente.

A reimplementação da derivação legada em `derive_improvised_1970()` reproduz o
publicado em **100,000000%** (24.793.358 de 24.793.358 pessoas e os 4.737.407
domicílios), e o crosswalk do CEM bate com ela em 100,000000% das outras
24.325.194 pessoas. Os ids criados não colidem com nenhum existente.

### Risco residual

Os **736 domicílios** (0,07%) em que o tamanho excede o `V005` do chefe. Podem
ser famílias secundárias legítimas ou fronteiras perdidas menores; os dois
casos não foram separados.
