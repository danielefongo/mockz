typeset -gA __mocks_functions=()
typeset -gA __mocks_invocations=()
typeset -gA __mocks_old_functions=()
typeset -gA __mocks_musts=()
typeset -gA __mocks_ifs=()
typeset -gA __mocks_dos=()

mock_fail_function=fail

mock() {
    local mockedFunction=$1
    __mocks_functions["$mockedFunction"]="$mockedFunction"
    shift

    if [ "$#" -eq 0 ]; then
        __mock_create $mockedFunction
    else
        local command=$1
        local params="$2"
        shift; shift;

        case "$command" in
            must) __mocks_musts["$mockedFunction"]="$params";;
            if) __mocks_ifs["$mockedFunction"]="$params";;
            do) __mocks_dos["$mockedFunction"]="$params";;
            called) __mock_check_invocations $mockedFunction "$params" || return 1;;
            *) return;;
        esac

        mock $mockedFunction "$@"
    fi
}

rock() {
    local mockedFunction="$1"

    eval "$__mocks_old_functions["$mockedFunction"]"

    [ "$__mocks_functions["$mockedFunction"]" ] && __mocks_functions["$mockedFunction"]=""
    [ "$__mocks_old_functions["$mockedFunction"]" ] && __mocks_old_functions["$mockedFunction"]=""
    [ "$__mocks_invocations["$mockedFunction"]}" != 0 ] && __mocks_invocations["$mockedFunction"]=""
    [ "$__mocks_dos["$mockedFunction"]" ] && __mocks_dos["$mockedFunction"]=""
    [ "$__mocks_ifs["$mockedFunction"]" ] && __mocks_ifs["$mockedFunction"]=""
    [ "$__mocks_musts["$mockedFunction"]" ] && __mocks_musts["$mockedFunction"]=""
}

__mock_create() {
    local mockedFunction="$1"

    __mocks_old_functions["$mockedFunction"]=$(declare -f $mockedFunction)
    __mocks_invocations["$mockedFunction"]=0

    eval """
    $mockedFunction()
    {
        (( __mocks_invocations[\"$mockedFunction\"] = __mocks_invocations[\"$mockedFunction\"] + 1 ));
        __mock_must $mockedFunction \$@ || return
        __mock_if $mockedFunction \$@ || return
        __mock_do $mockedFunction
    }
    """
    return
}

__mock_do() {
    local mockedFunction="$1"
    local dos=$__mocks_dos["$mockedFunction"]
    eval "$__mocks_dos["$mockedFunction"]";
}

__mock_if() {
    local mockedFunction="$1"
    shift

    __mock_check_equality "$__mocks_ifs["$mockedFunction"]" "$@"
    [ $? = 0 ] || return 1 
}

__mock_must() {
    local mockedFunction="$1"
    shift

    __mock_check_equality "$__mocks_musts["$mockedFunction"]" "$@"
    if [ $? != 0 ]; then
        $mock_fail_function
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