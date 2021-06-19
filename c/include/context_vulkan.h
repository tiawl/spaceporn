// for attributes in CONTEXT_VULKAN_T struct
#define GLFW_INCLUDE_VULKAN
#include <GLFW/glfw3.h>

// for strcmp()
#include <string.h>

// for attributes in CONTEXT_VULKAN_T struct
#include "extensions.h"

// for error() function
#include "log.h"

// for MALLOC/REALLOC macros
#include "helpers.h"

#define CALL_VK(name, ...)                                                                           \
DEF                                                                                                  \
  PFN_ ## name func = (PFN_ ## name) CALL vkGetInstanceProcAddr WITH *(vk->instance), #name ENDCALL; \
  IF func(__VA_ARGS__) != VK_SUCCESS                                                                 \
  THEN                                                                                               \
    ERROR("%s failed", #name);                                                                       \
  ENDIF                                                                                              \
ENDDEF

#define CALL_VOID_VK(name, ...)                                                                      \
DEF                                                                                                  \
  PFN_ ## name func = (PFN_ ## name) CALL vkGetInstanceProcAddr WITH *(vk->instance), #name ENDCALL; \
  func(__VA_ARGS__);                                                                                 \
ENDDEF

#define CONTEXT_VULKAN_T PREFIX_TYPE(context_vulkan)

STRUCT
  ATTR
    VkInstance*                         instance;
    VkApplicationInfo*                  app_info;
    VkInstanceCreateInfo*               create_info;
#if BUILD == DEV_BUILD
    VkDebugUtilsMessengerEXT*           debug_messenger;
    VkDebugUtilsMessengerCreateInfoEXT* debug_info;
#endif
    const char*                         layers[PREFIX_MACRO(VK_LAYERS_COUNT)];
    uint32_t                            layers_count;
    EXTENSIONS_T*                       ext;
  NAME
    CONTEXT_VULKAN_T;
ENDSTRUCT

PROTO check_layer_support ARGS CONTEXT_VULKAN_T* vk                           ENDPROTO;
PROTO init_debug_info     ARGS VkDebugUtilsMessengerCreateInfoEXT* debug_info ENDPROTO;
PROTO check_vk_func       ARGS CONTEXT_VULKAN_T* vk                           ENDPROTO;
PROTO init_vk_instance    ARGS CONTEXT_VULKAN_T* vk                           ENDPROTO;
PROTO init_vulkan         ARGS CONTEXT_VULKAN_T* vk                           ENDPROTO;
PROTO loop_vulkan         ARGS /*CONTEXT_VULKAN_T* vk*/                       ENDPROTO;
PROTO cleanup_vulkan      ARGS CONTEXT_VULKAN_T* vk                           ENDPROTO;
