const std   = @import ("std");
const build = @import ("build_options");

const utils    = @import ("../utils.zig");
const log_app  = utils.log_app;
const profile  = utils.profile;
const severity = utils.severity;

const init = if (build.LOG_LEVEL == @enumToInt (profile.TURBO)) @import ("init_turbo.zig") else @import ("init_debug.zig");
const init_vk = init.init_vk;
const vk      = init.vk;

pub const context_vk = struct
{
  initializer: init_vk,

  const Self = @This ();

  const ContextError = error
  {
    NoDevice,
    NoSuitableDevice,
  };

  fn find_queue_family (self: *Self, device: vk.PhysicalDevice, allocator: std.mem.Allocator) !bool
  {
    var queue_family_count: u32 = undefined;

    self.initializer.instance_dispatch.getPhysicalDeviceQueueFamilyProperties (device, &queue_family_count, null);

    var queue_families = try allocator.alloc (vk.QueueFamilyProperties, queue_family_count);
    defer allocator.free (queue_families);

    self.initializer.instance_dispatch.getPhysicalDeviceQueueFamilyProperties (device, &queue_family_count, queue_families.ptr);

    var graphics_family: ?u32 = null;

    for (queue_families, 0..) |properties, index|
    {
      const family = @intCast(u32, index);

      if (graphics_family == null and properties.queue_flags.graphics_bit)
      {
        graphics_family = family;
        break;
      }
    }

    return if (graphics_family) |_| true else false;
  }

  fn is_suitable (self: *Self, device: vk.PhysicalDevice, allocator: std.mem.Allocator) !bool
  {
    const device_prop = self.initializer.instance_dispatch.getPhysicalDeviceProperties (device);
    const device_feat = self.initializer.instance_dispatch.getPhysicalDeviceFeatures (device);

    // TODO: issue #52

    _ = device_prop;
    _ = device_feat;

    return try self.find_queue_family (device, allocator);
  }

  fn pick_physical_devices (self: *Self) !void
  {
    var device_count: u32 = undefined;

    _ = try self.initializer.instance_dispatch.enumeratePhysicalDevices (self.initializer.instance, &device_count, null);

    if (device_count == 0)
    {
      return ContextError.NoDevice;
    }

    var gpa = std.heap.GeneralPurposeAllocator (.{}){};
    defer _ = gpa.deinit ();
    const allocator = gpa.allocator ();
    var devices = try allocator.alloc (vk.PhysicalDevice, device_count);
    defer allocator.free (devices);

    _ = try self.initializer.instance_dispatch.enumeratePhysicalDevices (self.initializer.instance, &device_count, devices.ptr);

    var physical_device: ?vk.PhysicalDevice = null;

    for (devices) |device|
    {
      if (try self.is_suitable (device, allocator))
      {
        physical_device = device;
        break;
      }
    }

    if (physical_device == null)
    {
      return ContextError.NoSuitableDevice;
    }
  }

  pub fn init (extensions: *[][*:0] const u8,
    instance_proc_addr: *const fn (?*anyopaque, [*:0] const u8) callconv (.C) ?*const fn () callconv (.C) void) !Self
  {
    var self: Self = undefined;
    self.initializer = try init_vk.init_instance (extensions, instance_proc_addr);

    try self.pick_physical_devices ();

    try log_app ("Init Vulkan OK", severity.DEBUG, .{});
    return self;
  }

  pub fn loop (self: Self) !void
  {
    _ = self;
    try log_app ("Loop Vulkan OK", severity.DEBUG, .{});
  }

  pub fn cleanup (self: Self) !void
  {
    try self.initializer.cleanup ();
    try log_app ("Cleanup Vulkan OK", severity.DEBUG, .{});
  }
};
