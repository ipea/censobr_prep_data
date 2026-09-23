# O que as fontes adicionais esclarecem — 22/09/2026

Esta é uma investigação, não uma alteração da base. O programa, os registros e os pesos de produção não foram modificados. O resultado completo está no [relatório integrador](investigacao_residual_registros_1960_20260922.md).

## Uma pendência documental pode ser reduzida: idade ignorada em atividade e renda

O relatório anterior procurou uma frase que dissesse se as pessoas cuja idade foi declarada ignorada entravam nos quadros 3 a 5 do volume preliminar. Não encontrou essa frase e deixou os três quadros pendentes. Essa busca era insuficiente: faltava conferir a relação aritmética entre as próprias tabelas publicadas.

O quadro 1, página impressa 7/PDF 20, apresenta **70.119.071 pessoas presentes**. Destas, 11.196.313 têm de 0 a 4 anos e 10.161.291 têm de 5 a 9 anos. A última faixa combina expressamente as pessoas de 70 anos ou mais **e as de idade ignorada**. Portanto, retirar apenas as duas primeiras faixas mantém as idades ignoradas:

```text
70.119.071  total de presentes
11.196.313  menos as pessoas de 0 a 4 anos
10.161.291  menos as pessoas de 5 a 9 anos
──────────
48.761.467  restante, incluindo a faixa que contém as idades ignoradas
```

**48.761.467 é exatamente o total publicado nos quadros 3 e 4**, de atividade e renda. Também é o total de 10 anos e mais do quadro 2. Não se trata de aproximar os microdados aos totais: a igualdade está nas tabelas originais, antes de consultar qualquer peso atual.

| Domínio publicado | Total menos as faixas de 0 a 9 anos | Quadro 3 | Quadro 4 |
|---|---:|---:|---:|
| Brasil |48.761.467|48.761.467|48.761.467|
| Nordeste |10.628.579|10.628.579|10.628.579|
| Leste |17.172.324|17.172.324|17.172.324|
| Sul |17.282.772|17.282.772|17.282.772|

A mesma igualdade vale separadamente para homens e mulheres: **12 conferências nos quatro domínios publicados**. São verificações da coerência interna da mesma publicação, não 12 pesquisas independentes. Norte e Centro-Oeste também fecham, mas seus valores na transcrição do projeto são calculados por diferença; não acrescentam evidência independente. As 16 páginas dos quadros 1 a 4 desses quatro domínios foram conferidas visualmente, além do cálculo automatizado.

**Conclusão:** há evidência interna forte de que o universo de comparação dos quadros 3 e 4 deve incluir idade *declarada* ignorada. É uma conclusão pela estrutura e pela aritmética da publicação, não uma citação de instrução textual nem uma importação da convenção dos resultados definitivos. Ela não descobre a idade dessas pessoas e não permite tratar uma idade danificada como declarada ignorada.

**Como o código ainda está:** em `R/microdata_1960_amostra_127.R`, a formação de `q3` exige idade conhecida de pelo menos 10 anos; `q4` usa esse mesmo conjunto. A validação sinaliza a idade ignorada como inclusão pendente. Na próxima implementação, deve-se incluir explicitamente `V204=9` nesses dois universos, conservando os bloqueios separados para idade danificada, atividade/renda não classificável e peso inválido. Não se alteram as respostas originais. No índice atual, depois das remoções já aprovadas, há **1.223 registros de pessoas presentes com V204=9**; esse número ainda conserva repetições pendentes e não é uma estimativa populacional.

**O quadro 5 continua diferente:** ele conta residentes, não presentes. Seu total brasileiro, 40.189.391, não é intercambiável com os 40.187.590 presentes de 15 anos e mais do quadro 2. A igualdade demonstrada acima não resolve a regra das idades ignoradas para estado conjugal. Seria necessário um total de residentes por idade comparável ou uma instrução específica de apuração. Não se deve estender a conclusão por conveniência. Isso também não demonstra que as idades ignoradas devam ser excluídas do quadro5; a diferença de1.801 mistura universos de presença e não mede o número de idades ignoradas.

Uma segunda conferência recalculou independentemente as12 relações e as somas das faixas, dos ramos e das classes de renda. A evidência é agregada: não rastreia cada indivíduo incluído, nem documenta o algoritmo histórico de apuração. A inclusão explícita deV204=9 é a proposta operacional sustentada por essa inferência, não uma instrução textual encontrada.

Fonte: [volume preliminar do IBGE](https://www.ibge.gov.br/biblioteca/visualizacao/periodicos/68/cd_1960_v2_resultados_preliminares.pdf), páginas impressas 7–10, 17–20, 26–29 e 35–38; [cópia local](fontes_1960/1965_resultados_preliminares_vol2.pdf). A habilidade de leitura de PDF foi usada para extrair o texto e conferir as imagens, evitando que um erro de reconhecimento de dígitos fosse tratado como evidência.

## Voltar à cópia recebida não recuperou bytes perdidos

A comparação foi feita novamente, arquivo por arquivo, em vez de confiar apenas na nota de procedência anterior:

- O HHOLDA dentro do pacote original `Censo1960.zip` é idêntico ao arquivo bruto local: 68.756.992 bytes, 1.074.328 linhas e SHA-256 `6449ca06c9086bbb0474481827f0efff98a0d9489838f322b4a69e489a42c44c`.
- Os 17 arquivos locais de 25%, descomprimidos, têm os mesmos bytes das 17 cópias preservadas já abertas no acervo original: 18.055.053 linhas ao todo. Nesta rodada, a comparação não fez uma nova descompressão dos `.Z`; confrontou os `.gz` atuais com os arquivos anteriormente descomprimidos e preservados.
- O histórico público do caminho `Original Files/HHOLDA.txt` apresenta um único commit de conteúdo, `af4714a1de468bd1ee94d5df432d10fd5cd60b1b`, de 19/08/2018. A única ramificação e a cópia pública derivada consultada têm o mesmo arquivo. No GitHub, a quebra de linha é LF; localmente, CRLF. Ao comparar com LF, o objeto Git calculado é `c8742b846e3e0466dd71cb56075896c64ebd8938`, idêntico aos dois repositórios. A diferença de tamanho não é uma versão com pessoas diferentes.

Assim, os danos examinados já estão nessas cópias preservadas. Isso não data a origem histórica do dano, nem prova que não exista outra fita, cópia particular ou acervo não consultado. Apenas elimina essas cópias específicas como uma fonte de bytes mais íntegros.

O programa SAS `TESTE_peso1%.sas`, datado de 10/06/2003 e incluído no pacote, chama as posições 56–62 de `NUMDOM`. Isso reforça que o número ao fim da linha é domiciliar, não um identificador individual que permita separar dois irmãos com respostas iguais. Esse leitor também tem regras próprias de idade; não é uma especificação de como o IBGE tabulou em 1965.

Fontes públicas consultadas: [repositório original](https://github.com/antrologos/ConsistenciaCenso1960Br), [histórico do arquivo](https://github.com/antrologos/ConsistenciaCenso1960Br/commits/master/Original%20Files/HHOLDA.txt) e [cópia derivada](https://github.com/guilhermejacob/ConsistenciaCenso1960Br). A consulta foi somente de leitura; nenhum contato ou pedido de dados foi enviado.

## O catálogo atual do IPUMS não preenche as onze UFs ausentes

A documentação atual do [IPUMS para Brasil 1960](https://international.ipums.org/international-action/sample_details/country/br) enumera as mesmas onze UFs ausentes da fonte de 25% e informa 14.983.769 registros pessoais. Esse número é igual a 18.055.053 registros locais menos 3.071.284 cartões. A coincidência de tamanho e cobertura **não demonstra igualdade registro a registro**, mas não oferece evidência de uma nova fonte para aquelas UFs. O catálogo antigo do [Banco Mundial](https://microdata.worldbank.org/catalog/450) descreve uma versão menor, de 3.001.439 pessoas; não deve ser confundido com a documentação atual do IPUMS. Não foi solicitado nem baixado um extrato licenciado.

## Reprodução e limites

Auditor: [investigacao_residual_fontes_1960.py](investigacao_residual_fontes_1960.py). Testes: [test_investigacao_residual_fontes_1960.py](test_investigacao_residual_fontes_1960.py). Resultado desta execução: `tmp/investigacao_residual_1960_20260922/fontes_integral_02/fontes.json`, com assinaturas, contagens, identidades aritméticas e páginas renderizadas. O caderno portátil desta rodada preserva o resultado resumido, sem copiar o acervo de microdados.

Para conferir as relações publicadas, sem acesso ao acervo particular:

```powershell
python -m unittest discover -s references -p test_investigacao_residual_fontes_1960.py
python references/investigacao_residual_fontes_1960.py --out tmp/NOVA_CONFERENCIA_FONTES --render
```

A comparação de procedência requer os argumentos `--archive` e `--raw25` apontando para as cópias preservadas. A contagem de registros com idade ignorada requer `--index127` e depende do índice correspondente aos manifestos atuais. Nada desse procedimento executa R ou recalcula pesos.
