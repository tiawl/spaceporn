// for uint32_t
#include <stdint.h>

// for strlen()
#include <string.h>

// for MALLOC and TYPE macros
#include "helpers.h"

#define EXTENTIONS_T PREFIX_TYPE(extensions)

STRUCT
  ATTR
    uint32_t count;
    char**   list;
  NAME
    EXTENSIONS_T;
ENDSTRUCT

PROTO copy_ext ARGS EXTENSIONS_T* from, EXTENSIONS_T** to ENDPROTO;
