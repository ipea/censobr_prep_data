# Caderno da investigação adicional dos registros de 1960

Data: 22/09/2026. Estado de referência: commit `790d9d7`. Esta é uma investigação posterior à publicação desse commit, não uma nova aplicação de correções.

## Por onde começar

Leia primeiro o [relatório narrativo integrador](../investigacao_residual_registros_1960_20260922.md). Ele explica os problemas com exemplos, distingue evidência de proposta e indica o próximo passo. Os documentos por assunto permitem aprofundar a conferência:

- [Repetições pessoais e diferenças de numeração](../investigacao_residual_duplicatas_1960.md).
- [Pessoas sem família, conflitos e cartões ausentes](../investigacao_residual_vinculos_1960.md).
- [Texto danificado e reparos possíveis](../investigacao_residual_texto_1960.md).
- [Publicações históricas, idade ignorada e procedência dos arquivos](../investigacao_residual_fontes_1960.md).

Aqui, uma **linha** é a posição do registro no arquivo bruto, começando em 1. Um **cartão familiar** é o registro que descreve a família; não é uma pessoa adicional. Pasta e boletim são códigos históricos usados para localizar os questionários. Os arquivos JSON abaixo guardam listas estruturadas de casos, textos, contagens e justificativas para conferência por programa; não é necessário começar a leitura por eles.

## Cobertura e unidades que não devem ser somadas

O inventário da rodada anterior foi refeito e o conteúdo coincide integralmente com [inventario_final.json](../fechamento_registros_1960_evidencias/inventario_final.json). Nenhuma descoberta desta rodada já foi descontada das pendências de produção.

| Pergunta | Cobertura conferida | Limite da contagem |
|---|---:|---|
| Repetições pessoais ainda sem decisão | 463 conjuntos, 928 linhas, 400 contextos familiares | Um contexto pode conter vários conjuntos repetidos. |
| Falta de família e conflitos geográficos | 1.421 linhas distintas: 1.418 passíveis de busca por chave e 3 fragmentos | Reúne 1.229 sem família e 192 pessoas com conflitos; município e situação se sobrepõem dentro dos 192. Algumas das 1.418 ainda têm campos pessoais inválidos. |
| Suspeitas de dano textual | 124 registros revisitados | Inclui casos resolvidos anteriormente; não são 124 pendências novas. |
| Composições familiares iguais sob chaves distintas | 174.425 cartões não vazios e sem campos inválidos comparados | Foram encontrados dez conjuntos, 21 cartões e 54 registros pessoais; igualdade não prova duplicação. Usa os vínculos atuais a cartões reais, sem incluir órfãos nem cartões recuperados sintéticos. |
| Fonte de 25% | 17 arquivos, 18.055.053 registros percorridos nas buscas integrais | Incluem pessoas e cartões. Não cobrem as onze UFs ausentes dessa fonte. |

[cobertura_integrada.json](cobertura_integrada.json) identifica cada linha e todas as categorias que a alcançam. Suas marcações se sobrepõem: não somar as contagens para anunciar um total de pessoas com problema. As 54 linhas pessoais dos novos conjuntos familiares não pertencem às 928 linhas da lista anterior de repetições pessoais.

## O que cada arquivo permite conferir

| Arquivo | Conteúdo e uso |
|---|---|
| [duplicatas_cobertura463.json](duplicatas_cobertura463.json) | Todos os conjuntos pessoais pendentes, inclusive os sem candidato e os sem fonte da própria UF. |
| [duplicatas_fora_chave.json](duplicatas_fora_chave.json) | Treze alternativas encontradas fora da chave anterior, com diferenças e ressalvas. |
| [duplicatas_vizinhancas1702.json](duplicatas_vizinhancas1702.json) | Famílias vizinhas examinadas para investigar padrões de renumeração. |
| [duplicatas_hipotese_um_campo.json](duplicatas_hipotese_um_campo.json) | Ensaio que admite mais um campo diferente; não é uma regra aprovada de correção. |
| [duplicatas_colisoes_familias.json](duplicatas_colisoes_familias.json) | Verificação de famílias distintas que apontariam para o mesmo grupo na outra fonte. |
| [familias_coincidentes.json](familias_coincidentes.json) | Busca nacional de famílias com os mesmos conteúdos e quantidades sob chaves distintas. |
| [duplicatas_qc_blocos_am_ma.json](duplicatas_qc_blocos_am_ma.json) | Segunda leitura dos textos de Amazonas e Maranhão; preserva a correspondência entre pessoas, mesmo reordenadas. |
| [vinculos_casos.json](vinculos_casos.json) | Cobertura individual dos vínculos/conflitos, candidatos, textos originais e comparação de grupos. |
| [vinculos_extensoes.json](vinculos_extensoes.json) | Pasta gaúcha 82588 e busca ampliada dos adultos associados ao cartão paulista vazio. |
| [vinculos_recuperacao.json](vinculos_recuperacao.json) | Hipóteses de cartões ausentes, alternativas e dependência conjunta entre reparo textual e vínculo. |
| [Evidências textuais](../investigacao_residual_texto_1960_evidencias.json) e [complementos](../investigacao_residual_texto_1960_complementos.json) | Os 124 casos revisitados, caracteres preservados, falsos acordos após apagar danos e buscas complementares. |
| [fontes_documentais.json](fontes_documentais.json) | Relações aritméticas das tabelas publicadas, assinaturas e comparações com cópias preservadas. |
| [qc_independente.json](qc_independente.json) | Segunda leitura de 423 textos da amostra de 1,27% e 352 da fonte de 25%; composição, quantidades e cobertura. |
| [indice.json](indice.json) | Tamanho e assinatura SHA-256 dos arquivos da entrega: serve para detectar alteração de arquivo, não para provar uma identidade histórica. |

**Candidato não é decisão aplicada.** Localizar uma pessoa parecida é diferente de identificar sua família. Confirmar a família é diferente de escolher qual geografia deve prevalecer. Correspondência entre cópias também não torna a fonte maior infalível. As propostas fortes e as ressalvas estão explicitadas no relatório, não deduzidas apenas da existência de uma linha nestes arquivos.

## Como repetir as verificações

Os programas são auditores separados do processamento de produção. Não executam R nem recalculam pesos. Execute na raiz do projeto. Todos os diretórios de saída dos exemplos devem ser novos; não apague evidências anteriores para reutilizar um nome.

Os 31 testes desta investigação passaram:

```powershell
python -m unittest discover -s references -p 'test_*investigacao*1960.py'
```

Para repetir a segunda leitura das evidências já reunidas:

```powershell
python references/conferir_investigacao_residual_1960.py --out tmp/NOVO_QC_RESIDUAL
```

O teste confere os textos diretamente nos arquivos brutos e nas correções anteriormente aprovadas; não importa os novos auditores das três frentes. Não repete todas as buscas globais nem confirma por si só a identidade de cada candidato. O auditor é [conferir_investigacao_residual_1960.py](../conferir_investigacao_residual_1960.py).

A busca nacional de famílias inteiras teve um piloto no Ceará. Para reproduzi-la, incluindo cartões com apenas uma pessoa:

```powershell
python references/investigacao_familias_repetidas_1960.py --uf 14 --min-people 1 --out tmp/NOVO_PILOTO_FAMILIAS
python references/investigacao_familias_repetidas_1960.py --min-people 1 --out tmp/NOVA_BUSCA_FAMILIAS
```

As notas por assunto trazem os comandos dos demais pilotos e buscas. A investigação documental pode ser repetida sem o acervo particular para as relações das tabelas publicadas; a comparação com as cópias recebidas exige fornecer os caminhos `--archive` e `--raw25`. A renderização das páginas requer PyMuPDF; o ensaio de emparelhamento usa NumPy/SciPy já disponíveis nesta execução. Não foram instalados pacotes.

### Dependências que precisam existir

As buscas usam o bruto `data_raw/microdata/1960/amostra_127/HHOLDA.txt`, os guias e manifestos da rodada anterior, os arquivos `data/release_legacy/Censo.1960.amostra.25porcento.*.gz` e o índice SQLite somente para leitura:

```text
tmp/fechamento_registros_1960_20260922/recuperacao_atualizada_01/indice127.sqlite
SHA-256 54833acacc7baed83d97e46a53cb9c144740b3e36bcd8922888804027bbf6535
```

Esse índice representa os registros e decisões anteriores, não os parquets ainda sem reconstrução. Os caminhos e opções estão nos scripts. O caderno conserva as provas selecionadas e a cobertura integral das listas examinadas, mas **não distribui todas as fontes nem promete uma reconstrução autônoma usando somente estes recortes**.

Os resultados documentais e familiares foram preservados por [consolidar_investigacao_residual_1960.py](../consolidar_investigacao_residual_1960.py), com os argumentos `--families` e `--sources`. O programa também exige igualdade entre as listas de cobertura e o inventário anterior e recusa sobrescrever os arquivos finais. Não é necessário rodá-lo para ler ou conferir uma entrega já consolidada.

## O que não foi feito

Não foram implementados novos vínculos, remoções, restaurações ou reparos. Não foram alterados os dados completos, os pesos, os guias ou os manifestos de produção. Não houve R, targets, commit, push ou publicação de dados nesta investigação. As mudanças preexistentes do usuário em `renv.lock` e no arquivo de projeto ficaram fora da tarefa.

Não houve busca de todas as possíveis divisões/fusões familiares nem de qualquer quantidade de caracteres corrompidos. A ausência de correspondência sob um critério é um resultado de busca, não prova de inexistência da pessoa. A falta das fontes de onze UFs, os danos sem reconstrução comprovada e as alternativas não excluídas continuam expressamente pendentes.
