const std = @import ("std");

const context_vk   = @import ("context_vk.zig").context_vk;
const context_glfw = @import ("context_glfw.zig").context_glfw;

const utils = @import ("utils.zig");
const debug = utils.debug;

pub const context = struct
{
  glfw: context_glfw,
  vk:   context_vk,

  const Self = @This ();

  pub fn init () !Self
  {
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
    debug ("Init OK", .{});
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
    debug ("Loop OK", .{});
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
    debug ("Clean Up OK", .{});
  }
};
