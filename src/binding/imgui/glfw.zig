const std = @import ("std");
const c = @import ("c");
const glfw = @import ("glfw");

pub const Frame = struct
{
  pub fn new () void
  {
    c.cImGui_ImplGlfw_NewFrame ();
  }
};

pub fn init () !void
{
  const window = try glfw.Context.get ();
  if (!c.cImGui_ImplGlfw_InitForVulkan (@ptrCast (window), true)) return error.ImGuiGlfwInitForVulkanFailure;
}

pub fn shutdown () void
{
  c.cImGui_ImplGlfw_Shutdown ();
}
