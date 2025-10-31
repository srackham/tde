# tde

A tmux-based workspace-centric text windows manager.

## Installation

Install [tmux](https://github.com/tmux/tmux/) if it is not already installed.

Download `tde` and the default tmux commands file:

```bash
mkdir -p ~/.local/bin
curl -L -o ~/.local/bin/tde https://raw.githubusercontent.com/srackham/tde/main/tde
chmod +x ~/.local/bin/tde
mkdir -p ~/.config/tde
curl -L -o ~/.config/tde/tde.tmux https://raw.githubusercontent.com/srackham/tde/main/tde.tmux
```

## Examples

TODO:

## Usage

```
NAME
    tde - open workspaces with tmux

SYNOPSIS

        tde [OPTION...] [PROJECT_DIR...]

DESCRIPTION
    tde is a bash script that opens project directory workspaces, one workspace
    per tmux window. The number of tmux panes, each accompanied by optional
    launch commands, can be specified per workspace window.

    One or more project workspace windows can be specified using command-line
    arguments or in session configuration files. Workspace windows are
    assigned to a named tmux session (see --session option).

    For each project workspace directory:

        1. A new tmux window is created (see --window-name option).
        2. The optional tmux commands are sourced and executed (see
           TMUX COMMANDS FILE).
        3. Additional panes, if specified, are created (see --panes option).
        4. The window --layout option is applied.
        5. The pane --launch options are executed.
        6. The --focus option pane is selected.

    The first newly created workspace window is selected and the session is
    attached to the client terminal.

    If the session already exists then new workspace windows are appended to the
    existing set of windows.

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

    -s, --session SESSION
        Specify the tmux session name. The --session option also sets the
        configuration file names, for example '--session monitor' would set the
        session configuration file name to 'monitor.tde' and the tmux commands
        file name to 'monitor.tmux'. The default session name is 'tde'. SESSION
        must begin with an alpha numeric character and can only contain only
        alphanumeric characters, dashes, underscores, or periods.

    -t, --tmux-commands TMUX_COMMANDS
        This option sets the tmux commands file name. For example the
        '--tmux-commands red' option sets the tmux commands file name to
        'red.tmux' (see TMUX COMMANDS FILES). TMUX_COMMANDS must begin with an
        alpha numeric character and can only contain only alphanumeric
        characters, dashes, underscores, or periods.

    -w, --window-name WINDOW_NAME
        Sets the tmux workspace window name. Defaults to the project directory's
        base name stripped of its file name extension and with period characters
        replaced with hyphens.

    -v, --verbose
        Print informational messages and tmux commands.

CONFIGURATION FILES
    There are two types of configuration files: session configuration files and
    tmux commands files.

    Configuration files are optional. The configuration files default directory
    location is $HOME/.config/tde/. A custom configuration files directory can
    be specified with the TDE_CONFIG_DIR environment variable.

SESSION CONFIGURATION FILE
    Session configuration files contain tde workspace window definitions and are
    sourced and executed when the corresponding session is created.

    Session configuration file names match either the host name
    ('<host-name>.tde') or the session name ('<session-name>.tde'). The host
    name takes precedence over the session name.

    A session configuration file specifies a set of project workspace windows,
    one per line, formatted like:

        [OPTION...] PROJECT_DIR

    The following tde options are valid in tde configuration files: --focus,
    --launch, --layout, --panes, --window-name. Omitted option values default to
    their command-line values.

    Default option values can be assigned by setting PROJECT_DIR to '-'. The
    option values in lines with PROJECT_DIR set to '-' become the new default option
    values for subsequently created windows.

    Blank lines and lines beginning with a '#' character are skipped.

    The following example session> configuration file line creates a
    tmux window with three panes in the ~/nixos-configurations working
    directory. The first pane runs nvim, the third pane runs lazygit:

        --panes 3 --launch 1:nvim --launch 3:lazygit ~/nixos-configurations

    The next example creates a tmux window called 'monitor' with three vertical
    equal-width panes: pane 1 in the first column; pane 2 in the second; pane 3.
    The first pane is a shell prompt; the second runs htop; the third runs
    iotop:

        -p 3 -l 2:htop -l '3:sudo iotop' -w monitor -L even-horizontal ~

TMUX COMMANDS FILE
    A tmux command file contains tmux commands; they are sourced and executed by
    the tmux 'source-file' command after a session window is created (see the
    tmux(1) man page).

    Unless overridden by the --tmux-commands option, the tmux commands file name
    match either the host name ('<host-name>.tmux') or the session name
    ('<session-name>.tmux'). The host name takes precedence over the session
    name.

    tmux command file names must match either the host name ('<host-name>.tmux')
    or the tmux commands option ('<tmux-commands-option>.tmux'). The host name takes
    precedence over the tmux commands name.

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

    tmux layouts are documented in the tmux man(1) page.
```

## Tips

- Sessions can be built from multiple session configuration files using the same `--session` option.
- Use the shell `clear` command to create a null launch option, this is handy if you want to override the default launch options, for example, `--launch 1:clear`.
- Use the tmux `run-shell` to run shell commands synchronously from tmux commands files.
