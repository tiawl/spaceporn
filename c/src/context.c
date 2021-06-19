#include "context.h"

FUNC init ARGS CONTEXT_T* context
DO
  MALLOC(context->glfw, sizeof(CONTEXT_GLFW_T));
  MALLOC(context->vulkan, sizeof(CONTEXT_VULKAN_T));

  CALL init_glfw   WITH context->glfw                               ENDCALL;
  CALL copy_ext    WITH context->glfw->ext, &(context->vulkan->ext) ENDCALL;
  CALL init_vulkan WITH context->vulkan                             ENDCALL;

  SUCCESS;
DONE

FUNC loop ARGS CONTEXT_T* context
DO
  CALL loop_glfw   WITH context->glfw   ENDCALL;
  CALL loop_vulkan WITH context->vulkan ENDCALL;

  SUCCESS;
DONE

FUNC cleanup ARGS CONTEXT_T* context
DO
  CALL cleanup_vulkan WITH context->vulkan ENDCALL;
  CALL cleanup_glfw   WITH context->glfw   ENDCALL;

  CALL free WITH context->glfw   ENDCALL;
  CALL free WITH context->vulkan ENDCALL;

  SUCCESS;
DONE
