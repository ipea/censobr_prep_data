# A amostra de 25% do Censo de 1960: o desenho amostral

Este guia explica como a amostra de 25% do Censo Demográfico de 1960 foi sorteada, o que isso implica para quem for estimar qualquer coisa com ela, e como calcular um erro-padrão que faça sentido.

Ele é o irmão de [`microdata_1960_amostra_127_desenho_amostral.md`](microdata_1960_amostra_127_desenho_amostral.md), que trata da outra amostra de 1960. Aquele documento traz o vocabulário da época — pasta, setor, quadro urbano, Folha de Coleta, Boletim de Amostra — num glossário, e a engenharia reversa do cadastro de sorteio. **Este aqui não repete nada disso.** Quem não conhece os termos deve começar por lá; quem conhece pode ler este sozinho.

O resumo, para quem tem pressa: o desenho desta amostra é **de uma etapa só**, e por isso é muito mais simples e muito mais preciso que o da amostra de 1,27%. A unidade sorteada é o domicílio, um em quatro, sistematicamente, dentro do setor censitário. Os coeficientes de variação ficam abaixo de 0,1% nos grandes agregados.

---

## 1. O que é esta amostra

O Censo de 1960 teve dois questionários. O **Boletim Geral**, formulário CD 1, foi aplicado a todos os domicílios e perguntava o básico: quem morava ali, sexo, idade, cor, alfabetização. O **Boletim de Amostra**, formulário CD 2, foi aplicado a **um domicílio em cada quatro** e perguntava muito mais — rendimento, migração, fecundidade, curso completo, posição na ocupação, ramo de atividade.

A amostra de 25% é o conjunto dos domicílios que receberam o CD 2. Não é uma amostra tirada depois, para economizar apuração: **é o desenho do censo**, decidido antes do campo. É dela que saíram os volumes definitivos.

A amostra de 1,27%, preparada no estágio irmão, é uma **subamostra desta**: uma pasta em vinte, sorteada em 1965 do cadastro de arquivamento, para apurar depressa alguns resultados preliminares. Toda pessoa da amostra de 1,27% está também nesta — e a comparação registro a registro entre as duas está na seção 9 do documento de preparação.

**Os microdados sobreviveram para dezessete unidades da federação**, que são exatamente aquelas cujos tomos do Volume I foram apurados só pelo Boletim de Amostra: Ceará, Rio Grande do Norte, Paraíba, Pernambuco, Fernando de Noronha, Alagoas, Sergipe, Bahia, Minas Gerais, Serra dos Aimorés, Rio de Janeiro, São Paulo, Paraná, Rio Grande do Sul, Mato Grosso, Goiás e Distrito Federal. Nas outras onze o Boletim Geral foi apurado por completo e a amostra não precisou ser guardada.

---

## 2. Como o sorteio foi feito

A descrição está na seção *Amostragem* da introdução dos tomos do Volume I, e é curta:

> Nas Fôlhas de Coleta C D 7 e C D 8 foram impressas, a intervalos regulares de quatro linhas, as chamadas "Linhas de Amostra". O recenseador aplicava o Boletim de Amostra ao domicílio que coubesse numa dessas linhas.

Três coisas seguem daí, e são o desenho inteiro.

**Primeiro: a unidade sorteada é o domicílio, não a pessoa.** O Boletim de Amostra cobre o domicílio inteiro — todas as pessoas que moravam ali entraram juntas. Isso tem consequência direta na precisão, e é o assunto da seção 6.

**Segundo: a seleção é sistemática, com passo 4.** Não é aleatória simples. O recenseador percorria a Folha de Coleta na ordem em que visitava os domicílios, e a cada quatro linhas caía numa Linha de Amostra. O ponto de partida dentro de cada folha é o que faz a amostra ser aleatória; o passo é fixo.

**Terceiro: a seleção acontece dentro do setor censitário.** A Folha de Coleta é do setor, e o setor é, pela definição do próprio censo, *"área territorial contínua situada num só quadro — urbano, suburbano ou rural — do mesmo distrito administrativo"*. Ou seja: a amostra é **estratificada por setor**, com a estratificação vindo de graça da organização do campo.

Não há sorteio de pastas. Todas as pastas entram. A pasta, aqui, é só a unidade de arquivamento dos boletins — e é por isso que ela nos serve de aproximação do setor, como a seção 4 explica.

---

## 3. O que o arquivo confirma

O arquivo não traz o número do setor. Traz o número da **pasta**, que é o lote de arquivamento, e é dele que se reconstrói o desenho. Três medidas.

**A pasta tem o tamanho de um setor.** São 13.411 pastas para 3.071.284 boletins, mediana de **235 boletins por pasta**, com quartis em 210 e 252. O volume de 1965 descreve a pasta como contendo "cêrca de 250 questionários". Um setor censitário de 1960 tinha por volta de 250 a 300 domicílios, dos quais um em quatro recebeu o CD 2 — de modo que uma pasta corresponde grosso modo a **um conjunto de setores contíguos**, não a um setor só. Isso importa: a pasta é mais grossa que o setor, e o estrato que construímos é, portanto, conservador.

**A pasta está num só município.** Sem exceção, nas 13.411. Isso permite usá-la na estratificação sem contaminar a geografia.

**A fração realizada não é exatamente um quarto.** O fator implícito — população publicada dividida pelos presentes na amostra — vai de **3,668 em Sergipe a 4,441 em Fernando de Noronha**, com 3,915 no conjunto. O volume de 1965 já dizia "aproximadamente 25%". As causas são as de sempre: domicílio fechado, recusa, folha mal preenchida, e o arredondamento da própria regra de quatro linhas em setores pequenos.

---

## 4. O desenho, como o pipeline o escreve

Três colunas, em ambas as tabelas.

### `censobr_upa` — a unidade primária é o domicílio

Todas as pessoas de um domicílio entram ou saem juntas do sorteio. No **boletim individual** (`V101` = 9), que é o morador de domicílio coletivo amostrado pessoa a pessoa pela Lista CD 3, a unidade é a própria pessoa; no **domicílio coletivo**, é o grupo familiar do boletim. Em todos os casos, `censobr_upa` é `censobr_idhousehold`.

### `censobr_estrato` — pasta × situação

A seleção foi sistemática dentro do setor. Como o arquivo não traz o setor, usamos a pasta, que é o que mais perto chega dele — e cruzamos com `V118`, a situação do domicílio, para separar as pastas mistas nas suas partes urbana e rural. Toda pasta está num só município, então o estrato herda o município de graça.

Resultado: **18.400 estratos**, mediana de 193 domicílios, do menor com 1 ao maior com 997. Cinco estratos têm um domicílio só e não medem variância; entram com contribuição zero.

Esta é uma escolha nossa, e é conservadora nos dois sentidos. A pasta é mais grossa que o setor, então estratificamos menos do que o desenho real permitiria — e uma estratificação mais grossa **superestima** a variância, nunca a subestima. Por outro lado, tratar os domicílios do estrato como sorteados independentemente ignora o efeito de ordenação da seleção sistemática, que em geral **reduz** a variância de verdade. As duas coisas puxam para lados opostos, e o saldo é que o erro-padrão publicado é levemente conservador.

### `censobr_fpc` — a correção de população finita

`censobr_fpc` é **0,25**, em todas as unidades. Sorteou-se um domicílio em quatro de uma população finita de domicílios, então a variância leva o fator (1 − f). Não há exceção: em Fernando de Noronha, ao contrário do que acontece na amostra de 1,27%, o sorteio de um em quatro aconteceu normalmente — 76 boletins, 307 pessoas, fator implícito 4,44.

---

## 5. Os dois pesos

### `censobr_weight` — razão à contagem completa por município × situação

Este é o peso final. É a razão entre a população que a contagem completa apurou e a que a amostra encontrou, célula a célula, com a célula sendo **município × situação**.

Duas coisas a notar.

**Não precisa de solver.** Na amostra de 1,27% as células de calibração eram de pessoa — sexo por faixa de idade — e um domicílio cruzava muitas delas, o que obrigava ao Newton de Deville–Särndal. Aqui cada domicílio pertence a exatamente uma célula, e a calibração é razão em forma fechada.

**A âncora é externa.** É a Sinopse Preliminar, a contagem completa publicada por município e situação — e é exatamente o que o IBGE declarou ter usado nestas dezessete unidades: *"o processo de estimativa de razão baseou-se na população urbana e rural constante das Sinopses Preliminares"*. O que fazemos é refinar o nível: o IBGE calibrou por unidade da federação, nós por município.

O fator vai de **1,18 a 8,02**, com mediana **3,95**.

**O colapso.** Célula magra dá fator instável, e o remédio é agregar. A regra tem dois degraus, e o princípio é que a âncora municipal não se abandona:

1. A célula de situação vira **município inteiro** quando o seu fator sai de [2; 8], quando o universo é menor que 100, ou quando o universo tem uma situação que a amostra não alcançou. Este terceiro caso é o de Cristalândia, em Goiás, cujos 2.345 habitantes urbanos não têm um domicílio urbano sorteado: sem o colapso, essa população não teria a que se prender.
2. Só o município **sem universo nenhum** desceria para a unidade da federação × situação. Nenhum desce.

São 9.958 domicílios colapsados, 0,32% do total. Uma primeira versão da regra mandava todo município de fator baixo direto para o nível do estado, e isso inflava Alpinópolis, Itueta e Abadia dos Dourados em 23 mil pessoas — porque a elas o fator do estado simplesmente não se aplica. O erro foi encontrado na validação.

### `censobr_weight_ibge` — o método publicado, ao pé da letra

Razão a **unidade da federação × urbana/rural**, com **peso inteiro** — 3, 4 ou 5 — sorteado para fechar o total exato, com semente fixa. É o método que os tomos descrevem: *"pesos inteiros próximos à razão fracionária, atribuídos aleatoriamente"*.

Serve a dois propósitos: reproduz a Série Regional inclusive nos seus artefatos de arredondamento, e mede quanto o refinamento municipal vale. Fecha exato nas dezessete unidades.

### `censobr_weight_desenho`

O peso nominal do desenho, 4. Serve de referência; não se usa em estimativa.

### Qual usar

**`censobr_weight`**, por padrão. É o mais fino e o que reproduz melhor a geografia. Use `censobr_weight_ibge` quando quiser reproduzir exatamente um número publicado pelo IBGE, ou quando quiser medir o efeito do refinamento.

Duas ressalvas a declarar.

**Serra dos Aimorés** é a única unidade cuja âncora não é contagem completa. Os tomos de Minas e do Espírito Santo excluem a região do litígio dos dois estados — *"a exemplo do que se fez em 1940 e 1950"* — e não publicam tabela própria para ela. A única publicação que a traz é a Série Nacional, e é a ela que a região calibra. Como essa linha da Série Nacional foi ela própria estimada com esta amostra, há circularidade, e ela fica dita.

**Alto Garças, em Mato Grosso**, tem 4.630 habitantes publicados e **nenhum domicílio sorteado**. Com `censobr_weight` essa população não tem a que se prender, e Mato Grosso fecha 4.630 pessoas abaixo do publicado. Com `censobr_weight_ibge`, que é por estado, ela se redistribui e o total fecha. É buraco de cobertura da amostra, não defeito do método.

---

## 6. Como calcular o erro-padrão

A variância de um total estimado é a dispersão dos totais expandidos entre os domicílios do estrato, com a correção de população finita:

$$V(\hat Y) \;=\; \sum_h (1 - f)\,\frac{n_h}{n_h - 1}\sum_{i \in h}\left(w_i y_i - \bar t_h\right)^2, \qquad f = \tfrac14$$

onde $h$ indexa os estratos, $i$ os domicílios do estrato, $n_h$ o número de domicílios do estrato, $w_i$ o peso do domicílio, $y_i$ o total da variável **naquele domicílio** (não na pessoa) e $\bar t_h$ a média de $w_i y_i$ no estrato.

Em R, com o pacote `survey`:

```r
library(survey); library(arrow); library(dplyr)

p <- open_dataset("data_raw/microdata/1960/amostra_25") |>
  filter(...) |> collect()

d <- svydesign(ids     = ~censobr_upa,
               strata  = ~censobr_estrato,
               weights = ~censobr_weight,
               fpc     = ~censobr_fpc,
               data    = p)

# um total, com erro-padrao
svytotal(~I(!V202 %in% c(3, 4)), d)

# uma proporcao
svymean(~I(V211 %in% c(0, 1)), subset(d, V204B >= 5), deff = TRUE)

# um dominio
svyby(~I(V211 %in% c(2, 3)), ~code_state, d, svytotal, vartype = c("se", "cv"))
```

O pipeline calcula os mesmos números à mão, para não acrescentar dependência, em `sampling_errors_1960_amostra_25()`. A saída fica em `data_raw/microdata/1960/amostra_25/erros_amostrais.csv`.

---

## 7. O que os números dizem

| domínio | estimativa | erro-padrão | CV | efeito de desenho |
|---|---|---|---|---|
| pessoas | 58.638.580 | 16.035 | 0,027% | — |
| presentes | 57.948.156 | 15.886 | 0,027% | — |
| população urbana | 25.941.017 | 10.785 | 0,042% | 2,74 |
| população rural | 32.007.139 | 11.664 | 0,036% | 3,19 |
| analfabetos de 15 anos e mais | 13.520.687 | 6.755 | 0,050% | 1,49 |
| crianças de 0 a 4 anos | 7.413.679 | 4.994 | 0,067% | 1,31 |
| pessoas com rendimento | 36.687.921 | 11.478 | 0,031% | 3,27 |

**Esta amostra é enormemente precisa.** Os coeficientes de variação ficam entre 0,027% e 0,067% nos grandes agregados. Isso é o que se espera de um domicílio em quatro, com 3,07 milhões de domicílios sorteados: a correção de população finita sozinha já retira um quarto da variância, e o que sobra é dividido por três milhões.

Para dar escala: nos mesmos domínios, a amostra de 1,27% tem coeficientes de variação entre 1% e 3% — **de vinte a cinquenta vezes maiores**. Ela é vinte vezes menor e sofre um segundo estágio de conglomeração, em que a pasta inteira entra ou não entra.

**O efeito de desenho fica entre 1,31 e 3,27.** Ele mede quantas vezes esta amostra é menos precisa que um sorteio pessoa a pessoa do mesmo tamanho. Está acima de um porque **o domicílio entra inteiro**: pessoas do mesmo domicílio se parecem — moram no mesmo lugar, têm renda correlacionada, a mesma situação urbana ou rural —, e isso custa precisão.

O padrão dos valores é informativo. O efeito é **menor** nas variáveis que variam muito dentro do domicílio (crianças de 0 a 4 anos, 1,31; analfabetismo, 1,49) e **maior** nas que são praticamente constantes dentro dele (urbano ou rural, 2,74 e 3,19). No limite, uma variável que fosse idêntica para todos os moradores de um domicílio teria efeito de desenho igual ao tamanho médio do domicílio, que aqui é 4,9.

Em domínios que são quase toda a população o efeito de desenho perde sentido — o denominador tende a zero — e fica ausente da tabela.

**Uma advertência.** Esse erro-padrão é do **desenho**. Ele não cobre erro de cobertura, erro de resposta nem erro de transcrição. O último não é desprezível: a comparação com a amostra de 1,27%, que transcreveu os mesmos questionários de forma independente, mostra desacordo de 8,65% no tipo de construção e 3,48% na instalação sanitária. Um intervalo de confiança de 0,03% não diz nada sobre isso.

---

## 8. Em que nível a amostra é representativa

A amostra foi desenhada para dar resultados por **unidade da federação e situação**, e é isso que os volumes publicam.

Ela reproduz bem o **município**, porque `censobr_weight` calibra nesse nível — mas reproduzir o total não é o mesmo que ser representativa: dentro do município, o que a amostra diz sobre composição vem de um sorteio de um em quatro dos seus domicílios, e num município pequeno isso são poucas dezenas de domicílios.

Abaixo do município, **não use**. O guia de leitura anota isso na própria `V116`: *"não há rótulos identificadores para os códigos de municípios — esta amostra não é representativa para essa unidade geográfica"*. O distrito (`code_district_1960`) está na tabela porque é informação do registro, não porque sirva de domínio de estimação.

---

## 9. Comparado com a amostra de 1,27%

As duas amostras de 1960 têm desenhos diferentes, e vale ter isso claro:

| | amostra de 25% | amostra de 1,27% |
|---|---|---|
| etapas | uma | duas |
| unidade sorteada | domicílio | pasta, e dentro dela o domicílio da amostra de 25% |
| fração | 1/4 | 1/20 da de 25%, isto é ~1,27% |
| estratos | pasta × situação (18.400) | UF × grupo de situação (75) |
| correção finita | 1/4 | 1/20, mais o termo da etapa dos domicílios |
| unidades da federação | 17 | 28 |
| CV típico | 0,03% a 0,07% | 1% a 3% |
| efeito de desenho típico | 1,3 a 3,3 | 6 a 250 |

O efeito de desenho da amostra de 1,27% chega a 250 em domínios definidos por região e situação, porque ali a pasta é quase toda urbana ou quase toda rural — e a pasta é justamente o que se sorteia. Aqui esse problema não existe: o que se sorteia é o domicílio.

Em compensação, a amostra de 1,27% **cobre as 28 unidades da federação** e esta cobre dezessete. É por isso que a compilação das duas — que é um estágio à parte, ainda por fazer — usará esta onde ela existe e aquela onde não existe.

---

## 10. Limitações e cuidados

1. **O estrato é a pasta, não o setor.** A pasta é mais grossa. O erro-padrão sai levemente conservador.
2. **A seleção foi sistemática, e o estimador a trata como aleatória dentro do estrato.** Isso também é conservador, quando a ordenação da folha carrega informação — e ela carrega, porque o recenseador percorria o setor geograficamente.
3. **A fração realizada não é 1/4**, mas 1/3,92 no conjunto, com variação por unidade. A correção finita usa 1/4, que é o desenho; o desvio está absorvido no peso.
4. **Cinco estratos têm um domicílio** e não contribuem com variância. É 0,03% dos estratos.
5. **Alto Garças não tem domicílio sorteado**, e com `censobr_weight` a sua população não é representada.
6. **O erro-padrão não cobre erro de transcrição**, que a comparação com a amostra de 1,27% mostra ser da ordem de alguns por cento em variáveis do domicílio.
7. **Não estime abaixo do município.**

---

## 11. Fontes

- IBGE, *Censo Demográfico de 1960*, Série Regional, Volume I, seção *Amostragem* da introdução de cada tomo — a descrição do sorteio e do método de estimativa de razão.
- IBGE, *Censo Demográfico de 1960 — Brasil*, Série Nacional vol. I, em [`fontes_1960/1960_serie_nacional_vol1_brasil.pdf`](fontes_1960/1960_serie_nacional_vol1_brasil.pdf).
- IBGE, *Resultados Preliminares do Censo Demográfico de 1960*, Série Especial vol. II, março de 1965, em [`fontes_1960/1965_resultados_preliminares_vol2.pdf`](fontes_1960/1965_resultados_preliminares_vol2.pdf) — descreve o desenho da subamostra de 1,27% e, de passagem, o da amostra geral.
- IBGE, Serviço Nacional de Recenseamento, *Código do Censo Demográfico — 1960*, em [`fontes_1960/1960_codigo_do_censo_demografico.pdf`](fontes_1960/1960_codigo_do_censo_demografico.pdf).
- Sinopse Preliminar do Censo Demográfico de 1960, por unidade da federação — a âncora de `censobr_weight`.
- O guia irmão, [`microdata_1960_amostra_127_desenho_amostral.md`](microdata_1960_amostra_127_desenho_amostral.md), para o vocabulário, o cadastro de pastas e a engenharia reversa do sorteio de 1965.
