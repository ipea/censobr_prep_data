# Escopo do trabalho — INVIOLÁVEL

Este é o projeto `censobr_prep_data` — pipeline auxiliar de preparação de dados que produz os parquets consumidos pelo pacote `censobr` (`https://github.com/ipea/censobr`).

## Workspace policy

Este projeto é **sempre aberto como workspace autônomo** — nunca abrir o diretório pai `censobr_e_prepData/` no VS Code, pois isso mistura este repo com o repo `censobr/` (consumidor) no mesmo painel de Source Control.

O `censobr` é gerenciado em outra janela / outra sessão Claude Code, e mudanças nele vão por PR no GitHub `ipea/censobr`.

## Caminhos editáveis

- `D:\Dropbox\Software\R_Packages\censobr_e_prepData\censobr_prep_data\**`

E **somente** isto. Edits/Writes/NotebookEdits, novos arquivos, deleções, e comandos de shell com efeito colateral só podem mirar caminhos sob esta raiz.

## Caminhos PROIBIDOS de edição (read-only)

- `D:\Dropbox\Software\R_Packages\censobr_e_prepData\censobr\**` — o consumidor `censobr`. Existe no disco como vizinho deste projeto, mas é gerenciado em outra sessão.
- Qualquer outro caminho fora de `censobr_prep_data/`.

A cópia local de `..\censobr\` existe apenas como referência. Mudanças no consumidor `censobr` se fazem via PR direto em `ipea/censobr` no GitHub — nunca a partir desta sessão. A cópia local pode estar desatualizada em relação ao GitHub a qualquer momento; a fonte de verdade é o repositório remoto.

## O que é permitido em `..\censobr\`

- `Read` — ler arquivos para entender o que o consumidor espera (DESCRIPTION, NEWS.md, R/, vinhetas).
- `Grep` / `Glob` — buscar referências, funções, padrões.
- `Bash`/`PowerShell` somente leitura — `gh release view`, `gh api repos/ipea/censobr/...`, `git log`, `git show`.

## O que é PROIBIDO em `..\censobr\`

- `Write`, `Edit`, `NotebookEdit` — qualquer alteração de arquivo.
- `Bash`/`PowerShell` com efeito colateral — `>` redirection, `Out-File`, `Set-Content`, `Add-Content`, `New-Item -Force`, `Remove-Item`, `rm`, `mv`, `cp`, `git checkout` de paths, `git reset`, `git apply`, `git restore`.
- Disparar `git commit`, `git push`, `gh pr create` apontando para esse diretório.

## Por quê

1. **Separação de responsabilidades.** Este pipeline é o *produtor* de dados. O `censobr` é o *consumidor*. Misturar os dois esconde de qual lado vem cada mudança.
2. **Reprodutibilidade.** Se o pipeline depender de uma cópia local específica do consumidor, perde-se a propriedade de que `tar_make()` em qualquer máquina produz o mesmo resultado.
3. **Risco de Dropbox/sincronização.** A cópia local mora num Dropbox compartilhado; um Edit aqui pode propagar para todos os colaboradores antes de revisão de código.

## Mecanismo de aplicação

Esta regra é aplicada por um hook `PreToolUse` em `.claude/settings.json` que invoca `.claude/hooks/check-scope.ps1` (e `check-scope-shell.ps1` para Bash/PowerShell). Tentativas de violação retornam exit code 2 com mensagem `BLOQUEADO: edição em ../censobr proibida — use o repo GitHub ipea/censobr.`

Em caso de bloqueio: **não tente contornar.** Pare, explique ao usuário o que precisava ser feito no `censobr`, e ofereça abrir um PR no GitHub.