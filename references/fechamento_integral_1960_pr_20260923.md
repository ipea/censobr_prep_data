# Fechamento da soma municipal do Paraná e cinco transcrições adicionais

## Resultado

A divergência do Paraná foi resolvida na fonte: os 162 municípios do Quadro II somam **4.277.763 habitantes**, exatamente a linha estadual, e não os 4.272.847 do guia anterior. A leitura integral das 21 páginas também fecha as 11 zonas fisiográficas e a distribuição estadual urbana/rural. Foram corrigidas sete linhas pelo agente principal, depois de segunda inspeção dos recortes. O exame adicional de cinco divergências aritméticas em outras UFs confirmou mais cinco erros de transcrição. Nenhum desses reparos altera respostas dos microdados, códigos municipais ou distritos.

Esta frente produziu transcrições, imagens, testes e conferência independente em Python; não executou R nem alterou diretamente o guia. O agente principal aplicou as 12 linhas e executou os novos pesos de MT, PR e MG. As três saídas passaram na conferência independente abaixo. Isso não homologa os microdados nacionais nem resolve os impedimentos históricos da amostra de 1,27%.

## Fonte primária e cobertura

O [volume do Paraná da Sinopse Preliminar do Censo Demográfico de 1960](https://biblioteca.ibge.gov.br/visualizacao/periodicos/312/cd_1960_sinopse_preliminar_pr.pdf), Quadro II, páginas impressas 3–23 (PDF 7–27), foi lido integralmente em renderizações a 300 dpi. As 162 triplas numéricas estão no script `fechamento_integral_1960_pr_conferencia.py`, objeto `VISUAL`, e no caderno `tmp/fechamento_integral_1960/parana/conferencia_162_municipios.json`. A camada de texto serviu para localizar páginas, não como prova suficiente de algarismos ambíguos.

A cópia local do PDF tem SHA-256 `ed14507806b1774e317c4d2f620beb2265d0882f399ff00a41a91c4841a3540a`. O endereço primário é o registrado no catálogo de fontes do projeto; a tentativa de reabrir o PDF pela ferramenta web nesta rodada não funcionou. A leitura efetiva foi da cópia local, cuja assinatura e fac-símiles foram registrados. Não se afirma novo download desse PDF.

## As sete correções do Paraná

Cada tripla segue a ordem total / urbana / rural. `fonte_pop` era `AEB` em todas as sete linhas; essa procedência anterior está preservada no snapshot e nos JSONs. O guia atual identifica a página impressa da Sinopse, no formato `Sinopse1960_QuadroII_pN`.

| Código e município | Guia anterior | Fac-símile confirmado | Página impressa / PDF |
|---|---:|---:|---:|
| 7120 Bituruna | 7.484 / 634 / 6.850 | 7.484 / 706 / 6.778 | 23 / 27 |
| 7227 Cianorte | 49.731 / 8.086 / 41.645 | 53.658 / 8.480 / 45.178 | 12 / 16 |
| 7252 Paranavaí | 63.189 / 25.058 / 38.131 | 63.189 / 25.028 / 38.161 | 15 / 19 |
| 7266 Terra Boa | 16.697 / 2.485 / 14.212 | 17.143 / 2.485 / 14.658 | 17 / 21 |
| 7336 Nova Fátima | 12.802 / 2.436 / 10.366 | 12.829 / 2.463 / 10.366 | 21 / 25 |
| 7348 Sertaneja | 17.334 / 4.379 / 12.955 | 17.337 / 2.114 / 15.223 | 22 / 26 |
| 7350 Uraí | 24.137 / 5.535 / 18.602 | 24.650 / 6.964 / 17.686 | 23 / 27 |

As mudanças no total são +3.927, +446, +27, +3 e +513: **+4.916**, a diferença que permanecia aberta. A soma urbana muda de 1.328.355 para 1.327.982 (−373); a rural, de 2.944.492 para 2.949.781 (+5.289). Bituruna e Paranavaí mudam somente a distribuição.

Em Bituruna, 634 é a população urbana do distrito-sede: faltavam os 72 habitantes urbanos de Santo Antônio do Iratim. Em Uraí, 5.535 também corresponde ao distrito-sede, não ao município inteiro. Em Paranavaí, o recorte ampliado confirma 22.141 urbanos no distrito-sede; a soma distrital fecha a linha municipal corrigida. Não se atribui uma causa editorial às demais divergências quando o fac-símile prova o número, mas não a história da transcrição.

O fechamento das zonas foi testado separadamente para Litoral, Alto Ribeira, Campos do Oeste, Castro, Campos Gerais, Curitiba, Tomazina, Alto Ivaí, Irati, Oeste e Norte. Nenhum município do PR ficou sem confronto.

## Cinco divergências adicionais

Os cinco fac-símiles foram inspecionados por esta frente e novamente pelo agente principal antes do patch. Os volumes são os da [Sinopse de MG](https://biblioteca.ibge.gov.br/visualizacao/periodicos/312/cd_1960_sinopse_preliminar_mg.pdf), [SP](https://biblioteca.ibge.gov.br/visualizacao/periodicos/312/cd_1960_sinopse_preliminar_sp.pdf), [SC](https://biblioteca.ibge.gov.br/visualizacao/periodicos/312/cd_1960_sinopse_preliminar_sc.pdf) e [MT](https://biblioteca.ibge.gov.br/visualizacao/periodicos/312/cd_1960_sinopse_preliminar_mt.pdf). Cópias locais e SHA-256 constam de `parana/outras_ufs/fontes.json`; os recortes têm nomes `recorte_<codigo_nome>_pdf<N>.png` nessa pasta.

| Código e município | Campo anterior → correto | Tripla correta | Página impressa / PDF |
|---|---:|---:|---:|
| MG 4032 Alpinópolis | rural 6.298 → 15.295 | 19.740 / 4.445 / 15.295 | 37 / 41 |
| MG 4095 Itumirim | urbana 3.043 → 2.043 | 7.395 / 2.043 / 5.352 | 43 / 47 |
| SP 6378 Jardinópolis | total 16.652 → 16.625 | 16.625 / 7.533 / 9.092 | 26 / 30 |
| SC 7457 São Bento do Sul | urbana 6.047 → 6.470 | 12.814 / 6.470 / 6.344 | 11 / 16 |
| MT 9204 Coxim | urbana 2.748 → 2.798 | 12.997 / 2.798 / 10.199 | 8 / 13 |

As somas distritais são provas adicionais independentes da soma urbana+rural:

- Alpinópolis: sede 9.225/3.869/5.356 + São José da Barra 10.515/576/9.939. O antigo 6.298 está na linha de Alterosa, logo abaixo, e não em Alpinópolis.
- Itumirim: sede 4.257/1.525/2.732 + Ingaí 3.138/518/2.620. Itutinga aparece em bloco municipal separado. Isso não prova a identidade de um código distrital dos microdados: nenhuma proposta de reescrever V116 decorre desses totais.
- Jardinópolis: sede 14.380/6.965/7.415 + Jurucê 2.245/568/1.677.
- São Bento do Sul: município e único distrito repetem 12.814/6.470/6.344.
- Coxim: sede 9.893/1.371/8.522 + Pedro Gomes 3.104/1.427/1.677.

Jardinópolis altera somente `pop_total`. O ajuste usa `pop_urbana` e `pop_rural`, que já estavam corretos; essa correção isolada não muda os pesos de SP. SC não integra a fonte de 25% disponível. Os alvos de MG, MT e PR mudaram e foram recalculados pelo agente principal.

## Provas antes/depois e preservação do restante

O snapshot anterior, com todas as 2.770 linhas e todas as colunas, está preservado
de forma portátil em [guia_municipal_anterior.json](fechamento_integral_1960_evidencias/guia_municipal_anterior.json).
A cópia tem 967.599 bytes e SHA-256
`5362895fd1fc4f2c721436008308438067fb18b9c2a904624fb9fe0a51afa0cb`, idêntico ao
arquivo originalmente gerado em `parana/guia_antes_snapshot.json`, que também foi
preservado. Não se trata de uma reserialização ou de um snapshot criado depois
da correção. O SHA do CSV original, registrado dentro desse JSON, continua
`f77a4802a38a1a6246d2d870717c5be88eb843e36e1fd9fd106d673fae86ad11`.

Os dois testes agora leem a cópia portátil e exigem a assinatura do próprio
artefato. A geração histórica por `--snapshot` foi bloqueada: o guia já corrigido
não pode recriar a evidência anterior. A conferência visual dos 162 valores
também usa a fonte portátil. Reexecução do integrativo passou, comprovante
`parana/outras_ufs/teste_integrativo_portatil.json`, conservando a exigência de
exatamente 12 linhas nominais. O teste de sete linhas permanece um teste do
marco histórico, não o critério de aprovação do guia atual com 12 correções.

O teste `fechamento_integral_1960_pr_test.py` falhou antes das sete correções e passou depois, comprovante independente `parana/teste_guia_depois_independente.json`. Nesse marco, o guia tinha SHA `92401870ff3ad7284c1b3b1ed4208f1a0d23730da8b27e607ea886ed01270b8b`. Esse teste conserva a exigência de nenhuma mudança fora das sete linhas: não foi afrouxado depois.

O novo `fechamento_integral_1960_pr_integrativo_test.py` autoriza nominalmente as sete correções de PR e as cinco adicionais. Compara integralmente as 2.770 linhas, sua ordem e cada coluna contra o snapshot mais essas 12 atualizações; preserva as outras 2.758 linhas e os componentes originalmente ausentes. Falhou pelas cinco divergências esperadas antes do segundo patch e passou depois, inclusive em repetição independente. Os comprovantes estão em `parana/outras_ufs/teste_integrativo_antes.json`, `teste_integrativo_depois.json` e `teste_integrativo_depois_independente.json`. O SHA final é `3bc197bdbb6e8746614b108acbdb9cb2de079810172fdea2ffd268e0cf99ed96`. A fonte anterior `AEB` e as páginas novas estão preservadas na proposta e na entrega JSON.

O fechamento aritmético nacional não é uma releitura visual dos 2.770 municípios: a cobertura visual integral aqui foi dos 162 do PR, somada aos cinco casos adicionais. Campos ausentes fora da tarefa não foram transformados em zero.

## Conferência independente dos novos pesos

`fechamento_integral_1960_pr_qc.py` foi adaptado da auditoria anterior, lida integralmente, para `--partial-run`, `--out` e `--uf mg|sp|mt|pr`. Não executa R nem recalibra. A reconstrução dos alvos parte do guia atual, dos resultados definitivos e das contagens domiciliares originais: refaz o colapso por fator fora de [2,8], universo abaixo de 100 ou situação sem amostra; preserva a ordem da primeira ocorrência para o desempate; reescala as âncoras antes de omitir a menor célula; recompõe os controles de sexo/idade e alfabetização. Só então compara com os alvos registrados.

Pessoas são lidas em lotes de 131.072, com seleção de colunas. A auditoria reconta presentes e suporte pessoal/domiciliar, soma diretamente os pesos por controle, verifica chaves e ordem, unicidade, pesos pessoa=domicílio, extração=saída parcial, positividade e limites [1,12], base4 e fator=peso/4. Verifica ainda os dois inteiros implícitos do peso IBGE, seus totais por situação e o limite do eventual resto. Não tenta reproduzir o sorteio do R. Os sete arquivos de entrada/saída lidos por UF têm SHA antes/depois iguais. Nenhuma fonte foi gravada.

Uma execução contra os pesos antigos do PR falhou precisamente nos alvos municipais atuais (`parana/qc_antigo_esperado_falha.json`): a validação não aprova apenas por ler resíduos pequenos do diagnóstico antigo.

As saídas novas em `tmp/fechamento_integral_1960/pesos_municipais_20260923_021933_338649` passaram:

| UF | Domicílios / pessoas | Controles | Resíduo relativo direto máximo | RSS máximo observado |
|---|---:|---:|---:|---:|
| MT | 45.199 / 227.936 | 147 | 1,03×10⁻¹⁴ | 206.495.744 bytes |
| PR | 224.179 / 1.111.227 | 347 | 3,73×10⁻¹³ | 303.534.080 bytes |
| MG | 489.505 / 2.494.671 | 986 | 4,50×10⁻¹⁴ | 408.768.512 bytes |

Relatórios completos: `parana/qc_mt_novo_02.json`, `qc_pr_novo_01.json`, `qc_mg_novo_01.json`. A versão MT01 anterior à inclusão das assinaturas permanece como cronologia; MT02 é a versão completa desta entrega.

O reaproveitamento de SP também foi testado, não apenas inferido pela leitura do
código. Com o guia já corrigido, os pesos anteriores passaram na reconstrução dos
1.025 controles e na leitura de 740.936 domicílios/3.319.710 pessoas; máximo resíduo
direto 1,05×10⁻¹³, RSS 501.305.344 bytes. Os pesos IBGE fecharam 8.148.929 urbanos e
4.825.770 rurais. Prova: `parana/qc_sp_reuso_01.json`, sobre a execução anterior
`tmp/execucao_1960_20260922/pesos25_reduzido_20260922_095713_201741`. Não houve novo
ajuste de SP: corrigir o total informativo de Jardinópolis não alterou seus alvos.

As reescalas foram PR 4.263.721/4.277.763 e MG 9.698.118/9.798.780. Em MT, o denominador é **905.632**, não 910.262: Alto Garças (9111, 4.630 habitantes no guia) não está na amostra disponível; há 63 dos 64 municípios. O procedimento existente reescala apenas as âncoras com suporte para o total definitivo 892.233. A auditoria confirmou essa regra, não declarou recuperada a cobertura municipal ausente. Já o peso IBGE usa os totais integrais por situação do guia. Nesta execução fechou exatamente urbana/rural: MT 364.004/546.258, PR 1.327.982/2.949.781 e MG 3.940.457/5.858.323.

## Limite da conclusão

A pendência aritmética do PR está resolvida, com documentação integral, e os cinco erros adicionais estão corrigidos e testados. O ajuste numérico das três UFs foi refeito e conferido. Não foram resolvidos por esses resultados os vínculos e duplicatas históricos, a ausência de municípios/fontes, a política não identificada de idade ignorada do Quadro5 preliminar, a incompletude domiciliar, nem a validação das variâncias. Essas limitações permanecem nas notas próprias.
