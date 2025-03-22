source [file join [file dirname [info script]] .. jimtcl tcltest.tcl]

needs constraint jim
# set ::debug(here) to a unique value (numeric or string, etc.) anywhere
# in your script where you need to be able to break based on a break
# condition.
set ::debug(here) {}
# invoke the jdb.tcl debugger on tclscript and pass a string containing
# debugger commdands to it. The debugger command string is trimmed to remove
# whitespace from the start and end overall, and also from the start and
# end of each line.
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
