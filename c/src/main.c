#include "main.h"

FUNC main ARGS
DO
#if BUILD == DEV_BUILD
  CALL info WITH "You are running a dev build" ENDCALL;
#endif

  CONTEXT_T context;

  CALL init    WITH &context ENDCALL;
  CALL loop    WITH &context ENDCALL;
  CALL cleanup WITH &context ENDCALL;

  RETURN EXIT_SUCCESS;
DONE
