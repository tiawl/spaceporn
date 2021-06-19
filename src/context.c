#include "context.h"

// Helper to check for extension string presence.  Adapted from:
//   http://www.opengl.org/resources/features/OGLextensions/
bool isExtensionSupported(const char* extList, const char* extension)
{
  const char* start;
  const char* where;
  const char* terminator;

  /* Extension names should not have spaces. */
  where = strchr(extension, ' ');
  if (where || (*extension == '\0'))
  {
    return false;
  }

  /* It takes a bit of care to be fool-proof about parsing the
     OpenGL extensions string. Don't be fooled by sub-strings,
     etc. */
  for (start = extList;;)
  {
    where = strstr(start, extension);

    if (!where)
    {
      break;
    }

    terminator = where + strlen(extension);

    if ((where == start) || (*(where - 1) == ' '))
    {
      if ((*terminator == ' ') || (*terminator == '\0'))
      {
        return true;
      }
    }

    start = terminator;
  }

  return false;
}

static bool contextErrorOccurred = false;
int contextErrorHandler(Display* display, XErrorEvent* event)
{
  contextErrorOccurred = true;
  return 0;
}

void initContext(ContextBuilder* builder)
{
  builder->display = XOpenDisplay(NULL);

  if (!builder->display)
  {
    printf("Failed to open X display\n");
    exit(EXIT_FAILURE);
  }

  // Get a matching FB config
  int visual_attribs[] =
    {
      GLX_X_RENDERABLE    , True,
      GLX_DRAWABLE_TYPE   , GLX_WINDOW_BIT,
      GLX_RENDER_TYPE     , GLX_RGBA_BIT,
      GLX_X_VISUAL_TYPE   , GLX_TRUE_COLOR,
      GLX_RED_SIZE        , 8,
      GLX_GREEN_SIZE      , 8,
      GLX_BLUE_SIZE       , 8,
      GLX_ALPHA_SIZE      , 8,
      GLX_DEPTH_SIZE      , 24,
      GLX_STENCIL_SIZE    , 8,
      GLX_DOUBLEBUFFER    , True,
      None
    };

  int glx_major;
  int glx_minor;

  // FBConfigs were added in GLX version 1.3.
  if (!glXQueryVersion(builder->display, &glx_major, &glx_minor) ||
    ((glx_major == 1) && (glx_minor < 3)) || (glx_major < 1))
  {
    printf("Invalid GLX version");
    exit(EXIT_FAILURE);
  }

  int fbcount;
  GLXFBConfig* fbc = glXChooseFBConfig(builder->display,
                                       DefaultScreen(builder->display),
                                       visual_attribs, &fbcount);
  if (!fbc)
  {
    printf("Failed to retrieve a framebuffer config\n");
    exit(EXIT_FAILURE);
  }

  // Pick the FB config/visual with the most samples per pixel
  int best_fbc = -1;
  int worst_fbc = -1;
  int best_num_samp = -1;
  int worst_num_samp = 999;

  for (int i = 0; i < fbcount; ++i)
  {
    XVisualInfo *vi = glXGetVisualFromFBConfig(builder->display, fbc[i]);
    if (vi)
    {
      int samp_buf, samples;
      glXGetFBConfigAttrib(builder->display, fbc[i],
                           GLX_SAMPLE_BUFFERS, &samp_buf);
      glXGetFBConfigAttrib(builder->display, fbc[i], GLX_SAMPLES, &samples);

      if ((best_fbc < 0) || (samp_buf && (samples > best_num_samp)))
      {
        best_fbc = i;
        best_num_samp = samples;
      }
      if ((worst_fbc < 0) || (!samp_buf || (samples < worst_num_samp)))
      {
        worst_fbc = i;
        worst_num_samp = samples;
      }
    }
    XFree(vi);
  }

  GLXFBConfig bestFbc = fbc[best_fbc];

  XFree(fbc);

  XVisualInfo *vi = glXGetVisualFromFBConfig(builder->display, bestFbc);
  Window root = RootWindow(builder->display, vi->screen);

  XSetWindowAttributes swa;
  swa.colormap = builder->cmap = XCreateColormap(builder->display, root,
                                                 vi->visual, AllocNone);
  swa.background_pixmap = None;
  swa.border_pixel      = 0;
  swa.event_mask        = StructureNotifyMask;

  XGetWindowAttributes(builder->display, root, &(builder->window_attribs));

  builder->window = XCreateWindow(builder->display, root,
                                  builder->window_attribs.x,
                                  builder->window_attribs.y,
                                  builder->window_attribs.width,
                                  builder->window_attribs.height, 0,
                                  vi->depth, InputOutput, vi->visual,
                                  CWBorderPixel | CWColormap | CWEventMask,
                                  &swa);

  if (!builder->window)
  {
    printf("Failed to create window.\n");
    exit(EXIT_FAILURE);
  }

  XWMHints *wmHint = XAllocWMHints();
  wmHint->flags = InputHint | StateHint;
  wmHint->input = false;
  wmHint->initial_state = NormalState;
  XSetWMProperties(builder->display, builder->window, NULL, NULL,
                   NULL, 0, NULL, wmHint, NULL);

  Atom xa = XInternAtom(builder->display, "_NET_WM_WINDOW_TYPE", False);
  Atom prop =
    XInternAtom(builder->display, "_NET_WM_WINDOW_TYPE_DESKTOP", False);

  XChangeProperty(builder->display, builder->window, xa, XA_ATOM, 32,
                  PropModeReplace, (unsigned char *)&prop, 1);

  XFree(wmHint);
  XFree(vi);

  XMapWindow(builder->display, builder->window);

  // Get the default screen's GLX extension list
  const char *glxExts =
    glXQueryExtensionsString(builder->display, DefaultScreen(builder->display));

  // NOTE: It is not necessary to create or make current to a context before
  // calling glXGetProcAddressARB
  glXCreateContextAttribsARBProc glXCreateContextAttribsARB = 0;
  glXCreateContextAttribsARB = (glXCreateContextAttribsARBProc)
    glXGetProcAddressARB((const GLubyte *) "glXCreateContextAttribsARB");

  // Install an X error handler so the application won't exit if GL 3.3
  // context allocation fails.
  //
  // Note this error handler is global.  All display connections in all threads
  // of a process use the same error handler, so be sure to guard against other
  // threads issuing X commands while this code is running.
  contextErrorOccurred = false;
  int (*oldHandler)(Display*, XErrorEvent*) =
    XSetErrorHandler(&contextErrorHandler);

  if (!isExtensionSupported(glxExts, "GLX_ARB_create_context") ||
    !glXCreateContextAttribsARB)
  {
    printf("glXCreateContextAttribsARB() not found"
           " ... using old-style GLX context\n");
    builder->context =
      glXCreateNewContext(builder->display, bestFbc, GLX_RGBA_TYPE, 0, True);
  } else {
    int context_attribs[] =
      {
        GLX_CONTEXT_MAJOR_VERSION_ARB, 3,
        GLX_CONTEXT_MINOR_VERSION_ARB, 3,
        None
      };

    builder->context = glXCreateContextAttribsARB(builder->display, bestFbc, 0,
                                                  True, context_attribs);

    // Sync to ensure any errors generated are processed.
    XSync(builder->display, False);
    if (contextErrorOccurred || !builder->context)
    {
      context_attribs[1] = 1;
      context_attribs[3] = 0;

      contextErrorOccurred = false;

      printf("Failed to create GL 3.3 context"
             " ... using old-style GLX context\n");
      builder->context = glXCreateContextAttribsARB(builder->display, bestFbc,
                                                    0, True, context_attribs);
    }
  }

  // Sync to ensure any errors generated are processed.
  XSync(builder->display, False);

  // Restore the original error handler
  XSetErrorHandler(oldHandler);

  if (contextErrorOccurred || !builder->context)
  {
    printf("Failed to create an OpenGL context\n");
    exit(EXIT_FAILURE);
  }

  glXMakeCurrent(builder->display, builder->window, builder->context);
}
