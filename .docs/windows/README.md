# Windows support plan

Getting a new Windows laptop productive with this repo. This documents the
recommended strategy and the concrete changes needed.

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
