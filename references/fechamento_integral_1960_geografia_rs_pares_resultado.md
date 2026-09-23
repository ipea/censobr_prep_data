# Horizontina e Tenente Portela: o cadastro de 1970 não fecha os códigos de 1960

Data: 23/09/2026. Conferência documental limitada, sem modificar guias, limiares, dados ou produção.

## Resultado

Horizontina ganhou uma terceira evidência favorável à leitura posicional: o cadastro de 1970 registra Pitanga = 07 e Pranchada = 09. A lista de distritos permaneceu a mesma de 1960 a 1983, segundo o histórico do IBGE. Isso não exclui a hipótese de que a codificação tenha sido reorganizada entre as operações de 1960 e 1970. Tenente Portela não ganhou sequer uma equivalência numérica transferível: em 1970, Vista Gaúcha = 13 e Derrubadas = 11, enquanto Miraguaí já era outro município. Nenhum dos dois casos foi promovido a resolvido.

## Original de 1960, inspecionado visualmente

As referências antigas 278 e 280 são páginas do PDF, não as páginas impressas. A página PDF 278/impressa 277 traz Horizontina 8312; a PDF 280/impressa 279 traz Tenente Portela 8325. Ambas foram renderizadas diretamente do original e lidas, sem depender da transcrição ou de OCR.

| Município | Códigos impressos em 1960 | Cadastro de 1970 |
|---|---|---|
| Horizontina | 01 Horizontina; 03 Cascata; 05 Doutor Maurício Cardoso; **09 Pitanga; 07 Pranchada** | 01 Horizontina; 03 Cascata; 05 Doutor Maurício Cardoso; **07 Pitanga; 09 Pranchada** |
| Tenente Portela | 01 Tenente Portela; 03 Derrubadas; **07 Miraguaí; 05 Vista Gaúcha** | 01 Tenente Portela; 03 Barra do Guarita; 05 Capoeira Grande; 07 Cedro Marcado; 09 Daltro Filho; **11 Derrubadas; 13 Vista Gaúcha** |

A planilha local `Rio Grande do Sul.xls`, aba `Rio Grande do Sul`, tem cabeçalhos MICRO/MUNICÍPIO/DISTRITO/NOME. Horizontina está em A623:D628, micro 867/município 708. Tenente Portela está em A654:D661, micro 867/município 717. Miraguaí figura como município próprio, micro 868/município 810, em A724:D727, com os distritos 01 Miraguaí, 03 Sítio Gabriel e 05 Tronqueiras. Logo, comparar apenas a coluna DISTRITO entre os anos confundiria chaves municipais diferentes.

## Transformações territoriais e limite da inferência

O [histórico de Horizontina do IBGE](https://www.ibge.gov.br/biblioteca/visualizacao/dtb/riograndedosul/horizontina.pdf) situa a criação dos quatro distritos em 15/04/1957 e mantém os cinco nomes até 1983. A emancipação de Doutor Maurício Cardoso com Pitanga e Pranchada, lei estadual 8.455 de 08/12/1987, é posterior a 1970: não explica uma diferença entre os códigos de 1960 e 1970. Porém a estabilidade territorial não demonstra estabilidade dos identificadores operacionais. Duas histórias permanecem compatíveis: código posicional já usado em 1960; ou código impresso usado em 1960 e renumerado alfabeticamente até 1970. A planilha não informa a data nem a razão da troca.

O [histórico de Tenente Portela do IBGE](https://www.ibge.gov.br/biblioteca/visualizacao/dtb/riograndedosul/tenenteportela.pdf) documenta novos distritos em 1962–1963, extinção de Sítio Biron em 1964 e emancipação de Miraguaí pela lei estadual 5.152, de 15/12/1965. O próprio cadastro de 1970 demonstra que os códigos remanescentes foram reorganizados. Não é possível retroceder Vista Gaúcha = 13 para escolher entre 05 e 07 sem documento intermediário.

Os históricos descrevem atos e nomes, não os códigos operacionais do Censo1960. Para fechar, seria necessária errata/lista operacional de 1960, correspondência explícita entre codificações, ou boletins/cadernetas/mapas de setor identificados nominalmente. A insuficiência das duas métricas demográficas anteriormente usadas não autoriza afirmar que toda medida imaginável seria incapaz de separar Tenente Portela; apenas que aquelas comparações não o fizeram. Não se alterou nenhum limiar para favorecer um caso.

## Reprodutibilidade

Script: `fechamento_integral_1960_geografia_rs_pares.py`. Prova de fontes, hashes, células e textos integrais dos históricos: `tmp/fechamento_integral_1960/geografia_rs/horizontina_tenenteportela_fontes.json`. Recortes verificados: `codigo_original_p278.png` e `codigo_original_p280.png`. As habilidades de leitura de PDF e planilhas foram usadas somente para inspecionar originais e extrair células; nenhum documento-fonte foi editado.
