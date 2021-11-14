  /* The V register is
   * - dead on entry to an "eval" configuration,
   * - live on entry to a "return" configuration, 
   *   and holds the Value being returned.
   */
  mpj_value V = mpj_make_integer(0);

  mpj_env * env = NULL;
  mpj_cont * cont = mpj_cont_empty();
  mpj_cont_change(cont,&&MPJ_K_HALT,NULL,NULL);
  mpj_code_addr label_closure;

  /* Jump over the following labels to the program START. */
  goto START;

MPJ_K_HALT:
  {
    switch (mpj_value_type(V)) {
    case mpj_type_integer:
      printf("%ld\n", mpj_value_as_integer(V));
      exit(0);
    case mpj_type_closure:
      printf("function\n");
      exit(1);
    case mpj_type_pair:
      printf("pair\n");
      exit(1);
    default:
      mpj_panic("Program halted with unknown type!");
    }
  }


  /* MORE STUFF MIGHT GO HERE */
