const std = @import ("std");
const c = @import ("c");
const vk = @import ("vk");
const glfw = @import ("glfw");
const imgui = @import ("imgui");

pub const DrawData = struct
{
  pub const Ex = struct
  {
    pub fn render (draw_data: *c.ImDrawData,
      command_buffer: vk.Command.Buffer, pipeline: vk.Pipeline) void
    {
      c.cImGui_ImplVulkan_RenderDrawDataEx (draw_data,
        @ptrFromInt (@intFromEnum (command_buffer)),
        @ptrFromInt (@intFromEnum (pipeline)));
    }
  };
};

pub const FontsTexture = struct
{
  pub fn create () !void
  {
    if (!c.cImGui_ImplVulkan_CreateFontsTexture ()) return error.ImGuiVulkanCreateFontsTexture;
  }
};

pub const Frame = struct
{
  pub fn new () void
  {
    c.cImGui_ImplVulkan_NewFrame ();
  }
};

pub const InitInfo = struct
{
  Instance:              vk.Instance,
  PhysicalDevice:        vk.PhysicalDevice,
  Device:                vk.Device,
  QueueFamily:           u32,
  Queue:                 vk.Queue,
  PipelineCache:         vk.Pipeline.Cache,
  DescriptorPool:        vk.Descriptor.Pool,
  Subpass:               u32,
  MinImageCount:         u32,
  ImageCount:            u32,
  MSAASamples:           c_uint,
  UseDynamicRendering:   bool,
  ColorAttachmentFormat: i32,
  Allocator:             [*c] const vk.AllocationCallbacks,
  CheckVkResultFn:       ?*const fn (c_int) callconv (c.call_conv) void,
};

fn loader (function_name: [*c] const u8, instance: ?*anyopaque)
  callconv (c.call_conv) ?*const fn () callconv (c.call_conv) void
{
  return glfw.vk.Instance.ProcAddress.get (instance, function_name);
}

pub fn load () !void
{
  if (!c.cImGui_ImplVulkan_LoadFunctions (loader))
    return error.ImGuiVulkanLoadFunctionsFailure;
}

pub fn init (init_info: *imgui.vk.InitInfo) !void
{
  if (!c.cImGui_ImplVulkan_Init (@ptrCast (init_info)))
    return error.ImGuiVulkanInitFailure;
}

pub fn shutdown () void
{
  c.cImGui_ImplVulkan_Shutdown ();
}
