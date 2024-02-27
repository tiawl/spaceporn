const c = @import ("c");
const std = @import ("std");

const main = @import ("main.zig");
const Bool = main.Bool;
const Monitor = main.Monitor;

pub const Window = struct
{
  handle: *c.GLFWwindow,

  pub fn from (handle: *anyopaque) @This ()
  {
    return .{ .handle = @as (*c.GLFWwindow, @ptrCast (@alignCast (handle))), };
  }

  const Tag = enum
  {
    resizable,
    client_api,
  };

  pub const Hint = union (Tag)
  {
    pub const ClientAPI = enum (c_int)
    {
      no_api = c.GLFW_NO_API,
    };

    resizable: Bool,
    client_api: ClientAPI,

    fn tag (self: @This ()) c_int
    {
      return switch (self)
      {
        .resizable  => c.GLFW_RESIZABLE,
        .client_api => c.GLFW_CLIENT_API,
      };
    }
  };

  pub const Size = struct
  {
    width: u32,
    height: u32,

    pub const Optional = struct
    {
      width: ?u32,
      height: ?u32,
    };
  };

  pub fn create (width: u32, height: u32, title: [*:0] const u8,
    monitor: ?Monitor, share: ?@This (), hints: [] const Hint) ?@This ()
  {
    for (hints) |hint| c.glfwWindowHint (hint.tag (), @intFromEnum (std.meta.activeTag (hint)));
    if (c.glfwCreateWindow (@as (c_int, @intCast (width)), @as (c_int, @intCast (height)),
      &title [0], if (monitor) |m| m.handle else null, if (share) |w| w.handle else null)) |handle|
        return from (handle);

    return null;
  }

  pub fn destroy (self: @This ()) void
  {
    c.glfwDestroyWindow (self.handle);
  }

  pub fn getFramebufferSize (self: @This ()) Size
  {
    var width: c_int = 0;
    var height: c_int = 0;
    c.glfwGetFramebufferSize (self.handle, &width, &height);
    return .{
              .width = @as (u32, @intCast (width)),
              .height = @as (u32, @intCast (height)),
            };
  }

  pub fn getUserPointer (self: @This (), comptime T: type) ?*T
  {
    if (c.glfwGetWindowUserPointer (self.handle)) |user_pointer|
      return @as (?*T, @ptrCast (@alignCast (user_pointer)));
    return null;
  }

  pub fn setFramebufferSizeCallback (self: @This (), comptime callback: ?fn (@This (), u32, u32) void) void
  {
    if (callback) |user_callback|
    {
      const Wrapper = struct
      {
        pub fn framebufferSizeCallbackWrapper (handle: ?*c.GLFWwindow, width: c_int, height: c_int) callconv(.C) void
        {
          @call (.always_inline, user_callback, .{ from (handle.?), @as (u32, @intCast (width)), @as (u32, @intCast (height)), });
        }
      };

      _ = c.glfwSetFramebufferSizeCallback (self.handle, Wrapper.framebufferSizeCallbackWrapper);
    } else _ = c.glfwSetFramebufferSizeCallback (self.handle, null);
  }

  pub fn setSizeLimits (self: @This (), min: Size.Optional, max: Size.Optional) void
  {
    if (min.width != null and max.width != null)
      std.debug.assert (min.width.? <= max.width.?);
    if (min.height != null and max.height != null)
      std.debug.assert (min.height.? <= max.height.?);

    c.glfwSetWindowSizeLimits (self.handle,
      if (min.width) |min_width| @as (c_int, @intCast (min_width)) else c.GLFW_DONT_CARE,
      if (min.height) |min_height| @as (c_int, @intCast (min_height)) else c.GLFW_DONT_CARE,
      if (max.width) |max_width| @as (c_int, @intCast (max_width)) else c.GLFW_DONT_CARE,
      if (max.height) |max_height| @as (c_int, @intCast (max_height)) else c.GLFW_DONT_CARE);
  }

  pub fn setUserPointer (self: @This (), pointer: ?*anyopaque) void
  {
    c.glfwSetWindowUserPointer (self.handle, pointer);
  }
};
