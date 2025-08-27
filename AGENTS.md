# AGENTS.md

## Build, Lint, and Test Commands

- This project is a bash script (`tde`) for managing tmux sessions and windows.
- No explicit build or lint commands are present.
- To test, run `./tde --help` command and check the output.

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

<!--
## Session Transcript

- Append all questions and responses to `TRANSCRIPT.md` in Markdown format.
- Each interaction should be clearly formatted with timestamps and user/Crush labels.
- Ensure the transcript file is created if it doesn't exist.
-->

---

This file is intended for agentic coding agents operating in this repository to understand the project structure, style, and usage.
