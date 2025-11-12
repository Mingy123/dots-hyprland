# Auto start Hyprland on tty1
if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" -eq 1 ]; then
  exec Hyprland > ~/.cache/hyprland.log 2>&1
fi
