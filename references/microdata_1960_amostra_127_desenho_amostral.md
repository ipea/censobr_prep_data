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
- **As pastas rurais e mistas ficam fora dessa grade**, com espaçamentos irregulares. São sequências sistemáticas próprias, intercaladas com as urbanas na numeração: a assinatura de estratos de situação sorteados separadamente.
- **O peso realizado** bate com o nominal. Dividindo a população presente publicada em 1965 pela nossa contagem, o fator implícito é 79,2 no Leste, 79,4 no Sul e 79,5 no Nordeste, 80,0 no urbano e 78,6 no rural; o nominal é 80.

### O cadastro reconstruído: a prova direta

A evidência decisiva veio de onde não se esperava. A amostra de 25% do Censo de 1960, que o `censobr` distribui na compilação, **guarda o número da pasta de cada domicílio**. Como ela é 25% de tudo, os seus números de pasta são o **cadastro inteiro** — a lista de onde as 814 foram sorteadas —, e não apenas as sorteadas. Para as 17 unidades da federação em que a amostra de 25% sobreviveu, isso permite refazer o sorteio e olhá-lo por dentro.

O cadastro assim reconstruído tem **13.411 pastas**. Três fatos saem dele imediatamente:

1. **Todas as 671 pastas que a subamostra tem nessas 17 unidades da federação estão no cadastro.** Nenhuma pasta "inventada", nenhuma chave inconsistente.
2. **A razão entre o cadastro e as sorteadas é 20 em todas as unidades da federação**, de 18,5 a 21,1, mediana 19,9. É a confirmação direta e independente do "uma pasta em vinte".
3. **O cadastro é ordenado por zona fisiográfica.** Em São Paulo, percorrendo as 3.140 pastas na ordem do número, a zona fisiográfica muda exatamente 70 vezes, e São Paulo tem 70 zonas: cada zona é um bloco contíguo. Em Minas, 56 mudanças para 56 zonas; na Bahia, 26 para 26. A situação do domicílio, ao contrário, muda 1.048 vezes em São Paulo, embora só existam 4 grupos: as pastas urbanas, rurais e mistas estão intercaladas ao longo de todo o cadastro.

Com o cadastro em mãos, a pergunta "qual era o estrato?" vira uma pergunta com resposta. Se o sorteio foi sistemático de um em vinte dentro de um estrato, então, **ordenando o cadastro daquele estrato e numerando as pastas de 1 em diante, as sorteadas devem cair de 20 em 20**. Testamos cada estratificação candidata pela proporção de espaçamentos exatamente iguais a 20:

| estratificação candidata | estratos | pares medidos | espaçamento exatamente 20 | entre 19 e 21 |
|---|---|---|---|---|
| **unidade da federação × situação (4 grupos)** | 61 | 612 | **77,0%** | **90,2%** |
| unidade da federação × urbana/rural/mista (3 grupos) | 48 | 625 | 74,4% | 87,4% |
| região × situação (4 grupos) | 16 | 655 | 72,2% | 84,9% |
| unidade da federação, sem situação | 17 | 654 | 12,1% | 18,3% |
| região, sem situação | 4 | 667 | 11,8% | 18,1% |
| zona fisiográfica, sem situação | 321 | 413 | 18,4% | 23,5% |

A leitura é direta. Sem a situação, o padrão desaparece (12%, que é o acaso). Com a situação, ele aparece. E ele é mais nítido com a unidade da federação do que com a região — a diferença entre 77,0% e 72,2% são exatamente as quebras que aparecem quando se emendam as unidades da federação de uma mesma região numa sequência só, prova de que cada unidade da federação recomeçava a série. Estratos mais finos que isso (zona × situação) não melhoram de forma interpretável, porque deixam quase todo estrato com uma pasta só.

Olhados de perto, os estratos são bonitos de ver. Cada um começa num ponto próprio, sorteado ao acaso, e daí anda de vinte em vinte:

```
Bahia, cidade grande  (cadastro de  153 pastas, 8 sorteadas):  12  32  52  72  92 112 132 152
Bahia, rural          (cadastro de  427 pastas, 21 sorteadas):  12  32  52  72  92 112 132 152 172 192 212 232 252 ...
Bahia, mista          (cadastro de  642 pastas, 33 sorteadas):   6  26  46  66  86 106 126 146 166 186 206 226 246 ...
São Paulo, cidade grande (cadastro de 1.074, 54 sorteadas):     19  39  59  79  99 119 139 159 179 199 219 239 259 ...
Minas Gerais, rural   (cadastro de  531 pastas, 26 sorteadas):   2  21  41  61  81 101 121 141 161 181 201 ...
```

Os inícios — 12, 12, 6, 19, 2 — são o "início das séries aleatório" que o volume de 1965 menciona em uma linha e nunca explica. A razão cadastro/sorteadas por estrato tem mediana 19,9, com quartis 19,1 e 21,3.

O mesmo teste responde a outra pergunta que estava em aberto: **como o IBGE separava a "cidade de 100 000 e mais habitantes"?** Basta trocar a definição do grupo e ver qual delas produz a progressão mais limpa:

| definição de "cidade grande" | espaçamento exatamente 20 |
|---|---|
| **população urbana do município ≥ 100 mil** | **77,0%** |
| população urbana ≥ 200 mil | 75,2% |
| população total do município ≥ 100 mil | 72,5% |
| população urbana ≥ 50 mil | 68,9% |
| não separar cidades grandes (3 grupos) | 74,4% |

A definição que usamos — pasta puramente urbana de município com população urbana de 100 mil ou mais no Anuário de 1961 — é a que melhor reproduz o sorteio, e o grupo "cidade grande" é justamente o de ajuste mais alto (92% dos espaçamentos exatos, contra 70% a 79% dos outros três). O que sobra de imperfeição vem de classificarmos individualmente alguma pasta de forma diferente do IBGE, o que desloca os postos em uma unidade: 90% dos espaçamentos caem em 19, 20 ou 21.

Conclusão: o desenho de 1965 está confirmado e detalhado pelo próprio dado. Sorteio sistemático, uma pasta em vinte, início aleatório por estrato, **estratos definidos pela unidade da federação cruzada com os quatro grupos de situação**, sobre um cadastro ordenado por zona fisiográfica dentro de cada unidade da federação.

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
- `censobr_estrato` — o **estrato**: a unidade da federação cruzada com o grupo de situação da pasta, como a seção 5 demonstrou. São **47 estratos**, dos quais 39 são de unidade da federação (rótulo `UF 60 - cidade grande`, por exemplo) e 8 são de região (rótulo `Leste - rural`), pela regra de colapso explicada abaixo. Cada estrato tem de 2 a 72 pastas, mediana 12.

**Como cada pasta foi classificada.** Pela situação dos seus próprios boletins: mista se tem urbanos e rurais; rural se só tem rurais; e as puramente urbanas se dividem pelo tamanho da cidade. O corte de 100 mil habitantes não se deduz da amostra — um município que recebeu uma pasta inteira já parece ter 90 mil habitantes, e o cálculo acusaria 216 municípios acima de 100 mil — e vem de fora: a população urbana de cada município no Anuário Estatístico do Brasil de 1961, casada pelo código de município (`read_guides/1960_municipios.csv`). Cidade grande é a pasta puramente urbana de município com população urbana de 100 mil ou mais: 34 municípios, de São Paulo e Rio de Janeiro (3,3 e 3,2 milhões) a Olinda e Teresina (100 mil), todos com pasta na amostra. O teste do cadastro (seção 5) confirma que é este o corte que o IBGE usou.

**A regra de colapso.** Um estrato com uma pasta só não permite medir variância: não há com o que comparar. Onde isso acontece, o grupo de situação inteiro daquela região vira um estrato único. São oito casos, todos previsíveis: as unidades da federação pequenas do Norte e Centro-Oeste e do Leste, que receberam uma ou duas pastas por grupo. Esses oito estratos são mais grossos que o desenho, o que **aumenta** o erro-padrão estimado — é o lado seguro do erro.

Para referência, o agrupamento mais grosso (região × situação, 16 estratos) que o pipeline usava antes:

| região | cidade grande | urbana menor | mista | rural |
|---|---|---|---|---|
| Leste | 72 | 42 | 108 | 63 |
| Sul | 64 | 63 | 92 | 70 |
| Nordeste | 22 | 20 | 64 | 70 |
| Norte e Centro-Oeste | 6 | 12 | 29 | 20 |

As regiões são as do volume de 1965: Nordeste (MA, PI, CE, RN, PB, PE, FN, AL), Leste (SE, BA, MG, Serra dos Aimorés, ES, RJ, GB), Sul (SP, PR, SC, RS) e Norte e Centro-Oeste (RO, AC, AM, RR, PA, AP, MT, GO, DF).

**O que é fato e o que é escolha.** É fato documentado que o IBGE usou quatro grupos de situação e um critério geográfico. É fato demonstrado pelo cadastro (seção 5) que o critério geográfico era a unidade da federação e que o corte de cidade grande era a população urbana municipal. Continua sendo escolha nossa (1) a regra de colapso dos estratos de uma pasta, e (2) a extensão do critério às onze unidades da federação em que a amostra de 25% não sobreviveu e o cadastro não pode ser reconstruído — ali a classificação das pastas usa a mesma regra, mas sem a verificação.

**Por que isso basta para o erro-padrão.** Para estimar variância de uma amostra de conglomerados é preciso saber (a) quais observações foram sorteadas juntas — a pasta — e (b) dentro de que grupos o sorteio foi independente — o estrato. Errar o estrato para mais grosso (juntar estratos que o IBGE separava) superestima a variância, porque atribui ao acaso diferenças que na verdade estavam controladas pela estratificação.

**A pasta é a última unidade sorteada, e não há unidade secundária.** Uma dúvida natural é se o domicílio não seria a unidade secundária de amostragem. Não é, e a razão é que neste desenho a ordem das etapas é invertida em relação ao livro-texto. No desenho comum, sorteiam-se conglomerados e depois unidades dentro deles. Aqui, o domicílio foi sorteado **primeiro**, no campo, um em cada quatro na folha de coleta; as pastas foram formadas **depois**, no órgão central, com os boletins que já estavam na amostra; e o sorteio de uma pasta em vinte veio por último. Dentro de uma pasta sorteada **não há subamostragem**: todos os seus boletins entram. Por isso a pasta é a unidade primária para efeito de variância — é a última coisa sorteada e é tomada inteira — e o domicílio não é uma unidade secundária, mas a unidade da etapa anterior. A consequência prática está na seção 11.2: a aleatoriedade da etapa dos domicílios é uma componente de variância à parte, que o estimador usual não inclui.

(A compilação antiga do `censobr` traz colunas `censobr_upa` e `censobr_usa` com outra convenção: nos registros da amostra de 25% a unidade primária é o próprio domicílio, e nos registros de 1,27% é o município. Nenhuma das duas corresponde ao desenho descrito aqui; as colunas deste estágio substituem essa convenção.)

## 8. Como calcular um erro-padrão, e o que ele diz

**Por que não tratar as 897 mil linhas como 897 mil sorteios.** As pessoas de uma pasta são vizinhas: mesmos setores, mesmo bairro ou mesma zona rural, mesma situação. Se a pasta sorteada é um bairro operário, ela traz 1.100 pessoas parecidas; a próxima pasta, 40 posições adiante no cadastro, pode ser outro mundo. A informação que a amostra contém sobre o país é, em boa medida, a informação de 817 pastas, não de 897 mil pessoas. Quem calcula o erro-padrão como se fossem sorteios independentes publica intervalos de confiança várias vezes estreitos demais.

**O estimador.** Para um total Y estimado por Ŷ = Σ w·y, calcula-se em cada pasta o total ponderado t = Σ w·y das suas pessoas, e em cada estrato h com n_h pastas a variância entre os totais das pastas:

  V(Ŷ) = Σ_h n_h/(n_h − 1) · Σ_i (t_hi − t̄_h)²

multiplicada pela **correção de população finita** (1 − 1/20) = 0,95, que é a fração de pastas sorteadas em cada estrato. Isto é o estimador de "conglomerado último" (ultimate cluster): a variância vem inteiramente da dispersão entre pastas dentro de cada estrato. Dois detalhes: as pastas que não têm ninguém do domínio estimado entram com total zero, e é por isso que n_h é o número de pastas do estrato na amostra toda, e não só das que têm o domínio; e a calibração é ignorada no cálculo, o que é conservador (seção 11.5).

O passo 11 do pipeline faz essa conta à mão, para que o cálculo não dependa de pacote externo. Que ela está certa se verifica com o `survey`, que está no `renv` do projeto: `svydesign(ids = ~censobr_upa, strata = ~censobr_estrato, weights = ~censobr_weight, fpc = ~I(rep(1/20, .N)))` seguido de `svytotal` devolve os mesmos números até o último dígito — 298.019 no Leste, 261.593 no Nordeste, 188.363 no Norte e Centro-Oeste, 325.023 no Sul. O script da conferência é `references/conferencia_desenho_amostral_1960.R`.

**O efeito de desenho.** É a razão entre a variância assim calculada e a que uma amostra aleatória simples de pessoas do mesmo tamanho teria. Diz "quantas vezes menos precisa" a amostra é do que parece. Um efeito de desenho 10 numa célula com 4.810 pessoas significa que ela vale o que valeriam 481 sorteios independentes.

**O que os números dizem.** Para a população presente, com os 16 estratos:

| domínio | estimativa | erro-padrão | coeficiente de variação | efeito de desenho |
|---|---|---|---|---|
| Brasil, urbana | 32.471.377 | 504.122 | 1,55% | 186 |
| Brasil, rural | 37.647.694 | 555.285 | 1,47% | 226 |
| Leste | 24.659.232 | 298.019 | 1,21% | 71 |
| Sul | 24.445.902 | 325.023 | 1,33% | 85 |
| Nordeste | 15.524.609 | 261.593 | 1,69% | 72 |
| Norte e Centro-Oeste | 5.489.328 | 188.363 | 3,43% | 90 |
| Norte e Centro-Oeste, urbana | 2.242.836 | 203.845 | 9,09% | 245 |

Os efeitos de desenho de 70 a 260 nesses domínios grandes assustam, e têm uma razão simples: a situação e a região são atributos da pasta inteira. Estimar quanta gente mora no urbano do Nordeste é contar quantas pastas urbanas foram sorteadas no Nordeste e o tamanho de cada uma — e isso varia de sorteio para sorteio muito mais do que a contagem de pessoas sugere. Nas 176 células do quadro 1 (região × situação × sexo × idade), onde a variável de interesse varia dentro das pastas, o efeito de desenho tem mediana 6,0 e o coeficiente de variação mediana 3,5%, máximo 11,6%. Um exemplo completo, mulheres do urbano do Nordeste:

| faixa de idade | estimativa | erro-padrão | CV | efeito de desenho | pessoas na amostra |
|---|---|---|---|---|---|
| 0 a 4 | 417.327 | 18.072 | 4,3% | 10,1 | 5.294 |
| 5 a 9 | 381.630 | 16.584 | 4,4% | 9,3 | 4.810 |
| 20 a 24 | 286.222 | 10.343 | 3,6% | 4,8 | 3.582 |
| 40 a 49 | 240.804 | 8.884 | 3,7% | 4,2 | 3.039 |
| 60 a 69 | 101.760 | 5.817 | 5,7% | 4,3 | 1.277 |
| 70 e mais | 67.782 | 4.224 | 6,2% | 3,4 | 837 |

Os efeitos são maiores nas crianças (famílias grandes se concentram em pastas) e menores nos idosos. Uma célula dessas, que com 4.810 pessoas pareceria ter um erro relativo de 1,4% se fosse aleatória simples, tem 4,4%.

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

### 11.2 A correção de população finita: adotada

**A ideia.** Se uma amostra tomasse todas as pastas do cadastro, não haveria erro amostral nenhum. Tomando uma fração f delas, a variância de um total é proporcional a (1 − f): sortear 5% das pastas deixa 95% do "espaço" para variar. A correção multiplica a variância por (1 − 1/20) = 0,95, e o erro-padrão por 0,975.

**A dúvida que havia.** A amostra tem duas etapas, e — como a seção 7 explica — elas estão em ordem invertida: primeiro o domicílio (um em quatro, no campo), depois a pasta (uma em vinte, no escritório). Decompondo a variância total em relação à população de 1960:

  V(Ŷ) = V₁ + E[V₂]

onde V₁ é a variância de estimar a população a partir da amostra de 25% **inteira**, e V₂ é a variância de estimar a amostra de 25% a partir das pastas sorteadas. O estimador de conglomerado último mede E[V₂]; a correção de população finita se aplica a ele. A pergunta era se valia a pena aplicar a correção enquanto V₁ ficava de fora — se as duas omissões se compensassem, o melhor seria não mexer em nenhuma.

**A medida resolveu.** V₁ é a variância de uma amostra sistemática de um em quatro, com 17,5 milhões de pessoas e efeito de desenho perto de 1. O coeficiente de variação que ela produz para um total é de **0,02%** para uma proporção de 50% e **0,21%** para uma de 1%, contra os 3,5% que o nosso estimador mede. Em variância, V₁ vale entre 0,003% e 0,3% de E[V₂] — três ordens de grandeza abaixo dos 5% da correção finita. Não há compensação nenhuma: ignorar a correção era inflar o erro-padrão em 2,5% de graça.

**A decisão: a correção entra**, com f = 1/20 em todos os estratos, e V₁ continua de fora, documentado. O valor nominal da fração é o do desenho declarado em 1965, e o cadastro reconstruído o confirma (razão cadastro/sorteadas de 19,9, quartis 19,1 e 21,3). Os erros-padrão de toda a seção 8 já trazem a correção: o do Nordeste, por exemplo, caiu de 268.389 para 261.593.

### 11.3 Estratos mais finos: o que a mudança para unidade da federação × situação fez

**O que mudou.** Até a demonstração da seção 5, `censobr_estrato` era região × situação, 16 estratos, por prudência: não se sabia qual era o critério geográfico do IBGE e a região era a aposta segura. Com o cadastro reconstruído, sabe-se: o critério era a unidade da federação. O pipeline passou a usar 47 estratos (39 de unidade da federação, 8 de região, pela regra de colapso da seção 7).

**A intuição.** O estrato diz de que grupo de pastas a variação "conta". Com região × situação, duas pastas urbanas menores do Ceará e do Maranhão estavam no mesmo estrato, e a diferença entre elas — que é, em boa parte, a diferença entre Ceará e Maranhão — entrava no erro-padrão. Mas essa diferença não existia no sorteio: cada unidade da federação teve a sua própria série sistemática, com o seu próprio início. Atribuí-la ao acaso era inflar a variância.

**O efeito, medido.** Modesto no agregado e grande onde a estratificação mais importava:

| domínio | erro-padrão com 16 estratos | com 47 estratos | razão |
|---|---|---|---|
| Norte e Centro-Oeste, total | 218.714 | 193.256 | 0,88 |
| Norte e Centro-Oeste, rural | 212.708 | 186.442 | 0,88 |
| Nordeste, urbana | 192.846 | 184.793 | 0,96 |
| Brasil, rural | 576.427 | 569.710 | 0,99 |
| Leste, rural | 316.776 | 326.130 | 1,03 |

Nas 176 células do quadro 1 a razão vai de 0,83 a 1,03, com mediana 1,00. Os poucos domínios em que o erro-padrão **sobe** não são um erro: o estimador de variância é ele próprio uma variável aleatória, e estratos mais finos têm menos graus de liberdade, o que o torna mais instável. A justificativa da mudança não é o ganho, é a correspondência com o desenho real.

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


**Como se faz no R.** O pacote `survey` sozinho não constrói pesos de diferenças sucessivas; ele os *consome*, via `svrepdesign(type = "successive-difference")`. Quem os constrói a partir de um desenho é o pacote `svrep`, com `as_sdr_design()`. A receita, com as colunas destas tabelas:

```r
library(survey); library(svrep)

# 1. a ordem do sorteio: o numero da pasta dentro da UF e a ordem do cadastro (secao 5)
pessoas$ordem_cadastro <- as.integer(sub(".*-", "", pessoas$censobr_upa))
pessoas <- pessoas[order(pessoas$censobr_estrato, pessoas$ordem_cadastro), ]

# 2. o desenho como de costume
desenho <- svydesign(ids = ~censobr_upa, strata = ~censobr_estrato,
                     weights = ~censobr_weight, data = pessoas)

# 3. os pesos de diferencas sucessivas (o numero de replicas deve ser multiplo de 4)
sdr <- as_sdr_design(desenho, replicates = 96, sort_variable = "ordem_cadastro",
                     use_normal_hadamard = TRUE)

svytotal(~I(V223B == 351), subset(sdr, !(V202 %in% c(3, 4))), na.rm = TRUE)
```

Dois cuidados. O primeiro é que `as_sdr_design()` exige que os dados estejam **ordenados na ordem do sorteio** antes de construir o desenho, e ordena por estrato e depois pela variável indicada; é por isso que a ordenação vem antes. O segundo é que o método pressupõe que essa ordem seja de fato a do cadastro — o que a seção 5 demonstra para esta amostra, mas que deixaria de valer se alguém reordenasse as tabelas.

Sem os dois pacotes, a fórmula acima é uma linha de `data.table`: dentro de cada estrato, ordenar os totais das pastas pela ordem do cadastro, tomar as diferenças consecutivas ao quadrado, somar e multiplicar por n/(2(n−1)).

**Quanto custa.** Nada, se for pela fórmula. Medido neste arquivo: o estimador de conglomerado último e o de diferenças sucessivas levam **menos de um décimo de segundo cada um** — os dois operam sobre os 817 totais por pasta, não sobre as 897 mil linhas, e a única diferença entre eles é uma ordenação. O que custa é a outra forma de calcular a mesma coisa: construir os **pesos replicados** de diferenças sucessivas (`as_sdr_design` com 96 réplicas) leva cerca de **10 segundos** e produz 96 colunas de peso. Ou seja, se a preocupação for tempo de máquina, a fórmula direta não é motivo para evitar o método; os pesos replicados é que são caros, e só compensam se o usuário for calcular muitas estatísticas não lineares.

### 11.5 A variância depois da calibração: por que ela **não** deve ser o padrão

Esta subseção corrige o que uma versão anterior deste guia recomendava. A correção importa, porque o erro é do tipo que produz intervalos de confiança confortáveis e errados.

**A aritmética.** Os pesos foram calibrados para que 184 totais — idade × sexo × situação × região do quadro 1, e alfabetização por sexo e região do quadro 2 — sejam reproduzidos exatamente. A teoria de Deville e Särndal diz que o estimador calibrado se comporta como um estimador de regressão, e que a sua variância é a variância do **resíduo** da regressão da variável nas colunas de calibração, e não a da variável em si. Calculada assim, a variância cai muito, e para os próprios totais calibrados cai a zero:

| total | erro-padrão usual | pelos resíduos da calibração |
|---|---|---|
| população urbana do Nordeste | 193 mil | **0** |
| analfabetos de 15 anos e mais | 215 mil | 34 mil |
| solteiros de 15 anos e mais | 141 mil | 52 mil |
| rendimento acima de Cr$ 10 mil | 83 mil | 65 mil |
| operários da construção civil | 29 mil | 26 mil |

**Por que o zero é um sinal de alarme, e não um resultado.** A fórmula está certa; a hipótese é que não está. Ela supõe que os totais de calibração são **constantes conhecidas**, sem erro — é o caso normal, em que se calibra a um registro administrativo ou a um censo completo. Aqui não é o caso: os totais de 1965 **foram calculados com esta mesma amostra**. O IBGE pegou as 814 pastas, expandiu-as pelo peso de desenho e publicou o resultado. Calibrar a eles não traz nenhuma informação nova sobre o Brasil de 1960; traz de volta os pesos que o IBGE usou, e repara o dano que o arquivo sofreu depois.

Escrito em uma linha: seja S a amostra íntegra de 814 pastas, e A o nosso arquivo danificado. A calibração faz Ŷ(A) = Ŷ(S) para as margens. O erro que interessa ao usuário é Ŷ(A) − Y (a população verdadeira), que se decompõe em

  [Ŷ(A) − Ŷ(S)] + [Ŷ(S) − Y]

O primeiro colchete é o erro do dano, e é dele que a variância pós-calibração trata. O segundo é o erro amostral da amostra de 1,27%, e **nenhuma calibração a ela mesma o elimina** — é o termo dominante, o que tem efeito de desenho 7 a 250. Para uma margem, o primeiro colchete é zero por construção, e a fórmula devolve zero; mas o segundo continua valendo 193 mil pessoas no caso do urbano do Nordeste.

**A conclusão, portanto, é o contrário do que eu havia escrito.** O padrão continua sendo o estimador de conglomerado último aplicado aos pesos calibrados, que é o que a seção 8 descreve e o que o passo 11 calcula. Ele estima a ordem de grandeza certa de [Ŷ(S) − Y]. A variância pós-calibração responde a outra pergunta, legítima mas diferente: **"quanto o dano do arquivo afastou este número do que a amostra íntegra teria dado?"** — útil para avaliar a reparação, não para publicar um intervalo de confiança sobre o Brasil de 1960.

**Onde ela seria legítima, e isso é uma oportunidade real.** A calibração a totais verdadeiramente conhecidos reduz a variância de verdade, e aí a fórmula dos resíduos é a correta. E esses totais existem: sexo, idade, cor, nacionalidade e alfabetização eram quesitos do **universo** em 1960, não da amostra, e estão publicados por unidade da federação e situação nos tomos do Volume 1 dos resultados definitivos. Calibrar a eles — em vez de calibrar às estimativas amostrais de 1965 — tornaria real a redução de variância, e de quebra ancoraria a amostra na contagem completa em vez de numa tabulação preliminar. É a melhoria de maior valor que resta, e está registrada na seção 11.10.

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

O que está adotado, depois das decisões de 2026-09-15:

1. **Estimador de conglomerado último com correção de população finita**, sobre os 47 estratos de unidade da federação × situação. É o padrão do passo 11, confere com o `survey` até o último dígito, e responde à pergunta do usuário: quanto erra esta amostra em relação ao Brasil de 1960.
2. **Sem variância pós-calibração** (11.5), enquanto a calibração for às tabelas de 1965, que saíram desta mesma amostra.
3. **Sem unidade secundária de amostragem**: a pasta é a última unidade sorteada e o domicílio é a etapa anterior (seção 7).

O que fica como opção documentada, não como padrão:

4. **Diferenças sucessivas** (11.4), para variáveis com padrão espacial. A fórmula é instantânea; os pesos replicados custam 10 segundos e 96 colunas.
5. **Pesos de bootstrap** (11.7), 200 a 500 réplicas, se a compilação quiser poupar o usuário de montar o desenho.

O que fica como tarefa, em ordem de valor:

6. **Calibrar aos totais do universo, e não às estimativas de 1965** (11.5). Sexo, idade, cor, nacionalidade e alfabetização foram apuradas em 100% dos domicílios e publicadas por unidade da federação e situação nos tomos do Volume I. Calibrar a elas torna real a redução de variância, permite usar a fórmula dos resíduos com legitimidade e ancora a amostra na contagem completa. Implica transcrever essas tabelas como se fez com as de 1965.
7. **A componente de variância da primeira etapa** (11.2), se um dia se quiser o rigor completo: vale entre 0,003% e 0,3% do total, e exige o número de domicílios do universo por pasta, que só a amostra de 25% dá.

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

- IBGE, Serviço Nacional de Recenseamento. *Censo Demográfico: resultados preliminares*. Série Especial, vol. II. Rio de Janeiro, março de 1965 (Biblioteca do IBGE, `liv84480`; cópia em `references/fontes_1960/1965_resultados_preliminares_vol2.pdf`), pp. 5–6 para o desenho; transcrição dos sete quadros em `references/censo_1960_resultados_preliminares_1965.csv`.
- IBGE, Serviço Nacional de Recenseamento. *Código do Censo Demográfico – 1960* (manual de codificação, 25 p.); *Código para uso da Agência Municipal de Estatística* (236 p.); *Código de Zonas Fisiográficas, Municípios e Distritos, situação em 1º-7-1960* (313 p.). Transcrições em `read_guides/1960_codigo_do_censo.csv` e `read_guides/1960_municipios.csv`.
- IPEA. *Processamento de uma amostra do Censo Demográfico de 1960*, abril de 1969: a história dos cartões. Cópia em `references/fontes_1960/1969_ipea_processamento_amostra_1960.pdf`.
- IBGE. *Censo Demográfico de 1960 — Favelas, Estado da Guanabara*. Série Especial, vol. IV: as favelas cariocas por zona e circunscrição censitária, a partir dos resultados **definitivos** (amostra de 25% e universo), não desta subamostra. Cópia em `references/fontes_1960/1960_serie_especial_vol4_favelas.pdf`.
- IBGE. *Censo Demográfico de 1960*, Série Regional, Volume I (19 tomos, um por unidade da federação): a seção "Amostragem" da introdução descreve a amostra de 25% e a estimativa de razão em 48 grupos (situação × sexo × posição na família × idade), baseada na população urbana e rural das Sinopses Preliminares. Em `D:\Dropbox\Bancos_Dados\Censos\Censo 1960\4 - Ponderação do Censo de 1960\3-Publicações Originais dos Resultados\`.
- A amostra de 25% do Censo de 1960, na compilação que o `censobr` distribui (`release_legacy`): o cadastro de pastas que permitiu demonstrar os estratos (seção 5).
- Deville, J.-C. e Särndal, C.-E. (1992). Calibration estimators in survey sampling. *Journal of the American Statistical Association*, 87, 376–382.
- O pipeline: `R/microdata_1960_amostra_127.R`, passos 8 (desenho), 9 (calibração) e 11 (erros amostrais); `references/microdata_1960_amostra_127_preparacao.md`, seções 7 e 8.
