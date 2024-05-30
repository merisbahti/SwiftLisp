(define (square x) (* x x))
(define (square-list items)
  (define (iter things answer)
    (if (null? things)
      answer
      (iter (cdr things)
        (cons (square (car things))
          answer))))
  (iter items nil))

(assert (square-list '(1 2 3 4)) '(16 9 4 1))
