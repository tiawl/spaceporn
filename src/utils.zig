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

  pub fn expand (self: Self, expanded: anytype, args: anytype) !void
  {
    switch (self)
    {
      Self.DEBUG => { expanded.format.* = try std.fmt.allocPrint(expanded.allocator.*, "[{s}{s} DEBUG{s}] {s}\n", args); },
      Self.INFO => { expanded.format.* = try std.fmt.allocPrint(expanded.allocator.*, "[{s}{s} INFO{s}] {s}\n", args); },
      Self.WARNING => { expanded.format.* = try std.fmt.allocPrint(expanded.allocator.*, "[{s}{s} WARNING{s}] {s}\n", args); },
      Self.ERROR => { expanded.format.* = try std.fmt.allocPrint(expanded.allocator.*, "[{s}{s} ERROR{s}] {s}\n", args); },
    }
  }

  pub fn print (self: Self, to_print: [] const u8) !void
  {
    switch (self)
    {
      Self.DEBUG,Self.INFO => { try stdout.print ("{s}", .{ to_print }); },
      Self.WARNING,Self.ERROR => { stderr.print ("{s}", .{ to_print }); },
    }
  }
};

const UtilsError = error
{
  ProcessFailed,
};

fn sys_date (expanded: anytype, date: *[] const u8,
             comptime format: [] const u8, args: anytype) !void
{
  expanded.format.* = try std.fmt.allocPrint(expanded.allocator.*, format, args);

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

    try child.spawn ();
    try child.collectOutput (&out, &_err, 4096);
    const status = try child.wait ();

    if (status.Exited != 0)
    {
      stderr.print ("[spacedream ERROR] {s} command exit code is {}\n", .{ command, status });
      return UtilsError.ProcessFailed;
    }

    date.* = try out.toOwnedSlice ();
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

pub fn log (comptime format: [] const u8, id: [] const u8, sev: severity, _type: [] const u8, args: anytype) !void
{
  if (is_logging (sev))
  {
    var expanded_format: [] const u8 = undefined;
    var date: [] const u8 = undefined;

    var buffer: [4096] u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init (&buffer);
    const allocator = fba.allocator ();

    try sys_date (.{ .format = &expanded_format, .allocator = &allocator }, &date, format, args);
    defer allocator.free (expanded_format);

    var full_expanded_format: [] const u8 = undefined;

    var gpa = std.heap.GeneralPurposeAllocator (.{}){};
    defer _ = gpa.deinit ();
    const full_allocator = gpa.allocator ();

    try sev.expand (.{ .format = &full_expanded_format, .allocator = &full_allocator }, .{ date, id, _type, expanded_format });
    defer full_allocator.free (full_expanded_format);

    try sev.print (full_expanded_format);

    if (build.LOG_DIR.len > 0)
    {
      var file = try std.fs.cwd ().openFile (log_file, .{ .mode = std.fs.File.OpenMode.write_only });
      defer file.close ();

      try file.seekFromEnd (0);
      _ = try file.writeAll (full_expanded_format);
    }
  }
}

pub fn log_vk (comptime format: [] const u8, sev: severity, _type: [] const u8, args: anytype) !void
{
  try log (format, "vulkan", sev, _type, args);
}

pub fn log_app (comptime format: [] const u8, sev: severity, args: anytype) !void
{
  try log (format, "spacedream", sev, "", args);
}
