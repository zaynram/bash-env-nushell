#!/usr/bin/env nu
const PARENT: path = path self ..
const SUITES: path = path self ./tests/suites/
const NU_LIB_DIRS = [$PARENT]
use bash-env
# Run tests for the `bash-env` nushell module.
#
# The `--include` pattern uses regex matching (=~)
# against the basenames of the suite files.
def main [
    --verbose(-v) # Show verbose error information for failing tests
    --include(-i): string = default # Include tests from matching files in `tests/suites`
]: nothing -> nothing {
    let files: list<record<index: int item: path>> = try { ls $SUITES } catch { [] }
    | get name
    | where ($it | path basename) =~ $include
    | enumerate
    for f in $files {
        print $"(ansi dark_gray_bold)#[(ansi rst)(ansi blue_bold)suite(ansi rst)\((ansi pink3)($f.item | path basename)(ansi rst))(ansi dark_gray_bold)](ansi rst)"
        nu --commands $'source ($f.item | path expand); do ({|verbose|
            let commands: list<string> = scope commands
                | where type == custom and name =~ ^test\s\w+ and description !~ ^\s*ignore\.*$
                | get name
            for test in $commands {
                print --no-newline $"($test | nu-highlight)(ansi attr_dimmed)...(ansi rst)"
                try {
                    with-env {NU_LIB_DIRS: ($env.NU_LIB_DIRS ++ $NU_LIB_DIRS)} { $test }
                    print $"(ansi g)[ok](ansi rst)"
                } catch {|err|
                    print --stderr $"(ansi r)[err](ansi rst)"
                    if ($verbose) { print --stderr $err.rendered }
                }
             }
        } | to nuon --serialize | from nuon) ($verbose)' # nu-lint-ignore: catch_builtin_error_try
    }
}
