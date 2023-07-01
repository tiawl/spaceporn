const std = @import ("std");

const context = @import ("context.zig").context;
const opts    = @import ("options.zig").options;

const utils    = @import ("utils.zig");
const log_app  = utils.log_app;
const severity = utils.severity;

pub fn main () !void
{
  var status: u2 = 0;
  var arena = std.heap.ArenaAllocator.init (std.heap.page_allocator);
  defer arena.deinit ();
  var allocator = arena.allocator ();
  {
    errdefer status = 1;

    _ = try opts.init (allocator);

    var app = try context.init (allocator);

    defer app.cleanup () catch
    {
      log_app ("failed to cleanup {s} context", severity.ERROR, .{ utils.exe }) catch {};
    };

    try app.loop ();
  }

  std.process.exit (status);
}
