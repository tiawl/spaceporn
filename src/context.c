#include "context.h"

#if DEBUG
static void key_callback(GLFWwindow* window, int key, int scancode,
  int action, int mods)
{
  if ((key == GLFW_KEY_ESCAPE) && (action == GLFW_PRESS))
  {
    glfwSetWindowShouldClose(window, GLFW_TRUE);
  }
}
#endif

bool initWindow(Context* context, Log* log)
{
  bool status = true;

  do
  {
    writeLog(log, stdout, "", "    Requesting primary monitor ...\n");
    GLFWmonitor* monitor = glfwGetPrimaryMonitor();
    writeLog(log, stdout, "", "    Primary monitor returned\n");

    writeLog(log, stdout, "", "    Requesting video mode associated to %s\n",
      "primary monitor ...");
    const GLFWvidmode* mode = glfwGetVideoMode(monitor);

    context->width = mode->width;
    context->height = mode->height;
    writeLog(log, stdout, "", "    Video mode returned %s %dx%d\n",
      "with dimensions:", context->width, context->height);

    writeLog(log, stdout, "", "    Initializing window hint ...\n");
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
    glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
    glfwWindowHint(GLFW_DECORATED, GLFW_FALSE);
    glfwWindowHint(GLFW_FOCUSED, GLFW_FALSE);
    glfwWindowHint(GLFW_AUTO_ICONIFY, GLFW_FALSE);
    glfwWindowHint(GLFW_RED_BITS, mode->redBits);
    glfwWindowHint(GLFW_GREEN_BITS, mode->greenBits);
    glfwWindowHint(GLFW_BLUE_BITS, mode->blueBits);
    glfwWindowHint(GLFW_REFRESH_RATE, mode->refreshRate);
    writeLog(log, stdout, "", "    Window hint initialized\n");

    writeLog(log, stdout, "", "    Opening GLFW window\n");
    context->window = glfwCreateWindow(context->width, context->height, "",
      monitor, NULL);
    if ((context->window == NULL) ||
      (log->roadmap.id == GLFWCREATEWINDOW_FAILED_RM))
    {
      fprintf(stderr, "Failed to open GLFW window. %s\n",
        "If you have an Intel GPU, they are not 3.3 compatible.");

      status = false;
      break;
    }
    writeLog(log, stdout, "", "    GLFW window opened\n");

#if DEBUG
    writeLog(log, stdout, "", "    Setting GLFW window key callback ...\n");
    glfwSetKeyCallback(context->window, key_callback);
    writeLog(log, stdout, "", "    Key callback associated with GLFW window\n");
#endif

  } while (false);

  return status;
}

bool initContext(Context* context, Log* log)
{
  bool status = true;

  do
  {
    writeLog(log, stdout, "", "  Initializing GLFW ...\n");
    if (!glfwInit() || (log->roadmap.id == GLFWINIT_FAILED_RM))
    {
      writeLog(log, (log->verbose ? stdout : stderr), "  ",
        "GLFW failed to initialize\n");

      status = false;
      break;
    }
    writeLog(log, stdout, "", "  GLFW initialized\n");

    writeLog(log, stdout, "", "  Creating window ...\n");
    if (!initWindow(context, log))
    {
      writeLog(log, (log->verbose ? stdout : stderr), "  ",
        "GLFW failed to created window\n");

      status = false;
      break;
    }
    writeLog(log, stdout, "", "  Window created\n");

    writeLog(log, stdout, "", "  Initializing GLFW context ...\n");
    glfwMakeContextCurrent(context->window);
    writeLog(log, stdout, "", "  GLFW context initialized\n");

    writeLog(log, stdout, "", "  Setting sticky keys ...\n");
    glfwSetInputMode(context->window, GLFW_STICKY_KEYS, GLFW_TRUE);
    writeLog(log, stdout, "", "  Sticky keys set\n");

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

    writeLog(log, stdout, "", "  Setting swap interval ...\n");
    glfwSwapInterval(1);
    writeLog(log, stdout, "", "  Swap interval set\n");

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

  } while (false);

  return status;
}

void freeContext(Context* context, Log* log)
{
  writeLog(log, stdout, "", "Destroying window ...\n");
  glfwDestroyWindow(context->window);
  writeLog(log, stdout, "", "Window destroyed\n");

  writeLog(log, stdout, "", "Terminating GLFW ...\n");
  glfwTerminate();
  writeLog(log, stdout, "", "GLFW terminated\n");
}
