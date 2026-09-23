# RS8405/03: Morro Reuter é plausível, mas a associação permanece sem prova direta

Data: 23/09/2026. Nenhum guia, manifesto, código R ou parquet foi alterado.

## Resultado

Não é correto afirmar como fato comprovado que o código 03 seja apenas uma repartição interna da sede. Também não foi encontrada, nesta investigação, prova suficiente para converter automaticamente o nome ausente em Morro Reuter. A hipótese de Morro Reuter ganhou evidência documental independente, mas a passagem do nome ao código censitário de 1960 ainda exige uma correspondência que os documentos examinados não fornecem.

## Fontes e contraprovas

1. O original do **Código de Zonas Fisiográficas, Municípios e Distritos**, página impressa 284/PDF 285, traz literalmente RS8405, Dois Irmãos = 01 e Santa Maria do Erval = 05. Não há linha apagada, recorte ou falha de OCR onde deveria estar Morro Reuter. A transcrição existente está fiel a essa página.
2. A **Sinopse Preliminar RS**, quadro II, página impressa 22/PDF 27, publica somente dois distritos: Dois Irmãos, 6.621 habitantes, e Santa Maria do Erval, 5.098, total municipal de 11.719. Sua súmula territorial na página impressa 70/PDF 75 também descreve a criação municipal com apenas esses dois distritos. Portanto a omissão não está só na tabela numérica.
3. A publicação contemporânea do CNE/IBGE **Divisão territorial do Brasil**, de 1961, contradiz aquela cobertura nominal: página impressa 14/PDF 19 documenta Morro Reuter, lei municipal 264 de 24-III-1956. O quadro em 1º-VII-1960, página impressa 125/PDF 130, inclui expressamente os três distritos de Dois Irmãos. Seus números 101, 102 e 103 são ordinais estaduais, não os códigos 01, 03 e 05 dos microdados. [Livro original, liv13611](https://biblioteca.ibge.gov.br/visualizacao/livros/liv13611.pdf).
4. Os históricos territoriais do IBGE confirmam a criação de Morro Reuter em 1956, sua transferência para Dois Irmãos em 1959 e a presença dos três distritos em 1960. Não publicam o código censitário 03. [Morro Reuter](https://www.ibge.gov.br/biblioteca/visualizacao/dtb/riograndedosul/morroreuter.pdf), [Dois Irmãos](https://www.ibge.gov.br/biblioteca/visualizacao/dtb/riograndedosul/doisirmaos.pdf).
5. O cadastro territorial de **1970** no acervo local identifica expressamente Morro Reuter com código 03, junto a Dois Irmãos 01 e Santa Maria do Erval 05, mas sob município 202/microrregião 852. Planilha `Rio Grande do Sul.xls`, aba de mesmo nome, A59:D62. É evidência de continuidade possível, não documento da equivalência operacional em 1960.

## Recontagem dos brutos de 25%

Foram feitas duas leituras integrais somente da fonte RS, preservando chaves, textos e multiplicidades. Todas as cardinalidades dos cartões-alvo concordam com seus registros pessoais. Os números abaixo são cartões/boletins, não uma nova demonstração de domicílios físicos distintos.

| Distrito bruto | Cartões | Pessoas | Situação dos cartões | Pastas |
|---|---:|---:|---|---|
| 01 | 207 | 854 | 120 urbana, 29 suburbana, 58 rural | 82950 |
| 03 | 158 | 836 | 158 rural | 82950, 82952 |
| 05 | 222 | 1.239 | 18 urbana, 204 rural | 82952, 82954 |

O código 03 não é ruído isolado: há um conjunto coerente de 158 cartões. Isso não nomeia o distrito. Ele estar todo na situação rural tampouco permite escolher entre Morro Reuter contabilizado ruralmente e uma subdivisão operacional da parte rural da sede. Não existem cartões RS8405 no índice127 construído antes desta integração, portanto a outra amostra não oferece uma testemunha local independente.

As contagens aproximadas comparadas à Sinopse não distinguem as hipóteses: ambas conservam a soma dos códigos 01+03. A hipótese de agregação de Morro Reuter na linha da sede e a hipótese de repartição operacional da sede produzem os mesmos totais observados. Os dados pessoais não trazem nomes de localidades ou endereços que decidam entre elas. O código 03 de 1970 favorece a primeira hipótese, mas a continuidade dos códigos entre as duas operações não está demonstrada por esse arquivo.

## O que falta

Uma lista operacional ou errata do Censo1960 que associe **8405/03 a Morro Reuter**; alternativamente, mapa/caderneta de setor, cadastro nacional de pastas 82950–82952 ou boletim identificado que ligue nominalmente esses cartões ao distrito. Uma prova da identidade histórica do distrito sem a ligação ao código não basta. A correção defensável agora é retirar o caráter categórico de “código interno da sede” na nota de pendência, conservando o nome não atribuído e registrando Morro Reuter como hipótese documentada. Essa correção não foi aplicada por esta frente.

## Reprodutibilidade

`fechamento_integral_1960_geografia_rs_fontes.py` registra hashes e páginas, gera recortes dos originais e extrai as células de 1970 sem editar suas fontes. `fechamento_integral_1960_geografia_rs_contagem.py` usa os guias existentes para conferir os cartões de RS8405. Resultados em `tmp/fechamento_integral_1960/geografia_rs/`: `fontes_locais.json`, `cadastro1970_rs.json` e `contagem_rs8405.json`. O PDF `liv13611.pdf` foi obtido do endereço primário acima, 8.047.622 bytes, SHA-256 `e2ec8c1ada31a216cff61be11108bf5e9946a3ba753487a8eb2f6b782c4d2935`.
