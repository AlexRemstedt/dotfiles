# GlazeWM

[repo](https://github.com/glzr-io/glazewm)

A tiling window manager for Windows, inspired by i3 and Polybar. This is the
only Windows-only config in the repo, so it is gated to Windows in
`home/.chezmoiignore` and won't be applied on Linux/WSL.

## Installation

### Scoop

```powershell
scoop install glazewm
```

### Winget

```powershell
winget install glzr-io.glazewm
```

## Configuration

The config lives at `~/.glzr/glazewm/config.yaml`
(`home/dot_glzr/glazewm/config.yaml` in this repo). On a fresh Windows machine:

```powershell
chezmoi init --apply AlexRemstedt/dotfiles
```

Reload the config after edits with `alt+shift+r` (or `wm-reload-config`).

### Zebar

The `startup_commands` launch [Zebar](https://github.com/glzr-io/zebar) as the
status bar. It ships with GlazeWM, so no separate install is needed.
