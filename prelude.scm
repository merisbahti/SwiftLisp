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
(define = eq)
