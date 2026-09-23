# Revisões independentes dos novos casos de 1960

Esta frente não alterou manifestos ou código de produção e não executou R. Os testes R novos foram entregues à integração para execução sequencial.

## Preservação paulista

A proposta de manter as linhas **773911 e 773913** está em [duplicata_sp_composta.json](fechamento_integral_1960_evidencias/duplicata_sp_composta.json). Foram relidos os 14 registros brutos dos três grupos envolvidos e os três boletins correspondentes da fonte paulista. O alvo tem quatro pessoas, cartão e geografia exatos nos 25 campos; seu grupo completo é único nas duas fontes. Os dois concorrentes têm grupos próprios independentes. Seis contraprovas Python foram recusadas: perda de pessoa, mudança de idade, cartão, geografia, chave e ocorrência adicional da composição.

As duas linhas de CSV propostas estão em `tmp/fechamento_integral_1960/duplicatas/duplicata_sp_decisoes_propostas.csv`. O teste `references/fechamento_integral_1960_duplicatas_teste_sp.R` verifica o bloqueio anterior, a preservação das quatro pessoas com manifesto temporário e a recusa de grupo incompleto ou texto adulterado. Ele conserva o manifesto real.

Uma conferência complementar incluiu também os **129 grupos paulistas sem cartão no índice atual**, agregados pela chave pessoal. Nenhum possui a composição completa de qualquer dos três grupos da prova. Assim a unicidade não depende de ignorar os registros órfãos.

A revisão de chaves partidas examinou todas as 17 fontes. Só encontrou **SP64150/005**, com as três pessoas nas linhas 1–3 e o cartão na última linha 4.062.698. A composição reagrupada não coincide com nenhum dos três grupos da prova paulista nem com qualquer dos 395 contextos pessoais residuais. Portanto essa descontinuidade não acrescenta uma alternativa omitida à proposta paulista. O resultado está em `revisao_independente_vinculos.json`, na pasta de resultados desta frente.

## Oito cartões para vinte pessoas existentes

Foi refeito o teste de unicidade dos seis cartões concorrentes decisivos do pacote de vínculos, usando o índice construído nesta frente e nova leitura das fontes. Os membros atuais coincidem com os membros físicos e suas chaves; nenhum depende de correção textual, vínculo anterior ou pessoa órfã usada como prova de si mesma. As multiplicidades foram conservadas. Os grupos-alvo não têm cartão na chave, mesmo removendo o distrito da consulta.

Não foi identificado obstáculo à proposta de oito cartões em SP/GO para vinte pessoas existentes. Os dois cartões paranaenses, para sete pessoas, continuam separados: o concorrente 866162 tem V216 igual a 19 numa cópia e 17 na outra, diferença além de 00/63. Esta revisão não aprovou a ampliação do critério para esse caso.

Foi identificada uma invariante que precisava ficar explícita no código: a chave pessoal de cada concorrente deve concordar com seu cartão antes de usar a unicidade do multiconjunto. Os seis concorrentes atuais passam. O autor da implementação foi informado e confirmou a inclusão dessa guarda.

A prova é `tmp/fechamento_integral_1960/duplicatas/revisao_independente_vinculos.json`. A eliminação de candidatos usa o universo de buscas do auditor vigente; não demonstra inexistência absoluta sob qualquer combinação imaginável de erros históricos de chave e cartão.

## Minas: identificação anterior ao reparo

A nova prova de MG405458 foi conferida separadamente. A varredura das 17 fontes encontrou três ocorrências da pessoa intacta 405457 e 39 da intacta 405459. A presença conjunta das duas só ocorre em **MG40880/001**. Nenhum caractere da pessoa danificada foi usado para identificar essa conjunção.

Em outra consulta, todos os caracteres pessoais legíveis de 405458 foram conservados, exceto as posições danificadas 20 e 22. Só houve uma ocorrência compatível nas 17 fontes: a linha 567047 do mesmo boletim. A proposta altera apenas esses dois caracteres, recupera V203 = 7 e AGE = 79, conserva o dígito 9 já legível e preserva REC_TYPE = 3.

Os concorrentes 405480 e 405486 têm composições próprias únicas em ambas as fontes, novamente contadas sem usar qualquer das três pessoas órfãs. Seus desacordos pessoais são apenas V216 = 00/63. A busca de cartões foi refeita com o perfil reparado somente em memória: os mesmos **289 candidatos e suas pistas** foram encontrados; os dois acima continuam os únicos que dependem da nova prova composta. Portanto o reparo não introduziu um concorrente pessoal que tivesse escapado à lista anterior.

Não foi identificada circularidade nessa prova nova. Ela sustenta o reparo localizado, seguido da recuperação do cartão, como etapas distintas. A prova desta revisão é `tmp/fechamento_integral_1960/duplicatas/revisao_independente_mg405458.json`; a conferência dos 289 candidatos foi refeita por consulta independente ao índice atual, comparando os identificadores e as pistas com `vinculos/mg_proposta01/proposta_mg.json`.
