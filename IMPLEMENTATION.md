# Implementation Specification

## Overview

A specification for feature enhancements to the `tde` application in the current directory.
Read this file carefully before proceeding.

- This Markdown file is structured as follows:

  - Level-2 Markdown sections with headings formatted like `## Feature: <feature-name>` contain a single feature enhancement specification.
  - Within each feature specification section is a dated log in reverse chronological order (most recent entries first); each log entry is a level-3 Markdown section with headings formatted like `### <date>`.
  - A `### Description` section containing a condensed overview of the feature is also included in the feature specification.

- In the case of ambiguous or conflicting log entries, the most recent log entry takes precedence over older entries; this allows the feature specification to be progressively refined with the addition of new log entries without having to change previous log entries.
- Observe the instructions, conventions and guidelines in the `AGENTS.md` file.

This file is executed with the following prompt:

"Carefully review the guidelines and instructions in the `Overview` and `Feature: Add launch option to tde` sections in the `IMPLEMENTATION.md` file. Create the feature implementation then ask for approval before applying it."

## Feature: Add launch option to tde

### Description

Add a new `--launch` command option to the `tde` script.

### 23-Aug-2025

- Currently `tde` is hard-wired to run the `nvim` command (`PANE1_CMD`) in pane 1 of each window using the tmux `send-keys` command. Change this behaviour so that the commands specified by `--launch` options are executed in the specified panes.
- See the _Usage_ section of in the `README.md` file for a description of this new option.
- `tde` exits with an error if the launch `COMMAND` does not exist or fails to execute.
- Multiple `--launch` options can be specified.
