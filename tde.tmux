# vim: set filetype=tmux:

# See X11 color names: https://www.w3schools.com/colors/default.asp
# 256 terminal colors: https://robotmoon.com/256-colors/

#
# tde tmux configuration
#

# Layout options
set-option main-pane-width 50%

# Set pane styles
set-option pane-border-lines heavy
set-option pane-border-style fg=color240
set-option pane-active-border-style fg=green

# Format status line
set-option status-left "#[bg=color227,bold] #{pane_index} "
set-option status-right  "#[bg=color227] #H #[bg=color190] %H:%M  %a %d %b %Y "

set-option status-style bg=green,fg=black
set-option window-status-current-style bg=color190,fg=black,bold
set-option window-status-format " #W:#I "
set-option window-status-current-format " #W:#I "

set-hook after-new-window {
  set-option window-status-current-style bg=color190,fg=black,bold
  set-option window-status-format ' #W:#I '
  set-option window-status-current-format ' #W:#I '
}
