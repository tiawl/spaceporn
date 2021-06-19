#include "log.h"

FUNC debug ARGS char* message, ...
DO
  LOG(DEBUG_PREFIX, message);
DONE

FUNC info ARGS char* message, ...
DO
  LOG(INFO_PREFIX, message);
DONE

FUNC error ARGS char* message, ...
DO
  LOG(ERROR_PREFIX, message);
DONE
