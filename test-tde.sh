#!/usr/bin/env bash

set -euo pipefail

# Create temporary directories for testing
TEST_DIR=/tmp/test-tde
TEST_HOME="$TEST_DIR/home"
TEST_TDE_CONF="$TEST_HOME/.tde"

setup() {
    mkdir -p "$TEST_DIR"
    mkdir -p "$TEST_HOME"
    touch "$TEST_TDE_CONF"
    PROJECT1="$TEST_DIR/project1"
    PROJECT2="$TEST_DIR/project2"
    mkdir -p $PROJECT1 $PROJECT2
}
setup

cleanup() {
    rm -rf "$TEST_DIR"
}
# trap cleanup EXIT

# Function to run a test
run_test() {
    local test_name="$1"
    local command="TEST_TDE=true ./tde $2"
    local expected_output="$3"
    local expected_exit_code="${4:-0}" # Defaults to 0 if not provided
    local env_vars="${5:-TMUX=true}"

    # Prepend env_vars to command if specified
    if [[ -n "$env_vars" ]]; then
        command="$env_vars $command"
    fi

    # Execute the command and capture its output and exit code
    set +e
    actual_output=$(bash -c "$command 2>&1")
    actual_exit_code=$?
    set -e

    # Normalize line endings for comparison
    actual_output=$(echo "$actual_output" | sed 's/\r$//')
    expected_output=$(echo "$expected_output" | sed 's/\r$//')

    local pass=true

    echo "Running test: $test_name"
    echo "              $command"

    # Check output
    if [[ "$actual_output" != "$expected_output" ]]; then
        echo "  FAIL (Output mismatch)"
        echo "    Expected Output:"
        echo "$expected_output" | sed 's/^/      /'
        echo "    Actual Output:"
        echo "$actual_output" | sed 's/^/      /'
        pass=false
    fi

    # Check exit code
    if [[ "$actual_exit_code" -ne "$expected_exit_code" ]]; then
        echo "  FAIL (Exit code mismatch)"
        echo "    Expected Exit Code: $expected_exit_code"
        echo "    Actual Exit Code:   $actual_exit_code"
        pass=false
    fi

    if $pass; then
        echo "  PASS"
    else
        exit 1
    fi
}

run_test "Basic dry-run with a single directory" "$PROJECT1" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -c $PROJECT1 -n $(basename "$PROJECT1")
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

run_test "Dry-run with 2 panes" "-p 2 $PROJECT1" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -c $PROJECT1 -n $(basename "$PROJECT1")
tmux split-window -h -t tde:999 -c $PROJECT1
tmux select-layout -E -t tde:999.2
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

run_test "Dry-run with 2 panes and explicit pane 1 launch command" "-p 2 -l 1:nvim $PROJECT1" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -c $PROJECT1 -n $(basename "$PROJECT1")
tmux split-window -h -t tde:999 -c $PROJECT1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.1 -l nvim
tmux send-keys -t tde:999.1 Enter
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

run_test "Dry-run with 2 panes and implicit pane 1 launch command" "-p 2 -l nvim $PROJECT1" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -c $PROJECT1 -n $(basename "$PROJECT1")
tmux split-window -h -t tde:999 -c $PROJECT1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.1 -l nvim
tmux send-keys -t tde:999.1 Enter
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

run_test "Multiple project directories with default panes" "$PROJECT1 $PROJECT2" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -c $PROJECT1 -n project1
tmux select-pane -t tde:999.1
tmux new-window -c $PROJECT2 -n project2
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

run_test "Multiple project directories with 3 panes" "-p 3 $PROJECT1 $PROJECT2" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -c $PROJECT1 -n project1
tmux split-window -h -t tde:999 -c $PROJECT1
tmux split-window -t tde:999.2 -c $PROJECT1
tmux select-layout -E -t tde:999.2
tmux select-pane -t tde:999.1
tmux new-window -c $PROJECT2 -n project2
tmux split-window -h -t tde:999 -c $PROJECT2
tmux split-window -t tde:999.2 -c $PROJECT2
tmux select-layout -E -t tde:999.2
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

run_test "Multiple project directories with a launch command in pane 1" "-l 1:ls -p 2 $PROJECT1 $PROJECT2" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -c $PROJECT1 -n project1
tmux split-window -h -t tde:999 -c $PROJECT1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.1 -l ls
tmux send-keys -t tde:999.1 Enter
tmux select-pane -t tde:999.1
tmux new-window -c $PROJECT2 -n project2
tmux split-window -h -t tde:999 -c $PROJECT2
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.1 -l ls
tmux send-keys -t tde:999.1 Enter
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

run_test "Multiple project directories with a launch command in pane 2" "-l '2:git status' -p 2 $PROJECT1 $PROJECT2" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -c $PROJECT1 -n project1
tmux split-window -h -t tde:999 -c $PROJECT1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.2 -l git status
tmux send-keys -t tde:999.2 Enter
tmux select-pane -t tde:999.1
tmux new-window -c $PROJECT2 -n project2
tmux split-window -h -t tde:999 -c $PROJECT2
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.2 -l git status
tmux send-keys -t tde:999.2 Enter
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

run_test "Multiple project directories with a launch command in pane 3" "-l 3:htop -p 3 $PROJECT1 $PROJECT2" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -c $PROJECT1 -n project1
tmux split-window -h -t tde:999 -c $PROJECT1
tmux split-window -t tde:999.2 -c $PROJECT1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.3 -l htop
tmux send-keys -t tde:999.3 Enter
tmux select-pane -t tde:999.1
tmux new-window -c $PROJECT2 -n project2
tmux split-window -h -t tde:999 -c $PROJECT2
tmux split-window -t tde:999.2 -c $PROJECT2
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.3 -l htop
tmux send-keys -t tde:999.3 Enter
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

run_test "Multiple project directories with multiple launch commands" "-l 1:nvim -l '2:git status' -p 2 $PROJECT1 $PROJECT2" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -c $PROJECT1 -n project1
tmux split-window -h -t tde:999 -c $PROJECT1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.1 -l nvim
tmux send-keys -t tde:999.1 Enter
tmux send-keys -t tde:999.2 -l git status
tmux send-keys -t tde:999.2 Enter
tmux select-pane -t tde:999.1
tmux new-window -c $PROJECT2 -n project2
tmux split-window -h -t tde:999 -c $PROJECT2
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.1 -l nvim
tmux send-keys -t tde:999.1 Enter
tmux send-keys -t tde:999.2 -l git status
tmux send-keys -t tde:999.2 Enter
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

run_test "Single project directory with 4 panes" "-p 4 $PROJECT1" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -c $PROJECT1 -n project1
tmux split-window -h -t tde:999 -c $PROJECT1
tmux split-window -t tde:999.2 -c $PROJECT1
tmux split-window -t tde:999.2 -c $PROJECT1
tmux select-layout -E -t tde:999.2
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

run_test "Single project directory with 4 panes and multiple launch commands" "-p 4 -l 1:ls -l '2:git status' $PROJECT1" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -c $PROJECT1 -n project1
tmux split-window -h -t tde:999 -c $PROJECT1
tmux split-window -t tde:999.2 -c $PROJECT1
tmux split-window -t tde:999.2 -c $PROJECT1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.1 -l ls
tmux send-keys -t tde:999.1 Enter
tmux send-keys -t tde:999.2 -l git status
tmux send-keys -t tde:999.2 Enter
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

run_test "Single project directory with 4 panes and a launch command in pane 4" "-p 4 -l '4:tail -f /var/log/syslog' $PROJECT1" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -c $PROJECT1 -n project1
tmux split-window -h -t tde:999 -c $PROJECT1
tmux split-window -t tde:999.2 -c $PROJECT1
tmux split-window -t tde:999.2 -c $PROJECT1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.4 -l tail -f /var/log/syslog
tmux send-keys -t tde:999.4 Enter
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

run_test "Multiple project directories with 5 panes and a launch command in pane 1" "-p 5 -l 1:nvim $PROJECT1 $PROJECT2" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -c $PROJECT1 -n project1
tmux split-window -h -t tde:999 -c $PROJECT1
tmux split-window -t tde:999.2 -c $PROJECT1
tmux split-window -t tde:999.2 -c $PROJECT1
tmux split-window -t tde:999.2 -c $PROJECT1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.1 -l nvim
tmux send-keys -t tde:999.1 Enter
tmux select-pane -t tde:999.1
tmux new-window -c $PROJECT2 -n project2
tmux split-window -h -t tde:999 -c $PROJECT2
tmux split-window -t tde:999.2 -c $PROJECT2
tmux split-window -t tde:999.2 -c $PROJECT2
tmux split-window -t tde:999.2 -c $PROJECT2
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.1 -l nvim
tmux send-keys -t tde:999.1 Enter
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

run_test "Multiple project directories with 5 panes and a launch command in pane 3" "-p 5 -l 3:htop $PROJECT1 $PROJECT2" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -c $PROJECT1 -n project1
tmux split-window -h -t tde:999 -c $PROJECT1
tmux split-window -t tde:999.2 -c $PROJECT1
tmux split-window -t tde:999.2 -c $PROJECT1
tmux split-window -t tde:999.2 -c $PROJECT1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.3 -l htop
tmux send-keys -t tde:999.3 Enter
tmux select-pane -t tde:999.1
tmux new-window -c $PROJECT2 -n project2
tmux split-window -h -t tde:999 -c $PROJECT2
tmux split-window -t tde:999.2 -c $PROJECT2
tmux split-window -t tde:999.2 -c $PROJECT2
tmux split-window -t tde:999.2 -c $PROJECT2
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.3 -l htop
tmux send-keys -t tde:999.3 Enter
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

run_test "Multiple project directories with 5 panes and a launch command in pane 5" "-p 5 -l 5:ps $PROJECT1 $PROJECT2" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -c $PROJECT1 -n project1
tmux split-window -h -t tde:999 -c $PROJECT1
tmux split-window -t tde:999.2 -c $PROJECT1
tmux split-window -t tde:999.2 -c $PROJECT1
tmux split-window -t tde:999.2 -c $PROJECT1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.5 -l ps
tmux send-keys -t tde:999.5 Enter
tmux select-pane -t tde:999.1
tmux new-window -c $PROJECT2 -n project2
tmux split-window -h -t tde:999 -c $PROJECT2
tmux split-window -t tde:999.2 -c $PROJECT2
tmux split-window -t tde:999.2 -c $PROJECT2
tmux split-window -t tde:999.2 -c $PROJECT2
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.5 -l ps
tmux send-keys -t tde:999.5 Enter
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

run_test "Multiple project directories with 1 pane and a launch command in pane 1" "-p 1 -l 1:ls $PROJECT1 $PROJECT2" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -c $PROJECT1 -n project1
tmux send-keys -t tde:999.1 -l ls
tmux send-keys -t tde:999.1 Enter
tmux select-pane -t tde:999.1
tmux new-window -c $PROJECT2 -n project2
tmux send-keys -t tde:999.1 -l ls
tmux send-keys -t tde:999.1 Enter
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

run_test "Multiple project directories with 4 panes and multiple launch commands" "-p 4 -l 1:nvim -l '2:git status' -l 3:htop -l 4:ps $PROJECT1 $PROJECT2" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -c $PROJECT1 -n project1
tmux split-window -h -t tde:999 -c $PROJECT1
tmux split-window -t tde:999.2 -c $PROJECT1
tmux split-window -t tde:999.2 -c $PROJECT1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.1 -l nvim
tmux send-keys -t tde:999.1 Enter
tmux send-keys -t tde:999.2 -l git status
tmux send-keys -t tde:999.2 Enter
tmux send-keys -t tde:999.3 -l htop
tmux send-keys -t tde:999.3 Enter
tmux send-keys -t tde:999.4 -l ps
tmux send-keys -t tde:999.4 Enter
tmux select-pane -t tde:999.1
tmux new-window -c $PROJECT2 -n project2
tmux split-window -h -t tde:999 -c $PROJECT2
tmux split-window -t tde:999.2 -c $PROJECT2
tmux split-window -t tde:999.2 -c $PROJECT2
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.1 -l nvim
tmux send-keys -t tde:999.1 Enter
tmux send-keys -t tde:999.2 -l git status
tmux send-keys -t tde:999.2 Enter
tmux send-keys -t tde:999.3 -l htop
tmux send-keys -t tde:999.3 Enter
tmux send-keys -t tde:999.4 -l ps
tmux send-keys -t tde:999.4 Enter
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

run_test "Illegal command option" "-X $PROJECT1" "Unknown option: -X" 1

run_test "Multiple project directories with 2 panes, and a launch command with a complex string" "-p 2 -l '1:echo \"Hello World\!\" && sleep 1' $PROJECT1 $PROJECT2" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -c $PROJECT1 -n project1
tmux split-window -h -t tde:999 -c $PROJECT1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.1 -l echo \"Hello World\!\" && sleep 1
tmux send-keys -t tde:999.1 Enter
tmux select-pane -t tde:999.1
tmux new-window -c $PROJECT2 -n project2
tmux split-window -h -t tde:999 -c $PROJECT2
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.1 -l echo \"Hello World\!\" && sleep 1
tmux send-keys -t tde:999.1 Enter
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

run_test "Tesst Case 21: Help message (first two lines)" "--help | head -n 2" "NAME
    tde - open project workspaces"

# Tests for invalid command options
run_test "Invalid --panes value (0)" "-p 0 $PROJECT1" "Error: PANES must be between 1 and 9" 1
run_test "Invalid --panes value (10)" "--panes=10 $PROJECT1" "Error: PANES must be between 1 and 9" 1
run_test "Invalid --panes value (abc)" "-p abc $PROJECT1" "Error: PANES must be between 1 and 9" 1
run_test "Invalid --launch pane number (0)" "-p 2 -l 0:ls $PROJECT1" "Error: Invalid pane number '0' for --launch option. Must be between 1 and 2." 1
run_test "Invalid --launch pane number (too high)" "-p 2 -l 3:ls $PROJECT1" "Error: Invalid pane number '3' for --launch option. Must be between 1 and 2." 1
run_test "Invalid --launch pane number (non-numeric)" "-p 2 -l x:ls $PROJECT1" "Error: Invalid pane number 'x' for --launch option. Must be between 1 and 2." 1

run_test "New Session Mode inside tmux" "" "Error: No project directories specified; cannot run New Session Mode inside tmux." 1
run_test "Current Session Mode outside tmux" "$PROJECT1" "Error: PROJECT_DIR arguments specified but not running inside a tmux session." 1 TMUX=
run_test "Missing project directory" "/nonexistent/path" "Error: The following project directories do not exist:
  /nonexistent/path" 1
run_test "No project directories found in $TEST_TDE_CONF" "" "Error: No project directories found in $TEST_TDE_CONF" 1 "HOME=$TEST_HOME TMUX="

echo
echo "All tests passed!"
