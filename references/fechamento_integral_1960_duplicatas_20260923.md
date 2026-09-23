# Reexame integral das duplicatas de 1960

## Estado final após a integração de 23/09/2026

As linhas paulistas **773911 e 773913 já foram incorporadas ao manifesto com ação manter**, após a prova composta e sua revisão independente. O manifesto vigente tem **6.463 decisões: 3.727 manter e 2.736 remover**. Permanecem **457 conjuntos pessoais/916 linhas** sem decisão demonstrada; os cinco conjuntos familiares coincidentes também continuam pendentes. A investigação abaixo documenta o universo inicial de 458 conjuntos/918 linhas, não a contagem final.

A [revisão final independente](fechamento_integral_1960_duplicatas_revisao_final.md) registra a cadeia vigente de 41 cartões/103 pessoas preexistentes, 15 JSON ativos e 410 vínculos de hashes conferidos, além da recontagem dos sete concorrentes compostos no índice127 atual. A prova portátil da preservação paulista é [duplicata_sp_composta.json](fechamento_integral_1960_evidencias/duplicata_sp_composta.json).

## Investigação inicial, preservada como histórico

Todos os **458 conjuntos pessoais/918 linhas**, incluindo as **127 exclusões históricas em 125 conjuntos**, foram reexaminados com os manifestos então vigentes. Também foram reexaminados os cinco conjuntos de famílias inteiras coincidentes. Esta investigação não aplicou decisões diretamente; a integração posterior da preservação paulista está registrada acima.

O índice novo foi construído com o leitor existente, cache SQLite de 16MiB e leitura sequencial. Contém 899.856 registros pessoais legíveis e 174.467 cartões; os três fragmentos já classificados como corrompidos não são artificialmente reconstruídos no índice. A lista nominal de 918 linhas inclui os dois fragmentos que formam um conjunto computacional. O piloto RN, com dois pares reais, precedeu a nova varredura das **17 fontes/18.055.053 linhas**. O uso de memória observado nas conferências ficou entre 37 e 108MiB.

## Resultado da recontagem

Há 395 contextos legíveis para os 457 conjuntos não corrompidos. Nenhum deles recebeu mudança de composição, texto ou cartão desde a busca anterior, após considerar as correções e os vínculos atuais. Portanto os reparos da rodada precedente não liberam inadvertidamente uma pendência desta lista.

A busca nacional atual encontrou 25 alternativas de composição por 24 campos, oito fora de chave, e nenhuma que passe todas as condições vigentes de forma automática. Os 117 contextos viáveis no ensaio de até um campo adicional continuam hipóteses; 108 dependem efetivamente de outra divergência. Não se transformou esse ensaio em regra de recodificação ou exclusão.

A prova nominal está em `tmp/fechamento_integral_1960/duplicatas/testemunhos458.json`: para cada conjunto há textos brutos relidos, ação histórica, motivos atuais, alternativas integrais, ensaio de multiplicidades e a informação adicional necessária. As razões podem se sobrepor; os 458 conjuntos não foram substituídos por uma amostra de exemplos.

## Proposta histórica paulista, posteriormente aprovada e incorporada

Uma conferência adicional examinou a unicidade do **grupo inteiro**, sem restringir a busca aos atributos do cartão e sem exigir que cada pessoa seja individualmente rara. Foram pesquisados os agrupamentos atuais e físicos na amostra127, além da busca integral anterior nas17fontes.

O cartão **773909, SP63788/146**, tem quatro pessoas; sua composição de24campos é única na UF127 e em todas as17fontes25. A correspondência é **3827371, SP63788/163**, e os **25 campos pessoais completos, as quatro ocorrências, o cartão e a geografia coincidem**. A linha repetida tem duas ocorrências25,3827374/3827375. Nenhuma respostaV216 precisa ser omitida para confirmar a igualdade deste grupo.

O cartão127 que usa o boletim163, **774008**, tem grupo próprio único em SP63788/180 na25, com quatro pessoas, cartão/geografia exatos e três testemunhas pessoais exatas únicas naUF127. A alternativa que reduziria o grupo-alvo a três pessoas, SP63788/140 na25, tem grupo próprio127 **773767, boletim123**, com composição e cartão exatos; difere do cartão-alvo emV103. Não foi escolhida por favorecer uma exclusão.

Isso sustentou a **preservação de773911 e773913 pelo critério de unicidade da composição integral e contraprova dos concorrentes**, depois revisada e promovida ao manifesto vigente. Não se trata de identidade civil. Os perfis individuais do grupo-alvo aparecem5,19 e31vezes naUF25 na comparação24, razão pela qual a regra anterior de pessoas individualmente únicas não o aprovava. A investigação inicial está em `alternativas_familias_e_concorrentes.json` e `unicidade_composicao24.json`, na mesma pasta de resultados; a prova portátil integrada está ligada no topo desta nota.

No alvoPE21604/118, cartão200309, a composição de16pessoas também é única nasduasfontes e corresponde a25boletim156. Contudo, o cartão127 concorrente200562 só encontra composição completa em25boletim006 com situação5/1divergente. A nova busca explicitou esse obstáculo; não resolveu a geografia do concorrente por conveniência.

## As cinco coincidências familiares receberam uma busca global própria

A investigação pessoal anterior não abrangia esses cinco conjuntos. A busca nova pesquisou suas composições completas nas17fontes, conservando multiplicidades, e releu seus11cartões/42pessoas. Nenhuma coincidência familiar passou a ter uma correspondência integral sem ressalva.

- **AM02104/248 e250;249 e251:** continuam os dois grupos repetidos de quatro e onze pessoas. Não há fonte25estadual. Nenhuma das17outrasfontes fornece composição completa correspondente; isso não substitui a fonte ausente.
- **MA10820/155 e236:** o casal e o cartão continuam repetidos. Falta a fonte25estadual e não apareceu composição integral nasoutrasfontes.
- **SP60118/109,116 e220:** surgiu uma alternativa explícita adicional no boletim25**195**. Ela coincide nos25campos pessoais com os três grupos, mas diverge em seis campos do cartão. O boletim25**220** também coincide nos25campos pessoais, mas diverge emV112/V113. Nos boletins originais109/116 há ainda divergências pessoais. Logo existem múltiplas correspondências pessoais possíveis; a escolha não é determinada pela igualdade dos perfis.
- **PE21322/167 e179:** ambos encontram a composição24 no boletim25**009**, mas há divergências emV102,V107,V112. Nas próprias chaves a pessoa diverge emV215=5/1 eV216=63/0. Essa contraprova impede afirmar que apenas o ano do casamento difere.

## O limite tem uma testemunha concreta

Dos458conjuntos,456 têm textos brutos completos literalmente iguais; um só se torna igual depois do reparo de layout preexistente de199617, comparado com199618; e os fragmentos951432/951433 **não são textos iguais**. O último conjunto surge da perda dos campos e não é prova de duplicação.

Para cada conjunto legível, o JSON registra duas interpretações da mesma sequência observável: pessoas diferentes com respostas iguais; ou regravações de uma pessoa. Isso é uma demonstração de que **HHOLDA isolado não identifica a multiplicidade histórica**, não uma estimativa do número verdadeiro de pessoas. A fonte25 pode distinguir as interpretações apenas quando sua correspondência foi demonstrada; os motivos de rejeição e os concorrentes estão preservados caso a caso.

A conferência também examinou os espaços não mapeados dos174.467cartões: a posição32 só contém0(173.209cartões) ou branco(1.258);35–54 são brancas em todos. Não há um total pessoal oculto nessas posições. O guia127 não trazV100 nem ordinal pessoal; o guia25 os preserva. O IDarquivo compartilhado não distingue os registros de um mesmo conjunto.

São176conjuntos sem fonte25da própriaUF. Uma nova cópia dos mesmos bytes deHHOLDA não recupera ordens ou totais perdidos. Para esses casos falta a fonte estadual25, o boletim original ou listagem anterior à transformação que preserve essa informação. Nos demais, a necessidade concreta varia: correspondência integral com multiplicidades, resolução documental da geografia ou prova das divergências entre versões. Não há autorização nesta análise para excluir irmãos, copiar respostas divergentes ou transformar uma hipótese em homologação.

## Reprodução e verificação

Os scripts novos começam por `references/fechamento_integral_1960_duplicatas`. O principal oferece `prepare`, `pilot`, `search`, `evaluate`; os scripts `alternativas`, `unicidade` e `testemunhos` completam as provas. As saídas são exclusivas em `tmp/fechamento_integral_1960/duplicatas/`; uma repetição exige uma nova pasta, para preservar a execução original.

Na investigação inicial, passaram os31testes do auditor de pendências e os8da investigação residual. A conciliação nominal daquela etapa conferiu458grupos,918linhas,127exclusões,456igualdades brutas,uma igualdade após reparo e um conjunto corrompido. Os textos e hashes dasfontes foram conferidos. Essa etapa não executouR,targets,pesos,parquet de produção,manifestos ou mutaçõesGit. As contagens vigentes e a posterior integração coordenada estão explicitadas no topo e na nota da revisão final, sem reclassificar como resolvidas as457pendências restantes.
