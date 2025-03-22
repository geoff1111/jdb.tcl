source [file join [file dirname [info script]] .. jimtcl tcltest.tcl]
# the above needs to source the JimTcl version of tcltest.tcl
# Copyright (c) Geoffrey P. Messer 2025.

needs constraint jim

proc debug {tclscript debuggercmds} {
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
         [exec ./jdb.tcl - {*}$tclscript << $trimmedcmds]]]]
}
