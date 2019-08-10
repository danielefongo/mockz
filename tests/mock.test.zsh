#!/usr/bin/env zsh

# Setup

setopt shwordsplit
SHUNIT_PARENT=$0

setUp() {  
  source mock.zsh
}

tearDown() {  
    __mocks_invocations=()
    __mocks_functions=()
    __mocks_dos=()
    __mocks_ifs=()
    __mocks_musts=()
}

# Tests

test_create_mocks() {
    mock myFunction
    mock myFunction2

    assertEquals "myFunction" "$__mocks_functions[\"myFunction\"]"
    assertEquals "myFunction2" "$__mocks_functions[\"myFunction2\"]"
}

test_delete_mocks() {
    mock myFunction

    rock myFunction

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

test_do_something() {
    mock myFunction do "echo hello"

    local actual=$(myFunction)

    assertEquals "hello" "$actual"
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

test_must_do_something_with_right_params() {
    mock mustFunction must "greetings yeah" do "echo hello"

    local actual=$(mustFunction greetings yeah)

    assertEquals "hello" "$actual"
}

test_must_fails_with_wrong_params() {
    failFunction() {failCalled=true;}
    mock_fail_function=failFunction

    mock mustFunction must "greetings yeah"

    mustFunction greetings

    assertTrue "$failCalled"
}

test_must_do_nothing_with_wrong_params() {
    failFunction() {failCalled=true;}
    mock_fail_function=failFunction

    mock mustFunction must "greetings yeah" do "echo hello"

    local actual=$(mustFunction greetings)
    
    assertEquals "" "$actual"
    mock_fail_function=fail
}

# Run

source "shunit2/shunit2"