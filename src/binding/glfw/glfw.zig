const c = @import ("c");

pub const Context = @import ("context").Context;
pub const Error = @import ("error").Error;
pub const vk = @import ("vk").vk;
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

pub fn init () bool
{
  return c.glfwInit () == c.GLFW_TRUE;
}

pub fn terminate () void
{
  c.glfwTerminate ();
}
