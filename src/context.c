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

bool initContext(ContextBuilder* builder, bool verbose)
{
  VERB(verbose, printf("Opening X Display ...\n"));
  builder->display = XOpenDisplay(NULL);

  if (!builder->display)
  {
    fprintf(stderr, "Failed to open X display\n");
    return false;
  }
  VERB(verbose, printf("X Display opened\n"));

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
  VERB(verbose, printf("Querying GLX version ...\n"));
  if (!glXQueryVersion(builder->display, &glx_major, &glx_minor) ||
    ((glx_major == 1) && (glx_minor < 3)) || (glx_major < 1))
  {
    fprintf(stderr, "Invalid GLX version\n");
    XCloseDisplay(builder->display);
    return false;;
  }
  VERB(verbose, printf("Valid GLX version: %d.%d\n", glx_major, glx_minor));

  int fbcount;
  VERB(verbose, printf("Querying GLX framebuffer config ...\n"));
  GLXFBConfig* fbc = glXChooseFBConfig(builder->display,
    DefaultScreen(builder->display), visual_attribs, &fbcount);

  if (!fbc)
  {
    fprintf(stderr, "Failed to retrieve a GLX framebuffer config\n");
    XCloseDisplay(builder->display);
    return false;
  }
  VERB(verbose, printf("GLX framebuffer config found\n"));

  // Pick the FB config/visual with the most samples per pixel
  int best_fbc = -1;
  int worst_fbc = -1;
  int best_num_samp = -1;
  int worst_num_samp = 999;

  for (int i = 0; i < fbcount; ++i)
  {
    VERB(verbose, printf("Searching GLX framebuffer visual with the most \
samples per pixel ... %d/%d\n", i, fbcount));
    VERB(verbose, printf("Querying visual from GLX framebuffer config \
... \n"));
    XVisualInfo* vi = glXGetVisualFromFBConfig(builder->display, fbc[i]);
    if (vi)
    {
      VERB(verbose, printf("Corresponding visual found\n"));

      int samp_buf, samples;

      VERB(verbose, printf("Querying GLX_SAMPLE_BUFFERS attribute ...\n"));
      glXGetFBConfigAttrib(builder->display, fbc[i],
        GLX_SAMPLE_BUFFERS, &samp_buf);
      VERB(verbose, printf("Current visual GLX_SAMPLE_BUFFERS value: %d\n",
        samp_buf));

      VERB(verbose, printf("Querying GLX_SAMPLES attribute ...\n"));
      glXGetFBConfigAttrib(builder->display, fbc[i], GLX_SAMPLES, &samples);
      VERB(verbose, printf("Current visual GLX_SAMPLES value: %d\n", samples));

      if ((best_fbc < 0) || (samp_buf && (samples > best_num_samp)))
      {
        VERB(verbose, printf("Setting best GLX framebuffer config ...\n"));
        best_fbc = i;
        best_num_samp = samples;
        VERB(verbose, printf("Current best GLX framebuffer config index \
is: %d\n", best_fbc));
        VERB(verbose, printf("Current best GLX_SAMPLES value is: %d\n",
          best_num_samp));
      }
      if ((worst_fbc < 0) || (!samp_buf || (samples < worst_num_samp)))
      {
        VERB(verbose, printf("Setting worst GLX framebuffer config ...\n"));
        worst_fbc = i;
        worst_num_samp = samples;
        VERB(verbose, printf("Current worst GLX framebuffer config index \
is: %d\n", worst_fbc));
        VERB(verbose, printf("Current worst GLX_SAMPLES value is: %d\n",
          worst_num_samp));
      }
    }
    VERB(verbose, printf("Freeing current visual ...\n"));
    XFree(vi);
    VERB(verbose, printf("Current visual freed\n"));
  }

  GLXFBConfig bestFbc = fbc[best_fbc];
  VERB(verbose, printf("Searching GLX framebuffer visual with the most \
samples per pixel ... %d/%d\n", fbcount, fbcount));
  VERB(verbose, printf("Best GLX framebuffer config index: %d\n", best_fbc));

  VERB(verbose, printf("Freeing GLX framebuffer config ...\n"));
  XFree(fbc);
  VERB(verbose, printf("GLX framebuffer config freed\n"));

  VERB(verbose, printf("Querying visual from best GLX framebuffer config \
... \n"));
  XVisualInfo* vi = glXGetVisualFromFBConfig(builder->display, bestFbc);
  VERB(verbose, printf("Corresponding visual found\n"));

  VERB(verbose, printf("Searching X root window from visual's screen ...\n"));
  Window root = RootWindow(builder->display, vi->screen);
  VERB(verbose, printf("X root window: 0x%lx\n", root));

  XSetWindowAttributes swa;

  VERB(verbose, printf("Creating color map from visual and root window ...\n"));
  swa.colormap = builder->cmap = XCreateColormap(builder->display, root,
    vi->visual, AllocNone);
  VERB(verbose, printf("Color map created\n"));

  swa.background_pixmap = None;
  swa.border_pixel      = 0;
  swa.event_mask        = StructureNotifyMask;
  VERB(verbose, printf("XSetWindowAttributes structure initialized\n"));

  VERB(verbose, printf("Querying root window attributes ...\n"));
  XGetWindowAttributes(builder->display, root, &(builder->window_attribs));
  VERB(verbose, printf("Root window dimensions are: %ux%u\n",
    builder->window_attribs.width, builder->window_attribs.height));

  VERB(verbose, printf("Creating new window ...\n"));
  builder->window = XCreateWindow(builder->display, root,
    builder->window_attribs.x, builder->window_attribs.y,
    builder->window_attribs.width, builder->window_attribs.height, 0,
    vi->depth, InputOutput, vi->visual,
    CWBorderPixel | CWColormap | CWEventMask, &swa);

  if (!builder->window)
  {
    fprintf(stderr, "Failed to create window\n");
    XFree(vi);
    XCloseDisplay(builder->display);
    return false;
  }
  VERB(verbose, printf("Window created: 0x%lx\n", builder->window));

  XWMHints* wmHint = XAllocWMHints();
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
    fprintf(stderr, "glXCreateContextAttribsARB() not found\n");
    XCloseDisplay(builder->display);
    return false;
  } else {
    int context_attribs[] =
    {
      GLX_CONTEXT_MAJOR_VERSION_ARB, 3,
      GLX_CONTEXT_MINOR_VERSION_ARB, 3,
      None
    };

    builder->context = glXCreateContextAttribsARB(builder->display, bestFbc, 0,
      True, context_attribs);
  }

  // Sync to ensure any errors generated are processed.
  XSync(builder->display, False);

  // Restore the original error handler
  XSetErrorHandler(oldHandler);

  if (contextErrorOccurred || !builder->context)
  {
    XCloseDisplay(builder->display);
    return false;
  }

  glXMakeCurrent(builder->display, builder->window, builder->context);

  return true;
}

void hideCursor(ContextBuilder* builder)
{
  XColor black;
  black.red = black.green = black.blue = 0;
  static char noData[] =
  {
    0, 0, 0, 0, 0, 0, 0, 0
  };

  Pixmap bitmapNoData =
    XCreateBitmapFromData(builder->display, builder->window, noData, 8, 8);
  Cursor invisibleCursor = XCreatePixmapCursor(builder->display, bitmapNoData,
    bitmapNoData, &black, &black, 0, 0);

  XDefineCursor(builder->display, builder->window, invisibleCursor);

  XFreeCursor(builder->display, invisibleCursor);
  XFreePixmap(builder->display, bitmapNoData);
}

void getCursor(ContextBuilder* builder, int* cursor_x, int* cursor_y)
{
  Window dummy;
  int x;
  int y;
  unsigned int mask_return;

  XQueryPointer(builder->display, builder->window, &dummy, &dummy, cursor_x,
    cursor_y, &x, &y, &mask_return);
}
