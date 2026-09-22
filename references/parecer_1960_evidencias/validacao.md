> Caderno de evidência da [versão narrativa do parecer](../microdata_1960_amostra_127_revisao_integrativa.md), de 22/09/2026. Caminhos citados sem link partem da raiz do projeto; números de linha identificam as fontes, não pessoas pelo nome. As propostas não foram aplicadas.

# Casos de validação: registros, regras e resultados verificáveis

Extração somente leitura em 22/09/2026. Não houve execução de R, alteração de produção ou recalibração. Os resultados propostos abaixo são **retabulações com os pesos gravados**, não pesos novos nem homologação dos dados. Números de linha de CSV contam o cabeçalho como linha 1; o campo `linha` do parquet identifica a linha original da respectiva fonte, não a posição física no parquet.

## Como ler os códigos presentes nos exemplos

`V202` reúne sexo e condição de presença: 1 = homem morador presente; 2 = mulher moradora presente; 3/4 = homem/mulher morador(a) ausente; 5/6 = homem/mulher não morador(a) presente. Assim, os presentes são os códigos 1, 2, 5 e 6; residentes são 1, 2, 3 e 4. Fonte transcrita: `read_guides/1960_codigo_do_censo.csv:2–7`, quesito B, página impressa 2 do Código do Censo.

`V204` informa a unidade ou declaração da idade: 0 = meses; 1 = anos; 5 = mais de 99 anos; 9 = idade ignorada declarada pelo código completo 999, isto é, V204=9/V204B=99. Não se deve equiparar esse código a um campo perdido. Fonte: mesmo CSV, linhas 18–21, quesito D, página impressa 2.

`V211` reúne alfabetização e frequência escolar: 0 = sabe ler e frequenta escola; 1 = sabe ler e não frequenta; 2 = não sabe ler e frequenta; 3 = não sabe ler e não frequenta; 4 = informação ignorada. X é o salto para menores de cinco anos. Fonte: mesmo CSV, linhas 158–163, quesito L, página impressa 6. Os leitores da comparação são V211 em {0,1}.

## Caso 1 — Rondônia: o rural some, embora o total estadual feche

O universo comparado é o de pessoas presentes, por situação do domicílio, da tabela 34 dos resultados definitivos. O arquivo de 1,27% contém 675 pessoas de Rondônia: V118=1 em 673 e V118=3 em duas. Ambos são urbanos para essa tabulação; V118=3 significa suburbano. Não há V118=5, o rural.

Entre os presentes conhecidos restam 666 registros: 305 homens e 361 mulheres. Seus pesos finais somam, respectivamente, 39.038 e 31.194, total 70.232. Os pesos fecham o total estadual, mas concentram todo esse total nas pessoas urbanas observadas.

### Trilha de evidência

No gabarito `references/censo_1960_resultados_definitivos_serie_nacional.csv`, tabela 34, página impressa 85 da Série Nacional:

| Linha do CSV | Situação/sexo | Publicado |
|---:|---|---:|
| 1142 | rural, homens | 23.324 |
| 1143 | rural, mulheres | 16.282 |
| 1144 | rural, total | 39.606 |
| 1147 | total estadual | 70.232 |
| 1148 | urbana, homens | 15.714 |
| 1149 | urbana, mulheres | 14.912 |
| 1150 | urbana, total | 30.626 |

No CSV materializado do compilado, `data_raw/microdata/1960/compilada/validacao_definitivos.csv`, as linhas 803–804 são:

```csv
0,34,urbana,homens,39038,"1,27%",15714,23324,148.428
0,34,urbana,mulheres,31194,"1,27%",14912,16282,109.187
```

Não existem linhas rurais para Rondônia nesse CSV. A ausência foi verificada pelas chaves, não inferida de uma amostra visual de linhas.

### Por que a regra parecia funcionar e onde falha

Somar os registros existentes por situação é uma primeira etapa plausível. O problema aparece ao juntar essa agregação ao gabarito preservando somente o lado medido: uma categoria sem registros não cria grupo e não sobrevive até a comparação. Esse é o percurso de `R/microdata_1960.R:392–393,411`; o validador de 25% repete a direção do join em `R/microdata_1960_amostra_25.R:779`.

O total estadual fecha, e o relatório mostra excesso urbano. Porém não mostra a outra metade da evidência: nenhum registro representa os 39.606 presentes rurais publicados. Não é necessário encontrar uma linha rural errada; o defeito é a linha de comparação que falta.

### Proposta e resultado esperado, com pesos inalterados

Preservar a grade oficial e completar a célula reconstruível sem contribuições com n=0 e soma observada=0. O resultado esperado é:

| Célula | n amostral | Soma observada | Publicado | Diferença absoluta | Diferença percentual |
|---|---:|---:|---:|---:|---:|
| rural, homens | 0 | 0 | 23.324 | −23.324 | −100% |
| rural, mulheres | 0 | 0 | 16.282 | −16.282 | −100% |
| rural, total | 0 | 0 | 39.606 | −39.606 | −100% |

Esse resultado já pode ser visto na auditoria Python separada `data_raw/microdata/1960/amostra_127/auditoria_validacao_20260921/definitivos_grade_completa.csv`: linhas 1850, 1852 e 1854 para `censobr_weight`. Não é saída da implementação R reformulada, que não foi executada. O helper proposto está em `R/microdata_1960_amostra_127.R:1135–1148`.

Zero observado informa falta de suporte rural. Não prova população rural zero e não autoriza aumentar pesos urbanos para fabricar essa representação. O ganho aqui é tornar a limitação visível.

## Caso 2 — Leitores com idade ignorada: calibração e teste compartilham a exclusão

A tabela 40 compara alfabetização entre presentes de cinco anos e mais. A Série Nacional, página impressa XIII, determina que idades declaradas ignoradas integram os totais quando a informação tem limite mínimo de idade. Essa convenção histórica foi conferida visualmente nas rodadas anteriores. Ela não exige imputar uma idade biológica: exige incluir V204=9 no universo da comparação publicada.

### Uma pessoa real que a regra deixa de fora

Em `data_raw/microdata/1960/amostra_25/sp/pessoas_pesos.parquet`, o campo `linha=1434472` contém:

| Campo | Valor | Leitura em português |
|---|---:|---|
| V202 | 2 | Mulher moradora presente |
| V204 / V204B | 9 / 99 | Idade declarada ignorada |
| V211 | 1 | Sabe ler e não frequenta escola |
| censobr_weight | 3,9826059092885377 | Peso final gravado |

Ela satisfaz presença e alfabetização. O descarte decorre somente de transformar a idade declarada ignorada em NA e exigir uma idade numérica conhecida de pelo menos cinco anos.

### Onde a exclusão entra e por que passa no teste

No calibrador de 25%, `R/microdata_1960_amostra_25.R:568–574` transforma V204=9 em idade NA. A margem de leitores em :621–622 exige `!is.na(idade) & idade >= 5`. A regra é plausível para uma pergunta estritamente biológica sobre idade conhecida; não corresponde à convenção da publicação usada como controle.

O validador de 25% reproduz o mesmo filtro em :743–745 e :767–768. O compilado o reproduz em `R/microdata_1960.R:374–376,395–396`. Por isso o ajuste e o teste concordam sobre a exclusão e podem fechar exatamente o alvo errado para aquele universo.

As 34 células estaduais de leitores do CSV de validação de 25%, com peso final, têm diferença arredondada zero. Ainda assim, ficaram fora **9.395 leitores presentes com idade declarada ignorada**, soma de pesos **36.562,002299**. Essa contagem foi extraída dos 17 parquets de fonte e conferida no compilado; ver `tmp/integrativa127/validacao_interfaces_results.json`, blocos `calibrated_literacy_cells_25` e `source25_ignored_age`.

### São Paulo: antes e depois da retabulação, sem ajustar pesos

O gabarito definitivo traz leitores homens e mulheres de SP nas linhas 2078–2079: 4.089.706 e 3.557.693. Em `data_raw/microdata/1960/amostra_25/validacao_definitivos.csv:777–778` consta:

```csv
60,40,sabem,homens,4089706,censobr_weight,4089706,0,0
60,40,sabem,mulheres,3557693,censobr_weight,3557693,0,0
```

O compilado repete esses valores nas linhas 1304–1305 de seu `validacao_definitivos.csv`.

Recontagem seletiva do parquet fonte, mantendo os pesos gravados:

| Sexo | Leitores de idade conhecida: soma atual | Leitores ignorados omitidos: n | Peso omitido | Soma incluindo os declarados ignorados |
|---|---:|---:|---:|---:|
| Homens | 4.089.706,000000014 | 2.080 | 8.153,188102289 | 4.097.859,188102303 |
| Mulheres | 3.557.693,000000039 | 2.092 | 8.218,110569485 | 3.565.911,110569523 |

SP soma 4.172 leitores omitidos, peso 16.371,298672. A comparação corrigida **deixa de fechar**: aparecem os excessos de 8.153,19 e 8.218,11 contra o publicado. Isso é o resultado esperado de corrigir a medição mantendo pesos anteriormente ajustados a outro recorte. Não é indicação para esconder os novos resíduos. Uma futura recalibração coerente dependerá da implementação e dos testes autorizados; não foi executada nem prevista numericamente aqui.

### As três políticas não são iguais

| Componente | Tratamento atual de V204=9 na margem/comparação de leitores |
|---|---|
| Calibrador 127 | Inclui os declarados ignorados; a inclusão é compatível com a fonte. Usa idade auxiliar 999 em :886–887 e :908. Essa implementação também equipara outros desconhecimentos a 999, questão separada que não está aprovada. |
| Validador definitivo 127 reformulado | Exclui V204=9 em :1308–1310 e :1335–1336. É a regressão semântica identificada na primeira reformulação. |
| Calibrador e validador 25%; validador compilado | Excluem V204=9 pelos trechos citados acima; o validador confirma a mesma exclusão presente no ajuste. |

Os impactos não são intercambiáveis: na amostra 127 integral há 520 leitores presentes com idade declarada ignorada; no compilado a contribuição dessa metade é de 49, e os outros 9.395 vêm de 25%. No conjunto compilado são 9.444 leitores, peso 40.856,717108. A proposta é incluir os **declarados** ignorados conforme a fonte, mantendo idade danificada em diagnóstico próprio.

### Outro exemplo didático — números inventados, não registros do censo

Este exemplo de doze leitores ilustra o mesmo mecanismo da figura de cinco leitores no texto principal; são duas miniaturas diferentes, não dois resultados observados nem duas versões do dado real.

Imagine dez domicílios, cada qual com um leitor de idade conhecida. Dois desses domicílios têm, ainda, um leitor cuja idade foi declarada ignorada. São doze leitores distribuídos em dez domicílios. Suponha um alvo publicado de 120 leitores, incluindo os dois de idade ignorada.

Se o ajuste conta somente os dez leitores de idade conhecida e dá peso 12 a cada domicílio, obtém 10 × 12 = 120. O teste que repete esse filtro também obtém 120 e declara fechamento. Os outros dois leitores recebem o peso dos seus domicílios, mas não entram no teste.

Mantendo esses pesos e contando o universo correto, o resultado é 12 × 12 = 144, excesso de 24. O fechamento anterior era compartilhamento de uma exclusão, não validação independente do universo. Este exemplo simplifica deliberadamente as demais margens e a distribuição de pesos da aplicação real.

## Caso 3 — Água: o código de ignorado sai; o salto estrutural entra

No quadro 7 preliminar, a linha de comparação é `agua_outra_sem_declaracao`. O manual distingue V105=3, outra forma de abastecimento, de V105=4, ignorado. A regra implementada em `R/microdata_1960_amostra_127.R:1246` seleciona `V105 %in% 3 | is.na(V105)`: deixa o ignorado codificado fora e inclui todos os NA.

### Dois domicílios reais, ambos no Leste

Em `data_raw/microdata/1960/amostra_127/domicilios_1960_amostra_127.parquet`:

| Linha original / domicílio | UF | V101 | V102 | V105 | Peso final | Efeito atual na linha de água |
|---|---|---:|---:|---:|---:|---|
| 303650 / 47403 | Bahia, UF31 | 1 | 4 | 4 | 73,27234762515546 | Excluído, embora a resposta seja ignorado codificado |
| 284026 / 44240 | Sergipe, UF30 | 1 | 6 | NA | 69,72438449881565 | Incluído como outra/sem declaração, embora o quesito não seja codificado para esse tipo |

V101=1 significa família única em domicílio particular. V102=4 é durável; V102=6 é improvisado. O Código manda não codificar os quesitos seguintes nos improvisados: `read_guides/1960_codigo_do_censo.csv:681`, quesito C domiciliar, página impressa 23. Os rótulos de V102 estão nas linhas 677–680. V105=3/4 está nas linhas 700–701, página impressa 24. Portanto, o branco do segundo exemplo é um salto estrutural, não a resposta V105=4.

O efeito da troca, nesses dois registros, é claro: o primeiro deve passar a contribuir 73,2723476; o segundo deve deixar de contribuir 69,7243845 nessa categoria de água. Nenhum valor original precisa ser alterado para retabular a comparação corretamente.

### Alcance real e uma célula publicada

Na amostra 127 integral, entre os particulares selecionados pela regra V101, há **101 domicílios V105=4**, peso **8.129,032178**, hoje omitidos dessa categoria. Dos 53 NA atualmente incluídos, 49 são improvisados, uma é família secundária sem bloco domiciliar codificado e três são duráveis com resposta ausente. Estes três últimos exigem diagnóstico de classificação perdida, não conversão automática em ignorado declarado.

O alvo do Leste para domicílios com outra forma/sem declaração de água é 2.396.086: `references/censo_1960_resultados_preliminares_1965.csv:2255`. O auditor Python anterior gravou, em `data_raw/microdata/1960/amostra_127/auditoria_validacao_20260921/preliminares_grade_completa.csv:3398`, 31.295 contribuições, soma 2.434.799,910644134 e diferença +1,62% com o peso final.

Mantendo exatamente a seleção domiciliar V101 atual e os pesos, mas contando somente respostas explícitas V105 em {3,4} e separando todos os NA no diagnóstico, a célula fica com 31.302 contribuições e soma **2.435.495,556415465**. São 21 respostas ignoradas codificadas que entram, peso 1.794,425541411, e 14 NA que saem, peso 1.098,779770080. A diferença absoluta contra o publicado passa a +39.409,556415465, aproximadamente +1,64%.

Essa é uma demonstração localizada da classificação, **não** uma homologação de todos os recortes domiciliares, vínculos ou pesos. O erro não precisa diminuir para a classificação melhorar. Ainda é necessário manter separados salto estrutural, resposta ignorada codificada e dado perdido, além de resolver o restante do universo domiciliar documentado nos pareceres.

## Rastreabilidade e limites

As contagens de interfaces e de idade ignorada vêm de `tmp/integrativa127/validacao_interfaces.py` e suas saídas, conferidas também por `tmp/integrativa127/rechecagem_principal.py`. Nesta tarefa foram refeitas leituras seletivas para Rondônia, leitores de São Paulo e V105 dos particulares, incluindo os registros individuais expostos acima. Os CSVs existentes foram lidos com seus números de linha; nenhuma saída de produção foi sobrescrita.

As linhas de código citadas descrevem a implementação disponível nesta data. As propostas não foram aplicadas ao R. Não se confundem: (a) saída materializada antiga; (b) auditoria Python isolada; (c) cálculo contrafactual apenas de classificação/universo com pesos fixos; e (d) futura reconstrução e recalibração, ainda não realizadas.
