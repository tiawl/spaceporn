pub usingnamespace @cImport ({
  @cDefine ("GLFW_INCLUDE_VULKAN", {});
  @cInclude ("GLFW/glfw3.h");
  @cInclude ("vulkan/vulkan.h");
  @cInclude ("cimgui.h");
  @cInclude ("cimgui_impl_glfw.h");
  @cInclude ("cimgui_impl_vulkan.h");
});
