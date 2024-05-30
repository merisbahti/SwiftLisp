(def not
  (fn (x)
    (cond
      (x false)
      (true true))))

(def null?
  (fn (x)
    (cond
      ((eq x '()) true)
      (true false))))
(define nil '())

(define (map proc items)
  (cond
    ((null? items) nil)
    (else
      (cons (proc (car items))
        (map proc (cdr items))))))
(define (newline) (print ""))
(define display print)

(def filter
  (fn (pred xs)
    (cond
      ((eq xs '()) '())
      ((pred (car xs)) (cons (car xs) (filter pred (cdr xs))))
      (true (filter pred (cdr xs))))))

(define = eq)

(define (assert a b)
  (let ((aEvaled (eval a))
        (bEvaled (eval b)))
    (cond
      ((= aEvaled bEvaled) null)
      (else (print "assertion failed, found: " aEvaled ", but expected: " bEvaled " (" a " != " b ")")))))
