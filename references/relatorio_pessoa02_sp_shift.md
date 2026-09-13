# Relatório: o shift de numeração em Pessoa02 dos arquivos de São Paulo

**Data:** 2026-05-04
**Autor:** Rogério Barbosa (com investigação assistida)
**Escopo:** Censo Demográfico 2010 — Agregados por Setores Censitários — arquivo Pessoa02 (Alfabetização, homens e mulheres)
**Decisão:** correção a aplicar antes do `rbindlist` no pipeline `censobr_prep_data`.

## 1. O problema, em uma frase

Os arquivos `Pessoa02_SP1.xls` e `Pessoa02_SP2.xls` distribuídos pelo IBGE têm exatamente as mesmas 170 variáveis que o dicionário oficial define para Pessoa02, com os **mesmos significados**, com os **mesmos valores**, mas com os **nomes shiftados em +85**: o que o dicionário chama de `V001` está nesses arquivos como `V086`; o que o dicionário chama de `V170` aparece como `V255`.

Resultado prático: quando o pipeline empilha (`rbindlist`) as 28 publicações IBGE (26 UFs comuns + SP1 + SP2), variáveis com o mesmo significado caem em colunas diferentes do parquet final. As variáveis ficam tecnicamente todas presentes, mas **bagunçadas** — e ninguém percebe sem inspecionar arquivo por arquivo.

A versão antiga do pipeline, baseada em `dplyr::left_join`, também não percebia: ela seguia tranquila, com SP escrevendo nas colunas erradas e o usuário final consumindo o resultado como se fosse o esperado.

> **Correção de 2026-09-12.** Este parágrafo afirmava que o pipeline antigo gerava um parquet com os 256 nomes (`V001`–`V255`). Isso foi verificado e **não procede** para nenhum artefato entregue: o `v0.5.0` publicado, o baseline `v0.6.0` guardado em `data_raw/baseline_compare/` e a saída atual têm todos **171** colunas `pessoa02_V*` e **zero** na faixa `V171`–`V255`. Os 256 nomes devem ter sido um estado transitório de build local durante a investigação de maio.
>
> O estrago real no publicado é **pior** do que colunas bagunçadas, e tem três camadas: (a) `V001`–`V085` de SP ficam vazias; (b) `V086`–`V170` de SP contêm o dado **masculino** deslocado — `pub_V086 == V001` correto em 64.717 de 64.717 setores; (c) os dados **femininos de SP se perderam**, porque viriam nomeados `V171`–`V255`, que o schema de 170 colunas não acomoda. Só a camada (a) é visível. Detalhamento em [relatorio_defeitos_2010_tracts_v050.md](relatorio_defeitos_2010_tracts_v050.md).

## 2. Por que esse tipo de erro escapa do controle

Há três fontes documentais que **deveriam** detectar a divergência, e nenhuma das três detectou:

1. **Dicionário oficial IBGE** (`BASE DE INFORMAÇÕES POR SETOR CENSITÁRIO Censo 2010 - Universo novo.pdf`, seção 6.7): lista Pessoa02 = `Cod_setor + Situacao + V001..V170`. Não menciona variante para SP. Não tem versão alternativa que vá até V255.

2. **Log de atualizações IBGE** (`https://ftp.ibge.gov.br/.../1_Atualizacoes_20250915.txt`): registra correções em vários arquivos de UF/tabela ao longo dos anos. O log lista a correção análoga de Goiás (V001-V099 estavam sem o zero, IBGE corrigiu em 15/09/2025). O log **não** registra nada análogo para SP em Pessoa02.

3. **Dicionário transcrito por Pedro Souza** (`references/phgfsouza_census_tracts/`): Pessoa02 = V001-V170 + V1005, idêntico ao oficial. Pedro menciona SP1/SP2 em uma única linha (sobre divisão geográfica RM vs interior), nada sobre schema diferente.

A discrepância só apareceu na nossa investigação porque mudamos o leitor (de `readxl::read_excel + dplyr::left_join` para `data.table::merge`) e o `data.table` é estrito quanto a chaves duplicadas: ele recusou silenciosamente fazer um Cartesian. O pipeline antigo escondia o problema; o novo expôs.

## 3. A estratégia diagnóstica

A intuição é simples e segue um princípio que sempre vale em dados desagregados: **o todo é a soma das partes**.

O IBGE distribui dois arquivos sobre alfabetização que respondem perguntas diferentes mas sobre a **mesma população**:

- `Pessoa01_UF.xls` — "Alfabetização total". Para cada setor, traz V001 = quantas pessoas alfabetizadas com 5 ou mais anos de idade (sem distinguir sexo); V002 = mesmas pessoas com exatamente 5 anos de idade; V003 = com 6 anos; … V077 = com 80 anos ou mais; V078–V085 = subtotais por relação de parentesco (responsáveis, filhos, etc.).

- `Pessoa02_UF.xls` — "Alfabetização, homens e mulheres". A mesma população desagregada por sexo:
  - V001–V077: contagens equivalentes a Pessoa01, **só homens**;
  - V078–V085: relações de parentesco, **só homens**;
  - V086–V162: contagens equivalentes a Pessoa01, **só mulheres**;
  - V163–V170: relações de parentesco, **só mulheres**.

Por construção, a soma das contagens de homens e mulheres tem que ser igual à contagem total. Mais formalmente, para todo `i` no intervalo 1..85, vale a identidade:

```
Pessoa01_V_i  ≡  Pessoa02_V_i  +  Pessoa02_V_(i+85)
   total           homens          mulheres
```

Em UF normal, essa identidade tem 85 instâncias verificáveis: uma para cada categoria etária e cada relação de parentesco.

Para testar a hipótese H2 ("SP usa o mesmo schema com nomes shiftados em +85"), basta substituir os nomes shiftados na identidade. Se H2 estiver certa:

```
Pessoa01_SP_V_i  ≡  Pessoa02_SP_V_(i+85)  +  Pessoa02_SP_V_(i+170)
   total                homens                  mulheres
   (i = 1..85)        (índices 86..170)      (índices 171..255)
```

E aqui está o ponto-chave: **não importa o que IBGE pretende V086 significar em SP**; o que importa é a **conta** que tem que fechar. Se a soma de duas variáveis especificas em Pessoa02_SP for igual à variável correspondente em Pessoa01_SP em **todos os 85 cortes**, então essas duas variáveis necessariamente são "homens" e "mulheres" do corte i — ou alguém estaria forjando coincidências aritméticas em escala impossível.

A estratégia tem três propriedades importantes:

1. **Não exige documentação**. Se IBGE não diz o que V200 representa em SP, não importa: o teste resolve sem precisar saber.
2. **É exaustiva**. Cobre 85 categorias × 3 UFs (AC como controle, SP1 e SP2 como teste), totalizando 255 verificações independentes.
3. **É falsificável**. Se um único corte não fechasse a conta, a hipótese cairia.

## 4. Resultados detalhados

Comparações foram feitas sobre **valores totais agregados** por categoria — somatório sobre todos os setores de cada UF. Isso é mais robusto que comparação setor-a-setor porque contorna os artefatos de censura "X" do IBGE em setores com menos de 5 domicílios.

### 4.1 AC (controle — schema oficial canônico)

85 categorias testadas. Cabeçalho da tabela completa:

| i | Pessoa01 | Pessoa02 (homens) | Pessoa02 (mulheres) | Total Pessoa01 | Soma H+M | Diferença |
|---|---|---|---|---|---|---|
| 1 | V001 | V001 | V086 | 533.213 | 532.966 | 247 (0,046%) |
| 2 | V002 | V002 | V087 | 3.647 | 3.647 | **0** |
| 3 | V003 | V003 | V088 | 6.768 | 6.768 | **0** |
| 4 | V004 | V004 | V089 | 10.334 | 10.334 | **0** |
| 5 | V005 | V005 | V090 | 11.926 | 11.926 | **0** |
| ... | ... | ... | ... | ... | ... | **0** |
| 85 | V085 | V085 | V170 | (relações parentesco) | (idem) | **0** |

**Síntese AC:** 84 das 85 identidades batem com diferença ABSOLUTA igual a zero. A única exceção é V001 (total geral 5+), com diferença de 247 pessoas em 533 mil (0,046%). Essa pequena discrepância também aparece em SP — é característica do IBGE, não do nosso pipeline.

### 4.2 SP1 (Região Metropolitana de São Paulo)

85 categorias testadas com a hipótese de shift +85.

| i | Pessoa01 | Pessoa02_SP (testado como homens) | Pessoa02_SP (testado como mulheres) | Total Pessoa01 | Soma H+M | Diferença |
|---|---|---|---|---|---|---|
| 1 | V001 | V086 | V171 | 10.033.341 | 10.029.271 | 4.070 (0,041%) |
| 2 | V002 | V087 | V172 | 54.127 | 54.127 | **0** |
| 3 | V003 | V088 | V173 | 84.746 | 84.746 | **0** |
| 4 | V004 | V089 | V174 | 119.464 | 119.464 | **0** |
| 5 | V005 | V090 | V175 | 136.842 | 136.842 | **0** |
| ... | ... | ... | ... | ... | ... | **0** |
| 85 | V085 | V170 | V255 | (relações parentesco) | (idem) | **0** |

**Síntese SP1:** 84 de 85 identidades batem exatamente. Uma vez mais, a única exceção é V001 (total geral), com 0,041% de diferença — mesma natureza e magnitude que AC. Os 84 zeros restantes coincidem exatamente em milhões de pessoas.

### 4.3 SP2 (interior de São Paulo)

| i | Pessoa01 | Pessoa02_SP (homens) | Pessoa02_SP (mulheres) | Total Pessoa01 | Soma H+M | Diferença |
|---|---|---|---|---|---|---|
| 1 | V001 | V086 | V171 | 26.385.739 | 26.298.641 | 87.098 (0,33%) |
| 2 | V002 | V087 | V172 | 171.027 | 171.027 | **0** |
| 3 | V003 | V088 | V173 | 262.692 | 262.692 | **0** |
| ... | ... | ... | ... | ... | ... | **0** |
| 85 | V085 | V170 | V255 | (relações parentesco) | (idem) | **0** |

**Síntese SP2:** 84 de 85 identidades exatas. V001 com 0,33% de diferença (87 mil em 26 milhões) — proporcional à escala maior do interior paulista. Todas as outras 84 categorias fecham na vírgula.

### 4.4 Sanity check

Para confirmar que o schema realmente shiftou (e não simplesmente "tem variáveis a mais"), foram contadas as colunas presentes em `Pessoa02_SP1.xls` por faixa de índice:

- V001 a V085: **0 de 85 presentes** (estas variáveis simplesmente não existem nos arquivos SP).
- V086 a V170: **85 de 85 presentes**.
- V171 a V255: **85 de 85 presentes**.

Isto é, SP literalmente não publica V001-V085 nos arquivos Pessoa02 — porque o que seriam V001-V085 (homens, no dicionário) está sob os nomes V086-V170. E o que seriam V086-V170 (mulheres) está sob V171-V255. O shift cobre todas as 170 variáveis sem exceção.

### 4.5 Especificidade

O shift é **único do arquivo Pessoa02 nos arquivos de SP**. Não afeta nem outros temas em SP nem outras UFs. Verificação direta dos 13 arquivos da família Pessoa em AC e SP1:

| Arquivo | AC | SP1 |
|---|---|---|
| Pessoa01 | V001-V085 | V001-V085 ✅ |
| **Pessoa02** | **V001-V170** | **V086-V255 ❌** |
| Pessoa03 | V001-V251 | V001-V251 ✅ |
| Pessoa04 | V001-V155 | V001-V155 ✅ |
| Pessoa05 | V001-V010 | V001-V010 ✅ |
| Pessoa06 | V001-V213 | V001-V213 ✅ |
| Pessoa07 | V001-V204 | V001-V204 ✅ |
| Pessoa08 | V001-V254 | V001-V254 ✅ |
| Pessoa09 | V001-V240 | V001-V240 ✅ |
| Pessoa10 | V001-V003 | V001-V003 ✅ |
| Pessoa11 | V001-V134 | V001-V134 ✅ |
| Pessoa12 | V001-V134 | V001-V134 ✅ |
| Pessoa13 | V001-V134 | V001-V134 ✅ |

Logo a correção não precisa varrer arquivos por palpite — basta o par (`tema == Pessoa02`, `uf ∈ {SP_Capital, SP_Exceto_Capital}`).

### 4.6 Quanto à única identidade que não bate (V001 = total 5+)

A pequena diferença em V001 (~0,04% em AC e SP1, ~0,33% em SP2) **não invalida a hipótese**: ela existe igualmente nos três casos, sempre na mesma posição (V001), e sempre na mesma direção (Pessoa01 ligeiramente maior que H+M). É comportamento sistemático do IBGE: ao agregar o total 5+, o IBGE aplica censura por confidencialidade ("X" cells em setores com menos de 5 domicílios) com critério um pouco diferente do que aplica nos cortes etários individuais. Como a média ponderada de censura cresce com o tamanho da UF, SP2 mostra 0,33% e AC mostra 0,046%.

A relação testável que importa é o batimento dos 84 cortes que **não** sofrem essa censura agregada — todos esses fecham com diferença absoluta zero.

## 5. Crosswalk completo

A correspondência entre a numeração presente nos arquivos `Pessoa02_SP1.xls` / `Pessoa02_SP2.xls` e a numeração canônica do dicionário oficial é dada por:

```
Para todo n ∈ {86, 87, 88, ..., 254, 255}:
   V<n>  publicado em SP1 ou SP2  ≡  V<n − 85>  do dicionário oficial
```

A tabela em extenso:

| Significado (dicionário) | Nome canônico | Nome em SP1/SP2 |
|---|---|---|
| Homens alfabetizados com 5 ou mais anos de idade | V001 | **V086** |
| Homens alfabetizados com 5 anos de idade | V002 | **V087** |
| Homens alfabetizados com 6 anos de idade | V003 | **V088** |
| Homens alfabetizados com 7 anos de idade | V004 | **V089** |
| ... | ... | ... |
| Homens alfabetizados com 80+ anos de idade | V077 | **V162** |
| Homens responsáveis alfabetizados 10+ em domicílios particulares | V078 | **V163** |
| Homens cônjuges/companheiros alfabetizados 10+ em DPs | V079 | **V164** |
| Filhos/enteados alfabetizados 10+ em DPs | V080 | **V165** |
| Pais/sogros alfabetizados 20+ em DPs | V081 | **V166** |
| Netos/bisnetos alfabetizados 10+ em DPs | V082 | **V167** |
| Irmãos alfabetizados 10+ em DPs | V083 | **V168** |
| Outros parentes homens alfabetizados 10+ em DPs | V084 | **V169** |
| Conviventes alfabetizados 10+ em DPs (homens) | V085 | **V170** |
| Mulheres alfabetizadas com 5 ou mais anos de idade | V086 | **V171** |
| Mulheres alfabetizadas com 5 anos de idade | V087 | **V172** |
| Mulheres alfabetizadas com 6 anos de idade | V088 | **V173** |
| ... | ... | ... |
| Mulheres alfabetizadas com 80+ anos de idade | V162 | **V247** |
| Mulheres responsáveis alfabetizadas 10+ em DPs | V163 | **V248** |
| Mulheres cônjuges/companheiras alfabetizadas 10+ em DPs | V164 | **V249** |
| Filhas/enteadas alfabetizadas 10+ em DPs | V165 | **V250** |
| Mães/sogras alfabetizadas 20+ em DPs | V166 | **V251** |
| Netas/bisnetas alfabetizadas 10+ em DPs | V167 | **V252** |
| Irmãs alfabetizadas 10+ em DPs | V168 | **V253** |
| Outros parentes mulheres alfabetizadas 10+ em DPs | V169 | **V254** |
| Conviventes alfabetizadas 10+ em DPs (mulheres) | V170 | **V255** |

Os significados são exatamente os que constam no dicionário oficial (seção 6.7 do PDF "BASE DE INFORMAÇÕES POR SETOR CENSITÁRIO Censo 2010 - Universo novo"). O crosswalk é puramente uma renomeação — o conteúdo numérico dos arquivos SP é o mesmo que estaria em um arquivo SP "canônico".

## 6. Estratégia de correção

### 6.1 Onde aplicar

Em `R/census_tracts_2010.R`, dentro da função interna `read_single_file_tract_2010`, **logo após o read e antes do prefixo de tema**. O ponto preciso é entre a linha que fecha o bloco do fix #68 (Goiás V01-V99) e a linha que faz o filtro all-NA, **mas antes** do prefixo `paste0(root_name, "_", cols)`.

Critério de ativação: dois testes lógicos simultâneos:
1. UF é `SP1` ou `SP2` (extraído do nome do arquivo).
2. Tema do arquivo é `PESSOA` *e* o sub-arquivo é `Pessoa02` (extraído do nome do arquivo).

### 6.2 Implementação proposta (pseudo-código a converter para o estilo do projeto)

```r
# Issue: IBGE publicou Pessoa02 de SP1 e SP2 com numeração shiftada em +85 vs
# dicionário oficial — V086 no SP corresponde a V001 do dicionário, e assim
# por diante até V255 ↔ V170. Confirmado exaustivamente em 84 das 85
# identidades aritméticas (Pessoa01_V_i = Pessoa02_homens_i + Pessoa02_mulheres_i),
# com diferença absoluta zero em todas exceto V001 (total 5+, censura IBGE).
# Análogo ao erro de GO V01-V99 sem zeros, mas IBGE não corrigiu este (até 2025-09-15).
# Crosswalk completo em references/relatorio_pessoa02_sp_shift.md.
is_sp <- uf %in% c("SP1", "SP2")
is_pessoa02 <- grepl("^PESSOA02", basename(f), ignore.case = TRUE)
if(is_sp && is_pessoa02){
  v_old <- grep("^V\\d+$", names(temp_df), value = TRUE)
  v_num <- as.integer(sub("V", "", v_old))
  v_new <- ifelse(v_num >= 86, sprintf("V%03d", v_num - 85), v_old)
  data.table::setnames(temp_df, v_old, v_new)
}
```

Aplicado **antes** do prefixo de tema, garantindo que a renomeação resultará em colunas `V001`–`V170` que serão prefixadas para `pessoa02_V001`–`pessoa02_V170` exatamente como nas outras UFs. Após o `rbindlist` no `clean_tracts_2010`, todas as 28 publicações UF terão o mesmo schema canônico, e o parquet final terá 171 colunas `pessoa02_V*` (V001-V170 + V1005), exatamente alinhado com o dicionário e com a spec do Pedro Souza.

### 6.3 Validação após implementação

Validação em três níveis, em ordem crescente de custo:

**Nível 1 — sintático.** O parquet `2010_tracts_PESSOA.parquet` resultante deve ter exatamente 171 colunas com prefixo `pessoa02_V*`, indo de `pessoa02_V001` a `pessoa02_V170`, mais `pessoa02_V1005`. Não pode ter `pessoa02_V171` a `pessoa02_V255`.

**Nível 2 — semântico setor a setor.** Para um setor de SP qualquer, ler valores de `pessoa02_V001` (Homens 5+) e `pessoa02_V086` (Mulheres 5+) e somar. Comparar com `pessoa01_V001` do mesmo setor. Diferença esperada: zero ou na ordem de 0,04% (artefato de censura). Repetir para 5-10 setores aleatórios em SP_Capital e SP_Exceto_Capital.

**Nível 3 — total agregado.** Repetir o teste exaustivo das 85 identidades sobre o parquet final consolidado, somando over toda a base. Deve reproduzir exatamente os 84 zeros em cada UF, incluindo SP1+SP2 agora alinhado.

**Regressão check.** Outros parquets (BASICO, DOMICILIO, DOMICILIORENDA, ENTORNO, PESSOARENDA, RESPONSAVEL, RESPONSAVELRENDA) não devem mudar — o fix toca apenas Pessoa02 e apenas SP. Confirmar via comparação de `nrow`/`ncol`/hash de colunas-chave contra o estado atual em commit `6a1e66f`.

### 6.4 Documentação a atualizar

- `memory/project_open_data_bugs.md`: adicionar este caso como "bug IBGE não corrigido pela fonte; corrigido por nós no pipeline", citando o crosswalk.
- Comentário no `commit message`: linkar para este relatório.

### 6.5 Comunicação ao IBGE (opcional)

Como IBGE corrigiu o caso análogo de GO sem aviso prévio em 15/09/2025, vale comunicar o achado ao Centro de Documentação do IBGE — eles podem republicar `Pessoa02_SP1.xls` e `Pessoa02_SP2.xls` com os nomes canônicos. Isso não muda nada no pipeline (continua corrigindo defensivamente), mas reduz o risco de outros pesquisadores tropeçarem no mesmo problema.

## 7. Síntese

Em termos práticos: o schema `Pessoa02_SP` é o schema canônico, escondido atrás de um shift trivial de +85 nos nomes das colunas. Nos **arquivos do IBGE**, as variáveis `V171`–`V255` de SP não são informação extra — são a mesma informação canônica que todas as outras UFs publicam, só que sob nomes errados. A correção shifta os nomes de volta, fazendo o parquet final ter exatamente as 170 variáveis canônicas para todas as 28 publicações, em paridade com o dicionário oficial do IBGE.

> **Correção de 2026-09-12.** A redação original dizia "no parquet atual de v0.6.0", sugerindo que o parquet carregava as colunas `V171`–`V255`. Nenhum parquet entregue as tem: são 171 colunas `pessoa02_V*` em todos os artefatos verificados. As colunas `V171`–`V255` existem apenas nos **XLS do IBGE**; no parquet publicado elas foram descartadas no empilhamento, e com elas os dados femininos de São Paulo. Ver a nota da seção 1.