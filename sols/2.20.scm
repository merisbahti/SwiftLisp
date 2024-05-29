(define (odd? x) (eq (% x 2) 1))
(define (even? x) (eq (% x 2) 0))
(define (f y) (odd? y))
(define parityyy 1)
(define
  (same-parity parity . xs)
  (let
    (
      (parityFn (cond
                 ((odd? parity) odd?)
                 (else even?))))
    (cons parity (filter parityFn xs))))

(print
  (eq (same-parity 1 2 3 4 5 6 7) '(1 3 5 7)))

(print
  (eq (same-parity 2 3 4 5 6 7) '(2 4 6)))
