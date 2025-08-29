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
    actual_output=$(bash -c "./tde --dry-run $command 2>/dev/null || true")

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

# Test Case 5: Dry-run with 3 panes
run_test "Dry-run with 3 panes" "-p 3 /tmp/dir1" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -c /tmp/dir1 -n dir1
tmux split-window -h -t tde:999 -c /tmp/dir1
tmux split-window -t tde:999.2 -c /tmp/dir1
tmux select-layout -E -t tde:999.2
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

# Test Case 6: Dry-run with 2 panes and explicit pane 2 launch command
run_test "Dry-run with 2 panes and explicit pane 2 launch" "-p 2 -l 2:ls /tmp/dir1" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -c /tmp/dir1 -n dir1
tmux split-window -h -t tde:999 -c /tmp/dir1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.2 ls C-m
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

# Test Case 7: Dry-run with 4 panes and explicit pane 1 launch command
run_test "Dry-run with 4 panes and explicit pane 1 launch" "-p 4 -l 1:pwd /tmp/dir1" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -c /tmp/dir1 -n dir1
tmux split-window -h -t tde:999 -c /tmp/dir1
tmux split-window -t tde:999.2 -c /tmp/dir1
tmux split-window -t tde:999.2 -c /tmp/dir1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.1 pwd C-m
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

# Test Case 8: Dry-run with 2 panes and implicit pane 2 launch command for multiple directories
run_test "Dry-run with 2 panes and implicit pane 2 launch for multiple directories" "-p 2 -l 2:nvim /tmp/dir1 /tmp/dir2" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -c /tmp/dir1 -n dir1
tmux split-window -h -t tde:999 -c /tmp/dir1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.2 nvim C-m
tmux select-pane -t tde:999.1
tmux new-window -c /tmp/dir2 -n dir2
tmux split-window -h -t tde:999 -c /tmp/dir2
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.2 nvim C-m
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

# Test Case 9: Dry-run with 1 pane and implicit pane 1 launch command
run_test "Dry-run with 1 pane and implicit pane 1 launch" "-p 1 -l nvim /tmp/dir1" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -c /tmp/dir1 -n dir1
tmux send-keys -t tde:999.1 nvim C-m
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

# Test Case 10: Dry-run with 5 panes
run_test "Dry-run with 5 panes" "-p 5 /tmp/dir1" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -c /tmp/dir1 -n dir1
tmux split-window -h -t tde:999 -c /tmp/dir1
tmux split-window -t tde:999.2 -c /tmp/dir1
tmux split-window -t tde:999.2 -c /tmp/dir1
tmux split-window -t tde:999.2 -c /tmp/dir1
tmux select-layout -E -t tde:999.2
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

# Test Case 11: Dry-run with 3 panes and explicit pane 3 launch command with arguments
run_test "Dry-run with 3 panes and explicit pane 3 launch command with arguments" "-p 3 -l '3:ls -l' /tmp/dir1" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -c /tmp/dir1 -n dir1
tmux split-window -h -t tde:999 -c /tmp/dir1
tmux split-window -t tde:999.2 -c /tmp/dir1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.3 ls -l C-m
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

# Test Case 12: Dry-run with 2 panes and multiple launch commands
run_test "Dry-run with 2 panes and multiple launch commands" "-p 2 -l '1:echo hello' -l '2:echo world' /tmp/dir1" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -c /tmp/dir1 -n dir1
tmux split-window -h -t tde:999 -c /tmp/dir1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.1 echo hello C-m
tmux send-keys -t tde:999.2 echo world C-m
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

# Test Case 13: Dry-run with 3 panes and multiple launch commands
run_test "Dry-run with 3 panes and multiple launch commands" "-p 3 -l 1:nvim -l '2:ls -l' -l 3:pwd /tmp/dir1" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -c /tmp/dir1 -n dir1
tmux split-window -h -t tde:999 -c /tmp/dir1
tmux split-window -t tde:999.2 -c /tmp/dir1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.1 nvim C-m
tmux send-keys -t tde:999.2 ls -l C-m
tmux send-keys -t tde:999.3 pwd C-m
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

# Test Case 14: Dry-run with 2 panes and implicit pane 2 launch command for three directories
run_test "Dry-run with 2 panes and implicit pane 2 launch for three directories" "-p 2 -l '2:echo hello' /tmp/dir1 /tmp/dir2 /tmp/dir3" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -c /tmp/dir1 -n dir1
tmux split-window -h -t tde:999 -c /tmp/dir1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.2 echo hello C-m
tmux select-pane -t tde:999.1
tmux new-window -c /tmp/dir2 -n dir2
tmux split-window -h -t tde:999 -c /tmp/dir2
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.2 echo hello C-m
tmux select-pane -t tde:999.1
tmux new-window -c /tmp/dir3 -n dir3
tmux split-window -h -t tde:999 -c /tmp/dir3
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.2 echo hello C-m
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

# Test Case 15: Dry-run with 6 panes and explicit pane 1 launch command
run_test "Dry-run with 6 panes and explicit pane 1 launch command" "-p 6 -l 1:bash /tmp/dir1" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -c /tmp/dir1 -n dir1
tmux split-window -h -t tde:999 -c /tmp/dir1
tmux split-window -t tde:999.2 -c /tmp/dir1
tmux split-window -t tde:999.2 -c /tmp/dir1
tmux split-window -t tde:999.2 -c /tmp/dir1
tmux split-window -t tde:999.2 -c /tmp/dir1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.1 bash C-m
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

# Test Case 16: Dry-run with 7 panes and explicit pane 4 launch command
run_test "Dry-run with 7 panes and explicit pane 4 launch command" "-p 7 -l '4:python --version' /tmp/dir1" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -c /tmp/dir1 -n dir1
tmux split-window -h -t tde:999 -c /tmp/dir1
tmux split-window -t tde:999.2 -c /tmp/dir1
tmux split-window -t tde:999.2 -c /tmp/dir1
tmux split-window -t tde:999.2 -c /tmp/dir1
tmux split-window -t tde:999.2 -c /tmp/dir1
tmux split-window -t tde:999.2 -c /tmp/dir1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.4 python --version C-m
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

# Test Case 17: Dry-run with 8 panes and explicit pane 5 launch command
run_test "Dry-run with 8 panes and explicit pane 5 launch command" "-p 8 -l '5:node --version' /tmp/dir1" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -c /tmp/dir1 -n dir1
tmux split-window -h -t tde:999 -c /tmp/dir1
tmux split-window -t tde:999.2 -c /tmp/dir1
tmux split-window -t tde:999.2 -c /tmp/dir1
tmux split-window -t tde:999.2 -c /tmp/dir1
tmux split-window -t tde:999.2 -c /tmp/dir1
tmux split-window -t tde:999.2 -c /tmp/dir1
tmux split-window -t tde:999.2 -c /tmp/dir1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.5 node --version C-m
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

# Test Case 18: Dry-run with 9 panes and explicit pane 9 launch command
run_test "Dry-run with 9 panes and explicit pane 9 launch command" "-p 9 -l '9:ls -a' /tmp/dir1" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -c /tmp/dir1 -n dir1
tmux split-window -h -t tde:999 -c /tmp/dir1
tmux split-window -t tde:999.2 -c /tmp/dir1
tmux split-window -t tde:999.2 -c /tmp/dir1
tmux split-window -t tde:999.2 -c /tmp/dir1
tmux split-window -t tde:999.2 -c /tmp/dir1
tmux split-window -t tde:999.2 -c /tmp/dir1
tmux split-window -t tde:999.2 -c /tmp/dir1
tmux split-window -t tde:999.2 -c /tmp/dir1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.9 ls -a C-m
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

run_test "Help message (first two lines)" "--help | head -n 2" "NAME
    tde - open project workspaces"

echo "All tests passed!"
rm -rf "$TEST_DIR"
