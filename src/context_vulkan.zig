const vk  = @import("vulkan");

const utils = @import("utils.zig");
const Error = utils.SpacedreamError;
const debug = utils.debug;

pub fn init () Error!void
{
  debug("Init Vulkan OK", .{});
}

pub fn loop () Error!void
{
  debug("Loop Vulkan OK", .{});
}

pub fn cleanup () Error!void
{
  debug("Clean Up Vulkan OK", .{});
}
