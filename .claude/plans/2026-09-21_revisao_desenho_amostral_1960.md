# Plano: revisão do guia do desenho amostral de 1960 (amostra de 1,27%)

**Status:** CONCLUÍDO (21/09/2026)
**Data:** 2026-09-21
**Alvo principal:** `references/microdata_1960_amostra_127_desenho_amostral.md` (927 linhas)

## Contexto

O guia foi escrito em 15/09/2026, **antes** da compilação das duas amostras (16–17/09). Desde então o desenho que o `censobr` publica mudou, e o documento afirma o contrário de três coisas que hoje são verdade. Somam-se a isso seis defeitos de exposição e de evidência levantados numa auditoria de leitura em 21/09.

Os três substantivos:

1. **A segunda etapa existe.** A §11 diz "A pasta é a última unidade sorteada, e não há unidade secundária", e o item 6 da §13.10 repete. Na tabela publicada, `censobr_upa` é a pasta com `censobr_fpc` = 1/20 e `censobr_usa` é o domicílio com `censobr_fpc2` = 1/4 — duas etapas e duas correções de população finita, numa chamada só de `svydesign`.
2. **Famílias e domicílios nunca são distinguidos.** O boletim de 1960 é **por família**. Medido no estágio: 897.009 pessoas, **174.616 famílias**, **174.244 domicílios**, 345 domicílios com mais de uma família (`V101` = 4 ou 5). O documento diz "174.245 domicílios" e segue.
3. **As 814 pastas nunca viraram 814.** O estágio tem **817** unidades primárias e conta 817 em todas as tabelas. Duas delas são chaves danificadas com **um domicílio cada** — `71-70382` (espremida entre as pastas 70380 e 70424) e `54-541` (três dígitos onde a Guanabara usa cinco) — e entram no estimador como unidades primárias, inflando a soma de quadrados do seu estrato. A terceira "a mais" que o texto alega não se confirma: `3-03002` (Roraima, 6 domicílios) é legítima — as pastas de Roraima têm mediana de 17 boletins e ela está contígua no arquivo, boletins 079 a 084.

**Resultado pretendido:** o guia volta a descrever com exatidão o que o código faz, declara o que é inferência, e ganha uma seção de ligação com o desenho publicado — sem duplicar `microdata_1960_compilacao.md`.

## Decisões já tomadas (21/09)

| decisão | escolha |
|---|---|
| pseudo-pastas | **medir primeiro**, decidir com a medida; nenhuma mudança de código antes disso |
| escopo do documento | continua **documento do estágio**, com correções + seção de ligação ao publicado |
| fac-símiles | **recortar as páginas dos PDFs** para `references/figuras/` e embutir |
| bug do `sampling_errors_1960()` | **entra como item à parte**, na mesma rodada |

---

## Fase 0 — medir antes de escrever

Nenhuma linha do texto novo é escrita antes destes números. Script de trabalho em `references/figuras/desenho_amostral_1960.R` (seção nova no fim) ou em script temporário; os valores entram no texto e no plano.

**0.1 As duas chaves danificadas.** Para `71-70382` e `54-541`, medir: (a) quanto cada uma acrescenta ao erro-padrão do seu estrato, recalculando o estrato com e sem ela — o estrato `UF 54 - cidade grande` tem 40 pastas de ~226 boletins e uma de 1; (b) se a chave tem destino inequívoco. `70382` fica entre `70380` (boletins até 242) e `70424`, e o seu único boletim é o 088, que cabe em `70380` — a fusão é defensável. `54-541` é ambígua entre `54102` e `54142`; decidir pela posição no arquivo (`linha`), como o passo 4 já faz com as linhas realocadas.
   - **Se a fusão for inequívoca nas duas:** vira item da Fase 4 (muda `censobr_upa` no passo 8, invalida os alvos do estágio e da compilação, muda os erros-padrão dos dois documentos).
   - **Se for ambígua em alguma:** ela fica como está e o documento passa a declarar as 817 = 814 + 2 chaves danificadas + 1 pasta legítima que o texto contava errado, com o efeito conservador medido em 0.1(a).

**0.2 Famílias, domicílios e boletins.** Números já medidos e a conferir uma vez mais na escrita: 174.616 famílias, 174.244 domicílios, 345 com mais de uma família. Acrescentar a distribuição de `V101` (1, 2, 3, 4, 5) e a contagem de domicílios coletivos.

**0.3 O domicílio órfão.** `censobr_idhousehold` = 127134 (São Paulo, pasta 63936, `V101` = 1) existe na tabela de domicílios e não tem **nenhuma** pessoa; `censobr_n_listadas` e `censobr_n_presentes` em NA. Por isso a tabela tem 174.245 linhas e as pessoas apontam para 174.244. Verificar se é caso único e se o passo 7 deveria descartá-lo ou marcá-lo.

**0.4 Reconciliação 814 / 817.** Refazer a contagem com a correção de Rondônia já aplicada (64 famílias devolvidas de UF 03 para UF 00) e dizer, pasta a pasta, de onde vem cada unidade acima de 814.

---

## Fase 1 — correções factuais no texto

Edições cirúrgicas, uma por defeito. Nada de reescrita de seção que já está certa (`minimal-changes.md`).

**1.1 §11 e §13.10 item 6 — a segunda etapa.** O parágrafo "A pasta é a última unidade sorteada, e não há unidade secundária" está certo **como descrição do sorteio** e errado como descrição das colunas publicadas. Reescrever para: o sorteio tem a ordem invertida em relação ao livro-texto (domicílio primeiro, pasta depois); para a **variância** a pasta é a unidade primária; e a compilação escreve as duas etapas explicitamente, com `censobr_usa` e `censobr_fpc2`, para que uma chamada de `svydesign` descreva o país. O parêntese final da §11, que diz que "as colunas deste estágio substituem essa convenção", inverte-se: foi a convenção da compilação que prevaleceu.

**1.2 §4, §6.2, §11 — as 817 pastas.** Trocar "as 814 pastas estão todas lá; o arquivo tem 817 números de pasta distintos; os três a mais são…" pelo que a Fase 0.4 apurar. A tabela de distribuição por UF da §4 soma 817 e precisa de nota de rodapé dizendo o que isso inclui.

**1.3 §4, §10.3, §15 — Brasília.** Substituir as três afirmações de fato pelo que se sabe, nesta ordem: as duas pastas do DF têm 77 e 60 boletins contra 520 e 257 no cadastro (85% e 75% perdidos); a construção civil é o único ramo do quadro 3 que não fecha (−36% no Norte e Centro-Oeste contra −2,7% no Leste e no Sul); e a amostra de 25%, processada **depois** deste documento, mostra que 8.698 dos 14.818 boletins do DF são boletins individuais de morador de domicílio coletivo (`V101` = 9), isto é, os alojamentos (`references/microdata_1960_amostra_25_preparacao.md`, linha 109). Conclusão a escrever: o que falta é desproporcionalmente operário da construção; **não se sabe quais boletins a fita perdeu**.

**1.4 §5.2 — a unidade de medida.** Abrir a seção dizendo que ali a distância é medida em **números de pasta** (esperado: 40) e que na §7 ela passa a ser medida em **posições dentro da sublista do estrato** (esperado: 20). Dizer, antes da figura 2, que fora das cidades grandes essa medida **não consegue** ver o salto — as pastas dos outros três grupos estão intercaladas no cadastro — e que o grupo fica indecidido até a §7. Hoje o texto tem uma frase nesse sentido depois da figura, e a figura fala mais alto.

**1.5 §6.3 — "a situação não ordena o cadastro".** Acrescentar um exemplo trabalhado, no estilo do exemplo de brinquedo da §7.1: um município real, a fila das suas pastas com o grupo de cada uma, a sublista rural extraída e as sorteadas marcadas de vinte em vinte. É o mesmo conteúdo da figura nova (3.2).

**1.6 §12.4 — as linhas da figura 8.** Escrever o que elas são: três retas de inclinação 1 em eixos log-log, interceptos 0, log₁₀2 e log₁₀4, isto é, **deff = 1, 4 e 16** — referência, não tendência ajustada. E declarar que o eixo x é derivado do y (`cv_aas = cv_pct / sqrt(deff)`, `references/figuras/desenho_amostral_1960.R:236`), de modo que a figura mostra a distribuição do deff em outro sistema de coordenadas e não a comparação de duas medidas independentes.

**1.7 §14 "Como usar em R".** Reescrever para o parquet publicado (`data/microdata_sample/1960/1960_population_v1.0.0.parquet`), com o desenho de duas etapas, `check.strata = FALSE` (sem ele, `svydesign` aborta com `attempt to make a table with >= 2^31 elements`, porque a checagem de aninhamento monta uma tabela densa de 3.066.511 × 18.421) e o custo medido: 252 s para montar o desenho, 4,84 GB de objeto, 388 s por `svytotal`.

**1.8 §13.4 — diferenças sucessivas.** Acrescentar o que se mediu em 17–18/09: a receita do `svrep::as_sdr_design()` **não** devolve a fórmula de Wolter. O `svrep` implementa o SDR de Fay–Train, que fecha a lista somando `(t₁ − tₙ)²` e dispensa o fator `n/(n−1)`; na Guanabara isso é 15,3% da soma das diferenças e 6% a mais de erro-padrão (158.036 contra 149.043). A implementação em fórmula fechada das duas variantes está em `references/estimador_diferencas_sucessivas_1960.R`, que passa a ser citado aqui.

---

## Fase 2 — seções novas

**2.1 Nova seção na Parte I: "Boletim, família e domicílio".** Entre a §2 (vocabulário) e a §3. O que precisa ficar claro: o boletim é por família; `V101` diz o que a família é (1 ocupante único, 2 principal, 3 coletivo, 4 segunda, 5 terceira); 1, 2 e 3 abrem domicílio e 4 e 5 entram no da família anterior; a tabela de domicílios tem uma linha por domicílio com a página da família principal; a página de domicílio das famílias secundárias fica em branco por decisão (`ipea/censobr#87`); e o peso é **um por domicílio**, igual para todas as suas pessoas. Com os números da Fase 0.2 e 0.3.

**2.2 Nova seção final da Parte III: "O que deste desenho chega ao `censobr`".** Curta, com ponteiro para `microdata_1960_compilacao.md` em vez de repeti-lo. Precisa dizer: das 28 unidades deste estágio, **onze** vão para a tabela publicada (as outras dezessete vêm da amostra de 25%); os 75 estratos foram refeitos sobre essas onze e viraram **21 estratos em 146 pastas**; o desenho publicado é de duas etapas com duas fpc; os pesos foram recalibrados à Série Nacional nas duas metades; e a coluna `censobr_amostra` diz de onde vem cada registro.

**2.3 §10 — a calibração, célula a célula.** Expandir a tabela de quatro blocos da §10.3 para uma descrição que nomeie, para cada bloco: a variável do arquivo, as categorias, a tabela de origem, a **página** e o recorte de unidades. As páginas já estão na coluna `pagina` de `references/censo_1960_resultados_definitivos_serie_nacional.csv` — tab. 33 nas pp. 82–84, tab. 34 na p. 85, tab. 40 na p. 98 (tab. 32 na p. 80, tab. 37 na p. 90 e tab. 7 na p. 128 para as validações). A construção das células está em `celulas_definitivos_1960_amostra_127()` (`R/microdata_1960_amostra_127.R:851`) e a de 1965 em torno da linha 1016. A transcrição de 1965 (`censo_1960_resultados_preliminares_1965.csv`) **não** guarda página: anotar quadro por quadro ao recortar o fac-símile.

---

## Fase 3 — figuras

**3.1 Renumerar os dois pares fora de ordem.** No Markdown, `![Figura 4]` está na linha 270 e `![Figura 3]` na 274; `![Figura 6]` na 312 e `![Figura 5]` na 344. O conversor numera a legenda pela posição e imprime o texto alternativo junto, daí "Figura 3: Figura 4" e "Figura 4: Figura 3". Corrigir na fonte: trocar os nomes dos arquivos nas chamadas `salva()` de `references/figuras/desenho_amostral_1960.R` para que a ordem do documento seja a numeração (zonas de São Paulo → `fig03`, cadastro da Bahia → `fig04`, espaçamentos candidatos → `fig05`, progressão dos estratos → `fig06`), regerar e atualizar as quatro referências no Markdown.

**3.2 Figura nova: o sorteio dentro de um estrato que não é de cidade grande.** A figura do cadastro da Bahia mostra os quatro grupos intercalados, que é a vista em que o salto de 20 **não** aparece. A nova toma **uma** sublista — Bahia rural, 427 pastas, 21 sorteadas, cujos inícios já estão no texto da §7.3 — desenha só ela na ordem do cadastro e marca as sorteadas, ao lado da mesma sublista vista na numeração original das pastas. É a figura que liga a §5.2 à §7 e que o exemplo trabalhado da 1.5 acompanha. Entra como `fig03b` ou empurra a numeração — decidir ao renumerar (3.1).

**3.3 Figura 8 anotada.** Rotular as três retas como referência de deff e acrescentar ao subtítulo que o eixo x é derivado. Sem mudar os dados.

**3.4 Fac-símiles.** Extrair as páginas dos dois PDFs de `references/fontes_1960/` para `references/figuras/desenho_amostral_1960/`: tab. 33 (pp. 82–84), tab. 34 (p. 85) e tab. 40 (p. 98) de `1960_serie_nacional_vol1_brasil.pdf`; quadros 1 e 2 de `1965_resultados_preliminares_vol2.pdf` (páginas a anotar). Script de extração junto das figuras, para ser reprodutível. Embutir na §10.3 e na §10.4, ao lado da descrição das células.

**3.5 Regerar o PDF do documento.** O `.pdf` ao lado do `.md` é de 15/09 e já está uma revisão atrás. Confirmar com o usuário qual foi o comando (não há script de build no repositório).

---

## Fase 4 — item à parte: o erro-padrão subestimado da compilação

Independente do documento, feito na mesma rodada.

**O defeito.** `sampling_errors_1960()` (`R/microdata_1960.R:442`) acumula os agregados por estrato **dentro do laço por UF** e só depois empilha. Seis estratos da metade de 1,27% atravessam fronteira de UF, porque a regra de colapso os construiu assim — `UF 0+1 - urbana menor`, `UF 1+2 - mista`, `UF 2+4 - cidade grande`, `UF 4+6 - mista+urbana menor`, `UF 10+12 - cidade grande`, `UF 10+12 - urbana menor`. O laço os parte em doze pedaços (daí o CSV reportar 18.427 estratos contra os 18.421 da tabela) e **nove desses pedaços ficam com uma pasta só**, caindo no `fifelse(n_upa > 1, ..., 0)` e contribuindo zero. O colapso existia exatamente para dar duas pastas a esses estratos.

**A medida.** População presente: a fórmula fechada refeita sobre a tabela inteira dá **291.693** e o `survey` dá o mesmo no dígito; o publicado é **286.168**. Subestimação de 1,9%.

**O conserto.** Agregar `e` por `(dominio, censobr_estrato)` antes de calcular `v` — uma linha. `dd` (a parcela de dentro) não precisa: cada pasta está numa UF só.

**O rastro.** Reexecutar o alvo dos erros amostrais; atualizar `data_raw/microdata/1960/compilada/erros_amostrais.csv` e a tabela de erros-padrão do §6 de `references/microdata_1960_compilacao.md` (sete linhas: pessoas, presentes, urbana, rural, analfabetos, crianças, com rendimento — com CV, deff e n efetivo).

---

## Verificação

1. **Números do texto contra o código.** Todo número novo sai de script reproduzível (`references/figuras/desenho_amostral_1960.R` ou o de conferência), não de leitura de tela. Rodar o script inteiro e conferir que ele reproduz cada tabela alterada.
2. **Figuras.** Rodar `references/figuras/desenho_amostral_1960.R` do começo ao fim, conferir que os nove (ou dez) PNGs saem com os nomes novos e que o Markdown não tem referência quebrada: `grep -o 'figuras/[^)]*' no .md` contra `ls` do diretório.
3. **§14 na prática.** Executar o bloco de código da §14 tal como publicado, sobre `1960_population_v1.0.0.parquet`, e conferir que o total fecha em 70.191.146 e que o erro-padrão bate com o do `erros_amostrais.csv` já corrigido (Fase 4).
4. **Fase 4.** Depois do conserto, conferir que a fórmula fechada e o `survey` continuam batendo no dígito e que o novo `erros_amostrais.csv` traz 18.421 estratos, não 18.427.
5. **Fase 0.1.** Se a fusão for adotada, `tar_make()` dos alvos de 1960 e comparação dos erros-padrão antes/depois, estrato a estrato, para mostrar que só os dois estratos afetados mudam.
6. **Leitura.** Reler §5.2 → §6.3 → §7 em sequência procurando a contradição que motivou a revisão: um leitor que não conheça o desenho deve sair da §5.2 sabendo que o grupo não-cidade-grande está indecidido, e não que o salto não existe.

## Fora de escopo

- Reescrever `references/microdata_1960_compilacao.md` além da tabela do §6 (decisão de 21/09: o conserto do estimador entra, a revisão do documento não).
- Mexer nos pesos, nos estratos ou na calibração. A Fase 0.1 pode mudar `censobr_upa` em dois domicílios; nada mais.
- `references/estimador_diferencas_sucessivas_1960.R` fica onde está e passa a ser citado pela §13.4.


---

# Resultado da execução (21/09/2026)

## Fase 0 — o que a medição decidiu

**As duas fusões eram inequívocas**, cada uma por duas evidências independentes, e foram aplicadas.

- `71-70382` → `71-70380`: a 70382 existe no cadastro (230 boletins), mas ela e a 70380 são as duas urbanas de Ponta Grossa, **adjacentes no cadastro e no mesmo estrato** — uma em vinte não tira as duas; a cobertura é de 0,4% contra 74% da 70380 e 98,7% de mediana no Paraná; o boletim 088 que ela traz é o que falta na 70380; e está encostada nos registros dela no arquivo.
- `54-541` → `54-54142`: o cartão (linha 611254) é `54 | 5___ | 18 | 541__ | 101` — a pasta perdeu dois dígitos para brancos e sobreviveram o prefixo `541` e o distrito 18, que entre as três pastas `541xx` da Guanabara só a 54142 tem.

**Terceira "pasta a mais" não se confirma:** `3-03002` (Roraima, 6 domicílios) é legítima. Sobram **815** unidades primárias contra as 814 declaradas, e a diferença não se explica por dano; a conjectura registrada é Fernando de Noronha, onde não houve sorteio.

**Achado não previsto:** a pasta **31144, de Salvador**, é legítima (está na grade perfeita de 40 em 40 da Bahia) e guarda 18 dos seus 247 boletins — os de número 230 a 247, a cauda exata. Um bloco contíguo perdido pela cabeça. Derruba a afirmação do §4 de que Brasília era a única perda parcial comprovada.

**Mecanismo escolhido pelo usuário:** corrigir só `censobr_upa`, marcando em `censobr_diagnostico`; `pasta`, `V116` e `v001` ficam como o cartão gravou. Sem coluna nova, sem regenerar `schemas/censobr_types.csv`.

## O efeito, medido

| | antes | depois |
|---|---|---|
| unidades primárias no estágio | 817 | **815** |
| unidades primárias na compilação | 3.066.511 | **3.066.510** |
| pastas das onze UFs | 146 | **145** |
| EP do estrato `UF 71 - urbana menor` | 100.398 | **50.643** (−49,6%) |
| EP do estrato `UF 54 - cidade grande` | 174.107 | **154.770** (−11,1%) |
| EP da população presente do **país** | 286.168 (publicado) | **280.574** |

Os dois consertos andam em sentidos opostos: o do `sampling_errors_1960()` sozinho levava o EP nacional de 286.168 para 291.693 (+1,9%), e o das chaves danificadas o trouxe a 280.574 (−3,8%).

## Arquivos alterados

- `R/microdata_1960_amostra_127.R` — passo 8: as duas chaves devolvidas à pasta certa, marcadas em `censobr_diagnostico`.
- `R/microdata_1960.R` — `sampling_errors_1960()`: agregação por `(dominio, censobr_estrato)` antes da variância; e a compilação passa a tomar a pasta do desenho em vez de `v001`.
- `references/microdata_1960_amostra_127_desenho_amostral.md` — nova seção 2.1; §§4, 5.1, 5.2, 6.2, 6.3, 7.2, 7.3, 8, 9, 10.3, 10.4, 11, 12.4, 13, 13.4, 13.6, 13.10 corrigidos; nova 13.11; §14 reescrita em três partes; legendas de figura de verdade; cinco fac-símiles embutidos.
- `references/figuras/desenho_amostral_1960.R` — figuras renumeradas na ordem do documento, figura 5 nova (Bahia rural nas duas réguas), figura do deff anotada.
- `references/figuras/facsimiles_1960.py` — novo; extrai as páginas das publicações (o deslocamento da Série Nacional é +40, não −1).
- `references/microdata_1960_compilacao.md` — tabela de erros amostrais do §6 e a nota que explica as duas correções.
- `CLAUDE.md` — contagens de unidades primárias.

## O que ficou de fora

- A tabela do §13.2 (peso de $V_{dom}$ por total-exemplo) não foi re-medida: são quantidades de segunda ordem (0,05% a 0,6% do erro-padrão) cuja conclusão não muda, e o script que as produziu era avulso.
- O PDF foi regerado com `pandoc --pdf-engine=xelatex --toc --number-sections`; não havia script de build no repositório e este comando passa a ser o de referência.
