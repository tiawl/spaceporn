const c = @import ("c");
const std = @import ("std");

const glfw = @import ("glfw");

pub const Window = struct
{
  handle: *c.GLFWwindow,

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

    resizable: glfw.Bool,
    client_api: glfw.Window.Hint.ClientAPI,

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

    pub const Limits = struct
    {
      pub fn set (min: glfw.Window.Size.Optional, max: glfw.Window.Size.Optional) !void
      {
        if (min.width != null and max.width != null)
          std.debug.assert (min.width.? <= max.width.?);
        if (min.height != null and max.height != null)
          std.debug.assert (min.height.? <= max.height.?);

        const window = try glfw.Context.get ();
        c.glfwSetWindowSizeLimits (window,
          if (min.width) |min_width| @as (c_int, @intCast (min_width)) else c.GLFW_DONT_CARE,
          if (min.height) |min_height| @as (c_int, @intCast (min_height)) else c.GLFW_DONT_CARE,
          if (max.width) |max_width| @as (c_int, @intCast (max_width)) else c.GLFW_DONT_CARE,
          if (max.height) |max_height| @as (c_int, @intCast (max_height)) else c.GLFW_DONT_CARE);
      }
    };
  };

  pub const Surface = struct
  {
    pub fn create (vk_instance: anytype, window: Window, vk_allocation_callbacks: anytype, vk_surface_khr: anytype) !void
    {
      const instance: c.VkInstance = @as (c.VkInstance, @ptrFromInt (@intFromEnum (vk_instance)));

      const result = c.glfwCreateWindowSurface (instance, window.handle,
        if (vk_allocation_callbacks == null) null else @as (*const c.VkAllocationCallbacks, @ptrCast (@alignCast (vk_allocation_callbacks))),
        @as (*c.VkSurfaceKHR, @ptrCast (@alignCast (vk_surface_khr))));

      if (result > 0)
      {
        std.debug.print ("{s} failed with {} status code\n", .{ @typeName (@This ()) ++ "." ++ @src ().fn_name, result, });
        return error.UnexpectedResult;
      }
    }
  };

  pub const UserPointer = struct
  {
    pub fn get (comptime T: type) !?*T
    {
      const window = try glfw.Context.get ();
      if (c.glfwGetWindowUserPointer (window)) |user_pointer|
        return @as (?*T, @ptrCast (@alignCast (user_pointer)));
      return null;
    }

    pub fn set (pointer: ?*anyopaque) !void
    {
      const window = try glfw.Context.get ();
      c.glfwSetWindowUserPointer (window, pointer);
    }
  };

  pub const Framebuffer = struct
  {
    pub const Size = struct
    {
      pub fn get () !glfw.Window.Size
      {
        const window = try glfw.Context.get ();
        var width: c_int = 0;
        var height: c_int = 0;
        c.glfwGetFramebufferSize (window, &width, &height);
        return .{
                  .width = @as (u32, @intCast (width)),
                  .height = @as (u32, @intCast (height)),
                };
      }

      pub const Callback = struct
      {
        pub fn set (comptime callback: ?fn (glfw.Window, u32, u32) void) !void
        {
          const window = try glfw.Context.get ();
          if (callback) |user_callback|
          {
            const Wrapper = struct
            {
              pub fn framebufferSizeCallbackWrapper (handle: ?*c.GLFWwindow, width: c_int, height: c_int) callconv(.C) void
              {
                @call (.always_inline, user_callback, .{ from (handle.?), @as (u32, @intCast (width)), @as (u32, @intCast (height)), });
              }
            };

            _ = c.glfwSetFramebufferSizeCallback (window, Wrapper.framebufferSizeCallbackWrapper);
          } else _ = c.glfwSetFramebufferSizeCallback (window, null);
        }
      };
    };
  };

  pub fn create (width: u32, height: u32, title: [*:0] const u8,
    monitor: ?glfw.Monitor, share: ?@This (), hints: [] const glfw.Window.Hint) !@This ()
  {
    for (hints) |hint| c.glfwWindowHint (hint.tag (), @intFromEnum (std.meta.activeTag (hint)));
    if (c.glfwCreateWindow (@as (c_int, @intCast (width)), @as (c_int, @intCast (height)),
      &title [0], if (monitor) |m| m.handle else null, if (share) |w| w.handle else null)) |handle|
        return from (handle);

    return error.WindowInitFailed;
  }

  pub fn destroy (self: @This ()) void
  {
    c.glfwDestroyWindow (self.handle);
  }

  pub fn from (handle: *anyopaque) @This ()
  {
    return .{ .handle = @as (*c.GLFWwindow, @ptrCast (@alignCast (handle))), };
  }

  pub fn shouldClose (self: @This ()) bool
  {
    return c.glfwWindowShouldClose (self.handle) == c.GLFW_TRUE;
  }
};
