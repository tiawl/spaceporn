const std  = @import ("std");
const glfw = @import ("glfw");
const vk   = @import ("vk");

const Logger = @import ("logger").Logger;

const imgui = @import ("imgui");

pub const Context = struct
{
  const Renderer = struct
                   {
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

  pub const ImguiPrepare = enum
                           {
                             Nothing,
                             Screenshot,
                           };

  glfw_win_size: glfw.Window.Size = undefined,
  init_window:   bool = false,
  screenshot:    bool = false,
  logger:        *const Logger = undefined,

  // TODO: remove this:
  pub fn init (logger: *const Logger) @This ()
  {
    return .{ .logger = logger, };
  }

  // TODO: remove this:
  pub fn init_glfw (self: *@This ()) !void
  {
    self.glfw_win_size = try glfw.Window.Framebuffer.Size.get ();

    try imgui.Context.create ();

    imgui.Style.colorsDark ();

    imgui.Style.set (&.{
                        .{ .window_rounding = 0, },
                        .{ .colors = .{
                                        .index = imgui.Col.WindowBg,
                                        .channel = "w",
                                        .value = 1,
                                      }, },
    });

    try imgui.glfw.init ();

    try self.logger.app (.DEBUG, "init Imgui GLFW OK", .{});
  }

  fn check_vk_result (err: c_int) callconv (.C) void
  {
    if (err == 0) return;
    std.debug.print ("[vulkan ERROR from Imgui] VkResult = {d}\n", .{ err, });
    if (err < 0) std.process.exit (1);
  }

  fn upload_fonts (self: @This (), renderer: Renderer) !void
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

    if (!imgui.cImGui_ImplVulkan_CreateFontsTexture (@ptrFromInt (@intFromEnum (renderer.command_buffer)))) return error.ImGuiVulkanCreateFontsTextureFailure;

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
    imgui.cImGui_ImplVulkan_DestroyFontUploadObjects ();

    try self.logger.app (.DEBUG, "upload Imgui fonts OK", .{});
  }

  pub fn init_vk (self: @This (), renderer: Renderer) !void
  {
    const sample = vk.SampleCountFlags { .@"1_bit" = true, };
    const format = vk.Format.undefined;
    var init_info = imgui.vk.InitInfo
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

    if (!imgui.cImGui_ImplVulkan_LoadFunctions ()) return error.ImGuiVulkanLoadFunctionsFailure;
    if (!imgui.cImGui_ImplVulkan_Init (@ptrCast (&init_info), @ptrFromInt (@intFromEnum (renderer.render_pass)))) return error.ImGuiVulkanInitFailure;

    try self.upload_fonts (renderer);

    try self.logger.app (.DEBUG, "init Imgui Vulkan OK", .{});
  }

  fn prepare_pane (self: *@This (), framebuffer: struct { width: u32, height: u32, }) !void
  {
    if (framebuffer.height != self.glfw_win_size.height)
    {
      self.glfw_win_size.height = framebuffer.height;
      const window_size = imgui.ImVec2 { .x = 0.0, .y = @floatFromInt (self.glfw_win_size.height), };
      imgui.ImGui_SetNextWindowSize (window_size, 0);
    }

    if (!self.init_window)
    {
      const window_pos = imgui.ImVec2 { .x = 0.0, .y = 0.0, };
      const window_pivot = imgui.ImVec2 { .x = 0.0, .y = 0.0, };
      imgui.ImGui_SetNextWindowPosEx (window_pos, 0, window_pivot);

      const window_size = imgui.ImVec2 { .x = 0.0, .y = @floatFromInt (self.glfw_win_size.height), };
      imgui.ImGui_SetNextWindowSize (window_size, 0);

      self.init_window = true;
    }
  }

  fn prepare_fps (_: @This (), last_displayed_fps: *?std.time.Instant, fps: *f32) !void
  {
    if (last_displayed_fps.* == null or (try std.time.Instant.now ()).since (last_displayed_fps.*.?) > std.time.ns_per_s)
    {
      fps.* = imgui.ImGui_GetIO ().*.Framerate;
      last_displayed_fps.* = try std.time.Instant.now ();
    }

    imgui.ImGui_Text ("Average %.3f ms/frame (%.1f FPS)", 1000.0 / fps.*, fps.*);
  }

  fn prepare_seed (tweak_me: anytype) void
  {
    const button_size = imgui.ImVec2 { .x = 0, .y = 0, };

    if (imgui.ImGui_ButtonEx ("New seed", button_size)) tweak_me.seed.* = @intCast (@mod (std.time.milliTimestamp (), @as (i64, @intCast (std.math.maxInt (u32)))));
    if (Logger.build.profile.eql (.DEFAULT))
    {
      imgui.ImGui_SameLineEx (0.0, -1.0);
      imgui.ImGui_Text ("%u", tweak_me.seed.*);
    }
  }

  fn prepare_screenshot (self: *@This ()) void
  {
    const button_size = imgui.ImVec2 { .x = 0, .y = 0, };

    // TODO: display window size
    self.screenshot = imgui.ImGui_ButtonEx ("Take a screenshot", button_size);
  }

  pub fn prepare (self: *@This (), last_displayed_fps: *?std.time.Instant, fps: *f32,
                  framebuffer: struct { width: u32, height: u32, }, tweak_me: anytype) !ImguiPrepare
  {
    imgui.cImGui_ImplVulkan_NewFrame ();
    imgui.cImGui_ImplGlfw_NewFrame ();
    imgui.ImGui_NewFrame ();

    try self.prepare_pane (.{ .width = framebuffer.width, .height = framebuffer.height, });

    const window_flags = imgui.ImGuiWindowFlags_NoTitleBar | imgui.ImGuiWindowFlags_NoCollapse | imgui.ImGuiWindowFlags_NoResize | imgui.ImGuiWindowFlags_NoMove;

    if (!imgui.ImGui_Begin ("Tweaker", null, window_flags)) return error.ImGuiBeginFailure;

    try self.prepare_fps (last_displayed_fps, fps);
    self.prepare_seed (tweak_me);
    self.prepare_screenshot ();

    // Return a boolean depending on the fact that the value of the variable changed or not
    //_ = imgui.ImGui_SliderFloat ("Float", tweak_me.f, 0.0, 1.0, "%.3f", 0);

    imgui.ImGui_End ();
    imgui.ImGui_Render ();

    try self.logger.app (.DEBUG, "start render Imgui OK", .{});
    return if (self.screenshot) ImguiPrepare.Screenshot else ImguiPrepare.Nothing;
  }

  pub fn render (self: @This (), command_buffer: vk.CommandBuffer) !void
  {
    const pipeline = vk.Pipeline.null_handle;
    imgui.cImGui_ImplVulkan_RenderDrawDataEx (imgui.ImGui_GetDrawData (), @ptrFromInt (@intFromEnum (command_buffer)), @ptrFromInt (@intFromEnum (pipeline)));

    try self.logger.app (.DEBUG, "end render Imgui OK", .{});
  }

  pub fn cleanup (self: @This ()) void
  {
    imgui.cImGui_ImplVulkan_Shutdown ();
    imgui.cImGui_ImplGlfw_Shutdown ();
    imgui.ImGui_DestroyContext (null);

    try self.logger.app (.DEBUG, "cleanup Imgui OK", .{});
  }
};
