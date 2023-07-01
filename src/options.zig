const std = @import ("std");

const build = @import ("build_options");

const utils    = @import ("utils.zig");
const exe      = utils.exe;
const log_app  = utils.log_app;
const profile  = utils.profile;
const severity = utils.severity;

pub const options = struct
{
  const OptionsAnimation = enum
  {
    None,
  };

  const OptionsColor = enum
  {
    BlackAndWhite,
    RandomMonochromatic,
  };

  const OptionsWindow = enum
  {
    Basic,
    Fullscreen,
  };

  const DEFAULT_ANIMATION = OptionsAnimation.None;
  const SHORT_ANIMATION   = "-a";
  const LONG_ANIMATION    = "--animate";

  const DEFAULT_COLOR = OptionsColor.BlackAndWhite;
  const SHORT_COLOR   = "-c";
  const LONG_COLOR    = "--color";

  const DEFAULT_HELP = false;
  const SHORT_HELP   = "-h";
  const LONG_HELP    = "--help";

  const DEFAULT_FPS = null;
  const SHORT_FPS   = "-f";
  const LONG_FPS    = "--fps";

  const DEFAULT_OUTPUT = "./" ++ exe ++ ".output";
  const SHORT_OUTPUT   = "-o";
  const LONG_OUTPUT    = "--output";

  const DEFAULT_PIXEL = 200;
  const SHORT_PIXEL   = "-p";
  const LONG_PIXEL    = "--pixel";

  const DEFAULT_SEED = null;
  const SHORT_SEED   = "-S";
  const LONG_SEED    = "--seed";

  const DEFAULT_SLIDE = false;
  const SHORT_SLIDE   = "-s";
  const LONG_SLIDE    = "--slide";

  const DEFAULT_VERSION = false;
  const SHORT_VERSION   = "-V";
  const LONG_VERSION    = "--version";

  const DEFAULT_WINDOW = OptionsWindow.Basic;
  const SHORT_WINDOW   = "-w";
  const LONG_WINDOW    = "--window";

  const DEFAULT_ZOOM = null;
  const SHORT_ZOOM   = "-z";
  const LONG_ZOOM    = "--zoom";

  // No-argument options
  help:    bool = DEFAULT_HELP,
  slide:   bool = DEFAULT_SLIDE,
  version: bool = DEFAULT_VERSION,

  // 1-argument options
  animation: OptionsAnimation = DEFAULT_ANIMATION,
  color:     OptionsColor     = DEFAULT_COLOR,
  fps:       ?u8           = DEFAULT_FPS,
  output:    [] const u8   = DEFAULT_OUTPUT,
  pixel:     u32           = DEFAULT_PIXEL,
  seed:      ?u32          = DEFAULT_SEED,
  window:    OptionsWindow    = DEFAULT_WINDOW,
  zoom:      ?u32          = DEFAULT_ZOOM,

  const Self = @This ();

  const OptionsError = error
  {
    NoExecutableName,
  };

  fn parse (self: *Self) !void
  {
    var arena = std.heap.ArenaAllocator.init (std.heap.page_allocator);
    defer arena.deinit ();

    var allocator = arena.allocator ();

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
            or opts.items [index][1] == SHORT_SLIDE [1]
            or opts.items [index][1] == SHORT_VERSION [1]
              )
         )
      {
        try opts.append (opts.items [index][0..2]);
        new_opt = try std.fmt.allocPrint(allocator, "-{s}", .{ opts.items [index][2..] });
        new_opt_used = true;
        try opts.append (new_opt [0..]);
        _ = opts.orderedRemove (index);
        continue;
      }

      // Handle '-foo' the same as '-f oo' for short-form 1-arg options
      if (opts.items [index][0] == '-' and opts.items [index].len > 2
          and (opts.items [index][1] == SHORT_ANIMATION [1]
            or opts.items [index][1] == SHORT_COLOR [1]
            or opts.items [index][1] == SHORT_FPS [1]
            or opts.items [index][1] == SHORT_OUTPUT [1]
            or opts.items [index][1] == SHORT_PIXEL [1]
            or opts.items [index][1] == SHORT_SEED [1]
            or opts.items [index][1] == SHORT_WINDOW [1]
            or opts.items [index][1] == SHORT_ZOOM [1]
              )
         )
      {
        try opts.append (opts.items [index][0..2]);
        try opts.append (opts.items [index][2..]);
        _ = opts.orderedRemove (index);
        continue;
      }

      // TODO: Handle '--file=file1' the same as '--file file1' for long-form 1-arg options

      // help option
      if (std.mem.eql (u8, opts.items [index], SHORT_HELP) or std.mem.eql (u8, opts.items [index], LONG_HELP))
      {
        self.help = true;
      }

      // slide option
      if (std.mem.eql (u8, opts.items [index], SHORT_SLIDE) or std.mem.eql (u8, opts.items [index], LONG_SLIDE))
      {
        self.slide = true;
      }

      // version option
      if (std.mem.eql (u8, opts.items [index], SHORT_VERSION) or std.mem.eql (u8, opts.items [index], LONG_VERSION))
      {
        self.version = true;
      }

      index += 1;
    }
  }

  fn check (self: Self) void
  {
    _ = self;
  }

  fn show (self: Self) void
  {
    _ = self;
  }

  pub fn init () !Self
  {
    var self: Self = undefined;

    try self.parse ();
    self.check ();
    if (build.LOG_LEVEL > @intFromEnum (profile.TURBO)) self.show ();
    std.process.exit (0);

    return self;
  }
};
