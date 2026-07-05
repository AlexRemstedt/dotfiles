# Dotfiles
Dotfiles managed by chezmoi.

First, make sure the 1Password CLI (`op`) is on your `PATH`, since secrets are fetched at apply time:

```sh
command -v op >/dev/null 2>&1 || echo "op is not on PATH; install the 1Password CLI first"
```

## 1Password CLI on WSL

On WSL, don't install a separate Linux `op` — reuse the one from the Windows
1Password app. In the Windows desktop app enable **Settings → Developer →
Integrate with 1Password CLI** so `op.exe` can unlock via the app, then expose
it to WSL as `op`:

```sh
# op.exe must be on your Windows PATH (winget installs it there by default)
mkdir -p ~/.local/bin
ln -sf "$(command -v op.exe)" ~/.local/bin/op
```

Make sure `~/.local/bin` is on your `PATH`, then verify:

```sh
op --version
op signin
```

See the [1Password CLI docs](https://developer.1password.com/docs/cli/get-started/)
for other platforms.

Then install in one line by running the following command in your terminal:

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply $GITHUB_USERNAME
```

For shortlived one-shot configurations, use:

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --one-shot $GITHUB_USERNAME
```
