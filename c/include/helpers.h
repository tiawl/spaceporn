// for algol macros
#include "macros.h"

// for ERROR macro
#include "log.h"

#define PREFIX_TYPE(name)  name ## _ ## EXE ## _t

#define MALLOC(var, mem)                                        \
DEF                                                             \
  var = CALL malloc WITH mem ENDCALL;                           \
  IF NOT var                                                    \
  THEN                                                          \
    ERROR("Failed to allocate memory for '%s' variable", #var); \
    FAILURE;                                                    \
  ENDIF                                                         \
ENDDEF

#define REALLOC(var, mem)                                         \
DEF                                                               \
  var = CALL realloc WITH var, mem ENDCALL;                       \
  IF NOT var                                                      \
  THEN                                                            \
    ERROR("Failed to reallocate memory for '%s' variable", #var); \
    FAILURE;                                                      \
  ENDIF                                                           \
ENDDEF
