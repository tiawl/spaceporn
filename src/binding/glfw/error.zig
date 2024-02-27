const c = @import ("c");
const std = @import ("std");

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
      c.GLFW_NOT_INITIALIZED => Code.NotInitialized,
      c.GLFW_NO_CURRENT_CONTEXT => Code.NoCurrentContext,
      c.GLFW_INVALID_ENUM => Code.InvalidEnum,
      c.GLFW_INVALID_VALUE => Code.InvalidValue,
      c.GLFW_OUT_OF_MEMORY => Code.OutOfMemory,
      c.GLFW_API_UNAVAILABLE => Code.APIUnavailable,
      c.GLFW_VERSION_UNAVAILABLE => Code.VersionUnavailable,
      c.GLFW_PLATFORM_ERROR => Code.PlatformError,
      c.GLFW_FORMAT_UNAVAILABLE => Code.FormatUnavailable,
      c.GLFW_NO_WINDOW_CONTEXT => Code.NoWindowContext,
      c.GLFW_CURSOR_UNAVAILABLE => Code.CursorUnavailable,
      c.GLFW_FEATURE_UNAVAILABLE => Code.FeatureUnavailable,
      c.GLFW_FEATURE_UNIMPLEMENTED => Code.FeatureUnimplemented,
      c.GLFW_PLATFORM_UNAVAILABLE => Code.PlatformUnavailable,
      else => unreachable,
    };
  }

  pub fn getString () ?[:0] const u8
  {
    var desc: [*c] const u8 = null;
    const code = c.glfwGetError (&desc);
    if (code != c.GLFW_NO_ERROR)
      return std.mem.sliceTo (desc, 0);
    return null;
  }

  pub fn mustGetString () [:0] const u8
  {
    return getString () orelse std.debug.panic ("glfw.Error.{s} () called but no error is present", .{ @src ().fn_name, });
  }

  pub fn setCallback (comptime callback: ?fn (Code, [:0] const u8) void) void
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
