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

typedef struct
{
  Display *display;
  GLXContext glx_context;
  Window window;
#ifdef DEBUG
  Window debug_window;
  XEvent event;
#endif
  XWindowAttributes window_attribs;
  Colormap cmap;
  GLuint program;
} Context;

typedef struct
{
  char* fshaderpath;
  char* vshaderpath;
  GLuint vertex_shader;
  GLuint fragment_shader;
  char* vertex_file;
  char* fragment_file;
} Shaders;

#endif
