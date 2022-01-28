#ifndef SPACEPORN_CONTEXT_H
#define SPACEPORN_CONTEXT_H

#include <stdio.h>
#include <stdlib.h>
#include <X11/Xatom.h>

#include "util.h"

typedef struct
{
  GLFWwindow* window;
  int width;
  int height;
} Context;

bool initWindow(Context* context, Log* log);
bool initContext(Context* context, Log* log);
void freeContext(Context* context, Log* log);

#endif
