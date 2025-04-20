#! ./jimsh
# Adjust the path above to path for jimsh, e.g. /usr/bin/jimsh
# Copyright (c) Geoffrey P. Messer 2025.
# GNU Affero General Public Licenced (Version 3.0).

if {$argv in {-v -V --version}} {
  puts "testing.tcl version 0.2"
} elseif {$argv in {-h -? --help}} {
  puts {
The following is an example of a test file for a simple webserver
illustrating the kinds of test which can be automated.

    #! ./jimsh

    set thisdir [file dirname [info script]]
    set script [file join $thisdir b3k.tcl]
    set tclsh [file join $thisdir jimbinary/b3k]
    set ::jim_tcltest_path [file join $thisdir ../jimtcl/tcltest.tcl]

    source [file join $thisdir testing.tcl]

    needs constraint jim
    constraint cmd puts

    test b3k-001.001 {startup test mimetype} -body {
      debug $tclsh $script {
        # set breakcondition (A) at first call of "foreach"
        bc {$::debug(tclcmd) eq "foreach"}
        c
        # breakcondition (A)
        pd $::w4(_mimetype)
        exit
      }
    } -result {text/html; charset=utf-8}

    test b3k-001.002 {startup test -mxage valid input} -body {
      debug $tclsh "$script -max-age 1024" {
        bc {$::debug(tclcmd) eq "w4-start"}
        c
        bc {[_exists ::w4]}
        c
        bcr
        bc {$::w4(_mxage) ne 120}
        c
        pd $::w4(_mxage)
        exit
      }
    } -result {1024}

    test b3k-001.003 {startup test -mxage invalid input} -body {
      debug $tclsh "$script -max-age xxx" {
        bc {$::debug(tclcmd) eq "puts"}
        c
        pd $::w4(_mxage),$val
        exit
      }
    } -result {120,xxx}

    test b3k-001.004 {startup test -sa "yes" input} -body {
      debug $tclsh "$script -sa yes" {
        bc {[_exists ::w4] && $::w4(_sa) ne 0}
        c
        pd $::w4(_sa)
        exit
      }
    } -result {1}

    test b3k-001.005 {startup test -sa "no" input} -body {
      debug $tclsh "$script -sa no" {
        bc {[_exists ::w4]}
        c
        set ::w4(_sa) 4
        bcr
        bc {$::w4(_sa) ne 4}
        c
        pd $::w4(_sa)
        exit
      }
    } -result {0}

    test b3k-002.001 {setpeername test for REMOTE_ADDR and REMOTE_PORT} -body {
      debug $tclsh $script {
        # set breakpoint (A) in proc setpeername (once server running)
        b proc:setpeername:1
        # set breakcondition (B) at "puts" prior to "vwait" starting server
        bc {$::debug(tclcmd) eq "puts"}
        c
        # breakcondition (B): action: start client
        exec curl 127.0.0.1:8080 &
        c
        # breakpoint (A): set breakcondition (C) when ::w4(REMOTE_PORT) is set
        bc {$::w4(REMOTE_PORT) ne {}}
        c
        # breakcondition (C): print dbg values and exit
        pd $::w4(REMOTE_ADDR):$::w4(REMOTE_PORT)
        exit
     }
    } -match regexp -result {^127.0.0.1:[0-9]+$}

    testreport
  }
} elseif {![exists ::jim_tcltest_path]} {
  error "set ::jim_tcltest_path (path to JimTcl tcltest.tcl)"
} else {
  source $::jim_tcltest_path

  # invoke the jdb.tcl debugger on tclscript and pass a string containing
  # debugger commdands to it. The debugger command string is trimmed to remove
  # whitespace from the start and end overall, and also from the start and
  # end of each line.

  proc debug {tclsh tclscript debuggercmds} {
    foreach line [split [string trim $debuggercmds] "\n"] {
      if {! [string match #* $line]} {
        # (ignore comment lines)
        append trimmedcmds [string trim $line] "\n"
      }
    }
    set trimmedcmds [string trim $trimmedcmds]
    return [string map [list <dbg> "" </dbg> ""] \
           [string cat \
           {*}[regexp -inline -all <dbg>.*?</dbg> \
           [exec $tclsh jdb.tcl - {*}$tclscript << $trimmedcmds]]]]
  }
}
