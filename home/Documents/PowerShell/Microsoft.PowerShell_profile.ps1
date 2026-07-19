# Sensible PowerShell profile.
#
# Mirrors the ergonomics of the zsh setup (starship prompt, zoxide, eza, a
# curated set of git aliases, emacs-style line editing, UTF-8 everywhere) so
# that a Windows shell feels the same as the *nix ones. Everything that depends
# on an external tool is guarded, so this profile stays quiet on a bare box.

#region Helpers

# True when the named command resolves to something runnable.
function Test-Command {
    param([Parameter(Mandatory)] [string] $Name)
    [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

#endregion

#region Environment

# UTF-8 for both input and output so unicode (glyphs in prompts, eza icons,
# git output) renders correctly regardless of the console code page.
[Console]::InputEncoding = [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
$OutputEncoding = [System.Text.UTF8Encoding]::new()

# Prefer nvim, fall back to vim, then Notepad. Matches the zsh EDITOR logic.
$editor = @('nvim', 'vim', 'notepad') | Where-Object { Test-Command $_ } | Select-Object -First 1
$env:EDITOR = $editor
$env:VISUAL = $editor
$env:GIT_EDITOR = $editor

# Keep starship's cache out of the way, matching the zsh config.
if (-not $env:STARSHIP_CACHE) {
    $env:STARSHIP_CACHE = Join-Path $env:LOCALAPPDATA 'starship'
}

#endregion

#region PSReadLine — line editing that behaves like zsh

if (Get-Module -ListAvailable -Name PSReadLine) {
    Import-Module PSReadLine

    Set-PSReadLineOption -EditMode Emacs
    Set-PSReadLineOption -BellStyle None
    Set-PSReadLineOption -HistoryNoDuplicates
    Set-PSReadLineOption -HistorySearchCursorMovesToEnd

    # Tab cycles through completions in a menu instead of the default expand.
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete

    # Up/Down search history by the text already typed (history-beginning-search).
    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

    # Ctrl+P / Ctrl+N mirror the zsh history-substring-search bindings.
    Set-PSReadLineKeyHandler -Key Ctrl+p -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key Ctrl+n -Function HistorySearchForward

    # Inline autosuggestions from history (PSReadLine 2.2+ / PowerShell 7.2+).
    try {
        Set-PSReadLineOption -PredictionSource History
        Set-PSReadLineOption -PredictionViewStyle ListView
    } catch {
        # Older PSReadLine without prediction support — ignore.
    }
}

#endregion

#region Navigation & small utilities

function .. { Set-Location .. }
function ... { Set-Location ../.. }
function .... { Set-Location ../../.. }
function ..... { Set-Location ../../../.. }

# `cd` into the repo root, like the zsh `grt` alias.
function grt {
    $root = git rev-parse --show-toplevel 2>$null
    if ($root) { Set-Location $root } else { Write-Warning 'Not inside a git repository.' }
}

# mkdir + cd in one step.
function mkcd {
    param([Parameter(Mandatory)] [string] $Path)
    New-Item -ItemType Directory -Force -Path $Path | Out-Null
    Set-Location $Path
}

# touch: create an empty file or bump its timestamp.
function touch {
    param([Parameter(Mandatory)] [string] $Path)
    if (Test-Path $Path) {
        (Get-Item $Path).LastWriteTime = Get-Date
    } else {
        New-Item -ItemType File -Path $Path | Out-Null
    }
}

# `which` for people who forget it is Get-Command here. Returns the executable
# path for applications, or the definition (alias target / function body) for
# everything else — `Source` alone is empty for prompt-defined functions.
function which {
    param([Parameter(Mandatory)] [string] $Name)
    $cmd = Get-Command $Name -ErrorAction SilentlyContinue
    if ($cmd) { if ($cmd.Path) { $cmd.Path } else { $cmd.Definition } }
}

# Reload this profile without restarting the shell.
function reload { . $PROFILE }

#endregion

#region Listing — eza when available, sensible fallbacks otherwise

if (Test-Command eza) {
    function ls   { eza @args }
    function ll   { eza -lh @args }
    function l    { eza -al @args }
    function la   { eza -a @args }
    function lla  { eza -alh @args }
    function tree { eza --tree @args }
} else {
    function ll { Get-ChildItem @args }
    function la { Get-ChildItem -Force @args }
}

# `cat` with syntax highlighting when bat is around.
if (Test-Command bat) {
    function cat { bat -pp @args }
}

#endregion

#region Git — a curated slice of the zsh git aliases

function g    { git @args }
function ga   { git add @args }
function gaa  { git add --all @args }
function gap  { git add --patch @args }
function gst  { git status @args }
function gss  { git status --short @args }
function gsb  { git status --short --branch @args }
function gc   { git commit --verbose @args }
function gcmsg { git commit --message @args }
function 'gc!' { git commit --verbose --amend @args }
function gcn  { git commit --verbose --no-edit @args }
function gco  { git checkout @args }
function gcb  { git checkout -b @args }
function gsw  { git switch @args }
function gswc { git switch --create @args }
function gb   { git branch @args }
function gba  { git branch --all @args }
function gbd  { git branch --delete @args }
function gd   { git diff @args }
function gds  { git diff --staged @args }
function gdca { git diff --cached @args }
function gf   { git fetch @args }
function gfa  { git fetch --all --tags --prune @args }
function gl   { git pull @args }
function gpr  { git pull --rebase @args }
function gp   { git push @args }
function gpf  { git push --force-with-lease --force-if-includes @args }
function gpsup { git push --set-upstream origin (git branch --show-current) @args }
function glo  { git log --oneline --decorate @args }
function glog { git log --oneline --decorate --graph @args }
function gloga { git log --oneline --decorate --graph --all @args }
function grh  { git reset @args }
function grhh { git reset --hard @args }
function grb  { git rebase @args }
function grbi { git rebase --interactive @args }
function grba { git rebase --abort @args }
function grbc { git rebase --continue @args }
function gsta { git stash push @args }
function gstp { git stash pop @args }
function gstl { git stash list @args }
function gm   { git merge @args }
function gcl  { git clone --recurse-submodules @args }

# Lazygit gets a short alias too.
if (Test-Command lazygit) { function lg { lazygit @args } }

#endregion

#region 1Password

# The zsh config aliases `op` to the Windows CLI; keep parity here.
if (Test-Command op.exe) { Set-Alias -Name op -Value op.exe -Scope Global }

#endregion

#region Tool integrations — loaded last, only when present

# zoxide: smarter `cd`. Provides `z` and `zi`.
if (Test-Command zoxide) {
    Invoke-Expression (& { (zoxide init powershell | Out-String) })
}

# fzf key bindings via PSFzf (the fzf binary has no PowerShell init flag; the
# module is what wires up Ctrl+T for files and Ctrl+R for history).
if ((Test-Command fzf) -and (Get-Module -ListAvailable -Name PSFzf)) {
    Import-Module PSFzf
    Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
}

# starship prompt — kept last so it owns the prompt function.
if (Test-Command starship) {
    Invoke-Expression (& { (starship init powershell) -join "`n" })
}

#endregion
