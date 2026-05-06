# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Does

Chezmoi dotfiles repository for managing system configuration across multiple machines. Uses templating to support personal machines, work machines, and ephemeral systems. Automatically downloads and pins binary tools from GitHub releases. Integrates with 1Password for secret management.

## Core Concepts

**Machine detection** (`.chezmoi.toml.tmpl`): Hostname-based feature flags determine which configs apply. Default is ephemeral + headless. Set `$ephemeral = true|false`, `$work = true|false`, `$personal = true|false` to control what gets installed. Personal machines inferred from `AREMSTEDT` (personal) or `PLT5CD331HC4N` (work) hostnames.

**External tools** (`home/.chezmoiexternals/external.toml.tmpl`): Downloads binaries on `chezmoi apply`. Uses GitHub API to fetch latest releases. Arch detection handles x86_64/aarch64. Refresh periods (e.g., `720h`) control update frequency. Tools auto-pinned in `.local/bin/`.

**Templates**: Most files are `.tmpl` files evaluated with chezmoi's template engine. Can reference `{{ .chezmoi.* }}` (OS, arch, hostname, username) and `{{ .data.* }}` (custom data from `[data]` section in config).

## Common Commands

```sh
# Preview what will change (always do this first)
chezmoi diff

# Apply configuration to current machine
chezmoi apply

# Edit a dotfile directly (opens in $EDITOR, typically nvim)
chezmoi edit ~/.zshrc

# Re-run setup scripts and externals without touching configs
chezmoi apply --refresh-externals

# Check current machine's feature flags
chezmoi data
```

## Configuration Areas

**Shell** (`home/private_dot_config/zsh/`): zsh config split into:
- `conf.d/` — Individual config files (bindings, aliases, plugins, etc.)
- `plugin/` — Custom plugin definitions
- `aliases/` — Separate alias file

`sheldon` (plugin manager) defined in `home/private_dot_config/sheldon/`. Plugins auto-loaded on shell start.

**Terminal** (`home/private_dot_config/tmux/`): tmux config. TPM (tmux plugin manager) in `.local/share/tmux/plugins/tpm/` — auto-installed. Edit `tmux.conf`, then `tmux source-file ~/.tmux.conf` to reload.

**Git** (`home/private_dot_config/git/`): Config files split by purpose. Uses delta + diffsitter for diffs (auto-downloaded).

**Editor** (`home/.chezmoiexternals/nvim-config.toml.tmpl`): Neovim managed separately (likely LazyVim starter). Uses bob for version management (auto-downloaded in externals).

**Setup scripts** (`home/.chezmoiscripts/`): Named scripts run at apply time:
- `run_once_*` — Execute only on first apply (installs, one-time setup)
- `run_onchange_*` — Re-run if hash changes (detected via marker file)
- `run_before_*` / `run_after_*` — Hook into apply lifecycle

## Working With This Repo

**Editing dotfiles**: Use `chezmoi edit` to modify files. Changes are automatically staged + committed if `autoCommit = true` (it is). Note: `autoPush = false`, so push manually or set to true if you want auto-push.

**Adding a new tool**: Add entry to `home/.chezmoiexternals/external.toml.tmpl` with archive-file/file/git-repo type. Specify GitHub release URL pattern. Refresh period in hours. On next `chezmoi apply --refresh-externals`, it downloads and pins.

**Templating gotcha**: If a file needs to be templated, must be `.tmpl`. For example, `run_once_install-python-env.sh.tmpl` is templated to skip on ephemeral machines.

**Machine-specific behavior**: Check `{{ .ephemeral }}`, `{{ .work }}`, `{{ .personal }}` in templates. Wrap config blocks with `{{- if not .ephemeral -}}...{{- end }}` to skip on VMs/cloud instances.

**1Password integration**: Secrets fetched at apply time using `{{ onepasswordRead "op://vault/item/field" }}`. Requires `op` CLI in PATH and auth. Can reference custom vault + machine-specific paths (see config for examples).

## Architecture Notes

Single-machine flow: Edits via `chezmoi edit` → git auto-commit → re-apply to test. Multi-machine flow: Clone repo on new machine → `chezmoi init --apply <repo>` with feature flags set (or fix hostname) → externals auto-download.

Tools downloaded from GitHub: ~20 CLI tools (atuin, zoxide, fzf, eza, lazygit, delta, etc.) managed in externals. Ensures consistent versions across machines. Arch-aware download paths.

Don't edit files in `~/.config/` directly — chezmoi re-manages them on next apply. Always use `chezmoi edit` or edit in repo and re-apply.

## Machine-Specific Setup

Default behavior assumes ephemeral machine (no secrets, minimal install). To enable personal/work features:
- Work machine: Hostname must be `PLT5CD331HC4N` (or change condition in `.chezmoi.toml.tmpl`)
- Personal machine: Hostname must be `AREMSTEDT`
- If hostname doesn't match, manually set flags or change template condition

1Password vault selection is tied to machine type (`development` for personal, `work` for work).

## Installation/Reinitialization

Fresh machine:
```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply <github-username>
```

One-shot (no git needed):
```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --one-shot <github-username>
```

During `--apply`, setup scripts run (package install, externals download, symlinks). Set feature flags in env or via `chezmoi data --output json` inspection before first apply.
