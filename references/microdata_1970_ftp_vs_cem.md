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

## Decisão pendente

Se a paridade exata com o publicado importar mais que a reprodutibilidade,
1970 pode migrar para o `release_legacy`, como 1960, 1980 e 1991 — hospedando
o CSV da versão CEM. O custo é mais ~4 GB no release e a perda da fonte
pública. Pela rota atual, o dado é do IBGE, reprodutível por qualquer um, e
diverge em 2 pessoas e 275 domicílios.
