#!/bin/bash
WINDOWS_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')
ln -sf "/mnt/c/Users/$WINDOWS_USER/Downloads" "$HOME/downloads"
