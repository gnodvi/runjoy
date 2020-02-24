#!/bin/sh
# the next line restarts using tclsh\
exec tclsh "$0" "$@"
#===============================================================================

source "t_g1.tcl";   # стековая машина типа Joy
source "t_g2.tcl";   # эволюционный движок

#-------------------------------------------------------------------------------
# Типичный пример. Выявлем (раскручиваем) программу, вычисляющую квадрат числа.
# Лучшая програма :  "DUP *"
# Лучший фитнес == 2 (нет ошибок для любых входов, длина проги == 2).
#-------------------------------------------------------------------------------
proc squareFitness prg {
    set fitness 0

    foreach i {1 2 3 4 5} o {1 4 9 16 25} {
 	set stack [run $prg $i]
 	set result [lindex $stack end]
 	
        if {$result eq {}}  {
 	    incr fitness 50
 	} else {
 	    set delta [expr {abs($o-$result)}]
 	    if {$delta > 1000} {
 		# anti overflow
 		set delta 1000
 	    }
 	    incr fitness $delta
 	}
    }
    
    return [expr {$fitness+[llength $prg]}]
}
#===============================================================================
proc test_01 {argv argc} {
    puts "-------------------------------------------"

    # Tcl script to echo command line arguments
    #puts "Program: $argv0"
    puts "Number of arguments: $argc"
    set i 0
    foreach arg $argv {
        puts "Arg $i: $arg"
        incr i
    }

    #---------------------------------
#     for { set i 0 } { $i < $argc } { incr i } {
#         set option [lindex $argv $i]
        
#         switch -glob -- $option {
#             "A" {
#                 puts "AAA"
#                 continue
#             }
#             "-*" {
#                 set option "-$option"
#             }   
#             default {
#                 puts "default"
#             }
#         }
#     }

    puts "-------------------------------------------"
    return   
}
#===============================================================================

if {$argc == 0}  {
    set mode 0
} else {
    set mode [lindex $argv 0] ;# argv - здесь нет имени программы?!
    #puts $mode
}


if {$mode == 0} { 
    expr {srand (1020)}
    evolve 90 5 squareFitness 0.1
}
if {$mode == 1} { 
    test_01 $argv $argc
}

#===============================================================================
