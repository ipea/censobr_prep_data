# A cópia CEM não acrescenta identificação aos resíduos de HHOLDA

23/09/2026. Auditoria integral, sem modificar dados de origem, manifestos,
produção ou pesos. Fontes locais e hashes foram verificados antes e depois.

## Resultado

Os 899.861 registros do SAV CEM são reproduzíveis a partir dos 174.467 blocos
físicos de HHOLDA: os 30 campos pessoais coincidem integralmente como
**multiconjuntos por ID**, preservando multiplicidades, após reproduzir a leitura
numérica observada no SAV. Os 14 campos domiciliares de cada pessoa coincidem
com o cartão físico anterior de HHOLDA. Não foi encontrado cartão, resposta,
identificador ou reparo independente que resolva as pendências.

A ordem pessoal NÃO coincide: 28.194 blocos permutam perfis pessoais. Portanto
as linhas do CEM não podem ser unidas às de HHOLDA por posição. A auditoria
conserva todas as correspondências quando há perfis indistinguíveis; não atribui
artificialmente uma linha do SAV a determinada pessoa repetida.

| Cobertura anterior | Registros confrontados | Perfis e multiplicidades presentes no CEM |
|---|---:|---:|
| Sem cartão confirmado | 1.216 | 1.216 |
| Conflitos municipais/situação | 192 | 192 |
| Dez danos textuais | 10 | 10 |
| Fragmentos | 3 | 3 |
| 458 conjuntos repetidos | 918 | 918 |

As listas se sobrepõem: sua união contém 2.332 linhas. Essa cobertura se refere
ao inventário com SHA256 `0938e196012e1cb11dd087edd06a85cb9d5fa81f4a34fa9cbe6a93f180f0c67c`,
não altera decisões novas de outras frentes.

## Transformações observadas, não reparos

- `V210` do SAV lê somente a primeira das duas colunas: por exemplo, `14` vira
  `1`. Isso muda 270.090 valores em comparação com a leitura completa, mesmo
  depois de corrigir o alinhamento. É perda de informação, não recuperação.
- Duas coerções adicionais são inteiramente explicadas pelo texto existente:
  linha 199.113, `V221="4- "` vira `4`; linha 199.617, `V221="34-"` vira `34`.
  O SAV não recupera a posição correta dos campos dessas linhas danificadas.
  A primeira comparação por multiconjuntos detectou precisamente esses dois
  casos; a segunda reproduziu as coerções e fechou todas as 899.861 pessoas.
- O SAV não contém distrito, pasta ou boletim. `STATE`, `RECD` e `RURURBP` são
  os campos pessoais; `RURURB` é a situação do cartão domiciliar replicado.
  A discordância entre as duas situações não constitui nova vinculação.
- Os 456 conjuntos literalmente repetidos continuam com o mesmo perfil de
  44 campos. Os outros dois conjuntos — 199.617/199.618 e 951.432/951.433 —
  conservam as diferenças que já existiam no texto danificado, sem acrescentar
  atributos que identifiquem pessoas ou permitam excluir uma delas.

Os fragmentos são exemplos decisivos: linha 951.432 permanece quase toda vazia;
951.433 conserva `V116=-357` e os demais números do texto corrompido;
855.822 conserva a leitura deslocada `STATE=91`, município ausente e valores
anômalos. Seus campos domiciliares vêm dos cartões físicos 951.430 e 855.812,
respectivamente, não de uma lista de família recuperada. Nos dez danos, até os
algarismos isolados após o marcador terminal reaparecem nos campos numéricos
do SAV. Não há informação anterior ao dano.

## Procedência e reprodução

A [página pública do CEM](https://centrodametropole.fflch.usp.br/pt-br/node/8857),
conferida nesta rodada, oferece o arquivo pelo
[link de distribuição](https://drive.google.com/file/d/1ehlPo10QweI9xCj_3L6QnYRNfEnGP1nv/view).
Sua data de publicação é 26/12/2018; o arquivo extraído traz data 20/06/2012.
Essas datas não provam independência histórica de HHOLDA. A conclusão acima é
sobre o conteúdo integral efetivamente recebido, não uma afirmação sobre a
história de transmissão do arquivo.

- SAV: `fa1b29242572d4563ce40a80d60e6c2daafb32f107de41dbb7684adef1ec7ac0`.
- HHOLDA: `6449ca06c9086bbb0474481827f0efff98a0d9489838f322b4a69e489a42c44c`.
- Parquet de leitura sem recodificações: `c24d829bf6e2ca87f54041f0d28c5c6751a0a9b4d65398c1c27257eab1196e4e`.

Executar `python -X utf8 references/fechamento_integral_1960_cem.py` para testar
a hipótese posicional e os campos domiciliares; depois
`python -X utf8 references/fechamento_integral_1960_cem_pareamento.py` para o
pareamento correto por multiconjuntos. A primeira saída individual
`registros_pendentes_cem.json` é apenas hipótese posicional e NÃO deve ser usada
como vínculo. A entrega individual válida é `residuos_pareados.json`.

Artefatos em `tmp/fechamento_integral_1960/fonte_cem/auditoria_integral/`:
`comparacao_integral.json`, `pareamento_integral.json`, `residuos_pareados.json`
e `duplicatas458_pareadas.json`. Pico RSS observado: 717.205.504 bytes na
passagem posicional e 148.733.952 na passagem de perfis; ambos abaixo de 2 GiB.

**Decisão implementável:** não importar campos nem vínculos do CEM sobre os
originais; registrar que essa fonte alternativa foi integralmente esgotada.
Nenhuma pendência pode ser encerrada somente pela repetição dos mesmos danos
e anexação física no SAV. As reparações já demonstradas em fontes independentes
continuam válidas, mas não recebem confirmação nova dessa cópia.
