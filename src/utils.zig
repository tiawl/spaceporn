const std = @import ("std");

const build = @import ("build_options");

pub const exe: [*:0]const u8 = build.EXE.ptr[0..build.EXE.len :0];

pub fn debug (comptime format: []const u8, args: anytype) void
{
  if (build.DEV) std.log.debug (format, args);
}
