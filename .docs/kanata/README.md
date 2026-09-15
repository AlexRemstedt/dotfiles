# Kanata

[repo](https://github.com/jtroo/kanata)

A cross-platform keyboard remapper. Like GlazeWM, this is Windows-only in
this repo (gated in `home/.chezmoiignore`) — the config here implements home
row mods: tapping caps locks acts as Escape, and `a s d f` / `j k l ;` act as
modifiers (`meta alt shift ctrl`, mirrored on both hands) when held.

## Installation

Kanata isn't packaged for winget/scoop; grab it directly from
[releases](https://github.com/jtroo/kanata/releases). Pick the `x64` or
`arm64` zip matching your CPU — the release also offers a `tty` vs `gui`
build and a `winIOv2` vs `wintercept` keyboard-hook driver; `winIOv2` needs
no extra driver install and is the simpler default. Unzip and you have a
single `kanata.exe`, no installer.

## Configuration

The config lives at `~/.config/kanata.kbd`
(`home/private_dot_config/kanata.kbd` in this repo).

Run it pointed at that config:

```powershell
kanata.exe --cfg $env:USERPROFILE\.config\kanata.kbd
```

## Administrator privileges

Kanata's default Windows backend (`WH_KEYBOARD_LL`) can't intercept input for
windows running elevated (e.g. an admin terminal) unless kanata itself is
also running elevated. Since most terminals in this setup (Windows Terminal,
PowerShell) may run elevated, run kanata as administrator.

To have it start automatically with admin rights at login, use Task
Scheduler with an "At log on" trigger and "Run with highest privileges"
enabled — a plain Startup-folder shortcut won't auto-elevate. See the
[kanata autostart guide](https://rpnfan.github.io/keyboard-heaven/how-to/kanata-autostart-windows/)
for the exact steps.
