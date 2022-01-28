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
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
    glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);

    glfwWindowHint(GLFW_DECORATED, GLFW_FALSE);

    GLFWmonitor* monitor = glfwGetPrimaryMonitor();
    const GLFWvidmode* mode = glfwGetVideoMode(monitor);

    context->width = mode->width;
    context->height = mode->height;

    context->window = glfwCreateWindow(context->width, context->height, "",
      monitor, NULL);
    if (context->window == NULL)
    {
      fprintf(stderr, "Failed to open GLFW window. %s\n",
        "If you have an Intel GPU, they are not 3.3 compatible.");

      status = false;
      break;
    }

    glfwSetKeyCallback(context->window, key_callback);

    glfwMakeContextCurrent(context->window);

    glfwSetInputMode(context->window, GLFW_STICKY_KEYS, GLFW_TRUE);

  } while (false);

  return status;
}

bool initContext(Context* context, Log* log)
{
  bool status = true;

  do
  {
    if (!glfwInit())
    {
      writeLog(log, (log->verbose ? stdout : stderr), "  ",
        "glfwInit() failed: %s\n");

      status = false;
      break;
    }

    if (!initWindow(context, log))
    {
      status = false;
      break;
    }

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

    glfwSwapInterval(1);

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
  glfwDestroyWindow(context->window);
  glfwTerminate();
}
