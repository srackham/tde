#!/usr/bin/env bash

trap 'echo; echo "$TEST_COUNT tests passed!"' EXIT

set -euo pipefail

# Create temporary directories for testing
TEST_DIR=/tmp/test-tde
CONFIG_DIR="$TEST_DIR/.config/tde"
CONFIG_FILE="$CONFIG_DIR/tde.conf"

setup() {
    mkdir -p "$TEST_DIR"
    mkdir -p "$(dirname "$CONFIG_FILE")"
    [ -f "$CONFIG_FILE" ] && rm "$CONFIG_FILE"
    touch "$CONFIG_FILE"
    PROJECT1="$TEST_DIR/project1"
    PROJECT2="$TEST_DIR/project2"
    PROJECT3="$TEST_DIR/project3"
    mkdir -p $PROJECT1 $PROJECT2 $PROJECT3
}
setup

# Function to run a test
run_test() {
    local test_name="$1"
    local command="TEST_TDE=true $2"
    local expected_output="$3"
    local expected_exit_code="${4:-0}" # Defaults to 0 if not provided
    local env_vars="TMUX=\"$TMUX\" TDE_CONFIG_FILE=\"$CONFIG_FILE\""

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
    # shellcheck disable=SC2001
    actual_output=$(echo "$actual_output" | sed 's/\r$//')
    # shellcheck disable=SC2001
    expected_output=$(echo "$expected_output" | sed 's/\r$//')

    local pass=true

    echo "Running test: $test_name"
    echo "              $command"

    # Check output
    if [[ "$actual_output" != "$expected_output" ]]; then
        echo "  FAIL (Output mismatch)"
        echo "    Expected Output:"
        # shellcheck disable=SC2001
        echo "$expected_output" | sed 's/^/      /'
        echo "    Actual Output:"
        # shellcheck disable=SC2001
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
        TEST_COUNT=$((TEST_COUNT + 1))
    else
        exit 1
    fi
}

# Function to write configuration file.
write_conf() {
    local content="$1"
    # Overwrite config file
    printf "%s\n" "$content" >"$CONFIG_FILE"
}

TEST_COUNT=0

#
# Simulate running in a tmux window
#
TMUX=true

run_test "Basic dry-run with a single directory" "./tde $PROJECT1" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -t tde: -c $PROJECT1 -n $(basename "$PROJECT1")
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

run_test "Dry-run with 2 panes" "./tde -p 2 $PROJECT1" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -t tde: -c $PROJECT1 -n $(basename "$PROJECT1")
tmux split-window -h -t tde:999 -c $PROJECT1
tmux select-layout -E -t tde:999.2
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

run_test "Dry-run with 2 panes and explicit pane 1 launch command" "./tde -p 2 -l 1:nvim $PROJECT1" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -t tde: -c $PROJECT1 -n $(basename "$PROJECT1")
tmux split-window -h -t tde:999 -c $PROJECT1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.1 -l nvim
tmux send-keys -t tde:999.1 Enter
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

run_test "Dry-run with 2 panes and implicit pane 1 launch command" "./tde -p 2 -l 1:nvim $PROJECT1" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -t tde: -c $PROJECT1 -n $(basename "$PROJECT1")
tmux split-window -h -t tde:999 -c $PROJECT1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.1 -l nvim
tmux send-keys -t tde:999.1 Enter
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

run_test "Multiple project directories with default panes" "./tde $PROJECT1 $PROJECT2" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -t tde: -c $PROJECT1 -n project1
tmux select-pane -t tde:999.1
tmux new-window -t tde: -c $PROJECT2 -n project2
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

run_test "Multiple project directories with 3 panes" "./tde -p 3 $PROJECT1 $PROJECT2" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -t tde: -c $PROJECT1 -n project1
tmux split-window -h -t tde:999 -c $PROJECT1
tmux split-window -t tde:999.2 -c $PROJECT1
tmux select-layout -E -t tde:999.2
tmux select-pane -t tde:999.1
tmux new-window -t tde: -c $PROJECT2 -n project2
tmux split-window -h -t tde:999 -c $PROJECT2
tmux split-window -t tde:999.2 -c $PROJECT2
tmux select-layout -E -t tde:999.2
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

run_test "Multiple project directories with a launch command in pane 1" "./tde -l 1:ls -p 2 $PROJECT1 $PROJECT2" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -t tde: -c $PROJECT1 -n project1
tmux split-window -h -t tde:999 -c $PROJECT1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.1 -l ls
tmux send-keys -t tde:999.1 Enter
tmux select-pane -t tde:999.1
tmux new-window -t tde: -c $PROJECT2 -n project2
tmux split-window -h -t tde:999 -c $PROJECT2
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.1 -l ls
tmux send-keys -t tde:999.1 Enter
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

run_test "Multiple project directories with a launch command in pane 2" "./tde -l '2:git status' -p 2 $PROJECT1 $PROJECT2" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -t tde: -c $PROJECT1 -n project1
tmux split-window -h -t tde:999 -c $PROJECT1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.2 -l git status
tmux send-keys -t tde:999.2 Enter
tmux select-pane -t tde:999.1
tmux new-window -t tde: -c $PROJECT2 -n project2
tmux split-window -h -t tde:999 -c $PROJECT2
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.2 -l git status
tmux send-keys -t tde:999.2 Enter
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

run_test "Multiple project directories with a launch command in pane 3" "./tde -l 3:htop -p 3 $PROJECT1 $PROJECT2" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -t tde: -c $PROJECT1 -n project1
tmux split-window -h -t tde:999 -c $PROJECT1
tmux split-window -t tde:999.2 -c $PROJECT1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.3 -l htop
tmux send-keys -t tde:999.3 Enter
tmux select-pane -t tde:999.1
tmux new-window -t tde: -c $PROJECT2 -n project2
tmux split-window -h -t tde:999 -c $PROJECT2
tmux split-window -t tde:999.2 -c $PROJECT2
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.3 -l htop
tmux send-keys -t tde:999.3 Enter
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

run_test "Multiple project directories with multiple launch commands" "./tde -l 1:nvim -l '2:git status' -p 2 $PROJECT1 $PROJECT2" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -t tde: -c $PROJECT1 -n project1
tmux split-window -h -t tde:999 -c $PROJECT1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.1 -l nvim
tmux send-keys -t tde:999.1 Enter
tmux send-keys -t tde:999.2 -l git status
tmux send-keys -t tde:999.2 Enter
tmux select-pane -t tde:999.1
tmux new-window -t tde: -c $PROJECT2 -n project2
tmux split-window -h -t tde:999 -c $PROJECT2
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.1 -l nvim
tmux send-keys -t tde:999.1 Enter
tmux send-keys -t tde:999.2 -l git status
tmux send-keys -t tde:999.2 Enter
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

run_test "Single project directory with 4 panes" "./tde -p 4 $PROJECT1" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -t tde: -c $PROJECT1 -n project1
tmux split-window -h -t tde:999 -c $PROJECT1
tmux split-window -t tde:999.2 -c $PROJECT1
tmux split-window -t tde:999.2 -c $PROJECT1
tmux select-layout -E -t tde:999.2
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

run_test "Single project directory with 4 panes and multiple launch commands" "./tde -p 4 -l 1:ls -l '2:git status' $PROJECT1" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -t tde: -c $PROJECT1 -n project1
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

run_test "Single project directory with 4 panes and a launch command in pane 4" "./tde -p 4 -l '4:tail -f /var/log/syslog' $PROJECT1" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -t tde: -c $PROJECT1 -n project1
tmux split-window -h -t tde:999 -c $PROJECT1
tmux split-window -t tde:999.2 -c $PROJECT1
tmux split-window -t tde:999.2 -c $PROJECT1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.4 -l tail -f /var/log/syslog
tmux send-keys -t tde:999.4 Enter
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

run_test "Multiple project directories with 5 panes and a launch command in pane 1" "./tde -p 5 -l 1:nvim $PROJECT1 $PROJECT2" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -t tde: -c $PROJECT1 -n project1
tmux split-window -h -t tde:999 -c $PROJECT1
tmux split-window -t tde:999.2 -c $PROJECT1
tmux split-window -t tde:999.2 -c $PROJECT1
tmux split-window -t tde:999.2 -c $PROJECT1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.1 -l nvim
tmux send-keys -t tde:999.1 Enter
tmux select-pane -t tde:999.1
tmux new-window -t tde: -c $PROJECT2 -n project2
tmux split-window -h -t tde:999 -c $PROJECT2
tmux split-window -t tde:999.2 -c $PROJECT2
tmux split-window -t tde:999.2 -c $PROJECT2
tmux split-window -t tde:999.2 -c $PROJECT2
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.1 -l nvim
tmux send-keys -t tde:999.1 Enter
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

run_test "Multiple project directories with 5 panes and a launch command in pane 3" "./tde -p 5 -l 3:htop $PROJECT1 $PROJECT2" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -t tde: -c $PROJECT1 -n project1
tmux split-window -h -t tde:999 -c $PROJECT1
tmux split-window -t tde:999.2 -c $PROJECT1
tmux split-window -t tde:999.2 -c $PROJECT1
tmux split-window -t tde:999.2 -c $PROJECT1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.3 -l htop
tmux send-keys -t tde:999.3 Enter
tmux select-pane -t tde:999.1
tmux new-window -t tde: -c $PROJECT2 -n project2
tmux split-window -h -t tde:999 -c $PROJECT2
tmux split-window -t tde:999.2 -c $PROJECT2
tmux split-window -t tde:999.2 -c $PROJECT2
tmux split-window -t tde:999.2 -c $PROJECT2
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.3 -l htop
tmux send-keys -t tde:999.3 Enter
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

run_test "Multiple project directories with 5 panes and a launch command in pane 5" "./tde -p 5 -l 5:ps $PROJECT1 $PROJECT2" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -t tde: -c $PROJECT1 -n project1
tmux split-window -h -t tde:999 -c $PROJECT1
tmux split-window -t tde:999.2 -c $PROJECT1
tmux split-window -t tde:999.2 -c $PROJECT1
tmux split-window -t tde:999.2 -c $PROJECT1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.5 -l ps
tmux send-keys -t tde:999.5 Enter
tmux select-pane -t tde:999.1
tmux new-window -t tde: -c $PROJECT2 -n project2
tmux split-window -h -t tde:999 -c $PROJECT2
tmux split-window -t tde:999.2 -c $PROJECT2
tmux split-window -t tde:999.2 -c $PROJECT2
tmux split-window -t tde:999.2 -c $PROJECT2
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.5 -l ps
tmux send-keys -t tde:999.5 Enter
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

run_test "Multiple project directories with 1 pane and a launch command in pane 1" "./tde -p 1 -l 1:ls $PROJECT1 $PROJECT2" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -t tde: -c $PROJECT1 -n project1
tmux send-keys -t tde:999.1 -l ls
tmux send-keys -t tde:999.1 Enter
tmux select-pane -t tde:999.1
tmux new-window -t tde: -c $PROJECT2 -n project2
tmux send-keys -t tde:999.1 -l ls
tmux send-keys -t tde:999.1 Enter
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

run_test "Multiple project directories with 4 panes and multiple launch commands" "./tde -p 4 -l 1:nvim -l '2:git status' -l 3:htop -l 4:ps $PROJECT1 $PROJECT2" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -t tde: -c $PROJECT1 -n project1
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
tmux new-window -t tde: -c $PROJECT2 -n project2
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

run_test "Illegal command option" "./tde -X $PROJECT1" "Unknown option: -X" 1

run_test "Multiple project directories with 2 panes, and a launch command with a complex string" "./tde -p 2 -l '1:echo \"Hello World\!\" && sleep 1' $PROJECT1 $PROJECT2" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-window -t tde: -c $PROJECT1 -n project1
tmux split-window -h -t tde:999 -c $PROJECT1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.1 -l echo \"Hello World\!\" && sleep 1
tmux send-keys -t tde:999.1 Enter
tmux select-pane -t tde:999.1
tmux new-window -t tde: -c $PROJECT2 -n project2
tmux split-window -h -t tde:999 -c $PROJECT2
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.1 -l echo \"Hello World\!\" && sleep 1
tmux send-keys -t tde:999.1 Enter
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

run_test "Tesst Case 21: Help message (first two lines)" "./tde --help | head -n 2" "NAME
    tde - open project workspaces"

# Tests for invalid command options
run_test "Invalid --panes value '0'" "./tde -p 0 $PROJECT1" "Error: PANES must be between 1 and 9" 1
run_test "Invalid --panes value '10'" "./tde --panes 10 $PROJECT1" "Error: PANES must be between 1 and 9" 1
run_test "Invalid --panes value 'abc'" "./tde -p abc $PROJECT1" "Error: PANES must be between 1 and 9" 1
run_test "Invalid --launch pane number '0'" "./tde -p 2 -l 0:ls $PROJECT1" "Error: Invalid launch option pane number '0'. Must be between 1 and 2" 1
run_test "Invalid --launch pane number (too high)" "./tde -p 2 -l 3:ls $PROJECT1" "Error: Invalid launch option pane number '3'. Must be between 1 and 2" 1
run_test "Invalid --launch pane number (non-numeric)" "./tde -p 2 -l x:ls $PROJECT1" "Error: Invalid launch option pane number 'x'. Must be between 1 and 2" 1
run_test "Invalid --launch value" "./tde -l bad-launch $PROJECT1" "Error: Invalid launch option 'bad-launch'" 1

run_test "New Session Mode inside tmux" "./tde" "Error: No project directories specified; cannot run New Session Mode inside tmux" 1
run_test "Missing project directory" "./tde /nonexistent/path" "Error: Project directory does not exist: '/nonexistent/path'" 1

#
# Simulate not running in a tmux window
#
TMUX=""

run_test "Current Session Mode outside tmux" "./tde $PROJECT1" "Error: Project directory command-line arguments specified but not running inside a tmux session" 1

# Tests for configuration file
run_test "No project directories specified" "./tde" "Error: No project directories specified" 1

write_conf "/tmp/test-tde/project1"

run_test "Configuration file with single directory-only entry" "./tde" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-session -d -s tde -c /tmp/test-tde/project1 -n project1
tmux select-pane -t tde:999.1
tmux select-window -t tde:999
tmux attach-session -t tde" 0

run_test "Command-line panes option with directory-only configuration file entry" "./tde -p 2" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-session -d -s tde -c /tmp/test-tde/project1 -n project1
tmux split-window -h -t tde:999 -c /tmp/test-tde/project1
tmux select-layout -E -t tde:999.2
tmux select-pane -t tde:999.1
tmux select-window -t tde:999
tmux attach-session -t tde" 0

run_test "Command-line launch option with directory-only configuration file entry" "./tde -l 1:nvim" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-session -d -s tde -c /tmp/test-tde/project1 -n project1
tmux send-keys -t tde:999.1 -l nvim
tmux send-keys -t tde:999.1 Enter
tmux select-pane -t tde:999.1
tmux select-window -t tde:999
tmux attach-session -t tde" 0

run_test "Command-line panes and launch options with directory-only configuration file entry" "./tde -l 1:nvim -p 2 -l 2:lazygit" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-session -d -s tde -c /tmp/test-tde/project1 -n project1
tmux split-window -h -t tde:999 -c /tmp/test-tde/project1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.1 -l nvim
tmux send-keys -t tde:999.1 Enter
tmux send-keys -t tde:999.2 -l lazygit
tmux send-keys -t tde:999.2 Enter
tmux select-pane -t tde:999.1
tmux select-window -t tde:999
tmux attach-session -t tde" 0

write_conf "-l 1:nvim -l '2:git status' -p 2 /tmp/test-tde/project1
--panes 3 --launch 1:nvim --launch 3:lazygit /tmp/test-tde/project2"

run_test "Configuration file with two project directories and configuration options" "./tde" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-session -d -s tde -c /tmp/test-tde/project1 -n project1
tmux split-window -h -t tde:999 -c /tmp/test-tde/project1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.1 -l nvim
tmux send-keys -t tde:999.1 Enter
tmux send-keys -t tde:999.2 -l git status
tmux send-keys -t tde:999.2 Enter
tmux select-pane -t tde:999.1
tmux new-window -t tde: -c /tmp/test-tde/project2 -n project2
tmux split-window -h -t tde:999 -c /tmp/test-tde/project2
tmux split-window -t tde:999.2 -c /tmp/test-tde/project2
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.1 -l nvim
tmux send-keys -t tde:999.1 Enter
tmux send-keys -t tde:999.3 -l lazygit
tmux send-keys -t tde:999.3 Enter
tmux select-pane -t tde:999.1
tmux select-window -t tde:999
tmux attach-session -t tde" 0

write_conf "-l 1:nvim -l '2:git status' -p 2 /tmp/test-tde/project1
/tmp/test-tde/project2
--panes 3 --launch 1:nvim --launch 3:lazygit /tmp/test-tde/project3"

run_test "Configuration file with three project directories, one is directory-only" "./tde --panes 4" "tmux set-option -t tde -g base-index 1
tmux set-window-option -t tde -g pane-base-index 1
tmux new-session -d -s tde -c /tmp/test-tde/project1 -n project1
tmux split-window -h -t tde:999 -c /tmp/test-tde/project1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.1 -l nvim
tmux send-keys -t tde:999.1 Enter
tmux send-keys -t tde:999.2 -l git status
tmux send-keys -t tde:999.2 Enter
tmux select-pane -t tde:999.1
tmux new-window -t tde: -c /tmp/test-tde/project2 -n project2
tmux split-window -h -t tde:999 -c /tmp/test-tde/project2
tmux split-window -t tde:999.2 -c /tmp/test-tde/project2
tmux split-window -t tde:999.2 -c /tmp/test-tde/project2
tmux select-layout -E -t tde:999.2
tmux select-pane -t tde:999.1
tmux new-window -t tde: -c /tmp/test-tde/project3 -n project3
tmux split-window -h -t tde:999 -c /tmp/test-tde/project3
tmux split-window -t tde:999.2 -c /tmp/test-tde/project3
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.1 -l nvim
tmux send-keys -t tde:999.1 Enter
tmux send-keys -t tde:999.3 -l lazygit
tmux send-keys -t tde:999.3 Enter
tmux select-pane -t tde:999.1
tmux select-window -t tde:999
tmux attach-session -t tde" 0

run_test "Bad session name" "./tde -s 'bad#session#name'" "Error: SESSION_NAME must contain only alphanumeric characters, dashes, underscores, or periods: 'bad#session#name'" 1

CONFIG_FILE="$CONFIG_DIR/session-name.conf"
run_test "Missing session configuration file" "./tde -s 'session-name'" "Warning: Configuration file '/tmp/test-tde/.config/tde/session-name.conf' not found
Error: No project directories specified" 1

exit
