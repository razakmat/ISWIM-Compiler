#lang racket
(require redex/reduction-semantics)
(provide (all-defined-out))

(define-language ISWIM

  ;; Surface language
  [SM SN SL ::=
      B
      X
      (λ X SM)
      (SM SN)
      (Op1 SM)
      (Op2 SM SN)
      (if SL SM SN)     ;; treats any value except 0 as true
      (let ([X SM]) SN)
      (letrec ([X SM]) SN)]

  [B ::= integer]
  [X Y Z ::= variable-not-otherwise-mentioned]
  [Op1 ::= add1 sub1 fst snd]
  [Op2 ::= + * = < pair])

(define SurfaceExpr? (redex-match ISWIM SM))
