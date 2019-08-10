typeset -gA __mocks_functions
typeset -gA __mocks_dos
typeset -gA __mocks_ifs
typeset -gA __mocks_musts

mock_fail_function=fail
mock_equals_function=assertEquals

mock() {
    local mockedFunction=$1
    __mocks_functions["$mockedFunction"]="$mockedFunction"
    shift

    if [ "$#" -eq 0 ]; then
        eval """
        $mockedFunction()
        {
            __mock_must $mockedFunction \$@ || return
            __mock_if $mockedFunction \$@ || return
            __mock_do $mockedFunction
        }
        """
        return
    else
        local command=$1
        local params="$2"
        shift;
        shift;

        if [ "$command" = "do" ]; then
            __mocks_dos["$mockedFunction"]="$params"
        fi

        if [ "$command" = "if" ]; then
            __mocks_ifs["$mockedFunction"]="$params"
        fi

        if [ "$command" = "must" ]; then
            __mocks_musts["$mockedFunction"]="$params"
        fi

        mock $mockedFunction "$@"
    fi
}

rock() {
    local mockedFunction="$1"
    __mocks_functions[$__mocks_functions[(i)$mockedFunction]]=() 2>/dev/null
    __mocks_dos[$__mocks_dos[(i)$mockedFunction]]=() 2>/dev/null
    __mocks_ifs[$__mocks_ifs[(i)$mockedFunction]]=() 2>/dev/null
    __mocks_musts[$__mocks_musts[(i)$mockedFunction]]=() 2>/dev/null
}

__mock_do() {
    local mockedFunction="$1"
    local dos=$__mocks_dos["$mockedFunction"]
    eval "$__mocks_dos["$mockedFunction"]";
}

__mock_if() {
    local mockedFunction="$1"
    shift

    local ifs=$__mocks_ifs["$mockedFunction"]

    local actualParams="$(echo $@)"
    local expectedParams="$(echo $ifs)"

    if [ -z "$expectedParams" ]; then
        return
    fi

    [ "$actualParams" = "$expectedParams" ] || return 1
}

__mock_must() {
    local mockedFunction="$1"
    shift

    local musts="$__mocks_musts[\"$mockedFunction\"]"

    local actualParams="$(echo $@)"
    local expectedParams="$(echo $musts)"

    if [ -z "$expectedParams" ]; then
        return
    fi

    if [ "$actualParams" != "$expectedParams" ]; then
        $mock_fail_function
        return 1 
    fi
}
