# Vínculos familiares: o que foi resolvido nesta rodada

Esta nota descreve a implementação de 22 de setembro de 2026. Ela não substitui nem altera os cadernos da investigação anterior. As mudanças são localizadas: não se aplicou uma regra geral de anexar pessoas ao cartão anterior, de trocar números de pasta ou de corrigir respostas pelo que parece mais provável.

## Resultado concreto

Treze pessoas que estavam sem família identificada passam a ter um vínculo demonstrado: duas por identificação de cartões já existentes, seis mediante recuperação de dois cartões na outra cópia dos dados e cinco após recuperação do distrito danificado de um cartão existente. **Nenhuma dessas treze pessoas foi criada. Todas já estavam em HHOLDA.**

O inventário independente recalculado pela integração desta rodada registra **1.216 registros pessoais ainda sem família identificada, em 481 grupos de chave**. O total inclui três fragmentos indecifráveis: reuni-los por chave vazia não demonstra uma família comum nem quantas pessoas históricas representam. Não se declarou que esses casos restantes estavam resolvidos. A contagem anterior era 1.229 registros; a diferença de treze corresponde às ações abaixo. Outros problemas — inclusive conflitos territoriais em vínculos já existentes — têm conferências próprias e não devem ser confundidos com essa contagem.

| Pessoas que já existiam | Antes | Decisão implementada | O que não muda |
|---|---|---|---|
| 142402 | Um algarismo ilegível na pasta impedia localizar o cartão | Liga ao cartão 142817; família completa com oito pessoas conferida na outra cópia | Texto, idade, parentesco, município e todas as respostas pessoais |
| 259248 | Um algarismo ilegível na pasta impedia localizar o cartão | Liga ao cartão 259657; família completa com sete pessoas conferida na outra cópia | Os mesmos campos; o espaço ilegível não é reescrito |
| 132193–132196, Ceará | Quatro pessoas sem cartão sob pasta 15004 / boletim 116 | Recupera o cartão conservado na fonte de 25%, pasta 14990 / boletim 116 | A pasta operacional continua 15004; nenhuma pessoa é importada; V216 da pessoa 132194 continua 00 |
| 333756–333757, Bahia | Duas pessoas sem cartão sob pasta 32426 / boletim 233 | Recupera o cartão conservado na fonte de 25%, pasta 32426 / boletim 006 | O boletim operacional continua 233 e todas as respostas pessoais permanecem iguais |
| 239457–239461, Pernambuco | Cinco pessoas com distrito 07 não encontravam o cartão 238422, cujo distrito estava escrito X7 | Deriva distrito operacional 07 somente para o cartão 238422 e o chefe 238423; documenta os cinco vínculos | Os textos continuam com X7; o valor original fica em coluna própria; pasta 22366 e V216 da pessoa 239457 continuam intactos |

Uma **pasta** é uma unidade do arquivo que também participa do desenho da amostra. Um **boletim** identifica uma família dentro da pasta. Um **cartão familiar** é a linha que contém os dados da família/domicílio; não é uma pessoa. Recuperar um cartão ausente não significa acrescentar seus moradores da fonte de 25%: os moradores usados continuam sendo exclusivamente os que já existiam na amostra de 1,27%.

## Por que as duas pessoas com pasta ilegível puderam ser ligadas

Na linha 142402, o trecho legível da pasta é `152 0`, e o boletim é 067. O procedimento não decidiu que todo espaço deve virar 9. Examinou os cartões compatíveis com **todos os caracteres legíveis**, o município, o distrito e a situação; restou o cartão 142817, da pasta 15290 / boletim 067. Além disso, as oito pessoas do grupo correspondem integralmente às oito da outra cópia dos dados.

O caso 259248 segue a mesma lógica: pasta `22 34`, boletim 069, cartão 259657 da pasta 22934. Aqui são sete pessoas, não apenas um perfil individual semelhante. O texto danificado continua preservado. O vínculo é uma informação adicional, com a linha de origem e a prova registradas.

Isso é diferente do antigo atalho de usar o cartão imediatamente anterior: a distância física entre linhas não é a razão da decisão.

Prova: [vinculos_chaves_incompletas.json](resolucao_residuais_1960_evidencias/vinculos_chaves_incompletas.json). Implementação das decisões: [manifesto de vínculos](../read_guides/1960_amostra_127_vinculos.csv).

## Ceará e Bahia: recuperar o cartão não autoriza trocar a pasta da amostra

As duas cópias possuem numerações diferentes para os grupos identificados. O tratamento distingue explicitamente:

- **Número operacional:** o que a amostra de 1,27% preservou e que continuará sendo usado nessa base.
- **Número da fonte:** onde o cartão foi encontrado na cópia de 25%, armazenado como procedência da recuperação.

Na Bahia, as duas pessoas coincidem em todos os 25 campos pessoais usados na conferência. Os dois perfis são únicos, separadamente, na respectiva UF nas duas fontes. Foram examinados 240 cartões concorrentes, sem alternativa restante sob a busca documentada.

No Ceará, três pessoas têm os 25 campos exatamente iguais e perfis únicos nas duas fontes. A quarta tem uma diferença: V216, o ano do casamento, é 00 na amostra de 1,27% e 63 na fonte de 25%. Essa diferença **não é resolvida copiando 63**. Ela é preservada; os outros 24 campos, a composição completa e o território coincidem. Foram examinados 19 cartões concorrentes. Nenhuma alternativa permaneceu.

O código exige uma prova específica, assinada por hashes dos arquivos, para aceitar essas duas decisões. Um hash é uma impressão digital do arquivo: se ele muda, a conferência precisa ser refeita. São exigidos ao menos dois testemunhos completos e únicos — aqui três no Ceará e dois na Bahia —, grupo completo, território concordante e ausência de alternativas segundo a busca registrada. A hipótese não foi convertida em uma regra geral de renumeração de pastas vizinhas.

O manifesto de recuperação agora contém 32 cartões para 80 pessoas já existentes: os 30 cartões / 74 pessoas anteriores mais estes dois cartões / seis pessoas. Os 30 anteriores foram preservados e reconferidos na integração. A prova vigente é indicada no campo `reconciliacao_chave.prova_arquivo` dos dois cartões no [manifesto atual](../read_guides/1960_amostra_127_cartoes_recuperados.json); a integração a reaudita quando as decisões de entrada mudam. A primeira prova desta rodada, mantida como histórico, é [cartoes_fora_chave.json](resolucao_residuais_1960_evidencias/cartoes_fora_chave.json).

## Pernambuco: recuperar um caractere danificado sem apagar o original

O cartão 238422 e o chefe 238423 trazem distrito `X7`. As outras cinco pessoas do mesmo grupo trazem `07`. O cartão tem a pasta 22366 e o boletim 154, ambos legíveis.

Não basta notar que X se parece com um algarismo. A decisão combina fatos independentes:

1. Existe um único cartão na amostra de 1,27% sob a mesma pasta, boletim e território legíveis.
2. Na fonte de 25%, esse boletim tem um cartão e seis pessoas, com ordens e quantidade verificadas.
3. Os 15 campos familiares coincidem; a fonte registra distrito 07, compatível com o algarismo 7 ainda legível.
4. O chefe já era um testemunho único **antes** da recuperação de sua nacionalidade V208: a procura ignorou V208, então em branco. Não se usou a resposta recém-preenchida para justificar a própria identificação.
5. As seis pessoas podem ser pareadas integralmente, preservando uma única divergência V216=00/63 na pessoa 239457.

A busca ampla examinou outros 326 cartões. Sete eram pistas por proximidade ou chave parecida, mas tinham boletins 124, 144, 150, 153, 156, 157 e 184; nenhum preservava o boletim 154 legível nem continha o grupo completo de seis. Esse resultado é diferente de afirmar que a busca ampla deu zero pistas. O critério localizado não permite trocar caracteres legíveis para escolher outra família.

O resultado fica assim:

| Registro | Texto preservado | Distrito operacional | Marca de recuperação |
|---|---|---|---|
| Cartão 238422 | Continua com X7 | 07 | Sim; origem X7 e caminho/hash da prova |
| Chefe 238423 | Continua com X7; o reparo anterior de V208 é separado | 07 | Sim; origem X7 e caminho/hash da prova |
| Cinco pessoas 239457–239461 | Continua com 07 | 07 | Não houve reparo de distrito nessas pessoas |

A pasta continua 22366. O vínculo às cinco pessoas passa a ser explícito no manifesto. A diferença de ano do casamento continua visível. A prova e suas alternativas estão em [distrito_pe_operacional.json](resolucao_residuais_1960_evidencias/distrito_pe_operacional.json) e [distrito_pe_proposta.json](resolucao_residuais_1960_evidencias/distrito_pe_proposta.json).

## Proteção contra famílias inteiras coincidentes

A conferência de duplicatas pessoais não bastava para detectar dois cartões diferentes com famílias inteiras de conteúdo igual. A reconstrução agora verifica esse problema separadamente, sem apagar ou fundir pessoas.

A guarda compara UF, distrito, os 15 campos familiares e a composição completa dos 25 campos pessoais. A quantidade de ocorrências também conta: dois irmãos com respostas iguais continuam sendo duas ocorrências. Registros danificados ou com variáveis anuladas ficam fora dessa comparação de igualdade; isso não os torna válidos.

Quando dois grupos coincidem, exige-se uma disposição explícita e provas verificadas. Cinco conjuntos têm boletins distintos preservados também na outra fonte. Isso sustenta **mantê-los separados nos arquivos**, não prova identidade civil ou ausência de erro histórico. Outros cinco conjuntos continuam bloqueados: a repetição não foi transformada em autorização de exclusão.

O código relê os literais da fonte de 25%, confere o grupo completo, ordens, quantidades, geografia e respostas. Não basta trocar no JSON uma indicação de “pendente” por “aprovado”. Veja o [manifesto de famílias coincidentes](../read_guides/1960_amostra_127_familias_coincidentes.json) e a nota da frente de duplicatas.

## O que continua realmente sem prova suficiente

**Rio Grande do Sul, pessoas 1009631/1009632.** Foi testada outra via de identificação: um testemunho completo único mais um segundo perfil único quando se desconsidera apenas V216. Ela falhou. O segundo perfil tem duas ocorrências completas na amostra de 1,27% e oito ocorrências de 24 campos na fonte de 25%. Logo, não é o segundo testemunho raro que essa alternativa exigiria. A família candidata pode ser correta, mas não foi demonstrada por essa via. [Conferência reproduzível](resolucao_residuais_1960_evidencias/segunda_testemunha_rs.json).

**Belo Horizonte, pasta 40090 / boletim 004.** As duas pessoas coincidem com a fonte, mas sete cartões concorrentes ainda não foram excluídos pela busca documentada. Criar um cartão sem resolver essa concorrência pode duplicar uma família já existente sob outra chave.

**Minas Gerais, pasta 40880 / boletim 001.** Um reparo textual conjunto do integrante 405458 poderia completar o grupo de três, porém dois cartões concorrentes continuam presentes. O reparo não foi aplicado para forçar a recuperação, nem se exigiu circularmente que a recuperação já estivesse feita para considerar a hipótese.

**Cartão vazio 780535, São Paulo.** A outra cópia contém cinco pessoas, mas isso não prova quais cinco pessoas da amostra de 1,27% pertencem a esse cartão. Importá-las integralmente da fonte de 25% aumentaria indevidamente a amostra. Nenhuma pessoa foi acrescentada.

**Família convivente 743894, São Paulo.** Há correspondência pessoal, mas os cartões divergem na espécie da família/domicílio. A fonte não autoriza decidir automaticamente se deve ser uma residência própria ou se deve integrar a residência anterior. O bloqueio permanece.

**Cartão 695175, São Paulo.** A comparação correta envolve três pessoas já existentes — 695176, 661580 e 661581 —, não uma pessoa com outras duas desaparecidas. A identidade do grupo é forte, mas município, situação e atributos do cartão divergem entre cópias. Corrigir esses campos exige decidir qual conteúdo territorial/habitacional é válido; essa decisão não decorre apenas dos perfis pessoais.

**Pessoa 611254, Guanabara.** O cartão 616230 é candidato compatível com os caracteres legíveis e com a composição relacional. Falta a cópia de 25% da UF para a contraprova adotada nos casos resolvidos. Proximidade, idade, casamento e número de filhos não foram tratados como prova suficiente de identidade familiar.

Além desses exemplos, as classificações por pessoa da investigação anterior continuam disponíveis. Não se atribuiu um cartão pelo perfil “mais parecido” nem se chamou a falta de prova de certeza de erro.

## A exigência de dois testemunhos escondia casos unipessoais?

Esta possibilidade foi verificada especificamente nos 199 alvos classificados anteriormente como composição pessoal exata na mesma chave, mas cartão ainda pendente. São 80 grupos completos: 53 com duas pessoas, 14 com três, cinco com quatro, três com cinco, dois com seis e três com oito. **Nenhum é unipessoal.** Portanto, nesse subconjunto, não há caso bloqueado simplesmente porque uma família de uma pessoa jamais poderia fornecer dois testemunhos.

Essa checagem não aprova os 199 casos e não prova que nenhuma outra alternativa metodológica possa ser investigada. Ela responde à dúvida estrutural delimitada sem repetir uma busca nacional inteira. [Cobertura dos 80 grupos](resolucao_residuais_1960_evidencias/conferencia199_unipessoais.json).

## Como auditar e reproduzir

As buscas e preparadores desta frente são Python e leem os arquivos originais; não executam R, não reconstruem parquet, não alteram pesos e não escrevem os dados históricos. As promoções para manifestos foram feitas por patches explícitos.

- [resolver_vinculos_chaves_incompletas_1960.py](resolver_vinculos_chaves_incompletas_1960.py): prova dos dois vínculos; testes pequenos em `test_resolver_vinculos_chaves_incompletas_1960.py`.
- [resolver_cartoes_chaves_fonte25_1960.py](resolver_cartoes_chaves_fonte25_1960.py): novo índice127, testemunhos nas 17 fontes e cartões concorrentes para BA/CE; cinco testes em `test_resolver_cartoes_chaves_fonte25_1960.py`.
- [conferir_distrito_pe_residual_1960.py](conferir_distrito_pe_residual_1960.py) e [preparar_distrito_pe_operacional_1960.py](preparar_distrito_pe_operacional_1960.py): investigação limitada e promoção documentada de PE.
- [conferir_segunda_testemunha_rs_1960.py](conferir_segunda_testemunha_rs_1960.py): consulta dos índices existentes e releitura somente dos candidatos na fonte gaúcha.
- [conferir_limite_unipessoal_residual_1960.py](conferir_limite_unipessoal_residual_1960.py): enumera todos os 80 grupos / 199 alvos do subconjunto examinado.

Os testes R são microlotes, para execução sequencial pelo runner isolado: [dois vínculos](test_vinculos_chaves_incompletas_1960.R), [dois cartões BA/CE](test_cartoes_chaves_fonte25_1960.R), [distrito de Pernambuco](test_distrito_pe_operacional_1960.R) e [famílias coincidentes](test_resolucao_familias_coincidentes_1960.R). O teste de finalização de PE usa uma segunda pasta **fictícia somente dentro do teste**, evitando um estrato solitário artificial; esse controle não integra dados, provas históricas ou manifestos.

As contagens de unicidade e a busca de cartões concorrentes são produzidas pelos auditores e preservadas com as assinaturas dos arquivos examinados. Os microlotes R verificam a aplicação das decisões, a releitura das fontes e os bloqueios de entradas adulteradas; não repetem uma varredura nacional a cada teste.

Os sete testes Python de vínculos/cartões passaram. O teste R atualizado de BA/CE passou com duas famílias, seis pessoas e dezessete contraprovas; o de PE passou com seis pessoas, uma família e treze contraprovas, inclusive preservação da origem até a finalização de 1,27%. O primeiro teste BA/CE tinha onze contraprovas; a versão ampliada não deve ser confundida com esse ensaio anterior. Os resultados consolidados estão no [caderno da implementação](resolucao_residuais_1960_evidencias/LEIAME.md). Arquivos de produção, provas e dados originais permanecem separados dos controles dos testes.

A finalização de 1,27% preserva as novas marcas de distrito, mas isso não certifica sua propagação ao esquema fechado da compilação combinada. Para PE, a compilação usa o ramo de 25%. Além disso, a compilação bloqueia cartões recuperados no ramo de 1,27% enquanto sua origem não estiver representada no esquema final. Essa proteção não foi removida.
