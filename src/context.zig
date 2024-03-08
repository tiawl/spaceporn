const std = @import ("std");

const ImguiContext = @import ("imgui/context.zig").Context;
const GlfwContext  = @import ("glfw/context.zig").Context;
const VkContext    = @import ("vk/context.zig").Context;

const log = @import ("log.zig");

const opts = @import ("options.zig").options;

pub const Context = struct
{
  imgui: ImguiContext = undefined,
  glfw:  GlfwContext  = undefined,
  vk:    VkContext    = undefined,

  pub fn init (allocator: std.mem.Allocator, options: opts) !@This ()
  {
    var self: @This () = .{};

    self.imgui = ImguiContext.init ();

    self.glfw = try GlfwContext.init (&(self.imgui), options);

    self.vk = try VkContext.init_instance (&self.glfw.extensions, allocator);

    var wrapper = self.vk.get_surface ();
    try self.glfw.init_surface (wrapper.instance, &wrapper.surface, wrapper.success);
    self.vk.set_surface (&wrapper.surface);

    const framebuffer = self.glfw.get_framebuffer_size ();
    try self.vk.init (self.imgui, .{ .width = framebuffer.width, .height = framebuffer.height, }, allocator);

    try log.app ("init OK", .DEBUG, .{});
    return self;
  }

  pub fn loop (self: *@This (), options: *opts) !void
  {
    var arena = std.heap.ArenaAllocator.init (std.heap.page_allocator);
    var allocator = arena.allocator ();

    while (self.glfw.looping ())
    {
      try self.glfw.loop ();
      const framebuffer = self.glfw.get_framebuffer_size ();
      try self.vk.loop (&(self.imgui), .{ .resized = framebuffer.resized, .width = framebuffer.width, .height = framebuffer.height, }, &arena, &allocator, options);
    }
    try log.app ("loop OK", .DEBUG, .{});
  }

  pub fn cleanup (self: @This ()) !void
  {
    self.imgui.cleanup ();
    try self.vk.cleanup ();
    try self.glfw.cleanup ();
    try log.app ("cleanup OK", .DEBUG, .{});
  }
};
