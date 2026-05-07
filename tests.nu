#!/usr/bin/env nu
const PARENT: path = path self ..
const SUITES: path = path self ./tests/suites/
const NU_LIB_DIRS = [$PARENT]
try { use bash-env-nushell }
# Run tests for the `bash-env` nushell module.
#
# The `--include` pattern uses regex matching (=~)
# against the basenames of the suite files.
def main [
    --verbose(-v) # Show verbose error information for failing tests
    --include(-i): string = .+ # Include tests from matching files in `tests/suites`
]: nothing -> nothing {
    let files: list<record<index: int item: path>> = try { ls $SUITES } catch { [] }
    | get name
    | where ($it | path basename) =~ $include
    | enumerate
    for f in $files {
        print $"(ansi dark_gray_bold)#[(ansi rst)(ansi cyan_bold)($f.item | path parse | get stem)(ansi rst)(ansi dark_gray_bold)](ansi rst)"
        nu --commands $'source ($f.item | path expand); do ({|verbose|
            let commands: list<string> = scope commands
                | where type == custom and name =~ ^test\s\w+ and description !~ ^\s*ignore\.*$
                | get name
            for test in $commands {
                print --no-newline $"(ansi blue)($test | split words | drop nth 0 | str join -)(ansi rst)(ansi attr_dimmed)...(ansi rst)"
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
