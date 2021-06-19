#include "extensions.h"

FUNC copy_ext ARGS EXTENSIONS_T* from, EXTENSIONS_T** to
DO
  MALLOC(*to, sizeof(EXTENSIONS_T));
  MALLOC((*to)->list, sizeof(char*) * from->count + 1);

  (*to)->count = from->count;
  uint32_t len = 0;
  FOR uint32_t i = 0; i < from->count; ++i
  DO
    len = strlen(from->list[i]);
    MALLOC((*to)->list[i], sizeof(char) * (len + 1));
    CALL memset WITH (*to)->list[i], 0, len + 1                        ENDCALL;
    CALL memcpy WITH (*to)->list[i], from->list[i], sizeof(char) * len ENDCALL;
  DONE

  SUCCESS;
DONE
