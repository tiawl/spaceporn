const std   = @import ("std");
const build = @import ("build_options");
const glfw  = @import ("glfw");
const vk    = @import ("vulkan");

const utils    = @import ("../utils.zig");
const log_app  = utils.log_app;
const profile  = utils.profile;
const severity = utils.severity;

const imgui = if (build.LOG_LEVEL > @intFromEnum (profile.DEFAULT))
                @cImport ({
                            @cDefine ("CIMGUI_DEFINE_ENUMS_AND_STRUCTS", {});
                            @cInclude ("cimgui.h");
                          })
              else null;

const dispatch         = @import ("../vk/dispatch.zig");
const DeviceDispatch   = dispatch.DeviceDispatch;

const ImGui_ImplVulkan_InitInfo = extern struct
{
  Instance:              vk.Instance,
  PhysicalDevice:        vk.PhysicalDevice,
  Device:                vk.Device,
  QueueFamily:           u32,
  Queue:                 vk.Queue,
  PipelineCache:         vk.PipelineCache,
  DescriptorPool:        vk.DescriptorPool,
  Subpass:               u32,
  MinImageCount:         u32,
  ImageCount:            u32,
  MSAASamples:           c_uint,
  UseDynamicRendering:   bool,
  ColorAttachmentFormat: i32,
  Allocator:             [*c] const vk.AllocationCallbacks,
  CheckVkResultFn:       ?*const fn (c_int) callconv (.C) void,
};

pub const context_imgui = struct
{
  const Renderer = struct
                   {
                     device_dispatch: DeviceDispatch,
                     instance:        vk.Instance,
                     physical_device: vk.PhysicalDevice,
                     logical_device:  vk.Device,
                     graphics_family: u32,
                     graphics_queue:  vk.Queue,
                     descriptor_pool: vk.DescriptorPool,
                     render_pass:     vk.RenderPass,
                     command_pool:    vk.CommandPool,
                     command_buffer:  vk.CommandBuffer,
                   };

  const ImguiContextError = error
                            {
                              InitFailure,
                              InitGlfwFailure,
                              InitVulkanFailure,
                              CreateFontsTextureFailure,
                              BeginFailure,
                              SliderFloatFailure,
                            };

  pub fn init_glfw (window: glfw.Window) !void
  {
    if (build.LOG_LEVEL > @intFromEnum (profile.DEFAULT))
    {
      if (imgui.igCreateContext (null) == null)
      {
        return ImguiContextError.InitFailure;
      }

      var io = imgui.igGetIO ();
      io.*.ConfigFlags |= imgui.ImGuiConfigFlags_NavEnableKeyboard; // Enable Keyboard Controls
      io.*.ConfigFlags |= imgui.ImGuiConfigFlags_DockingEnable;     // Enable Docking
      io.*.ConfigFlags |= imgui.ImGuiConfigFlags_ViewportsEnable;   // Enable Multi-Viewport / Platform Windows

      imgui.igStyleColorsDark (null);

      var style = imgui.igGetStyle ();
      style.*.WindowRounding = 0;
      style.*.Colors [imgui.ImGuiCol_WindowBg].w = 1;

      if (!imgui.igImGui_ImplGlfw_InitForVulkan (@ptrCast (window.handle), true))
      {
        return ImguiContextError.InitGlfwFailure;
      }

      try log_app ("init Imgui GLFW OK", severity.DEBUG, .{});
    }
  }

  fn check_vk_result (err: c_int) callconv(.C) void
  {
    if (err == 0) return;
    std.debug.print ("[vulkan ERROR from Imgui] VkResult = {d}\n", .{ err, });
    if (err < 0) std.process.exit (1);
  }

  fn upload_fonts (renderer: Renderer) !void
  {
    try renderer.device_dispatch.resetCommandPool (renderer.logical_device, renderer.command_pool, vk.CommandPoolResetFlags {});
    const begin_info = vk.CommandBufferBeginInfo
                       {
                         .flags = vk.CommandBufferUsageFlags { .one_time_submit_bit = true, },
                       };

    const command_buffers = [_] vk.CommandBuffer
                            {
                              renderer.command_buffer,
                            };

    try renderer.device_dispatch.beginCommandBuffer (command_buffers [0], &begin_info);

    if (!imgui.igImGui_ImplVulkan_CreateFontsTexture (@ptrFromInt (@intFromEnum (renderer.command_buffer))))
    {
      return ImguiContextError.CreateFontsTextureFailure;
    }

    const submit_info = [_] vk.SubmitInfo
                        {
                          vk.SubmitInfo
                          {
                            .command_buffer_count = command_buffers.len,
                            .p_command_buffers    = &command_buffers,
                          },
                        };

    try renderer.device_dispatch.endCommandBuffer (command_buffers [0]);
    try renderer.device_dispatch.queueSubmit (renderer.graphics_queue, 1, &submit_info, vk.Fence.null_handle);

    try renderer.device_dispatch.deviceWaitIdle (renderer.logical_device);
    imgui.igImGui_ImplVulkan_DestroyFontUploadObjects ();

    try log_app ("upload Imgui fonts OK", severity.DEBUG, .{});
  }

  pub fn init_vk (renderer: Renderer) !void
  {
    if (build.LOG_LEVEL > @intFromEnum (profile.DEFAULT))
    {
      const sample = vk.SampleCountFlags { .@"1_bit" = true, };
      const format = vk.Format.undefined;
      var init_info = ImGui_ImplVulkan_InitInfo
                      {
                        .Instance              = renderer.instance,
                        .PhysicalDevice        = renderer.physical_device,
                        .Device                = renderer.logical_device,
                        .QueueFamily           = renderer.graphics_family,
                        .Queue                 = renderer.graphics_queue,
                        .PipelineCache         = vk.PipelineCache.null_handle,
                        .DescriptorPool        = renderer.descriptor_pool,
                        .Subpass               = 0,
                        .MinImageCount         = 2,
                        .ImageCount            = 2,
                        .MSAASamples           = sample.toInt (),
                        .UseDynamicRendering   = false,
                        .ColorAttachmentFormat = @intFromEnum (format),
                        .Allocator             = null,
                        .CheckVkResultFn       = check_vk_result,
                      };

      if (!imgui.igImGui_ImplVulkan_Init (@ptrCast (&init_info), @ptrFromInt (@intFromEnum (renderer.render_pass))))
      {
        return ImguiContextError.InitVulkanFailure;
      }

      try upload_fonts (renderer);

      try log_app ("init Imgui Vulkan OK", severity.DEBUG, .{});
    }
  }

  pub fn render_start () !void
  {
    if (build.LOG_LEVEL > @intFromEnum (profile.DEFAULT))
    {
      imgui.igImGui_ImplVulkan_NewFrame ();
      imgui.igImGui_ImplGlfw_NewFrame ();
      imgui.igNewFrame ();

      var f: f32 = 0.0;
      var counter: u32 = 0;

      if (!imgui.igBegin ("Hello, world!", null, 0))
      {
        return ImguiContextError.BeginFailure;
      }

      imgui.igText ("This is some useful text");

      if (!imgui.igSliderFloat ("Float", &f, 0.0, 1.0, "%.3f", 0))
      {
        return ImguiContextError.SliderFloatFailure;
      }

      const button_size = imgui.ImVec2
                          {
                            .x = 0,
                            .y = 0,
                          };

      if (imgui.igButton ("Button", button_size)) counter += 1;
      imgui.igSameLine (0.0, -1.0);
      imgui.igText ("counter = %d", counter);

      imgui.igText ("Application average %.3f ms/frame (%.1f FPS)", 1000.0 / imgui.igGetIO ().*.Framerate, imgui.igGetIO ().*.Framerate);
      imgui.igEnd ();

      imgui.igRender ();

      try log_app ("start render Imgui OK", severity.DEBUG, .{});
    }
  }

  pub fn render_end (command_buffer: *vk.CommandBuffer) !void
  {
    if (build.LOG_LEVEL > @intFromEnum (profile.DEFAULT))
    {
      var pipeline = vk.Pipeline.null_handle;
      imgui.igImGui_ImplVulkan_RenderDrawData (imgui.igGetDrawData (), @ptrCast (command_buffer), @ptrCast (&pipeline));

      try log_app ("end render Imgui OK", severity.DEBUG, .{});
    }
  }

  pub fn cleanup () void
  {
    if (build.LOG_LEVEL > @intFromEnum (profile.DEFAULT))
    {
      imgui.igImGui_ImplVulkan_Shutdown ();
      imgui.igImGui_ImplGlfw_Shutdown ();
      imgui.igDestroyContext (null);

      try log_app ("cleanup Imgui OK", severity.DEBUG, .{});
    }
  }
};
