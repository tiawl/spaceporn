const std  = @import ("std");
const glfw = @import ("glfw");

const ImguiContext = @import ("../imgui/context.zig").Context;

const log = @import ("../log.zig").Log;
const exe = log.exe;

const opts = @import ("../options.zig").options;

pub const Context = struct
{
  window:              glfw.Window = undefined,
  extensions:          [][*:0] const u8 = undefined,
  instance_proc_addr:  *const fn (?*anyopaque, [*:0] const u8) callconv (.C) ?*const fn () callconv (.C) void = undefined,
  framebuffer_resized: bool = undefined,

  fn error_callback (code: glfw.ErrorCode, description: [:0] const u8) void
  {
    log.app ("GLFW: {}: {s}", .ERROR, .{ code, description }) catch std.process.exit (1);
  }

  fn framebuffer_resize_callback (window: glfw.Window, width: u32, height: u32) void
  {
    _ = width;
    _ = height;

    var self = window.getUserPointer (Context);
    self.?.framebuffer_resized = true;
  }

  const MIN_WINDOW_WIDTH  = 800;
  const MIN_WINDOW_HEIGHT = 600;

  pub fn init (imgui: *ImguiContext, options: opts) !@This ()
  {
    var self: @This () = .{};

    glfw.setErrorCallback (error_callback);
    if (!glfw.init (.{}))
    {
      try log.app ("failed to initialize GLFW: {?s}", .ERROR, .{ glfw.getErrorString () });
      return error.ContextInitFailed;
    }
    errdefer glfw.terminate ();

    if (!glfw.vulkanSupported ())
    {
      return error.VulkanNotSupported;
    }

    const hints = glfw.Window.Hints
                  {
                    .client_api = .no_api,
                    .resizable  = true,
                  };

    self.window = glfw.Window.create (options.window.width.?, options.window.height.?, exe, null, null, hints) orelse
    {
      try log.app ("failed to initialize GLFW window: {?s}", .ERROR, .{ glfw.getErrorString () });
      return error.WindowInitFailed;
    };
    errdefer self.window.destroy ();

    const min = glfw.Window.SizeOptional
                {
                  .width  = MIN_WINDOW_WIDTH,
                  .height = MIN_WINDOW_HEIGHT,
                };
    const max = glfw.Window.SizeOptional
                {
                  .width  = null,
                  .height = null,
                };
    self.window.setSizeLimits (min, max);

    self.framebuffer_resized = true;
    self.window.setUserPointer (&self);
    self.window.setFramebufferSizeCallback (framebuffer_resize_callback);

    self.extensions = glfw.getRequiredInstanceExtensions () orelse
    {
      const err = glfw.mustGetError();
      try log.app ("failed to get required vulkan instance extensions: error={s}", .ERROR, .{err.description});
      return error.RequiredInstanceExtensionsFailed;
    };
    self.instance_proc_addr = &(glfw.getInstanceProcAddress);

    try imgui.init_glfw (self.window);

    try log.app ("init GLFW OK", .DEBUG, .{});

    return self;
  }

  pub fn init_surface (self: @This (), instance: anytype, surface: anytype, success: i32) !void
  {
    if (glfw.createWindowSurface (instance, self.window, null, surface) != success)
    {
      return error.SurfaceInitFailed;
    }

    try log.app ("init GLFW surface OK", .DEBUG, .{});
  }

  pub fn get_framebuffer_size (self: *@This ()) struct { resized: bool, width: u32, height: u32, }
  {
    const resized = self.framebuffer_resized;

    if (resized)
    {
      self.framebuffer_resized = false;
    }

    var size = self.window.getFramebufferSize ();

    while (size.width == 0 or size.height == 0)
    {
      glfw.waitEvents ();
      size = self.window.getFramebufferSize ();
    }

    return .{
              .resized = resized,
              .width   = size.width,
              .height  = size.height,
            };
  }

  pub fn get_window (self: @This ()) glfw.Window
  {
    return self.window;
  }

  pub fn looping (self: @This ()) bool
  {
    const close_window = self.window.shouldClose ();
    return !close_window;
  }

  pub fn loop (self: @This ()) !void
  {
    _ = self;
    glfw.pollEvents ();
    try log.app ("loop GLFW OK", .DEBUG, .{});
  }

  pub fn cleanup (self: @This ()) !void
  {
    self.window.destroy ();
    glfw.terminate ();
    try log.app ("cleanup GLFW OK", .DEBUG, .{});
  }
};
