const std   = @import("std");
const build = @import("build_options");

const context = @import("context.zig");

const MainError = error
{
  InitError,
  LoopError,
};

pub fn main () MainError!void
{
  if (build.DEV) std.log.debug("You are running a dev build", .{});
  {
    errdefer std.process.exit(1);
    context.init () catch
    {
      std.log.err("Init error", .{});
      return MainError.InitError;
    };
    defer context.cleanup () catch
    {
      std.log.err("Clean Up error", .{});
    };
    context.loop () catch
    {
      std.log.err("Loop error", .{});
      return MainError.LoopError;
    };
  }

  std.process.exit(0);
}
