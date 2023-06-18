const build = @import ("build_options");

const utils    = @import ("../utils.zig");
const log_app  = utils.log_app;
const profile  = utils.profile;
const severity = utils.severity;

const init_vk = if (build.LOG_LEVEL == @enumToInt (profile.TURBO)) @import ("init_turbo.zig").init_vk else @import ("init_debug.zig").init_vk;

pub const context_vk = struct
{
  initializer: init_vk,

  const Self = @This ();

  pub fn init (extensions: *[][*:0] const u8,
    instance_proc_addr: *const fn (?*anyopaque, [*:0] const u8) callconv (.C) ?*const fn () callconv (.C) void) !Self
  {
    var self: Self = undefined;
    self.initializer = try init_vk.init_instance (extensions, instance_proc_addr);

    try log_app ("Init Vulkan OK", severity.DEBUG, .{});
    return self;
  }

  pub fn loop (self: Self) !void
  {
    _ = self;
    try log_app ("Loop Vulkan OK", severity.DEBUG, .{});
  }

  pub fn cleanup (self: Self) !void
  {
    try self.initializer.cleanup ();
    try log_app ("Cleanup Vulkan OK", severity.DEBUG, .{});
  }
};
