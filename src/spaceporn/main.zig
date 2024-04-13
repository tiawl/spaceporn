const std = @import ("std");

const Logger  = @import ("logger").Logger;
const Context = @import ("context.zig").Context;
const Options = @import ("options.zig").Options;

pub fn main () !void
{
  var arena = std.heap.ArenaAllocator.init (std.heap.page_allocator);
  defer arena.deinit ();
  const allocator = arena.allocator ();

  const logger = try Logger.init (&allocator);
  defer logger.deinit ();
  var options = try Options.init (&logger);

  var context = try Context.init (&logger, &options);
  defer context.deinit () catch {};

  try context.loop (&options);
}
