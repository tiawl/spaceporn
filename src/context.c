#include "context.h"

// Helper to check for extension string presence.  Adapted from:
//   http://www.opengl.org/resources/features/OGLextensions/
bool isExtensionSupported(const char* extList, const char* extension,
  bool verbose, enum Roadmap roadmap)
{
  const char* start = NULL;
  const char* where = NULL;
  const char* terminator = NULL;

  /* Extension names should not have spaces. */
  VERB(verbose, printf("    Testing presence of space in GLX extension \
string ...\n"));
  where = strchr(extension, ' ');
  if (where || (*extension == '\0') || (roadmap == SPACE_IN_GLX_EXT_RM))
  {
    VERB(verbose, printf("    Space in this GLX extension name: %s\n",
      extension));
    return false;
  }
  VERB(verbose, printf("    No space in GLX extension name\n"));

  /* It takes a bit of care to be fool-proof about parsing the
     GLX extensions string. Don't be fooled by sub-strings, etc. */
  VERB(verbose, printf("    Searching GLX extension in extensions list \
...\n"));
  for (start = extList;;)
  {
    if (roadmap != UNSUPPORTED_GLX_EXT_RM)
    {
      where = strstr(start, extension);
    }

    if (!where)
    {
      VERB(verbose, printf("    GLX extension not found\n"));
      break;
    }

    terminator = where + strlen(extension);

    if ((where == start) || (*(where - 1) == ' '))
    {
      if ((*terminator == ' ') || (*terminator == '\0'))
      {
        VERB(verbose, printf("    GLX extension found\n"));
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

bool queryingGlxVersion(Context* context, bool verbose, enum Roadmap roadmap)
{
  int glx_major;
  int glx_minor;

  // FBConfigs were added in GLX version 1.3.
  VERB(verbose, printf("  Querying GLX version ...\n"));
  if ((!glXQueryVersion(context->display, &glx_major, &glx_minor) ||
    ((glx_major == 1) && (glx_minor < 3)) || (glx_major < 1)) ||
    (roadmap == INVALID_GLX_VERSION_RM))
  {
    fprintf(stderr, "  Invalid GLX version\n");

    VERB(verbose, printf("  Closing display ...\n"));
    XCloseDisplay(context->display);
    VERB(verbose, printf("  Display closed\n"));

    return false;
  }
  VERB(verbose, printf("  Valid GLX version: %d.%d\n", glx_major, glx_minor));

  return true;
}

bool searchingBestFbc(Context* context, XVisualInfo** vi,
  GLXFBConfig* bestFbc, bool verbose, enum Roadmap roadmap)
{
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

  int fbcount;
  VERB(verbose, printf("  Querying GLX framebuffer config ...\n"));
  GLXFBConfig* fbc = NULL;

  if (roadmap != GLXCHOOSEFBCONFIG_FAILED_RM)
  {
    fbc = glXChooseFBConfig(context->display,
      DefaultScreen(context->display), visual_attribs, &fbcount);
  }

  if (!fbc)
  {
    fprintf(stderr, "  Failed to found a GLX framebuffer config\n");

    VERB(verbose, printf("  Closing display ...\n"));
    XCloseDisplay(context->display);
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
    VERB(verbose, printf("    Querying visual from GLX framebuffer config \
... \n"));
    *vi = glXGetVisualFromFBConfig(context->display, fbc[i]);
    if (*vi)
    {
      VERB(verbose, printf("    Corresponding visual found\n"));

      int samp_buf, samples;

      VERB(verbose, printf("    Querying GLX_SAMPLE_BUFFERS attribute \
...\n"));
      glXGetFBConfigAttrib(context->display, fbc[i],
        GLX_SAMPLE_BUFFERS, &samp_buf);
      VERB(verbose, printf("    Current visual GLX_SAMPLE_BUFFERS \
value: %d\n", samp_buf));

      VERB(verbose, printf("    Querying GLX_SAMPLES attribute ...\n"));
      glXGetFBConfigAttrib(context->display, fbc[i], GLX_SAMPLES, &samples);
      VERB(verbose, printf("    Current visual GLX_SAMPLES value: %d\n",
        samples));

      if ((best_fbc < 0) || (samp_buf && (samples > best_num_samp)))
      {
        VERB(verbose, printf("    Setting best GLX framebuffer config \
...\n"));
        best_fbc = i;
        best_num_samp = samples;
        VERB(verbose, printf("    Current best GLX framebuffer config index \
is: %d\n", best_fbc));
        VERB(verbose, printf("    Current best GLX_SAMPLES value is: %d\n",
          best_num_samp));
      }
      if ((worst_fbc < 0) || (!samp_buf || (samples < worst_num_samp)))
      {
        VERB(verbose, printf("    Setting worst GLX framebuffer config \
...\n"));
        worst_fbc = i;
        worst_num_samp = samples;
        VERB(verbose, printf("    Current worst GLX framebuffer config index \
is: %d\n", worst_fbc));
        VERB(verbose, printf("    Current worst GLX_SAMPLES value is: %d\n",
          worst_num_samp));
      }
    }
    VERB(verbose, printf("    Freeing current visual ...\n"));
    XFree(*vi);
    VERB(verbose, printf("    Current visual freed\n"));
  }

  *bestFbc = fbc[best_fbc];
  VERB(verbose, printf("  Searching GLX framebuffer visual with the most \
samples per pixel ... %d/%d\n", fbcount, fbcount));
  VERB(verbose, printf("  Best GLX framebuffer config index: %d\n",
    best_fbc));

  VERB(verbose, printf("  Freeing GLX framebuffer config ...\n"));
  XFree(fbc);
  VERB(verbose, printf("  GLX framebuffer config freed\n"));

  VERB(verbose, printf("  Querying visual from best GLX framebuffer config \
... \n"));
  *vi = glXGetVisualFromFBConfig(context->display, *bestFbc);
  VERB(verbose, printf("  Corresponding visual found\n"));

  return true;
}

bool initWindow(Context* context, XVisualInfo** vi, bool verbose,
  enum Roadmap roadmap)
{
  VERB(verbose, printf("  Searching X root window from visual's screen \
...\n"));
  Window root = RootWindow(context->display, (*vi)->screen);
  VERB(verbose, printf("  X root window: 0x%lx\n", root));

  XSetWindowAttributes swa;

  VERB(verbose, printf("  Creating color map from visual and root window \
...\n"));
  swa.colormap = context->cmap = XCreateColormap(context->display, root,
    (*vi)->visual, AllocNone);
  VERB(verbose, printf("  Color map created\n"));

  swa.background_pixmap = None;
  swa.border_pixel      = 0;
  swa.event_mask        = StructureNotifyMask;
  VERB(verbose, printf("  XSetWindowAttributes structure initialized\n"));

  VERB(verbose, printf("  Querying root window attributes ...\n"));
  XGetWindowAttributes(context->display, root, &(context->window_attribs));
  VERB(verbose, printf("  Root window dimensions are: %ux%u\n",
    context->window_attribs.width, context->window_attribs.height));

  VERB(verbose, printf("  Creating new X window ...\n"));

  if (roadmap != XCREATEWINDOW_FAILED_RM)
  {
    context->window = XCreateWindow(context->display, root,
      context->window_attribs.x, context->window_attribs.y,
      context->window_attribs.width, context->window_attribs.height, 0,
      (*vi)->depth, InputOutput, (*vi)->visual,
      CWBorderPixel | CWColormap | CWEventMask, &swa);
  }

  if (!context->window)
  {
    fprintf(stderr, "  Failed to create X window\n");

    VERB(verbose, printf("  Freeing current visual ...\n"));
    XFree(*vi);
    VERB(verbose, printf("  Current visual freed\n"));

    VERB(verbose, printf("  Freeing colormap ...\n"));
    XFreeColormap(context->display, context->cmap);
    VERB(verbose, printf("  Colormap freed\n"));

    VERB(verbose, printf("  Closing Display ...\n"));
    XCloseDisplay(context->display);
    VERB(verbose, printf("  Display closed\n"));

    return false;
  }
  VERB(verbose, printf("  X Window created: 0x%lx\n", context->window));

  VERB(verbose, printf("  Allocating window manager hints ...\n"));
  XWMHints* wmHint = XAllocWMHints();
  VERB(verbose, printf("  Window manager hints allocated\n"));

  wmHint->flags = InputHint | StateHint;
  wmHint->input = false;
  wmHint->initial_state = NormalState;
  VERB(verbose, printf("  Window manager hints declared\n"));

  VERB(verbose, printf("  Setting window manager properties ...\n"));
  XSetWMProperties(context->display, context->window, NULL, NULL,
    NULL, 0, NULL, wmHint, NULL);
  VERB(verbose, printf("  Window manager properties set\n"));

  VERB(verbose, printf("  Querying _NET_WM_WINDOW_TYPE atom identifier \
...\n"));
  Atom xa = XInternAtom(context->display, "_NET_WM_WINDOW_TYPE", False);
  VERB(verbose, printf("  _NET_WM_WINDOW_TYPE atom identifier found\n"));

  VERB(verbose, printf("  Querying _NET_WM_WINDOW_TYPE_DESKTOP atom \
identifier ...\n"));
  Atom prop =
    XInternAtom(context->display, "_NET_WM_WINDOW_TYPE_DESKTOP", False);
  VERB(verbose, printf("  _NET_WM_WINDOW_TYPE_DESKTOP atom identifier \
found\n"));

  VERB(verbose, printf("  Discarding _NET_WM_WINDOW_TYPE property value and \
storing the new _NET_WM_WINDOW_TYPE_DESKTOP ...\n"));
  XChangeProperty(context->display, context->window, xa, XA_ATOM, 32,
    PropModeReplace, (unsigned char*) &prop, 1);
  VERB(verbose, printf("  _NET_WM_WINDOW_TYPE discarded and \
_NET_WM_WINDOW_TYPE_DESKTOP stored\n"));

  VERB(verbose, printf("  Freeing window manager hints ...\n"));
  XFree(wmHint);
  VERB(verbose, printf("  Window manager hints freed\n"));

  VERB(verbose, printf("  Freeing current visual ...\n"));
  XFree(*vi);
  VERB(verbose, printf("  Current visual freed\n"));

  VERB(verbose, printf("  Mapping the newly created window ...\n"));
  XMapWindow(context->display, context->window);
  VERB(verbose, printf("  Newly created window mapped\n"));

  return true;
}

bool initDebugWindow(Context* context, bool verbose, enum Roadmap roadmap)
{
  VERB(verbose, printf("  Creating a debug window to catch key press events \
...\n"));

  if (roadmap != XCREATEDEBUGWINDOW_FAILED_RM)
  {
    context->debug_window = XCreateSimpleWindow(context->display,
      RootWindow(context->display, DefaultScreen(context->display)), 0, 0, 1,
      1, 1, BlackPixel(context->display, DefaultScreen(context->display)),
      WhitePixel(context->display, DefaultScreen(context->display)));
  }

  if (!context->debug_window)
  {
    fprintf(stderr, "  Failed to create debug window\n");
    return false;
  }
  VERB(verbose, printf("  Debug window created\n"));

  VERB(verbose, printf("  Requesting X server to report key press events for \
debug window ...\n"));
  XSelectInput(context->display, context->debug_window, KeyPressMask);
  VERB(verbose, printf("  X server is now reporting key press events for \
debug window\n"));

  VERB(verbose, printf("  Mapping debug window ...\n"));
  XMapWindow(context->display, context->debug_window);
  VERB(verbose, printf("  Debug window mapped\n"));

  return true;
}

void freeContext(Context* context, char* spaces, bool verbose)
{
  VERB(verbose, printf("%sDetaching current rendering context ...\n",
    spaces));
  glXMakeCurrent(context->display, 0, 0);
  VERB(verbose, printf("%sCurrent rendering context detached\n", spaces));

  VERB(verbose, printf("%sDestroying detached rendering context ...\n",
    spaces));
  glXDestroyContext(context->display, context->glx_context);
  VERB(verbose, printf("%sDetached rendering context destroyed\n", spaces));

  VERB(verbose, printf("%sDestroying current window ...\n", spaces));
  XDestroyWindow(context->display, context->window);
  VERB(verbose, printf("%sCurrent window destroyed\n", spaces));

  VERB(verbose, printf("%sFreeing colormap ...\n", spaces));
  XFreeColormap(context->display, context->cmap);
  VERB(verbose, printf("%sColormap freed\n", spaces));

  VERB(verbose, printf("%sClosing Display ...\n", spaces));
  XCloseDisplay(context->display);
  VERB(verbose, printf("%sDisplay closed\n", spaces));
}

void freeDebugContext(Context* context, bool verbose)
{
#ifdef DEBUG
  VERB(verbose, printf("Destroying debug window ...\n"));
  XDestroyWindow(context->display, context->debug_window);
  VERB(verbose, printf("Debug window destroyed\n"));
#endif

  freeContext(context, "", verbose);
}

bool initContext(Context* context, bool verbose, enum Roadmap roadmap)
{
  VERB(verbose, printf("  Opening X Display ...\n"));

  if (roadmap != XOPENDISPLAY_FAILED_RM)
  {
    context->display = XOpenDisplay(NULL);
  }

  if (!context->display)
  {
    fprintf(stderr, "  Failed to open X display\n");
    return false;
  }
  VERB(verbose, printf("  X Display opened\n"));

  if (!queryingGlxVersion(context, verbose, roadmap))
  {
    return false;
  }

  GLXFBConfig bestFbc;
  XVisualInfo* vi = NULL;

  if (!searchingBestFbc(context, &vi, &bestFbc, verbose, roadmap))
  {
    return false;
  }

  if (!initWindow(context, &vi, verbose, roadmap))
  {
    return false;
  }

  VERB(verbose, printf("  Querying the default screen's GLX extensions list \
...\n"));
  const char* glxExts = glXQueryExtensionsString(context->display,
    DefaultScreen(context->display));
  VERB(verbose, printf("  Default screen's GLX extensions list is:\n");
    char* token = strtok((char*) glxExts, " ");
    while (token != NULL)
    {
      printf("  - %s\n", token);
      token = strtok(NULL, " ");
    });

  VERB(verbose, printf("  Querying pointer to glXCreateContextAttribsARB() \
function ...\n"));
  glXCreateContextAttribsARBProc glXCreateContextAttribsARB = 0;
  if (roadmap != GLXCREATECONTEXTATTRIBSARB_UNFOUNDABLE_RM)
  {
    glXCreateContextAttribsARB = (glXCreateContextAttribsARBProc)
      glXGetProcAddressARB((const GLubyte *) "glXCreateContextAttribsARB");
  }

  VERB(verbose, printf("  Installing X error handler ...\n"));
  contextErrorOccurred = false;
  int (*oldHandler)(Display*, XErrorEvent*) =
    XSetErrorHandler(&contextErrorHandler);
  VERB(verbose, printf("  X error handler installed\n"));

  if (!glXCreateContextAttribsARB)
  {
    fprintf(stderr, "  glXCreateContextAttribsARB() not found\n");

    VERB(verbose, printf("  Restoring original X error handler ...\n"));
    XSetErrorHandler(oldHandler);
    VERB(verbose, printf("  Original X error handler restored\n"));

    VERB(verbose, printf("  Destroying current window ...\n"));
    XDestroyWindow(context->display, context->window);
    VERB(verbose, printf("  Current window destroyed\n"));

    VERB(verbose, printf("  Freeing colormap ...\n"));
    XFreeColormap(context->display, context->cmap);
    VERB(verbose, printf("  Colormap freed\n"));

    VERB(verbose, printf("  Closing Display ...\n"));
    XCloseDisplay(context->display);
    VERB(verbose, printf("  Display closed\n"));

    return false;
  }
  VERB(verbose, printf("  Pointer to glXCreateContextAttribsARB() \
found\n"));

  VERB(verbose, printf("  Testing GLX extension support ...\n"));
  if (!isExtensionSupported(glxExts, "GLX_ARB_create_context", verbose,
    roadmap))
  {
    fprintf(stderr, "  GLX extension not supported\n");

    VERB(verbose, printf("  Restoring original X error handler ...\n"));
    XSetErrorHandler(oldHandler);
    VERB(verbose, printf("  Original X error handler restored\n"));

    VERB(verbose, printf("  Destroying current window ...\n"));
    XDestroyWindow(context->display, context->window);
    VERB(verbose, printf("  Current window destroyed\n"));

    VERB(verbose, printf("  Freeing colormap ...\n"));
    XFreeColormap(context->display, context->cmap);
    VERB(verbose, printf("  Colormap freed\n"));

    VERB(verbose, printf("  Closing Display ...\n"));
    XCloseDisplay(context->display);
    VERB(verbose, printf("  Display closed\n"));

    return false;
  }
  VERB(verbose, printf("  Extension supported\n"));

  int context_attribs[] =
  {
    GLX_CONTEXT_MAJOR_VERSION_ARB, 3,
    GLX_CONTEXT_MINOR_VERSION_ARB, 3,
    None
  };

  VERB(verbose, printf("  Initializing the context to the initial state \
defined by the OpenGL specification ...\n"));
  context->glx_context = glXCreateContextAttribsARB(context->display,
    bestFbc, 0, True, context_attribs);
  VERB(verbose, printf("  Context initialized to the initial state defined \
by the OpenGL specification\n"));

  // Sync to ensure any errors generated are processed.
  VERB(verbose, printf("  Synchronizing generated X errors ... \n"));
  XSync(context->display, False);
  VERB(verbose, printf("  Generated X errors synchronized\n"));

  VERB(verbose, printf("  Restoring original X error handler ...\n"));
  XSetErrorHandler(oldHandler);
  VERB(verbose, printf("  Original X error handler restored\n"));

  VERB(verbose, printf("  Testing X error generation during context \
creation ...\n"));
  if (contextErrorOccurred || !context->glx_context ||
    (roadmap == CREATION_CONTEXT_FAILED_RM))
  {
    fprintf(stderr, "  An X error occured during creation context\n");

    VERB(verbose, printf("  Destroying current window ...\n"));
    XDestroyWindow(context->display, context->window);
    VERB(verbose, printf("  Current window destroyed\n"));

    VERB(verbose, printf("  Freeing colormap ...\n"));
    XFreeColormap(context->display, context->cmap);
    VERB(verbose, printf("  Colormap freed\n"));

    VERB(verbose, printf("  Closing Display ...\n"));
    XCloseDisplay(context->display);
    VERB(verbose, printf("  Display closed\n"));

    return false;
  }
  VERB(verbose, printf("  No X error occured during context creation\n"));

  VERB(verbose, printf("  Attaching the current rendering context to the \
newly created window ...\n"));
  glXMakeCurrent(context->display, context->window, context->glx_context);
  VERB(verbose, printf("  Current rendering context attached to the newly \
created window\n"));

  VERB(verbose, printf("  Requesting X server to report exposure events for \
current window ...\n"));
  XSelectInput(context->display, context->window, ExposureMask);
  VERB(verbose, printf("  X server is now reporting exposure events for \
current window\n"));

  VERB(verbose, printf("  Initializing GLEW ...\n"));
  glewExperimental = GL_TRUE;

  if (glewInit() || (roadmap == GLEWINIT_FAILED_RM))
  {
    fprintf(stderr, "  glewInit() failed\n");
    freeContext(context, "  ", verbose);
    return false;
  }
  VERB(verbose, printf("  GLEW initialized\n"));

  VERB(verbose, printf("  Enabling transparency for current window ...\n"));
  GL_CHECK(glEnable(GL_BLEND));
  VERB(verbose, printf("  Transparency enabled for current window\n"));

  VERB(verbose, printf("  Selecting transparency function for current \
window ...\n"));
  GL_CHECK(glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA));
  VERB(verbose, printf("  Transparency function selected for current \
window\n"));

#if DEBUG
  if (!initDebugWindow(context, verbose, roadmap))
  {
    freeContext(context, "  ", verbose);
    return false;
  }
#endif

  return true;
}
