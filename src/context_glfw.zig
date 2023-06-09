const glfw  = @import("glfw");

const utils = @import("utils.zig");
const Error = utils.SpacedreamError;
const debug = utils.debug;

pub fn init () Error!void
{
  debug("Init Glfw OK", .{});
}

pub fn loop () Error!void
{
  debug("Loop Glfw OK", .{});
}

pub fn cleanup () Error!void
{
  debug("Clean Up Glfw OK", .{});
}
