#!/bin/sh
#
################################################################################

# подцепить библиотеку "тестовых" утилит
source ./lib.sh

echo ""

#===============================================================================
# перейти в корневую директорию для выполнения заданий
cd ..

#tst A E/OUT . "joy.cl" 
#tst A E/OUT . "l_ga.tcl"
tst A E/OUT . "l_gp.tcl"

# tst A E/OUT . "j_find" 

# tst A E/OUT . "j_main j_00.joy" 
# tst A E/OUT . "j_main j_01.joy" 
# tst A E/OUT . "j_main j_02.joy" 


#===============================================================================
# перейти в НУЖНУЮ директорию для выполнения заданий
# cd ../L

# tst B E/OUT . "j_main grmtst.joy" 
# tst B E/OUT . "j_main jp-joytst.joy" 
# tst B E/OUT . "j_main laztst.joy" 
# tst B E/OUT . "j_main modtst.joy" 
# tst B E/OUT . "j_main mtrtst.joy" 
# tst B E/OUT . "j_main plgtst.joy" 
# tst B E/OUT . "j_main symtst.joy" 

#---------------------------------------
# тесты с ошибками
#---------------------------------------
#tst B E/OUT . "j_main lsptst.joy"
#tst B E/OUT . "j_main joytut.inp"
#---------------------------------------

#tst C E/OUT . "j_main jp-church.joy" 
#tst C E/OUT . "j_main jp-nestrec.joy" 


#===============================================================================
echo ""
#===============================================================================

