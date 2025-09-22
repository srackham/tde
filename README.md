# tde

A simple tmux-based text IDE.

## Installation

```
curl -L -o tde https://raw.githubusercontent.com/srackham/tde/main/tde
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
    tde is a bash script that opens project directory workspaces in separate
    tmux windows. The number of tmux panes and optional launch commands can be
    specified per workspace window.

    The project directory workspaces can be specified in optional configuration
    files or with commnand-line arguments.

    For each project workspace directory:

        1. A new tmux window is created (see --window-name option).
        2. The window is split into columns (see --columns option).
        3. If PANES is greater than COLUMNS then remaining panes are
           stacked vertically in the right-hand column.
        4. The focus pane is selected (see --focus option).

    The first newly created project window is selected and the session
    is attached to the client terminal.

OPTIONS
     -n, --dry-run
        Print tmux commands without doing anything. '999' is a dummy value for
        tmux window index numbers.

    -h, --help
        Print this text.

    -c, --config-file CONFIG_FILE
        Specify the path of a tde configuration file. If this option is not
        specified tde sources the optional '_default.conf' file followed by the
        optional '<session-name>.conf' file from the configuration files
        directory. See CONFIGURATION FILES.

    -f, --focus PANE
        Focus pane number PANE (1..PANES). The default value is 1.

    -l, --launch PANE:COMMAND
        Execute a shell COMMAND in pane PANE of each project workspace window.
        PANE must be between 1 and the value specified by the --panes option.
        For example '3:lazyvim' executes the lazyvim command in pane 3.

    -p,--panes PANES
        The number of panes created in the tmux window. PANES is 1..9. This
        option value defaults to 1. See also the --columns option.

    -s, --session SESSION_NAME
        Specify the tmux session name. The --session option determines the
        configuration file name, for example the '--session go-dev' command
        option would set configuration file name to 'go-dev.conf'. The default
        session name is 'tde'. SESSION_NAME must begin with an alpha numberic
        character and can only contain only alphanumeric characters, dashes,
        underscores, or periods.

    -w, --window-name WINDOW_NAME
        The tmux window name. Defaults to the project directory's base name
       minus its file name extension and with period characters
       replaced with hyphens.

    -x, --columns COLUMNS
        Split the tmux window into COLUMNS columns. COLUMNS is between 1 and
        PANES. The default option value is 1 (if PANES=1) or 2 (if PANES is 2 or
        greater).

    -v, --verbose
        Print tmux commands.

CONFIGURATION FILES
    A tde configuration file specifies a set of project workspace windows, one
    per line, formatted like:

        [OPTION...] PROJECT_DIR

    The following tde options are valid in configuration files: --focus,
    --launch, --panes, --window-name, --columns. Omitted option values default
    to their command-line values.

    Blank lines and lines beginning with a '#' character are skipped.

    The default configuration files directory follows XDG Base Directory
    conventions:

        ${XDG_CONFIG_HOME:-$HOME/.config}/tde/

    The following example configuration file line creates a tmux window with
    three panes in the ~/nixos-configurations working directory. The first pane
    runs nvim, the third pane runs lazygit:

        --panes 3 --launch 1:nvim --launch 3:lazygit ~/nixos-configurations

    The next example creates a tmux window called 'monitor' with four panes
    layed out in three columns: pane 1 in the first column; pane 2 in the
    second; panes 3 and 4 in the third. The first is a terminal; the second runs
    htop; the third runs iotop; the fourth runs nethogs:

        -x 3 -p 4 -l 2:htop -l '3:sudo iotop' -l '4:sudo nethogs' -w monitor ~
```
