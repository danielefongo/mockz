#!/usr/bin/env zsh

# Setup

setopt shwordsplit
SHUNIT_PARENT=$0

setUp() {  
  source mockz.zsh
}

tearDown() {  
    __mocks_invocations=()
    __mocks_functions=()
    __mocks_dos=()
    __mocks_ifs=()
    __mocks_expectations=()
}

# Tests

test_create_mocks() {
    mock myFunction

    assertEquals "myFunction" "$__mocks_functions[\"myFunction\"]"
    assertEquals "0" "$__mocks_invocations[\"myFunction\"]"
}

test_create_mocks_for_system_command() {
    actualdir=$(pwd)
    mkdir -p foo
    cd foo

    mock cd

    assertEquals "cd" "$__mocks_functions[\"cd\"]"

    rock cd
    cd ..
    rm -rf foo

    assertEquals "$actualdir" "$(pwd)"
}

test_do_not_create_mock_with_wrong_command() {
    mock myFunction wtf hello 1>/dev/null

    assertEquals "1" "$?"
    assertNull "$__mocks_functions[\"myFunction\"]"
}

test_do_not_create_mock_with_wrong_number_of_params() {
    mock myFunction do 1>/dev/null

    assertEquals "1" "$?"
    assertNull "$__mocks_functions[\"myFunction\"]"
}

test_delete_mock() {
    mock myFunction

    rock myFunction

    assertEquals "0" "$?"
    assertNull "$__mocks_functions[\"myFunction\"]"
    assertNull "$__mocks_invocations[\"myFunction\"]"
    assertNull "$__mocks_old_functions[\"myFunction\"]"
    assertNull "$__mocks_expectations[\"myFunction\"]"
    assertNull "$__mocks_ifs[\"myFunction\"]"
    assertNull "$__mocks_dos[\"myFunction\"]"
}

test_delete_mocks() {
    mock myFunction
    mock myFunction2

    rockall

    assertNull "$__mocks_functions[\"myFunction\"]"
    assertNull "$__mocks_functions[\"myFunction2\"]"
}

test_delete_mock_restores_the_old_functionality() {
    local function sampleFunction() {
        echo "hello"
    }

    mock sampleFunction do "echo wtf"
    rock sampleFunction

    local actual=$(sampleFunction)
    assertEquals "hello" "$actual"
}

test_defining_mock_multiple_times_does_not_override_old_functionality() {
    local function sampleFunction() {
        echo "hello"
    }

    mock sampleFunction do "echo wtf"
    mock sampleFunction do "echo wtf"
    
    rock sampleFunction

    local actual=$(sampleFunction)
    assertEquals "hello" "$actual"
}

test_do_something() {
    mock myFunction do 'echo hello'

    local actual=$(myFunction)

    assertEquals "hello" "$actual"
}

test_do_something_using_parameters() {
    mock myFunction do 'echo $1'

    local actual=$(myFunction hello notNecessary)

    assertEquals "hello" "$actual"
}

test_do_returns_status_code_ok() {
    mock myFunction

    myFunction

    assertEquals "0" "$?"
}

test_do_returns_status_code_ko() {
    mock myFunction do 'return 1'

    myFunction

    assertEquals "1" "$?"
}

test_failure_should_rise_on_async_jobs() {
    local failCalled
    failFunction() {failCalled=true;}
    mockz_fail_function=failFunction

    mock myFunction expect 'expected'

    myFunction &!

    sleep 0.1

    assertTrue "$failCalled"
}

test_if_params_are_ok_do_something() {
    mock myFunction if "greetings" do "echo hello"

    local actual=$(myFunction greetings)

    assertEquals "hello" "$actual"
}

test_if_params_are_wrong_do_nothing() {
    mock ifFunction if "greetings" do "echo hello"

    local actual=$(ifFunction)

    assertEquals "" "$actual"
}

test_expect_do_something_with_right_params() {
    mock expectFunction expect "greetings yeah" do "echo hello"

    local actual=$(expectFunction greetings yeah)

    assertEquals "hello" "$actual"
}

test_expect_fails_with_wrong_params() {
    local failCalled
    failFunction() {failCalled=true;}
    mockz_fail_function=failFunction

    mock expectFunction expect "greetings yeah"

    expectFunction greetings

    assertTrue "$failCalled"
}

test_expect_do_nothing_with_wrong_params() {
    failFunction() {;}
    mockz_fail_function=failFunction

    mock expectFunction expect "greetings yeah" do "echo hello"

    local actual=$(expectFunction greetings)
    
    assertEquals "" "$actual"
    mockz_fail_function=fail
}

test_called_the_right_number_of_times() {
    mock myFunction

    myFunction
    myFunction

    mock myFunction called 2
}

test_called_the_wrong_number_of_times() {
    local failCalled
    failFunction() {failCalled=true;}
    mockz_fail_function=failFunction

    mock myFunction

    mock myFunction called 1
    assertTrue "$failCalled"
}

# Run

source "shunit2/shunit2"