typeset -gA __mocks_functions=()
typeset -gA __mocks_invocations=()
typeset -gA __mocks_old_functions=()
typeset -gA __mocks_expectations=()
typeset -gA __mocks_ifs=()
typeset -gA __mocks_dos=()

mockz_fail_function=fail
mockz_debug=false

function __USR1() {
    $mockz_fail_function
}
trap '__USR1' USR1

mock() {
    local mockedFunction=$1
    shift

    (( $# % 2 != 0 )) && echo "wrong number of parameters" && return 1
    (( $# == 0 )) && __mock_create $mockedFunction && return 0

    local command=$1
    local params="$2"
    shift; shift;

    case "$command" in
        expect) __mocks_expectations["$mockedFunction"]="$params";;
        if) __mocks_ifs["$mockedFunction"]="$params";;
        do) __mocks_dos["$mockedFunction"]="$params";;
        called) __mock_check_invocations $mockedFunction "$params" && return;;
        *) echo "wrong command $command"; return 1;;
    esac

    mock $mockedFunction "$@"
}

rockall() {
    __mockz_debug "deleting all mocks"
    for mockedFunction in $__mocks_functions
    do
        rock $mockedFunction
    done
}

rock() {
    local mockedFunction="$1"
    __mockz_debug "deleting mock for $mockedFunction"

    unset -f $mockedFunction
    eval "$__mocks_old_functions["$mockedFunction"]"

    [ -z "$__mocks_functions["$mockedFunction"]" ] || __mocks_functions["$mockedFunction"]=""
    [ -z "$__mocks_old_functions["$mockedFunction"]" ] || __mocks_old_functions["$mockedFunction"]=""
    [ "$__mocks_invocations["$mockedFunction"]}" = 0 ] || __mocks_invocations["$mockedFunction"]=""
    [ -z "$__mocks_dos["$mockedFunction"]" ] || __mocks_dos["$mockedFunction"]=""
    [ -z "$__mocks_ifs["$mockedFunction"]" ] || __mocks_ifs["$mockedFunction"]=""
    [ -z "$__mocks_expectations["$mockedFunction"]" ] || __mocks_expectations["$mockedFunction"]=""
}

__mock_create() {
    local mockedFunction="$1"
    __mockz_debug "creating mock for for $mockedFunction"
    
    __mocks_functions["$mockedFunction"]="$mockedFunction"

    if [ ! "$__mocks_old_functions["$mockedFunction"]" ]; then
        __mocks_old_functions["$mockedFunction"]=$(declare -f $mockedFunction)
    fi
    __mocks_invocations["$mockedFunction"]=0

    eval """
    $mockedFunction()
    {
        __mockz_debug \"executing mock $mockedFunction with params \$@\"
        __mock_invocations $mockedFunction
        __mock_expect $$ $mockedFunction \$@ || return
        __mock_if $mockedFunction \$@ || return
        __mock_do $mockedFunction \$@
        return \$?
    }
    """
    return
}

__mock_invocations() {
    local mockedFunction="$1"
    __mockz_debug "add invocation for $mockedFunction"
    __mocks_invocations["$mockedFunction"]=$((__mocks_invocations["$mockedFunction"] + 1 ))
}

__mock_do() {
    local mockedFunction="$1"
    __mockz_debug "evaluating $mockedFunction"
    shift

    (
        local function __execute() { 
            eval $__mocks_dos["$mockedFunction"]
        }
        __execute $@
    )
    local exitStatus=$?

    return $exitStatus
}

__mock_if() {
    local mockedFunction="$1"
    __mockz_debug "checking if for $mockedFunction"
    shift

    __mock_check_equality "$__mocks_ifs["$mockedFunction"]" "$@"
    [ $? = 0 ] || return 1 
}

__mock_expect() {
    local parentPid=$1
    local mockedFunction="$2"
    __mockz_debug "checking expect for $mockedFunction"
    shift; shift

    __mock_check_equality "$__mocks_expectations["$mockedFunction"]" "$@"
    if [ $? != 0 ]; then
        kill -s USR1 $parentPid
        return 1 
    fi
}

__mock_check_invocations() {
    local mockedFunction="$1"
    __mockz_debug "checking invocations for $mockedFunction"
    shift

    __mock_check_equality "$__mocks_invocations["$mockedFunction"]" "$@"
    if [ $? != 0 ]; then
        $mockz_fail_function
        return 1 
    fi
}

__mock_check_equality() {
    local expected="$1"
    shift
    local actual="$(echo $@)"

    if [ -z "$expected" ]; then
        return
    fi

    if [[ "$actual" =~ "$expected" ]]; then
        return 0
        __mockz_debug "parameters ok: $actual"
    fi
    
    __mockz_debug "parameters wrong: $actual"
    return 1 

}

__mockz_debug() {
    [ $mockz_debug = false ] || echo "mockz: $@"
}