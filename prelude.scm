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

(def filter
  (fn (pred xs)
    (cond
      ((eq xs '()) '())
      ((pred (car xs)) (cons (car xs) (filter pred (cdr xs))))
      (true (filter pred (cdr xs))))))

(define = eq)
