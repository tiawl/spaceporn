const c = @import ("c");
const std = @import ("std");

const glfw = @import ("glfw");

pub const Context = struct
{
  var handle: ?*c.GLFWwindow = null;

  pub fn make (window: *glfw.Window) void
  {
    handle = window.handle;
  }

  pub fn get () !*c.GLFWwindow
  {
    return handle orelse error.GlfwNoCurrentContext;
  }
};
