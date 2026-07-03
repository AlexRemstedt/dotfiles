# Windows support plan

Getting a new Windows laptop productive with this repo. This documents the
recommended strategy and the concrete changes needed.

## Field research: how others do multi-OS chezmoi

Five public repos studied (2026-07). Three distinct patterns emerged.

### Pattern A — one tree, two applies (jwnmulder/dotfiles)

[jwnmulder/dotfiles](https://github.com/jwnmulder/dotfiles) targets Linux,
WSL2, *and* native Windows from a single `home/` root. `chezmoi init` runs
twice on a Windows laptop: once in PowerShell, once inside WSL. Separation
mechanics:

- **Blanket extension globs in `.chezmoiignore.tmpl`** do most of the work:

  ```
  {{ if ne .chezmoi.os "linux" }}
  **/*.sh
  {{ end }}
  {{ if ne .chezmoi.os "windows" }}
  **/*.bat
  **/*.ps1
  Documents
  AppData
  {{ end }}
  ```

- **`.chezmoiscripts/linux/` and `.chezmoiscripts/windows/`** — chezmoi
  runs scripts in subdirectories of `.chezmoiscripts`, and the extension
  globs above stop the wrong OS from running them. This gives the
  per-OS-directory layout for all setup scripts.
- **WSL detection**: `.chezmoi.kernel.osrelease | lower | contains
  "microsoft"` → `is_wsl` data flag. Also captures the Windows username
  from inside WSL (`cmd.exe /C echo %USERNAME%` — same trick as our
  `run_once_create_symlinks.sh`) into a `wsl.win_username` data value.
- **Profile by prompt, not hostname**: a `promptString` loop asks
  `personal/work1/work2` on first init, overridable via env var for CI.
- **Package lists as data**: `.chezmoidata/packages.yaml` holds
  `winget_packages` / `scoop_packages` / apt lists keyed `all` /
  `personal` / `work1`; `run_onchange` scripts consume them, so adding a
  package is a data edit, not a script edit.
- **`.ps1` interpreter config**: chezmoi needs `[interpreters.ps1]` in the
  config to execute PowerShell scripts, wrapped in `cmd /c` and preferring
  `pwsh.exe`.
- **Windows-side WSL config is managed by the *Windows* apply**:
  `.wslgconfig` lives in the Windows user profile, so the native apply owns
  it — a subtlety a WSL-only setup would miss.
- **OneDrive gotcha**: when Documents is OneDrive-redirected,
  `$HOME\Documents` isn't where PowerShell reads its profile; a
  `run_after` script detects the redirect and copies the profile over.

### Pattern B — WSL-only chezmoi that reaches across the boundary (felipecrs/dotfiles)

[felipecrs/dotfiles](https://github.com/felipecrs/dotfiles) never runs
chezmoi natively on Windows. One apply inside WSL configures *both* worlds
via interop:

- A top-level `windows/` dir (outside `.chezmoiroot = home`, so never a
  chezmoi target) holds Windows payloads: Windows Terminal settings and a
  PowerShell profile. This is the literal "windows stuff in its own dir"
  layout — possible precisely because those files are script *inputs*, not
  managed targets.
- `run_after_*-on-windows.sh.tmpl` scripts resolve the Windows home with
  `wslvar USERPROFILE` + `wslpath` (from the `wslu` package), then write
  into `AppData\Local\Packages\Microsoft.WindowsTerminal_.../LocalState`,
  install winget packages by calling `winget.exe` directly from WSL
  (even bootstrapping WinGet itself via `PowerShell.exe Add-AppxPackage`),
  and install Nerd Fonts.
- **Merge, don't overwrite**: Windows Terminal settings are patched by
  piping the live `settings.json` through
  `chezmoi execute-template --with-stdin` with a `modify_settings.json`
  template, writing back only if changed. Windows Terminal rewrites its own
  settings file, so a blind overwrite would fight it.

### Pattern C — native Windows in-tree (Jaykul, renemarc)

[Jaykul/dotfiles](https://github.com/Jaykul/dotfiles) manages
`AppData/Roaming/powershell/profile.ps1`, jj, and OBS config directly in
the source tree, with `.chezmoiignore` dropping `AppData` off-Windows and
`stat`-based conditions handling OneDrive-redirected Documents dirs.
[renemarc/dotfiles](https://github.com/renemarc/dotfiles) (the classic
cross-platform example) keeps Windows Terminal config under
`dot_config/windows_terminal/` and ignores it off-Windows.

### Deep dive: dir-per-OS chezmoi repos — verified, with mechanism

The hunch that dir-OS-structured chezmoi repos exist is correct. The
canonical example is
[shunk031/dotfiles](https://github.com/shunk031/dotfiles), which is
OS-directory-structured at every level — verified by cloning:

```
home/
├── .chezmoiscripts/
│   ├── common/                      run_once_*-install-mise.sh.tmpl, …
│   ├── macos/                       run_once_before_03-install-brew.sh.tmpl, …
│   └── ubuntu/                      run_once_10-install-docker.sh.tmpl, …
├── .chezmoitemplates/
│   ├── chezmoiignore.d/
│   │   ├── common
│   │   ├── macos
│   │   └── ubuntu/{common,client,server}
│   └── chezmoiexternal.d/
│       ├── common.yaml.tmpl
│       ├── macos.yaml.tmpl
│       └── ubuntu.yaml.tmpl
├── .chezmoiignore                   ← 12-line assembler (below)
├── .chezmoiexternal.yaml.tmpl       ← 8-line assembler (below)
└── dot_tmux.conf.d/os/…             ← per-OS fragments in the dotfiles too
```

The whole `.chezmoiignore` is just includes:

```
{{ template "chezmoiignore.d/common" . }}
{{ if eq .chezmoi.os "darwin" -}}
{{   template "chezmoiignore.d/macos" . }}
{{ else if eq .chezmoi.os "linux" -}}
{{   template "chezmoiignore.d/ubuntu/common" . }}
{{   if eq .system "client" -}}
{{     template "chezmoiignore.d/ubuntu/client" . }}
{{   end -}}
{{ end -}}
```

and likewise `.chezmoiexternal.yaml.tmpl`:

```
{{ template "chezmoiexternal.d/common.yaml.tmpl" . }}
{{ if eq .chezmoi.os "darwin" -}}
{{   template "chezmoiexternal.d/macos.yaml.tmpl" . }}
{{ else if (and (eq .chezmoi.os "linux") (eq .chezmoi.osRelease.idLike "debian")) -}}
{{   template "chezmoiexternal.d/ubuntu.yaml.tmpl" . }}
{{ else -}}
{{   fail (printf "Unknown OS for client system: %s" .chezmoi.os) }}
{{ end -}}
```

Why this works while a top-level `windows/` home-remap can't: files inside
`.chezmoiscripts/` and `.chezmoitemplates/` don't map to target paths, so
chezmoi is free to let you organize them in arbitrary — e.g. per-OS —
subdirectories. Regular dotfiles keep their 1:1 source→target mapping, and
the per-OS look there comes from conf.d-style fragments (e.g.
`.tmux.conf.d/os/ubuntu_client.conf`) with the other OS's fragments listed
in that OS's ignore file.

For literal per-OS *roots*, upstream is explicit that it's unsupported:
`.chezmoiroot` is deliberately not a template
([discussion #3083](https://github.com/twpayne/chezmoi/discussions/3083),
[#1433](https://github.com/twpayne/chezmoi/discussions/1433)); a "mapping
file" that would allow per-OS target relocation is a "maybe, someday" v3
idea. The accepted answers are separate repos, or the multi-instance
layering documented in
[discussion #2574](https://github.com/twpayne/chezmoi/discussions/2574):
several chezmoi instances with distinct `--source` + `--config` pairs
(e.g. `~/.local/share/chezmoi` + `~/.local/share/chezmoi.base`), the base
layer pulled in via `.chezmoiexternals` and applied from a `run_after`
script. Powerful, but two states to keep coherent — overkill for one
Windows laptop.

### Upstream note — twpayne/dotfiles

Our `.chezmoi.toml.tmpl` derives from
[twpayne/dotfiles](https://github.com/twpayne/dotfiles). Upstream has since
gained a fallback we should back-port: unknown hostname + interactive TTY →
`promptBoolOnce . "headless" "headless"` / `promptBoolOnce . "ephemeral"
"ephemeral"` instead of silently assuming ephemeral. (Upstream also treats
*native* Windows as ephemeral — consistent with WSL-first.)

### What this changes in our plan

1. **Adopt the shunk031 layout**: `.chezmoiscripts/{common,linux,windows}/`
   for scripts, `.chezmoitemplates/chezmoiignore.d/<os>` fragments assembled
   by a tiny `.chezmoiignore`, and — directly relevant to our monolithic
   `external.toml.tmpl` — `.chezmoitemplates/chezmoiexternal.d/<os>`
   fragments assembled by the externals file, with a `fail` for unknown
   OSes. Every OS-varying piece of machinery then lives in an OS-named
   directory.
2. **Adopt the merge-template trick** for Windows Terminal settings
   regardless of pattern — never blind-overwrite `settings.json`.
3. **Package lists move to `.chezmoidata/packages.yaml`** keyed by profile;
   works for apt today and winget later.
4. **Back-port `promptBoolOnce`** for unknown hostnames.
5. **Phase 2 has two viable shapes.** Start with **Pattern B** (Windows
   Terminal + winget configured from WSL `run_after` scripts, payloads in a
   real top-level `windows/` dir): it fits this repo's existing WSL lean
   (`op.exe`, `cmd.exe` symlinks), needs no second `chezmoi init`, and no
   `.ps1` interpreter plumbing. Graduate to **Pattern A** (second native
   apply managing `AppData/` + `Documents/`) only if the Windows side grows
   real config — PowerShell profile, `.wslgconfig`, scoop — beyond what
   interop scripts comfortably cover.

## Strategy: WSL2-first, thin native layer

The whole stack here (zsh, sheldon, tmux, nvim, the ~20 Linux binaries in
`.chezmoiexternals/`) runs unchanged inside WSL2 Ubuntu. The repo already
half-assumes this today:

- `run_once_create_symlinks.sh` calls `cmd.exe` and symlinks
  `/mnt/c/Users/<user>/Downloads` — this only makes sense on WSL.
- `.chezmoi.toml.tmpl` sets `[onepassword] command = "op.exe"` and
  `zsh/plugin/1password.zsh` aliases `op=op.exe` — that's the Windows
  1Password CLI invoked from WSL via interop.
- `run_onchange_before_install_packages.sh.tmpl` targets `linux-ubuntu`.

So the recommendation is **not** to port the dotfiles to native Windows.
Instead:

1. **WSL2 Ubuntu is the primary environment** — chezmoi runs inside WSL
   exactly as it does on any Linux box.
2. **A small native Windows layer** (optional, phase 2) for the few things
   that must live on the Windows side: Windows Terminal settings, a
   PowerShell profile, and a `winget` bootstrap script.

## Phase 1 — make the repo WSL-aware (required)

### 1. Detect WSL in `.chezmoi.toml.tmpl`

On WSL, `.chezmoi.kernel.osrelease` contains `microsoft`
(e.g. `5.15.167.4-microsoft-standard-WSL2`). Add a flag:

```
{{- $wsl := false -}}
{{- if and (eq .chezmoi.os "linux") (.chezmoi.kernel.osrelease | lower | contains "microsoft") -}}
{{-   $wsl = true -}}
{{- end -}}
```

and export it under `[data]` as `wsl = {{ $wsl }}`.

### 2. Guard the existing WSL-isms

- `run_once_create_symlinks.sh` → rename to `.tmpl`, wrap in
  `{{ if .wsl }}...{{ end }}` so it's a no-op on macOS/Linux.
- `[onepassword] command` → `{{ if $wsl }}op.exe{{ else }}op{{ end }}`.
- `zsh/plugin/1password.zsh` → template the alias the same way (or drop it
  and rely on the config value).

### 3. Hostname / machine detection

WSL inherits the Windows hostname by default, so the new laptop needs either:

- its hostname added to the conditions in `.chezmoi.toml.tmpl`, or
- (better long-term) switch to `promptBoolOnce` so a fresh machine asks
  `personal? work? ephemeral?` on first `chezmoi init` instead of relying on
  a hardcoded hostname list.

### 4. Guard externals and scripts by OS

`external.toml.tmpl` is only guarded by `not .ephemeral`. Add
`and (eq .chezmoi.os "linux")` (or `ne .chezmoi.os "windows"`) so a future
native-Windows `chezmoi apply` doesn't try to install Linux ELF binaries.
Same for `run_onchange_after_chsh.sh.tmpl` (already fine on WSL, breaks on
native Windows).

## Phase 2 — thin native Windows layer (optional)

Only if managing the Windows side from this repo turns out to be worth it.
Per the field research above, prefer starting with Pattern B (WSL interop
scripts + top-level `windows/` payload dir) and treat everything below —
the native-apply layout — as the Pattern A graduation path.

### Layout: OS worlds as separate directories

A literal top-level `windows/` + `linux/` split is not possible in chezmoi:
source paths map 1:1 onto target paths under `$HOME` (a source file
`windows/foo.ps1` would be created at `~/windows/foo.ps1`), and
`.chezmoiroot` is read before templating so it cannot vary per OS. Setups
with real per-OS top-level dirs are either two separate repos or
symlink-based managers (stow, bare git).

The chezmoi-idiomatic equivalent gets the same separation because Windows
keeps its config under `AppData/` and `Documents/` — directories under
`$HOME` — while unix config lives under `.config/`. One templated
`.chezmoiignore` enforces the split:

```
home/
├── .chezmoiignore.tmpl          ← the per-OS gate
├── private_dot_config/…         ← Linux/WSL world
├── private_dot_local/…          ← Linux/WSL world
├── dot_zshenv                   ← Linux/WSL world
├── AppData/…                    ← Windows world (Windows Terminal settings)
├── Documents/PowerShell/…       ← Windows world (PowerShell profile)
└── .chezmoiscripts/
    ├── run_once_*.sh.tmpl       ← guarded by .osid / .wsl
    └── run_once_*.ps1.tmpl      ← Windows-only
```

Everything else stays shared: one repo, one `chezmoi init`, one
`.chezmoi.toml.tmpl` whose feature flags and 1Password data feed both
worlds' templates. That sharing is the main advantage over a two-repo
split.

### Pieces

- **`.chezmoiignore`** (templated): ignore all unix config on
  `windows`, ignore windows files elsewhere:

  ```
  {{ if eq .chezmoi.os "windows" }}
  .config/**
  .local/**
  .zshenv
  {{ else }}
  AppData/**
  Documents/**
  {{ end }}
  ```

- **Windows Terminal**: `AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json`
  is under `$HOME`, so chezmoi can manage it directly (set WSL/Ubuntu as the
  default profile, font, colorscheme).
- **PowerShell profile**: `Documents/PowerShell/Microsoft.PowerShell_profile.ps1`
  — minimal: starship init, a few aliases.
- **winget bootstrap**: `run_once_install-packages.ps1.tmpl` guarded by
  `eq .chezmoi.os "windows"` installing e.g. `Microsoft.WindowsTerminal`,
  `AgileBits.1Password`, `AgileBits.1Password.CLI`, `Git.Git`,
  `Microsoft.PowerShell`. Chezmoi runs `.ps1` scripts natively on Windows.

This means running `chezmoi init` twice on the laptop — once in PowerShell
(native, thin layer) and once inside WSL (full environment). The
`.chezmoiignore` templating keeps the two from stepping on each other.

## New laptop bootstrap (manual steps before chezmoi)

1. `wsl --install -d Ubuntu` (from an elevated PowerShell), reboot, create
   the unix user.
2. Install 1Password for Windows, sign in, enable **Settings → Developer →
   CLI integration** (this is what makes `op.exe` work from WSL with
   biometric/Windows Hello auth).
3. Inside WSL:

   ```sh
   sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply $GITHUB_USERNAME
   ```

4. (Phase 2) In PowerShell: `winget install twpayne.chezmoi` then
   `chezmoi init --apply $GITHUB_USERNAME` for the native layer.

## Explicitly not recommended

- Porting zsh/tmux/sheldon config to native Windows equivalents — high
  effort, worse result than WSL2.
- Git Bash / Cygwin / MSYS2 as the primary shell — WSL2 is strictly better
  for this setup.
