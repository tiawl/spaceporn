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

  const DEFAULT_OUTPUT = null;
  const SHORT_OUTPUT   = "-o";
  const LONG_OUTPUT    = "--output";

  const DEFAULT_SEED = .{ .random = true, .sample = 0, };
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
  const CAMERA_DYNAMIC_NO      = "--no" ++ CAMERA_DYNAMIC [1..];

  const DEFAULT_CAMERA_FPS = null;
  const CAMERA_FPS         = "--camera-fps";

  const DEFAULT_CAMERA_PIXEL = 200;
  const CAMERA_PIXEL         = "--camera-pixel";

  const DEFAULT_CAMERA_SLIDE = null;
  const CAMERA_SLIDE         = "--camera-slide";

  const DEFAULT_CAMERA_ZOOM = .{ .random = true, .percent = 0, };
  const CAMERA_ZOOM         = "--camera-zoom";

  const Camera = struct
  {
    dynamic: bool                                   = DEFAULT_CAMERA_DYNAMIC,
    fps:     ?u8                                    = DEFAULT_CAMERA_FPS,
    pixel:   u32                                    = DEFAULT_CAMERA_PIXEL,
    slide:   ?u32                                   = DEFAULT_CAMERA_SLIDE,
    zoom:    struct { random: bool, percent: u32, } = DEFAULT_CAMERA_ZOOM,
  };

  const DEFAULT_COLORS_SMOOTH = false;
  const COLORS_SMOOTH         = "--colors-smooth";
  const COLORS_SMOOTH_NO      = "--no" ++ COLORS_SMOOTH [1..];

  const Colors = struct
  {
    smooth: bool = DEFAULT_COLORS_SMOOTH,
  };

  const DEFAULT_STARS_DYNAMIC = false;
  const STARS_DYNAMIC         = "--stars-dynamic";
  const STARS_DYNAMIC_NO      = "--no" ++ STARS_DYNAMIC [1..];

  const Stars = struct
  {
    dynamic: bool = DEFAULT_STARS_DYNAMIC,
  };

  help:    bool                                                       = DEFAULT_HELP,
  output:  ?[] const u8                                               = DEFAULT_OUTPUT,
  seed:    struct { random: bool, sample: u32, }                      = DEFAULT_SEED,
  version: bool                                                       = DEFAULT_VERSION,
  window:  struct { type: OptionsWindow, width: ?u32, height: ?u32, } = .{ .type = DEFAULT_WINDOW, .width = 800, .height = 600, },
  camera:  Camera                                                     = Camera {},
  colors:  Colors                                                     = Colors {},
  stars:   Stars                                                      = Stars {},

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
        continue;
      }

      // help option
      if (std.mem.eql (u8, opts.items [index], SHORT_HELP) or std.mem.eql (u8, opts.items [index], LONG_HELP))
      {
        self.help = true;
        break;
      // output option
      } else if (std.mem.eql (u8, opts.items [index], SHORT_OUTPUT) or std.mem.eql (u8, opts.items [index], LONG_OUTPUT)) {
        if (index + 1 >= opts.items.len)
        {
          try log_app ("missing mandatory argument with {s},{s} option", severity.ERROR, .{ SHORT_OUTPUT, LONG_OUTPUT });
          return OptionsError.MissingArgument;
        } else {
          self.output = opts.items [index + 1];
          index += 1;
        }
      // seed option
      } else if (std.mem.eql (u8, opts.items [index], SHORT_SEED) or std.mem.eql (u8, opts.items [index], LONG_SEED)) {
        if (index + 1 >= opts.items.len)
        {
          try log_app ("missing mandatory argument with {s},{s} option", severity.ERROR, .{ SHORT_SEED, LONG_SEED });
          return OptionsError.MissingArgument;
        } else {
          self.seed.sample = try std.fmt.parseInt (u32, opts.items [index + 1], 10);
          self.seed.random = false;
          index += 1;
        }
      // version option
      } else if (std.mem.eql (u8, opts.items [index], SHORT_VERSION) or std.mem.eql (u8, opts.items [index], LONG_VERSION)) {
        self.version = true;
        break;
      // window option
      } else if (std.mem.eql (u8, opts.items [index], SHORT_WINDOW) or std.mem.eql (u8, opts.items [index], LONG_WINDOW)) {
        if (index + 1 >= opts.items.len)
        {
          try log_app ("missing mandatory argument with {s},{s} option", severity.ERROR, .{ SHORT_WINDOW, LONG_WINDOW });
          return OptionsError.MissingArgument;
        } else {
          if (std.mem.count (u8, opts.items [index + 1], "x") == 1)
          {
            var token_iterator = std.mem.tokenizeScalar (u8, opts.items [index + 1], 'x');
            self.window.type = OptionsWindow.Basic;

            if (token_iterator.next ()) |token|
            {
              self.window.width = try std.fmt.parseInt(u32, token, 10);
            } else {
              try log_app ("unknown argument with {s},{s} option: '{s}'", severity.ERROR, .{ SHORT_WINDOW, LONG_WINDOW, opts.items [index + 1] });
              return OptionsError.UnknownArgument;
            }

            if (token_iterator.next ()) |token|
            {
              self.window.height = try std.fmt.parseInt(u32, token, 10);
            } else {
              try log_app ("unknown argument with {s},{s} option: '{s}'", severity.ERROR, .{ SHORT_WINDOW, LONG_WINDOW, opts.items [index + 1] });
              return OptionsError.UnknownArgument;
            }

            if (token_iterator.next () != null)
            {
              try log_app ("unknown argument with {s},{s} option: '{s}'", severity.ERROR, .{ SHORT_WINDOW, LONG_WINDOW, opts.items [index + 1] });
              return OptionsError.UnknownArgument;
            }

            index += 1;
          } else {
            try log_app ("unknown argument with {s},{s} option: '{s}'", severity.ERROR, .{ SHORT_WINDOW, LONG_WINDOW, opts.items [index + 1] });
            return OptionsError.UnknownArgument;
          }
        }

      // --- CAMERA ----------------------------------------------------------

      // camera dynamic option
      } else if (std.mem.eql (u8, opts.items [index], CAMERA_DYNAMIC)) {
        self.camera.dynamic = true;
      } else if (std.mem.eql (u8, opts.items [index], CAMERA_DYNAMIC_NO)) {
        self.camera.dynamic = false;
      // camera fps option
      } else if (std.mem.eql (u8, opts.items [index], CAMERA_FPS)) {
        if (index + 1 >= opts.items.len)
        {
          try log_app ("missing mandatory argument with {s} option", severity.ERROR, .{ CAMERA_FPS });
          return OptionsError.MissingArgument;
        } else {
          self.camera.fps = try std.fmt.parseInt (u8, opts.items [index + 1], 10);
          index += 1;
        }
      // camera pixel option
      } else if (std.mem.eql (u8, opts.items [index], CAMERA_PIXEL)) {
        if (index + 1 >= opts.items.len)
        {
          try log_app ("missing mandatory argument with {s} option", severity.ERROR, .{ CAMERA_PIXEL });
          return OptionsError.MissingArgument;
        } else {
          self.camera.pixel = try std.fmt.parseInt (u32, opts.items [index + 1], 10);
          index += 1;
        }
      // camera slide option
      } else if (std.mem.eql (u8, opts.items [index], CAMERA_SLIDE)) {
        if (index + 1 >= opts.items.len)
        {
          try log_app ("missing mandatory argument with {s} option", severity.ERROR, .{ CAMERA_SLIDE });
          return OptionsError.MissingArgument;
        } else {
          self.camera.slide = try std.fmt.parseInt (u32, opts.items [index + 1], 10);
          index += 1;
        }
      // camera zoom option
      } else if (std.mem.eql (u8, opts.items [index], CAMERA_ZOOM)) {
        if (index + 1 >= opts.items.len)
        {
          try log_app ("missing mandatory argument with {s} option", severity.ERROR, .{ CAMERA_ZOOM });
          return OptionsError.MissingArgument;
        } else {
          self.camera.zoom.percent = try std.fmt.parseInt (u32, opts.items [index + 1], 10);
          self.camera.zoom.random  = false;
          index += 1;
        }

      // --- COLORS ----------------------------------------------------------

      // colors smooth option
      } else if (std.mem.eql (u8, opts.items [index], COLORS_SMOOTH)) {
        self.colors.smooth = true;
      } else if (std.mem.eql (u8, opts.items [index], COLORS_SMOOTH_NO)) {
        self.colors.smooth = false;

      // --- STARS -----------------------------------------------------------

      // stars dynamic option
      } else if (std.mem.eql (u8, opts.items [index], STARS_DYNAMIC)) {
        self.stars.dynamic = true;
      } else if (std.mem.eql (u8, opts.items [index], STARS_DYNAMIC_NO)) {
        self.stars.dynamic = false;

      // ---------------------------------------------------------------------

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
    if (self.output == null)
    {
      try log_app ("output: not used", severity.INFO, .{});
    } else {
      try log_app ("output: {s}", severity.INFO, .{ self.output.? });
    }
    try log_app ("seed: {any}", severity.INFO, .{ self.seed });
    try log_app ("window: {any}", severity.INFO, .{ self.window });

    try log_app ("camera dynamic: {}", severity.INFO, .{ self.camera.dynamic });
    if (self.camera.fps == null)
    {
      try log_app ("camera max fps: maximum unspecified", severity.INFO, .{});
    } else {
      try log_app ("camera max fps: {d}", severity.INFO, .{ self.camera.fps.? });
    }
    try log_app ("camera pixel: {d}", severity.INFO, .{ self.camera.pixel });
    if (self.camera.slide == null)
    {
      try log_app ("camera slide mode: not used", severity.INFO, .{});
    } else {
      try log_app ("camera mode: every {d} minutes", severity.INFO, .{ self.camera.slide.? });
    }
    try log_app ("zoom: {any}", severity.INFO, .{ self.camera.zoom });

    try log_app ("colors smooth transition: {}", severity.INFO, .{ self.colors.smooth });

    try log_app ("stars dynamic transition: {}", severity.INFO, .{ self.stars.dynamic });
  }

  pub fn init (allocator: std.mem.Allocator) !Self
  {
    var self = Self {};

    try self.parse (allocator);
    self.check ();
    if (build.LOG_LEVEL > @intFromEnum (profile.TURBO)) try self.show ();

    return self;
  }
};
