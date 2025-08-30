# AGENTS.md

## Build, Lint, and Test Commands

- This project is a bash script (`tde`) for managing tmux sessions and windows.
- No explicit build or lint commands are present.
- All temporary files should be confined to the `/tmp` directory.

## Code Style Guidelines

- Shell script uses `#!/usr/bin/env bash` with `set -euo pipefail` for strict error handling.
- Use clear, descriptive function names (e.g., `print_help`, `tmux_cmd`).
- Use local variables inside functions.
- Use double brackets `[[ ... ]]` for conditionals.
- Use arrays for lists (e.g., `PROJECT_DIRS=()`).
- Use consistent indentation (4 spaces).
- Use comments to explain complex logic.
- Error messages should be sent to stderr.
- Validate input parameters strictly.
- Use `echo` for output and warnings.
- Avoid global variables unless necessary.

## Imports

- No external imports or dependencies.

## Naming Conventions

- Variables and functions use lowercase with underscores.
- Constants use uppercase (e.g., `DRY_RUN`, `PANES`).

## Error Handling

- Exit immediately on errors.
- Print error messages to stderr.
- Validate all user inputs.
