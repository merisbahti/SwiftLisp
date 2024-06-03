(define (dot-product v w)
  (accumulate + 0 (map-n * v w)))
(define matrix '((1 2 3 4) (4 5 6 6) (6 7 8 9)))

(assert
  (map-n (lambda (a b) (+ a b)) (car matrix) (car (cdr matrix)))
  '(5 7 9 10))

(assert (dot-product '(1 2 3) '(4 -5 6)) 12)
(assert (dot-product (car matrix) (car (cdr matrix))) (+ (* 1 4) (* 2 5) (* 6 3) (* 6 4)))
