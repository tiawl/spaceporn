const std = @import("std");
const vk  = @import("vulkan");

const build = @import("build_options");

const ContextVulkanError = error
{
  InitError,
  LoopError,
  CleanupError,
};

pub fn init () ContextVulkanError!void
{
  if (build.DEV) std.log.debug("Init Vulkan OK", .{});
}

pub fn loop () ContextVulkanError!void
{
  if (build.DEV) std.log.debug("Loop Vulkan OK", .{});
}

pub fn cleanup () ContextVulkanError!void
{
  if (build.DEV) std.log.debug("Clean Up Vulkan OK", .{});
}
