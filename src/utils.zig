const std = @import("std");

const build = @import("build_options");

pub const SpacedreamError = error
{
  InitError,
  LoopError,
  CleanupError,
};

pub fn debug (comptime format: []const u8, args: anytype) void
{
  if (build.DEV) std.log.debug(format, args);
}
