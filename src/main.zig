const std = @import ("std");

const utils    = @import ("utils.zig");

const context = @import ("context.zig").context;
const opts    = @import ("options.zig").options;

pub fn main () void
{
  var arena = std.heap.ArenaAllocator.init (std.heap.page_allocator);
  defer arena.deinit ();
  var allocator = arena.allocator ();

  const options = opts.init (allocator) catch
                  {
                    std.process.exit (1);
                  };

  var app = context.init (allocator, options) catch
            {
              std.process.exit (1);
            };

  defer app.cleanup () catch
  {
    std.process.exit (1);
  };

  app.loop (options) catch
  {
    std.process.exit (1);
  };

  std.process.exit (0);
}
