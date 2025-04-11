#! ./jimsh

# Adjust the path above to path for jimsh, e.g. /usr/bin/jimsh
# Copyright (c) Geoffrey P. Messer 2025.
# GNU Affero General Public Licenced (Version 3.0).

if {$argv in {-v -V --version}} {
  puts "jdb.tcl version 0.1"
} elseif {$argv in {-h -? --help}} {
  puts {
Small JimTcl debugger
=====================

`Jdb.tcl` is simple and small--the debugger proper (excluding
comments and code implementing this help text, version information etc)
is implemented in less than 250 single lines of code.

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
need to be renamed, and success is not guaranteed.)

The debugger control commands `si` (step in), `so` (step out),
`n` (next), `c` (continue) and `q` (quit debugger) directly control
debugger movement through `JIM_SCRIPT`. Typing Enter repeats the last
debugger control command (except for `q`, since it causes the debugger
to exit).

Breakpoints and breakconditions are set with `b` and `bc` respectively
and either can cause execution of `JIM_SCRIPT` to pause and for control to
be returned to the user at the debugger prompt.

All other debugger commands display information. For instance, the debugger
command `h` (or `?`) display general help consisting of a synopsis of all
debugger commands. Specific help on subcommand "subcmd" is available with
`h subcmd` (or `? subcmd`).

In addition to debugger control and display commands, any JimTcl command
can be used at the debugger prompt, including `exec`, so debugging can
extend to more complex JimTcl scripts such as webservers. The `_cmd` pattern
should be used for most JimTcl builtins at the debugger prompt (except for
those which are not renamed such as `if`, `pid`, etc). Tcl commands extending
over multiple lines are supported. Once the debugger reaches the point
immediately prior to the webserver accepting a connection, `curl` could be
invoked in the background at the debugger command prompt to connect:

    _exec curl 127.0.0.1:8080 &

`Jdb.tcl` relies on array `::debug` internally. Use of `::debug` enables
various arbitrary functions to be achieved. (For example, to remove all break
conditions the JimTcl command `_set ::debug(breakconditions) {}` can be
used at the debugger prompt.) Peruse `::debug` array initialization in the
source of `jdb.tcl` to assess what ad hoc functions might be achievable.

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
output surrounded by XML tags `<dbg>` and `</dbg>`.

When used with the `testing.tcl` helper script (which sources JimTcl
`tcltest.tcl`), the debugger can be used for unit and/or integration
tests. Nearly any part of a JimTcl script can be instrumented live
or in tests, in virtually any script context.
  }
} elseif {$argc < 2} {
  puts "USAGE:\n $argv0 \[-|JDB_CMD_FILE\] JIM_SCRIPT ?args ...?"
  puts " $argv0 --help | less"
  puts " $argv0 --version"
} else {
  set ::debug [dict create \
    active 0 \
    breakconditions {} \
    breakpoints {} \
    debugcmd si \
    help {
        b {{?loc? ?constraint?} {print/add breakpoint/constraint}}
        bc {{?condition?} {print/add break condition}}
        c {{} {continue to next breakpoint}}
        h {{?cmd?} {print general or specific help}}
        ? {{?cmd?} {print general or specific help}}
        n {{} {step to next command}}
        pc {{} {print complete command and args}}
        pv {{} {print return value of last command}}
        q {{} {exit debugger}}
        si {{} {step into proc}}
        so {{} {step out of proc}}
        st {{} {print current stacktrace}}
        {""} {{} {repeat prior command}}
        cmd {{} {execute JimTcl "cmd"}}
    } \
    in stdin \
    notrenamed {if pid regexp tailcall stdout stdin stderr} \
    out [open debug.history w] \
    outfirst 1 \
    retval {} \
    setstacklen 1 \
    stack toplevel \
    stackcmdno 0 \
    tclcmd {}]
 if {[lindex $argv 0] ne "-"} {
  set ::debug(in) [open [lindex $argv 0] r]
 }
 set argv [lassign [lrange $argv 1 end] argv0]
 set argc [llength $argv]
 proc unknown {args} {
  foreach cmd $args {
    rename $cmd _$cmd
  }
  _proc proc {args} {
    _uplevel _proc _$args
  }
  _proc unknown {args} {
    if {[_string index $args 0] eq "_"} {
      _puts stderr "error: unknown command $args"
      _exit 1
    }
    if {$::debug(active)} {
      _set ::debug(tclcmd) [_lindex $args 0]
      _lappend ::debug(stack) $::debug(tclcmd)
      _lappend ::debug(stackcmdno) 0
      _lset ::debug(stackcmdno) end-1 [_expr {[_lindex $::debug(stackcmdno) end-1]+1}]
      if {[_dict exists [_info frame -1] file] && [_dict get [_info frame -1] file] ne {}} {
        _set ::debug(loc) file:[_dict get [_info frame -1] file]:[_dict get [_info frame -1] line]
      } else {
        _set ::debug(loc) proc:[_lindex $::debug(stack) end-1]:[_lindex $::debug(stackcmdno) end-1]
      }
      # set stack length, and whether usrcmd loop is entered:
      _set getdebugcmd 0
      _switch -- $::debug(debugcmd) {
        si {
          # allow for stack to go deeper
          _set ::debug(setstacklen) [_llength $::debug(stack)]
          _set getdebugcmd 1
        }
        n {
          if {[_llength $::debug(stack)] <= $::debug(setstacklen)} {
            # allow stack to stay the same or reduce
            _set ::debug(setstacklen) [_llength $::debug(stack)]
            _set getdebugcmd 1
          }
        }
        so {
          if {[_llength $::debug(stack)] < $::debug(setstacklen)} {
            # stack must reduce
            _set ::debug(setstacklen) [_llength $::debug(stack)]
            _set getdebugcmd 1
          }
        }
        c {
          _foreach bp $::debug(breakpoints) {
            _set b [_dict get $bp location]
            _set c [_string cat "{" [_dict get $bp constraint] "}"]
            if {$b eq $::debug(loc) && [_uplevel _expr $c]} {
              _set ::debug(debugcmd) si
              _set ::debug(setstacklen) [_llength $::debug(stack)]
              _set getdebugcmd 1
              _puts "\[breakpoint loc=$b; constraint=$c\]"
              _break
            }
          }
          _foreach bc $::debug(breakconditions) {
            if {[_uplevel _expr [_string cat "{" $bc "}"]]} {
              _set ::debug(debugcmd) si
              _set ::debug(setstacklen) [_llength $::debug(stack)]
              _set getdebugcmd 1
              _puts "\[break condition=$bc\]"
              _break
            }
          }
        }
      }
      if {$getdebugcmd} {
        # trim jimtcl command to a single line, and 54 or less chars on that
        # line. Use pc to print entire command (and args).
        _set trimargs [_regsub {\n(.*\n)*} $args {...}]
        _set trimargs [_expr {[_string length $trimargs]>54 ? "[_string range $trimargs 0 51]..." : $trimargs}]
        _puts "\[$::debug(loc)\] $trimargs"
        _while 1 {
          _puts -nonewline "\[b bc c h n pc pv q si so st\]>> "
          _flush stdout
          if {[_gets $::debug(in) cmd]==-1 && $::debug(in) ne "stdin"} {
            _puts "\[input changed to: stdin\]"
            _set ::debug(in) stdin
            _continue
          }
          if {$::debug(in) ne "stdin"} {
            _puts $cmd
          }
          if {$::debug(outfirst)} {
            # this avoids an unnecessary starting newline in debug.history
            _puts -nonewline $::debug(out) $cmd
            _set ::debug(outfirst) 0
          } else {
            _puts -nonewline $::debug(out) \n$cmd
          }
          _switch -regexp -- [_string trim $cmd] {
            ^b$ {
              _foreach b $::debug(breakpoints) {
                _puts "breakpoint: [_dict get $b location]: [_dict get $b constraint]"
              }
            }
            {^b +.+$} {
              _lappend ::debug(breakpoints) [_dict create location [_lindex $cmd 1] constraint \
                [_expr {[_llength $cmd] == 2 ? 1 : [_lindex $cmd 2]}]]
            }
            ^bc$ {
              _foreach b $::debug(breakconditions) {
                _puts "break condition: $b"
              }
            }
            {^bc +.+$} {
              _lappend ::debug(breakconditions) [_lindex $cmd 1]
            }
            ^c$ {
              _set ::debug(debugcmd) c
              _set getdebugcmd 0
              # all printworthy commands end in _break
              _break
            }
            ^h$ -
            {^\?$} {
              _foreach {cmd1 detail1 cmd2 detail2} $::debug(help) {
                _lassign $detail1 opt1 msg1
                _lassign $detail2 opt2 msg2
                _puts [_format "   %-4s %-35s   %-4s %-35s" $cmd1 $msg1 $cmd2 $msg2]
              }
              _puts "Use \"? cmd\" or \"h cmd\" for specific help."
            }
            {^h +.*$} -
            {^\? +.*$} {
              _set subcmd [_lindex $cmd 1]
              if {[_dict exists $::debug(help) $subcmd]} {
                _lassign [_dict get $::debug(help) $subcmd] opt msg
                _puts [_format "   %s %s   %s" $subcmd $opt $msg]
              } else {
                _puts "cmd \"$subcmd\" not found"
              }
            }
            ^n$ {
              _set ::debug(debugcmd) n
              _break
            }
            ^pc$ {
              _puts $args
            }
            ^pv$ {
              _puts $::debug(retval)
            }
            ^q$ _exit
            ^si$ {
              _set ::debug(debugcmd) si
              _break
            }
            ^so$ {
              _set ::debug(debugcmd) so
              _break
            }
            ^st$ {
              _puts "stack: [_lmap x $::debug(stack) y $::debug(stackcmdno) {_list $x $y}]"
            }
            ^$ _break
            default {
              _set ::debug(active) 0
              # accept multi-line commands:
              _while {![_info complete $cmd]} {
                _gets $::debug(in) addit
                _puts -nonewline $::debug(out) \n$addit
                _append cmd \n $addit
              }
              # print any errors:
              if {[_catch {_uplevel $cmd} res]} {
                _puts $res
              }
              _set ::debug(active) 1
            }
          }
        }
      }
      _set rc [_catch {_uplevel _$args} ::debug(retval)]
      if {$getdebugcmd} {
        # for a printed user command, the printed output is trimmed to
        # about 63 chars at most.
        _puts "\n=([_info returncodes $rc])=>\
          \"[_string range $::debug(retval) 0 60][_expr {[_string length $::debug(retval)]>60?"...":""}]\"\n"
      }
      _set ::debug(stack) [_lrange $::debug(stack) 0 end-1]
      _set ::debug(stackcmdno) [_lrange $::debug(stackcmdno) 0 end-1]
      _return -code $rc $::debug(retval)
    } else {
      # continuing
      _return [_uplevel _$args]
    }
  }
  _set ::debug(active) 1
 }
 # unknown is delivered a list of builtins to rename.
 # This list must have "foreach" and "rename" last (as below)
 # Builtins which cannot be renamed, such as if, pid, regexp, tailcall,
 # stdin, stdout and stderr are not supplied to unknown here.
 # Builtins containing + - / * . : or " " are not renamed, as per regexp
 # in expr below.
 unknown {*}[lmap x [info commands] {
   expr {$x in [list rename foreach {*}$::debug(notrenamed)]
         || [regexp {[+-/*.: ]+} $x] ? [continue] : $x}
 }] foreach rename
 if {[_file readable $argv0]} {
   _source $argv0
 } else {
   _puts stderr "$argv0 not readable"
 }
 if {$::debug(in) ne "stdin"} {
   _close $::debug(in)
 }
 _close $::debug(out)
}
