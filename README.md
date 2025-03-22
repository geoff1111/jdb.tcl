# jdb.tcl
Simple JimTcl debugger
======================

Jdb.tcl can be used at at the command line or in JimTcl tests (tcltest)
using the "testing.tcl" helper script. Command line synopsis:

    ./jdb.tcl [-|JDB_CMD_FILE] JIM_SCRIPT ?args ...?

Jdb.tcl creates an "unknown" command as the debugger. It redefines
"proc" so that any JIM_SCRIPT proc will be named _cmd instead of cmd.
Almost all builtins are named from _cmd to cmd.

JIM_SCRIPT cannot define "unknown" and cannot redefine "proc". Thus
jdb.tcl cannot be used to debug itself, because it redefines proc and
unknown.

Empirically, the author determined that certain builtins could not be
renamed on a Debian system (if, pid, regexp and tailcall). You will
need to perform tests on your system if these need to be renamed, and
success is not guaranteed.

"Unknown" is first called to rename most builtins (from cmd to _cmd);
within the new "unknown" builtins are referred to by their new name
(_cmd) to avoid excess recursion. Users should use the _cmd pattern
for jimtcl builtins at the debugger prompt (except for if, pid, regexp
and tailcall, as per above).

Jdb.tcl relies on array ::debug internally. Users are cautioned
to be thoughtful if using the ::debug array variable. Use of ::debug
enables advanced or arbitrary functionality to be achieved. (For
example, to remove all break conditions the JimTcl command
"_set ::debug(breakconditions) {}" can be used at the debugger prompt.)

Once invoked, the debugger breaks at the first command of JIM_SCRIPT
using "si" (excepting commands which cannot be renamed such as if, pid,
etc).

Typical debugger subcommands such as "si", "n", "b" and "c" are
available. The debugger command "h" (or "?") provides general help.
Specific help on subcommand "subcmd" is available with "h subcmd"
(or "? subcmd").

Jdb.tcl reads from stdin ("-") or a JDB_COMMAND_FILE to accept
input (debugger commands) using an array variable ::debug(in).
Command input is overwritten to file "debug.history" using file handle
variable ::debut(out). To rerun the previous sequence of debugger
commands use:

    ./jdb.tcl debug.history JIMTCL_SCRIPT [ARG ...]

The debugger enters manual mode after the last command in
debug.history. Command sequence files can be created with a text
editor.

The format for specifying breakpoints in JIM_SCRIPT depends on whether
they are at the toplevel or within a proc. Toplevel breakpoints use the
format "file:FILENAME:LINE" (without quotes). Breakpoints within a proc
are formatted "proc:PROCNAME:CMD_NUMBER" (without quotes). The
"CMD_NUMBER" is the number of the command within the proc (including
subcommands) counting from 1.

A constraint (optional) can be defined with a breakpoint for
conditionality. The default constraint is "1" which represents
non-conditional breakpoint function. A breakpoint constraint is
evaluated as an "expr" expression and should be enclosed in braces if
it contains variables or commands. The format for a breakpoint with
a constraint is:

    b proc:PROCNAME:CMD_NO {constraint commands}

A breakcondition can be specified as follows:

    bc {$::debug(tclcmd) eq "puts"}

The break condition is evaluated as a JimTcl "expr". Break conditions
are versatile. For example they can break execution when a variable is
given a non-empty value (or a specific value):

    bc {$::myvar ne {}}

In general, breakconditions are preferable to a combination of break
points and repeated stepping when using jdb.tcl for automated tests.
Otherwise, whenever the JimTcl script is altered, the tests may become
out of sync.

Any JimTcl command can be used at the debugger prompt, including
"exec", so debugging can extend to more complex JimTcl scripts
such as webservers. Once the debugger reaches the point immediately
prior to the webserver accepting a connection, curl could be
invoked in the background at the debugger command prompt to connect:

    _exec curl 127.0.0.1:8080 &

Conventions can be used to facilitate testing. To simplify capturing
specific output (ignoring the rest) testing.tcl captures any debug
output surrounded with XML tags <dbg> and </dbg>.

When used with the "testing.tcl" helper script (which sources JimTcl
"tcltest.tcl"), the debugger can be used for unit and/or integration
testing, and for code review. Nearly any part of a JimTcl script
can be instrumented live or in tests, in virtually any script context.
Debugger driven development becomes possible.
