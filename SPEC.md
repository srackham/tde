# tde Specification

See also:

- GEMINI.md
- AGENTS.md

## Man Page

## Program Execution

Execution pseudo-code:

```
parse command arguments
if session_name does not exist:
    append configuration file entries to project specs
append command-line project directories to project specs
if #specs == 0:
    if session_name does not exist:
        error exit
    attach and exit
for spec in specs:
    TODO:
```

## Coding Guidelines

## Implementation Guidelines

