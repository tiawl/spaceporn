const std   = @import ("std");

const context = @import ("context.zig").context;

const utils            = @import ("utils.zig");
const debug_spacedream = utils.debug_spacedream;
const severity         = utils.severity;

pub fn main () !void
{
  {
    errdefer std.process.exit (1);

    var spacedream = context.init () catch |err|
    {
      try debug_spacedream ("failed to init {s} context", severity.ERROR, .{ utils.exe });
      return err;
    };

    defer spacedream.cleanup () catch
    {
      debug_spacedream ("failed to cleanup {s} context", severity.ERROR, .{ utils.exe }) catch {};
    };

    spacedream.loop () catch |err|
    {
      try debug_spacedream ("failed to loop", severity.ERROR, .{});
      return err;
    };
  }

  std.process.exit (0);
}
