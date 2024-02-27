const c = @import ("c");

pub const Vulkan = struct
{
  pub const VKProc = *const fn () callconv (.C) void;

  pub fn supported () bool
  {
    return c.glfwVulkanSupported () == c.GLFW_TRUE;
  }

  pub fn getInstanceProcAddress (instance: ?*anyopaque, name: [*:0] const u8) callconv (.C) ?VKProc
  {
    if (c.glfwGetInstanceProcAddress (if (instance) |v| @as (c.VkInstance, @ptrCast (v)) else null, name)) |addr|
      return addr;
    return null;
  }

  pub fn getRequiredInstanceExtensions () ?[][*:0] const u8
  {
    var count: u32 = 0;
    if (c.glfwGetRequiredInstanceExtensions (&count)) |extensions|
      return @as ([*][*:0] const u8, @ptrCast (extensions)) [0 .. count];
    return null;
  }
};
