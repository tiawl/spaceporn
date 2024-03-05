const c = @import ("c");
const std = @import ("std");

const Window = @import ("window.zig").Window;

pub const Context = struct
{
  pub fn make (window: *Window) void
  {
    c.glfwMakeContextCurrent (window.handle);
  }

  pub fn get () !*c.GLFWwindow
  {
    return c.glfwGetCurrentContext () orelse error.NoCurrentContext;
  }
};
