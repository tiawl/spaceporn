const std  = @import ("std");
const glfw = @import ("glfw");

const context_imgui = @import ("../imgui/context.zig").context_imgui;

const utils    = @import ("../utils.zig");
const log_app  = utils.log_app;
const exe      = utils.exe;
const severity = utils.severity;

const opts          = @import ("../options.zig").options;

const GlfwError = error
{
  ContextInitFailed,
  VulkanNotSupported,
  WindowInitFailed,
  SurfaceInitFailed,
  RequiredInstanceExtensionsFailed,
};

pub const context_glfw = struct
{
  window:              glfw.Window = undefined,
  extensions:          [][*:0] const u8 = undefined,
  instance_proc_addr:  *const fn (?*anyopaque, [*:0] const u8) callconv (.C) ?*const fn () callconv (.C) void = undefined,
  framebuffer_resized: bool = undefined,

  const Self = @This ();

  fn error_callback (code: glfw.ErrorCode, description: [:0] const u8) void
  {
    log_app ("GLFW: {}: {s}", severity.ERROR, .{ code, description }) catch
    {
      std.process.exit (1);
    };
  }

  fn framebuffer_resize_callback (window: glfw.Window, width: u32, height: u32) void
  {
    _ = width;
    _ = height;

    var self = window.getUserPointer (context_glfw);
    self.?.framebuffer_resized = true;
  }

  const MIN_WINDOW_WIDTH  = 800;
  const MIN_WINDOW_HEIGHT = 600;

  pub fn init (imgui: *context_imgui, options: opts) !Self
  {
    var self = Self {};

    glfw.setErrorCallback (error_callback);
    if (!glfw.init (.{}))
    {
      try log_app ("failed to initialize GLFW: {?s}", severity.ERROR, .{ glfw.getErrorString () });
      return GlfwError.ContextInitFailed;
    }
    errdefer glfw.terminate ();

    if (!glfw.vulkanSupported ())
    {
      return GlfwError.VulkanNotSupported;
    }

    const hints = glfw.Window.Hints
                  {
                    .client_api = .no_api,
                    .resizable  = true,
                  };

    self.window = glfw.Window.create (options.window.width.?, options.window.height.?, exe, null, null, hints) orelse
    {
      try log_app ("failed to initialize GLFW window: {?s}", severity.ERROR, .{ glfw.getErrorString () });
      return GlfwError.WindowInitFailed;
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
      try log_app ("failed to get required vulkan instance extensions: error={s}", severity.ERROR, .{err.description});
      return GlfwError.RequiredInstanceExtensionsFailed;
    };
    self.instance_proc_addr = &(glfw.getInstanceProcAddress);

    try imgui.init_glfw (self.window);

    try log_app ("init GLFW OK", severity.DEBUG, .{});

    return self;
  }

  pub fn init_surface (self: Self, instance: anytype, surface: anytype, success: i32) !void
  {
    if (glfw.createWindowSurface (instance, self.window, null, surface) != success)
    {
      return GlfwError.SurfaceInitFailed;
    }

    try log_app ("init GLFW surface OK", severity.DEBUG, .{});
  }

  pub fn get_framebuffer_size (self: *Self) struct { resized: bool, width: u32, height: u32, }
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

  pub fn get_window (self: Self) glfw.Window
  {
    return self.window;
  }

  pub fn looping (self: Self) bool
  {
    const close_window = self.window.shouldClose ();
    return !close_window;
  }

  pub fn loop (self: Self) !void
  {
    _ = self;
    glfw.pollEvents ();
    try log_app ("loop GLFW OK", severity.DEBUG, .{});
  }

  pub fn cleanup (self: Self) !void
  {
    self.window.destroy ();
    glfw.terminate ();
    try log_app ("cleanup GLFW OK", severity.DEBUG, .{});
  }
};