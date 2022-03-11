AC_PREREQ([2.69])
AC_INIT([spaceporn], [0.1], [pabtomas@protonmail.com])
AC_CONFIG_SRCDIR([../../src/spaceporn.c])

AC_LANG(C)

# Checks for programs.
AC_PROG_CC

if test "$ac_cv_prog_cc_g" = "no"; then
  AC_MSG_ERROR([No C compiler present. Install GCC.]);
fi

# Checks for libraries and headers
AC_CHECK_HEADERS([errno.h stdio.h stdlib.h string.h unistd.h \
string.h regex.h math.h limits.h], [], AC_MSG_ERROR([Some GLibC headers are \
missing. Install or check the GLibC library.]))

AC_CHECK_LIB([m], [pow], [], [AC_MSG_ERROR([lib math linking flag (-lm) is \
missing. Install or check GLibC library.])])
AC_CHECK_LIB([png], [png_create_read_struct], [], [AC_MSG_ERROR([libPNG \
linking flag (-lpng) is missing. Install or check libPNG.])])
AC_CHECK_LIB([systemd], [sd_journal_send], [], [AC_MSG_ERROR([libsystemd \
linking flag (-lsystemd) is missing. Install or check libsystemd library.])])
AC_CHECK_LIB([GL], [glClear], [], [AC_MSG_ERROR([GL linking flag \
(-lGL) is missing. Install or check GL library.])])
AC_CHECK_LIB([GLEW], [glewInit], [], [AC_MSG_ERROR([GLEW linking flag \
(-lGLEW) is missing. Install or check GLEW library.])])
AC_CHECK_LIB([X11], [XOpenDisplay], [], [AC_MSG_ERROR([X11 linking flag \
(-lX11) is missing. Install or check X11 library.])])

AC_CHECK_HEADER([png.h], [], [AC_MSG_ERROR([libPNG header is missing. \
Install or check libPNG.])])
AC_CHECK_HEADER([systemd/sd-journal.h], [],
  [AC_MSG_ERROR([libsystemd-journal header is missing. Install or check \
libsystemd.])])
AC_CHECK_HEADER([GL/gl.h], [], [AC_MSG_ERROR([GL header is missing. \
Install or check GL library.])])
AC_CHECK_HEADER([GL/glx.h], [], [AC_MSG_ERROR([GLX header is missing. \
Install or check GLX library.])])
AC_CHECK_HEADER([GL/glew.h], [], [AC_MSG_ERROR([GLEW header is missing. \
Install or check GLEW library.])])
AC_CHECK_HEADERS([X11/X.h X11/Xlib.h X11/Xutil.h X11/Xatom.h], [],
  [AC_MSG_ERROR([Some X11 headers are missing. Install or check X11 \
library.])])

# Checks for typedefs, structures, and compiler characteristics.
AC_HEADER_STDBOOL
AC_HEADER_TIME
AC_C_CONST
AC_TYPE_SIZE_T
AC_TYPE_UINT8_T
AC_CHECK_TYPES([FILE, regex_t, regmatch_t], [], AC_MSG_ERROR([GLibC library \
is installed but some of its types are missing.]), [[#include <stdio.h>
#include <regex.h>]])
AC_CHECK_TYPES([png_infop, png_byte, png_bytep, png_uint_32, png_structp],
  [], AC_MSG_ERROR([libPNG lbrary is installed but some of its types and \
structures are missing.]), [[#include <png.h>]])
AC_CHECK_TYPES([GLubyte, GLuint, GLenum, GLfloat, GLint, GLchar], [],
  AC_MSG_ERROR([GL library is installed but some of its types are missing.]),
[[#include <GL/gl.h>]])
AC_CHECK_TYPES([GLXFBConfig, GLXContext], [], AC_MSG_ERROR([GLX library is \
installed but some of its strutures are missing.]),
  [[#include <GL/glx.h>]])
AC_CHECK_TYPES([Bool, XEvent, XErrorEvent, XSetWindowAttributes, XWMHints,
  XVisualInfo, Window, Colormap], [], AC_MSG_ERROR([X11 library is installed
but some of its types and strutures are missing.]),
[[#include <X11/Xutil.h>]])

# Checks for predefined macros and variables.
AC_CHECK_DECLS([NULL, EXIT_FAILURE, EXIT_SUCCESS, SEEK_END, SEEK_SET, errno,
  REG_EXTENDED, REG_NEWLINE, REG_NOMATCH, F_OK, UINT_MAX], [],
  AC_MSG_ERROR([GLibC library is installed but some of its declarations are \
  missing.]), [[#include <stdlib.h>
#include <stdio.h>
#include <sys/time.h>
#include <errno.h>
#include <limits.h>
#include <regex.h>
#include <unistd.h>]])
AC_CHECK_DECLS([PNG_LIBPNG_VER_STRING, PNG_COLOR_MASK_ALPHA, png_jmpbuf, \
  PNG_COLOR_TYPE_RGB_ALPHA, PNG_INTERLACE_NONE, PNG_COMPRESSION_TYPE_DEFAULT, \
  PNG_FILTER_TYPE_DEFAULT], [],
  AC_MSG_ERROR([libPNG is installed but some of its \
declarations are missing.]), [[#include <png.h>]])
AC_CHECK_DECLS([GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_TEXTURE_WRAP_T,
  GL_TEXTURE_MAG_FILTER, GL_NEAREST, GL_TEXTURE_MIN_FILTER, GL_NO_ERROR,
  GL_FALSE, GL_COMPILE_STATUS, GL_TRUE, GL_INFO_LOG_LENGTH, GL_VERTEX_SHADER,
  GL_FRAGMENT_SHADER, GL_LINK_STATUS, GL_ARRAY_BUFFER, GL_STATIC_DRAW,
  GL_FLOAT, GL_COLOR_BUFFER_BIT, GL_DEPTH_BUFFER_BIT, GL_TRIANGLE_STRIP,
  GL_RGBA, GL_RGB, GL_UNSIGNED_BYTE, GL_CLAMP_TO_BORDER, GL_BLEND,
  GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, GL_TEXTURE_2D_ARRAY,
  GL_REPEAT, GL_RGBA8, GL_TEXTURE0], [], AC_MSG_ERROR([GL library is \
installed but some of its declarations are missing.]),
  [[#include <GL/gl.h>]])
AC_CHECK_DECL(glewExperimental, [], AC_MSG_ERROR([GLEW library is \
installed but some of its declarations are missing.]),
  [[#include <GL/glew.h>]])
AC_CHECK_DECLS([GLX_WINDOW_BIT, GLX_RGBA_BIT, GLX_TRUE_COLOR,
  GLX_X_RENDERABLE, GLX_DRAWABLE_TYPE, GLX_RENDER_TYPE, GLX_X_VISUAL_TYPE,
  GLX_RED_SIZE, GLX_GREEN_SIZE, GLX_BLUE_SIZE, GLX_ALPHA_SIZE, GLX_DEPTH_SIZE,
  GLX_STENCIL_SIZE, GLX_DOUBLEBUFFER, GLX_SAMPLE_BUFFERS, GLX_SAMPLES], [],
AC_MSG_ERROR([GLX library is installed but some of its declarations are \
missing.]), [[#include <GL/glx.h>]])
AC_CHECK_DECLS([XA_ATOM, True, False, None, CWBorderPixel, CWColormap,
  CWEventMask, InputHint, StateHint, BlackPixel, WhitePixel, InputOutput,
  NormalState, AllocNone, StructureNotifyMask, PropModeReplace, DefaultScreen,
  RootWindow, ExposureMask, KeyPressMask], [], AC_MSG_ERROR([X11 library is \
installed but some of its declarations are missing.]),
[[#include <X11/Xutil.h>
#include <X11/Xatom.h>]])

# Checks for library functions.
AC_FUNC_MALLOC
AC_CHECK_FUNCS([strchr strerror strstr strlen strcmp strtok strcpy strcat \
strncpy strncat strtoul getenv usleep memcpy printf fprintf snprintf free \
srand rand time gettimeofday fopen fseek fread fclose setjmp \
realloc regcomp regexec regerror regfree log10 floor access], [],
AC_MSG_ERROR([GLibC library is installed but some of its functions are \
missing.]))
AC_CHECK_FUNCS([png_destroy_read_struct png_create_read_struct \
png_create_info_struct png_init_io png_read_info png_get_IHDR \
png_read_update_info png_get_rowbytes png_read_image png_destroy_write_struct \
png_create_write_struct png_write_info png_write_image png_write_end \
png_read_end png_set_IHDR], [], AC_MSG_ERROR([libPNG is installed but some of \
  its functions are missing.]))
AC_CHECK_FUNCS([glEnable glBlendFunc glDeleteProgram glUseProgram glViewport \
glDisableVertexAttribArray glDeleteBuffers glDeleteVertexArrays \
glDeleteTextures glGetError glUniform1fv glUniform1iv glCreateShader \
glShaderSource glCompileShader glGetShaderiv glGetShaderInfoLog \
glDeleteShader glAttachShader glLinkProgram glGetProgramiv glValidateProgram \
glDetachShader glGetUniformLocation glGenVertexArrays glBindVertexArray \
glGenBuffers glBindBuffer glBufferData glEnableVertexAttribArray \
glVertexAttribPointer glClearColor glClear glDrawArrays glGenTextures \
glBindTexture glTexImage2D glTexParameteri glGetProgramInfoLog \
glActiveTexture glTexImage3D glUniform1i glTexSubImage3D], [],
AC_MSG_ERROR([GL library is installed but some of its functions are missing.]))
AC_CHECK_FUNC(glewInit, [], AC_MSG_ERROR([GLEW library is installed but some \
of its functions are missing.]))
AC_CHECK_FUNCS([glXQueryVersion glXChooseFBConfig glXGetVisualFromFBConfig \
glXGetFBConfigAttrib glXQueryExtensionsString glXGetProcAddressARB \
glXMakeCurrent glXDestroyContext glXSwapBuffers],
  [], AC_MSG_ERROR([GLX library is installed but some of its functions are \
missing.]))
AC_CHECK_FUNCS([XOpenDisplay XCloseDisplay XFree XCreateColormap \
XAllocWMHints XSetWMProperties XInternAtom XChangeProperty XMapWindow \
XGetWindowAttributes XCreateWindow XSetErrorHandler XSync XDestroyWindow \
XFreeColormap XSelectInput XCreateSimpleWindow XCheckMaskEvent XUnmapWindow],
[], AC_MSG_ERROR([X11 library is installed but some of its functions are \
missing.]))

AC_OUTPUT
