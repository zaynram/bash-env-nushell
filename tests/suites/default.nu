use std/assert
use ../../../bash-env
def "test echo" []: nothing -> nothing {
    let actual = "export A=123" | bash-env
    let expected = {A: "123"}
    assert equal $actual $expected
}

def "test not-exported" []: nothing -> nothing {
    let actual = "A=123" | bash-env
    let expected = {}
    assert equal $actual $expected
}

def "test shell-variables-inline" []: nothing -> nothing {
    let actual = "A=123" | bash-env --vars | get shellvars
    let expected = {A: "123"}
    assert equal $actual $expected
}

def "test shell-variables-from-file" []: nothing -> nothing {
    let actual = bash-env tests/shell-variables.env
    let expected = {B: exported}
    assert equal $actual $expected
}

def "test empty-value" []: nothing -> nothing {
    let actual = "export A=\"\"" | bash-env
    let expected = {A: ""}
    assert equal $actual $expected
}

def "test simple-file" []: nothing -> nothing {
    let actual = bash-env tests/simple.env
    let expected = {A: a, B: b}
    assert equal $actual $expected
}

def "test cat-simple-file" []: nothing -> nothing {
    let actual = open --raw tests/simple.env | bash-env # nu-lint-ignore: catch_builtin_error_try
    let expected = {A: a, B: b}
    assert equal $actual $expected
}

def "test nasty-values-from-file" []: nothing -> nothing {
    let actual = bash-env "tests/Ming's menu of (merciless) monstrosities.env"
    let expected = [[SPACEMAN, QUOTE, MIXED_BAG]; ["One small step for a man ...", "\"Well done!\" is better than \"Well said!\"", "Did the sixth sheik's sixth sheep say \"baa\", or not?"]] | into record
    assert equal $actual $expected
}
