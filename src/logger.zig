const std = @import ("std");
const stdout = std.io.getStdOut ().writer ();
const stderr = std.io.getStdErr ().writer ();

const Build = struct
{
  const options = @import ("build");

  const Binary = struct
  {
    name: [:0] const u8 = options.name [0 .. :0],
    version: [] const u8 = options.version,
  };

  const Vk = struct
  {
    optional_extensions: [] const [] const [] const u8 = options.vk_optional_extensions,
    minor: [] const u8 = options.vk_minor,
  };

  profile: Profile = @enumFromInt (options.log_level),
  binary: Binary = .{},
  log: struct {
    path: [:0] const u8 = options.log_dir ++ "/" ++ options.name [0 .. :0] ++ ".log",
    dir: [] const u8 = options.log_dir,
  } = .{},
  vk: Vk = .{},
};

const LevelInt = u8;
const Level = enum (LevelInt)
{
  DEBUG = 0, INFO, WARNING, ERROR,

  pub fn int (self: @This ()) LevelInt { return @intFromEnum (self); }
  pub fn lt (self: @This (), other: @This ()) bool { return self.int () < other.int (); }
  pub fn ge (self: @This (), other: @This ()) bool { return !self.lt (other); }
};

fn access (path: [] const u8) bool
{
  if (path.len == 0) return false;
  std.fs.accessAbsolute (path, .{}) catch return false;
  return true;
}

fn print (level: Level, entry: [] const u8) !void
{
  const writer = switch (level)
  {
    .DEBUG,.INFO    => stdout,
    .WARNING,.ERROR => stderr,
  };
  try writer.print ("{s}", .{ entry, });
}

fn create_file (path: [] const u8) !void
{
  const handle = std.fs.createFileAbsolute (path, .{ .exclusive = true, }) catch |err| switch (err)
                 {
                   error.PathAlreadyExists => return,
                   else => return err,
                 };
  defer handle.close ();
}

const ProfileInt = u8;
const Profile = enum (ProfileInt)
{
  TURBO = 0, DEFAULT, DEV,

  pub fn int (self: @This ()) ProfileInt { return @intFromEnum (self); }
  pub fn eql (self: @This (), other: @This ()) bool { return self == other; }
  pub fn gt (self: @This (), other: @This ()) bool { return self.int () > other.int (); }
};

const Event = enum { GENERAL, VALIDATION, PERFORMANCE, @"DEVICE ADDR BINDING", };

pub const Logger = struct
{
  allocator: *const std.mem.Allocator,
  file: ?std.fs.File = null,

  pub const build: Build = .{};

  pub fn init (allocator: *const std.mem.Allocator) !@This ()
  {
    var self: @This () = .{ .allocator = allocator, };

    if (Logger.build.profile.gt (.TURBO) and access (Logger.build.log.dir))
    {
      try create_file (Logger.build.log.path);

      self.file = try std.fs.openFileAbsolute (Logger.build.log.path, .{ .mode = .write_only, });
      try self.app (.DEBUG, "log file init OK", .{});
    }

    return self;
  }

  pub fn deinit (self: @This ()) void
  {
    if (self.file) |handle| handle.close ();
  }

  pub fn version () void
  {
    std.debug.print ("{s} {s}\n", .{ Logger.build.binary.name, Logger.build.binary.version, });
  }

  fn now (self: @This ()) ![] const u8
  {
    if (Logger.build.profile.eql (.TURBO) or !access (Logger.build.log.dir))
      return "X" ** 29;

    const ns_ts = std.time.nanoTimestamp ();
    const instant = @import ("datetime").datetime.Datetime.fromTimestamp (@intCast (@divFloor (ns_ts, std.time.ns_per_ms)));

    return try std.fmt.allocPrint (self.allocator.*,
      "{d:0>4}-{d:0>2}-{d:0>2} {d:0>2}:{d:0>2}:{d:0>2}.{d:0>9}",
      .{
         instant.date.year, instant.date.month, instant.date.day,
         instant.time.hour, instant.time.minute, instant.time.second,
         @as (u32, @intCast (@mod (ns_ts, std.time.ns_per_s))),
       },
    );
  }

  fn header (self: @This (), level: Level, caller: [*:0] const u8, event: ?Event) ![] const u8
  {
    return try std.fmt.allocPrint (self.allocator.*, "[{s}: {s} {s}{s}{s}]",
      .{ try self.now (), caller, @tagName (level), if (event) |_| " " else "",
         if (event) |e| @tagName (e) else "", });
  }

  fn write (self: @This (), caller: [*:0] const u8, level: Level,
    event: ?Event, comptime format: [] const u8, args: anytype) !void
  {
    const message = try std.fmt.allocPrint (self.allocator.*, format, args);
    const head = try self.header (level, caller, event);
    var entry = try std.fmt.allocPrint (self.allocator.*, "{s} {s}\n", .{ head, message, });

    try print (level, try std.fmt.allocPrint (self.allocator.*, "{s}{s}", .{ entry [0 .. 1], entry [32 ..], }));

    if (access (Logger.build.log.path))
    {
      try self.file.?.seekFromEnd (0);
      _ = try self.file.?.writeAll (entry);
    }
  }

  fn allows (level: Level, min: Level) bool
  {
    return (Logger.build.profile.eql (.DEV) or (Logger.build.profile.eql (.DEFAULT) and level.ge (min)));
  }

  pub fn vk (self: @This (), level: Level, event: Event, comptime format: [] const u8, args: anytype) !void
  {
    if (allows (level, .WARNING)) try self.write ("vulkan", level, event, format, args);
  }

  pub fn app (self: @This (), level: Level, comptime format: [] const u8, args: anytype) !void
  {
    if (allows (level, .INFO)) try self.write (Logger.build.binary.name, level, null, format, args);
  }
};
