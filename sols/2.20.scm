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
    (filter (fn (x) (parityFn x)) xs)))
(print
  (eq (same-parity 1 2 3 4 5 6 7) '(3 5 7)))

(print
  (eq (same-parity 2 3 4 5 6 7) '(4 6)))
