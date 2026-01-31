
# Apply terminal color theme on shell startup

SEQUENCES_FILE="$HOME/.local/state/quickshell/user/generated/terminal/sequences.txt"

# Bail if the theme file doesn't exist
[[ -f "$SEQUENCES_FILE" ]] || return

# Apply only to the current terminal
if [[ -n "$TTY" && -w "$TTY" ]]; then
  <"$SEQUENCES_FILE" > "$TTY"
fi

