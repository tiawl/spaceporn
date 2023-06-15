const std = @import ("std");

const context_vk   = @import ("context_vk.zig").context_vk;
const context_glfw = @import ("context_glfw.zig").context_glfw;

const build = @import ("build_options");

const utils            = @import ("utils.zig");
const debug_spacedream = utils.debug_spacedream;
const log_file         = utils.log_file;
const profile          = utils.profile;
const severity         = utils.severity;

pub const context = struct
{
  glfw: context_glfw,
  vk:   context_vk,

  const Self = @This ();

  fn init_logfile () !void
  {
    if (build.LOG_LEVEL > @enumToInt(profile.TURBO))
    {
      const file = std.fs.cwd ().openFile (log_file, .{}) catch |open_err| blk:
      {
        if (open_err != std.fs.File.OpenError.FileNotFound)
        {
          try debug_spacedream ("failed to open log file", severity.ERROR, .{});
          return open_err;
        } else {
          const cfile = std.fs.cwd ().createFile (log_file, .{}) catch |create_err|
          {
            try debug_spacedream ("failed to create log file", severity.ERROR, .{});
            return create_err;
          };
          break :blk cfile;
        }
      };

      defer file.close ();
    }
  }

  pub fn init () !Self
  {
    init_logfile () catch |err|
    {
      try debug_spacedream ("failed to init log file", severity.ERROR, .{});
      return err;
    };

    var self: Self = undefined;

    self.glfw = context_glfw.init () catch |err|
    {
      try debug_spacedream ("failed to init GLFW", severity.ERROR, .{});
      return err;
    };

    self.vk = context_vk.init (&self.glfw.extensions, self.glfw.instance_proc_addr) catch |err|
    {
      try debug_spacedream ("failed to init Vulkan", severity.ERROR, .{});
      return err;
    };

    try debug_spacedream ("Init OK", severity.DEBUG, .{});
    return self;
  }

  pub fn loop (self: Self) !void
  {
    self.glfw.loop () catch |err|
    {
      try debug_spacedream ("failed to loop on GLFW context", severity.ERROR, .{});
      return err;
    };

    self.vk.loop () catch |err|
    {
      try debug_spacedream ("failed to loop on Vulkan context", severity.ERROR, .{});
      return err;
    };

    try debug_spacedream ("Loop OK", severity.DEBUG, .{});
  }

  pub fn cleanup (self: Self) !void
  {
    self.vk.cleanup () catch |err|
    {
      try debug_spacedream ("failed to cleanup Vulkan", severity.ERROR, .{});
      return err;
    };

    self.glfw.cleanup () catch |err|
    {
      try debug_spacedream ("failed to cleanup GLFW", severity.ERROR, .{});
      return err;
    };

    try debug_spacedream ("Cleanup OK", severity.DEBUG, .{});
  }
};
