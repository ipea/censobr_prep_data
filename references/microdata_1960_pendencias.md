# 1960 — o que ficou em aberto

Anotado em 17/09/2026, depois da reconstrução do guia de distritos e da rodada que
gravou os dois parquets da v1.0.0. Serve para quem voltar a 1960 daqui a algum
tempo — inclusive eu mesmo — não ter de redescobrir onde as coisas pararam.

**O que está fechado**, e não precisa ser revisitado: a compilação das duas
amostras, os pesos, o desenho amostral e os erros-padrão, a geografia, os nomes de
município, a estrutura da Guanabara e a numeração dos distritos em 2.769
municípios. O guia de distritos foi refeito da transcrição integral das 313
páginas do *Código de Zonas Fisiográficas, Municípios e Distritos* de 1960, e os
dois rastreios sobre a base inteira — a regra de que o distrito 01 é a sede e a de
que o distrito homônimo do município é o maior e o mais urbano — não deixaram
suspeito por explicar. O passo a passo está em
[`microdata_1960_compilacao.md`](microdata_1960_compilacao.md) e a auditoria roda
por [`auditoria_distritos_1960.R`](auditoria_distritos_1960.R).

Sobram três pontas. Nenhuma bloqueia nada, e as três estão listadas em ordem de
quanto ainda se pode fazer por elas.

---

## 1. Os oito pares município–distrito sem nome

São 561 domicílios, 0,018% do compilado, listados um a um com o motivo em
[`read_guides/1960_distritos_pendentes.csv`](../read_guides/1960_distritos_pendentes.csv).
Não são um problema só, são dois.

**Cinco são dano de fita, e estão encerrados.** Três registros da Guanabara
trazem o `V116` corrompido — vale 5 ou 18, quando na cidade ele é o código do
bairro e vai de 5410 a 5591 —, e sem bairro não há a que ligar a circunscrição. Um
domicílio de Colatina traz código de distrito 31 onde o maior impresso para o
município é 25, e um de Rodeio traz 15 onde o maior é 05. O valor foi destruído no
suporte magnético; não existe fonte que o reconstitua, porque a fonte seria o
próprio questionário. Não há o que fazer, e é melhor que fique assim, com a marca,
do que sair um palpite.

**Três são de outra natureza, e em tese têm conserto.** Em Nossa Senhora do
Livramento (MT), Dois Irmãos (RS) e Itutinga (MG) o arquivo usa um código de
distrito a mais do que qualquer publicação de 1960 lista, e a aritmética mostra o
que ele é. Em Nossa Senhora do Livramento, por exemplo, a Sinopse publica dois
distritos — a sede com 12.486 habitantes e Pirizal com 1.700 — e o arquivo traz
três códigos: o 03 é Pirizal, e o 01 mais o 05 reconstituem a sede. O código 05,
portanto, é uma repartição interna da sede que nenhuma publicação distingue.
Batizá-lo seria invenção.

O que fecharia: uma fonte municipal ou estadual da época que nomeasse essas
subdivisões — um mapa do setor censitário, um decreto de criação de distrito, a
divisão territorial estadual. Não sei se existe, e o retorno é pequeno: 555
domicílios. Fica anotado porque a pergunta é legítima, não porque valha a pena
persegui-la já.

---

## 2. Horizontina e Tenente Portela

Estes dois são os únicos sobreviventes da auditoria de numeração, e vale explicar
o problema do começo, porque ele não é óbvio.

O livro dá, para cada município, uma lista de distritos com um código ao lado de
cada nome. Em 96% dos municípios a lista vem com a sede primeiro e o resto em
ordem alfabética, e os códigos sobem junto com as linhas: 01, 03, 05, 07. Mas há
municípios em que os códigos **não** sobem com as linhas, porque um distrito
criado depois recebeu o próximo código livre e foi encaixado na ordem alfabética.
Nesses casos há duas leituras possíveis do que os codificadores do censo usaram: o
código impresso ao lado do nome (leitura "do livro") ou o código que a posição na
lista implica (leitura "posicional"). As duas dão nomes diferentes aos mesmos
códigos, e a diferença aparece nos microdados.

Trinta municípios foram decididos pela posição e sete pelo livro, cada um medido
contra a **Sinopse Preliminar de 1960** — o volume que o IBGE publicou por estado
em 1961-62 com a população de cada distrito — por duas medidas: a população do
distrito e a parcela dele que o censo classificou no quadro urbano. A regra de
decisão foi vencer por pelo menos 2 pontos percentuais na parcela urbana, ou, se a
urbana empatasse, por pelo menos 5% na população.

Estes dois não venceram por essa margem, e ficaram com a leitura do livro, que é o
padrão quando nada decide. A Sinopse deles **já está transcrita** em
[`censo_1960_sinopse_preliminar_distritos.csv`](censo_1960_sinopse_preliminar_distritos.csv):
o que falta não é dado, é separação.

### Horizontina (8312), página 278 do livro

O livro imprime, nesta ordem: Horizontina (01), Cascata (03), Doutor Maurício
Cardoso (05), **Pitanga (09)**, **Pranchada (07)**. As duas leituras discordam só
nos dois últimos — trocam Pitanga e Pranchada entre si.

| distrito | Sinopse: pop / urbana | lendo o livro | lendo a posição |
|---|---|---|---|
| Pitanga | 3.156 / 5,6% | código 09 → 2.824 / 9,9% | código 07 → 2.500 / 7,2% |
| Pranchada | 2.862 / 9,2% | código 07 → 2.500 / 7,2% | código 09 → 2.824 / 9,9% |

Erro mediano na população: livro 11,6%, posicional 11,1% — empate. Na parcela
urbana: **livro 3,1 pontos, posicional 1,1** — a leitura posicional erra 2,0
pontos menos, e a regra pedia *mais* de 2. Perdeu por um fio.

Ou seja: **Horizontina pende para a leitura posicional**, e só não foi corrigida
porque a margem ficou exatamente no limiar. Quem retomar isto tem duas saídas —
baixar o limiar e assumir a consequência (mas aí é preciso reexaminar os outros
municípios com a régua nova, senão a decisão vira ad hoc), ou buscar uma terceira
fonte. A mais promissora é o cadastro de distritos de 1970, em que boa parte dos
códigos é herdada de 1960.

### Tenente Portela (8325), página 280 do livro

Aqui não é falta de margem, é impossibilidade, e a razão é bonita. O livro imprime
Tenente Portela (01), Derrubadas (03), **Miraguaí (07)**, **Vista Gaúcha (05)**, e
as duas leituras trocam Miraguaí e Vista Gaúcha.

| distrito | Sinopse: pop / urbana |
|---|---|
| Miraguaí | 7.282 / 5,0% |
| Vista Gaúcha | 7.275 / 3,9% |

Os dois distritos têm **sete habitantes de diferença** e pouco mais de um ponto de
diferença na parcela urbana. Trocá-los não muda praticamente nada em nenhuma das
duas medidas: as duas leituras erram 5,2% na população e 0,9 ponto na parcela
urbana, iguais até a casa decimal. Nenhuma medida sobre a amostra vai separá-los,
nem com amostra maior, nem com medida melhor. Só uma fonte documental decide — o
cadastro de 1970, um ato de criação dos distritos, a divisão territorial do Rio
Grande do Sul.

---

## 3. Os 4.916 do Paraná

A população municipal de
[`read_guides/1960_municipios.csv`](../read_guides/1960_municipios.csv) soma, no
Paraná, **4.272.847 habitantes em 162 municípios, contra os 4.277.763 da linha
ESTADO da Sinopse Preliminar** — 4.916 a menos, 0,115%. A herança é da transcrição
antiga, feita antes de a Sinopse do Paraná estar em mãos, e o modo de falha é
conhecido porque já foi apanhado uma vez: em Rio Azul o guia trazia a população
urbana do distrito-sede (1.634) onde devia trazer a do município (1.967), e a
diferença era o distrito de Soares. Corrigido aquele, a Zona do Irati passou a
fechar.

Os 19 municípios que não tinham o corte urbano/rural já foram lidos na Sinopse, e
hoje urbana mais rural fecha com o total em todos os 162. O que resta é o mesmo
erro em algum dos outros 143 municípios, ainda não localizado.

**Por que importa, e por que não é urgente.** Esse arquivo é a âncora da
calibração de `censobr_weight` na amostra de 25%: as células são município ×
situação. Mas a margem municipal é reescalada para somar o total definitivo da
unidade da federação, que vem da Série Nacional — de modo que os 4.916 não
deslocam a escala do Paraná, só distribuem mal entre os municípios a população que
o estado tem. O efeito é local, nos municípios que carregam o valor errado, e some
na agregação estadual.

**O que fecharia:** auditar as 21 páginas do Quadro II da Sinopse Preliminar do
Paraná contra as 162 linhas do guia, do jeito que foi feito com os 19 —
renderizando as páginas a 300 dpi e lendo, porque a camada de texto do PDF é ruim
demais para extração em massa (só 56% das linhas fecham as cinco colunas). O
gerador está em
[`transcricao_1960_sinopse_preliminar.py`](transcricao_1960_sinopse_preliminar.py).

---

## O que não vale a pena refazer

Deixo registrado para poupar o trabalho a quem retomar: **os dois rastreios sobre
a base inteira já foram feitos e não sobrou suspeito**. A regra de que o distrito
01 é a sede vale em 98,56% dos municípios, e as 40 exceções foram examinadas uma a
uma — 37 são grafia de época e 3 têm explicação. A regra de que o distrito
homônimo do município é o maior e o mais urbano alcança 1.316 dos 1.337 municípios
com dois ou mais distritos nomeados, e os 37 suspeitos que ela levantou ou são
estruturalmente incapazes de estar desalinhados ou já estavam decididos. Ampliar a
amostra da auditoria não acha nada novo; foi medido.
