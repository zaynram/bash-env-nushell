# Bash environment for Nushell

Historically Bash environment for Nushell was provided via the `nu_plugin_bash_env` plugin in this repo.

That plugin has now been removed in favour of the `bash-env` module, which is more feature rich and also embarrassingly simpler than the plugin.

#### Introduction

This edition of the adapter focused on catering to Nushell's strengths and prioritizing "thinking in nu" when putting the polish on.

Environment variables (only) may be auto-loaded with `-l` or `--load`. Shell variables cannot be automatically loaded.

```nu
# bash-env-nushell
# * forked by zaynram on 2026-05-07

## Installation

> $NU_LIB_DIRS.0?
| default $env.pwd
| path join bash-env
| prepend [https://github.com/zaynram/bash-env-nushell]
| git clone ...$in

## Basic Usage

> ssh-agent | bash-env --load
+------------------------------------+
| SSH_AUTH_SOCK | /tmp/ssh-x/agent.n |
| SSH_AGENT_PID | 648298             |
+------------------------------------+
> $env.ssh_agent_pid
648298
```

#### Shell Variables

Rather than folding shell variables in with the environment variables as was done by the plugin, the `-v` or `--vars` option results in structured output with separate `env` and `shellvars`.

Metadata from `bash-env-json` can optionally be preserved using the `-m` or `--meta` flag.

```nu
# capture shell variables 
> echo ABC=123 | bash-env --vars
+-------------------------------+
| env       | {record 0 fields} |
| shellvars | +-------------+   |
|           | | ABC  | 123  |   |
|           | +-------------+   |
+-------------------------------+

# add shell variables to env
> [A=1 B=2 C=3] 
| bash-env --vars
| get shellvars
| load-env
> $env | select A B C
+-------------------------------+
| A         | 1                 |
| B         | 2                 |
| C         | 3                 |
+-------------------------------+

```

---

## Original Examples

The remaining examples are unedited from the forked repository and are not accurate going into the future. They are still useful to get an idea of what's possible; the main difference is `-f` and `--fn` was replaced by `-e` and `--exec`.

```nu
> (bash-env /etc/os-release -s).shellvars
╭───────────────────┬─────────────────────────────────────────╮
│ LOGO              │ nix-snowflake                           │
│ NAME              │ NixOS                                   │
│ BUG_REPORT_URL    │ https://github.com/NixOS/nixpkgs/issues │
│ HOME_URL          │ https://nixos.org/                      │
│ VERSION_CODENAME  │ vicuna                                  │
│ ANSI_COLOR        │ 1;34                                    │
│ ID                │ nixos                                   │
│ PRETTY_NAME       │ NixOS 24.11 (Vicuna)                    │
│ DOCUMENTATION_URL │ https://nixos.org/learn.html            │
│ SUPPORT_URL       │ https://nixos.org/community.html        │
│ IMAGE_ID          │                                         │
│ VERSION_ID        │ 24.11                                   │
│ VERSION           │ 24.11 (Vicuna)                          │
│ IMAGE_VERSION     │                                         │
│ BUILD_ID          │ 24.11.20240916.99dc878                  │
╰───────────────────┴─────────────────────────────────────────╯
```

### Shell Functions

Shell functions may be run and their effect on the environment captured.

```nu
> cat ./tests/shell-functions.env
export A=1
export B=1

function f2() {
        export A=2
        export B=2
        C2="I am shell variable C2"
}

function f3() {
        export A=3
        export B=3
        C3="I am shell variable C3"
}
> bash-env ./tests/shell-functions.env
╭───┬───╮
│ B │ 1 │
│ A │ 1 │
╰───┴───╯
> bash-env -f [f2 f3] ./tests/shell-functions.env
╭───────────┬──────────────────────────────────────────────────────────╮
│           │ ╭───┬───╮                                                │
│ env       │ │ B │ 1 │                                                │
│           │ │ A │ 1 │                                                │
│           │ ╰───┴───╯                                                │
│ shellvars │ {record 0 fields}                                        │
│           │ ╭────┬─────────────────────────────────────────────────╮ │
│ fn        │ │    │ ╭───────────┬─────────────────────────────────╮ │ │
│           │ │ f2 │ │           │ ╭───┬───╮                       │ │ │
│           │ │    │ │ env       │ │ B │ 2 │                       │ │ │
│           │ │    │ │           │ │ A │ 2 │                       │ │ │
│           │ │    │ │           │ ╰───┴───╯                       │ │ │
│           │ │    │ │           │ ╭────┬────────────────────────╮ │ │ │
│           │ │    │ │ shellvars │ │ C2 │ I am shell variable C2 │ │ │ │
│           │ │    │ │           │ ╰────┴────────────────────────╯ │ │ │
│           │ │    │ ╰───────────┴─────────────────────────────────╯ │ │
│           │ │    │ ╭───────────┬─────────────────────────────────╮ │ │
│           │ │ f3 │ │           │ ╭───┬───╮                       │ │ │
│           │ │    │ │ env       │ │ B │ 3 │                       │ │ │
│           │ │    │ │           │ │ A │ 3 │                       │ │ │
│           │ │    │ │           │ ╰───┴───╯                       │ │ │
│           │ │    │ │           │ ╭────┬────────────────────────╮ │ │ │
│           │ │    │ │ shellvars │ │ C3 │ I am shell variable C3 │ │ │ │
│           │ │    │ │           │ ╰────┴────────────────────────╯ │ │ │
│           │ │    │ ╰───────────┴─────────────────────────────────╯ │ │
│           │ ╰────┴─────────────────────────────────────────────────╯ │
╰───────────┴──────────────────────────────────────────────────────────╯

> (bash-env -f [f2 f3] ./tests/shell-functions.env).fn.f2.env
╭───┬───╮
│ B │ 2 │
│ A │ 2 │
╰───┴───╯
> (bash-env -f [f2 f3] ./tests/shell-functions.env).fn.f2.env | load-env
> echo $env.B
2

```