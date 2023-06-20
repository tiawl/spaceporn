const std   = @import ("std");
const build = @import ("build_options");

const utils    = @import ("../utils.zig");
const log_app  = utils.log_app;
const profile  = utils.profile;
const severity = utils.severity;

const dispatch         = @import ("dispatch.zig");
const InstanceDispatch = dispatch.InstanceDispatch;
const DeviceDispatch   = dispatch.DeviceDispatch;

const init            = if (build.LOG_LEVEL == @enumToInt (profile.TURBO)) @import ("init_turbo.zig") else @import ("init_debug.zig");
const init_vk         = init.init_vk;
const vk              = init.vk;
const required_layers = init_vk.required_layers;

pub const context_vk = struct
{
  initializer:        init_vk,
  surface:            vk.SurfaceKHR      = undefined,
  device_dispatch:    DeviceDispatch,
  physical_device:    ?vk.PhysicalDevice = null,
  candidate:          struct { graphics_family: u32, present_family: u32, },
  logical_device:     vk.Device,
  graphics_queue:     vk.Queue,
  present_queue:      vk.Queue,

  const Self = @This ();

  const ContextError = error
  {
    NoDevice,
    NoSuitableDevice,
  };

  fn find_queue_families (self: *Self, device: vk.PhysicalDevice, allocator: std.mem.Allocator) !?struct { graphics_family: u32, present_family: u32, }
  {
    var queue_family_count: u32 = undefined;

    self.initializer.instance_dispatch.getPhysicalDeviceQueueFamilyProperties (device, &queue_family_count, null);

    var queue_families = try allocator.alloc (vk.QueueFamilyProperties, queue_family_count);
    defer allocator.free (queue_families);

    self.initializer.instance_dispatch.getPhysicalDeviceQueueFamilyProperties (device, &queue_family_count, queue_families.ptr);

    var present_family: ?u32 = null;
    var graphics_family: ?u32 = null;

    for (queue_families, 0..) |properties, index|
    {
      const family = @intCast(u32, index);

      if (graphics_family == null and properties.queue_flags.graphics_bit)
      {
        graphics_family = family;
      }

      if (present_family == null and try self.initializer.instance_dispatch.getPhysicalDeviceSurfaceSupportKHR (device, family, self.surface) == vk.TRUE)
      {
        present_family = family;
      }
    }

    if (graphics_family != null and present_family != null)
    {
      try log_app ("Find Queue Families Vulkan OK", severity.DEBUG, .{});
      return .{
                .graphics_family = graphics_family.?,
                .present_family = present_family.?,
              };
    }

    try log_app ("Find Queue Families Vulkan failed", severity.ERROR, .{});
    return null;
  }

  fn is_suitable (self: *Self, device: vk.PhysicalDevice, allocator: std.mem.Allocator) !?struct { graphics_family: u32, present_family: u32, }
  {
    const device_prop = self.initializer.instance_dispatch.getPhysicalDeviceProperties (device);
    const device_feat = self.initializer.instance_dispatch.getPhysicalDeviceFeatures (device);

    // TODO: issue #52: prefer a device that support drawing and presentation in the same queue for better perf

    _ = device_prop;
    _ = device_feat;

    if (try self.find_queue_families (device, allocator)) |candidate|
    {
      try log_app ("Device Is Suitable Vulkan OK", severity.DEBUG, .{});
      return .{
                .graphics_family = candidate.graphics_family,
                .present_family = candidate.present_family,
              };
    }

    try log_app ("Device Is Suitable Vulkan failed", severity.ERROR, .{});
    return null;
  }

  fn pick_physical_device (self: *Self) !void
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

    for (devices) |device|
    {
      if (try self.is_suitable (device, allocator)) |candidate|
      {
        self.physical_device = device;
        self.candidate = .{
                            .graphics_family = candidate.graphics_family,
                            .present_family = candidate.present_family,
                          };
        break;
      }
    }

    if (self.physical_device == null)
    {
      return ContextError.NoSuitableDevice;
    }

    try log_app ("Pick Physical Device Vulkan OK", severity.DEBUG, .{});
  }

  fn init_logical_device (self: *Self) !void
  {
    const priority = [_] f32 {1};
    const queue_create_info = [_] vk.DeviceQueueCreateInfo
                              {
                                .{
                                  .flags              = .{},
                                  .queue_family_index = self.candidate.graphics_family,
                                  .queue_count        = 1,
                                  .p_queue_priorities = &priority,
                                 },
                                .{
                                  .flags              = .{},
                                  .queue_family_index = self.candidate.present_family,
                                  .queue_count        = 1,
                                  .p_queue_priorities = &priority,
                                 },
                              };
    const queue_count: u32 = if (self.candidate.graphics_family == self.candidate.present_family) 1 else 2;

    const device_feat = vk.PhysicalDeviceFeatures {};

    const device_create_info = vk.DeviceCreateInfo
                               {
                                 .flags                   = .{},
                                 .p_queue_create_infos    = &queue_create_info,
                                 .queue_create_info_count = queue_count,
                                 .enabled_layer_count     = required_layers.len,
                                 .pp_enabled_layer_names  = if (required_layers.len > 0) @ptrCast ([*] const [*:0] const u8, required_layers[0..required_layers.len]) else undefined,
                                 .p_enabled_features      = &device_feat,
                               };

    self.logical_device = try self.initializer.instance_dispatch.createDevice (self.physical_device.?, &device_create_info, null);

    self.device_dispatch = try DeviceDispatch.load (self.logical_device, self.initializer.instance_dispatch.dispatch.vkGetDeviceProcAddr);
    errdefer self.device_dispatch.destroyDevice (self.logical_device, null);

    self.graphics_queue = self.device_dispatch.getDeviceQueue (self.logical_device, self.candidate.graphics_family, 0);
    self.present_queue = self.device_dispatch.getDeviceQueue (self.logical_device, self.candidate.present_family, 0);

    try log_app ("Init Logical Device Vulkan OK", severity.DEBUG, .{});
  }

  pub fn get_surface (self: Self) struct { instance: vk.Instance, surface: vk.SurfaceKHR, success: i32, }
  {
    return .{
              .instance = self.initializer.instance,
              .surface  = self.surface,
              .success  = @enumToInt (vk.Result.success),
            };
  }

  pub fn set_surface (self: *Self, surface: *vk.SurfaceKHR) void
  {
    self.surface = surface.*;
  }

  pub fn init_instance (extensions: *[][*:0] const u8,
    instance_proc_addr: *const fn (?*anyopaque, [*:0] const u8) callconv (.C) ?*const fn () callconv (.C) void) !Self
  {
    var self: Self = undefined;
    self.initializer = try init_vk.init_instance (extensions, instance_proc_addr);

    try log_app ("Init Vulkan Instance OK", severity.DEBUG, .{});
    return self;
  }

  pub fn init_devices (self: *Self) !void
  {
    try self.pick_physical_device ();
    try self.init_logical_device ();

    try log_app ("Init Vulkan Devices OK", severity.DEBUG, .{});
  }

  pub fn loop (self: Self) !void
  {
    _ = self;
    try log_app ("Loop Vulkan OK", severity.DEBUG, .{});
  }

  pub fn cleanup (self: Self) !void
  {
    self.device_dispatch.destroyDevice (self.logical_device, null);
    self.initializer.instance_dispatch.destroySurfaceKHR (self.initializer.instance, self.surface, null);
    try self.initializer.cleanup ();
    try log_app ("Cleanup Vulkan OK", severity.DEBUG, .{});
  }
};
