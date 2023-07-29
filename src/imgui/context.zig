const std      = @import ("std");
const build    = @import ("build_options");
const glfw     = @import ("glfw");
const vk       = @import ("vulkan");
const datetime = @import ("datetime").datetime;

const utils    = @import ("../utils.zig");
const log_app  = utils.log_app;
const profile  = utils.profile;
const severity = utils.severity;

const imgui = @cImport ({
                          @cDefine ("CIMGUI_DEFINE_ENUMS_AND_STRUCTS", {});
                          @cInclude ("cimgui.h");
                        });

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
                              NoAvailableFilename,
                            };

  glfw_win_pos: glfw.Window.Pos = undefined,
  glfw_win_size: glfw.Window.Size = undefined,
  init_window: bool = false,

  const Self = @This ();

  pub fn init () Self
  {
    return Self {};
  }

  pub fn init_glfw (self: *Self, window: glfw.Window) !void
  {
    self.glfw_win_pos = window.getPos ();
    self.glfw_win_size = window.getFramebufferSize ();

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

  fn check_vk_result (err: c_int) callconv(.C) void
  {
    if (err == 0) return;
    std.debug.print ("[vulkan ERROR from Imgui] VkResult = {d}\n", .{ err, });
    if (err < 0) std.process.exit (1);
  }

  fn upload_fonts (self: Self, renderer: Renderer) !void
  {
    _ = self;

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

  pub fn init_vk (self: Self, renderer: Renderer) !void
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

    try self.upload_fonts (renderer);

    try log_app ("init Imgui Vulkan OK", severity.DEBUG, .{});
  }

  fn prepare_pane (self: *Self, framebuffer: struct { width: u32, height: u32, }) !void
  {
    if (framebuffer.height != self.glfw_win_size.height)
    {
      self.glfw_win_size.height = framebuffer.height;
      const window_size = imgui.ImVec2 { .x = 0.0, .y = @floatFromInt (self.glfw_win_size.height), };
      imgui.igSetNextWindowSize (window_size, 0);
    }

    if (!self.init_window)
    {
      const window_pos = imgui.ImVec2
                         {
                           .x = @floatFromInt (self.glfw_win_pos.x),
                           .y = @floatFromInt (self.glfw_win_pos.y),
                         };
      const window_pivot = imgui.ImVec2 { .x = 0.0, .y = 0.0, };
      imgui.igSetNextWindowPos (window_pos, 0, window_pivot);

      const window_size = imgui.ImVec2 { .x = 0.0, .y = @floatFromInt (self.glfw_win_size.height), };
      imgui.igSetNextWindowSize (window_size, 0);

      self.init_window = true;
    }
  }

  fn prepare_fps (self: Self, last_displayed_fps: *?std.time.Instant, fps: *f32) !void
  {
    _ = self;

    if (last_displayed_fps.* == null or (try std.time.Instant.now ()).since (last_displayed_fps.*.?) > std.time.ns_per_s)
    {
      fps.* = imgui.igGetIO ().*.Framerate;
      last_displayed_fps.* = try std.time.Instant.now ();
    }

    imgui.igText ("Average %.3f ms/frame (%.1f FPS)", 1000.0 / fps.*, fps.*);
  }

  fn prepare_seed (self: Self, tweak_me: anytype) void
  {
    _ = self;

    const button_size = imgui.ImVec2 { .x = 0, .y = 0, };

    if (imgui.igButton ("New seed", button_size)) tweak_me.seed.* = @intCast (@mod (std.time.milliTimestamp (), @as (i64, @intCast (std.math.maxInt (u32)))));
    if (build.LOG_LEVEL > @intFromEnum (profile.DEFAULT))
    {
      imgui.igSameLine (0.0, -1.0);
      imgui.igText ("%u", tweak_me.seed.*);
    }
  }

  fn find_available_filename (self: Self, allocator: std.mem.Allocator) ![] const u8
  {
    _ = self;

    var screenshots_dir = std.fs.cwd ().openDir ("screenshots", .{}) catch |err| blk:
                          {
                            if (err == std.fs.Dir.OpenError.FileNotFound)
                            {
                              try std.fs.cwd ().makeDir ("screenshots");
                              break :blk try std.fs.cwd ().openDir ("screenshots", .{});
                            } else {
                              return err;
                            }
                          };
    defer screenshots_dir.close ();

    const now = datetime.Datetime.now ();
    var iterator = std.mem.tokenizeAny (u8, try now.formatISO8601 (allocator, true), ":.+");
    var id: u32 = 0;
    var filename: [] const u8 = undefined;
    var file: std.fs.File = undefined;
    var available = false;
    var date: [] const u8 = "";

    while (iterator.next ()) |token|
    {
      date = try std.fmt.allocPrint (allocator, "{s}{s}-", .{ date, token, });
    }

    while (id < std.math.maxInt (u32))
    {
      filename = try std.fmt.allocPrint (allocator, "{s}{d}", .{ date, id, });
      file = screenshots_dir.openFile (filename, .{}) catch |err|
             {
               if (err == std.fs.File.OpenError.FileNotFound)
               {
                 available = true;
                 break;
               } else {
                 return err;
               }
             };
      file.close ();
      id += 1;
    }

    if (!available)
    {
      return ImguiContextError.NoAvailableFilename;
    }

    return filename;
  }

  fn prepare_screenshot (self: Self, allocator: std.mem.Allocator) !void
  {
    const button_size = imgui.ImVec2 { .x = 0, .y = 0, };

    // TODO: display window size
    if (imgui.igButton ("Take a screenshot", button_size))
    {
      const filename = try self.find_available_filename (allocator);
      _ = filename;

      // TODO: make the screenshot
    }
  }

  pub fn prepare (self: *Self, allocator: std.mem.Allocator, last_displayed_fps: *?std.time.Instant, fps: *f32, framebuffer: struct { width: u32, height: u32, }, tweak_me: anytype) !void
  {
    imgui.igImGui_ImplVulkan_NewFrame ();
    imgui.igImGui_ImplGlfw_NewFrame ();
    imgui.igNewFrame ();

    try self.prepare_pane (.{ .width = framebuffer.width, .height = framebuffer.height, });

    const window_flags = imgui.ImGuiWindowFlags_NoTitleBar | imgui.ImGuiWindowFlags_NoCollapse | imgui.ImGuiWindowFlags_NoResize | imgui.ImGuiWindowFlags_NoMove;

    if (!imgui.igBegin ("Tweaker", null, window_flags))
    {
      return ImguiContextError.BeginFailure;
    }

    try self.prepare_fps (last_displayed_fps, fps);
    self.prepare_seed (tweak_me);
    try self.prepare_screenshot (allocator);

    // Return a boolean depending on the fact that the value of the variable changed or not
    //_ = imgui.igSliderFloat ("Float", tweak_me.f, 0.0, 1.0, "%.3f", 0);


    imgui.igEnd ();

    imgui.igRender ();

    try log_app ("start render Imgui OK", severity.DEBUG, .{});
  }

  pub fn render (self: Self, command_buffer: vk.CommandBuffer) !void
  {
    _ = self;

    var pipeline = vk.Pipeline.null_handle;
    imgui.igImGui_ImplVulkan_RenderDrawData (imgui.igGetDrawData (), @ptrFromInt (@intFromEnum (command_buffer)), @ptrFromInt (@intFromEnum (pipeline)));

    imgui.igUpdatePlatformWindows ();

    try log_app ("end render Imgui OK", severity.DEBUG, .{});
  }

  pub fn cleanup (self: Self) void
  {
    _ = self;

    imgui.igImGui_ImplVulkan_Shutdown ();
    imgui.igImGui_ImplGlfw_Shutdown ();
    imgui.igDestroyContext (null);

    try log_app ("cleanup Imgui OK", severity.DEBUG, .{});
  }
};
