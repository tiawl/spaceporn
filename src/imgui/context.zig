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
                            @cDefine ("CIMGUI_USE_VULKAN", {});
                            @cDefine ("CIMGUI_USE_GLFW", {});
                            @cInclude ("vulkan/vulkan.h");
                            @cInclude ("cimgui.h");
                            @cInclude ("cimgui_impl.h");
                          })
              else null;

pub const context_imgui = struct
{
  const ImguiContextError = error
                            {
                              InitFailure,
                              InitGlfwFailure,
                              InitVulkanFailure,
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

      if (!imgui.ImGui_ImplGlfw_InitForVulkan (@ptrCast (window.handle), true))
      {
        return ImguiContextError.InitGlfwFailure;
      }

      try log_app ("init Imgui GLFW OK", severity.DEBUG, .{});
    }
  }

  fn check_vk_result (err: c_int) callconv(.C) void
  {
    if (err == 0) return;
    std.debug.print ("[vulkan ERROR] VkResult = {d}\n", .{ err, });
    if (err < 0) std.process.exit (1);
  }

  pub fn init_vk (renderer: struct {
                                     instance: *vk.Instance,
                                     physical_device: *vk.PhysicalDevice,
                                     logical_device: *vk.Device,
                                     graphics_family: u32,
                                     graphics_queue: *vk.Queue,
                                     descriptor_pool: *vk.DescriptorPool,
                                     render_pass: *vk.RenderPass,
                                   }) !void
  {
    if (build.LOG_LEVEL > @intFromEnum (profile.DEFAULT))
    {
      var cache = vk.PipelineCache.null_handle;
      const sample = vk.SampleCountFlags { .@"1_bit" = true, };
      const format = vk.Format.undefined;
      var init_info = imgui.ImGui_ImplVulkan_InitInfo
                      {
                        .Instance              = @ptrCast (renderer.instance),
                        .PhysicalDevice        = @ptrCast (renderer.physical_device),
                        .Device                = @ptrCast (renderer.logical_device),
                        .QueueFamily           = renderer.graphics_family,
                        .Queue                 = @ptrCast (renderer.graphics_queue),
                        .PipelineCache         = @ptrCast (&cache),
                        .DescriptorPool        = @ptrCast (renderer.descriptor_pool),
                        .Subpass               = 0,
                        .MinImageCount         = 2,
                        .ImageCount            = 2,
                        .MSAASamples           = sample.toInt (),
                        .UseDynamicRendering   = false,
                        .ColorAttachmentFormat = @intFromEnum (format),
                        .Allocator             = null,
                        .CheckVkResultFn       = check_vk_result,
                      };

      if (!imgui.ImGui_ImplVulkan_Init (&init_info, @ptrCast (renderer.render_pass)))
      {
        return ImguiContextError.InitVulkanFailure;
      }

      try log_app ("init Imgui Vulkan OK", severity.DEBUG, .{});
    }
  }

  pub fn render_start () !void
  {
    if (build.LOG_LEVEL > @intFromEnum (profile.DEFAULT))
    {
      imgui.ImGui_ImplVulkan_NewFrame ();
      imgui.ImGui_ImplGlfw_NewFrame ();
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
      imgui.ImGui_ImplVulkan_RenderDrawData (imgui.igGetDrawData (), @ptrCast (command_buffer), @ptrCast (&pipeline));

      try log_app ("end render Imgui OK", severity.DEBUG, .{});
    }
  }

  pub fn cleanup () void
  {
    if (build.LOG_LEVEL > @intFromEnum (profile.DEFAULT))
    {
      imgui.ImGui_ImplVulkan_Shutdown ();
      imgui.ImGui_ImplGlfw_Shutdown ();
      imgui.igDestroyContext (null);

      try log_app ("cleanup Imgui OK", severity.DEBUG, .{});
    }
  }
};
