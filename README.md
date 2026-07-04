# Dofiles
Dotfiles managed by chezmoi.

First, make sure the 1Password CLI (`op`) is on your `PATH`, since secrets are fetched at apply time:

```sh
command -v op >/dev/null 2>&1 || echo "op is not on PATH; install the 1Password CLI first"
```

## Installing the 1Password CLI

On WSL (Debian/Ubuntu), install `op` from 1Password's apt repository:

```sh
# Add the key and repository
curl -sS https://downloads.1password.com/linux/keys/1password.asc \
  | sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" \
  | sudo tee /etc/apt/sources.list.d/1password.list

# Add the debsig verification policy
sudo mkdir -p /etc/debsig/policies/AC2D62742012EA22/
curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol \
  | sudo tee /etc/debsig/policies/AC2D62742012EA22/1password.pol
sudo mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22
curl -sS https://downloads.1password.com/linux/keys/1password.asc \
  | sudo gpg --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg

# Install
sudo apt update && sudo apt install 1password-cli
```

Verify and sign in:

```sh
op --version
op signin
```

> On WSL you can also drive the CLI through the Windows 1Password desktop app
> (biometric unlock, no separate WSL sign-in). Enable **Settings → Developer →
> Integrate with 1Password CLI** in the Windows app. See the
> [1Password CLI docs](https://developer.1password.com/docs/cli/get-started/)
> for other platforms.

Then install in one line by running the following command in your terminal:

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply $GITHUB_USERNAME
```

For shortlived one-shot configurations, use:

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --one-shot $GITHUB_USERNAME
```
