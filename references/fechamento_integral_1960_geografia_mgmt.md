# Os códigos sem nome de Livramento e Itutinga

23/09/2026. Esta nota substitui as certezas indevidas do histórico: um código
sem nome no guia não demonstra, sozinho, dano de fita ou subdivisão da sede.
Não houve renomeação de distrito, transferência de pessoa ou troca de código.

## Nossa Senhora do Livramento: existe uma terceira possibilidade documentada

O guia antigo dizia que o código 05 era uma repartição interna da sede que
nenhuma publicação distinguia. A afirmação é incorreta. O IBGE publicou,
na *Divisão territorial do Brasil — 1.º-VII-1960*, página 135 (PDF 140), os três
distritos: Nossa Senhora do Livramento, Pirizal e Sêco. A terceira unidade tem
asterisco de alteração; não é um nome imaginado a partir da amostra.

A [publicação contemporânea do IBGE](https://biblioteca.ibge.gov.br/visualizacao/livros/liv13611.pdf)
usa os números 117, 118 e 119 para enumerar os distritos no estado. Esses números
não são os códigos 01, 03 e 05 dos microdados. O [histórico administrativo do IBGE](https://biblioteca.ibge.gov.br/visualizacao/dtb/matogrosso/nossasenhoradolivramento.pdf),
página 2, também situa a criação de Seco em 1958 e registra os três distritos em 1960.
O [plano municipal de turismo](https://www.nossasenhoradolivramento.mt.gov.br/fotos_secretarias_downloads/20.pdf)
repete esse histórico; não constitui um cadastro operacional independente.

Assim, Seco é candidato documental para 05. Ainda falta a ligação explícita
entre o nome e o código usado nos cartões de 1960. Não converti a ordem da lista
em uma correspondência comprovada. A ausência de Seco na Sinopse consultada
também não prova que ele fosse uma repartição sem nome da sede.

A nova releitura percorreu as 273.217 linhas da amostra de 25% de MT. Em Livramento,
achou 639 cartões: 304 no código 01, 89 no 03 e 246 no 05. O código 05 aparece em
duas pastas, 91172/91174, sempre rural, com 1.637 pessoas listadas e 1.631 presentes.
As contagens descrevem
o arquivo; não são uma prova do nome nem um novo total populacional.

## Itutinga: o código 03 continua sem identificação, mas a causa não está provada

O [histórico do IBGE](https://biblioteca.ibge.gov.br/visualizacao/dtb/minasgerais/itutinga.pdf),
a [lei mineira 1.039/1953](https://www.almg.gov.br/legislacao-mineira/texto/LEI/1039/1953/)
e a Sinopse consultada sustentam município de distrito único em 1960.
Os microdados, entretanto, apresentam 388 cartões: 237 no código 01 e 151 no 03.
Todos os 151 do código 03 pertencem à pasta 40884. Há também 23 cartões do código
01 nessa pasta; os outros 214 pertencem à pasta 40886.

O código 03 tem 820 pessoas listadas e 786 presentes; o 01 tem 1.231 listadas e
1.173 presentes. Multiplicar os 1.959 presentes por quatro dá 7.836, contra
4.318 na publicação.
Essa diferença **não demonstra que a fração sorteada tenha sido maior**.
Há explicações concorrentes, inclusive problema de codificação territorial;
uma calibração pode reduzir a diferença numérica sem decidir qual delas ocorreu.

O município vizinho Itumirim tem um distrito chamado Ingaí com código 03 no
cadastro. A possibilidade de confusão de município precisa de prova de registros,
não apenas semelhança de contagens ou proximidade numérica 4095/4096. Nenhuma
dessas respostas foi recodificada nesta análise. A investigação independente
dos grupos da amostra de 25% está na [nota de Itutinga](fechamento_integral_1960_duplicatas_itutinga_resultado.md):
os 388 grupos foram comparados com 489.898 grupos mineiros, sem encontrar uma
cópia integral de família que autorizasse a transferência para Itumirim.

## Como conferir

- Script: `fechamento_integral_1960_geografia_mgmt.py`; leitura integral de MG/MT,
  com contagens por distrito, pasta e situação, sem alterar os brutos.
- Cartões nominais, textos e resumos: `tmp/fechamento_integral_1960/geografia_mgmt/cartoes_e_contagens.json`.
- Fac-símile consultado: `tmp/fechamento_integral_1960/geografia_mgmt/dtb1960_pdf140.png`.
- URLs, tamanhos e assinaturas das fontes: `tmp/fechamento_integral_1960/geografia_fontes/consultas.json`.

Uma assinatura SHA256 identifica a cópia efetivamente lida; ela não transforma
uma hipótese de correspondência territorial em certeza histórica.
