(define lambda fn)
(defMacro (dprint . exprs)
  (let (
        (firstLine (print "========="))
        (firstLine
          (map (lambda (x)
                (cond
                  ((string? x) (print x))
                  (else (print x ": " (eval x)))))
            exprs)))
    (print "=========")))
(def not
  (fn (x)
    (cond
      (x false)
      (true true))))

(defMacro
  (if pred consequent alternate)
  (cond
    ((eval pred) (eval consequent))
    (else (eval alternate))))
(define (append list1 list2)
  (if
    (null? list1)
    list2
    (cons (car list1) (append (cdr list1) list2))))

(define nil '())
(def null?
  (fn (x)
    (cond
      ((eq x nil) true)
      (true false))))

(define lambda fn)
(define (map proc items)
  (cond
    ((null? items) nil)
    (else
      (cons (proc (car items))
        (map proc (cdr items))))))
(define (accumulate op initial sequence)
  (if (null? sequence)
    initial
    (op (car sequence)
      (accumulate op initial (cdr sequence)))))
(define (map-n op . seqs)
  (define (c-args seqs)
    (cond
      ((null? (car seqs)) '())
      ((pair? seqs) (append
                     (list (map car seqs))
                     (c-args
                       (map cdr seqs))))))
  (accumulate
    (lambda (args acc)
      (cons (eval (cons op args)) acc))
    '()
    (c-args seqs)))

(define (map proc items)
  (cond
    ((null? items) nil)
    (else
      (cons (proc (car items))
        (map proc (cdr items))))))

(define (newline) (print ""))
(define display print)

(define (filter predicate sequence)
  (cond ((null? sequence) nil)
    ((predicate (car sequence))
      (cons (car sequence)
        (filter predicate (cdr sequence))))
    (else (filter predicate (cdr sequence)))))

(define = eq)

(defMacro (assert a b)
  (let ((aEvaled (eval a))
        (bEvaled (eval b)))
    (cond
      ((= aEvaled bEvaled)
        null)
      (else
        (print "assertion failed, found: " aEvaled ", but expected: " bEvaled " (" a " != " b ")")))))

(defMacro (apply fn seq)
  (eval (cons (eval fn) (eval seq))))

(assert (apply + (list 1 5)) 6)

(define (reverse x)
  (def reverse-iter
    (fn (x acc)
      (cond
        ((null? x) acc)
        (true (reverse-iter (cdr x) (cons (car x) acc))))))
  (reverse-iter x '()))

(define (accumulate op initial sequence)
  (if (null? sequence)
    initial
    (op (car sequence)
      (accumulate op initial (cdr sequence)))))

(define (enumerate-interval low high)
  (if (> low high)
    nil
    (cons low (enumerate-interval (+ low 1) high))))

(define (enumerate-tree tree)
  (cond ((null? tree) nil)
    ((not (pair? tree)) (list tree))
    (else (append (enumerate-tree (car tree))
           (enumerate-tree (cdr tree))))))

(define (length sequence)
  (accumulate (lambda (skip x) (+ 1 x)) 0 sequence))

(define (someOp x) x)
(define (lambdaUsingOp someOp y) (someOp y))
(define
  (otherLambdaWithOp someOp i j)
  (lambdaUsingOp
    (fn (x) x)
    (someOp i j)))

(define lambda fn)
(define (map proc items)
  (cond
    ((null? items) nil)
    (else
      (cons (proc (car items))
        (map proc (cdr items))))))
(define (accumulate op initial sequence)
  (if (null? sequence)
    initial
    (op (car sequence)
      (accumulate op initial (cdr sequence)))))
(define (map-n op . seqs)
  (define (c-args seqs)
    (cond
      ((null? (car seqs)) '())
      ((pair? seqs) (append
                     (list (map car seqs))
                     (c-args
                       (map cdr seqs))))))
  (accumulate
    (lambda (args acc)
      (cons (eval (cons op args)) acc))
    '()
    (c-args seqs)))
