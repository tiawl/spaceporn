const std = @import ("std");
const stdout = std.io.getStdOut ().writer ();
const stderr = std.debug;

const build = @import ("build");
pub const exe: [*:0] const u8 = build.name [0 .. :0];
pub const log_file = build.log_dir ++ "/" ++ exe ++ ".log";

pub const Profile = enum { TURBO = 0, DEFAULT, DEV, };
pub const Event = enum { GENERAL, VALIDATION, PERFORMANCE, @"DEVICE ADDR BINDING", };

fn now (allocator: std.mem.Allocator) ![] const u8
{
  if (build.log_level > @intFromEnum (.TURBO)) return "X" ** 29;

  const ns_ts = std.time.nanoTimestamp ();
  const instant = @import ("datetime").datetime.Datetime.fromTimestamp (@intCast (@divFloor (ns_ts, std.time.ns_per_ms)));

  return try std.fmt.allocPrint (allocator,
    "{d:0>4}-{d:0>2}-{d:0>2} {d:0>2}:{d:0>2}:{d:0>2}.{d:0>9}",
    .{
       instant.date.year,
       instant.date.month,
       instant.date.day,
       instant.time.hour,
       instant.time.minute,
       instant.time.second,
       @as (u32, @intCast (@mod (ns_ts, std.time.ns_per_s))),
     },
  );
}

pub const Level = enum
{
  DEBUG,
  INFO,
  WARNING,
  ERROR,

  pub fn expand (self: @This (), allocator: std.mem.Allocator,
    caller: [*:0] const u8, event: ?Event, expanded: [] const u8) ![] const u8
  {
    return try std.fmt.allocPrint (allocator, "[{s}: {s} {s}{s}] {s}\n",
      .{ try now (allocator), caller, @tagName (self),
         if (event) |e| " " ++ @tagName (e) else "", expanded, });
  }

  pub fn print (self: @This (), message: [] const u8) !void
  {
    switch (self)
    {
      .DEBUG,.INFO    => try stdout.print ("{s}", .{ message, }),
      .WARNING,.ERROR => stderr.print ("{s}", .{ message, }),
    }
  }
};

fn is_logging (level: Level, min: Level) bool
{
  return (build.log_level == @intFromEnum (.DEV)
      or (build.log_level == @intFromEnum (.DEFAULT) and @intFromEnum (level) >= @intFromEnum (min)));
}

pub fn log (caller: [*:0] const u8, level: Level, event: ?Event,
  comptime format: [] const u8, args: anytype) !void
{
  var arena = std.heap.ArenaAllocator.init (std.heap.page_allocator);
  defer arena.deinit ();
  const allocator = arena.allocator ();

  const expanded = try std.fmt.allocPrint (allocator, format, args);
  const message = try level.expand (allocator, caller, event, expanded);

  try level.print (message);

  if (build.log_dir.len > 0)
  {
    var file = try std.fs.cwd ().openFile (log_file, .{ .mode = std.fs.File.OpenMode.write_only });
    defer file.close ();

    try file.seekFromEnd (0);
    _ = try file.writeAll (message [0 .. 1] ++ message [32 ..]);
  }
}

pub fn log_vk (level: Level, event: Event, comptime format: [] const u8, args: anytype) !void
{
  if (is_logging (level, .WARNING)) try log ("vulkan", level, event, format, args);
}

pub fn log_app (level: Level, comptime format: [] const u8, args: anytype) !void
{
  if (is_logging (level, .INFO)) try log (exe, level, null, format, args);
}
