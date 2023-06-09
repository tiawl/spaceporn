const std   = @import("std");
const glfw  = @import("glfw");

const build = @import("build_options");

const ContextGlfwError = error
{
  InitError,
  LoopError,
  CleanupError,
};

pub fn init () ContextGlfwError!void
{
  if (build.DEV) std.log.debug("Init Glfw OK", .{});
}

pub fn loop () ContextGlfwError!void
{
  if (build.DEV) std.log.debug("Loop Glfw OK", .{});
}

pub fn cleanup () ContextGlfwError!void
{
  if (build.DEV) std.log.debug("Clean Up Glfw OK", .{});
}
