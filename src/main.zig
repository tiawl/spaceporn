const std  = @import("std");
const vk   = @import("vulkan");
const glfw = @import("glfw");

const print = std.debug.print;

fn init () error{InitFailure}!void
{
  print("Init OK\n", .{});
}

fn loop () !void
{
  print("Loop OK\n", .{});
}

fn cleanup () !void
{
  print("Clean Up OK\n", .{});
}

pub fn main () u8
{
  init () catch
  {
    print("Init failure\n", .{});
    return 1;
  };
  loop () catch
  {
    print("Loop failure\n", .{});
    return 1;
  };
  cleanup () catch
  {
    print("Cleanup failure\n", .{});
    return 1;
  };

  return 0;
}
