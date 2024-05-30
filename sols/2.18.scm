(def
  reverse
  (fn (x)
    (reverse-iter x '())))

(def reverse-iter
  (fn (x acc)
    (cond
      ((null? x) acc)
      (true (reverse-iter (cdr x) (cons (car x) acc))))))

(assert
  '(reverse '(1 4 9 16 25))
  '(list 25 16 9 4 1))
