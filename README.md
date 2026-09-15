# Dotfiles

Dotfiles managed by chezmoi.

## Installation

Then install in one line by running the following command in your terminal:

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply AlexRemstedt
```

For shortlived one-shot configurations, use:

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --one-shot AlexRemstedt
```

On Windows, run the equivalent from a PowerShell prompt:

```powershell
iex "&{$(irm 'https://get.chezmoi.io/ps1')} -- init --apply AlexRemstedt"
```

For shortlived one-shot configurations, use:

```powershell
iex "&{$(irm 'https://get.chezmoi.io/ps1')} -- init --one-shot AlexRemstedt"
```

### Install chezmoi

#### Linux

```sh
sh -c "$(curl -fsLS get.chezmoi.io)"
```

#### MacOS

```sh
# macOS
brew install chezmoi
```

#### Windows

```sh
# Windows
winget install twpayne.chezmoi
```

> [!note] First, make sure the 1Password CLI (`op`) is on your `PATH`, since secrets
> are fetched at apply time. Check out the [./docs/op.md](./docs/op.md)
> section below for more details.
