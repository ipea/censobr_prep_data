# Recuperação de cartões de 1960: prova e limites

Auditoria de 22/09/2026, separada dos 82 vínculos anteriores. Estes últimos apontam para cartões já existentes em HHOLDA. O novo [manifesto de recuperação](../read_guides/1960_amostra_127_cartoes_recuperados.json) descreve **29 cartões conservados na fonte de 25%**, cujas **72 pessoas já existem em HHOLDA**, sem cartão encontrado pelas chaves e buscas documentadas. Não acrescenta pessoas nem fabrica uma linha original de 62 caracteres.

Todos os 29 são boletins coletivos (`V101=3`). As 72 pessoas são **presentes não moradoras**: 29 homens (`V202=5`) e 43 mulheres (`V202=6`). Recuperar esses vínculos não acrescenta 72 moradores à população residente. Um boletim coletivo é uma unidade de registro; sua recuperação não demonstra a existência de um edifício fisicamente separado.

## O que foi examinado

O universo partiu das pendências atuais, após aplicar em memória as decisões documentadas de texto, duplicatas e os 82 vínculos. Entre os registros utilizáveis, havia 751 pessoas em 253 chaves UF/pasta/boletim sem cartão127 encontrado, mesmo desconsiderando distrito. Dessas, **589 pessoas em 215 chaves**, distribuídas em 13 UFs com fonte25, foram examinadas. As outras 162 pessoas/38 chaves não têm essa fonte disponível. Três linhas com decisão antiga de conteúdo corrompido ficaram fora da busca, sem serem apagadas ou resolvidas: 855822, 951432 e 951433.

O núcleo aprovado contém:

| UF | Cartões | Pessoas já existentes |
|---|---:|---:|
| Ceará | 1 | 2 |
| Minas Gerais | 5 | 16 |
| Rio de Janeiro | 2 | 9 |
| São Paulo | 11 | 22 |
| Paraná | 6 | 13 |
| Rio Grande do Sul | 2 | 4 |
| Goiás | 2 | 6 |
| **Total** | **29** | **72** |

Os outros 186 grupos/517 pessoas examinados não foram aprovados. Os motivos se sobrepõem: composição pessoal divergente em 107 grupos; alternativa de cartão127 não descartada em 67; espécie fora do escopo em 10; divergência/ausência de geografia pessoal em 7; cartão25 ausente em 6; chave127 inválida em 2; código pessoal inválido em 1. As chaves inválidas são as linhas HHOLDA **142402** (CE) e **259248** (PE): suas linhas permanecem identificadas, sem classificá-las falsamente como ausência demonstrada de cartão25.

## Critérios de aprovação

- Cartão25 único; todas as pessoas imediatamente após ele, com ordens completas, redundâncias conferidas e contagem igual a `v100`.
- Igualdade dos 25 campos pessoais comuns e da composição inteira do boletim, preservando multiplicidades. Cada correspondência pessoal é única dentro do boletim. Branco legítimo, zero e caractere inválido são distinguidos; não se aceita igualdade artificial causada por converter dano em valores ausentes.
- UF, município, distrito e situação das pessoas127 concordantes com o cartão25. Fonte da UF é o arquivo25, não o prefixo da pasta.
- Nenhuma pessoa nova, resposta transferida, vínculo anterior sobrescrito ou duplicata ainda sem decisão usada para fechar a composição. Espécies 2/4/5 não são recuperadas nesta rodada: precisam de prova adicional da estrutura convivente.
- Busca ampliada pelos cartões127 de toda a UF: chave exata e parcial, diferenças de um caractere, perfil familiar, cartões adjacentes e perfis pessoais encontrados em outros contextos. O bloco físico e a ligação por chave são examinados separadamente. Composição inteira igual permanece uma alternativa mesmo com geografia divergente.
- Perfil familiar coletivo vazio, chave próxima ou uma pessoa de respostas iguais são pistas, não decisões. Para afastar um cartão de corpo/geografia compatíveis como pertencente a outro grupo, exige-se confirmação de seu próprio cartão25 e composição integral. Houve **7.564 exames de cartões candidatos, somando os 29 grupos aprovados**; um mesmo cartão pode ser examinado para mais de um grupo. Seis comparações tinham corpo familiar igual, referentes a cinco cartões distintos, todos com grupo próprio integralmente confirmado.

Os saltos de HHOLDA são reconhecidos somente nas posições documentadas 20, 21, 33, 36 e 47, quando a cauda dos quesitos permanece em branco. Texto ilegível não recebe esse tratamento. O campo familiar `V113` tem três caracteres na25 e dois na127; a conversão é expressa. O texto25 literal continua sendo a autoridade.

## Exemplo aprovado: Cambuí, MG, pasta40654/177

O cartão está na linha **429723** de `data/release_legacy/Censo.1960.amostra.25porcento.mg.gz`, município4051, distrito01, situação3, espécie3, duas pessoas. Não foi encontrado cartão correspondente em HHOLDA, inclusive nas buscas ampliadas descritas acima.

| Linha HHOLDA | Informação pessoal preservada | Linha25 / ordem |
|---|---|---|
| 400682 | Mulher, 33 anos, não moradora presente; hóspede ou empregado | 429725 / 02 |
| 400683 | Homem, 31 anos, não morador presente; hóspede ou empregado | 429724 / 01 |

As duas ordens estão invertidas entre os arquivos; por isso a prova usa composição e correspondências explícitas, não alinhamento físico. Não há base para chamar essas pessoas de casal. O identificador de recuperação é **40-40654-177**; não é um número de linha inventado para HHOLDA.

Texto literal do cartão25:

```text
40654177004023               4051013000000000000000000
```

## Exemplo mantido pendente: Belo Horizonte, MG, pasta40090/004

As pessoas HHOLDA **491756–491757** coincidem com as linhas25 **58694–58693**, e o cartão25 **58692** declara as duas. É evidência forte para um boletim próprio, mas **não entrou no manifesto**: restaram cartões coletivos alternativos cuja composição própria não pôde ser confirmada integralmente sob os critérios desta rodada.

Por exemplo, o cartão127 **491871**, pasta40090/064, tem oito pessoas e corresponde a um cartão25 na linha **58898**. Seis perfis pessoais coincidem; as correspondências candidatas **491874↔58901** e **491877↔58906** divergem em `V216=00/63`. No cartão127 adjacente **491772**, boletim021, três das quatro pessoas têm divergências: **491773↔58736** em V212, V214 e V216; **491774↔58738** e **491776↔58737** em V216. Não se igualaram esses códigos nem se corrigiram respostas. Isso não demonstra que tais cartões pertençam ao boletim004: demonstra que a prova negativa exigida para descartá-los ainda não fechou.

A mulher491756 também compartilha o perfil pessoal com **417911**, em outra localidade: município4150, situação3, pasta41228/103. Essa coincidência individual foi registrada, não confundida com identidade civil. O grupo da outra chave tem 11 pessoas e não coincide com o par de Belo Horizonte. Portanto, essa coincidência isolada não é o motivo atual para bloquear o004.

## Reprodução e rastreabilidade

Código: [auditoria_recuperacao_cartoes_1960.py](auditoria_recuperacao_cartoes_1960.py). Testes: [test_auditoria_recuperacao_cartoes_1960.py](test_auditoria_recuperacao_cartoes_1960.py), **27 testes aprovados**. O índice completo fica em SQLite local, com cache limitado; as leituras dos gzip são sequenciais. Exigem-se 4 GiB livres no início e 2 GiB durante as etapas acompanhadas.

```text
python references/test_auditoria_recuperacao_cartoes_1960.py
python references/auditoria_recuperacao_cartoes_1960.py --out tmp/recuperacao_cartoes_1960_20260922/auditoria_NOVA
```

Usar pasta nova: o script recusa sobrescrita. Não executa R, targets, calibração ou exportação. A execução final desta auditoria está em `tmp/recuperacao_cartoes_1960_20260922/auditoria_completa_02/`: `resultado.json`, `alternativas.jsonl`, `indice127.sqlite` e `manifesto.json`. Durou 41,31 segundos, com RSS final de 60,95 MiB. Os hashes de todas as fontes antes/depois permaneceram iguais. O manifesto registra os hashes SHA256 de HHOLDA, quatro guias, correções, duplicatas, vínculos e gzip utilizados, além do hash do script, do arquivo de alternativas e do comando de reprodução. O caminho temporário das alternativas é referência de auditoria, não uma entrada exigida pelo consumidor R.

A contagem interna de duplicatas da busca é 2.834 linhas em perfis pendentes, contra as 2.836 do censo anterior: a diferença são exatamente **951432 e 951433**, previamente corrompidas e excluídas deste índice. **Nenhuma dessas duas pendências foi resolvida.** Os 1.417 perfis pendentes do censo global não foram reduzidos por essa diferença de escopo.

Esta nota demonstra a seleção do manifesto, não a reconstrução integral da base127. A execução do consumidor R, os microlotes, a integração ao pipeline e os limites restantes são registrados pela nota principal da rodada. As bases originais continuam preservadas; os demais vínculos, duplicatas e conflitos de geografia/convivência continuam exigindo decisão.
