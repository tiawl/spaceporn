const std   = @import("std");
const vk    = @import("context_vulkan.zig");
const glfw  = @import("context_glfw.zig");

const build = @import("build_options");

const ContextError = error
{
  InitError,
  LoopError,
  CleanupError,
};

pub fn init () ContextError!void
{
  glfw.init () catch
  {
    std.log.err("Init Glfw error", .{});
    return ContextError.InitError;
  };
  vk.init () catch
  {
    std.log.err("Init Vulkan error", .{});
    return ContextError.InitError;
  };
  if (build.DEV) std.log.debug("Init OK", .{});
}

pub fn loop () ContextError!void
{
  glfw.loop () catch
  {
    std.log.err("Loop Glfw error", .{});
    return ContextError.LoopError;
  };
  vk.loop () catch
  {
    std.log.err("Loop Vulkan error", .{});
    return ContextError.LoopError;
  };
  if (build.DEV) std.log.debug("Loop OK", .{});
}

pub fn cleanup () ContextError!void
{
  glfw.cleanup () catch
  {
    std.log.err("Clean Up Glfw error", .{});
    return ContextError.CleanupError;
  };
  vk.cleanup () catch
  {
    std.log.err("Clean Up Vulkan error", .{});
    return ContextError.CleanupError;
  };
  if (build.DEV) std.log.debug("Clean Up OK", .{});
}
