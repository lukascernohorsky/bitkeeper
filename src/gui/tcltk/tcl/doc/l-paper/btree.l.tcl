#!/usr/bin/env tclsh

# Tcl port of the Little binary tree sample.

proc insert {treeVar node value} {
    upvar 1 $treeVar tree
    if {![info exists tree($node)]} {
        set tree($node) $value
    } elseif {$value < $tree($node)} {
        insert tree [expr {$node * 2 + 1}] $value
    } else {
        insert tree [expr {$node * 2 + 2}] $value
    }
}

proc printTree {treeVar node} {
    upvar 1 $treeVar tree
    if {![info exists tree($node)]} {
        return
    }
    printTree tree [expr {$node * 2 + 1}]
    puts $tree($node)
    printTree tree [expr {$node * 2 + 2}]
}

proc main {argv} {
    array set tree {}
    for {set i 0} {$i < 100} {incr i} {
        insert tree 0 [expr {int(rand() * 100)}]
    }
    printTree tree 0
    return 0
}

if {![info exists ::tcl_interactive] || !$::tcl_interactive} {
    set code [catch {main $argv} result]
    if {$code} {
        if {[string length $result]} {puts stderr $result}
        exit 1
    }
    exit $result
}
