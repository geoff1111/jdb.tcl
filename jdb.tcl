#! ./jimsh
# Copyright (c) Geoffrey P. Messer 2025.
# Adjust the path above to path for jimsh, e.g. /usr/bin/jimsh

if {$argv in {-h -? --help}} {
  puts {
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
variable ::debug(out). To rerun the previous sequence of debugger
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
  }
} elseif {$argc < 2} {
  puts "USAGE:\n $argv0 \[-|JDB_CMD_FILE\] JIM_SCRIPT ?args ...?"
  puts " $argv0 --help | less"
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
        pv {{} {print complete return value}}
        q {{} {exit debugger}}
        si {{} {step into proc}}
        so {{} {step out of proc}}
        st {{} {print current stacktrace}}
        {""} {{} {repeat prior command}}
        cmd {{} {execute JimTcl "cmd"}}
    } \
    in stdin \
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
      if {[_dict get [_info frame -1] file] ne {}} {
        _set ::debug(loc) file:[_dict get [_info frame -1] file]:[_dict get [_info frame -1] line]
      } else {
        _set ::debug(loc) proc:[_lindex $::debug(stack) end-1]:[_lindex $::debug(stackcmdno) end-1]
      }
      # set stack length, and whether usrcmd loop is entered:
      _set getdebugcmd 0
      _switch -- $::debug(debugcmd) {
        si {
          _set ::debug(setstacklen) [_llength $::debug(stack)]
          _set getdebugcmd 1 ;# allow for stack to go deeper
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
          _puts -nonewline "\[b bc c h n pc pr q si so st\]>> "
          _flush stdout
          if {$::debug(in) ne "stdin" && [_eof $::debug(in)]} {
            _puts "\[input changed to: stdin\]"
            _set ::debug(in) stdin
            _continue
          }
          _gets $::debug(in) cmd
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
            {^b .+$} {
              _lappend ::debug(breakpoints) [_dict create location [_lindex $cmd 1] constraint \
                [_expr {[_llength $cmd] == 2 ? 1 : [_lindex $cmd 2]}]]
            }
            ^bc$ {
              _foreach b $::debug(breakconditions) {
                _puts "break condition: $b"
              }
            }
            {^bc .+$} {
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
            {^h .*$} -
            {^\? .*$} {
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
            ^q$ {
              _exit 1
            }
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
              _catch {_uplevel $cmd} res
              _puts $res
              _set ::debug(active) 1
            }
          }
        }
      }
      _set rc [_catch {_uplevel _$args} ::debug(retval)]
      if {$getdebugcmd} {
        # for a printed user command, the output is printed...
        # the output is trimmed to about 63 chars at most...
        _puts "\n=([_info returncodes $rc])=>\
          \"[_string range $::debug(retval) 0 60][_expr {[_string length $::debug(retval)]>60?"...":""}]\"\n"
      }
      _set ::debug(stack) [_lrange $::debug(stack) 0 end-1]
      _set ::debug(stackcmdno) [_lrange $::debug(stackcmdno) 0 end-1]
      _return -code $rc $::debug(retval)
    } else {
      _uplevel _$args
    }
  }
  _set ::debug(active) 1
 }
 # the final two commands are purposely out of alphabetical order (below):
 unknown after alarm alias append apply array binary break catch cd class \
   clock close collect concat continue curry defer dict ensemble env eof eval \
   exec exists exit expr fconfigure file fileevent finalize flush for format \
   function getref gets glob global incr info interp join kill lambda lappend \
   lassign lindex linsert list llength lmap lrange lset load load_ssl_certs \
   local loop lrepeat lreplace lreverse lsearch lsort namespace open os.fork \
   os.gethostname os.getids os.uptime pack package parray pipe popen proc \
   puts pwd rand range read readdir ref regsub return scan seek set setref \
   signal sleep socket source split string subst super switch tell throw time \
   timerate tree try unpack uplevel unset upcall update upvar variable vwait wait \
   while foreach rename
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
