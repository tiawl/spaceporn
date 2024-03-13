const c = @import ("c");
const std = @import ("std");

const glfw = @import ("glfw.zig");

pub const Context = struct
{
  pub fn make (window: *glfw.Window) void
  {
    c.glfwMakeContextCurrent (window.handle);
  }

  pub fn get () !*c.GLFWwindow
  {
    return c.glfwGetCurrentContext () orelse error.NoCurrentContext;
  }
};
