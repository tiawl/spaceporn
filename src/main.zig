const std = @import ("std");

const log = @import ("log.zig");

const Context = @import ("context.zig").Context;
const opts    = @import ("options.zig").options;

fn init_logfile () !void
{
  if (log.profile.gt (.TURBO) and log.dir.len > 0)
  {
    var dir = std.fs.cwd ().openDir (log.dir, .{}) catch |err|
              {
                if (err == std.fs.File.OpenError.FileNotFound)
                  try log.app ("{s} does not exist, impossible to log execution.", .ERROR, .{ log.dir, });
                return err;
              };

    defer dir.close ();

    const file = std.fs.cwd ().openFile (log.file, .{}) catch |open_err| blk:
                 {
                   if (open_err != std.fs.File.OpenError.FileNotFound)
                   {
                     try log.app ("failed to open log file", .ERROR, .{});
                     return open_err;
                   } else {
                     const cfile = std.fs.cwd ().createFile (log.file, .{}) catch |create_err|
                     {
                       try log.app ("failed to create log file", .ERROR, .{});
                       return create_err;
                     };
                     break :blk cfile;
                   }
                 };

    defer file.close ();
  }
  try log.app (.DEBUG, "log file init OK", .{});
}

pub fn main () void
{
  var arena = std.heap.ArenaAllocator.init (std.heap.page_allocator);
  defer arena.deinit ();
  const allocator = arena.allocator ();

  init_logfile () catch
  {
    std.process.exit (1);
  };

  var options = opts.init (allocator) catch
                {
                  std.process.exit (1);
                };

  var app = Context.init (allocator, options) catch
            {
              std.process.exit (1);
            };

  defer app.cleanup () catch
  {
    std.process.exit (1);
  };

  app.loop (&options) catch
  {
    std.process.exit (1);
  };

  std.process.exit (0);
}
