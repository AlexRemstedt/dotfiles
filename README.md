# Dofiles
Dotfiles managed by chezmoi. Install in one line by running the following command in your terminal:

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply $GITHUB_USERNAME
```

For shortlived one-shot configurations, use:

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --one-shot $GITHUB_USERNAME
```

## Windows

On a fresh Windows host, run the bootstrap script from an elevated PowerShell
prompt to install WSL and the Windows-side apps (PowerToys, kanata, GlazeWM,
Obsidian):

```powershell
powershell -ExecutionPolicy Bypass -File .\windows-install.ps1
```

Then bootstrap the dotfiles from inside WSL using the command above.
