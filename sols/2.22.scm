(define (for-each f xs)
  (let
    ((throwaway (map f xs)))
    true))
(for-each
  (fn (x) (let ((throwaway newline)) 
           (display x)))
  (list 57 321 88))
