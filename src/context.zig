const std = @import ("std");

const context_imgui = @import ("imgui/context.zig").context_imgui;
const context_glfw  = @import ("glfw/context.zig").context_glfw;
const context_vk    = @import ("vk/context.zig").context_vk;

const utils    = @import ("utils.zig");
const log_app  = utils.log_app;
const severity = utils.severity;

const opts = @import ("options.zig").options;

pub const context = struct
{
  imgui: context_imgui = undefined,
  glfw:  context_glfw  = undefined,
  vk:    context_vk    = undefined,

  const Self = @This ();

  pub fn init (allocator: std.mem.Allocator, options: opts) !Self
  {
    var self = Self {};

    self.imgui = context_imgui.init ();

    self.glfw = try context_glfw.init (&(self.imgui), options);

    self.vk = try context_vk.init_instance (&self.glfw.extensions, self.glfw.instance_proc_addr, allocator);

    var wrapper = self.vk.get_surface ();
    try self.glfw.init_surface (wrapper.instance, &wrapper.surface, wrapper.success);
    self.vk.set_surface (&wrapper.surface);

    const framebuffer = self.glfw.get_framebuffer_size ();
    try self.vk.init (self.imgui, .{ .width = framebuffer.width, .height = framebuffer.height, }, allocator);

    try log_app ("init OK", severity.DEBUG, .{});
    return self;
  }

  pub fn loop (self: *Self, options: *opts) !void
  {
    var arena = std.heap.ArenaAllocator.init (std.heap.page_allocator);
    var allocator = arena.allocator ();

    while (self.glfw.looping ())
    {
      try self.glfw.loop ();
      const framebuffer = self.glfw.get_framebuffer_size ();
      try self.vk.loop (&(self.imgui), .{ .resized = framebuffer.resized, .width = framebuffer.width, .height = framebuffer.height, }, &arena, &allocator, options);
    }
    try log_app ("loop OK", severity.DEBUG, .{});
  }

  pub fn cleanup (self: Self) !void
  {
    self.imgui.cleanup ();
    try self.vk.cleanup ();
    try self.glfw.cleanup ();
    try log_app ("cleanup OK", severity.DEBUG, .{});
  }
};
