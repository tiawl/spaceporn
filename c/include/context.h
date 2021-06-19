#include "context_glfw.h"
#include "context_vulkan.h"

#define CONTEXT_T PREFIX_TYPE(context)

STRUCT
  ATTR
    CONTEXT_GLFW_T*   glfw;
    CONTEXT_VULKAN_T* vulkan;
  NAME
    CONTEXT_T;
ENDSTRUCT

PROTO init    ARGS CONTEXT_T* context ENDPROTO;
PROTO loop    ARGS CONTEXT_T* context ENDPROTO;
PROTO cleanup ARGS CONTEXT_T* context ENDPROTO;
