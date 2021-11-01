#lang racket
(require "iswim.rkt")

;; ----------------------------------------

;; Running "racket compiler.rkt <arg> ..." invokes the main submodule:
(module+ main
  (require (only-in "iswim.rkt" SurfaceExpr?))
  ;; When this module is run as a program, it reads an ISWIM program
  ;; from standard input and writes the compiled version to standard
  ;; output.
  (match (port->list read (current-input-port))
    [(list program)
     (unless (SurfaceExpr? program)
       (error 'compiler.rkt "not an ISWIM surface expression: ~e" program))
     (compile-program program)]
    [(list) (error 'compiler.rkt "file contains zero expressions")]
    [_ (error 'compiler.rkt "file contains multiple expressions")]))

;; ----------------------------------------

;; compile-program : Expr -> Void (& writes)
;; Writes compilation of given expression as a C program to stdout.
(define (compile-program program)
  (printf "#include \"program-prefix.inc\"\n")
  (printf "int main() {\n#include \"main-prefix.inc\"\n")
  (define start-index (compile program))
  (printf "\nSTART: goto EVAL_~a;\n" start-index)
  (printf "}\n")
  (void))

;; compile : Expr -> Nat (and writes)
;; Allocates an index for the expression, writes labeled blocks to
;; stdout, and returns the index.
(define (compile expr)
  (define index (get-index))
  (print-code-comment expr)  ;; to help debugging
  (match expr
    [(? exact-integer? B)
     (printf "EVAL_~a:\n" index)
     (printf "  V = mpj_make_integer(~s);\n" B)
     ;; FIXME: need to return to current continuation
     (printf "  goto MPJ_K_HALT;\n")]
    [_ (error 'compile "My compiler is incomplete!\n  expr: ~e" expr)])
  index)

;; print-code-comment : Expr -> Void
;; Prints the expression (up to 40 chars) in a C comment.
(define (print-code-comment expr)
  (parameterize ((error-print-width 40))
    (printf "/* Code for ~.s */\n" expr)))

;; ----------------------------------------

;; last-index : Nat, mutated
(define last-index 0)

;; get-index : -> Nat
;; Returns next unused index, increments counter.
(define (get-index)
  (set! last-index (add1 last-index))
  last-index)
