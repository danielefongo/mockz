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

test_mock_do_something() {
    mock myFunction do "echo hello"

    local actual=$(myFunction)

    assertEquals "hello" "$actual"
}

test_mock_if_params_do_something() {
    mock myFunction if "greetings" do "echo hello"

    local actual=$(myFunction greetings)

    assertEquals "hello" "$actual"
}

test_mock_if_params_wrong_do_nothing() {
    mock ifFunction if "greetings" do "echo hello"

    local actual=$(ifFunction)

    assertEquals "" "$actual"
}

test_mock_fails_with_wrong_params() {
    failFunction() {
        failCalled=true
    }
    mock_fail_function=failFunction

    mock mustFunction must "greetings yeah"

    mustFunction greetings

    assertTrue "$failCalled"
}

test_mock_fails_with_wrong_params_should_dont_do_anything() {
    failFunction() {
        failCalled=true
    }
    mock_fail_function=failFunction

    mock mustFunction must "greetings yeah" do "echo hello"

    local actual=$(mustFunction greetings)
    
    assertEquals "" "$actual"
    mock_fail_function=fail
}

test_mock_ok_with_right_params() {
    mock mustFunction must "greetings yeah" do "echo hello"

    local actual=$(mustFunction greetings yeah)

    assertEquals "hello" "$actual"
}


# Run

source "shunit2/shunit2"