const std       = @import ("std");
const build     = @import ("build_options");
const resources = @import ("resources");
const vk        = @import ("vulkan");

const context_imgui = @import ("../imgui/context.zig").context_imgui;

const utils    = @import ("../utils.zig");
const log_app  = utils.log_app;
const profile  = utils.profile;
const severity = utils.severity;

const opts = @import ("../options.zig").options;

const dispatch         = @import ("dispatch.zig");
const InstanceDispatch = dispatch.InstanceDispatch;
const DeviceDispatch   = dispatch.DeviceDispatch;

const vertex_vk = @import ("vertex.zig").vertex_vk;

const instance        = if (build.LOG_LEVEL == @intFromEnum (profile.TURBO)) @import ("instance_turbo.zig") else @import ("instance_debug.zig");
const instance_vk     = instance.instance_vk;
const required_layers = instance_vk.required_layers;

const uniform_buffer_object_vk = struct
{
  // WARNING: manage alignment when adding new field
  time: f32,
};

const offscreen_uniform_buffer_object_vk = struct
{
  // WARNING: manage alignment when adding new field
  seed: u32,
};

pub const context_vk = struct
{
  instance:                         instance_vk = undefined,
  surface:                          vk.SurfaceKHR = undefined,
  device_dispatch:                  DeviceDispatch = undefined,
  physical_device:                  ?vk.PhysicalDevice = null,
  candidate:                        struct { graphics_family: u32, present_family: u32, extensions: std.ArrayList ([*:0] const u8), } = undefined,
  logical_device:                   vk.Device = undefined,
  graphics_queue:                   vk.Queue = undefined,
  present_queue:                    vk.Queue = undefined,
  capabilities:                     vk.SurfaceCapabilitiesKHR = undefined,
  formats:                          [] vk.SurfaceFormatKHR = undefined,
  present_modes:                    [] vk.PresentModeKHR = undefined,
  surface_format:                   vk.SurfaceFormatKHR = undefined,
  extent:                           vk.Extent2D = undefined,
  swapchain:                        vk.SwapchainKHR = undefined,
  images:                           [] vk.Image = undefined,
  views:                            [] vk.ImageView = undefined,
  viewport:                         [1] vk.Viewport = undefined,
  scissor:                          [1] vk.Rect2D = undefined,
  render_pass:                      vk.RenderPass = undefined,
  descriptor_set_layout:            [] vk.DescriptorSetLayout = undefined,
  pipeline_layout:                  vk.PipelineLayout = undefined,
  pipelines:                        [] vk.Pipeline = undefined,
  framebuffers:                     [] vk.Framebuffer = undefined,
  command_pool:                     vk.CommandPool = undefined,
  command_buffers:                  [] vk.CommandBuffer = undefined,
  image_available_semaphores:       [] vk.Semaphore = undefined,
  render_finished_semaphores:       [] vk.Semaphore = undefined,
  in_flight_fences:                 [] vk.Fence = undefined,
  current_frame:                    u8 = 0,
  vertex_buffer:                    vk.Buffer = undefined,
  vertex_buffer_memory:             vk.DeviceMemory = undefined,
  buffers_command_pool:             vk.CommandPool = undefined,
  index_buffer:                     vk.Buffer = undefined,
  index_buffer_memory:              vk.DeviceMemory = undefined,
  uniform_buffers:                  [] vk.Buffer = undefined,
  uniform_buffers_memory:           [] vk.DeviceMemory = undefined,
  start_time:                       std.time.Instant,
  last_displayed_fps:               ?std.time.Instant = null,
  fps:                              f32 = undefined,
  descriptor_pool:                  vk.DescriptorPool = undefined,
  descriptor_sets:                  [] vk.DescriptorSet = undefined,

  offscreen_width:                  u32 = undefined,
  offscreen_height:                 u32 = undefined,
  offscreen_render_pass:            vk.RenderPass = undefined,
  offscreen_descriptor_set_layout:  [] vk.DescriptorSetLayout = undefined,
  offscreen_pipeline_layout:        vk.PipelineLayout = undefined,
  offscreen_pipelines:              [] vk.Pipeline = undefined,
  offscreen_framebuffer:            vk.Framebuffer = undefined,
  offscreen_uniform_buffers:        vk.Buffer = undefined,
  offscreen_uniform_buffers_memory: vk.DeviceMemory = undefined,
  offscreen_descriptor_sets:        [] vk.DescriptorSet = undefined,
  offscreen_image:                  vk.Image = undefined,
  offscreen_image_memory:           vk.DeviceMemory = undefined,
  offscreen_views:                  [] vk.ImageView = undefined,
  offscreen_sampler:                vk.Sampler = undefined,
  render_offscreen:                 bool = true,

  const Self = @This ();

  const MAX_FRAMES_IN_FLIGHT = 2;
  const MAX_DEVICE_SCORE = 3;

  const vertices = [_] vertex_vk
                   {
                     vertex_vk { .pos = [_] f32 { -1.0, -1.0, }, },
                     vertex_vk { .pos = [_] f32 {  3.0, -1.0, }, },
                     vertex_vk { .pos = [_] f32 { -1.0,  3.0, }, },
                   };

  const indices = [_] u32 { 0, 1, 2, };

  const required_device_extensions = [_][*:0] const u8
  {
    vk.extension_info.khr_swapchain.name,
  };

  const ContextError = error
  {
    NoDevice,
    NoSuitableDevice,
    NoSuitableMemoryType,
    ImageAcquireFailed,
  };

  fn find_queue_families (self: *Self, device: vk.PhysicalDevice, allocator: std.mem.Allocator) !?struct { graphics_family: u32, present_family: u32, }
  {
    var queue_family_count: u32 = undefined;

    self.instance.dispatch.getPhysicalDeviceQueueFamilyProperties (device, &queue_family_count, null);

    var queue_families = try allocator.alloc (vk.QueueFamilyProperties, queue_family_count);

    self.instance.dispatch.getPhysicalDeviceQueueFamilyProperties (device, &queue_family_count, queue_families.ptr);

    var present_family: ?u32 = null;
    var graphics_family: ?u32 = null;

    for (queue_families, 0..) |properties, index|
    {
      const family: u32 = @intCast(index);

      if (properties.queue_flags.graphics_bit and try self.instance.dispatch.getPhysicalDeviceSurfaceSupportKHR (device, family, self.surface) == vk.TRUE)
      {
        graphics_family = family;
        present_family = family;
        break;
      }

      if (graphics_family == null and properties.queue_flags.graphics_bit)
      {
        graphics_family = family;
      }

      if (present_family == null and try self.instance.dispatch.getPhysicalDeviceSurfaceSupportKHR (device, family, self.surface) == vk.TRUE)
      {
        present_family = family;
      }
    }

    if (graphics_family != null and present_family != null)
    {
      try log_app ("find Vulkan queue families OK", severity.DEBUG, .{});
      return .{ .graphics_family = graphics_family.?, .present_family = present_family.?, };
    }

    try log_app ("find Vulkan queue families failed", severity.ERROR, .{});
    return null;
  }

  fn check_device_extension_support (self: *Self, device: vk.PhysicalDevice, name: [vk.MAX_PHYSICAL_DEVICE_NAME_SIZE] u8, allocator: std.mem.Allocator) !bool
  {
    var supported_device_extensions_count: u32 = undefined;

    _ = try self.instance.dispatch.enumerateDeviceExtensionProperties (device, null, &supported_device_extensions_count, null);

    var supported_device_extensions = try allocator.alloc (vk.ExtensionProperties, supported_device_extensions_count);

    _ = try self.instance.dispatch.enumerateDeviceExtensionProperties (device, null, &supported_device_extensions_count, supported_device_extensions.ptr);

    for (required_device_extensions) |required_ext|
    {
      for (supported_device_extensions) |supported_ext|
      {
        if (std.mem.eql (u8, std.mem.span (required_ext), supported_ext.extension_name [0..std.mem.indexOfScalar (u8, &(supported_ext.extension_name), 0).?]))
        {
          try log_app ("Vulkan device {s} supports the {s} required device extension", severity.DEBUG, .{ name, required_ext });
          break;
        }
      } else {
        try log_app ("Vulkan device {s} does not support the {s} required device extension", severity.DEBUG, .{ name, required_ext });
        return false;
      }
    }

    self.candidate.extensions = try std.ArrayList ([*:0] const u8).initCapacity (allocator, required_device_extensions.len);

    try self.candidate.extensions.appendSlice (required_device_extensions [0..]);

    try log_app ("Vulkan device {s} supports all required device extension", severity.DEBUG, .{ name });
    return true;
  }

  fn query_swapchain_support (self: *Self, device: vk.PhysicalDevice, allocator: std.mem.Allocator) !void
  {
    self.capabilities = try self.instance.dispatch.getPhysicalDeviceSurfaceCapabilitiesKHR (device, self.surface);

    var format_count: u32 = undefined;

    _ = try self.instance.dispatch.getPhysicalDeviceSurfaceFormatsKHR (device, self.surface, &format_count, null);

    if (format_count > 0)
    {
      self.formats = try allocator.alloc (vk.SurfaceFormatKHR, format_count);

      _ = try self.instance.dispatch.getPhysicalDeviceSurfaceFormatsKHR (device, self.surface, &format_count, self.formats.ptr);
    }

    var present_mode_count: u32 = undefined;

    _ = try self.instance.dispatch.getPhysicalDeviceSurfacePresentModesKHR (device, self.surface, &present_mode_count, null);

    if (present_mode_count > 0)
    {
      self.present_modes = try allocator.alloc (vk.PresentModeKHR, present_mode_count);

      _ = try self.instance.dispatch.getPhysicalDeviceSurfacePresentModesKHR (device, self.surface, &present_mode_count, self.present_modes.ptr);
    }

    try log_app ("query Vulkan swapchain support OK", severity.DEBUG, .{});
  }

  fn check_device_features_properties (self: Self, features: vk.PhysicalDeviceFeatures, properties: vk.PhysicalDeviceProperties) !bool
  {
    if (features.sampler_anisotropy != vk.TRUE)
    {
      try log_app ("Vulkan device {s} does not support sampler anisotropy feature", severity.INFO, .{ properties.device_name, });
      return false;
    }
    try log_app ("Vulkan device {s} supports sampler anisotropy feature", severity.DEBUG, .{ properties.device_name, });

    if (properties.limits.max_sampler_anisotropy < 1)
    {
      try log_app ("Vulkan device {s} does not support a sampler anisotropy value greater than 1", severity.INFO, .{ properties.device_name, });
      return false;
    }
    try log_app ("Vulkan device {s} supports a sampler anisotropy value greater than 1", severity.DEBUG, .{ properties.device_name, });

    if (properties.limits.max_image_dimension_2d < self.offscreen_width)
    {
      try log_app ("Vulkan device {s} does not support a maximum 2D image size ({d}) greater than offscreen framebuffer width ({d})", severity.INFO, .{ properties.device_name, properties.limits.max_image_dimension_2d, self.offscreen_width, });
      return false;
    }
    try log_app ("Vulkan device {s} supports a maximum 2D image size ({d}) greater than offscreen framebuffer width ({d})", severity.DEBUG, .{ properties.device_name, properties.limits.max_image_dimension_2d, self.offscreen_width, });

    if (properties.limits.max_image_dimension_2d < self.offscreen_height)
    {
      try log_app ("Vulkan device {s} does not support a maximum 2D image size ({d}) greater than offscreen framebuffer height ({d})", severity.INFO, .{ properties.device_name, properties.limits.max_image_dimension_2d, self.offscreen_height, });
      return false;
    }
    try log_app ("Vulkan device {s} supports a maximum 2D image size ({d}) greater than offscreen framebuffer height ({d})", severity.DEBUG, .{ properties.device_name, properties.limits.max_image_dimension_2d, self.offscreen_height, });

    if (properties.limits.max_uniform_buffer_range < @sizeOf (uniform_buffer_object_vk))
    {
      try log_app ("Vulkan device {s} does not support a maximum uniform buffer range ({d}) greater than uniform_buffer_object_vk struct size ({d})", severity.INFO, .{ properties.device_name, properties.limits.max_uniform_buffer_range, @sizeOf (uniform_buffer_object_vk), });
      return false;
    }
    try log_app ("Vulkan device {s} supports a maximum uniform buffer range ({d}) greater than uniform_buffer_object_vk struct size ({d})", severity.DEBUG, .{ properties.device_name, properties.limits.max_uniform_buffer_range, @sizeOf (uniform_buffer_object_vk), });

    if (properties.limits.max_uniform_buffer_range < @sizeOf (offscreen_uniform_buffer_object_vk))
    {
      try log_app ("Vulkan device {s} does not support a maximum uniform buffer range ({d}) greater than offscreen_uniform_buffer_object_vk struct size ({d})", severity.INFO, .{ properties.device_name, properties.limits.max_uniform_buffer_range, @sizeOf (offscreen_uniform_buffer_object_vk), });
      return false;
    }
    try log_app ("Vulkan device {s} supports a maximum uniform buffer range ({d}) greater than offscreen_uniform_buffer_object_vk struct size ({d})", severity.DEBUG, .{ properties.device_name, properties.limits.max_uniform_buffer_range, @sizeOf (offscreen_uniform_buffer_object_vk), });

    if (properties.limits.max_memory_allocation_count < 1)
    {
      try log_app ("Vulkan device {s} does not support a vkAllocateMemory() call", severity.INFO, .{ properties.device_name, });
      return false;
    }
    try log_app ("Vulkan device {s} supports until {d} vkAllocateMemory() calls simultaneously", severity.DEBUG, .{ properties.device_name, properties.limits.max_memory_allocation_count });

    if (properties.limits.max_sampler_allocation_count < 1)
    {
      try log_app ("Vulkan device {s} does not support creation of sampler objects", severity.INFO, .{ properties.device_name, });
      return false;
    }
    try log_app ("Vulkan device {s} supports until {d} sampler objects simultaneously", severity.DEBUG, .{ properties.device_name, properties.limits.max_sampler_allocation_count, });

    if (properties.limits.max_bound_descriptor_sets < 2)
    {
      try log_app ("Vulkan device {s} does not support that 2 or more descriptor sets can be simultaneously used", severity.INFO, .{ properties.device_name, });
      return false;
    }
    try log_app ("Vulkan device {s} supports until {d} descriptor sets used simultaneously", severity.DEBUG, .{ properties.device_name, properties.limits.max_bound_descriptor_sets });

    if (properties.limits.max_per_stage_descriptor_samplers < 1)
    {
      try log_app ("Vulkan device {s} does not support access to a sample object by a single shader stage", severity.INFO, .{ properties.device_name, });
      return false;
    }
    try log_app ("Vulkan device {s} supports until {d} accessible sample objects by a single shader stage", severity.DEBUG, .{ properties.device_name, properties.limits.max_per_stage_descriptor_samplers });

    if (properties.limits.max_per_stage_descriptor_uniform_buffers < 1)
    {
      try log_app ("Vulkan device {s} does not support access to a uniform buffer by a single shader stage", severity.INFO, .{ properties.device_name, });
      return false;
    }
    try log_app ("Vulkan device {s} supports until {d} accessible uniform buffers by a single shader stage", severity.DEBUG, .{ properties.device_name, properties.limits.max_per_stage_descriptor_samplers });

    if (properties.limits.max_per_stage_descriptor_sampled_images < 1)
    {
      try log_app ("Vulkan device {s} does not support access to a sampled image by a single shader stage", severity.INFO, .{ properties.device_name, });
      return false;
    }
    try log_app ("Vulkan device {s} supports until {d} accessible sampled image by a single shader stage", severity.DEBUG, .{ properties.device_name, properties.limits.max_per_stage_descriptor_sampled_images });

    if (properties.limits.max_per_stage_resources < 2)
    {
      try log_app ("Vulkan device {s} does not support access to 2 or more resources by a single shader stage", severity.INFO, .{ properties.device_name, });
      return false;
    }
    try log_app ("Vulkan device {s} supports until {d} resources by a single shader stage", severity.DEBUG, .{ properties.device_name, properties.limits.max_per_stage_resources });

    if (properties.limits.max_descriptor_set_uniform_buffers < 1)
    {
      try log_app ("Vulkan device {s} does not support inclusion of a uniform buffer in a pipeline layout", severity.INFO, .{ properties.device_name, });
      return false;
    }
    try log_app ("Vulkan device {s} supports until {d} included uniform buffers in a pipeline layout", severity.DEBUG, .{ properties.device_name, properties.limits.max_descriptor_set_uniform_buffers });

    if (properties.limits.max_descriptor_set_samplers < 1)
    {
      try log_app ("Vulkan device {s} does not support inclusion of a sampler in a pipeline layout", severity.INFO, .{ properties.device_name, });
      return false;
    }
    try log_app ("Vulkan device {s} supports until {d} included samplers in a pipeline layout", severity.DEBUG, .{ properties.device_name, properties.limits.max_descriptor_set_samplers });

    if (properties.limits.max_descriptor_set_sampled_images < 1)
    {
      try log_app ("Vulkan device {s} does not support inclusion of a sampled image in a pipeline layout", severity.INFO, .{ properties.device_name, });
      return false;
    }
    try log_app ("Vulkan device {s} supports until {d} included sampled image in a pipeline layout", severity.DEBUG, .{ properties.device_name, properties.limits.max_descriptor_set_sampled_images });

    if (properties.limits.max_fragment_input_components < 2)
    {
      try log_app ("Vulkan device {s} does not support 2 or more components of input variables provided as inputs to the fragment shader stage", severity.INFO, .{ properties.device_name, });
      return false;
    }
    try log_app ("Vulkan device {s} supports until {d} components of input variables provided as inputs to the fragment shader stage", severity.DEBUG, .{ properties.device_name, properties.limits.max_fragment_input_components });

    if (properties.limits.max_viewports < 1)
    {
      try log_app ("Vulkan device {s} does not support active viewport", severity.INFO, .{ properties.device_name, });
      return false;
    }
    try log_app ("Vulkan device {s} supports until {d} active viewports", severity.DEBUG, .{ properties.device_name, properties.limits.max_viewports });

    if (properties.limits.max_viewports < 1)
    {
      try log_app ("Vulkan device {s} does not support active viewport", severity.INFO, .{ properties.device_name, });
      return false;
    }
    try log_app ("Vulkan device {s} supports until {d} active viewports", severity.DEBUG, .{ properties.device_name, properties.limits.max_viewports });

    if (properties.limits.max_viewport_dimensions [0] < self.offscreen_width)
    {
      try log_app ("Vulkan device {s} does not support a maximum viewport width ({d}) greater than offscreen framebuffer width ({d})", severity.INFO, .{ properties.device_name, properties.limits.max_viewport_dimensions [0], self.offscreen_width});
      return false;
    }
    try log_app ("Vulkan device {s} supports a maximum viewport width ({d}) greater than offscreen framebuffer width ({d})", severity.DEBUG, .{ properties.device_name, properties.limits.max_viewport_dimensions [0], self.offscreen_width});

    if (properties.limits.max_viewport_dimensions [1] < self.offscreen_height)
    {
      try log_app ("Vulkan device {s} does not support a maximum viewport height ({d}) greater than offscreen framebuffer height ({d})", severity.INFO, .{ properties.device_name, properties.limits.max_viewport_dimensions [1], self.offscreen_height});
      return false;
    }
    try log_app ("Vulkan device {s} supports a maximum viewport height ({d}) greater than offscreen framebuffer height ({d})", severity.DEBUG, .{ properties.device_name, properties.limits.max_viewport_dimensions [1], self.offscreen_height});

    if (properties.limits.max_framebuffer_width < self.offscreen_width)
    {
      try log_app ("Vulkan device {s} does not support a maximum framebuffer width ({d}) greater than offscreen framebuffer width ({d})", severity.INFO, .{ properties.device_name, properties.limits.max_framebuffer_width, self.offscreen_width});
      return false;
    }
    try log_app ("Vulkan device {s} supports a maximum framebuffer width ({d}) greater than offscreen framebuffer width ({d})", severity.DEBUG, .{ properties.device_name, properties.limits.max_framebuffer_width, self.offscreen_width});

    if (properties.limits.max_framebuffer_height < self.offscreen_height)
    {
      try log_app ("Vulkan device {s} does not support a maximum framebuffer height ({d}) greater than offscreen framebuffer height ({d})", severity.INFO, .{ properties.device_name, properties.limits.max_framebuffer_height, self.offscreen_height});
      return false;
    }
    try log_app ("Vulkan device {s} supports a maximum framebuffer height ({d}) greater than offscreen framebuffer height ({d})", severity.DEBUG, .{ properties.device_name, properties.limits.max_framebuffer_height, self.offscreen_height});

    if (properties.limits.max_color_attachments < 1)
    {
      try log_app ("Vulkan device {s} does not support color attachment used by a subpass in a render pass", severity.INFO, .{ properties.device_name, });
      return false;
    }
    try log_app ("Vulkan device {s} supports until {d} color attachment used by a subpass in a render pass", severity.DEBUG, .{ properties.device_name, properties.limits.max_color_attachments });

    return true;
  }

  fn is_suitable (self: *Self, device: vk.PhysicalDevice, allocator: std.mem.Allocator) !?struct { graphics_family: u32, present_family: u32, score: u8, }
  {
    const properties = self.instance.dispatch.getPhysicalDeviceProperties (device);
    const features = self.instance.dispatch.getPhysicalDeviceFeatures (device);

    if (!try self.check_device_extension_support (device, properties.device_name, allocator))
    {
      try log_app ("Vulkan device {s} is not suitable", severity.ERROR, .{ properties.device_name, });
      return null;
    }

    try self.query_swapchain_support (device, allocator);

    if (!try self.check_device_features_properties (features, properties))
    {
      try log_app ("Vulkan device {s} is not suitable", severity.ERROR, .{ properties.device_name, });
      return null;
    }

    if (self.formats.len > 0 and self.present_modes.len > 0)
    {
      if (try self.find_queue_families (device, allocator)) |candidate|
      {
        try log_app ("Vulkan device {s} is suitable", severity.DEBUG, .{ properties.device_name, });
        return .{
                  .graphics_family = candidate.graphics_family,
                  .present_family  = candidate.present_family,
                  .score           = @as (u8, @intFromBool (properties.device_type == vk.PhysicalDeviceType.discrete_gpu)) * 4 +
                                     @as (u8, @intFromBool (candidate.graphics_family == candidate.present_family)) * 2 + 1,
                };
      }
    }

    try log_app ("Vulkan device {s} is not suitable", severity.ERROR, .{ properties.device_name, });
    return null;
  }

  fn pick_physical_device (self: *Self, allocator: std.mem.Allocator) !void
  {
    var device_count: u32 = undefined;

    _ = try self.instance.dispatch.enumeratePhysicalDevices (self.instance.instance, &device_count, null);

    if (device_count == 0)
    {
      return ContextError.NoDevice;
    }

    var devices = try allocator.alloc (vk.PhysicalDevice, device_count);
    var max_score: u8 = 0;

    _ = try self.instance.dispatch.enumeratePhysicalDevices (self.instance.instance, &device_count, devices.ptr);

    for (devices) |device|
    {
      const candidate = try self.is_suitable (device, allocator);
      if (candidate != null and candidate.?.score > max_score)
      {
        self.physical_device           = device;
        self.candidate.graphics_family = candidate.?.graphics_family;
        self.candidate.present_family  = candidate.?.present_family;
        max_score                      = candidate.?.score;
      }
      if (max_score == MAX_DEVICE_SCORE) break;
    }

    if (max_score == 0 or self.physical_device == null)
    {
      return ContextError.NoSuitableDevice;
    }

    try log_app ("pick a {d}/3 Vulkan physical device OK", severity.DEBUG, .{ max_score });
  }

  fn init_logical_device (self: *Self) !void
  {
    const priority = [_] f32 {1};
    const queue_create_info = [_] vk.DeviceQueueCreateInfo
                              {
                                vk.DeviceQueueCreateInfo
                                {
                                  .flags              = vk.DeviceQueueCreateFlags {},
                                  .queue_family_index = self.candidate.graphics_family,
                                  .queue_count        = 1,
                                  .p_queue_priorities = &priority,
                                },
                                vk.DeviceQueueCreateInfo
                                {
                                  .flags              = vk.DeviceQueueCreateFlags {},
                                  .queue_family_index = self.candidate.present_family,
                                  .queue_count        = 1,
                                  .p_queue_priorities = &priority,
                                },
                              };
    const queue_count: u32 = if (self.candidate.graphics_family == self.candidate.present_family) 1 else 2;

    const device_features = vk.PhysicalDeviceFeatures
                            {
                              .sampler_anisotropy = vk.TRUE,
                            };

    const device_create_info = vk.DeviceCreateInfo
                               {
                                 .flags                      = vk.DeviceCreateFlags {},
                                 .p_queue_create_infos       = &queue_create_info,
                                 .queue_create_info_count    = queue_count,
                                 .enabled_layer_count        = required_layers.len,
                                 .pp_enabled_layer_names     = if (required_layers.len > 0) @ptrCast (required_layers [0..]) else undefined,
                                 .enabled_extension_count    = @intCast (self.candidate.extensions.items.len),
                                 .pp_enabled_extension_names = @ptrCast (self.candidate.extensions.items),
                                 .p_enabled_features         = &device_features,
                               };

    self.logical_device = try self.instance.dispatch.createDevice (self.physical_device.?, &device_create_info, null);

    self.device_dispatch = try DeviceDispatch.load (self.logical_device, self.instance.dispatch.dispatch.vkGetDeviceProcAddr);
    errdefer self.device_dispatch.destroyDevice (self.logical_device, null);

    self.graphics_queue = self.device_dispatch.getDeviceQueue (self.logical_device, self.candidate.graphics_family, 0);
    self.present_queue = self.device_dispatch.getDeviceQueue (self.logical_device, self.candidate.present_family, 0);

    try log_app ("init Vulkan logical device OK", severity.DEBUG, .{});
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

  fn init_swapchain_images (self: *Self, allocator: std.mem.Allocator) !void
  {
    var image_count: u32 = undefined;

    _ = try self.device_dispatch.getSwapchainImagesKHR (self.logical_device, self.swapchain, &image_count, null);

    self.images = try allocator.alloc (vk.Image, image_count);
    self.views = try allocator.alloc (vk.ImageView, image_count);

    _ = try self.device_dispatch.getSwapchainImagesKHR (self.logical_device, self.swapchain, &image_count, self.images.ptr);

    try log_app ("init Vulkan swapchain images OK", severity.DEBUG, .{});
  }

  fn init_swapchain (self: *Self, framebuffer: struct { width: u32, height: u32, }, allocator: std.mem.Allocator) !void
  {
    self.choose_swap_support_format ();
    const present_mode = self.choose_swap_present_mode ();
    self.choose_swap_extent (.{ .width = framebuffer.width, .height = framebuffer.height, });

    var image_count = self.capabilities.min_image_count + 1;

    if (self.capabilities.max_image_count > 0 and image_count > self.capabilities.max_image_count)
    {
      image_count = self.capabilities.max_image_count;
    }

    const queue_family_indices = [_] u32
                                 {
                                   self.candidate.graphics_family,
                                   self.candidate.present_family,
                                 };

    const create_info = vk.SwapchainCreateInfoKHR
                        {
                          .flags                    = vk.SwapchainCreateFlagsKHR {},
                          .surface                  = self.surface,
                          .min_image_count          = image_count,
                          .image_format             = self.surface_format.format,
                          .image_color_space        = self.surface_format.color_space,
                          .image_extent             = self.extent,
                          .image_array_layers       = 1,
                          .image_usage              = vk.ImageUsageFlags
                                                      {
                                                        .color_attachment_bit = true,
                                                        .transfer_src_bit     = true,
                                                        .transfer_dst_bit     = true,
                                                      },
                          .image_sharing_mode       = if (self.candidate.graphics_family != self.candidate.present_family) .concurrent else .exclusive,
                          .queue_family_index_count = if (self.candidate.graphics_family != self.candidate.present_family) queue_family_indices.len else 0,
                          .p_queue_family_indices   = if (self.candidate.graphics_family != self.candidate.present_family) &queue_family_indices else null,
                          .pre_transform            = self.capabilities.current_transform,
                          .composite_alpha          = vk.CompositeAlphaFlagsKHR { .opaque_bit_khr = true },
                          .present_mode             = present_mode,
                          .clipped                  = vk.TRUE,
                        };

    self.swapchain = try self.device_dispatch.createSwapchainKHR (self.logical_device, &create_info, null);
    errdefer self.device_dispatch.destroySwapchainKHR (self.logical_device, self.swapchain, null);

    try self.init_swapchain_images (allocator);

    try log_app ("init Vulkan swapchain OK", severity.DEBUG, .{});
  }

  fn init_image_views (self: *Self) !void
  {
    var create_info: vk.ImageViewCreateInfo = undefined;

    for (self.images, 0..) |image, index|
    {
      create_info = vk.ImageViewCreateInfo
                    {
                      .flags             = vk.ImageViewCreateFlags {},
                      .image             = image,
                      .view_type         = vk.ImageViewType.@"2d",
                      .format            = self.surface_format.format,
                      .components        = vk.ComponentMapping
                                           {
                                             .r = vk.ComponentSwizzle.identity,
                                             .g = vk.ComponentSwizzle.identity,
                                             .b = vk.ComponentSwizzle.identity,
                                             .a = vk.ComponentSwizzle.identity,
                                           },
                      .subresource_range = vk.ImageSubresourceRange
                                           {
                                             .aspect_mask      = vk.ImageAspectFlags { .color_bit = true },
                                             .base_mip_level   = 0,
                                             .level_count      = 1,
                                             .base_array_layer = 0,
                                             .layer_count      = 1,
                                           },
                    };

      self.views [index] = try self.device_dispatch.createImageView (self.logical_device, &create_info, null);
      errdefer self.device_dispatch.destroyImageView (self.logical_device, self.views [index], null);
    }

    try log_app ("init Vulkan swapchain image views OK", severity.DEBUG, .{});
  }

  fn init_render_pass (self: *Self) !void
  {
    const attachment_desc = [_] vk.AttachmentDescription
                            {
                              vk.AttachmentDescription
                              {
                                .flags            = vk.AttachmentDescriptionFlags {},
                                .format           = self.surface_format.format,
                                .samples          = vk.SampleCountFlags { .@"1_bit" = true },
                                .load_op          = vk.AttachmentLoadOp.clear,
                                .store_op         = vk.AttachmentStoreOp.store,
                                .stencil_load_op  = vk.AttachmentLoadOp.dont_care,
                                .stencil_store_op = vk.AttachmentStoreOp.dont_care,
                                .initial_layout   = vk.ImageLayout.undefined,
                                .final_layout     = vk.ImageLayout.present_src_khr,
                              },
                            };

    const attachment_ref = [_] vk.AttachmentReference
                           {
                             vk.AttachmentReference
                             {
                               .attachment = 0,
                               .layout     = vk.ImageLayout.color_attachment_optimal,
                             },
                           };

    const subpass = [_] vk.SubpassDescription
                    {
                      vk.SubpassDescription
                      {
                        .flags                  = vk.SubpassDescriptionFlags {},
                        .pipeline_bind_point    = vk.PipelineBindPoint.graphics,
                        .color_attachment_count = attachment_ref.len,
                        .p_color_attachments    = &attachment_ref,
                      },
                    };

    const dependency = [_] vk.SubpassDependency
                       {
                         vk.SubpassDependency
                         {
                           .src_subpass     = vk.SUBPASS_EXTERNAL,
                           .dst_subpass     = 0,
                           .src_stage_mask  = vk.PipelineStageFlags { .color_attachment_output_bit = true },
                           .src_access_mask = vk.AccessFlags {},
                           .dst_stage_mask  = vk.PipelineStageFlags { .color_attachment_output_bit = true },
                           .dst_access_mask = vk.AccessFlags {},
                         },
                       };

    const create_info = vk.RenderPassCreateInfo
                        {
                          .flags            = vk.RenderPassCreateFlags {},
                          .attachment_count = attachment_desc.len,
                          .p_attachments    = &attachment_desc,
                          .subpass_count    = subpass.len,
                          .p_subpasses      = &subpass,
                          .dependency_count = dependency.len,
                          .p_dependencies   = &dependency,
                        };

    self.render_pass = try self.device_dispatch.createRenderPass (self.logical_device, &create_info, null);
    errdefer self.device_dispatch.destroyRenderPass (self.logical_device, self.render_pass, null);

    try log_app ("init Vulkan render pass OK", severity.DEBUG, .{});
  }

  fn init_offscreen (self: *Self, allocator: std.mem.Allocator) !void
  {
    const image_create_info = vk.ImageCreateInfo
                              {
                                .image_type     = vk.ImageType.@"2d",
                                .format         = vk.Format.r8g8b8a8_unorm,
                                .extent         = vk.Extent3D
                                                  {
                                                    .width  = self.offscreen_width,
                                                    .height = self.offscreen_height,
                                                    .depth  = 1,
                                                  },
                                .mip_levels     = 1,
                                .array_layers   = 1,
                                .samples        = vk.SampleCountFlags { .@"1_bit" = true, },
                                .tiling         = vk.ImageTiling.optimal,
                                .usage          = vk.ImageUsageFlags
                                                  {
                                                    .color_attachment_bit = true,
                                                    .sampled_bit          = true,
                                                  },
                                .sharing_mode   = vk.SharingMode.exclusive,
                                .initial_layout = vk.ImageLayout.undefined,
                              };

    self.offscreen_image = try self.device_dispatch.createImage (self.logical_device, &image_create_info, null);
    errdefer self.device_dispatch.destroyImage (self.logical_device, self.offscreen_image, null);

    const memory_requirements = self.device_dispatch.getImageMemoryRequirements (self.logical_device, self.offscreen_image);

    const alloc_info = vk.MemoryAllocateInfo
                       {
                         .allocation_size   = memory_requirements.size,
                         .memory_type_index = try self.find_memory_type (memory_requirements.memory_type_bits, vk.MemoryPropertyFlags { .device_local_bit = true, }),
                       };

    self.offscreen_image_memory = try self.device_dispatch.allocateMemory (self.logical_device, &alloc_info, null);
    errdefer self.device_dispatch.freeMemory (self.logical_device, self.offscreen_image_memory, null);

    try self.device_dispatch.bindImageMemory (self.logical_device, self.offscreen_image, self.offscreen_image_memory, 0);

    const view_create_info = vk.ImageViewCreateInfo
                             {
                               .view_type         = vk.ImageViewType.@"2d",
                               .format            = vk.Format.r8g8b8a8_unorm,
                               .subresource_range = vk.ImageSubresourceRange
                                                    {
                                                      .aspect_mask      = vk.ImageAspectFlags { .color_bit = true },
                                                      .base_mip_level   = 0,
                                                      .level_count      = 1,
                                                      .base_array_layer = 0,
                                                      .layer_count      = 1,
                                                    },
                               .image             = self.offscreen_image,
                               .components        = vk.ComponentMapping
                                                    {
                                                      .r = vk.ComponentSwizzle.identity,
                                                      .g = vk.ComponentSwizzle.identity,
                                                      .b = vk.ComponentSwizzle.identity,
                                                      .a = vk.ComponentSwizzle.identity,
                                                    },
                             };

    self.offscreen_views = try allocator.alloc (vk.ImageView, 1);

    self.offscreen_views [0] = try self.device_dispatch.createImageView (self.logical_device, &view_create_info, null);
    errdefer self.device_dispatch.destroyImageView (self.logical_device, self.offscreen_views [0], null);

    const sampler_create_info = vk.SamplerCreateInfo
                                {
                                  .mag_filter               = vk.Filter.linear,
                                  .min_filter               = vk.Filter.linear,
                                  .mipmap_mode              = vk.SamplerMipmapMode.linear,
                                  .address_mode_u           = vk.SamplerAddressMode.clamp_to_border,
                                  .address_mode_v           = vk.SamplerAddressMode.clamp_to_border,
                                  .address_mode_w           = vk.SamplerAddressMode.clamp_to_border,
                                  .mip_lod_bias             = 0,
                                  .anisotropy_enable        = vk.TRUE,
                                  .max_anisotropy           = 1,
                                  .min_lod                  = 0,
                                  .max_lod                  = 1,
                                  .border_color             = vk.BorderColor.float_opaque_black ,
                                  .compare_enable           = vk.FALSE,
                                  .compare_op               = vk.CompareOp.always,
                                  .unnormalized_coordinates = vk.FALSE,
                                };

    self.offscreen_sampler = try self.device_dispatch.createSampler (self.logical_device, &sampler_create_info, null);
    errdefer self.device_dispatch.destroySampler (self.logical_device, self.offscreen_sampler, null);

    const attachment_desc = [_] vk.AttachmentDescription
                            {
                              vk.AttachmentDescription
                              {
                                .flags            = vk.AttachmentDescriptionFlags {},
                                .format           = vk.Format.r8g8b8a8_unorm,
                                .samples          = vk.SampleCountFlags { .@"1_bit" = true },
                                .load_op          = vk.AttachmentLoadOp.clear,
                                .store_op         = vk.AttachmentStoreOp.store,
                                .stencil_load_op  = vk.AttachmentLoadOp.dont_care,
                                .stencil_store_op = vk.AttachmentStoreOp.dont_care,
                                .initial_layout   = vk.ImageLayout.undefined,
                                .final_layout     = vk.ImageLayout.shader_read_only_optimal,
                              },
                            };

    const attachment_ref = [_] vk.AttachmentReference
                           {
                             vk.AttachmentReference
                             {
                               .attachment = 0,
                               .layout     = vk.ImageLayout.color_attachment_optimal,
                             },
                           };

    const subpass = [_] vk.SubpassDescription
                    {
                      vk.SubpassDescription
                      {
                        .flags                  = vk.SubpassDescriptionFlags {},
                        .pipeline_bind_point    = vk.PipelineBindPoint.graphics,
                        .color_attachment_count = attachment_ref.len,
                        .p_color_attachments    = &attachment_ref,
                      },
                    };

    const dependency = [_] vk.SubpassDependency
                       {
                         vk.SubpassDependency
                         {
                           .src_subpass      = vk.SUBPASS_EXTERNAL,
                           .dst_subpass      = 0,
                           .src_stage_mask   = vk.PipelineStageFlags { .fragment_shader_bit = true },
                           .dst_stage_mask   = vk.PipelineStageFlags { .color_attachment_output_bit = true },
                           .src_access_mask  = vk.AccessFlags { .shader_read_bit = true, },
                           .dst_access_mask  = vk.AccessFlags { .color_attachment_write_bit = true},
                           .dependency_flags = vk.DependencyFlags { .by_region_bit = true },
                         },
                         vk.SubpassDependency
                         {
                           .src_subpass      = 0,
                           .dst_subpass      = vk.SUBPASS_EXTERNAL,
                           .src_stage_mask   = vk.PipelineStageFlags { .color_attachment_output_bit = true },
                           .dst_stage_mask   = vk.PipelineStageFlags { .fragment_shader_bit = true },
                           .src_access_mask  = vk.AccessFlags { .color_attachment_write_bit = true},
                           .dst_access_mask  = vk.AccessFlags { .shader_read_bit = true, },
                           .dependency_flags = vk.DependencyFlags { .by_region_bit = true },
                         },
                       };

    const create_info = vk.RenderPassCreateInfo
                        {
                          .flags            = vk.RenderPassCreateFlags {},
                          .attachment_count = attachment_desc.len,
                          .p_attachments    = &attachment_desc,
                          .subpass_count    = subpass.len,
                          .p_subpasses      = &subpass,
                          .dependency_count = dependency.len,
                          .p_dependencies   = &dependency,
                        };

    self.offscreen_render_pass = try self.device_dispatch.createRenderPass (self.logical_device, &create_info, null);
    errdefer self.device_dispatch.destroyRenderPass (self.logical_device, self.offscreen_render_pass, null);

    const framebuffer_create_info = vk.FramebufferCreateInfo
                                    {
                                      .flags            = vk.FramebufferCreateFlags {},
                                      .render_pass      = self.offscreen_render_pass,
                                      .attachment_count = @intCast (self.offscreen_views.len),
                                      .p_attachments    = self.offscreen_views.ptr,
                                      .width            = self.offscreen_width,
                                      .height           = self.offscreen_height,
                                      .layers           = 1,
                                    };

    self.offscreen_framebuffer = try self.device_dispatch.createFramebuffer (self.logical_device, &framebuffer_create_info, null);
    errdefer self.device_dispatch.destroyFramebuffer (self.logical_device, self.offscreen_framebuffer, null);

    try log_app ("init Vulkan offscreen render pass OK", severity.DEBUG, .{});
  }

  fn init_descriptor_set_layout (self: *Self, allocator: std.mem.Allocator) !void
  {
    const ubo_layout_binding = [_] vk.DescriptorSetLayoutBinding
                               {
                                 vk.DescriptorSetLayoutBinding
                                 {
                                   .binding              = 0,
                                   .descriptor_type      = vk.DescriptorType.uniform_buffer,
                                   .descriptor_count     = 1,
                                   .stage_flags          = vk.ShaderStageFlags { .fragment_bit = true, },
                                   .p_immutable_samplers = null,
                                 },
                                 vk.DescriptorSetLayoutBinding
                                 {
                                   .binding              = 1,
                                   .descriptor_type      = vk.DescriptorType.combined_image_sampler,
                                   .descriptor_count     = 1,
                                   .stage_flags          = vk.ShaderStageFlags { .fragment_bit = true, },
                                   .p_immutable_samplers = null,
                                 },
                               };

    const offscreen_ubo_layout_binding = [_] vk.DescriptorSetLayoutBinding
                                         {
                                           vk.DescriptorSetLayoutBinding
                                           {
                                             .binding              = 0,
                                             .descriptor_type      = vk.DescriptorType.uniform_buffer,
                                             .descriptor_count     = 1,
                                             .stage_flags          = vk.ShaderStageFlags { .fragment_bit = true, },
                                             .p_immutable_samplers = null,
                                           },
                                         };

    var create_info = vk.DescriptorSetLayoutCreateInfo
                      {
                        .flags         = vk.DescriptorSetLayoutCreateFlags {},
                        .binding_count = ubo_layout_binding.len,
                        .p_bindings    = &ubo_layout_binding,
                      };

    self.descriptor_set_layout = try allocator.alloc (vk.DescriptorSetLayout, 1);

    self.descriptor_set_layout [0] = try self.device_dispatch.createDescriptorSetLayout (self.logical_device, &create_info, null);
    errdefer self.device_dispatch.destroyDescriptorSetLayout (self.logical_device, self.descriptor_set_layout [0], null);

    create_info.binding_count = offscreen_ubo_layout_binding.len;
    create_info.p_bindings = &offscreen_ubo_layout_binding;

    self.offscreen_descriptor_set_layout = try allocator.alloc (vk.DescriptorSetLayout, 1);

    self.offscreen_descriptor_set_layout [0] = try self.device_dispatch.createDescriptorSetLayout (self.logical_device, &create_info, null);
    errdefer self.device_dispatch.destroyDescriptorSetLayout (self.logical_device, self.offscreen_descriptor_set_layout [0], null);

    try log_app ("init Vulkan descriptor set layout OK", severity.DEBUG, .{});
  }

  fn init_shader_module (self: Self, resource: [] const u8) !vk.ShaderModule
  {
    const create_info = vk.ShaderModuleCreateInfo
                        {
                          .flags     = vk.ShaderModuleCreateFlags {},
                          .code_size = resource.len,
                          .p_code    = @ptrCast (@alignCast (resource.ptr)),
                        };

    return try self.device_dispatch.createShaderModule (self.logical_device, &create_info, null);

  }

  fn init_graphics_pipeline (self: *Self, allocator: std.mem.Allocator) !void
  {
    const vertex = try self.init_shader_module (resources.vert [0..]);
    defer self.device_dispatch.destroyShaderModule (self.logical_device, vertex, null);
    const fragment = try self.init_shader_module (resources.frag [0..]);
    defer self.device_dispatch.destroyShaderModule (self.logical_device, fragment, null);
    const offscreen_fragment = try self.init_shader_module (resources.offscreen_frag [0..]);
    defer self.device_dispatch.destroyShaderModule (self.logical_device, offscreen_fragment, null);

    var shader_stage = [_] vk.PipelineShaderStageCreateInfo
                       {
                         vk.PipelineShaderStageCreateInfo
                         {
                            .flags                 = vk.PipelineShaderStageCreateFlags {},
                            .stage                 = vk.ShaderStageFlags { .vertex_bit = true },
                            .module                = vertex,
                            .p_name                = "main",
                            .p_specialization_info = null,
                          },
                         vk.PipelineShaderStageCreateInfo
                         {
                            .flags                 = vk.PipelineShaderStageCreateFlags {},
                            .stage                 = vk.ShaderStageFlags { .fragment_bit = true },
                            .module                = fragment,
                            .p_name                = "main",
                            .p_specialization_info = null,
                          },
                       };

    const dynamic_states = [_] vk.DynamicState { .viewport, .scissor };

    const dynamic_state = vk.PipelineDynamicStateCreateInfo
                          {
                            .flags               = vk.PipelineDynamicStateCreateFlags {},
                            .dynamic_state_count = dynamic_states.len,
                            .p_dynamic_states    = &dynamic_states,
                          };

    const vertex_input_state = vk.PipelineVertexInputStateCreateInfo
                               {
                                 .flags                              = vk.PipelineVertexInputStateCreateFlags {},
                                 .vertex_binding_description_count   = vertex_vk.binding_description.len,
                                 .p_vertex_binding_descriptions      = &(vertex_vk.binding_description),
                                 .vertex_attribute_description_count = vertex_vk.attribute_description.len,
                                 .p_vertex_attribute_descriptions    = &(vertex_vk.attribute_description),
                               };

    const input_assembly = vk.PipelineInputAssemblyStateCreateInfo
                           {
                             .flags                    = vk.PipelineInputAssemblyStateCreateFlags {},
                             .topology                 = vk.PrimitiveTopology.triangle_list,
                             .primitive_restart_enable = vk.FALSE,
                           };

    self.viewport = [_] vk.Viewport
                    {
                      vk.Viewport
                      {
                        .x         = 0,
                        .y         = 0,
                        .width     = @floatFromInt(self.extent.width),
                        .height    = @floatFromInt(self.extent.height),
                        .min_depth = 0,
                        .max_depth = 1,
                      },
                    };

    self.scissor = [_] vk.Rect2D
                   {
                     vk.Rect2D
                     {
                       .offset = vk.Offset2D { .x = 0, .y = 0 },
                       .extent = self.extent,
                     },
                   };

    const viewport_state = vk.PipelineViewportStateCreateInfo
                           {
                             .flags          = vk.PipelineViewportStateCreateFlags {},
                             .viewport_count = self.viewport.len,
                             .p_viewports    = &(self.viewport),
                             .scissor_count  = self.scissor.len,
                             .p_scissors     = &(self.scissor),
                           };

    const rasterizer = vk.PipelineRasterizationStateCreateInfo
                       {
                         .flags                      = vk.PipelineRasterizationStateCreateFlags {},
                         .depth_clamp_enable         = vk.FALSE,
                         .rasterizer_discard_enable  = vk.FALSE,
                         .polygon_mode               = vk.PolygonMode.fill,
                         .line_width                 = 1,
                         .cull_mode                  = vk.CullModeFlags { .back_bit = true },
                         .front_face                 = vk.FrontFace.clockwise,
                         .depth_bias_enable          = vk.FALSE,
                         .depth_bias_constant_factor = 0,
                         .depth_bias_clamp           = 0,
                         .depth_bias_slope_factor    = 0,
                       };

    const multisampling = vk.PipelineMultisampleStateCreateInfo
                          {
                            .flags                    = vk.PipelineMultisampleStateCreateFlags {},
                            .sample_shading_enable    = vk.FALSE,
                            .rasterization_samples    = vk.SampleCountFlags { .@"1_bit" = true },
                            .min_sample_shading       = 1,
                            .p_sample_mask            = null,
                            .alpha_to_coverage_enable = vk.FALSE,
                            .alpha_to_one_enable      = vk.FALSE,
                          };

    const blend_attachment = [_] vk.PipelineColorBlendAttachmentState
                             {
                               vk.PipelineColorBlendAttachmentState
                               {
                                 .color_write_mask       = vk.ColorComponentFlags
                                                           {
                                                             .r_bit = true,
                                                             .g_bit = true,
                                                             .b_bit = true,
                                                             .a_bit = true,
                                                           },
                                 .blend_enable           = vk.FALSE,
                                 .src_color_blend_factor = vk.BlendFactor.one,
                                 .dst_color_blend_factor = vk.BlendFactor.zero,
                                 .color_blend_op         = vk.BlendOp.add,
                                 .src_alpha_blend_factor = vk.BlendFactor.one,
                                 .dst_alpha_blend_factor = vk.BlendFactor.zero,
                                 .alpha_blend_op         = vk.BlendOp.add,
                               },
                             };

    const blend_state = vk.PipelineColorBlendStateCreateInfo
                        {
                          .flags            = vk.PipelineColorBlendStateCreateFlags {},
                          .logic_op_enable  = vk.FALSE,
                          .logic_op         = vk.LogicOp.copy,
                          .attachment_count = blend_attachment.len,
                          .p_attachments    = &blend_attachment,
                          .blend_constants  = [_] f32 { 0, 0, 0, 0 },
                        };

    var layout_create_info = vk.PipelineLayoutCreateInfo
                             {
                               .flags                     = vk.PipelineLayoutCreateFlags {},
                               .set_layout_count          = @intCast(self.descriptor_set_layout.len),
                               .p_set_layouts             = self.descriptor_set_layout.ptr,
                               .push_constant_range_count = 0,
                               .p_push_constant_ranges    = undefined,
                             };

    self.pipeline_layout = try self.device_dispatch.createPipelineLayout (self.logical_device, &layout_create_info, null);
    errdefer self.device_dispatch.destroyPipelineLayout (self.logical_device, self.pipeline_layout, null);

    layout_create_info.set_layout_count = @intCast (self.offscreen_descriptor_set_layout.len);
    layout_create_info.p_set_layouts = self.offscreen_descriptor_set_layout.ptr;

    self.offscreen_pipeline_layout = try self.device_dispatch.createPipelineLayout (self.logical_device, &layout_create_info, null);
    errdefer self.device_dispatch.destroyPipelineLayout (self.logical_device, self.offscreen_pipeline_layout, null);

    var pipeline_create_info = [_] vk.GraphicsPipelineCreateInfo
                               {
                                 vk.GraphicsPipelineCreateInfo
                                 {
                                   .flags                  = vk.PipelineCreateFlags {},
                                   .stage_count            = shader_stage.len,
                                   .p_stages               = &shader_stage,
                                   .p_vertex_input_state   = &vertex_input_state,
                                   .p_input_assembly_state = &input_assembly,
                                   .p_tessellation_state   = null,
                                   .p_viewport_state       = &viewport_state,
                                   .p_rasterization_state  = &rasterizer,
                                   .p_multisample_state    = &multisampling,
                                   .p_depth_stencil_state  = null,
                                   .p_color_blend_state    = &blend_state,
                                   .p_dynamic_state        = &dynamic_state,
                                   .layout                 = self.pipeline_layout,
                                   .render_pass            = self.render_pass,
                                   .subpass                = 0,
                                   .base_pipeline_handle   = vk.Pipeline.null_handle,
                                   .base_pipeline_index    = -1,
                                 },
                               };

    self.pipelines = try allocator.alloc (vk.Pipeline, 1);

    _ = try self.device_dispatch.createGraphicsPipelines (self.logical_device, vk.PipelineCache.null_handle, pipeline_create_info.len, &pipeline_create_info, null, self.pipelines.ptr);
    errdefer
    {
      var index: u32 = 0;

      while (index < self.pipelines.len)
      {
        self.device_dispatch.destroyPipeline (self.logical_device, self.pipelines [index], null);
        index += 1;
      }
    }

    shader_stage [1].module = offscreen_fragment;
    pipeline_create_info [0].layout = self.offscreen_pipeline_layout;
    pipeline_create_info [0].render_pass = self.offscreen_render_pass;

    self.offscreen_pipelines = try allocator.alloc (vk.Pipeline, 1);

    _ = try self.device_dispatch.createGraphicsPipelines (self.logical_device, vk.PipelineCache.null_handle, pipeline_create_info.len, &pipeline_create_info, null, self.offscreen_pipelines.ptr);
    errdefer
    {
      var index: u32 = 0;

      while (index < self.offscreen_pipelines.len)
      {
        self.device_dispatch.destroyPipeline (self.logical_device, self.offscreen_pipelines [index], null);
        index += 1;
      }
    }

    try log_app ("init Vulkan graphics pipeline OK", severity.DEBUG, .{});
  }

  fn init_framebuffers (self: *Self, allocator: std.mem.Allocator) !void
  {
    self.framebuffers = try allocator.alloc (vk.Framebuffer, self.views.len);

    var index: usize = 0;
    var create_info: vk.FramebufferCreateInfo = undefined;

    for (self.framebuffers) |*framebuffer|
    {
      create_info = vk.FramebufferCreateInfo
                    {
                      .flags            = vk.FramebufferCreateFlags {},
                      .render_pass      = self.render_pass,
                      .attachment_count = 1,
                      .p_attachments    = &[_] vk.ImageView { self.views [index] },
                      .width            = self.extent.width,
                      .height           = self.extent.height,
                      .layers           = 1,
                    };

      framebuffer.* = try self.device_dispatch.createFramebuffer (self.logical_device, &create_info, null);
      errdefer self.device_dispatch.destroyFramebuffer (self.logical_device, framebuffer.*, null);

      index += 1;
    }

    try log_app ("init Vulkan framebuffers OK", severity.DEBUG, .{});
  }

  fn init_command_pools (self: *Self) !void
  {
    const create_info = vk.CommandPoolCreateInfo
                        {
                          .flags              = vk.CommandPoolCreateFlags { .reset_command_buffer_bit = true, },
                          .queue_family_index = self.candidate.graphics_family,
                        };

    self.command_pool = try self.device_dispatch.createCommandPool (self.logical_device, &create_info, null);
    errdefer self.device_dispatch.destroyCommandPool (self.logical_device, self.command_pool, null);

    const buffers_create_info = vk.CommandPoolCreateInfo
                                {
                                  .flags              = vk.CommandPoolCreateFlags { .reset_command_buffer_bit = true, .transient_bit = true, },
                                  .queue_family_index = self.candidate.graphics_family,
                                };

    self.buffers_command_pool = try self.device_dispatch.createCommandPool (self.logical_device, &buffers_create_info, null);
    errdefer self.device_dispatch.destroyCommandPool (self.logical_device, self.buffers_command_pool, null);

    try log_app ("init Vulkan command pools OK", severity.DEBUG, .{});
  }

  fn find_memory_type (self: Self, type_filter: u32, properties: vk.MemoryPropertyFlags) !u32
  {
    const memory_properties = self.instance.dispatch.getPhysicalDeviceMemoryProperties (self.physical_device.?);

    for (memory_properties.memory_types [0..memory_properties.memory_type_count], 0..) |memory_type, index|
    {
      if (type_filter & (@as (u32, 1) << @truncate (index)) != 0 and memory_type.property_flags.contains (properties))
      {
        return @truncate (index);
      }
    }

    return ContextError.NoSuitableMemoryType;
  }

  fn init_buffer (self: Self, size: vk.DeviceSize, usage: vk.BufferUsageFlags, properties: vk.MemoryPropertyFlags, buffer: *vk.Buffer, buffer_memory: *vk.DeviceMemory) !void
  {
    const create_info = vk.BufferCreateInfo
                        {
                          .flags        = vk.BufferCreateFlags {},
                          .size         = size,
                          .usage        = usage,
                          .sharing_mode = vk.SharingMode.exclusive,
                        };

    buffer.* = try self.device_dispatch.createBuffer (self.logical_device, &create_info, null);
    errdefer self.device_dispatch.destroyBuffer (self.logical_device, buffer.*, null);

    const memory_requirements = self.device_dispatch.getBufferMemoryRequirements (self.logical_device, buffer.*);

    const alloc_info = vk.MemoryAllocateInfo
                       {
                         .allocation_size   = memory_requirements.size,
                         .memory_type_index = try self.find_memory_type (memory_requirements.memory_type_bits, properties),
                       };

    // TODO: issue #68
    buffer_memory.* = try self.device_dispatch.allocateMemory (self.logical_device, &alloc_info, null);
    errdefer self.device_dispatch.freeMemory (self.logical_device, buffer_memory.*, null);

    try self.device_dispatch.bindBufferMemory (self.logical_device, buffer.*, buffer_memory.*, 0);
  }

  fn copy_buffer (self: Self, src_buffer: vk.Buffer, dst_buffer: vk.Buffer, size: vk.DeviceSize) !void
  {
    var command_buffer = [_] vk.CommandBuffer
                         {
                           undefined,
                         };

    const alloc_info = vk.CommandBufferAllocateInfo
                       {
                         .command_pool         = self.buffers_command_pool,
                         .level                = vk.CommandBufferLevel.primary,
                         .command_buffer_count = command_buffer.len,
                       };

    try self.device_dispatch.allocateCommandBuffers (self.logical_device, &alloc_info, &command_buffer);
    errdefer self.device_dispatch.freeCommandBuffers (self.logical_device, self.buffers_command_pool, 1, &command_buffer);

    const begin_info = vk.CommandBufferBeginInfo
                       {
                         .flags = vk.CommandBufferUsageFlags { .one_time_submit_bit = true, },
                       };

    try self.device_dispatch.beginCommandBuffer (command_buffer [0], &begin_info);

    const region = [_] vk.BufferCopy
                   {
                     vk.BufferCopy
                     {
                       .src_offset = 0,
                       .dst_offset = 0,
                       .size       = size,
                     },
                   };

    self.device_dispatch.cmdCopyBuffer (command_buffer [0], src_buffer, dst_buffer, 1, &region);
    try self.device_dispatch.endCommandBuffer (command_buffer [0]);

    const submit_info = [_] vk.SubmitInfo
                        {
                          vk.SubmitInfo
                          {
                            .command_buffer_count = command_buffer.len,
                            .p_command_buffers    = &command_buffer,
                          },
                        };

    try self.device_dispatch.queueSubmit (self.graphics_queue, 1, &submit_info, vk.Fence.null_handle);
    try self.device_dispatch.queueWaitIdle (self.graphics_queue);

    self.device_dispatch.freeCommandBuffers (self.logical_device, self.buffers_command_pool, 1, &command_buffer);
  }

  fn init_vertex_buffer (self: *Self) !void
  {
    const size = @sizeOf (@TypeOf (vertices));
    var staging_buffer: vk.Buffer = undefined;
    var staging_buffer_memory: vk.DeviceMemory = undefined;
    try self.init_buffer (size, vk.BufferUsageFlags { .transfer_src_bit = true, }, vk.MemoryPropertyFlags { .host_visible_bit = true, .host_coherent_bit = true, }, &staging_buffer, &staging_buffer_memory);

    const data = try self.device_dispatch.mapMemory (self.logical_device, staging_buffer_memory, 0, size, vk.MemoryMapFlags {});
    @memcpy (@as ([*] u8, @ptrCast (data.?)) [0..size], std.mem.sliceAsBytes (&vertices));
    self.device_dispatch.unmapMemory (self.logical_device, staging_buffer_memory);

    try self.init_buffer (size, vk.BufferUsageFlags { .transfer_dst_bit = true, .vertex_buffer_bit = true, }, vk.MemoryPropertyFlags { .device_local_bit = true, }, &(self.vertex_buffer), &(self.vertex_buffer_memory));

    try self.copy_buffer(staging_buffer, self.vertex_buffer, size);

    self.device_dispatch.destroyBuffer (self.logical_device, staging_buffer, null);
    self.device_dispatch.freeMemory (self.logical_device, staging_buffer_memory, null);

    try log_app ("init Vulkan vertexbuffer OK", severity.DEBUG, .{});
  }

  fn init_index_buffer (self: *Self) !void
  {
    const size = @sizeOf (@TypeOf (indices));
    var staging_buffer: vk.Buffer = undefined;
    var staging_buffer_memory: vk.DeviceMemory = undefined;
    try self.init_buffer (size, vk.BufferUsageFlags { .transfer_src_bit = true, }, vk.MemoryPropertyFlags { .host_visible_bit = true, .host_coherent_bit = true, }, &staging_buffer, &staging_buffer_memory);

    const data = try self.device_dispatch.mapMemory (self.logical_device, staging_buffer_memory, 0, size, vk.MemoryMapFlags {});
    @memcpy (@as ([*] u8, @ptrCast (data.?)) [0..size], std.mem.sliceAsBytes (&indices));
    self.device_dispatch.unmapMemory (self.logical_device, staging_buffer_memory);

    try self.init_buffer (size, vk.BufferUsageFlags { .transfer_dst_bit = true, .index_buffer_bit = true, }, vk.MemoryPropertyFlags { .device_local_bit = true, }, &(self.index_buffer), &(self.index_buffer_memory));

    try self.copy_buffer(staging_buffer, self.index_buffer, size);

    self.device_dispatch.destroyBuffer (self.logical_device, staging_buffer, null);
    self.device_dispatch.freeMemory (self.logical_device, staging_buffer_memory, null);

    try log_app ("init Vulkan indexbuffer OK", severity.DEBUG, .{});
  }

  fn init_uniform_buffers (self: *Self, allocator: std.mem.Allocator) !void
  {
    self.uniform_buffers = try allocator.alloc (vk.Buffer, MAX_FRAMES_IN_FLIGHT);
    self.uniform_buffers_memory = try allocator.alloc (vk.DeviceMemory, MAX_FRAMES_IN_FLIGHT);

    var index: u32 = 0;

    while (index < MAX_FRAMES_IN_FLIGHT)
    {
      try self.init_buffer (@sizeOf (uniform_buffer_object_vk), vk.BufferUsageFlags { .uniform_buffer_bit = true, }, vk.MemoryPropertyFlags { .host_visible_bit = true, .host_coherent_bit = true, }, &(self.uniform_buffers [index]), &(self.uniform_buffers_memory [index]));
      index += 1;
    }

    errdefer
    {
      index = 0;

      while (index < MAX_FRAMES_IN_FLIGHT)
      {
        self.device_dispatch.destroyBuffer (self.logical_device, self.uniform_buffers [index], null);
        self.device_dispatch.freeMemory (self.logical_device, self.uniform_buffers_memory [index], null);
        index += 1;
      }
    }

    try self.init_buffer (@sizeOf (offscreen_uniform_buffer_object_vk), vk.BufferUsageFlags { .uniform_buffer_bit = true, }, vk.MemoryPropertyFlags { .host_visible_bit = true, .host_coherent_bit = true, }, &(self.offscreen_uniform_buffers), &(self.offscreen_uniform_buffers_memory));

    errdefer
    {
      self.device_dispatch.destroyBuffer (self.logical_device, self.offscreen_uniform_buffers, null);
      self.device_dispatch.freeMemory (self.logical_device, self.offscreen_uniform_buffers_memory, null);
    }

    try log_app ("init Vulkan uniform buffers OK", severity.DEBUG, .{});
  }

  fn init_descriptor_pool (self: *Self) !void
  {
    const pool_size = [_] vk.DescriptorPoolSize
                      {
                        vk.DescriptorPoolSize
                        {
                          .type             = vk.DescriptorType.uniform_buffer,
                          .descriptor_count = MAX_FRAMES_IN_FLIGHT * 2,
                        },
                        vk.DescriptorPoolSize
                        {
                          .type             = vk.DescriptorType.combined_image_sampler,
                          .descriptor_count = MAX_FRAMES_IN_FLIGHT + 1,
                        },
                      };

    const create_info = vk.DescriptorPoolCreateInfo
                        {
                          .flags           = vk.DescriptorPoolCreateFlags { .free_descriptor_set_bit = true, },
                          .pool_size_count = pool_size.len,
                          .p_pool_sizes    = &pool_size,
                          .max_sets        = @min (pool_size [0].descriptor_count, pool_size [1].descriptor_count),
                        };

    self.descriptor_pool = try self.device_dispatch.createDescriptorPool (self.logical_device, &create_info, null);
    errdefer self.device_dispatch.destroyDescriptorPool (self.logical_device, self.descriptor_pool, null);

    try log_app ("init Vulkan descriptor pool OK", severity.DEBUG, .{});
  }

  fn init_descriptor_sets (self: *Self, allocator: std.mem.Allocator) !void
  {
    var alloc_info = vk.DescriptorSetAllocateInfo
                     {
                       .descriptor_pool      = self.descriptor_pool,
                       .descriptor_set_count = MAX_FRAMES_IN_FLIGHT,
                       .p_set_layouts        = &[_] vk.DescriptorSetLayout
                                                {
                                                  self.descriptor_set_layout [0],
                                                  self.descriptor_set_layout [0],
                                                },
                     };

    self.descriptor_sets = try allocator.alloc (vk.DescriptorSet, MAX_FRAMES_IN_FLIGHT);

    try self.device_dispatch.allocateDescriptorSets (self.logical_device, &alloc_info, self.descriptor_sets.ptr);

    var index: u32 = 0;
    var buffer_info: [1] vk.DescriptorBufferInfo = undefined;
    var image_info: [1] vk.DescriptorImageInfo = undefined;
    var descriptor_write: [2] vk.WriteDescriptorSet = undefined;

    while (index < MAX_FRAMES_IN_FLIGHT)
    {
      buffer_info = [_] vk.DescriptorBufferInfo
                    {
                      vk.DescriptorBufferInfo
                      {
                        .buffer = self.uniform_buffers [index],
                        .offset = 0,
                        .range  = @sizeOf (uniform_buffer_object_vk),
                      },
                    };

      image_info = [_] vk.DescriptorImageInfo
                   {
                     vk.DescriptorImageInfo
                     {
                       .sampler      = self.offscreen_sampler,
                       .image_view   = self.offscreen_views [0],
                       .image_layout = vk.ImageLayout.shader_read_only_optimal,
                     },
                 };

      descriptor_write = [_] vk.WriteDescriptorSet
                         {
                           vk.WriteDescriptorSet
                           {
                             .dst_set             = self.descriptor_sets [index],
                             .dst_binding         = 0,
                             .dst_array_element   = 0,
                             .descriptor_type     = vk.DescriptorType.uniform_buffer,
                             .descriptor_count    = 1,
                             .p_buffer_info       = &buffer_info,
                             .p_image_info        = undefined,
                             .p_texel_buffer_view = undefined,
                           },
                           vk.WriteDescriptorSet
                           {
                             .dst_set             = self.descriptor_sets [index],
                             .dst_binding         = 1,
                             .dst_array_element   = 0,
                             .descriptor_type     = vk.DescriptorType.combined_image_sampler,
                             .descriptor_count    = 1,
                             .p_buffer_info       = undefined,
                             .p_image_info        = &image_info,
                             .p_texel_buffer_view = undefined,
                           },
                         };

      self.device_dispatch.updateDescriptorSets (self.logical_device, descriptor_write.len, &descriptor_write, 0, undefined);

      index += 1;
    }

    alloc_info.descriptor_set_count = @intCast (self.offscreen_descriptor_set_layout.len);
    alloc_info.p_set_layouts = self.offscreen_descriptor_set_layout.ptr;

    self.offscreen_descriptor_sets = try allocator.alloc (vk.DescriptorSet, 1);

    try self.device_dispatch.allocateDescriptorSets (self.logical_device, &alloc_info, self.offscreen_descriptor_sets.ptr);

    buffer_info = [_] vk.DescriptorBufferInfo
                  {
                    vk.DescriptorBufferInfo
                    {
                      .buffer = self.offscreen_uniform_buffers,
                      .offset = 0,
                      .range  = @sizeOf (offscreen_uniform_buffer_object_vk),
                    },
                  };

    const offscreen_descriptor_write = [_] vk.WriteDescriptorSet
                                       {
                                         vk.WriteDescriptorSet
                                         {
                                           .dst_set             = self.offscreen_descriptor_sets [0],
                                           .dst_binding         = 0,
                                           .dst_array_element   = 0,
                                           .descriptor_type     = vk.DescriptorType.uniform_buffer,
                                           .descriptor_count    = 1,
                                           .p_buffer_info       = &buffer_info,
                                           .p_image_info        = undefined,
                                           .p_texel_buffer_view = undefined,
                                         },
                                       };

    self.device_dispatch.updateDescriptorSets (self.logical_device, offscreen_descriptor_write.len, &offscreen_descriptor_write, 0, undefined);

    try log_app ("init Vulkan descriptor sets OK", severity.DEBUG, .{});
  }

  fn init_command_buffers (self: *Self, allocator: std.mem.Allocator) !void
  {
    self.command_buffers = try allocator.alloc (vk.CommandBuffer, MAX_FRAMES_IN_FLIGHT);

    const alloc_info = vk.CommandBufferAllocateInfo
                       {
                         .command_pool         = self.command_pool,
                         .level                = vk.CommandBufferLevel.primary,
                         .command_buffer_count = MAX_FRAMES_IN_FLIGHT,
                       };

    try self.device_dispatch.allocateCommandBuffers (self.logical_device, &alloc_info, self.command_buffers.ptr);
    errdefer self.device_dispatch.freeCommandBuffers (self.logical_device, self.command_pool, 1, self.command_buffers.ptr);

    try log_app ("init Vulkan command buffer OK", severity.DEBUG, .{});
  }

  fn init_sync_objects (self: *Self, allocator: std.mem.Allocator) !void
  {
    self.image_available_semaphores = try allocator.alloc (vk.Semaphore, MAX_FRAMES_IN_FLIGHT);
    self.render_finished_semaphores = try allocator.alloc (vk.Semaphore, MAX_FRAMES_IN_FLIGHT);
    self.in_flight_fences = try allocator.alloc (vk.Fence, MAX_FRAMES_IN_FLIGHT);

    var index: u32 = 0;

    while (index < MAX_FRAMES_IN_FLIGHT)
    {
      self.image_available_semaphores [index] = try self.device_dispatch.createSemaphore (self.logical_device, &vk.SemaphoreCreateInfo { .flags = vk.SemaphoreCreateFlags {} }, null);
      errdefer self.device_dispatch.destroySemaphore (self.logical_device, self.image_available_semaphores [index], null);
      self.render_finished_semaphores [index] = try self.device_dispatch.createSemaphore (self.logical_device, &vk.SemaphoreCreateInfo { .flags = vk.SemaphoreCreateFlags {} }, null);
      errdefer self.device_dispatch.destroySemaphore (self.logical_device, self.render_finished_semaphores [index], null);
      self.in_flight_fences [index] = try self.device_dispatch.createFence(self.logical_device, &vk.FenceCreateInfo { .flags = vk.FenceCreateFlags { .signaled_bit = true } }, null);
      errdefer self.device_dispatch.destroyFence (self.logical_device, self.in_flight_fences [index], null);
      index += 1;
    }

    try log_app ("init Vulkan semaphores and fence OK", severity.DEBUG, .{});
  }

  pub fn get_surface (self: Self) struct { instance: vk.Instance, surface: vk.SurfaceKHR, success: i32, }
  {
    return .{
              .instance = self.instance.instance,
              .surface  = self.surface,
              .success  = @intFromEnum (vk.Result.success),
            };
  }

  pub fn set_surface (self: *Self, surface: *vk.SurfaceKHR) void
  {
    self.surface = surface.*;
  }

  pub fn init_instance (extensions: *[][*:0] const u8,
    instance_proc_addr: *const fn (?*anyopaque, [*:0] const u8) callconv (.C) ?*const fn () callconv (.C) void,
    allocator: std.mem.Allocator) !Self
  {
    var self = Self { .start_time = try std.time.Instant.now (), };

    self.instance = try instance_vk.init (extensions, instance_proc_addr, allocator);

    try log_app ("init Vulkan instance OK", severity.DEBUG, .{});
    return self;
  }

  pub fn init (self: *Self, imgui: context_imgui, framebuffer: struct { width: u32, height: u32, }, allocator: std.mem.Allocator) !void
  {
    self.offscreen_width  = framebuffer.width;
    self.offscreen_height = framebuffer.height;

    try self.pick_physical_device (allocator);

    try self.init_logical_device ();
    try self.init_swapchain (.{ .width = framebuffer.width, .height = framebuffer.height, }, allocator);

    try self.init_image_views ();
    try self.init_render_pass ();
    try self.init_offscreen (allocator);
    try self.init_descriptor_set_layout (allocator);
    try self.init_graphics_pipeline (allocator);
    try self.init_framebuffers (allocator);

    try self.init_command_pools ();
    try self.init_vertex_buffer ();
    try self.init_index_buffer ();
    try self.init_uniform_buffers (allocator);
    try self.init_descriptor_pool ();
    try self.init_descriptor_sets (allocator);
    try self.init_command_buffers (allocator);
    try self.init_sync_objects (allocator);

    try imgui.init_vk (.{
                          .device_dispatch = self.device_dispatch,
                          .instance        = self.instance.instance,
                          .physical_device = self.physical_device.?,
                          .logical_device  = self.logical_device,
                          .graphics_family = self.candidate.graphics_family,
                          .graphics_queue  = self.graphics_queue,
                          .descriptor_pool = self.descriptor_pool,
                          .render_pass     = self.render_pass,
                          .command_pool    = self.command_pool,
                          .command_buffer  = self.command_buffers [self.current_frame],
                        });

    try log_app ("init Vulkan OK", severity.DEBUG, .{});
  }

  fn record_command_buffer (self: *Self, imgui: *context_imgui, command_buffer: *vk.CommandBuffer, image_index: u32) !void
  {
    try self.device_dispatch.resetCommandBuffer (command_buffer.*, vk.CommandBufferResetFlags {});

    const command_buffer_begin_info = vk.CommandBufferBeginInfo
                                      {
                                        .flags              = vk.CommandBufferUsageFlags {},
                                        .p_inheritance_info = null,
                                      };

    try self.device_dispatch.beginCommandBuffer (command_buffer.*, &command_buffer_begin_info);

    var clear = [_] vk.ClearValue
                {
                  vk.ClearValue
                  {
                    .color = vk.ClearColorValue { .float_32 = [4] f32 { 0, 0, 0, 0 } },
                  }
                };

    var render_pass_begin_info = vk.RenderPassBeginInfo
                                 {
                                   .render_pass       = self.offscreen_render_pass,
                                   .framebuffer       = self.offscreen_framebuffer,
                                   .render_area       = vk.Rect2D
                                                        {
                                                          .offset = vk.Offset2D { .x = 0, .y = 0 },
                                                          .extent = vk.Extent2D
                                                                    {
                                                                      .width  = self.offscreen_width,
                                                                      .height = self.offscreen_height,
                                                                    },
                                                        },
                                   .clear_value_count = clear.len,
                                   .p_clear_values    = &clear,
                                 };

    if (self.render_offscreen)
    {
      self.device_dispatch.cmdBeginRenderPass (command_buffer.*, &render_pass_begin_info, vk.SubpassContents.@"inline");

      const offscreen_viewport = [_] vk.Viewport
                                 {
                                   vk.Viewport
                                   {
                                     .x         = 0,
                                     .y         = 0,
                                     .width     = @floatFromInt(self.offscreen_width),
                                     .height    = @floatFromInt(self.offscreen_height),
                                     .min_depth = 0,
                                     .max_depth = 1,
                                   },
                                 };

      const offscreen_scissor = [_] vk.Rect2D
                                {
                                  vk.Rect2D
                                  {
                                    .offset = vk.Offset2D { .x = 0, .y = 0 },
                                    .extent = vk.Extent2D
                                              {
                                                .width  = self.offscreen_width,
                                                .height = self.offscreen_height,
                                              },
                                  },
                                };

      self.device_dispatch.cmdSetViewport (command_buffer.*, 0, 1, &offscreen_viewport);
      self.device_dispatch.cmdSetScissor (command_buffer.*, 0, 1, &offscreen_scissor);
    }

    const offset = [_] vk.DeviceSize {0};
    self.device_dispatch.cmdBindVertexBuffers (command_buffer.*, 0, 1, &[_] vk.Buffer { self.vertex_buffer }, &offset);

    self.device_dispatch.cmdBindIndexBuffer (command_buffer.*, self.index_buffer, 0, vk.IndexType.uint32);

    if (self.render_offscreen)
    {
      self.device_dispatch.cmdBindDescriptorSets (command_buffer.*, vk.PipelineBindPoint.graphics, self.offscreen_pipeline_layout, 0, 1, self.offscreen_descriptor_sets.ptr, 0, undefined);
      self.device_dispatch.cmdBindPipeline (command_buffer.*, vk.PipelineBindPoint.graphics, self.offscreen_pipelines [0]);

      self.device_dispatch.cmdDrawIndexed (command_buffer.*, indices.len, 1, 0, 0, 0);

      self.device_dispatch.cmdEndRenderPass (command_buffer.*);
    }

    clear [0].color.float_32 [3] = 1;
    render_pass_begin_info.render_pass = self.render_pass;
    render_pass_begin_info.framebuffer = self.framebuffers [image_index];
    render_pass_begin_info.render_area.extent = self.extent;

    self.device_dispatch.cmdBeginRenderPass (command_buffer.*, &render_pass_begin_info, vk.SubpassContents.@"inline");
    self.device_dispatch.cmdBindPipeline (command_buffer.*, vk.PipelineBindPoint.graphics, self.pipelines [0]);

    self.device_dispatch.cmdSetViewport (command_buffer.*, 0, 1, self.viewport [0..].ptr);
    self.device_dispatch.cmdSetScissor (command_buffer.*, 0, 1, self.scissor [0..].ptr);

    self.device_dispatch.cmdBindDescriptorSets (command_buffer.*, vk.PipelineBindPoint.graphics, self.pipeline_layout, 0, 1, &[_] vk.DescriptorSet { self.descriptor_sets [self.current_frame] }, 0, undefined);

    self.device_dispatch.cmdDrawIndexed (command_buffer.*, indices.len, 1, 0, 0, 0);

    try imgui.render (command_buffer.*);

    self.device_dispatch.cmdEndRenderPass (command_buffer.*);

    try self.device_dispatch.endCommandBuffer (command_buffer.*);

    self.render_offscreen = false;
  }

  fn cleanup_swapchain (self: Self) void
  {
    for (self.framebuffers) |framebuffer|
    {
      self.device_dispatch.destroyFramebuffer (self.logical_device, framebuffer, null);
    }

    for (self.views) |image_view|
    {
      self.device_dispatch.destroyImageView (self.logical_device, image_view, null);
    }

    self.device_dispatch.destroySwapchainKHR (self.logical_device, self.swapchain, null);
  }

  fn rebuild_swapchain (self: *Self, framebuffer: struct { width: u32, height: u32, }, arena: *std.heap.ArenaAllocator, allocator: *std.mem.Allocator) !void
  {
    try self.device_dispatch.deviceWaitIdle (self.logical_device);

    self.cleanup_swapchain ();

    arena.deinit ();
    arena.* = std.heap.ArenaAllocator.init (std.heap.page_allocator);
    allocator.* = arena.allocator ();

    try self.query_swapchain_support (self.physical_device.?, allocator.*);
    try self.init_swapchain (.{ .width = framebuffer.width, .height = framebuffer.height, }, allocator.*);

    try self.init_image_views ();
    try self.init_framebuffers (allocator.*);
  }

  fn update_uniform_buffer (self: *Self, options: *opts) !void
  {
    const ubo_size = @sizeOf (uniform_buffer_object_vk);

    const ubo = uniform_buffer_object_vk
                {
                  .time = @as(f32, @floatFromInt ((try std.time.Instant.now ()).since (self.start_time))) / @as(f32, @floatFromInt (std.time.ns_per_s)),
                };

    var data = try self.device_dispatch.mapMemory (self.logical_device, self.uniform_buffers_memory [self.current_frame], 0, ubo_size, vk.MemoryMapFlags {});
    @memcpy (@as ([*] u8, @ptrCast (data.?)) [0..ubo_size], std.mem.asBytes (&ubo));
    self.device_dispatch.unmapMemory (self.logical_device, self.uniform_buffers_memory [self.current_frame]);

    if (self.render_offscreen)
    {
      const oubo_size = @sizeOf (offscreen_uniform_buffer_object_vk);

      const oubo = offscreen_uniform_buffer_object_vk
                   {
                     .seed = options.seed,
                   };

      data = try self.device_dispatch.mapMemory (self.logical_device, self.offscreen_uniform_buffers_memory, 0, oubo_size, vk.MemoryMapFlags {});
      @memcpy (@as ([*] u8, @ptrCast (data.?)) [0..oubo_size], std.mem.asBytes (&oubo));
      self.device_dispatch.unmapMemory (self.logical_device, self.offscreen_uniform_buffers_memory);
    }
  }

  fn draw_frame (self: *Self, imgui: *context_imgui, framebuffer: struct { resized: bool, width: u32, height: u32, }, arena: *std.heap.ArenaAllocator, allocator: *std.mem.Allocator, options: *opts) !void
  {
    _ = try self.device_dispatch.waitForFences (self.logical_device, 1, &[_] vk.Fence { self.in_flight_fences [self.current_frame] }, vk.TRUE, std.math.maxInt (u64));

    const seed_before = options.seed;
    try imgui.prepare (allocator.*, &(self.last_displayed_fps), &(self.fps), .{ .width = framebuffer.width, .height = framebuffer.height, },
                       .{
                          .seed = &(options.seed),
                        });
    self.render_offscreen = self.render_offscreen or (options.seed != seed_before);

    const acquire_result = self.device_dispatch.acquireNextImageKHR (self.logical_device, self.swapchain, std.math.maxInt(u64), self.image_available_semaphores [self.current_frame], vk.Fence.null_handle) catch |err| switch (err)
                           {
                             error.OutOfDateKHR => {
                                                     try self.rebuild_swapchain (.{ .width = framebuffer.width, .height = framebuffer.height, }, arena, allocator);
                                                     return;
                                                   },
                             else               => return err,
                           };

    try self.update_uniform_buffer (options);

    _ = try self.device_dispatch.resetFences (self.logical_device, 1, &[_] vk.Fence { self.in_flight_fences [self.current_frame] });

    if (acquire_result.result != vk.Result.success and acquire_result.result != vk.Result.suboptimal_khr)
    {
      return ContextError.ImageAcquireFailed;
    }

    try self.record_command_buffer (imgui, &(self.command_buffers [self.current_frame]), acquire_result.image_index);

    const wait_stage = [_] vk.PipelineStageFlags
                       {
                         vk.PipelineStageFlags { .color_attachment_output_bit = true },
                       };

    const submit_info = [_] vk.SubmitInfo
                        {
                          vk.SubmitInfo
                          {
                            .wait_semaphore_count   = 1,
                            .p_wait_semaphores      = &[_] vk.Semaphore { self.image_available_semaphores [self.current_frame] },
                            .p_wait_dst_stage_mask  = &wait_stage,
                            .command_buffer_count   = 1,
                            .p_command_buffers      = &[_] vk.CommandBuffer { self.command_buffers [self.current_frame] },
                            .signal_semaphore_count = 1,
                            .p_signal_semaphores    = &[_] vk.Semaphore { self.render_finished_semaphores [self.current_frame] },
                          },
                        };

    try self.device_dispatch.queueSubmit (self.graphics_queue, 1, &submit_info, self.in_flight_fences [self.current_frame]);

    const present_info = vk.PresentInfoKHR
                         {
                           .wait_semaphore_count = 1,
                           .p_wait_semaphores    = &[_] vk.Semaphore { self.render_finished_semaphores [self.current_frame] },
                           .swapchain_count      = 1,
                           .p_swapchains         = &[_] vk.SwapchainKHR { self.swapchain },
                           .p_image_indices      = &[_] u32 { acquire_result.image_index },
                           .p_results            = null,
                         };

    const present_result = self.device_dispatch.queuePresentKHR (self.present_queue, &present_info) catch |err| switch (err)
                           {
                             error.OutOfDateKHR => vk.Result.suboptimal_khr,
                             else               => return err,
                           };

    if (present_result == vk.Result.suboptimal_khr or framebuffer.resized)
    {
      try self.rebuild_swapchain (.{ .width = framebuffer.width, .height = framebuffer.height, }, arena, allocator);
    }

    self.current_frame = (self.current_frame + 1) % MAX_FRAMES_IN_FLIGHT;
  }

  pub fn loop (self: *Self, imgui: *context_imgui, framebuffer: struct { resized: bool, width: u32, height: u32, }, arena: *std.heap.ArenaAllocator, allocator: *std.mem.Allocator, options: *opts) !void
  {
    try self.draw_frame (imgui, .{ .resized = framebuffer.resized, .width = framebuffer.width, .height = framebuffer.height, }, arena, allocator, options);
    try log_app ("loop Vulkan OK", severity.DEBUG, .{});
  }

  pub fn cleanup (self: Self) !void
  {
    try self.device_dispatch.deviceWaitIdle (self.logical_device);

    self.instance.cleanup_imgui ();

    self.cleanup_swapchain ();

    self.device_dispatch.destroyFramebuffer (self.logical_device, self.offscreen_framebuffer, null);

    self.device_dispatch.destroySampler (self.logical_device, self.offscreen_sampler, null);
    self.device_dispatch.destroyImageView (self.logical_device, self.offscreen_views [0], null);
    self.device_dispatch.destroyImage (self.logical_device, self.offscreen_image, null);
    self.device_dispatch.freeMemory (self.logical_device, self.offscreen_image_memory, null);

    var index: u32 = 0;

    while (index < MAX_FRAMES_IN_FLIGHT)
    {
      self.device_dispatch.destroyBuffer (self.logical_device, self.uniform_buffers [index], null);
      self.device_dispatch.freeMemory (self.logical_device, self.uniform_buffers_memory [index], null);
      index += 1;
    }

    self.device_dispatch.destroyBuffer (self.logical_device, self.offscreen_uniform_buffers, null);
    self.device_dispatch.freeMemory (self.logical_device, self.offscreen_uniform_buffers_memory, null);

    self.device_dispatch.destroyDescriptorPool (self.logical_device, self.descriptor_pool, null);

    index = 0;

    while (index < self.descriptor_set_layout.len)
    {
      self.device_dispatch.destroyDescriptorSetLayout (self.logical_device, self.descriptor_set_layout [index], null);
      index += 1;
    }
    self.device_dispatch.destroyDescriptorSetLayout (self.logical_device, self.offscreen_descriptor_set_layout [0], null);

    self.device_dispatch.destroyBuffer (self.logical_device, self.index_buffer, null);
    self.device_dispatch.freeMemory (self.logical_device, self.index_buffer_memory, null);

    self.device_dispatch.destroyBuffer (self.logical_device, self.vertex_buffer, null);
    self.device_dispatch.freeMemory (self.logical_device, self.vertex_buffer_memory, null);

    index = 0;

    while (index < self.pipelines.len)
    {
      self.device_dispatch.destroyPipeline (self.logical_device, self.pipelines [index], null);
      index += 1;
    }
    self.device_dispatch.destroyPipeline (self.logical_device, self.offscreen_pipelines [0], null);

    self.device_dispatch.destroyPipelineLayout (self.logical_device, self.pipeline_layout, null);
    self.device_dispatch.destroyPipelineLayout (self.logical_device, self.offscreen_pipeline_layout, null);
    self.device_dispatch.destroyRenderPass (self.logical_device, self.render_pass, null);
    self.device_dispatch.destroyRenderPass (self.logical_device, self.offscreen_render_pass, null);

    index = 0;

    while (index < MAX_FRAMES_IN_FLIGHT)
    {
      self.device_dispatch.destroyFence (self.logical_device, self.in_flight_fences [index], null);
      self.device_dispatch.destroySemaphore (self.logical_device, self.image_available_semaphores [index], null);
      self.device_dispatch.destroySemaphore (self.logical_device, self.render_finished_semaphores [index], null);
      index += 1;
    }

    self.device_dispatch.destroyCommandPool (self.logical_device, self.command_pool, null);
    self.device_dispatch.destroyCommandPool (self.logical_device, self.buffers_command_pool, null);

    self.device_dispatch.destroyDevice (self.logical_device, null);
    self.instance.dispatch.destroySurfaceKHR (self.instance.instance, self.surface, null);
    try self.instance.cleanup ();

    try log_app ("cleanup Vulkan OK", severity.DEBUG, .{});
  }
};
