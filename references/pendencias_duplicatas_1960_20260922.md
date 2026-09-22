# Perfis repetidos: o que a conferência acrescentou

Esta nota documenta a auditoria de 22/09/2026. As três listas abaixo são propostas conferidas, não uma afirmação de que a base completa já foi reconstruída. A integração decide quais entradas promover para os manifestos de produção.

## Por que duas respostas iguais não bastam

Em uma família da Paraíba, pasta 19030, boletim 134, as linhas 164631 e 164633 descrevem dois filhos de 5 anos com as mesmas respostas. A fonte de 25% contém dois registros correspondentes, nas linhas 21419 e 21420, com números de ordem diferentes. Os outros quatro integrantes, o cartão e a geografia também coincidem. A conclusão é manter os dois registros. Não precisamos saber qual filho é qual; precisamos não transformar dois em um.

Outra situação é haver duas cópias integrais em HHOLDA, mas uma ocorrência na fonte25. Isso só foi proposto como remoção quando a família inteira também pôde ser conciliada: mesmos integrantes, quantidades sustentadas pela fonte e nenhum outro perfil desaparecendo. Escolher a cópia de menor linha é apenas uma escolha operacional entre textos idênticos, não uma identificação civil.

## Três classes de evidência, mantidas separadas

| Classe | Grupos repetidos | Linhas127 | Remoções propostas | Restaurações contra a regra antiga |
|---|---:|---:|---:|---:|
| Cartão e 25 campos pessoais integralmente concordantes |199|398|15|0|
| Mesma composição por 24 campos; divergência V216=00/63 preservada |447|894|244|2|
| Mesma evidência pessoal, com diferenças domiciliares não identificadoras preservadas |308|616|231|1|
| Total, sem sobreposição |954|1.908|490|3|

As classes adicionais não declaram que 00 e 63 significam a mesma coisa. No quesito V216, 00 indica que não vive com cônjuge; 63 indica ano ignorado. A correspondência usa os outros 24 campos e o grupo completo, mas conserva as respostas originais. Não é permitida a fusão de dois perfis diferentes só porque a retirada de V216 os faria parecer iguais. Divergências com outros valores continuam bloqueadas.

Na terceira classe, diferenças como tipo de construção ou instalação sanitária não são usadas para invalidar automaticamente uma composição pessoal inteira. Espécie do boletim, município, distrito, situação e chave precisam concordar. Todos os atributos divergentes permanecem registrados; não se copia a resposta domiciliar da fonte25 para HHOLDA.

Cada grupo das classes 2 e 3 apresenta a quantidade de correspondências exatas nos 25 campos e a quantidade que exige a comparação por 24. Apenas três grupos da classe 2 não possuem testemunha pessoal exata nos 25 campos: `21-21438-116-linha195452`, `21-21438-124-linha195508` e `21-21362-18-linha220853`. Cada um tem três pessoas, todas identificáveis pelos 24 campos restantes e pelo conjunto. Essa ressalva fica explícita para a revisão integrativa.

As três restaurações propostas são 211049, 392256 e 217736. A última pertence a dois filhos de idade ignorada: excluir um deles pela igualdade das respostas seria indevido, porque a outra fonte preserva duas ocorrências. As respostas dos dois são mantidas, inclusive os códigos ignorados.

## O que permanece sem prova

O inventário integral cobriu 1.417 grupos e 2.836 linhas. Depois das três classes, restam 463 grupos e 928 linhas, incluindo 127 linhas que o procedimento antigo excluía sem prova agora confirmada. Não foram tratadas como duplicatas demonstradas.

| Razão principal, sem dupla contagem | Grupos | Exclusões antigas sem prova |
|---|---:|---:|
| Fonte25 indisponível para a UF |176|14|
| Outros integrantes do grupo divergem |182|58|
| Geografia ou distrito diverge |15|0|
| Perfil repetido não localizado pelos 24 campos no boletim da fonte de 25% |57|40|
| Ano do casamento diverge fora do par00/63 |15|10|
| Há mais ocorrências na25 do que linhas127 disponíveis |12|4|
| Espécie ou geografia do cartão diverge |4|1|
| Cartão25 ausente ou não único |1|0|
| Texto pessoal corrompido |1|0|

Não foi identificada uma prova interna determinística que permita fechar esses casos usando apenas HHOLDA. Seu cartão não contémV100, a quantidade declarada de pessoas; tampouco preserva o número de ordem pessoal da25. O identificador do arquivo é compartilhado pelo grupo familiar. Estar na cauda do grupo ou repetir o código de chefe/cônjuge é um sinal para investigar, não uma contagem independente. Isso não é declaração de impossibilidade de pesquisa futura; uma fonte adicional ou correspondência fora da chave pode trazer nova evidência.

## Caminho de auditoria

Raiz dos resultados: `tmp/fechamento_registros_1960_20260922/duplicatas/`.

- `completa_01/resultado.json` e `decisoes_candidatas.csv`: inventário integral, contextos literais e 199 grupos estritos.
- `projecao_completa_03/projecao24.json` e `propostas_condicionais.csv`: 447 grupos adicionais, pareamentos por grupo, testemunhas e divergências V216.
- `atributos_completa_02/projecao24.json` e `propostas_condicionais.csv`: 308 grupos adicionais, incluindo todas as diferenças domiciliares.
- `residuais_01/residuais463.json`: cada linha dos 463 grupos restantes, ação histórica, motivos completos e razão principal mutuamente exclusiva.

O auditor reproduzível é `references/auditoria_pendencias_duplicatas_1960.py`. Os 31 testes em `references/test_auditoria_pendencias_duplicatas_1960.py` incluem grupo incompleto, fonte ausente, códigos inválidos, geografia/chave erradas, mudança de idade, variantes que colidiriam ao omitir V216 e preservação dos textos. Piloto real com três grupos da PB precedeu a varredura integral. Os originais, parquets e manifestos não foram alterados por esta subtarefa.

## Revisão independente dos 17 reparos de texto

Também foi revisado, sem alterá-lo, `read_guides/1960_amostra_127_reparos_fonte25.json`. Uma leitura independente conferiu HHOLDA e os cinco gzips necessários, todos os campos legíveis e a composição dos 15 grupos familiares. Foram enumerados todos os pareamentos um-a-um possíveis, sem omitir V216: cada grupo tem exatamente um pareamento; cada valor reparado tem uma única origem possível.

Os 17 reparos passaram. Por exemplo, a idade parcialmente ilegível `0 ` da linha 760742 pode ser recuperada como `08`, porque a outra pessoa correspondente está determinada pelo restante do grupo e registra 08. Nenhum outro campo é alterado. Evidência em `revisao17_01/revisao_independente.json`; reprodução por `references/revisao_independente_reparos_1960.py`.

Uma rodada adicional independente confirmou seis outros reparos, nas linhas 541238, 963286, 998640, 1019837, 675159 e 706676. Cada alvo coincide integralmente nos campos não reparados; as diferenças V216=00/63 em outros integrantes permanecem sem alteração. No primeiro grupo, V102=5 na127 e4 na25 é uma diferença habitacional documentada, não uma resposta copiada. Os seis grupos têm pareamento único. O controle negativo da linha760804 foi rejeitado porque outro integrante,760807, contém V214 e V218 inválidos: substituir esses códigos por ausência não demonstra igualdade. Evidência em `revisao6_01/revisao_independente.json`.

## Revisão independente dos vínculos entregues pela outra frente

O script `references/revisao_independente_vinculos_1960.py` releu HHOLDA e os 12 gzips pertinentes, usando as decisões congeladas antes da integração e as três classes de duplicatas. Os 166 vínculos em 82 grupos passaram. A contagem de testemunhas foi refeita em toda a UF na amostra de 1,27%; todos os 57 grupos condicionais têm pelo menos duas pessoas com perfis exatos e únicos na UF. Os 25 grupos estritos têm concordância integral; três deles não possuem duas testemunhas únicas na UF, condição que foi exigida apenas dos casos condicionais.

Não havia outros integrantes ligados aos cartões de destino fora dos conjuntos comparados, nem pessoas dos conjuntos já ligadas a outro cartão. As diferenças geográficas pessoais continuam visíveis. A linha 425558 conserva duas origens possíveis na amostra de 25%, 898627 e 898631, ambas no mesmo cartão; isso permite confirmar a família, não a identidade civil do filho. Evidência em `tmp/fechamento_registros_1960_20260922/vinculos/revisao_independente_02/revisao_independente166.json`.
