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
    tde - open project workspaces

SYNOPSIS
    New Session Mode: Create 'tde' tmux session and add project workspace windows from the
    configuration file:

        tde [OPTION...]

    Current Session Mode: Add project workspace windows to the current tmux session:

        tde [OPTION...] PROJECT_DIR...

OPTIONS
    --dry-run, -n
        print tmux commands without doing anything.

    --help, -h
        print this text.

    -c, --config CONFIG_FILE
        Specify the path of the configuration file overriding the default configuration file path
        and the TDE_CONFIG_FILE environment variable.

    -l, --launch PANE:COMMAND
        Execute shell COMMAND in pane PANE of each project workspace window. PANE must be between 1
        and the value specified by the --panes option.

    -p,--panes=PANES
        Open window with PANES panes. PANES is 1..9. Pane 1 is positioned on the left hand side of
        the enclosing window; panes 2..PANES are arranged vertically on the right hand side. This
        option value defaults 1.

    -s, --session SESSION_NAME
        Specify the tmux session name. The --session option also sets the configuration file name,
        for example the '--session go-dev' command option would set configuration file name to
        'go-dev.conf`. The default session name is 'tde'.

DESCRIPTION
    `tde` is a bash script that opens project directory workspaces in separate tmux windows. The
    script has two modes of operation:

    New Session Mode:

        If no project directories are specified on the command-line a tmux session named `tde` is
        created and project workspace windows are added from the list of directories read from the
        configuration file.

    Current Session Mode:

        Project workspace windows are added, one per project directory, to current tmux session.

    For each project directory:

    1. A new window name is generated from the project directory's base name minus its file name extension
       and with remaining period characters replaced with hyphens.
    2. If a tmux window with the same name already exists in the target session then print a warning and
       skip to the next project directory.
    3. A new tmux window is created with the newly generated window name and the window start directory
       set to the project directory.
    5. If PANES is greater than 1 then pane 1 is split vertically creating a second pane.
    6. If PANES is greater than 2 then panes 3..PANES are created by splitting pane 2 horizontally
       PANES - 2 times.
    7. The left-hand pane (pane 1) is selected.

    Finally the first newly created project window is selected and, if `tde` was executed in New Session
    Mode, the `tde` session is attached.

CONFIGURATION FILE
    The New Session Mode configuration file specifies a set of project workspace windows, one per
    line, formatted like:

        [OPTION...] PROJECT_DIR

    The default configuration file path follows XDG Base Directory conventions:

        ${XDG_CONFIG_HOME:-$HOME/.config}/tde/tde.conf

    The environment variable TDE_CONFIG_FILE can be used to override the default configuration
    file path.

    If only a PROJECT_DIR is specified then the options default to the command-line options.
    Blank lines and lines beginning with a `#` character are skipped.
```
