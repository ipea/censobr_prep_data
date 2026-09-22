# Execução, correções dos registros e pesos de 1960

**Status:** APROVADO; ENTREGA PARCIAL CONFERIDA, com 25% concluída em área separada e 1,27% ainda pendente de decisões de integridade/reconstrução. Data: 22/09/2026.

**Autorização posterior:** o usuário autorizou recuperar cartões da fonte25 após explicação contextualizada. Plano específico `.claude/plans/2026-09-22_recuperacao_cartoes_127.md`; resultado em `references/recuperacao_cartoes_1960_20260922.md`. Foram recuperados 29 cartões para 72 pessoas em recorte separado, sem resolver a base inteira. As referências abaixo a ausência dessa autorização são históricas e não devem bloquear o mecanismo aprovado, nem liberar os demais casos sem prova.

## Autorização e limites

O usuário autorizou investigar o crash Rscript, executar testes pequenos, gerar relatórios com pesos atuais, corrigir vínculos/duplicatas/reparos comprovados, completar conferências e revisar/recalcular pesos. Essa autorização substitui a suspensão de R apenas no percurso controlado abaixo. Variâncias calibradas continuam adiadas. Sem publicação, alteração em projetos vizinhos, atualização global de R/pacotes ou reconstrução de outros anos. Preservar as mudanças existentes, inclusive Rproj e renv.lock.

## Ordem e verificações

1. Diagnóstico Windows somente leitura (processos, eventos de falha, versões, inicialização e bibliotecas). Primeiro teste R: arquivo mínimo, sem `-e`, `--vanilla`, um processo, limite de tempo, sem carregar targets; impedir diálogos de falha apenas no processo de diagnóstico, sem mudar configuração global. Se falhar, investigar antes de repetir.
2. Confirmar carregamento dos pacotes indispensáveis e leitura mínima Arrow. Executar testes sintéticos de validação. Corrigir falhas demonstradas, repetir teste pequeno. Só então gerar relatórios com dados/pesos atuais em diretório novo, preservando relatórios antigos.
3. Implementar correções de registros com trilha de origem e decisões demonstradas por arquivos brutos/fontes paralelas. Não deduplicar pessoas apenas porque respostas coincidem; não anexar órfão pelo cartão anterior; não completar campos por hipótese. Restaurar os exemplos comprovados e tratar sistematicamente a classe de erro, mantendo casos não resolvidos separados/assinalados. Testes por família e amostra pequena antes de gerar novos arquivos de 1,27% em staging.
4. Completar tabela7 em 25%/combinado e aluguel/estado conjugal preliminares somente quando variáveis e universo publicados permitirem reconstrução comprovada. Quando faltar informação necessária, manter limite explícito em vez de inventar resultados. Testar cada tabela/unidade isoladamente.
5. Corrigir população elegível dos controles de alfabetização, verificar suporte e convergência do ajuste; recalcular pesos apenas sobre dados conferidos, em staging, com comparações antes/depois. Controle positivo sem observações não se resolve fabricando casos nem aceitando falsa convergência. Separar limitações de referência estimada e variâncias adiadas.

## Arquivos previstos

- Diagnóstico/runner/testes específicos em `references/` e artefatos/logs isolados em `tmp/execucao_1960_20260922/`.
- `R/microdata_1960_amostra_127.R`: reparos/dedup/vínculos, validadores e ajustes/guardas de calibração estritamente necessários.
- `R/microdata_1960_amostra_25.R`, `R/microdata_1960.R`, `R/microdata_1960_validacao.R`: conferências, regra de alfabetização e caminhos de entrada/saída isoláveis. Não alterar fórmulas de variância.
- `read_guides/1960_amostra_127_correcoes.csv` e eventual tabela explícita de decisões de vínculo: somente correções comprovadas, com origem e teste. Nenhuma alteração genérica em guias de largura fixa.
- Testes R e documentação de resultado/pendências. `_targets.R` não será executado nesta etapa, pois dispara verificações externas/invalidações.

### Ajuste pontual de implementação — decisões por linha

A correção dos registros passou a usar dois manifestos explícitos de decisões. Para que uma mudança nesses arquivos não deixe o pipeline usando uma decisão antiga, acrescentar somente dois `tar_target(format = "file")` de 1960 e passar esses caminhos aos targets existentes de deduplicação e vínculos. Isso é parte da correção reproduzível autorizada; não muda a estrutura geral, os outros anos, os downloads ou os schemas. Conferir por parsing estático e pelos testes diretos, sem avaliar `_targets.R` nem executar `tar_make()` enquanto houver registros sem decisão.

## Preservação e critério de entrega

Arquivos originais e resultados atuais permanecem como comparação; novas saídas em diretório separado. Não sobrescrever materialização antiga antes de verificar contagens, pessoas mantidas/restauradas, chaves, pesos e diferenças. Não anunciar causa do crash, correção dos dados ou convergência sem evidência. Se alguma decisão alterar substancialmente a interpretação sem prova documental, concluir o trabalho independente possível e pedir a decisão faltante.

## Primeira evidência do ambiente

Eventos Windows de 16/09/2026 registram Rscript4.6.1, exceção0xc0000005 em ucrtbase.dll (offset0xed8b0). Nenhum processo R estava ativo na consulta. Há instalações R4.5.0 e4.6.1. O projeto ativa renv via .Rprofile. Isso identifica o local de uma falha, ainda não a causa.

## Progresso e execução de baixo consumo

Diagnóstico concluído: ausência de `PROCESSOR_ARCHITECTURE` causa falha reproduzível no encerramento de `cli`; arquitetura real fornecida apenas ao filho resolveu os testes. As quatro validações completas com entradas antigas terminaram sem alterar as entradas. Testes sintéticos e microlotes reais passaram. Há decisões comprovadas em manifestos de duplicatas/vínculos e bloqueios para o restante não demonstrado; por isso a reconstrução integral de 1,27% continua impedida.

O piloto real de pesos de 25% em FN/SE passou, com 13 hashes de entradas/código preservados durante a execução. A conferência prévia das 17 UFs não encontrou exceções nas classificações/chaves/contagens examinadas; isso não equivale a provar convergência. Para recalcular as outras 15 UFs sem disputar excessivamente memória com tarefas do usuário, foi autorizada a projeção das mesmas entradas em 8 colunas domiciliares e 10 pessoais, preservando tipos, ordem e contagens. A mesma função de pesos será usada, primeiro em SE para exigir equivalência com o piloto completo; depois, uma UF por filho, MG/SP por último. Início exige 4 GiB livres; abaixo de 2 GiB livres ou após 600 segundos, interromper somente o filho criado. Sem relaxar controles ou limites. Saídas reduzidas serão identificadas como auxiliares, não como microdados completos; nenhuma compilação/publicação ou substituição das entradas é autorizada por esse percurso. Resultados finais e pendências: `references/execucao_correcao_1960_20260922.md`.

Após um bloqueio inicial antes de criar R (1,06 GiB livres), a memória voltou a ficar disponível. SE reduzido passou com igualdade exata de todas as colunas selecionadas e dos 146 controles do piloto completo; pico do processo aproximadamente 442 MiB. Prosseguiram as 15 UFs com as mesmas proteções. O monitor Python recebeu teste específico de falha: encerra e aguarda apenas o filho/descendentes próprios, mesmo se seu acompanhamento levantar uma exceção.

Se todos os recálculos passarem e a memória continuar disponível, reunir as nove colunas calculadas aos **arquivos brutos completos atuais**, não aos antigos parquets ponderados, por UF e em nova pasta separada. Essa materialização é parte da entrega dos pesos recalculados; não altera dados originais nem publica/compila. Exigir igualdade de todas as colunas comuns, ordem/chaves/contagens/tipos, hashes antes/depois e memória limitada por lotes. Primeiro reconstruir somente SE e comparar integralmente com o piloto completo já aprovado; só então materializar as outras UFs. Arquivo previsto: `references/reunir_pesos_25_1960.py`. A base de 1,27% permanece bloqueada, e as tabelas auxiliares não poderão ser apresentadas como completas sem essa prova.

Os 17 recálculos e a recomputação independente dos 5.039 controles passaram. O novo relatório integrado de 25% também passou, com 2.040 linhas e as mesmas pendências explícitas. SE foi recomposto integralmente e comparado ao piloto com igualdade de todas as colunas. A finalização por renomeação de diretório falhou em tentativas posteriores com erros Windows 32 e 5, embora os dados e hashes conferissem; nenhuma causa externa foi presumida nem permissão alterada. As tentativas foram preservadas. A estratégia aprovada passa a criar diretórios UF fixos numa raiz nova e registrar aprovação **somente** após todas as verificações em um manifesto final. Existência de pasta/parquet não equivale a aprovação. Falha após escrita não pode gerar marcador de aprovação; isso deve ser testado. Não haverá nova tentativa de renomear pastas bloqueadas, exclusão de artefatos ou promoção ao pipeline. Repetir SE antes das demais UFs com esse contrato.

## Entrega desta rodada

Contrato sem renomeação testado (16 casos), SE novamente igual ao piloto completo e 15/15 UFs recompostas com igualdade integral bruto+9 campos, chaves únicas, releitura e hashes preservados. Índice aprovado dos 34 parquets/17 UFs: `tmp/execucao_1960_20260922/pesos25_completo_15_fixo_01/indice_34_parquets_completos.json`; 3.066.365 domicílios e 14.983.769 pessoas, sem substituição/publicação. Relatório novo integrado: `tmp/execucao_1960_20260922/validacao25_novos_17ufs_20260922_101103_802707/relatorio_novo/validacao_definitivos.csv`. Os quatro relatórios antigos permanecem separados.

Em 1,27%, manifestos finais: 82 vínculos e 4.543 linhas de decisões de duplicatas; três reparos de texto; suíte completa aprovada. Restam 1.411 pessoas/555 grupos sem cartão confirmado, 1.417 perfis repetidos sem decisão, 63 vínculos diretos com município divergente/ausente e um cartão convivente sem principal confirmado. Há candidatos ainda a examinar e casos cujo cartão só existe na fonte25: reconstruí-lo na127 exige contrato de origem diferente do remapeamento para cartões já existentes. Não presumir autorização para importar registros nem excluir os duvidosos. Também restam convenções de idade nas tabelas preliminares. A base127 integral, seus pesos e a compilação final não estão concluídos. Variâncias continuam adiadas. A nota narrativa vigente explica a prova e o que falta, sem apresentar convergência numérica como aprovação do desenho inteiro.
