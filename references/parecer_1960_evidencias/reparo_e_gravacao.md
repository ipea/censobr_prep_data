> Caderno de evidência da [versão narrativa do parecer](../microdata_1960_amostra_127_revisao_integrativa.md), de 22/09/2026. Caminhos citados sem link partem da raiz do projeto; números de linha identificam as fontes, não pessoas pelo nome. As propostas não foram aplicadas.

# Dois casos para a explicação narrativa

Conferência pontual de 22/09/2026. Somente leitura com Python/PyArrow; nenhum R/Rscript, pipeline, guia ou parquet foi alterado. Esta nota complementa o parecer, não aprova os dados.

## 1. RS, linha 951431: o conserto mudou respostas legíveis

O caso é uma menina de 12 anos, codificada como outro parente, na pasta **81076**, boletim **016**. O registro correspondente preservado na amostra de 25% é a linha **252042**, ordem **03**. A conclusão não depende de considerar a escolaridade plausível ou implausível: o trecho legível do próprio HHOLDA e a outra cópia preservada concordam, enquanto o texto reparado diverge.

O HHOLDA traz esta linha de 62 caracteres, idêntica a `texto_original` em `read_guides/1960_amostra_127_correcoes.csv:99`:

```text
34-       \818262018107 601 63 1221 12552492000062000000155539
```

Depois de separar o fragmento posterior à barra e retirar seus espaços, os primeiros 38 caracteres são:

```text
81826201810760163122112552492000062000
```

O reparo registrado no CSV, de fato aplicado no parquet, é:

```text
81826201810760163122112552492000006200                \0155539
```

Para enxergar a alteração, separamos o prefixo comum de 33 posições dos quatro quesitos seguintes. Os colchetes **marcam o zero excedente**, não fazem parte do arquivo:

```text
                                              V212 V213 V214 V215
Posições no layout de 1,27%:                    34   35  36–37  38

Fragmento preservado: 818262018107601631221125524920000 | 6 | 2 | 00 | 0
Reparo atual:        818262018107601631221125524920000 |[0]| 6 | 20 | 0
```

Os quatro zeros imediatamente anteriores são idênticos; a marcação identifica o excesso na fronteira do campo, não uma posição de digitação manual demonstrável. O fato verificável é que o `6` que ocupava V212 foi deslocado para V213, e o `2` passou a iniciar V214. V215 continuou 0 por coincidência entre os zeros vizinhos.

O bruto preservado `data/release_legacy/Censo.1960.amostra.25porcento.rs.gz`, linha 252042, é:

```text
8107601603603622112552499200006200000000035        000
```

Seu layout é diferente: V212 está na posição **31**, V213 na **32**, V214 em **33–34** e V215 na **35**. Lidos pelos guias de cada fonte, os campos pessoais do prefixo até V215 concordam com o fragmento original sem espaços. Não se devem comparar as posições físicas das duas fontes como se seus layouts fossem iguais.

| Campo e posição na amostra127 | Reparo/parquet127 atual | Fragmento preservado e fonte25 | O que mudou de sentido |
|---|---|---|---|
| V212, posição 34 | `0` | `6` | De **3ª série** para **cursa o 1º ano elementar** |
| V213, posição 35 | `6` | `2` | De **elementar** para **ignorado** |
| V214, posições 36–37 | `20` | `00` | De **prejudicado (sem curso completo)** para **ginasial, médio de 1º ciclo** |

Os significados são os da transcrição em `read_guides/1960_codigo_do_censo.csv`: V212=6/0 nas linhas **166/170**; V213=2/6 nas **173/177**; V214=00/20 nas **181/192**. A associação entre campo e posição está em `readguide_1960_amostra_127_pessoas.csv:19–22` e `readguide_1960_amostra_25_pessoas.csv:21–24`. `00` aparece como número **0** no parquet; isso não muda o código de duas posições do arquivo de origem.

### Por que o teste de códigos não percebeu

`0` é permitido em V212, `6` em V213 e `20` em V214. O leitor apenas extrai as posições e testa se cada valor pertence ao conjunto admitido (`R/microdata_1960_amostra_127.R:382–397`). Portanto, ele executou corretamente **um reparo errado**. No parquet127, a linha 951431 contém V212=0, V213=6, V214=20, `censobr_diagnostico="recuperada"` e `censobr_variaveis_anuladas=""`.

Uma lista vazia de variáveis anuladas significa “nenhum campo não vazio foi rejeitado pelo teste de códigos”, não “todas as respostas são verdadeiras”. Os brancos deixados na cauda também não entram nessa lista, pois `ruim` exclui explicitamente os brancos. É a distinção entre **estar no vocabulário permitido** e **ser a resposta daquele registro**.

### Proposta mínima, ainda não aplicada

Revisar somente a decisão desta linha: restaurar as posições **34–37** para `6200`, isto é, V212=6, V213=2 e V214=00; manter V215 e o restante do reparo. Isso restaura o prefixo diretamente preservado e corroborado, sem simplesmente apagar um caractere e deslocar a barra/identificador ou os campos seguintes.

As posições **39–54**, de V216 a V224, estão em branco no reparo e NA no parquet127. Devem continuar assim nesta proposta: a concordância do prefixo não autoriza preencher automaticamente a cauda pelo registro25. A fonte25 possui valores adicionais, mas usá-los exigiria uma decisão separada de reconstrução e proveniência. Também não se resolve o vínculo domiciliar desta pessoa apenas corrigindo sua escolaridade.

A alteração afeta a amostra127. O compilado do RS escolhe a fonte25 (`R/microdata_1960.R`, `UF_1960_AMOSTRA_25` e ramo `do_25` em `compile_1960()`); não se deve apresentar este erro como encontrado no parquet nacional compilado.

Fontes materializadas consultadas: `data_raw/microdata/1960/amostra_127/HHOLDA.txt`, linha 951431; CSV de correções, linha 99; gzip RS, linha 252042; `amostra_127/pessoas_1960_amostra_127.parquet`, filtro `linha=951431`; `amostra_25/rs/pessoas.parquet`, filtro `linha=252042`. A primeira consulta confirmou a igualdade literal HHOLDA–CSV; as consultas parquet confirmaram 0/6/20 versus 6/2/0. Evidência anterior reproduzível: `tmp/integrativa127/integridade_reparos_gzip.py` e `.json` (o script existente grava seu JSON; não foi reexecutado nesta nota).

## 2. “Exportar sem aprovação” não quer dizer “não ter validação”

O projeto calcula comparações e grava relatórios. O problema é que **produzir esse relatório não é uma condição para gravar o arquivo de dados**. Na amostra127, o mesmo objeto calibrado alimenta ramos separados: os validadores (`_targets.R:218–224`) e a gravação (`:231–233`). No compilado, a validação é outro ramo (`:359–362`), enquanto a saída depende apenas dos dados compilados, do nome da tabela e da versão (`:381–386`). Assim, pedir apenas o output não exige executar os validadores. Mesmo quando um validador roda, o compilado calcula as diferenças, escreve o CSV e retorna seu caminho (`R/microdata_1960.R:411–424`): uma diferença grande no CSV é **conteúdo diagnóstico**, não uma exceção que interrompe a gravação. Nos validadores127 também se escrevem CSVs e resumos (`R/microdata_1960_amostra_127.R:1271–1277,1356–1364`), sem um critério geral de aprovação de conteúdo alimentando o output. Isso não significa que nada possa interromper a cadeia: há erros técnicos e bloqueios de integridade. Significa que **“arquivo gravado” não é sinônimo de “comparações examinadas e aprovadas”**. Uma futura aprovação precisaria ter critérios explícitos e ser uma dependência efetiva da liberação; não bastaria gerar mais um CSV.

## 3. Leitura segura de FALSE e NA nas flags

Também não se deve traduzir toda flag FALSE/0 por “consistência comprovada”. Nas três flags pessoais de coerência, o código depende de sexo/idade do chefe, idade pessoal ou ano de casamento (`R/microdata_1960_amostra_127.R:724–734`); depois converte qualquer NA restante em FALSE (`:736`). Um filho sem idade comparável pode terminar sem sinalização porque o teste não dispõe dos dados necessários. Para a saída atual, a interpretação segura é **“esta regra não sinalizou o registro”**. Separar “testado e não sinalizado”, “não aplicável” e “não avaliável por falta de dado” seria uma melhoria de metadados a decidir; não foi implementada nesta nota. O mesmo cuidado vale para `variaveis_anuladas=""`: ausência de sinalização não é certificado de exatidão.
