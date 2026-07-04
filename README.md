# Dofiles
Dotfiles managed by chezmoi.

First, make sure the 1Password CLI (`op`) is on your `PATH`, since secrets are fetched at apply time:

```sh
command -v op >/dev/null 2>&1 || echo "op is not on PATH; install the 1Password CLI first"
```

Then install in one line by running the following command in your terminal:

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply $GITHUB_USERNAME
```

For shortlived one-shot configurations, use:

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --one-shot $GITHUB_USERNAME
```
