(define (domain monkey)
   (:requirements :adl)
   (:constants monkey box bananas)
   (:predicates  (goto ?x ?y) 
                 (climp ?x)
                 (push-box ?x ?y)
                 (grab-bananas ?y)
                 (on-floor)
                 (at ?x ?y)
                 (hasbananas)
                 (onbox ?x))

   (:action goto
             :parameters (?x ?y)
             :precondition (and (on-floor)
                                (at monkey ?y))
             :effect  (and (at monkey ?x)
                           (not (at monkey ?y)))) 

   (:action climp
             :parameters (?x)
             :precondition (and (at box ?x)
                             (at monkey ?x))
             :effect  (and (onbox ?x)
                           (not (on-floor)))) 

   (:action push-box
             :parameters (?x ?y)
             :precondition (and (at box ?y)
                                (at monkey ?y)
                                (on-floor))
             :effect  (and (at monkey ?x)
                           (at box ?x)
                           (not (at monkey ?y))
                           (not (at box ?y)))) 

   (:action grab-bananas
             :parameters (?y)
             :precondition (and (at bananas ?y)
                                (onbox ?y))
             :effect  (and (hasbananas))) 
)
