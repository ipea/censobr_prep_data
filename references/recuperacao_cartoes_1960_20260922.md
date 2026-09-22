# Recuperação de registros familiares de 1960, com origem identificada

**Resultado: 29 cartões recuperados, correspondentes a 72 pessoas já existentes, em arquivos separados.** A recuperação foi implementada no programa, exercitada em casos reais e integrada às dependências do pipeline. Os arquivos originais e a base completa atual não foram substituídos. Esta entrega não encerra a reconstrução integral nem recalcula seus pesos.

Todos os 29 cartões aprovados são de grupos em domicílios coletivos. As 72 pessoas estão registradas como presentes, mas não moradoras habituais desses locais. Portanto, não acrescentamos 72 moradores à população residente nem demonstramos a existência de 29 edifícios distintos.

As 72 pessoas já constavam também do parquet atual, todas com a marca de ligação ao cartão anterior. Em cinco delas, o cartão recuperado pertence a uma pasta diferente daquela que lhes fora atribuída. Portanto, o efeito pode alcançar o agrupamento usado no desenho amostral, mesmo sem mudar o número de pessoas.

O [índice da entrega e conferência antes/depois](../tmp/recuperacao_cartoes_1960_20260922/conferencia_final_01/indice_entrega.json) identifica os arquivos que contêm somente esses casos, suas fontes e seus resumos de conteúdo. Não confundir esse recorte com a amostra completa.

## O que muda — e o que permanece

O arquivo HHOLDA tem linhas de pessoas e linhas que identificam o grupo familiar e seu domicílio. Quando não encontramos a linha do grupo, as pessoas não deixam de existir. A regra antiga de anexá-las ao cartão imediatamente anterior já foi retirada do código. Nesta rodada, procuramos se o cartão correspondente sobreviveu no outro arquivo histórico.

Recuperar significa acrescentar à **tabela preparada de famílias**, não ao arquivo original, informações observadas naquele cartão da fonte de 25%. A lista de pessoas da amostra de 1,27% permanece igual. O cartão recuperado não ganha uma falsa linha de HHOLDA: `linha`, `id_arquivo` e os campos de texto original de HHOLDA ficam ausentes. Seu identificador de recuperação, arquivo, linha e resumo criptográfico da fonte ficam em campos próprios. Esse resumo permite detectar se o arquivo de origem mudou.

`recuperada_25` significa que o **cartão familiar**, não a pessoa, veio da outra fonte. Nenhum peso da amostra de 25% é transportado. As duas fontes têm origem histórica compartilhada; concordância entre elas não é uma certificação independente de verdade populacional.

## Um exemplo do que efetivamente ficou corrigido

Em Cambuí, Minas Gerais, duas pessoas já presentes em HHOLDA — linhas **400682 e 400683**, uma mulher de 33 anos e um homem de 31 — trazem a identificação **pasta 40654, boletim 177**. Ambos estão registrados como hóspedes ou empregados, presentes e não moradores habituais. Não há fundamento para chamá-los de casal.

No parquet antigo, os dois estavam anexados ao cartão da linha **400678**, da mesma pasta, mas do **boletim 176**. Esse cartão é de domicílio particular. A regra da posição no arquivo tinha, portanto, colocado visitantes de um boletim coletivo no grupo particular anterior.

Na fonte de 25%, o cartão da linha **429723** é do boletim **177**, classificado como coletivo, e declara exatamente duas pessoas. A mulher corresponde à linha **429725**, e o homem à **429724**. A ordem é inversa à de HHOLDA: alinhar as linhas pela posição seria errado. As respostas individuais e a composição inteira coincidem; as buscas de cartões alternativos não deixaram alternativa plausível não resolvida para este caso.

| Aspecto | Antes, no parquet atual | Depois, no recorte conferido |
|---|---|---|
| Pessoas | As duas linhas já existiam | As mesmas duas linhas, com respostas preservadas |
| Grupo atribuído | Boletim 176, cartão particular anterior | Boletim 177, cartão coletivo recuperado |
| Origem do cartão | HHOLDA, linha 400678 | Fonte de 25%, linha 429723, explicitamente identificada |
| Moradores acrescentados | — | Nenhum |

No código, a origem passa de `anexada_anterior` para `recuperada_25`. Isso descreve uma correção de agrupamento, não uma alteração de idade, sexo, parentesco ou condição de presença. Os espaços em branco das perguntas domiciliares do coletivo continuam ausentes; não viram zeros nem recebem respostas do domicílio particular anterior.

## Por que o exemplo de Belo Horizonte continuou pendente

O exemplo discutido com o usuário envolve duas pessoas de Belo Horizonte, nas linhas 491756 e 491757 de HHOLDA, pasta40090/boletim004. A fonte de 25% contém um cartão correspondente na linha58692 e duas pessoas nas linhas58693 e58694. O processamento antigo anexava as duas ao cartão491747, de outra pasta e outro boletim.

A busca ampliada encontrou também o perfil da mulher de19anos em outro grupo, em Três Pontas. Isso exigiu exame adicional, não exclusão automática nem aprovação automática. A composição inteira e a localização precisam distinguir os grupos. O registro individual não contém um documento civil que permita concluir, só pelas respostas, que estamos diante da mesma pessoa.

A conferência mostrou que o grupo de Três Pontas, com 11 pessoas e outro município, não corresponde ao par de Belo Horizonte. Mas restaram **outras** alternativas: cartões coletivos próximos cujas pessoas não coincidem integralmente entre as duas fontes. Por exemplo, algumas respostas do ano de casamento aparecem como `00` em um arquivo e `63` no outro. Esses valores não foram equiparados para fazer a conferência passar. Assim, o boletim 004 de Belo Horizonte **não entrou nos 29 aprovados**. As duas pessoas continuam preservadas e pendentes. A [nota de evidências](recuperacao_cartoes_1960_evidencias.md) identifica cada divergência.

O número de cartões também não deve ser lido como número de prédios. Um cartão de domicílio coletivo identifica uma unidade de registro do arquivo; não demonstra que cada boletim corresponde a um edifício fisicamente distinto. A saída distingue `boletim_coletivo` de `boletim_particular`.

## Critérios de incorporação

1. Não haver cartão na amostra de1,27% sob a mesma UF, pasta e boletim, mesmo desconsiderando o distrito.
2. Haver um único cartão correspondente na fonte de25%, com localização compatível, número declarado de pessoas e ordens individuais conferidos.
3. A composição completa das pessoas coincidir, sem diminuir ou aumentar a quantidade de ocorrências de um perfil. A implementação atual também exige distinguir cada correspondência dentro do grupo.
4. Procurar cartões deslocados pelas chaves parciais, pelos campos familiares, pelas pessoas e pela posição no arquivo. Uma pista de semelhança não equivale a um vínculo provado. Alternativas plausíveis não afastadas mantêm o caso pendente.
5. Não resolver códigos danificados apagando-os antes da comparação. Branco legítimo, salto de questionário, zero e resposta inválida são situações diferentes.
6. Recuperar nesta rodada somente espécie1 ou3. Famílias principais com conviventes e famílias secundárias exigem demonstração adicional da estrutura domiciliar.

O programa R confere o manifesto de decisões contra os arquivos históricos: verifica seus resumos criptográficos, relê os textos das pessoas em HHOLDA e os textos do boletim na fonte25, reaplica os guias e exige a composição aprovada. Um lote parcial, um cartão já existente ou uma evidência alterada interrompem a operação. As respostas individuais não são modificadas.

## Roteiro auditável

- [Plano e limites autorizados](../.claude/plans/2026-09-22_recuperacao_cartoes_127.md).
- [Auditoria das correspondências e alternativas](auditoria_recuperacao_cartoes_1960.py) e [testes da auditoria](test_auditoria_recuperacao_cartoes_1960.py).
- [Implementação no preparo de1,27%](../R/microdata_1960_amostra_127.R), função `recover_family_cards_1960_amostra_127`.
- [Testes reais e adversos de recuperação](test_recuperacao_cartoes_1960.R).
- [Conferência independente das saídas](conferir_recuperacao_cartoes_1960.py) e [evidências da seleção dos 29 cartões](recuperacao_cartoes_1960_evidencias.md).
- Resultados desta rodada: `tmp/recuperacao_cartoes_1960_20260922/`, separados dos dados atuais. Uma tentativa de auditoria ou um arquivo existente não significa aprovação.

## O que os testes demonstraram

Os 27 testes da auditoria passaram. No R, primeiro o grupo de duas pessoas de Cambuí passou; depois foram aplicadas todas as 29 decisões, conservando as 72 pessoas. A reabertura dos parquets conferiu as respostas, os vínculos e a procedência. Inverter a ordem das decisões não mudou o resultado.

Houve 38 testes de interrupção com entrada ou evidência alterada, além das guardas específicas para conviventes, ausência de decisão e compilação. Os exemplos incluem pessoa faltante, pessoa excedente, texto adulterado, origem com conteúdo alterado, cartão já existente e tentativa de executar a recuperação duas vezes. Não bastava o programa terminar: precisava recusar essas situações e conservar a entrada.

A finalização foi conferida em um microlote com quatro pessoas e duas pastas: o caso recuperado de Cambuí e um grupo real de Paracatu usado como contexto. Isso permite testar a passagem dos novos campos para a tabela de domicílios sem afrouxar a guarda de estrato com uma única pasta. Não é uma validação da finalização da amostra inteira. Todos os casos positivos reais desta rodada são coletivos; não houve recuperação positiva real de cartão particular.

Log completo: [recuperacao_real_04.log](../tmp/recuperacao_cartoes_1960_20260922/recuperacao_real_04.log). A suíte das correções anteriores também passou em [regressao_integridade_02.log](../tmp/recuperacao_cartoes_1960_20260922/regressao_integridade_02.log). Os testes usaram o executor isolado já diagnosticado, sem reproduzir o crash nativo do Rscript. Tentativas anteriores permanecem guardadas, mas não substituem esses resultados de conferência.

Reprodução, sempre escolhendo um nome de log novo:

```text
python references/test_auditoria_recuperacao_cartoes_1960.py
python references/rodar_r_isolado_1960.py references/test_recuperacao_cartoes_1960.R tmp/recuperacao_cartoes_1960_20260922/NOVO.log --windows-arch --locale-c --timeout 420
```

## Limites que continuam valendo

As pendências de vínculos e duplicatas não tratadas aqui continuam interrompendo a construção integral. O recálculo de pesos da amostra de1,27% continua dependendo dessas decisões. A compilação recebeu um bloqueio adicional: não pode descartar silenciosamente os novos campos de origem por usar uma lista antiga e fechada de colunas. Não houve substituição de parquets atuais, publicação, cálculo de variâncias calibradas ou execução de `targets` nesta rodada.

As 72 pessoas aprovadas pertencem à lista anterior de 1.411 pessoas sem cartão confirmado. Retirando somente essas decisões dessa lista, restam **1.339 pessoas em 526 grupos**, ante 555 grupos. Essa é a conciliação das decisões, não uma contagem de uma base integral regravada. Continuam também os 1.417 perfis repetidos sem decisão, os conflitos municipais e a família convivente sem principal confirmado, com possíveis sobreposições entre as listas.

Os identificadores internos de famílias e domicílios podem mudar numa reconstrução. Por isso, não se devem reaproveitar os pesos antigos por uma simples junção desses identificadores: os pesos de 1,27% precisarão ser recalculados depois de resolver as demais pendências e conferir os universos. A autorização desta rodada resolve a possibilidade de recuperar cartões; não transforma as outras incertezas em decisões aprovadas.
