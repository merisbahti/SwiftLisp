(car ''abracadabra)
; its because it expands to the following expr
(assert (car ''abracadabra) (car (quote (quote abracadabra))))

 
