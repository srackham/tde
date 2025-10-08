# tde

A simple tmux-based text IDE.

## Installation

Install [tmux](https://github.com/tmux/tmux/) if it is not already installed.

Download `tde` and the default tmux commands file:

```bash
mkdir -p ~/.local/bin
curl -L -o ~/.local/bin/tde https://raw.githubusercontent.com/srackham/tde/main/tde
chmod +x ~/.local/bin/tde
mkdir -p ~/.config/tde
curl -L -o ~/.config/tde/tde.tmux https://raw.githubusercontent.com/srackham/tde/main/tde.tmux
curl -L -o ~/.config/tde/monitor.tmux https://raw.githubusercontent.com/srackham/tde/main/monitor.tmux
curl -L -o ~/.config/tde/monitor.tde https://raw.githubusercontent.com/srackham/tde/main/monitor.tde
```

## Examples

TODO:

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

    One or more project workspace windows can be specified in configuration
    files or with command-line arguments. Workspace windows are assigned to a
    named tmux session (see --session-name option).

    For each project workspace directory:

        1. A new tmux window is created (see --window-name option).
        2. Any additional panes are created (see --panes option).
        3. The <session-name>.tmux file is sourced.
        4. The window --layout option is applied.
        5. The pane --launch options are applied.
        6. The focus pane is selected (see --focus option).

    The first newly created workspace window is selected and the session is
    attached to the client terminal.

    Explicit command-line options take precedence over configuration file
    options.

OPTIONS
     -n, --dry-run
        Print tmux commands without doing anything. '999' is a dummy value for
        tmux window index numbers.

    -h, --help
        Print this text.

    -f, --focus PANE
        Focus pane number PANE (1..PANES). The default value is 1.

    -l, --launch PANE:COMMAND
        Execute a shell COMMAND in pane PANE of each project workspace window.
        PANE must be between 1 and the value specified by the --panes option.
        For example '3:lazyvim' executes the lazyvim command in pane 3.

    -L, --layout LAYOUT
        Assigns a tmux layout to project workspace windows. The default LAYOUT
        value is `main-vertical`.

    -p,--panes PANES
        The minimum number of panes created in the tmux window. PANES is 1..9.
        This option value defaults to 1. The actual number of panes is either
        PANES or the maximum --launch options PANE number, whichever is greater.
        For example, the following sets of options will all generate three-pane
        windows:

            --launch 3:ls
            --panes 3
            --panes 2 --launch 3:ls
            --panes 3 --launch 1:nvim

    -s, --session-name SESSION_NAME
        Specify the tmux session name. The --session-name option determines the
        configuration file names, for example the '--session-name monitor' option
        would set configuration file names to 'monitor.tde' and 'monitor.tmux'.
        The default session name is 'tde'. SESSION_NAME must begin with an alpha
        numeric character and can only contain only alphanumeric characters,
        dashes, underscores, or periods.

    -w, --window-name WINDOW_NAME
        The tmux window name. Defaults to the project directory's base name
       minus its file name extension and with period characters
       replaced with hyphens.

    -v, --verbose
        Print informational messages and tmux commands.

CONFIGURATION FILES
    Each session has two optional configuration files: '<session-name>.tde' and
    '<session-name>.tmux'. The former contains tde project workspace window
    definitions, the latter contains tmux commands.

    The configuration files directory follows XDG Base Directory conventions:

        ${XDG_CONFIG_HOME:-$HOME/.config}/tde/

    <session-name>.tde files are sourced at session creation.
    <session-name>.tmux files contain tmux commands which are sourced at window
    creation.

    A <session-name>.tde configuration file specifies a set of project workspace
    windows, one per line, formatted like:

        [OPTION...] PROJECT_DIR

    The following tde options are valid in tde configuration files: --focus,
    --launch, --layout, --panes, --session-name, --window. Omitted option values
    default to their command-line values.

    The --session-name option can be used to create windows in other sessions;
    the session will be created if does not exist.

    Blank lines and lines beginning with a '#' character are skipped.

    The following example <session-name>.tde configuration file line creates a
    tmux window with three panes in the ~/nixos-configurations working
    directory. The first pane runs nvim, the third pane runs lazygit:

        --panes 3 --launch 1:nvim --launch 3:lazygit ~/nixos-configurations

    The next example creates a tmux window called 'monitor' with three vertical
    equal-width panes: pane 1 in the first column; pane 2 in the second; pane 3.
    The first pane is a shell prompt; the second runs htop; the third runs
    iotop:

        -p 3 -l 2:htop -l '3:sudo iotop' -w monitor -L even-horizontal ~

LAYOUTS
    tmux preset or custom layouts can be applied to project workspace windows
    with the --layout option (either on the command-line or in a tde
    configuration file).

    To create a custom tmux layout:

        1. Create the desired layout manually e.g. using tmux split horizontal
           (C-a %), split vertical (C-a "), spread panes evenly (C-a E) commands.
        2. Run the `tmux list-windows -F "#{window_layout}"` command to generate
           the custom layout; use this as the --layout option value.

    tmux automatically adjusts the size of the layout for the current window
    size.

    Additional tmux layout-related options can be included in tde .tmux
    configuration files.

    tmux layouts are documented in the tmux man page.

ENVIRONMENT VARIABLES
    TDE_CONFIG_DIR
        The configuration files directory.
```
