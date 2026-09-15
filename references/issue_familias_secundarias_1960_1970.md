# Rascunho de issue para o ipea/censobr

**Título:** Famílias secundárias (conviventes) não têm as variáveis do domicílio nos microdados de 1960 e 1970: deixar em branco, ou preencher a partir da família principal?

---

Este issue é para decidirmos, com calma, uma regra que afeta os microdados de 1960 e 1970 e que hoje está resolvida de um jeito provisório no pipeline de preparação (`censobr_prep_data`). Vou explicar como o dado é, por que é assim, o que está em jogo, e quais são as opções.

## Como o formulário funcionava

Nos censos de 1960 e 1970 o questionário era **por família**, não por domicílio. Quando um domicílio tinha mais de uma família (um casal de filhos morando com os pais, uma família hóspede, empregados com família própria), cada família recebia o seu próprio boletim. As características do **domicílio** (tipo de construção, condição de ocupação, aluguel, água, sanitário, fogão, luz, rádio, geladeira, televisão, cômodos, dormitórios) eram perguntadas uma vez só, no boletim da família principal. Nos boletins das outras famílias do mesmo domicílio essas perguntas ficavam em branco ("não se aplica"), porque a resposta já estava no boletim principal.

Em 1960 isso está na variável `V101` (espécie do domicílio): 1 = família única no domicílio, 2 = família principal de um domicílio com mais de uma, 3 = domicílio coletivo, 4 = segunda família, 5 = terceira família. A página do domicílio (`V102` a `V113`) só vem preenchida quando `V101` é 1 ou 2. Nas famílias 4 e 5 ela é toda em branco, sem exceção.

Em 1970 é a mesma coisa com `V006` (espécie da família) e o bloco `V007` a `V021`: o bloco só vem preenchido quando `V006` é 1 ou 2 (única ou principal). Nas famílias secundárias vem vazio.

## Quanto dado é

| censo | famílias secundárias | pessoas nelas | o que fica em branco |
|---|---|---|---|
| 1960 (amostra de 1,27%) | 373 | 1.367 | `V102` a `V113` |
| 1970 (amostra de 25%) | em 233.856 domicílios | 822.748 | `V007` a `V021` |

Em 1970 são 822.748 pessoas, 3,3% da amostra, espalhadas por 233.856 domicílios, sem condição de ocupação, água, sanitário, cômodos e dormitórios. (Na tabela de domicílios essas famílias não têm linha própria: ela traz 4.507.529 famílias únicas e 233.857 principais.) Quem faz uma tabela de "pessoas por tipo de abastecimento de água" a partir do arquivo de pessoas perde essas pessoas ou as põe numa categoria "sem informação" que não existe no censo.

Um exemplo de 1960 (linhas 5648 a 5657 do arquivo): a família principal tem `V101` = 2, um chefe de 33 anos e uma pessoa de 23; a segunda família, `V101` = 4, tem um chefe de 38 anos, a esposa de 27 e quatro filhos. As duas moram no mesmo domicílio. A página do domicílio existe uma vez, no boletim da primeira; no boletim da segunda, `V102` a `V113` estão vazios.

## As opções

1. **Deixar em branco e documentar.** O dado fica como o IBGE gravou. O dicionário de variáveis e os rótulos do `censobr` avisam: "nas famílias secundárias (`V101` = 4 ou 5 em 1960; `V006` = 3 ou mais em 1970) as variáveis do domicílio estão no registro da família principal; para tê-las por pessoa, junte a tabela de pessoas à de domicílios por `id_household`". O usuário decide e faz a junção; o `merge_household()` já existe para isso.

2. **Preencher só as variáveis físicas do domicílio, com marca de origem.** Tipo de construção, água, sanitário, fogão, luz, rádio, geladeira, TV, cômodos e dormitórios são propriedades do prédio: para quem mora no mesmo domicílio, o valor é o mesmo por definição, e copiá-lo da família principal é dedução, não estimativa. Condição de ocupação (próprio, alugado, cedido) e aluguel descrevem o arranjo da família principal, e a secundária pode morar de favor: esses ficariam em branco. Uma coluna diria de onde veio cada valor.

3. **Preencher tudo.** Mais cômodo, mas atribui à família secundária uma condição de ocupação e um aluguel que podem não ser dela.

## O que o pipeline faz hoje

A opção 1, nos dois censos, com uma coluna que identifica a família secundária. Em 1970 chegamos a implementar a opção 3 e voltamos atrás, porque preencher condição de ocupação e aluguel é inventar dado. A opção 2 foi discutida e não adotada por ora, para que a decisão seja tomada aqui, com os dois olhando.

## O que precisamos decidir

- Fica na opção 1, com a documentação, ou vamos para a 2?
- Se for a 1: onde o aviso deve aparecer no `censobr` (dicionário, rótulos, vinheta), e se vale ter um argumento em `read_population()` que faça a junção com o domicílio automaticamente.
- Se for a 2: qual é a lista exata de variáveis "físicas" em cada censo, e o nome da coluna de origem.

A mesma questão vai aparecer na amostra de 25% de 1960 quando ela entrar no pipeline.
