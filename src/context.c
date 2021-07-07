#include "context.h"

// Helper to check for extension string presence.  Adapted from:
//   http://www.opengl.org/resources/features/OGLextensions/
bool isExtensionSupported(const char* extList, const char* extension,
  bool verbose)
{
  const char* start;
  const char* where;
  const char* terminator;

  /* Extension names should not have spaces. */
  VERB(verbose, printf("    Testing presence of space in OpenGL extension \
string ...\n"));
  where = strchr(extension, ' ');
  if (where || (*extension == '\0'))
  {
    VERB(verbose, printf("    Space in this OpenGL extension name: %s\n",
      extension));
    return false;
  }
  VERB(verbose, printf("    No space in OpenGL extension name\n"));

  /* It takes a bit of care to be fool-proof about parsing the
     OpenGL extensions string. Don't be fooled by sub-strings,
     etc. */
  VERB(verbose, printf("    Parsing OpenGL extensions string ...\n"));
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
  VERB(verbose, printf("  Opening X Display ...\n"));
  builder->display = XOpenDisplay(NULL);

  if (!builder->display)
  {
    fprintf(stderr, "Failed to open X display\n");
    return false;
  }
  VERB(verbose, printf("  X Display opened\n"));

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
  VERB(verbose, printf("  Querying GLX version ...\n"));
  if (!glXQueryVersion(builder->display, &glx_major, &glx_minor) ||
    ((glx_major == 1) && (glx_minor < 3)) || (glx_major < 1))
  {
    fprintf(stderr, "Invalid GLX version\n");

    VERB(verbose, printf("  Closing display ...\n"));
    XCloseDisplay(builder->display);
    VERB(verbose, printf("  Display closed\n"));

    return false;
  }
  VERB(verbose, printf("  Valid GLX version: %d.%d\n", glx_major, glx_minor));

  int fbcount;
  VERB(verbose, printf("  Querying GLX framebuffer config ...\n"));
  GLXFBConfig* fbc = glXChooseFBConfig(builder->display,
    DefaultScreen(builder->display), visual_attribs, &fbcount);

  if (!fbc)
  {
    fprintf(stderr, "Failed to found a GLX framebuffer config\n");

    VERB(verbose, printf("  Closing display ...\n"));
    XCloseDisplay(builder->display);
    VERB(verbose, printf("  Display closed\n"));

    return false;
  }
  VERB(verbose, printf("  GLX framebuffer config found\n"));

  // Pick the FB config/visual with the most samples per pixel
  int best_fbc = -1;
  int worst_fbc = -1;
  int best_num_samp = -1;
  int worst_num_samp = 999;

  for (int i = 0; i < fbcount; ++i)
  {
    VERB(verbose, printf("  Searching GLX framebuffer visual with the most \
samples per pixel ... %d/%d\n", i, fbcount));
    VERB(verbose, printf("  Querying visual from GLX framebuffer config \
... \n"));
    XVisualInfo* vi = glXGetVisualFromFBConfig(builder->display, fbc[i]);
    if (vi)
    {
      VERB(verbose, printf("  Corresponding visual found\n"));

      int samp_buf, samples;

      VERB(verbose, printf("  Querying GLX_SAMPLE_BUFFERS attribute ...\n"));
      glXGetFBConfigAttrib(builder->display, fbc[i],
        GLX_SAMPLE_BUFFERS, &samp_buf);
      VERB(verbose, printf("  Current visual GLX_SAMPLE_BUFFERS value: %d\n",
        samp_buf));

      VERB(verbose, printf("  Querying GLX_SAMPLES attribute ...\n"));
      glXGetFBConfigAttrib(builder->display, fbc[i], GLX_SAMPLES, &samples);
      VERB(verbose, printf("  Current visual GLX_SAMPLES value: %d\n",
        samples));

      if ((best_fbc < 0) || (samp_buf && (samples > best_num_samp)))
      {
        VERB(verbose, printf("  Setting best GLX framebuffer config ...\n"));
        best_fbc = i;
        best_num_samp = samples;
        VERB(verbose, printf("  Current best GLX framebuffer config index \
is: %d\n", best_fbc));
        VERB(verbose, printf("  Current best GLX_SAMPLES value is: %d\n",
          best_num_samp));
      }
      if ((worst_fbc < 0) || (!samp_buf || (samples < worst_num_samp)))
      {
        VERB(verbose, printf("  Setting worst GLX framebuffer config ...\n"));
        worst_fbc = i;
        worst_num_samp = samples;
        VERB(verbose, printf("  Current worst GLX framebuffer config index \
is: %d\n", worst_fbc));
        VERB(verbose, printf("  Current worst GLX_SAMPLES value is: %d\n",
          worst_num_samp));
      }
    }
    VERB(verbose, printf("  Freeing current visual ...\n"));
    XFree(vi);
    VERB(verbose, printf("  Current visual freed\n"));
  }

  GLXFBConfig bestFbc = fbc[best_fbc];
  VERB(verbose, printf("  Searching GLX framebuffer visual with the most \
samples per pixel ... %d/%d\n", fbcount, fbcount));
  VERB(verbose, printf("  Best GLX framebuffer config index: %d\n",
    best_fbc));

  VERB(verbose, printf("  Freeing GLX framebuffer config ...\n"));
  XFree(fbc);
  VERB(verbose, printf("  GLX framebuffer config freed\n"));

  VERB(verbose, printf("  Querying visual from best GLX framebuffer config \
... \n"));
  XVisualInfo* vi = glXGetVisualFromFBConfig(builder->display, bestFbc);
  VERB(verbose, printf("  Corresponding visual found\n"));

  VERB(verbose, printf("  Searching X root window from visual's screen \
...\n"));
  Window root = RootWindow(builder->display, vi->screen);
  VERB(verbose, printf("  X root window: 0x%lx\n", root));

  XSetWindowAttributes swa;

  VERB(verbose, printf("  Creating color map from visual and root window \
...\n"));
  swa.colormap = builder->cmap = XCreateColormap(builder->display, root,
    vi->visual, AllocNone);
  VERB(verbose, printf("  Color map created\n"));

  swa.background_pixmap = None;
  swa.border_pixel      = 0;
  swa.event_mask        = StructureNotifyMask;
  VERB(verbose, printf("  XSetWindowAttributes structure initialized\n"));

  VERB(verbose, printf("  Querying root window attributes ...\n"));
  XGetWindowAttributes(builder->display, root, &(builder->window_attribs));
  VERB(verbose, printf("  Root window dimensions are: %ux%u\n",
    builder->window_attribs.width, builder->window_attribs.height));

  VERB(verbose, printf("  Creating new window ...\n"));
  builder->window = XCreateWindow(builder->display, root,
    builder->window_attribs.x, builder->window_attribs.y,
    builder->window_attribs.width, builder->window_attribs.height, 0,
    vi->depth, InputOutput, vi->visual,
    CWBorderPixel | CWColormap | CWEventMask, &swa);

  if (!builder->window)
  {
    fprintf(stderr, "Failed to create window\n");

    VERB(verbose, printf("  Freeing current visual ...\n"));
    XFree(vi);
    VERB(verbose, printf("  Current visual freed\n"));

    VERB(verbose, printf("  Closing Display ...\n"));
    XCloseDisplay(builder->display);
    VERB(verbose, printf("  Display closed\n"));

    return false;
  }
  VERB(verbose, printf("  Window created: 0x%lx\n", builder->window));

  VERB(verbose, printf("  Allocating window manager hints ...\n"));
  XWMHints* wmHint = XAllocWMHints();
  VERB(verbose, printf("  Window manager hints allocated\n"));

  wmHint->flags = InputHint | StateHint;
  wmHint->input = false;
  wmHint->initial_state = NormalState;
  VERB(verbose, printf("  Window manager hints declared\n"));

  VERB(verbose, printf("  Setting window manager properties ...\n"));
  XSetWMProperties(builder->display, builder->window, NULL, NULL,
    NULL, 0, NULL, wmHint, NULL);
  VERB(verbose, printf("  Window manager properties set\n"));

  VERB(verbose, printf("  Querying _NET_WM_WINDOW_TYPE atom identifier \
...\n"));
  Atom xa = XInternAtom(builder->display, "_NET_WM_WINDOW_TYPE", False);
  VERB(verbose, printf("  _NET_WM_WINDOW_TYPE atom identifier found\n"));

  VERB(verbose, printf("  Querying _NET_WM_WINDOW_TYPE_DESKTOP atom \
identifier ...\n"));
  Atom prop =
    XInternAtom(builder->display, "_NET_WM_WINDOW_TYPE_DESKTOP", False);
  VERB(verbose, printf("  _NET_WM_WINDOW_TYPE_DESKTOP atom identifier \
found\n"));

  VERB(verbose, printf("  Discarding _NET_WM_WINDOW_TYPE property value and \
storing the new _NET_WM_WINDOW_TYPE_DESKTOP ...\n"));
  XChangeProperty(builder->display, builder->window, xa, XA_ATOM, 32,
    PropModeReplace, (unsigned char *)&prop, 1);
  VERB(verbose, printf("  _NET_WM_WINDOW_TYPE discarded and \
_NET_WM_WINDOW_TYPE_DESKTOP stored\n"));

  VERB(verbose, printf("  Freeing window manager hints ...\n"));
  XFree(wmHint);
  VERB(verbose, printf("  Window manager hints freed\n"));

  VERB(verbose, printf("  Freeing current visual ...\n"));
  XFree(vi);
  VERB(verbose, printf("  Current visual freed\n"));

  VERB(verbose, printf("  Mapping the newly created window ...\n"));
  XMapWindow(builder->display, builder->window);
  VERB(verbose, printf("  Newly created window mapped\n"));

  VERB(verbose, printf("  Querying the default screen's GLX extensions list \
...\n"));
  const char* glxExts = glXQueryExtensionsString(builder->display,
    DefaultScreen(builder->display));
  VERB(verbose, printf("  Default screen's GLX extensions list is: %s\n",
    glxExts));

  VERB(verbose, printf("  Querying pointer to glXCreateContextAttribsARB() \
function ...\n"));
  glXCreateContextAttribsARBProc glXCreateContextAttribsARB = 0;
  glXCreateContextAttribsARB = (glXCreateContextAttribsARBProc)
    glXGetProcAddressARB((const GLubyte *) "glXCreateContextAttribsARB");
  VERB(verbose, printf("  Pointer to glXCreateContextAttribsARB() \
function found\n"));

  VERB(verbose, printf("  Installing X error handler ...\n"));
  contextErrorOccurred = false;
  int (*oldHandler)(Display*, XErrorEvent*) =
    XSetErrorHandler(&contextErrorHandler);
  VERB(verbose, printf("  X error handler installed\n"));

  VERB(verbose, printf("  Testing extension support ...\n"));
  if (!isExtensionSupported(glxExts, "GLX_ARB_create_context", verbose) ||
    !glXCreateContextAttribsARB)
  {
    fprintf(stderr, "glXCreateContextAttribsARB() not found\n");

    VERB(verbose, printf("  Closing Display ...\n"));
    XCloseDisplay(builder->display);
    VERB(verbose, printf("  Display closed\n"));

    return false;
  } else {
    VERB(verbose, printf("  Extension supported\n"));
    int context_attribs[] =
    {
      GLX_CONTEXT_MAJOR_VERSION_ARB, 3,
      GLX_CONTEXT_MINOR_VERSION_ARB, 3,
      None
    };

    VERB(verbose, printf("  Initializing the context to the initial state \
defined by the OpenGL specification ...\n"));
    builder->context = glXCreateContextAttribsARB(builder->display, bestFbc,
      0, True, context_attribs);
    VERB(verbose, printf("  Context initialized to the initial state defined \
by the OpenGL specification\n"));
  }

  // Sync to ensure any errors generated are processed.
  VERB(verbose, printf("  Synchronizing generated errors ... \n"));
  XSync(builder->display, False);
  VERB(verbose, printf("  Generated errors synchronized\n"));

  VERB(verbose, printf("  Restoring original error handler ...\n"));
  XSetErrorHandler(oldHandler);
  VERB(verbose, printf("  Original error handler restored\n"));

  VERB(verbose, printf("  Testing error generation during context \
creation ...\n"));
  if (contextErrorOccurred || !builder->context)
  {
    fprintf(stderr, "An error occured during creation context\n");

    VERB(verbose, printf("  Closing Display ...\n"));
    XCloseDisplay(builder->display);
    VERB(verbose, printf("  Display closed\n"));

    return false;
  }
  VERB(verbose, printf("  No error occured during context creation\n"));

  VERB(verbose, printf("  Attaching the current rendering context to the \
newly created window ...\n"));
  glXMakeCurrent(builder->display, builder->window, builder->context);
  VERB(verbose, printf("  Current rendering context attached to the newly \
created window\n"));

  return true;
}
