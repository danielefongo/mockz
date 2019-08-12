typeset -gA __mocks_functions=()
typeset -gA __mocks_invocations=()
typeset -gA __mocks_old_functions=()
typeset -gA __mocks_expectations=()
typeset -gA __mocks_ifs=()
typeset -gA __mocks_dos=()

mock_fail_function=fail

function __USR1() {
    $mock_fail_function
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
        called) __mock_check_invocations $mockedFunction "$params" || return 1;;
        *) echo "wrong command $command"; return 1;;
    esac

    mock $mockedFunction "$@"
}

rockall() {
    for mockedFunction in $__mocks_functions
    do
        rock $mockedFunction
    done
}

rock() {
    local mockedFunction="$1"

    eval "$__mocks_old_functions["$mockedFunction"]"

    [ "$__mocks_functions["$mockedFunction"]" ] && __mocks_functions["$mockedFunction"]=""
    [ "$__mocks_old_functions["$mockedFunction"]" ] && __mocks_old_functions["$mockedFunction"]=""
    [ "$__mocks_invocations["$mockedFunction"]}" != 0 ] && __mocks_invocations["$mockedFunction"]=""
    [ "$__mocks_dos["$mockedFunction"]" ] && __mocks_dos["$mockedFunction"]=""
    [ "$__mocks_ifs["$mockedFunction"]" ] && __mocks_ifs["$mockedFunction"]=""
    [ "$__mocks_expectations["$mockedFunction"]" ] && __mocks_expectations["$mockedFunction"]=""
}

__mock_create() {
    local mockedFunction="$1"
    
    __mocks_functions["$mockedFunction"]="$mockedFunction"

    if [ ! "$__mocks_old_functions["$mockedFunction"]" ]; then
        __mocks_old_functions["$mockedFunction"]=$(declare -f $mockedFunction)
    fi
    __mocks_invocations["$mockedFunction"]=0

    eval """
    $mockedFunction()
    {
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
    __mocks_invocations["$mockedFunction"]=$((__mocks_invocations["$mockedFunction"] + 1 ))
}

__mock_do() {
    local mockedFunction="$1"
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
    shift

    __mock_check_equality "$__mocks_ifs["$mockedFunction"]" "$@"
    [ $? = 0 ] || return 1 
}

__mock_expect() {
    local parentPid=$1
    local mockedFunction="$2"
    shift; shift

    __mock_check_equality "$__mocks_expectations["$mockedFunction"]" "$@"
    if [ $? != 0 ]; then
        kill -s USR1 $parentPid
        return 1 
    fi
}

__mock_check_invocations() {
    local mockedFunction="$1"
    shift

    __mock_check_equality "$__mocks_invocations["$mockedFunction"]" "$@"
    if [ $? != 0 ]; then
        $mock_fail_function
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

    if [ "$actual" != "$expected" ]; then
        return 1 
    fi
}