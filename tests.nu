#!/usr/bin/env nu
const DEFAULT: path = path self ./tests/suites/default.nu
const EXTRA: path = path self ./tests/suites/extra.nu
def main [
    --verbose(-v) # Show verbose error information for failing tests
    --extra(-e) # Run the extended test suite (includes tests from extra-module-tests.nu)
]: nothing -> nothing {
    let files: list<record<index: int item: path>> = [$DEFAULT]
    | if $extra { $in | append [$EXTRA] } else { $in }
    | enumerate
    for f in $files {
        print $"(ansi dark_gray_bold)#[(ansi rst)(ansi blue_bold)suite(ansi rst)\((ansi pink3)($f.item | path basename)(ansi rst))(ansi dark_gray_bold)](ansi rst)"
        nu --commands $'source ($f.item); do ({|verbose|
            let commands: list<string> = scope commands
                | where type == custom and name =~ ^test\s\w+ and description !~ ^\s*ignore\.*$
                | get name
            for test in $commands {
                print --no-newline $"($test | nu-highlight)(ansi attr_dimmed)...(ansi rst)"
                try {
                    $test
                    print $"(ansi g)[ok](ansi rst)"
                } catch {|err|
                    print --stderr $"(ansi r)[err](ansi rst)"
                    if ($verbose) { print --stderr $err.rendered }
                }
             }
        } | to nuon --serialize | from nuon) ($verbose)' # nu-lint-ignore: catch_builtin_error_try
    }
}
