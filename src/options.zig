const std = @import ("std");

const Logger = @import ("logger").Logger;

pub const Options = struct
{
  const DEFAULT_HELP = false;
  const SHORT_HELP   = "-h";
  const LONG_HELP    = "--help";
  pub const HELP_FLAGS  = "  " ++ SHORT_HELP ++ ", " ++ LONG_HELP;

  const DEFAULT_VERSION = false;
  const SHORT_VERSION   = "-v";
  const LONG_VERSION    = "--version";
  pub const VERSION_FLAGS   = "  " ++ SHORT_VERSION ++ ", " ++ LONG_VERSION;

  const DEFAULT_SEED = 0;

  const DEFAULT_WINDOW_WIDTH  = 800;
  const DEFAULT_WINDOW_HEIGHT = 600;

  const DEFAULT_CAMERA_DYNAMIC = false;

  const DEFAULT_CAMERA_PIXEL = 200;
  const CAMERA_PIXEL_MIN     = 100;
  const CAMERA_PIXEL_MAX     = 600;

  const DEFAULT_CAMERA_ZOOM = 1;
  const CAMERA_ZOOM_MIN     = 1;
  const CAMERA_ZOOM_MAX     = 40;

  const DEFAULT_COLORS_SMOOTH = false;

  const DEFAULT_STARS_DYNAMIC = false;

  const MAX_FLAGS_LEN = blk:
                        {
                          var max: usize = 0;
                          for (std.meta.declarations (@This ())) |decl|
                          {
                            if (std.mem.endsWith (u8, decl.name, "_FLAGS"))
                            {
                              max = @max (max, @field (@This (), decl.name).len);
                            }
                          }
                          break :blk max;
                        };

  const camera_options = struct
  {
    dynamic: bool = DEFAULT_CAMERA_DYNAMIC,
    pixel:   u32  = DEFAULT_CAMERA_PIXEL,
    zoom:    u32  = DEFAULT_CAMERA_ZOOM,
  };

  const colors_options = struct
  {
    smooth: bool = DEFAULT_COLORS_SMOOTH,
  };

  const stars_options = struct
  {
    dynamic: bool = DEFAULT_STARS_DYNAMIC,
  };

  help:    bool                                  = DEFAULT_HELP,
  seed:    u32                                   = DEFAULT_SEED,
  version: bool                                  = DEFAULT_VERSION,
  window:  struct { width: ?u32, height: ?u32, } = .{ .width = DEFAULT_WINDOW_WIDTH, .height = DEFAULT_WINDOW_HEIGHT, },
  camera:  camera_options                        = camera_options {},
  colors:  colors_options                        = colors_options {},
  stars:   stars_options                         = stars_options {},

  const OptionsError = error
  {
    NoExecutableName,
    MissingArgument,
    UnknownOption,
    UnknownArgument,
    ZeroIntegerArgument,
    OverflowArgument,
    Help,
    Version,
  };

  fn usage_help (self: *@This ()) void
  {
    _ = self;
    std.debug.print ("{s}{s} - Print this help\n", .{ HELP_FLAGS, " " ** (MAX_FLAGS_LEN - HELP_FLAGS.len), });
  }

  fn usage_version (self: *@This ()) void
  {
    _ = self;
    std.debug.print ("{s}{s} - Print this help\n", .{ VERSION_FLAGS, " " ** (MAX_FLAGS_LEN - VERSION_FLAGS.len), });
  }

  fn usage_seed (self: *@This ()) void
  {
    _ = self;
  }

  fn usage_window (self: *@This ()) void
  {
    _ = self;
  }

  fn usage_camera_dynamic (self: *@This ()) void
  {
    _ = self;
  }

  fn usage_camera_pixel (self: *@This ()) void
  {
    _ = self;
  }

  fn usage_camera_zoom (self: *@This ()) void
  {
    _ = self;
  }

  fn usage_camera (self: *@This ()) void
  {
    inline for (std.meta.fields (@TypeOf (self.camera))) |field|
    {
      @call (.auto, @field (@This (), "usage_camera_" ++ field.name), .{ self });
    }
  }

  fn usage_colors_smooth (self: *@This ()) void
  {
    _ = self;
  }

  fn usage_colors (self: *@This ()) void
  {
    inline for (std.meta.fields (@TypeOf (self.colors))) |field|
    {
      @call (.auto, @field (@This (), "usage_colors_" ++ field.name), .{ self });
    }
  }

  fn usage_stars_dynamic (self: *@This ()) void
  {
    _ = self;
  }

  fn usage_stars (self: *@This ()) void
  {
    inline for (std.meta.fields (@TypeOf (self.stars))) |field|
    {
      @call (.auto, @field (@This (), "usage_stars_" ++ field.name), .{ self });
    }
  }

  fn usage (self: *@This ()) void
  {
    std.debug.print ("\nUsage: {s} [OPTION] ...\n\nGenerator for space contemplators\n\nOptions:\n", .{ Logger.build.binary.name, });
    inline for (std.meta.fields (@TypeOf (self.*))) |field|
    {
      @call (.auto, @field (@This (), "usage_" ++ field.name), .{ self });
    }
    std.debug.print ("\nThe {s} home page: http://www.github.com/tiawl/spaceporn\nReport {s} bugs to http://www.github.com/tiawl/spaceporn/issues\n\n", .{ Logger.build.binary.name, Logger.build.binary.name, });
  }

  fn parse (self: *@This (), logger: *const Logger, options: *std.ArrayList ([] const u8)) !void
  {
    var index: usize = 0;
    var new_opt_used = false;
    var new_opt: [] const u8 = undefined;

    while (index < options.items.len)
    {
      // Handle '-abc' the same as '-a -bc' for short-form no-arg options
      if (options.items [index][0] == '-' and options.items [index].len > 2
          and (options.items [index][1] == SHORT_HELP [1]
            or options.items [index][1] == SHORT_VERSION [1]
              )
         )
      {
        try options.insert (index + 1, options.items [index][0..2]);
        new_opt = try std.fmt.allocPrint (logger.allocator.*, "-{s}", .{ options.items [index][2..] });
        new_opt_used = true;
        try options.insert (index + 2, new_opt);
        _ = options.orderedRemove (index);
        continue;
      }

      // /!\ KEEP THIS FOR POTENTIAL REUSE /!\
      // Handle '-foo' the same as '-f oo' for short-form 1-arg options
      // if (options.items [index][0] == '-' and options.items [index].len > 2
      //     and (options.items [index][1] == SHORT_OUTPUT [1]
      //       or options.items [index][1] == SHORT_SEED [1]
      //         )
      //    )
      // {
      //   try options.insert (index + 1, options.items [index][0..2]);
      //   try options.insert (index + 2, options.items [index][2..]);
      //   _ = options.orderedRemove (index);
      //   continue;
      // }
      // /!\ KEEP THIS FOR POTENTIAL REUSE /!\

      // /!\ KEEP THIS FOR POTENTIAL REUSE /!\
      // Handle '--file=file1' the same as '--file file1' for long-form 1-arg options
      // if (    std.mem.startsWith (u8, options.items [index], CAMERA_PIXEL ++ "=")
      //      or std.mem.startsWith (u8, options.items [index], CAMERA_ZOOM ++ "=")
      //    )
      // {
      //   const eq_index = std.mem.indexOf (u8, options.items [index], "=").?;
      //   try options.insert (index + 1, options.items [index][0..eq_index]);
      //   try options.insert (index + 2, options.items [index][(eq_index + 1)..]);
      //   _ = options.orderedRemove (index);
      //   continue;
      // }
      // /!\ KEEP THIS FOR POTENTIAL REUSE /!\

      // help option
      if (std.mem.eql (u8, options.items [index], SHORT_HELP) or std.mem.eql (u8, options.items [index], LONG_HELP))
      {
        self.help = true;
      // version option
      } else if (std.mem.eql (u8, options.items [index], SHORT_VERSION) or std.mem.eql (u8, options.items [index], LONG_VERSION)) {
        self.version = true;

      // ---------------------------------------------------------------------

      } else {
        try logger.app (.ERROR, "unknown option: '{s}'", .{ options.items [index] });
        self.usage ();
        return OptionsError.UnknownOption;
      }

      index += 1;
    }
  }

  fn check (self: @This ()) !void
  {
    _ = self;
  }

  fn fix_random (self: *@This ()) void
  {
    self.seed = @intCast (@mod (std.time.milliTimestamp (), @as (i64, @intCast (std.math.maxInt (u32)))));

    self.camera.zoom = @intCast (@mod (std.time.milliTimestamp (), std.math.maxInt (u32)));
    self.camera.zoom = (self.camera.zoom % (CAMERA_ZOOM_MAX - CAMERA_ZOOM_MIN + 1)) + CAMERA_ZOOM_MIN;
  }

  pub fn init (logger: *const Logger) !@This ()
  {
    var self: @This () = .{};

    var options_iterator = try std.process.argsWithAllocator (logger.allocator.*);
    defer options_iterator.deinit();

    _ = options_iterator.next () orelse
        {
          return OptionsError.NoExecutableName;
        };

    var options = std.ArrayList ([] const u8).init (logger.allocator.*);

    while (options_iterator.next ()) |opt|
    {
      try options.append (opt);
    }

    try self.parse (logger, &options);
    try self.check ();

    if (self.help)
    {
      self.usage ();
      return OptionsError.Help;
    } else if (self.version) {
      Logger.version ();
      return OptionsError.Version;
    }

    self.fix_random ();

    return self;
  }
};
