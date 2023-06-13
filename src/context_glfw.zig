const std  = @import ("std");
const glfw = @import ("glfw");

const utils            = @import ("utils.zig");
const debug_spacedream = utils.debug_spacedream;
const exe              = utils.exe;

pub const context_glfw = struct
{
  window:             glfw.Window,
  extensions:         [][*:0] const u8,
  instance_proc_addr: *const fn (?*anyopaque, [*:0] const u8) callconv (.C) ?*const fn () callconv (.C) void,

  const Self = @This ();

  fn callback (code: glfw.ErrorCode, description: [:0] const u8) void
  {
    std.log.err ("glfw: {}: {s}", .{ code, description });
  }

  pub fn init () !Self
  {
    var self: Self = undefined;

    glfw.setErrorCallback (callback);
    if (!glfw.init (.{}))
    {
      std.log.err ("failed to initialize GLFW: {?s}", .{ glfw.getErrorString () });
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
      std.log.err ("failed to initialize GLFW window: {?s}", .{ glfw.getErrorString () });
      std.process.exit (1);
    };
    errdefer self.window.destroy ();

    self.extensions = glfw.getRequiredInstanceExtensions () orelse
    {
      const err = glfw.mustGetError();
      std.log.err("failed to get required vulkan instance extensions: error={s}", .{err.description});
      std.process.exit (1);
    };
    self.instance_proc_addr = &(glfw.getInstanceProcAddress);

    try debug_spacedream ("Init Glfw OK", .{});

    return self;
  }

  pub fn loop (self: Self) !void
  {
    while (!self.window.shouldClose ())
    {
      glfw.pollEvents ();
    }
    try debug_spacedream ("Loop Glfw OK", .{});
  }

  pub fn cleanup (self: Self) !void
  {
    self.window.destroy ();
    glfw.terminate ();
    try debug_spacedream ("Clean Up Glfw OK", .{});
  }
};
