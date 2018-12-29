(define (problem m-01)
   (:domain monkey)
   (:objects p1 p2 p3 p4)
   (:init
     (at monkey p1)
     (on-floor)
     (at box p2)
     (at bananas p3)
   )
   (:goal 
       (and 
        (hasbananas)
       )
       )
)