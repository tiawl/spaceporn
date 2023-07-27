const std = @import ("std");

const build   = @import ("build_options");
const LOG_DIR = build.LOG_DIR;

const utils    = @import ("utils.zig");
const log_app  = utils.log_app;
const log_file = utils.log_file;
const profile  = utils.profile;
const severity = utils.severity;

const context = @import ("context.zig").context;
const opts    = @import ("options.zig").options;

fn init_logfile () !void
{
  if (build.LOG_LEVEL > @intFromEnum (profile.TURBO) and build.LOG_DIR.len > 0)
  {
    var dir = std.fs.cwd ().openDir (LOG_DIR, .{}) catch |err|
    {
      if (err == std.fs.File.OpenError.FileNotFound)
      {
        try log_app ("{s} does not exist, impossible to log execution.", severity.ERROR, .{ LOG_DIR });
      }
      return err;
    };

    defer dir.close ();

    const file = std.fs.cwd ().openFile (log_file, .{}) catch |open_err| blk:
    {
      if (open_err != std.fs.File.OpenError.FileNotFound)
      {
        try log_app ("failed to open log file", severity.ERROR, .{});
        return open_err;
      } else {
        const cfile = std.fs.cwd ().createFile (log_file, .{}) catch |create_err|
        {
          try log_app ("failed to create log file", severity.ERROR, .{});
          return create_err;
        };
        break :blk cfile;
      }
    };

    defer file.close ();
  }
  try log_app ("log file init OK", severity.DEBUG, .{});
}

pub fn main () !void
{
  var arena = std.heap.ArenaAllocator.init (std.heap.page_allocator);
  defer arena.deinit ();
  var allocator = arena.allocator ();

  init_logfile () catch
  {
    std.process.exit (1);
  };

  var options = try opts.init (allocator);

  var app = context.init (allocator, options) catch
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
