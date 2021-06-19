#include "context_vulkan.h"

FUNC_VK debug_callback ARGS VkDebugUtilsMessageSeverityFlagBitsEXT vk_severity,
        VkDebugUtilsMessageTypeFlagsEXT vk_type,
        const VkDebugUtilsMessengerCallbackDataEXT* vk_callback,
        void* user
DO
  char * severity;
  char * type;
  FILE * fd = stdout;

  FILE* log_file = CALL fopen WITH LOGFILE, "a" ENDCALL;
  IF NOT log_file
  THEN
    CALL fprintf WITH stderr, "%s fopen(%s) failed\n", ERROR_PREFIX, LOGFILE ENDCALL;
    FAILURE;
  ENDIF

  SWITCH vk_severity IN

    CASE VK_DEBUG_UTILS_MESSAGE_SEVERITY_VERBOSE_BIT_EXT:
      severity = "VERBOSE";
    ENDCASE

    CASE VK_DEBUG_UTILS_MESSAGE_SEVERITY_INFO_BIT_EXT:
      severity = "INFO";
    ENDCASE

    CASE VK_DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT_EXT:
      severity = "WARNING";
    ENDCASE

    CASE VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT:
      severity = "ERROR";
      fd = stderr;
    ENDCASE

    DEFAULT:
    ENDDEFAULT
  ENDSWITCH

  SWITCH vk_type IN

    CASE VK_DEBUG_UTILS_MESSAGE_TYPE_GENERAL_BIT_EXT:
      type = "GENERAL";
    ENDCASE

    CASE VK_DEBUG_UTILS_MESSAGE_TYPE_VALIDATION_BIT_EXT:
      type = "VALIDATION";
    ENDCASE

    CASE VK_DEBUG_UTILS_MESSAGE_TYPE_PERFORMANCE_BIT_EXT:
      type = "PERFORMANCE";
    ENDCASE

    DEFAULT:
    ENDDEFAULT
  ENDSWITCH
  CALL fprintf WITH fd, VULKAN_LOG                      ENDCALL;

  time_t raw_time = CALL time WITH NULL                 ENDCALL;
  struct tm * time_info = CALL localtime WITH &raw_time ENDCALL;

  CALL fprintf WITH log_file, CURRENT_TIME              ENDCALL;
  CALL fprintf WITH log_file, VULKAN_LOG                ENDCALL;
  CALL fclose  WITH log_file                            ENDCALL;

  FAILURE_VK;
DONE

FUNC init_debug_info ARGS VkDebugUtilsMessengerCreateInfoEXT* debug_info
DO
  debug_info->sType = VK_STRUCTURE_TYPE_DEBUG_UTILS_MESSENGER_CREATE_INFO_EXT;
  debug_info->messageSeverity = VK_DEBUG_UTILS_MESSAGE_SEVERITY_VERBOSE_BIT_EXT
    | VK_DEBUG_UTILS_MESSAGE_SEVERITY_INFO_BIT_EXT
    | VK_DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT_EXT
    | VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT;
  debug_info->messageType = VK_DEBUG_UTILS_MESSAGE_TYPE_GENERAL_BIT_EXT
    | VK_DEBUG_UTILS_MESSAGE_TYPE_VALIDATION_BIT_EXT
    | VK_DEBUG_UTILS_MESSAGE_TYPE_PERFORMANCE_BIT_EXT;
  debug_info->pfnUserCallback = debug_callback;
  SUCCESS;
DONE

FUNC check_vk_func ARGS CONTEXT_VULKAN_T* vk
DO
  const char * names[] =
  {
    "vkCreateDebugUtilsMessengerEXT", "vkDestroyDebugUtilsMessengerEXT",
  };
  void* func = NULL;

  FOR uint32_t i = 0; i < sizeof(names) / sizeof(const char *); i++
  DO
    func = CALL vkGetInstanceProcAddr WITH *(vk->instance), names[i] ENDCALL;
    IF NOT func
    THEN
      ERROR("'%s' extension function not supported", names[i]);
      FAILURE;
    ELSE
      CALL debug WITH "'%s' extension function supported", names[i] ENDCALL;
    ENDIF
  DONE
  SUCCESS;
DONE

FUNC init_vk_instance ARGS CONTEXT_VULKAN_T* vk
DO
  MALLOC(vk->instance, sizeof(VkInstance));
  MALLOC(vk->app_info, sizeof(VkApplicationInfo));
  MALLOC(vk->create_info, sizeof(VkInstanceCreateInfo));

  vk->app_info->sType              = VK_STRUCTURE_TYPE_APPLICATION_INFO;
  vk->app_info->pApplicationName   = EXE;
  vk->app_info->applicationVersion = VK_MAKE_VERSION(1, 0, 0);
  vk->app_info->pEngineName        = "No Engine";
  vk->app_info->engineVersion      = VK_MAKE_VERSION(1, 0, 0);
  vk->app_info->apiVersion         = VK_API_VERSION_1_0;

#if BUILD == DEV_BUILD
  REALLOC(vk->ext->list, sizeof(char *) * (vk->ext->count + 1));
  uint32_t len = strlen(VK_EXT_DEBUG_UTILS_EXTENSION_NAME);
  MALLOC(vk->ext->list[vk->ext->count], sizeof(char) * len + 1);
  CALL memset WITH vk->ext->list[vk->ext->count], 0, len + 1 ENDCALL;
  CALL memcpy WITH vk->ext->list[vk->ext->count], VK_EXT_DEBUG_UTILS_EXTENSION_NAME, sizeof(char) * len ENDCALL;
  vk->ext->count = vk->ext->count + 1;

  vk->create_info->enabledLayerCount   = vk->layers_count;
  vk->create_info->ppEnabledLayerNames = vk->layers;

  VkDebugUtilsMessengerCreateInfoEXT debug_info;

  CALL init_debug_info WITH &debug_info ENDCALL;

  vk->create_info->pNext = (VkDebugUtilsMessengerCreateInfoEXT*) &debug_info;
#else
  vk->create_info->enabledLayerCount   = 0;
#endif

  vk->create_info->sType                   = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO;
  vk->create_info->pApplicationInfo        = vk->app_info;
  vk->create_info->enabledExtensionCount   = vk->ext->count;
  vk->create_info->ppEnabledExtensionNames = (const char * const *) vk->ext->list;

  IF CALL vkCreateInstance WITH vk->create_info, NULL, vk->instance ENDCALL != VK_SUCCESS
  THEN
    ERROR("Failed to create Vulkan instance");
    FAILURE;
  ENDIF

#if BUILD == DEV_BUILD
  check_vk_func(vk);

  VkExtensionProperties* prop;
  uint32_t prop_count;

  CALL vkEnumerateInstanceExtensionProperties WITH NULL, &prop_count, NULL ENDCALL;

  MALLOC(prop, prop_count * sizeof(VkExtensionProperties));

  CALL vkEnumerateInstanceExtensionProperties WITH NULL, &prop_count, prop ENDCALL;

  FOR uint32_t i = 0; i < prop_count; i++
  DO
    CALL debug WITH "'%s' extension available", prop[i].extensionName ENDCALL;
  DONE

  MALLOC(vk->debug_messenger, sizeof(VkDebugUtilsMessengerEXT));
  MALLOC(vk->debug_info, sizeof(VkDebugUtilsMessengerCreateInfoEXT));

  CALL init_debug_info WITH vk->debug_info ENDCALL;

  CALL_VK(vkCreateDebugUtilsMessengerEXT, *(vk->instance), vk->debug_info, NULL, vk->debug_messenger);
#endif

  SUCCESS;
DONE

FUNC check_layer_support ARGS CONTEXT_VULKAN_T* vk
DO
  vk->layers_count = PREFIX_MACRO(VK_LAYERS_COUNT);
  vk->layers[0] = "VK_LAYER_KHRONOS_validation";

  uint32_t available_layers_count;
  CALL vkEnumerateInstanceLayerProperties WITH &available_layers_count, NULL ENDCALL;

  VkLayerProperties* available_layers = NULL;
  MALLOC(available_layers, available_layers_count * sizeof(VkLayerProperties));

  CALL vkEnumerateInstanceLayerProperties WITH &available_layers_count, available_layers ENDCALL;

  FOR uint32_t i = 0; i < vk->layers_count; i++
  DO
    FUNC layer_found = FALSE;

    FOR uint32_t j = 0; j < available_layers_count; j++
    DO
      IF CALL strcmp WITH vk->layers[i], available_layers[j].layerName ENDCALL == 0
      THEN
        layer_found = TRUE;
        BREAK;
      ENDIF
    DONE

    IF NOT layer_found
    THEN
      FAILURE;
    ENDIF
  DONE

  CALL free WITH available_layers ENDCALL;
  SUCCESS;
DONE

FUNC init_vulkan ARGS CONTEXT_VULKAN_T* vk
DO
#if BUILD == DEV_BUILD
  IF NOT CALL check_layer_support WITH vk ENDCALL
  THEN
    ERROR("Validation layers unavailable");
    FAILURE;
  ENDIF
#endif

  CALL init_vk_instance WITH vk ENDCALL;

  SUCCESS;
DONE

FUNC loop_vulkan ARGS /*CONTEXT_VULKAN_T* vk*/
DO
  SUCCESS;
DONE

FUNC cleanup_vulkan ARGS CONTEXT_VULKAN_T* vk
DO
#if BUILD == DEV_BUILD
  CALL_VOID_VK(vkDestroyDebugUtilsMessengerEXT, *(vk->instance), *(vk->debug_messenger), NULL);
  CALL free              WITH vk->debug_info        ENDCALL;
  CALL free              WITH vk->debug_messenger   ENDCALL;
#endif
  CALL vkDestroyInstance WITH *(vk->instance), NULL ENDCALL;
  CALL free              WITH vk->instance          ENDCALL;
  CALL free              WITH vk->app_info          ENDCALL;
  CALL free              WITH vk->create_info       ENDCALL;

  FOR uint32_t i = 0; i < vk->ext->count; ++i
  DO
    CALL free            WITH vk->ext->list[i]      ENDCALL;
  DONE
  CALL free              WITH vk->ext->list         ENDCALL;
  CALL free              WITH vk->ext               ENDCALL;

  SUCCESS;
DONE
