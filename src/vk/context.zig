const std       = @import ("std");
const build     = @import ("build_options");
const resources = @import ("resources");

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
  allocator:          std.mem.Allocator,
  initializer:        init_vk,
  surface:            vk.SurfaceKHR      = undefined,
  device_dispatch:    DeviceDispatch,
  physical_device:    ?vk.PhysicalDevice = null,
  candidate:          struct { graphics_family: u32, present_family: u32, extensions: std.ArrayList ([*:0] const u8), },
  logical_device:     vk.Device,
  graphics_queue:     vk.Queue,
  present_queue:      vk.Queue,
  capabilities:       vk.SurfaceCapabilitiesKHR,
  formats:            [] vk.SurfaceFormatKHR,
  present_modes:      [] vk.PresentModeKHR,
  surface_format:     vk.SurfaceFormatKHR,
  extent:             vk.Extent2D,
  swapchain:          vk.SwapchainKHR,
  images:             [] vk.Image,
  image_views:        [] vk.ImageView,

  const Self = @This ();

  const required_device_extensions = [_][*:0] const u8
  {
    vk.extension_info.khr_swapchain.name,
  };

  const ContextError = error
  {
    NoDevice,
    NoSuitableDevice,
  };

  fn find_queue_families (self: *Self, device: vk.PhysicalDevice) !bool
  {
    var queue_family_count: u32 = undefined;

    self.initializer.instance_dispatch.getPhysicalDeviceQueueFamilyProperties (device, &queue_family_count, null);

    var queue_families = try self.allocator.alloc (vk.QueueFamilyProperties, queue_family_count);
    defer self.allocator.free (queue_families);

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
      try log_app ("Find Vulkan Queue Families OK", severity.DEBUG, .{});
      self.candidate.graphics_family = graphics_family.?;
      self.candidate.present_family = present_family.?;
      return true;
    }

    try log_app ("Find Vulkan Queue Families failed", severity.ERROR, .{});
    return false;
  }

  fn check_device_extension_support (self: *Self, device: vk.PhysicalDevice) !bool
  {
    var supported_device_extensions_count: u32 = undefined;

    _ = try self.initializer.instance_dispatch.enumerateDeviceExtensionProperties (device, null, &supported_device_extensions_count, null);

    var supported_device_extensions = try self.allocator.alloc (vk.ExtensionProperties, supported_device_extensions_count);
    defer self.allocator.free (supported_device_extensions);

    _ = try self.initializer.instance_dispatch.enumerateDeviceExtensionProperties (device, null, &supported_device_extensions_count, supported_device_extensions.ptr);

    for (required_device_extensions) |required_ext|
    {
      for (supported_device_extensions) |supported_ext|
      {
        if (std.mem.eql (u8, std.mem.span (required_ext), supported_ext.extension_name [0..std.mem.indexOfScalar (u8, &(supported_ext.extension_name), 0).?]))
        {
          try log_app ("{s} required device extension is supported", severity.DEBUG, .{ required_ext });
          break;
        }
      } else {
        try log_app ("{s} required device extension is not supported", severity.ERROR, .{ required_ext });
        return false;
      }
    }

    self.candidate.extensions = try std.ArrayList ([*:0] const u8).initCapacity (self.allocator, required_device_extensions.len);
    errdefer self.candidate.extensions.deinit ();

    try self.candidate.extensions.appendSlice (required_device_extensions [0..]);

    try log_app ("Check Vulkan Device Extension Support OK", severity.DEBUG, .{});
    return true;
  }

  fn query_swapchain_support (self: *Self, device: vk.PhysicalDevice) !void
  {
    self.capabilities = try self.initializer.instance_dispatch.getPhysicalDeviceSurfaceCapabilitiesKHR (device, self.surface);

    var format_count: u32 = undefined;

    _ = try self.initializer.instance_dispatch.getPhysicalDeviceSurfaceFormatsKHR (device, self.surface, &format_count, null);

    if (format_count > 0)
    {
      self.formats = try self.allocator.alloc (vk.SurfaceFormatKHR, format_count);
      errdefer self.allocator.free (self.formats);

      _ = try self.initializer.instance_dispatch.getPhysicalDeviceSurfaceFormatsKHR (device, self.surface, &format_count, self.formats.ptr);
    }

    var present_mode_count: u32 = undefined;

    _ = try self.initializer.instance_dispatch.getPhysicalDeviceSurfacePresentModesKHR (device, self.surface, &present_mode_count, null);

    if (present_mode_count > 0)
    {
      self.present_modes = try self.allocator.alloc (vk.PresentModeKHR, present_mode_count);
      errdefer self.allocator.free (self.present_modes);

      _ = try self.initializer.instance_dispatch.getPhysicalDeviceSurfacePresentModesKHR (device, self.surface, &present_mode_count, self.present_modes.ptr);
    }

    try log_app ("Query Vulkan Swapchain Support OK", severity.DEBUG, .{});
  }

  fn is_suitable (self: *Self, device: vk.PhysicalDevice) !bool
  {
    const device_prop = self.initializer.instance_dispatch.getPhysicalDeviceProperties (device);
    const device_feat = self.initializer.instance_dispatch.getPhysicalDeviceFeatures (device);

    // TODO: issue #52: prefer a device that support drawing and presentation in the same queue for better perf

    _ = device_prop;
    _ = device_feat;

    if (!try self.check_device_extension_support (device))
    {
      return false;
    }

    try self.query_swapchain_support (device);

    if (self.formats.len > 0 and self.present_modes.len > 0)
    {
      if (try self.find_queue_families (device))
      {
        try log_app ("Is Vulkan Device Suitable OK", severity.DEBUG, .{});
        return true;
      }
    }

    try log_app ("Is Vulkan Device Suitable failed", severity.ERROR, .{});
    return false;
  }

  fn pick_physical_device (self: *Self) !void
  {
    var device_count: u32 = undefined;

    _ = try self.initializer.instance_dispatch.enumeratePhysicalDevices (self.initializer.instance, &device_count, null);

    if (device_count == 0)
    {
      return ContextError.NoDevice;
    }

    var devices = try self.allocator.alloc (vk.PhysicalDevice, device_count);
    defer self.allocator.free (devices);

    _ = try self.initializer.instance_dispatch.enumeratePhysicalDevices (self.initializer.instance, &device_count, devices.ptr);

    for (devices) |device|
    {
      if (try self.is_suitable (device))
      {
        self.physical_device = device;
        break;
      }
    }

    if (self.physical_device == null)
    {
      return ContextError.NoSuitableDevice;
    }

    try log_app ("Pick Vulkan Physical Device OK", severity.DEBUG, .{});
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
                                 .pp_enabled_layer_names  = if (required_layers.len > 0) @ptrCast ([*] const [*:0] const u8, required_layers[0..]) else undefined,
                                 .enabled_extension_count = @intCast(u32, self.candidate.extensions.items.len),
                                 .pp_enabled_extension_names = @ptrCast([*] const [*:0] const u8, self.candidate.extensions.items),
                                 .p_enabled_features      = &device_feat,
                               };
    defer self.candidate.extensions.deinit ();

    self.logical_device = try self.initializer.instance_dispatch.createDevice (self.physical_device.?, &device_create_info, null);

    self.device_dispatch = try DeviceDispatch.load (self.logical_device, self.initializer.instance_dispatch.dispatch.vkGetDeviceProcAddr);
    errdefer self.device_dispatch.destroyDevice (self.logical_device, null);

    self.graphics_queue = self.device_dispatch.getDeviceQueue (self.logical_device, self.candidate.graphics_family, 0);
    self.present_queue = self.device_dispatch.getDeviceQueue (self.logical_device, self.candidate.present_family, 0);

    try log_app ("Init Vulkan Logical Device OK", severity.DEBUG, .{});
  }

  fn choose_swap_support_format (self: *Self) void
  {
    for (self.formats) |format|
    {
      if (format.format == vk.Format.b8g8r8a8_srgb and format.color_space == vk.ColorSpaceKHR.srgb_nonlinear_khr)
      {
        self.surface_format = format;
      }
    }

    self.surface_format = self.formats [0];
  }

  fn choose_swap_present_mode (self: Self) vk.PresentModeKHR
  {
    for (self.present_modes) |present_mode|
    {
      if (present_mode == vk.PresentModeKHR.mailbox_khr)
      {
        return present_mode;
      }
    }

    return vk.PresentModeKHR.fifo_khr;
  }

  fn choose_swap_extent (self: *Self, framebuffer: struct { width: u32, height: u32, }) void
  {
    if (self.capabilities.current_extent.width != std.math.maxInt (u32))
    {
      self.extent = self.capabilities.current_extent;
    } else {
      self.extent = vk.Extent2D
                    {
                      .width  = std.math.clamp (framebuffer.width, self.capabilities.min_image_extent.width, self.capabilities.max_image_extent.width),
                      .height = std.math.clamp (framebuffer.height, self.capabilities.min_image_extent.height, self.capabilities.max_image_extent.height),
                    };
    }
  }

  fn init_swapchain_images (self: *Self) !void
  {
    var image_count: u32 = undefined;

    _ = try self.device_dispatch.getSwapchainImagesKHR (self.logical_device, self.swapchain, &image_count, null);

    self.images = try self.allocator.alloc (vk.Image, image_count);
    errdefer self.allocator.free (self.images);

    self.image_views = try self.allocator.alloc (vk.ImageView, image_count);
    errdefer self.allocator.free (self.image_views);

    _ = try self.device_dispatch.getSwapchainImagesKHR (self.logical_device, self.swapchain, &image_count, self.images.ptr);

    try log_app ("Init Vulkan Swapchain Images OK", severity.DEBUG, .{});
  }

  fn init_swapchain (self: *Self, framebuffer: struct { width: u32, height: u32, }) !void
  {
    self.choose_swap_support_format ();
    const present_mode = self.choose_swap_present_mode ();
    self.choose_swap_extent (.{ .width = framebuffer.width, .height = framebuffer.height, });

    var image_count = self.capabilities.min_image_count + 1;

    if (self.capabilities.max_image_count > 0 and image_count > self.capabilities.max_image_count)
    {
      image_count = self.capabilities.max_image_count;
    }

    const queue_family_indices = [_] u32 {
                                           self.candidate.graphics_family,
                                           self.candidate.present_family,
                                         };

    const create_info = vk.SwapchainCreateInfoKHR
                        {
                          .flags                    = .{},
                          .surface                  = self.surface,
                          .min_image_count          = image_count,
                          .image_format             = self.surface_format.format,
                          .image_color_space        = self.surface_format.color_space,
                          .image_extent             = self.extent,
                          .image_array_layers       = 1,
                          .image_usage              = .{ .color_attachment_bit = true, .transfer_dst_bit = true },
                          .image_sharing_mode       = if (self.candidate.graphics_family != self.candidate.present_family) .concurrent else .exclusive,
                          .queue_family_index_count = if (self.candidate.graphics_family != self.candidate.present_family) queue_family_indices.len else 0,
                          .p_queue_family_indices   = if (self.candidate.graphics_family != self.candidate.present_family) &queue_family_indices else null,
                          .pre_transform            = self.capabilities.current_transform,
                          .composite_alpha          = .{ .opaque_bit_khr = true },
                          .present_mode             = present_mode,
                          .clipped                  = vk.TRUE,
                          // .old_swapchain            = null,
                        };

    self.swapchain = try self.device_dispatch.createSwapchainKHR (self.logical_device, &create_info, null);
    errdefer self.device_dispatch.destroySwapchainKHR (self.logical_device, self.swapchain, null);

    try self.init_swapchain_images ();

    try log_app ("Init Vulkan Swapchain OK", severity.DEBUG, .{});
  }

  fn init_image_views (self: *Self) !void
  {
    var create_info: vk.ImageViewCreateInfo = undefined;

    for (self.images, 0..) |image, index|
    {
      create_info = vk.ImageViewCreateInfo
                    {
                      .flags             = .{},
                      .image             = image,
                      .view_type         = .@"2d",
                      .format            = self.surface_format.format,
                      .components        = .{
                                              .r = .identity,
                                              .g = .identity,
                                              .b = .identity,
                                              .a = .identity,
                                            },
                      .subresource_range = .{
                                              .aspect_mask      = .{ .color_bit = true },
                                              .base_mip_level   = 0,
                                              .level_count      = 1,
                                              .base_array_layer = 0,
                                              .layer_count      = 1,
                                            },
                    };

      self.image_views [index] = try self.device_dispatch.createImageView (self.logical_device, &create_info, null);
      errdefer self.device_dispatch.destroyImageView (self.logical_device, self.image_views [index], null);
    }

    try log_app ("Init Vulkan Swapchain Image Views OK", severity.DEBUG, .{});
  }

  fn init_shader_module (self: Self, resource: [] const u8) !vk.ShaderModule
  {
    const create_info = vk.ShaderModuleCreateInfo
                        {
                          .flags     = .{},
                          .code_size = resource.len,
                          .p_code    = @ptrCast ([*] const u32, @alignCast (@alignOf(u32), resource.ptr)),
                        };

    return try self.device_dispatch.createShaderModule (self.logical_device, &create_info, null);

  }

  fn init_graphics_pipeline (self: Self) !void
  {
    const vertex = try self.init_shader_module (resources.vert [0..]);
    defer self.device_dispatch.destroyShaderModule (self.logical_device, vertex, null);
    const fragment = try self.init_shader_module (resources.frag [0..]);
    defer self.device_dispatch.destroyShaderModule (self.logical_device, fragment, null);

    const create_info = [_] vk.PipelineShaderStageCreateInfo
                        {
                          .{
                             .flags                 = .{},
                             .stage                 = .{ .vertex_bit = true },
                             .module                = vertex,
                             .p_name                = "main",
                             .p_specialization_info = null,
                           },
                          .{
                             .flags                 = .{},
                             .stage                 = .{ .fragment_bit = true },
                             .module                = fragment,
                             .p_name                = "main",
                             .p_specialization_info = null,
                           },
                        };

    _ = create_info;

    try log_app ("Init Vulkan Graphics Pipeline OK", severity.DEBUG, .{});
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

    self.allocator = std.heap.page_allocator;

    self.initializer = try init_vk.init_instance (extensions, instance_proc_addr, self.allocator);

    try log_app ("Init Vulkan Instance OK", severity.DEBUG, .{});
    return self;
  }

  pub fn init_devices (self: *Self, framebuffer: struct { width: u32, height: u32, }) !void
  {
    try self.pick_physical_device ();
    defer self.allocator.free (self.formats);
    defer self.allocator.free (self.present_modes);

    try self.init_logical_device ();
    try self.init_swapchain (.{ .width = framebuffer.width, .height = framebuffer.height, });
    defer self.allocator.free (self.images);
    errdefer self.allocator.free (self.image_views);

    try self.init_image_views ();

    try self.init_graphics_pipeline ();

    try log_app ("Init Vulkan Devices OK", severity.DEBUG, .{});
  }

  pub fn loop (self: Self) !void
  {
    _ = self;
    try log_app ("Loop Vulkan OK", severity.DEBUG, .{});
  }

  pub fn cleanup (self: Self) !void
  {
    for (self.image_views) |image_view|
    {
      self.device_dispatch.destroyImageView (self.logical_device, image_view, null);
    }
    self.allocator.free (self.image_views);
    self.device_dispatch.destroySwapchainKHR (self.logical_device, self.swapchain, null);
    self.device_dispatch.destroyDevice (self.logical_device, null);
    self.initializer.instance_dispatch.destroySurfaceKHR (self.initializer.instance, self.surface, null);
    try self.initializer.cleanup ();
    try log_app ("Cleanup Vulkan OK", severity.DEBUG, .{});
  }
};
