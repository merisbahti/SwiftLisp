(def
  reverse
  (fn (x)
    (reverse-iter x '())))

(def reverse-iter
  (fn (x acc)
    (cond
      ((null? x) acc)
      (true (reverse-iter (cdr x) (cons (car x) acc))))))

(reverse '(1 4 9 16 25))
