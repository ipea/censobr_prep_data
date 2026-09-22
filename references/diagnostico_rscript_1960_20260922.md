# Por que o Rscript fechava com erro

## Conclusão verificada

A falha foi reproduzida sem abrir os dados do censo. O ambiente recebido pelos processos desta sessão não continha a variável `PROCESSOR_ARCHITECTURE`, que informa a arquitetura do Windows. O pacote `cli` 3.6.6 tenta comparar seu conteúdo com `ARM64` ao encerrar, sem verificar se a variável existe. A ausência produz uma leitura de endereço nulo e a saída nativa `0xc0000005`.

Isso explica a falha reproduzida nesta investigação. As imagens antigas, sozinhas, não permitem demonstrar que todos os episódios anteriores tiveram a mesma causa. Um registro Windows de 16/09 apontava outro projeto; não foi usado como prova de origem neste projeto.

O `cli` é carregado indiretamente por outros pacotes. Por isso o primeiro teste apontou o Arrow, mas essa hipótese foi refinada: `library(cli)` sozinho também falhou, inclusive ao executar explicitamente seu descarregamento. R básico, `data.table`, `tzdb`, `glue` e `magrittr` isolados terminaram normalmente.

## O que foi feito

O executor [rodar_r_isolado_1960.py](rodar_r_isolado_1960.py) recebeu a opção `--windows-arch`: consulta a arquitetura real usando `GetNativeSystemInfo` e a fornece **somente ao processo R que ele inicia**. Nesta máquina o resultado é `AMD64`, confirmado também pela consulta do Windows (`X64`). Não houve reinstalação de R, troca de pacote, alteração do registro do Windows, alteração global de variáveis ou edição de `renv.lock`.

O executor também grava um log novo, limita o tempo e não abre diálogos nativos de falha. Impedir o diálogo não transforma uma falha em sucesso: qualquer saída diferente de zero continua reprovando a execução. O prazo encerra exclusivamente o processo criado pelo teste; processos R de outros trabalhos não são tocados.

## Evidência que permite repetir a conferência

Os scripts e logs estão em `tmp/execucao_1960_20260922/`:

| Teste | Resultado |
|---|---|
| `01_base.R` | R 4.5.0 básico: saída 0 |
| `04_arrow_carga.R` | Apenas carregar Arrow 25.0.0: erro ao encerrar |
| `06_arrow_23.R` | Arrow 23.0.1.1: também falha; trocar somente Arrow não resolve |
| `07_arrow_carga_sem_sandbox.log` | Mesmo erro fora do isolamento |
| `14_data_table.R` | `data.table`: saída 0 |
| `19_cli.R` | Apenas `cli`: erro ao encerrar |
| `24_rlang_locale.log` | Corrigir apenas a configuração regional não resolve |
| `26_cli_unload.R` | Falha dentro do descarregamento de `cli` |
| `27_cli_arch.R` | Mesma biblioteca, arquitetura fornecida corretamente: descarrega e termina com saída 0 |
| `28_arrow_confirmacao_a.log` e `_b.log` | Duas execuções independentes: leem 675 pessoas de RO, gravam uma cópia de teste, conferem igualdade após reabertura e terminam com saída 0 |

O teste `02` usou uma única thread de entrada/saída do Arrow e atingiu o prazo; essa configuração foi abandonada após o aviso do próprio pacote. Os testes seguintes usam duas threads de entrada/saída. Esse travamento de diagnóstico não deve ser confundido com a falha de encerramento original.

Exemplo do comando seguro adotado nesta etapa, a partir da raiz do projeto:

```powershell
python references/rodar_r_isolado_1960.py caminho/do/teste.R tmp/log_novo.log --timeout 60 --locale-c --windows-arch
```

O script R precisa restabelecer a leitura de acentos antes de carregar os arquivos do projeto: `Sys.setlocale("LC_CTYPE", ".UTF-8")`, seguido de `stopifnot(l10n_info()[["UTF-8"]])` e `source(..., encoding = "UTF-8")`. A opção `--locale-c` isoladamente não garante isso. Os scripts executados nesta etapa fazem esse ajuste e usam a biblioteca local de R 4.5.0 do projeto; não instalam nem atualizam pacotes.

## Fontes técnicas

A condição foi conferida no [código oficial de `cli` 3.6.6, função `cli__kill_thread`](https://github.com/r-lib/cli/blob/v3.6.6/src/thread.c). A consulta de arquitetura segue [GetNativeSystemInfo](https://learn.microsoft.com/en-us/windows/win32/api/sysinfoapi/nf-sysinfoapi-getnativesysteminfo). A prevenção de janelas usa a configuração herdada, limitada ao processo, de [SetErrorMode](https://learn.microsoft.com/en-us/windows/win32/api/errhandlingapi/nf-errhandlingapi-seterrormode).

Isso é uma correção do ambiente de execução destes testes, não uma correção dos registros, dos pesos ou dos resultados estatísticos. As etapas de dados precisam de verificação própria.
