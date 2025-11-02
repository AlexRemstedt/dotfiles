#!/usr/bin/zsh

if [[ -z "$NVIM_CONFIG_HOME" ]]; then
  echo "Error: NVIM_CONFIG_HOME is not set."
  exit 1
fi

git -C "$NVIM_CONFIG_HOME" fetch --all || exit 1
git -C "$NVIM_CONFIG_HOME" pull || exit 1
nvim --headless "+Lazy! sync" +qa || exit 1
git -C "$NVIM_CONFIG_HOME" add lazy-lock.json lazyvim.json

if git -C "$NVIM_CONFIG_HOME" diff --cached --quiet; then
  echo "No changes to commit"
else
  git -C "$NVIM_CONFIG_HOME" commit -m "chore: update lock-file" && \
  git -C "$NVIM_CONFIG_HOME" push || echo "Failed to update nvim config"
fi
