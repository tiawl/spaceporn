#ifndef XTELESKTOP_UTIL_H
#define XTELESKTOP_UTIL_H

#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <png.h>
#include <GL/glew.h>
#include <GL/glx.h>

#define DEBUG true

enum Roadmap
{
  FOPEN_FAILED_RM = -2,
  BUFFER_MALLOC_FAILED_RM = -1,
  EXIT_SUCCESS_RM = 0, // ----------------------------   0
  BREAK_SUCCESS_RM,
  GETENV_USERNAME_FAILED_RM,
  FSHADERPATH_MALLOC_FAILED_RM,
  VSHADERPATH_MALLOC_FAILED_RM,
  TEXTUREPATH_MALLOC_FAILED_RM, // -------------------   5
  XOPENDISPLAY_FAILED_RM,
  INVALID_GLX_VERSION_RM,
  GLXCHOOSEFBCONFIG_FAILED_RM,
  XCREATEWINDOW_FAILED_RM,
  GLXCREATECONTEXTATTRIBSARB_UNFOUNDABLE_RM, // ------  10
  SPACE_IN_GLX_EXT_RM,
  UNSUPPORTED_GLX_EXT_RM,
  CONTEXT_CREATION_FAILED_RM,
  GLEWINIT_FAILED_RM,
  FOPEN_VERTEX_FILE_FAILED_RM, // --------------------  15
  BUFFER_VERTEX_FILE_MALLOC_FAILED_RM,
  FOPEN_FRAGMENT_FILE_FAILED_RM,
  BUFFER_FRAGMENT_FILE_MALLOC_FAILED_RM,
  VERTEX_SHADER_COMPILATION_FAILED_RM,
  FRAGMENT_SHADER_COMPILATION_FAILED_RM, // ----------  20
  LINKING_PROGRAM_FAILED_RM,
  NO_PNG_FILENAME_RM,
  FOPEN_PNG_FILE_FAILED_RM,
  PNGCREATEREADSTRUCT_FAILED_RM,
  PNGCREATEINFOSTRUCT_FAILED_RM, // ------------------  25
  PNG_JMPBUF_FAILED_RM,
  BAD_PNG_DIMENSIONS_RM,
  PNG_DATA_MALLOC_FAILED_RM,
  PNG_ROWPOINTERS_MALLOC_FAILED_RM,
  OPENGL_ERROR_RM, // --------------------------------  30
#if DEBUG
  XCREATEDEBUGWINDOW_FAILED_RM,
#endif
  RM_NB
};

#define VERB(v, stmt) if (v) { \
  stmt; \
}

typedef struct
{
  Display* display;
  GLXContext glx_context;
  Window window;
#if DEBUG
  Window debug_window;
  XEvent event;
#endif
  XWindowAttributes window_attribs;
  XVisualInfo* visual_info;
  Colormap cmap;
} Context;

typedef struct
{
  char* fshaderpath;
  char* vshaderpath;
  char* vertex_file;
  char* fragment_file;
  GLuint vertex_shader;
  GLuint fragment_shader;
  GLuint program;
} Shaders;

typedef struct
{
  png_structp parser;
  png_infop info;
  png_bytep* row_pointers;
  uint8_t* data;
  FILE* file;
  char* path;
  GLuint texture;
} PNG;

typedef struct
{
  GLuint array;
  GLuint buffer;
} Vertices;

typedef struct
{
  Context* context;
  Shaders* shaders;
  PNG* png;
  Vertices* vertices;
  bool* verbose;
} Aggregate;

void freeContext(Context* context, bool verbose);
void freeProgram(Shaders* shaders, bool verbose);
void freePng(PNG* png, bool verbose);
void freePaths(Shaders* shaders, PNG* png, bool verbose);
void freeVertices(Vertices* vertices, bool verbose);

void aggregateContext(Context* context);
void aggregateShaders(Shaders* shaders);
void aggregatePng(PNG* png);
void aggregateVertices(Vertices* vertices);
void aggregateVerbose(bool* verbose);

void exitHandler();
void checkOpenGLError(const char* stmt, const char* fname, int line);

#define GL_CHECK(stmt) do { \
  stmt; \
  checkOpenGLError(#stmt, __FILE__, __LINE__); \
} while (0)

#endif
