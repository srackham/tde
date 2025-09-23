#!/usr/bin/env bash

trap 'echo; echo "$TEST_COUNT tests passed!"' EXIT

set -euo pipefail

TEST_DIR=/tmp/test-tde
TDE_CONFIG_DIR="$TEST_DIR/.config/tde"
TDE_CLIENT_COUNT=0 # Number of clients attached to the current session

# For testing purposes the TMUX environment variable is the name of the client session,
# i.e the name of the session in the executing terminal, or empty if not inside a tmux session.
TMUX=tde

setup() {
    mkdir -p "${TEST_DIR:?}"
    mkdir -p "${TDE_CONFIG_DIR:?}"
    rm -rf "${TDE_CONFIG_DIR:?}"/*
    touch "${TDE_CONFIG_DIR:?}"/tde.conf # Default configuration file
    PROJECT1="$TEST_DIR/project1"
    PROJECT2="$TEST_DIR/project2"
    PROJECT3="$TEST_DIR/project3"
    mkdir -p $PROJECT1 $PROJECT2 $PROJECT3
}
setup

# Function to run a test
run_test() {
    local test_name="$1"
    local command="$2"
    local expected_output="$3"
    local expected_exit_code="${4:-0}" # Defaults to 0
    local env_vars="TDE_TEST=true TDE_CLIENT_COUNT=${TDE_CLIENT_COUNT:?} TMUX=$TMUX TDE_CONFIG_DIR=\"${TDE_CONFIG_DIR:?}\""

    # Execute the command and capture its output and exit code
    set +e
    actual_output=$(bash -c "$env_vars $command 2>&1")
    actual_exit_code=$?
    set -e

    # Normalize line endings for comparison
    # shellcheck disable=SC2001
    actual_output=$(echo "$actual_output" | sed 's/\r$//')
    # shellcheck disable=SC2001
    expected_output=$(echo "$expected_output" | sed 's/\r$//')

    local pass=true

    echo "Running test: $test_name"
    echo "              $env_vars $command"

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
    local session="$1"
    local content="$2"
    local config_file="${TDE_CONFIG_DIR:?}"/$session.conf
    # Overwrite config file
    printf "%s\n" "$content" >"$config_file"
}

TEST_COUNT=0
TDE_CLIENT_COUNT=1
TMUX= # Outside a tmux session
run_test "Single directory from outside tmux" "./tde $PROJECT1" "tmux new-window -t tde: -c $PROJECT1 -n $(basename "$PROJECT1")
tmux set-option -t tde:999 pane-base-index 1
tmux select-pane -t tde:999.1
tmux select-window -t tde:999
tde: warning: tmux session 'tde' is attached to 1 other client terminal
tmux attach-session -t tde"

TDE_CLIENT_COUNT=0
run_test "Dry-run with 3 columns; session mysession" "./tde -p 4 --columns 3 -s mysession -w mywindow $PROJECT1" "tmux new-session -d -s mysession -c /tmp/test-tde/project1 -n mywindow
tmux set-option -t mysession:999 pane-base-index 1
tmux split-window -h -t mysession:999 -c /tmp/test-tde/project1
tmux split-window -h -t mysession:999 -c /tmp/test-tde/project1
tmux split-window -v -t mysession:999 -c /tmp/test-tde/project1
tmux select-layout -E -t mysession:999.1
tmux select-layout -E -t mysession:999.3
tmux select-pane -t mysession:999.1
tmux select-window -t mysession:999
tmux attach-session -t mysession"

TDE_CLIENT_COUNT=1
TMUX=tde # Inside a tmux session called 'tde'
run_test "Single directory from inside tmux" "./tde $PROJECT1" "tmux new-window -t tde: -c $PROJECT1 -n $(basename "$PROJECT1")
tmux set-option -t tde:999 pane-base-index 1
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

run_test "--window-name option on command-line; verbose option" "./tde --verbose -w mywindow $PROJECT1" "tmux new-window -t tde: -c /tmp/test-tde/project1 -n mywindow
tmux set-option -t tde:999 pane-base-index 1
tmux select-pane -t tde:999.1
tmux select-window -t tde:999
tmux command file '/tmp/test-tde/.config/tde/_default.tmux' not found
tmux command file '/tmp/test-tde/.config/tde/tde.tmux' not found"

run_test "Dry-run with 2 panes" "./tde -p 2 $PROJECT1" "tmux new-window -t tde: -c $PROJECT1 -n $(basename "$PROJECT1")
tmux set-option -t tde:999 pane-base-index 1
tmux split-window -h -t tde:999 -c $PROJECT1
tmux select-layout -E -t tde:999.1
tmux select-layout -E -t tde:999.2
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

run_test "Dry-run with 4 panes" "./tde -p 4 $PROJECT1" "tmux new-window -t tde: -c /tmp/test-tde/project1 -n project1
tmux set-option -t tde:999 pane-base-index 1
tmux split-window -h -t tde:999 -c /tmp/test-tde/project1
tmux split-window -v -t tde:999 -c /tmp/test-tde/project1
tmux split-window -v -t tde:999 -c /tmp/test-tde/project1
tmux select-layout -E -t tde:999.1
tmux select-layout -E -t tde:999.2
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

run_test "Dry-run with 4 columns" "./tde -p 4 -x 4 $PROJECT1" "tmux new-window -t tde: -c /tmp/test-tde/project1 -n project1
tmux set-option -t tde:999 pane-base-index 1
tmux split-window -h -t tde:999 -c /tmp/test-tde/project1
tmux split-window -h -t tde:999 -c /tmp/test-tde/project1
tmux split-window -h -t tde:999 -c /tmp/test-tde/project1
tmux select-layout -E -t tde:999.1
tmux select-layout -E -t tde:999.4
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

run_test "Dry-run with 2 panes and explicit pane 1 launch command" "./tde -p 2 -l 1:nvim $PROJECT1" "tmux new-window -t tde: -c $PROJECT1 -n $(basename "$PROJECT1")
tmux set-option -t tde:999 pane-base-index 1
tmux split-window -h -t tde:999 -c $PROJECT1
tmux select-layout -E -t tde:999.1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.1 -l nvim
tmux send-keys -t tde:999.1 Enter
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

run_test "Dry-run with 2 panes and implicit pane 1 launch command" "./tde -p 2 -l 1:nvim $PROJECT1" "tmux new-window -t tde: -c $PROJECT1 -n $(basename "$PROJECT1")
tmux set-option -t tde:999 pane-base-index 1
tmux split-window -h -t tde:999 -c $PROJECT1
tmux select-layout -E -t tde:999.1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.1 -l nvim
tmux send-keys -t tde:999.1 Enter
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

run_test "Multiple project directories with default panes" "./tde $PROJECT1 $PROJECT2" "tmux new-window -t tde: -c $PROJECT1 -n project1
tmux set-option -t tde:999 pane-base-index 1
tmux select-pane -t tde:999.1
tmux new-window -t tde: -c $PROJECT2 -n project2
tmux set-option -t tde:999 pane-base-index 1
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

run_test "Multiple project directories with 3 panes" "./tde -p 3 $PROJECT1 $PROJECT2" "tmux new-window -t tde: -c $PROJECT1 -n project1
tmux set-option -t tde:999 pane-base-index 1
tmux split-window -h -t tde:999 -c $PROJECT1
tmux split-window -v -t tde:999 -c $PROJECT1
tmux select-layout -E -t tde:999.1
tmux select-layout -E -t tde:999.2
tmux select-pane -t tde:999.1
tmux new-window -t tde: -c $PROJECT2 -n project2
tmux set-option -t tde:999 pane-base-index 1
tmux split-window -h -t tde:999 -c $PROJECT2
tmux split-window -v -t tde:999 -c $PROJECT2
tmux select-layout -E -t tde:999.1
tmux select-layout -E -t tde:999.2
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

run_test "Multiple project directories with a launch command in pane 1" "./tde -l 1:ls -p 2 $PROJECT1 $PROJECT2" "tmux new-window -t tde: -c $PROJECT1 -n project1
tmux set-option -t tde:999 pane-base-index 1
tmux split-window -h -t tde:999 -c $PROJECT1
tmux select-layout -E -t tde:999.1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.1 -l ls
tmux send-keys -t tde:999.1 Enter
tmux select-pane -t tde:999.1
tmux new-window -t tde: -c $PROJECT2 -n project2
tmux set-option -t tde:999 pane-base-index 1
tmux split-window -h -t tde:999 -c $PROJECT2
tmux select-layout -E -t tde:999.1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.1 -l ls
tmux send-keys -t tde:999.1 Enter
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

run_test "Multiple project directories with a launch command in pane 2" "./tde -l '2:git status' -p 2 $PROJECT1 $PROJECT2" "tmux new-window -t tde: -c $PROJECT1 -n project1
tmux set-option -t tde:999 pane-base-index 1
tmux split-window -h -t tde:999 -c $PROJECT1
tmux select-layout -E -t tde:999.1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.2 -l git status
tmux send-keys -t tde:999.2 Enter
tmux select-pane -t tde:999.1
tmux new-window -t tde: -c $PROJECT2 -n project2
tmux set-option -t tde:999 pane-base-index 1
tmux split-window -h -t tde:999 -c $PROJECT2
tmux select-layout -E -t tde:999.1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.2 -l git status
tmux send-keys -t tde:999.2 Enter
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

run_test "Multiple project directories with a launch command in pane 3" "./tde -l 3:htop -p 3 $PROJECT1 $PROJECT2" "tmux new-window -t tde: -c $PROJECT1 -n project1
tmux set-option -t tde:999 pane-base-index 1
tmux split-window -h -t tde:999 -c $PROJECT1
tmux split-window -v -t tde:999 -c $PROJECT1
tmux select-layout -E -t tde:999.1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.3 -l htop
tmux send-keys -t tde:999.3 Enter
tmux select-pane -t tde:999.1
tmux new-window -t tde: -c $PROJECT2 -n project2
tmux set-option -t tde:999 pane-base-index 1
tmux split-window -h -t tde:999 -c $PROJECT2
tmux split-window -v -t tde:999 -c $PROJECT2
tmux select-layout -E -t tde:999.1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.3 -l htop
tmux send-keys -t tde:999.3 Enter
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

run_test "Multiple project directories with multiple launch commands" "./tde -l 1:nvim -l '2:git status' -p 2 $PROJECT1 $PROJECT2" "tmux new-window -t tde: -c $PROJECT1 -n project1
tmux set-option -t tde:999 pane-base-index 1
tmux split-window -h -t tde:999 -c $PROJECT1
tmux select-layout -E -t tde:999.1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.1 -l nvim
tmux send-keys -t tde:999.1 Enter
tmux send-keys -t tde:999.2 -l git status
tmux send-keys -t tde:999.2 Enter
tmux select-pane -t tde:999.1
tmux new-window -t tde: -c $PROJECT2 -n project2
tmux set-option -t tde:999 pane-base-index 1
tmux split-window -h -t tde:999 -c $PROJECT2
tmux select-layout -E -t tde:999.1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.1 -l nvim
tmux send-keys -t tde:999.1 Enter
tmux send-keys -t tde:999.2 -l git status
tmux send-keys -t tde:999.2 Enter
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

run_test "Single project directory with 4 panes" "./tde -p 4 $PROJECT1" "tmux new-window -t tde: -c $PROJECT1 -n project1
tmux set-option -t tde:999 pane-base-index 1
tmux split-window -h -t tde:999 -c $PROJECT1
tmux split-window -v -t tde:999 -c $PROJECT1
tmux split-window -v -t tde:999 -c $PROJECT1
tmux select-layout -E -t tde:999.1
tmux select-layout -E -t tde:999.2
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

run_test "Single project directory with 4 panes and multiple launch commands" "./tde -p 4 -l 1:ls -l '2:git status' $PROJECT1" "tmux new-window -t tde: -c $PROJECT1 -n project1
tmux set-option -t tde:999 pane-base-index 1
tmux split-window -h -t tde:999 -c $PROJECT1
tmux split-window -v -t tde:999 -c $PROJECT1
tmux split-window -v -t tde:999 -c $PROJECT1
tmux select-layout -E -t tde:999.1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.1 -l ls
tmux send-keys -t tde:999.1 Enter
tmux send-keys -t tde:999.2 -l git status
tmux send-keys -t tde:999.2 Enter
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

run_test "Single project directory with 4 panes and a launch command in pane 4" "./tde -p 4 -l '4:tail -f /var/log/syslog' $PROJECT1" "tmux new-window -t tde: -c $PROJECT1 -n project1
tmux set-option -t tde:999 pane-base-index 1
tmux split-window -h -t tde:999 -c $PROJECT1
tmux split-window -v -t tde:999 -c $PROJECT1
tmux split-window -v -t tde:999 -c $PROJECT1
tmux select-layout -E -t tde:999.1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.4 -l tail -f /var/log/syslog
tmux send-keys -t tde:999.4 Enter
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

run_test "Multiple project directories with 5 panes and a launch command in pane 1" "./tde -p 5 -l 1:nvim $PROJECT1 $PROJECT2" "tmux new-window -t tde: -c $PROJECT1 -n project1
tmux set-option -t tde:999 pane-base-index 1
tmux split-window -h -t tde:999 -c $PROJECT1
tmux split-window -v -t tde:999 -c $PROJECT1
tmux split-window -v -t tde:999 -c $PROJECT1
tmux split-window -v -t tde:999 -c $PROJECT1
tmux select-layout -E -t tde:999.1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.1 -l nvim
tmux send-keys -t tde:999.1 Enter
tmux select-pane -t tde:999.1
tmux new-window -t tde: -c $PROJECT2 -n project2
tmux set-option -t tde:999 pane-base-index 1
tmux split-window -h -t tde:999 -c $PROJECT2
tmux split-window -v -t tde:999 -c $PROJECT2
tmux split-window -v -t tde:999 -c $PROJECT2
tmux split-window -v -t tde:999 -c $PROJECT2
tmux select-layout -E -t tde:999.1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.1 -l nvim
tmux send-keys -t tde:999.1 Enter
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

run_test "Multiple project directories with 5 panes and a launch command in pane 3" "./tde -p 5 -l 3:htop $PROJECT1 $PROJECT2" "tmux new-window -t tde: -c $PROJECT1 -n project1
tmux set-option -t tde:999 pane-base-index 1
tmux split-window -h -t tde:999 -c $PROJECT1
tmux split-window -v -t tde:999 -c $PROJECT1
tmux split-window -v -t tde:999 -c $PROJECT1
tmux split-window -v -t tde:999 -c $PROJECT1
tmux select-layout -E -t tde:999.1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.3 -l htop
tmux send-keys -t tde:999.3 Enter
tmux select-pane -t tde:999.1
tmux new-window -t tde: -c $PROJECT2 -n project2
tmux set-option -t tde:999 pane-base-index 1
tmux split-window -h -t tde:999 -c $PROJECT2
tmux split-window -v -t tde:999 -c $PROJECT2
tmux split-window -v -t tde:999 -c $PROJECT2
tmux split-window -v -t tde:999 -c $PROJECT2
tmux select-layout -E -t tde:999.1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.3 -l htop
tmux send-keys -t tde:999.3 Enter
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

run_test "Multiple project directories with 5 panes and a launch command in pane 5" "./tde -p 5 -l 5:ps $PROJECT1 $PROJECT2" "tmux new-window -t tde: -c $PROJECT1 -n project1
tmux set-option -t tde:999 pane-base-index 1
tmux split-window -h -t tde:999 -c $PROJECT1
tmux split-window -v -t tde:999 -c $PROJECT1
tmux split-window -v -t tde:999 -c $PROJECT1
tmux split-window -v -t tde:999 -c $PROJECT1
tmux select-layout -E -t tde:999.1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.5 -l ps
tmux send-keys -t tde:999.5 Enter
tmux select-pane -t tde:999.1
tmux new-window -t tde: -c $PROJECT2 -n project2
tmux set-option -t tde:999 pane-base-index 1
tmux split-window -h -t tde:999 -c $PROJECT2
tmux split-window -v -t tde:999 -c $PROJECT2
tmux split-window -v -t tde:999 -c $PROJECT2
tmux split-window -v -t tde:999 -c $PROJECT2
tmux select-layout -E -t tde:999.1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.5 -l ps
tmux send-keys -t tde:999.5 Enter
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

run_test "Multiple project directories with 1 pane and a launch command in pane 1" "./tde -p 1 -l 1:ls $PROJECT1 $PROJECT2" "tmux new-window -t tde: -c $PROJECT1 -n project1
tmux set-option -t tde:999 pane-base-index 1
tmux send-keys -t tde:999.1 -l ls
tmux send-keys -t tde:999.1 Enter
tmux select-pane -t tde:999.1
tmux new-window -t tde: -c $PROJECT2 -n project2
tmux set-option -t tde:999 pane-base-index 1
tmux send-keys -t tde:999.1 -l ls
tmux send-keys -t tde:999.1 Enter
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

run_test "Multiple project directories with 4 panes and multiple launch commands" "./tde -p 4 -l 1:nvim -l '2:git status' -l 3:htop -l 4:ps $PROJECT1 $PROJECT2" "tmux new-window -t tde: -c $PROJECT1 -n project1
tmux set-option -t tde:999 pane-base-index 1
tmux split-window -h -t tde:999 -c $PROJECT1
tmux split-window -v -t tde:999 -c $PROJECT1
tmux split-window -v -t tde:999 -c $PROJECT1
tmux select-layout -E -t tde:999.1
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
tmux set-option -t tde:999 pane-base-index 1
tmux split-window -h -t tde:999 -c $PROJECT2
tmux split-window -v -t tde:999 -c $PROJECT2
tmux split-window -v -t tde:999 -c $PROJECT2
tmux select-layout -E -t tde:999.1
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

run_test "Illegal command option" "./tde -X $PROJECT1" "tde: error: unknown option: -X" 1

run_test "Multiple project directories with 2 panes, and a launch command with a complex string" "./tde -p 2 -l '1:echo \"Hello World\!\" && sleep 1' $PROJECT1 $PROJECT2" "tmux new-window -t tde: -c $PROJECT1 -n project1
tmux set-option -t tde:999 pane-base-index 1
tmux split-window -h -t tde:999 -c $PROJECT1
tmux select-layout -E -t tde:999.1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.1 -l echo \"Hello World\!\" && sleep 1
tmux send-keys -t tde:999.1 Enter
tmux select-pane -t tde:999.1
tmux new-window -t tde: -c $PROJECT2 -n project2
tmux set-option -t tde:999 pane-base-index 1
tmux split-window -h -t tde:999 -c $PROJECT2
tmux select-layout -E -t tde:999.1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.1 -l echo \"Hello World\!\" && sleep 1
tmux send-keys -t tde:999.1 Enter
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

run_test "Help message (first two lines)" "./tde --help | head -n 2" "NAME
    tde - open project workspaces with tmux"
run_test "Just reattach to existing session if no project directory arguments are specified" "./tde" "" 0

# Tests for invalid command options
run_test "Invalid --panes value '0'" "./tde -p 0 $PROJECT1" "tde: error: invalid --panes option '0': must be between 1 and 9" 1
run_test "Invalid --panes value '10'" "./tde --panes 10 $PROJECT1" "tde: error: invalid --panes option '10': must be between 1 and 9" 1
run_test "Invalid --panes value 'abc'" "./tde -p abc $PROJECT1" "tde: error: invalid --panes option 'abc': must be between 1 and 9" 1
run_test "Invalid --launch pane number '0'" "./tde -p 2 -l 0:ls $PROJECT1" "tde: error: invalid --launch option pane number '0': must be between 1 and 2" 1
run_test "Invalid --launch pane number (too high)" "./tde -p 2 -l 3:ls $PROJECT1" "tde: error: invalid --launch option pane number '3': must be between 1 and 2" 1
run_test "Invalid --launch pane number (non-numeric)" "./tde -p 2 -l x:ls $PROJECT1" "tde: error: invalid --launch option pane number 'x': must be between 1 and 2" 1
run_test "Invalid --launch value" "./tde -l bad-launch $PROJECT1" "tde: error: invalid --launch option 'bad-launch'" 1
run_test "Missing project directory" "./tde /nonexistent/path" "tde: error: project directory not found: '/nonexistent/path'" 1
run_test "Invalid --columns value 'abc'" "./tde -x abc -p 2 $PROJECT1" "tde: error: invalid --columns option 'abc': must be between 1 and 9" 1
run_test "Invalid --columns value '9'" "./tde -x 0 -p 2 $PROJECT1" "tde: error: invalid --columns option '0': must be between 1 and 9" 1
run_test "Invalid --focus value '0'" "./tde -f 0 $PROJECT1" "tde: error: invalid --focus option '0': must be between 1 and 9" 1
run_test "Invalid --focus value '2'" "./tde -f 2 $PROJECT1" "tde: error: invalid --focus option '2': must be between 1 and 1" 1
run_test "Invalid --columns value '3'" "./tde -x 3 -p 2 $PROJECT1" "tde: error: invalid --columns option '3': must be between 1 and 2" 1

run_test "Duplicate project directories arguments" "./tde '$PROJECT1' '$PROJECT1'" "tmux new-window -t tde: -c /tmp/test-tde/project1 -n project1
tmux set-option -t tde:999 pane-base-index 1
tmux select-pane -t tde:999.1
tde: warning: duplicate project workspace name: 'project1' exists in session 'tde', skipping
tmux select-window -t tde:999"

TDE_CLIENT_COUNT=0

# Tests for configuration file
run_test "No project directories specified" "./tde" "tde: error: session does not exist: 'tde'" 1

write_conf tde "/tmp/test-tde/project1"
run_test "Configuration file with single directory-only entry" "./tde" "tmux new-session -d -s tde -c /tmp/test-tde/project1 -n project1
tmux set-option -t tde:999 pane-base-index 1
tmux select-pane -t tde:999.1
tmux select-window -t tde:999" 0

run_test "Duplicate project workspace name" "./tde '$PROJECT1'" "tmux new-session -d -s tde -c /tmp/test-tde/project1 -n project1
tmux set-option -t tde:999 pane-base-index 1
tmux select-pane -t tde:999.1
tde: warning: duplicate project workspace name: 'project1' exists in session 'tde', skipping
tmux select-window -t tde:999"

run_test "Command-line panes option with directory-only configuration file entry" "./tde -p 2" "tmux new-session -d -s tde -c /tmp/test-tde/project1 -n project1
tmux set-option -t tde:999 pane-base-index 1
tmux split-window -h -t tde:999 -c /tmp/test-tde/project1
tmux select-layout -E -t tde:999.1
tmux select-layout -E -t tde:999.2
tmux select-pane -t tde:999.1
tmux select-window -t tde:999" 0

run_test "Command-line launch option with directory-only configuration file entry" "./tde -l 1:nvim" "tmux new-session -d -s tde -c /tmp/test-tde/project1 -n project1
tmux set-option -t tde:999 pane-base-index 1
tmux send-keys -t tde:999.1 -l nvim
tmux send-keys -t tde:999.1 Enter
tmux select-pane -t tde:999.1
tmux select-window -t tde:999" 0

run_test "Command-line panes and launch options with directory-only configuration file entry" "./tde -l 1:nvim -p 2 -l 2:lazygit" "tmux new-session -d -s tde -c /tmp/test-tde/project1 -n project1
tmux set-option -t tde:999 pane-base-index 1
tmux split-window -h -t tde:999 -c /tmp/test-tde/project1
tmux select-layout -E -t tde:999.1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.1 -l nvim
tmux send-keys -t tde:999.1 Enter
tmux send-keys -t tde:999.2 -l lazygit
tmux send-keys -t tde:999.2 Enter
tmux select-pane -t tde:999.1
tmux select-window -t tde:999" 0

write_conf tde "-l 1:nvim -l '2:git status' -p 2 /tmp/test-tde/project1
--panes 3 --focus 2 --window-name mywindow --launch 1:nvim --launch 3:lazygit /tmp/test-tde/project2"

run_test "Configuration file with two project directories and configuration options" "./tde" "tmux new-session -d -s tde -c /tmp/test-tde/project1 -n project1
tmux set-option -t tde:999 pane-base-index 1
tmux split-window -h -t tde:999 -c /tmp/test-tde/project1
tmux select-layout -E -t tde:999.1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.1 -l nvim
tmux send-keys -t tde:999.1 Enter
tmux send-keys -t tde:999.2 -l git status
tmux send-keys -t tde:999.2 Enter
tmux select-pane -t tde:999.1
tmux new-window -t tde: -c /tmp/test-tde/project2 -n mywindow
tmux set-option -t tde:999 pane-base-index 1
tmux split-window -h -t tde:999 -c /tmp/test-tde/project2
tmux split-window -v -t tde:999 -c /tmp/test-tde/project2
tmux select-layout -E -t tde:999.1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.1 -l nvim
tmux send-keys -t tde:999.1 Enter
tmux send-keys -t tde:999.3 -l lazygit
tmux send-keys -t tde:999.3 Enter
tmux select-pane -t tde:999.2
tmux select-window -t tde:999" 0

write_conf tde "-l 1:nvim -l '2:git status' -p 2 /tmp/test-tde/project1
/tmp/test-tde/project2
--panes 3 --launch 1:nvim --launch 3:lazygit /tmp/test-tde/project3"

run_test "Configuration file with three project directories, one is directory-only" "./tde --panes 4" "tmux new-session -d -s tde -c /tmp/test-tde/project1 -n project1
tmux set-option -t tde:999 pane-base-index 1
tmux split-window -h -t tde:999 -c /tmp/test-tde/project1
tmux select-layout -E -t tde:999.1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.1 -l nvim
tmux send-keys -t tde:999.1 Enter
tmux send-keys -t tde:999.2 -l git status
tmux send-keys -t tde:999.2 Enter
tmux select-pane -t tde:999.1
tmux new-window -t tde: -c /tmp/test-tde/project2 -n project2
tmux set-option -t tde:999 pane-base-index 1
tmux split-window -h -t tde:999 -c /tmp/test-tde/project2
tmux split-window -v -t tde:999 -c /tmp/test-tde/project2
tmux split-window -v -t tde:999 -c /tmp/test-tde/project2
tmux select-layout -E -t tde:999.1
tmux select-layout -E -t tde:999.2
tmux select-pane -t tde:999.1
tmux new-window -t tde: -c /tmp/test-tde/project3 -n project3
tmux set-option -t tde:999 pane-base-index 1
tmux split-window -h -t tde:999 -c /tmp/test-tde/project3
tmux split-window -v -t tde:999 -c /tmp/test-tde/project3
tmux select-layout -E -t tde:999.1
tmux select-layout -E -t tde:999.2
tmux send-keys -t tde:999.1 -l nvim
tmux send-keys -t tde:999.1 Enter
tmux send-keys -t tde:999.3 -l lazygit
tmux send-keys -t tde:999.3 Enter
tmux select-pane -t tde:999.1
tmux select-window -t tde:999" 0

run_test "Bad session name" "./tde -s 'bad#session#name'" "tde: error: invalid --session option 'bad#session#name': must begin with an alpha numberic character and can only contain only alphanumeric characters, dashes, underscores, or periods" 1

run_test "--config-file option: missing configuration file" "./tde --config-file '$TDE_CONFIG_DIR/missing-file.conf'" "tde: error: session does not exist: 'tde'" 1
run_test "--config-file option: missing configuration file; verbose" "./tde -v --config-file '$TDE_CONFIG_DIR/missing-file.conf'" "configuration file '/tmp/test-tde/.config/tde/_default.conf' not found
configuration file '/tmp/test-tde/.config/tde/missing-file.conf' not found
tde: error: session does not exist: 'tde'" 1

run_test "--sesion option: missing configuration file warning" "./tde -s 'session-name'" "tde: error: session does not exist: 'session-name'" 1

TMUX=another-session
run_test "Missing session configuration file warning; refusing attachment; one project directory argument" "./tde -s 'session-name' '$PROJECT1'" "tmux new-session -d -s session-name -c /tmp/test-tde/project1 -n project1
tmux set-option -t session-name:999 pane-base-index 1
tmux select-pane -t session-name:999.1
tmux select-window -t session-name:999
tde: warning: refusing to attach nested tmux session 'session-name' inside tmux session 'another-session'"

write_conf session-name "/tmp/test-tde/project1"
TMUX=another-session
run_test "Single-entry configuration file; nested session warning" "./tde -s 'session-name'" "tmux new-session -d -s session-name -c /tmp/test-tde/project1 -n project1
tmux set-option -t session-name:999 pane-base-index 1
tmux select-pane -t session-name:999.1
tmux select-window -t session-name:999
tde: warning: refusing to attach nested tmux session 'session-name' inside tmux session 'another-session'"

TMUX=
write_conf session-name ""
run_test "Missing session configuration file warning; one project directory argument" "./tde -s 'session-name' '$PROJECT1'" "tmux new-session -d -s session-name -c /tmp/test-tde/project1 -n project1
tmux set-option -t session-name:999 pane-base-index 1
tmux select-pane -t session-name:999.1
tmux select-window -t session-name:999
tmux attach-session -t session-name"

exit
