# Revisão do desenho reconstruído da amostra de 1,27% de 1960

> **Atualização delimitada de 23/09/2026 — cinco pastas:** o [confronto nominal dos brutos e estratos exportados](fechamento_integral_1960_duplicatas_pastas_resultado.md) demonstrou que comparar CE15004→15004 apenas pelo número é inadequado:145 famílias com corpo/geografia e composição24 concordantes apontam para CE14990, rural. A UPA127 permanece15004. Nas outras quatro pastas, oito cartões determinam a divergência e27 pessoas já pertencem ao inventário de192 conflitos geográficos. Identidade familiar não decide V118 entre valores legíveis concorrentes. Nenhum estrato, UPA, peso, fração ou regra de sorteio foi alterado; as guardas atuais bloqueiam esses conflitos antes de nova exportação. O diagnóstico desta nota abaixo é histórico; ranks/corridas não foram refeitos por esta investigação. [Evidências e fontes](fechamento_integral_1960_evidencias/pastas_desenho.json).

> **Síntese vigente:** a [revisão integrativa](microdata_1960_amostra_127_revisao_integrativa.md) concilia esta nota com a rechecagem de ranks/corridas e os achados nas duas calibrações. Prevalece em caso de conflito. Reconstrução não equivale a identificação histórica completa; variâncias após calibração continuam adiadas.

Data: 2026-09-21. Documentos relacionados: [desenho amostral](microdata_1960_amostra_127_desenho_amostral.md), [preparação](microdata_1960_amostra_127_preparacao.md) e [consistência](microdata_1960_amostra_127_consistencia.md).

O uso da pasta como conglomerado tem respaldo histórico direto. A representação por **UF × quatro grupos de situação**, seguida de colapso para análise, é uma reconstrução plausível com evidência favorável, mas ainda não é uma identificação completa do desenho original. A distinção importa: reproduzir margens e obter a mesma fórmula no `survey` não verifica as probabilidades de seleção, os limites dos estratos ou a integridade do cadastro.

Esta nota não altera a matemática do desenho, não executa R/Rscript nem recalcula estimativas ou pesos. Combina leitura estática com uma auditoria independente de classificação em Python, somente leitura, descrita na seção 3. Na revisão paralela de integridade, foram acrescentadas validações e guardas preventivas ao pipeline; essas mudanças são descritas nos documentos de preparação e consistência. Os números de espaçamento e de variância citados aqui são resultados anteriores, sujeitos às limitações identificadas. Por decisão do usuário, **a análise e a implementação das variâncias calibradas ficam para uma etapa posterior**. Os resultados definitivos das dezessete UFs, embora estimados com a amostra de 25%, continuam sendo os referenciais disponíveis adotados pelo projeto.

## 1. O que a evidência permite afirmar

| Elemento | Classificação da evidência | Consequência para o projeto |
|---|---|---|
| Coleta sistemática de aproximadamente 1/4, por domicílio particular e por pessoa em coletivos | Documentado pelo Volume II de 1965, seção de planejamento, transcrita no documento de desenho | A unidade elementar não é indistintamente o domicílio físico para todos os registros |
| Formação de pastas com boletins já selecionados, preservando a ordem dos setores | Documentado | A pasta é um conglomerado da subamostra, formado depois da primeira seleção |
| Seleção sistemática de aproximadamente uma pasta em vinte, com início aleatório, por critérios geográfico e de situação | Documentado | A pasta deve ser preservada na análise; o texto não nomeia o nível geográfico exato |
| Quatro grupos: cidade grande, urbana menor, rural e mista | Documentado | A comparação identificou sete divergências entre fontes; duas decorrem de recodificação duplicada na investigação e cinco de composição observada |
| UF como limite das séries | Hipótese operacional favorecida pelos espaçamentos | Manter sua identificação como reconstrução, sem alegar prova de reinícios independentes |
| População urbana municipal ≥ 100 mil como aproximação de cidade grande | Melhor regra entre as alternativas testadas no cadastro legado | Não equivale a recuperar a lista histórica de cidades nem a validar automaticamente a regra do pipeline |
| Cadastro reconstruído a partir do `release_legacy` de 25% | Fonte empírica intermediária, não cadastro histórico preservado | Confrontar sua cobertura e classificação com os arquivos brutos de 25% |
| Pasta de Fernando de Noronha selecionada com certeza | Hipótese operacional apoiada no cadastro observado e na escala dos totais | `fpc=1` e peso-base 4 ficam identificados como decisões condicionadas a essa hipótese |
| Colapso de estratos solitários com UFs vizinhas | Escolha analítica do projeto | Não apresentar os estratos colapsados como estratos originais do sorteio |
| Frações exatas e probabilidades conjuntas | Não recuperadas | Não atribuir exatidão histórica ao peso-base ou à variância aproximada |

A fonte histórica central é o IBGE, *Resultados Preliminares do Censo Demográfico*, Série Especial, volume II, 1965, item `liv84480`. A procedência das cópias e das demais fontes está no [índice de fontes primárias](fontes_1960/README.md); os trechos do planejamento estão transcritos na seção 3 do [documento de desenho](microdata_1960_amostra_127_desenho_amostral.md). Esta nota não acrescenta uma nova conferência visual dos fac-símiles.

## 2. UF × situação: evidência favorável e limites

O script `references/figuras/desenho_amostral_1960.R`, na função `espac()`, constrói uma lista ordenada para cada candidata e mede a distância em posições entre pastas consecutivas identificadas como selecionadas. Os resultados registrados favorecem UF × quatro grupos: 77,3% dos 612 pares com intervalo 20 e 90,4% com intervalo entre 19 e 21. Região × grupos tem 72,6% de intervalos exatos em 654 pares.

Essa comparação é útil, mas não é prova de que cada UF teve início aleatório independente. Os denominadores diferem porque uma candidata acrescenta pares entre fronteiras. Além disso, uma série contínua atravessando blocos contíguos de UFs também pode produzir razões cadastro/selecionadas próximas de 20 dentro de cada UF. A razão agregada não identifica por si só onde o início foi reiniciado.

A evidência mais informativa sobre as zonas é a continuidade entre elas: o documento registra 431 pares que atravessam zonas, dos quais 73,3% têm intervalo 20. O bloco correspondente do script ordena por `h, r`, preservando UF × grupo. Isso favorece uma série que atravessa zonas em vez de inícios independentes em todas as zonas. O valor de aproximadamente 5% citado como referência de acaso é uma heurística para modelos simples de inícios uniformes; não é um valor-p calculado para este cadastro com perdas e classificações incertas.

As exceções precisam permanecer visíveis. Há grupos com fraco ajuste e primeiras posições observadas superiores a 20, inclusive 24 no exemplo de Pernambuco e 38 no de Porto Alegre. Sob o modelo linear simples com intervalo 20, essas posições não podem ser o primeiro início sem alguma explicação adicional: alteração do cadastro, classificação divergente, pasta perdida ou outra regra de seleção. Não basta chamar todas as primeiras posições observadas de inícios aleatórios.

O teste por espaçamentos não cobre as onze UFs sem arquivo de 25%. Aplicar a elas a mesma estrutura é uma extrapolação operacional. A presença das quatro categorias na publicação e os padrões da subamostra ajudam a motivá-la, mas não fornecem validação do cadastro que falta.

## 3. A classificação foi confrontada entre regras e fontes

Há uma diferença concreta entre duas rotas:

| Etapa | Regra de município e cidade grande | Código inspecionado |
|---|---|---|
| Investigação com o legado de 25% | Escolhe `v116` modal em cada pasta, corrige os códigos previstos e usa a população urbana desse município | `references/figuras/desenho_amostral_1960.R`, bloco B, construção de `mmoda` e `cad` |
| Pipeline de 1,27% | Reúne os domicílios da pasta corrigida e aplica `any(pop_urbana_muni >= 1e5)` | `R/microdata_1960_amostra_127.R`, função `finalize_1960_amostra_127()`, construção de `pastas` e `grupo` |

As regras podem divergir em tese, mas **não divergem nas bases examinadas**. A auditoria independente em [auditoria_classificacao_pastas_1960.py](auditoria_classificacao_pastas_1960.py) encontrou zero diferenças entre moda e `any()`, tanto na marca de cidade grande quanto no grupo final, nas **13.411 pastas do legado de 25% e nas 815 da subamostra materializada**. A diferença de implementação existe, mas não explica os problemas observados nesses arquivos.

O pareamento encontrou **todas as 670 pastas da subamostra nas UFs com legado**. Entre a classificação da investigação original e a da subamostra, encontrou sete divergências:

| UF/pasta | Grupo na investigação original | Grupo na subamostra | Evidência identificada |
|---|---|---|---|
| AL 25002 | urbana menor | cidade grande | Recodificação de município aplicada duas vezes no script de investigação |
| AL 25042 | urbana menor | cidade grande | Mesmo defeito de recodificação |
| CE 15004 | mista | rural | Diferença de composição observada em `V118` |
| CE 15290 | rural | mista | Diferença de composição observada em `V118` |
| MG 43234 | urbana menor | mista | Diferença de composição observada em `V118` |
| SP 60158 | cidade grande | mista | Diferença de composição observada em `V118` |
| SP 60718 | cidade grande | mista | Diferença de composição observada em `V118` |

Em Alagoas, o `v116` legado já é 2306 para as duas pastas. O script de figuras subtraía 200 novamente, produzindo 2106, sem correspondência no guia daquela UF. Sem população urbana vinculada, a pasta era classificada como urbana menor. É um erro concreto da investigação, separado da regra moda/`any()` e dos pesos do pipeline. A revisão corrige essa recodificação no script; **os ranks, os percentuais de espaçamento e as figuras antigas não foram recalculados**.

As outras cinco divergências persistem ao aplicar a mesma regra às duas fontes. Mediu-se a diferença de conteúdo, não sua causa histórica: perdas, recodificações ou composição original ainda precisam ser distinguidas pelo confronto de boletins. Assim, 77,3% e 90,4% continuam sendo resultados históricos da investigação anterior, não percentuais revalidados após a correção de Alagoas. Não há base para escolher a classificação que produza menor erro-padrão.

O próximo confronto deve detalhar, para essas cinco pastas, chave original e corrigida, municípios, contagens por situação, boletins em comum e registros sem par. Deve também confirmar a correspondência com os rótulos efetivamente exportados. Esse trabalho separa divergência de conteúdo, regra de reconstrução e evidência histórica insuficiente.

## 4. A estatística de corridas não pode ser usada como confirmação

O documento citava 104 corridas de intervalos 20, das quais 97 atravessariam zonas. A leitura do script revela que esse bloco não preserva a unidade de série:

```r
x6 <- cands[[6]]$s[order(uf, r)]
series <- x6[, .(pastas = .N, grupos = uniqueN(grupo), zonas = uniqueN(zona)),
             by = .(uf, serie = cumsum(is.na(d) | d != 20))]
```

`r` reinicia dentro de `h`, que é UF × grupo. Ordenar apenas por UF e `r` pode intercalar grupos, e o agrupamento das corridas não inclui `h` ou `grupo`. O script chega a contar `grupos` por corrida, mas o resumo impresso não exige que essa contagem seja um. Assim, esse número não demonstra corridas contínuas dentro de uma mesma série de situação.

A recontagem deverá preservar `h` e a ordem `r` na identificação de cada corrida e conferir sua composição. **O bloco de corridas não foi alterado nem reexecutado nesta revisão.** A correção de Alagoas descrita acima é separada desse problema, que não invalida automaticamente a estatística de pares que atravessam zonas calculada por outro bloco do script.

## 5. Frações, peso-base e Fernando de Noronha

O produto nominal de 1/4 por 1/20 é 1/80 = 1,25%, cujo inverso é 80. O código usa 1/0,0127 ≈ 78,7402. A diferença é de aproximadamente 1,575% em relação a 80; não deve ser confundida com evidência de probabilidades individuais diferentes. A denominação aproximada de 1,27%, a fração realizada e a probabilidade de inclusão são objetos distintos.

Não é possível corrigir essa questão simplesmente trocando 78,74 por 80: há pesos calibrados, limites de ajuste e exceções que dependem da base. Esta revisão mantém a convenção, documenta a diferença e reserva a reconciliação para uma mudança explícita acompanhada de avaliação de seus efeitos.

Em Noronha, o cadastro legado mostra uma pasta, também presente na subamostra, e o documento registra 62 domicílios em comum com os 75 do arquivo de 25%. A escala dos totais reforça o tratamento de certeza. Ainda assim, a presença de uma pasta em ambos os arquivos não demonstra sua probabilidade de inclusão: uma única realização não distingue todas as regras possíveis de seleção. Também não identifica sozinha por que 13 registros não aparecem no outro arquivo.

Há duas convenções simultâneas nos metadados atuais: `d_def=4` na calibração final de Noronha, mas `censobr_weight_desenho=78,74` e `censobr_weight_fator=w/78,74` na saída. Portanto, o fator publicado não é, nesse caso, o fator logit sobre a base efetivamente usada. Essa diferença foi explicitada no documento original, sem modificar as colunas.

A conciliação 815 unidades reconstruídas menos uma pasta de certeza igual a 814 pastas declaradas é uma hipótese possível. Falta uma fonte que diga que o IBGE excluiu Noronha dessa contagem. Da mesma forma, encontrar todas as pastas observadas no cadastro reconstruído não demonstra que nenhuma pasta selecionada originalmente tenha desaparecido.

## 6. Colapso, seleção sistemática e representação das etapas

A pasta é documentada como unidade de seleção da subamostra e deve ser preservada. Já os rótulos `censobr_estrato` são estratos **de análise**, resultantes de classificação reconstruída e colapso. Unir UFs com uma pasta a vizinhas é uma decisão para viabilizar a aproximação de variância, não a recuperação de um estrato original com esse rótulo.

O argumento de que qualquer erro de classificação seria conservador não procede. Mover uma pasta de um grupo para outro não é apenas fundir estratos; pode alterar contagens, médias e dispersões em direções diferentes. Mesmo uma queda observada de erro-padrão ao adotar estratos mais finos não prova que o resultado esteja mais próximo da variância verdadeira. Sem comparação adequada não se pode assegurar direção ou magnitude do efeito.

A ordem histórica também merece distinção: primeiro foram selecionados domicílios particulares e pessoas em coletivos; depois os boletins selecionados foram agrupados em pastas; por fim selecionaram-se pastas. A representação computacional pasta → domicílio reproduz uma fórmula convencional de dois estágios, mas sua equivalência completa com essa seleção histórica não decorre apenas de inverter os rótulos das etapas. A formação das pastas sobre a primeira amostra, os setores de coleta e a unidade em coletivos precisam entrar na justificativa.

Por fim, a variação das linhas de amostra na Folha de Coleta buscava evitar periodicidade; ela não converte automaticamente a seleção sistemática em amostragem aleatória simples dentro de uma pasta reconstruída. A aproximação AAS e as frações nominais podem ser operacionalmente úteis, mas devem ser reconhecidas como hipóteses. A [documentação do survey para `svydesign`](https://r-survey.r-forge.r-project.org/pkgdown/docs/reference/svydesign.html) descreve o desenho que o usuário fornece; o pacote não recupera a regra histórica nem demonstra que ela coincide com a parametrização escolhida.

## 7. Calibração: decisão preservada, incerteza adiada

Os resultados definitivos são os referenciais disponíveis adotados. Nas onze UFs apuradas com a contagem completa para as variáveis em questão, podem desempenhar o papel de totais censitários de referência. Nas outras dezessete, derivam da amostra de 25% e são estimativas. Não se propõe abandoná-los nem buscar um substituto inexistente; corrige-se a afirmação de que seriam constantes populacionais porque sua amostra é maior.

Reproduzir uma margem estimada fixa seu valor na calibração. Um resíduo zero nessa margem expressa essa restrição, não erro populacional zero. Incorporar a incerteza do controle requer tratamento de sua variância e da dependência entre as duas amostras. Isso é explicado na literatura de [amostragem em duas fases com calibração, Estevão e Särndal (2009)](https://www150.statcan.gc.ca/n1/en/catalogue/12-001-X200900110880) e, operacionalmente, no [método de calibração a controles estimados do svrep](https://bschneidr.github.io/svrep/reference/calibrate_to_estimate.html). A presente nota apenas registra a questão; o cálculo fica adiado.

Há também um limite de verificação: `references/conferencia_desenho_amostral_1960.R` chama `svydesign()` para a parcela entre pastas, adiciona manualmente uma parcela interna e, ao final, **apenas imprime** as colunas de resíduos já existentes no CSV. Não chama `survey::calibrate()`. A alegação de conferência independente dos resíduos foi retirada. A escolha da projeção e sua comparação com uma implementação independente ficam para a etapa específica de variâncias calibradas.

## 8. Critérios para encerrar a revisão do desenho

1. Identificar e versionar a tabela de pastas usada como cadastro, com origem, cobertura, chave original e chave corrigida; confrontar o legado com os arquivos brutos de 25% disponíveis.
2. Manter o confronto moda/`any()` concluído e a correção aplicada à recodificação de Alagoas; atualizar os diagnósticos de espaçamento quando a execução for retomada e investigar as cinco divergências de composição, sem escolher grupos para obter menor variância.
3. Examinar separadamente fronteiras de UF e de zona, primeiras posições superiores a 20 e grupos de baixo ajuste; recontar corridas preservando UF × grupo.
4. Registrar para cada componente o status documentado, reconstruído ou assumido, mantendo explícitas a extrapolação às onze UFs sem cadastro, a hipótese de certeza de Noronha e a distinção 1/80 versus 1/0,0127.
5. Documentar a unidade elementar de seleção em domicílios particulares e coletivos e justificar a representação das etapas sem alegar equivalência histórica apenas pela concordância de uma fórmula.

Esses critérios dizem respeito à fundamentação do desenho. Reestimação de pesos e cálculo das variâncias calibradas não foram feitos nesta revisão e seguem a decisão de tratá-los em sua etapa própria.
