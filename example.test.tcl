#! ./jimsh
# This is part of an actual jdb.tcl test file using "testing.tcl" and "jdb.tcl" 
# and JimTcl's "tcltest.tcl". The script file (b3k.tcl) which is the target of 
# these tests is not included in this repository.

source [file join [file dirname [info script]] testing.tcl]
constraint cmd puts
set script ./b3k.tcl

test b3k-001.001 {startup test mimetype} -body {
  debug $script {
    # set breakcondition (A) at first call of "foreach"
    bc {$::debug(tclcmd) eq "foreach"}
    c
    # breakcondition (A)
    _puts <dbg>$::w4(.mimetype)</dbg>
    _exit
  }
} -result {text/html; charset=utf-8}

test b3k-001.002 {startup test -mxage valid input} -body {
  debug "$script -max-age 1024" {
    bc {$::debug(tclcmd) eq "w4-start"}
    c
    bc {[_exists ::w4]}
    c
    _set ::debug(breakconditions) {}
    bc {$::w4(mxage) ne 120}
    c
    _puts <dbg>$::w4(mxage)</dbg>
    _exit
  }
} -result {1024}

test b3k-001.003 {startup test -mxage invalid input} -body {
  debug "$script -max-age xxx" {
    bc {$::debug(tclcmd) eq "puts"}
    c
    _puts <dbg>$::w4(mxage),$val</dbg>
    _exit
  }
} -result {120,xxx}

test b3k-001.004 {startup test -sa "yes" input} -body {
  debug "$script -sa yes" {
    bc {[_exists ::w4] && $::w4(sa) ne 0}
    c
    _puts <dbg>$::w4(sa)</dbg>
    _exit
  }
} -result {1}

test b3k-001.005 {startup test -sa "no" input} -body {
  debug "$script -sa no" {
    bc {[_exists ::w4]}
    c
    _set ::w4(sa) 4
    _set ::debug(breakconditions) {}
    bc {$::w4(sa) ne 4}
    c
    _puts <dbg>$::w4(sa)</dbg>
    _exit
  }
} -result {0}

test b3k-002.001 {setpeername test for REMOTE_ADDR and REMOTE_PORT} -body {
  debug $script {
    # set breakpoint (A) in proc setpeername (once server running)
    b proc:setpeername:1
    # set breakcondition (B) at "puts" prior to "vwait" starting server
    bc {$::debug(tclcmd) eq "puts"}
    c
    # breakcondition (B): action: start client
    _exec curl 127.0.0.1:8080 &
    c
    # breakpoint (A): set breakcondition (C) when ::w4(REMOTE_PORT) is set
    bc {$::w4(REMOTE_PORT) ne {}}
    c
    # breakcondition (C): print dbg values and exit
    _puts <dbg>$::w4(REMOTE_ADDR):$::w4(REMOTE_PORT)</dbg>
    _exit
  }
} -match regexp -result {^127.0.0.1:[0-9]+$}

test b3k-004.001 {parse-hdr REQUEST_METHOD and REQUEST_URI test} -body {
  debug $script {
    # set breakpoint (A) (once server running)
    b proc:parse-hdr:1
    # set breakcondition (B) at "puts" prior to "vwait" starting server
    bc {$::debug(tclcmd) eq "puts"}
    c
    # breakcondition (B): action: start client
    _exec curl 127.0.0.1:8080 &
    c
    # breakpoint (A)
    bc {[_exists ::w4(QUERY_STRING)]}
    c
    # breakcondition (C): print dbg values and exit
    _puts <dbg>$::w4(REQUEST_METHOD),$::w4(REQUEST_URI)</dbg>
    _exit
  }
} -match regexp -result {GET,/}

test b3k-004.002 {parse-hdr overall test} -body {
  debug $script {
    # set breakpoint (A) (once server running)
    b proc:parse-hdr:1
    # set breakcondition (B) at "puts" prior to "vwait" starting server
    bc {$::debug(tclcmd) eq "puts"}
    c
    # breakcondition (B): action: start client
    _exec curl 127.0.0.1:8080 &
    c
    # breakpoint (A)
    bc {$::debug(tclcmd) eq "return"}
    c
    # breakcondition (C): print dbg values and exit
    _puts <dbg>$::w4</dbg>
    _exit
  }
} -match regexp -result {authdb \{\} bandir \{\} bantime [0-9]+ mxage [0-9]+ mxcontent [0-9]+ mxhdr [0-9]+ sa 0 SERVER_NAME 127.0.0.1 SERVER_PORT 8080 SERVER_PROTOCOL http:// SERVER_SOFTWARE b2k .bytegot [0-9]+ .bytesent 0 .csp \{default-src 'self'\} .hdr:AUTH \{\} .mimetype \{text/html; charset=utf-8\} .reply \{\} .reply-code \{200 Ok\} .closeConn 0 DOCUMENT_ROOT \{\} GATEWAY_INTERFACE CGI/1.0 HTTP_HOST 127.0.0.1:8080 _HTTP_HOST \{\} REMOTE_ADDR 127.0.0.1 REMOTE_PORT [0-9]+ REQUEST_URI / SAME_ORIGIN 0 SCRIPT_FILENAME .*/b3k.tcl SERVER_ROOT .*/b3k.tcl cgiparam \{ACCEPT HTTP_ACCEPT ACCEPT-ENCODING HTTP_ACCEPT_ENCODING AUTHORIZATION .hdr:AUTH CONNECTION .hdr:CONN CONTENT-LENGTH CONTENT_LENGTH CONTENT-TYPE CONTENT_TYPE COOKIE HTTP_COOKIE HOST HTTP_HOST IF-MODIFIED-SINCE HTTP_IF_MODIFIED_SINCE IF-NONE-MATCH HTTP_IF_NONE_MATCH RANGE .hdr:RANGE REFERER HTTP_REFERER USER-AGENT HTTP_USER_AGENT\} hacks \{/../ /./ _SELECT_ _select_ _sleep_ _OR_ _AND_ /etc/passwd /bin/sh /.git/ /swagger.yaml /phpThumb.php /.htpasswd /.passwd /tomcat/manager/status/ /WEB-INF/jboss-web.xml /phpMyAdmin/setup/index.php /examples/feed-viewer/feed-proxy.php\} mimetypes \{.htm text/html .html text/html .webp image/webp\} nrequests 0 sock ::aio.sock[0-9]+ sourced \{\} uagent \{Amazonbot \{Windows 9\} \{Download Master\} Ezooms/ DotBot HTTrace AhrefsBot MicroMessenger \{OPPO A33 Build\} SemrushBot MegaIndex.ru MJ12bot Chrome/0.A.B.C Neevabot/ BLEXBot/ Synapse\} chan ::aio.sockstream[0-9]+ REQUEST_METHOD GET PATH_INFO / QUERY_STRING \{\} HTTP_USER_AGENT curl/.* HTTP_ACCEPT \*/\*}

test b3k-004.003 {parse-hdr PATH_INFO, REQUEST_URI, QUERY_STRING test} -body {
  debug $script {
    # set breakpoint (A) (once server running)
    b proc:parse-hdr:1
    # set breakcondition (B) at "puts" prior to "vwait" starting server
    bc {$::debug(tclcmd) eq "puts"}
    c
    # breakcondition (B): action: start client
    _exec curl 127.0.0.1:8080/go/to/path?name=geoff &
    c
    # breakpoint (A)
    bc {$::debug(tclcmd) eq "return"}
    c
    # breakcondition (C): print dbg values and exit
    _puts <dbg>$::w4(PATH_INFO),$::w4(REQUEST_URI),$::w4(QUERY_STRING)</dbg>
    _exit
  }
} -match exact -result {/go/to/path,/go/to/path?name=geoff,name=geoff}

testreport
