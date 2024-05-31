(define (square x) (* x x))
(define (square-list items)
  (define (iter things answer)
    (if (null? things)
      answer
      (iter (cdr things)
        (cons (square (car things))
          answer))))
  (iter items nil))

(print "it's because cons adds to the front of the list, and we're processing the first item first.")
(assert (square-list '(1 2 3 4)) '(16 9 4 1))

(define (square-list items)
  (define (iter things answer)
    (if (null? things)
      answer
      (iter (cdr things)
        (cons answer
          (square (car things))))))
  (iter items nil))

(print "it still puts things in the wrong order, but now the list is in the 'head' position")
(assert (square-list '(1 2 3 4)) (cons (cons (cons (cons null 1) 4) 9) 16))
