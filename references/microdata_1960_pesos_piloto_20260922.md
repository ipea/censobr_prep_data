# Pesos de 1960: piloto isolado e metadados de Fernando de Noronha

**Materialização completa também concluída:** estão prontas 34 cópias completas separadas, reunindo os novos pesos às respostas originais das 17 UFs. O [índice dos arquivos conferidos](../tmp/execucao_1960_20260922/pesos25_completo_15_fixo_01/indice_34_parquets_completos.json) identifica FN do piloto, SE recomposto e as outras 15 UFs. Os 34 arquivos novos e os 68 originais foram reconferidos, sem alterações nos originais. A [nota narrativa](execucao_correcao_1960_20260922.md) explica a recomposição, o relatório integrado e os bloqueios ainda existentes em 1,27%. As saídas reduzidas mencionadas abaixo continuam auxiliares, mas já não são a única entrega de dados disponível.

**22/09/2026 — estado atualizado.** O piloto real de25% em Fernando de Noronha/Sergipe e o percurso reduzido SE+15 UFs restantes terminaram com exit0. Ha pesos recalculados para as17 UFs de25%, somente em staging; nenhum parquet de producao foi substituido. Os arquivos reduzidos sao auxiliares parciais, nao microdados completos. A amostra de1,27% nao foi recalibrada. Variancias continuam adiadas.

## Evidencias e resultados do piloto de 25%

Runner: `references/recalibrar_pesos_25_piloto_1960.R`, executado pelo processo isolado com autorizacao explicita e `PROCESSOR_ARCHITECTURE` informado apenas ao filho. Log: `tmp/execucao_1960_20260922/preparacao_piloto_pesos25_01.log`.

Raiz dos artefatos: `tmp/execucao_1960_20260922/pesos25_piloto_20260922_092755/`.

| Conferencia | Fernando de Noronha | Sergipe |
|---|---:|---:|
| Domicilios | 75 | 44.059 |
| Pessoas listadas | 307 | 209.544 |
| Presentes diretos, V202 em 1/2/5/6 | 297 | 207.246 |
| Domicilios com contagem informada igual a contagem direta | 75 | 44.059 |
| Controles efetivamente usados | 4 | 146 |
| Iteracoes de Newton | 5 | 6 |
| Maior residuo relativo absoluto | 4,65e-16 | 1,21e-14 |
| Menor / maior peso novo | 4 / 4,958680 | 1,561066 / 10,478809 |
| Maior mudanca absoluta do peso | 1,07e-14 | 0,0305157 |
| Pesos IBGE inteiros alterados | 0 | 0 |

Em FN, a diferenca e apenas numerica. Em SE, o universo correto inclui 25 leitores presentes cuja idade foi explicitamente declarada ignorada. Nos controles de leitores:

| SE | Alvo | Pesos antigos, universo corrigido | Pesos novos |
|---|---:|---:|---:|
| Homens | 103.279 | 103.326,566380 | 103.279 |
| Mulheres | 115.189 | 115.237,183422 | 115.189 |

Cada UF tem, em `diagnosticos/<uf>/`, `contagem_presentes_por_domicilio.csv`, `controles.csv`, `pesos_domicilios_antes_depois.csv` e validacoes completas em `antes/` e `depois/`. Os controles registram suporte pessoal/domiciliar, alvo, soma pelo desenho, soma anterior, soma posterior, limites isolados e residuo. O arquivo `status.csv` registra as duas UFs concluidas. Os arquivos novos mantem os nomes canonicos em `pesos/<uf>/`.

O manifesto comparou tres arquivos R, dois guias/referencias e oito parquets originais: **13/13 hashes iguais entre inicio e fim do piloto**. Uma posterior correcao de metadados no codigo de 1,27%, descrita abaixo, ocorreu depois desse fechamento; nao invalida a prova de preservacao durante o piloto. Os timestamps dos manifestos delimitam aproximadamente nove segundos de execucao, nao uma medicao de pico de memoria.

Convergencia certifica as restricoes usadas, nao todas as tabelas nem a integridade dos registros. A validacao T7 de SE continua marcando seis celulas com classificacao incompleta em cada peso; nao se transformou essa pendencia em resultado aprovado. A politica existente de excluir idade declarada ignorada da margem etaria de 25% nao foi redesenhada: a correcao aqui foi sua inclusao explicita nos leitores. Controles da Serie Nacional nessas 17 UFs sao referencias amostrais estimadas.

## Correcao dos metadados finais de FN na amostra de 1,27%

O solver definitivo ja usava `d_def = 4` em FN. O codigo, entretanto, gravava `censobr_weight_desenho = 1/0,0127` e calculava `censobr_weight_fator = w/(1/0,0127)`. A correcao posterior ao piloto grava a mesma base realmente usada no ajuste final: `censobr_weight_desenho = d_def` e `censobr_weight_fator = w/d_def`, propagadas do domicilio para suas pessoas.

**Nao se alterou a politica preliminar:** `censobr_weight_1965` continua calculado com base `d = 1/0,0127`; `censobr_weight_1965_fator` continua sendo a razao contra essa base preliminar. Assim, especificamente em FN, o fator1965 nao e a razao contra a coluna que agora descreve a base do peso definitivo. Nenhuma dessas colunas foi regravada nos parquets reais de 1,27%.

O teste sintetico completo verifica em FN peso final 4, base final 4 e fator final 1, mantendo peso1965 em 1/0,0127 e fator1965 em 1. Um segundo caso, fora de FN, verifica que as bases continuam 1/0,0127. Log aprovado, exit 0: `tmp/execucao_1960_20260922/preparacao_testes_pesos_fn_metadata_01.log`. Os demais testes de guardas e I/O sintetico passaram em `preparacao_testes_pesos_arrow_05.log`.

Uma revisao independente encontrou ainda um diagnostico que dividia o alvo por `amostra * 78,74` em toda UF, exibindo cerca de 0,05 em FN quando a razao efetiva era 1. O diagnostico passou a dividir o alvo por `crossprod(X, base_def)`, usando base4 em FN e 1/0,0127 nas demais UFs. Isso corrige o rotulo/numero informado, nao os pesos nem as restricoes. O teste FN/foraFN falhou antes da correcao e passou depois; suite completa com I/O exit0 em `tmp/execucao_1960_20260922/pesos_diagnostico_fn_depois_01.log`. Os rotulos do dicionario de compilacao tambem explicitam a excecao FN na base definitiva e a base historica propria do fator1965.

## Dimensionamento e proposta anterior a execucao

Uma pre-conferencia independente das entradas das17 UFs terminou sem excecoes nas verificacoes executadas: chaves/vinculos existentes, contagens domiciliares versus pessoais de listadas/presentes/residentes, codigos de presenca/situacao/idade/alfabetizacao nos controles e coerencia de municipio/situacao entre pessoa e domicilio. Evidencia: `tmp/execucao_1960_20260922/preflight_25_classificacoes_v2_resumo.json`. Essa conferencia, isoladamente, nao certifica a identidade historica dos vinculos nem suporte ou convergencia dos controles. Naquele momento o solver real so havia sido demonstrado em duas UFs; a execucao posterior das demais esta documentada ao final.

Ordem sugerida: `df, sa, mt, rn, al, go, pb, ce, rj, pe, pr, rs, ba, mg, sp`, serialmente, com diretorio novo por execucao, diagnosticos antes/depois e hashes. A ordem crescente aproximada pode ser ajustada pelas contagens reais; o ponto essencial e deixar MG/SP depois das menores. Nao ampliar limites nem retirar automaticamente controles sem suporte se outra UF falhar. Uma falha deve interromper aquela execucao e conservar o diagnostico, sem promover resultados parciais a arquivos finais.

O caminho pesado continua lendo as tabelas completas e materializando a copia de presentes. Pelos schemas e numeros de linhas, apenas os vetores iniciais de pessoas+domicilios representam aproximadamente **60 MiB em SE, 708 MiB em MG e 957 MiB em SP**, antes de conteudo das strings, copias, colunas auxiliares, matriz e buffers Arrow. SP tem 3.319.710 pessoas e 740.936 domicilios. Esses numeros sao limites inferiores, nao picos medidos. Como outros trabalhos do usuario ocupam memoria, nao se deve encerrar processos existentes nem depender de toda a RAM instalada estar livre.

Alternativa proposta e posteriormente executada: projetar somente as colunas abaixo em arquivos auxiliares novos, preservando ordem, tipos e numero de linhas; executar **a mesma funcao de pesos**, sem alterar formulas, limites ou controles; conservar a saida como tabelas parciais de calculo, sem compilar nem publicar como microdados completos.

- Domicilios (8): `UF`, `censobr_idhousehold`, `V118`, `v001`, `code_muni_1960`, `censobr_n_presentes`, `V101`, `V102`.
- Pessoas (10): `UF`, `censobr_idhousehold`, `linha`, `V118`, `V202`, `V204`, `V204B`, `V211`, `code_muni_1960`, `V206`.

Os dois ultimos campos domiciliares e `V206` pessoal permitem manter T7 e cor na validacao; nao sao necessarios ao solver. `linha` preserva a referencia para diagnosticos e futura reuniao com o arquivo original. Nos footers conferidos de SE/MG/SP, todas essas colunas sao int32: os vetores iniciais selecionados ocupam aproximadamente **9,34 / 110,11 / 149,25 MiB**, respectivamente. Continuam faltando copias, variaveis auxiliares, buffers e estruturas de trabalho: nao se trata de previsao de pico. O preflight contou 1.005 pares municipio-situacao em SP; antes dos colapsos isso limita a margem a 1.028 controles (1.005 menos um, mais 22 etarios e dois de alfabetizacao), cuja Hessiana densa nominal seria cerca de 8,06 MiB. A matriz de observacoes permanece esparsa.

Antes das 15 UFs, recomenda-se repetir SE com essa projecao, exigir igualdade numerica dos pesos e dos controles com o piloto completo, e medir memoria do processo filho. Depois: um filho por UF, entradas originais somente leitura, projeção em lotes, hashes antes/depois, limite de tempo e monitoramento de memoria. Extrair pesos e identificadores em artefatos explicitamente auxiliares; reunir as colunas completas pode esperar disponibilidade de RAM. Nao ha ainda medicao de pico para esse percurso. O prazo de 600 segundos por UF pode ser usado como limite inicial, nao garantia de termino.

Nenhum passo desta proposta autoriza reconstruir 1,27% com casos de integridade nao resolvidos, executar `_targets.R`, calcular variancias, publicar ou sobrescrever a materializacao atual.

### Executor implementado e primeiro bloqueio de recursos

`references/recalibrar_pesos_25_reduzido_1960.py` e seu script R homonimo implementam o percurso reduzido autorizado: SE primeiro, comparacao de todas as colunas de pesos/desenho da saida parcial e de todos os campos dos controles contra o piloto completo, depois as15 UFs restantes, um filho por vez. A projecao usa lotes de65.536 linhas. O executor recusa inicio com menos de4GiB livres e encerra somente seus proprios filhos se a memoria livre cair abaixo de2GiB; prazo600s/UF. Nunca procura nem encerra processos preexistentes. Alem das saidas parciais, extrai tabelas separadas com pesos e chaves UF/domicilio/linha pessoal. Os hashes incluem originais, codigo, guias e, na paridade SE, os tres artefatos do piloto usados como referencia.

A primeira tentativa, em22/09/2026 as09:47, foi corretamente bloqueada **antes de iniciar R**, pois a memoria livre estava abaixo de4GiB. A consulta imediatamente posterior registrou aproximadamente1,06GiB livres de63,74GiB (98,3% usados). Evidencia: `tmp/execucao_1960_20260922/pesos25_reduzido_20260922_094717_846529/resumo_se.json`. Nao houve nessa tentativa recalibracao reduzida, comparacao de paridade nem medicao do pico R. O limite nao foi relaxado e nenhum processo existente foi encerrado.

**Estado no momento do bloqueio inicial:** piloto completo FN/SE concluido; SE reduzido ainda nao demonstrado; demais15 UFs ainda nao recalculadas. Nao ha log R dessa primeira tentativa, porque nenhum R foi iniciado; o estado `nao_iniciado` esta em `resultados/se_nao_iniciado.json` da raiz bloqueada. Essa evidencia historica foi preservada; a retomada bem-sucedida abaixo usa outra raiz.

Para uma retomada autorizada, no diretorio do projeto, com pelo menos4GiB livres e sem alterar fontes durante a sequencia:

```powershell
python references/recalibrar_pesos_25_reduzido_1960.py --autorizar-execucao
```

O comando cria outra raiz nova e executa somente SE. Nao reutilizar a raiz bloqueada. Somente se `paridade_se.json` tiver `aprovado: true` e `resultados/se.json` registrar `concluido_auxiliar_parcial`, executar o comando abaixo substituindo `RAIZ_NOVA_APROVADA` pelo caminho `RAIZ_REDUZIDA` impresso na tentativa bem-sucedida:

```powershell
python references/recalibrar_pesos_25_reduzido_1960.py --autorizar-execucao --restantes --raiz RAIZ_NOVA_APROVADA
```

O segundo comando verifica novamente a paridade, o estado de SE, os hashes das fontes e a memoria. Interrompe a sequencia na primeira falha; nao adapta controles nem limites para continuar. As entradas presumidas sao os quatro parquets atuais de cada UF em `data_raw/microdata/1960/amostra_25/<uf>/`, os guias locais `read_guides/1960_municipios.csv` e `references/censo_1960_resultados_definitivos_serie_nacional.csv`, as funcoes atuais de25/127/validacao e o runner isolado. A referencia de SE permanece o piloto completo `pesos25_piloto_20260922_092755`. Essas fontes sao identificadas por hash nos manifestos, nao substituidas silenciosamente.

## Retomada concluida: SE reduzido e as15 UFs restantes

A memoria livre voltou a superar4GiB sem encerrar processos do usuario. Antes da retomada, o monitor foi corrigido para encerrar e aguardar apenas a arvore de processos que ele criou mesmo se o proprio monitor lancar uma excecao. Dois testes com Python inofensivo (erro inesperado e AccessDenied no monitor/limpeza) passaram, preservando a causa original e o log: `tmp/execucao_1960_20260922/teste_monitor_python_87e648932d804621b50cb85df794a2f7/resultado.json`. Esses testes nao executaram R nem leram microdados. O mecanismo recebeu revisao estatica independente antes do piloto.

Raiz da retomada: `tmp/execucao_1960_20260922/pesos25_reduzido_20260922_095713_201741/`. SE concluiu com exit0 e **paridade exata**, nao apenas dentro de tolerancia: todas as17 colunas domiciliares nas44.059 linhas, todas as19 colunas pessoais nas209.544 linhas e todos os146 controles com14 campos. Evidencia: `paridade_se.json`. Os16 hashes conferidos de fontes/originais/referencias do piloto ficaram iguais. Pico de working set do R medido pelo Windows:441,93MiB; RAM livre minima:10,96GiB.

Somente depois desse resultado, as15 UFs restantes foram executadas serialmente. Todas concluiram com exit0 e preservaram as13 verificacoes de hash por UF. `resumo_restantes.json` registra `concluido: true`; os logs individuais estao em `logs/<uf>.log`, os diagnósticos em `diagnosticos/<uf>/` e os estados em `resultados/<uf>.json`. Nao houve limite ou controle relaxado, controle positivo abandonado, interrupcao por memoria ou prazo, nem alteracao dos pesos inteiros IBGE. Os pesos foram gravados em `saidas_parciais/<uf>/`; `pesos_com_chaves/<uf>/` contem somente UF, identificadores e quatro colunas de pesos. Nao usar esses parquets reduzidos como dados completos.

Consolidado reproduzivel: `resumo_metricas_pesos.json`, produzido por `tmp/execucao_1960_20260922/resumir_pesos_reduzidos.py`. Ele contem por UF alvos e somas dos leitores antes/depois, quantidade de controles, pior residuo, faixas de pesos/razoes, maior alteracao, leitores de idade ignorada, memoria e hashes. Resultado compacto (FN vem do piloto completo; demais UFs do percurso reduzido):

| UF | Controles | Maior residuo relativo absoluto | Maior mudanca absoluta de peso | Leitores presentes, idade ignorada |
|---|---:|---:|---:|---:|
| AL | 161 | 1,37e-14 | 0,035436 | 75 |
| BA | 410 | 1,98e-14 | 0,057368 | 732 |
| CE | 307 | 3,91e-11 | 0,053339 | 264 |
| DF | 25 | 9,57e-14 | 0,103148 | 27 |
| FN | 4 | 4,65e-16 | 1,07e-14 | 0 |
| GO | 377 | 2,21e-14 | 0,021725 | 111 |
| MG | 985 | 7,52e-15 | 0,053259 | 1.066 |
| MT | 147 | 8,77e-15 | 0,056900 | 95 |
| PB | 198 | 6,94e-15 | 0,024588 | 136 |
| PE | 227 | 1,07e-14 | 0,068039 | 608 |
| PR | 347 | 3,47e-13 | 0,109038 | 941 |
| RJ | 143 | 7,48e-11 | 0,057774 | 400 |
| RN | 189 | 9,13e-11 | 0,049763 | 120 |
| RS | 323 | 1,05e-14 | 0,076714 | 589 |
| SA | 25 | 2,18e-14 | 0,036427 | 34 |
| SE | 146 | 1,21e-14 | 0,030516 | 25 |
| SP | 1.025 | 4,09e-14 | 0,211943 | 4.172 |

Incluindo FN, sao3.066.365 domicilios,14.983.769 pessoas e9.395 leitores presentes com idade explicitamente ignorada. Ha5.039 controles efetivamente usados, com pior residuo relativo9,13e-11, inferior a tolerancia1e-10 do solver. Os pesos finais ficaram entre1,000047 e11,754717, dentro dos limites1 a12 correspondentes a base4 e fatores0,25 a3. A maior mudanca ocorreu em SP:0,211943 em valor absoluto; as razoes novo/antigo, considerando todas as UFs, ficaram entre0,958274 e1,055671. Os pesos inteiros IBGE permaneceram iguais.

MG levou45,51s no runner, com pico1,813GiB; SP levou61,46s, com pico2,316GiB. A menor RAM livre observada no percurso foi10,072GiB, bem acima do corte2GiB. A soma dos tempos totais dos16 processos reduzidos foi330,797s (inclui projecao e verificacoes por UF, nao o periodo inicial bloqueado). Houve211 comparacoes de hash por UF nesse percurso, todas iguais; esse numero conta fontes compartilhadas repetidas, nao211 arquivos distintos.

Uma conferencia independente posterior, sem R, verificou as17 UFs inteiras:3.066.365 domicilios,14.983.769 pessoas e14.807.957 presentes. Recalculou diretamente das pessoas todos os5.039 controles, sem reutilizar a matriz X, obtendo pior residuo9,1279e-11 em RN (`mun_1822_urbana`). Tambem verificou chaves/ordem/contagens originais, pesos finitos e dentro dos limites, base4/fator, igualdade P-D dos quatro pesos por domicilio e igualdade exata dos extratos com as saidas parciais. Evidencia: `tmp/execucao_1960_20260922/qc_pesos25_independente_resultado.json`. Isso nao homologa a identidade historica dos registros nem transforma arquivos parciais em completos.

**Limites mantidos:** fechar controles nao homologa a leitura nem elimina as pendencias de classificacao da T7. Os alvos da Serie Nacional nas17 UFs sao estimativas amostrais. Nao se alterou a exclusao da idade declarada ignorada da margem etaria25; sua inclusao foi corrigida especificamente no controle de leitores. Esta entrega nao recalibrou1,27%, nao calculou variancias, nao compilou dados, nao publicou e nao substituiu parquets de producao. Eventual reuniao posterior dos pesos com colunas completas exige sua propria evidencia de preservacao.

## Relatorio integrado das17 UFs com pesos novos

Foi executado apenas `validate_definitivos_1960_amostra_25`, sem novo ajuste de pesos, usando os16 pares reduzidos e o par completo de FN do piloto. Embora os16 pares sejam arquivos parciais, incluem todos os campos usados pelo validador; a igualdade de SE e as conferencias independentes acima delimitam esse uso. O relatorio novo esta em `tmp/execucao_1960_20260922/validacao25_novos_17ufs_20260922_101103_802707/relatorio_novo/validacao_definitivos.csv`. Nenhum relatorio antigo foi substituido.

O runner terminou com exit0 em90,115s, pico de working set982,91MiB e memoria livre minima11,40GiB. Os75 hashes de inputs, relatorios individuais e fontes ficaram iguais. As assercoes R verificaram **2.040 linhas,17 UFs com120 linhas cada, nenhuma chave duplicada e igualdade exata com a reuniao dos17 relatorios individuais posteriores**. Evidencias na mesma raiz: `resultado.json`, `verificacoes_grade.csv`, `resumo_leitura.json` e `logs/validacao17.log`.

Os estados, tanto antes quanto depois, sao1.846 celulas observadas,172 com classificacao incompleta e22 sem observacoes. Por peso:923 observadas,86 incompletas e11 sem observacoes. Todas as172 incompletas pertencem a T7; nenhuma foi convertida em zero aprovado. Nao ha UF omitida, celula nao reconstruida por falta de arquivo ou peso ausente. Uma conferencia adicional dos11 campos de classificacao/contagens nas2.040 celulas comparou22.440 valores antes/depois, sem divergencias; a soma ponderada pode mudar, mas as indicacoes de informacao incompleta foram preservadas.

`comparacao_status_antes_depois.csv` discrimina os estados por peso/tabela. `leitores_SP_SE_antes_depois.csv` mostra, entre outros, os leitores com `censobr_weight`: SE homens103.326,566380 para103.279 e mulheres115.237,183422 para115.189; SP homens4.097.859,188102 para4.089.706 e mulheres3.565.911,110570 para3.557.693, salvo arredondamento numerico inferior a0,000001. Esses sao controles usados na calibracao, nao uma validacao externa independente do ajuste. As linhas correspondentes de `censobr_weight_ibge` permaneceram iguais.
