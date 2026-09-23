# Revisão independente: integração final e guardas de 1960

Data: 23/09/2026. Não executou R nem alterou código de produção. Revisão do diff das funções de reparo, recuperação de cartões e calibração25, acompanhada de verificações Python somente leitura.

## Conclusão

Nenhum defeito analítico bloqueante foi encontrado nas novas guardas. A cadeia portátil vigente passou: **41 cartões, 103 pessoas preexistentes, 15 documentos JSON ativos e 410 vínculos de hashes**. Os nove casos compostos e os dois casos de chave diferente são literalmente iguais às regras do manifesto. Nenhuma dependência declarada em `fontes` aponta para `tmp/`.

O índice127 final foi reaberto somente leitura. As composições completas de 24 campos dos sete concorrentes decisivos foram recontadas em toda a base atual, preservando multiplicidades: 405480, 405486, 700142, 794622, 1060560, 1060755 e 1060763 continuam únicos. Seus cartões e pessoas são intactos, pertencem à mesma chave/geografia e não incluem alvos órfãos nem dependem dos reparos novos. A única divergência pessoal admitida permanece V216 = 00/63; o caso PR com 19/17 não entrou.

## Invariantes revisadas no código R

- Reparo MG405458: restrição explícita de alvo, chave, três pessoas e campos V203/AGE; preservação dos caracteres legíveis e do tipo3; duas testemunhas distintas, intactas e anteriores ao reparo, sem usar o alvo; conjunção única e cardinalidade da chave conferidas nas duas fontes. O pareamento integral posterior continua obrigatório.
- Cartões compostos: hashes atuais das fontes internas, regra localizada igual ao manifesto, exame de todos os concorrentes registrados e nenhuma alternativa remanescente; releitura dos originais e aplicação apenas de correções vigentes; chave/geografia própria dos membros; corpo familiar de15campos; ordens, redundâncias e cardinalidade25; multiconjunto24 e pareamento que conserva multiplicidades; divergência V216 restrita a00/63. As pessoas do cartão recuperado continuam exigindo correspondência nos25campos.
- Calibração25: unicidade municipal dentro daUF; recusa de população conhecida negativa ou não finita; recusa de total conhecido diferente da soma urbana+rural. Ausências legítimas continuam admitidas, inclusive o tratamento específico da Serra dos Aimorés. A guarda não é uma certificação da transcrição histórica, apenas da coerência numérica examinada.

## Limites preservados

A conferência de unicidade nacional25 já tinha sido executada nas17fontes na revisão independente anterior, com reagrupamento de chave partida; não foi repetida nesta última etapa porque os hashes das fontes são os mesmos. O ramo R confere as provas portáteis e seus originais, mas não refaz a busca nacional nem reconstrói seu universo de candidatos. Essa divisão de responsabilidade está documentada; hashes atestam a versão das entradas, não substituem a investigação já registrada.

Excluir todos os concorrentes encontrados demonstra ausência dentro das buscas especificadas, não inexistência histórica absoluta de qualquer cartão perdido ou ilegível. A ressalva está preservada no manifesto. A revisão estática e as verificações Python não equivalem a executar a suíte R; essa execução permanece com o coordenador.

## Testes nominais

Após conferir o CSV vigente, foram atualizados somente `test_novas_duplicatas_1960.R` e `test_resolucao_duplicatas_1960.R`, por autorização coordenada: 6.463 decisões e 3.727 manter. As 2.736 remoções e o fixture histórico954/1.908/490 permanecem inalterados. O diff passou em `git diff --check`. Os testes de cartões e reparos usam o tamanho do manifesto e não têm expectativas nominais32/80/37 que precisem ser substituídas.

Script e resultado: `fechamento_integral_1960_duplicatas_revisao_final.py` e `tmp/fechamento_integral_1960/duplicatas/revisao_final/resultado.json`. SHA-256 do índice atual examinado: `0df274929772fb14720a0f61b2f8de6a3486791dc31597f9a420022018f59ce7`.

Reconferência após a ampliação final das listas superiores de dependências: `python references/fechamento_integral_1960_duplicatas_revisao_final.py --out tmp/fechamento_integral_1960/duplicatas/revisao_final02`. Resultado **PASS**, novamente15 JSON/410 vínculos de hashes,41 cartões/103 pessoas e sete concorrentes únicos na base127 atual. Resultado novo preservado em `tmp/fechamento_integral_1960/duplicatas/revisao_final02/resultado.json`; o resultado anterior não foi sobrescrito. O manifesto de cartões examinado nesta reconferência tem SHA-256 `baaebe8230266f5e5c145f7b4ce5ba40b9eb807cbe98b23043fa3eef9e4792ef`.
