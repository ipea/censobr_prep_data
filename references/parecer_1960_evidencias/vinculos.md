> Caderno de evidência da [versão narrativa do parecer](../microdata_1960_amostra_127_revisao_integrativa.md), de 22/09/2026. Caminhos citados sem link partem da raiz do projeto; números de linha identificam as fontes, não pessoas pelo nome. As propostas não foram aplicadas.

# Três casos reais: quando a regra muda a família ou elimina uma pessoa

Nota de apoio à reescrita do parecer, 22/09/2026. Somente leitura dos dados; nenhuma correção abaixo foi aplicada. Os números de família e domicílio descrevem os parquets existentes e podem mudar numa reconstrução. As linhas do `HHOLDA.txt` e dos arquivos descomprimidos de 25% são os localizadores primários.

## Como ler os exemplos

O arquivo de 1,27% tem linhas diferentes para o **cartão de família**, que contém também os dados do domicílio, e para cada pessoa. Para reuni-las, o programa procura a mesma UF, distrito, pasta e número de boletim. Um dígito divergente no distrito pode, portanto, separar pessoas do cartão que lhes corresponde. O número depois da barra invertida no fim da linha é `id_arquivo`: não é um identificador civil de pessoa nem, por si só, prova de parentesco.

Nos exemplos, “filho” ou “filha” abrevia o código **filho ou enteado** (`V203=9`); a fonte não permite separar essas duas condições. Sexo e condição de presença vêm de `V202`; todos os integrantes exibidos nas três famílias são moradores presentes. `V204=1` indica idade em anos; `V204=9` indica **idade ignorada**. Nesse último caso, o `99` gravado em `AGE` — chamado `V204B` no parquet — não significa 99 anos.

A fonte de 25% foi relida diretamente dos arquivos `.gz`, sem passar pelo leitor R nem reconstruir os vínculos de 1,27%. A comparação pessoal aqui mencionada usa 25 campos comuns, listados no fim desta nota. Trata-se de concordância de conteúdo e quantidade de registros, não de identificação nominal. As duas cópias têm origem histórica compartilhada: não são testemunhos estatisticamente independentes.

## Caso 1 — BA 31606/031: a menina de cinco anos enviada a outro município

### O que havia no original

Na linha **302261** do `HHOLDA.txt` há uma pessoa do sexo feminino, registrada como filha/enteada, com **cinco anos**. Sua própria linha informa município **3138, Ipiaú**, pasta **31606**, boletim **031** e distrito **01**. O cartão correspondente à pasta e ao boletim existe mais adiante, na linha **302453**, também em Ipiaú, mas com distrito **07**.

| Peça do arquivo de 1,27% | Linha HHOLDA | Município | Distrito | Pasta / boletim | `id_arquivo` |
|---|---:|---|---|---|---|
| Cartão anterior à menina | 302253 | 3136 — Ibicaraí | 01 | 31516 / 238 | 0048054 |
| Menina, filha/enteada, 5 anos | 302261 | 3138 — Ipiaú | 01 | 31606 / 031 | 0048054 |
| Cartão que tem a mesma pasta e boletim da menina | 302453 | 3138 — Ipiaú | 07 | 31606 / 031 | 0048082 |

Trechos integrais do bruto, sem inserir separadores dentro das linhas:

```text
HHOLDA 302253  3131360131516238151598389680204003                    \0048054
HHOLDA 302261  31313801316060313129105570592000311-                  \0048054
HHOLDA 302453  3131380731606031111578289680207003                    \0048082
```

### Como a regra antiga decidiu — e o resultado que ainda está salvo

O distrito diferente impediu a ligação direta. Como o grupo pendente não tinha chefe nem cônjuge, a regra antiga escolheu **o último cartão de família situado antes da pessoa no arquivo**. Esse procedimento é observável no código antigo; não precisamos supor uma intenção histórica de seu autor. A interpretação operacional era que a proximidade na sequência bastaria para completar o vínculo.

Neste caso, a proximidade apontou para o cartão de **outro município e outra pasta**. No parquet existente, a menina recebeu a família **47221**, domicílio **47171**, origem `anexada_anterior`, município derivado **3136** e UPA **31-31516**. Sua pasta original continua sendo 31606 e seu `V116` original continua sendo 3138: a linha conserva a pista que contradiz o vínculo derivado.

### O que a cópia de 25% permite conferir

No gzip da BA, o cartão está na linha **399494** e declara **sete pessoas** (`v100=7`), município 3138 e distrito 07. A menina aparece na linha **399500**, ordem **06** do boletim, com correspondência nos **25 campos pessoais**. A família legível é esta:

| Sexo | Relação com o chefe | Idade | Linha HHOLDA | Linha gzip BA / ordem |
|---|---|---:|---:|---|
| Feminino | Chefe | 45 anos | 302454 | 399495 / 01 |
| Masculino | Filho/enteado | 21 anos | 302456 | 399496 / 02 |
| Feminino | Filha/enteada | 19 anos | 302459 | 399497 / 03 |
| Feminino | Filha/enteada | 17 anos | 302458 | 399498 / 04 |
| Feminino | Filha/enteada | 16 anos | 302457 | 399499 / 05 |
| Feminino | Filha/enteada | 5 anos | **302261** | **399500 / 06** |
| Masculino | Outros parentes | 52 anos | 302455 | 399501 / 07 |

O quadro mostra sexo, parentesco e idade das duas fontes; a conferência de todos os 25 campos foi feita especificamente para a menina. Não é necessário inventar uma mãe, um pai ou um nome para concluir que o vínculo atual está errado.

```text
gzip BA 399494  316060310040714782896802070033138071000000000000000000
gzip BA 399500  31606031065065291055705992000311                   000
```

### Correção proposta e limite da prova

A proposta é registrar uma reconciliação de chave para essa ocorrência, preservar o distrito bruto 01 e ligar a menina ao **cartão já existente 302453**, de distrito 07. Não é adicionar uma pessoa nem fabricar um novo domicílio: é mudar o pertencimento de uma pessoa já presente.

| Medida | Estado salvo | Após somente essa realocação, se aprovada |
|---|---|---|
| Família / domicílio da menina | 47221 / 47171 | Cartão 302453; atualmente 47249 / 47199 |
| Município derivado / UPA | Ibicaraí / 31-31516 | Ipiaú / 31-31606 |
| Pessoas listadas no domicílio de origem do vínculo errado | 9 | 8 |
| Pessoas listadas no domicílio 31606/031 | 6 | 7 |
| Pessoas no conjunto de dados | Sem mudança | Sem mudança |

Por que **9 → 8**, e não 9 → 7? O mesmo domicílio errado também recebeu um menino de cinco anos da linha **302262**, cuja pasta/boletim é **31606/072**. Corrigir a menina não corrige automaticamente o menino. Esse segundo vínculo precisa de decisão própria.

Há ainda uma divergência domiciliar que a narrativa não deve esconder: no cartão 302453, **V102=5, domicílio rústico**; no cartão 399494 da fonte de 25%, **V102=4, durável**. Dos 15 campos familiares comuns comparados, esse foi o divergente. A prova do vínculo da menina **não autoriza sobrescrever o tipo do domicílio**. Falta decidir como registrar essa divergência de conteúdo, separadamente da reconciliação do vínculo.

## Caso 2 — BA 31962/118: seis pessoas viraram uma família nova, embora o cartão existisse

### A separação já está visível no arquivo original

Em **Conceição do Coité, município 3175**, seis pessoas aparecem nas linhas **315134–315139**, pasta **31962**, boletim **118**, distrito **03**. O grupo contém uma mulher registrada como **cônjuge, 37 anos**, e cinco filhos/enteados. Mais adiante está o cartão da mesma pasta e boletim, linha **315732**, distrito **05**, seguido de um chefe homem de **44 anos**, linha **315733**.

| Sexo | Relação com o chefe | Idade | Linha HHOLDA / distrito | Linha gzip BA / ordem |
|---|---|---:|---|---|
| Masculino | Chefe | 44 anos | 315733 / 05 | 645853 / 01 |
| Feminino | Cônjuge | 37 anos | **315134 / 03** | 645854 / 02 |
| Masculino | Filho/enteado | 14 anos | **315136 / 03** | 645855 / 03 |
| Feminino | Filha/enteada | 12 anos | **315137 / 03** | 645856 / 04 |
| Masculino | Filho/enteado | 10 anos | **315139 / 03** | 645857 / 05 |
| Masculino | Filho/enteado | 8 anos | **315135 / 03** | 645858 / 06 |
| Masculino | Filho/enteado | 4 anos | **315138 / 03** | 645859 / 07 |

Trecho suficiente para ver a divergência de distrito e os dois tipos de registro:

```text
HHOLDA 315134  3131750331962118312813754059200031100845050534-       \0050196
HHOLDA 315139  3131750331962118311911054059200020000000000035-       \0050196
HHOLDA 315732  3131750531962118111478389680205002                    \0050305
HHOLDA 315733  313175053196211821171445405920001110084505056371224227\0050305
```

### O raciocínio da regra antiga e o que foi produzido

A ligação direta exigia distrito igual e falhou para os seis registros. A regra seguinte perguntava se o grupo sem cartão tinha **chefe ou cônjuge**. Como havia cônjuge, classificou o cartão como perdido e criou uma família nova. “O cartão se perdeu” era, portanto, uma **inferência da regra**, não um fato verificado contra todos os cartões candidatos. Neste exemplo o cartão existe, apenas com outro distrito.

O resultado salvo é a família **174495**, domicílio **49314**, com seis pessoas e marca `registro_perdido`. Não há cartão original de família na linha 315134: ali está a mulher de 37 anos. O programa usa essa linha como referência da família fabricada. Os dados domiciliares **V101–V113 ficam vazios**. Já o cartão real 315732 é a família **49472**, domicílio **49430**, com sua página domiciliar preservada.

### A confirmação de 25% — e a armadilha de somar seis ao domicílio atual

O gzip da BA contém o cartão na linha **645852**, com distrito **05** e **sete pessoas** (`v100=7`). Ele coincide nos **15 campos familiares comuns** com o cartão HHOLDA 315732. Os sete registros pessoais da tabela acima coincidem, cada um, nos **25 campos comuns**. A evidência sustenta reunir cônjuge e filhos/enteados ao chefe que já está na cópia de 1,27%.

```text
gzip BA 645852  319621180000714783896802050023175051000000000000000000
gzip BA 645853  319621180100101714454059920001110084505056371224227000
gzip BA 645854  3196211802802828137540599200031100845050534        000
```

Mas o domicílio atual 49430 **não contém somente esse chefe**. Ele contém também a linha **315736**, sexo feminino, **filha/enteada de 13 anos**, origem `anexada_anterior`. Sua própria chave diz **31962/124**, não 31962/118. Simplesmente mover os seis produziria oito pessoas, em vez das sete da fonte de 25%.

| Grupo | Estado salvo | Se apenas os seis forem reunidos | Situação sustentada para o boletim 118 |
|---|---:|---:|---|
| Família artificial 174495 / domicílio 49314 | 6 pessoas | 0 | Deixa de ser necessária se a reconciliação for aprovada |
| Cartão real 315732 / domicílio 49430 | 2 pessoas: chefe da 118 + filha da 124 | **8 pessoas** | 7 pessoas da 118; a pessoa da 124 exige outro vínculo |

A filha de 13 anos não é uma sobra a apagar. Sua linha **315736** corresponde exatamente nos 25 campos à **ordem 06 do boletim 124**, linha **645897** do gzip. O cartão desse outro boletim existe em **HHOLDA 315168**, distrito 03; no gzip está na linha **645891**, distrito 05, com `v100=13`. Os 15 campos familiares comuns dos dois cartões concordam. Assim, existe um destino candidato bem corroborado também para ela, mas esta nota **não auditou toda a composição e multiplicidade atual do domicílio 124** nem resolveu os demais conflitos que ele possa conter.

```text
HHOLDA 315168  3131750331962124111478389680208003                    \0050202
HHOLDA 315736  3131750531962124312911354059200005200000000035-       \0050305
gzip BA 645891  319621240001314783896802080033175051000000000000000000
gzip BA 645897  3196212406006029113540599200005200000000035        000
```

### O que falta decidir

A proposta é reconciliar os seis registros com o cartão 315732, preservando as chaves brutas, e retirar a família artificial **somente depois de comprovar que ficou vazia**. A pessoa 315736 deve ser preservada e ter o vínculo da 124 examinado junto com esse ajuste. A decisão é sobre dois destinos relacionados, não uma fusão cega de dois domicílios. Ao final, é necessário recontar pessoas, famílias e domicílios, conferir que nenhuma linha se perdeu ou ganhou cópia e recalcular os atributos derivados. Os IDs apresentados acima servem para localizar o estado atual, não como novos IDs prometidos.

## Caso 3 — PB 19124/166: duas pessoas excluídas porque seus registros eram indistinguíveis

### O que realmente sabemos sobre essas pessoas

Em **Mamanguape, município 1925**, distrito **07**, pasta **19124**, boletim **166**, o cartão de família está em **HHOLDA 168800**. Em seguida há **sete registros pessoais**, linhas 168801–168807. Todos, inclusive chefe e cônjuge, têm **idade ignorada** (`V204=9`, `AGE=99`). Não podemos chamá-los todos de crianças, afirmar que dois são gêmeos ou inferir idades iguais.

Existem dois pares indistinguíveis dentro dos campos registrados: duas filhas/enteadas, e dois filhos/enteados. Um terceiro filho/enteado tem outros campos diferentes. A existência de fichas indistinguíveis não basta para decidir se são duas pessoas ou uma cópia indevida.

| Linha HHOLDA | Sexo / relação com o chefe | Idade | Resultado salvo | Localização na fonte de 25% |
|---:|---|---|---|---|
| 168801 | Masculino / chefe | Ignorada | Mantido | 84594, ordem 01 |
| 168802 | Feminino / filha ou enteada, perfil A | Ignorada | Mantida | Par A: 84598 e 84599, ordens 05 e 06 |
| 168803 | Masculino / filho ou enteado, perfil C | Ignorada | Mantido | 84600, ordem 07 |
| 168804 | Masculino / filho ou enteado, perfil B | Ignorada | Mantido | Par B: 84596 e 84597, ordens 03 e 04 |
| **168805** | **Feminino / filha ou enteada, perfil A** | **Ignorada** | **Excluída** | Mesmo par A; não há correspondência individual distinguível |
| **168806** | **Masculino / filho ou enteado, perfil B** | **Ignorada** | **Excluído** | Mesmo par B; não há correspondência individual distinguível |
| 168807 | Feminino / cônjuge | Ignorada | Mantida | 84595, ordem 02 |

“Perfil A/B/C” são apenas rótulos desta explicação, não variáveis adicionadas aos dados. Dentro de cada par, não podemos dizer qual pessoa é qual entre as duas fontes: podemos comparar a **quantidade de ocorrências**.

### Por que a regra antiga apagou duas linhas

O programa marcava linhas repetidas dentro do mesmo `id_arquivo`. Aqui encontrou duas ocorrências repetidas: 168805 repete 168802, e 168806 repete 168804. Uma das condições de exclusão era haver **duas ou mais repetidas na família** (`n_repetidas >= 2`). Isso bastava para chamar o conjunto de `bloco_copiado`.

Essa condição não exigia que a família fosse de Pernambuco nem que as repetições estivessem na cauda do grupo. Neste caso, **não estão na cauda**: ainda vem a cônjuge, na linha 168807. O próprio arquivo de exclusões registra `na_cauda=FALSE`. Mesmo assim, a condição “duas repetidas” acionou a remoção.

```text
HHOLDA 168802  1919250719124166352999957189200031100000000034-       \0025763
HHOLDA 168805  1919250719124166352999957189200031100000000034-       \0025763
HHOLDA 168804  191925071912416635199995718920003110000000003332321200\0025763
HHOLDA 168806  191925071912416635199995718920003110000000003332321200\0025763
```

O arquivo `duplicatas_removidas.csv`, linhas físicas **7 e 8**, registra as duas exclusões:

```text
linha,id_arquivo,UF,V116,tipo,V203,AGE,V202,na_cauda,n_repetidas,motivo
168805,0025763,19,1925,3,9,99,2,FALSE,2,bloco_copiado
168806,0025763,19,1925,3,9,99,1,FALSE,2,bloco_copiado
```

O parquet existente ficou com **cinco pessoas**, família **25763**, domicílio **25721**, apesar de o HHOLDA listar sete.

### O que a fonte de 25% acrescenta à decisão

O cartão do gzip da PB, linha **84593**, declara **sete pessoas**. As linhas 84594–84600 contêm sete ordens distintas, 01–07, incluindo **duas ocorrências do perfil A e duas do perfil B**. Os primeiros 14 caracteres, que incluem número de ordem e seus controles, distinguem os registros na fonte de 25%; os campos pessoais de cada par continuam iguais.

```text
gzip PB 84593  191241660050714783896802030011925075000000000000000000
gzip PB 84596  191241660390391999957189920003110000000003332321200000
gzip PB 84597  191241660420421999957189920003110000000003332321200000
gzip PB 84598  1912416605805829999571899200031100000000034        000
gzip PB 84599  1912416606906929999571899200031100000000034        000
```

| Conteúdo | Quantidade no HHOLDA original | Quantidade no parquet atual | Quantidade no gzip de 25% | Proposta |
|---|---:|---:|---:|---:|
| Filhas/enteadas, perfil A | 2 | 1 | 2 | Preservar 2 |
| Filhos/enteados, perfil B | 2 | 1 | 2 | Preservar 2 |
| Demais integrantes | 3 | 3 | 3 | Preservar 3 |
| **Total** | **7** | **5** | **7** | **Voltar a 7** |

A correção proposta é restaurar as ocorrências das linhas **168805 e 168806**, ou expressar a mesma decisão como preservação da multiplicidade dois em cada perfil. Isso não exige inventar idades, nomes ou uma distinção individual que a fonte não fornece. A concordância entre contagem declarada, sete ordens e quantidade de perfis nas duas cópias dá suporte à restauração; não transforma a fonte de 25% em prova de identidade civil nem resolve outros boletins por analogia.

Falta aprovar a regra e o registro de exceções que preservarão essa multiplicidade na reconstrução, testar este boletim como caso obrigatório e verificar a contagem final. **Nada foi restaurado durante esta revisão.**

## Alcance: o que os três casos provam — e o que não provam

Os três defeitos estão nos **intermediários da amostra de 1,27% já gravados**. Não devem ser apresentados como três erros automaticamente transmitidos ao produto compilado: BA e PB estão entre as UFs para as quais `compile_1960()` lê a amostra de **25%**. O roteamento está em `R/microdata_1960.R`, linhas 193–201, e a lista de UFs em `R/microdata_1960_amostra_25.R`, linha 71. Nesta nota não foi refeita uma comparação integral com o parquet final; o alcance direto demonstrado é o dos intermediários e das fontes brutas identificadas.

O código de trabalho já tem bloqueios preventivos antes da exclusão de duplicatas e antes da anexação de pessoas ao cartão anterior. **Bloquear não é corrigir os arquivos salvos**. Além disso, a criação de famílias `registro_perdido` continua no corpo da função; não se deve dizer que a guarda, por si só, resolveu o caso BA31962/118. Não houve execução de R/Rscript/targets, nem alteração de código, guias, dados ou relatório principal nesta tarefa.

## Roteiro de auditoria e referências exatas

### Arquivos e localizadores

- Bruto de 1,27%: `data_raw/microdata/1960/amostra_127/HHOLDA.txt`. Todas as linhas HHOLDA desta nota são físicas, começando em 1.
- Brutos de 25%: `data/release_legacy/Censo.1960.amostra.25porcento.ba.gz` e `...pb.gz`. As linhas citadas são contadas **depois da descompressão**, começando em 1; não são deslocamentos no arquivo comprimido.
- Estado atual de pessoas: `data_raw/microdata/1960/amostra_127/pessoas_1960_amostra_127.parquet`; filtrar por `linha` ou pelos `censobr_idhousehold` indicados. Não confiar em posição física de linha no parquet.
- Estado atual dos domicílios: `data_raw/microdata/1960/amostra_127/domicilios_1960_amostra_127.parquet`; domicílios 47171, 47199, 49314, 49430 e 25721.
- Exclusões PB: `data_raw/microdata/1960/amostra_127/duplicatas_removidas.csv`, linhas 7–8.
- Decodificação: `read_guides/1960_amostra_127_codigos.csv`, linhas 7–8 (V102), 49–57 (sexo/presença e parentesco), 60 (outros parentes), 63–66 (unidade de idade/ignorada). Município: `read_guides/1960_municipios.csv`, linhas 516 (Mamanguape), 847 (Ibicaraí), 849 (Ipiaú), 878 (Conceição do Coité).

### Regras citadas

- **Código antigo:** `git show ad8e365a54e610bbaf6be35943d7205f0cf3b83c:R/microdata_1960_amostra_127.R`. Linhas 475–482: repetidas e condição de remoção. Linhas 572–588: grupos com chefe/cônjuge viram famílias novas. Linhas **591–594**: escolha do cartão anterior usando `findInterval()`, seguida da marca `anexada_anterior`.
- **Código de trabalho consultado em 22/09/2026:** `R/microdata_1960_amostra_127.R`. Linha **479**: condição antiga que ainda identifica candidatos; **489**: parada antes de remover. Linha **568**: vínculo por UF e chave; **574**: presença de chefe/cônjuge; **579–589**: criação de famílias; **597**: parada antes de anexar pendentes. As numerações do código antigo e do atual diferem.
- Auditor de conteúdo já existente: `references/auditoria_vinculos_duplicatas_1960.py`, linhas 96–103, define a assinatura pessoal. Saídas de rodadas anteriores: `tmp/doublecheck127/auditoria_original_reexec.json` (buscar `linha` 302261 e 315736 em `vinculos`); `tmp/doublecheck127/integridade_results.json` (chave `[31,31962,118]` em `lost_groups`; casos PB19124/166 e BA31962/118 em `raw25_cases`). A releitura direta adicional da BA nesta tarefa confirmou 31606/031 e 31962/124, além de repetir 31962/118.

### Campos e limites da comparação

Os 25 campos pessoais comuns são: `V202, V203, V204, AGE, V205, V206, V207, V208, V209, V299, V210, V211, V212, V213, V214, V215, V216, V217, V218, V219, V220, V221, V223, V223B, V224`. A concordância é de valores lidos nos seus intervalos de caracteres; espaços e o marcador de fim de preenchimento não são tratados como uma pessoa adicional ou como identidade.

Essa assinatura **não inclui** distrito, município, ordem da pessoa, dígitos de controle, `id_arquivo`, identificadores gerados, pesos ou página domiciliar. Nos casos da BA, distrito e município foram confrontados separadamente e as divergências estão explícitas acima. Os 15 campos familiares comparados são `V116`, `V118` e `V101–V113`; distrito é um confronto adicional (`distrito` no HHOLDA, `V117` em 25%). A quantidade declarada `v100` só existe na fonte de 25% e foi comparada à contagem de linhas, não presumida a partir dela.

Para reproduzir seletivamente, abrir os `.gz` em leitura de texto Latin-1, enumerar linhas a partir de 1 e selecionar `int(texto[0:5])` e `int(texto[5:8])` como pasta/boletim. Neste conjunto, `texto[8:10] == "00"` identifica o cartão familiar. No HHOLDA, a pessoa usa UF em 1–2, município em 3–6, distrito em 7–8, pasta em 9–13, boletim em 14–16, tipo em 17, sexo/presença em 19, parentesco em 20, unidade de idade em 21 e idade em 22–23 (posições começando em 1). Aplicar os guias existentes para os demais campos. As constatações desta nota não dependem de executar o pipeline nem de aceitar a inferência de vínculo que está sendo contestada.
