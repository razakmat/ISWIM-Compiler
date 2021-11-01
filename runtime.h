#ifndef MPJ_RUNTIME_H
#define MPJ_RUNTIME_H

#include <stdint.h>
#include <stddef.h>
#include <stdlib.h>
#include <stdnoreturn.h>

#define MPJ_SAFE 1

typedef void *mpj_code_addr;
typedef struct mpj_env_frame_st mpj_env;

/* ------------------------------------------------------------
 * Values
 */

/* mpj_value -- see comment for enum mpj_type */
typedef void* mpj_value;

struct mpj_closure_st {
  mpj_env *env;
  char *var;
  mpj_code_addr code;
};

struct mpj_pair_st {
  mpj_value car;
  mpj_value cdr;
};

/* A Value (mpj_value v) is a word whose low 2 bits are a type tag; the
 * meaning of the rest of the bits depends on the tag:
 *   tag = 0: integer (fixnum), upper 62 (or 30) bits are shifted signed integer
 *   tag = 1: closure, v is a pointer (struct mpj_closure_st*) + tag
 *   tag = 2: pair, v is is a pointer (struct mpj_pair*) + tag
 *   tag = 3: unused
 *
 * This requires libgc to be built with "interior pointer" support,
 * which is enabled by default.
 */
enum mpj_type {
   mpj_type_integer = 0,
   mpj_type_closure = 1,
   mpj_type_pair = 2
};

#define mpj_value_type(v) (((intptr_t)v) & 3)
#define mpj_value_is_integer(v) (mpj_value_type(v) == mpj_type_integer)
#define mpj_value_is_closure(v) (mpj_value_type(v) == mpj_type_closure)
#define mpj_value_is_pair(v) (mpj_value_type(v) == mpj_type_pair)

#define mpj_make_integer(n) ((void*)((n << 2) + mpj_type_integer))
#define mpj_value_as_integer(v) (((intptr_t)v) >> 2)

mpj_value mpj_make_closure(mpj_env*, char*, mpj_code_addr);
#define mpj_value_as_closure(v) ((struct mpj_closure_st*)(v - mpj_type_closure))

mpj_value mpj_make_pair(mpj_value, mpj_value);
#define mpj_value_as_pair(v) ((struct mpj_pair_st*)(v - mpj_type_pair))

void mpj_value_eprint(mpj_value);

/* ------------------------------------------------------------
 * Environments
 */

/* An Environment (mpj_env *env) is either
 * - NULL, representing the empty environment, or
 * - a pointer to an mpj_env_frame_st instance, representing (extend Env X V), where
 *   - env->name represents X,
 *   - env->value represents V, and
 *   - env->next represents Env.
 */
struct mpj_env_frame_st {
  char *name;
  mpj_value value;
  mpj_env *next;
};

mpj_env *mpj_env_empty();
mpj_env *mpj_env_extend(mpj_env*, char*, mpj_value);
mpj_value mpj_env_lookup(mpj_env*, char*);

void mpj_env_print(mpj_env*);

/* ------------------------------------------------------------ */

noreturn void mpj_panic(char*); /* does not return */


/* ============================================================
 * YOUR CODE GOES HERE
 * ============================================================ */



#endif
