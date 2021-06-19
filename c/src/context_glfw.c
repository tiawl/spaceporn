#include "context_glfw.h"

FUNC init_glfw ARGS CONTEXT_GLFW_T* glfw
DO
  CALL glfwInit WITH NOARG;

  CALL glfwWindowHint WITH GLFW_CLIENT_API, GLFW_NO_API ENDCALL;
  CALL glfwWindowHint WITH GLFW_RESIZABLE,  GLFW_FALSE  ENDCALL;
  //glfwWindowHint(GLFW_DECORATED, GLFW_FALSE);

  glfw->win = CALL glfwCreateWindow WITH 800, 600, EXE, NULL, NULL ENDCALL;
  MALLOC(glfw->ext, sizeof(EXTENSIONS_T));

  glfw->ext->count = 0;
  glfw->ext->list = (char**) CALL glfwGetRequiredInstanceExtensions WITH &(glfw->ext->count) ENDCALL;

  SUCCESS;
DONE

FUNC loop_glfw ARGS CONTEXT_GLFW_T* glfw
DO
  WHILE NOT CALL glfwWindowShouldClose WITH glfw->win ENDCALL
  DO
    CALL glfwPollEvents WITH NOARG;
  DONE

  SUCCESS;
DONE

FUNC cleanup_glfw ARGS CONTEXT_GLFW_T* glfw
DO
  CALL free              WITH glfw->ext          ENDCALL;
  CALL glfwDestroyWindow WITH glfw->win          ENDCALL;
  CALL glfwTerminate     WITH NOARG;

  SUCCESS;
DONE
