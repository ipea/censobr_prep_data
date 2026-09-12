# check-scope-shell.ps1
# PreToolUse hook for Bash / PowerShell tools.
# Blocks any shell command that *writes* to ..\censobr\ (the consumer package).
# Read-only operations against ../censobr (cat, ls, grep, git log, gh release view)
# are allowed. See .claude/rules/scope.md.
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
    exit 0
}

$cmd = [string]$payload.tool_input.command
if ([string]::IsNullOrWhiteSpace($cmd)) { exit 0 }

# Strip remote-repo references (GitHub URLs, --repo args, gh api endpoints)
# from the text we'll scan for filesystem paths. These tokens are remote
# refs, not local paths, so even if they contain "censobr" they cannot be
# a write target. Removing them prevents false positives like:
#
#   mkdir foo && gh release download --repo ipea/censobr --dir foo
#   gh api repos/ipea/censobr/contents/...
#   curl https://github.com/ipea/censobr/...
#
# Note: this does NOT weaken the write check below — `-X POST/PUT/PATCH/DELETE`
# against `gh ... censobr` is still flagged via the write-pattern list, and
# `gh pr/release/issue create|edit|delete|...` are matched on $cmd directly.
$cmdForPath = $cmd `
    -replace '--repo[=\s]+\S+', '' `
    -replace 'https?://github\.com/\S+', '' `
    -replace 'gh\s+api\s+\S+', ''

# Does the (stripped) command reference the forbidden directory as a
# filesystem path? We require:
#   - immediately BEFORE "censobr": a path-like character (`.`, `/`, or `\`)
#   - immediately AFTER  "censobr": a path separator, whitespace, quote, or EOL
# Together these isolate filesystem-path references and reject bare uses
# of the bare word.
#
# Matches:    "../censobr/...", "..\censobr\...", "D:/.../censobr/..."
# Does NOT:   "censobr_prep_data", "censobr-prep-data", "censobr_e_prepData",
#             "grep -c censobr", "echo the-censobr-project"
$pathPattern = '(?i)(?<=[./\\])censobr(?=[\\/\s"''`]|$)'
if ($cmdForPath -notmatch $pathPattern) {
    exit 0
}

# Path is mentioned. Is the command write-capable?
# Conservative list: any of these patterns + the forbidden path = block.
$writePatterns = @(
    # I/O redirection (with or without leading number for fd, e.g. 2>)
    '(?<![0-9])>\s',
    '(?<![0-9])>>\s',
    '(?<![0-9])>"',
    "(?<![0-9])>'",
    # PowerShell write cmdlets
    '\bOut-File\b',
    '\bSet-Content\b',
    '\bAdd-Content\b',
    '\bTee-Object\b',
    '\bExport-Csv\b',
    '\bExport-Clixml\b',
    # File manipulation
    '\bNew-Item\b',
    '\bRemove-Item\b',
    '\bCopy-Item\b',
    '\bMove-Item\b',
    '\bRename-Item\b',
    # POSIX file ops
    '\brm\s+',
    '\bmv\s+',
    '\bcp\s+',
    '\bmkdir\b',
    '\brmdir\b',
    '\btouch\s+',
    '\bdd\s+',
    # Shell built-ins (Windows)
    '\bdel\b',
    '\berase\b',
    # Heredocs / writes via tee/sed -i / awk -i
    '\btee\s+',
    '\bsed\s+-i\b',
    '\bawk\s+-i\b',
    # Editors that write
    '\bvim?\b',
    '\bnano\b',
    '\bemacs\b',
    # Git destructive / mutating
    'git\s+(commit|push|checkout|restore|reset|apply|rm|mv|pull|fetch|merge|rebase|stash|tag|cherry-pick|revert|clean|init|clone|add)\b',
    # gh mutating
    'gh\s+(pr|release|issue|repo|api).*-X\s+(POST|PUT|PATCH|DELETE)',
    'gh\s+(pr|release|issue)\s+(create|edit|delete|comment|merge|close|reopen|review)\b',
    # Package install / R writing
    '\binstall\.packages\b',
    '\bRscript\b'
)

$matched = $null
foreach ($pat in $writePatterns) {
    if ($cmd -match $pat) {
        $matched = $pat
        break
    }
}

if ($null -eq $matched) {
    # Path mentioned but no write pattern detected — assume read-only, allow.
    exit 0
}

[Console]::Error.WriteLine("BLOQUEADO: comando com efeito colateral em ../censobr nao permitido.")
[Console]::Error.WriteLine("")
[Console]::Error.WriteLine("Padrao detectado: $matched")
[Console]::Error.WriteLine("Comando: $cmd")
[Console]::Error.WriteLine("")
[Console]::Error.WriteLine("O diretorio ../censobr e somente leitura nesta sessao.")
[Console]::Error.WriteLine("Mudancas no consumidor 'censobr' devem ser feitas via PR")
[Console]::Error.WriteLine("no GitHub: https://github.com/ipea/censobr")
[Console]::Error.WriteLine("")
[Console]::Error.WriteLine("Operacoes read-only (cat, ls, grep, git log, gh release view, etc.)")
[Console]::Error.WriteLine("sao permitidas. Veja .claude/rules/scope.md.")
exit 2