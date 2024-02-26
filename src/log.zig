const std = @import ("std");
const stdout = std.io.getStdOut ().writer ();
const stderr = std.debug;

const build = @import ("build");

pub const Log = struct
{
  pub const exe: [*:0] const u8 = build.name [0 .. :0];
  pub const version = build.version;
  pub const dir = build.log_dir;
  pub const level = build.log_level;
  pub const file = dir ++ "/" ++ exe ++ ".log";

  pub const Profile = enum (u8) { TURBO = 0, DEFAULT, DEV, };
  pub const Event = enum
  {
    GENERAL, VALIDATION, PERFORMANCE, @"DEVICE ADDR BINDING",

    fn tag (self: @This (), allocator: *const std.mem.Allocator) ![] const u8
    {
      return try std.fmt.allocPrint (allocator.*, " {s}", .{ @tagName (self), });
    }
  };

  fn now (allocator: *const std.mem.Allocator) ![] const u8
  {
    if (level > @intFromEnum (Profile.TURBO)) return "X" ** 29;

    const ns_ts = std.time.nanoTimestamp ();
    const instant = @import ("datetime").datetime.Datetime.fromTimestamp (@intCast (@divFloor (ns_ts, std.time.ns_per_ms)));

    return try std.fmt.allocPrint (allocator.*,
      "{d:0>4}-{d:0>2}-{d:0>2} {d:0>2}:{d:0>2}:{d:0>2}.{d:0>9}",
      .{
         instant.date.year, instant.date.month, instant.date.day,
         instant.time.hour, instant.time.minute, instant.time.second,
         @as (u32, @intCast (@mod (ns_ts, std.time.ns_per_s))),
       },
    );
  }

  pub const Level = enum
  {
    DEBUG, INFO, WARNING, ERROR,

    pub fn expand (self: @This (), allocator: *const std.mem.Allocator,
      caller: [*:0] const u8, event: ?Event, expanded: [] const u8) ![] const u8
    {
      return try std.fmt.allocPrint (allocator.*, "[{s}: {s} {s}{s}] {s}\n",
        .{ try now (allocator), caller, @tagName (self),
           if (event) |e| try e.tag (allocator) else "", expanded, });
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

  fn is_logging (lvl: Level, min: Level) bool
  {
    return (level == @intFromEnum (Profile.DEV)
        or (level == @intFromEnum (Profile.DEFAULT) and @intFromEnum (lvl) >= @intFromEnum (min)));
  }

  fn log (caller: [*:0] const u8, lvl: Level, event: ?Event,
    comptime format: [] const u8, args: anytype) !void
  {
    var arena = std.heap.ArenaAllocator.init (std.heap.page_allocator);
    defer arena.deinit ();
    const allocator = arena.allocator ();

    const expanded = try std.fmt.allocPrint (allocator, format, args);
    const message = try lvl.expand (&allocator, caller, event, expanded);

    try lvl.print (message);

    if (dir.len > 0)
    {
      var handle = try std.fs.cwd ().openFile (file, .{ .mode = std.fs.File.OpenMode.write_only });
      defer handle.close ();

      try handle.seekFromEnd (0);
      _ = try handle.writeAll (message [0 .. 1] ++ message [32 ..]);
    }
  }

  pub fn vk (lvl: Level, event: Event, comptime format: [] const u8, args: anytype) !void
  {
    if (is_logging (lvl, .WARNING)) try log ("vulkan", lvl, event, format, args);
  }

  pub fn app (lvl: Level, comptime format: [] const u8, args: anytype) !void
  {
    if (is_logging (lvl, .INFO)) try log (exe, lvl, null, format, args);
  }
};
