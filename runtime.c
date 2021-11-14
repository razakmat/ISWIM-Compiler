#include <stdio.h>
#include <string.h>
#include <gc.h>
#include "runtime.h"

/* ------------------------------------------------------------
 * Values                                                       
 */

mpj_value mpj_make_closure(mpj_env *env, char *var, mpj_code_addr code) {
  struct mpj_closure_st *c = GC_MALLOC(sizeof(*c));
  c->env = env;
  c->var = var;
  c->code = code;
  return ((void*)c) + mpj_type_closure;
}

mpj_value mpj_make_pair(mpj_value car, mpj_value cdr) {
  struct mpj_pair_st *p = GC_MALLOC(sizeof(*p));
  p->car = car;
  p->cdr = cdr;
  return ((void*)p) + mpj_type_pair;
}

void mpj_value_eprint(mpj_value v) {
  switch (mpj_value_type(v)) {
  case mpj_type_integer:
    fprintf(stderr, "%ld", mpj_value_as_integer(v));
    return;
  case mpj_type_closure:
    {
      struct mpj_closure_st *c = mpj_value_as_closure(v);
      fprintf(stderr, "(lambda %s %p)", c->var, c->code);
      return;
    }
  case mpj_type_pair:
    {
      fprintf(stderr, "(");
      while (mpj_value_is_pair(v)) {
        struct mpj_pair_st *p = mpj_value_as_pair(v);
        mpj_value_eprint(p->car);
        fprintf(stderr, " ");
        v = p->cdr;
      }
      fprintf(stderr, ". ");
      mpj_value_eprint(v);
      fprintf(stderr, ")");
      return;
    }
  default:
    fprintf(stderr, "BAD_VALUE");
    return;
  }
}

/* ------------------------------------------------------------
 * Environments
 */

mpj_env *mpj_env_empty() {
  return NULL;
}

mpj_env *mpj_env_extend(mpj_env *base, char *name, mpj_value value) {
  mpj_env *env = GC_MALLOC(sizeof(*env));
  env->name = name;
  env->value = value;
  env->next = base;
  return env;
}

mpj_value mpj_env_lookup(mpj_env *env, char *name) {
  while (env) {
    if (!strcmp(name, env->name)) {
      return env->value;
    } else {
      env = env->next;
    }
  }
  mpj_panic("mpj_env_lookup failed");
}

void mpj_env_eprint(mpj_env *env) {
  fprintf(stderr, "ENV: ");
  while (env) {
    fprintf(stderr, "%s = ", env->name);
    mpj_value_eprint(env->value);
    fprintf(stderr, "; ");
    env = env->next;
  }
  fprintf(stderr, "\n");
}

/* ------------------------------------------------------------
 * Other
 */

void mpj_panic(char *message) {
  fprintf(stderr, "error: %s\n", message);
  exit(2);
}

mpj_cont *mpj_cont_empty() {
  mpj_cont *cont = GC_MALLOC(sizeof(*cont));
  cont->label = NULL;
  cont->env = NULL;
  cont->value = NULL;
  cont->prev = NULL;
  return cont;
}

mpj_cont * mpj_cont_extend(mpj_cont* prev,mpj_code_addr label,mpj_env* env,mpj_value value){
  mpj_cont *cont = GC_MALLOC(sizeof(*cont));
  cont->label = label;
  cont->env = env;
  cont->value = value;
  cont->prev = prev;
  return cont;
}

void mpj_cont_change(mpj_cont* cont,void * label,mpj_env* env,mpj_value value){
  cont->label = label;
  cont->env = env;
  cont->value = value;
}

mpj_cont * mpj_cont_remove(mpj_cont* cont){
  return cont->prev;
}

