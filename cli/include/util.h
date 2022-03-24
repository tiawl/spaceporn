#ifndef SPACEPORN_UTIL_H
#define SPACEPORN_UTIL_H

#include <stdarg.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>
#include <systemd/sd-journal.h>
#include <GL/glew.h>
#include <GL/glx.h>

#define DEV GCC_DEV

enum Mode
{
  NO_MODE,
  ANIM_MOTION_MODE,
  ANIM_MODE,
  MOTION_MODE,
  BGGEN_MODE,
  SLIDE_MODE,
  LOCKED
};

enum ColorSetting
{
  BLACK_WHITE,
  STATIC_MONO,
  DYNAMIC_MONO,
  COLORFUL
};

enum RoadmapID
{
  IMPROVELOGSHADER_REGCOMP_FAILED_RM =                                 -26,
  IMPROVELOGSHADER_REGEXEC_FAILED_RM =                                 -25,
  IMPROVELOGSHADER_REPLACE_REGEXEC_FAILED_RM =                         -24,
  IMPROVELOGSHADER_REPLACE_REALLOC_FAILED_RM =                         -23,
  IMPROVELOGSHADER_REPLACE_REGCOMP_FAILED_RM =                         -22,
  SARH_REGEXEC_FAILED_RM =                                             -21,
  SARH_REPLACE_2_REGEXEC_FAILED_RM =                                   -20,
  SARH_REPLACE_2_REALLOC_FAILED_RM =                                   -19,
  SARH_REPLACE_2_REGCOMP_FAILED_RM =                                   -18,
  SARH_ADDMARKERS_IN_LOOP_REALLOC_FAILED_RM =                          -17,
  SARH_READFILE_FOPEN_FAILED_RM =                                      -16,
  SARH_READFILE_BUFFER_MALLOC_FAILED_RM =                              -15,
  SARH_HEADER_REALLOC_FAILED_RM =                                      -14,
  SARH_HEADERS_REALLOC_FAILED_RM =                                     -13,
  SARH_REPLACE_1_REGEXEC_FAILED_RM =                                   -12,
  SARH_REPLACE_1_REALLOC_FAILED_RM =                                   -11,
  SARH_REPLACE_1_REGCOMP_FAILED_RM =                                   -10,
  REPLACE_REGEXEC_FAILED_RM =                                           -9,
  REPLACE_REALLOC_FAILED_RM =                                           -8,
  REPLACE_REGCOMP_FAILED_RM =                                           -7,
  SARH_ADDMARKERS_REALLOC_FAILED_RM =                                   -6,
  SARH_HEADER_MALLOC_FAILED_RM =                                        -5,
  SARH_HEADERS_MALLOC_FAILED_RM =                                       -4,
  SARH_REGCOMP_FAILED_RM =                                              -3,
  FOPEN_FAILED_RM =                                                     -2,
  BUFFER_MALLOC_FAILED_RM =                                             -1,
// -------------------------------------------------------------------   0
  EXIT_SUCCESS_RM = 0,
  SLIDEMODE_SUCCESS_RM,
  BREAK_SUCCESS_RM,
  PATH_MALLOC_FAILED_RM,
  FSHADERPATH_MALLOC_FAILED_RM,
// -------------------------------------------------------------------   5
  VSHADERDIR_MALLOC_FAILED_RM,
  VSHADERPATH_MALLOC_FAILED_RM,
  XOPENDISPLAY_FAILED_RM,
  INVALID_GLX_VERSION_RM,
  GLXCHOOSEFBCONFIG_FAILED_RM,
// -------------------------------------------------------------------  10
  XCREATEWINDOW_FAILED_RM,
  GLXCREATECONTEXTATTRIBSARB_UNFOUNDABLE_RM,
  SPACE_IN_GLX_EXT_RM,
  UNSUPPORTED_GLX_EXT_RM,
  CONTEXT_CREATION_FAILED_RM,
// -------------------------------------------------------------------  15
  GLEWINIT_FAILED_RM,
  FOPEN_VERTEX_FILE_FAILED_RM,
  BUFFER_VERTEX_FILE_MALLOC_FAILED_RM,
  FOPEN_FRAGMENT_FILE_FAILED_RM,
  BUFFER_FRAGMENT_FILE_MALLOC_FAILED_RM,
// -------------------------------------------------------------------  20
  VERTEX_SHADER_COMPILATION_FAILED_RM,
  FRAGMENT_SHADER_COMPILATION_FAILED_RM,
  LINKING_PROGRAM_FAILED_RM,
  OPENGL_ERROR_RM,
  VERTEX_FILE_SARH_REGCOMP_FAILED_RM,
// -------------------------------------------------------------------  25
  VERTEX_FILE_SARH_HEADERS_MALLOC_FAILED_RM,
  FRAGMENT_FILE_SARH_REGCOMP_FAILED_RM,
  FRAGMENT_FILE_SARH_HEADERS_MALLOC_FAILED_RM,
  VERTEX_FILE_SARH_HEADER_MALLOC_FAILED_RM,
  VERTEX_FILE_SARH_ADDMARKERS_REALLOC_FAILED_RM,
// -------------------------------------------------------------------  30
  VERTEX_FILE_SARH_REPLACE_1_REGCOMP_FAILED_RM,
  VERTEX_FILE_SARH_REPLACE_1_REALLOC_FAILED_RM,
  VERTEX_FILE_SARH_REPLACE_1_REGEXEC_FAILED_RM,
  VERTEX_FILE_SARH_HEADERS_REALLOC_FAILED_RM,
  VERTEX_FILE_SARH_HEADER_REALLOC_FAILED_RM,
// -------------------------------------------------------------------  35
  VERTEX_FILE_SARH_READFILE_BUFFER_MALLOC_FAILED_RM,
  VERTEX_FILE_SARH_READFILE_FOPEN_FAILED_RM,
  VERTEX_FILE_SARH_ADDMARKERS_IN_LOOP_REALLOC_FAILED_RM,
  VERTEX_FILE_SARH_REPLACE_2_REGCOMP_FAILED_RM,
  VERTEX_FILE_SARH_REPLACE_2_REALLOC_FAILED_RM,
// -------------------------------------------------------------------  40
  VERTEX_FILE_SARH_REPLACE_2_REGEXEC_FAILED_RM,
  FRAGMENT_FILE_SARH_HEADER_MALLOC_FAILED_RM,
  FRAGMENT_FILE_SARH_ADDMARKERS_REALLOC_FAILED_RM,
  FRAGMENT_FILE_SARH_REPLACE_1_REGCOMP_FAILED_RM,
  FRAGMENT_FILE_SARH_REPLACE_1_REALLOC_FAILED_RM,
// -------------------------------------------------------------------  45
  FRAGMENT_FILE_SARH_REPLACE_1_REGEXEC_FAILED_RM,
  FRAGMENT_FILE_SARH_HEADERS_REALLOC_FAILED_RM,
  FRAGMENT_FILE_SARH_HEADER_REALLOC_FAILED_RM,
  FRAGMENT_FILE_SARH_READFILE_BUFFER_MALLOC_FAILED_RM,
  FRAGMENT_FILE_SARH_READFILE_FOPEN_FAILED_RM,
// -------------------------------------------------------------------  50
  FRAGMENT_FILE_SARH_ADDMARKERS_IN_LOOP_REALLOC_FAILED_RM,
  FRAGMENT_FILE_SARH_REPLACE_2_REGCOMP_FAILED_RM,
  FRAGMENT_FILE_SARH_REPLACE_2_REALLOC_FAILED_RM,
  FRAGMENT_FILE_SARH_REPLACE_2_REGEXEC_FAILED_RM,
  VERTEX_FILE_SARH_REGEXEC_FAILED_RM,
// -------------------------------------------------------------------  55
  VERTEX_FILE_ILS_REPLACE_REGCOMP_FAILED_RM,
  VERTEX_FILE_ILS_REPLACE_REALLOC_FAILED_RM,
  VERTEX_FILE_ILS_REPLACE_REGEXEC_FAILED_RM,
  VERTEX_FILE_ILS_REGCOMP_FAILED_RM,
  VERTEX_FILE_ILS_REGEXEC_FAILED_RM,
// -------------------------------------------------------------------  60
  FRAGMENT_FILE_SARH_REGEXEC_FAILED_RM,
  FRAGMENT_FILE_ILS_REPLACE_REGCOMP_FAILED_RM,
  FRAGMENT_FILE_ILS_REPLACE_REALLOC_FAILED_RM,
  FRAGMENT_FILE_ILS_REPLACE_REGEXEC_FAILED_RM,
  FRAGMENT_FILE_ILS_REGCOMP_FAILED_RM,
// -------------------------------------------------------------------  65
  FRAGMENT_FILE_ILS_REGEXEC_FAILED_RM,
  ATLASTEXTUREPATH_MALLOC_FAILED_RM,
  ATLASTEXELS_MALLOC_FAILED_RM,
  ATLASTEXELROW_MALLOC_FAILED_RM,
  FOPEN_NEW_PNG_FILE_FAILED_RM,
// -------------------------------------------------------------------  70
  PNGCREATEWRITESTRUCT_FAILED_RM,
  PNGCREATEWRITEINFOSTRUCT_FAILED_RM,
  PNG_WRITEJMPBUF_FAILED_RM,
  NO_ATLASPNG_FILENAME_RM,
  FOPEN_ATLASPNG_FILE_FAILED_RM,
// -------------------------------------------------------------------  75
  ATLASPNGCREATEREADSTRUCT_FAILED_RM,
  ATLASPNGCREATEREADINFOSTRUCT_FAILED_RM,
  ATLASPNG_READJMPBUF_FAILED_RM,
  ATLASPNG_DATA_MALLOC_FAILED_RM,
  ATLASPNG_READROWPOINTERS_MALLOC_FAILED_RM,
// -------------------------------------------------------------------  80
  BAD_ATLASPNG_DIMENSIONS_RM,
  PRECOMPUTE_AND_STOP_RM,
  PRECOMPUTE_AND_CONTINUE_RM,
#if DEV
  XCREATEKBWINDOW_FAILED_RM,
#endif
  RM_NB
};

#define MSG_LEN 8

enum LogLevel
{
  DEBUG,
  INFO,
  WARNING,
  ERROR
};

#define LOGLEVEL GCC_LOGLEVEL

typedef struct
{
  enum RoadmapID id;
  char* glsl_file;
} Roadmap;

typedef struct
{
  bool verbose;
  Roadmap roadmap;
} Log;

bool initLog(Log* log);
void writeLog(Log* log, FILE* stream, enum LogLevel level,
  const char* stdoutstr, const char* str, ...);
void freeLog(Log* log);

bool checkOpenGLError(const char* stmt, const char* fname, int line, Log* log);

double timediff(struct timeval* start, struct timeval* end);
int nextpow2(int n);

#define GL_CHECK(stmt, status, log) { \
  stmt; \
  status = checkOpenGLError(#stmt, __FILE__, __LINE__, log); \
  if (!(status)) \
  { \
    break; \
  } \
}

#define MISSINGMAIN_VERTEX_SHADER GCC_MISSINGMAIN_VERTEX
#define ERRONEOUS_VERTEX_SHADER GCC_ERRONEOUS_VERTEX
#define ERRONEOUS_FRAGMENT_SHADER GCC_ERRONEOUS_FRAGMENT

#endif
