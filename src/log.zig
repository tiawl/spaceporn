const std = @import ("std");
const stdout = std.io.getStdOut ().writer ();
const stderr = std.debug;

const build = @import ("build");

pub const exe: [*:0] const u8 = build.name [0 .. :0];
pub const version = build.version;
pub const dir = build.log_dir;
pub const profile: Profile = @enumFromInt (build.log_level);
pub const file = dir ++ "/" ++ exe ++ ".log";

const LevelInt = u8;
pub const Level = enum (LevelInt)
{
  DEBUG = 0, INFO, WARNING, ERROR,

  pub fn header (self: @This (), allocator: *const std.mem.Allocator,
    caller: [*:0] const u8, event: ?Event) ![] const u8
  {
    return try std.fmt.allocPrint (allocator.*, "[{s}: {s} {s}{s}]",
      .{ try now (allocator), caller, @tagName (self),
         if (event) |e| try e.tag (allocator) else "", });
  }

  pub fn print (self: @This (), entry: [] const u8) !void
  {
    switch (self)
    {
      .DEBUG,.INFO    => try stdout.print ("{s}", .{ entry, }),
      .WARNING,.ERROR => stderr.print ("{s}", .{ entry, }),
    }
  }

  pub fn int (self: @This ()) LevelInt { return @intFromEnum (self); }
  pub fn lt (self: @This (), other: @This ()) bool { return self.int () < other.int (); }
  pub fn ge (self: @This (), other: @This ()) bool { return !self.lt (other); }
};

const ProfileInt = u8;
pub const Profile = enum (ProfileInt)
{
  TURBO = 0, DEFAULT, DEV,

  pub fn int (self: @This ()) ProfileInt { return @intFromEnum (self); }
  pub fn eql (self: @This (), other: @This ()) bool { return self == other; }
  pub fn gt (self: @This (), other: @This ()) bool { return self.int () > other.int (); }

  fn allows (self: @This (), lvl: Level, min: Level) bool
  {
    return (self.eql (.DEV) or (self.eql (.DEFAULT) and lvl.ge (min)));
  }
};

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
  if (profile.gt (.TURBO)) return "X" ** 29;

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

fn write (allocator: *const std.mem.Allocator, caller: [*:0] const u8, lvl: Level,
  event: ?Event, comptime format: [] const u8, args: anytype) !void
{
  const message = try std.fmt.allocPrint (allocator.*, format, args);
  const header = try lvl.header (allocator, caller, event);
  var entry = try std.fmt.allocPrint (allocator.*, "{s} {s}\n", .{ header, message, });

  try lvl.print (entry);

  if (dir.len > 0)
  {
    var handle = try std.fs.cwd ().openFile (file, .{ .mode = .write_only, });
    defer handle.close ();

    try handle.seekFromEnd (0);
    entry = try std.fmt.allocPrint (allocator.*, "{s}{s}\n", .{ entry [0 .. 1], entry [32 ..], });
    _ = try handle.writeAll (entry);
  }
}

pub fn vk (allocator: *const std.mem.Allocator, lvl: Level, event: Event, comptime format: [] const u8, args: anytype) !void
{
  if (profile.allows (lvl, .WARNING)) try write (allocator, "vulkan", lvl, event, format, args);
}

pub fn app (allocator: *const std.mem.Allocator, lvl: Level, comptime format: [] const u8, args: anytype) !void
{
  if (profile.allows (lvl, .INFO)) try write (allocator, exe, lvl, null, format, args);
}
