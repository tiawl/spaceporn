const c = @import ("c");

pub const Context = @import ("context.zig").Context;
pub const Error = @import ("error.zig").Error;
pub const vk = @import ("vk.zig").vk;
pub const Window = @import ("window.zig").Window;

pub const Bool = enum (c_int)
{
  @"true" = c.GLFW_TRUE,
  @"false" = c.GLFW_FALSE,
};

pub const Events = struct
{
  pub fn wait () void
  {
    c.glfwWaitEvents ();
  }
};

pub const Monitor = struct
{
  handle: *c.GLFWmonitor,
};

pub fn init () bool
{
  return c.glfwInit () == c.GLFW_TRUE;
}

pub fn terminate () void
{
  c.glfwTerminate ();
}
