#!/usr/bin/env tclsh
proc fib {n} {
    expr {$n < 2 ? 1 : [fib [expr {$n -2}]] + [fib [expr {$n -1}]]}
}
for {set i 0} {$i <= 30} {incr i} {
    puts "n=$i => [fib $i]"
}
