# Correções técnicas de 1960, preservando o estilo procedural

Status: CONCLUÍDO no escopo de código e testes pequenos. O usuário autorizou implementar os consertos técnicos delimitados na resposta anterior e exigiu seguir `.claude/rules/code-style.md`. Não equivale a homologação da base completa.

## Escopo

1. Preservar as 15 colunas existentes de procedência (`censobr_cartao_*`, `censobr_distrito_*`) nas listas do esquema compilado, nos tipos intermediários e no dicionário de 1960. Corrigir o dicionário para usar os caminhos recebidos e permitir saída de teste isolada. Não mudar respostas, chaves, pesos ou a partição de UFs entre as duas amostras. Cartões recuperados continuam bloqueados no ramo de 1,27%: nenhum dos 32 atualmente aprovados pertence às onze UFs desse ramo. Coluna de procedência desconhecida não pode ser descartada silenciosamente.
2. Fazer a exportação destinada à publicação depender de uma conferência técnica explícita. `validate_1960` conservará seu retorno e acrescentará um comprovante com assinaturas dos insumos e do relatório. Uma função pública/target específico conferirá a cobertura de UFs, grade completa, pendências estruturais e frescor das provas; diferença numérica com uma referência não será motivo automático de reprovação. A autorização será vinculada aos arquivos efetivos e ao esquema. `save_microdata_1960` exigirá essa autorização antes de escrever. Intermediários de diagnóstico continuam graváveis; não criar ciclo envolvendo `output_1960_amostra_127`.
3. Marcar saídas de `sampling_errors_1960*` como diagnósticos provisórios, distinguindo aproximação de desenho, resíduos condicionais e incerteza dos controles não incorporada. Não alterar fórmulas, valores, pesos ou recalcular variâncias da base completa. Corrigir somente comentários inexatos diretamente associados a essas funções.

## Arquivos e propriedade

- Frente esquema: somente constantes de colunas/tipos intermediários, `compile_1960`, rótulos e `dicionario_1960` em `R/microdata_1960.R`; teste novo próprio.
- Frente diagnósticos: somente as três funções `sampling_errors_1960*`, nos arquivos de 1960/127/25; comentários correspondentes em `references/conferencia_desenho_amostral_1960.R`; teste novo próprio.
- Integração: `validate_1960`, `save_microdata_1960`, nova função/arquivo `R/microdata_1960_publicacao.R`, `_targets.R`, testes de autorização/exportação e documentação. Não alterar helpers compartilhados ou outros anos.

## Tipos e segurança de saída

`schemas/censobr_types.csv` não será preenchido manualmente nem com números de um microlote apresentados como medição integral. A autorização exige cobertura declarada de todas as colunas e tipos válidos. Os novos campos só poderão ser publicados após a medição do produto real pelo procedimento do projeto; este impedimento será explícito. O schema entra como dependência de arquivo do target de conferência/saída. Não alterar `cast_censobr_types` global.

Ao tocar o gravador, impedir a sobrescrita silenciosa de um arquivo de versão existente e verificar o sucesso da instalação da saída antes de retornar seu caminho. Temporários exclusivos ficam sob a saída escolhida; nenhuma limpeza recursiva de caminho amplo ou preexistente. Saída de testes apenas em `tmp`.

## Estilo e validação

`data.table`, passos lineares, uma função pública por target, sem helpers privados de uso único, sem comentários extensos dentro do R ou mensagens com `sprintf`. Exceções explícitas apenas para invariantes analíticas/de entrega. Objetos grandes por UF, com liberação de memória. Manter nomes IBGE e nomes de procedência já existentes.

Antes: testes pequenos devem demonstrar perda das colunas, ausência de rótulos e possibilidade de exportação sem conferência. Depois: releitura de parquets, preservação de dados/pesos, recusa de relatório ausente/adulterado/desatualizado, grade incompleta, vínculos/pesos inválidos e esquema incompleto; aceitação de diferença amostral sem defeito estrutural; nenhuma substituição de arquivo existente. Conferir também dependências por parse de `_targets.R`, sem executar o pipeline.

R exclusivamente pelo executor isolado com arquitetura Windows e locale do filho, uma instância por vez. Congelar funções em cada janela de teste. Não usar `Rscript -e`, `tar_make`, modificar ambiente global, instalar pacotes ou encerrar processos alheios. Baterias anteriores pertinentes serão repetidas após estabilizar a integração. Sem reconstrução nacional, recálculo de pesos, release, commit ou push nesta rodada. Preservar alterações anteriores em Rproj e renv.lock e os cadernos históricos do commit 91372a3.

## Fechamento

Implementadas as três frentes. A conferência é técnica, não metodológica; mantém divergências e categorias vazias visíveis. O gravador revalida assinaturas e não sobrescreve versões. O target de validação acompanha CSV e JSON, embora a função continue retornando um caminho. Esquema publicado permaneceu intocado e incompleto para as novas colunas, portanto sem liberação da exportação real.

Seis scripts de testes com última execução aprovada: procedência, rótulos, recusa de exportação sem conferência, publicação (30 recusas esperadas), validação anterior e pesos anteriores com I/O Arrow ativado. Os avisos de coerção da bateria de pesos revelaram um caso adicional de NA inteiro preexistente: contraprova falhou para duas linhas e passou depois da substituição da coluna inteira. Os valores anteriores dos erros amostrais são exatamente iguais, comparados com baseline imutável. Não houve crash nativo.

Histórico de tentativas, limites e resultados em `references/correcao_scripts_r_1960_20260923.md` e `references/correcao_scripts_r_1960_evidencias/`. Assinaturas dos três arquivos protegidos da amostra127 permanecem iguais. Nenhum guia, manifesto, função compartilhada, outro ano, dado completo, peso real ou alteração preexistente do usuário foi editado.
