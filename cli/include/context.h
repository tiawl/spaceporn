#ifndef SPACEPORN_CONTEXT_H
#define SPACEPORN_CONTEXT_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <X11/Xatom.h>

#include "util.h"

#define GLX_CONTEXT_MAJOR_VERSION_ARB       0x2091
#define GLX_CONTEXT_MINOR_VERSION_ARB       0x2092

typedef struct
{
  Display* display;
  GLXContext glx_context;
  Window window;
#if DEV
  Window debug_window;
  XEvent event;
#endif
  XWindowAttributes window_attribs;
  XVisualInfo* visual_info;
  Colormap cmap;
} Context;

typedef GLXContext (*glXCreateContextAttribsARBProc)(Display*, GLXFBConfig,
  GLXContext, Bool, const int*);

bool isExtensionSupported(const char* extList, const char* extension,
  Log* log);
int contextErrorHandler();
bool queryingGlxVersion(Context* context, Log* log);
bool searchingBestFbc(Context* context, GLXFBConfig* bestFbc, Log* log);
bool initWindow(Context* context, Log* log);
bool initDebugWindow(Context* context, Log* log);
bool initContext(Context* context, Log* log);
void freeContext(Context* context, Log* log);

#endif
