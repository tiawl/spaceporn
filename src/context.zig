const std   = @import ("std");
const vk    = @import ("context_vulkan.zig");
const glfw  = @import ("context_glfw.zig");

const context_glfw_t = @import ("context_glfw.zig").context_glfw_t;
const context_vk_t   = @import ("context_vk.zig").context_vk_t;

const utils = @import ("utils.zig");
const Error = utils.SpacedreamError;
const debug = utils.debug;

pub const context_t = struct
{
  glfw: ?context_glfw_t = null,
  vk:   ?context_vk_t   = null,
};

pub fn init (context: *context_t) Error!void
{
  context.glfw = context_glfw_t{};
  glfw.init (&(context.glfw.?)) catch
  {
    std.log.err ("Init Glfw error", .{});
    return Error.InitError;
  };
  context.vk = context_vk_t{ .extensions = context.glfw.extensions, };
  vk.init (&(context.vk.?)) catch
  {
    std.log.err ("Init Vulkan error", .{});
    return Error.InitError;
  };
  debug ("Init OK", .{});
}

pub fn loop (context: *context_t) Error!void
{
  glfw.loop (&(context.glfw.?)) catch
  {
    std.log.err ("Loop Glfw error", .{});
    return Error.LoopError;
  };
  vk.loop () catch
  {
    std.log.err ("Loop Vulkan error", .{});
    return Error.LoopError;
  };
  debug ("Loop OK", .{});
}

pub fn cleanup (context: *context_t) Error!void
{
  glfw.cleanup (&(context.glfw.?)) catch
  {
    std.log.err ("Clean Up Glfw error", .{});
    return Error.CleanupError;
  };
  vk.cleanup (&(context.vk.?)) catch
  {
    std.log.err ("Clean Up Vulkan error", .{});
    return Error.CleanupError;
  };
  debug ("Clean Up OK", .{});
}
