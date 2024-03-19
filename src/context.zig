const std = @import ("std");

const Logger = @import ("logger").Logger;

const ImguiContext = @import ("imgui/context.zig").Context;
const GlfwContext = @import ("glfw/context.zig").Context;
const VkContext = @import ("vk/context.zig").Context;

const Options = @import ("options.zig").Options;

pub const Context = struct
{
  logger: *const Logger = undefined,
  imgui:  ImguiContext = undefined,
  glfw:   GlfwContext = undefined,
  vk:     VkContext = undefined,

  pub fn init (logger: *const Logger, options: *const Options) !@This ()
  {
    var self: @This () = .{ .logger = logger, };

    self.imgui = ImguiContext.init (self.logger);
    self.glfw = try GlfwContext.init (&(self.imgui), self.logger, options);
    self.vk = try VkContext.init_instance (self.logger, &self.glfw.extensions);

    var wrapper = self.vk.get_surface ();
    try self.glfw.init_surface (wrapper.instance, &wrapper.surface);
    self.vk.set_surface (&wrapper.surface);

    const framebuffer = try self.glfw.get_framebuffer_size ();
    try self.vk.init (self.imgui, .{ .width = framebuffer.width, .height = framebuffer.height, });

    try self.logger.app ("init OK", .DEBUG, .{});
    return self;
  }

  pub fn loop (self: *@This (), options: *const Options) !void
  {
    var arena = std.heap.ArenaAllocator.init (std.heap.page_allocator);
    var allocator = arena.allocator ();

    while (self.glfw.looping ())
    {
      try self.glfw.loop ();
      const framebuffer = self.glfw.get_framebuffer_size ();
      try self.vk.loop (&(self.imgui), .{ .resized = framebuffer.resized, .width = framebuffer.width, .height = framebuffer.height, }, &arena, &allocator, options);
    }
    try self.logger.app ("loop OK", .DEBUG, .{});
  }

  pub fn cleanup (self: @This ()) !void
  {
    self.imgui.cleanup ();
    try self.vk.cleanup ();
    try self.glfw.cleanup ();
    try self.logger.app ("cleanup OK", .DEBUG, .{});
  }
};
