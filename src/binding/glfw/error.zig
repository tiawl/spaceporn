const c = @import ("c");
const std = @import ("std");

const glfw = @This ();

pub const Error = struct
{
  pub const Code = error
  {
    NotInitialized,
    NoCurrentContext,
    InvalidEnum,
    InvalidValue,
    OutOfMemory,
    APIUnavailable,
    VersionUnavailable,
    PlatformError,
    FormatUnavailable,
    NoWindowContext,
    CursorUnavailable,
    FeatureUnavailable,
    FeatureUnimplemented,
    PlatformUnavailable,
  };

  fn convert (int: c_int) !void
  {
    return switch (int)
    {
      c.GLFW_NO_ERROR => {},
      c.GLFW_NOT_INITIALIZED => glfw.Error.Code.NotInitialized,
      c.GLFW_NO_CURRENT_CONTEXT => glfw.Error.Code.NoCurrentContext,
      c.GLFW_INVALID_ENUM => glfw.Error.Code.InvalidEnum,
      c.GLFW_INVALID_VALUE => glfw.Error.Code.InvalidValue,
      c.GLFW_OUT_OF_MEMORY => glfw.Error.Code.OutOfMemory,
      c.GLFW_API_UNAVAILABLE => glfw.Error.Code.APIUnavailable,
      c.GLFW_VERSION_UNAVAILABLE => glfw.Error.Code.VersionUnavailable,
      c.GLFW_PLATFORM_ERROR => glfw.Error.Code.PlatformError,
      c.GLFW_FORMAT_UNAVAILABLE => glfw.Error.Code.FormatUnavailable,
      c.GLFW_NO_WINDOW_CONTEXT => glfw.Error.Code.NoWindowContext,
      c.GLFW_CURSOR_UNAVAILABLE => glfw.Error.Code.CursorUnavailable,
      c.GLFW_FEATURE_UNAVAILABLE => glfw.Error.Code.FeatureUnavailable,
      c.GLFW_FEATURE_UNIMPLEMENTED => glfw.Error.Code.FeatureUnimplemented,
      c.GLFW_PLATFORM_UNAVAILABLE => glfw.Error.Code.PlatformUnavailable,
      else => unreachable,
    };
  }

  pub const String = struct
  {
    pub fn get () ?[:0] const u8
    {
      var desc: [*c] const u8 = null;
      const code = c.glfwGetError (&desc);
      if (code != c.GLFW_NO_ERROR)
        return std.mem.sliceTo (desc, 0);
      return null;
    }
  };

  pub const Callback = struct
  {
    pub fn set (comptime callback: ?fn (Code, [:0] const u8) void) void
    {
      if (callback) |user_callback|
      {
        const Wrapper = struct
        {
          pub fn errorCallbackWrapper (int: c_int, description: [*c] const u8) callconv (.C) void
          {
            convert (int) catch |err|
            {
              user_callback (err, std.mem.sliceTo (description, 0));
            };
          }
        };

        _ = c.glfwSetErrorCallback (Wrapper.errorCallbackWrapper);
        return;
      } else _ = c.glfwSetErrorCallback (null);
    }
  };
};
