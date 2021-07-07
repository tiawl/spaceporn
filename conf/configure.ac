AC_PREREQ([2.69])
AC_INIT([xtelesktop], [0.1], [pabtomas@protonmail.com])
AC_CONFIG_SRCDIR([../src/xtelesktop.c])

AC_LANG(C)

# Checks for programs.
AC_PROG_CC

if test "$ac_cv_prog_cc_g" = "no"; then
  AC_MSG_ERROR([No C compiler present. Install GCC.]);
fi

# Checks for libraries and headers
AC_CHECK_HEADERS([time.h errno.h stdio.h stdlib.h string.h unistd.h string.h],
  [], AC_MSG_ERROR([Some GLibC headers are not found. Install or check the \
GLibC developing package.]))

AC_CHECK_LIB([png], [png_create_read_struct], [], [AC_MSG_ERROR([libPNG \
linking flag (-lpng) is not found. Install or check libPNG developing \
package.])])
AC_CHECK_LIB([GL], [glClear], [], [AC_MSG_ERROR([GL linking flag \
(-lGL) is not found. Install or check GL developing package.])])
AC_CHECK_LIB([GLEW], [glewInit], [], [AC_MSG_ERROR([GLEW linking flag \
(-lGLEW) is not found. Install or check GLEW developing package.])])
AC_CHECK_LIB([X11], [XOpenDisplay], [], [AC_MSG_ERROR([X11 linking flag \
(-lX11) is not found. Install or check X11 developing package.])])

AC_CHECK_HEADER([png.h], [], [AC_MSG_ERROR([libPNG header is not found. \
Install or check libPNG developing package.])])
AC_CHECK_HEADER([GL/gl.h], [], [AC_MSG_ERROR([GL header is not found. \
Install or check GL developing package.])])
AC_CHECK_HEADER([GL/glx.h], [], [AC_MSG_ERROR([GLX header is not found. \
Install or check GLX developing package.])])
AC_CHECK_HEADER([GL/glew.h], [], [AC_MSG_ERROR([GLEW header is not found. \
Install or check GLEW developing package.])])
AC_CHECK_HEADERS([X11/X.h X11/Xlib.h X11/Xutil.h X11/Xatom.h], [],
  [AC_MSG_ERROR([Some X11 headers are not found. Install or check X11 \
developing package.])])

# Checks for typedefs, structures, and compiler characteristics.
AC_CHECK_HEADER_STDBOOL
AC_C_CONST
AC_TYPE_SIZE_T
AC_TYPE_UINT8_T
AC_CHECK_TYPE(FILE, [], AC_MSG_ERROR([GLibC package is found but some types \
of this package are not found. Update the GLibC developing package.]))
AC_CHECK_TYPES([png_infop, png_byte, png_bytep, png_uint_32, png_structp],
  [], AC_MSG_ERROR([libPNG package is found but some types and structures \
of this package are not found. Update the libPNG developing package.]),
  [[#include <png.h>]])
AC_CHECK_TYPES([GLubyte, GLuint, GLenum, GLfloat, GLint, GLchar], [],
  AC_MSG_ERROR([GL package is found but some types of this package are \
not found. Update the GL developing package.]), [[#include <GL/gl.h>]])
AC_CHECK_TYPES([GLXFBConfig, GLXContext], [], AC_MSG_ERROR([GLX package is \
found but some strutures of this package are not found. Update the GLX \
developing package.]), [[#include <GL/glx.h>]])
AC_CHECK_TYPES([Bool, XEvent, XErrorEvent, XSetWindowAttributes, XWMHints,
  XVisualInfo, Window, Colormap], [], AC_MSG_ERROR([X11 package is found but \
some types and strutures of this package are not found. Update the X11 \
developing package.]), [[#include <X11/Xutil.h>]])

# Checks for predefined macros and variables.
AC_CHECK_DECLS([NULL, EXIT_FAILURE, EXIT_SUCCESS, SEEK_END, SEEK_SET,
  CLOCKS_PER_SEC, errno], [], AC_MSG_ERROR([GLibC package is found but some \
declarations of this package are not found. Update the GLibC developing \
package.]), [[#include <stdlib.h>
#include <stdio.h>
#include <time.h>
#include <errno.h>]])
AC_CHECK_DECLS([PNG_LIBPNG_VER_STRING, PNG_INFO_tRNS, PNG_COLOR_TYPE_GRAY,
  PNG_COLOR_TYPE_PALETTE, PNG_COLOR_TYPE_GRAY_ALPHA, PNG_COLOR_MASK_ALPHA,
  png_jmpbuf], [], AC_MSG_ERROR([libPNG package is found but some \
declarations of this package are not found. Update the libPNG developing \
package.]), [[#include <png.h>]])
AC_CHECK_DECLS([GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_TEXTURE_WRAP_T,
  GL_TEXTURE_MAG_FILTER, GL_NEAREST, GL_TEXTURE_MIN_FILTER, GL_NO_ERROR,
  GL_FALSE, GL_COMPILE_STATUS, GL_TRUE, GL_INFO_LOG_LENGTH, GL_VERTEX_SHADER,
  GL_FRAGMENT_SHADER, GL_LINK_STATUS, GL_ARRAY_BUFFER, GL_STATIC_DRAW,
  GL_FLOAT, GL_COLOR_BUFFER_BIT, GL_DEPTH_BUFFER_BIT, GL_TRIANGLE_STRIP,
  GL_RGBA, GL_RGB, GL_UNSIGNED_BYTE, GL_CLAMP_TO_BORDER, GL_BLEND,
  GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA], [], AC_MSG_ERROR([GL package is \
found but some declarations of this package are not found. Update the GL \
developing package.]), [[#include <GL/gl.h>]])
AC_CHECK_DECL(glewExperimental, [], AC_MSG_ERROR([GLEW package is \
found but some declarations of this package are not found. Update the GLEW \
developing package.]), [[#include <GL/glew.h>]])
AC_CHECK_DECLS([GLX_WINDOW_BIT, GLX_RGBA_BIT, GLX_TRUE_COLOR,
  GLX_X_RENDERABLE, GLX_DRAWABLE_TYPE, GLX_RENDER_TYPE, GLX_X_VISUAL_TYPE,
  GLX_RED_SIZE, GLX_GREEN_SIZE, GLX_BLUE_SIZE, GLX_ALPHA_SIZE, GLX_DEPTH_SIZE,
  GLX_STENCIL_SIZE, GLX_DOUBLEBUFFER, GLX_SAMPLE_BUFFERS, GLX_SAMPLES,
  GLX_CONTEXT_MAJOR_VERSION_ARB, GLX_CONTEXT_MINOR_VERSION_ARB], [],
AC_MSG_ERROR([GLX package is found but some declarations of this package are \
not found. Update the GLX developing package.]), [[#include <GL/glx.h>]])
AC_CHECK_DECLS([XA_ATOM, True, False, None, CWBorderPixel, CWColormap,
  CWEventMask, InputHint, StateHint, BlackPixel, WhitePixel, InputOutput,
  NormalState, AllocNone, StructureNotifyMask, PropModeReplace, DefaultScreen,
  RootWindow, ExposureMask, KeyPressMask], [], AC_MSG_ERROR([X11 package is \
found but some declarations of this package are not found. Update the X11 \
developing package.]), [[#include <X11/Xutil.h>
#include <X11/Xatom.h>]])

# Checks for library functions.
AC_FUNC_MALLOC
AC_CHECK_FUNCS([strchr strerror strstr strlen strcmp getenv usleep memcpy \
printf fprintf free srand rand atof atoi time clock abort fopen fseek fread \
fclose setjmp], [], AC_MSG_ERROR([GLibC package is found but some functions \
of this package are not found. Update the GLibC developing package.]))
AC_CHECK_FUNCS([png_destroy_read_struct png_create_read_struct \
png_create_info_struct png_init_io png_read_info png_get_IHDR \
png_get_valid png_set_expand png_set_strip_16 png_set_gray_to_rgb \
png_read_update_info png_get_rowbytes png_read_image], [],
  AC_MSG_ERROR([libPNG package is found but some functions of this package \
are not found. Update the libPNG developing package.]))
AC_CHECK_FUNCS([glEnable glBlendFunc glDeleteProgram glUseProgram glViewport \
glDisableVertexAttribArray glDeleteBuffers glDeleteVertexArrays \
glDeleteTextures glGetError glUniform1fv glUniform3i glCreateShader \
glShaderSource glCompileShader glGetShaderiv glGetShaderInfoLog \
glDeleteShader glAttachShader glLinkProgram glGetProgramiv glValidateProgram \
glDetachShader glGetUniformLocation glGenVertexArrays glBindVertexArray \
glGenBuffers glBindBuffer glBufferData glEnableVertexAttribArray \
glVertexAttribPointer glClearColor glClear glDrawArrays glGenTextures \
glBindTexture glTexImage2D glTexParameteri], [], AC_MSG_ERROR([GL \
package is found but some functions of this package are not found. Update \
the GL developing package.]))
AC_CHECK_FUNC(glewInit, [], AC_MSG_ERROR([GLEW package is found but some \
functions of this package are not found. Update the GLEW developing \
package.]))
AC_CHECK_FUNCS([glXQueryVersion glXChooseFBConfig glXGetVisualFromFBConfig \
glXGetFBConfigAttrib glXQueryExtensionsString glXGetProcAddressARB \
glXCreateContextAttribsARB glXMakeCurrent glXDestroyContext glXSwapBuffers],
  [], AC_MSG_ERROR([GLX package is found but some functions of this package \
are not found. Update the GLX developing package.]))
AC_CHECK_FUNCS([XOpenDisplay XCloseDisplay XFree XCreateColormap \
XAllocWMHints XSetWMProperties XInternAtom XChangeProperty XMapWindow \
XGetWindowAttributes XCreateWindow XSetErrorHandler XSync XDestroyWindow \
XFreeColormap XSelectInput XCreateSimpleWindow XCheckMaskEvent], [],
AC_MSG_ERROR([X11 package is found but some functions of this package are \
not found. Update the X11 developing package.]))

AC_OUTPUT
