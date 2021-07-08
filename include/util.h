#ifndef XTELESKTOP_UTIL_H
#define XTELESKTOP_UTIL_H

#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <GL/glew.h>
#include <GL/glx.h>

#define DEBUG true

#if DEBUG
#define EXIT_SUCCESS_RM 0
#define EXIT_FAILURE_RM 1
#endif

#define VERB(v, stmt) if (v) { \
  stmt; \
}

void CheckOpenGLError(const char* stmt, const char* fname, int line);

#define GL_CHECK(stmt) do { \
  stmt; \
  CheckOpenGLError(#stmt, __FILE__, __LINE__); \
} while (0)

#endif
