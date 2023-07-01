const std = @import ("std");

const build = @import ("build_options");

const utils    = @import ("utils.zig");
const exe      = utils.exe;
const log_app  = utils.log_app;
const profile  = utils.profile;
const severity = utils.severity;

pub const options = struct
{
  const DEFAULT_HELP = false;
  const SHORT_HELP   = "-h";
  const LONG_HELP    = "--help";

  const DEFAULT_OUTPUT = "./" ++ exe ++ ".output";
  const SHORT_OUTPUT   = "-o";
  const LONG_OUTPUT    = "--output";

  const DEFAULT_SEED = null;
  const SHORT_SEED   = "-S";
  const LONG_SEED    = "--seed";

  const DEFAULT_VERSION = false;
  const SHORT_VERSION   = "-v";
  const LONG_VERSION    = "--version";

  const OptionsWindow = enum
  {
    Basic,
  };

  const DEFAULT_WINDOW = OptionsWindow.Basic;
  const SHORT_WINDOW   = "-w";
  const LONG_WINDOW    = "--window";

  const DEFAULT_CAMERA_DYNAMIC = false;
  const CAMERA_DYNAMIC         = "--camera-dynamic";
  const CAMERA_DYNAMIC_NO      = "--no-camera-dynamic";

  const DEFAULT_CAMERA_FPS = null;
  const CAMERA_FPS         = "--camera-fps";

  const DEFAULT_CAMERA_PIXEL = 200;
  const CAMERA_PIXEL         = "--camera-pixel";

  const DEFAULT_CAMERA_SLIDE = null;
  const CAMERA_SLIDE         = "--camera-slide";

  const DEFAULT_CAMERA_ZOOM = null;
  const CAMERA_ZOOM         = "--camera-zoom";

  const DEFAULT_COLORS_SMOOTH = false;
  const COLORS_SMOOTH         = "--colors-smooth";
  const COLORS_SMOOTH_NO      = "--no-colors-smooth";

  const DEFAULT_STARS_DYNAMIC = false;
  const STARS_DYNAMIC         = "--stars-dynamic";
  const STARS_DYNAMIC_NO      = "--no-stars-dynamic";

  help:    bool          = DEFAULT_HELP,
  output:  [] const u8   = DEFAULT_OUTPUT,
  seed:    ?u32          = DEFAULT_SEED,
  version: bool          = DEFAULT_VERSION,
  window:  OptionsWindow = DEFAULT_WINDOW,

  camera_dynamic: bool = DEFAULT_CAMERA_DYNAMIC,
  camera_fps:     ?u8  = DEFAULT_CAMERA_FPS,
  camera_pixel:   u32  = DEFAULT_CAMERA_PIXEL,
  camera_slide:   ?u32 = DEFAULT_CAMERA_SLIDE,
  camera_zoom:    ?u32 = DEFAULT_CAMERA_ZOOM,

  colors_smooth: bool = DEFAULT_COLORS_SMOOTH,

  stars_dynamic: bool = DEFAULT_STARS_DYNAMIC,

  const Self = @This ();

  const OptionsError = error
  {
    NoExecutableName,
    MissingArgument,
    UnknownOption,
    UnknownArgument,
  };

  fn parse (self: *Self, allocator: std.mem.Allocator) !void
  {
    var opts_iterator = try std.process.argsWithAllocator (allocator);
    defer opts_iterator.deinit();

    _ = opts_iterator.next () orelse
        {
          return OptionsError.NoExecutableName;
        };

    var opts = std.ArrayList ([] const u8).init (allocator);
    defer opts.deinit ();

    while (opts_iterator.next ()) |opt|
    {
      try opts.append (opt);
    }

    var index: usize = 0;
    var new_opt_used = false;
    var new_opt: [] const u8 = undefined;
    defer if (new_opt_used) allocator.free (new_opt);

    while (index < opts.items.len)
    {
      std.log.debug ("{s} | {s}", .{opts.items, opts.items [index]});

      // Handle '-abc' the same as '-a -bc' for short-form no-arg options
      if (opts.items [index][0] == '-' and opts.items [index].len > 2
          and (opts.items [index][1] == SHORT_HELP [1]
            or opts.items [index][1] == SHORT_VERSION [1]
              )
         )
      {
        try opts.insert (index + 1, opts.items [index][0..2]);
        new_opt = try std.fmt.allocPrint(allocator, "-{s}", .{ opts.items [index][2..] });
        new_opt_used = true;
        try opts.insert (index + 2, new_opt [0..]);
        _ = opts.orderedRemove (index);
        index += 1;
        continue;
      }

      // Handle '-foo' the same as '-f oo' for short-form 1-arg options
      if (opts.items [index][0] == '-' and opts.items [index].len > 2
          and (opts.items [index][1] == SHORT_OUTPUT [1]
            or opts.items [index][1] == SHORT_SEED [1]
            or opts.items [index][1] == SHORT_WINDOW [1]
              )
         )
      {
        try opts.insert (index + 1, opts.items [index][0..2]);
        try opts.insert (index + 2, opts.items [index][2..]);
        _ = opts.orderedRemove (index);
        index += 2;
        continue;
      }

      // Handle '--file=file1' the same as '--file file1' for long-form 1-arg options
      if (    std.mem.startsWith (u8, opts.items [index], CAMERA_PIXEL ++ "=")
           or std.mem.startsWith (u8, opts.items [index], CAMERA_ZOOM ++ "=")
           or std.mem.startsWith (u8, opts.items [index], LONG_OUTPUT ++ "=")
           or std.mem.startsWith (u8, opts.items [index], LONG_SEED ++ "=")
           or std.mem.startsWith (u8, opts.items [index], LONG_WINDOW ++ "=")
         )
      {
        const eq_index = std.mem.indexOf (u8, opts.items [index], "=").?;
        try opts.insert (index + 1, opts.items [index][0..eq_index]);
        try opts.insert (index + 2, opts.items [index][(eq_index + 1)..]);
        _ = opts.orderedRemove (index);
        index += 2;
        continue;
      }

      if (std.mem.eql (u8, opts.items [index], SHORT_HELP) or std.mem.eql (u8, opts.items [index], LONG_HELP))
      {
        self.help = true;
        break;
      // version option
      } else if (std.mem.eql (u8, opts.items [index], SHORT_VERSION) or std.mem.eql (u8, opts.items [index], LONG_VERSION)) {
        self.version = true;
        break;
      } else {
        try log_app ("unknown option: '{s}'", severity.ERROR, .{ opts.items [index] });
        return OptionsError.UnknownOption;
      }

      index += 1;
    }
  }

  fn check (self: Self) void
  {
    _ = self;
  }

  fn show (self: Self) !void
  {
    if (self.camera_slide == null)
    {
      try log_app ("Slide mode: not used", severity.INFO, .{});
    } else {
      try log_app ("Slide mode: every {d} minutes", severity.INFO, .{ self.camera_slide.? });
    }
  }

  pub fn init (allocator: std.mem.Allocator) !Self
  {
    var self = Self {};

    try self.parse (allocator);
    self.check ();
    if (build.LOG_LEVEL > @intFromEnum (profile.TURBO)) try self.show ();
    //std.process.exit (0);

    return self;
  }
};
