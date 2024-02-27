const c = @import ("c");

pub const Bool = enum (c_int)
{
  @"true" = c.GLFW_TRUE,
  @"false" = c.GLFW_FALSE,
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
