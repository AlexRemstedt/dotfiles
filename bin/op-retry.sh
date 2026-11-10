#!/bin/sh
# Wrapper for the 1Password CLI used by chezmoi.
# The desktop app integration fails when calls come in quick succession.
# Retry a few times with a short pause before we give up.
set -u
op=/mnt/c/Users/ARem/AppData/Local/Microsoft/WinGet/Packages/AgileBits.1Password.CLI_Microsoft.Winget.Source_8wekyb3d8bbwe/op.exe
command -v op.exe >/dev/null 2>&1 && op=op.exe
max=8
n=1
while :; do
  err=$("$op" "$@" 2>&1 >&3 3>&-) 3>&1 && exit 0
  status=$?
  case $err in
    *"cannot connect to 1Password app"*) ;;
    *) printf '%s\n' "$err" >&2; exit "$status" ;;
  esac
  [ "$n" -ge "$max" ] && { printf '%s\n' "$err" >&2; exit "$status"; }
  n=$((n + 1))
  sleep 0.5
done
