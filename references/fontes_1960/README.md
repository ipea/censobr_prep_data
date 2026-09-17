# Fontes primárias do Censo de 1960

Os PDFs desta pasta **são versionados** (o `.gitignore` abre exceção para `references/**/*.pdf`). Este índice guarda a procedência de cada um para que qualquer pessoa possa baixá-los de novo.

| arquivo | o que é | de onde veio |
|---|---|---|
| `1965_resultados_preliminares_vol2.pdf` | IBGE, *Censo Demográfico: resultados preliminares*, Série Especial vol. II, março de 1965, 41 p. Descreve o desenho da amostra de 1,27% (pp. 5–6) e publica os sete quadros que servem de gabarito da calibração. | Biblioteca do IBGE, `liv84480` |
| `1960_serie_especial_vol4_favelas.pdf` | IBGE, *Censo Demográfico de 1960 — Favelas, Estado da Guanabara*, Série Especial vol. IV, 108 p. Resultados das favelas cariocas por zona e circunscrição censitária. Vem dos resultados **definitivos** (amostra de 25% e universo), não da amostra de 1,27%: a sua seção "Amostragem" é a mesma dos tomos do Volume I. | Internet Archive, item `censoesp1960vol4fav` |
| `1960_serie_nacional_vol1_brasil.pdf` | IBGE, *Censo Demográfico de 1960 — Brasil*, Série Nacional vol. I, 177 p., Fundação IBGE (anos 1970; presidência Isaac Kerstenetzky). Encerra os resultados definitivos: a "Apresentação" conta que onze UFs saíram em duas partes e as dezessete restantes em volume único apurado só pelo Boletim de Amostra. As tabelas 32, 33, 34, 37, 40 e 7 (por região e UF) estão transcritas em `references/censo_1960_resultados_definitivos_serie_nacional.csv` por `references/transcricao_1960_serie_nacional.py`. Sem camada de texto; o OCR do Archive está em `censodem1960br_djvu.xml`. | Internet Archive, item `censodem1960br` |
| `1969_ipea_processamento_amostra_1960.pdf` | IPEA, *Processamento de uma amostra do Censo Demográfico de 1960*, abril de 1969, 5 p. Registra as 29 caixas com ~56.000 cartões da subamostra do IPEA, a estratificação por grau de instrução do chefe, as dez subamostras pelo último dígito da enumeração e a gravação na fita "IPEA 10" no Rio Datacentro da PUC-Rio. | Repositório do IPEA, handle `11058/16462` |
| `1960_codigo_do_censo_demografico.pdf` | IBGE, Serviço Nacional de Recenseamento, *Código do Censo Demográfico — 1960*, 26 p. O manual de codificação do órgão central: quesito por quesito, o código de cada resposta. É a autoridade de `read_guides/1960_codigo_do_censo.csv`. Esta cópia **completa** o exemplar usado na primeira transcrição, que se interrompia no quesito J do domicílio (geladeira) e deixava sem fonte os quesitos L (televisão), M (total de cômodos) e N (peças servindo de dormitório) — é nela, p. 25, que está escrito que "não havendo indicação do número total de cômodos codifique-se 00" e "não havendo indicação do número de peças servindo de dormitório codifique-se 000". | Biblioteca do IBGE, `instrumentos_de_coleta/doc231.pdf` |
| `1970_sinopse_preliminar_df.pdf` | IBGE, *Sinopse Preliminar do Censo Demográfico: Distrito Federal*, VIII Recenseamento Geral, 27 p. É a fonte que resolve os distritos de Brasília em 1960. O seu **quadro 1**, "População recenseada nos Censos de 1960 e 1970, segundo as Regiões Administrativas", publica o 1960 repartido: Brasília 92.761 (Plano Piloto 71.728 mais Núcleo Bandeirante 21.033), Taguatinga 27.315, Sobradinho 10.217, Planaltina 4.651, Paranoá 3.576, Jardim 1.677, Gama 811 e Brazlândia 734 — soma que fecha exatamente nos 141.742 da Série Nacional. É a única publicação encontrada que abre o Distrito Federal por localidade: o tomo XIX do Volume I traz só os 40 quadros da unidade inteira, e os Anuários Estatísticos de 1961, 1962 e 1963 não nomeiam as cidades satélites. | Biblioteca do IBGE, `visualizacao/periodicos/311/cd_1970_sinopse_preliminar_df.pdf` |

## As Sinopses Preliminares de 1960 (`sinopse_preliminar_1960/`)

A pasta **não entra no git** — as dez unidades baixadas somam 226 MB, e Minas
sozinha tem 67. A procedência fica aqui para que qualquer pessoa as baixe de
novo com uma linha de `curl`.

São os volumes que o IBGE mimeografou por unidade da federação entre junho de
1961 (Espírito Santo) e março de 1962 (Paraná), antecipando os resultados do
Censo Demográfico. O tomo XII do Volume I descreve a série: *"reuniu
informações por Municípios e Distritos, sôbre o total da população, população
urbana e rural, e número de domicílios"*. O **quadro II** é justamente essa
tabela, e é a única fonte publicada que desce ao distrito para as dezessete
unidades apuradas só pelo Boletim de Amostra — os tomos do Volume I delas
trazem apenas os quadros da unidade inteira.

**Endereço:** `https://biblioteca.ibge.gov.br/visualizacao/periodicos/312/cd_1960_sinopse_preliminar_<uf>.pdf`,
com `<uf>` em minúsculas (`rj`, `mg`, `sp`…). O catálogo HTML da biblioteca
responde 403, mas os PDFs sob `/visualizacao/` são servidos sem autenticação.

**As 26 unidades existem; o Distrito Federal não.** Sondei as 27 e só `df` dá
404, sob todos os nomes plausíveis. É coerente: o Distrito Federal foi criado
pela Lei 3 752, de 14 de abril de 1960, depois de aprovado o plano da série, e
os seus distritos tiveram de ser reconstituídos por outro caminho — o quadro 1
da Sinopse Preliminar de **1970** (ver `1970_sinopse_preliminar_df.pdf`).

**Baixadas nesta pasta**, as dez unidades de que a auditoria dos nomes de
distrito precisa: `rj` (12,5 MB), `rn` (12,6), `pb` (15,2), `mg` (66,8),
`sp` (5,4), `rs` (40,1), `mt` (12,9), `es` (10,0), `sc` (21,9) e `gb` (28,4).
Todas com camada de texto em 100% das páginas.

**A camada de texto é ruim, e isso é esperado.** Na página de Campos, do volume
do Rio, só 3% das linhas fecham a aritmética `urbana + rural = total` como
saem da extração: dígitos colam em separadores (`10 4591` por `10 459`) e
letras substituem algarismos (`8o5` por `805`, `16o 31a` por `160 318`). É pior
que o volume do Paraná, em que 56% fechavam. A leitura, portanto, é visual
sobre as páginas renderizadas a 300 dpi, com a aritmética como validador — o
mesmo método que os dezenove municípios do Paraná já exigiram. Isso é viável
porque a auditoria é de quinze municípios, e não dos 2.434 do banco.

## A procedência dos microdados

As duas amostras de 1960 vieram no **mesmo pacote**, entregue por Suzana Cavenaghi: `Censo1960.zip`, 216.605.779 bytes, em `D:\Dropbox\Bancos_Dados\Censos\Censo 1960\0-Originais\Arquivos Recebidos - Suzana Cavenaghi\`. Dentro dele, lado a lado: `1%/HHOLDA.txt` (a amostra de 1,27%, que o repositório `antrologos/ConsistenciaCenso1960Br` publicou no GitHub e este pipeline baixa de lá) e `25%/` com dezessete arquivos `.Z` de Unix compress, um por unidade da federação, mais o dicionário `dicionario_60_last.doc` e os fac-símiles do Boletim de Amostra CD-2, do Boletim Geral CD-1 e das Instruções ao Recenseador.

Os dezessete `.Z` têm timestamp de 1998-09-09, somam 189,5 MB e descomprimem em 993.027.915 bytes de largura fixa, 54 caracteres por linha, 18.055.053 linhas. São a fonte da amostra de 25% e estão em `D:\Dropbox\Bancos_Dados\Censos\Censo 1960\4 - Ponderação do Censo de 1960\1-DadosOriginais\25%\`, com cópia já descomprimida em `D:\Dropbox\Bancos_Dados\Censos\Censo 1960\0-Originais\Abertura - 25%\Sample_25percent_someStates\raw_files\`. O layout de leitura é `Census1960_input_Sample_25.xlsx`, na mesma pasta, e o leitor de referência de 2019 é `Opening_25percentSample.R`.

O R não lê `.Z` (LZW). Os assets publicados no release `release_legacy` são, por isso, os dezessete `Censo.1960.amostra.25porcento.<uf>.gz` (155,7 MB), recompressão do mesmo conteúdo, conferida byte a byte contra os arquivos abertos nas dezessete unidades. Os `.Z` originais ficam como prova de proveniência.

Fora desta pasta, no Dropbox do usuário:

- `D:\Dropbox\Bancos_Dados\Censos\Censo 1960\4 - Ponderação do Censo de 1960\3-Publicações Originais dos Resultados\` — os 19 tomos do Volume I (resultados definitivos, Série Regional). A introdução de cada tomo traz a seção "Amostragem". Ela descreve a estimativa de razão em 48 grupos (situação × sexo × posição na família × idade) e **nomeia as unidades a que essa estimativa se aplica: as onze cujos microdados de 25% não sobreviveram**. Para as dezessete restantes o texto diz que "todos os dados foram obtidos usando-se os formulários C D 2 — Boletim de Amostra" e que "o processo de estimativa de razão baseou-se na população urbana e rural constante das Sinopses Preliminares", com pesos inteiros próximos à razão fracionária, atribuídos aleatoriamente.
- `D:\Dropbox\Bancos_Dados\Estatisticas Historicas_SemOCR\Censos\Censo 1960\` — entre outros, `cd_1960_sinopse_preliminar_br.pdf`, a *Sinopse Preliminar do Censo Demográfico: Brasil* (maio de 1962, 84 p., com camada de texto). O seu **quadro XIII** desce ao município — área, densidade e população total e urbana por unidade da federação, zona fisiográfica e município — e é a safra a que o IBGE declarou ter ancorado a estimativa de razão das dezessete unidades. Dá o Distrito Federal numa linha só: 141.742 habitantes, 89.698 urbanos, todos na sede municipal. Os volumes **por estado**, mimeografados entre junho de 1961 e março de 1962, são os que descem ao **distrito**, e não estão neste acervo.
- `D:\Dropbox\Bancos_Dados\Censos\Censo 1960\2-Arquivos Auxiliares\` — questionário, manual do recenseador, ABC do recenseamento, Código do Censo, Código para uso da Agência Municipal de Estatística e Código de Zonas Fisiográficas, Municípios e Distritos.
