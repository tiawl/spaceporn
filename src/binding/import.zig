//pub usingnamespace @cImport ({
pub const c = @cImport ({
  @cDefine ("GLFW_INCLUDE_VULKAN", "1");
  @cDefine ("GLFW_INCLUDE_NONE", "1");
  @cInclude ("GLFW/glfw3.h");
  @cInclude ("cimgui.h");
  @cInclude ("cimgui_impl_glfw.h");
  @cInclude ("cimgui_impl_vulkan.h");
});
