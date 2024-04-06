const std  = @import ("std");
const glfw = @import ("glfw");
const vk   = @import ("vk");

const Logger = @import ("logger").Logger;

const imgui = @import ("imgui");

pub const Tweaker = struct
{
  seed: *u32,
};

pub const Context = struct
{
  const Renderer = struct
  {
    instance:        vk.Instance,
    physical_device: vk.PhysicalDevice,
    logical_device:  vk.Device,
    graphics_family: u32,
    graphics_queue:  vk.Queue,
    descriptor_pool: vk.Descriptor.Pool,
    render_pass:     vk.RenderPass,
    command_pool:    vk.Command.Pool,
    command_buffer:  vk.Command.Buffer,
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
         },
       },
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
    try renderer.command_pool.reset (renderer.logical_device, 0);
    const begin_info = vk.Command.Buffer.Begin.Info
    {
      .flags = @intFromEnum (vk.Command.Buffer.Usage.Bit.ONE_TIME_SUBMIT),
    };

    const command_buffers = [_] vk.Command.Buffer
    {
      renderer.command_buffer,
    };

    try command_buffers [0].begin (&begin_info);

    try imgui.vk.FontsTexture.create ();

    const submit_info = [_] vk.Submit.Info
    {
      .{
         .command_buffer_count = command_buffers.len,
         .p_command_buffers    = &command_buffers,
       },
    };

    try command_buffers [0].end ();
    try renderer.graphics_queue.submit (1, &submit_info, .NULL_HANDLE);

    try renderer.logical_device.waitIdle ();

    try self.logger.app (.DEBUG, "upload Imgui fonts OK", .{});
  }

  pub fn init_vk (self: @This (), renderer: Renderer) !void
  {
    var init_info = imgui.vk.InitInfo
    {
      .Instance              = renderer.instance,
      .PhysicalDevice        = renderer.physical_device,
      .Device                = renderer.logical_device,
      .QueueFamily           = renderer.graphics_family,
      .Queue                 = renderer.graphics_queue,
      .PipelineCache         = .NULL_HANDLE,
      .DescriptorPool        = renderer.descriptor_pool,
      .Subpass               = 0,
      .MinImageCount         = 2,
      .ImageCount            = 2,
      .MSAASamples           = @intFromEnum (vk.Sample.Count.Bit.@"1"),
      .UseDynamicRendering   = false,
      .ColorAttachmentFormat = @intFromEnum (vk.Format.UNDEFINED),
      .Allocator             = null,
      .CheckVkResultFn       = check_vk_result,
    };

    try imgui.vk.load ();
    try imgui.vk.init (&init_info);

    try self.upload_fonts (renderer);

    try self.logger.app (.DEBUG, "init Imgui Vulkan OK", .{});
  }

  fn prepare_pane (self: *@This (),
    framebuffer: struct { width: u32, height: u32, }) !void
  {
    if (framebuffer.height != self.glfw_win_size.height)
    {
      self.glfw_win_size.height = framebuffer.height;
      const window_size = imgui.Vec2 { .x = 0.0,
        .y = @floatFromInt (self.glfw_win_size.height), };
      imgui.NextWindow.Size.set (window_size, 0);
    }

    if (!self.init_window)
    {
      const window_pos = imgui.Vec2 { .x = 0.0, .y = 0.0, };
      const window_pivot = imgui.Vec2 { .x = 0.0, .y = 0.0, };
      imgui.NextWindow.Pos.Ex.set (window_pos, 0, window_pivot);

      const window_size = imgui.Vec2 { .x = 0.0,
        .y = @floatFromInt (self.glfw_win_size.height), };
      imgui.NextWindow.Size.set (window_size, 0);

      self.init_window = true;
    }
  }

  fn prepare_fps (_: @This (), allocator: *std.mem.Allocator,
    last_displayed_fps: *?std.time.Instant, fps: *f32) !void
  {
    if (last_displayed_fps.* == null or
      (try std.time.Instant.now ()).since (last_displayed_fps.*.?) > std.time.ns_per_s)
    {
      fps.* = imgui.IO.get ().Framerate;
      last_displayed_fps.* = try std.time.Instant.now ();
    }

    try imgui.text (allocator.*, "Average {d:.3} ms/frame ({d:.1} FPS)",
      .{ 1000.0 / fps.*, fps.*, });
  }

  fn prepare_seed (_: *@This (), allocator: *std.mem.Allocator, tweak_me: *Tweaker) !void
  {
    const button_size = imgui.Vec2 { .x = 0, .y = 0, };

    if (imgui.Ex.button ("New seed", button_size)) tweak_me.seed.* =
      @intCast (@mod (std.time.milliTimestamp (), @as (i64, @intCast (std.math.maxInt (u32)))));
    if (Logger.build.profile.eql (.DEFAULT))
    {
      imgui.Ex.sameline (0.0, -1.0);
      try imgui.text (allocator.*, "{}", .{ tweak_me.seed.*, });
    }
  }

  fn prepare_screenshot (self: *@This ()) void
  {
    const button_size = imgui.Vec2 { .x = 0, .y = 0, };

    // TODO: display window size
    self.screenshot = imgui.Ex.button ("Take a screenshot", button_size);
  }

  pub fn prepare (self: *@This (), allocator: *std.mem.Allocator,
    last_displayed_fps: *?std.time.Instant, fps: *f32,
    framebuffer: struct { width: u32, height: u32, }, tweak_me: *Tweaker) !ImguiPrepare
  {
    imgui.vk.Frame.new ();
    imgui.glfw.Frame.new ();
    imgui.Frame.new ();

    try self.prepare_pane (
      .{ .width = framebuffer.width, .height = framebuffer.height, });

    const window_flags = @intFromEnum (imgui.Window.Bit.NO_TITLE_BAR) |
      @intFromEnum (imgui.Window.Bit.NO_COLLAPSE) |
      @intFromEnum (imgui.Window.Bit.NO_RESIZE) |
      @intFromEnum (imgui.Window.Bit.NO_MOVE);

    try imgui.begin ("Tweaker", null, window_flags);

    try self.prepare_fps (allocator, last_displayed_fps, fps);
    try self.prepare_seed (allocator, tweak_me);
    self.prepare_screenshot ();

    // Return a boolean depending on the fact that the value of the variable changed or not
    //_ = imgui.ImGui_SliderFloat ("Float", tweak_me.f, 0.0, 1.0, "%.3f", 0);

    imgui.end ();
    imgui.render ();

    try self.logger.app (.DEBUG, "start render Imgui OK", .{});
    return if (self.screenshot) .Screenshot else .Nothing;
  }

  pub fn render (self: @This (), command_buffer: vk.Command.Buffer) !void
  {
    const pipeline: vk.Pipeline = .NULL_HANDLE;
    imgui.vk.DrawData.Ex.render (imgui.DrawData.get (), command_buffer, pipeline);

    try self.logger.app (.DEBUG, "end render Imgui OK", .{});
  }

  pub fn cleanup (self: @This ()) void
  {
    imgui.vk.shutdown ();
    imgui.glfw.shutdown ();
    imgui.Context.destroy ();

    try self.logger.app (.DEBUG, "cleanup Imgui OK", .{});
  }
};
