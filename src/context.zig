const std = @import ("std");

const context_vk   = @import ("context_vk.zig").context_vk;
const context_glfw = @import ("context_glfw.zig").context_glfw;

const build = @import ("build_options");

const utils            = @import ("utils.zig");
const debug_spacedream = utils.debug_spacedream;
const log_file         = utils.log_file;

pub const context = struct
{
  glfw: context_glfw,
  vk:   context_vk,

  const Self = @This ();

  fn init_logfile () !void
  {
    const file = std.fs.openFileAbsolute (build.LOGDIR ++ "/" ++ log_file, .{}) catch |open_err| blk:
    {
      if (open_err != std.fs.File.OpenError.FileNotFound)
      {
        std.log.err ("Open File Absolute Log File error", .{});
        return open_err;
      } else {
        const cfile = std.fs.createFileAbsolute (build.LOGDIR ++ "/" ++ log_file, .{}) catch |create_err|
        {
          std.log.err ("Create File Absolute Log File error", .{});
          return create_err;
        };
        break :blk cfile;
      }
    };

    defer file.close ();
  }

  pub fn init () !Self
  {
    init_logfile () catch |err|
    {
      std.log.err ("Init Log File error", .{});
      return err;
    };

    var self: Self = undefined;

    self.glfw = context_glfw.init () catch |err|
    {
      std.log.err ("Init Glfw error", .{});
      return err;
    };

    self.vk = context_vk.init (&self.glfw.extensions, self.glfw.instance_proc_addr) catch |err|
    {
      std.log.err ("Init Vulkan error", .{});
      return err;
    };

    try debug_spacedream ("Init OK", .{});
    return self;
  }

  pub fn loop (self: Self) !void
  {
    self.glfw.loop () catch |err|
    {
      std.log.err ("Loop Glfw error", .{});
      return err;
    };

    self.vk.loop () catch |err|
    {
      std.log.err ("Loop Vulkan error", .{});
      return err;
    };

    try debug_spacedream ("Loop OK", .{});
  }

  pub fn cleanup (self: Self) !void
  {
    self.vk.cleanup () catch |err|
    {
      std.log.err ("Clean Up Vulkan error", .{});
      return err;
    };

    self.glfw.cleanup () catch |err|
    {
      std.log.err ("Clean Up Glfw error", .{});
      return err;
    };

    try debug_spacedream ("Clean Up OK", .{});
  }
};
