const TESTS: path = path self ..
use std/assert

def "test shell-variables" []: nothing -> nothing {
    let actual = ("A=123" | bash-env --vars).shellvars
    let expected = {A: "123"}
    assert equal $actual $expected
}

def "test shell-variables-from-file" []: nothing -> nothing {
    let file = $TESTS | path join shell-variables.env
    let actual = bash-env --vars $file
    let expected = {
        shellvars: {A: "not exported"}
        env: {B: exported}
    }
    assert equal $actual $expected
}

def "test shell-functions" []: nothing -> nothing {
    let file = $TESTS | path join shell-functions.env
    let actual = bash-env --exec [f2 f3] $file
    let expected = {
        env: {B: "1", A: "1"}
        shellvars: {}
        fn: {
            f2: {
                env: {B: "2", A: "2"}
                shellvars: {C2: "I am shell variable C2"}
            }
            f3: {
                env: {B: "3", A: "3"}
                shellvars: {C3: "I am shell variable C3"}
            }
        }
    }
    assert equal $actual $expected
}
