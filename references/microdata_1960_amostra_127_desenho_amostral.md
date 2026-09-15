# A amostra de 1,27% do Censo de 1960: o desenho amostral explicado do zero

Este texto acompanha `R/microdata_1960_amostra_127.R` e o documento de preparação (`references/microdata_1960_amostra_127_preparacao.md`). Ele existe para um leitor que conhece estatística e análise de dados, tem noções de amostragem (sabe o que é um estrato, uma unidade primária, um peso), mas nunca ouviu falar desta amostra nem do vocabulário do IBGE de 1960. A promessa é que, ao fim, o leitor saiba exatamente como a amostra foi sorteada, o que sobreviveu no arquivo, o que cada coluna de desenho significa, como calcular um erro-padrão correto e por que cada decisão foi tomada. Todos os números vêm da execução do pipeline em 2026-09-14 e podem ser reproduzidos pelos alvos do `targets`.

## 1. O Censo de 1960 e as suas duas amostras

O Censo Demográfico de 1960 foi feito com data de referência em 1º de setembro de 1960: em cada domicílio foram recenseadas as pessoas que ali passaram a noite de 31 de agosto para 1º de setembro. O recenseador percorria o seu **setor censitário** — a área de trabalho de um recenseador, com algumas centenas de domicílios — e preenchia um questionário curto para todos os domicílios. Esse questionário curto é o **universo** do censo, e é dele que saem as contagens totais de população.

O IBGE não perguntou tudo a todo mundo. As perguntas longas — migração, instrução, estado conjugal, filhos, rendimento, ocupação, ramo de atividade, e as características do domicílio como água, esgoto, fogão, rádio — foram feitas a uma **amostra de 25%** dos domicílios, num questionário próprio, o **Boletim de Amostra** (formulário CD 2). O sorteio dessa amostra era sistemático e feito no campo: o recenseador listava os domicílios do setor na folha de coleta e aplicava o boletim de amostra a uma em cada quatro linhas; nos domicílios coletivos (quartéis, hospitais, hotéis, pensões), a um em cada quatro moradores. Essa amostra de 25% é a "amostra geral" do censo, e é dela que saíram os volumes definitivos publicados ao longo dos anos 1960 e 1970. Os seus microdados sobrevivem hoje para 17 unidades da federação (o `censobr` os distribui na compilação de 1960).

A apuração mecânica de 25% do país levaria anos. Para publicar resultados rápidos, o IBGE sorteou, dentro da amostra de 25%, uma **subamostra de cerca de 1,27% da população**, tabulou-a em cartões perfurados e publicou com ela, em março de 1965, os *Resultados Preliminares do Censo Demográfico* (Série Especial, volume II). É dessa subamostra que trata este texto. Ela é a única amostra do Censo de 1960 que cobre todas as unidades da federação, e é por isso que ela importa mesmo onde a amostra de 25% existe.

## 2. O vocabulário da época

Sem estas palavras o resto não se lê.

- **Boletim** — o questionário de um domicílio. O boletim de amostra (CD 2) tem a página do domicílio e uma linha por pessoa. No arquivo, cada boletim virou um cartão de família (a página do domicílio) e um cartão por pessoa.
- **Setor censitário** — a área de um recenseador. Os boletins de amostra de um setor ficavam juntos.
- **Pasta** — a palavra central. Quando os boletins de amostra chegavam ao órgão central, eram reunidos em lotes de trabalho de cerca de 250 boletins, na ordem dos setores, e cada lote era uma pasta física, numerada. A pasta é uma unidade administrativa (um pacote de papel que um codificador recebia para codificar), não uma unidade geográfica; mas, como os boletins entravam na ordem dos setores, uma pasta contém boletins de setores vizinhos, quase sempre do mesmo município, e é inteiramente urbana, inteiramente rural ou mista conforme os setores que a compõem. No desenho, a pasta é a **unidade primária de amostragem**: sorteou-se a pasta inteira.
- **Distrito** — a divisão administrativa abaixo do município (a sede é o distrito 01; os demais têm códigos ímpares, 03, 05, 07…). Na Guanabara, que era estado e cidade ao mesmo tempo, não há distritos: há bairros, circunscrições censitárias e favelas, com códigos próprios.
- **Zona fisiográfica** — a divisão regional que o IBGE usava dentro de cada estado (por exemplo, "Zona do Litoral", "Zona da Mata"). Cada município pertence a uma zona. Ela importa porque o cadastro de sorteio foi ordenado por zona.
- **Situação** — do domicílio: quadro urbano, suburbano ou rural. "Urbano" nas tabelas de 1965 soma urbano e suburbano.
- **População presente** e **população residente** — presente é quem estava no domicílio na noite de referência (moradores presentes mais não moradores presentes); residente é quem mora ali (moradores presentes mais moradores ausentes). As tabelas de 1965 usam presente para pessoas e residente para domicílios.
- **Chave do questionário** — a identificação que o arquivo guarda para cada boletim: unidade da federação, distrito, número da pasta e número do boletim dentro da pasta. É por ela que a pasta é reconhecível no arquivo.

## 3. Como a subamostra foi sorteada

A descrição que existe é a do volume II de 1965, páginas 5 e 6, e é curta. Em nossas palavras:

1. A primeira etapa é a própria amostra de 25%: os boletins de amostra do país inteiro, reunidos em pastas de cerca de 250 boletins cada, na ordem dos setores.
2. As pastas foram classificadas em **estratos**, definidos por dois critérios cruzados: a geografia (o volume não diz qual é a unidade geográfica) e a **situação** das pastas em quatro grupos — pastas de cidades com 100 mil habitantes ou mais; pastas de aglomerados urbanos menores; pastas rurais; pastas mistas (com boletins urbanos e rurais).
3. Dentro de cada estrato, sorteou-se **uma pasta em vinte**, sistematicamente, com início aleatório: numa lista ordenada, escolhe-se um ponto de partida ao acaso entre as vinte primeiras e a partir dele toma-se uma pasta a cada vinte.
4. Todos os boletins da pasta sorteada entram na subamostra. Foram sorteadas **814 pastas**.

A fração de amostragem nominal é, portanto, ¼ × 1/20 = 1/80 = 1,25%; o volume fala em "aproximadamente 1,27%" porque o número de boletins por pasta variava. O peso de desenho nominal, o inverso da fração, é 80: cada pessoa da subamostra representa oitenta pessoas.

Em figura:

```
todos os domicilios do pais  ->  1 em 4, no setor  ->  amostra de 25% (boletins CD 2)
                                                        reunidos em pastas de ~250 boletins, na ordem dos setores
                                                        classificadas em estratos: geografia x situacao
                                                  ->  1 pasta em 20, sistematico, dentro de cada estrato
                                                  ->  814 pastas = a amostra de 1,27% (todos os boletins da pasta)
```

Por que sortear pastas inteiras, e não pessoas? Porque era barato. As pastas já existiam como pacotes físicos; perfurar cartões para 814 pastas era um trabalho que cabia no calendário de uma publicação preliminar, e sortear pessoas espalhadas por milhares de pastas não cabia. O custo estatístico dessa escolha é o assunto da seção 8: as pessoas de uma mesma pasta são vizinhas e parecidas, e a amostra tem menos informação do que os seus 897 mil registros sugerem.

O volume promete "uma publicação especial" com a descrição detalhada do desenho e os erros de amostragem. Ela não existe na biblioteca do IBGE, no Internet Archive nem nas citações dos volumes definitivos; tudo indica que nunca saiu. O que vai abaixo sobre estratos e erros é, por isso, reconstrução a partir do próprio arquivo, e em cada ponto dizemos o que é fato documentado, o que o dado mostra e o que é escolha nossa.

## 4. O que sobreviveu

A subamostra foi perfurada em cartões de 62 colunas, um por pessoa e um por página de domicílio. Um relatório do IPEA de 1969 mostra os cartões circulando entre instituições e sendo gravados em fita; o arquivo de hoje, `HHOLDA.txt`, é a imagem desse baralho de cartões depois de décadas de cópias: 1.074.328 linhas de 62 caracteres. O documento de preparação descreve o dano (linhas deslocadas, caracteres corrompidos, blocos de cartões copiados duas vezes em Pernambuco, cartões de família perdidos) e o que se fez com ele. Aqui interessa o que o dano fez ao desenho:

- **As 814 pastas estão todas lá.** O arquivo tem 817 números de pasta distintos; os três a mais são uma pasta de Rondônia gravada em duas unidades da federação e chaves com um dígito trocado. Nenhum conglomerado inteiro se perdeu.
- **As pastas têm o tamanho esperado.** Mediana de 223 boletins por pasta (quartis 197 e 241, máximo 352), e cerca de 1.100 pessoas. Vinte e três pastas têm menos de 100 boletins: as de Roraima e de Fernando de Noronha, que eram pequenas mesmo, e algumas truncadas. O caso grave é o Distrito Federal: as duas pastas de Brasília têm 77 e 60 boletins no arquivo, quando a amostra de 25% mostra que tinham 520 e 257. O arquivo perdeu 85% e 75% dessas duas pastas, e o trecho perdido era um acampamento de operários da construção de Brasília. É a única perda de conglomerado de que se tem prova.
- **A chave do questionário sobreviveu em quase todas as linhas**, e é ela que permite dizer a que pasta cada pessoa pertence. Onde o cartão de família se perdeu, a chave está nos cartões de pessoa.
- O resultado é uma tabela de 897.009 pessoas em 174.245 domicílios, 885.127 delas presentes na noite de referência — 1,26% dos 70.119.071 presentes que o volume de 1965 publicou.

## 5. O que o próprio arquivo diz sobre o sorteio

Como não há publicação especial, fomos ao número da pasta. Ele é a ordem do cadastro de sorteio, e carrega a assinatura do sorteio:

- **Todas as 817 pastas têm número par** (a única exceção é lixo). As pastas da amostra de 25% foram numeradas de dois em dois.
- **O espaçamento dominante entre pastas consecutivas de uma unidade da federação é 40** — vinte pastas pares —, que é exatamente "uma em vinte". Numa cidade grande, cujas pastas urbanas são contíguas no cadastro, a grade é quase perfeita: Salvador tem 8 pastas todas a 40 uma da outra, Belo Horizonte 8, Porto Alegre 7, Curitiba 4, o Rio de Janeiro 40 com um único salto, São Paulo 42 com saltos pequenos onde o cadastro pulou números.
- **As pastas rurais e mistas ficam fora dessa grade**, com espaçamentos irregulares e sempre maiores que 40. São sequências sistemáticas próprias, intercaladas com as urbanas na numeração: a assinatura de estratos de situação sorteados separadamente.
- **Nenhuma pasta puramente urbana de um município com cidade grande fica a menos de 40 de outra pasta urbana do mesmo município**; as vizinhas próximas são sempre mistas. As pastas urbanas de um município grande se comportam como um estrato só.
- **A numeração segue a zona fisiográfica.** Com o Código de Municípios e Distritos de 1960, que dá a zona de cada município, vê-se que em 14 das 20 unidades da federação com oito pastas ou mais a correlação de postos entre o número da pasta e o código da zona do seu município é 0,9 ou mais, e que em 19 delas a zona não decresce em 95% a 100% das pastas consecutivas. O cadastro foi ordenado por zona fisiográfica, município e setor. Um sorteio sistemático numa lista assim ordenada é **implicitamente estratificado** por zona: a amostra se espalha pelas zonas na proporção em que elas estão no cadastro, sem que a zona precise ser um estrato explícito.
- **O peso realizado** bate com o nominal. Dividindo a população presente publicada em 1965 pela nossa contagem, o fator implícito é 79,2 no Leste, 79,4 no Sul e 79,5 no Nordeste, 80,0 no urbano e 78,6 no rural; o nominal é 80.

Conclusão: o sorteio descrito em 1965 está confirmado no arquivo — sistemático, uma pasta em vinte, por estratos de situação, sobre um cadastro ordenado geograficamente. O que a numeração não revela é a unidade geográfica dos estratos, porque a sequência não atravessa unidades da federação; e o que o arquivo não pode dizer é como o IBGE operacionalizou "cidade de 100 mil habitantes".

## 6. Os pesos

**O peso de desenho.** Cada domicílio da subamostra recebe 1/0,0127 = 78,74, o inverso da fração de amostragem que o volume de 1965 declara. Está em `censobr_weight_desenho`. Se o arquivo fosse íntegro e a fração exata, bastaria multiplicar contagens por esse número para estimar totais do país.

**Por que calibrar.** O arquivo não é íntegro (pastas truncadas, cartões perdidos, cópias removidas), a fração real variou por estrato, e o IBGE publicou em 1965, com estes mesmos cartões antes do dano, as tabelas que a amostra deveria reproduzir. Calibrar é ajustar os pesos o mínimo necessário para que a amostra reproduza totais conhecidos. A intuição: se a amostra tem 1.000 mulheres de 20 a 24 anos no urbano do Nordeste e o IBGE publicou que elas eram 286.222, o peso delas tem de ser 286,2; a calibração faz isso simultaneamente para todas as células, mexendo o menos possível em cada peso.

**A que se calibra.** Às margens demográficas: as 176 células do quadro 1 de 1965 (4 regiões × 2 situações × 2 sexos × 11 faixas de idade, população presente) e as 8 do quadro 2 que contam quem sabe ler e escrever, por sexo e região, entre os presentes de 5 anos e mais. São 184 restrições, reproduzidas exatamente. A regra é: calibrar ao que é demográfico e determina quase tudo o mais; deixar as tabelas de resultado (ramo de atividade, rendimento, estado conjugal, domicílios) como validação. Testamos acrescentar o estado conjugal e o ramo de atividade: o primeiro faz os pesos explodirem, porque força os domicílios que perderam o cartão do chefe a compensar com peso o que falta; o segundo conserta o ramo à custa de inflar até 5,8 vezes os domicílios do Norte e Centro-Oeste com operários da construção — isto é, cria com peso os candangos de Brasília que o arquivo perdeu — e piora rendimento e instalações. Ficou a regra demográfica.

**Como se calibra.** Método de Deville e Särndal com distância "raking": o peso final é o de desenho vezes exp(x'λ), onde x conta quantas pessoas o domicílio tem em cada célula de restrição e λ é um vetor de 184 multiplicadores resolvido por Newton em seis iterações. O peso é um por domicílio, o mesmo para todas as suas pessoas (peso integrado): isso garante que pessoas e domicílios sejam estimados com os mesmos pesos e que um domicílio nunca "represente" 80 chefes e 90 cônjuges.

**O resultado.** `censobr_weight` vai de 38,6 a 384,5, com 98% dos domicílios entre 72,8 e 89,6 e mediana 78,8. O fator de calibração (`censobr_weight_fator`, peso calibrado dividido pelo de desenho) vai de 0,49 a 4,88; os extremos estão nos domínios pequenos e danificados (o Distrito Federal, com fator mediano 1,07, é o mais alto por unidade da federação). Para as 184 células a estimativa é exata por construção; para qualquer outra variável, a calibração reduz a variância na medida em que a variável se correlaciona com idade, sexo, situação, região e alfabetização.

**O que o peso não faz.** Nenhum peso cria o que não foi amostrado. Rondônia só tem Porto Velho urbano; Amapá tem um município; Acre dois; Fernando de Noronha só urbano; o Distrito Federal perdeu dois terços dos seus boletins. A calibração reproduz totais regionais, e a estimativa para essas unidades isoladas descreve só o que foi sorteado e sobreviveu.

## 7. Estratos e unidades primárias no arquivo

Duas colunas, presentes nas tabelas de pessoas e de domicílios, dizem como o sorteio foi feito:

- `censobr_upa` — a **unidade primária de amostragem**: a pasta, identificada por unidade da federação e número (817 valores).
- `censobr_estrato` — o **estrato**: a região cruzada com o grupo de situação da pasta. São 16 estratos.

| região | cidade grande | urbana menor | mista | rural |
|---|---|---|---|---|
| Leste | 72 | 42 | 108 | 63 |
| Sul | 64 | 63 | 92 | 70 |
| Nordeste | 22 | 20 | 64 | 70 |
| Norte e Centro-Oeste | 6 | 12 | 29 | 20 |

As regiões são as do volume de 1965: Nordeste (MA, PI, CE, RN, PB, PE, FN, AL), Leste (SE, BA, MG, Serra dos Aimorés, ES, RJ, GB), Sul (SP, PR, SC, RS) e Norte e Centro-Oeste (RO, AC, AM, RR, PA, AP, MT, GO, DF).

**Como cada pasta foi classificada.** Pela situação dos seus próprios boletins: mista se tem urbanos e rurais; rural se só tem rurais; e as puramente urbanas se dividem pelo tamanho da cidade. O corte de 100 mil habitantes não se deduz da amostra — um município que recebeu uma pasta inteira já parece ter 90 mil habitantes, e o cálculo acusaria 216 municípios acima de 100 mil — e vem de fora: a população urbana de cada município no Anuário Estatístico do Brasil de 1961, casada pelo código de município (`read_guides/1960_municipios.csv`). Cidade grande é a pasta puramente urbana de município com população urbana de 100 mil ou mais: 34 municípios, de São Paulo e Rio de Janeiro (3,3 e 3,2 milhões) a Olinda e Teresina (100 mil), todos com pasta na amostra.

**O que é fato e o que é escolha.** É fato que o IBGE usou quatro grupos de situação e uma geografia. É escolha nossa (1) a região como geografia, porque estratos por unidade da federação teriam pastas sozinhas e a numeração das pastas não revela a unidade usada; (2) o corte de cidade grande pela população urbana do município, porque o volume fala em "cidades de 100 000 e mais habitantes" e define cidade como sede municipal mas não diz como operacionalizou, e a numeração mostra que as pastas urbanas de um município grande formam um estrato só. O critério alternativo, população total do município (64 municípios), foi calculado como sensibilidade: muda pouco, e piora o Norte e Centro-Oeste urbano em 8%.

**Por que isso basta para o erro-padrão.** Para estimar variância de uma amostra de conglomerados é preciso saber (a) quais observações foram sorteadas juntas — a pasta — e (b) dentro de que grupos o sorteio foi independente — o estrato. Errar o estrato para mais grosso (juntar estratos que o IBGE separava) superestima a variância, porque atribui ao acaso diferenças que na verdade estavam controladas pela estratificação. É o lado seguro do erro, e é onde estamos: os nossos estratos são mais grossos que os do IBGE, e a estratificação implícita por zona (seção 5) não entra.

## 8. Como calcular um erro-padrão, e o que ele diz

**Por que não tratar as 897 mil linhas como 897 mil sorteios.** As pessoas de uma pasta são vizinhas: mesmos setores, mesmo bairro ou mesma zona rural, mesma situação. Se a pasta sorteada é um bairro operário, ela traz 1.100 pessoas parecidas; a próxima pasta, 40 posições adiante no cadastro, pode ser outro mundo. A informação que a amostra contém sobre o país é, em boa medida, a informação de 817 pastas, não de 897 mil pessoas. Quem calcula o erro-padrão como se fossem sorteios independentes publica intervalos de confiança várias vezes estreitos demais.

**O estimador.** Para um total Y estimado por Ŷ = Σ w·y, calcula-se em cada pasta o total ponderado t = Σ w·y das suas pessoas, e em cada estrato h com n_h pastas a variância entre os totais das pastas:

  V(Ŷ) = Σ_h n_h/(n_h − 1) · Σ_i (t_hi − t̄_h)²

Isto é o estimador de "conglomerado último" (ultimate cluster): a variância vem inteiramente da dispersão entre pastas dentro de cada estrato. Três detalhes: as pastas que não têm ninguém do domínio estimado entram com total zero, e é por isso que n_h é o número de pastas do estrato na amostra toda, e não só das que têm o domínio; a fração de uma pasta em vinte não entra como correção de população finita (ela reduziria a variância em 5%; ignorá-la é conservador); e a calibração é ignorada no cálculo (para variáveis correlacionadas com as margens, a variância verdadeira é menor; ignorar é conservador de novo). O passo 11 do pipeline faz essa conta à mão para não acrescentar dependência; `survey::svydesign(ids = ~censobr_upa, strata = ~censobr_estrato, weights = ~censobr_weight)` dá o mesmo resultado.

**O efeito de desenho.** É a razão entre a variância assim calculada e a que uma amostra aleatória simples de pessoas do mesmo tamanho teria. Diz "quantas vezes menos precisa" a amostra é do que parece. Um efeito de desenho 10 numa célula com 4.810 pessoas significa que ela vale o que valeriam 481 sorteios independentes.

**O que os números dizem.** Para a população presente, com os 16 estratos:

| domínio | estimativa | erro-padrão | coeficiente de variação | efeito de desenho |
|---|---|---|---|---|
| Brasil, urbana | 32.471.377 | 517.287 | 1,6% | 196 |
| Brasil, rural | 37.647.694 | 576.427 | 1,5% | 244 |
| Leste | 24.659.232 | 307.307 | 1,25% | 76 |
| Sul | 24.445.902 | 332.447 | 1,4% | 89 |
| Nordeste | 15.524.609 | 263.393 | 1,7% | 73 |
| Norte e Centro-Oeste | 5.489.328 | 218.714 | 4,0% | 121 |
| Norte e Centro-Oeste, urbana | 2.242.836 | 209.141 | 9,3% | 258 |

Os efeitos de desenho de 70 a 260 nesses domínios grandes assustam, e têm uma razão simples: a situação e a região são atributos da pasta inteira. Estimar quanta gente mora no urbano do Nordeste é contar quantas pastas urbanas foram sorteadas no Nordeste e o tamanho de cada uma — e isso varia de sorteio para sorteio muito mais do que a contagem de pessoas sugere. Nas 176 células do quadro 1 (região × situação × sexo × idade), onde a variável de interesse varia dentro das pastas, o efeito de desenho tem mediana 6,6 e o coeficiente de variação mediana 3,6%, máximo 11,9%. Um exemplo completo, mulheres do urbano do Nordeste:

| faixa de idade | estimativa | erro-padrão | CV | efeito de desenho | pessoas na amostra |
|---|---|---|---|---|---|
| 0 a 4 | 417.327 | 18.975 | 4,5% | 11,1 | 5.294 |
| 5 a 9 | 381.630 | 17.470 | 4,6% | 10,3 | 4.810 |
| 20 a 24 | 286.222 | 10.938 | 3,8% | 5,4 | 3.582 |
| 40 a 49 | 240.804 | 9.603 | 4,0% | 4,9 | 3.039 |
| 60 a 69 | 101.760 | 6.120 | 6,0% | 4,7 | 1.277 |
| 70 e mais | 67.782 | 4.336 | 6,4% | 3,6 | 837 |

Os efeitos são maiores nas crianças (famílias grandes se concentram em pastas) e menores nos idosos. Uma célula dessas, que com 4.810 pessoas pareceria ter um erro relativo de 1,4% se fosse aleatória simples, tem 4,6%.

**Duas ausências.** Não há erro-padrão para o total do país nem para as 184 células calibradas, e não é esquecimento: a soma dos pesos foi calibrada a esses totais, e eles são reproduzidos por construção, sem erro. Os erros-padrão que a tabela traz para essas células são os de antes da calibração, e portanto conservadores. A tabela completa, com 191 domínios, está em `data_raw/microdata/1960/amostra_127/erros_amostrais.csv`.

## 9. Como usar em R

```r
library(arrow); library(survey)
pessoas <- read_parquet("data_raw/microdata/1960/amostra_127/pessoas_1960_amostra_127.parquet")

desenho <- svydesign(ids = ~censobr_upa, strata = ~censobr_estrato,
                     weights = ~censobr_weight, data = pessoas)
options(survey.lonely.psu = "adjust")   # nenhum estrato tem pasta sozinha, mas subconjuntos podem ter

# um total com erro-padrao: pessoas presentes por regiao x situacao
presentes <- subset(desenho, !(V202 %in% c(3, 4)))
svyby(~I(rep(1, nrow(presentes))), ~censobr_estrato, presentes, svytotal)

# uma proporcao: sabem ler entre os presentes de 5 anos e mais
alf <- subset(presentes, V204 == 1 & V204B >= 5 | V204 == 5)
svymean(~I(V211 %in% c(0, 1)), alf, na.rm = TRUE)

# uma media com dominio: idade media dos operarios da construcao civil, com o efeito de desenho
svymean(~V204B, subset(presentes, V223B == 351 & V204 == 1), deff = TRUE)
```

Três cuidados. Subconjuntos devem ser feitos com `subset()` sobre o objeto de desenho, não filtrando a tabela antes, para que as pastas sem ninguém do domínio continuem contadas. Domicílios usam as mesmas colunas e os mesmos pesos, uma linha por domicílio. Estimativas para um município são, em geral, estimativas de uma ou duas pastas: não têm erro-padrão calculável e não devem ser publicadas como estimativas municipais — a amostra não foi desenhada para isso.

## 10. Limitações e cuidados

- **O desenho é reconstruído.** Estratos, geografia e a regra da cidade grande são a nossa melhor leitura do volume de 1965 e do arquivo. Os erros-padrão são, por construção, um pouco conservadores.
- **O Distrito Federal está truncado** e o trecho perdido não é aleatório (um acampamento de construção). Estimativas para o DF a partir desta amostra subestimam a construção civil; a compilação com a amostra de 25% resolve, porque lá o DF está inteiro.
- **Cobertura parcial** de Rondônia, Amapá, Acre, Roraima, Fernando de Noronha e Distrito Federal: poucas pastas, e em alguns casos uma situação só.
- **Domínios pequenos.** Com efeitos de desenho de 5 a 10, uma célula precisa de milhares de pessoas na amostra para ter erro relativo abaixo de 5%.
- **Comparações com 1965.** Os quadros 1 e 2 são reproduzidos exatamente por construção; os demais diferem por poucos por cento, e as diferenças estão explicadas ou documentadas no documento de preparação (seção 7).

## 11. Como incorporar melhor o desenho: as possibilidades, uma a uma

Esta seção percorre cada forma de melhorar o cálculo do erro-padrão, com a intuição, um exemplo numérico calculado neste arquivo e o que cada uma exige. Nada aqui muda os pesos nem os estratos das tabelas; muda o que se faz com eles. Para tornar tudo concreto, cinco totais servem de exemplo ao longo da seção, todos para a população presente:

| total (pessoas) | estimativa | pastas com o atributo |
|---|---|---|
| operários da construção civil (classe 351) | 748.117 | 657 |
| pessoas com rendimento acima de Cr$ 10 mil | 2.525.829 | 748 |
| analfabetos de 15 anos e mais | 15.828.389 | 816 |
| solteiros de 15 anos e mais | 13.425.845 | 814 |
| população urbana do Nordeste | 5.449.423 | 106 |

E o resumo, em milhares de pessoas, dos erros-padrão que cada alternativa dá; as subseções explicam cada coluna:

| total | atual (16 estratos) | com correção finita | estratos UF × situação | diferenças sucessivas | resíduos da calibração | jackknife | se fosse aleatória simples |
|---|---|---|---|---|---|---|---|
| construção civil | 29 | 28 | 28 | 27 | 26 | 29 | 8 |
| rendimento > 10 mil | 83 | 81 | 80 | 70 | 65 | 83 | 14 |
| analfabetos 15+ | 215 | 209 | 202 | 196 | 34 | 215 | 31 |
| solteiros 15+ | 141 | 138 | 137 | 133 | 52 | 141 | 29 |
| urbana do Nordeste | 193 | 188 | 186 | 184 | 0 | 193 | 20 |

A última coluna é o erro-padrão que uma amostra aleatória simples de pessoas do mesmo tamanho teria; a razão entre ela e a primeira, ao quadrado, é o efeito de desenho (14 na construção, 36 no rendimento, 48 nos analfabetos, 95 no urbano do Nordeste). É a medida do que a amostragem por pastas custa.

### 11.1 O ponto de partida: o que o estimador atual supõe

O estimador da seção 8 trata a amostra como se, em cada um dos 16 estratos, as pastas tivessem sido sorteadas **com reposição e independentemente umas das outras**, e como se os pesos fossem fixos. Nenhuma das duas coisas é exatamente verdade: as pastas foram sorteadas sistematicamente num cadastro ordenado (o que é melhor que independente), e os pesos foram calibrados (o que os torna dependentes da amostra). As duas simplificações erram para o lado seguro, isto é, produzem erros-padrão maiores que os verdadeiros. As alternativas abaixo relaxam uma simplificação de cada vez.

Uma imagem para fixar. Pense no cadastro de uma unidade da federação como uma fila de pastas, e nos estratos como cores:

```
cadastro (uma UF)      U U U U U U U U U U U U U U U U U U U U   M M M M M M M M   R R R R R R R R R R R R
número da pasta        02 04 06 08 10 12 14 16 18 20 22 24 ...   ...              ...
sorteio (uma em 20)          ^                                       ^                         ^
```

U, M e R são as pastas urbanas, mistas e rurais; cada grupo é uma sequência própria (é o que a numeração mostra, seção 5), e em cada sequência sorteia-se uma pasta a cada vinte. O estimador atual olha para as pastas sorteadas de um estrato e mede o quanto os seus totais diferem entre si; quanto mais diferem, maior o erro-padrão.

### 11.2 A correção de população finita

**A ideia.** Se uma amostra tomasse todas as pastas do cadastro, não haveria erro amostral nenhum. Tomando uma fração f delas, a variância de um total é proporcional a (1 − f): sortear 5% das pastas deixa 95% do "espaço" para variar. A correção multiplica a variância por (1 − 1/20) = 0,95, e o erro-padrão por 0,975.

**O exemplo.** Construção civil: 29 mil vira 28 mil; rendimento alto: 83 vira 81. Um ganho de 2,5% em qualquer estimativa.

**Por que ficou de fora.** Porque a subamostra tem duas etapas. A primeira, um domicílio em quatro dentro de cada setor, também tem variância própria; o estimador de conglomerado último sem correção finita estima aproximadamente a soma das duas etapas, e é assim que se usa em amostras de conglomerados com fração pequena. Pôr a correção da segunda etapa sem acrescentar a variância da primeira dentro das pastas sorteadas subestimaria um pouco. O ganho é pequeno e a omissão é conservadora; se um dia se acrescentar a componente da primeira etapa, a correção entra junto.

### 11.3 Estratos mais finos: unidade da federação cruzada com situação

**A ideia.** O estrato diz de que grupo de pastas a variação "conta". Com região × situação, duas pastas urbanas menores do Ceará e do Maranhão estão no mesmo estrato, e a diferença entre elas (que é, em parte, a diferença entre Ceará e Maranhão) entra no erro-padrão. Se o IBGE estratificou por unidade da federação, essa diferença não existia no sorteio e não deveria contar. Cruzar unidade da federação com os quatro grupos dá 88 estratos, dos quais 16 têm uma pasta só e precisam ser colapsados (voltam ao estrato regional), porque com uma pasta não se mede variação.

**O exemplo.** Rendimento alto: 83 vira 80; analfabetos: 215 vira 202; construção: 29 vira 28. Ganhos de 3% a 6%.

**O que custa e o que arrisca.** Nada nas tabelas: é só outra coluna de estrato, que qualquer usuário pode construir com `UF` e o grupo de `censobr_estrato`. O risco é o colapso: juntar estratos que eram separados no sorteio superestima; separar estratos que eram juntos subestima. Como não sabemos qual geografia o IBGE usou, a região é a aposta segura e a unidade da federação é a alternativa a documentar.

### 11.4 Usar a ordem do cadastro: o estimador de diferenças sucessivas

**A ideia.** Numa amostra sistemática sobre uma lista ordenada, as pastas sorteadas vêm em ordem: a primeira da zona A, depois outra da zona A, depois uma da zona B, e assim por diante. Pastas vizinhas na lista são parecidas (mesma zona, municípios contíguos), e o que o sorteio realmente deixa ao acaso é o ponto de partida dentro do intervalo de vinte. Um estimador que mede a variância pelas **diferenças entre pastas consecutivas na ordem do sorteio** captura essa estrutura: em vez de comparar cada pasta com a média do estrato inteiro, compara cada pasta com a sua vizinha. Formalmente, dentro de cada estrato com as pastas ordenadas pelo número,

  V_SD(Ŷ) = Σ_h n_h / (2(n_h − 1)) · Σ_{i=2}^{n_h} (t_{h,i} − t_{h,i−1})²

É o estimador que o Census Bureau americano usa para amostras sistemáticas (o "v2" de Wolter), e o que o próprio IBGE recomenda para a PNAD. A figura:

```
ordem no cadastro (pastas urbanas de Sao Paulo, sorteadas):
  pasta   60118  60158  60198  60238  60278  60318 ...
  zona      A      A      A      A      B      B   ...
  total    t1     t2     t3     t4     t5     t6   ...
estimador atual:      (t1 - t̄)² + (t2 - t̄)² + ...      compara com a media de todo o estrato
diferencas sucessivas: (t2 - t1)² + (t3 - t2)² + ...   compara cada pasta com a vizinha
```

Na capital paulista, os 39 números de pasta urbanos sorteados estão a 40 um do outro em 25 dos 38 intervalos, e a 44 ou 46 em outros seis; os saltos maiores (62, 64, 78, 80, 82) são buracos de numeração do cadastro. É a grade do sorteio, visível.

**O exemplo.** Rendimento alto: 83 vira 70 (−16%); analfabetos: 215 vira 196 (−9%); solteiros: 141 vira 133; construção: 29 vira 27. O ganho é maior justamente nas variáveis com forte padrão espacial, que é onde a ordenação por zona mais ajuda.

**O que custa e o que arrisca.** Custa documentar a ordem (o número da pasta dentro de cada sequência de situação de cada unidade da federação, que as tabelas já trazem em `pasta` e `UF`). Arrisca duas coisas: se a ordem usada não for a do sorteio, o estimador perde a justificativa; e se houver periodicidade no cadastro alinhada com o intervalo de vinte, subestima. A numeração mostra que a ordem é por zona, município e setor, sem periodicidade visível. É a alternativa mais bem fundamentada para variáveis com padrão espacial.

### 11.5 A variância depois da calibração: resíduos em vez de valores

**A ideia.** Os pesos foram calibrados para que 184 totais (idade × sexo × situação × região, e alfabetização por sexo e região) sejam reproduzidos exatamente. Para esses totais, o erro amostral é zero por construção. Para qualquer outra variável, a calibração "fixa" a parte dela que se explica pelas margens e deixa ao acaso só o resto. A variância correta do estimador calibrado é, portanto, a variância do **resíduo** da regressão da variável nas margens, e não a da variável em si. É o resultado clássico de Deville e Särndal: o estimador calibrado é assintoticamente igual ao estimador de regressão generalizada (GREG), e a variância se calcula com os resíduos e = y − x'B, onde B é o coeficiente da regressão ponderada de y nas colunas de calibração.

Na prática: monta-se, por domicílio, o total da variável (y) e o vetor x com o número de pessoas do domicílio em cada uma das 184 células; estima-se B por mínimos quadrados ponderados; calcula-se e; e aplica-se o estimador de conglomerado último aos totais de w·e por pasta.

**O exemplo.** Aqui o efeito é grande e didático:

- população urbana do Nordeste: 193 mil vira **zero**, porque ela é uma das margens calibradas;
- analfabetos de 15 anos e mais: 215 mil vira 34 mil, porque "sabe ler, por sexo e região" é margem, e a idade também; o resíduo é só o que a faixa de 15 anos e mais não determina;
- solteiros de 15 anos e mais: 141 vira 52, porque estado conjugal se explica muito por idade e sexo;
- rendimento alto: 83 vira 65 (−22%), e construção civil 29 vira 26 (−10%): variáveis pouco explicadas pelas margens ganham pouco.

**O que custa e o que arrisca.** Custa reproduzir as células de calibração no cálculo, o que o pacote `survey` faz sozinho: com um objeto de desenho construído com os pesos de desenho e a chamada `calibrate(desenho, ~celulas, totais_publicados)`, as funções `svytotal` e `svymean` passam a usar os resíduos automaticamente. O risco é assumir que as margens de 1965 são exatas; elas têm erro de amostragem próprio (foram estimadas da mesma amostra) e um pouco de erro de processamento, mas ambos são pequenos diante do que a calibração remove. Esta é a alternativa **correta** para os pesos que as tabelas trazem, e a que recomendamos adotar como padrão.

### 11.6 Pesos replicados: jackknife

**A ideia.** Em vez de fórmula, repetição. Constrói-se uma coleção de conjuntos de pesos, cada um simulando "a amostra sem uma pasta": retira-se a pasta i do estrato h e multiplicam-se os pesos das outras n_h − 1 pastas do estrato por n_h/(n_h − 1), para que o estrato continue somando o mesmo. Calcula-se a estimativa com cada conjunto; a dispersão das 817 estimativas em torno da estimativa completa é a variância:

  V_JK(Ŷ) = Σ_h (n_h − 1)/n_h · Σ_i (Ŷ_(hi) − Ŷ)²

```
pasta       peso original   réplica 1 (sem a pasta 1)   réplica 2 (sem a pasta 2) ...
  1 (h=A)        78,8              0                         78,8 · 3/2
  2 (h=A)        78,8           78,8 · 3/2                       0
  3 (h=A)        78,8           78,8 · 3/2                    78,8 · 3/2
  4 (h=B)        80,1             80,1                         80,1
  ...
```

**O exemplo.** Para totais e médias o jackknife dá **exatamente** o estimador de conglomerado último: 29, 83, 215, 141 e 193 mil, os mesmos números. Não é ganho de precisão; é ganho de conveniência: o usuário não precisa saber o que é estrato nem pasta, só multiplicar pelas colunas de peso.

**O que custa.** 817 colunas a mais em 897 mil linhas (uns 6 GB em ponto flutuante), o que é inviável para distribuir. As alternativas de tamanho razoável são o jackknife por grupos aleatórios de pastas (por exemplo, 100 réplicas) ou o bootstrap da subseção seguinte. Com o `survey`, `as.svrepdesign(desenho, type = "JK1")` constrói as réplicas a partir de `censobr_upa` e `censobr_estrato` sem gravar nada.

### 11.7 Pesos replicados: bootstrap de Rao e Wu

**A ideia.** Em cada estrato, sorteiam-se n_h − 1 pastas com reposição entre as n_h sorteadas; os pesos são multiplicados por n_h/(n_h − 1) vezes o número de vezes que a pasta saiu. Repete-se, digamos, 200 vezes. A variância é a dispersão das 200 estimativas. Diferente do jackknife, o bootstrap funciona também para estatísticas não lineares — medianas, quantis, índice de Gini, coeficientes de modelos —, que são o que muita gente quer estimar com esta amostra.

**O que custa.** 200 colunas de peso (cerca de 1,4 GB) ou, melhor, a instrução de gerá-las: `as.svrepdesign(desenho, type = "subbootstrap", replicates = 200)`. Se a compilação com a amostra de 25% for distribuir pesos replicados, esta é a forma a escolher, e um número de réplicas entre 200 e 500.

### 11.8 Domínios pequenos e o que não fazer

A estimativa de um domínio usa as pastas que têm alguém do domínio, mas a variância usa todas as pastas do estrato (as sem ninguém entram com zero), e é assim que deve ser: um município com uma pasta sorteada é, para fins de variância, um domínio que poderia ter recebido outra pasta e não recebeu nenhuma. Duas regras práticas:

- Um domínio precisa de pastas em pelo menos dois estratos ou de várias pastas num estrato para ter erro-padrão calculável; com uma pasta o erro é indefinido, e com duas é uma estimativa com um grau de liberdade.
- Estimativas por município a partir desta amostra não devem ser publicadas. A amostra foi desenhada para regiões e situações; para municípios ela é uma ou duas pastas de um bairro. O caminho para estimativas locais é a amostra de 25%, que tem dezenas de pastas por município médio, ou modelos de pequenas áreas, que estão fora do escopo deste pipeline.

### 11.9 O que muda com a amostra de 25%

A amostra de 25% sobreviveu para 17 unidades da federação, com a mesma chave de questionário (distrito, pasta, boletim). O seu desenho é outro e mais simples: um domicílio em quatro, sistematicamente, dentro de cada setor — quase uma amostra aleatória simples estratificada por setor, com efeito de desenho perto de 1. Na compilação, as duas amostras se combinam: onde a de 25% existe, ela domina; onde não existe, a de 1,27% é tudo o que há. Três consequências para o desenho:

- O Distrito Federal volta a ter os seus boletins: a truncagem das duas pastas deixa de importar.
- Nas 17 unidades da federação, os erros-padrão caem para uma fração dos daqui, e a estratificação passa a ser por setor.
- A amostra de 1,27% continua sendo a única nacional, e a única em que se pode reproduzir 1965. Para estimativas nacionais consistentes com as publicadas, ela é a referência; para estimativas estaduais e locais, a de 25%.

### 11.10 Recomendação e ordem

1. **Adotar a variância pós-calibração como padrão** (11.5). É a variância correta dos pesos que as tabelas trazem, dá o maior ganho e o `survey` a calcula com uma chamada. Custo: reproduzir as 184 células no objeto de desenho, o que o passo 11 do pipeline pode passar a fazer.
2. **Oferecer o estimador de diferenças sucessivas como alternativa documentada** (11.4) para variáveis com padrão espacial, com a ordem do cadastro explicada.
3. **Manter os 16 estratos** como estrato oficial e documentar a alternativa por unidade da federação (11.3).
4. **Deixar a correção finita de fora** até que a componente da primeira etapa entre junto (11.2).
5. **Distribuir pesos de bootstrap na compilação** (11.7), 200 a 500 réplicas, se a compilação quiser poupar o usuário de montar o desenho; caso contrário, documentar a chamada do `survey` que os gera.

Nenhum desses itens muda um número das tabelas atuais; todos mudam quão estreitos são os intervalos de confiança que se publicam com elas, e todos na direção de intervalos mais estreitos e mais honestos.

## 12. Glossário

- **Amostra de 25%**: a amostra geral do Censo de 1960, um domicílio em quatro, com o Boletim de Amostra.
- **Amostra de 1,27%**: subamostra de uma pasta em vinte da amostra de 25%, com que o IBGE publicou os resultados preliminares de 1965. É este arquivo.
- **Boletim de Amostra (CD 2)**: o questionário longo, de um domicílio, aplicado à amostra de 25%.
- **Calibração**: ajuste dos pesos para que a amostra reproduza totais conhecidos; aqui, as margens demográficas de 1965.
- **Coeficiente de variação (CV)**: erro-padrão dividido pela estimativa.
- **Conglomerado**: um grupo de unidades sorteado em bloco; aqui, a pasta.
- **Efeito de desenho (deff)**: variância do desenho real dividida pela de uma amostra aleatória simples do mesmo tamanho.
- **Estrato**: grupo dentro do qual o sorteio foi feito separadamente; aqui, região × grupo de situação da pasta.
- **Pasta**: lote de trabalho de cerca de 250 boletins de amostra, na ordem dos setores; a unidade sorteada.
- **Peso de desenho**: inverso da fração de amostragem, 78,74.
- **Peso integrado**: um peso por domicílio, igual para todas as suas pessoas.
- **Raking**: a forma de calibração usada, que multiplica cada peso de desenho por um fator exp(x'λ).
- **Situação**: urbana, suburbana ou rural, do domicílio ou da pasta.
- **Unidade primária de amostragem (UPA)**: a unidade sorteada na primeira etapa que interessa à variância; aqui, a pasta.
- **Zona fisiográfica**: divisão regional do IBGE dentro de cada estado, usada para ordenar o cadastro.

## 13. Fontes

- IBGE, Serviço Nacional de Recenseamento. *Censo Demográfico: resultados preliminares*. Série Especial, vol. II. Rio de Janeiro, março de 1965 (Biblioteca do IBGE, `liv84480`), pp. 5–6 para o desenho; transcrição dos sete quadros em `references/censo_1960_resultados_preliminares_1965.csv`.
- IBGE, Serviço Nacional de Recenseamento. *Código do Censo Demográfico – 1960* (manual de codificação, 25 p.); *Código para uso da Agência Municipal de Estatística* (236 p.); *Código de Zonas Fisiográficas, Municípios e Distritos, situação em 1º-7-1960* (313 p.). Transcrições em `read_guides/1960_codigo_do_censo.csv` e `read_guides/1960_municipios.csv`.
- IPEA. *Processamento de uma amostra do Censo Demográfico de 1960*, abril de 1969 (repositório do IPEA): a história dos cartões.
- Deville, J.-C. e Särndal, C.-E. (1992). Calibration estimators in survey sampling. *Journal of the American Statistical Association*, 87, 376–382.
- O pipeline: `R/microdata_1960_amostra_127.R`, passos 8 (desenho), 9 (calibração) e 11 (erros amostrais); `references/microdata_1960_amostra_127_preparacao.md`, seções 7 e 8.
