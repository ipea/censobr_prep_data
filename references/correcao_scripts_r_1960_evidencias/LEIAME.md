# Evidencias das correcoes tecnicas dos scripts de 1960

Rodada de 23/09/2026. Dados ficticios nos testes; nenhuma reconstrucao nacional.

O arquivo `rotulos_erros_antes.rds` conserva os resultados numericos obtidos antes das mudancas de rotulagem. SHA-256: `62cf0ead55444b40df317be15f7356a235cc1220ef6ca5dd5be4986422a55c77`. O teste compara cada coluna antiga com igualdade exata de valores, tipos e ordem. O ponteiro interno de um `data.table` nao e dado: reaparece nulo ao ler RDS, por isso nao faz parte dessa comparacao.

Resultado e limites: [nota narrativa](../correcao_scripts_r_1960_20260923.md). Os logs anteriores com falha permanecem como cronologia; nao representam aprovacao.

## Resultados de encerramento

| Teste | Log da ultima execucao pertinente | Resultado |
|---|---|---|
| Preservacao de origem e tipos | [procedencia_final.log](procedencia_final.log) | Codigo 0; inclui NA inteiro preexistente com uma e duas linhas |
| Exportacao sem conferencia | [exportacao_depois.log](exportacao_depois.log) | Codigo 0; recusada antes de criar saida |
| Numeros e rotulos dos erros amostrais | [rotulos_final.log](rotulos_final.log) | Codigo 0; quatro saidas com valores anteriores exatamente iguais |
| Conferencia e exportacao | [publicacao_final.log](publicacao_final.log) | Codigo 0; releitura das duas saidas e 30 recusas esperadas |
| Validacao anterior | [validacao_legada.log](validacao_legada.log) | Codigo 0; retorno e grade preservados |
| Pesos anteriores, incluindo I/O Arrow | [pesos_arrow_final_02.log](pesos_arrow_final_02.log) | Codigo 0; entradas ficticias, nao recalculo nacional |

O ultimo teste foi executado com `CENSOBR_TEST_PESOS_ARROW=1` e um invocador contendo `options(warn = 1)` seguido de `source("references/test_pesos_1960.R", encoding = "UTF-8")`, para imprimir cada aviso em vez de somente sua quantidade. Restaram dois avisos de formatacao dos separadores numericos na mensagem de progresso, nao de conversao de colunas. No teste de procedencia, o aviso de compilacao do pacote digest e o aviso de V117 sem rotulo sao registrados: o teste usa guias127, enquanto o dicionario real recebe guias25; todos os 15 rotulos novos foram verificados.

## Como repetir

Da raiz do projeto, sempre uma execucao por vez:

```powershell
python -X utf8 references/rodar_r_isolado_1960.py references/test_publicacao_1960.R tmp/publicacao_nova.log --windows-arch --locale-c --timeout 360
```

Substituir script e nome do log para as demais baterias. Para o teste de pesos com leitura/escrita, definir `$env:CENSOBR_TEST_PESOS_ARROW='1'` apenas no processo PowerShell dessa execucao. Para rotulos, usar o padrao `depois`; a etapa `antes` recusa sobrescrever o baseline existente. Nao executar targets, nem o script `conferencia_desenho_amostral_1960.R`, que carrega produtos completos.

## O que as tentativas anteriores mostram

- `procedencia_antes_02.log`: demonstracao original da perda dos campos, rotulos e guarda; `procedencia_antes.log` inclui um erro de tipos da primeira fixture. `procedencia_depois.log` passou antes de ampliar a cobertura do caso de NA inteiro.
- `procedencia_na_antes.log`: a contraprova adicional revelou duas falhas reais de retipagem; corrigidas em `procedencia_final.log`. Os avisos foram localizados em `pesos_avisos_detalhados.log`; o primeiro `pesos_arrow_final.log` nao deve ser interpretado como aprovacao dessa retipagem.
- `exportacao_antes_03.log`: demonstrou exportacao sem conferencia. `exportacao_antes.log` registra um problema de locale na leitura do codigo; a segunda tentativa tambem exportou, mas a terceira imprimiu o fato explicitamente.
- `rotulos_antes_02.log`: gerou o baseline e falhou pela ausencia dos avisos metodologicos. A primeira tentativa comparou tambem indices internos mutaveis da tabela. `rotulos_depois.log` comparou o ponteiro interno de uma tabela viva com o ponteiro nulo lido do RDS; a comparacao correta por colunas passou em `rotulos_depois_02.log` e `rotulos_final.log`, sem substituir o baseline.
- `publicacao_depois.log` e `publicacao_depois_02.log`: regravacao de um arquivo ficticio ainda mapeado foi recusada pelo Windows (erro 1224). Nao houve queda nativa do Rscript. A restauracao passou a criar novos arquivos; `publicacao_depois_03.log` passou com 23 recusas, depois ampliadas a 30.

Todas as tentativas conservadas terminaram com codigo R 0 ou 1, nao com codigo de violacao de acesso. A falha separada de impressao do primeiro log no console Python foi evitada com `-X utf8`; o log R original foi preservado.

## Arquivos reais preservados

As assinaturas abaixo foram recalculadas ao encerrar e coincidem com as registradas antes desta rodada:

| Arquivo em `data_raw/microdata/1960/amostra_127/` | SHA-256 |
|---|---|
| HHOLDA.txt | `6449ca06c9086bbb0474481827f0efff98a0d9489838f322b4a69e489a42c44c` |
| pessoas_1960_amostra_127.parquet | `f757fddae54edddd6742ad800149a3086acc9f581a8197ec0a123d7f4efca404` |
| domicilios_1960_amostra_127.parquet | `f526ab6090d0be7dd9325a0f6b5143dab46186734f8760be8f44513924f93938` |

O esquema publicado tambem nao mudou: `schemas/censobr_types.csv`, SHA-256 `9bb56074c5d6b00cb8bc435bba4390c99d9543e431d572c1ea65f368f50790c2`.

`indice.json` registra as assinaturas dos arquivos desta entrega. Para textos, registra tanto os bytes locais como o texto UTF-8 sem BOM com finais de linha LF; este segundo hash permite conferir o conteudo se o Git normalizar CRLF/LF. O baseline RDS e binario e usa assinatura dos bytes. Nenhum indice historico das rodadas anteriores foi reescrito.
