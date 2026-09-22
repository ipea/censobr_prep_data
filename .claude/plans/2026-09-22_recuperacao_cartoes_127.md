# Recuperação documentada de cartões da amostra de 1,27%

**Status:** CONCLUÍDO no escopo de recuperação comprovada; base integral ainda pendente. Autorizado pelo usuário em 22/09/2026.

## Escopo autorizado

Recuperar registros familiares não encontrados em HHOLDA usando a fonte de 25%, somente com correspondência demonstrada, origem explícita e sem acrescentar pessoas. A autorização sucede a explicação do caso MG/pasta40090/boletim004. Preservar originais, parquets atuais e alterações anteriores. Não publicar, recalcular pesos sobre pendências, executar targets, atualizar pacotes ou inferir edifícios a partir de boletins coletivos. As demais pendências da amostra continuam bloqueando sua aprovação integral.

## Percurso

1. Reler regras, implementação e evidências atuais. Identificar candidatos entre as pendências restantes após os 82 vínculos aprovados. Auditoria de baixo consumo em Python, com releitura literal dos arquivos históricos.
2. Exigir cartão25 único, grupo pessoal completo, multiplicidades e ordens conferidas, geografia/situação compatíveis, quesitos pessoais íntegros e iguais. Procurar cartões deslocados em toda a UF, pelas chaves, composição pessoal e contexto físico. Registrar alternativas e rejeitar os ambíguos, sem suprimir pessoas.
3. Salvar manifesto versionável de recuperação com textos originais, hashes e localizadores das duas fontes, verificações, campos recuperáveis e pessoas já presentes na127. Não fabricar uma linha HHOLDA de aparência original. Cartões coletivos não demonstram prédios distintos; conviventes não são recuperados sem a relação com a família principal demonstrada.
4. Acrescentar etapa explícita no R que consome apenas as decisões aprovadas, valida sua correspondência com a entrada, não modifica respostas pessoais e mantém procedência em famílias/pessoas. Integrar somente os alvos necessários para rastrear o manifesto, sem avaliar `_targets.R`.
5. Testar primeiro o microlote MG40090/004 (2 pessoas), incluindo casos adversos: origem alterada, pessoa faltante/excedente, cartão existente, composição divergente e ausência de decisão. Usar exclusivamente o runner R isolado que já resolveu o crash; um processo de cada vez. Ampliar somente depois do piloto, em nova pasta de resultados.
6. Conferir saídas reabertas, cardinalidade, respostas, procedência e hashes dos originais. Registrar antes/depois e pendências sem alegar reconstrução integral. Revisão independente do mecanismo e da evidência.

## Arquivos e impacto previsto

- `references/auditoria_recuperacao_cartoes_1960.py` e teste específico: auditoria e geração reproduzível do manifesto, não edição manual dos dados.
- `read_guides/1960_amostra_127_cartoes_recuperados.json`: decisões explícitas e evidências; separado dos vínculos que usam cartões existentes.
- `R/microdata_1960_amostra_127.R`: etapa de recuperação e preservação mínima da origem ao construir/finalizar famílias. Sem refatoração de outras etapas ou variâncias.
- `_targets.R`: dependência de arquivo e chamada explícita da etapa, se o contrato estiver aprovado pelos testes; não executar targets.
- `R/microdata_1960.R`: bloqueio pontual antes de compilar registros recuperados, pois as listas fechadas de publicação ainda não incorporam sua procedência. Não descartar essa origem silenciosamente nem ampliar schemas/publicação nesta rodada.
- `references/test_recuperacao_cartoes_1960.R`, nota narrativa e logs em raiz nova `tmp/recuperacao_cartoes_1960_20260922/`.
- `references/conferir_recuperacao_cartoes_1960.py`: conferência independente dos parquets R reabertos e índice antes/depois.

Novos campos de procedência terão prefixo `censobr_`; nenhum nome/código IBGE será reinterpretado. Identificador interno de cartão recuperado não será apresentado como número de linha original de HHOLDA. Aprovação dos casos recuperados não remove travas de outras duplicatas/vínculos.

## Contrato refinado após revisão independente

Cartões recuperados têm `linha`, `id_arquivo` e textos HHOLDA ausentes. O ID de recuperação, arquivo/linha/hash da fonte25 e unidade do boletim ficam em campos separados; `censobr_ordem_cartao` é somente uma posição operacional. Não se transportam pesos nem respostas individuais da fonte25. V113 é convertido de três para dois caracteres pelo valor, conservando o literal25 na evidência. Só V101=1/3 são elegíveis nesta implementação. Inserção diante de convivente interrompe a construção.

Fontes brutas, quatro guias e decisões anteriores são rastreados como arquivos no targets, além do manifesto. O R relê os literais de ambas as fontes, confere hashes, composição, ordens/redundâncias e quesitos antes de incorporar. O teste de disponibilidade falhou antes da nova função e passou depois; a suíte antiga de integridade voltou a passar, sem crash nativo. Testes funcionais da recuperação aguardam o manifesto da auditoria.

## Entrega conferida

- Auditoria final `tmp/recuperacao_cartoes_1960_20260922/auditoria_completa_02/`: 215 grupos/589 pessoas examinados; 29 cartões/72 pessoas aprovados, todos coletivos e presentes não moradores. Os demais casos permanecem pendentes. Nenhuma pessoa acrescentada, excluída ou alterada pela recuperação.
- Manifesto versionado com 21 fontes, literais, hashes e localizadores. Os 27 testes Python passaram; revisão independente conferiu 72 registros127 e 101 registros25 literais. Código sem dependência do relatório antigo em tmp; chaves inválidas são registradas, não perdidas por comparação SQL com NULL.
- O caso BH40090/004 não foi aprovado: outras alternativas coletivas não foram afastadas integralmente. A coincidência isolada de perfil com Três Pontas foi investigada e distinguida da composição inteira. Não houve equivalência imposta entre códigos00/63 para liberar o caso.
- Piloto aprovado: Cambuí40654/177, duas pessoas e um cartão25. Suíte R completa final `recuperacao_real_04.log` passou, com 38 bloqueios adversos, ausência de decisão, conviventes, compilação, ordem das decisões, repetição, todos29/72 e reabertura dos parquets. A finalização foi testada com contexto real de Paracatu: quatro pessoas/duas pastas/duas unidades; sem relaxar guarda de estrato.
- Correções durante os testes: uma expressão de seleção estava acrescentando índice data.table por referência à entrada, corrigida com seleção posicional; um else de teste em linha separada era inválido no Rscript; desambiguação da seleção de procedência retirou um warning. Falhas/tentativas anteriores preservadas. Execução final sem crash nativo; permanece aviso de versão de compilação do pacote digest, sem atualização de pacotes.
- Saídas finais em `tmp/recuperacao_cartoes_1960_20260922/teste_bf643622f74/`. Conferência independente final: `tmp/recuperacao_cartoes_1960_20260922/conferencia_final_01/indice_entrega.json`. Os dois parquets29/72 também têm hashes idênticos aos da execução R completa anterior. Todos72 já estavam no parquet atual como anexada_anterior; cinco mudam a pasta atribuída. Hashes das fontes usadas e do parquet pessoal atual permaneceram iguais.
- Reconciliação com a lista anterior: 1.339 pessoas/526 grupos ainda sem cartão confirmado, além das duplicatas/conflitos anteriores. Nenhum peso127 foi recalculado; nenhum parquet completo substituído; nenhum targets ou upload executado. Os IDs internos podem mudar na reconstrução futura: não juntar pesos antigos por esses IDs.

Nota narrativa principal: `references/recuperacao_cartoes_1960_20260922.md`. Evidência metodológica: `references/recuperacao_cartoes_1960_evidencias.md`. Referências históricas receberam apontadores explícitos ao estado mais recente.
