const std   = @import ("std");

const context = @import ("context.zig").context;

const utils            = @import ("utils.zig");
const debug_spacedream = utils.debug_spacedream;

pub fn main () !void
{
  try debug_spacedream ("You are running a dev build", .{});

  {
    errdefer std.process.exit (1);

    var spacedream = context.init () catch |err|
    {
      std.log.err ("Init error", .{});
      return err;
    };

    defer spacedream.cleanup () catch
    {
      std.log.err ("Clean Up error", .{});
    };

    spacedream.loop () catch |err|
    {
      std.log.err ("Loop error", .{});
      return err;
    };
  }

  std.process.exit (0);
}
