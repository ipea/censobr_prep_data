# O que foi corrigido no texto, e o que a prova ainda não permite corrigir

Esta nota registra a implementação de 22 de setembro de 2026, posterior à investigação congelada. A fonte de **1,27%** é o arquivo histórico `HHOLDA.txt` que estamos preparando. A fonte de **25%** é outra versão dos microdados, disponível para algumas UFs, usada como testemunho para conferir registros danificados. Ela não é tratada como infalível: há respostas legíveis que diferem entre as duas versões.

Uma **linha** é uma posição no arquivo bruto, não uma pessoa acrescentada. Um **cartão familiar** é o registro que descreve a família; os registros de pessoas guardam as respostas dos seus integrantes. Pasta e boletim são códigos históricos que ajudam a identificar esse conjunto. Os nomes como `V208` são os nomes dos campos, neste caso a pergunta sobre nacionalidade. As mudanças abaixo estão no código e nos manifestos de decisão; não significam que toda a base publicada e os pesos já tenham sido reconstruídos.

## 1. Quatro nacionalidades agora têm recuperação localizada

Antes, essas quatro pessoas tinham o campo de nacionalidade em branco. Uma regra antiga preenchia esse campo quando o lugar de nascimento indicava Brasil. Isso confundia duas perguntas diferentes e havia sido retirado. A nova decisão não restaura essa regra: procura a mesma pessoa e sua família na outra fonte, confere as respostas preservadas e recupera somente o caractere faltante.

| Linha em HHOLDA | Questionário | Linha da pessoa na fonte de 25% | Antes → depois em V208 | Grupo conferido |
|---:|---|---:|---|---|
| 238423 | PE, pasta 22366, boletim 154 | 902375 | branco → `9` | 6 pessoas nas duas fontes |
| 540394 | Serra dos Aimorés, pasta 50048, boletim 043 | 34601 | branco → `9` | 10 pessoas nas duas fontes |
| 540399 | Serra dos Aimorés, pasta 50048, boletim 043 | 34598 | branco → `9` | O mesmo grupo de 10 pessoas |
| 540461 | Serra dos Aimorés, pasta 50048, boletim 051 | 34663 | branco → `9` | 8 pessoas nas duas fontes |

O código `9` significa brasileiro nato no [dicionário adotado pelo projeto](../read_guides/1960_amostra_127_codigos.csv). Cada alteração substitui exatamente o caractere 28 da linha e conserva os outros 61 caracteres. Não acrescenta pessoas, não exclui pessoas e não muda seus lugares de nascimento.

### Por que o grupo pode ser identificado mesmo tendo algumas respostas diferentes?

Em Serra dos Aimorés, outras pessoas do grupo têm respostas completas que aparecem uma única vez em cada uma das duas fontes da UF. Essas pessoas funcionam como **testemunhas da correspondência**: por exemplo, sexo, idade, parentesco, escolaridade e demais respostas, examinados juntos, tornam muito menos plausível confundir dois grupos. Não são uma identificação civil por nome ou documento.

O programa exige ao menos duas dessas testemunhas completas, além do número do questionário, do cartão, da geografia e da composição inteira. Para o boletim 043, usa 540390 e 540396; para o boletim 051, 540456 e 540457. A conferência preserva a quantidade de pessoas e exige que cada registro corresponda a um único registro do outro grupo: uma criança com respostas comuns não pode ser usada duas vezes para completar a família.

Isso permite distinguir duas decisões que não devem ser confundidas. É possível reconhecer o mesmo grupo sem concluir que todas as respostas de uma versão estão certas e as da outra estão erradas. Na linha 540397, a última série concluída (`V212`) é `1` contra `4`, e o grau do curso (`V213`) é `1` contra `2`. Na linha 540458, a atividade não econômica (`V220`) é `1` contra `5`. **Essas respostas não foram substituídas.** As diferenças são declaradas uma a uma na prova, e o teste confirma que os respectivos textos continuam idênticos aos de antes.

No caso pernambucano, a prova é diferente e foi explicitada. O próprio alvo 238423 é único pelos outros 24 campos, com o grupo completo de seis pessoas conferido. O distrito `X7` no chefe e no cartão contém um caractere inválido, não um segundo distrito validamente declarado. O distrito `07` da fonte de 25% também aparece nos demais integrantes. A correção de nacionalidade admite essa identificação geográfica localizada para conferir o grupo, mas **mantém literalmente `X7` no texto**. A geografia derivada e os vínculos foram implementados por decisões separadas, descritas na [nota dos vínculos](resolucao_residual_vinculos_1960.md). Não foi criada uma regra geral que transforme toda letra X em zero.

As diferenças `00`/`63` no ano do casamento (`V216`) dos integrantes que servem de contexto também permanecem escritas e registradas. Reconhecer a correspondência não autoriza recodificá-las.

### O que impede esta regra de preencher outros brancos indiscriminadamente?

O [manifesto de reparos](../read_guides/1960_amostra_127_reparos_fonte25.json) enumera as quatro linhas, seus textos antes/depois e os grupos das duas fontes. A função verifica os textos e as assinaturas dos arquivos, confere as pessoas que testemunham a correspondência e reconta sua singularidade nas fontes da UF. Uma diferença não prevista na prova, uma testemunha que não coincide, uma segunda ocorrência do perfil usado como testemunha exclusiva ou uma composição familiar diferente bloqueiam o reparo. Só os campos danificados explicitamente propostos podem mudar.

O critério ampliado está identificado como uma decisão nova. Os 33 reparos anteriores permanecem no manifesto, agora com 37 entradas; o relatório antigo não foi reescrito como se os quatro novos já estivessem aprovados naquela ocasião.

## 2. Dez danos deixaram de parecer respostas iguais

O problema aqui não era uma alteração do arquivo bruto, mas uma classificação enganosa. Certas linhas têm um dígito depois do sinal de salto, onde o preenchimento deveria ter terminado. Ao ler esse trecho inválido, o programa representava o campo como ausente (`NA`). Uma conferência anterior acabava comparando esse resultado com o espaço em branco da outra fonte e chamando os dois de iguais.

Por exemplo, 760807 conserva um `9` depois do sinal de salto. A outra versão não preserva esse `9`. O resultado da leitura pode ficar ausente porque o trecho é inválido, mas isso não demonstra que os textos sejam iguais. Apagar o dígito para fazer a comparação passar esconderia o problema.

As dez linhas são **760807, 760919, 760923, 760925, 761056, 761057, 761058, 806791, 806800 e 806801**. Agora recebem o diagnóstico explícito `dano_salto_nao_resolvido`. O texto original permanece intocado; não há texto corrigido proposto. A função rejeita uma decisão que tente, ao mesmo tempo, declarar esse dano não resolvido e fornecer um texto substituto.

Isso encerra a classificação incorreta, **não recupera respostas que a fonte disponível não permite demonstrar**. As pessoas e suas demais respostas continuam preservadas. Os campos invalidados pela leitura continuam distinguíveis por seus avisos; não são transformados em um “não se aplica” confiável. A investigação anterior também verificou que essas dez linhas e seus cinco boletins não fundamentavam os reparos, cartões recuperados, vínculos ou grupos de duplicatas então aprovados. Esse resultado está no [complemento congelado da investigação](investigacao_residual_texto_1960_complementos.json).

## 3. São Paulo: confirmar o grupo não é escolher a situação urbana ou rural

As pessoas 661580 e 661581 aparecem fisicamente depois do cartão 661571, boletim 118. Mas trazem boletim **119**, e no vínculo lógico já adotado pelo projeto pertencem ao cartão 695175, junto com o chefe 695176. Portanto não estamos propondo agora retirá-las silenciosamente de uma família para completar outra.

A conferência nova examinou os dois lados da possível confusão. O boletim 118 tem oito pessoas próprias, assim como a fonte de 25%. Se fossem acrescentadas as duas pessoas de boletim 119 apenas por proximidade no arquivo, passaria a dez e deixaria de conferir. Das oito próprias, seis têm os 25 campos iguais; nas duas restantes, apenas o ano de casamento difere entre `00` e `63`. Já o boletim 119 confere integralmente com as três pessoas da fonte de 25%, em todos os 25 campos pessoais.

Essa evidência confirma a separação dos grupos. Ela não determina, sozinha, qual situação é verdadeira: cartão e chefe da amostra de 1,27% registram município 7234 e situação rural; os outros dois integrantes e a fonte de 25% registram município 6234 e situação urbana. A decisão geográfica deve manter explícita essa divergência, não usar maioria de registros como se fossem votos independentes. Nesta frente textual, nenhuma dessas respostas foi substituída.

O [caderno delimitado de SP e GB](resolucao_residuais_1960_evidencias/texto_disposicao_sp_gb.json) preserva cartões, pessoas, vínculos lógicos e posições físicas do índice anterior às novas mudanças, com assinaturas dos arquivos. Ele contém também a composição própria do boletim 118, de modo que a alternativa rejeitada pode ser conferida diretamente.

## 4. Guanabara e Minas: candidatos fortes ainda não são provas suficientes

Na Guanabara, a pessoa 611254 conserva pasta `541  `, boletim `101` e distrito `18`. O cartão imediatamente anterior, 611250, é de boletim **290**: ligá-la a ele pela posição seria inadequado. Entre os cartões preservados com pasta começando por 541 e boletim 101, só 616230 tem o distrito 18; os outros dois têm distritos 41 e 26. O contexto também é coerente: a pessoa danificada é cônjuge de 31 anos, o chefe do candidato tem 31 anos, ambos registram casamento em 55 e dois filhos tidos/vivos, e há duas crianças no grupo.

O candidato 616230 é, portanto, muito melhor sustentado que o cartão anterior. A alternativa que ainda não foi eliminada não é outro cartão preservado com a mesma chave parcial: é um cartão histórico **ausente** de outra pasta `541??`, também de boletim 101 e distrito 18. Não há a fonte de 25% da Guanabara disponível para uma confirmação equivalente à paulista. Nesta frente não foi restaurada a pasta nem foi aprovado vínculo por essa hipótese. O texto danificado e a limitação ficam explícitos.

Em Minas Gerais, a linha 405458 tem a relação com o chefe em branco e idade ` 9`. O candidato MG 567047 preserva relação 7 e idade 79. Simular essas duas respostas faz as três pessoas do grupo coincidirem, mas o cartão familiar está ausente e sua própria recuperação ainda depende de excluir alternativas. Dos 289 cartões examinados, 405480 e 405486 não foram eliminados pelo critério adotado. A hipótese conjunta de reparar a pessoa e recuperar o cartão foi examinada. O raciocínio seria circular se a pessoa hipoteticamente corrigida fosse depois apresentada como prova independente da própria hipótese. Nada foi alterado nesse caso; a [prova de recuperação congelada](investigacao_residual_1960_evidencias/vinculos_recuperacao.json) conserva proposta e alternativas separadas.

Os fragmentos 855822, 951432 e 951433 também não receberam texto inventado. A investigação preservada documenta por que coincidências parciais não demonstram nem a composição completa nem, em alguns fragmentos, quantas pessoas históricas estão representadas. A ordem para resolver pendências não transforma perda de informação em uma resposta recuperável.

## 5. Como conferir a implementação

A [prova portátil das propostas](resolucao_residuais_1960_evidencias/texto_propostas.json) conserva os quatro textos originais e propostos, grupos completos, diferenças mantidas, pessoas que sustentam a correspondência, contagens de ocorrência e assinaturas das fontes antes da aplicação. A assinatura do CSV ali registrada pertence deliberadamente à versão anterior à correção; não deve ser atualizada para disfarçar essa cronologia.

O script `preparar_reparos_residuais_texto_1960.py` gerou a proposta e o patch antes da aplicação. Ele não altera diretamente os manifestos e rejeita uma segunda aplicação sobre os mesmos quatro alvos já presentes. O teste Python atual usa a prova portátil para conferir as decisões aplicadas e verifica literalmente os dez textos danificados no bruto:

```powershell
python -m unittest discover -s references -p test_preparar_reparos_residuais_texto_1960.py -v
```

Resultado: **seis testes Python passaram**. O teste R `test_reparos_residuais_texto_1960.R` inclui uma fase antes da mudança, que demonstrou o bloqueio anterior, e uma fase depois, com preservação de todos os demais textos e contraprovas de testemunhas insuficientes, testemunha incorreta, divergência omitida, distrito indevido, campo ignorado indevido e tentativa de apagar dano. **As fases antes e depois passaram pelo executor isolado, ambas com saída 0 e sem queda do R.** A fase posterior confirmou os quatro reparos, os dez danos preservados e as seis contraprovas. Os registros de execução estão em `tmp/resolver_residuais_1960_20260922/texto_antes.log` e `tmp/resolver_residuais_1960_20260922/texto_depois.log`; os testes legados continuam sob responsabilidade da integração sequencial.

O escopo desta nota é texto e identificação dos casos aqui enumerados. Não constitui liberação para reconstruir toda a base com pendências de integridade, nem para recalcular ou reutilizar pesos sobre identificadores familiares modificados. Essas etapas dependem da conferência integrada.
