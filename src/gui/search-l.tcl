#!/usr/bin/env tclsh
# Tcl shim for search.l
# Delegates to the existing Tcl implementation used by the GUI tools.

source [file join [file dirname [info script]] search.tcl]
