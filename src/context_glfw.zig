const std  = @import ("std");
const glfw = @import ("glfw");

const utils            = @import ("utils.zig");
const debug_spacedream = utils.debug_spacedream;
const exe              = utils.exe;
const severity         = utils.severity;

pub const context_glfw = struct
{
  window:             glfw.Window,
  extensions:         [][*:0] const u8,
  instance_proc_addr: *const fn (?*anyopaque, [*:0] const u8) callconv (.C) ?*const fn () callconv (.C) void,

  const Self = @This ();

  fn callback (code: glfw.ErrorCode, description: [:0] const u8) void
  {
    debug_spacedream ("glfw: {}: {s}", severity.ERROR, .{ code, description }) catch
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
      try debug_spacedream ("failed to initialize GLFW: {?s}", severity.ERROR, .{ glfw.getErrorString () });
      std.process.exit (1);
    }
    errdefer glfw.terminate ();

    const hints = glfw.Window.Hints
                  {
                    .client_api = .no_api,
                    .resizable  = true,
                  };

    self.window = glfw.Window.create (800, 600, exe, null, null, hints) orelse
    {
      try debug_spacedream ("failed to initialize GLFW window: {?s}", severity.ERROR, .{ glfw.getErrorString () });
      std.process.exit (1);
    };
    errdefer self.window.destroy ();

    self.extensions = glfw.getRequiredInstanceExtensions () orelse
    {
      const err = glfw.mustGetError();
      try debug_spacedream ("failed to get required vulkan instance extensions: error={s}", severity.ERROR, .{err.description});
      std.process.exit (1);
    };
    self.instance_proc_addr = &(glfw.getInstanceProcAddress);

    try debug_spacedream ("Init GLFW OK", severity.DEBUG, .{});

    return self;
  }

  pub fn loop (self: Self) !void
  {
    while (!self.window.shouldClose ())
    {
      glfw.pollEvents ();
    }
    try debug_spacedream ("Loop GLFW OK", severity.DEBUG, .{});
  }

  pub fn cleanup (self: Self) !void
  {
    self.window.destroy ();
    glfw.terminate ();
    try debug_spacedream ("Cleanup GLFW OK", severity.DEBUG, .{});
  }
};
