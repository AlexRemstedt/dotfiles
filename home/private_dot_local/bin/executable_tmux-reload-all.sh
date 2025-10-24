#!/usr/bin/env bash

# Script to reload zsh in all tmux panes across all sessions

echo "⚠️  WARNING: This will execute 'exec zsh' in ALL tmux panes across ALL sessions."
echo "   Any running commands will be terminated!"
echo ""
echo "Sessions and panes that will be affected:"
tmux list-panes -a -F '  #{session_name}:#{window_index}.#{pane_index} - #{pane_current_command}'
echo ""
read -p "Do you want to continue? (y/N): " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo "Reloading zsh in all panes..."
  tmux list-panes -a -F '#{session_name}:#{window_index}.#{pane_index}' |
    xargs -I {} tmux send-keys -t {} 'exec zsh' Enter
  echo "✓ Done!"
else
  echo "Cancelled."
  exit 0
fi
