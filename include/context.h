#ifndef GLX_CONTEXT
#define GLX_CONTEXT

#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <X11/Xatom.h>
#include <GL/glx.h>

#define GLX_CONTEXT_MAJOR_VERSION_ARB       0x2091
#define GLX_CONTEXT_MINOR_VERSION_ARB       0x2092

typedef GLXContext (*glXCreateContextAttribsARBProc)(Display*, GLXFBConfig,
  GLXContext, Bool, const int*);

typedef struct
{
  Display *display;
  GLXContext context;
  Window window;
  XWindowAttributes window_attribs;
  Colormap cmap;
} ContextBuilder;

bool isExtensionSupported(const char* extList, const char* extension);
int contextErrorHandler(Display* display, XErrorEvent* event);
bool initContext(ContextBuilder* builder);

#endif
