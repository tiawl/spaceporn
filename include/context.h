#ifndef XTELESKTOP_CONTEXT_H
#define XTELESKTOP_CONTEXT_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <X11/Xatom.h>

#include "util.h"

#define GLX_CONTEXT_MAJOR_VERSION_ARB       0x2091
#define GLX_CONTEXT_MINOR_VERSION_ARB       0x2092

typedef GLXContext (*glXCreateContextAttribsARBProc)(Display*, GLXFBConfig,
  GLXContext, Bool, const int*);

typedef struct
{
  Display *display;
  GLXContext context;
  Window window;
#ifdef DEBUG
  Window debug_window;
  XEvent event;
#endif
  XWindowAttributes window_attribs;
  Colormap cmap;
} ContextBuilder;

bool isExtensionSupported(const char* extList, const char* extension,
  bool verbose);
int contextErrorHandler(Display* display, XErrorEvent* event);
bool queryingGlxVersion(ContextBuilder* builder, bool verbose);
bool searchingBestFbc(ContextBuilder* builder, XVisualInfo** vi,
  GLXFBConfig* bestFbc, bool verbose);
bool initWindow(ContextBuilder* builder, XVisualInfo** vi, bool verbose);
bool initDebugWindow(ContextBuilder* builder, bool verbose);
void freeContext(ContextBuilder* builder, bool verbose);
void freeDebugContext(ContextBuilder* builder, bool verbose);
bool initContext(ContextBuilder* builder, bool verbose);

#endif
