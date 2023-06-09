const std   = @import("std");

const context = @import("context.zig");

const utils = @import("utils.zig");
const Error = utils.SpacedreamError;
const debug = utils.debug;

pub fn main () Error!void
{
  debug("You are running a dev build", .{});
  {
    errdefer std.process.exit(1);
    context.init () catch
    {
      std.log.err("Init error", .{});
      return Error.InitError;
    };
    defer context.cleanup () catch
    {
      std.log.err("Clean Up error", .{});
    };
    context.loop () catch
    {
      std.log.err("Loop error", .{});
      return Error.LoopError;
    };
  }

  std.process.exit(0);
}
