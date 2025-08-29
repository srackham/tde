#!/usr/bin/env bash

set -euo pipefail

# Define a temporary directory for testing
TEST_DIR="/tmp/tde-test-$(date +%s)"
mkdir -p "$TEST_DIR"

# Function to run a test
run_test() {
    local test_name="$1"
    local command="$2"
    local expected_output="$3"

    echo "Running test: $test_name"
    
    # Execute the command and capture its output
    # We need to redirect stderr to /dev/null because tde prints warnings to stderr
    # when running in current session mode without an actual tmux session.
    # The dry-run output is always to stdout.
    actual_output=$(./tde --dry-run $command 2>/dev/null || true)

    # Normalize line endings for comparison
    actual_output=$(echo "$actual_output" | sed 's/\r$//')
    expected_output=$(echo "$expected_output" | sed 's/\r$//')

    if [[ "$actual_output" == "$expected_output" ]]; then
        echo "  PASS"
    else
        echo "  FAIL"
        echo "    Expected:"
        echo "$expected_output" | sed 's/^/      /'
        echo "    Actual:"
        echo "$actual_output" | sed 's/^/      /'
        exit 1
    fi
}

# Test Case 1: Basic dry-run with a single directory
run_test "Basic dry-run" "/tmp" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -c /tmp -n tmp
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

# Test Case 2: Dry-run with 2 panes
run_test "Dry-run with 2 panes" "-p 2 /tmp" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -c /tmp -n tmp
tmux split-window -h -t tde:999 -c /tmp
tmux select-layout -E -t tde:999.2
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

# Test Case 3: Dry-run with 2 panes and explicit pane 1 launch command
run_test "Dry-run with 2 panes and explicit pane 1 launch" "-p 2 -l 1:nvim /tmp" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -c /tmp -n tmp
tmux split-window -h -t tde:999 -c /tmp
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.1 nvim C-m
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

# Test Case 4: Dry-run with 2 panes and implicit pane 1 launch command
run_test "Dry-run with 2 panes and implicit pane 1 launch" "-p 2 -l nvim /tmp" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -c /tmp -n tmp
tmux split-window -h -t tde:999 -c /tmp
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.1 nvim C-m
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

echo "All tests passed!"
rm -rf "$TEST_DIR"
