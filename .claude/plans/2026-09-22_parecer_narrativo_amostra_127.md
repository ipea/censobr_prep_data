# Reescrita narrativa, ilustrada e auditável do parecer de 1960

**Status:** CONCLUÍDO — reescrita entregue; correções de dados não implementadas. **Data:** 22/09/2026. Pedido explícito: tornar o parecer compreensível, explicar antes/regra/justificativa/evidência/correção proposta/depois, com exemplos e ilustrações auditáveis.

## Limites

Somente documentação e seus recursos de ilustração/auditoria. Sem R/Rscript, targets, novos pesos/variâncias, alteração de produção, guias, parquets ou projetos vizinhos. Não transformar propostas em correções executadas. Preservar parecer anterior integralmente como anexo histórico e mudanças já existentes.

## Entrega

- [x] Preservar texto anterior em `references/microdata_1960_amostra_127_anexo_tecnico_20260921.md` e reescrever o ponto de entrada `references/microdata_1960_amostra_127_revisao_integrativa.md`.
- [x] Narrativa progressiva: como o arquivo é organizado; o que pretendiam as regras; casos concretos; por que a evidência muda a decisão; como deve ficar e o que continua indeterminado.
- [x] Vocabulário explicado ao primeiro uso; separar pessoas/famílias/domicílios, código escrito/arquivo gravado, dado ausente/ignorado, ajuste de pesos/conferência.
- [x] Comparações visuais antes/depois, esquemas pequenos e rótulos em português. Figuras documentais locais, não imagens inventadas de registros. Exemplo numérico inventado somente quando explicitamente didático.
- [x] Versão HTML para leitura confortável, gerada do mesmo Markdown com índice e figuras incorporadas; sem publicação ou mudança de aplicação.
- [x] Auditoria por caso: arquivo, linha, campos, regra de código, fonte comparadora e resultado. Links para evidência preservada; não depender só de JSON temporário.
- [x] Revisão independente de clareza e fidelidade; conferir links e figuras; nenhuma lacuna anterior silenciosamente apagada.

## Divisão

Três revisores extraem casos de vínculos/duplicatas, validação e reparo/exportação em `tmp/narrativa127/`; principal redige, confere fontes históricas, desenha explicações e preserva rastreabilidade. A habilidade de PDF orienta inspeção visual das fontes. A habilidade de visualização foi inspecionada: a entrega é documentação do projeto, não uma visualização interativa na conversa; usar diagramas e tabelas documentais comuns.

## Critério de conclusão

Um leitor deve conseguir explicar cada problema principal e localizar sua evidência sem conhecer nomes de variáveis. Quando não há prova suficiente de correção, o texto deve dizer por que não pode especificar um resultado único. A reescrita não homologa o tratamento nem os produtos.

## Conferência da entrega

Texto principal com sete casos narrados, quatro figuras e comparações antes/depois; HTML gerado do mesmo Markdown. Anexo técnico anterior preservado. Notas de evidência copiadas para documentação permanente e verificador independente somente leitura incluído. Os 25 trechos literais e as verificações numéricas selecionadas passaram; 46 links locais conferidos sem ausências. Revisores conferiram fidelidade e clareza; qualificadas a categoria filho/enteado, a composição ainda não auditada do destino124 e a diferença entre retabulação com pesos antigos e recalibração futura. Figuras inspecionadas após renderização; HTML sem transbordamento horizontal nos tamanhos desktop e móvel examinados. Nenhum R/Rscript, dado de produção, guia ou peso alterado.
