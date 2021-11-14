#lang racket
(require "iswim.rkt")

;; ----------------------------------------

;; Running "racket compiler.rkt <arg> ..." invokes the main submodule:
(module+ main
  (require (combine-in (only-in "iswim.rkt" SurfaceExpr?) (only-in "iswim.rkt" DesugarExpr)))
  ;; When this module is run as a program, it reads an ISWIM program
  ;; from standard input and writes the compiled version to standard
  ;; output.
  (match (port->list read (current-input-port))
    [(list program)
     (unless (SurfaceExpr? program)
       (error 'compiler.rkt "not an ISWIM surface expression: ~e" program))
     (compile-program (DesugarExpr program))]
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
     (printf "  goto *cont->label;\n")
     (printf "\n//------------------------------------------------------------\n")]
    [(? symbol? X)
     (printf "EVAL_~a:\n" index)
     (printf "  V = mpj_env_lookup(env,\"~a\");\n" X)
     (printf "  goto *cont->label;\n")
     (printf "\n//-------------------------------------------------------------\n")]
    [(list 'λ X M)
      (let ([indexM (compile M)])
      (printf "EVAL_~a:\n" index)
      (printf "  V = mpj_make_closure(env,\"~a\",&&EVAL_~a);\n" X indexM)
      (printf "  goto *cont->label;\n")
      (printf "\n//------------------------------------------------------------\n"))]
    [(list 'if L M N)
      (let ([indexL (compile L)] [indexM (compile M)] [indexN (compile N)])
      (printf "EVAL_~a:\n" index)
      (printf "  cont = mpj_cont_extend(cont,&&RET_if_~a,env,NULL);\n" index)
      (printf "  goto EVAL_~a;\n\n" indexL)
      (printf "RET_if_~a:\n" index)
      (printf "  env = cont->env;\n")
      (printf "  cont = mpj_cont_remove(cont);\n")
      (printf "  if (!(mpj_value_is_integer(V) && (mpj_value_as_integer(V) == 0)))\n")
      (printf "     goto EVAL_~a;\n" indexM)
      (printf "  goto EVAL_~a;\n" indexN)
      (printf "\n//------------------------------------------------------------\n"))]
    [(list 'add1 M)
      (let ([indexM (compile M)])
      (printf "EVAL_~a:\n" index)
      (printf "  cont = mpj_cont_extend(cont,&&RET_op1_~a,env,NULL);\n" index)
      (printf "  goto EVAL_~a;\n\n" indexM)
      (printf "RET_op1_~a:\n" index)
      (printf "  if (!mpj_value_is_integer(V))\n")
      (printf "     mpj_panic(\"Operator add1 can accept only type integer! Expr: (add1 ~a)\");\n" M)
      (printf "  V = mpj_make_integer(mpj_value_as_integer(V) + 1);\n")
      (printf "  cont = mpj_cont_remove(cont);\n")
      (printf "  goto *cont->label;\n\n")
      (printf "\n//------------------------------------------------------------\n"))]
    [(list 'sub1 M)
      (let ([indexM (compile M)])
      (printf "EVAL_~a:\n" index)
      (printf "  cont = mpj_cont_extend(cont,&&RET_op1_~a,env,NULL);\n" index)
      (printf "  goto EVAL_~a;\n\n" indexM)
      (printf "RET_op1_~a:\n" index)
      (printf "  if (!mpj_value_is_integer(V))\n")
      (printf "     mpj_panic(\"Operator sub1 can accept only type integer! Expr: (sub1 ~a)\");\n" M)
      (printf "  V = mpj_make_integer(mpj_value_as_integer(V) - 1);\n")
      (printf "  cont = mpj_cont_remove(cont);\n")
      (printf "  goto *cont->label;\n\n")
      (printf "\n//------------------------------------------------------------\n"))]
    [(list 'fst M)
      (let ([indexM (compile M)])
      (printf "EVAL_~a:\n" index)
      (printf "  cont = mpj_cont_extend(cont,&&RET_op1_~a,env,NULL);\n" index)
      (printf "  goto EVAL_~a;\n\n" indexM)
      (printf "RET_op1_~a:\n" index)
      (printf "  if (!mpj_value_is_pair(V))\n")
      (printf "     mpj_panic(\"Operator fst can accept only type pair! Expr: (fst ~a)\");\n" M)
      (printf "  V = (mpj_value_as_pair(V))->car;\n")
      (printf "  cont = mpj_cont_remove(cont);\n")
      (printf "  goto *cont->label;\n\n")
      (printf "\n//------------------------------------------------------------\n"))]
    [(list 'snd M)
      (let ([indexM (compile M)])
      (printf "EVAL_~a:\n" index)
      (printf "  cont = mpj_cont_extend(cont,&&RET_op1_~a,env,NULL);\n" index)
      (printf "  goto EVAL_~a;\n\n" indexM)
      (printf "RET_op1_~a:\n" index)
      (printf "  if (!mpj_value_is_pair(V))\n")
      (printf "     mpj_panic(\"Operator fst can accept only type pair! Expr: (fst ~a)\");\n" M)
      (printf "  V = (mpj_value_as_pair(V))->cdr;\n")
      (printf "  cont = mpj_cont_remove(cont);\n")
      (printf "  goto *cont->label;\n\n")
      (printf "\n//------------------------------------------------------------\n"))]
    [(list Op2 M N)
      (let ([indexM (compile M)] [indexN (compile N)])
      (printf "EVAL_~a:\n" index)
      (printf "  cont = mpj_cont_extend(cont,&&RET_op2l_~a,env,NULL);\n" index)
      (printf "  goto EVAL_~a;\n\n" indexM)
      (printf "RET_op2l_~a:\n" index)
      (printf "  env = cont->env;\n")
      (printf "  mpj_cont_change(cont,&&RET_op2r_~a,NULL,V);\n" index)
      (printf "  goto EVAL_~a;\n\n" indexN)
      (printf "RET_op2r_~a:\n" index)
      (match Op2
        ['+ 
          (printf "  if (!mpj_value_is_integer(V) || !mpj_value_is_integer(cont->value))\n")
          (printf "     mpj_panic(\"Operator + can accept only type integer! Expr: (+ ~a ~a)\");\n" M N)
          (printf "  V = mpj_make_integer(mpj_value_as_integer(V) + mpj_value_as_integer(cont->value));\n")]
        ['*
          (printf "  if (!mpj_value_is_integer(V) || !mpj_value_is_integer(cont->value))\n")
          (printf "     mpj_panic(\"Operator * can accept only type integer! Expr: (+ ~a ~a)\");\n" M N)
          (printf "  V = mpj_make_integer(mpj_value_as_integer(V) * mpj_value_as_integer(cont->value));\n")]
        ['=
          (printf "  if (!mpj_value_is_integer(V) || !mpj_value_is_integer(cont->value))\n")
          (printf "     mpj_panic(\"Operator + can accept only type integer! Expr: (+ ~a ~a)\");\n" M N)
          (printf "  V = mpj_make_integer((long int)(mpj_value_as_integer(V) == mpj_value_as_integer(cont->value)));\n")]
        ['<
          (printf "  if (!mpj_value_is_integer(V) || !mpj_value_is_integer(cont->value))\n")
          (printf "     mpj_panic(\"Operator + can accept only type integer! Expr: (+ ~a ~a)\");\n" M N)
          (printf "  V = mpj_make_integer((long int)(mpj_value_as_integer(cont->value) < mpj_value_as_integer(V)));\n")]
        ['pair
          (printf "  V = mpj_make_pair(cont->value,V);\n")])
      (printf "  cont = mpj_cont_remove(cont);\n")
      (printf "  goto *cont->label;\n\n")
      (printf "\n//------------------------------------------------------------\n"))]
    [(list M N)
      (let ([indexM (compile M)] [indexN (compile N)])
      (printf "EVAL_~a:\n" index)
      (printf "  cont = mpj_cont_extend(cont,&&RET_apl_~a,env,NULL);\n" index)
      (printf "  goto EVAL_~a;\n\n" indexM)
      (printf "RET_apl_~a:\n" index)
      (printf "  env = cont->env;\n")
      (printf "  mpj_cont_change(cont,&&RET_apr_~a,NULL,V);\n" index)
      (printf "  goto EVAL_~a;\n\n" indexN)
      (printf "RET_apr_~a:\n" index)
      (printf "  if (!mpj_value_is_closure(cont->value))\n")
      (printf "     mpj_panic(\"Left side (M) of application (M N) has to be a function! Expr: (~a ~a)\");\n" M N)
      (printf "  env = mpj_value_as_closure(cont->value)->env;\n")
      (printf "  env = mpj_env_extend(env,mpj_value_as_closure(cont->value)->var,V);\n")
      (printf "  label_closure = mpj_value_as_closure(cont->value)->code;\n")
      (printf "  cont = mpj_cont_remove(cont);\n")
      (printf "  goto *label_closure;\n\n")
      (printf "\n//------------------------------------------------------------\n")
      )])
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
