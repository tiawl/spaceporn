const std = @import ("std");
const stdout = std.io.getStdOut ().writer ();
const stderr = std.debug;

const build = @import ("build_options");
pub const exe: [*:0] const u8 = build.EXE.ptr[0..build.EXE.len :0];
pub const log_file = build.LOG_DIR ++ "/" ++ exe ++ ".log";

pub const profile = enum
{
  TURBO,
  DEFAULT,
  DEV,
};

pub const severity = enum
{
  DEBUG,
  INFO,
  WARNING,
  ERROR,

  const Self = @This ();

  pub fn print (self: Self, args: anytype) !void
  {
    switch (self)
    {
      Self.DEBUG => { try stdout.print ("[{s}{s} DEBUG{s}] {s}\n", args); },
      Self.INFO => { try stdout.print ("[{s}{s} INFO{s}] {s}\n", args); },
      Self.WARNING => { stderr.print ("[{s}{s} WARNING{s}] {s}\n", args); },
      Self.ERROR => { stderr.print ("[{s}{s} ERROR{s}] {s}\n", args); },
    }
  }
};

const UtilsError = error
{
  ProcessFailed,
};

fn log (function: [] const u8, expanded: anytype, date: *[] const u8,
          comptime format: [] const u8, args: anytype) !void
{
  var buffer: [4096] u8 = undefined;
  var fba = std.heap.FixedBufferAllocator.init (&buffer);
  expanded.allocator.* = fba.allocator ();

  expanded.format.* = std.fmt.allocPrint(expanded.allocator.*, format, args) catch |err|
  {
    stderr.print ("[spacedream ERROR] {s} expanded format allocPrint error\n", .{ function });
    return err;
  };

  if (build.LOG_LEVEL > @enumToInt (profile.DEFAULT))
  {
    const command = [_][] const u8 { "date", "+%F %T.%3N: " };
    var child = std.process.Child.init(&command, expanded.allocator.*);
    child.stdin_behavior = .Ignore;
    child.stdout_behavior = .Pipe;
    child.stderr_behavior = .Pipe;

    var out = std.ArrayList (u8).init (expanded.allocator.*);
    defer out.deinit ();
    var _err = std.ArrayList (u8).init (expanded.allocator.*);
    defer _err.deinit ();

    child.spawn () catch |err|
    {
      stderr.print ("[spacedream ERROR] {s} child spawn error\n", .{ function });
      return err;
    };

    child.collectOutput (&out, &_err, 4096) catch |err|
    {
      stderr.print ("[spacedream ERROR] {s} child collect output error\n", .{ function });
      return err;
    };

    const status = child.wait () catch |err|
    {
      stderr.print ("[spacedream ERROR] {s} child wait error\n", .{ function });
      return err;
    };

    if (status.Exited != 0)
    {
      stderr.print ("[spacedream ERROR] {s} {s} command exit code is {}\n", .{ function, command, status });
      return UtilsError.ProcessFailed;
    }

    date.* = out.toOwnedSlice () catch |err|
    {
      stderr.print ("[spacedream ERROR] {s} stdout to owned slice error\n", .{ function });
      return err;
    };

    date.* = date.*[0..date.len - 1];
  } else {
    date.* = "";
  }
}

pub fn is_logging (sev: severity) bool
{
  return (   (build.LOG_LEVEL == @enumToInt (profile.DEV)) or
           ( (build.LOG_LEVEL == @enumToInt (profile.DEFAULT)) and (@enumToInt (sev) > @enumToInt (severity.DEBUG)) ) );
}

pub fn log_vk (comptime format: [] const u8, sev: severity, _type: [] const u8, args: anytype) !void
{
  if (is_logging (sev))
  {
    var allocator: std.mem.Allocator = undefined;
    var expanded_format: [] const u8 = undefined;
    var date: [] const u8 = undefined;
    try log ("log_vk", .{ .format = &expanded_format, .allocator = &allocator }, &date, format, args);
    defer allocator.free (expanded_format);
    try sev.print (.{ date, "vulkan", _type, expanded_format });
  }
}

pub fn log_app (comptime format: [] const u8, sev: severity, args: anytype) !void
{
  if (is_logging (sev))
  {
    var allocator: std.mem.Allocator = undefined;
    var expanded_format: [] const u8 = undefined;
    var date: [] const u8 = undefined;
    try log ("log_app", .{ .format = &expanded_format, .allocator = &allocator }, &date, format, args);
    defer allocator.free (expanded_format);
    try sev.print (.{ date, "spacedream", "", expanded_format });
  }
}
