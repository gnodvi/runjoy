#!/bin/sh
#
####################################################################### --------
#
source ./E/lib.sh

echo ""

run_tests J1 ./E/OUT .
echo ""
run_tests J2 ./E/OUT ./L
echo ""
run_tests J3 ./E/OUT ./L
echo ""
run_tests J4 ./E/OUT ./L

echo ""
#-------------------------------------------------------------------------------



