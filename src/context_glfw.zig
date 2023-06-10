const std   = @import("std");
const glfw  = @import ("glfw");

const utils = @import ("utils.zig");
const Error = utils.SpacedreamError;
const debug = utils.debug;
const exe   = utils.exe;

pub const context_glfw_t = struct
{
  window: ?glfw.Window = null,
};

fn callback (code: glfw.ErrorCode, description: [:0]const u8) void
{
  std.log.err ("glfw: {}: {s}", .{ code, description });
}

pub fn init (context: *context_glfw_t) Error!void
{
  glfw.setErrorCallback (callback);
  if (!glfw.init (.{}))
  {
    std.log.err ("failed to initialize GLFW: {?s}", .{ glfw.getErrorString () });
    std.process.exit (1);
  }
  errdefer glfw.terminate ();

  context.window = glfw.Window.create (800, 600, exe, null, null, .{
    .client_api = .no_api,
  }) orelse {
    std.log.err ("failed to initialize GLFW window: {?s}", .{ glfw.getErrorString () });
    std.process.exit (1);
  };
  errdefer context.window.?.destroy ();

  debug ("Init Glfw OK", .{});
}

pub fn loop () Error!void
{
  debug ("Loop Glfw OK", .{});
}

pub fn cleanup (context: *context_glfw_t) Error!void
{
  context.window.?.destroy ();
  glfw.terminate ();
  debug ("Clean Up Glfw OK", .{});
}
