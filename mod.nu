const DIR: path = path self . | path expand
# Bash environment adapter for nushell to read variables
# and capture function environment changes.
#
@example "load an environment variable" { "export N=10" | bash-env --load; $env | select N } --result {N: 10}
@example "capture a shell variable" { "ABC=123" | bash-env --vars } --result {env: {} shellvars: {ABC: 123}}
@example "capture function environment effects" {
    let script: path = mktemp --dry --suffix .env
    [
        "export A=0"
        "export B=0"
        "function showcase1() { export A=1; export B=1; S1='showcase1 shell var'; }"
        "function showcase2() { export A=2; export B=2; S2='showcase2 shell var'; }"
    ] | save $script
    chmod +x $script
    bash-env --exec [showcase1 showcase2] $script
} --result {
    env: {B: 0 A: 0}
    shellvars: {}
    fn: {
        showcase1: {env: {B: 1 A: 1} shellvars: {S1: "showcase1 shell var"}}
        showcase2: {env: {B: 2 A: 2} shellvars: {S2: "showcase2 shell var"}}
    }
}
export def --env main [ # nu-lint-ignore: add_doc_comment_exported_fn
    file?: string # Path to bash script to source environment changes from
    --vars(-v) # Enables capture of non-exported shell variables
    --exec(-e): list<string> = [] # List of functions to execute and capture environment changes from
    --load(-l) # Automatically load the environment variables (does not include shellvars)
    --meta(-m) # Disable removal of the `meta` field from the `bash-env-json` output
]: [
    oneof<nothing any> -> record<env: record, shellvars: record>
    oneof<nothing any> -> record<env: record, shellvars: record, fn: record>
] {
    let input: string = $in | default "" | str join "\n"
    let fn: bool = $exec | is-not-empty
    let args: record<func: list path: list> = {
        func: (if $fn {
            [--shellfns ($exec | str join ,)]
        })
        path: (if $file != null {
            [($file | path expand)]
        })
    } | default [] func path
    let rest: list<string> = $args | values | flatten | compact
    let json: record = with-env {
        path: [...$env.path $DIR]
    } { $input | bash-env-json ...$rest | complete }
    | match $in {
        {exit_code: 0, stdout: $o} => {
            try {
                $o | from json | default {} env
            } catch {
                error make {
                    msg: "json parse error"
                    label: {
                        text: text
                        span: (metadata $o).span
                    }
                    inner: [$in]
                }
            }
        }
        {exit_code: $n, stderr: $e} => {error: $"bash-env-json exited with code ($n)\n($e)"}
    }
    | match $in {
        {error: $e} => {
            error make {
                msg: $e
                labels: [
                    {
                        text: script
                        span: (metadata $file).span
                    }
                    {
                        text: functions
                        span: (metadata $exec).span
                    }
                ]
            }
        }
        _ if $meta => { $in }
        _ => { $in | reject meta }
    }
    if $load { load-env $json.env }
    if $vars or $fn { $json } else { $json.env }
}
