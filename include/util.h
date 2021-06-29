#ifndef XTELESKTOP_UTIL_H
#define XTELESKTOP_UTIL_H

#include <stdbool.h>

#define DEBUG true

#if DEBUG
#define EXIT_SUCCESS_RM 0
#define EXIT_FAILURE_RM 1
#endif

#define VERB(v, stmt) if (v) { \
  stmt; \
}

#endif
