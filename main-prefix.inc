  /* The V register is
   * - dead on entry to an "eval" configuration,
   * - live on entry to a "return" configuration, 
   *   and holds the Value being returned.
   */
  mpj_value V = mpj_make_integer(0);

  /* MORE STUFF MIGHT GO HERE */

  /* Jump over the following labels to the program START. */
  goto START;

MPJ_K_HALT:
  {
    switch (mpj_value_type(V)) {
    case mpj_type_integer:
      printf("%ld\n", mpj_value_as_integer(V));
      exit(0);
    default:
      mpj_panic("My implementation of the halt continuation is incomplete!");
    }
  }

  /* MORE STUFF MIGHT GO HERE */
