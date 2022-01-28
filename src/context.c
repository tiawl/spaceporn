#include "context.h"

// Helper to check for extension string presence.  Adapted from:
//   http://www.opengl.org/resources/features/OGLextensions/
bool isExtensionSupported(const char* extList, const char* extension, Log* log)
{
  bool status = false;

  do
  {
    const char* start = NULL;
    const char* where = NULL;
    const char* terminator = NULL;

    // Extension names should not have spaces.
    writeLog(log, stdout, "", "    Testing presence of space in GLX %s",
      "extension string ...\n");
    where = strchr(extension, ' ');
    if (where || (*extension == '\0'))
    {
      writeLog(log, stdout, "",
        "    Space in this GLX extension name: \"%s\"\n", extension);
      break;
    }
    writeLog(log, stdout, "", "    No space in GLX extension name\n");

    // It takes a bit of care to be fool-proof about parsing the
    // GLX extensions string. Don't be fooled by sub-strings, etc.
    writeLog(log, stdout, "",
      "    Searching GLX extension \"%s\" in extensions list ...\n",
        extension);
    for (start = extList;;)
    {
      if (log->roadmap.id != UNSUPPORTED_GLX_EXT_RM)
      {
        where = strstr(start, extension);
      }

      if (!where)
      {
        writeLog(log, stdout, "", "    Unable to found GLX extension \"%s\"\n",
          extension);
        break;
      }

      terminator = where + strlen(extension);

      if ((where == start) || (*(where - 1) == ' '))
      {
        if ((*terminator == ' ') || (*terminator == '\0'))
        {
          writeLog(log, stdout, "", "    GLX extension found\n");
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
int contextErrorHandler()
{
  contextErrorOccurred = true;
  return 0;
}

bool queryingGlxVersion(Context* context, Log* log)
{
  bool status = true;

  int glx_major;
  int glx_minor;

  // FBConfigs were added in GLX version 1.3.
  writeLog(log, stdout, "", "  Querying GLX version ...\n");
  if ((!glXQueryVersion(context->display, &glx_major, &glx_minor) ||
    ((glx_major == 1) && (glx_minor < 3)) || (glx_major < 1)) ||
    (log->roadmap.id == INVALID_GLX_VERSION_RM))
  {
    writeLog(log, (log->verbose ? stdout : stderr), "  ",
      "Invalid GLX version\n");
    status = false;
  }
  writeLog(log, stdout, "", "  Valid GLX version: %d.%d\n", glx_major,
    glx_minor);

  return status;
}

bool searchingBestFbc(Context* context, GLXFBConfig* bestFbc, Log* log)
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
    writeLog(log, stdout, "", "  Querying GLX framebuffer config ...\n");
    GLXFBConfig* fbc = NULL;

    if (log->roadmap.id != GLXCHOOSEFBCONFIG_FAILED_RM)
    {
      fbc = glXChooseFBConfig(context->display,
        DefaultScreen(context->display), visual_attribs, &fbcount);
    }

    if (!fbc)
    {
      writeLog(log, (log->verbose ? stdout : stderr), "  ",
        "Failed to found a GLX framebuffer config\n");

      status = false;
      break;
    }
    writeLog(log, stdout, "", "  GLX framebuffer config found\n");

    // Pick the FB config/visual with the most samples per pixel
    int best_fbc = -1;
    int worst_fbc = -1;
    int best_num_samp = -1;
    int worst_num_samp = 999;

    for (int i = 0; i < fbcount; ++i)
    {
      writeLog(log, stdout, "", "  Searching GLX framebuffer %s %d/%d\n",
        "visual with the most samples per pixel ...", i, fbcount);
      writeLog(log, stdout, "",
        "    Querying visual from GLX framebuffer config ...\n");
      context->visual_info = glXGetVisualFromFBConfig(context->display, fbc[i]);
      if (context->visual_info)
      {
        writeLog(log, stdout, "", "    Corresponding visual found\n");

        int samp_buf, samples;

        writeLog(log, stdout, "",
          "    Querying GLX_SAMPLE_BUFFERS attribute ...\n");
        glXGetFBConfigAttrib(context->display, fbc[i],
          GLX_SAMPLE_BUFFERS, &samp_buf);
        writeLog(log, stdout, "",
          "    Current visual GLX_SAMPLE_BUFFERS value: %d\n", samp_buf);

        writeLog(log, stdout, "", "    Querying GLX_SAMPLES attribute ...\n");
        glXGetFBConfigAttrib(context->display, fbc[i], GLX_SAMPLES, &samples);
        writeLog(log, stdout, "",
          "    Current visual GLX_SAMPLES value: %d\n", samples);

        if ((best_fbc < 0) || (samp_buf && (samples > best_num_samp)))
        {
          writeLog(log, stdout, "",
            "    Setting best GLX framebuffer config ...\n");
          best_fbc = i;
          best_num_samp = samples;
          writeLog(log, stdout, "",
            "    Current best GLX framebuffer config index is: %d\n", best_fbc);
          writeLog(log, stdout, "",
            "    Current best GLX_SAMPLES value is: %d\n", best_num_samp);
        }
        if ((worst_fbc < 0) || (!samp_buf || (samples < worst_num_samp)))
        {
          writeLog(log, stdout, "",
            "    Setting worst GLX framebuffer config ...\n");
          worst_fbc = i;
          worst_num_samp = samples;
          writeLog(log, stdout, "",
            "    Current worst GLX framebuffer config index is: %d\n",
              worst_fbc);
          writeLog(log, stdout, "",
            "    Current worst GLX_SAMPLES value is: %d\n", worst_num_samp);
        }
      }
      writeLog(log, stdout, "", "    Freeing current visual ...\n");
      XFree(context->visual_info);
      writeLog(log, stdout, "", "    Current visual freed\n");
    }

    *bestFbc = fbc[best_fbc];
    writeLog(log, stdout, "", "  Searching GLX framebuffer visual %s %d/%d\n",
      "with the most samples per pixel ...", fbcount, fbcount);
    writeLog(log, stdout, "", "  Best GLX framebuffer config index: %d\n",
      best_fbc);

    writeLog(log, stdout, "", "  Freeing GLX framebuffer config ...\n");
    XFree(fbc);
    writeLog(log, stdout, "", "  GLX framebuffer config freed\n");

    writeLog(log, stdout, "",
      "  Querying visual from best GLX framebuffer config ...\n");
    context->visual_info = glXGetVisualFromFBConfig(context->display, *bestFbc);
    writeLog(log, stdout, "", "  Corresponding visual found\n");
  } while (false);

  return status;
}

bool initWindow(Context* context, Log* log)
{
  bool status = true;

  do
  {
    writeLog(log, stdout, "",
      "  Searching X root window from visual's screen ...\n");
    Window root = RootWindow(context->display, context->visual_info->screen);
    writeLog(log, stdout, "", "  X root window: 0x%lx\n", root);

    XSetWindowAttributes swa;

    writeLog(log, stdout, "",
      "  Creating color map from visual and root window ...\n");
    swa.colormap = context->cmap = XCreateColormap(context->display, root,
      context->visual_info->visual, AllocNone);
    writeLog(log, stdout, "", "  Color map created\n");

    swa.background_pixmap = None;
    swa.border_pixel      = 0;
    swa.event_mask        = StructureNotifyMask;
    writeLog(log, stdout, "", "  XSetWindowAttributes structure initialized\n");

    writeLog(log, stdout, "", "  Querying root window attributes ...\n");
    XGetWindowAttributes(context->display, root, &(context->window_attribs));
    writeLog(log, stdout, "", "  Root window dimensions are: %ux%u\n",
      context->window_attribs.width, context->window_attribs.height);

    writeLog(log, stdout, "", "  Creating new X window ...\n");

    if (log->roadmap.id != XCREATEWINDOW_FAILED_RM)
    {
      context->window = XCreateWindow(context->display, root,
        context->window_attribs.x, context->window_attribs.y,
        context->window_attribs.width, context->window_attribs.height, 0,
        context->visual_info->depth, InputOutput, context->visual_info->visual,
        CWBorderPixel | CWColormap | CWEventMask, &swa);
    }

    if (!context->window)
    {
      writeLog(log, (log->verbose ? stdout : stderr), "  ",
        "Failed to create X window\n");

      status = false;
      break;
    }
    writeLog(log, stdout, "", "  X Window created: 0x%lx\n", context->window);

    writeLog(log, stdout, "", "  Allocating window manager hints ...\n");
    XWMHints* wmHint = XAllocWMHints();
    writeLog(log, stdout, "",
      "  Window manager hints allocated successfully\n");

    wmHint->flags = InputHint | StateHint;
    wmHint->input = false;
    wmHint->initial_state = NormalState;
    writeLog(log, stdout, "", "  Window manager hints declared\n");

    writeLog(log, stdout, "", "  Setting window manager properties ...\n");
    XSetWMProperties(context->display, context->window, NULL, NULL,
      NULL, 0, NULL, wmHint, NULL);
    writeLog(log, stdout, "", "  Window manager properties set\n");

    writeLog(log, stdout, "",
      "  Querying _NET_WM_WINDOW_TYPE atom identifier ...\n");
    Atom xa = XInternAtom(context->display, "_NET_WM_WINDOW_TYPE", False);
    writeLog(log, stdout, "", "  _NET_WM_WINDOW_TYPE atom identifier found\n");

    writeLog(log, stdout, "",
      "  Querying _NET_WM_WINDOW_TYPE_DESKTOP atom identifier ...\n");
    Atom prop =
      XInternAtom(context->display, "_NET_WM_WINDOW_TYPE_DESKTOP", False);
    writeLog(log, stdout, "",
      "  _NET_WM_WINDOW_TYPE_DESKTOP atom identifier found\n");

    writeLog(log, stdout, "", "  Discarding _NET_WM_WINDOW_TYPE property %s",
      "value and storing the new _NET_WM_WINDOW_TYPE_DESKTOP ...\n");
    XChangeProperty(context->display, context->window, xa, XA_ATOM, 32,
      PropModeReplace, (unsigned char*) &prop, 1);
    writeLog(log, stdout, "", "  _NET_WM_WINDOW_TYPE discarded and %s",
      "_NET_WM_WINDOW_TYPE_DESKTOP stored\n");

    writeLog(log, stdout, "", "  Freeing window manager hints ...\n");
    XFree(wmHint);
    writeLog(log, stdout, "", "  Window manager hints freed\n");

    writeLog(log, stdout, "", "  Mapping the newly created window ...\n");
    XMapWindow(context->display, context->window);
    writeLog(log, stdout, "", "  Newly created window mapped\n");
  } while (false);

  return status;
}

#if DEBUG
bool initDebugWindow(Context* context, Log* log)
{
  bool status = true;

  do
  {
    writeLog(log, stdout, "",
      "  Creating a debug window to catch key press events ...\n");

    if (log->roadmap.id != XCREATEDEBUGWINDOW_FAILED_RM)
    {
      context->debug_window = XCreateSimpleWindow(context->display,
        RootWindow(context->display, DefaultScreen(context->display)), 0, 0, 1,
        1, 1, BlackPixel(context->display, DefaultScreen(context->display)),
        WhitePixel(context->display, DefaultScreen(context->display)));
    }

    if (!context->debug_window)
    {
      writeLog(log, (log->verbose ? stdout : stderr), "  ",
        "Failed to create debug window\n");

      status = false;
      break;
    }
    writeLog(log, stdout, "", "  Debug window created\n");

    writeLog(log, stdout, "",
      "  Requesting X server to report key press events for debug window ...\n");
    XSelectInput(context->display, context->debug_window, KeyPressMask);
    writeLog(log, stdout, "",
      "  X server is now reporting key press events for debug window\n");

    writeLog(log, stdout, "", "  Mapping debug window ...\n");
    XMapWindow(context->display, context->debug_window);
    writeLog(log, stdout, "", "  Debug window mapped\n");
  } while (false);

  return status;
}
#endif

bool initContext(Context* context, Log* log)
{
  bool status = true;

  do
  {
    writeLog(log, stdout, "", "  Opening X Display ...\n");

    if (log->roadmap.id != XOPENDISPLAY_FAILED_RM)
    {
      context->display = XOpenDisplay(NULL);
    }

    if (!context->display)
    {
      writeLog(log, (log->verbose ? stdout : stderr), "  ",
        "Failed to open X display\n");

      status = false;
      break;
    }
    writeLog(log, stdout, "", "  X Display opened\n");

    if (!queryingGlxVersion(context, log))
    {
      status = false;
      break;
    }

    GLXFBConfig bestFbc;

    if (!searchingBestFbc(context, &bestFbc, log))
    {
      status = false;
      break;
    }

    if (!initWindow(context, log))
    {
      status = false;
      break;
    }

    writeLog(log, stdout, "",
      "  Querying the default screen's GLX extensions list ...\n");
    const char* glxExts = glXQueryExtensionsString(context->display,
      DefaultScreen(context->display));
    writeLog(log, stdout, "", "  Default screen's GLX extensions list is:\n");
    char* token = strtok((char*) glxExts, " ");
    while (token != NULL)
    {
      writeLog(log, stdout, "", "  - %s\n", token);
      token = strtok(NULL, " ");
    };

    writeLog(log, stdout, "",
      "  Querying pointer to glXCreateContextAttribsARB() function ...\n");
    glXCreateContextAttribsARBProc glXCreateContextAttribsARB = 0;
    if (log->roadmap.id != GLXCREATECONTEXTATTRIBSARB_UNFOUNDABLE_RM)
    {
      glXCreateContextAttribsARB = (glXCreateContextAttribsARBProc)
        glXGetProcAddressARB((const GLubyte *) "glXCreateContextAttribsARB");
    }

    writeLog(log, stdout, "", "    Installing X error handler ...\n");
    contextErrorOccurred = false;
    int (*oldHandler)(Display*, XErrorEvent*) =
      XSetErrorHandler(&contextErrorHandler);
    writeLog(log, stdout, "", "    X error handler installed\n");

    if (!glXCreateContextAttribsARB)
    {
      writeLog(log, (log->verbose ? stdout : stderr), "  ",
        "Unable to found glXCreateContextAttribsARB()\n");

      writeLog(log, stdout, "", "  Restoring original X error handler ...\n");
      XSetErrorHandler(oldHandler);
      writeLog(log, stdout, "", "  Original X error handler restored\n");

      status = false;
      break;
    }
    writeLog(log, stdout, "",
      "  Pointer to glXCreateContextAttribsARB() found\n");

    writeLog(log, stdout, "", "  Testing GLX extension support ...\n");
    if (!isExtensionSupported(glxExts, (log->roadmap.id == SPACE_IN_GLX_EXT_RM ?
      "GLX_ARB_create_context " : "GLX_ARB_create_context"), log))
    {
      writeLog(log, (log->verbose ? stdout : stderr), "  ",
        "GLX extension not supported\n");

      writeLog(log, stdout, "", "  Restoring original X error handler ...\n");
      XSetErrorHandler(oldHandler);
      writeLog(log, stdout, "", "  Original X error handler restored\n");

      status = false;
      break;
    }
    writeLog(log, stdout, "", "  Extension supported\n");

    int context_attribs[] =
    {
      GLX_CONTEXT_MAJOR_VERSION_ARB, 3,
      GLX_CONTEXT_MINOR_VERSION_ARB, 3,
      None
    };

    writeLog(log, stdout, "", "  Initializing the context to the initial %s",
      "state defined by the OpenGL specification ...\n");
    if (log->roadmap.id != CONTEXT_CREATION_FAILED_RM)
    {
      context->glx_context = glXCreateContextAttribsARB(context->display,
        bestFbc, 0, True, context_attribs);
    }
    writeLog(log, stdout, "", "  Context initialized to the initial state %s",
      "defined by the OpenGL specification\n");

    // Sync to ensure any errors generated are processed.
    writeLog(log, stdout, "", "  Synchronizing generated X errors ...\n");
    XSync(context->display, False);
    writeLog(log, stdout, "", "  Generated X errors synchronized\n");

    writeLog(log, stdout, "", "  Restoring original X error handler ...\n");
    XSetErrorHandler(oldHandler);
    writeLog(log, stdout, "", "  Original X error handler restored\n");

    writeLog(log, stdout, "",
      "  Testing X error generation during context creation ...\n");
    if (contextErrorOccurred || !context->glx_context)
    {
      writeLog(log, (log->verbose ? stdout : stderr), "  ",
        "An X error occured during creation context\n");

      status = false;
      break;
    }
    writeLog(log, stdout, "", "  No X error occured during context creation\n");

    writeLog(log, stdout, "", "  Attaching the current rendering context %s",
      "to the newly created window ...\n");
    glXMakeCurrent(context->display, context->window, context->glx_context);
    writeLog(log, stdout, "",
      "  Current rendering context attached to the newly created window\n");

    writeLog(log, stdout, "", "  Requesting X server to report exposure %s",
      "events for current window ...\n");
    XSelectInput(context->display, context->window, ExposureMask);
    writeLog(log, stdout, "",
      "  X server is now reporting exposure events for current window\n");

    writeLog(log, stdout, "", "  Initializing GLEW ...\n");
    glewExperimental = GL_TRUE;

    GLenum err=glewInit();

    if ((err != GLEW_OK) || (log->roadmap.id == GLEWINIT_FAILED_RM))
    {
      writeLog(log, (log->verbose ? stdout : stderr), "  ",
        "glewInit() failed: %s\n", glewGetErrorString(err));

      status = false;
      break;
    }
    writeLog(log, stdout, "", "  GLEW initialized\n");

    writeLog(log, stdout, "",
      "  Enabling transparency for current window ...\n");
    GL_CHECK(glEnable(GL_BLEND), status, log);
    writeLog(log, stdout, "", "  Transparency enabled for current window\n");

    writeLog(log, stdout, "",
      "  Selecting transparency function for current window ...\n");
    GL_CHECK(glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA), status, log);
    writeLog(log, stdout, "",
      "  Transparency function selected for current window\n");

    writeLog(log, stdout, "",
      "  Disablings rendering of back face of drawn triangles ...\n");
    GL_CHECK(glCullFace(GL_BACK), status, log);
    writeLog(log, stdout, "",
      "  Rendering back face of drawn triangles disabled ...\n");

    writeLog(log, stdout, "", "  Enabling backface culling ...\n");
    GL_CHECK(glEnable(GL_CULL_FACE), status, log);
    writeLog(log, stdout, "", "  Backface culling enabled\n");

    writeLog(log, stdout, "", "  Enabling Depth buffer ...\n");
    GL_CHECK(glDepthFunc(GL_LESS), status, log);
    GL_CHECK(glEnable(GL_DEPTH_TEST), status, log);
    writeLog(log, stdout, "", "  Depth buffer enabled\n");

#if DEBUG
    if (!initDebugWindow(context, log))
    {
      status = false;
      break;
    }
#endif
  } while (false);

  return status;
}

void freeContext(Context* context, Log* log)
{
  if (context->glx_context)
  {
    writeLog(log, stdout, "", "Detaching current rendering context ...\n");
    glXMakeCurrent(context->display, 0, 0);
    writeLog(log, stdout, "", "Current rendering context detached\n");

    writeLog(log, stdout, "", "Destroying detached rendering context ...\n");
    glXDestroyContext(context->display, context->glx_context);
    writeLog(log, stdout, "", "Detached rendering context destroyed\n");
  }

#if DEBUG
  if (context->debug_window)
  {
    writeLog(log, stdout, "", "Unmapping debug window ...\n");
    XUnmapWindow(context->display, context->debug_window);
    writeLog(log, stdout, "", "Debug window unmapped\n");

    writeLog(log, stdout, "", "Destroying debug window ...\n");
    XDestroyWindow(context->display, context->debug_window);
    writeLog(log, stdout, "", "Debug window destroyed\n");
  }
#endif

  if (context->visual_info)
  {
    writeLog(log, stdout, "", "Freeing current visual ...\n");
    XFree(context->visual_info);
    writeLog(log, stdout, "", "Current visual freed\n");
  }

  if (context->cmap)
  {
    writeLog(log, stdout, "", "Freeing colormap ...\n");
    XFreeColormap(context->display, context->cmap);
    writeLog(log, stdout, "", "Colormap freed\n");
  }

  if (context->window)
  {
    writeLog(log, stdout, "", "Unmapping current window ...\n");
    XUnmapWindow(context->display, context->window);
    writeLog(log, stdout, "", "Current window unmapped\n");

    writeLog(log, stdout, "", "Destroying current window ...\n");
    XDestroyWindow(context->display, context->window);
    writeLog(log, stdout, "", "Current window destroyed\n");
  }

  if (context->display)
  {
    writeLog(log, stdout, "", "Closing Display ...\n");
    XCloseDisplay(context->display);
    writeLog(log, stdout, "", "Display closed\n");
  }
}
