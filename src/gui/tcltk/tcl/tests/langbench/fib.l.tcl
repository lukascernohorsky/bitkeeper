#!/usr/bin/env tclsh

proc fib n {
    if {$n < 2} {
        return $n
    }
    return [expr {[fib [expr {$n - 1}]] + [fib [expr {$n - 2}]]}]
}

for {set i 0} {$i <= 30} {incr i} {
    puts [format "n=%d => %d" $i [fib $i]]
}
