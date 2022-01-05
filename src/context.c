#include "context.h"

// Helper to check for extension string presence.  Adapted from:
//   http://www.opengl.org/resources/features/OGLextensions/
bool isExtensionSupported(const char* extList, const char* extension,
  bool verbose, Roadmap* roadmap)
{
  bool status = false;

  do
  {
    const char* start = NULL;
    const char* where = NULL;
    const char* terminator = NULL;

    /* Extension names should not have spaces. */
    LOG(verbose, printf("    Testing presence of space in GLX extension \
string ...\n"));
    where = strchr(extension, ' ');
    if (where || (*extension == '\0'))
    {
      LOG(verbose, printf("    Space in this GLX extension name: \"%s\"\n",
        extension));
      break;
    }
    LOG(verbose, printf("    No space in GLX extension name\n"));

    /* It takes a bit of care to be fool-proof about parsing the
       GLX extensions string. Don't be fooled by sub-strings, etc. */
    LOG(verbose, printf("    Searching GLX extension \"%s\" in extensions \
list ...\n", extension));
    for (start = extList;;)
    {
      if (roadmap->id != UNSUPPORTED_GLX_EXT_RM)
      {
        where = strstr(start, extension);
      }

      if (!where)
      {
        LOG(verbose, printf("    Unable to found GLX extension \"%s\"\n",
          extension));
        break;
      }

      terminator = where + strlen(extension);

      if ((where == start) || (*(where - 1) == ' '))
      {
        if ((*terminator == ' ') || (*terminator == '\0'))
        {
          LOG(verbose, printf("    GLX extension found\n"));
          status = true;
          break;
        }
      }

      start = terminator;
    }
  } while (false);

  return status;
}

static bool contextErrorOccurred = false;
int contextErrorHandler(Display* display, XErrorEvent* event)
{
  contextErrorOccurred = true;
  return 0;
}

bool queryingGlxVersion(Context* context, bool verbose, Roadmap* roadmap)
{
  bool status = true;

  int glx_major;
  int glx_minor;

  // FBConfigs were added in GLX version 1.3.
  LOG(verbose, printf("  Querying GLX version ...\n"));
  if ((!glXQueryVersion(context->display, &glx_major, &glx_minor) ||
    ((glx_major == 1) && (glx_minor < 3)) || (glx_major < 1)) ||
    (roadmap->id == INVALID_GLX_VERSION_RM))
  {
    LOG(verbose, printf("  "));
    fprintf((verbose ? stdout : stderr), "Invalid GLX version\n");
    status = false;
  }
  LOG(verbose, printf("  Valid GLX version: %d.%d\n", glx_major, glx_minor));

  return status;
}

bool searchingBestFbc(Context* context, GLXFBConfig* bestFbc, bool verbose,
  Roadmap* roadmap)
{
  bool status = true;

  do
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
    LOG(verbose, printf("  Querying GLX framebuffer config ...\n"));
    GLXFBConfig* fbc = NULL;

    if (roadmap->id != GLXCHOOSEFBCONFIG_FAILED_RM)
    {
      fbc = glXChooseFBConfig(context->display,
        DefaultScreen(context->display), visual_attribs, &fbcount);
    }

    if (!fbc)
    {
      LOG(verbose, printf("  "));
      fprintf((verbose ? stdout : stderr),
        "Failed to found a GLX framebuffer config\n");

      status = false;
      break;
    }
    LOG(verbose, printf("  GLX framebuffer config found\n"));

    // Pick the FB config/visual with the most samples per pixel
    int best_fbc = -1;
    int worst_fbc = -1;
    int best_num_samp = -1;
    int worst_num_samp = 999;

    for (int i = 0; i < fbcount; ++i)
    {
      LOG(verbose, printf("  Searching GLX framebuffer visual with the most \
samples per pixel ... %d/%d\n", i, fbcount));
      LOG(verbose, printf("    Querying visual from GLX framebuffer config \
...\n"));
      context->visual_info = glXGetVisualFromFBConfig(context->display, fbc[i]);
      if (context->visual_info)
      {
        LOG(verbose, printf("    Corresponding visual found\n"));

        int samp_buf, samples;

        LOG(verbose, printf("    Querying GLX_SAMPLE_BUFFERS attribute \
...\n"));
        glXGetFBConfigAttrib(context->display, fbc[i],
          GLX_SAMPLE_BUFFERS, &samp_buf);
        LOG(verbose, printf("    Current visual GLX_SAMPLE_BUFFERS \
value: %d\n", samp_buf));

        LOG(verbose, printf("    Querying GLX_SAMPLES attribute ...\n"));
        glXGetFBConfigAttrib(context->display, fbc[i], GLX_SAMPLES, &samples);
        LOG(verbose, printf("    Current visual GLX_SAMPLES value: %d\n",
          samples));

        if ((best_fbc < 0) || (samp_buf && (samples > best_num_samp)))
        {
          LOG(verbose, printf("    Setting best GLX framebuffer config \
...\n"));
          best_fbc = i;
          best_num_samp = samples;
          LOG(verbose, printf("    Current best GLX framebuffer config index \
is: %d\n", best_fbc));
          LOG(verbose, printf("    Current best GLX_SAMPLES value is: %d\n",
            best_num_samp));
        }
        if ((worst_fbc < 0) || (!samp_buf || (samples < worst_num_samp)))
        {
          LOG(verbose, printf("    Setting worst GLX framebuffer config \
...\n"));
          worst_fbc = i;
          worst_num_samp = samples;
          LOG(verbose, printf("    Current worst GLX framebuffer config index \
is: %d\n", worst_fbc));
          LOG(verbose, printf("    Current worst GLX_SAMPLES value is: %d\n",
            worst_num_samp));
        }
      }
      LOG(verbose, printf("    Freeing current visual ...\n"));
      XFree(context->visual_info);
      LOG(verbose, printf("    Current visual freed\n"));
    }

    *bestFbc = fbc[best_fbc];
    LOG(verbose, printf("  Searching GLX framebuffer visual with the most \
samples per pixel ... %d/%d\n", fbcount, fbcount));
    LOG(verbose, printf("  Best GLX framebuffer config index: %d\n",
      best_fbc));

    LOG(verbose, printf("  Freeing GLX framebuffer config ...\n"));
    XFree(fbc);
    LOG(verbose, printf("  GLX framebuffer config freed\n"));

    LOG(verbose, printf("  Querying visual from best GLX framebuffer config \
...\n"));
    context->visual_info = glXGetVisualFromFBConfig(context->display, *bestFbc);
    LOG(verbose, printf("  Corresponding visual found\n"));
  } while (false);

  return status;
}

bool initWindow(Context* context, bool verbose, Roadmap* roadmap)
{
  bool status = true;

  do
  {
    LOG(verbose, printf("  Searching X root window from visual's screen \
...\n"));
    Window root = RootWindow(context->display, context->visual_info->screen);
    LOG(verbose, printf("  X root window: 0x%lx\n", root));

    XSetWindowAttributes swa;

    LOG(verbose, printf("  Creating color map from visual and root window \
...\n"));
    swa.colormap = context->cmap = XCreateColormap(context->display, root,
      context->visual_info->visual, AllocNone);
    LOG(verbose, printf("  Color map created\n"));

    swa.background_pixmap = None;
    swa.border_pixel      = 0;
    swa.event_mask        = StructureNotifyMask;
    LOG(verbose, printf("  XSetWindowAttributes structure initialized\n"));

    LOG(verbose, printf("  Querying root window attributes ...\n"));
    XGetWindowAttributes(context->display, root, &(context->window_attribs));
    LOG(verbose, printf("  Root window dimensions are: %ux%u\n",
      context->window_attribs.width, context->window_attribs.height));

    LOG(verbose, printf("  Creating new X window ...\n"));

    if (roadmap->id != XCREATEWINDOW_FAILED_RM)
    {
      context->window = XCreateWindow(context->display, root,
        context->window_attribs.x, context->window_attribs.y,
        context->window_attribs.width, context->window_attribs.height, 0,
        context->visual_info->depth, InputOutput, context->visual_info->visual,
        CWBorderPixel | CWColormap | CWEventMask, &swa);
    }

    if (!context->window)
    {
      LOG(verbose, printf("  "));
      fprintf((verbose ? stdout : stderr), "Failed to create X window\n");

      status = false;
      break;
    }
    LOG(verbose, printf("  X Window created: 0x%lx\n", context->window));

    LOG(verbose, printf("  Allocating window manager hints ...\n"));
    XWMHints* wmHint = XAllocWMHints();
    LOG(verbose, printf("  Window manager hints allocated successfully\n"));

    wmHint->flags = InputHint | StateHint;
    wmHint->input = false;
    wmHint->initial_state = NormalState;
    LOG(verbose, printf("  Window manager hints declared\n"));

    LOG(verbose, printf("  Setting window manager properties ...\n"));
    XSetWMProperties(context->display, context->window, NULL, NULL,
      NULL, 0, NULL, wmHint, NULL);
    LOG(verbose, printf("  Window manager properties set\n"));

    LOG(verbose, printf("  Querying _NET_WM_WINDOW_TYPE atom identifier \
...\n"));
    Atom xa = XInternAtom(context->display, "_NET_WM_WINDOW_TYPE", False);
    LOG(verbose, printf("  _NET_WM_WINDOW_TYPE atom identifier found\n"));

    LOG(verbose, printf("  Querying _NET_WM_WINDOW_TYPE_DESKTOP atom \
identifier ...\n"));
    Atom prop =
      XInternAtom(context->display, "_NET_WM_WINDOW_TYPE_DESKTOP", False);
    LOG(verbose, printf("  _NET_WM_WINDOW_TYPE_DESKTOP atom identifier \
found\n"));

    LOG(verbose, printf("  Discarding _NET_WM_WINDOW_TYPE property value and \
storing the new _NET_WM_WINDOW_TYPE_DESKTOP ...\n"));
    XChangeProperty(context->display, context->window, xa, XA_ATOM, 32,
      PropModeReplace, (unsigned char*) &prop, 1);
    LOG(verbose, printf("  _NET_WM_WINDOW_TYPE discarded and \
_NET_WM_WINDOW_TYPE_DESKTOP stored\n"));

    LOG(verbose, printf("  Freeing window manager hints ...\n"));
    XFree(wmHint);
    LOG(verbose, printf("  Window manager hints freed\n"));

    LOG(verbose, printf("  Mapping the newly created window ...\n"));
    XMapWindow(context->display, context->window);
    LOG(verbose, printf("  Newly created window mapped\n"));
  } while (false);

  return status;
}

#if DEBUG
bool initDebugWindow(Context* context, bool verbose, Roadmap* roadmap)
{
  bool status = true;

  do
  {
    LOG(verbose, printf("  Creating a debug window to catch key press events \
...\n"));

    if (roadmap->id != XCREATEDEBUGWINDOW_FAILED_RM)
    {
      context->debug_window = XCreateSimpleWindow(context->display,
        RootWindow(context->display, DefaultScreen(context->display)), 0, 0, 1,
        1, 1, BlackPixel(context->display, DefaultScreen(context->display)),
        WhitePixel(context->display, DefaultScreen(context->display)));
    }

    if (!context->debug_window)
    {
      LOG(verbose, printf("  "));
      fprintf((verbose ? stdout : stderr), "Failed to create debug window\n");

      status = false;
      break;
    }
    LOG(verbose, printf("  Debug window created\n"));

    LOG(verbose, printf("  Requesting X server to report key press events for \
debug window ...\n"));
    XSelectInput(context->display, context->debug_window, KeyPressMask);
    LOG(verbose, printf("  X server is now reporting key press events for \
debug window\n"));

    LOG(verbose, printf("  Mapping debug window ...\n"));
    XMapWindow(context->display, context->debug_window);
    LOG(verbose, printf("  Debug window mapped\n"));
  } while (false);

  return status;
}
#endif

bool initContext(Context* context, bool verbose, Roadmap* roadmap)
{
  bool status = true;

  do
  {
    LOG(verbose, printf("  Opening X Display ...\n"));

    if (roadmap->id != XOPENDISPLAY_FAILED_RM)
    {
      context->display = XOpenDisplay(NULL);
    }

    if (!context->display)
    {
      LOG(verbose, printf("  "));
      fprintf((verbose ? stdout : stderr), "Failed to open X display\n");

      status = false;
      break;
    }
    LOG(verbose, printf("  X Display opened\n"));

    if (!queryingGlxVersion(context, verbose, roadmap))
    {
      status = false;
      break;
    }

    GLXFBConfig bestFbc;

    if (!searchingBestFbc(context, &bestFbc, verbose, roadmap))
    {
      status = false;
      break;
    }

    if (!initWindow(context, verbose, roadmap))
    {
      status = false;
      break;
    }

    LOG(verbose, printf("  Querying the default screen's GLX extensions list \
...\n"));
    const char* glxExts = glXQueryExtensionsString(context->display,
      DefaultScreen(context->display));
    LOG(verbose, printf("  Default screen's GLX extensions list is:\n");
      char* token = strtok((char*) glxExts, " ");
      while (token != NULL)
      {
        printf("  - %s\n", token);
        token = strtok(NULL, " ");
      });

    LOG(verbose, printf("  Querying pointer to glXCreateContextAttribsARB() \
function ...\n"));
    glXCreateContextAttribsARBProc glXCreateContextAttribsARB = 0;
    if (roadmap->id != GLXCREATECONTEXTATTRIBSARB_UNFOUNDABLE_RM)
    {
      glXCreateContextAttribsARB = (glXCreateContextAttribsARBProc)
        glXGetProcAddressARB((const GLubyte *) "glXCreateContextAttribsARB");
    }

    LOG(verbose, printf("    Installing X error handler ...\n"));
    contextErrorOccurred = false;
    int (*oldHandler)(Display*, XErrorEvent*) =
      XSetErrorHandler(&contextErrorHandler);
    LOG(verbose, printf("    X error handler installed\n"));

    if (!glXCreateContextAttribsARB)
    {
      LOG(verbose, printf("  "));
      fprintf((verbose ? stdout : stderr),
        "Unable to found glXCreateContextAttribsARB()\n");

      LOG(verbose, printf("  Restoring original X error handler ...\n"));
      XSetErrorHandler(oldHandler);
      LOG(verbose, printf("  Original X error handler restored\n"));

      status = false;
      break;
    }
    LOG(verbose, printf("  Pointer to glXCreateContextAttribsARB() \
found\n"));

    LOG(verbose, printf("  Testing GLX extension support ...\n"));
    if (!isExtensionSupported(glxExts, (roadmap->id == SPACE_IN_GLX_EXT_RM ?
      "GLX_ARB_create_context " : "GLX_ARB_create_context"), verbose, roadmap))
    {
      LOG(verbose, printf("  "));
      fprintf((verbose ? stdout : stderr), "GLX extension not supported\n");

      LOG(verbose, printf("  Restoring original X error handler ...\n"));
      XSetErrorHandler(oldHandler);
      LOG(verbose, printf("  Original X error handler restored\n"));

      status = false;
      break;
    }
    LOG(verbose, printf("  Extension supported\n"));

    int context_attribs[] =
    {
      GLX_CONTEXT_MAJOR_VERSION_ARB, 3,
      GLX_CONTEXT_MINOR_VERSION_ARB, 3,
      None
    };

    LOG(verbose, printf("  Initializing the context to the initial state \
defined by the OpenGL specification ...\n"));
    if (roadmap->id != CONTEXT_CREATION_FAILED_RM)
    {
      context->glx_context = glXCreateContextAttribsARB(context->display,
        bestFbc, 0, True, context_attribs);
    }
    LOG(verbose, printf("  Context initialized to the initial state defined \
by the OpenGL specification\n"));

    // Sync to ensure any errors generated are processed.
    LOG(verbose, printf("  Synchronizing generated X errors ...\n"));
    XSync(context->display, False);
    LOG(verbose, printf("  Generated X errors synchronized\n"));

    LOG(verbose, printf("  Restoring original X error handler ...\n"));
    XSetErrorHandler(oldHandler);
    LOG(verbose, printf("  Original X error handler restored\n"));

    LOG(verbose, printf("  Testing X error generation during context \
creation ...\n"));
    if (contextErrorOccurred || !context->glx_context)
    {
      LOG(verbose, printf("  "));
      fprintf((verbose ? stdout : stderr),
        "An X error occured during creation context\n");

      status = false;
      break;
    }
    LOG(verbose, printf("  No X error occured during context creation\n"));

    LOG(verbose, printf("  Attaching the current rendering context to the \
newly created window ...\n"));
    glXMakeCurrent(context->display, context->window, context->glx_context);
    LOG(verbose, printf("  Current rendering context attached to the newly \
created window\n"));

    LOG(verbose, printf("  Requesting X server to report exposure events for \
current window ...\n"));
    XSelectInput(context->display, context->window, ExposureMask);
    LOG(verbose, printf("  X server is now reporting exposure events for \
current window\n"));

    LOG(verbose, printf("  Initializing GLEW ...\n"));
    glewExperimental = GL_TRUE;

    GLenum err=glewInit();

    if ((err != GLEW_OK) || (roadmap->id == GLEWINIT_FAILED_RM))
    {
      LOG(verbose, printf("  "));
      fprintf((verbose ? stdout : stderr),
        "glewInit() failed: %s\n", glewGetErrorString(err));

      status = false;
      break;
    }
    LOG(verbose, printf("  GLEW initialized\n"));

    LOG(verbose, printf("  Enabling transparency for current window ...\n"));
    GL_CHECK(glEnable(GL_BLEND), status);
    LOG(verbose, printf("  Transparency enabled for current window\n"));

    LOG(verbose, printf("  Selecting transparency function for current \
window ...\n"));
    GL_CHECK(glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA), status);
    LOG(verbose, printf("  Transparency function selected for current \
window\n"));

#if DEBUG
    if (!initDebugWindow(context, verbose, roadmap))
    {
      status = false;
      break;
    }
#endif
  } while (false);

  return status;
}

void freeContext(Context* context, bool verbose)
{
  if (context->glx_context)
  {
    LOG(verbose, printf("Detaching current rendering context ...\n"));
    glXMakeCurrent(context->display, 0, 0);
    LOG(verbose, printf("Current rendering context detached\n"));

    LOG(verbose, printf("Destroying detached rendering context ...\n"));
    glXDestroyContext(context->display, context->glx_context);
    LOG(verbose, printf("Detached rendering context destroyed\n"));
  }

#if DEBUG
  if (context->debug_window)
  {
    LOG(verbose, printf("Unmapping debug window ...\n"));
    XUnmapWindow(context->display, context->debug_window);
    LOG(verbose, printf("Debug window unmapped\n"));

    LOG(verbose, printf("Destroying debug window ...\n"));
    XDestroyWindow(context->display, context->debug_window);
    LOG(verbose, printf("Debug window destroyed\n"));
  }
#endif

  if (context->visual_info)
  {
    LOG(verbose, printf("Freeing current visual ...\n"));
    XFree(context->visual_info);
    LOG(verbose, printf("Current visual freed\n"));
  }

  if (context->cmap)
  {
    LOG(verbose, printf("Freeing colormap ...\n"));
    XFreeColormap(context->display, context->cmap);
    LOG(verbose, printf("Colormap freed\n"));
  }

  if (context->window)
  {
    LOG(verbose, printf("Unmapping current window ...\n"));
    XUnmapWindow(context->display, context->window);
    LOG(verbose, printf("Current window unmapped\n"));

    LOG(verbose, printf("Destroying current window ...\n"));
    XDestroyWindow(context->display, context->window);
    LOG(verbose, printf("Current window destroyed\n"));
  }

  if (context->display)
  {
    LOG(verbose, printf("Closing Display ...\n"));
    XCloseDisplay(context->display);
    LOG(verbose, printf("Display closed\n"));
  }
}
