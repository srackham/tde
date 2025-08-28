# Project: tde

## Project Overview

`tde` is a bash script designed to function as a simple tmux-based text IDE. Its primary purpose is to streamline the process of opening project workspaces within separate tmux windows. It supports two modes of operation: creating a new `tde` tmux session or adding windows to the current tmux session. Project directories are configured via the `$HOME/.tde` file. The default editor launched in the first pane of each new window is `nvim`.

**Key Technologies:**
*   **Bash:** The core scripting language.
*   **tmux:** Terminal multiplexer used for managing sessions, windows, and panes.
*   **nvim:** The default text editor launched in project panes.

## Building and Running

### Installation

To install `tde`, download the script and make it executable:

```bash
curl -L -o tde https://raw.githubusercontent.com/srackham/tde/main/tde
chmod +x tde
```

### Usage

Run the script from the command line:

```bash
./tde [OPTION...] [PROJECT_DIR...]
```

Refer to `./tde --help` for a detailed list of options and their descriptions.

### Testing

There are no explicit unit tests for this project. Basic functionality can be verified by running the help command:

```bash
./tde --help
```

And checking the output for correctness.

## Development Conventions

### Code Style

*   **Shebang and Strict Mode:** Scripts start with `#!/usr/bin/env bash` and use `set -euo pipefail` for robust error handling.
*   **Function Naming:** Use clear, descriptive names (e.g., `print_help`, `tmux_cmd`).
*   **Variable Scope:** Prefer `local` variables within functions.
*   **Conditionals:** Use double brackets `[[ ... ]]` for conditional expressions.
*   **Data Structures:** Use arrays for lists (e.g., `PROJECT_DIRS=()`).
*   **Indentation:** Consistent 4-space indentation.
*   **Comments:** Use comments to explain complex logic.
*   **Error Output:** Error messages should be directed to `stderr`.
*   **General Output:** Use `echo` for standard output and warnings.
*   **Global Variables:** Avoid global variables unless absolutely necessary.

### Naming Conventions

*   **Variables and Functions:** Use lowercase with underscores (e.g., `my_variable`, `my_function`).
*   **Constants:** Use uppercase (e.g., `DRY_RUN`, `PANES`).

### Error Handling

*   **Exit on Error:** The script is configured to exit immediately upon encountering an error (`set -e`).
*   **Error Messages:** Print informative error messages to `stderr`.
*   **Input Validation:** Strictly validate all user inputs and command-line parameters.

### Dependencies

*   The project has no external software dependencies beyond `bash`, `tmux`, and `nvim` (as the default editor).
*   No external imports are used within the bash script itself.
