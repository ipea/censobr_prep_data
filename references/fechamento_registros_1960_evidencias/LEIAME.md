# Evidências pequenas do fechamento dos registros de 1960

**Verificação final integrada:** [13 suítes R e 150 testes Python aprovados](verificacao_final.json), com arquivos originais e parquets completos preservados. Inclui a segunda leitura dos parquets de teste dos 30 cartões/74 pessoas. Para repetir os testes pequenos: `python references/verificar_fechamento_registros_1960.py --out tmp/NOVA_VERIFICACAO_REGISTROS`. Os arquivos de dados locais continuam necessários; nenhum rebuild completo é executado.

Este diretório permite conferir as decisões e executar os testes novos sem
recuperar as pastas temporárias da sessão. Não contém arquivos brutos completos,
índices SQLite, parquets, pesos novos ou uma nova população censitária.

## O que está preservado

| Arquivo | Conteúdo e uso |
| --- | --- |
| `fixtures_decisoes.json` | 1.908 linhas dos 954 conjuntos de respostas repetidas; 166 vínculos familiares; os 653 números de linha necessários para testar esses vínculos com todo seu contexto; três vínculos especiais do Paraná. |
| `duplicatas_residuais463.json` | Os 463 conjuntos ainda indeterminados, com 928 linhas, motivos, textos e 127 exclusões históricas sem prova. Não são novas exclusões autorizadas. |
| `texto_selecao_final33.json` | Os 47 casos de texto examinados na seleção final, os 33 reparos aprováveis, os 14 casos que não passaram, e seus grupos completos nas duas fontes. |
| `geografia_pr_candidatos.json` | Prova do município derivado para as linhas 887255 e 887256: conservar `724Z` no texto e derivar apenas `code_muni_1960=7240`. |
| `qc954_duplicatas.json` | Resultado da conferência independente das três classes que somam 954 conjuntos. |
| `qc166_vinculos.json` | Conferência independente dos 166 vínculos, com diferenças preservadas e duas origens possíveis para a linha 425558. |
| `qc33_reparos_geografia.json` | Releitura independente dos 33 reparos em 30 grupos e da geografia do Paraná. |
| `qc10_reparos_geografia_vinculos.json` | Releitura adicional dos dez últimos reparos e dos três vínculos do grupo paranaense. |
| `qc30_cartoes.json` | Conferência independente de 30 cartões familiares recuperados, referentes a 74 pessoas que já existiam na amostra; nenhum morador acrescentado. |
| `inventario_final.json` | Inventário integral após considerar os manifestos: listas individualizadas das pendências de vínculos, repetições, geografia e cartões. Não é uma reconstrução R da base. |
| `indice_evidencias.json` | Caminhos, tamanhos e SHA-256 dos relatórios originais de onde vieram as sete evidências. |
| `indice_inventario_final.json` | Índice separado para o inventário final: hash e tamanho da origem e da cópia compactada, mais identificação de `qc30_cartoes.json`. Não altera o índice das sete evidências anteriores. |

Os arquivos JSON foram compactados, mas seus valores não foram alterados.
Consequentemente, o hash e o tamanho do relatório original registrados no índice
não são o hash e o tamanho de sua versão compactada. A identidade de conteúdo foi
conferida após a compactação por `empacotar_evidencias_registros_1960.py --check`.

Na fixture, cada tabela guarda os nomes das colunas e uma lista de linhas.
Justificativas repetidas ficam em um dicionário separado; seu número começa em
zero. `ler_fixtures_registros_1960.R` recompõe a tabela original, inclusive textos,
espaços, tipos de coluna e justificativas. Isso reduz a fixture a cerca de 570 KB.
Ela serve para testes, não substitui os manifestos de produção em `read_guides/`.

## Exemplos de salvaguardas

As linhas 164631 e 164633 têm respostas iguais, mas a fonte de 25% apresenta duas
pessoas correspondentes. Ambas são mantidas. A linha 217736 também é mantida,
embora a regra antiga a excluísse: idade ignorada não prova duplicação.

Os reparos 607903 e 607904 dependem um do outro: a conferência usa o cartão e as
quatro pessoas juntos. O teste rejeita tentar aprovar apenas um deles. No cartão
803760, `V112="0 "` pode ser completado para `"07"`, preservando o zero que já era
legível. Seu único integrante coincide em 24 campos, mas diverge em V216=00/63;
essa divergência continua registrada. Não é uma testemunha pessoal de 25 campos
exatos, nem uma autorização para ligar a pessoa a outra família.

No Paraná, os textos das linhas 887255 e 887256 continuam com `724Z`. A fonte
completa sustenta um campo geográfico derivado, sem reescrever o original. Os três
vínculos levam ao cartão 887255. Trocar V216 da linha 888718 para 63, mesmo mantendo
o texto original intacto, deve provocar erro: o código 00 da amostra 127 permanece.

## Como ler as pendências do inventário final

O inventário registra 1.229 registros pessoais ainda sem cartão familiar
confirmado, organizados em 486 grupos de chave. Esses números incluem três
registros corrompidos. Como suas chaves ficaram ausentes, eles aparecem juntos
na agregação por chave vazia; isso **não demonstra que sejam da mesma família**.
Os grupos são localizadores da investigação, não famílias comprovadas.

Há também 463 conjuntos de respostas repetidas, envolvendo 928 linhas. São casos
indeterminados, não 928 duplicatas comprovadas. Em especial, as linhas 951432 e
951433 passam a ter o mesmo perfil depois que campos danificados são anulados.
Perder diferenças porque os textos estão corrompidos não prova que duas linhas
representem a mesma pessoa e não autoriza eliminar uma delas.

As conferências geográficas apontam 50 conflitos de município e 145 de situação
do domicílio, mas envolvem **192 pessoas distintas**, não 195: três aparecem nas
duas listas. Além disso, uma pessoa pode aparecer também nas listas de vínculo
pendente ou de respostas repetidas. Portanto, **não se somam essas categorias**
para obter um total de pessoas problemáticas; é necessário reunir os números de
linha e contar cada registro uma única vez.

O inventário ainda enumera um cartão real sem pessoa associada e uma família
convivente sem família principal confirmada. São pendências de cartões e de sua
organização, não novas pessoas. Os 30 cartões recuperados, conferidos no relatório
`qc30_cartoes.json`, organizam 74 pessoas já existentes; recuperar o cartão não
significa acrescentar moradores nem demonstrar um prédio adicional.

O arquivo `inventario_final.json` preserva todas as listas e contagens do relatório
original, não apenas este resumo. Sua cópia compactada tem conteúdo JSON idêntico
ao original de `inventario_final_01`; os dois hashes e tamanhos estão no índice
separado. O inventário é uma conferência independente das pendências e não deve
ser apresentado como resultado de uma reconstrução integral dos microdados em R.

## Repetir testes pequenos

Da raiz do projeto, os testes Python abaixo não precisam de `tmp/`, de R ou dos
arquivos brutos completos. Usam as evidências deste diretório e os guias versionados:

```powershell
python references/test_fixtures_registros_1960.py
python references/test_revisao_independente_reparos_finais_1960.py
python references/test_auditoria_pendencias_duplicatas_1960.py
python references/test_auditoria_pendencias_vinculos_1960.py
```

Os testes R `test_novas_duplicatas_1960.R`, `test_novos_vinculos_1960.R` e
`test_geografia_registros_1960.R` leem esta fixture; só usam `tmp/` para resultados
novos. Ainda exigem os arquivos originais locais, os manifestos e a biblioteca R
do projeto. O teste de duplicatas também confere que os parquets atuais não mudam.
Executar R apenas pelo runner isolado já diagnosticado, por exemplo:

```powershell
python references/rodar_r_isolado_1960.py references/test_novas_duplicatas_1960.R tmp/teste_dup_portavel.log --windows-arch --locale-c --timeout 120
```

## Limites de reprodução da investigação inteira

Uma fixture testa a aplicação das decisões; não substitui reler as fontes para
descobri-las. Os programas de auditoria e revisão independente estão em
`references/`. As revisões independentes releram HHOLDA e os arquivos de 25% e
conferiram seus hashes antes/depois. As evidências registram arquivo e número de
linha, permitindo voltar à fonte local.

Os antigos comandos de investigação ainda dependem de insumos temporários:

| Programa | Dependência adicional para repetir a investigação histórica inteira |
| --- | --- |
| `auditoria_pendencias_duplicatas_1960.py` | Inventário inicial `integridade_127_pendencias_final.json` e, nas etapas projetadas/residuais, resultados integrais das etapas anteriores. |
| `auditoria_pendencias_vinculos_1960.py` | Mesmo inventário, guardas de vínculos e índice SQLite reconstruído pela auditoria de recuperação de cartões. O índice não foi versionado. |
| `fechar_reparos_texto_1960.py` / `conferir_inferencias_registros_1960.py` | Inventário `texto/completo01/casos.json`, além das fontes locais. |
| `revisao_independente_vinculos_1960.py` / `revisao_independente_reparos_finais_1960.py` | Fotografias das decisões anteriores em `vinculos/entrega_02`, relatórios de origem e fontes locais. |

Isso é distinto dos testes portáteis acima, que não leem esses insumos temporários.
Não se afirma que um clone vazio de dados reproduza a investigação integral.
`empacotar_evidencias_registros_1960.py` preserva o procedimento de extração: seus
modos `--patch` e `--evidence-patch` apenas imprimem patches, sem escrever nas fontes.
