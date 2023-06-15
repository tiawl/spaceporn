const std   = @import ("std");

const context = @import ("context.zig").context;

const utils    = @import ("utils.zig");
const log_app  = utils.log_app;
const severity = utils.severity;

pub fn main () !void
{
  {
    errdefer std.process.exit (1);

    var spacedream = context.init () catch |err|
    {
      try log_app ("failed to init {s} context", severity.ERROR, .{ utils.exe });
      return err;
    };

    defer spacedream.cleanup () catch
    {
      log_app ("failed to cleanup {s} context", severity.ERROR, .{ utils.exe }) catch {};
    };

    spacedream.loop () catch |err|
    {
      try log_app ("failed to loop", severity.ERROR, .{});
      return err;
    };
  }

  std.process.exit (0);
}
