# ============================================================================#
# makefile for Joy without BDW gc
# ============================================================================#

PROGS_JOY = b_find j_main j_main_d
#SRC = b.scm  $(SRC)

#CC    =  gcc -g -ansi -pedantic -Wall -D_C_SOURCE=1
CC    =  gcc -Wall 

#---------------------------------------------------------------

all:  $(PROGS_JOY)

#---------------------------------------------------------------
b_find:	b_find.c
	gcc -O2 -Wall -g  -o $@ $^  -lm  

#---------------------------------------------------------------
J_OBJS  =  T/j_intr.o  T/j_scan.o T/j_util.o 

j_main:	j_main.c $(J_OBJS)
	$(CC) -o $@ $^  -lm  

T/j_intr.o: j_intr.c j_glob.h
	$(CC) -o $@ -c j_intr.c
T/j_scan.o: j_scan.c j_glob.h
	$(CC) -o $@ -c j_scan.c 
T/j_util.o: j_util.c j_glob.h
	$(CC) -o $@ -c j_util.c 
#---------------------------------------------------------------
D_OBJS  =  T/d_intr.o  T/d_scan.o T/d_util.o 

j_main_d: j_main.c $(D_OBJS)
	$(CC) -D_DEBUG -o $@ $^  -lm  

T/d_intr.o: j_intr.c j_glob.h
	$(CC) -D_DEBUG -o $@ -c j_intr.c
T/d_scan.o: j_scan.c j_glob.h
	$(CC) -D_DEBUG -o $@ -c j_scan.c 
T/d_util.o: j_util.c j_glob.h
	$(CC) -D_DEBUG -o $@ -c j_util.c 
#---------------------------------------------------------------

#---------------------------------------------------------------
clean:
	rm -f $(PROGS_JOY) T/*.o

# ============================================================================#
ARX_NAME = my-joy
save :  
	tar --ignore-failed-read -cvf $(ARX_NAME).tar *.c *.g .o *.h *.t *.cl *.tcl *.txt *.run *.joy *.sh ./E ./L Makefile* 
	gzip -6 $(ARX_NAME).tar  
	(cd ../../A/my-joy; mdat) 
#---------------------------------------------------------------
tcl_f8:
	l_gp.tcl

# ============================================================================#
