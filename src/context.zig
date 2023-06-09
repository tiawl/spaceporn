const std   = @import("std");
const vk    = @import("context_vulkan.zig");
const glfw  = @import("context_glfw.zig");

const utils = @import("utils.zig");
const Error = utils.SpacedreamError;
const debug = utils.debug;

pub fn init () Error!void
{
  glfw.init () catch
  {
    std.log.err("Init Glfw error", .{});
    return Error.InitError;
  };
  vk.init () catch
  {
    std.log.err("Init Vulkan error", .{});
    return Error.InitError;
  };
  debug("Init OK", .{});
}

pub fn loop () Error!void
{
  glfw.loop () catch
  {
    std.log.err("Loop Glfw error", .{});
    return Error.LoopError;
  };
  vk.loop () catch
  {
    std.log.err("Loop Vulkan error", .{});
    return Error.LoopError;
  };
  debug("Loop OK", .{});
}

pub fn cleanup () Error!void
{
  glfw.cleanup () catch
  {
    std.log.err("Clean Up Glfw error", .{});
    return Error.CleanupError;
  };
  vk.cleanup () catch
  {
    std.log.err("Clean Up Vulkan error", .{});
    return Error.CleanupError;
  };
  debug("Clean Up OK", .{});
}
