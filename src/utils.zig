const std = @import ("std");

const build = @import ("build_options");
pub const exe: [*:0] const u8 = build.EXE.ptr[0..build.EXE.len :0];
pub const log_file = build.LOGDIR ++ "/" ++ exe ++ ".log";

pub const profile = enum
{
  TURBO,
  DEFAULT,
  DEV,
};

const UtilsError = error
{
  DateProcessError,
};

fn debug (function: [] const u8, expanded: anytype, date: *[] const u8,
          comptime format: [] const u8, args: anytype) !void
{
  var buffer: [4096] u8 = undefined;
  var fba = std.heap.FixedBufferAllocator.init (&buffer);
  expanded.allocator.* = fba.allocator ();
  const command = [_][] const u8 { "date", "+%F %T.%3N" };

  expanded.format.* = std.fmt.allocPrint(expanded.allocator.*, format, args) catch |err|
  {
    std.log.err ("{s} expanded format allocPrint error", .{ function });
    return err;
  };

  var child = std.process.Child.init(&command, expanded.allocator.*);
  child.stdin_behavior = .Ignore;
  child.stdout_behavior = .Pipe;
  child.stderr_behavior = .Pipe;

  var stdout = std.ArrayList (u8).init (expanded.allocator.*);
  var stderr = std.ArrayList (u8).init (expanded.allocator.*);
  defer
  {
      stdout.deinit ();
      stderr.deinit ();
  }

  child.spawn () catch |err|
  {
    std.log.err ("{s} child spawn error", .{ function });
    return err;
  };

  child.collectOutput (&stdout, &stderr, 4096) catch |err|
  {
    std.log.err ("{s} child collect output error", .{ function });
    return err;
  };

  const status = child.wait () catch |err|
  {
    std.log.err ("{s} child wait error", .{ function });
    return err;
  };

  if (status.Exited != 0)
  {
    std.log.err ("{s} {s} command exit code is {}", .{ function, command, status });
    return UtilsError.DateProcessError;
  }

  date.* = stdout.toOwnedSlice () catch |err|
  {
    std.log.err ("{s} stdout to owned slice error", .{ function });
    return err;
  };

  date.* = date.*[0..date.len - 1];
}

pub fn debug_vk (comptime format: [] const u8, severity: [] const u8, _type: [] const u8, args: anytype) !void
{
  if (build.LOG_LEVEL > @enumToInt(profile.TURBO))
  {
    var allocator: std.mem.Allocator = undefined;
    var expanded_format: [] const u8 = undefined;
    var date: [] const u8 = undefined;
    try debug ("debug_vk", .{ .format = &expanded_format, .allocator = &allocator }, &date, format, args);
    defer allocator.free (expanded_format);
    std.debug.print ("[{s}: vulkan {s} {s}] {s}\n", .{ date, severity, _type, expanded_format });
  }
}

pub fn debug_spacedream (comptime format: [] const u8, args: anytype) !void
{
  if (build.LOG_LEVEL > @enumToInt(profile.DEFAULT))
  {
    var allocator: std.mem.Allocator = undefined;
    var expanded_format: [] const u8 = undefined;
    var date: [] const u8 = undefined;
    try debug ("debug_spacedream", .{ .format = &expanded_format, .allocator = &allocator }, &date, format, args);
    defer allocator.free (expanded_format);
    std.debug.print ("[{s}: spacedream] {s}\n", .{ date, expanded_format });
  }
}
