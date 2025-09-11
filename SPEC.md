# tde Specification

See also:

- GEMINI.md
- AGENTS.md

## Man Page

## Program Execution

<!--
- If inside tmux and one or more PROJECT_DIR arguments and if no explicit --session option, then use the current session.
- If outside tmux and if no explicit --session option, then use the default session (`tde`).
-->

- The session name is determined as follows:

      - The default session name is `tde`.
      - Specify an alternative session name using the `--session` option.

  <!--
      - If `--session` option value is `-` then use the current tmux session name.
  -->

- The session name determines the name of the default configuration file.
- If the session exists then the configuration file is skipped, this allows additional workspace windows to be added with `PROJECT_DIR` options.
- If `tde` is run without any command-line arguments and the session exists then it will be attached.

Execution pseudo-code:

```
parse command arguments
if not session_exists:
    append configuration file entries to project specs
append command-line project directories to project specs
if #specs == 0:
    if session_exists:
        attach session
        exit
    else
        error "no project workspace directories specified"
        exit 1
for spec in specs:
    create project workspace window for the spec
select first new window
attach session
```

## Coding Guidelines

## Implementation Guidelines
