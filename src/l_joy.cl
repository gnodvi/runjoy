;===============================================================================
;#!/.../b/cl
;
;===============================================================================
;; JOY interpreter

;(declare (special joystack joyprogram joytable))

;===============================================================================
(defun joy ()

  (declare (special joystack joyprogram joytable))

;------------------------------------------------------------
  (defun seq (prog stack)

    (defun exe (command stk)
        
      (defun s1 ()	(first stk))    ; 1-й элемент стека (он может быть и списком)
      (defun s2 ()	(second stk))   ; 2-й
      (defun s3 ()	(third stk))    ;
      (defun s4 ()	(fourth stk))   ;
      (defun s5 ()	(fifth stk))    ; 5-й

      (defun r0 ()	stk)            ; весь стек

      (defun r1 ()	(cdr stk))      ; остаток от 1-го элемента
      (defun r2 ()	(cddr stk))     ;
      (defun r3 ()	(cdddr stk))
      (defun r4 ()	(cddddr stk))
      (defun r5 ()	(cddddr (rest stk)))

      (defun i (st p)		(seq p st))
      (defun b (st p1 p2)	(seq p2 (seq p1 st)))

      ; list* - если последний элемент является списком, то к нему как бы добавляются в начало
      (defmacro POP0PUSH1 (v1)	(list 'list* v1 '(r0)))     ; добавляем     один новый 
      (defmacro POP1PUSH1 (v1)	(list 'list* v1 '(r1)))     ; заменяем 1 на один новый
      (defmacro POP2PUSH1 (v1)	(list 'list* v1 '(r2)))     ; заменяем 2 на один новый
      (defmacro POP3PUSH1 (v1)	(list 'list* v1 '(r3)))     ; заменяем 3 на один новый
      (defmacro POP0PUSH2 (v1 v2) (list 'list* v1 v2 '(r0))); добавляем      два новых
      (defmacro POP1PUSH2 (v1 v2) (list 'list* v1 v2 '(r1))); заменяем 1 на  два новых
      (defmacro POP2PUSH2 (v1 v2) (list 'list* v1 v2 '(r2))); заменяем 2 на  два новых
      (defmacro POP3PUSH2 (v1 v2) (list 'list* v1 v2 '(r3))); заменяем 3 на  два новых

      ;; begin exe
      (case command
        
        (id	(r0))
        (pop	(r1))
        (dup	(POP0PUSH1 (s1)))      ; удваиваем первый элемент
        (swap	(POP2PUSH2 (s2) (s1))) ;
        (stack	(POP0PUSH1 (r0)))      ;
        (unstack	(s1))
        (car	(POP1PUSH1 (car (s1))))
        (cdr	(POP1PUSH1 (cdr (s1))))
        (cons	(POP2PUSH1 (cons (s2) (s1))))       ; формируем пару из верхних элементов
        (uncons	(POP1PUSH2 (cdr (s1)) (car (s1))))  ; заменяем (разбиваем) пару на элементы
        (cnos	(POP2PUSH1 (cons (s1) (s2))))
        (uncnos	(POP1PUSH2 (car (s1)) (cdr (s1))))
        (duco	(POP1PUSH1 (cons (s1) (s1))))       ; дублируем один элемент в пару
        (fix	(POP1PUSH1 (list* (cons 'duco (s1)) 'duco (s1))))
        (unit	(POP1PUSH1 (list (s1))))
        (pair	(POP2PUSH1 (list (s2) (s1))))
        (unpair	(POP1PUSH2 (second (s1)) (first (s1))))
        (triple	(POP3PUSH1 (list (s3) (s2) (s1))))
        (untriple	(list* (caddar stk) (cadar stk) (caar stk) (r1)))
        
        (+	(POP2PUSH1 (+ (s2) (s1))))
        (-	(POP2PUSH1 (- (s2) (s1))))
        (*	(POP2PUSH1 (* (s2) (s1))))
        (/	(POP2PUSH1 (/ (s2) (s1))))
        (=	(POP2PUSH1 (= (s2) (s1))))
        (/=	(POP2PUSH1 (/= (s2) (s1))))
        (<	(POP2PUSH1 (< (s2) (s1))))
        (<=	(POP2PUSH1 (<= (s2) (s1))))
        (>	(POP2PUSH1 (> (s2) (s1))))
        (>=	(POP2PUSH1 (>= (s2) (s1))))
        (eq	(POP2PUSH1 (eq (s2) (s1))))
        (eql	(POP2PUSH1 (eql (s2) (s1))))
        (equal	(POP2PUSH1 (equal (s2) (s1))))
        ;; it ought to be possible to do this:
        ;;    ((< <= > >=)
        ;;      (POP2PUSH1 ('command (s2) (s1))))
        (put	(print (s1)) (r1))  ; печатаем первый элемент списка стека и возвращаем остальное
        (get	(POP0PUSH1 (read))) ; читаем с терминала и записываем в стек
        
        (i	(i (r1) (s1)))
        (b	(b (r2) (s2) (s1)))
        (k	(b (r1) (list 'pop) (s1)))
        (w	(b (r1) (list 'dup) (s1)))
        (c	(b (r1) (list 'swap) (s1)))
        (y	(b (r0) (list 'fix) (list 'i)))
        (dip	(list* (s2) (i (r2) (s1))))
        ;; this is no go:
        ;;      (nullary	(POP1PUSH1 (first (i (r1) (s1)))))
        ;; in the following the cddr's should be rN - but no go
        (nullary	(list*	(first (i (r1) (s1)))
                                (cdr stk)))
        (unary	(list*	(first (i (r1) (s1)))
			(cddr stk)))
        (binary	(list*	(first (i (r1) (s1)))
			(cdddr stk)))
        (ternary	(list*	(first (i (r1) (s1)))
                                (cddddr stk)))
        (nullary2	(list*	(first (i (cddr stk) (first stk)))
                                (first (i (cddr stk) (second stk)))
                                (cddr stk)))
        (unary2	(list*	(first (i (cddr stk) (first stk)))
			(first (i (cddr stk) (second stk)))
			(cdddr stk)))
        (binary2	(list*	(first (i (cddr stk) (first stk)))
                                (first (i (cddr stk) (second stk)))
                                (cddddr stk)))
        
        (infra	(list*	(i (s2) (s1))
			(cddr stk)))
        (build	(POP1PUSH1
                 (if (null (first stk))
                     nil
                   (cons
                    (first (i (cdr stk)
                              (caar stk)))
                    (first (i (cons (cdar stk) (cdr stk))
                              (list 'build))))) ))
        ;;      (mapcar	(list* (mapcar ?) (cddr stk)))
        ;;      (mapcar	(list* (apply ?) (cddr stk)))
        ;;      (mapcar	(list* (eval (cons 'mapcar (s1))) (cddr stk)))
        (map	(POP2PUSH1
                 (if (null (second stk))
                     nil
                   (cons
                    (first (i (cons (caadr stk) (cddr stk))
                              (car stk)))
                    (first (i (list* (car stk) (cdadr stk) (cddr stk))
                              (list 'map))))) ))
        (zip	(POP3PUSH1
                 (if (or (null (second stk)) (null (third stk)) )
                     nil
                   (cons (first (i (list* (caadr stk)
                                          (caaddr stk)
                                          (cdddr stk) )
                                   (car stk)) )
                         (first (i (list* (car stk)
                                          (cdadr stk)
                                          (cdaddr stk)
                                          (cdddr stk) )
                                   (list 'zip))))) ))
        (step	(if (null (second stk))
                    nil
		  (progn
		    (i (cons (caadr stk) (cddr stk))
		       (car stk))
		    (i (list* (car stk) (cdadr stk) (cddr stk))
		       (list 'step)) ))
		(cddr stk))
        (eval	(eval (s1))  (r1))	; execute in lisp
        
        (lookup	(POP1PUSH1 (gethash (s1) joytable)))  ; заменить элемент значением из таблицы
        
        ;; DEFINITIONS:     (new == old1 old2 ..) enter
        ;; there is no check for == yet 
                                        ; ввести в таблицу новое определение и вернуть остаток стека
                                        ;                                              | пропускаем "=="
        (enter	(setf (gethash (car (s1)) joytable) (cddr (s1)))  (r1))
        
                                        ; если ничего из перечисленного не обнаружено, то :
        (t  (typecase command
              (symbol (i stk (gethash command joytable))) ; ищем в таблице и выполняем 
              (t		(POP0PUSH1 command)) ) )        ; запихиваем список в стек
        ) 
      )
;----------------------------------------------------------------
    ;; end exe
;----------------------------------------------------------------
    
    ;; begin seq
    ; выполняем последовательность команд (prog) над стеком
    (cond
     ((eq prog nil) stack)
     (t (seq (cdr prog) (exe (car prog) stack))))
    ; т.е. с помощью первой команды меняем стек, затем исполняем 
    ; оставшуюся последовательность

;----------------------------------------------------------------
  )  ;; end seq
;----------------------------------------------------------------
    
;-------------------------------------------------------------------------------
  ;; begin joy
;-------------------------------------------------------------------------------
  (setf joystack 'nil)
  (setf joytable (make-hash-table :test #'equal))
  
  (terpri)  ; outputs a newline to output-stream (default is standard output)
  
  (defun run-loop  ()
    (write-string "JOY in LISP    if it doesn't work, (load 'joy) a second time")
    (loop
      (terpri) 
      (write-string "j: ")
      (setf joyprogram (read)) ; читаем входную команду
      (if (eql joyprogram 'stop) (return '(JOY STOPPED)))
      ; непосредственно меняем стек, выполняя последоввательность команд
      (setf joystack (seq joyprogram joystack))
    ) 
  )
  
;-----------------------------------------------------
; можно попробовать выполнять непосредственно команды:
  (defun run-joy-cmd  (joy-cmd)
    (setf joystack (seq joy-cmd joystack)))

  (defun run-tests  ()
    (run-joy-cmd '(100   id   put)) ;(setf joystack 'nil)
    (run-joy-cmd '(101   pop  put))
    (run-joy-cmd '(102   dup  put put))
    (run-joy-cmd '("test103" 103  swap put))
    (run-joy-cmd '("test104" 104  stack put))
    (run-joy-cmd '((1051 1052) unstack stack put))
    (run-joy-cmd '((1061 1062) car  put))
    (run-joy-cmd '((1061 1062) cdr  put))
    (run-joy-cmd '(1071 1072 cons  put))
    (run-joy-cmd '(1071 1072 cnos  put))
    (run-joy-cmd '((1081 1082) uncons  put))
    (run-joy-cmd '((1081 1082) uncnos  put))
    (run-joy-cmd '(109 duco  put))
    (run-joy-cmd '(110 fix   put)) ; ??
    (run-joy-cmd '(111 unit  put))     ; группируем один элемент в список
    (run-joy-cmd '(111 112 pair  put)) ; группируем два элемента в список
    (run-joy-cmd '((1 2 3) (4 5 6 7) pair put))
    (run-joy-cmd '((111 112) unpair  put)) ;
    (run-joy-cmd '(111 112 113 triple  put)) ; группируем три элемента в список
    (run-joy-cmd '((111 112 113) untriple  put)) ;
    
    (terpri) 
    (run-joy-cmd '(2 3 + put) )
    (run-joy-cmd '(2 3 + dup * put) )
    (run-joy-cmd '((1 2 3 4)  (dup *)  map put))
    
    (terpri) 
    (run-joy-cmd '((plus == +) enter)) ; задать новую команду
    (run-joy-cmd '(2 3 plus put) )
    (run-joy-cmd '((print "222") eval) )
    (run-joy-cmd '((print joystack) eval) )
    (run-joy-cmd '((print joytable) eval) )
    
    (terpri) 
    
    (terpri) 
    (format t "~%")
  )
;-----------------------------------------------------
  
  (run-tests)
  ;(run-loop)
  
;-------------------------------------------------------------------------------
) ;; end joy ()
;-------------------------------------------------------------------------------

;(compile 'joy)

(joy)

;(let ((a1 (first ext:*args*)))
;(cond 
;  ((equal a1 "1") (format t "111111 ~%"))
;  (t              (print a1))
;))
;===============================================================================

