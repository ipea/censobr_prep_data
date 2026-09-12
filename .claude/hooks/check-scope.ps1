# check-scope.ps1
# PreToolUse hook for Edit / Write / NotebookEdit.
# Blocks any tool call whose target path lives in ..\censobr\ (the consumer
# package), which is read-only from this project. See .claude/rules/scope.md.
#
# Exits:
#   0 = allow
#   2 = block (stderr is shown to Claude)

$ErrorActionPreference = 'Stop'

$raw = [Console]::In.ReadToEnd()
if ([string]::IsNullOrWhiteSpace($raw)) { exit 0 }

try {
    $payload = $raw | ConvertFrom-Json
} catch {
    # Can't parse — don't block; let the harness handle it.
    exit 0
}

$toolInput = $payload.tool_input
if ($null -eq $toolInput) { exit 0 }

# Candidate path-bearing fields across Edit / Write / NotebookEdit.
$pathFields = @('file_path', 'path', 'notebook_path')
$candidates = @()
foreach ($field in $pathFields) {
    if ($toolInput.PSObject.Properties.Name -contains $field) {
        $val = [string]$toolInput.$field
        if (-not [string]::IsNullOrWhiteSpace($val)) {
            $candidates += $val
        }
    }
}

if ($candidates.Count -eq 0) { exit 0 }

# A path is "in censobr/" if it contains "censobr" immediately followed by
# a path separator (/ or \) or end-of-string, AND not preceded by another
# word/dash character (which would mean it's part of a longer name like
# "censobr-prep-data" or "censobr_e_prepData/...-censobr-prep-data" — the
# latter is the auto-memory dir of THIS very project).
#
# Matches:    "../censobr/foo", "..\censobr\foo", "D:/.../censobr"
# Does NOT:   "censobr_prep_data", "censobr-prep-data", "censobr_e_prepData"
$forbiddenPattern = '(?i)(?<![A-Za-z0-9_-])censobr(?=[\\/]|$)'

$blocked = $false
foreach ($p in $candidates) {
    if ($p -match $forbiddenPattern) {
        $blocked = $true
        [Console]::Error.WriteLine("BLOQUEADO: edicao em '$p' nao permitida.")
    }
}

if ($blocked) {
    [Console]::Error.WriteLine("")
    [Console]::Error.WriteLine("O diretorio ../censobr e somente leitura nesta sessao.")
    [Console]::Error.WriteLine("Mudancas no consumidor 'censobr' devem ser feitas via PR")
    [Console]::Error.WriteLine("no GitHub: https://github.com/ipea/censobr")
    [Console]::Error.WriteLine("")
    [Console]::Error.WriteLine("Veja .claude/rules/scope.md para a regra completa.")
    exit 2
}

exit 0