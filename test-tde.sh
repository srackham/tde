#!/usr/bin/env bash

trap 'echo; echo "$TEST_COUNT tests passed!"' EXIT

set -euo pipefail
# set -x # Turn on execution trace

TEST_DIR=/tmp/test-tde
TDE_CONFIG_DIR="$TEST_DIR/.config/tde"
TDE_CURRENT_SESSION= # The name of the current tmux session or blank if not in tmux terminal
TDE_SESSIONS=        # A list of tmux sesssions

setup() {
    mkdir -p "${TEST_DIR:?}"
    mkdir -p "${TDE_CONFIG_DIR:?}"
    rm -rf "${TDE_CONFIG_DIR:?}"/*
    # touch "${TDE_CONFIG_DIR:?}"/tde.tde # Default configuration file
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
    local env_vars="TDE_TEST=true TDE_CURRENT_SESSION=\"$TDE_CURRENT_SESSION\" TDE_SESSIONS=\"$TDE_SESSIONS\" TDE_CONFIG_DIR=\"${TDE_CONFIG_DIR:?}\""

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

# Write configuration file.
write_conf() {
    local filename="$1"
    local content="$2"
    printf "%s\n" "$content" >"${TDE_CONFIG_DIR:?}/$filename"
}

# Delete configuration file.
rm_conf() {
    local filename="$1"
    rm "${TDE_CONFIG_DIR:?}/$filename"
}

TEST_COUNT=0

TDE_SESSIONS=tde
TDE_CURRENT_SESSION=
run_test "Single directory from outside tmux" \
    "./tde $PROJECT1" \
    "tmux new-window -t tde: -c $PROJECT1 -n $(basename "$PROJECT1")
tmux set-option -t tde:999 pane-base-index 1
tmux select-layout -t tde:999 main-vertical
tmux select-pane -t tde:999.1
tmux select-window -t tde:999
tmux attach-session -t tde"

TDE_SESSIONS=
TDE_CURRENT_SESSION=
run_test "4 panes; session mysession" \
    "./tde -p 4 -s mysession -w mywindow $PROJECT1" \
    "tmux new-session -d -s mysession -c /tmp/test-tde/project1 -n mywindow
tmux set-option -t mysession:999 pane-base-index 1
tmux split-window -v -t mysession:999 -c /tmp/test-tde/project1
tmux split-window -v -t mysession:999 -c /tmp/test-tde/project1
tmux split-window -v -t mysession:999 -c /tmp/test-tde/project1
tmux select-layout -t mysession:999 main-vertical
tmux select-pane -t mysession:999.1
tmux select-window -t mysession:999"

TDE_SESSIONS=tde
TDE_CURRENT_SESSION=tde
run_test "Single directory from inside tmux" \
    "./tde $PROJECT1" \
    "tmux new-window -t tde: -c $PROJECT1 -n $(basename "$PROJECT1")
tmux set-option -t tde:999 pane-base-index 1
tmux select-layout -t tde:999 main-vertical
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

TDE_SESSIONS=tde
TDE_CURRENT_SESSION=tde
run_test "--window-name option on command-line; verbose option" \
    "./tde --verbose -w mywindow $PROJECT1" \
    "tmux new-window -t tde: -c /tmp/test-tde/project1 -n mywindow
tmux set-option -t tde:999 pane-base-index 1
tmux select-layout -t tde:999 main-vertical
tmux select-pane -t tde:999.1
tmux select-window -t tde:999
tde: info: skipping attachment: session 'tde' is already current"

TDE_SESSIONS=tde
TDE_CURRENT_SESSION=tde
run_test "2 panes" \
    "./tde -p 2 $PROJECT1" \
    "tmux new-window -t tde: -c $PROJECT1 -n $(basename "$PROJECT1")
tmux set-option -t tde:999 pane-base-index 1
tmux split-window -v -t tde:999 -c $PROJECT1
tmux select-layout -t tde:999 main-vertical
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

TDE_SESSIONS=tde
TDE_CURRENT_SESSION=tde
run_test "4 panes" \
    "./tde -p 4 $PROJECT1" \
    "tmux new-window -t tde: -c /tmp/test-tde/project1 -n project1
tmux set-option -t tde:999 pane-base-index 1
tmux split-window -v -t tde:999 -c /tmp/test-tde/project1
tmux split-window -v -t tde:999 -c /tmp/test-tde/project1
tmux split-window -v -t tde:999 -c /tmp/test-tde/project1
tmux select-layout -t tde:999 main-vertical
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

TDE_SESSIONS=tde
TDE_CURRENT_SESSION=tde
run_test "2 panes and explicit pane 1 launch command" \
    "./tde -p 2 -l 1:nvim $PROJECT1" \
    "tmux new-window -t tde: -c $PROJECT1 -n $(basename "$PROJECT1")
tmux set-option -t tde:999 pane-base-index 1
tmux split-window -v -t tde:999 -c $PROJECT1
tmux select-layout -t tde:999 main-vertical
tmux send-keys -t tde:999.1 -l nvim
tmux send-keys -t tde:999.1 Enter
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

TDE_SESSIONS=tde
TDE_CURRENT_SESSION=tde
run_test "2 panes and implicit pane 1 launch command" \
    "./tde -p 2 -l 1:nvim $PROJECT1" \
    "tmux new-window -t tde: -c $PROJECT1 -n $(basename "$PROJECT1")
tmux set-option -t tde:999 pane-base-index 1
tmux split-window -v -t tde:999 -c $PROJECT1
tmux select-layout -t tde:999 main-vertical
tmux send-keys -t tde:999.1 -l nvim
tmux send-keys -t tde:999.1 Enter
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

TDE_SESSIONS=tde
TDE_CURRENT_SESSION=tde
run_test "Two project directories appended to current session each with 1 pane" \
    "./tde $PROJECT1 $PROJECT2" \
    "tmux new-window -t tde: -c $PROJECT1 -n project1
tmux set-option -t tde:999 pane-base-index 1
tmux select-layout -t tde:999 main-vertical
tmux select-pane -t tde:999.1
tmux new-window -t tde: -c $PROJECT2 -n project2
tmux set-option -t tde:999 pane-base-index 1
tmux select-layout -t tde:999 main-vertical
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

TDE_SESSIONS=tde
TDE_CURRENT_SESSION=tde
run_test "Two project directories appended to current session each with 3 panes; --layout even-horizontal" \
    "./tde -p 3 --layout even-horizontal $PROJECT1 $PROJECT2" \
    "tmux new-window -t tde: -c $PROJECT1 -n project1
tmux set-option -t tde:999 pane-base-index 1
tmux split-window -v -t tde:999 -c $PROJECT1
tmux split-window -v -t tde:999 -c $PROJECT1
tmux select-layout -t tde:999 even-horizontal
tmux select-pane -t tde:999.1
tmux new-window -t tde: -c $PROJECT2 -n project2
tmux set-option -t tde:999 pane-base-index 1
tmux split-window -v -t tde:999 -c $PROJECT2
tmux split-window -v -t tde:999 -c $PROJECT2
tmux select-layout -t tde:999 even-horizontal
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

TDE_SESSIONS=tde
TDE_CURRENT_SESSION=tde
run_test "Two project directories appended to current session each with 2 panes and a launch command in pane 1" \
    "./tde -l 1:ls -p 2 $PROJECT1 $PROJECT2" \
    "tmux new-window -t tde: -c $PROJECT1 -n project1
tmux set-option -t tde:999 pane-base-index 1
tmux split-window -v -t tde:999 -c $PROJECT1
tmux select-layout -t tde:999 main-vertical
tmux send-keys -t tde:999.1 -l ls
tmux send-keys -t tde:999.1 Enter
tmux select-pane -t tde:999.1
tmux new-window -t tde: -c $PROJECT2 -n project2
tmux set-option -t tde:999 pane-base-index 1
tmux split-window -v -t tde:999 -c $PROJECT2
tmux select-layout -t tde:999 main-vertical
tmux send-keys -t tde:999.1 -l ls
tmux send-keys -t tde:999.1 Enter
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

TDE_SESSIONS=tde
TDE_CURRENT_SESSION=tde
run_test "Two project directories appended to current session each with 2 panes and a launch command in pane 2" \
    "./tde -l '2:git status' -p 2 $PROJECT1 $PROJECT2" \
    "tmux new-window -t tde: -c $PROJECT1 -n project1
tmux set-option -t tde:999 pane-base-index 1
tmux split-window -v -t tde:999 -c $PROJECT1
tmux select-layout -t tde:999 main-vertical
tmux send-keys -t tde:999.2 -l git status
tmux send-keys -t tde:999.2 Enter
tmux select-pane -t tde:999.1
tmux new-window -t tde: -c $PROJECT2 -n project2
tmux set-option -t tde:999 pane-base-index 1
tmux split-window -v -t tde:999 -c $PROJECT2
tmux select-layout -t tde:999 main-vertical
tmux send-keys -t tde:999.2 -l git status
tmux send-keys -t tde:999.2 Enter
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

TDE_SESSIONS=tde
TDE_CURRENT_SESSION=tde
run_test "Two project directories appended to current session each with 2 panes and a launch command in pane 3" \
    "./tde -l 3:htop -p 3 $PROJECT1 $PROJECT2" \
    "tmux new-window -t tde: -c $PROJECT1 -n project1
tmux set-option -t tde:999 pane-base-index 1
tmux split-window -v -t tde:999 -c $PROJECT1
tmux split-window -v -t tde:999 -c $PROJECT1
tmux select-layout -t tde:999 main-vertical
tmux send-keys -t tde:999.3 -l htop
tmux send-keys -t tde:999.3 Enter
tmux select-pane -t tde:999.1
tmux new-window -t tde: -c $PROJECT2 -n project2
tmux set-option -t tde:999 pane-base-index 1
tmux split-window -v -t tde:999 -c $PROJECT2
tmux split-window -v -t tde:999 -c $PROJECT2
tmux select-layout -t tde:999 main-vertical
tmux send-keys -t tde:999.3 -l htop
tmux send-keys -t tde:999.3 Enter
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

TDE_SESSIONS=tde
TDE_CURRENT_SESSION=tde
run_test "Two project directories appended to current session each with 2 panes and a launch command in panes 1 and 2" \
    "./tde -l 1:nvim -l '2:git status' -p 2 $PROJECT1 $PROJECT2" \
    "tmux new-window -t tde: -c $PROJECT1 -n project1
tmux set-option -t tde:999 pane-base-index 1
tmux split-window -v -t tde:999 -c $PROJECT1
tmux select-layout -t tde:999 main-vertical
tmux send-keys -t tde:999.1 -l nvim
tmux send-keys -t tde:999.1 Enter
tmux send-keys -t tde:999.2 -l git status
tmux send-keys -t tde:999.2 Enter
tmux select-pane -t tde:999.1
tmux new-window -t tde: -c $PROJECT2 -n project2
tmux set-option -t tde:999 pane-base-index 1
tmux split-window -v -t tde:999 -c $PROJECT2
tmux select-layout -t tde:999 main-vertical
tmux send-keys -t tde:999.1 -l nvim
tmux send-keys -t tde:999.1 Enter
tmux send-keys -t tde:999.2 -l git status
tmux send-keys -t tde:999.2 Enter
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

TDE_SESSIONS=tde
TDE_CURRENT_SESSION=tde
run_test "Single project directory with 4 panes" \
    "./tde -p 4 $PROJECT1" \
    "tmux new-window -t tde: -c $PROJECT1 -n project1
tmux set-option -t tde:999 pane-base-index 1
tmux split-window -v -t tde:999 -c $PROJECT1
tmux split-window -v -t tde:999 -c $PROJECT1
tmux split-window -v -t tde:999 -c $PROJECT1
tmux select-layout -t tde:999 main-vertical
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

TDE_SESSIONS=tde
TDE_CURRENT_SESSION=tde
run_test "Single project directory with 4 panes and multiple launch commands" \
    "./tde -p 4 -l 1:ls -l '2:git status' $PROJECT1" \
    "tmux new-window -t tde: -c $PROJECT1 -n project1
tmux set-option -t tde:999 pane-base-index 1
tmux split-window -v -t tde:999 -c $PROJECT1
tmux split-window -v -t tde:999 -c $PROJECT1
tmux split-window -v -t tde:999 -c $PROJECT1
tmux select-layout -t tde:999 main-vertical
tmux send-keys -t tde:999.1 -l ls
tmux send-keys -t tde:999.1 Enter
tmux send-keys -t tde:999.2 -l git status
tmux send-keys -t tde:999.2 Enter
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

TDE_SESSIONS=tde
TDE_CURRENT_SESSION=tde
run_test "Single project directory with 4 panes and a launch command in pane 4" \
    "./tde -p 4 -l '4:tail -f /var/log/syslog' $PROJECT1" \
    "tmux new-window -t tde: -c $PROJECT1 -n project1
tmux set-option -t tde:999 pane-base-index 1
tmux split-window -v -t tde:999 -c $PROJECT1
tmux split-window -v -t tde:999 -c $PROJECT1
tmux split-window -v -t tde:999 -c $PROJECT1
tmux select-layout -t tde:999 main-vertical
tmux send-keys -t tde:999.4 -l tail -f /var/log/syslog
tmux send-keys -t tde:999.4 Enter
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

TDE_SESSIONS=tde
TDE_CURRENT_SESSION=tde
run_test "Multiple project directories with 5 panes and a launch command in pane 1" \
    "./tde -p 5 -l 1:nvim $PROJECT1 $PROJECT2" \
    "tmux new-window -t tde: -c $PROJECT1 -n project1
tmux set-option -t tde:999 pane-base-index 1
tmux split-window -v -t tde:999 -c $PROJECT1
tmux split-window -v -t tde:999 -c $PROJECT1
tmux split-window -v -t tde:999 -c $PROJECT1
tmux split-window -v -t tde:999 -c $PROJECT1
tmux select-layout -t tde:999 main-vertical
tmux send-keys -t tde:999.1 -l nvim
tmux send-keys -t tde:999.1 Enter
tmux select-pane -t tde:999.1
tmux new-window -t tde: -c $PROJECT2 -n project2
tmux set-option -t tde:999 pane-base-index 1
tmux split-window -v -t tde:999 -c $PROJECT2
tmux split-window -v -t tde:999 -c $PROJECT2
tmux split-window -v -t tde:999 -c $PROJECT2
tmux split-window -v -t tde:999 -c $PROJECT2
tmux select-layout -t tde:999 main-vertical
tmux send-keys -t tde:999.1 -l nvim
tmux send-keys -t tde:999.1 Enter
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

TDE_SESSIONS=tde
TDE_CURRENT_SESSION=tde
run_test "Multiple project directories with 5 panes and a launch command in pane 3" \
    "./tde -p 5 -l 3:htop $PROJECT1 $PROJECT2" \
    "tmux new-window -t tde: -c $PROJECT1 -n project1
tmux set-option -t tde:999 pane-base-index 1
tmux split-window -v -t tde:999 -c $PROJECT1
tmux split-window -v -t tde:999 -c $PROJECT1
tmux split-window -v -t tde:999 -c $PROJECT1
tmux split-window -v -t tde:999 -c $PROJECT1
tmux select-layout -t tde:999 main-vertical
tmux send-keys -t tde:999.3 -l htop
tmux send-keys -t tde:999.3 Enter
tmux select-pane -t tde:999.1
tmux new-window -t tde: -c $PROJECT2 -n project2
tmux set-option -t tde:999 pane-base-index 1
tmux split-window -v -t tde:999 -c $PROJECT2
tmux split-window -v -t tde:999 -c $PROJECT2
tmux split-window -v -t tde:999 -c $PROJECT2
tmux split-window -v -t tde:999 -c $PROJECT2
tmux select-layout -t tde:999 main-vertical
tmux send-keys -t tde:999.3 -l htop
tmux send-keys -t tde:999.3 Enter
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

TDE_SESSIONS=tde
TDE_CURRENT_SESSION=tde
run_test "Multiple project directories with 5 panes and a launch command in pane 5" \
    "./tde -p 5 -l 5:ps $PROJECT1 $PROJECT2" \
    "tmux new-window -t tde: -c $PROJECT1 -n project1
tmux set-option -t tde:999 pane-base-index 1
tmux split-window -v -t tde:999 -c $PROJECT1
tmux split-window -v -t tde:999 -c $PROJECT1
tmux split-window -v -t tde:999 -c $PROJECT1
tmux split-window -v -t tde:999 -c $PROJECT1
tmux select-layout -t tde:999 main-vertical
tmux send-keys -t tde:999.5 -l ps
tmux send-keys -t tde:999.5 Enter
tmux select-pane -t tde:999.1
tmux new-window -t tde: -c $PROJECT2 -n project2
tmux set-option -t tde:999 pane-base-index 1
tmux split-window -v -t tde:999 -c $PROJECT2
tmux split-window -v -t tde:999 -c $PROJECT2
tmux split-window -v -t tde:999 -c $PROJECT2
tmux split-window -v -t tde:999 -c $PROJECT2
tmux select-layout -t tde:999 main-vertical
tmux send-keys -t tde:999.5 -l ps
tmux send-keys -t tde:999.5 Enter
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

TDE_SESSIONS=tde
TDE_CURRENT_SESSION=tde
run_test "Multiple project directories with 1 pane and a launch command in pane 1" \
    "./tde -p 1 -l 1:ls $PROJECT1 $PROJECT2" \
    "tmux new-window -t tde: -c $PROJECT1 -n project1
tmux set-option -t tde:999 pane-base-index 1
tmux select-layout -t tde:999 main-vertical
tmux send-keys -t tde:999.1 -l ls
tmux send-keys -t tde:999.1 Enter
tmux select-pane -t tde:999.1
tmux new-window -t tde: -c $PROJECT2 -n project2
tmux set-option -t tde:999 pane-base-index 1
tmux select-layout -t tde:999 main-vertical
tmux send-keys -t tde:999.1 -l ls
tmux send-keys -t tde:999.1 Enter
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

TDE_SESSIONS=tde
TDE_CURRENT_SESSION=tde
run_test "Multiple project directories with 4 panes and multiple launch commands" \
    "./tde -p 4 -l 1:nvim -l '2:git status' -l 3:htop -l 4:ps $PROJECT1 $PROJECT2" \
    "tmux new-window -t tde: -c $PROJECT1 -n project1
tmux set-option -t tde:999 pane-base-index 1
tmux split-window -v -t tde:999 -c $PROJECT1
tmux split-window -v -t tde:999 -c $PROJECT1
tmux split-window -v -t tde:999 -c $PROJECT1
tmux select-layout -t tde:999 main-vertical
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
tmux split-window -v -t tde:999 -c $PROJECT2
tmux split-window -v -t tde:999 -c $PROJECT2
tmux split-window -v -t tde:999 -c $PROJECT2
tmux select-layout -t tde:999 main-vertical
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

TDE_SESSIONS=tde
TDE_CURRENT_SESSION=tde
run_test "Illegal command option" \
    "./tde -X $PROJECT1" \
    "tde: error: unknown option: -X" 1

TDE_SESSIONS=tde
TDE_CURRENT_SESSION=tde
run_test "Multiple project directories with 2 panes, and a launch command with a complex string" \
    "./tde -p 2 -l '1:echo \"Hello World\\!\" && sleep 1' $PROJECT1 $PROJECT2" \
    "tmux new-window -t tde: -c $PROJECT1 -n project1
tmux set-option -t tde:999 pane-base-index 1
tmux split-window -v -t tde:999 -c $PROJECT1
tmux select-layout -t tde:999 main-vertical
tmux send-keys -t tde:999.1 -l echo \"Hello World\!\" && sleep 1
tmux send-keys -t tde:999.1 Enter
tmux select-pane -t tde:999.1
tmux new-window -t tde: -c $PROJECT2 -n project2
tmux set-option -t tde:999 pane-base-index 1
tmux split-window -v -t tde:999 -c $PROJECT2
tmux select-layout -t tde:999 main-vertical
tmux send-keys -t tde:999.1 -l echo \"Hello World\!\" && sleep 1
tmux send-keys -t tde:999.1 Enter
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

TDE_SESSIONS=tde
TDE_CURRENT_SESSION=tde
run_test "Help message (first two lines)" \
    "./tde --help | head -n 2" \
    "NAME
    tde - open workspaces with tmux"

TDE_SESSIONS=tde
TDE_CURRENT_SESSION=tde
run_test "Executed inside tde session with no PROJECT_DIR arguments: nothing to do" \
    "./tde" \
    ""

TDE_SESSIONS=tde
TDE_CURRENT_SESSION=
run_test "Executed outside tde session with no PROJECT_DIR arguments" \
    "./tde" \
    "tmux attach-session -t tde"

TDE_SESSIONS=
TDE_CURRENT_SESSION=
run_test "No PROJECT_DIR arguments spaces specified" \
    "./tde" \
    "tde: error: no project directories specified" 1

# Tests for invalid command options
TDE_SESSIONS=tde
TDE_CURRENT_SESSION=tde
run_test "Invalid --panes value '0'" \
    "./tde -p 0 $PROJECT1" \
    "tde: error: invalid --panes option '0': must be between 1 and 9" 1

TDE_SESSIONS=tde
TDE_CURRENT_SESSION=tde
run_test "Invalid --panes value '10'" \
    "./tde --panes 10 $PROJECT1" \
    "tde: error: invalid --panes option '10': must be between 1 and 9" 1

TDE_SESSIONS=tde
TDE_CURRENT_SESSION=tde
run_test "Invalid --panes value 'abc'" \
    "./tde -p abc $PROJECT1" \
    "tde: error: invalid --panes option 'abc': must be between 1 and 9" 1

TDE_SESSIONS=tde
TDE_CURRENT_SESSION=tde
run_test "Invalid --launch pane number '0'" \
    "./tde -p 2 -l 0:ls $PROJECT1" \
    "tde: error: invalid --launch option '0:ls': pane number must be between 1 and 9" 1

TDE_SESSIONS=tde
TDE_CURRENT_SESSION=tde
run_test "Invalid --launch pane number (non-numeric)" \
    "./tde -p 2 -l x:ls $PROJECT1" \
    "tde: error: invalid --launch option 'x:ls': pane number must be between 1 and 9" 1

TDE_SESSIONS=tde
TDE_CURRENT_SESSION=tde
run_test "Number of panes set by launch option" \
    "./tde -l 3:ls -v $PROJECT1" \
    "tde: info: number of panes increased to 3 to accomodate launch options: '3:ls'
tmux new-window -t tde: -c /tmp/test-tde/project1 -n project1
tmux set-option -t tde:999 pane-base-index 1
tmux split-window -v -t tde:999 -c /tmp/test-tde/project1
tmux split-window -v -t tde:999 -c /tmp/test-tde/project1
tmux select-layout -t tde:999 main-vertical
tmux send-keys -t tde:999.3 -l ls
tmux send-keys -t tde:999.3 Enter
tmux select-pane -t tde:999.1
tmux select-window -t tde:999
tde: info: skipping attachment: session 'tde' is already current"

TDE_SESSIONS=tde
TDE_CURRENT_SESSION=tde
run_test "Invalid --launch value" \
    "./tde -l bad-launch $PROJECT1" \
    "tde: error: invalid --launch option 'bad-launch'" 1

TDE_SESSIONS=tde
TDE_CURRENT_SESSION=tde
run_test "Missing project directory" \
    "./tde /nonexistent/path" \
    "tde: error: project directory not found: '/nonexistent/path'" 1

TDE_SESSIONS=tde
TDE_CURRENT_SESSION=tde
run_test "Invalid --focus value '0'" \
    "./tde -f 0 $PROJECT1" \
    "tde: error: invalid --focus option '0': must be between 1 and 9" 1

TDE_SESSIONS=tde
TDE_CURRENT_SESSION=tde
run_test "Invalid --focus value '2'" \
    "./tde -f 2 $PROJECT1" \
    "tde: error: invalid --focus option '2': must be between 1 and 1" 1

TDE_SESSIONS=tde
TDE_CURRENT_SESSION=tde
run_test "Missing --layout argument" \
    "./tde $PROJECT1 -L" \
    "tde: error: invalid --layout option ''" 1

TDE_SESSIONS=tde
TDE_CURRENT_SESSION=tde
run_test "Duplicate project directories arguments" \
    "./tde '$PROJECT1' '$PROJECT1'" \
    "tmux new-window -t tde: -c /tmp/test-tde/project1 -n project1
tmux set-option -t tde:999 pane-base-index 1
tmux select-layout -t tde:999 main-vertical
tmux select-pane -t tde:999.1
tde: warning: skipping duplicate window name: 'project1'
tmux select-window -t tde:999"

TDE_SESSIONS=
TDE_CURRENT_SESSION=
run_test "Duplicate --launch option pane number" \
    "./tde --launch 1:nvim -l 1:lazygit $PROJECT1" \
    "tde: error: duplicate pane number 1 in --launch options: '1:nvim, 1:lazygit'" 1

TDE_SESSIONS=
TDE_CURRENT_SESSION=
write_conf tde.tde "--launch 1:nvim -l 1:lazygit /tmp/test-tde/project1"
run_test "Duplicate --launch option pane number in configuration file" \
    "./tde -l 1:lazygit $PROJECT1" \
    "tde: error: duplicate pane number 1 in --launch options: '1:nvim, 1:lazygit'" 1

TDE_SESSIONS=
TDE_CURRENT_SESSION=
write_conf tde.tde "--launch 1:nvim 3:lazygit -"
run_test "Invalid option 3:lazygit; missing --launch option name" \
    "./tde $PROJECT1" \
    "tde: error: unknown option in project definition: '3:lazygit'" 1

TDE_SESSIONS=
TDE_CURRENT_SESSION=
write_conf tde.tde "/tmp/test-tde/project1"
run_test "Configuration file with single directory-only entry; verbose" \
    "./tde --verbose" \
    "tde: info: reading session configuration file '/tmp/test-tde/.config/tde/tde.tde'
tmux new-session -d -s tde -c /tmp/test-tde/project1 -n project1
tde: info: tmux commands file '/tmp/test-tde/.config/tde/tde.tmux' not found
tmux set-option -t tde:999 pane-base-index 1
tmux select-layout -t tde:999 main-vertical
tmux select-pane -t tde:999.1
tmux select-window -t tde:999
tde: info: skipping attachment: session 'tde' is already current"

TDE_SESSIONS=
TDE_CURRENT_SESSION=
run_test "Duplicate project window name" \
    "./tde '$PROJECT1'" \
    "tmux new-session -d -s tde -c /tmp/test-tde/project1 -n project1
tmux set-option -t tde:999 pane-base-index 1
tmux select-layout -t tde:999 main-vertical
tmux select-pane -t tde:999.1
tde: warning: skipping duplicate window name: 'project1'
tmux select-window -t tde:999"

TDE_SESSIONS=
TDE_CURRENT_SESSION=
run_test "Command-line panes option with directory-only configuration file entry" \
    "./tde -p 2" \
    "tmux new-session -d -s tde -c /tmp/test-tde/project1 -n project1
tmux set-option -t tde:999 pane-base-index 1
tmux split-window -v -t tde:999 -c /tmp/test-tde/project1
tmux select-layout -t tde:999 main-vertical
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

TDE_SESSIONS=
TDE_CURRENT_SESSION=
run_test "Command-line launch option with directory-only configuration file entry" \
    "./tde -l 1:nvim" \
    "tmux new-session -d -s tde -c /tmp/test-tde/project1 -n project1
tmux set-option -t tde:999 pane-base-index 1
tmux select-layout -t tde:999 main-vertical
tmux send-keys -t tde:999.1 -l nvim
tmux send-keys -t tde:999.1 Enter
tmux select-pane -t tde:999.1
tmux select-window -t tde:999"

TDE_SESSIONS=
TDE_CURRENT_SESSION=
run_test "Command-line panes and launch options with directory-only configuration file entry" \
    "./tde -l 1:nvim -p 2 -l 2:lazygit" \
    "tmux new-session -d -s tde -c /tmp/test-tde/project1 -n project1
tmux set-option -t tde:999 pane-base-index 1
tmux split-window -v -t tde:999 -c /tmp/test-tde/project1
tmux select-layout -t tde:999 main-vertical
tmux send-keys -t tde:999.1 -l nvim
tmux send-keys -t tde:999.1 Enter
tmux send-keys -t tde:999.2 -l lazygit
tmux send-keys -t tde:999.2 Enter
tmux select-pane -t tde:999.1
tmux select-window -t tde:999" 0

TDE_SESSIONS=
TDE_CURRENT_SESSION=
write_conf tde.tde "-l 1:nvim -l '2:git status' -p 2 /tmp/test-tde/project1
-L even-horizontal --panes 3 --focus 2 --window-name mywindow --launch 1:nvim --launch 3:lazygit /tmp/test-tde/project2"
run_test "Configuration file with two project directories and configuration options" \
    "./tde" \
    "tmux new-session -d -s tde -c /tmp/test-tde/project1 -n project1
tmux set-option -t tde:999 pane-base-index 1
tmux split-window -v -t tde:999 -c /tmp/test-tde/project1
tmux select-layout -t tde:999 main-vertical
tmux send-keys -t tde:999.1 -l nvim
tmux send-keys -t tde:999.1 Enter
tmux send-keys -t tde:999.2 -l git status
tmux send-keys -t tde:999.2 Enter
tmux select-pane -t tde:999.1
tmux new-window -t tde: -c /tmp/test-tde/project2 -n mywindow
tmux set-option -t tde:999 pane-base-index 1
tmux split-window -v -t tde:999 -c /tmp/test-tde/project2
tmux split-window -v -t tde:999 -c /tmp/test-tde/project2
tmux select-layout -t tde:999 even-horizontal
tmux send-keys -t tde:999.1 -l nvim
tmux send-keys -t tde:999.1 Enter
tmux send-keys -t tde:999.3 -l lazygit
tmux send-keys -t tde:999.3 Enter
tmux select-pane -t tde:999.2
tmux select-window -t tde:999" 0

TDE_SESSIONS=
TDE_CURRENT_SESSION=
write_conf tde.tde "-l 1:nvim -l '2:git status' -p 2 /tmp/test-tde/project1
/tmp/test-tde/project2
-L even-vertical --panes 3 --launch 1:nvim --launch 3:lazygit /tmp/test-tde/project3"
run_test "Configuration file with three project directories; one is directory-only; --layout command-line option" \
    "./tde --panes 4 --layout even-horizontal" \
    "tmux new-session -d -s tde -c /tmp/test-tde/project1 -n project1
tmux set-option -t tde:999 pane-base-index 1
tmux split-window -v -t tde:999 -c /tmp/test-tde/project1
tmux select-layout -t tde:999 even-horizontal
tmux send-keys -t tde:999.1 -l nvim
tmux send-keys -t tde:999.1 Enter
tmux send-keys -t tde:999.2 -l git status
tmux send-keys -t tde:999.2 Enter
tmux select-pane -t tde:999.1
tmux new-window -t tde: -c /tmp/test-tde/project2 -n project2
tmux set-option -t tde:999 pane-base-index 1
tmux split-window -v -t tde:999 -c /tmp/test-tde/project2
tmux split-window -v -t tde:999 -c /tmp/test-tde/project2
tmux split-window -v -t tde:999 -c /tmp/test-tde/project2
tmux select-layout -t tde:999 even-horizontal
tmux select-pane -t tde:999.1
tmux new-window -t tde: -c /tmp/test-tde/project3 -n project3
tmux set-option -t tde:999 pane-base-index 1
tmux split-window -v -t tde:999 -c /tmp/test-tde/project3
tmux split-window -v -t tde:999 -c /tmp/test-tde/project3
tmux select-layout -t tde:999 even-vertical
tmux send-keys -t tde:999.1 -l nvim
tmux send-keys -t tde:999.1 Enter
tmux send-keys -t tde:999.3 -l lazygit
tmux send-keys -t tde:999.3 Enter
tmux select-pane -t tde:999.1
tmux select-window -t tde:999" 0

TDE_SESSIONS=
TDE_CURRENT_SESSION=
write_conf tde.tde "-l 1:nvim -l '2:git status' -p 2 /tmp/test-tde/project1
-L even-horizontal --panes 4 --focus 2 --window-name mywindow --launch 4:nvim --launch 3:lazygit -
/tmp/test-tde/project2
-w mywindow-two -p 3 --launch 2:nvim /tmp/test-tde/project3"
run_test "Configuration file with three entries, the second is a default '-' entry" \
    "./tde" \
    "tmux new-session -d -s tde -c /tmp/test-tde/project1 -n project1
tmux set-option -t tde:999 pane-base-index 1
tmux split-window -v -t tde:999 -c /tmp/test-tde/project1
tmux select-layout -t tde:999 main-vertical
tmux send-keys -t tde:999.1 -l nvim
tmux send-keys -t tde:999.1 Enter
tmux send-keys -t tde:999.2 -l git status
tmux send-keys -t tde:999.2 Enter
tmux select-pane -t tde:999.1
tmux new-window -t tde: -c /tmp/test-tde/project2 -n mywindow
tmux set-option -t tde:999 pane-base-index 1
tmux split-window -v -t tde:999 -c /tmp/test-tde/project2
tmux split-window -v -t tde:999 -c /tmp/test-tde/project2
tmux split-window -v -t tde:999 -c /tmp/test-tde/project2
tmux select-layout -t tde:999 even-horizontal
tmux send-keys -t tde:999.4 -l nvim
tmux send-keys -t tde:999.4 Enter
tmux send-keys -t tde:999.3 -l lazygit
tmux send-keys -t tde:999.3 Enter
tmux select-pane -t tde:999.2
tmux new-window -t tde: -c /tmp/test-tde/project3 -n mywindow-two
tmux set-option -t tde:999 pane-base-index 1
tmux split-window -v -t tde:999 -c /tmp/test-tde/project3
tmux split-window -v -t tde:999 -c /tmp/test-tde/project3
tmux select-layout -t tde:999 even-horizontal
tmux send-keys -t tde:999.2 -l nvim
tmux send-keys -t tde:999.2 Enter
tmux select-pane -t tde:999.2
tmux select-window -t tde:999" 0

TDE_SESSIONS=
TDE_CURRENT_SESSION=
run_test "Bad session name" \
    "./tde -s 'bad#session#name'" \
    "tde: error: invalid --session-name option 'bad#session#name': must begin with an alpha numberic character and can only contain only alphanumeric characters, dashes, underscores, or periods" 1

TDE_SESSIONS=
TDE_CURRENT_SESSION=
run_test "Bad tmux commands name" \
    "./tde -t 'bad#theme#name'" \
    "tde: error: invalid --theme option 'bad#theme#name': must begin with an alpha numberic character and can only contain only alphanumeric characters, dashes, underscores, or periods" 1

TDE_SESSIONS=
TDE_CURRENT_SESSION=
run_test "Missing tmux commands file" \
    "./tde -t non-existent" \
    "tmux new-session -d -s tde -c /tmp/test-tde/project1 -n project1
tde: error: tmux commands file '/tmp/test-tde/.config/tde/non-existent.tmux' not found" 1

TDE_SESSIONS=
TDE_CURRENT_SESSION=
run_test "Missing session configuration file warning; refusing attachment; one project directory argument; --verbose" \
    "./tde -s 'session-name-2' --verbose '$PROJECT1'" \
    "tde: info: session configuration file '/tmp/test-tde/.config/tde/session-name-2.tde' not found
tmux new-session -d -s session-name-2 -c /tmp/test-tde/project1 -n project1
tde: info: tmux commands file '/tmp/test-tde/.config/tde/session-name-2.tmux' not found
tmux set-option -t session-name-2:999 pane-base-index 1
tmux select-layout -t session-name-2:999 main-vertical
tmux select-pane -t session-name-2:999.1
tmux select-window -t session-name-2:999
tmux attach-session -t session-name-2"

TDE_CURRENT_SESSION=another-session
write_conf session-name.tde "/tmp/test-tde/project1"
write_conf session-name.tmux ""
run_test "Single-entry configuration file; nested session warning" \
    "./tde -s 'session-name'" \
    "tmux new-session -d -s session-name -c /tmp/test-tde/project1 -n project1
tmux source-file -t session-name /tmp/test-tde/.config/tde/session-name.tmux
tmux set-option -t session-name:999 pane-base-index 1
tmux select-layout -t session-name:999 main-vertical
tmux select-pane -t session-name:999.1
tmux select-window -t session-name:999
tde: warning: refusing to attach nested tmux session 'session-name' inside tmux session 'another-session'"

TDE_SESSIONS=
TDE_CURRENT_SESSION=
rm_conf session-name.tde
rm_conf session-name.tmux
run_test "One project directory argument" \
    "./tde -s 'session-name' '$PROJECT1'" \
    "tmux new-session -d -s session-name -c /tmp/test-tde/project1 -n project1
tmux set-option -t session-name:999 pane-base-index 1
tmux select-layout -t session-name:999 main-vertical
tmux select-pane -t session-name:999.1
tmux select-window -t session-name:999
tmux attach-session -t session-name"

TDE_SESSIONS=
TDE_CURRENT_SESSION=
write_conf session-default.tde "--session-name session-one --window-name one --panes 3 /tmp
--session-name session-two --theme theme --window-name two --panes 3 /tmp
--window-name default --panes 3 /tmp
--session-name session-one --window-name three --panes 3 /tmp
--session-name session-two --window-name four --panes 3 /tmp"
write_conf theme.tmux ""
run_test "Multiple interweaved sessions in single session config file" \
    "./tde --session-name session-default" \
    "tmux new-session -d -s session-one -c /tmp -n one
tmux set-option -t session-one:999 pane-base-index 1
tmux split-window -v -t session-one:999 -c /tmp
tmux split-window -v -t session-one:999 -c /tmp
tmux select-layout -t session-one:999 main-vertical
tmux select-pane -t session-one:999.1
tmux new-session -d -s session-two -c /tmp -n two
tmux set-option -t session-two:999 pane-base-index 1
tmux split-window -v -t session-two:999 -c /tmp
tmux split-window -v -t session-two:999 -c /tmp
tmux select-layout -t session-two:999 main-vertical
tmux select-pane -t session-two:999.1
tmux new-window -t session-default: -c /tmp -n default
tmux set-option -t session-default:999 pane-base-index 1
tmux split-window -v -t session-default:999 -c /tmp
tmux split-window -v -t session-default:999 -c /tmp
tmux select-layout -t session-default:999 main-vertical
tmux select-pane -t session-default:999.1
tmux new-window -t session-one: -c /tmp -n three
tmux set-option -t session-one:999 pane-base-index 1
tmux split-window -v -t session-one:999 -c /tmp
tmux split-window -v -t session-one:999 -c /tmp
tmux select-layout -t session-one:999 main-vertical
tmux select-pane -t session-one:999.1
tmux new-window -t session-two: -c /tmp -n four
tmux set-option -t session-two:999 pane-base-index 1
tmux split-window -v -t session-two:999 -c /tmp
tmux split-window -v -t session-two:999 -c /tmp
tmux select-layout -t session-two:999 main-vertical
tmux select-pane -t session-two:999.1
tmux select-window -t session-two:999
tmux attach-session -t session-two"

exit
