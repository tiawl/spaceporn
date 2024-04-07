const c = @import ("c");

const glfw = @This ();

pub const Context = @import ("context").Context;
pub const Error = @import ("error").Error;
pub const vk = @import ("vk");
pub const Window = @import ("window").Window;

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

  pub fn poll () void
  {
    c.glfwPollEvents ();
  }
};

pub const Monitor = struct
{
  handle: *c.GLFWmonitor,
};

pub fn init () !void
{
  if (c.glfwInit () != c.GLFW_TRUE) return error.GlfwInitFailed;
}

pub fn terminate () void
{
  c.glfwTerminate ();
}
