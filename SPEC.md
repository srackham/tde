# tde Specification

See also:

- GEMINI.md
- AGENTS.md

## Man Page

## Program Execution

- If inside tmux and one or more PROJECT_DIR arguments and if no explicit --session option, then use the current session.
- If outside tmux and if no explicit --session option, then use the default session (`tde`).

Execution pseudo-code:

```
parse command arguments
if session does not exist:
    if ! in_tmux:
        append configuration file entries to project specs
    else if ! --session:
        session = current session
append command-line project directories to project specs
if #specs == 0:
    # This block exits.
    if session does not exist:
        error exit
    attach and exit
if session does not exist:
    create session
for spec in specs:
    TODO:


parse command arguments
if ! --session:
    if in_tmux && #project_dirs > 0:
        session = current session
    else:
        session = default_session
if session does not exist:
    append configuration file entries to project specs
append project_dirs to specs
if #specs == 0:
    # This block exits.
    if session does not exist:
        error exit
    attach and exit
if session does not exist:
    create session
for spec in specs:
    TODO:
```

## Coding Guidelines

## Implementation Guidelines

