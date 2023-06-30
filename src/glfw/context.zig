const std  = @import ("std");
const glfw = @import ("glfw");

const utils    = @import ("../utils.zig");
const log_app  = utils.log_app;
const exe      = utils.exe;
const severity = utils.severity;

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
  window:              glfw.Window,
  extensions:          [][*:0] const u8,
  instance_proc_addr:  *const fn (?*anyopaque, [*:0] const u8) callconv (.C) ?*const fn () callconv (.C) void,
  framebuffer_resized: bool,

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

  pub fn init () !Self
  {
    var self: Self = undefined;

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

    self.window = glfw.Window.create (800, 600, exe, null, null, hints) orelse
    {
      try log_app ("failed to initialize GLFW window: {?s}", severity.ERROR, .{ glfw.getErrorString () });
      return GlfwError.WindowInitFailed;
    };
    errdefer self.window.destroy ();

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
