# Implementation Specification

## Overview

A specification for feature enhancements to the application in the current directory.
Read this file carefully before proceeding.

- This Markdown file is structured as follows:

  - Level-2 Markdown sections with headings formatted like `## Feature: <feature-name>` contain a single feature enhancement specification.
  - Within each feature specification section is a dated log in reverse chronological order (most recent entries first); each log entry is a level-3 Markdown section with headings formatted like `### <date>`.
  - A `### Description` section containing a condensed overview of the feature is also included in the feature specification.

- Instructions in more recent log entries take precedence over ambiguous or conflicting instructions in older entries; this allows the feature specification to be progressively refined with the addition of new log entries while maintaining previous log entries.
- Follow the guidelines in the `AGENTS.md` file.
- Show your implementation plan first, then apply the changes.

Invoke this file with the following prompt:

"Review the guidelines and instructions in the `Overview` and `Feature: Add launch option to tde` sections in the `IMPLEMENTATION.md` file and propose the feature implementation. Follow the coding conventions in the `AGENTS.md` file, create an implementation, then show me the proposed changes before applying it."

## Feature: Add launch option to tde

### Description

Add a new `--launch` command option to the `tde` script.

### 23-Aug-2025

Implement the new `--launch` option in the `tde` script.

- The _Usage_ section of in the `README.md` file has been updated with details of this new option. Compare it with the usage text in the `tde` script to see what has changed.
- `COMMAND` is executed in pane `PANE` of each window.
- `tde` exits with an error it the `COMMAND` does not exist or fails to execute.
- Multiple `--launch` options can be specified.
- Replace the current usage text in `tde` with the updated usage text from the _Usage_ section of the `README.md`.
