#include "context.h"

// Helper to check for extension string presence.  Adapted from:
//   http://www.opengl.org/resources/features/OGLextensions/
bool isExtensionSupported(const char* extList, const char* extension, Log* log)
{
  bool status = false;

  do
  {
    const char* where = NULL;

    // Extension names should not have spaces.
    writeLog(log, stdout, DEBUG, "", "    Testing presence of space in %s",
      "GLX extension string ...\n");
    where = strchr(extension, ' ');
    if (where || (*extension == '\0'))
    {
      writeLog(log, stdout, ERROR, "",
        "    Space in this GLX extension name: \"%s\"\n", extension);
      break;
    }
    writeLog(log, stdout, DEBUG, "", "    No space in GLX extension name\n");

    // It takes a bit of care to be fool-proof about parsing the
    // GLX extensions string. Don't be fooled by sub-strings, etc.
    writeLog(log, stdout, INFO, "",
      "    Searching GLX extension \"%s\" in extensions list ...\n",
        extension);
    char* token = strtok((char*) extList, " ");
    while (token != NULL)
    {
      if (strcmp(token, extension) == 0)
      {
        writeLog(log, stdout, INFO, "", "    GLX extension found\n");
        status = true;
        break;
      }
      token = strtok(NULL, " ");
    }
    writeLog(log, stdout, ERROR, "",
      "    Unable to found GLX extension \"%s\"\n", extension);
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
  writeLog(log, stdout, INFO, "", "  Querying GLX version ...\n");
  if ((!glXQueryVersion(context->display, &glx_major, &glx_minor) ||
    ((glx_major == 1) && (glx_minor < 3)) || (glx_major < 1)) ||
    (log->roadmap.id == INVALID_GLX_VERSION_RM))
  {
    writeLog(log, (log->verbose ? stdout : stderr), ERROR, "  ",
      "Invalid GLX version\n");
    status = false;
  }
  writeLog(log, stdout, INFO, "", "  Valid GLX version: %d.%d\n", glx_major,
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
    writeLog(log, stdout, DEBUG, "", "  Querying GLX framebuffer config ...\n");
    GLXFBConfig* fbc = NULL;

    if (log->roadmap.id != GLXCHOOSEFBCONFIG_FAILED_RM)
    {
      fbc = glXChooseFBConfig(context->display,
        DefaultScreen(context->display), visual_attribs, &fbcount);
    }

    if (!fbc)
    {
      writeLog(log, (log->verbose ? stdout : stderr), ERROR, "  ",
        "Failed to found a GLX framebuffer config\n");

      status = false;
      break;
    }
    writeLog(log, stdout, DEBUG, "", "  GLX framebuffer config found\n");

    // Pick the FB config/visual with the most samples per pixel
    int best_fbc = -1;
    int worst_fbc = -1;
    int best_num_samp = -1;
    int worst_num_samp = 999;

    for (int i = 0; i < fbcount; ++i)
    {
      writeLog(log, stdout, DEBUG, "", "  Searching GLX framebuffer %s %d/%d\n",
        "visual with the most samples per pixel ...", i, fbcount);
      writeLog(log, stdout, DEBUG, "",
        "    Querying visual from GLX framebuffer config ...\n");
      context->visual_info = glXGetVisualFromFBConfig(context->display, fbc[i]);
      if (context->visual_info)
      {
        writeLog(log, stdout, DEBUG, "", "    Corresponding visual found\n");

        int samp_buf, samples;

        writeLog(log, stdout, DEBUG, "",
          "    Querying GLX_SAMPLE_BUFFERS attribute ...\n");
        glXGetFBConfigAttrib(context->display, fbc[i],
          GLX_SAMPLE_BUFFERS, &samp_buf);
        writeLog(log, stdout, DEBUG, "",
          "    Current visual GLX_SAMPLE_BUFFERS value: %d\n", samp_buf);

        writeLog(log, stdout, DEBUG, "",
          "    Querying GLX_SAMPLES attribute ...\n");
        glXGetFBConfigAttrib(context->display, fbc[i], GLX_SAMPLES, &samples);
        writeLog(log, stdout, DEBUG, "",
          "    Current visual GLX_SAMPLES value: %d\n", samples);

        if ((best_fbc < 0) || (samp_buf && (samples > best_num_samp)))
        {
          writeLog(log, stdout, DEBUG, "",
            "    Setting best GLX framebuffer config ...\n");
          best_fbc = i;
          best_num_samp = samples;
          writeLog(log, stdout, DEBUG, "",
            "    Current best GLX framebuffer config index is: %d\n", best_fbc);
          writeLog(log, stdout, DEBUG, "",
            "    Current best GLX_SAMPLES value is: %d\n", best_num_samp);
        }
        if ((worst_fbc < 0) || (!samp_buf || (samples < worst_num_samp)))
        {
          writeLog(log, stdout, DEBUG, "",
            "    Setting worst GLX framebuffer config ...\n");
          worst_fbc = i;
          worst_num_samp = samples;
          writeLog(log, stdout, DEBUG, "",
            "    Current worst GLX framebuffer config index is: %d\n",
              worst_fbc);
          writeLog(log, stdout, DEBUG, "",
            "    Current worst GLX_SAMPLES value is: %d\n", worst_num_samp);
        }
      }
      writeLog(log, stdout, DEBUG, "", "    Freeing current visual ...\n");
      XFree(context->visual_info);
      writeLog(log, stdout, DEBUG, "", "    Current visual freed\n");
    }

    *bestFbc = fbc[best_fbc];
    writeLog(log, stdout, DEBUG, "", "  Searching GLX framebuffer %s %d/%d\n",
      "visual with the most samples per pixel ...", fbcount, fbcount);
    writeLog(log, stdout, DEBUG, "",
      "  Best GLX framebuffer config index: %d\n", best_fbc);

    writeLog(log, stdout, DEBUG, "", "  Freeing GLX framebuffer config ...\n");
    XFree(fbc);
    writeLog(log, stdout, DEBUG, "", "  GLX framebuffer config freed\n");

    writeLog(log, stdout, DEBUG, "",
      "  Querying visual from best GLX framebuffer config ...\n");
    context->visual_info = glXGetVisualFromFBConfig(context->display, *bestFbc);
    writeLog(log, stdout, DEBUG, "", "  Corresponding visual found\n");
  } while (false);

  return status;
}

bool initWindow(Context* context, Log* log)
{
  bool status = true;

  do
  {
    writeLog(log, stdout, INFO, "",
      "  Searching X root window from visual's screen ...\n");
    Window root = RootWindow(context->display, context->visual_info->screen);
    writeLog(log, stdout, INFO, "", "  X root window: 0x%lx\n", root);

    XSetWindowAttributes swa;

    writeLog(log, stdout, DEBUG, "",
      "  Creating color map from visual and root window ...\n");
    swa.colormap = context->cmap = XCreateColormap(context->display, root,
      context->visual_info->visual, AllocNone);
    writeLog(log, stdout, DEBUG, "", "  Color map created\n");

    swa.background_pixmap = None;
    swa.border_pixel      = 0;
    swa.event_mask        = StructureNotifyMask;
    writeLog(log, stdout, DEBUG, "",
      "  XSetWindowAttributes structure initialized\n");

    writeLog(log, stdout, INFO, "", "  Querying root window attributes ...\n");
    XGetWindowAttributes(context->display, root, &(context->window_attribs));
    writeLog(log, stdout, INFO, "", "  Root window dimensions are: %ux%u\n",
      context->window_attribs.width, context->window_attribs.height);

    writeLog(log, stdout, INFO, "", "  Creating new X window ...\n");

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
      writeLog(log, (log->verbose ? stdout : stderr), ERROR, "  ",
        "Failed to create X window\n");

      status = false;
      break;
    }
    writeLog(log, stdout, INFO, "", "  X Window created: 0x%lx\n",
      context->window);

    writeLog(log, stdout, DEBUG, "", "  Allocating window manager hints ...\n");
    XWMHints* wmHint = XAllocWMHints();
    writeLog(log, stdout, DEBUG, "",
      "  Window manager hints allocated successfully\n");

    wmHint->flags = InputHint | StateHint;
    wmHint->input = false;
    wmHint->initial_state = NormalState;
    writeLog(log, stdout, DEBUG, "", "  Window manager hints declared\n");

    writeLog(log, stdout, DEBUG, "",
      "  Setting window manager properties ...\n");
    XSetWMProperties(context->display, context->window, NULL, NULL,
      NULL, 0, NULL, wmHint, NULL);
    writeLog(log, stdout, DEBUG, "", "  Window manager properties set\n");

    writeLog(log, stdout, DEBUG, "",
      "  Querying _NET_WM_WINDOW_TYPE atom identifier ...\n");
    Atom xa = XInternAtom(context->display, "_NET_WM_WINDOW_TYPE", False);
    writeLog(log, stdout, DEBUG, "",
      "  _NET_WM_WINDOW_TYPE atom identifier found\n");

    writeLog(log, stdout, DEBUG, "",
      "  Querying _NET_WM_WINDOW_TYPE_DESKTOP atom identifier ...\n");
    Atom prop =
      XInternAtom(context->display, "_NET_WM_WINDOW_TYPE_DESKTOP", False);
    writeLog(log, stdout, DEBUG, "",
      "  _NET_WM_WINDOW_TYPE_DESKTOP atom identifier found\n");

    writeLog(log, stdout, DEBUG, "", "  Discarding _NET_WM_WINDOW_TYPE %s",
      "property value and storing the new _NET_WM_WINDOW_TYPE_DESKTOP ...\n");
    XChangeProperty(context->display, context->window, xa, XA_ATOM, 32,
      PropModeReplace, (unsigned char*) &prop, 1);
    writeLog(log, stdout, DEBUG, "", "  _NET_WM_WINDOW_TYPE discarded and %s",
      "_NET_WM_WINDOW_TYPE_DESKTOP stored\n");

    writeLog(log, stdout, DEBUG, "",
      "  Querying _NET_WM_NAME atom identifier ...\n");
    xa = XInternAtom(context->display, "_NET_WM_NAME", False);
    writeLog(log, stdout, DEBUG, "", "  _NET_WM_NAME atom identifier found\n");

    writeLog(log, stdout, DEBUG, "",
      "  Querying UTF8_STRING atom identifier ...\n");
    Atom xa2 = XInternAtom(context->display, "UTF8_STRING", False);
    writeLog(log, stdout, DEBUG, "", "  UTF8_STRING atom identifier found\n");

    writeLog(log, stdout, DEBUG, "", "  Changing _NET_WM_NAME ...\n");
    char window_name[] = "spaceporn";
    XChangeProperty(context->display, context->window, xa, xa2, 8,
      PropModeReplace, (unsigned char*) window_name, strlen(window_name));
    writeLog(log, stdout, DEBUG, "", "  _NET_WM_NAME changed\n");

    writeLog(log, stdout, DEBUG, "",
      "  Querying _NET_WM_ICON_NAME atom identifier ...\n");
    xa = XInternAtom(context->display, "_NET_WM_ICON_NAME", False);
    writeLog(log, stdout, DEBUG, "",
      "  _NET_WM_ICON_NAME atom identifier found\n");

    writeLog(log, stdout, DEBUG, "", "  Changing _NET_WM_ICON_NAME ...\n");
    XChangeProperty(context->display, context->window, xa, xa2, 8,
      PropModeReplace, (unsigned char*) window_name, strlen(window_name));
    writeLog(log, stdout, DEBUG, "", "  _NET_WM_ICON_NAME changed\n");

    writeLog(log, stdout, DEBUG, "",
      "  Querying _NET_WM_PID atom identifier ...\n");
    xa = XInternAtom(context->display, "_NET_WM_PID", False);
    writeLog(log, stdout, DEBUG, "", "  _NET_WM_PID atom identifier found\n");

    writeLog(log, stdout, DEBUG, "", "  Changing _NET_WM_PID ...\n");
    long pid = getpid();
    XChangeProperty(context->display, context->window, xa, XA_CARDINAL, 32,
      PropModeReplace, (unsigned char*) &pid, 1);
    writeLog(log, stdout, DEBUG, "", "  _NET_WM_PID changed to %l\n", pid);

    int ret;
    char hostname[256];

    ret = gethostname(&hostname[0], 256);
    if (ret == -1)
    {
      perror("gethostname");
      status = false;
      break;
    }

    XTextProperty xtp;
    writeLog(log, stdout, DEBUG, "",
      "  Querying WM_CLIENT_MACHINE atom identifier ...\n");
    xa = XInternAtom(context->display, "WM_CLIENT_MACHINE", False);
    writeLog(log, stdout, DEBUG, "",
      "  WM_CLIENT_MACHINE atom identifier found\n");

    writeLog(log, stdout, DEBUG, "",
      "  Querying WM_CLIENT_MACHINE text property ...\n");
    XGetTextProperty(context->display, context->window, &xtp, xa);
    xtp.value = (unsigned char*) hostname;
    writeLog(log, stdout, DEBUG, "",
      "  WM_CLIENT_MACHINE text property found\n");

    writeLog(log, stdout, DEBUG, "", "  Changing WM_CLIENT_MACHINE ...\n");
    XSetWMClientMachine(context->display, context->window, &xtp);
    writeLog(log, stdout, DEBUG, "", "  WM_CLIENT_MACHINE changed to %s\n",
      hostname);

    writeLog(log, stdout, DEBUG, "", "  Freeing window manager hints ...\n");
    XFree(wmHint);
    writeLog(log, stdout, DEBUG, "", "  Window manager hints freed\n");

    writeLog(log, stdout, DEBUG, "", "  Mapping the newly created window ...\n");
    XMapWindow(context->display, context->window);
    writeLog(log, stdout, DEBUG, "", "  Newly created window mapped\n");
  } while (false);

  return status;
}

#if DEV
bool initDebugWindow(Context* context, Log* log)
{
  bool status = true;

  do
  {
    writeLog(log, stdout, DEBUG, "",
      "  Creating a debug window to catch key press events ...\n");

    if (log->roadmap.id != XCREATEKBWINDOW_FAILED_RM)
    {
      writeLog(log, stdout, INFO, "",
        "  Searching X root window from visual's screen ...\n");
      Window root = RootWindow(context->display, context->visual_info->screen);
      writeLog(log, stdout, INFO, "", "  X root window: 0x%lx\n", root);

      XSetWindowAttributes swa;

      writeLog(log, stdout, DEBUG, "",
        "  Creating color map from visual and root window ...\n");
      swa.colormap = context->cmap = XCreateColormap(context->display, root,
        context->visual_info->visual, AllocNone);
      writeLog(log, stdout, DEBUG, "", "  Color map created\n");

      swa.background_pixmap = None;
      swa.border_pixel      = 0;
      swa.event_mask        = StructureNotifyMask;
      writeLog(log, stdout, DEBUG, "",
      "  XSetWindowAttributes structure initialized\n");

      context->debug_window = XCreateWindow(context->display, root, 0, 0, 1,
        1, 0, context->visual_info->depth, InputOutput,
        context->visual_info->visual,
        CWBorderPixel | CWColormap | CWEventMask, &swa);
    }

    if (!context->debug_window)
    {
      writeLog(log, (log->verbose ? stdout : stderr), ERROR, "  ",
        "Failed to create debug window\n");

      status = false;
      break;
    }
    writeLog(log, stdout, DEBUG, "", "  Debug window created\n");

    writeLog(log, stdout, DEBUG, "",
      "  Querying _NET_WM_NAME atom identifier ...\n");
    Atom xa = XInternAtom(context->display, "_NET_WM_NAME", False);
    writeLog(log, stdout, DEBUG, "", "  _NET_WM_NAME atom identifier found\n");

    writeLog(log, stdout, DEBUG, "",
      "  Querying UTF8_STRING atom identifier ...\n");
    Atom xa2 = XInternAtom(context->display, "UTF8_STRING", False);
    writeLog(log, stdout, DEBUG, "", "  UTF8_STRING atom identifier found\n");

    writeLog(log, stdout, DEBUG, "", "  Changing _NET_WM_NAME ...\n");
    char window_name[] = "[debug] spaceporn";
    XChangeProperty(context->display, context->debug_window, xa, xa2, 8,
      PropModeReplace, (unsigned char*) window_name, strlen(window_name));
    writeLog(log, stdout, DEBUG, "", "  _NET_WM_NAME changed\n");

    writeLog(log, stdout, DEBUG, "",
      "  Querying _NET_WM_ICON_NAME atom identifier ...\n");
    xa = XInternAtom(context->display, "_NET_WM_ICON_NAME", False);
    writeLog(log, stdout, DEBUG, "",
      "  _NET_WM_ICON_NAME atom identifier found\n");

    writeLog(log, stdout, DEBUG, "", "  Changing _NET_WM_ICON_NAME ...\n");
    XChangeProperty(context->display, context->debug_window, xa, xa2, 8,
      PropModeReplace, (unsigned char*) window_name, strlen(window_name));
    writeLog(log, stdout, DEBUG, "", "  _NET_WM_ICON_NAME changed\n");

    writeLog(log, stdout, DEBUG, "",
      "  Querying _NET_WM_PID atom identifier ...\n");
    xa = XInternAtom(context->display, "_NET_WM_PID", False);
    writeLog(log, stdout, DEBUG, "", "  _NET_WM_PID atom identifier found\n");

    writeLog(log, stdout, DEBUG, "", "  Changing _NET_WM_PID ...\n");
    long pid = getpid();
    XChangeProperty(context->display, context->debug_window, xa, XA_CARDINAL,
      32, PropModeReplace, (unsigned char*) &pid, 1);
    writeLog(log, stdout, DEBUG, "", "  _NET_WM_PID changed to %l\n", pid);

    XTextProperty xtp;
    writeLog(log, stdout, DEBUG, "",
      "  Querying WM_CLIENT_MACHINE atom identifier ...\n");
    xa = XInternAtom(context->display, "WM_CLIENT_MACHINE", False);
    writeLog(log, stdout, DEBUG, "",
      "  WM_CLIENT_MACHINE atom identifier found\n");

    writeLog(log, stdout, DEBUG, "",
      "  Querying WM_CLIENT_MACHINE text property ...\n");
    XGetTextProperty(context->display, context->window, &xtp, xa);
    writeLog(log, stdout, DEBUG, "",
      "  WM_CLIENT_MACHINE text property found\n");

    writeLog(log, stdout, DEBUG, "", "  Changing WM_CLIENT_MACHINE ...\n");
    XSetWMClientMachine(context->display, context->debug_window, &xtp);
    writeLog(log, stdout, DEBUG, "", "  WM_CLIENT_MACHINE changed to %s\n",
      xtp.value);

    writeLog(log, stdout, DEBUG, "",
      "  Requesting X server to report key press events for debug window ...\n");
    XSelectInput(context->display, context->debug_window, KeyPressMask);
    writeLog(log, stdout, DEBUG, "",
      "  X server is now reporting key press events for debug window\n");

    writeLog(log, stdout, DEBUG, "", "  Mapping debug window ...\n");
    XMapWindow(context->display, context->debug_window);
    writeLog(log, stdout, DEBUG, "", "  Debug window mapped\n");
  } while (false);

  return status;
}
#endif

bool initContext(Context* context, Log* log)
{
  bool status = true;

  do
  {
    writeLog(log, stdout, DEBUG, "", "  Opening X Display ...\n");

    if (log->roadmap.id != XOPENDISPLAY_FAILED_RM)
    {
      context->display = XOpenDisplay(NULL);
    }

    if (!context->display)
    {
      writeLog(log, (log->verbose ? stdout : stderr), ERROR, "  ",
        "Failed to open X display\n");

      status = false;
      break;
    }
    writeLog(log, stdout, DEBUG, "", "  X Display opened\n");

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

    writeLog(log, stdout, INFO, "",
      "  Querying the default screen's GLX extensions list ...\n");
    const char* glxExts = glXQueryExtensionsString(context->display,
      DefaultScreen(context->display));
    writeLog(log, stdout, INFO, "",
      "  Default screen's GLX extensions list is:\n");
    unsigned s = 0;
    unsigned e = 0;
    while (s < strlen(glxExts))
    {
      e = strcspn(glxExts + s, " ");
      writeLog(log, stdout, INFO, "", "  - %.*s\n", e, glxExts + s);
      s += e + 1;
    }

    writeLog(log, stdout, DEBUG, "",
      "  Querying pointer to glXCreateContextAttribsARB() function ...\n");
    glXCreateContextAttribsARBProc glXCreateContextAttribsARB = 0;
    if (log->roadmap.id != GLXCREATECONTEXTATTRIBSARB_UNFOUNDABLE_RM)
    {
      glXCreateContextAttribsARB = (glXCreateContextAttribsARBProc)
        glXGetProcAddressARB((const GLubyte *) "glXCreateContextAttribsARB");
    }

    writeLog(log, stdout, DEBUG, "", "    Installing X error handler ...\n");
    contextErrorOccurred = false;
    int (*oldHandler)(Display*, XErrorEvent*) =
      XSetErrorHandler(&contextErrorHandler);
    writeLog(log, stdout, DEBUG, "", "    X error handler installed\n");

    if (!glXCreateContextAttribsARB)
    {
      writeLog(log, (log->verbose ? stdout : stderr), ERROR, "  ",
        "Unable to found glXCreateContextAttribsARB()\n");

      writeLog(log, stdout, DEBUG, "",
        "  Restoring original X error handler ...\n");
      XSetErrorHandler(oldHandler);
      writeLog(log, stdout, DEBUG, "", "  Original X error handler restored\n");

      status = false;
      break;
    }
    writeLog(log, stdout, DEBUG, "",
      "  Pointer to glXCreateContextAttribsARB() found\n");

    writeLog(log, stdout, DEBUG, "", "  Testing GLX extension support ...\n");
    if (!isExtensionSupported(glxExts, (log->roadmap.id == SPACE_IN_GLX_EXT_RM ?
      "GLX_ARB_create_context " : "GLX_ARB_create_context"), log))
    {
      writeLog(log, (log->verbose ? stdout : stderr), ERROR, "  ",
        "GLX extension not supported\n");

      writeLog(log, stdout, DEBUG, "",
        "  Restoring original X error handler ...\n");
      XSetErrorHandler(oldHandler);
      writeLog(log, stdout, DEBUG, "", "  Original X error handler restored\n");

      status = false;
      break;
    }
    writeLog(log, stdout, DEBUG, "", "  Extension supported\n");

    int context_attribs[] =
    {
      GLX_CONTEXT_MAJOR_VERSION_ARB, 3,
      GLX_CONTEXT_MINOR_VERSION_ARB, 3,
      None
    };

    writeLog(log, stdout, DEBUG, "", "  Initializing the context to the %s",
      "initial state defined by the OpenGL specification ...\n");
    if (log->roadmap.id != CONTEXT_CREATION_FAILED_RM)
    {
      context->glx_context = glXCreateContextAttribsARB(context->display,
        bestFbc, 0, True, context_attribs);
    }
    writeLog(log, stdout, DEBUG, "", "  Context initialized to the %s",
      "initial state defined by the OpenGL specification\n");

    // Sync to ensure any errors generated are processed.
    writeLog(log, stdout, DEBUG, "",
      "  Synchronizing generated X errors ...\n");
    XSync(context->display, False);
    writeLog(log, stdout, DEBUG, "", "  Generated X errors synchronized\n");

    writeLog(log, stdout, DEBUG, "",
      "  Restoring original X error handler ...\n");
    XSetErrorHandler(oldHandler);
    writeLog(log, stdout, DEBUG, "", "  Original X error handler restored\n");

    writeLog(log, stdout, INFO, "",
      "  Testing X error generation during context creation ...\n");
    if (contextErrorOccurred || !context->glx_context)
    {
      writeLog(log, (log->verbose ? stdout : stderr), ERROR, "  ",
        "An X error occured during creation context\n");

      status = false;
      break;
    }
    writeLog(log, stdout, INFO, "",
      "  No X error occured during context creation\n");

    writeLog(log, stdout, DEBUG, "", "  Attaching the current rendering %s",
      "context to the newly created window ...\n");
    glXMakeCurrent(context->display, context->window, context->glx_context);
    writeLog(log, stdout, DEBUG, "",
      "  Current rendering context attached to the newly created window\n");

    writeLog(log, stdout, DEBUG, "", "  Requesting X server to report %s",
      "exposure events for current window ...\n");
    XSelectInput(context->display, context->window, ExposureMask);
    writeLog(log, stdout, DEBUG, "",
      "  X server is now reporting exposure events for current window\n");

    writeLog(log, stdout, DEBUG, "", "  Initializing GLEW ...\n");
    glewExperimental = GL_TRUE;

    GLenum err=glewInit();

    if ((err != GLEW_OK) || (log->roadmap.id == GLEWINIT_FAILED_RM))
    {
      writeLog(log, (log->verbose ? stdout : stderr), ERROR, "  ",
        "glewInit() failed: %s\n", glewGetErrorString(err));

      status = false;
      break;
    }
    writeLog(log, stdout, DEBUG, "", "  GLEW initialized\n");

    writeLog(log, stdout, DEBUG, "",
      "  Enabling transparency for current window ...\n");
    GL_CHECK(glEnable(GL_BLEND), status, log);
    writeLog(log, stdout, DEBUG, "",
      "  Transparency enabled for current window\n");

    writeLog(log, stdout, DEBUG, "",
      "  Selecting transparency function for current window ...\n");
    GL_CHECK(glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA), status, log);
    writeLog(log, stdout, DEBUG, "",
      "  Transparency function selected for current window\n");

    writeLog(log, stdout, DEBUG, "",
      "  Disablings rendering of back face of drawn triangles ...\n");
    GL_CHECK(glCullFace(GL_BACK), status, log);
    writeLog(log, stdout, DEBUG, "",
      "  Rendering back face of drawn triangles disabled ...\n");

    writeLog(log, stdout, DEBUG, "", "  Enabling backface culling ...\n");
    GL_CHECK(glEnable(GL_CULL_FACE), status, log);
    writeLog(log, stdout, DEBUG, "", "  Backface culling enabled\n");

    writeLog(log, stdout, DEBUG, "", "  Enabling Depth buffer ...\n");
    GL_CHECK(glDepthFunc(GL_LESS), status, log);
    GL_CHECK(glEnable(GL_DEPTH_TEST), status, log);
    writeLog(log, stdout, DEBUG, "", "  Depth buffer enabled\n");

    writeLog(log, stdout, INFO, "",
      "  Querying maximum array textures layers ...\n");
    int max_arraytextures_layers;
    glGetIntegerv(GL_MAX_ARRAY_TEXTURE_LAYERS, &max_arraytextures_layers);
    writeLog(log, stdout, INFO, "", "  Maximum array textures layers is %d\n",
      max_arraytextures_layers);

    writeLog(log, stdout, INFO, "",
      "  Querying maximum renderbuffer size ...\n");
    int max_rb_size;
    glGetIntegerv(GL_MAX_RENDERBUFFER_SIZE, &max_rb_size);
    writeLog(log, stdout, INFO, "", "  Maximum renderbuffer size is %d\n",
      max_rb_size);

    writeLog(log, stdout, INFO, "",
      "  Querying maximum viewport dimensions ...\n");
    int max_viewport_dims[2];
    glGetIntegerv(GL_MAX_VIEWPORT_DIMS, &(*max_viewport_dims));
    writeLog(log, stdout, INFO, "", "  Maximum viewport dimensions are %dx%d\n",
      max_viewport_dims[0], max_viewport_dims[1]);

    writeLog(log, stdout, INFO, "", "  Querying maximum texture size ...\n");
    int max_texture_size;
    glGetIntegerv(GL_MAX_TEXTURE_SIZE, &max_texture_size);
    writeLog(log, stdout, INFO, "", "  Maximum texture size is %d\n",
      max_texture_size);

#if DEV
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
    writeLog(log, stdout, DEBUG, "",
      "Detaching current rendering context ...\n");
    glXMakeCurrent(context->display, 0, 0);
    writeLog(log, stdout, DEBUG, "", "Current rendering context detached\n");

    writeLog(log, stdout, DEBUG, "",
      "Destroying detached rendering context ...\n");
    glXDestroyContext(context->display, context->glx_context);
    writeLog(log, stdout, DEBUG, "",
      "Detached rendering context destroyed\n");
  }

#if DEV
  if (context->debug_window)
  {
    writeLog(log, stdout, DEBUG, "", "Unmapping debug window ...\n");
    XUnmapWindow(context->display, context->debug_window);
    writeLog(log, stdout, DEBUG, "", "Debug window unmapped\n");

    writeLog(log, stdout, DEBUG, "", "Destroying debug window ...\n");
    XDestroyWindow(context->display, context->debug_window);
    writeLog(log, stdout, DEBUG, "", "Debug window destroyed\n");
  }
#endif

  if (context->visual_info)
  {
    writeLog(log, stdout, DEBUG, "", "Freeing current visual ...\n");
    XFree(context->visual_info);
    writeLog(log, stdout, DEBUG, "", "Current visual freed\n");
  }

  if (context->cmap)
  {
    writeLog(log, stdout, DEBUG, "", "Freeing colormap ...\n");
    XFreeColormap(context->display, context->cmap);
    writeLog(log, stdout, DEBUG, "", "Colormap freed\n");
  }

  if (context->window)
  {
    writeLog(log, stdout, DEBUG, "", "Unmapping current window ...\n");
    XUnmapWindow(context->display, context->window);
    writeLog(log, stdout, DEBUG, "", "Current window unmapped\n");

    writeLog(log, stdout, DEBUG, "", "Destroying current window ...\n");
    XDestroyWindow(context->display, context->window);
    writeLog(log, stdout, DEBUG, "", "Current window destroyed\n");
  }

  if (context->display)
  {
    writeLog(log, stdout, DEBUG, "", "Closing Display ...\n");
    XCloseDisplay(context->display);
    writeLog(log, stdout, DEBUG, "", "Display closed\n");
  }
}
