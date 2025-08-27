# Implementation Specification

This file is executed with the following prompt:

Read the instructions in the `IMPLEMENTATION.md` file then implement the `Add launch option to tde` feature.

## Overview

**Read this file and the `AGENTS.md` file carefully before proceeding**.

This file (`IMPLEMENTATION.md`) is a Markdown file containing a specification for feature enhancements to the `tde` application (the application in the current directory).

In addition to this file, follow the instructions, conventions and guidelines in the `AGENTS.md` file.

- This file is structured as follows:

  - Each Level-2 Markdown section with heading formatted like `## Feature: <feature-name>` contains a single feature enhancement specification.
  - Within each feature specification section is:

    - A `### Description` section containing a condensed overview of the feature is also included in the feature specification.
    - A `### Details` section containing rules and instructions for implementing the feature.

## Feature: Add launch option to tde

### Description

Add a `--launch` command option to the `tde` script.

### Details

- See the _Usage_ section of in the `README.md` file for a description of this new option.
- Currently `tde` is hard-wired to run the `nvim` command (`PANE1_CMD`) in pane 1 of each window using the tmux `send-keys` command. Change this behaviour so that the commands specified by `--launch` options are executed in the specified panes.
- `tde` exits with an error if the launch `COMMAND` does not exist or fails to execute.
- Multiple `--launch` options can be specified.
- Validate the `--launch` option pane number after the options have been parsed to ensure the `--panes` option value has been calculated before the pane number validation.
