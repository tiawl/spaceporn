const std = @import ("std");
const stdout = std.io.getStdOut ().writer ();
const stderr = std.debug;

const datetime = @import ("datetime").datetime;

const build = @import ("build_options");
pub const exe: [*:0] const u8 = build.EXE [0..:0];
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

  pub fn expand (self: Self, to_expand: anytype) !void
  {
    switch (self)
    {
      Self.DEBUG =>   {
                        to_expand.format.log.* = try std.fmt.allocPrint(to_expand.allocator, "[{s}: {s} DEBUG{s}] {s}\n", to_expand.args.log);
                        to_expand.format.stdout.* = try std.fmt.allocPrint(to_expand.allocator, "[{s} DEBUG{s}] {s}\n", to_expand.args.stdout);
                      },
      Self.INFO =>    {
                        to_expand.format.log.* = try std.fmt.allocPrint(to_expand.allocator, "[{s}: {s} INFO{s}] {s}\n", to_expand.args.log);
                        to_expand.format.stdout.* = try std.fmt.allocPrint(to_expand.allocator, "[{s} INFO{s}] {s}\n", to_expand.args.stdout);
                      },
      Self.WARNING => {
                        to_expand.format.log.* = try std.fmt.allocPrint(to_expand.allocator, "[{s}: {s} WARNING{s}] {s}\n", to_expand.args.log);
                        to_expand.format.stdout.* = try std.fmt.allocPrint(to_expand.allocator, "[{s} WARNING{s}] {s}\n", to_expand.args.stdout);
                      },
      Self.ERROR =>   {
                        to_expand.format.log.* = try std.fmt.allocPrint(to_expand.allocator, "[{s}: {s} ERROR{s}] {s}\n", to_expand.args.log);
                        to_expand.format.stdout.* = try std.fmt.allocPrint(to_expand.allocator, "[{s} ERROR{s}] {s}\n", to_expand.args.stdout);
                      },
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
  expanded.format.* = try std.fmt.allocPrint(expanded.allocator, format, args);

  if (build.LOG_LEVEL > @intFromEnum (profile.TURBO))
  {
    const now = datetime.Datetime.now ();
    date.* = try now.formatISO8601 (expanded.allocator, true);
  } else {
    date.* = "";
  }
}

fn is_logging (sev: severity, min_sev: severity) bool
{
  return (   build.LOG_LEVEL == @intFromEnum (profile.DEV) or
           ( build.LOG_LEVEL == @intFromEnum (profile.DEFAULT) and @intFromEnum (sev) >= @intFromEnum (min_sev) ) );
}

pub fn log (comptime format: [] const u8, id: [*:0] const u8, sev: severity, min_sev: severity,  _type: [] const u8, args: anytype) !void
{
  if (is_logging (sev, min_sev))
  {
    var expanded: [] const u8 = undefined;
    var date: [] const u8 = undefined;

    var arena = std.heap.ArenaAllocator.init (std.heap.page_allocator);
    defer arena.deinit ();
    const allocator = arena.allocator ();

    try sys_date (.{ .format = &expanded, .allocator = allocator }, &date, format, args);

    var log_format: [] const u8 = undefined;
    var stdout_format: [] const u8 = undefined;

    try sev.expand (.{ .format = .{ .log = &log_format, .stdout = &stdout_format }, .allocator = allocator, .args = .{ .log = .{ date, id, _type, expanded }, .stdout = .{ id, _type, expanded },},});

    try sev.print (stdout_format);

    if (build.LOG_DIR.len > 0)
    {
      var file = try std.fs.cwd ().openFile (log_file, .{ .mode = std.fs.File.OpenMode.write_only });
      defer file.close ();

      try file.seekFromEnd (0);
      _ = try file.writeAll (log_format);
    }
  }
}

pub fn log_vk (comptime format: [] const u8, sev: severity, _type: [] const u8, args: anytype) !void
{
  try log (format, "vulkan", sev, severity.WARNING, _type, args);
}

pub fn log_app (comptime format: [] const u8, sev: severity, args: anytype) !void
{
  try log (format, exe, sev, severity.INFO, "", args);
}
