const std   = @import ("std");

const context = @import ("context.zig").context;

const utils    = @import ("utils.zig");
const log_app  = utils.log_app;
const severity = utils.severity;

pub fn main () !void
{
  var status: u2 = 0;
  {
    errdefer status = 1;

    var spacedream = try context.init ();

    defer spacedream.cleanup () catch
    {
      log_app ("failed to cleanup {s} context", severity.ERROR, .{ utils.exe }) catch {};
    };

    try spacedream.loop ();
  }

  std.process.exit (status);
}
