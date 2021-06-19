// for attributes in CONTEXT_GLFW_T struct
#define GLFW_INCLUDE_VULKAN
#include <GLFW/glfw3.h>

// for attributes in CONTEXT_GLFW_T struct
#include "extensions.h"

// for MALLOC macros
#include "helpers.h"

#define CONTEXT_GLFW_T PREFIX_TYPE(context_glfw)

STRUCT
  ATTR
    GLFWwindow*   win;
    EXTENSIONS_T* ext;
  NAME
    CONTEXT_GLFW_T;
ENDSTRUCT

PROTO init_glfw    ARGS CONTEXT_GLFW_T* glfw ENDPROTO;
PROTO loop_glfw    ARGS CONTEXT_GLFW_T* glfw ENDPROTO;
PROTO cleanup_glfw ARGS CONTEXT_GLFW_T* glfw ENDPROTO;
