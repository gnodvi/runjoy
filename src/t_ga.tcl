#!/bin/sh
# the next line restarts using tclsh\
exec tclsh "$0" "$@"
#-------------------------------------------------------------------------------

# Drawbacks of this implementation:

#* The interface needs improvements (no way to examine the population)
#* The fitness function has to take care of scaling the input parameters from "GA-typical" data  
#  (32-bits integers) to real-world values (in the test case: floating-point numbers between 0 and 1)
#* A few items were left out (quadratic weighing for instance)
#* A few uncertainties with regard to the range of the generated integers (does the sign-bit get 
#  set? What if we have a 1s-complement machine?)

# TS Converting the hardcoded constants using int2bits from Binary representation of numbers on 
# my Pentium4/WinXP/Tcl8.4a4 led to - at least for me - surprising results

#  % int2bits -2147483647 32 (should be all bits set)
#  0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0

#  % int2bits 2147483000 32 (used for chromosome initialisation)
#  0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0 1 0 1 1 1 1 0 0 0

# Lars H: Which int2bits are you talking about here? There are oodles of them on that page, 
# and several of them assume non-negative input (e.g. have main loops
# while {$i>0} {
# ). Also, it is in 32-bit 1's complement notation that -2147483647 has all bits set. Tcl bit 
# operations work with 2's complement notation, in which it is always -1 that has all bits set.

#-------------------------------------------------------------------------------
# genetic_alg.tcl --
#
#    Package for implementing simple genetic algorithms
#    (Tcl-only version)
#
# Notes:
#    This package is shamelessly modelled after a publically
#    available program by Scott Robert Ladd (http://www.coyotegulch.com)
#
# Version information:
#    version 0.1: initial implementation, february 2002

package provide GeneticAlgorithms 0.1

#-------------------------------------------------------------------------------
#namespace eval ::GeneticAlgorithms {
#-------------------------------------------------------------------------------

variable crossover  0.5
variable mutation   0.1
variable elitism    1
variable quadweight 0

variable best_guess {}
variable population {}
variable child_pop  {}

namespace export setting optimise optimiseStep

#-------------------------------------------------------------------------------
# limitvalue
#    Limit the argument between two bounds
#
# Arguments:
#    value    New value (if not present, return current value)
#    minimum  Minimum bound
#    maximum  Maximum bound
#
# Result:
#    Value or one of the bounds
#
#-------------------------------------------------------------------------------
proc limitvalue {value minimum maximum} {
    if { $value < $minimum } {
        return $minimum
    }
    if { $value > $maximum } {
        return $maximum
    }
    return $value
}
#-------------------------------------------------------------------------------
# setting
#    Set/get the settings
#
# Arguments:
#    name     Name of a variable to set or get
#    value    New value (if not present, return current value)
#
# Result:
#    New value for given variable
#
# Side effects:
#    Sets given variable to new value
#
#-------------------------------------------------------------------------------
proc setting {name {value NONE} } {
    variable $name
    if { $value != "NONE" } {
        switch -- $name {
            "crossover"  { set $name [limitvalue $value 0.0 1.0] }
            "mutation"   { set $name [limitvalue $value 0.0 1.0] }
            "elitism"    { set $name [expr $value!=0] }
            "quadweight" { set $name [expr $value!=0] }

            default      { error "setting: unknown parameter $name" }
        }
        set $name
    }
}
#-------------------------------------------------------------------------------
# optimise --
#    Optimise the given function using a genetic algorithm
#
# Arguments:
#    pop_size   Size of the population
#    max_gen    Maximum number of generations
#    no_genes   Number of "genes" - degrees of freedoms
#    fitness    Function of the degrees of freedom, returns the fitness
#               of the solution (as a non-negative number!)
#
# Result:
#    Best guess of degrees of freedom, as a list
#
#-------------------------------------------------------------------------------
proc optimise { pop_size max_gen no_genes fitness } {
    variable best_guess
    
    optimiseInit $pop_size $no_genes
    
    for { set i 0 } { $i < $max_gen } { incr i } {
        optimiseStep $pop_size $no_genes $fitness
        puts "$best_guess - [$fitness $best_guess]"
    }
    
    return $best_guess
}
#-------------------------------------------------------------------------------
# optimiseInit --
#    Initialise the population
#
# Arguments:
#    pop_size   Size of the population
#    no_genes   Number of "genes" - degrees of freedoms
#
# Result:
#    None
#
# Side effects:
#    Initialised list variable population
#
#-------------------------------------------------------------------------------
proc optimiseInit { pop_size no_genes } {
    variable population
    variable child_pop
    
    set population {}
    
    for { set i 0 } { $i < $pop_size } { incr i } {
        set member {}
        for { set j 0 } { $j < $no_genes } { incr j } {
            lappend member [expr {int(2147483000.0*rand())}]
        }
        lappend population $member
    }
    
    set child_pop $population
}
#-------------------------------------------------------------------------------
# optimiseStep --
#    Perform a single step in the optimisation
#
# Arguments:
#    pop_size   Size of the population
#    no_genes   Number of "genes" - degrees of freedoms
#    fitness    Function for determining the fitness
#
# Result:
#    None
#
# Side effects:
#    New population, best_guess set
#
#-------------------------------------------------------------------------------
proc optimiseStep { pop_size no_genes fitness } {
    variable population
    variable child_pop
    variable best_guess
    variable mutation
    variable crossover
    variable quadweight
    variable elitism
    
    #
    # Copy the child population
    #
    set population $child_pop
    
    #
    # Determine the fitness per member
    #
    set high_fit -1
    set tot_fit   0.0
    set pop_fit  {}
    foreach member $population {
        set fit [eval $fitness $member]
        if { $high_fit < $fit } {
            set high_fit $fit
            set best_guess $member
        }
        
        lappend pop_fit $fit
        set tot_fit [expr {$tot_fit+$fit}]
    }
    
    #
    # Scale the fitness (quadratic weight)
    #
    # PM
    
    #
    # Elitism: keep the best in any case
    #
    set child_pop {}
    set no_child  $pop_size
    if { $elitism } {
        lappend child_pop $best_guess
        incr no_child -1
    }
    
    #
    # Breed the children
    #
    for { set i 0 } { $i < $no_child } { incr i } {
        set selection [expr {$tot_fit*rand()}]
        set father     0
        set father_fit [lindex $pop_fit $father]
        while { $selection > $father_fit } {
            set selection [expr {$selection-$father_fit}]
            incr father
            set father_fit [lindex $pop_fit $father]
        }
        
        set selection [expr {$tot_fit*rand()}]
        set mother     0
        set mother_fit [lindex $pop_fit $mother]
        while { $selection > $mother_fit } {
            set selection [expr {$selection-$mother_fit}]
            incr mother
            set mother_fit [lindex $pop_fit $mother]
        }
        
        set child [combineGenes [lindex $population $mother] \
                       [lindex $population $father] ]
        set child [mutateGenes $child]
        lappend child_pop $child
    }
    
    #puts $population
    #puts $pop_fit
}
#-------------------------------------------------------------------------------
# combineGenes --
#    Combine the genes of the two parents (using cross-over)
#
# Arguments:
#    mother     Genes of the first parent
#    father     Genes of the second parent
#
# Result:
#    Genes of the child
#
#-------------------------------------------------------------------------------
proc combineGenes { mother father } {
    variable crossover
    
    set all_bits_set -2147483647
    
    set child {}
    foreach first $mother second $father {
        set bit_no  [expr int(32.0*rand())]
        set bitmask [expr {($all_bits_set>>$bit_no)<<$bit_no}]
        set newgene [expr {$first&$bitmask|$second&~$bitmask}]
        
        lappend child $newgene
    }
    
    return $child
}
#-------------------------------------------------------------------------------
# mutateGenes --
#    Mutate the genes of a child (flip a bit)
#
# Arguments:
#     child      Genes of the child to be mutated
#
# Result:
#    Mutated genes
#
#-------------------------------------------------------------------------------
proc mutateGenes { child } {
    variable mutation
    
    set newgenes {}
    foreach gene $child {
        if { [expr {rand()}] < $mutation } {
            set bit_no  [expr {int(32.0*rand())}]
            set bitmask [expr {1<<$bit_no}]
            set bitset  [expr {($gene&$bitmask) != 0}]
            if { $bitset } {
                set newgene [expr {$gene&~$bitmask}]
            } else {
                set newgene [expr {$gene|$bitmask}]
            }
        } else {
            set newgene $gene
        }
        
        lappend newgenes $newgene
    }
    
    return $newgenes
}
#-------------------------------------------------------------------------------
#  } ;# End of namespace
#-------------------------------------------------------------------------------

#namespace import ::GeneticAlgorithms::*

proc testFunc { var } {
    #puts $var
    #expr {1.0-abs($var/2147483647.0-0.5)}
    expr {$var * $var}
}

expr {srand (2010)}
# puts ""
# puts [expr {rand()}] 
# puts ""

# puts [::GeneticAlgorithms::optimise 100 40 1 testFunc]
puts [optimise 100 40 1 testFunc]


#-------------------------------------------------------------------------------
