# Amostra de 1,27% de 1960: revisão de vínculos, duplicatas e dois reparos

> **Integração posterior:** a [revisão integrativa](microdata_1960_amostra_127_revisao_integrativa.md) prevalece nos pontos conflitantes e acrescenta famílias sintéticas, conviventes e reparos antes não avaliados. As 31 restaurações sugeridas não são 31 ausências no compilado; os candidatos de vínculo não autorizam fusão automática. Esta auditoria permanece como evidência histórica, não homologação.

Auditoria de 21/09/2026. O resultado principal é que há exclusões excessivas
corroboradas pela amostra de 25% e vínculos ao registro anterior que contrariam
boletins identificáveis nessa mesma fonte. A preparação não está encerrada.
Os parquets existentes não foram corrigidos por esta auditoria.

## Fontes, reprodução e limites

O script [auditoria_vinculos_duplicatas_1960.py](auditoria_vinculos_duplicatas_1960.py)
lê o `HHOLDA.txt`, confere as 1.074.328 linhas de 62 caracteres e o texto original
de cada decisão do CSV, aplica essas decisões somente em memória e confronta:

- o registro de exclusões `data_raw/microdata/1960/amostra_127/duplicatas_removidas.csv`;
- os parquets atuais de pessoas e domicílios da amostra de 1,27%;
- `familias.parquet` e `pessoas.parquet`, intermediários de leitura da amostra de
  25%, separados por UF. Não são os arquivos já calibrados.

O SHA-256 de `HHOLDA.txt` é
`6449ca06c9086bbb0474481827f0efff98a0d9489838f322b4a69e489a42c44c`.
Os parquets de 1,27% examinados têm data de modificação de 21/09/2026; os
intermediários de 25% vêm da leitura anterior. O script imprime os caminhos,
tamanhos e horários dos insumos, além dos hashes do bruto e dos CSVs usados.

```text
python references/auditoria_vinculos_duplicatas_1960.py --uf pb
python references/auditoria_vinculos_duplicatas_1960.py
python references/auditoria_vinculos_duplicatas_1960.py --details
```

A primeira chamada é a verificação pequena da Paraíba. A segunda apresenta
resumo e casos de referência; a terceira inclui cada pessoa anexada e cada
perfil sujeito a exclusão. O programa escreve somente na saída padrão. Não
executa R, targets, downloads nem grava parquets.

A comparação exata usa UF + pasta + boletim e os 25 campos comuns de pessoa,
de V202 a V224, incluindo AGE e V223B. Branco, salto e valor fora do guia
tornam-se ausentes conforme o parsing. Ela **não** usa idade, nome de município
ou fator de calibração para escolher a pessoa mais parecida. O distrito é
conferido separadamente porque está justamente entre os campos com erros.
Para os reparos deslocados usa-se apenas o trecho anterior ao dano.

Os intermediários de 25% consultados têm um cartão de família por boletim e
`v100` igual ao número de pessoas lidas em todos os boletins examinados. Isso
fortalece a evidência de multiplicidade. Os gzip originais de 25% não foram
relidos nesta rodada: a evidência é a fonte preservada nos intermediários de
parsing. Ela não identifica pessoas civilmente, não prova ausência de erros na
amostra de 25% e não deve ser chamada de controle externo independente: as duas
amostras têm origem comum.

## 1. Vínculos ao cartão de família anterior

O código vigente antes desta revisão, em
`R/microdata_1960_amostra_127.R`, usava `findInterval()` sobre a posição física
dos cartões para anexar todo grupo ainda sem família ao cartão anterior.
Depois atribuía a essa pessoa a UPA, o município e o distrito do domicílio
assim escolhido. Ausência de chefe ou cônjuge não demonstra que esse vínculo
seja correto.

São 1.008 pessoas com `censobr_familia_origem = anexada_anterior`. Destas,
70 discordam da geografia do domicílio adotado: 48 em pasta, 30 em distrito e
26 em V116, com interseções; nenhuma em UF. Duas diferenças de V116 são bairros
da Guanabara, de modo que 24 se referem a municípios fora da Guanabara.

| Resultado do confronto exato com 25% | Todas as anexadas | Entre os 70 conflitos |
|---|---:|---:|
| Perfil encontrado; cartão correspondente já existe em HHOLDA | 135 | 10 |
| Perfil encontrado; cartão existe em 25%, mas não em HHOLDA | 362 | 36 |
| UF tem 25%, mas não há perfil inteiramente idêntico na chave examinada | 263 | 16 |
| UF sem amostra de 25% preservada | 248 | 8 |
| Total | 1.008 | 70 |

“Perfil encontrado” informa uma correspondência de conteúdo e de boletim.
Não é autorização automática para reescrever o arquivo. Cada reconciliação
deve registrar a fonte, a pessoa ou multiplicidade encontrada, o cartão de
destino e a origem da alteração. A tabela também mostra por que revisar só
os 70 conflitos seria insuficiente: dentro da mesma geografia há outros
boletins próprios que o fallback reuniu.

### Os dezesseis hóspedes de Minas Gerais

As linhas 491756–491771 têm pasta 40090, mas o parquet lhes atribui UPA
`40-40050`, família 77251 e domicílio 77177: os da família cujo cartão está na
linha 491747, pasta 40050, boletim 260. O confronto com 25% encontra:

| Pasta | Boletins | Cartões de família em 25% | V101 | Pessoas declaradas por boletim |
|---|---|---|---:|---:|
| 40090 | 004, 006, 007, 009, 010, 011, 012, 013 | linhas 58692, 58697, 58700, 58705, 58708, 58711, 58714, 58717 | 3 | 2 |

São oito boletins coletivos próprios. Quinze das dezesseis pessoas coincidem
nos 25 campos. A linha 491763 tem candidato no mesmo boletim 009, linha 58706
de 25%, com diferenças em V212 (7/8), V219 (9/3) e V224 (6/0). Essas diferenças
devem permanecer anotadas; não foram corrigidas.

A evidência sustenta desfazer o vínculo com a pasta 40050 e reconstruir os
boletins próprios com proveniência da amostra de 25%. Não sustenta anexar todo
o lote à primeira família seguinte da pasta 40090. A existência de um cartão
V101=3 representa uma unidade de registro coletivo no arquivo; não demonstra
por si só que cada boletim era um prédio coletivo fisicamente diferente.

### As duas crianças da Bahia

| Linha HHOLDA | Pasta/boletim | Pessoa correspondente em 25% | Cartão de família já presente em HHOLDA |
|---:|---|---:|---:|
| 302261 | 31606/031 | 399500 | 302453 |
| 302262 | 31606/072 | 399788 | 302742 |

Os dois perfis coincidem integralmente. As pessoas têm distrito 01 gravado no
HHOLDA; os respectivos cartões em HHOLDA e em 25% dizem distrito 07,
município 3138. O fallback as havia ligado à família da linha 302253,
município 3136 e pasta 31516. Há evidência para corrigir a chave de distrito e
vincular cada uma ao cartão **existente**, sem criar domicílio novo.

### Encaminhamento dos demais conflitos

Os dez pareamentos exatos com cartão já existente são as linhas 302261,
302262, 431444, 565604, 781974, 781975, 781981, 829767, 835578 e 964086.
O script fornece para cada uma a linha de destino. Os 36 pareamentos exatos
com cartão ausente em HHOLDA também estão discriminados na saída detalhada.
Entre as 362 pessoas nessa situação considerando todas as anexadas, 350
pertencem a boletins V101=3 e 12 a boletins V101=1 em 25%.

Os 16 conflitos sem perfil exato na chave são:
113838, 142402, 259248, 405458, 425866, 432996, 469039, 469040, 469041,
469042, 491763, 673349, 781973, 1046045, 1055742 e 1055743.
Sete têm um candidato cuja única diferença é V216=00 em 1,27% e 63 em 25%:
113838, 425866, 432996, 673349, 781973, 1055742 e 1055743. Essa regularidade é
uma pista de codificação, não licença para declarar todos os candidatos
idênticos nem para fundir as categorias 00 e 63. A linha 405458 difere do
candidato somente nos dois campos ausentes V203 e AGE. Os demais incluem
pasta ilegível ou diferenças maiores. O script lista candidatos e campos
discordantes sem promovê-los a correspondência exata.

Os oito sem UF de 25% preservada são 11249, 11250, 630958, 630959, 637049,
637050, 938795 e 938796. A falta da fonte permanece como pendência explícita.

### Vínculos diretos também precisam de conferência

Comparando pessoas materializadas com origem `registro` ao seu **próprio**
cartão familiar identificado por UF + chave completa, e não à família
principal de um domicílio convivente, há 61 diferenças em V116. São 58 com
ambos os valores numéricos; as outras três são pessoas cujo município 7240
foi preenchido posteriormente a partir do cartão familiar `724Z`.
Das 58 numéricas, quatro são bairros da Guanabara. A distribuição das 61 é:
RJ 30, SC 6, RS 6, SP 5, GB 4, PR 3 e uma em cada uma de AM, PA, CE, RN,
PB, BA e MG.

Não se deve transformar toda divergência em prova de família errada. Por
exemplo, o cartão da linha 695175 tem V116=7234; pessoas das linhas 661580 e
661581 trazem 6234, erro municipal familiar já discutido na preparação. Já
na linha 569740 o V116 pessoal é 5221 e o cartão da linha 570020 tem 5222.
O script lista os casos; eles exigem separar defeito da chave de defeito do
campo municipal. Um bloqueio indiscriminado por V116 poderia rejeitar
reparos documentados válidos.

## 2. Exclusões como duplicatas

A regra anterior eliminava qualquer perfil repetido quando houvesse pelo
menos duas repetições no número de família, mesmo fora de Pernambuco e sem
bloco contíguo na cauda. A comparação preserva multiplicidades: conta quantas
ocorrências do mesmo perfil há antes da deduplicação, depois dela e em 25%.

| Resultado por perfil | Linhas atualmente excluídas |
|---|---:|
| Quantidade restante coincide com a quantidade de pessoas em 25% | 2.238 |
| Quantidade restante ficou menor que em 25%, sem exceder o bruto de 1,27% | 39 |
| Não há perfil exato na chave examinada, embora a UF tenha 25% | 555 |
| A quantidade em 25% supera até a quantidade anterior à exclusão em 1,27% | 4 |
| UF sem 25% preservada | 14 |
| Total | 2.850 |

As 39 exclusões excessivas pertencem a 28 perfis e exigiriam **31
restaurações**, não 39. Em alguns perfis havia simultaneamente pessoas
distintas idênticas e cópias adicionais: parte da remoção foi correta, parte
foi excessiva. A distribuição das 31 restaurações corroboradas é PE 8,
BA 4, MG 4, SP 4, RS 4, RJ 3, PB 2 e MT 2.

Das 2.238 exclusões corroboradas, 2.212 estão em Pernambuco. Isso confirma
a existência do problema de cópia, mas não a regra de que toda repetição
deve ser reduzida a uma só pessoa. Os 555 casos sem perfil exato incluem
550 de Pernambuco; ausência de correspondência exata não demonstra nem
autenticidade nem duplicação. É necessário conferir campos divergentes,
chaves e composição do boletim. As 14 exclusões sem fonte de 25% são GB 6,
SC 4, MA 3 e PI 1.

### Paraíba: pessoas distintas com idade ignorada

HHOLDA, pasta 19124, boletim 166, número a posteriori 25763, tinha sete
pessoas. O cartão de 25%, linha 84593, declara sete e é seguido de sete
registros com ordens próprias. Há dois filhos masculinos com o mesmo perfil
(linhas 84596 e 84597) e duas filhas com o mesmo perfil (84598 e 84599),
todos com idade ignorada. O pipeline excluiu as linhas 168805 e 168806 de
HHOLDA, ficando com cinco pessoas.

A fonte preserva a multiplicidade de duas em cada perfil. A hipótese de que
dois pares de repetições implicariam dois pares de gêmeos não se aplica:
idade ignorada permite perfis coincidentes de irmãos de idades diferentes.
Mesmo quando a idade é conhecida, o evento raro não pode ser considerado
impossível. A Bahia, pasta 31712/057, confirma dois pares de filhos de um e
três anos, cujas segundas ocorrências foram excluídas nas linhas 306831 e
306841. A idade desconhecida não é o único modo de falha.

### Pernambuco: cópia e multiplicidade legítima no mesmo boletim

Na pasta 21438, boletim 069, um perfil de filho masculino de um ano tem
quatro ocorrências em HHOLDA. A amostra de 25% registra **duas pessoas** desse
perfil nas linhas 38184 e 38185. O algoritmo removeu três ocorrências
(195145, 195149 e 195153), deixando uma; deveria preservar multiplicidade
dois. Não é possível distinguir identidade civil entre linhas com o mesmo
conteúdo, mas é possível conservar a quantidade documentalmente sustentada.

Restringir a regra a Pernambuco + cauda + duas repetições ainda excluiria
2.708 das 2.850 linhas atuais e não resolveria esse caso. Logo esse filtro
não substitui a comparação de multiplicidades.

### Restaurações corroboradas, para uma futura decisão de tratamento

Os grupos abaixo enumeram linhas atualmente excluídas e quantas ocorrências
precisam voltar para reproduzir a multiplicidade de 25%. Quando o grupo tem
mais linhas que restaurações, não se está dizendo que todas são legítimas.

| UF | Linhas excluídas do mesmo perfil | Restaurar |
|---|---|---:|
| PB | 168805 | 1 |
| PB | 168806 | 1 |
| PE | 195145, 195149, 195153 | 1 |
| PE | 195736 | 1 |
| PE | 196376 | 1 |
| PE | 215900 | 1 |
| PE | 217417 | 1 |
| PE | 217465, 217467, 217469 | 1 |
| PE | 217594, 217596 | 1 |
| PE | 220680, 220682, 220686 | 1 |
| BA | 306831 | 1 |
| BA | 306841 | 1 |
| BA | 373052 | 1 |
| BA | 373053 | 1 |
| MG | 392259 | 1 |
| MG | 459628, 459630 | 2 |
| MG | 459629 | 1 |
| RJ | 565892 | 1 |
| RJ | 565893 | 1 |
| RJ | 592061 | 1 |
| SP | 659205, 659207 | 2 |
| SP | 780523, 780528 | 1 |
| SP | 828331 | 1 |
| RS | 981480 | 1 |
| RS | 981481 | 1 |
| RS | 1020880 | 1 |
| RS | 1020885 | 1 |
| MT | 1037123, 1037125 | 2 |

Se só essas restaurações fossem aplicadas e nenhum outro tratamento mudasse,
a amostra intermediária passaria de 897.009 para 897.040 pessoas. Esse é
apenas um impacto aritmético isolado, não uma nova população validada nem um
recálculo dos pesos. Todas essas UFs têm 25% preservados, e a compilação de
1960 seleciona a amostra maior nelas: não se deve afirmar que as 31 pessoas
foram também excluídas do parquet compilado.

## 3. Dois reparos deslocados na Bahia

As decisões das linhas 387715 e 387853 reconheciam duas posições possíveis
para um branco e escolheram a posição 45. A comparação com 25%, usando
somente os campos de V202 a V214, anteriores ao trecho deslocado, encontra
um candidato único em cada boletim:

| HHOLDA | Pasta/boletim | Linha/ordem em 25% | V218 atual / 25% | V219 atual / 25% | V220 atual / 25% |
|---:|---|---|---|---|---|
| 387715 | 33786/034 | 1909824 / 08 | 3 / 0 | ausente / 3 | 4 / 4 |
| 387853 | 33786/050 | 1909966 / 05 | 3 / 0 | ausente / 3 | 1 / 1 |

O reparo anterior preservou o dígito 3 de rendimento na posição dos filhos
vivos. A fonte de 25% sustenta V218=00 e V219=3. Inserir um zero no trecho
de zeros anterior recoloca esses campos nas posições esperadas; inserir um
branco em 45 ou 46 não recupera o mesmo conteúdo. Trata-se de reconstrução
agora apoiada pela outra cópia do boletim, não de dedução única do trecho
corrompido isoladamente.

A primeira pessoa ainda difere em V216: 00 em HHOLDA e 63 em 25%. Essa
diferença não é explicada pela simples perda de um zero e não deve ser
sobrescrita automaticamente. A segunda não tem outra diferença. O CSV de
correções e os parquets não foram alterados por esta auditoria.

## 4. Critérios conservadores e próxima implementação

1. Substituir a regra “duas repetições = bloco” por decisões de multiplicidade
   rastreáveis por boletim e perfil. Conservar as exclusões corroboradas e
   limitar a remoção ao excesso sustentado pela fonte. Para decisões sem
   fonte, registrar hipótese e análise de sensibilidade; não fabricar certeza.
2. Não anexar por posição sem evidência de continuidade. Aproveitar cartões
   já existentes nas reconciliações comprovadas; quando a outra amostra
   preserva o cartão perdido, registrar reconstrução por fonte, sem fingir
   que o cartão estava em HHOLDA. Não criar domicílios apenas para fazer o
   pipeline passar.
3. Conservar chave e campos originais e adicionar explicitamente a chave
   reconciliada, o motivo e a fonte de cada alteração. A UPA não deve mudar
   como efeito colateral silencioso de uma ligação familiar.
4. Manter os casos sem decisão como pendentes. Um bloqueio de reconstrução
   quando restam órfãos ou exclusões não aprovadas é uma salvaguarda; não
   constitui correção dos registros.
5. Validar a próxima implementação em boletins pequenos: PB19124/166,
   MG40090/004–013, BA31606/031 e072 e PE21438/069. Conferir multiplicidades,
   familiares, UPA, geografia e ausência de perdas adicionais. Só depois
   reprocessar os targets afetados e recalibrar o que depende da preparação.

Nesta rodada foram executadas as comparações independentes em Python, primeiro
na Paraíba e depois em todas as ocorrências delimitadas. Não foi executada a
implementação R. Os bloqueios preventivos introduzidos separadamente no código
R devem ser distinguidos desta auditoria e de uma futura base corrigida.
