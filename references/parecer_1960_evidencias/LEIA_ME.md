# Como conferir os exemplos do parecer

Este caderno acompanha a [explicação narrativa e ilustrada](../microdata_1960_amostra_127_revisao_integrativa.md). A versão para [leitura no navegador](../microdata_1960_amostra_127_revisao_integrativa.html) contém o mesmo texto e as mesmas figuras.

As fontes foram consultadas sem executar R/Rscript ou o processamento de produção. As notas distinguem arquivo original, decisão de tratamento, arquivo já gravado e proposta. Elas não são um conjunto de correções aplicado aos dados.

## Conferência sem programar

1. Abra o caso de interesse: [vínculos e duplicatas](vinculos.md), [validação](validacao.md) ou [reparo e gravação](reparo_e_gravacao.md).
2. Leia a tabela que traduz os códigos em palavras. Compare a coluna do estado atual com a fonte original e a outra cópia.
3. Use os números de linha e os trechos literais para localizar a evidência. Nos arquivos comprimidos de 25%, o número se refere à linha depois da descompressão.
4. Confira se a proposta altera somente aquilo que a evidência sustenta. Campos ainda desconhecidos e o destino completo do boletim 124 da Bahia permanecem sujeitos a decisão específica.

Os caminhos escritos nas notas começam na raiz de `censobr_prep_data`, salvo links clicáveis. Na tabela processada, o campo `linha` aponta ao original; não confundir com a ordem atual das linhas. Em CSVs, os números físicos citados contam o cabeçalho como linha 1.

## Conferência automatizada opcional, somente leitura

O [verificador dos exemplos](conferir_exemplos.py) lê as fontes locais, compara os trechos transcritos e verifica as contagens e campos principais. Não importa o código de produção, não executa R, não ajusta pesos e não grava arquivos. Requer Python e PyArrow, já disponíveis no ambiente em que foi conferido.

Na raiz do projeto:

```powershell
python references/parecer_1960_evidencias/conferir_exemplos.py
```

Ele imprime um resumo verificável e a identificação SHA-256 do HHOLDA. SHA-256 é uma assinatura do conteúdo: permite saber se a fonte completa continua sendo a mesma, sem depender apenas do nome do arquivo. A assinatura não prova a veracidade histórica dos registros.

**Execução conferida em 22/09/2026:** terminou sem erro; os 25 trechos literais transcritos coincidiram com as fontes (13 do HHOLDA, sete da BA e cinco da PB). Passaram também as verificações dos estados familiares selecionados, reparo do RS, ausência rural em RO, 9.395 leitores omitidos e dois domicílios do exemplo de água. A assinatura encontrada foi `6449ca06c9086bbb0474481827f0efff98a0d9489838f322b4a69e489a42c44c`.

O verificador **reproduz o estado ilustrado em 22/09/2026**. Depois de uma correção real dos arquivos, algumas de suas verificações do estado antigo devem deixar de passar. Não o transforme em teste que obrigue os dados corrigidos a repetir o erro. Para testar uma correção futura será necessário construir expectativas novas, documentadas caso a caso.

## O que a reprodução comprova — e o que não comprova

Ela comprova que os exemplos e as contagens selecionadas correspondem às fontes locais examinadas. Não prova a identidade civil dos pares indistinguíveis, a verdade de todos os campos das cópias, a correção do desenho histórico ou a execução futura do programa R.

O detalhe técnico das três revisões continua no [anexo preservado de 21/09](../microdata_1960_amostra_127_anexo_tecnico_20260921.md), com links para os relatórios anteriores. Algumas saídas extensas desses relatórios estão em `tmp/`, diretório não versionado. As três notas deste caderno preservam as evidências centrais dos exemplos e não dependem de o leitor interpretar aqueles JSONs temporários.

## Reproduzir a versão de leitura

O Markdown é a fonte editável; o HTML é uma conversão desse mesmo texto. As figuras são esquemas vetoriais próprios, com descrição textual acessível. Para gerar novamente o HTML, na raiz do projeto, com Pandoc instalado:

```powershell
pandoc references/microdata_1960_amostra_127_revisao_integrativa.md --standalone --embed-resources --toc --toc-depth=2 --css=references/figuras/parecer_1960/leitura.css --resource-path=references --metadata lang=pt-BR --metadata pagetitle="Censo de 1960: revisão explicada, ilustrada e auditável" --output references/microdata_1960_amostra_127_revisao_integrativa.html
```

Esse comando apenas atualiza a versão HTML da documentação. Não produz microdados nem altera o conteúdo científico da análise.
