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
  instance:              vk.Instance,
  physical_device:       vk.PhysicalDevice,
  device:                vk.Device,
  queue_family:          u32,
  queue:                 vk.Queue,
  pipeline_cache:        vk.Pipeline.Cache,
  descriptor_pool:       vk.Descriptor.Pool,
  render_pass:           vk.RenderPass,
  subpass:               u32,
  min_image_count:       u32,
  image_count:           u32,
  msaa_samples:          c_uint,
  use_dynamic_rendering: bool,
  check_vk_result_fn:    ?*const fn (c_int) callconv (c.call_conv) void,
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
  var c_init_info = c.ImGui_ImplVulkan_InitInfo
  {
    .Instance = @ptrFromInt (@intFromEnum (init_info.instance)),
    .PhysicalDevice = @ptrFromInt (@intFromEnum (init_info.physical_device)),
    .Device = @ptrFromInt (@intFromEnum (init_info.device)),
    .QueueFamily = init_info.queue_family,
    .Queue = @ptrFromInt (@intFromEnum (init_info.queue)),
    .DescriptorPool = @ptrFromInt (@intFromEnum (init_info.descriptor_pool)),
    .RenderPass = @ptrFromInt (@intFromEnum (init_info.render_pass)),
    .MinImageCount = init_info.min_image_count,
    .ImageCount = init_info.image_count,
    .MSAASamples = init_info.msaa_samples,
    .PipelineCache = @ptrFromInt (@intFromEnum (init_info.pipeline_cache)),
    .Subpass = init_info.subpass,
    .UseDynamicRendering = init_info.use_dynamic_rendering,
    .Allocator = null,
    .CheckVkResultFn = init_info.check_vk_result_fn,
  };

  if (!c.cImGui_ImplVulkan_Init (&c_init_info))
    return error.ImGuiVulkanInitFailure;
}

pub fn shutdown () void
{
  c.cImGui_ImplVulkan_Shutdown ();
}
