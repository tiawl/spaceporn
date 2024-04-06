const std    = @import ("std");
const shader = @import ("shader");
const vk     = @import ("vk");

// TODO: why ?
const datetime = @import ("datetime").datetime;

const ImguiContext = @import ("../imgui/context.zig").Context;
const Tweaker = @import ("../imgui/context.zig").Tweaker;
const ImguiPrepare = ImguiContext.ImguiPrepare;

const Logger = @import ("logger").Logger;

const Options = @import ("../options.zig").Options;

const vertex_vk = @import ("vertex.zig").vertex_vk;

const instance        = @import ("instance");
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

pub const Context = struct
{
  const MAX_FRAMES_IN_FLIGHT: u32 = 2;
  const DEVICE_CRITERIAS: u32 = 4;
  const MAX_DEVICE_SCORE = std.math.pow (u32, 2, DEVICE_CRITERIAS) - 1;

  const vertices = [_] vertex_vk
  {
    vertex_vk { .pos = [_] f32 { -1.0, -1.0, }, },
    vertex_vk { .pos = [_] f32 {  3.0, -1.0, }, },
    vertex_vk { .pos = [_] f32 { -1.0,  3.0, }, },
  };

  const indices = [_] u32 { 0, 1, 2, };

  const required_device_extensions = [_][*:0] const u8
  {
    vk.KHR.SWAPCHAIN,
  };

  const ContextError = error
  {
    NoDevice,
    NoSuitableDevice,
    NoSuitableMemoryType,
    ImageAcquireFailed,
    NoAvailableFilename,
  };

  logger:                           *const Logger = undefined,
  instance:                         instance_vk = undefined,
  surface:                          vk.KHR.Surface = undefined,
  physical_device:                  ?vk.PhysicalDevice = null,
  candidate:                        struct { graphics_family: u32,
                                      present_family: u32,
                                      extensions: std.ArrayList ([*:0] const u8),
                                      blitting_supported: bool, } = undefined,
  logical_device:                   vk.Device = undefined,
  graphics_queue:                   vk.Queue = undefined,
  present_queue:                    vk.Queue = undefined,
  capabilities:                     vk.KHR.Surface.Capabilities = undefined,
  formats:                          [] vk.KHR.Surface.Format = undefined,
  present_modes:                    [] vk.KHR.Present.Mode = undefined,
  surface_format:                   vk.KHR.Surface.Format = undefined,
  extent:                           vk.Extent2D = undefined,
  swapchain:                        vk.KHR.Swapchain = undefined,
  images:                           [] vk.Image = undefined,
  views:                            [] vk.Image.View = undefined,
  viewport:                         [1] vk.Viewport = undefined,
  scissor:                          [1] vk.Rect2D = undefined,
  render_pass:                      vk.RenderPass = undefined,
  descriptor_set_layout:            [] vk.Descriptor.Set.Layout = undefined,
  pipeline_layout:                  vk.Pipeline.Layout = undefined,
  pipelines:                        [] vk.Pipeline = undefined,
  framebuffers:                     [] vk.Framebuffer = undefined,
  command_pool:                     vk.Command.Pool = undefined,
  command_buffers:                  [] vk.Command.Buffer = undefined,
  image_available_semaphores:       [] vk.Semaphore = undefined,
  render_finished_semaphores:       [] vk.Semaphore = undefined,
  in_flight_fences:                 [] vk.Fence = undefined,
  current_frame:                    u32 = 0,
  vertex_buffer:                    vk.Buffer = undefined,
  vertex_buffer_memory:             vk.Device.Memory = undefined,
  buffers_command_pool:             vk.Command.Pool = undefined,
  index_buffer:                     vk.Buffer = undefined,
  index_buffer_memory:              vk.Device.Memory = undefined,
  uniform_buffers:                  [] vk.Buffer = undefined,
  uniform_buffers_memory:           [] vk.Device.Memory = undefined,
  start_time:                       std.time.Instant,
  last_displayed_fps:               ?std.time.Instant = null,
  fps:                              f32 = undefined,
  descriptor_pool:                  vk.Descriptor.Pool = undefined,
  descriptor_sets:                  [] vk.Descriptor.Set = undefined,
  prefered_criterias:               [DEVICE_CRITERIAS - 1] bool = undefined,
  screenshot_frame:                 u32 = std.math.maxInt (u32),
  screenshot_image_index:           u32 = undefined,

  offscreen_width:                  u32 = undefined,
  offscreen_height:                 u32 = undefined,
  offscreen_render_pass:            vk.RenderPass = undefined,
  offscreen_descriptor_set_layout:  [] vk.Descriptor.Set.Layout = undefined,
  offscreen_pipeline_layout:        vk.Pipeline.Layout = undefined,
  offscreen_pipelines:              [] vk.Pipeline = undefined,
  offscreen_framebuffer:            vk.Framebuffer = undefined,
  offscreen_uniform_buffers:        vk.Buffer = undefined,
  offscreen_uniform_buffers_memory: vk.Device.Memory = undefined,
  offscreen_descriptor_sets:        [] vk.Descriptor.Set = undefined,
  offscreen_image:                  vk.Image = undefined,
  offscreen_image_memory:           vk.Device.Memory = undefined,
  offscreen_views:                  [] vk.Image.View = undefined,
  offscreen_sampler:                vk.Sampler = undefined,
  render_offscreen:                 bool = true,

  fn find_queue_families (self: *@This (), device: vk.PhysicalDevice)
    !?struct { graphics_family: u32, present_family: u32, }
  {
    var queue_family_count: u32 = undefined;

    vk.PhysicalDevice.Queue.FamilyProperties.get (device, &queue_family_count,
      null);

    const queue_families = try self.logger.allocator.alloc (
      vk.Queue.FamilyProperties, queue_family_count);

    vk.PhysicalDevice.Queue.FamilyProperties.get (device, &queue_family_count,
      queue_families.ptr);

    var present_family: ?u32 = null;
    var graphics_family: ?u32 = null;

    for (queue_families, 0 ..) |properties, index|
    {
      const family: u32 = @intCast(index);

      if (vk.Queue.Bit.GRAPHICS.contains (properties.queue_flags) and
        try vk.KHR.PhysicalDevice.Surface.Support.get (device, family,
          self.surface) == vk.TRUE)
      {
        graphics_family = family;
        present_family = family;
        break;
      }

      if (graphics_family == null and
        vk.Queue.Bit.GRAPHICS.contains (properties.queue_flags))
          graphics_family = family;

      if (present_family == null and
        try vk.KHR.PhysicalDevice.Surface.Support.get (device, family,
          self.surface) == vk.TRUE) present_family = family;
    }

    if (graphics_family != null and present_family != null)
    {
      try self.logger.app (.DEBUG, "find Vulkan queue families OK", .{});
      return .{ .graphics_family = graphics_family.?,
        .present_family = present_family.?, };
    }

    try self.logger.app (.ERROR, "find Vulkan queue families failed", .{});
    return null;
  }

  fn check_device_extension_support (self: *@This (),
    device: vk.PhysicalDevice,
    name: [vk.MAX_PHYSICAL_DEVICE_NAME_SIZE] u8) !bool
  {
    var supported_device_extensions_count: u32 = undefined;

    try vk.Device.ExtensionProperties.enumerate (device, null,
      &supported_device_extensions_count, null);

    const supported_device_extensions = try self.logger.allocator.alloc (
      vk.ExtensionProperties, supported_device_extensions_count);

    try vk.Device.ExtensionProperties.enumerate (device, null,
      &supported_device_extensions_count, supported_device_extensions.ptr);

    for (required_device_extensions) |required_ext|
    {
      for (supported_device_extensions) |supported_ext|
      {
        if (std.mem.eql (u8, std.mem.span (required_ext),
          supported_ext.extension_name [0 .. std.mem.indexOfScalar (
            u8, &(supported_ext.extension_name), 0).?]))
        {
          try self.logger.app (.DEBUG,
            "Vulkan device {s} supports the {s} required device extension",
              .{ name, required_ext, });
          break;
        }
      } else {
        try self.logger.app (.DEBUG,
          "Vulkan device {s} does not support the {s} required device extension",
            .{ name, required_ext, });
        return false;
      }
    }

    self.candidate.extensions =
      try std.ArrayList ([*:0] const u8).initCapacity (self.logger.allocator.*,
        required_device_extensions.len);

    try self.candidate.extensions.appendSlice (
      required_device_extensions [0 ..]);

    try self.logger.app (.DEBUG,
      "Vulkan device {s} supports all required device extension", .{ name, });
    return true;
  }

  fn query_swapchain_support (self: *@This (), device: vk.PhysicalDevice) !void
  {
    self.capabilities =
      try vk.KHR.PhysicalDevice.Surface.Capabilities.get (device, self.surface);

    var format_count: u32 = undefined;

    try vk.KHR.PhysicalDevice.Surface.Formats.get (
      device, self.surface, &format_count, null);

    if (format_count > 0)
    {
      self.formats = try self.logger.allocator.alloc (
        vk.KHR.Surface.Format, format_count);

      try vk.KHR.PhysicalDevice.Surface.Formats.get (device, self.surface,
        &format_count, self.formats.ptr);
    }

    var present_mode_count: u32 = undefined;

    try vk.KHR.PhysicalDevice.Surface.PresentModes.get (device, self.surface,
      &present_mode_count, null);

    if (present_mode_count > 0)
    {
      self.present_modes = try self.logger.allocator.alloc (
        vk.KHR.Present.Mode, present_mode_count);

      try vk.KHR.PhysicalDevice.Surface.PresentModes.get (device, self.surface,
        &present_mode_count, self.present_modes.ptr);
    }

    try self.logger.app (.DEBUG, "query Vulkan swapchain support OK", .{});
  }

  fn check_device_features_properties (self: @This (),
    features: vk.PhysicalDevice.Features,
    properties: vk.PhysicalDevice.Properties) !bool
  {
    if (features.sampler_anisotropy != vk.TRUE)
    {
      try self.logger.app (.INFO,
        "Vulkan device {s} does not support sampler anisotropy feature",
          .{ properties.device_name, });
      return false;
    }
    try self.logger.app (.DEBUG,
      "Vulkan device {s} supports sampler anisotropy feature",
        .{ properties.device_name, });

    if (properties.limits.max_sampler_anisotropy < 1)
    {
      try self.logger.app (.INFO,
        "Vulkan device {s} does not support a sampler anisotropy value greater than 1",
          .{ properties.device_name, });
      return false;
    }
    try self.logger.app (.DEBUG,
      "Vulkan device {s} supports a sampler anisotropy value greater than 1",
        .{ properties.device_name, });

    if (properties.limits.max_image_dimension_2d < self.offscreen_width)
    {
      try self.logger.app (.INFO,
        "Vulkan device {s} does not support a maximum 2D image size ({d}) greater than offscreen framebuffer width ({d})",
          .{ properties.device_name, properties.limits.max_image_dimension_2d,
             self.offscreen_width, });
      return false;
    }
    try self.logger.app (.DEBUG,
      "Vulkan device {s} supports a maximum 2D image size ({d}) greater than offscreen framebuffer width ({d})",
        .{ properties.device_name, properties.limits.max_image_dimension_2d,
           self.offscreen_width, });

    if (properties.limits.max_image_dimension_2d < self.offscreen_height)
    {
      try self.logger.app (.INFO,
        "Vulkan device {s} does not support a maximum 2D image size ({d}) greater than offscreen framebuffer height ({d})",
          .{ properties.device_name, properties.limits.max_image_dimension_2d,
             self.offscreen_height, });
      return false;
    }
    try self.logger.app (.DEBUG,
      "Vulkan device {s} supports a maximum 2D image size ({d}) greater than offscreen framebuffer height ({d})",
        .{ properties.device_name, properties.limits.max_image_dimension_2d,
           self.offscreen_height, });

    if (properties.limits.max_uniform_buffer_range <
      @sizeOf (uniform_buffer_object_vk))
    {
      try self.logger.app (.INFO,
        "Vulkan device {s} does not support a maximum uniform buffer range ({d}) greater than uniform_buffer_object_vk struct size ({d})",
          .{ properties.device_name,
             properties.limits.max_uniform_buffer_range,
             @sizeOf (uniform_buffer_object_vk), });
      return false;
    }
    try self.logger.app (.DEBUG,
      "Vulkan device {s} supports a maximum uniform buffer range ({d}) greater than uniform_buffer_object_vk struct size ({d})",
        .{ properties.device_name, properties.limits.max_uniform_buffer_range,
           @sizeOf (uniform_buffer_object_vk), });

    if (properties.limits.max_uniform_buffer_range <
      @sizeOf (offscreen_uniform_buffer_object_vk))
    {
      try self.logger.app (.INFO,
        "Vulkan device {s} does not support a maximum uniform buffer range ({d}) greater than offscreen_uniform_buffer_object_vk struct size ({d})",
          .{ properties.device_name,
             properties.limits.max_uniform_buffer_range,
             @sizeOf (offscreen_uniform_buffer_object_vk), });
      return false;
    }
    try self.logger.app (.DEBUG,
      "Vulkan device {s} supports a maximum uniform buffer range ({d}) greater than offscreen_uniform_buffer_object_vk struct size ({d})",
        .{ properties.device_name, properties.limits.max_uniform_buffer_range,
           @sizeOf (offscreen_uniform_buffer_object_vk), });

    if (properties.limits.max_memory_allocation_count < 1)
    {
      try self.logger.app (.INFO,
        "Vulkan device {s} does not support a vkAllocateMemory() call",
          .{ properties.device_name, });
      return false;
    }
    try self.logger.app (.DEBUG,
      "Vulkan device {s} supports until {d} vkAllocateMemory() calls simultaneously",
        .{ properties.device_name,
           properties.limits.max_memory_allocation_count, });

    if (properties.limits.max_sampler_allocation_count < 1)
    {
      try self.logger.app (.INFO,
        "Vulkan device {s} does not support creation of sampler objects",
          .{ properties.device_name, });
      return false;
    }
    try self.logger.app (.DEBUG,
      "Vulkan device {s} supports until {d} sampler objects simultaneously",
        .{ properties.device_name,
           properties.limits.max_sampler_allocation_count, });

    if (properties.limits.max_bound_descriptor_sets < 2)
    {
      try self.logger.app (.INFO,
        "Vulkan device {s} does not support that 2 or more descriptor sets can be simultaneously used",
          .{ properties.device_name, });
      return false;
    }
    try self.logger.app (.DEBUG,
      "Vulkan device {s} supports until {d} descriptor sets used simultaneously",
        .{ properties.device_name,
           properties.limits.max_bound_descriptor_sets, });

    if (properties.limits.max_per_stage_descriptor_samplers < 1)
    {
      try self.logger.app (.INFO,
        "Vulkan device {s} does not support access to a sample object by a single shader stage",
          .{ properties.device_name, });
      return false;
    }
    try self.logger.app (.DEBUG,
      "Vulkan device {s} supports until {d} accessible sample objects by a single shader stage",
        .{ properties.device_name,
           properties.limits.max_per_stage_descriptor_samplers, });

    if (properties.limits.max_per_stage_descriptor_uniform_buffers < 1)
    {
      try self.logger.app (.INFO,
        "Vulkan device {s} does not support access to a uniform buffer by a single shader stage",
          .{ properties.device_name, });
      return false;
    }
    try self.logger.app (.DEBUG,
      "Vulkan device {s} supports until {d} accessible uniform buffers by a single shader stage",
        .{ properties.device_name,
           properties.limits.max_per_stage_descriptor_samplers, });

    if (properties.limits.max_per_stage_descriptor_sampled_images < 1)
    {
      try self.logger.app (.INFO,
        "Vulkan device {s} does not support access to a sampled image by a single shader stage",
          .{ properties.device_name, });
      return false;
    }
    try self.logger.app (.DEBUG,
      "Vulkan device {s} supports until {d} accessible sampled image by a single shader stage",
        .{ properties.device_name,
           properties.limits.max_per_stage_descriptor_sampled_images, });

    if (properties.limits.max_per_stage_resources < 2)
    {
      try self.logger.app (.INFO,
        "Vulkan device {s} does not support access to 2 or more resources by a single shader stage",
          .{ properties.device_name, });
      return false;
    }
    try self.logger.app (.DEBUG,
      "Vulkan device {s} supports until {d} resources by a single shader stage",
        .{ properties.device_name,
           properties.limits.max_per_stage_resources, });

    if (properties.limits.max_descriptor_set_uniform_buffers < 1)
    {
      try self.logger.app (.INFO,
        "Vulkan device {s} does not support inclusion of a uniform buffer in a pipeline layout",
          .{ properties.device_name, });
      return false;
    }
    try self.logger.app (.DEBUG,
      "Vulkan device {s} supports until {d} included uniform buffers in a pipeline layout",
        .{ properties.device_name,
           properties.limits.max_descriptor_set_uniform_buffers, });

    if (properties.limits.max_descriptor_set_samplers < 1)
    {
      try self.logger.app (.INFO,
        "Vulkan device {s} does not support inclusion of a sampler in a pipeline layout",
          .{ properties.device_name, });
      return false;
    }
    try self.logger.app (.DEBUG,
      "Vulkan device {s} supports until {d} included samplers in a pipeline layout",
        .{ properties.device_name,
           properties.limits.max_descriptor_set_samplers, });

    if (properties.limits.max_descriptor_set_sampled_images < 1)
    {
      try self.logger.app (.INFO,
        "Vulkan device {s} does not support inclusion of a sampled image in a pipeline layout",
          .{ properties.device_name, });
      return false;
    }
    try self.logger.app (.DEBUG,
      "Vulkan device {s} supports until {d} included sampled image in a pipeline layout",
        .{ properties.device_name,
           properties.limits.max_descriptor_set_sampled_images, });

    if (properties.limits.max_fragment_input_components < 2)
    {
      try self.logger.app (.INFO,
        "Vulkan device {s} does not support 2 or more components of input variables provided as inputs to the fragment shader stage",
          .{ properties.device_name, });
      return false;
    }
    try self.logger.app (.DEBUG,
      "Vulkan device {s} supports until {d} components of input variables provided as inputs to the fragment shader stage",
        .{ properties.device_name,
           properties.limits.max_fragment_input_components, });

    if (properties.limits.max_viewports < 1)
    {
      try self.logger.app (.INFO,
        "Vulkan device {s} does not support active viewport",
          .{ properties.device_name, });
      return false;
    }
    try self.logger.app (.DEBUG,
      "Vulkan device {s} supports until {d} active viewports",
        .{ properties.device_name, properties.limits.max_viewports, });

    if (properties.limits.max_viewports < 1)
    {
      try self.logger.app (.INFO,
        "Vulkan device {s} does not support active viewport",
          .{ properties.device_name, });
      return false;
    }
    try self.logger.app (.DEBUG,
      "Vulkan device {s} supports until {d} active viewports",
        .{ properties.device_name, properties.limits.max_viewports, });

    if (properties.limits.max_viewport_dimensions [0] < self.offscreen_width)
    {
      try self.logger.app (.INFO,
        "Vulkan device {s} does not support a maximum viewport width ({d}) greater than offscreen framebuffer width ({d})",
          .{ properties.device_name,
             properties.limits.max_viewport_dimensions [0],
             self.offscreen_width});
      return false;
    }
    try self.logger.app (.DEBUG,
      "Vulkan device {s} supports a maximum viewport width ({d}) greater than offscreen framebuffer width ({d})",
        .{ properties.device_name,
           properties.limits.max_viewport_dimensions [0],
           self.offscreen_width});

    if (properties.limits.max_viewport_dimensions [1] < self.offscreen_height)
    {
      try self.logger.app (.INFO,
        "Vulkan device {s} does not support a maximum viewport height ({d}) greater than offscreen framebuffer height ({d})",
        .{ properties.device_name,
           properties.limits.max_viewport_dimensions [1],
           self.offscreen_height});
      return false;
    }
    try self.logger.app (.DEBUG,
      "Vulkan device {s} supports a maximum viewport height ({d}) greater than offscreen framebuffer height ({d})",
        .{ properties.device_name,
           properties.limits.max_viewport_dimensions [1],
           self.offscreen_height});

    if (properties.limits.max_framebuffer_width < self.offscreen_width)
    {
      try self.logger.app (.INFO,
        "Vulkan device {s} does not support a maximum framebuffer width ({d}) greater than offscreen framebuffer width ({d})",
          .{ properties.device_name, properties.limits.max_framebuffer_width,
             self.offscreen_width});
      return false;
    }
    try self.logger.app (.DEBUG,
      "Vulkan device {s} supports a maximum framebuffer width ({d}) greater than offscreen framebuffer width ({d})",
        .{ properties.device_name, properties.limits.max_framebuffer_width,
           self.offscreen_width});

    if (properties.limits.max_framebuffer_height < self.offscreen_height)
    {
      try self.logger.app (.INFO,
        "Vulkan device {s} does not support a maximum framebuffer height ({d}) greater than offscreen framebuffer height ({d})",
          .{ properties.device_name, properties.limits.max_framebuffer_height,
             self.offscreen_height});
      return false;
    }
    try self.logger.app (.DEBUG,
      "Vulkan device {s} supports a maximum framebuffer height ({d}) greater than offscreen framebuffer height ({d})",
        .{ properties.device_name, properties.limits.max_framebuffer_height,
           self.offscreen_height});

    if (properties.limits.max_color_attachments < 1)
    {
      try self.logger.app (.INFO,
        "Vulkan device {s} does not support color attachment used by a subpass in a render pass",
          .{ properties.device_name, });
      return false;
    }
    try self.logger.app (.DEBUG,
      "Vulkan device {s} supports until {d} color attachment used by a subpass in a render pass",
        .{ properties.device_name, properties.limits.max_color_attachments, });

    return true;
  }

  fn compute_score (self: @This ()) u32
  {
    var score: u32 = 1;
    var power: u32 = 1;

    for (self.prefered_criterias) |criteria|
    {
      score += @intFromBool (criteria) *
        std.math.pow (@TypeOf (DEVICE_CRITERIAS), 2, power);
      power += 1;
    }

    return score;
  }

  fn is_suitable (self: *@This (), device: vk.PhysicalDevice)
    !?struct { graphics_family: u32, present_family: u32, score: u32,
      blitting_supported: bool, }
  {
    const properties = vk.PhysicalDevice.Properties.get (device);
    const features = vk.PhysicalDevice.Features.get (device);

    if (!try self.check_device_extension_support (
      device, properties.device_name))
    {
      try self.logger.app (.ERROR, "Vulkan device {s} is not suitable",
        .{ properties.device_name, });
      return null;
    }

    try self.query_swapchain_support (device);

    var selected_format = self.formats [0].format;

    for (self.formats) |supported_format|
    {
      if (selected_format == .B8G8R8A8_UNORM) break;

      if (supported_format.format == .B8G8R8A8_UNORM)
      {
        selected_format = supported_format.format;
      } else if (supported_format.format == .R8G8B8A8_UNORM and
        selected_format != .R8G8B8A8_UNORM) {
          selected_format = supported_format.format;
      } else if (supported_format.format == .A8B8G8R8_UNORM_PACK32 and
        selected_format != .R8G8B8A8_UNORM and
        selected_format != .A8B8G8R8_UNORM_PACK32) {
          selected_format = supported_format.format;
      }
    }

    const blitting_supported = vk.Format.Feature.Bit.BLIT_SRC.contains (
      vk.PhysicalDevice.Format.Properties.get (
        device, selected_format).optimal_tiling_features) and
          vk.Format.Feature.Bit.BLIT_DST.contains (
            vk.PhysicalDevice.Format.Properties.get (
              device, .R8G8B8A8_UNORM).linear_tiling_features);

    if (!try self.check_device_features_properties (features, properties))
    {
      try self.logger.app (.ERROR, "Vulkan device {s} is not suitable",
        .{ properties.device_name, });
      return null;
    }

    if (self.formats.len > 0 and self.present_modes.len > 0)
    {
      if (try self.find_queue_families (device)) |candidate|
      {
        try self.logger.app (.DEBUG, "Vulkan device {s} is suitable",
          .{ properties.device_name, });

        // from the least to the most important
        self.prefered_criterias = [DEVICE_CRITERIAS - 1] bool
        {
          blitting_supported,
          candidate.graphics_family == candidate.present_family,
          properties.device_type == .DISCRETE_GPU,
        };

        return .{
          .graphics_family    = candidate.graphics_family,
          .present_family     = candidate.present_family,
          .score              = self.compute_score (),
          .blitting_supported = blitting_supported,
        };
      }
    }

    try self.logger.app (.ERROR, "Vulkan device {s} is not suitable",
      .{ properties.device_name, });
    return null;
  }

  fn pick_physical_device (self: *@This ()) !void
  {
    var device_count: u32 = undefined;

    try vk.PhysicalDevices.enumerate (self.instance.instance, &device_count,
      null);

    if (device_count == 0) return ContextError.NoDevice;

    const devices = try self.logger.allocator.alloc (vk.PhysicalDevice,
      device_count);
    var max_score: u32 = 0;

    try vk.PhysicalDevices.enumerate (self.instance.instance, &device_count,
      devices.ptr);

    for (devices) |device|
    {
      const candidate = try self.is_suitable (device);
      if (candidate != null and candidate.?.score > max_score)
      {
        self.physical_device              = device;
        self.candidate.graphics_family    = candidate.?.graphics_family;
        self.candidate.present_family     = candidate.?.present_family;
        self.candidate.blitting_supported = candidate.?.blitting_supported;
        max_score                         = candidate.?.score;
      }
      if (max_score == MAX_DEVICE_SCORE) break;
    }

    if (max_score == 0 or self.physical_device == null)
      return ContextError.NoSuitableDevice;

    try self.logger.app (.DEBUG, "pick a {d}/{d} Vulkan physical device OK",
      .{ max_score, MAX_DEVICE_SCORE, });
  }

  fn init_logical_device (self: *@This ()) !void
  {
    const priority = [_] f32 { 1, };
    const queue_create_info = [_] vk.Device.Queue.Create.Info
    {
      .{
         .queue_family_index = self.candidate.graphics_family,
         .queue_count        = 1,
         .p_queue_priorities = &priority,
       }, .{
         .queue_family_index = self.candidate.present_family,
         .queue_count        = 1,
         .p_queue_priorities = &priority,
       },
    };
    const queue_count: u32 = if (self.candidate.graphics_family ==
      self.candidate.present_family) 1 else 2;

    const device_features = vk.PhysicalDevice.Features {
      .sampler_anisotropy = vk.TRUE, };

    const device_create_info = vk.Device.Create.Info
    {
      .p_queue_create_infos       = &queue_create_info,
      .queue_create_info_count    = queue_count,
      .enabled_layer_count        = required_layers.len,
      .pp_enabled_layer_names     = if (required_layers.len > 0)
        @ptrCast (required_layers [0 ..]) else undefined,
      .enabled_extension_count    = @intCast (self.candidate.extensions.items.len),
      .pp_enabled_extension_names = @ptrCast (self.candidate.extensions.items),
      .p_enabled_features         = &device_features,
    };

    self.logical_device = try vk.Device.create (self.physical_device.?,
      &device_create_info);

    try self.logical_device.load ();
    errdefer self.logical_device.destroy ();

    self.graphics_queue = vk.Device.Queue.get (self.logical_device,
      self.candidate.graphics_family, 0);
    self.present_queue = vk.Device.Queue.get (self.logical_device,
      self.candidate.present_family, 0);

    try self.logger.app (.DEBUG, "init Vulkan logical device OK", .{});
  }

  fn choose_swap_support_format (self: *@This ()) void
  {
    for (self.formats) |format|
    {
      if (format.format == .B8G8R8A8_SRGB and
        format.color_space == .SRGB_NONLINEAR) self.surface_format = format;
    }

    self.surface_format = self.formats [0];
  }

  fn choose_swap_present_mode (self: @This ()) vk.KHR.Present.Mode
  {
    for (self.present_modes) |present_mode|
    {
      if (present_mode == .MAILBOX) return present_mode;
    }

    return .FIFO;
  }

  fn choose_swap_extent (self: *@This (),
    framebuffer: struct { width: u32, height: u32, }) void
  {
    if (self.capabilities.current_extent.width != std.math.maxInt (u32))
    {
      self.extent = self.capabilities.current_extent;
    } else {
      self.extent = .{
        .width  = std.math.clamp (framebuffer.width,
          self.capabilities.min_image_extent.width,
          self.capabilities.max_image_extent.width),
        .height = std.math.clamp (framebuffer.height,
          self.capabilities.min_image_extent.height,
          self.capabilities.max_image_extent.height),
      };
    }
  }

  fn init_swapchain_images (self: *@This ()) !void
  {
    var image_count: u32 = undefined;

    try vk.KHR.Swapchain.Images.get (self.logical_device, self.swapchain,
      &image_count, null);

    self.images = try self.logger.allocator.alloc (vk.Image, image_count);
    self.views = try self.logger.allocator.alloc (vk.Image.View, image_count);

    try vk.KHR.Swapchain.Images.get (self.logical_device, self.swapchain,
      &image_count, self.images.ptr);

    try self.logger.app (.DEBUG, "init Vulkan swapchain images OK", .{});
  }

  fn init_swapchain (self: *@This (),
    framebuffer: struct { width: u32, height: u32, }) !void
  {
    self.choose_swap_support_format ();
    const present_mode = self.choose_swap_present_mode ();
    self.choose_swap_extent (.{ .width = framebuffer.width,
      .height = framebuffer.height, });

    var image_count = self.capabilities.min_image_count + 1;

    if (self.capabilities.max_image_count > 0 and
      image_count > self.capabilities.max_image_count)
    {
      image_count = self.capabilities.max_image_count;
    }

    const queue_family_indices = [_] u32 { self.candidate.graphics_family,
      self.candidate.present_family, };

    const create_info = vk.KHR.Swapchain.Create.Info
    {
      .surface                  = self.surface,
      .min_image_count          = image_count,
      .image_format             = self.surface_format.format,
      .image_color_space        = self.surface_format.color_space,
      .image_extent             = self.extent,
      .image_array_layers       = 1,
      .image_usage              =
        @intFromEnum (vk.Image.Usage.Bit.COLOR_ATTACHMENT) |
        @intFromEnum (vk.Image.Usage.Bit.TRANSFER_SRC) |
        @intFromEnum (vk.Image.Usage.Bit.TRANSFER_DST),
      .image_sharing_mode       = if (self.candidate.graphics_family !=
        self.candidate.present_family) .CONCURRENT else .EXCLUSIVE,
      .queue_family_index_count = if (self.candidate.graphics_family !=
        self.candidate.present_family) queue_family_indices.len else 0,
      .p_queue_family_indices   = if (self.candidate.graphics_family !=
        self.candidate.present_family) &queue_family_indices else null,
      .pre_transform            = self.capabilities.current_transform,
      .composite_alpha          =
        @intFromEnum (vk.KHR.CompositeAlpha.Bit.OPAQUE),
      .present_mode             = present_mode,
      .clipped                  = vk.TRUE,
    };

    self.swapchain = try vk.KHR.Swapchain.create (self.logical_device,
      &create_info);
    errdefer self.swapchain.destroy (self.logical_device);

    try self.init_swapchain_images ();

    try self.logger.app (.DEBUG, "init Vulkan swapchain OK", .{});
  }

  fn init_image_views (self: *@This ()) !void
  {
    var create_info: vk.Image.View.Create.Info = undefined;

    for (self.images, 0 ..) |image, index|
    {
      create_info = .{
        .image             = image,
        .view_type         = .@"2D",
        .format            = self.surface_format.format,
        .components        = .{ .r = .IDENTITY, .g = .IDENTITY,
          .b = .IDENTITY, .a = .IDENTITY, },
        .subresource_range = .{
          .aspect_mask      = @intFromEnum (vk.Image.Aspect.Bit.COLOR),
          .base_mip_level   = 0,
          .level_count      = 1,
          .base_array_layer = 0,
          .layer_count      = 1,
        },
      };

      self.views [index] = try vk.Image.View.create (self.logical_device,
        &create_info);
      errdefer self.views [index].destroy (self.logical_device);
    }

    try self.logger.app (.DEBUG, "init Vulkan swapchain image views OK", .{});
  }

  fn init_render_pass (self: *@This ()) !void
  {
    const attachment_desc = [_] vk.Attachment.Description
    {
      .{
         .format           = self.surface_format.format,
         .samples          = @intFromEnum (vk.Sample.Count.Bit.@"1"),
         .load_op          = .CLEAR,
         .store_op         = .STORE,
         .stencil_load_op  = .DONT_CARE,
         .stencil_store_op = .DONT_CARE,
         .initial_layout   = .UNDEFINED,
         .final_layout     = .PRESENT_SRC_KHR,
       },
    };

    const attachment_ref = [_] vk.Attachment.Reference
    {
      .{
         .attachment = 0,
         .layout     = .COLOR_ATTACHMENT_OPTIMAL,
       },
    };

    const subpass = [_] vk.Subpass.Description
    {
      .{
         .pipeline_bind_point    = .GRAPHICS,
         .color_attachment_count = attachment_ref.len,
         .p_color_attachments    = &attachment_ref,
       },
    };

    const dependency = [_] vk.Subpass.Dependency
    {
      .{
         .src_subpass     = vk.SUBPASS_EXTERNAL,
         .dst_subpass     = 0,
         .src_stage_mask  =
           @intFromEnum (vk.Pipeline.Stage.Bit.COLOR_ATTACHMENT_OUTPUT),
         .dst_stage_mask  =
           @intFromEnum (vk.Pipeline.Stage.Bit.COLOR_ATTACHMENT_OUTPUT),
       },
    };

    const create_info = vk.RenderPass.Create.Info
    {
      .attachment_count = attachment_desc.len,
      .p_attachments    = &attachment_desc,
      .subpass_count    = subpass.len,
      .p_subpasses      = &subpass,
      .dependency_count = dependency.len,
      .p_dependencies   = &dependency,
    };

    self.render_pass = try vk.RenderPass.create (self.logical_device,
      &create_info);
    errdefer self.render_pass.destroy (self.logical_device);

    try self.logger.app (.DEBUG, "init Vulkan render pass OK", .{});
  }

  fn find_memory_type (self: @This (), type_filter: u32,
    properties: vk.Memory.Property.Flags) !u32
  {
    const memory_properties = vk.PhysicalDevice.Memory.Properties.get (
      self.physical_device.?);

    for (memory_properties.memory_types [0 .. memory_properties.memory_type_count], 0 ..) |memory_type, index|
    {
      if (type_filter & (@as (u32, 1) << @truncate (index)) != 0 and
        memory_type.property_flags & properties == properties)
      {
        return @truncate (index);
      }
    }

    return ContextError.NoSuitableMemoryType;
  }

  fn init_offscreen (self: *@This ()) !void
  {
    const image_create_info = vk.Image.Create.Info
    {
      .image_type     = .@"2D",
      .format         = .R8G8B8A8_UNORM,
      .extent         = .{ .width  = self.offscreen_width,
        .height = self.offscreen_height, .depth  = 1, },
      .mip_levels     = 1,
      .array_layers   = 1,
      .samples        = @intFromEnum (vk.Sample.Count.Bit.@"1"),
      .tiling         = .OPTIMAL,
      .usage          = @intFromEnum (vk.Image.Usage.Bit.COLOR_ATTACHMENT) |
        @intFromEnum (vk.Image.Usage.Bit.SAMPLED),
      .sharing_mode   = .EXCLUSIVE,
      .initial_layout = .UNDEFINED,
    };

    self.offscreen_image = try vk.Image.create (self.logical_device,
      &image_create_info);
    errdefer self.offscreen_image.destroy (self.logical_device);

    const memory_requirements = vk.Image.Memory.Requirements.get (
      self.logical_device, self.offscreen_image);

    const alloc_info = vk.Memory.Allocate.Info
    {
      .allocation_size   = memory_requirements.size,
      .memory_type_index = try self.find_memory_type (
        memory_requirements.memory_type_bits,
        @intFromEnum (vk.Memory.Property.Bit.DEVICE_LOCAL)),
    };

    self.offscreen_image_memory = try vk.Device.Memory.allocate (
      self.logical_device, &alloc_info);
    errdefer self.offscreen_image_memory.free (self.logical_device);

    try vk.Image.Memory.bind (self.logical_device, self.offscreen_image,
      self.offscreen_image_memory, 0);

    const view_create_info = vk.Image.View.Create.Info
    {
      .view_type         = .@"2D",
      .format            = .R8G8B8A8_UNORM,
      .subresource_range = .{
        .aspect_mask      = @intFromEnum (vk.Image.Aspect.Bit.COLOR),
        .base_mip_level   = 0,
        .level_count      = 1,
        .base_array_layer = 0,
        .layer_count      = 1,
      },
      .image             = self.offscreen_image,
      .components        = .{ .r = .IDENTITY, .g = .IDENTITY, .b = .IDENTITY,
        .a = .IDENTITY, },
    };

    self.offscreen_views = try self.logger.allocator.alloc (vk.Image.View, 1);

    self.offscreen_views [0] = try vk.Image.View.create (self.logical_device,
      &view_create_info);
    errdefer self.offscreen_views [0].destroy (self.logical_device);

    const sampler_create_info = vk.Sampler.Create.Info
    {
      .mag_filter               = .LINEAR,
      .min_filter               = .LINEAR,
      .mipmap_mode              = .LINEAR,
      .address_mode_u           = .CLAMP_TO_BORDER,
      .address_mode_v           = .CLAMP_TO_BORDER,
      .address_mode_w           = .CLAMP_TO_BORDER,
      .mip_lod_bias             = 0,
      .anisotropy_enable        = vk.TRUE,
      .max_anisotropy           = 1,
      .min_lod                  = 0,
      .max_lod                  = 1,
      .border_color             = .FLOAT_OPAQUE_BLACK ,
      .compare_enable           = vk.FALSE,
      .compare_op               = .ALWAYS,
      .unnormalized_coordinates = vk.FALSE,
    };

    self.offscreen_sampler = try vk.Sampler.create (self.logical_device,
      &sampler_create_info);
    errdefer self.offscreen_sampler.destroy (self.logical_device);

    const attachment_desc = [_] vk.Attachment.Description
    {
      .{
         .format           = .R8G8B8A8_UNORM,
         .samples          = @intFromEnum (vk.Sample.Count.Bit.@"1"),
         .load_op          = .CLEAR,
         .store_op         = .STORE,
         .stencil_load_op  = .DONT_CARE,
         .stencil_store_op = .DONT_CARE,
         .initial_layout   = .UNDEFINED,
         .final_layout     = .SHADER_READ_ONLY_OPTIMAL,
       },
    };

    const attachment_ref = [_] vk.Attachment.Reference
    {
      .{
         .attachment = 0,
         .layout     = .COLOR_ATTACHMENT_OPTIMAL,
       },
    };

    const subpass = [_] vk.Subpass.Description
    {
      .{
         .pipeline_bind_point    = .GRAPHICS,
         .color_attachment_count = attachment_ref.len,
         .p_color_attachments    = &attachment_ref,
       },
    };

    const dependency = [_] vk.Subpass.Dependency
    {
      .{
         .src_subpass      = vk.SUBPASS_EXTERNAL,
         .dst_subpass      = 0,
         .src_stage_mask   =
           @intFromEnum (vk.Pipeline.Stage.Bit.FRAGMENT_SHADER),
         .dst_stage_mask   =
           @intFromEnum (vk.Pipeline.Stage.Bit.COLOR_ATTACHMENT_OUTPUT),
         .src_access_mask  = @intFromEnum (vk.Access.Bit.SHADER_READ),
         .dst_access_mask  =
           @intFromEnum (vk.Access.Bit.COLOR_ATTACHMENT_WRITE),
         .dependency_flags = @intFromEnum (vk.Dependency.Bit.BY_REGION),
       },.{
         .src_subpass      = 0,
         .dst_subpass      = vk.SUBPASS_EXTERNAL,
         .src_stage_mask   =
           @intFromEnum (vk.Pipeline.Stage.Bit.COLOR_ATTACHMENT_OUTPUT),
         .dst_stage_mask   =
           @intFromEnum (vk.Pipeline.Stage.Bit.FRAGMENT_SHADER),
         .src_access_mask  =
           @intFromEnum (vk.Access.Bit.COLOR_ATTACHMENT_WRITE),
         .dst_access_mask  = @intFromEnum (vk.Access.Bit.SHADER_READ),
         .dependency_flags = @intFromEnum (vk.Dependency.Bit.BY_REGION),
       },
    };

    const create_info = vk.RenderPass.Create.Info
    {
      .attachment_count = attachment_desc.len,
      .p_attachments    = &attachment_desc,
      .subpass_count    = subpass.len,
      .p_subpasses      = &subpass,
      .dependency_count = dependency.len,
      .p_dependencies   = &dependency,
    };

    self.offscreen_render_pass = try vk.RenderPass.create (self.logical_device,
      &create_info);
    errdefer self.offscreen_render_pass.destroy (self.logical_device);

    const framebuffer_create_info = vk.Framebuffer.Create.Info
    {
      .render_pass      = self.offscreen_render_pass,
      .attachment_count = @intCast (self.offscreen_views.len),
      .p_attachments    = self.offscreen_views.ptr,
      .width            = self.offscreen_width,
      .height           = self.offscreen_height,
      .layers           = 1,
    };

    self.offscreen_framebuffer = try vk.Framebuffer.create (
      self.logical_device, &framebuffer_create_info);
    errdefer self.offscreen_framebuffer.destroy (self.logical_device);

    try self.logger.app (.DEBUG, "init Vulkan offscreen render pass OK", .{});
  }

  fn init_descriptor_set_layout (self: *@This ()) !void
  {
    const ubo_layout_binding = [_] vk.Descriptor.Set.Layout.Binding
    {
      .{
         .binding              = 0,
         .descriptor_type      = .UNIFORM_BUFFER,
         .descriptor_count     = 1,
         .stage_flags          = @intFromEnum (vk.Shader.Stage.Bit.FRAGMENT),
         .p_immutable_samplers = null,
       }, .{
         .binding              = 1,
         .descriptor_type      = .COMBINED_IMAGE_SAMPLER,
         .descriptor_count     = 1,
         .stage_flags          = @intFromEnum (vk.Shader.Stage.Bit.FRAGMENT),
         .p_immutable_samplers = null,
       },
    };

    const offscreen_ubo_layout_binding = [_] vk.Descriptor.Set.Layout.Binding
    {
      .{
         .binding              = 0,
         .descriptor_type      = .UNIFORM_BUFFER,
         .descriptor_count     = 1,
         .stage_flags          = @intFromEnum (vk.Shader.Stage.Bit.FRAGMENT),
         .p_immutable_samplers = null,
       },
    };

    var create_info = vk.Descriptor.Set.Layout.Create.Info
    {
      .binding_count = ubo_layout_binding.len,
      .p_bindings    = &ubo_layout_binding,
    };

    self.descriptor_set_layout = try self.logger.allocator.alloc (
      vk.Descriptor.Set.Layout, 1);

    self.descriptor_set_layout [0] = try vk.Descriptor.Set.Layout.create (
      self.logical_device, &create_info);
    errdefer self.descriptor_set_layout [0].destroy (self.logical_device);

    create_info.binding_count = offscreen_ubo_layout_binding.len;
    create_info.p_bindings = &offscreen_ubo_layout_binding;

    self.offscreen_descriptor_set_layout = try self.logger.allocator.alloc (
      vk.Descriptor.Set.Layout, 1);

    self.offscreen_descriptor_set_layout [0] =
      try vk.Descriptor.Set.Layout.create (self.logical_device, &create_info);
    errdefer self.offscreen_descriptor_set_layout [0].destroy (
      self.logical_device);

    try self.logger.app (.DEBUG, "init Vulkan descriptor set layout OK", .{});
  }

  fn init_shader_module (self: @This (),
    resource: [] const u8) !vk.Shader.Module
  {
    const create_info = vk.Shader.Module.Create.Info
    {
      .code_size = resource.len,
      .p_code    = @ptrCast (@alignCast (resource.ptr)),
    };

    return try vk.Shader.Module.create (self.logical_device, &create_info);
  }

  fn init_graphics_pipeline (self: *@This ()) !void
  {
    const vertex = try self.init_shader_module (shader.main.vert [0 ..]);
    defer vertex.destroy (self.logical_device);
    const fragment = try self.init_shader_module (shader.main.frag [0 ..]);
    defer fragment.destroy (self.logical_device);
    const offscreen_fragment = try self.init_shader_module (
      shader.offscreen.frag [0 ..]);
    defer offscreen_fragment.destroy (self.logical_device);

    var shader_stage = [_] vk.Pipeline.ShaderStage.Create.Info
    {
      .{
         .stage                 = @intFromEnum (vk.Shader.Stage.Bit.VERTEX),
         .module                = vertex,
         .p_name                = "main",
         .p_specialization_info = null,
       }, .{
         .stage                 = @intFromEnum (vk.Shader.Stage.Bit.FRAGMENT),
         .module                = fragment,
         .p_name                = "main",
         .p_specialization_info = null,
       },
    };

    const dynamic_states = [_] vk.DynamicState { .VIEWPORT, .SCISSOR, };

    const dynamic_state = vk.Pipeline.DynamicState.Create.Info
    {
      .dynamic_state_count = dynamic_states.len,
      .p_dynamic_states    = &dynamic_states,
    };

    const vertex_input_state = vk.Pipeline.VertexInputState.Create.Info
    {
      .vertex_binding_description_count   = vertex_vk.binding_description.len,
      .p_vertex_binding_descriptions      = &(vertex_vk.binding_description),
      .vertex_attribute_description_count = vertex_vk.attribute_description.len,
      .p_vertex_attribute_descriptions    = &(vertex_vk.attribute_description),
    };

    const input_assembly = vk.Pipeline.InputAssemblyState.Create.Info
    {
      .topology                 = .TRIANGLE_LIST,
      .primitive_restart_enable = vk.FALSE,
    };

    self.viewport = [_] vk.Viewport
    {
      .{
         .x         = 0,
         .y         = 0,
         .width     = @floatFromInt (self.extent.width),
         .height    = @floatFromInt (self.extent.height),
         .min_depth = 0,
         .max_depth = 1,
       },
    };

    self.scissor = [_] vk.Rect2D
    {
      .{
         .offset = vk.Offset2D { .x = 0, .y = 0, },
         .extent = self.extent,
       },
    };

    const viewport_state = vk.Pipeline.ViewportState.Create.Info
    {
      .viewport_count = self.viewport.len,
      .p_viewports    = &(self.viewport),
      .scissor_count  = self.scissor.len,
      .p_scissors     = &(self.scissor),
    };

    const rasterizer = vk.Pipeline.RasterizationState.Create.Info
    {
      .depth_clamp_enable         = vk.FALSE,
      .rasterizer_discard_enable  = vk.FALSE,
      .polygon_mode               = .FILL,
      .line_width                 = 1,
      .cull_mode                  = @intFromEnum (vk.CullMode.Bit.BACK),
      .front_face                 = .CLOCKWISE,
      .depth_bias_enable          = vk.FALSE,
      .depth_bias_constant_factor = 0,
      .depth_bias_clamp           = 0,
      .depth_bias_slope_factor    = 0,
    };

    const multisampling = vk.Pipeline.MultisampleState.Create.Info
    {
      .sample_shading_enable    = vk.FALSE,
      .rasterization_samples    = @intFromEnum (vk.Sample.Count.Bit.@"1"),
      .min_sample_shading       = 1,
      .p_sample_mask            = null,
      .alpha_to_coverage_enable = vk.FALSE,
      .alpha_to_one_enable      = vk.FALSE,
    };

    const blend_attachment = [_] vk.Pipeline.ColorBlend.AttachmentState
    {
      .{
         .color_write_mask       = @intFromEnum (vk.ColorComponent.Bit.R) |
           @intFromEnum (vk.ColorComponent.Bit.G) |
           @intFromEnum (vk.ColorComponent.Bit.B) |
           @intFromEnum (vk.ColorComponent.Bit.A),
         .blend_enable           = vk.FALSE,
         .src_color_blend_factor = .ONE,
         .dst_color_blend_factor = .ZERO,
         .color_blend_op         = .ADD,
         .src_alpha_blend_factor = .ONE,
         .dst_alpha_blend_factor = .ZERO,
         .alpha_blend_op         = .ADD,
       },
    };

    const blend_state = vk.Pipeline.ColorBlend.State.Create.Info
    {
      .logic_op_enable  = vk.FALSE,
      .logic_op         = .COPY,
      .attachment_count = blend_attachment.len,
      .p_attachments    = &blend_attachment,
      .blend_constants  = [_] f32 { 0, 0, 0, 0, },
    };

    var layout_create_info = vk.Pipeline.Layout.Create.Info
    {
      .set_layout_count          = @intCast (self.descriptor_set_layout.len),
      .p_set_layouts             = self.descriptor_set_layout.ptr,
      .push_constant_range_count = 0,
      .p_push_constant_ranges    = undefined,
    };

    self.pipeline_layout =
      try vk.Pipeline.Layout.create (self.logical_device, &layout_create_info);
    errdefer self.pipeline_layout.destroy (self.logical_device);

    layout_create_info.set_layout_count =
      @intCast (self.offscreen_descriptor_set_layout.len);
    layout_create_info.p_set_layouts =
      self.offscreen_descriptor_set_layout.ptr;

    self.offscreen_pipeline_layout =
      try vk.Pipeline.Layout.create (self.logical_device, &layout_create_info);
    errdefer self.offscreen_pipeline_layout.destroy (self.logical_device);

    var pipeline_create_info = [_] vk.Graphics.Pipeline.Create.Info
    {
      .{
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
         .base_pipeline_handle   = .NULL_HANDLE,
         .base_pipeline_index    = -1,
       },
    };

    self.pipelines = try self.logger.allocator.alloc (vk.Pipeline, 1);

    try vk.Graphics.Pipelines.create (self.logical_device, .NULL_HANDLE,
      pipeline_create_info.len, &pipeline_create_info, self.pipelines.ptr);
    errdefer
    {
      var index: u32 = 0;

      while (index < self.pipelines.len)
      {
        self.pipelines [index].destroy (self.logical_device);
        index += 1;
      }
    }

    shader_stage [1].module = offscreen_fragment;
    pipeline_create_info [0].layout = self.offscreen_pipeline_layout;
    pipeline_create_info [0].render_pass = self.offscreen_render_pass;

    self.offscreen_pipelines = try self.logger.allocator.alloc (vk.Pipeline, 1);

    try vk.Graphics.Pipelines.create (self.logical_device, .NULL_HANDLE,
      pipeline_create_info.len, &pipeline_create_info,
      self.offscreen_pipelines.ptr);
    errdefer
    {
      var index: u32 = 0;

      while (index < self.offscreen_pipelines.len)
      {
        self.offscreen_pipelines [index].destroy (self.logical_device);
        index += 1;
      }
    }

    try self.logger.app (.DEBUG, "init Vulkan graphics pipeline OK", .{});
  }

  fn init_framebuffers (self: *@This ()) !void
  {
    self.framebuffers = try self.logger.allocator.alloc (vk.Framebuffer,
      self.views.len);

    var index: usize = 0;
    var create_info: vk.Framebuffer.Create.Info = undefined;

    for (self.framebuffers) |*framebuffer|
    {
      create_info = .{
        .render_pass      = self.render_pass,
        .attachment_count = 1,
        .p_attachments    = &[_] vk.Image.View { self.views [index], },
        .width            = self.extent.width,
        .height           = self.extent.height,
        .layers           = 1,
      };

      framebuffer.* = try vk.Framebuffer.create (self.logical_device,
        &create_info);
      errdefer framebuffer.destroy (self.logical_device);

      index += 1;
    }

    try self.logger.app (.DEBUG, "init Vulkan framebuffers OK", .{});
  }

  fn init_command_pools (self: *@This ()) !void
  {
    const create_info = vk.Command.Pool.Create.Info
    {
      .flags              =
        @intFromEnum (vk.Command.Pool.Create.Bit.RESET_COMMAND_BUFFER),
      .queue_family_index = self.candidate.graphics_family,
    };

    self.command_pool = try vk.Command.Pool.create (self.logical_device,
      &create_info);
    errdefer self.command_pool.destroy (self.logical_device);

    const buffers_create_info = vk.Command.Pool.Create.Info
    {
      .flags              =
        @intFromEnum (vk.Command.Pool.Create.Bit.RESET_COMMAND_BUFFER) |
        @intFromEnum (vk.Command.Pool.Create.Bit.TRANSIENT),
      .queue_family_index = self.candidate.graphics_family,
    };

    self.buffers_command_pool = try vk.Command.Pool.create (
      self.logical_device, &buffers_create_info);
    errdefer self.buffers_command_pool.destroy (self.logical_device);

    try self.logger.app (.DEBUG, "init Vulkan command pools OK", .{});
  }

  fn init_buffer (self: @This (), size: vk.Device.Size,
    usage: vk.Buffer.Usage.Flags, properties: vk.Memory.Property.Flags,
    buffer: *vk.Buffer, buffer_memory: *vk.Device.Memory) !void
  {
    const create_info = vk.Buffer.Create.Info
    {
      .size         = size,
      .usage        = usage,
      .sharing_mode = .EXCLUSIVE,
    };

    buffer.* = try vk.Buffer.create (self.logical_device, &create_info);
    errdefer buffer.destroy (self.logical_device);

    const memory_requirements = vk.Buffer.Memory.Requirements.get (
      self.logical_device, buffer.*);

    const alloc_info = vk.Memory.Allocate.Info
    {
      .allocation_size   = memory_requirements.size,
      .memory_type_index = try self.find_memory_type (
        memory_requirements.memory_type_bits, properties),
    };

    // TODO: issue #68
    buffer_memory.* = try vk.Device.Memory.allocate (self.logical_device,
      &alloc_info);
    errdefer buffer_memory.free (self.logical_device);

    try vk.Buffer.Memory.bind (self.logical_device, buffer.*,
      buffer_memory.*, 0);
  }

  fn copy_buffer (self: @This (), src_buffer: vk.Buffer, dst_buffer: vk.Buffer,
    size: vk.Device.Size) !void
  {
    var command_buffers = [_] vk.Command.Buffer { undefined, };

    const alloc_info = vk.Command.Buffer.Allocate.Info
    {
      .command_pool         = self.buffers_command_pool,
      .level                = .PRIMARY,
      .command_buffer_count = command_buffers.len,
    };

    try vk.Command.Buffers.allocate (self.logical_device, &alloc_info,
      &command_buffers);
    errdefer vk.Command.Buffers.free (self.logical_device,
      self.buffers_command_pool, 1, &command_buffers);

    const begin_info = vk.Command.Buffer.Begin.Info
    {
      .flags = @intFromEnum (vk.Command.Buffer.Usage.Bit.ONE_TIME_SUBMIT),
    };

    try command_buffers [0].begin (&begin_info);

    const region = [_] vk.Buffer.Copy
    {
      .{
         .src_offset = 0,
         .dst_offset = 0,
         .size       = size,
       },
    };

    command_buffers [0].copy_buffer (src_buffer, dst_buffer, 1, &region);
    try command_buffers [0].end ();

    const submit_info = [_] vk.Submit.Info
    {
      .{
         .command_buffer_count = command_buffers.len,
         .p_command_buffers    = &command_buffers,
       },
    };

    try self.graphics_queue.submit (1, &submit_info, .NULL_HANDLE);
    try self.graphics_queue.waitIdle ();

    vk.Command.Buffers.free (self.logical_device, self.buffers_command_pool,
      1, &command_buffers);
  }

  fn init_vertex_buffer (self: *@This ()) !void
  {
    const size = @sizeOf (@TypeOf (vertices));
    var staging_buffer: vk.Buffer = undefined;
    var staging_buffer_memory: vk.Device.Memory = undefined;

    try self.init_buffer (size,
      @intFromEnum (vk.Buffer.Usage.Bit.TRANSFER_SRC),
      @intFromEnum (vk.Memory.Property.Bit.HOST_VISIBLE) |
      @intFromEnum (vk.Memory.Property.Bit.HOST_COHERENT),
      &staging_buffer, &staging_buffer_memory);

    defer staging_buffer.destroy (self.logical_device);
    defer staging_buffer_memory.free (self.logical_device);

    const data = try staging_buffer_memory.map (
      self.logical_device, 0, size, 0);
    defer staging_buffer_memory.unmap (self.logical_device);

    @memcpy (@as ([*] u8, @ptrCast (data.?)) [0 ..size],
      std.mem.sliceAsBytes (&vertices));

    try self.init_buffer (size,
      @intFromEnum (vk.Buffer.Usage.Bit.TRANSFER_DST) |
      @intFromEnum (vk.Buffer.Usage.Bit.VERTEX_BUFFER),
      @intFromEnum (vk.Memory.Property.Bit.DEVICE_LOCAL),
      &(self.vertex_buffer), &(self.vertex_buffer_memory));

    try self.copy_buffer (staging_buffer, self.vertex_buffer, size);

    try self.logger.app (.DEBUG, "init Vulkan vertexbuffer OK", .{});
  }

  fn init_index_buffer (self: *@This ()) !void
  {
    const size = @sizeOf (@TypeOf (indices));
    var staging_buffer: vk.Buffer = undefined;
    var staging_buffer_memory: vk.Device.Memory = undefined;

    try self.init_buffer (size,
      @intFromEnum (vk.Buffer.Usage.Bit.TRANSFER_SRC),
      @intFromEnum (vk.Memory.Property.Bit.HOST_VISIBLE) |
      @intFromEnum (vk.Memory.Property.Bit.HOST_COHERENT),
      &staging_buffer, &staging_buffer_memory);

    defer staging_buffer.destroy (self.logical_device);
    defer staging_buffer_memory.free (self.logical_device);

    const data = try staging_buffer_memory.map (
      self.logical_device, 0, size, 0);
    defer staging_buffer_memory.unmap (self.logical_device);

    @memcpy (@as ([*] u8, @ptrCast (data.?)) [0 ..size],
      std.mem.sliceAsBytes (&indices));

    try self.init_buffer (size,
      @intFromEnum (vk.Buffer.Usage.Bit.TRANSFER_DST) |
      @intFromEnum (vk.Buffer.Usage.Bit.INDEX_BUFFER),
      @intFromEnum (vk.Memory.Property.Bit.DEVICE_LOCAL),
      &(self.index_buffer), &(self.index_buffer_memory));

    try self.copy_buffer (staging_buffer, self.index_buffer, size);

    try self.logger.app (.DEBUG, "init Vulkan indexbuffer OK", .{});
  }

  fn init_uniform_buffers (self: *@This ()) !void
  {
    self.uniform_buffers = try self.logger.allocator.alloc (vk.Buffer,
      MAX_FRAMES_IN_FLIGHT);
    self.uniform_buffers_memory = try self.logger.allocator.alloc (
      vk.Device.Memory, MAX_FRAMES_IN_FLIGHT);

    var index: u32 = 0;

    while (index < MAX_FRAMES_IN_FLIGHT)
    {
      try self.init_buffer (@sizeOf (uniform_buffer_object_vk),
        @intFromEnum (vk.Buffer.Usage.Bit.UNIFORM_BUFFER),
        @intFromEnum (vk.Memory.Property.Bit.HOST_VISIBLE) |
        @intFromEnum (vk.Memory.Property.Bit.HOST_COHERENT),
        &(self.uniform_buffers [index]),
        &(self.uniform_buffers_memory [index]));
      index += 1;
    }

    errdefer
    {
      index = 0;

      while (index < MAX_FRAMES_IN_FLIGHT)
      {
        self.uniform_buffers [index].destroy (self.logical_device);
        self.uniform_buffers_memory [index].free (self.logical_device);
        index += 1;
      }
    }

    try self.init_buffer (@sizeOf (offscreen_uniform_buffer_object_vk),
      @intFromEnum (vk.Buffer.Usage.Bit.UNIFORM_BUFFER),
      @intFromEnum (vk.Memory.Property.Bit.HOST_VISIBLE) |
      @intFromEnum (vk.Memory.Property.Bit.HOST_COHERENT),
      &(self.offscreen_uniform_buffers),
      &(self.offscreen_uniform_buffers_memory));

    errdefer
    {
      self.offscreen_uniform_buffers.destroy (self.logical_device);
      self.offscreen_uniform_buffers_memory.free (self.logical_device);
    }

    try self.logger.app (.DEBUG, "init Vulkan uniform buffers OK", .{});
  }

  fn init_descriptor_pool (self: *@This ()) !void
  {
    const pool_size = [_] vk.Descriptor.Pool.Size
    {
      .{
         .type             = .UNIFORM_BUFFER,
         .descriptor_count = MAX_FRAMES_IN_FLIGHT * 2,
       }, .{
         .type             = .COMBINED_IMAGE_SAMPLER,
         .descriptor_count = MAX_FRAMES_IN_FLIGHT + 1,
       },
    };

    const create_info = vk.Descriptor.Pool.Create.Info
    {
      .flags           =
        @intFromEnum (vk.Descriptor.Pool.Create.Bit.FREE_DESCRIPTOR_SET),
      .pool_size_count = pool_size.len,
      .p_pool_sizes    = &pool_size,
      .max_sets        =
        @min (pool_size [0].descriptor_count, pool_size [1].descriptor_count),
    };

    self.descriptor_pool = try vk.Descriptor.Pool.create (self.logical_device,
      &create_info);
    errdefer self.descriptor_pool.destroy (self.logical_device);

    try self.logger.app (.DEBUG, "init Vulkan descriptor pool OK", .{});
  }

  fn init_descriptor_sets (self: *@This ()) !void
  {
    var alloc_info = vk.Descriptor.Set.Allocate.Info
    {
      .descriptor_pool      = self.descriptor_pool,
      .descriptor_set_count = MAX_FRAMES_IN_FLIGHT,
      .p_set_layouts        = &[_] vk.Descriptor.Set.Layout
      {
        self.descriptor_set_layout [0],
        self.descriptor_set_layout [0],
      },
    };

    self.descriptor_sets = try self.logger.allocator.alloc (vk.Descriptor.Set,
      MAX_FRAMES_IN_FLIGHT);

    try vk.Descriptor.Sets.allocate (self.logical_device, &alloc_info,
      self.descriptor_sets.ptr);

    var index: u32 = 0;
    var buffer_info: [1] vk.Descriptor.Buffer.Info = undefined;
    var image_info: [1] vk.Descriptor.Image.Info = undefined;
    var descriptor_write: [2] vk.Write.Descriptor.Set = undefined;

    while (index < MAX_FRAMES_IN_FLIGHT)
    {
      buffer_info = [_] vk.Descriptor.Buffer.Info
      {
        .{
           .buffer = self.uniform_buffers [index],
           .offset = 0,
           .range  = @sizeOf (uniform_buffer_object_vk),
         },
      };

      image_info = [_] vk.Descriptor.Image.Info
      {
        .{
           .sampler      = self.offscreen_sampler,
           .image_view   = self.offscreen_views [0],
           .image_layout = .SHADER_READ_ONLY_OPTIMAL,
         },
      };

      descriptor_write = [_] vk.Write.Descriptor.Set
      {
        .{
           .dst_set             = self.descriptor_sets [index],
           .dst_binding         = 0,
           .dst_array_element   = 0,
           .descriptor_type     = .UNIFORM_BUFFER,
           .descriptor_count    = 1,
           .p_buffer_info       = &buffer_info,
           .p_image_info        = undefined,
           .p_texel_buffer_view = undefined,
         }, .{
           .dst_set             = self.descriptor_sets [index],
           .dst_binding         = 1,
           .dst_array_element   = 0,
           .descriptor_type     = .COMBINED_IMAGE_SAMPLER,
           .descriptor_count    = 1,
           .p_buffer_info       = undefined,
           .p_image_info        = &image_info,
           .p_texel_buffer_view = undefined,
         },
      };

      vk.Descriptor.Sets.update (self.logical_device, descriptor_write.len,
        &descriptor_write, 0, undefined);

      index += 1;
    }

    alloc_info.descriptor_set_count =
      @intCast (self.offscreen_descriptor_set_layout.len);
    alloc_info.p_set_layouts = self.offscreen_descriptor_set_layout.ptr;

    self.offscreen_descriptor_sets =
      try self.logger.allocator.alloc (vk.Descriptor.Set, 1);

    try vk.Descriptor.Sets.allocate (self.logical_device, &alloc_info,
      self.offscreen_descriptor_sets.ptr);

    buffer_info = [_] vk.Descriptor.Buffer.Info
    {
      .{
         .buffer = self.offscreen_uniform_buffers,
         .offset = 0,
         .range  = @sizeOf (offscreen_uniform_buffer_object_vk),
       },
    };

    const offscreen_descriptor_write = [_] vk.Write.Descriptor.Set
    {
      .{
         .dst_set             = self.offscreen_descriptor_sets [0],
         .dst_binding         = 0,
         .dst_array_element   = 0,
         .descriptor_type     = .UNIFORM_BUFFER,
         .descriptor_count    = 1,
         .p_buffer_info       = &buffer_info,
         .p_image_info        = undefined,
         .p_texel_buffer_view = undefined,
       },
    };

    vk.Descriptor.Sets.update (self.logical_device,
      offscreen_descriptor_write.len, &offscreen_descriptor_write, 0, undefined);

    try self.logger.app (.DEBUG, "init Vulkan descriptor sets OK", .{});
  }

  fn init_command_buffers (self: *@This ()) !void
  {
    self.command_buffers = try self.logger.allocator.alloc (vk.Command.Buffer,
      MAX_FRAMES_IN_FLIGHT);

    const alloc_info = vk.Command.Buffer.Allocate.Info
    {
      .command_pool         = self.command_pool,
      .level                = .PRIMARY,
      .command_buffer_count = MAX_FRAMES_IN_FLIGHT,
    };

    try vk.Command.Buffers.allocate (self.logical_device, &alloc_info,
      self.command_buffers.ptr);
    errdefer vk.Command.Buffers.free (self.logical_device, self.command_pool,
      1, self.command_buffers.ptr);

    try self.logger.app (.DEBUG, "init Vulkan command buffer OK", .{});
  }

  fn init_sync_objects (self: *@This ()) !void
  {
    self.image_available_semaphores = try self.logger.allocator.alloc (
      vk.Semaphore, MAX_FRAMES_IN_FLIGHT);
    self.render_finished_semaphores = try self.logger.allocator.alloc (
      vk.Semaphore, MAX_FRAMES_IN_FLIGHT);
    self.in_flight_fences = try self.logger.allocator.alloc (
      vk.Fence, MAX_FRAMES_IN_FLIGHT);

    var index: u32 = 0;

    while (index < MAX_FRAMES_IN_FLIGHT)
    {
      self.image_available_semaphores [index] = try vk.Semaphore.create (
        self.logical_device, &vk.Semaphore.Create.Info {});
      errdefer self.image_available_semaphores [index].destroy (
        self.logical_device);
      self.render_finished_semaphores [index] = try vk.Semaphore.create (
        self.logical_device, &vk.Semaphore.Create.Info {});
      errdefer self.render_finished_semaphores [index].destroy (
        self.logical_device);
      self.in_flight_fences [index] = try vk.Fence.create (
        self.logical_device, &vk.Fence.Create.Info {
          .flags = @intFromEnum (vk.Fence.Create.Bit.SIGNALED), });
      errdefer self.in_flight_fences [index].destroy (self.logical_device);
      index += 1;
    }

    try self.logger.app (.DEBUG, "init Vulkan semaphores and fence OK", .{});
  }

  pub fn get_surface (self: @This ())
    struct { instance: vk.Instance, surface: vk.KHR.Surface, }
  {
    return .{ .instance = self.instance.instance, .surface = self.surface, };
  }

  pub fn set_surface (self: *@This (), surface: *vk.KHR.Surface) void
  {
    self.surface = surface.*;
  }

  pub fn init_instance (logger: *const Logger,
    extensions: *[][*:0] const u8) !@This ()
  {
    var self: @This () = .{ .start_time = try std.time.Instant.now (),
      .logger = logger, };

    self.instance = try instance_vk.init (extensions, logger);

    try self.logger.app (.DEBUG, "init Vulkan instance OK", .{});
    return self;
  }

  pub fn init (self: *@This (), imgui: ImguiContext,
    framebuffer: struct { width: u32, height: u32, }) !void
  {
    self.offscreen_width  = framebuffer.width;
    self.offscreen_height = framebuffer.height;

    try self.pick_physical_device ();

    try self.init_logical_device ();
    try self.init_swapchain (.{ .width = framebuffer.width,
      .height = framebuffer.height, });

    try self.init_image_views ();
    try self.init_render_pass ();
    try self.init_offscreen ();
    try self.init_descriptor_set_layout ();
    try self.init_graphics_pipeline ();
    try self.init_framebuffers ();

    try self.init_command_pools ();
    try self.init_vertex_buffer ();
    try self.init_index_buffer ();
    try self.init_uniform_buffers ();
    try self.init_descriptor_pool ();
    try self.init_descriptor_sets ();
    try self.init_command_buffers ();
    try self.init_sync_objects ();

    try imgui.init_vk (.{
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

    try self.logger.app (.DEBUG, "init Vulkan OK", .{});
  }

  fn record_command_buffer (self: *@This (), imgui: *ImguiContext,
    command_buffer: *vk.Command.Buffer, image_index: u32) !void
  {
    try command_buffer.reset (0);

    const command_buffer_begin_info =
      vk.Command.Buffer.Begin.Info { .p_inheritance_info = null, };

    try command_buffer.begin (&command_buffer_begin_info);

    var clear = [_] vk.Clear.Value
    {
      .{
         .color = .{ .float_32 = [4] f32 { 0, 0, 0, 0, }, },
       },
    };

    var render_pass_begin_info = vk.RenderPass.Begin.Info
    {
      .render_pass       = self.offscreen_render_pass,
      .framebuffer       = self.offscreen_framebuffer,
      .render_area       = .{
        .offset = .{ .x = 0, .y = 0, },
        .extent = .{
          .width  = self.offscreen_width,
          .height = self.offscreen_height,
        },
      },
      .clear_value_count = clear.len,
      .p_clear_values    = &clear,
    };

    if (self.render_offscreen)
    {
      command_buffer.begin_render_pass (&render_pass_begin_info, .INLINE);

      const offscreen_viewport = [_] vk.Viewport
      {
        .{
           .x         = 0,
           .y         = 0,
           .width     = @floatFromInt (self.offscreen_width),
           .height    = @floatFromInt (self.offscreen_height),
           .min_depth = 0,
           .max_depth = 1,
         },
      };

      const offscreen_scissor = [_] vk.Rect2D
      {
        .{
           .offset = .{ .x = 0, .y = 0, },
           .extent = .{
             .width  = self.offscreen_width,
             .height = self.offscreen_height,
           },
         },
      };

      command_buffer.set_viewport (0, 1, &offscreen_viewport);
      command_buffer.set_scissor (0, 1, &offscreen_scissor);
    }

    const offset = [_] vk.Device.Size { 0, };
    command_buffer.bind_vertex_buffers (0, 1,
      &[_] vk.Buffer { self.vertex_buffer, }, &offset);

    command_buffer.bind_index_buffer (self.index_buffer, 0, .UINT32);

    if (self.render_offscreen)
    {
      command_buffer.bind_descriptor_sets (.GRAPHICS,
        self.offscreen_pipeline_layout, 0, 1,
        self.offscreen_descriptor_sets.ptr, 0, undefined);
      command_buffer.bind_pipeline (.GRAPHICS, self.offscreen_pipelines [0]);

      command_buffer.draw_indexed (indices.len, 1, 0, 0, 0);

      command_buffer.end_render_pass ();
    }

    clear [0].color.float_32 [3] = 1;
    render_pass_begin_info.render_pass = self.render_pass;
    render_pass_begin_info.framebuffer = self.framebuffers [image_index];
    render_pass_begin_info.render_area.extent = self.extent;

    command_buffer.begin_render_pass (&render_pass_begin_info, .INLINE);
    command_buffer.bind_pipeline (.GRAPHICS, self.pipelines [0]);

    command_buffer.set_viewport (0, 1, self.viewport [0 ..].ptr);
    command_buffer.set_scissor (0, 1, self.scissor [0 ..].ptr);

    command_buffer.bind_descriptor_sets (.GRAPHICS, self.pipeline_layout, 0,
      1, &[_] vk.Descriptor.Set { self.descriptor_sets [self.current_frame], },
      0, undefined);

    command_buffer.draw_indexed (indices.len, 1, 0, 0, 0);

    if (self.screenshot_frame == std.math.maxInt (u32))
      try imgui.render (command_buffer.*);

    command_buffer.end_render_pass ();

    try command_buffer.end ();

    self.render_offscreen = false;
  }

  fn cleanup_swapchain (self: @This ()) void
  {
    for (self.framebuffers) |framebuffer|
      framebuffer.destroy (self.logical_device);

    for (self.views) |image_view| image_view.destroy (self.logical_device);
    self.swapchain.destroy (self.logical_device);
  }

  fn rebuild_swapchain (self: *@This (),
    framebuffer: struct { width: u32, height: u32, },
    arena: *std.heap.ArenaAllocator, allocator: *std.mem.Allocator) !void
  {
    try self.logical_device.waitIdle ();

    self.cleanup_swapchain ();

    // TODO: rework this weird thing:
    arena.deinit ();
    arena.* = std.heap.ArenaAllocator.init (std.heap.page_allocator);
    allocator.* = arena.allocator ();

    try self.query_swapchain_support (self.physical_device.?);
    try self.init_swapchain (.{ .width = framebuffer.width,
      .height = framebuffer.height, });

    try self.init_image_views ();
    try self.init_framebuffers ();
  }

  fn update_uniform_buffer (self: *@This (), options: *Options) !void
  {
    const ubo_size = @sizeOf (uniform_buffer_object_vk);

    const ubo = uniform_buffer_object_vk
    {
      .time = @as (f32,
        @floatFromInt ((try std.time.Instant.now ()).since (self.start_time)))
          / @as (f32, @floatFromInt (std.time.ns_per_s)),
    };

    var data = try self.uniform_buffers_memory [self.current_frame].map (
      self.logical_device, 0, ubo_size, 0);
    defer self.uniform_buffers_memory [self.current_frame].unmap (
      self.logical_device);

    @memcpy (@as ([*] u8, @ptrCast (data.?)) [0 ..ubo_size],
      std.mem.asBytes (&ubo));

    if (self.render_offscreen)
    {
      const oubo_size = @sizeOf (offscreen_uniform_buffer_object_vk);

      const oubo = offscreen_uniform_buffer_object_vk { .seed = options.seed, };

      data = try self.offscreen_uniform_buffers_memory.map (
        self.logical_device, 0, oubo_size, 0);
      defer self.offscreen_uniform_buffers_memory.unmap (self.logical_device);

      @memcpy (@as ([*] u8, @ptrCast (data.?)) [0 ..oubo_size],
        std.mem.asBytes (&oubo));
    }
  }

  fn find_available_file (self: @This (), allocator: std.mem.Allocator,
    dir: std.fs.Dir) ![] const u8
  {
    _ = self;

    const now = datetime.Datetime.now ();
    var iterator =
      std.mem.tokenizeAny (u8, try now.formatISO8601 (allocator, true), ":.+");
    var id: u32 = 0;
    var filename: [] const u8 = undefined;
    var file: std.fs.File = undefined;
    var available = false;
    var date: [] const u8 = "";

    while (iterator.next ()) |token|
    {
      date = try std.fmt.allocPrint (allocator, "{s}{s}-", .{ date, token, });
    }

    while (id < std.math.maxInt (u32))
    {
      filename = try std.fmt.allocPrint (allocator, "{s}{d}", .{ date, id, });
      file = dir.openFile (filename, .{}) catch |err|
      {
        if (err == error.FileNotFound)
        {
          available = true;
          break;
        } else return err;
      };
      file.close ();
      id += 1;
    }

    if (!available) return ContextError.NoAvailableFilename;

    filename = try std.fmt.allocPrint (allocator, "{s}.ppm", .{ filename, });
    return filename;
  }

  fn save_screenshot_to_disk (self: @This (), allocator: std.mem.Allocator,
    framebuffer: struct { width: u32, height: u32, }) !void
  {
    try self.logger.app (.INFO, "generating ...", .{});

    var screenshots_dir =
      std.fs.cwd ().openDir ("screenshots", .{}) catch |err| blk:
    {
      if (err == error.FileNotFound)
      {
        try std.fs.cwd ().makeDir ("screenshots");
        break :blk try std.fs.cwd ().openDir ("screenshots", .{});
      } else return err;
    };
    defer screenshots_dir.close ();

    const filename = try self.find_available_file (allocator, screenshots_dir);
    var file = try screenshots_dir.createFile (filename, .{});
    defer file.close ();

    const image_create_info = vk.Image.Create.Info
    {
      .image_type     = .@"2D",
      .format         = .R8G8B8A8_UNORM,
      .extent         = .{
        .width  = framebuffer.width,
        .height = framebuffer.height,
        .depth  = 1,
      },
      .mip_levels     = 1,
      .array_layers   = 1,
      .samples        = @intFromEnum (vk.Sample.Count.Bit.@"1"),
      .tiling         = .LINEAR,
      .usage          = @intFromEnum (vk.Image.Usage.Bit.TRANSFER_DST),
      .sharing_mode   = .EXCLUSIVE,
      .initial_layout = .UNDEFINED,
    };

    const dst_image = try vk.Image.create (
      self.logical_device, &image_create_info);
    defer dst_image.destroy (self.logical_device);

    const memory_requirements = vk.Image.Memory.Requirements.get (
      self.logical_device, dst_image);

    const alloc_info = vk.Memory.Allocate.Info
    {
      .allocation_size   = memory_requirements.size,
      .memory_type_index = try self.find_memory_type (
        memory_requirements.memory_type_bits,
         @intFromEnum (vk.Memory.Property.Bit.HOST_VISIBLE) |
         @intFromEnum (vk.Memory.Property.Bit.HOST_COHERENT)),
    };

    const dst_image_memory = try vk.Device.Memory.allocate (
      self.logical_device, &alloc_info);
    errdefer dst_image_memory.free (self.logical_device);

    try vk.Image.Memory.bind (
      self.logical_device, dst_image, dst_image_memory, 0);

    var command_buffers = [_] vk.Command.Buffer { undefined, };

    const buffers_alloc_info = vk.Command.Buffer.Allocate.Info
    {
      .command_pool         = self.command_pool,
      .level                = .PRIMARY,
      .command_buffer_count = command_buffers.len,
    };

    try vk.Command.Buffers.allocate (
      self.logical_device, &buffers_alloc_info, &command_buffers);
    errdefer vk.Command.Buffers.free (
      self.logical_device, self.command_pool, 1, &command_buffers);

    const begin_info = vk.Command.Buffer.Begin.Info {};

    try command_buffers [0].begin (&begin_info);

    const dst_image_to_transfer_dst_layout = [_] vk.Image.Memory.Barrier
    {
      .{
         .src_access_mask        = 0,
         .dst_access_mask        = @intFromEnum (vk.Access.Bit.TRANSFER_WRITE),
         .old_layout             = .UNDEFINED,
         .new_layout             = .TRANSFER_DST_OPTIMAL,
         .src_queue_family_index = vk.QUEUE_FAMILY_IGNORED,
         .dst_queue_family_index = vk.QUEUE_FAMILY_IGNORED,
         .image                  = dst_image,
         .subresource_range      = .{
           .aspect_mask      = @intFromEnum (vk.Image.Aspect.Bit.COLOR),
           .base_mip_level   = 0,
           .level_count      = 1,
           .base_array_layer = 0,
           .layer_count      = 1,
         },
       },
    };

    command_buffers [0].pipeline_barrier (
      @intFromEnum (vk.Pipeline.Stage.Bit.TRANSFER),
      @intFromEnum (vk.Pipeline.Stage.Bit.TRANSFER),
      0, 0, null, 0, null, 1, &dst_image_to_transfer_dst_layout);

    const swapchain_image_from_present_to_transfer_src_layout =
    [_] vk.Image.Memory.Barrier
    {
      .{
         .src_access_mask        = @intFromEnum (vk.Access.Bit.MEMORY_READ),
         .dst_access_mask        = @intFromEnum (vk.Access.Bit.TRANSFER_READ),
         .old_layout             = .PRESENT_SRC_KHR,
         .new_layout             = .TRANSFER_SRC_OPTIMAL,
         .src_queue_family_index = vk.QUEUE_FAMILY_IGNORED,
         .dst_queue_family_index = vk.QUEUE_FAMILY_IGNORED,
         .image                  = self.images [self.screenshot_image_index],
         .subresource_range      = .{
           .aspect_mask      = @intFromEnum (vk.Image.Aspect.Bit.COLOR),
           .base_mip_level   = 0,
           .level_count      = 1,
           .base_array_layer = 0,
           .layer_count      = 1,
         },
       },
    };

    command_buffers [0].pipeline_barrier (
      @intFromEnum (vk.Pipeline.Stage.Bit.TRANSFER),
      @intFromEnum (vk.Pipeline.Stage.Bit.TRANSFER),
      0, 0, null, 0, null, 1,
      &swapchain_image_from_present_to_transfer_src_layout);

    if (self.candidate.blitting_supported)
    {
      const blit_size = [2] vk.Offset3D
      {
        .{ .x = 0, .y = 0, .z = 0, },
        .{ .x = @intCast (framebuffer.width),
           .y = @intCast (framebuffer.height), .z = 1, },
      };

      const image_blit_region = [_] vk.Image.Blit
      {
        .{
           .src_subresource = .{
             .aspect_mask      = @intFromEnum (vk.Image.Aspect.Bit.COLOR),
             .base_array_layer = 0,
             .layer_count      = 1,
             .mip_level        = 0,
           },
           .src_offsets     = blit_size,
           .dst_subresource = .{
             .aspect_mask      = @intFromEnum (vk.Image.Aspect.Bit.COLOR),
             .base_array_layer = 0,
             .layer_count      = 1,
             .mip_level        = 0,
           },
           .dst_offsets     = blit_size,
         },
      };

      command_buffers [0].blit_image (self.images [self.screenshot_image_index],
        .TRANSFER_SRC_OPTIMAL, dst_image, .TRANSFER_DST_OPTIMAL, 1,
        &image_blit_region, .NEAREST);
    } else {
      const image_copy_region = [_] vk.Image.Copy
      {
        .{
           .src_subresource = .{
             .aspect_mask      = @intFromEnum (vk.Image.Aspect.Bit.COLOR),
             .base_array_layer = 0,
             .layer_count      = 1,
             .mip_level        = 0,
           },
           .src_offset      = .{ .x = 0, .y = 0, .z = 0, },
           .dst_subresource = .{
             .aspect_mask      = @intFromEnum (vk.Image.Aspect.Bit.COLOR),
             .base_array_layer = 0,
             .layer_count      = 1,
             .mip_level        = 0,
           },
           .dst_offset      = .{ .x = 0, .y = 0, .z = 0, },
           .extent          = .{
             .width  = framebuffer.width,
             .height = framebuffer.height,
             .depth  = 1,
           },
         },
      };

      command_buffers [0].copy_image (self.images [self.screenshot_image_index],
        .TRANSFER_SRC_OPTIMAL, dst_image, .TRANSFER_DST_OPTIMAL, 1,
        &image_copy_region);
    }

    const dst_image_to_general_layout = [_] vk.Image.Memory.Barrier
    {
      .{
         .src_access_mask        = @intFromEnum (vk.Access.Bit.TRANSFER_WRITE),
         .dst_access_mask        = @intFromEnum (vk.Access.Bit.MEMORY_READ),
         .old_layout             = .TRANSFER_DST_OPTIMAL,
         .new_layout             = .GENERAL,
         .src_queue_family_index = vk.QUEUE_FAMILY_IGNORED,
         .dst_queue_family_index = vk.QUEUE_FAMILY_IGNORED,
         .image                  = dst_image,
         .subresource_range      = .{
           .aspect_mask      = @intFromEnum (vk.Image.Aspect.Bit.COLOR),
           .base_mip_level   = 0,
           .level_count      = 1,
           .base_array_layer = 0,
           .layer_count      = 1,
         },
       },
    };

    command_buffers [0].pipeline_barrier (
      @intFromEnum (vk.Pipeline.Stage.Bit.TRANSFER),
      @intFromEnum (vk.Pipeline.Stage.Bit.TRANSFER),
      0, 0, null, 0, null, 1, &dst_image_to_general_layout);

    const swapchain_image_after_blit = [_] vk.Image.Memory.Barrier
    {
      .{
         .src_access_mask        = @intFromEnum (vk.Access.Bit.TRANSFER_READ),
         .dst_access_mask        = @intFromEnum (vk.Access.Bit.MEMORY_READ),
         .old_layout             = .TRANSFER_SRC_OPTIMAL,
         .new_layout             = .PRESENT_SRC_KHR,
         .src_queue_family_index = vk.QUEUE_FAMILY_IGNORED,
         .dst_queue_family_index = vk.QUEUE_FAMILY_IGNORED,
         .image                  = self.images [self.screenshot_image_index],
         .subresource_range      = .{
           .aspect_mask      = @intFromEnum (vk.Image.Aspect.Bit.COLOR),
           .base_mip_level   = 0,
           .level_count      = 1,
           .base_array_layer = 0,
           .layer_count      = 1,
         },
       },
    };

    command_buffers [0].pipeline_barrier (
      @intFromEnum (vk.Pipeline.Stage.Bit.TRANSFER),
      @intFromEnum (vk.Pipeline.Stage.Bit.TRANSFER),
      0, 0, null, 0, null, 1, &swapchain_image_after_blit);

    try command_buffers [0].end ();

    const submit_info = [_] vk.Submit.Info
    {
      .{
         .command_buffer_count   = command_buffers.len,
         .p_command_buffers      = &command_buffers,
       },
    };

    const fence = try vk.Fence.create (self.logical_device,
      &vk.Fence.Create.Info {});
    defer fence.destroy (self.logical_device);

    try self.graphics_queue.submit (1, &submit_info, fence);

    try vk.Fences.waitFor (self.logical_device, 1, &[_] vk.Fence { fence, },
      vk.TRUE, std.math.maxInt (u64));

    const subresource = vk.Image.Subresource
    {
      .aspect_mask = @intFromEnum (vk.Image.Aspect.Bit.COLOR),
      .mip_level   = 0,
      .array_layer = 0,
    };

    const subresource_layout = vk.Image.Subresource.Layout.get (
      self.logical_device, dst_image, &subresource);

    // TODO: change as ([*] u8, ...) depending of blit support + surface format
    var data = @as ([*] u8, @ptrCast ((try dst_image_memory.map (
      self.logical_device, 0, vk.WHOLE_SIZE, 0)).?));
    defer dst_image_memory.unmap (self.logical_device);

    data += subresource_layout.offset;

    // TODO: change 255 depending of blit support + surface format (max: 65_536)
    const header = try std.fmt.allocPrint (allocator, "P6\n{d}\n{d}\n255\n",
      .{ framebuffer.width, framebuffer.height, });
    try file.writeAll (header);

    var x: u32 = 0;
    var y: u32 = 0;
    var color: [] u8 = undefined;

    while (y < framebuffer.height)
    {
      x = 0;
      while (x < framebuffer.width * 4)
      {
        if (self.candidate.blitting_supported)
        {
          color = try std.fmt.allocPrint (allocator, "{c}{c}{c}",
            .{ data [y * framebuffer.width * 4 + x],
               data [y * framebuffer.width * 4 + x + 1],
               data [y * framebuffer.width * 4 + x + 2], });
          try file.writeAll (color);
        //} else {
          // TODO: manage different format when blit is unsupported
          // TODO: error message promoting for issue posting when using unsupported format
        }

        x += 4;
      }

      // TODO: add this line for unsupported blit ?
      // data += subresource_layout.row_pitch;

      y += 1;
    }

    try self.logger.app (.INFO, "screenshot saved into {s}",
      .{ try screenshots_dir.realpathAlloc (allocator, filename), });
  }

  fn draw_frame (self: *@This (), imgui: *ImguiContext,
    framebuffer: struct { resized: bool, width: u32, height: u32, },
    arena: *std.heap.ArenaAllocator, allocator: *std.mem.Allocator,
    options: *Options) !void
  {
    try vk.Fences.waitFor (self.logical_device, 1,
      &[_] vk.Fence { self.in_flight_fences [self.current_frame], }, vk.TRUE,
      std.math.maxInt (u64));

    if (self.screenshot_frame == self.current_frame)
    {
      try self.save_screenshot_to_disk (allocator.*,
        .{ .width  = framebuffer.width, .height = framebuffer.height, });
      self.screenshot_frame = std.math.maxInt (u32);
    }

    var prepare = ImguiPrepare.Nothing;
    if (self.screenshot_frame == std.math.maxInt (u32))
    {
      var tweak_me: Tweaker = .{ .seed = &(options.seed), };
      const seed_before = options.seed;
      prepare = try imgui.prepare (allocator, &(self.last_displayed_fps),
        &(self.fps),
        .{ .width = framebuffer.width, .height = framebuffer.height, },
        &tweak_me);
      self.render_offscreen = self.render_offscreen or
        (options.seed != seed_before);
      if (prepare == .Screenshot) self.screenshot_frame = self.current_frame;
    }

    const image_index = vk.KHR.NextImage.acquire (self.logical_device,
      self.swapchain, std.math.maxInt(u64),
      self.image_available_semaphores [self.current_frame], .NULL_HANDLE)
      catch |err| switch (err)
    {
      error.OutOfDateKHR => {
                              try self.rebuild_swapchain (
                                .{ .width = framebuffer.width,
                                   .height = framebuffer.height, }, arena,
                                     allocator);
                              return;
                            },
      else               => return err,
    };

    try self.update_uniform_buffer (options);

    try vk.Fences.reset (self.logical_device, 1,
      &[_] vk.Fence { self.in_flight_fences [self.current_frame], });

    if (prepare == .Screenshot) self.screenshot_image_index = image_index;
    try self.record_command_buffer (imgui,
      &(self.command_buffers [self.current_frame]), image_index);

    const wait_stage = [_] vk.Pipeline.Stage.Flags
    {
      @intFromEnum (vk.Pipeline.Stage.Bit.COLOR_ATTACHMENT_OUTPUT),
    };

    const submit_info = [_] vk.Submit.Info
    {
      .{
         .wait_semaphore_count   = 1,
         .p_wait_semaphores      = &[_] vk.Semaphore {
            self.image_available_semaphores [self.current_frame], },
         .p_wait_dst_stage_mask  = &wait_stage,
         .command_buffer_count   = 1,
         .p_command_buffers      = &[_] vk.Command.Buffer {
            self.command_buffers [self.current_frame], },
         .signal_semaphore_count = 1,
         .p_signal_semaphores    = &[_] vk.Semaphore {
            self.render_finished_semaphores [self.current_frame], },
       },
    };

    try self.graphics_queue.submit (1, &submit_info,
      self.in_flight_fences [self.current_frame]);

    const present_info = vk.KHR.Present.Info
    {
      .wait_semaphore_count = 1,
      .p_wait_semaphores    = &[_] vk.Semaphore {
        self.render_finished_semaphores [self.current_frame], },
      .swapchain_count      = 1,
      .p_swapchains         = &[_] vk.KHR.Swapchain { self.swapchain, },
      .p_image_indices      = &[_] u32 { image_index, },
      .p_results            = null,
    };

    var present_result_suboptimal_khr = false;
    self.present_queue.presentKHR (&present_info) catch |err| switch (err)
    {
      error.OutOfDateKHR => present_result_suboptimal_khr = true,
      else               => return err,
    };

    if (present_result_suboptimal_khr or framebuffer.resized)
    {
      try self.rebuild_swapchain (
        .{ .width = framebuffer.width, .height = framebuffer.height, },
        arena, allocator);
    }

    self.current_frame = @intFromBool (self.current_frame == 0);
  }

  pub fn loop (self: *@This (), imgui: *ImguiContext,
    framebuffer: struct { resized: bool, width: u32, height: u32, },
    arena: *std.heap.ArenaAllocator, allocator: *std.mem.Allocator,
    options: *Options) !void
  {
    try self.draw_frame (imgui, .{ .resized = framebuffer.resized,
      .width = framebuffer.width, .height = framebuffer.height, }, arena,
      allocator, options);
    try self.logger.app (.DEBUG, "loop Vulkan OK", .{});
  }

  pub fn cleanup (self: @This ()) !void
  {
    try self.logical_device.waitIdle ();

    self.cleanup_swapchain ();

    self.offscreen_framebuffer.destroy (self.logical_device);

    self.offscreen_sampler.destroy (self.logical_device);
    self.offscreen_views [0].destroy (self.logical_device);
    self.offscreen_image.destroy (self.logical_device);
    self.offscreen_image_memory.free (self.logical_device);

    var index: u32 = 0;

    while (index < MAX_FRAMES_IN_FLIGHT)
    {
      self.uniform_buffers [index].destroy (self.logical_device);
      self.uniform_buffers_memory [index].free (self.logical_device);
      index += 1;
    }

    self.offscreen_uniform_buffers.destroy (self.logical_device);
    self.offscreen_uniform_buffers_memory.free (self.logical_device);

    self.descriptor_pool.destroy (self.logical_device);

    index = 0;

    while (index < self.descriptor_set_layout.len)
    {
      self.descriptor_set_layout [index].destroy (self.logical_device);
      index += 1;
    }
    self.offscreen_descriptor_set_layout [0].destroy (self.logical_device);

    self.index_buffer.destroy (self.logical_device);
    self.index_buffer_memory.free (self.logical_device);

    self.vertex_buffer.destroy (self.logical_device);
    self.vertex_buffer_memory.free (self.logical_device);

    index = 0;

    while (index < self.pipelines.len)
    {
      self.pipelines [index].destroy (self.logical_device);
      index += 1;
    }
    self.offscreen_pipelines [0].destroy (self.logical_device);

    self.pipeline_layout.destroy (self.logical_device);
    self.offscreen_pipeline_layout.destroy (self.logical_device);
    self.render_pass.destroy (self.logical_device);
    self.offscreen_render_pass.destroy (self.logical_device);

    index = 0;

    while (index < MAX_FRAMES_IN_FLIGHT)
    {
      self.in_flight_fences [index].destroy (self.logical_device);
      self.image_available_semaphores [index].destroy (self.logical_device);
      self.render_finished_semaphores [index].destroy (self.logical_device);
      index += 1;
    }

    self.command_pool.destroy (self.logical_device);
    self.buffers_command_pool.destroy (self.logical_device);

    self.logical_device.destroy ();
    self.surface.destroy (self.instance.instance);
    try self.instance.cleanup ();

    try self.logger.app (.DEBUG, "cleanup Vulkan OK", .{});
  }
};
