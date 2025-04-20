Small JimTcl debugger
=====================

`Jdb.tcl` is simple and small--the debugger proper (excluding
comments and code implementing this help text, version information etc)
is implemented in about 250 single lines of code.

`Jdb.tcl` can be used at at the command line or in JimTcl tests (tcltest)
using the `testing.tcl` helper script. Command line synopsis:

    ./jdb.tcl --help
    ./jdb.tcl --version
    ./jdb.tcl [-|JDB_CMD_FILE] JIM_SCRIPT ?args ...?

`Jdb.tcl` ultimately creates an `unknown` command as the debugger. It
redefines `proc` so that any `JIM_SCRIPT` proc will be named `_cmd` instead
of `cmd`. Most builtins are renamed from `cmd` to `_cmd`.

(`JIM_SCRIPT` cannot define `unknown` and cannot redefine `proc`. Thus
`jdb.tcl` cannot be used to debug itself, because it redefines `proc` and
`unknown`.)

Empirically, the author determined that certain JimTcl builtins cannot be
renamed on a Debian system, or if renamed, the functionality of `jdb.tcl`
is impaired. These are: `if`, `pid`, `regexp`, `tailcall`, `stdin`, `stdout`
and `stderr`. (You may need to perform tests on your system if any of these
need to be renamed, and success is not guaranteed.) This issue is significant
insofar as it is not possible to break on these particular builtins.

The debugger control commands `si` (step in), `so` (step out),
`n` (next), `c` (continue) and `q` (quit debugger) directly control
debugger movement through `JIM_SCRIPT`. Typing Enter repeats the last
debugger control command (except for `q`, since it causes the debugger
to exit).

Breakpoints and breakconditions are set with `b` and `bc` respectively
and either can cause execution of `JIM_SCRIPT` to pause and for control to
be returned to the user at the debugger prompt. `bcr` is helpful to reset
the break condition list. In interactive mode, the debugger will
break on the commands `exit` or `error` allowing further investigation
of problems before the debugger exits. In non-interactive mode `exit` and
`error` are not automatically set as break conditions, so the debugger
will exit if these are met and are not manually set as break conditions.
(This latter behavior is generally appropriate for batch mode).

All other debugger commands display information. For instance, the debugger
command `h` (or `?`) display general help consisting of a synopsis of all
debugger commands. Specific help on subcommand "subcmd" is available with
`h subcmd` (or `? subcmd`).

In addition to debugger control and display commands, any JimTcl command
can be used at the debugger prompt, including `exec`, so debugging can
extend to more complex JimTcl scripts such as webservers. Tcl commands can
extend over multiple lines. Once the debugger reaches the point
immediately prior to the webserver accepting a connection, `curl` could be
invoked in the background at the debugger command prompt to connect:

    exec curl 127.0.0.1:8080 &

`Jdb.tcl` relies on array `::debug` internally. Use of `::debug` enables
various arbitrary functions to be achieved. Peruse `::debug` array
initialization in the source of `jdb.tcl` to assess what ad hoc functions
might be achievable.

When invoked, the debugger breaks at the first JimTcl command of `JIM_SCRIPT`
using `si` (excluding JimTcl commands which cannot be renamed such as `if`,
`pid`, etc).

`Jdb.tcl` reads from stdin (`-`) or a `JDB_COMMAND_FILE` to accept
input (debugger commands) using array element `::debug(in)`. Command input is
overwritten to file `debug.history` using file handle variable `::debug(out)`.
To rerun the previous sequence of debugger commands, first change the name
of `debug.history` so that the input is not overwritten as soon as `jdb.tcl`
starts:

    mv debug.history debug.history.in
    ./jdb.tcl debug.history.in JIMTCL_SCRIPT [ARG ...]

The debugger enters interactive mode after the last command in
`debug.history.in` is executed. Command sequence files can be created with
a text editor.

The format for specifying breakpoints in `JIM_SCRIPT` depends on whether
they are at the toplevel or within a proc. Toplevel breakpoints use the
format `file:FILENAME:LINE`. Breakpoints within a proc are formatted
`proc:PROCNAME:CMD_NUMBER`. The `CMD_NUMBER` is the number of the command
within the proc (including subcommands) counting from 1.

A constraint (optional) can be defined with a breakpoint for
conditionality. The default constraint is `1` which causes a breakpoint
to be non-conditional. A breakpoint constraint is evaluated as an `expr`
expression and should be enclosed in braces if it contains variables or
commands. The format for a breakpoint with a constraint is:

    b proc:PROCNAME:CMD_NO {constraint expression}

A breakcondition can be specified as follows:

    bc {$::debug(tclcmd) eq "puts"}

The break condition is evaluated as a JimTcl `expr`. Break conditions
are versatile. For example they can break execution when a variable is
given a non-empty value (or a specific value):

    bc {$::myvar ne {}}

When using `jdb.tcl` for automated tests, breakconditions are preferable
to a combination of break points and repeated stepping. Otherwise, whenever
the JimTcl script is altered, tests may become out of sync.

Conventions can be used to facilitate testing. To simplify capturing
specific output (ignoring the rest) testing.tcl captures any debug
output surrounded by XML tags `<dbg>` and `</dbg>`. `Jdb.tcl` has a
convenience command `pd expr` which will print the value of `expr`
surrounded by `<dbg>` tags. Importantly, `expr` must contain no line breaks
(i.e. it must be on a single line, however long), otherwise `jdb.tcl`
will likely malfunction.

When used with the `testing.tcl` helper script (which sources JimTcl
`tcltest.tcl`), the debugger can be used for unit and/or integration
tests. Nearly any part of a JimTcl script can be instrumented live
or in tests, in virtually any script context.
