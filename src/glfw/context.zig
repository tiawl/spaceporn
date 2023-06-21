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
  window:             glfw.Window,
  extensions:         [][*:0] const u8,
  instance_proc_addr: *const fn (?*anyopaque, [*:0] const u8) callconv (.C) ?*const fn () callconv (.C) void,

  const Self = @This ();

  fn callback (code: glfw.ErrorCode, description: [:0] const u8) void
  {
    log_app ("glfw: {}: {s}", severity.ERROR, .{ code, description }) catch
    {
      std.process.exit (1);
    };
  }

  pub fn init () !Self
  {
    var self: Self = undefined;

    glfw.setErrorCallback (callback);
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

    self.extensions = glfw.getRequiredInstanceExtensions () orelse
    {
      const err = glfw.mustGetError();
      try log_app ("failed to get required vulkan instance extensions: error={s}", severity.ERROR, .{err.description});
      return GlfwError.RequiredInstanceExtensionsFailed;
    };
    self.instance_proc_addr = &(glfw.getInstanceProcAddress);

    try log_app ("Init GLFW OK", severity.DEBUG, .{});

    return self;
  }

  pub fn init_surface (self: Self, instance: anytype, surface: anytype, success: i32) !void
  {
    if (glfw.createWindowSurface (instance, self.window, null, surface) != success)
    {
      return GlfwError.SurfaceInitFailed;
    }

    try log_app ("Init GLFW Surface OK", severity.DEBUG, .{});
  }

  pub fn loop (self: Self) !void
  {
    while (!self.window.shouldClose ())
    {
      glfw.pollEvents ();
    }
    try log_app ("Loop GLFW OK", severity.DEBUG, .{});
  }

  pub fn cleanup (self: Self) !void
  {
    self.window.destroy ();
    glfw.terminate ();
    try log_app ("Cleanup GLFW OK", severity.DEBUG, .{});
  }
};