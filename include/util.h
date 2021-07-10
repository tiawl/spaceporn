#ifndef XTELESKTOP_UTIL_H
#define XTELESKTOP_UTIL_H

#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <GL/glew.h>
#include <GL/glx.h>

#define DEBUG true

enum Roadmap
{
  FOPEN_FAILED_RM = -2,
  BUFFER_MALLOC_FAILED_RM = -1,
  EXIT_SUCCESS_RM = 0, // ----------------------------   0
  BREAK_SUCCESS_RM,
  FSHADERPATH_MALLOC_FAILED_RM,
  VSHADERPATH_MALLOC_FAILED_RM,
  TEXTUREPATH_MALLOC_FAILED_RM,
  XOPENDISPLAY_FAILED_RM, // -------------------------   5
  INVALID_GLX_VERSION_RM,
  GLXCHOOSEFBCONFIG_FAILED_RM,
  XCREATEWINDOW_FAILED_RM,
  GLXCREATECONTEXTATTRIBSARB_UNFOUNDABLE_RM,
  SPACE_IN_GLX_EXT_RM, // ----------------------------  10
  UNSUPPORTED_GLX_EXT_RM,
  CREATION_CONTEXT_FAILED_RM,
  GLEWINIT_FAILED_RM,
  XCREATEDEBUGWINDOW_FAILED_RM,
  FOPEN_VERTEX_FILE_FAILED_RM, // --------------------  15
  BUFFER_VERTEX_FILE_MALLOC_FAILED_RM,
  FOPEN_FRAGMENT_FILE_FAILED_RM,
  BUFFER_FRAGMENT_FILE_MALLOC_FAILED_RM,
  LOAD_VERTEX_SHADER_FAILED_RM,
  LOAD_FRAGMENT_SHADER_FAILED_RM, // -----------------  20
  LINKING_PROGRAM_FAILED_RM,
  NO_PNG_FILENAME_RM,
  FOPEN_PNG_FILE_FAILED_RM,
  PNGCREATEREADSTRUCT_FAILED_RM,
  PNGCREATEINFOSTRUCT_FAILED_RM, // ------------------  25
  RM_NB
};

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
  Display* display;
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
