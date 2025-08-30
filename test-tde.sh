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

# Test Case 5: Multiple project directories with default panes
run_test "Multiple project directories with default panes" "/tmp/project1 /tmp/project2" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -c /tmp/project1 -n project1
tmux select-pane -t tde:999.1
tmux new-window -c /tmp/project2 -n project2
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

# Test Case 6: Multiple project directories with 3 panes
run_test "Multiple project directories with 3 panes" "-p 3 /tmp/project1 /tmp/project2" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -c /tmp/project1 -n project1
tmux split-window -h -t tde:999 -c /tmp/project1
tmux split-window -t tde:999.2 -c /tmp/project1	mux select-layout -E -t tde:999.2
tmux select-pane -t tde:999.1
tmux new-window -c /tmp/project2 -n project2
tmux split-window -h -t tde:999 -c /tmp/project2
tmux split-window -t tde:999.2 -c /tmp/project2
tmux select-layout -E -t tde:999.2
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

# Test Case 7: Multiple project directories with a launch command in pane 1
run_test "Multiple project directories with a launch command in pane 1" "-l 1:ls -p 2 /tmp/project1 /tmp/project2" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -c /tmp/project1 -n project1
tmux split-window -h -t tde:999 -c /tmp/project1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.1 ls C-m
tmux select-pane -t tde:999.1
tmux new-window -c /tmp/project2 -n project2
tmux split-window -h -t tde:999 -c /tmp/project2
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.1 ls C-m
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

# Test Case 8: Multiple project directories with a launch command in pane 2
run_test "Multiple project directories with a launch command in pane 2" "-l 2:git status -p 2 /tmp/project1 /tmp/project2" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -c /tmp/project1 -n project1
tmux split-window -h -t tde:999 -c /tmp/project1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.2 git\ status C-m
tmux select-pane -t tde:999.1
tmux new-window -c /tmp/project2 -n project2
tmux split-window -h -t tde:999 -c /tmp/project2
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.2 git\ status C-m
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

# Test Case 9: Multiple project directories with a launch command in pane 3
run_test "Multiple project directories with a launch command in pane 3" "-l 3:htop -p 3 /tmp/project1 /tmp/project2" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -c /tmp/project1 -n project1
tmux split-window -h -t tde:999 -c /tmp/project1
tmux split-window -t tde:999.2 -c /tmp/project1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.3 htop C-m
tmux select-pane -t tde:999.1
tmux new-window -c /tmp/project2 -n project2
tmux split-window -h -t tde:999 -c /tmp/project2
tmux split-window -t tde:999.2 -c /tmp/project2
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.3 htop C-m
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

# Test Case 10: Multiple project directories with multiple launch commands
run_test "Multiple project directories with multiple launch commands" "-l 1:nvim -l 2:git status -p 2 /tmp/project1 /tmp/project2" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -c /tmp/project1 -n project1
tmux split-window -h -t tde:999 -c /tmp/project1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.1 nvim C-m
tmux send-keys -t tde:999.2 git\ status C-m
tmux select-pane -t tde:999.1
tmux new-window -c /tmp/project2 -n project2
tmux split-window -h -t tde:999 -c /tmp/project2
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.1 nvim C-m
tmux send-keys -t tde:999.2 git\ status C-m
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

# Test Case 11: Single project directory with 4 panes
run_test "Single project directory with 4 panes" "-p 4 /tmp/project1" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -c /tmp/project1 -n project1
tmux split-window -h -t tde:999 -c /tmp/project1
tmux split-window -t tde:999.2 -c /tmp/project1
tmux split-window -t tde:999.2 -c /tmp/project1
tmux select-layout -E -t tde:999.2
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

# Test Case 12: Single project directory with 4 panes and multiple launch commands
run_test "Single project directory with 4 panes and multiple launch commands" "-p 4 -l 1:ls -l 2:git status /tmp/project1" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -c /tmp/project1 -n project1
tmux split-window -h -t tde:999 -c /tmp/project1
tmux split-window -t tde:999.2 -c /tmp/project1
tmux split-window -t tde:999.2 -c /tmp/project1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.1 ls C-m
tmux send-keys -t tde:999.2 git\ status C-m
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

# Test Case 13: Single project directory with 4 panes and a launch command in pane 4
run_test "Single project directory with 4 panes and a launch command in pane 4" "-p 4 -l 4:tail -f /var/log/syslog /tmp/project1" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -c /tmp/project1 -n project1
tmux split-window -h -t tde:999 -c /tmp/project1
tmux split-window -t tde:999.2 -c /tmp/project1
tmux split-window -t tde:999.2 -c /tmp/project1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.4 tail\ -f\ /var/log/syslog C-m
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

# Test Case 14: Multiple project directories with 5 panes and a launch command in pane 1
run_test "Multiple project directories with 5 panes and a launch command in pane 1" "-p 5 -l 1:nvim /tmp/project1 /tmp/project2" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -c /tmp/project1 -n project1
tmux split-window -h -t tde:999 -c /tmp/project1
tmux split-window -t tde:999.2 -c /tmp/project1
tmux split-window -t tde:999.2 -c /tmp/project1
tmux split-window -t tde:999.2 -c /tmp/project1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.1 nvim C-m
tmux select-pane -t tde:999.1
tmux new-window -c /tmp/project2 -n project2
tmux split-window -h -t tde:999 -c /tmp/project2
tmux split-window -t tde:999.2 -c /tmp/project2
tmux split-window -t tde:999.2 -c /tmp/project2
tmux split-window -t tde:999.2 -c /tmp/project2
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.1 nvim C-m
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

# Test Case 15: Multiple project directories with 5 panes and a launch command in pane 3
run_test "Multiple project directories with 5 panes and a launch command in pane 3" "-p 5 -l 3:htop /tmp/project1 /tmp/project2" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -c /tmp/project1 -n project1
tmux split-window -h -t tde:999 -c /tmp/project1
tmux split-window -t tde:999.2 -c /tmp/project1
tmux split-window -t tde:999.2 -c /tmp/project1
tmux split-window -t tde:999.2 -c /tmp/project1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.3 htop C-m
tmux select-pane -t tde:999.1
tmux new-window -c /tmp/project2 -n project2
tmux split-window -h -t tde:999 -c /tmp/project2
tmux split-window -t tde:999.2 -c /tmp/project2
tmux split-window -t tde:999.2 -c /tmp/project2
tmux split-window -t tde:999.2 -c /tmp/project2
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.3 htop C-m
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

# Test Case 16: Multiple project directories with 5 panes and a launch command in pane 5
run_test "Multiple project directories with 5 panes and a launch command in pane 5" "-p 5 -l 5:watch df -h /tmp/project1 /tmp/project2" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -c /tmp/project1 -n project1
tmux split-window -h -t tde:999 -c /tmp/project1
tmux split-window -t tde:999.2 -c /tmp/project1
tmux split-window -t tde:999.2 -c /tmp/project1
tmux split-window -t tde:999.2 -c /tmp/project1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.5 watch\ df\ -h C-m
tmux select-pane -t tde:999.1
tmux new-window -c /tmp/project2 -n project2
tmux split-window -h -t tde:999 -c /tmp/project2
tmux split-window -t tde:999.2 -c /tmp/project2
tmux split-window -t tde:999.2 -c /tmp/project2
tmux split-window -t tde:999.2 -c /tmp/project2
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.5 watch\ df\ -h C-m
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

# Test Case 17: Multiple project directories with 2 panes and multiple launch commands
run_test "Multiple project directories with 2 panes and multiple launch commands" "-p 2 -l 1:ls -l 2:git status /tmp/project1 /tmp/project2 /tmp/project3" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -c /tmp/project1 -n project1
tmux split-window -h -t tde:999 -c /tmp/project1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.1 ls C-m
tmux send-keys -t tde:999.2 git\ status C-m
tmux select-pane -t tde:999.1
tmux new-window -c /tmp/project2 -n project2
tmux split-window -h -t tde:999 -c /tmp/project2
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.1 ls C-m
tmux send-keys -t tde:999.2 git\ status C-m
tmux select-pane -t tde:999.1
tmux new-window -c /tmp/project3 -n project3
tmux split-window -h -t tde:999 -c /tmp/project3
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.1 ls C-m
tmux send-keys -t tde:999.2 git\ status C-m
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

# Test Case 18: Multiple project directories with 1 pane and a launch command in pane 1
run_test "Multiple project directories with 1 pane and a launch command in pane 1" "-p 1 -l 1:ls /tmp/project1 /tmp/project2" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -c /tmp/project1 -n project1
tmux send-keys -t tde:999.1 ls C-m
tmux select-pane -t tde:999.1
tmux new-window -c /tmp/project2 -n project2
tmux send-keys -t tde:999.1 ls C-m
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

# Test Case 19: Multiple project directories with 4 panes and multiple launch commands
run_test "Multiple project directories with 4 panes and multiple launch commands" "-p 4 -l 1:nvim -l 2:git status -l 3:htop -l 4:watch df -h /tmp/project1 /tmp/project2" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -c /tmp/project1 -n project1
tmux split-window -h -t tde:999 -c /tmp/project1
tmux split-window -t tde:999.2 -c /tmp/project1
tmux split-window -t tde:999.2 -c /tmp/project1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.1 nvim C-m
tmux send-keys -t tde:999.2 git\ status C-m
tmux send-keys -t tde:999.3 htop C-m
tmux send-keys -t tde:999.4 watch\ df\ -h C-m
tmux select-pane -t tde:999.1
tmux new-window -c /tmp/project2 -n project2
tmux split-window -h -t tde:999 -c /tmp/project2
tmux split-window -t tde:999.2 -c /tmp/project2
tmux split-window -t tde:999.2 -c /tmp/project2
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.1 nvim C-m
tmux send-keys -t tde:999.2 git\ status C-m
tmux send-keys -t tde:999.3 htop C-m
tmux send-keys -t tde:999.4 watch\ df\ -h C-m
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

# Test Case 20: Multiple project directories with 2 panes, and a launch command with a complex string
run_test "Multiple project directories with 2 panes, and a launch command with a complex string" "-p 2 -l '1:echo \"Hello World!\" && sleep 1' /tmp/project1 /tmp/project2" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -c /tmp/project1 -n project1
tmux split-window -h -t tde:999 -c /tmp/project1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.1 echo\ \"Hello\ World!\"\ \&\&\ sleep\ 1 C-m
tmux select-pane -t tde:999.1
tmux new-window -c /tmp/project2 -n project2
tmux split-window -h -t tde:999 -c /tmp/project2
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.1 echo\ \"Hello\ World!\"\ \&\&\ sleep\ 1 C-m
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

run_test "Help message (first two lines)" "--help | head -n 2" "NAME
    tde - open project workspaces"

echo "All tests passed!"
rm -rf "$TEST_DIR"
