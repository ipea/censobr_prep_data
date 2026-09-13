# O deslocamento de nomes no Pessoa02 de São Paulo (agregados por setor, Censo 2010)

**Data:** 2026-09-13 (substitui a versão de 2026-05-04)
**Escopo:** Censo Demográfico 2010, agregados por setores censitários, tema Pessoa02 (alfabetização por sexo) — o defeito nos arquivos de São Paulo distribuídos pelo IBGE, como ele se demonstra, o que o produto `censobr` faz com ele e o que a v0.5.0 publicada tinha.

---

## O defeito

`Pessoa02_SP1.xls` e `Pessoa02_SP2.xls` têm as mesmas 170 variáveis que o
dicionário oficial define para Pessoa02, com os mesmos significados e os
mesmos valores, mas com os **nomes deslocados em +85**: o que o dicionário
chama de `V001` está nesses arquivos como `V086`, e o `V170` como `V255`. As
colunas `V001`–`V085` não existem nos dois arquivos (0 de 85); `V086`–`V170`
e `V171`–`V255` existem todas (85 de 85 cada). Nas outras 26 UFs, Pessoa02
vai de `V001` a `V170`.

`SP1` é o município de São Paulo (3550308, 18.363 setores); `SP2` são os
outros 644 municípios do estado, inclusive Guarulhos (1.705 setores) e
Osasco. As pastas do zip chamam-se `SP_Capital` e `SP_Exceto_Capital`. O
dicionário do IBGE se contradiz a respeito: em dois trechos diz "município de
São Paulo" e na nota de rodapé 3 diz "Região Metropolitana".

O deslocamento é exclusivo de Pessoa02 em SP1 e SP2, verificado em todas as
28 publicações (26 UFs + SP1 + SP2) e todos os temas. Nos 13 arquivos da
família Pessoa, só um difere entre AC e SP1:

| arquivo | AC | SP1 |
|---|---|---|
| Pessoa01 | V001–V085 | V001–V085 |
| **Pessoa02** | **V001–V170** | **V086–V255** |
| Pessoa03 | V001–V251 | V001–V251 |
| Pessoa04 | V001–V155 | V001–V155 |
| Pessoa05 | V001–V010 | V001–V010 |
| Pessoa06 | V001–V213 | V001–V213 |
| Pessoa07 | V001–V204 | V001–V204 |
| Pessoa08 | V001–V254 | V001–V254 |
| Pessoa09 | V001–V240 | V001–V240 |
| Pessoa10 | V001–V003 | V001–V003 |
| Pessoa11 a Pessoa13 | V001–V134 | V001–V134 |

Dois padrões que parecem deslocamento e não são: a numeração de
`ENTORNO02`–`ENTORNO05` começa em 202, 422, 623 e 843 por desenho do IBGE,
idêntica nas 28 publicações; e `DOMICILIO02_RO` tem 241 colunas `V` contra
132 nas outras 26 UFs, sem deslocamento.

Nenhuma fonte documental acusa o defeito: o dicionário oficial (*Base de
informações por setor censitário, Censo 2010 — Universo*, seção 6.7) define
Pessoa02 = `Cod_setor + Situacao + V001..V170` sem variante para SP; o log de
atualizações do FTP registra a correção análoga de Goiás (nomes `V01`–`V99`,
sem o zero, corrigidos em 15/09/2025) e nada sobre SP; a transcrição de
Pedro Souza reproduz o dicionário.

**O defeito sobrevive à republicação de 15/06/2026.** O IBGE republicou as 27
UFs como `*_20260615.zip` e trocou o log `1_Atualizacoes_20250915.txt` (hoje
HTTP 404) por `1_Atualizacoes_20260615.txt`, que registra apenas a correção
do `Cod_setor` nos CSVs. O `pessoa02_sp1.csv` dessa publicação continua com
172 colunas e `V086`–`V255` contíguas.

## Como o deslocamento se demonstra

Pessoa01 e Pessoa02 descrevem a mesma população: Pessoa01 traz, por setor,
os alfabetizados de 5 anos ou mais por idade simples (`V001` total, `V002` a
`V077` por idade) e por relação de parentesco (`V078`–`V085`); Pessoa02 traz
as mesmas 85 contagens para homens (`V001`–`V085`) e para mulheres
(`V086`–`V170`). Para todo `i` de 1 a 85:

```
Pessoa01_V_i  =  Pessoa02_V_i  +  Pessoa02_V_(i+85)
   total            homens           mulheres
```

Em SP, com os nomes deslocados, a identidade se escreve
`Pessoa01_V_i = Pessoa02_V_(i+85) + Pessoa02_V_(i+170)`. Setor a setor, ela
fecha com diferença exatamente zero em 100% dos setores não censurados, nas
85 categorias: 854 de 854 no AC (controle, sem deslocamento), 18.206 de
18.206 em SP1 e 46.511 de 46.511 em SP2.

Agregada por UF, 84 das 85 identidades fecham em zero e a de `V001` difere —
247 no AC (0,046%), 4.070 em SP1 (0,041%), 87.098 em SP2 (0,33%):

| i | Pessoa01 | homens (SP) | mulheres (SP) | total Pessoa01, SP1 | soma H+M | diferença |
|---|---|---|---|---:|---:|---:|
| 1 | V001 | V086 | V171 | 10.033.341 | 10.029.271 | 4.070 |
| 2 | V002 | V087 | V172 | 54.127 | 54.127 | 0 |
| 3 | V003 | V088 | V173 | 84.746 | 84.746 | 0 |
| 4 | V004 | V089 | V174 | 119.464 | 119.464 | 0 |
| 5 | V005 | V090 | V175 | 136.842 | 136.842 | 0 |
| … | | | | | | 0 |
| 85 | V085 | V170 | V255 | | | 0 |

A diferença em `V001` é a censura por sigilo, que é simétrica: cada uma das
170 colunas de Pessoa02 e as colunas `V002`–`V085` de Pessoa01 têm 20 (AC),
157 (SP1) e 1.222 (SP2) células `X`; a única sem nenhuma célula `X` é
`Pessoa01_V001`, que o IBGE preserva como variável estrutural. Por isso 84
identidades somam zero dos dois lados nos setores censurados, e a 85ª difere
exatamente pela soma de `Pessoa01_V001` nesses setores (média de 12,3 / 25,9
/ 71,3 alfabetizados por setor censurado). A taxa de censura não cresce com o
tamanho da UF: AC 2,29%, SP1 0,85%, SP2 2,56%; no Quadro 1 do IBGE, PB 0,6%,
SC 4,5%, AC 2,3%, SP 2,1%, Brasil 2,0%.

## A correspondência

Para todo `n` de 86 a 255, o `V<n>` publicado em SP1 ou SP2 é o `V<n − 85>`
do dicionário:

| significado (dicionário) | canônico | em SP1/SP2 |
|---|---|---|
| homens alfabetizados, 5 anos ou mais | V001 | V086 |
| homens alfabetizados, 5 anos | V002 | V087 |
| … | … | … |
| homens alfabetizados, 80 anos ou mais | V077 | V162 |
| homens responsáveis alfabetizados, 10 anos ou mais | V078 | V163 |
| … | … | … |
| homens conviventes alfabetizados, 10 anos ou mais | V085 | V170 |
| mulheres alfabetizadas, 5 anos ou mais | V086 | V171 |
| mulheres alfabetizadas, 5 anos | V087 | V172 |
| … | … | … |
| mulheres alfabetizadas, 80 anos ou mais | V162 | V247 |
| mulheres responsáveis alfabetizadas, 10 anos ou mais | V163 | V248 |
| … | … | … |
| mulheres conviventes alfabetizadas, 10 anos ou mais | V170 | V255 |

## O que o produto faz

Em `R/census_tracts_2010.R`, `read_single_file_tract_2010()` renomeia
`V<n>` para `V<n − 85>` (`n ≥ 86`) quando o arquivo é Pessoa02 de SP1 ou
SP2, antes do prefixo de tema. Sem a renomeação, a união dos nomes de Pessoa02
nas 28 publicações daria 256 colunas (`V001`–`V255` + `V1005`), 85 delas
espúrias; com ela, 171.

No parquet `2010_tracts_PESSOA.parquet`: 2.008 colunas, 310.114 setores,
exatamente 171 colunas `pessoa02_V*` (`V001`–`V170` + `V1005`). A identidade
`pessoa02_V_i + pessoa02_V_(i+85) = pessoa01_V_i` vale nas 85 categorias em
todos os 66.096 setores de São Paulo (18.363 + 47.733, o mesmo total do
Quadro 1 do IBGE): 1.379 (2,1%, também igual ao Quadro 1) estão suprimidos
dos dois lados e, nos 64.717 restantes, a soma das diferenças absolutas é 0.

## O que a v0.5.0 publicada tem

Em SP, `pessoa02_V001`–`V085` são 100% NA; `pessoa02_V086`–`V170` contêm o
dado **masculino**, que deveria estar em `V001`–`V085`; e não existem colunas
`V171`–`V255`, de modo que o dado **feminino** de São Paulo se perdeu no
empilhamento. Nas outras UFs, `V086`–`V170` estão preenchidas (NA entre 0,59%
e 4,45%). Nenhum parquet publicado ou construído teve 256 colunas
`pessoa02_V*`.

Goiás é um defeito distinto: os nomes malformados `V01`–`V99` deixavam, na
v0.5.0, 99 das 171 colunas `pessoa02_V*` de GO 100% NA e 72 com dado. O IBGE
corrigiu os arquivos em 15/09/2025; o pipeline trata o caso.

## Para a carta ao IBGE

Os arquivos `Pessoa02_SP1` e `Pessoa02_SP2` continuam com os nomes
deslocados na publicação de 15/06/2026, que é a que deve ser citada.
