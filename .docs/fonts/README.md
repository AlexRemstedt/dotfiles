# Fonts

This setup standardizes on **JetBrainsMono Nerd Font** for development. A
[Nerd Font](https://www.nerdfonts.com/) is required because several tools in
this repo render glyph icons that a regular monospace font doesn't have:
LazyVim (nvim), starship, and eza all assume one is on the system.

## Windows

```powershell
winget install --id DEVCOM.JetBrainsMonoNerdFont
```

or via [Scoop](https://scoop.sh):

```powershell
scoop bucket add nerd-fonts
scoop install JetBrainsMono-NF
```

Set it as the font in Windows Terminal (already done for the WSL profile by
the fragment in [`.docs/windows-terminal`](../windows-terminal/README.md)) and
in any other app you use — PowerShell ISE, VS Code, etc.

## Linux / WSL

```sh
# Arch
sudo pacman -S ttf-jetbrains-mono-nerd

# Debian/Ubuntu — no package, install manually
mkdir -p ~/.local/share/fonts
curl -fLo /tmp/JetBrainsMono.zip \
  https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
unzip -o /tmp/JetBrainsMono.zip -d ~/.local/share/fonts
fc-cache -f
```

## macOS

```sh
brew install --cask font-jetbrains-mono-nerd-font
```
