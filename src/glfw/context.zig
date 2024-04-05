const std  = @import ("std");
const glfw = @import ("glfw");

const ImguiContext = @import ("../imgui/context.zig").Context;

const Logger = @import ("logger").Logger;

const Options = @import ("../options.zig").Options;

pub const Context = struct
{
  window:              glfw.Window = undefined,
  extensions:          [][*:0] const u8 = undefined,
  framebuffer_resized: bool = undefined,
  logger:              *const Logger = undefined,

  fn error_callback (code: glfw.Error.Code, description: [:0] const u8) void
  {
    var self = glfw.Window.UserPointer.get (Context) catch std.debug.panic ("glfw.Window.UserPointer failed", .{});
    self.?.logger.app (.ERROR, "GLFW: {}: {s}", .{ code, description, }) catch std.process.exit (1);
  }

  fn framebuffer_resize_callback (_: glfw.Window, _: u32, _: u32) void
  {
    var self = glfw.Window.UserPointer.get (Context) catch std.debug.panic ("glfw.Window.UserPointer failed", .{});
    self.?.framebuffer_resized = true;
  }

  const MIN_WINDOW_WIDTH  = 800;
  const MIN_WINDOW_HEIGHT = 600;

  pub fn init (imgui: *ImguiContext, logger: *const Logger, options: *const Options) !@This ()
  {
    var self: @This () = .{ .logger = logger, };

    glfw.Error.Callback.set (error_callback);
    if (!glfw.init ())
    {
      try self.logger.app (.ERROR, "failed to initialize GLFW: {?s}", .{ glfw.Error.String.get (), });
      return error.ContextInitFailed;
    }
    errdefer glfw.terminate ();

    if (!glfw.vk.supported ()) std.debug.panic ("Vulkan not supported", .{});

    const hints = [_] glfw.Window.Hint
                  {
                    .{ .client_api = .no_api, },
                    .{ .resizable = .@"false", },
                  };

    self.window = glfw.Window.create (options.window.width.?, options.window.height.?, Logger.build.binary.name, null, null, &hints) catch |err|
    {
      try self.logger.app (.ERROR, "failed to initialize GLFW window: {?s}", .{ glfw.Error.String.get () });
      return err;
    };
    errdefer self.window.destroy ();
    glfw.Context.make (&self.window);

    const min = glfw.Window.Size.Optional
                {
                  .width  = MIN_WINDOW_WIDTH,
                  .height = MIN_WINDOW_HEIGHT,
                };

    const max = glfw.Window.Size.Optional
                {
                  .width  = null,
                  .height = null,
                };

    try glfw.Window.Size.Limits.set (min, max);

    self.framebuffer_resized = true;
    try glfw.Window.UserPointer.set (&self);
    try glfw.Window.Framebuffer.Size.Callback.set (framebuffer_resize_callback);

    self.extensions = glfw.vk.Instance.RequiredExtensions.get () orelse
    {
      try self.logger.app (.ERROR, "failed to get required vulkan instance extensions: error={s}", .{ glfw.Error.String.get () orelse std.debug.panic ("no Glfw error", .{}), });
      return error.RequiredInstanceExtensionsFailed;
    };

    // TODO: remove this:
    try imgui.init_glfw ();

    try self.logger.app (.DEBUG, "init GLFW OK", .{});

    return self;
  }

  pub fn init_surface (self: @This (), instance: anytype, surface: anytype) !void
  {
    try glfw.Window.Surface.create (instance, self.window, null, surface);
    try self.logger.app (.DEBUG, "init GLFW surface OK", .{});
  }

  pub fn get_framebuffer_size (self: *@This ()) !struct { resized: bool, width: u32, height: u32, }
  {
    const resized = self.framebuffer_resized;

    if (resized) self.framebuffer_resized = false;

    var size = try glfw.Window.Framebuffer.Size.get ();

    while (size.width == 0 or size.height == 0)
    {
      glfw.Events.wait ();
      size = try glfw.Window.Framebuffer.Size.get ();
    }

    return .{
              .resized = resized,
              .width   = size.width,
              .height  = size.height,
            };
  }

  pub fn get_window (self: @This ()) glfw.Window
  {
    return self.window;
  }

  pub fn looping (self: @This ()) bool
  {
    return !self.window.shouldClose ();
  }

  pub fn loop (self: @This ()) !void
  {
    glfw.Events.poll ();
    try self.logger.app (.DEBUG, "loop GLFW OK", .{});
  }

  pub fn cleanup (self: @This ()) !void
  {
    self.window.destroy ();
    glfw.terminate ();
    try self.logger.app (.DEBUG, "cleanup GLFW OK", .{});
  }
};
