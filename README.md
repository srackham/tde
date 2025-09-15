# tde

A simple tmux-based text IDE.

## Installation

```
curl -L -o mknotes https://raw.githubusercontent.com/srackham/tde/main/tde
chmod +x tde
./tde --help
```

## Usage

```
NAME
    tde - open project workspaces with tmux

SYNOPSIS

        tde [OPTION...] [PROJECT_DIR...]

DESCRIPTION
    `tde` is a bash script that opens project directory workspaces in separate
    tmux windows. The number of tmux panes and optional launch commands can be
    specified per workspace window.

    The project directory workspaces are specified in optional configuration files
    and with commnand-line arguments.

    For each project workspace directory:

    1. A new tmux window name is generated from the project directory's base name
       minus its file name extension and with remaining period characters
       replaced with hyphens.
    3. A new tmux window is created with the newly generated window name and
       the window start directory set to the project directory.
    5. If PANES is greater than 1 then pane 1 is split vertically creating a
       second pane.
    6. If PANES is greater than 2 then panes 3..PANES are created by splitting
       pane 2 horizontally.
    7. The left-hand pane (pane 1) is selected.

    Finally the first newly created project window is selected and the session
    is attached.

OPTIONS
    --dry-run, -n
        Print tmux commands without doing anything.

    --help, -h
        Print this text.

    -c, --config CONFIG_FILE
        Specify the path of the configuration file.

    -l, --launch PANE:COMMAND
        Execute shell COMMAND in pane PANE of each project workspace window.
        PANE must be between 1 and the value specified by the --panes option.
        For example '3:lazyvim' executes the lazyvim command in pane 3.

    -p,--panes=PANES
        Open window with PANES panes. PANES is 1..9. Pane 1 is positioned on the
        left hand side of the enclosing window; panes 2..PANES are arranged
        vertically on the right hand side. This option value defaults 1.

    -s, --session SESSION_NAME
        Specify the tmux session name. The --session option determines the
        configuration file name, for example the '--session go-dev' command
        option would set configuration file name to 'go-dev.conf`. The default
        session name is 'tde'.

CONFIGURATION FILES
    The New Session Mode configuration file specifies a set of project workspace
    windows, one per line, formatted like:

        [OPTION...] PROJECT_DIR

    If only a PROJECT_DIR is specified then the options default to the
    command-line options. Blank lines and lines beginning with a `#` character
    are skipped.

    The following example configuration file line creates a tmux window with
    three panes in the ~/nixos-configurations working directory, the first pane
    runs nvim, the third pane runs lazygit:

        --panes 3 --launch 1:nvim --launch 3:lazygit ~/nixos-configurations

    The default configuration file path follows XDG Base Directory conventions:

        ${XDG_CONFIG_HOME:-$HOME/.config}/tde/tde.conf
```
