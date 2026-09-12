# Relatório: defeitos nos agregados por setor de 2010 publicados em v0.5.0

**Data:** 2026-09-12
**Escopo:** Censo Demográfico 2010 — Agregados por Setores Censitários — as 8 tabelas
publicadas no release `v0.5.0` do `censobr`, comparadas registro a registro com a
saída atual deste pipeline
**Status:** diagnóstico concluído; nenhum dos defeitos existe na saída atual

---

## 1. Resumo

Comparando as 8 tabelas de 2010 do `v0.5.0` com o que este pipeline produz hoje,
**cinco têm divergência e quatro são defeito real no publicado**. Nenhum deles
existe na saída atual.

| Tabela | Defeito no publicado | UF(s) | Natureza |
|---|---|---|---|
| Pessoa | sim | SP, GO | shift de nomes (+85) e perda |
| Domicilio | sim | RS | **tabela trocada** |
| Responsavel | sim | ES | sub-tabela inteira ausente |
| Basico | sim | 24 das 28 publicações | **perda de decimais** |
| Entorno | não | CE, DF, MG, PE, RS | ausência na origem, idêntica nas duas versões |
| DomicilioRenda | não | — | paridade perfeita |
| PessoaRenda | não | — | paridade perfeita |
| ResponsavelRenda | não | — | paridade perfeita |

O padrão que une três dos quatro: **o IBGE distribui, dentro do mesmo lote,
arquivos fora do formato dominante** — um `.xlsx` onde todos são `.xls`, um `.xls`
onde deveria haver `.csv`, decimais que um leitor não digeriu. O quarto, o shift de
São Paulo, é defeito de conteúdo do próprio IBGE e está descrito em
[relatorio_pessoa02_sp_shift.md](relatorio_pessoa02_sp_shift.md).

Método comum a todos: casamento 1:1 por `code_tract` entre as duas versões
(atenção — no `v0.5.0` a chave é `character`, no nosso é `double` pela convenção
v0.6.0; converter com `sprintf("%.0f", code_tract)`, nunca com `as.integer`, que
estoura nos 15 dígitos e devolve `NA` em silêncio).

---

## 2. Domicilio — o Rio Grande do Sul recebeu outra tabela

O mais grave dos quatro, porque os valores são plausíveis e estão errados.

**O que se mede.** Nas 22.332 linhas do RS, as 107 colunas `domicilio01_V135` a
`domicilio01_V241` são 100% NA. E as 134 colunas preenchidas não são de
Domicilio01: são, bit a bit, a tabela **Pessoa11 do RS**.

```
pub domicilio01_V<k>  ==  nosso pessoa11_V<k>     para k = 1..134
   134 de 134 colunas idênticas em 22.332 de 22.332 setores
```

Como Pessoa11 tem exatamente 134 variáveis e Domicilio01 tem 241, sobram
precisamente as 107 colunas que ficaram vazias. A aritmética fecha.

**A consequência numérica.** A soma de todas as 241 colunas de `domicilio01` no RS
é 20.754.004 no publicado contra 112.321.585 no nosso — **18,5% da massa correta**.
São 22.332 × 241 = **5.382.012 células erradas ou vazias**.

Um exemplo que qualquer usuário poderia ter consumido sem desconfiar:

| | valor |
|---|---:|
| `domicilio01_V001` do RS, publicado | 5.205.057 |
| valor correto (domicílios particulares permanentes no RS) | 3.653.000 |

Os 5.205.057 são, na verdade, `pessoa11_V001` — e coincidem também com
`domicilio02_V045`, "Homens moradores em domicílios particulares e coletivos".

**Fora do RS não há dano:** nas outras 26 UFs, publicado e nosso coincidem em
9.884 das 10.125 células (UF × coluna), e o bloco `domicilio02` está íntegro nas 27.

**Validação da nossa versão:** as 241 somas de `domicilio01` do RS batem exatamente
com o arquivo bruto do IBGE `DOMICILIO01_RS.csv` (republicação de 11/12/2024) nos
mesmos 22.332 setores — 241 de 241.

**Causa — inferência, não observação.** `DOMICILIO01_RS` é o único arquivo do lote
2010 em `.xlsx`, republicado em 11/12/2024; todos os demais são `.xls` de 2012. Um
discovery que procurasse só `.xls` não o encontraria, e o slot de Domicilio01 teria
sido preenchido posicionalmente com Pessoa11. O commit `c3710b7` deste repo é
literalmente *"fix(2010): inclui .xlsx no discovery de tracts (Domicilio01_RS)"*.
O script que gerou o `v0.5.0` não foi lido para confirmar.

---

## 3. Responsavel — o Espírito Santo perdeu uma sub-tabela inteira

**O que se mede.** Os 6.380 setores do ES têm NA em **todas as 109 colunas de
`responsavel01`** (`V1005` + `V001`–`V108`). São **684.613 valores** ausentes.

| | preenchimento de `responsavel01` no ES |
|---|---:|
| publicado v0.5.0 | 0,0000 |
| nosso | 0,9845 |
| demais UFs (as duas versões) | ~0,9800 |

**Não é shift.** A hipótese foi testada e rejeitada: `pub responsavel02_V001`
coincide com `nosso responsavel01_V001` em apenas 13 dos 6.380 setores (0,2%). O
bloco vazio é exatamente a sub-tabela inteira, posições 1 a 109 das 326 colunas de
variável.

**Fora do ES, paridade total:** casando por `code_tract` nos 310.114 setores,
publicado e nosso coincidem em 303.734/303.734 setores não-NA em
`responsavel01_V001`, e em 297.540/297.540 em `V054` e `V108`. Dentro do ES,
`responsavel02` está intacto nas duas versões (6.380/6.380).

**Causa — observada na fonte.** No pacote bruto do IBGE, em
`Base informaçoes setores2010 universo ES/CSV/`, **não existe
`RESPONSAVEL01_ES.csv`**. No lugar dele o IBGE distribuiu `RESPONSAVEL01_ES.xls`
(assinatura `D0 CF 11 E0`, 9.241.088 bytes, MD5
`E3B2A977B5CA09582C48FD58B4125471`), byte-idêntico ao de `EXCEL/RESPONSAVEL01_ES.xls`.
Um discovery baseado em `.csv` não acha a tabela para o ES; o join por estado gera
um parquet sem essas colunas, e a unificação de schema do `arrow::open_dataset`
preenche tudo com NA.

É a mesma família do quirk do `DOMICILIO01_RS.xlsx`. A regra de **XLS-first** deste
projeto é o que nos protege dela.

---

## 4. Basico — decimais viraram NA em 24 das 28 publicações

Defeito de mecanismo diferente dos outros três, e o de maior alcance geográfico.

**O que se mede.** Nas colunas `V003` a `V012` (10 colunas contíguas), o
preenchimento no publicado cai para algo entre 0,7% e 3%, contra ~98% no nosso.
Ao todo **1.800.306 valores** existem no nosso parquet e são NA no publicado.

Casos extremos: `RN V003` com 0,723% de preenchimento (o pior do país) e
`AP V010` com 0,864%.

**O mecanismo é a vírgula decimal**, e a evidência é unânime nos dois sentidos:

- **100,00%** dos valores que sobreviveram são inteiros exatos — em `V003`
  sobrevivem 3.905 de 184.589, e os únicos valores observados são 1, 2, 3, …, 54;
- **100,00%** dos valores que viraram NA têm casa decimal no nosso parquet
  (3,16 / 3,25 / 2,84).

**Não há shift:** onde o publicado tem valor, ele é idêntico ao nosso em 100,00%
dos casos nas 13 colunas, e `PUB_V003` só casa com `OUR_V003` — com as vizinhas,
0,28% ou 0,00%.

**A quebra é por arquivo-fonte, não por UF.** Escapam apenas MG, RJ, PR e
SP_Exceto_Capital (47.733 setores, 99,47% preenchido). **SP_Capital**, que é outro
arquivo do IBGE, **quebra** — 18.363 setores com 1,46% em `V003`. É a prova de que
o dano acompanha o arquivo, não a unidade federativa.

**Outros três defeitos do Basico publicado**, de menor gravidade mas que confundem:

- `abbrev_state` traz o código de dois dígitos (`"11"`, `"12"`, …) em vez da sigla,
  nas 310.120 linhas — por isso qualquer agrupamento por UF no Basico publicado
  precisa usar `substr(code_tract, 1, 2)`;
- `name_region` vem com o prefixo `"Regiao "` (`"Regiao Norte"` em vez de `"Norte"`);
- há uma coluna a mais, `Cod_municipio` (string), redundante com `code_muni`.

**Ressalva de critério.** Nenhuma combinação (UF, coluna) do Basico é *exatamente*
100% NA — o pior caso é `RN V003` com 99,277%. O defeito é real e grande, mas de
mecanismo distinto do shift; quem o tratar como "o mesmo bug do Pessoa02" vai errar.

**Inferência.** A perda de decimais não foi confirmada abrindo os XLS/CSV brutos;
vem de evidência indireta, porém unânime.

---

## 5. Pessoa — SP e GO

Detalhado em [relatorio_pessoa02_sp_shift.md](relatorio_pessoa02_sp_shift.md).
O que a varredura acrescenta, em números:

Das 54.000 combinações (UF × coluna V), o publicado tem **184 pares 100% NA** — 99
em GO e 85 em SP, **todos em pessoa02**. O nosso tem zero.

Um segundo teste, independente do NA, comparou a soma por UF de cada uma das 2.000
colunas: **53.731 de 54.000 (99,50%) batem exatamente**, e os 269 divergentes são
exclusivamente SP/pessoa02 (170 = 85 vazias + 85 deslocadas) e GO/pessoa02 (99
vazias). **Pessoa01 e Pessoa03 a Pessoa13 estão intactas nas 27 UFs.**

- **SP** — shift +85 provado no nível da linha:
  `pub pessoa02_V(i+85) == nosso pessoa02_V(i)` nas 85 colunas, em 66.096 de 66.096
  setores (100,000%).
- **GO** — não é shift, é perda pura: nenhuma coluna do publicado reproduz o nosso
  `GO pessoa02_V001`, e `pub GO pessoa02_V100..V170` é idêntico ao nosso em 71/71
  colunas × 9.434 setores. É o defeito dos nomes sem zero à esquerda (`V01`–`V099`),
  que o IBGE corrigiu na origem em 15/09/2025.

---

## 6. Entorno — não é defeito, é ausência na origem

Registrado para não ser confundido com os demais.

As 95 colunas descritivas não-V (19 por tema × 5 temas: `Setor_Precoleta`, códigos e
nomes de região, UF, meso, micro, RM, município, distrito, subdistrito, bairro) estão
100% vazias em **CE, DF, MG, PE e RS** — 475 combinações (UF, coluna), 84.900
setores, 27,38% do país. **Isso ocorre identicamente nas duas versões.**

A causa foi confirmada na fonte: o XLS do IBGE desses cinco estados tem **203
colunas** (`Cod_setor` + `Situacao_setor` + 201 V) contra **222** em AC/SC (21 não-V
+ 201 V). O IBGE simplesmente não publicou o bloco descritivo para eles.

Nenhuma coluna V é afetada, `V1005` está preenchida nas 27 UFs, e a informação
geográfica equivalente é reposta pelo `censobr` em `code_muni`, `code_state`,
`name_state` e `code_region`. O teste de deslocamento por correlação de perfis
(lags −100 a +100) deu **lag ótimo 0 em 135 de 135** combinações tema × UF.

Os NAs restantes do Entorno são por linha, não por coluna: em `entorno01`, 6.302
setores têm a linha inteira vazia e 303.818 têm as 201 colunas preenchidas — zero
linhas parcialmente preenchidas.

---

## 7. As três tabelas limpas

| Tabela | Colunas | Células comparadas | Diferenças |
|---|---:|---:|---:|
| DomicilioRenda | 23 | 4.651.800 | **0** |
| PessoaRenda | 141 | 41.245.960 | **0** |
| ResponsavelRenda | 141 | — | **0** |

Em ResponsavelRenda o menor preenchimento observado é 0,9555 (SC, 11.353 de 11.882
setores) e é idêntico em todas as colunas V daquela UF — padrão de setor sem
informação, não defeito.

---

## 8. Cobertura e limites

Foram testadas as 8 tabelas, todas as 27 UFs e todas as colunas de variável de cada
tabela, nas duas versões. Nas tabelas grandes a comparação de valores foi feita por
soma agregada por UF, não célula a célula: uma permutação de linhas **dentro** da
mesma UF que preservasse as somas não seria detectada — cenário implausível, dado
que as chaves `code_tract` casam 1:1 e sem duplicatas.

Um viés que **nenhum** destes testes detecta: um deslocamento que afetasse
identicamente as 27 UFs nas duas versões. Detectá-lo exigiria confrontar os rótulos
com o dicionário de referência em
[`phgfsouza_census_tracts/`](phgfsouza_census_tracts/) — foi o que revelou o shift
de SP, e vale repetir por tema.

---

## 9. O que isto implica

1. **Não republicar 2010 a partir do baseline `v0.6.0`** guardado em
   `data_raw/baseline_compare/v0.6.0/`: ele já tem o fix de GO, mas **ainda carrega
   o shift de SP** (SP fica 0 em `pessoa02_V001`; o defeito só foi descoberto em
   04/05/2026, depois daquele build).
2. Antes de comunicar ao IBGE, **separar o que é defeito de origem do que é
   consequência**: o shift de SP em Pessoa02 e a heterogeneidade de formato dentro
   do mesmo lote são do IBGE; a tabela trocada do RS, a sub-tabela perdida do ES e
   os decimais do Basico são consequências dela no pipeline antigo.
3. Verificar **quais defeitos persistem na distribuição atual do IBGE** — o RS foi
   republicado em 12/2024 e o GO em 09/2025. Reportar algo já sanado enfraquece a
   carta.
