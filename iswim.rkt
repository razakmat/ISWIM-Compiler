#lang racket
(require redex/reduction-semantics)
(provide (all-defined-out))

(define-language ISWIM

  ;; Surface language
  [M N L ::= X (λ X M) B (M N) (Op1 M) (Op2 M N) (if L M N)]
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




(define-metafunction ISWIM
  desugar : SM -> M
  ;; The Core expression cases:
  [(desugar X) X]
  [(desugar (λ X SM)) (λ X (desugar SM))]
  [(desugar (SM SN)) ((desugar SM) (desugar SN))]
  [(desugar B) B]
  [(desugar (Op1 SM)) (Op1 (desugar SM))]
  [(desugar (Op2 SM SN)) (Op2 (desugar SM) (desugar SN))]
  [(desugar (if SL SM SN)) (if (desugar SL) (desugar SM) (desugar SN))]
  ;; The syntactic sugar cases:
  [(desugar (let ([X SM]) SN))
   (desugar ((λ X SN) SM))]
  [(desugar (letrec ([X SM]) SN))
   (desugar ((λ X SN) (,Z-term (λ X SM))))])

(define Z-term
  '(λ f (λ x (((λ g (f (λ v ((g g) v)))) (λ g (f (λ v ((g g) v))))) x))))


(define (DesugarExpr SurfaceExpr)
  (term (desugar ,SurfaceExpr))
  )