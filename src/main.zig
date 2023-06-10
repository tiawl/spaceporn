const std   = @import ("std");

const context = @import ("context.zig");
const context_t = context.context_t;

const utils = @import ("utils.zig");
const Error = utils.SpacedreamError;
const debug = utils.debug;

pub fn main () Error!void
{
  debug ("You are running a dev build", .{});

  var spacedream = context_t{};
  {
    errdefer std.process.exit (1);
    context.init (&spacedream) catch
    {
      std.log.err ("Init error", .{});
      return Error.InitError;
    };
    defer context.cleanup (&spacedream) catch
    {
      std.log.err ("Clean Up error", .{});
    };
    context.loop (&spacedream) catch
    {
      std.log.err ("Loop error", .{});
      return Error.LoopError;
    };
  }

  std.process.exit (0);
}
