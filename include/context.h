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

bool isExtensionSupported(const char* extList, const char* extension,
  bool verbose);
int contextErrorHandler(Display* display, XErrorEvent* event);
bool queryingGlxVersion(Context* context, bool verbose);
bool searchingBestFbc(Context* context, XVisualInfo** vi,
  GLXFBConfig* bestFbc, bool verbose);
bool initWindow(Context* context, XVisualInfo** vi, bool verbose);
bool initDebugWindow(Context* context, bool verbose);
void freeContext(Context* context, bool verbose);
void freeDebugContext(Context* context, bool verbose);
bool initContext(Context* context, bool verbose);

#endif
