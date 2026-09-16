# Censo de 1960, amostra de 25% — a preparação passo a passo

Este documento descreve como os dezessete arquivos brutos da amostra de 25% do Censo Demográfico de 1960 viram duas tabelas utilizáveis. Ele é o irmão de [`microdata_1960_amostra_127_preparacao.md`](microdata_1960_amostra_127_preparacao.md), que faz o mesmo para a outra amostra de 1960, e pressupõe pouco: onde precisar de vocabulário da época, o guia do desenho amostral da amostra de 1,27% tem um glossário.

O código está em [`R/microdata_1960_amostra_25.R`](../R/microdata_1960_amostra_25.R) e no bloco `# 01b.` do [`_targets.R`](../_targets.R).

---

## 1. De onde vêm os dados

O Censo de 1960 teve **duas amostras**, e é preciso não confundi-las.

A **amostra de 25%** é a amostra geral do censo: um domicílio em cada quatro foi recenseado no Boletim de Amostra, o formulário CD 2, que trazia os quesitos que o Boletim Geral não fazia — rendimento, migração, fecundidade, curso completo. É dela que saíram os volumes definitivos do censo.

A **amostra de 1,27%** é uma subamostra dela, sorteada em 1965: uma pasta em vinte do cadastro de arquivamento, para apurar depressa alguns resultados preliminares enquanto a apuração completa não saía.

Os microdados da amostra de 25% sobreviveram para **dezessete unidades da federação**, que são exatamente aquelas cujos tomos do Volume I foram apurados só pelo Boletim de Amostra. Nas outras onze o censo apurou o Boletim Geral por completo, e de lá só resta a amostra de 1,27%.

As duas vieram no mesmo pacote, entregue por Suzana Cavenaghi: um zip com `1%/HHOLDA.txt` e `25%/` com dezessete arquivos comprimidos, um por unidade da federação, com timestamp de 1998. A proveniência completa está em [`references/fontes_1960/README.md`](fontes_1960/README.md).

Os arquivos que o pipeline consome estão publicados no release `release_legacy` deste repositório, como `Censo.1960.amostra.25porcento.<uf>.gz`. Estão em gzip, e não no compress de 1998 em que chegaram, porque o R não decodifica LZW; a recompressão foi conferida byte a byte contra os originais nas dezessete unidades.

---

## 2. Como o arquivo é

Dezessete arquivos de largura fixa, **54 caracteres por linha**, **18.055.053 linhas** ao todo, 993 MB abertos. Dois tipos de registro no mesmo arquivo, distinguidos pelas posições 9 e 10:

```
970020010050190          9701011000000000000000000   <- familia (posicoes 9-10 = 00)
970020010150151612155089912081721006300007361423516000   <- pessoa (01 a 49)
```

Três diferenças de layout em relação à amostra de 1,27% mudam o código:

1. **Não há campo de unidade da federação.** Ela vem do nome do arquivo. O número da pasta não serve: ele é um bloco de numeração nacional, e os seus dois primeiros dígitos erram a unidade em dois dos dezessete casos — o Paraná começa em 70002 e Fernando de Noronha em 27002.
2. **A chave do questionário é pasta e boletim**, nas posições 1 a 8. O distrito está no corpo do registro de família (34-35), não na chave.
3. **O boletim é a família, não o domicílio.** Um domicílio com mais de uma família tem um boletim por família, com números de boletim diferentes.

Os guias de leitura estão em [`read_guides/readguide_1960_amostra_25_familias.csv`](../read_guides/readguide_1960_amostra_25_familias.csv) e [`_pessoas.csv`](../read_guides/readguide_1960_amostra_25_pessoas.csv), derivados do layout original do CEM e com os valores válidos vindos de [`read_guides/1960_codigo_do_censo.csv`](../read_guides/1960_codigo_do_censo.csv), que é a autoridade.

As colunas mantêm a grafia do layout original: `v001` a `v004` e `v100` em minúscula, `V101` em diante em maiúscula. É feio e é de propósito — é a grafia da fonte, e as variáveis V do questionário casam uma a uma com as da amostra de 1,27%.

---

## 3. Em que estado ele está

Muito melhor que o da amostra de 1,27%, e é justo dizer isso de saída.

Os 993 MB só contêm **dígitos, brancos e quebras de linha**: nenhuma letra, nenhum hífen, nenhuma barra, nenhum caractere de controle. O dano de fita que marca o arquivo de 1,27% — letras e sinais deixados pela leitura magnética — não existe aqui. As 18.055.053 linhas têm exatamente 54 caracteres, sem uma exceção.

O branco é o marcador de salto, e é regular: aparece nas variáveis do domicílio exatamente quando a espécie não as admite, e nas variáveis de instrução e trabalho exatamente quando a idade não as admite. São **140.805.616 brancos significativos**, e depois da leitura eles reaparecem aninhados e exatos — 10.088.132 na ocupação habitual, 4.520.276 em V214–V220, 2.364.121 em V211–V213.

O que há de defeito estrutural em dezoito milhões de registros cabe em **doze decisões**, e é de arquivamento, não de conteúdo. Está na seção 4.

---

## 4. O único defeito: a ordem do arquivo

Nove das dezessete unidades estão na **ordem do cadastro** — pasta, boletim, número da pessoa. Isso mostra qual era a ordem de gravação. Nas outras oito um **bloco de pastas foi gravado à frente do resto**:

| unidade | pastas deslocadas | linhas |
|---|---|---|
| Alagoas | 25082–25600 (16) | 18.433 |
| Bahia | 31322–31500 (90) | 120.032 |
| Goiás | 94072–94500 (214) | 271.214 |
| Pernambuco | 21374–21620 (124) | 153.446 |
| Paraná | 70194–70482 (145) | 192.737 |
| Rio de Janeiro | 52116–52508 (196) | 282.356 |
| Rio Grande do Sul | 81342–81636 (148) | 212.970 |
| São Paulo | 64150–66292 (1.072) | 1.433.310 |

Cada uma tem **um só corte**, com o resto do arquivo crescente e sem interseção com o bloco deslocado. É assinatura de fita remontada, não de dado perdido: nenhum registro se repete, nenhum falta.

Em São Paulo o deslocamento cortou ao meio um boletim: o registro de família do boletim 64150/005 ficou na **última linha do arquivo** e as suas três pessoas nas **três primeiras**. É o único dos 3.071.284 boletins que o deslocamento partiu.

Ordenar por pasta, boletim e número da pessoa resolve os dois casos de uma vez, e **não move nada nos nove arquivos que já estavam certos**. As doze decisões — oito de classe e quatro de linha — estão em [`read_guides/1960_amostra_25_correcoes.csv`](../read_guides/1960_amostra_25_correcoes.csv).

---

## 5. Passo a passo

### Passo 1 — baixar

`download_1960_amostra_25()` busca os dezessete `.gz` no `release_legacy`, com espelho local em `./data/release_legacy/`.

### Passo 2 — examinar, por classe de defeito

`audit_1960_amostra_25()` aplica **treze classes de teste** a cada unidade: caractere fora de `[0-9 ]`; valor fora do dicionário, variável por variável, nos dois layouts; boletim partido, sem família, sem pessoa, com duas famílias; ordem do cadastro; o total de pessoas declarado no registro de família contra o número de registros; boletim individual com mais de uma pessoa; família convivente sem principal; numeração de pessoa fora de sequência; as três redundâncias de perfuração (o número da pessoa repete a ordem, o dígito verificador repete o seu par, o campo rotulado *filler* repete a nacionalidade); mais de um chefe por boletim.

No fim, a **cobertura bidirecional**: toda linha marcada precisa de decisão, e toda decisão precisa apontar para linha marcada. Sem isso o pipeline para.

Resultado: **nove ocorrências em 18.055.053 linhas** — as oito de bloco deslocado e a de São Paulo. Nenhum valor fora do dicionário, em nenhuma variável.

### Passo 3 — aplicar as decisões e o layout

`read_1960_amostra_25()` ordena por pasta, boletim e ordem, confere que as pastas ficaram crescentes e que todo boletim é contíguo, e aplica o layout. Branco onde o dicionário permite branco vira ausente.

Ficam de fora do parse os campos que nunca foram gravados — total de famílias, total de moradores e peso do domicílio, zerados em 100% dos registros — e as três redundâncias de perfuração, que o passo 2 já usou como teste.

Saem **3.071.284 registros de família e 14.983.769 de pessoa**, em 13.411 pastas, com chave (pasta, boletim) única em todas as unidades, nenhum registro de pessoa órfão e **nenhuma coluna anulada**.

### Passo 4 — famílias, domicílios e geografia

`build_1960_amostra_25()`.

**O domicílio.** `V101` diz o que cada boletim é: 1 domicílio particular único, 2 principal de um domicílio com mais de uma família, 3 coletivo, 4 segunda família, 5 terceira, 9 boletim individual. Então 1, 2, 3 e 9 abrem domicílio; 4 e 5 entram no anterior. São **3.066.365 domicílios** para os 3.071.284 boletins — 4.602 com duas famílias e 317 com três.

**O boletim individual.** `V101 = 9` é o morador de domicílio coletivo sorteado pessoa a pessoa pela Lista CD 3, com a página do domicílio em branco por construção e sempre uma pessoa só. São **195.445**, 6,4% dos boletins, e no Distrito Federal são 8.698 dos 14.818 — o acampamento da construção de Brasília. Tratá-los como domicílio infla a contagem em 6,4% e envenena qualquer média por domicílio, e é por isso que `censobr_tipo_unidade` os separa:

| censobr_tipo_unidade | domicílios |
|---|---|
| domicílio particular | 2.854.157 |
| domicílio coletivo | 16.763 |
| boletim individual | 195.445 |

**A página de domicílio das famílias conviventes não é preenchida** a partir da principal. Fica ausente, como no estágio da amostra de 1,27%; a decisão está em discussão no `ipea/censobr#87` e vale para as duas amostras de 1960 e para 1970.

**O município.** `V116` é o código do *Código de Zonas Fisiográficas, Municípios e Distritos de 1960*, com três correções: Alagoas vem deslocada em +200, Fernando de Noronha vem 2701 e o seu único município é 2401, e o **Distrito Federal vem 9701 contra 9700 do livro** — esta última não era necessária na amostra de 1,27%, e sem ela 14.818 domicílios de Brasília ficam sem município. Com as três, o casamento fecha em **100%** dos boletins nas dezessete unidades, em 2.344 municípios.

**O ignorado do questionário.** O *Código do Censo* dá a cada quesito do domicílio um código próprio para a resposta ausente — `V102` = 7, `V103` = 0, `V105` = 4, `V106` = 9, `V107` = 5, `V108` = 7, `V109` = 9, `V110` = 1, `V111` = 3 — e para os dois campos numéricos manda, na p. 25, *"não havendo indicação do número total de cômodos codifique-se 00"* e *"não havendo indicação do número de peças servindo de dormitório codifique-se 000"*. São 23.109 e 24.285 domicílios, concentrados por lote de perfuração, e **ficam com o código do dicionário**. Não há coluna de marca: quem quiser distingui-los consulta o *Código*.

### Passo 5 — o desenho e os dois pesos

`weight_1960_amostra_25()`. Está na seção 6.

### Passos 6, 7 e 8 — validação

`validate_definitivos_1960_amostra_25()`, `sampling_errors_1960_amostra_25()` e `compare_127_1960_amostra_25()`. Estão nas seções 7, 8 e 9.

---

## 6. O desenho e os dois pesos

O desenho desta amostra é **outro**, e mais simples que o da amostra de 1,27%. Lá sorteou-se uma pasta em vinte e a pasta entrou inteira, de modo que a unidade primária era a pasta e o estimador era de conglomerado último. Aqui **não há sorteio de pastas** — todas entram — e o que se sorteia é o domicílio, um em quatro, sistematicamente, pelas "Linhas de Amostra" impressas em intervalos regulares de quatro linhas nas Folhas de Coleta CD 7 e CD 8, dentro de cada setor censitário. Uma etapa só.

- **`censobr_upa`** é o domicílio: todas as suas pessoas entram ou saem juntas. No boletim individual é a própria pessoa, e no coletivo o grupo do boletim, porque foi isso que a Lista CD 3 sorteou.
- **`censobr_estrato`** é **pasta × situação**. A seleção foi sistemática dentro do setor, e o setor é, por definição, "área territorial contínua situada num só quadro (urbano, suburbano ou rural), do mesmo distrito administrativo". Toda pasta está num só município, e cruzá-la com `V118` separa as pastas mistas nas suas partes urbana e rural: é a aproximação mais fina do setor que o arquivo permite. Dão **18.400 estratos**, mediana de 193 domicílios; só cinco têm um domicílio.
- **`censobr_fpc`** é 0,25 em todas as unidades, Fernando de Noronha inclusive, onde o sorteio de um em quatro aconteceu normalmente.

**`censobr_weight`** é razão à contagem completa por **município × situação**, em forma fechada: cada domicílio pertence a exatamente uma célula, o que dispensa o solver de Deville–Särndal que a amostra de 1,27% precisava. A âncora é a **Sinopse Preliminar**, que é a contagem completa e é o que o IBGE declarou ter usado nestas dezessete unidades, refinada do nível de unidade da federação para o de município. O fator vai de 1,18 a 8,02, com mediana 3,95.

O colapso tem dois degraus, e o princípio é que **a âncora municipal não se abandona**. A célula de situação vira município inteiro quando o seu fator sai de [2; 8], quando o universo é menor que 100, e também quando o universo tem uma situação que a amostra não alcançou — é o caso de Cristalândia, em Goiás, cujos 2.345 habitantes urbanos não têm um domicílio urbano sorteado. São 9.958 domicílios colapsados. Nenhum desce para a unidade da federação.

**`censobr_weight_ibge`** reproduz o método do IBGE ao pé da letra para estas unidades: razão a unidade da federação × urbana/rural com **peso inteiro** — 3, 4 ou 5 — sorteado com semente fixa para fechar o total. Fecha exato nas dezessete.

**Serra dos Aimorés** é a única unidade sem contagem completa. Os tomos de Minas (p. 6) e do Espírito Santo (p. 7–8) excluem a região do litígio dos dois estados, com todas as letras, e não publicam tabela própria para ela. A única publicação que a traz é a Série Nacional, e é a ela que a região calibra — âncora que é estimativa publicada, não contagem completa.

**Dezesseis das dezessete unidades reproduzem a contagem completa dígito a dígito.** A exceção é Mato Grosso, 4.630 pessoas abaixo, e a razão é de cobertura, não de método: **Alto Garças**, com 4.630 habitantes publicados, não tem um único domicílio sorteado na amostra, de modo que a sua população não tem a que se prender. Com o peso do IBGE, que é por estado, ela se distribui pelos demais municípios e o total fecha.

---

## 7. Contra a Série Nacional

As cinco tabelas por unidade da federação da Série Nacional, vol. I — condição de presença (32), idade por sexo (33), situação do domicílio (34), cor (37) e alfabetização de 5 anos e mais (40) — reproduzidas com os dois pesos:

| tabela | erro mediano | erro máximo |
|---|---|---|
| 32 condição de presença | 1,22% | 2,04% |
| 33 idade × sexo | 1,23% | 20,0% |
| 34 situação | 1,23% | 2,27% |
| 37 cor | 1,30% | 8,33% |
| 40 alfabetização | 1,12% | 3,11% |

O erro mediano de cerca de 1,2% é **sistemático e esperado**: é a distância entre a Sinopse Preliminar, que é a âncora da calibração, e os resultados definitivos que a Série Nacional publica — a mesma distância de 0,56% a 2% por unidade que o arquivo municipal já mostrava. Os erros máximos estão todos em Fernando de Noronha e na Serra dos Aimorés, em células de quatro ou cinco pessoas: é arredondamento, não método.

Há uma circularidade a declarar: para estas dezessete unidades as tabelas da Série Nacional **foram apuradas com esta mesma amostra**, com o método que `censobr_weight_ibge` reproduz. Então a comparação com `censobr_weight_ibge` mede o quanto a nossa leitura difere da do IBGE, e a comparação com `censobr_weight` mede quanto o refinamento municipal desloca as margens. As duas dão o mesmo resultado, o que é a notícia boa.

**O teste corrigiu um erro nosso.** A tabela 37 publica cinco categorias de cor, e "sem declaração" é apenas o ignorado (`V206` = 9): em Mato Grosso o publicado dá 139 e o nosso código 9 dá 138. O código 8, *índia*, tinha sido posto ali e pertence a *pardos*, que é onde o censo de 1960 o classificava. Antes da correção aquela célula errava 4.521%; depois, o erro máximo da tabela inteira cai para 8,3%.

Tudo em `data_raw/microdata/1960/amostra_25/validacao_definitivos.csv`, uma linha por célula e por peso.

---

## 8. Quanto se pode confiar numa estimativa

A variância de um total é a dispersão dos totais expandidos entre os domicílios do estrato, com a correção de população finita de 1/4:

$$V(\hat Y) = \sum_h (1 - f)\,\frac{n_h}{n_h - 1}\sum_{i \in h}\left(w_i y_i - \bar t_h\right)^2, \qquad f = \tfrac14$$

É o que `survey::svydesign(ids = ~censobr_upa, strata = ~censobr_estrato, weights = ~censobr_weight, fpc = ~censobr_fpc)` daria, escrito à mão para não acrescentar dependência ao pipeline.

| domínio | estimativa | erro-padrão | CV | efeito de desenho |
|---|---|---|---|---|
| pessoas | 58.638.580 | 16.035 | 0,027% | — |
| presentes | 57.948.156 | 15.886 | 0,027% | — |
| urbana | 25.941.017 | 10.785 | 0,042% | 2,74 |
| rural | 32.007.139 | 11.664 | 0,036% | 3,19 |
| analfabetos de 15 anos e mais | 13.520.687 | 6.755 | 0,050% | 1,49 |
| crianças de 0 a 4 anos | 7.413.679 | 4.994 | 0,067% | 1,31 |
| pessoas com rendimento | 36.687.921 | 11.478 | 0,031% | 3,27 |

Os coeficientes de variação ficam entre 0,027% e 0,067%: **uma amostra de um domicílio em quatro, com 3,07 milhões de domicílios, é extraordinariamente precisa**. Para comparação, a amostra de 1,27% tem coeficientes de variação de 1% a 3% nos mesmos domínios — é vinte vezes menor e sofre um segundo estágio de conglomeração.

Os efeitos de desenho ficam entre 1,31 e 3,27, acima de um como se esperava, porque o domicílio entra inteiro ou não entra: pessoas do mesmo domicílio se parecem, e isso custa precisão. Em domínios que são quase toda a população o efeito de desenho perde sentido — o denominador tende a zero — e fica ausente.

Essa precisão é do **desenho**, e não cobre o erro de cobertura nem o de transcrição. A seção 9 mostra que o segundo não é desprezível.

---

## 9. A amostra de 1,27% dentro desta

A amostra de 1,27% é subamostra desta e casa pela chave do questionário. É a única validação registro a registro que 1960 tem, e nenhuma das duas amostras a tem sozinha.

**Dos 143.223 domicílios da amostra de 1,27% nas dezessete unidades, 143.077 acham par — 99,90%**, com 146 sem par, dos quais 39 no Ceará e 39 no Rio de Janeiro.

A divergência por variável, entre os domicílios casados:

| variável | divergência |
|---|---|
| V102 tipo de construção | **8,65%** |
| V106 instalação sanitária | 3,48% |
| V105 abastecimento de água | 1,73% |
| V112 total de cômodos | 1,68% |
| V113 peças servindo de dormitório | 1,66% |
| V103 condição de ocupação | 0,76% |
| V118 situação | **0,64%** |
| V101 espécie do domicílio | 0,33% |
| V116 município | **0,10%** |

O padrão é o que importa. As **duas variáveis de geografia são as que menos divergem** — o município em 0,10% e a situação em 0,64% —, e isso é a prova de que a nossa leitura está certa nos dois arquivos: se houvesse erro de parsing, ele apareceria justamente ali, onde as fontes não têm por que discordar.

As variáveis substantivas divergem muito mais, e a divergência é **entre as duas transcrições**, não dentro da nossa. A amostra de 1,27% foi perfurada de cartões que sofreram dano de fita; esta não. Qual das duas está certa em cada caso é questão a resolver na compilação, não aqui. A matriz completa, por unidade e por variável, está em `data_raw/microdata/1960/amostra_25/comparacao_amostra_127.csv`.

---

## 10. Números por unidade da federação

| uf60 | domicílios | pessoas | pastas | municípios | estratos | expandido | fator |
|---|---|---|---|---|---|---|---|
| 14 Ceará | 157.889 | 850.533 | 706 | 142 | 1.087 | 3.337.856 | 3,982 |
| 17 Rio Grande do Norte | 59.421 | 305.939 | 266 | 83 | 382 | 1.157.258 | 3,837 |
| 19 Paraíba | 102.220 | 535.250 | 461 | 88 | 638 | 2.018.023 | 3,821 |
| 21 Pernambuco | 221.756 | 1.080.408 | 968 | 102 | 1.283 | 4.136.900 | 3,882 |
| 24 Fernando de Noronha | 75 | 307 | 1 | 1 | 1 | 1.319 | 4,441 |
| 25 Alagoas | 68.139 | 329.454 | 300 | 69 | 396 | 1.271.062 | 3,904 |
| 30 Sergipe | 44.059 | 209.544 | 195 | 62 | 257 | 760.273 | 3,668 |
| 31 Bahia | 313.602 | 1.597.093 | 1.392 | 194 | 2.034 | 5.990.605 | 3,796 |
| 40 Minas Gerais | 489.505 | 2.494.671 | 2.229 | 483 | 3.283 | 9.790.783 | 3,971 |
| 50 Serra dos Aimorés | 17.705 | 98.908 | 74 | 1 | 75 | 382.794 | 3,885 |
| 52 Rio de Janeiro | 178.824 | 878.115 | 764 | 61 | 997 | 3.402.728 | 3,916 |
| 60 São Paulo | 740.936 | 3.319.710 | 3.140 | 503 | 3.877 | 12.974.699 | 3,954 |
| 71 Paraná | 224.179 | 1.111.227 | 945 | 162 | 1.293 | 4.272.847 | 3,876 |
| 81 Rio Grande do Sul | 293.054 | 1.409.136 | 1.265 | 150 | 1.761 | 5.448.823 | 3,909 |
| 91 Mato Grosso | 45.199 | 227.936 | 211 | 63 | 324 | 905.582 | 4,033 |
| 94 Goiás | 95.005 | 500.664 | 456 | 179 | 674 | 1.954.862 | 3,959 |
| 97 Distrito Federal | 14.797 | 34.874 | 38 | 1 | 38 | 141.742 | 4,121 |
| **total** | **3.066.365** | **14.983.769** | **13.411** | **2.344** | **18.400** | **57.948.156** | |

O fator realizado — universo dividido por presentes na amostra — vai de **3,668 em Sergipe a 4,441 em Fernando de Noronha**, com 3,915 no conjunto. Não é 4: a fração realizada nunca foi exatamente um em quatro, e o volume de 1965 já dizia "aproximadamente 25%".

---

## 11. O que sai

Duas tabelas por unidade da federação, em `data_raw/microdata/1960/amostra_25/<uf>/`:

- **`domicilios_pesos.parquet`** — 47 colunas: a geografia (`code_muni`, `code_muni_1960`, `name_muni_1960`, `code_district_1960`, `name_district_1960`, `censobr_favela`, `censobr_muni_corrigido`), os identificadores (`censobr_idhousehold`, `censobr_idfamily`, `censobr_tipo_unidade`), a chave do questionário (`v001` a `v004`, `v100`), a página do domicílio (`V101` a `V113`), as contagens (`censobr_n_listadas`, `_residentes`, `_presentes`, `_familias`) e o desenho (`censobr_upa`, `censobr_estrato`, `censobr_fpc`, `censobr_weight`, `censobr_weight_nivel`, `censobr_weight_ibge`, `censobr_weight_desenho`).
- **`pessoas_pesos.parquet`** — as mesmas colunas de geografia, identificação e desenho, mais as 24 variáveis de pessoa (`V202` a `V224`, com `AGE` renomeada `V204B` para casar com a amostra de 1,27%).

Os intermediários de cada passo ficam ao lado, para auditoria: `familias.parquet`, `pessoas.parquet`, `domicilios.parquet`, `pessoas_geo.parquet`.

---

## 12. Decisões tomadas

1. **A ordem do cadastro é restaurada** em oito unidades, por ordenação de pasta, boletim e pessoa. Nenhum registro muda de conteúdo.
2. **O boletim individual não é domicílio** — `censobr_tipo_unidade` o separa.
3. **A página de domicílio das famílias conviventes fica ausente** (`ipea/censobr#87`).
4. **O ignorado fica com o código do dicionário**, inclusive o `00` de cômodos e o `000` de dormitórios. Não se cria coluna de marca para o que o *Código do Censo* já documenta.
5. **Três correções de código de município**: Alagoas −200, Fernando de Noronha 2701→2401, Distrito Federal 9701→9700.
6. **O estrato é pasta × situação** e a unidade primária é o domicílio, com correção finita de 1/4.
7. **Dois pesos**: `censobr_weight`, calibrado por município × situação à contagem completa, e `censobr_weight_ibge`, que reproduz o método publicado do IBGE.
8. **A âncora municipal não se abandona no colapso** — o município sobe no máximo ao seu próprio total.
9. **Serra dos Aimorés calibra à Série Nacional**, por não ter contagem completa, e isso fica documentado.

---

## 13. Em aberto

- **O nome do distrito falta em 4,6% dos domicílios.** `code_district_1960` está correto em 100% dos registros; o que falta é traduzir código em nome para 715 pares município–distrito que o *Código de Zonas Fisiográficas, Municípios e Distritos* traz impressos e que ninguém transcreveu. O livro são 313 páginas de scan sem camada de texto, e o método de leitura está em [`references/folha_contato_codigo_1960.py`](folha_contato_codigo_1960.py), com o que falta listado em [`read_guides/1960_amostra_25_distritos_pendentes.csv`](../read_guides/1960_amostra_25_distritos_pendentes.csv). Quatro atalhos foram testados e descartados: a regra de sequência dos códigos vale em 69% dos municípios; a divisão territorial de 2022 impõe grafia moderna e desconhece distrito extinto; a Sinopse Preliminar tem camada de texto tão danificada quanto; e a divisão territorial de **1970** erra 18% dos pares, porque os códigos foram reaproveitados — em Alto Paraná o 07 era Sumaré em 1960 e Socavão em 1970.
- **Alto Garças (Mato Grosso), 4.630 habitantes, não tem domicílio sorteado.** É buraco de cobertura da amostra.
- **O desacordo com a amostra de 1,27%** nas variáveis do domicílio — 8,65% no tipo de construção — fica medido e não resolvido. É assunto da compilação.
- **O dígito verificador não serve de teste.** Há 5.371 registros de pessoa com ele em branco, e nove esquemas de verificação foram testados sem que nenhum passasse de 10,9% de acerto, que é o acaso.
- **A compilação das duas amostras** é um estágio à parte, e é ela que produzirá o que o `censobr` distribui.

---

## 14. Como auditar

```r
targets::tar_make(names = c("auditoria_1960_amostra_25", "tabelas_brutas_1960_amostra_25",
                            "tabelas_1960_amostra_25", "pesos_1960_amostra_25",
                            "validacao_definitivos_1960_amostra_25", "erros_1960_amostra_25",
                            "comparacao_127_1960_amostra_25"))
```

O que conferir depois:

- `tar_read(auditoria_1960_amostra_25)` deve trazer nove classes de defeito e nada mais.
- A soma dos boletins deve dar 3.071.284; a das pessoas, 14.983.769; a das pastas, 13.411.
- Nenhum domicílio sem `code_muni`.
- `validacao_definitivos.csv` deve ter erro mediano perto de 1,2% em cada tabela.
- `comparacao_amostra_127.csv` deve mostrar V116 abaixo de 0,2% e V118 abaixo de 1%. Se algum deles subir, o erro é nosso.

---

## 15. Fontes

- **Microdados**: `Censo.1960.amostra.25porcento.<uf>.gz`, release `release_legacy` deste repositório. Proveniência em [`fontes_1960/README.md`](fontes_1960/README.md).
- **Layout**: `Census1960_input_Sample_25.xlsx` (CEM), transcrito em `read_guides/readguide_1960_amostra_25_*.csv`.
- **Códigos**: IBGE, Serviço Nacional de Recenseamento, *Código do Censo Demográfico — 1960*, 26 p., em [`fontes_1960/1960_codigo_do_censo_demografico.pdf`](fontes_1960/1960_codigo_do_censo_demografico.pdf); transcrito em `read_guides/1960_codigo_do_censo.csv`.
- **Municípios e distritos**: *Código de Zonas Fisiográficas, Municípios e Distritos de 1960*, transcrito em `read_guides/1960_municipios.csv` e `1960_distritos.csv`.
- **Universo**: Sinopse Preliminar do Censo Demográfico de 1960, por unidade da federação; para o Paraná, o Quadro II da edição de março de 1962.
- **Resultados definitivos**: IBGE, *Censo Demográfico de 1960 — Brasil*, Série Nacional vol. I, em [`fontes_1960/1960_serie_nacional_vol1_brasil.pdf`](fontes_1960/1960_serie_nacional_vol1_brasil.pdf); tabelas transcritas em `references/censo_1960_resultados_definitivos_serie_nacional.csv`.
- **Tomos regionais** consultados sobre a Serra dos Aimorés: `cd_1960_v1_t9_mg.pdf` (p. 6) e `cd_1960_v1_t10_p1_es.pdf` (p. 7–8), biblioteca do IBGE.
