const std   = @import ("std");
const build = @import ("build_options");

const utils    = @import ("../utils.zig");
const log_app  = utils.log_app;
const profile  = utils.profile;
const severity = utils.severity;

const dispatch       = @import ("dispatch.zig");
const DeviceDispatch = dispatch.DeviceDispatch;

const init            = if (build.LOG_LEVEL == @enumToInt (profile.TURBO)) @import ("init_turbo.zig") else @import ("init_debug.zig");
const init_vk         = init.init_vk;
const vk              = init.vk;
const required_layers = init_vk.required_layers;

pub const context_vk = struct
{
  initializer:        init_vk,
  device_dispatch:    DeviceDispatch,
  physical_device:    ?vk.PhysicalDevice = null,
  logical_device:     vk.Device,
  queue_create_info:  [1] vk.DeviceQueueCreateInfo,
  device_create_info: vk.DeviceCreateInfo,

  const Self = @This ();

  const ContextError = error
  {
    NoDevice,
    NoSuitableDevice,
  };

  fn find_queue_family (self: *Self, device: vk.PhysicalDevice, allocator: std.mem.Allocator) !?u32
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

    return if (graphics_family) |value| value else null;
  }

  fn is_suitable (self: *Self, device: vk.PhysicalDevice, allocator: std.mem.Allocator) !bool
  {
    const device_prop = self.initializer.instance_dispatch.getPhysicalDeviceProperties (device);
    const device_feat = self.initializer.instance_dispatch.getPhysicalDeviceFeatures (device);

    // TODO: issue #52

    _ = device_prop;
    _ = device_feat;

    return if (try self.find_queue_family (device, allocator)) |_| true else false;
  }

  fn pick_physical_device (self: *Self, allocator: std.mem.Allocator) !void
  {
    var device_count: u32 = undefined;

    _ = try self.initializer.instance_dispatch.enumeratePhysicalDevices (self.initializer.instance, &device_count, null);

    if (device_count == 0)
    {
      return ContextError.NoDevice;
    }

    var devices = try allocator.alloc (vk.PhysicalDevice, device_count);
    defer allocator.free (devices);

    _ = try self.initializer.instance_dispatch.enumeratePhysicalDevices (self.initializer.instance, &device_count, devices.ptr);

    for (devices) |device|
    {
      if (try self.is_suitable (device, allocator))
      {
        self.physical_device = device;
        break;
      }
    }

    if (self.physical_device == null)
    {
      return ContextError.NoSuitableDevice;
    }
  }

  fn init_logical_device (self: *Self, allocator: std.mem.Allocator) !void
  {
    const indices = if (try self.find_queue_family (self.physical_device.?, allocator)) |value| value else unreachable;
    const priority = [_] f32 {1};
    self.queue_create_info = [_] vk.DeviceQueueCreateInfo
                             {
                               .{
                                 .flags              = .{},
                                 .queue_family_index = indices,
                                 .queue_count        = 1,
                                 .p_queue_priorities = &priority,
                               },
                             };

    const device_feat = vk.PhysicalDeviceFeatures {};

    self.device_create_info = vk.DeviceCreateInfo
                              {
                                .flags                   = .{},
                                .p_queue_create_infos    = &(self.queue_create_info),
                                .queue_create_info_count = 1,
                                .enabled_layer_count     = required_layers.len,
                                .pp_enabled_layer_names  = if (required_layers.len > 0) @ptrCast ([*] const [*:0] const u8, required_layers[0..required_layers.len]) else undefined,
                                .p_enabled_features      = &device_feat,
                              };

    self.logical_device = try self.initializer.instance_dispatch.createDevice (self.physical_device.?, &(self.device_create_info), null);

    self.device_dispatch = try DeviceDispatch.load (self.logical_device, self.initializer.instance_dispatch.dispatch.vkGetDeviceProcAddr);
    errdefer self.device_dispatch.destroyDevice (self.logical_device, null);

    _ = self.device_dispatch.getDeviceQueue (self.logical_device, indices, 0);
  }

  pub fn init (extensions: *[][*:0] const u8,
    instance_proc_addr: *const fn (?*anyopaque, [*:0] const u8) callconv (.C) ?*const fn () callconv (.C) void) !Self
  {
    var self: Self = undefined;
    self.initializer = try init_vk.init_instance (extensions, instance_proc_addr);

    var gpa = std.heap.GeneralPurposeAllocator (.{}){};
    defer _ = gpa.deinit ();
    const allocator = gpa.allocator ();

    try self.pick_physical_device (allocator);
    try self.init_logical_device (allocator);

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
    self.device_dispatch.destroyDevice (self.logical_device, null);
    try self.initializer.cleanup ();
    try log_app ("Cleanup Vulkan OK", severity.DEBUG, .{});
  }
};
