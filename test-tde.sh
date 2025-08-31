#!/usr/bin/env bash

set -euo pipefail

# Define a temporary directories for testing
PROJECT1="/tmp/test-tde/project1"
PROJECT2="/tmp/test-tde/project2"
mkdir -p $PROJECT1 $PROJECT2

# Function to run a test
run_test() {
    local test_name="$1"
    local command="./tde --dry-run $2"
    local expected_output="$3"
    local expected_exit_code="${4:-0}"  # Defaults to 0 if not provided

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

run_test "Basic dry-run with a single directory" "/tmp" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -c /tmp -n tmp
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

run_test "Dry-run with 2 panes" "-p 2 /tmp" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -c /tmp -n tmp
tmux split-window -h -t tde:999 -c /tmp
tmux select-layout -E -t tde:999.2
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

run_test "Dry-run with 2 panes and explicit pane 1 launch command" "-p 2 -l 1:nvim /tmp" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -c /tmp -n tmp
tmux split-window -h -t tde:999 -c /tmp
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.1 nvim C-m
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

run_test "Dry-run with 2 panes and implicit pane 1 launch command" "-p 2 -l nvim /tmp" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -c /tmp -n tmp
tmux split-window -h -t tde:999 -c /tmp
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.1 nvim C-m
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
tmux send-keys -t tde:999.1 ls C-m
tmux select-pane -t tde:999.1
tmux new-window -c $PROJECT2 -n project2
tmux split-window -h -t tde:999 -c $PROJECT2
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.1 ls C-m
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

run_test "Multiple project directories with a launch command in pane 2" "-l '2:git status' -p 2 $PROJECT1 $PROJECT2" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -c $PROJECT1 -n project1
tmux split-window -h -t tde:999 -c $PROJECT1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.2 git Space status C-m
tmux select-pane -t tde:999.1
tmux new-window -c $PROJECT2 -n project2
tmux split-window -h -t tde:999 -c $PROJECT2
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.2 git Space status C-m
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

run_test "Multiple project directories with a launch command in pane 3" "-l 3:htop -p 3 $PROJECT1 $PROJECT2" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -c $PROJECT1 -n project1
tmux split-window -h -t tde:999 -c $PROJECT1
tmux split-window -t tde:999.2 -c $PROJECT1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.3 htop C-m
tmux select-pane -t tde:999.1
tmux new-window -c $PROJECT2 -n project2
tmux split-window -h -t tde:999 -c $PROJECT2
tmux split-window -t tde:999.2 -c $PROJECT2
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.3 htop C-m
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

run_test "Multiple project directories with multiple launch commands" "-l 1:nvim -l '2:git status' -p 2 $PROJECT1 $PROJECT2" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -c $PROJECT1 -n project1
tmux split-window -h -t tde:999 -c $PROJECT1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.1 nvim C-m
tmux send-keys -t tde:999.2 git Space status C-m
tmux select-pane -t tde:999.1
tmux new-window -c $PROJECT2 -n project2
tmux split-window -h -t tde:999 -c $PROJECT2
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.1 nvim C-m
tmux send-keys -t tde:999.2 git Space status C-m
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
tmux send-keys -t tde:999.1 ls C-m
tmux send-keys -t tde:999.2 git Space status C-m
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

run_test "Single project directory with 4 panes and a launch command in pane 4" "-p 4 -l '4:tail -f /var/log/syslog' $PROJECT1" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -c $PROJECT1 -n project1
tmux split-window -h -t tde:999 -c $PROJECT1
tmux split-window -t tde:999.2 -c $PROJECT1
tmux split-window -t tde:999.2 -c $PROJECT1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.4 tail Space -f Space /var/log/syslog C-m
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
tmux send-keys -t tde:999.1 nvim C-m
tmux select-pane -t tde:999.1
tmux new-window -c $PROJECT2 -n project2
tmux split-window -h -t tde:999 -c $PROJECT2
tmux split-window -t tde:999.2 -c $PROJECT2
tmux split-window -t tde:999.2 -c $PROJECT2
tmux split-window -t tde:999.2 -c $PROJECT2
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.1 nvim C-m
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
tmux send-keys -t tde:999.3 htop C-m
tmux select-pane -t tde:999.1
tmux new-window -c $PROJECT2 -n project2
tmux split-window -h -t tde:999 -c $PROJECT2
tmux split-window -t tde:999.2 -c $PROJECT2
tmux split-window -t tde:999.2 -c $PROJECT2
tmux split-window -t tde:999.2 -c $PROJECT2
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.3 htop C-m
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
tmux send-keys -t tde:999.5 ps C-m
tmux select-pane -t tde:999.1
tmux new-window -c $PROJECT2 -n project2
tmux split-window -h -t tde:999 -c $PROJECT2
tmux split-window -t tde:999.2 -c $PROJECT2
tmux split-window -t tde:999.2 -c $PROJECT2
tmux split-window -t tde:999.2 -c $PROJECT2
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.5 ps C-m
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

run_test "Multiple project directories with 1 pane and a launch command in pane 1" "-p 1 -l 1:ls $PROJECT1 $PROJECT2" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -c $PROJECT1 -n project1
tmux send-keys -t tde:999.1 ls C-m
tmux select-pane -t tde:999.1
tmux new-window -c $PROJECT2 -n project2
tmux send-keys -t tde:999.1 ls C-m
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

run_test "Multiple project directories with 4 panes and multiple launch commands" "-p 4 -l 1:nvim -l '2:git status' -l 3:htop -l 4:ps $PROJECT1 $PROJECT2" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -c $PROJECT1 -n project1
tmux split-window -h -t tde:999 -c $PROJECT1
tmux split-window -t tde:999.2 -c $PROJECT1
tmux split-window -t tde:999.2 -c $PROJECT1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.1 nvim C-m
tmux send-keys -t tde:999.2 git Space status C-m
tmux send-keys -t tde:999.3 htop C-m
tmux send-keys -t tde:999.4 ps C-m
tmux select-pane -t tde:999.1
tmux new-window -c $PROJECT2 -n project2
tmux split-window -h -t tde:999 -c $PROJECT2
tmux split-window -t tde:999.2 -c $PROJECT2
tmux split-window -t tde:999.2 -c $PROJECT2
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.1 nvim C-m
tmux send-keys -t tde:999.2 git Space status C-m
tmux send-keys -t tde:999.3 htop C-m
tmux send-keys -t tde:999.4 ps C-m
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

# FIXME: The exit code should have been 1.
run_test "Illegal command option" "-X $PROJECT1" "Unknown option: -X" 0

# FIXME: use the send-keys -l option to deal with commands with space et al.
# The  -l  flag  disables  key name lookup and processes the keys as literal UTF-8 characters.
run_test "Multiple project directories with 2 panes, and a launch command with a complex string" "-p 2 -l '1:echo \"Hello World!\" && sleep 1' $PROJECT1 $PROJECT2" "tmux set-option -t tde -g base-index 1

tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -c $PROJECT1 -n project1
tmux split-window -h -t tde:999 -c $PROJECT1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.1 echo\ \"Hello\ World!\"\ \&\&\ sleep\ 1 C-m
tmux select-pane -t tde:999.1
tmux new-window -c $PROJECT2 -n project2
tmux split-window -h -t tde:999 -c $PROJECT2
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.1 echo\ \"Hello\ World!\"\ \&\&\ sleep\ 1 C-m
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

run_test "Tesst Case 21: Help message (first two lines)" "--help | head -n 2" "NAME
    tde - open project workspaces"

echo "All tests passed!"
rm -rf /tmp/test-tde
