AC_PREREQ([2.69])
AC_INIT([xtelesktop], [0.1], [pabtomas@protonmail.com])
AC_CONFIG_SRCDIR([src/xtelesktop.c])

# Checks for programs.
AC_PROG_CC

# Checks for libraries and headers
AC_CHECK_HEADERS([time.h errno.h stdio.h stdlib.h string.h unistd.h string.h], [],
  AC_MSG_ERROR([Some GLibC headers are not found. Install or check the GLibC developing package.]))

AC_CHECK_LIB([png], [png_create_read_struct], [])
AC_CHECK_LIB([GL], [glXCreateContext], [])
AC_CHECK_LIB([GLEW], [glewInit], [])
AC_CHECK_LIB([X11], [XOpenDisplay], [])

AC_CHECK_HEADER([png.h])
AC_CHECK_HEADER([GL/gl.h])
AC_CHECK_HEADER([GL/glx.h])
AC_CHECK_HEADER([GL/glew.h])
AC_CHECK_HEADERS([X11/X.h X11/Xlib.h X11/Xutil.h X11/Xatom.h])

# Checks for typedefs, structures, and compiler characteristics.
AC_CHECK_HEADER_STDBOOL
AC_C_CONST
AC_TYPE_SIZE_T
AC_TYPE_UINT8_T

# Checks for library functions.
AC_FUNC_MALLOC
AC_CHECK_FUNCS([strchr strerror strstr strlen strcmp getenv usleep memcpy printf fprintf free srand rand atof atoi time clock abort fopen fseek fread fclose])

AC_OUTPUT
