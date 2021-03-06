################################################################################
# 
#   � � � � � � � � � � �   � � � � � � (���� Joy)
# 
################################################################################
  

# ������, ����������� ���������� [make_instr] 
set ::instructions {}

#-------------------------------------------------------------------------------
# ���������� ����� ���������� ��� ��
#-------------------------------------------------------------------------------
proc make_instr {name arglist body} {
    lappend ::instructions $name   ;# �������� ��� � ������ ����������
    proc $name $arglist $body      ;# ������� ��������� (���������� Tcl) 
}
#-------------------------------------------------------------------------------
# ����������� ��������� �� ��� ���������� ����� ���������
#-------------------------------------------------------------------------------
proc init stackval {
    set ::stack $stackval  ;# The VM stack
    set ::ip -1            ;# The VM istruction pointer
}
#-------------------------------------------------------------------------------
# �������� � ���� ��
#-------------------------------------------------------------------------------
proc push element {
    lappend ::stack $element
}
#-------------------------------------------------------------------------------
# ������� �� ����� 
#-------------------------------------------------------------------------------
proc pop {} {
    set element [lindex $::stack end]
    set ::stack [lrange [lindex [list $::stack [unset ::stack]] 0] 0 end-1]
    return $element
}
#-------------------------------------------------------------------------------
# ��������� ��� ���� ������ �� ������� ���� 'n', ����� 
# ��������� ��������� ��������� "���������"
#-------------------------------------------------------------------------------
proc needlen n {
    if {[llength $::stack] < $n} {
 	return -code return
    }
}
#-------------------------------------------------------------------------------


################################################################################
# 
#   � �   � � � � � � � � � �
# 
################################################################################


#-------------------------------------------------------------------------------
make_instr + {} {
     needlen 2
     push [expr {[pop]+[pop]}]
}
#---------------------------------------
make_instr - {} {
     needlen 2
     push [expr {[pop]-[pop]}]
}
#---------------------------------------
make_instr * {} {
     needlen 2
     push [expr {[pop]*[pop]}]
}
#---------------------------------------
proc divmod op {
     needlen 2
     set a [pop]
     set b [pop]
     if {!$b} {
 	push $b
 	push $a
 	return
     }
     push [expr "$a $op $b"]
}

make_instr   / {} {divmod /}
make_instr mod {} {divmod %}

#---------------------------------------
make_instr dup {} {
    needlen 1
    set a [pop]
    push $a
    push $a
}
#---------------------------------------
make_instr dup2 {} {
    needlen 2
    set a [pop]
    set b [pop]
    push $b
    push $a
    push $b
    push $a
}
#---------------------------------------
make_instr swap {} {
    needlen 2
    set a [pop]
    set b [pop]
    push $a
    push $b
}
#---------------------------------------
make_instr drop {} {
    needlen 1
    pop
}
#---------------------------------------
make_instr rot {} {
    needlen 3
    set c [pop]
    set b [pop]
    set a [pop]
    push $c
    push $a
    push $b
}
#---------------------------------------
make_instr peek {} {
    needlen 2
    push [lindex $::stack end-1]
}
#---------------------------------------
make_instr > {} {
    needlen 2
    push [expr {[pop]>[pop]}]
}
#---------------------------------------
make_instr < {} {
     needlen 2
     push [expr {[pop]<[pop]}]
}
#---------------------------------------
make_instr == {} {
     needlen 2
     push [expr {[pop]==[pop]}]
}
#---------------------------------------
make_instr jz {{n {-10 10}}} {
     needlen 1
     if {[pop] == 0} {
 	incr ::ip $n
 	if {$::ip < -1} {
 	    set ::ip -1
 	}
     }
}
#---------------------------------------
make_instr jnz {{n {-10 10}}} {
    needlen 1
    if {[pop] != 0} {
 	incr ::ip $n
 	if {$::ip < -1} {
 	    set ::ip -1
 	}
    }
}
#---------------------------------------
# Nop istruction is important to kill some istruction by mutation.
make_instr nop {} {

}
#---------------------------------------
# Return if zero
make_instr retz {} {
     needlen 1
    if {[pop] == 0} {
 	set ::ip 100000
    }
}
#---------------------------------------
# Return if nonzero
make_instr retnz {} {
    needlen 1
    if {[pop] != 0} {
 	set ::ip 100000
    }
}
#---------------------------------------
# Reiterate the program if zero
make_instr againifz {} {
    needlen 1
    if {[pop] == 0} {
 	set ::ip -1
    }
}
#---------------------------------------
# non-zero version
make_instr againifnz {} {
    needlen 1
    if {[pop] != 0} {
 	set ::ip -1
    }
}
#---------------------------------------
# Not
make_instr not {} {
    needlen 1
    push [expr {![pop]}]
}
#---------------------------------------
make_instr const {{n {-10 10}}} {
    push $n
}
#-------------------------------------------------------------------------------


################################################################################
# 
#  � � � � � � � � � �   � � � � � � � �
#
################################################################################


#-------------------------------------------------------------------------------
# prg      - ����������� ���������
# stack    - ��������� ���� (�����������)
# maxinstr - 

proc run {prg stack {maxinstr 100}} { 
    init $stack      ;# ������ ��������� ���� � ��������� (-1) 
    set instrcount 0 ;# ������� ��� ����������� ���-�� ������� ��������

    while 1 {
 	incr ::ip                     ;# �������� ���������
 	set instr [lindex $prg $::ip] ;# ����� �� ���� ����������
        
 	if {$instr eq {}} break
        
 	if {[llength $instr] == 1} {  ;# ���� ��� ��������� ����������
 	    $instr                    ;# �� ��������� ��
 	} else {                      ;# ���� �� ��� ������ (���� ?)
 	    [lindex $instr 0] [lindex $instr 1] ;# �� ��������� �� � ����������?
 	}

 	incr instrcount
 	if {$instrcount > $maxinstr} break
    }

    return $::stack
}
#-------------------------------------------------------------------------------
################################################################################
