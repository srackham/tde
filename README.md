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
    New Session Mode: Create 'tde' tmux session and add project workspace windows from the `$HOME/.tde` configuration file:

        tde [OPTION...]

    Current Session Mode: Add project workspace windows to the current tmux session:

        tde [OPTION...] PROJECT_DIR...

OPTIONS
    --dry-run, -n   print tmux commands without doing anything
    --help, -h      print this text

DESCRIPTION
    `tde` is a bash script which opens project directory workspaces in separate tmux windows. Each
    window has two tmux panes with the Neovim editor in the left hand pane and a terminal in the right
    hand pane. The script has two modes of operation:

    New Session Mode: If no project directories are specified on the command-line a tmux session named
    `tde` is created and project workspace windows are added from the list of directories read from the
    `$HOME/.tde` configuration file.

    Current Session Mode: If project directories are specified on the command-line then project
    workspace windows are added to current tmux session.

    The `$HOME/.tde` configuration file contains a list of project directories, one per line. Blank
    lines and lines beginning with a `#` character are skipped.

    For each project directory:

    1. A new window name is generated from the project directory's base name minus its file name extension
       and with remaining period characters replaced with hyphens.
    2. If a tmux window with the same name already exists in the target session then print a warning and
       skip to the next project directory.
    3. A new tmux window is created with the newly generated window name and the window start directory
       set to the project directory.
    4. The window is split into two vertical panes.
    5. The 'nvim' command is executed in the left-hand pane.
    6. The left-hand pane is selected.

    Finally the first newly created project window is selected and if `tde` was executed in New Session
    Mode the `tde` session is attached.
```
