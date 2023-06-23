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
  views:              [] vk.ImageView,
  viewport:           [1] vk.Viewport,
  scissor:            [1] vk.Rect2D,
  render_pass:        vk.RenderPass,
  pipeline_layout:    vk.PipelineLayout,
  pipeline:           vk.Pipeline,
  framebuffers:       [] vk.Framebuffer,
  command_pool:       vk.CommandPool,
  command_buffer:     vk.CommandBuffer,

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

    self.views = try self.allocator.alloc (vk.ImageView, image_count);
    errdefer self.allocator.free (self.views);

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

      self.views [index] = try self.device_dispatch.createImageView (self.logical_device, &create_info, null);
      errdefer self.device_dispatch.destroyImageView (self.logical_device, self.views [index], null);
    }

    try log_app ("Init Vulkan Swapchain Image Views OK", severity.DEBUG, .{});
  }

  fn init_render_pass (self: *Self) !void
  {
    const attachment_desc = vk.AttachmentDescription
                            {
                              .flags            = .{},
                              .format           = self.surface_format.format,
                              .samples          = .{ .@"1_bit" = true },
                              .load_op          = .clear,
                              .store_op         = .store,
                              .stencil_load_op  = .dont_care,
                              .stencil_store_op = .dont_care,
                              .initial_layout   = .undefined,
                              .final_layout     = .present_src_khr,
                            };

    const attachment_ref = vk.AttachmentReference
                           {
                             .attachment = 0,
                             .layout     = .color_attachment_optimal,
                           };

    const subpass = vk.SubpassDescription
                    {
                      .flags                  = .{},
                      .pipeline_bind_point    = .graphics,
                      .color_attachment_count = 1,
                      .p_color_attachments    = @ptrCast ([*] const vk.AttachmentReference, &attachment_ref),
                    };

    const create_info = vk.RenderPassCreateInfo
                        {
                          .flags            = .{},
                          .attachment_count = 1,
                          .p_attachments    = @ptrCast([*] const vk.AttachmentDescription, &attachment_desc),
                          .subpass_count    = 1,
                          .p_subpasses      = @ptrCast([*] const vk.SubpassDescription, &subpass),
                        };

    self.render_pass = try self.device_dispatch.createRenderPass (self.logical_device, &create_info, null);
    errdefer self.device_dispatch.destroyRenderPass (self.logical_device, self.render_pass, null);

    try log_app ("Init Vulkan Render Pass OK", severity.DEBUG, .{});
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

  fn init_graphics_pipeline (self: *Self) !void
  {
    const vertex = try self.init_shader_module (resources.vert [0..]);
    defer self.device_dispatch.destroyShaderModule (self.logical_device, vertex, null);
    const fragment = try self.init_shader_module (resources.frag [0..]);
    defer self.device_dispatch.destroyShaderModule (self.logical_device, fragment, null);

    const shader_stage = [_] vk.PipelineShaderStageCreateInfo
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

    const dynamic_states = [_] vk.DynamicState { .viewport, .scissor };

    const dynamic_state = vk.PipelineDynamicStateCreateInfo
                          {
                            .flags               = .{},
                            .dynamic_state_count = dynamic_states.len,
                            .p_dynamic_states    = &dynamic_states,
                          };

    const vertex_input_state = vk.PipelineVertexInputStateCreateInfo
                               {
                                 .flags                              = .{},
                                 .vertex_binding_description_count   = 0,
                                 .p_vertex_binding_descriptions      = null,
                                 .vertex_attribute_description_count = 0,
                                 .p_vertex_attribute_descriptions    = null,
                               };

    const input_assembly = vk.PipelineInputAssemblyStateCreateInfo
                           {
                             .flags                    = .{},
                             .topology                 = .triangle_list,
                             .primitive_restart_enable = vk.FALSE,
                           };

    self.viewport = [_] vk.Viewport
                    {
                      .{
                        .x         = 0,
                        .y         = 0,
                        .width     = @intToFloat(f32, self.extent.width),
                        .height    = @intToFloat(f32, self.extent.height),
                        .min_depth = 0,
                        .max_depth = 1,
                       },
                    };

    self.scissor = [_] vk.Rect2D
                   {
                     .{
                       .offset = .{ .x = 0, .y = 0 },
                       .extent = self.extent,
                      },
                   };

    const viewport_state = vk.PipelineViewportStateCreateInfo
                           {
                             .flags          = .{},
                             .viewport_count = 1,
                             .p_viewports    = &(self.viewport),
                             .scissor_count  = 1,
                             .p_scissors     = &(self.scissor),
                           };

    const rasterizer = vk.PipelineRasterizationStateCreateInfo
                       {
                         .flags                      = .{},
                         .depth_clamp_enable         = vk.FALSE,
                         .rasterizer_discard_enable  = vk.FALSE,
                         .polygon_mode               = .fill,
                         .line_width                 = 1,
                         .cull_mode                  = .{ .back_bit = true },
                         .front_face                 = .clockwise,
                         .depth_bias_enable          = vk.FALSE,
                         .depth_bias_constant_factor = 0,
                         .depth_bias_clamp           = 0,
                         .depth_bias_slope_factor    = 0,
                       };

    const multisampling = vk.PipelineMultisampleStateCreateInfo
                          {
                            .flags                    = .{},
                            .sample_shading_enable    = vk.FALSE,
                            .rasterization_samples    = .{ .@"1_bit" = true },
                            .min_sample_shading       = 1,
                            .p_sample_mask            = null,
                            .alpha_to_coverage_enable = vk.FALSE,
                            .alpha_to_one_enable      = vk.FALSE,
                          };

    const blend_attachment = vk.PipelineColorBlendAttachmentState
                             {
                               .color_write_mask       = .{
                                                            .r_bit = true,
                                                            .g_bit = true,
                                                            .b_bit = true,
                                                            .a_bit = true,
                                                          },
                               .blend_enable           = vk.FALSE,
                               .src_color_blend_factor = .one,
                               .dst_color_blend_factor = .zero,
                               .color_blend_op         = .add,
                               .src_alpha_blend_factor = .one,
                               .dst_alpha_blend_factor = .zero,
                               .alpha_blend_op         = .add,
                             };

    const blend_state = vk.PipelineColorBlendStateCreateInfo
                        {
                          .flags            = .{},
                          .logic_op_enable  = vk.FALSE,
                          .logic_op         = .copy,
                          .attachment_count = 1,
                          .p_attachments    = @ptrCast ([*] const vk.PipelineColorBlendAttachmentState, &blend_attachment),
                          .blend_constants  = [_] f32 { 0, 0, 0, 0 },
                        };

    const layout_create_info = vk.PipelineLayoutCreateInfo
                               {
                                 .flags                     = .{},
                                 .set_layout_count          = 0,
                                 .p_set_layouts             = undefined,
                                 .push_constant_range_count = 0,
                                 .p_push_constant_ranges    = undefined,
                               };

    self.pipeline_layout = try self.device_dispatch.createPipelineLayout (self.logical_device, &layout_create_info, null);
    errdefer self.device_dispatch.destroyPipelineLayout (self.logical_device, self.pipeline_layout, null);

    const pipeline_create_info = vk.GraphicsPipelineCreateInfo
                                  {
                                    .flags                  = .{},
                                    .stage_count            = 2,
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
                                    .base_pipeline_handle   = .null_handle,
                                    .base_pipeline_index    = -1,
                                  };

    _ = try self.device_dispatch.createGraphicsPipelines (self.logical_device, .null_handle, 1, @ptrCast ([*] const vk.GraphicsPipelineCreateInfo, &pipeline_create_info), null, @ptrCast ([*] vk.Pipeline, &(self.pipeline)));
    errdefer self.device_dispatch.destroyPipeline (self.logical_device, self.pipeline, null);

    try log_app ("Init Vulkan Graphics Pipeline OK", severity.DEBUG, .{});
  }

  fn init_framebuffers (self: *Self) !void
  {
    self.framebuffers = try self.allocator.alloc (vk.Framebuffer, self.views.len);
    errdefer self.allocator.free (self.views);

    var index: usize = 0;
    var create_info: vk.FramebufferCreateInfo = undefined;

    for (self.framebuffers) |*framebuffer|
    {
      create_info = vk.FramebufferCreateInfo
                    {
                      .flags            = .{},
                      .render_pass      = self.render_pass,
                      .attachment_count = 1,
                      .p_attachments    = @ptrCast ([*] const vk.ImageView, &(self.views [index])),
                      .width            = self.extent.width,
                      .height           = self.extent.height,
                      .layers           = 1,
                    };

      framebuffer.* = try self.device_dispatch.createFramebuffer (self.logical_device, &create_info, null);
      errdefer self.device_dispatch.destroyFramebuffer (self.logical_device, framebuffer.*, null);

      index += 1;
    }

    try log_app ("Init Vulkan Framebuffers OK", severity.DEBUG, .{});
  }

  fn init_commandpool (self: *Self) !void
  {
    const create_info = vk.CommandPoolCreateInfo
                        {
                          .flags              = .{},
                          .queue_family_index = self.candidate.graphics_family,
                        };

    self.command_pool = try self.device_dispatch.createCommandPool (self.logical_device, &create_info, null);
    errdefer self.device_dispatch.destroyCommandPool (self.logical_device, self.command_pool, null);

    try log_app ("Init Vulkan Command Pool OK", severity.DEBUG, .{});
  }

  fn init_commandbuffer (self: *Self) !void
  {
    const alloc_info = vk.CommandBufferAllocateInfo
                       {
                         .command_pool         = self.command_pool,
                         .level                = .primary,
                         .command_buffer_count = 1,
                       };

    try self.device_dispatch.allocateCommandBuffers (self.logical_device, &alloc_info, @ptrCast ([*] vk.CommandBuffer, &(self.command_buffer)));
    errdefer self.device_dispatch.freeCommandBuffers (self.logical_device, self.command_pool, 1, @ptrCast ([*] const vk.CommandBuffer, &(self.command_buffer)));

    try log_app ("Init Vulkan Command Buffer OK", severity.DEBUG, .{});
  }

  fn record_commandbuffer (self: Self, command_buffer: vk.CommandBuffer, image_index: u32) !void
  {
    const commandbuffer_begin_info = vk.CommandBufferBeginInfo
                                     {
                                       .flags              = .{},
                                       .p_inheritance_info = null,
                                     };

    try self.device_dispatch.beginCommandBuffer (command_buffer, &commandbuffer_begin_info);

    const clear = vk.ClearValue
                  {
                    .color = .{ .float_32 = .{ 0, 0, 0, 1 } },
                  };

    const renderpass_begin_info = vk.RenderPassBeginInfo
                                  {
                                    .render_pass       = self.render_pass,
                                    .framebuffer       = self.framebuffers [image_index],
                                    .render_area       = vk.Rect2D
                                                         {
                                                           .offset = .{ .x = 0, .y = 0 },
                                                           .extent = self.extent,
                                                         },
                                    .clear_value_count = 1,
                                    .p_clear_values    = @ptrCast([*] const vk.ClearValue, &clear),
                                  };

    self.device_dispatch.cmdBeginRenderPass (command_buffer, &renderpass_begin_info, .@"inline");
    self.device_dispatch.cmdBindPipeline (command_buffer, .graphics, self.pipeline);

    self.device_dispatch.cmdSetViewport (command_buffer, 0, 1, self.viewport.ptr);
    self.device_dispatch.cmdSetScissor (command_buffer, 0, 1, self.scissor.ptr);

    self.device_dispatch.cmdDraw (command_buffer, 3, 1, 0, 0);

    self.device_dispatch.cmdEndCommandBuffer (command_buffer);
    try self.device_dispatch.endCommandBuffer (command_buffer);
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

  pub fn init (self: *Self, framebuffer: struct { width: u32, height: u32, }) !void
  {
    try self.pick_physical_device ();
    defer self.allocator.free (self.formats);
    defer self.allocator.free (self.present_modes);

    try self.init_logical_device ();
    try self.init_swapchain (.{ .width = framebuffer.width, .height = framebuffer.height, });
    defer self.allocator.free (self.images);
    errdefer self.allocator.free (self.views);

    try self.init_image_views ();
    try self.init_render_pass ();
    try self.init_graphics_pipeline ();
    try self.init_framebuffers ();
    try self.init_commandpool ();
    try self.init_commandbuffer ();

    try log_app ("Init Vulkan OK", severity.DEBUG, .{});
  }

  pub fn loop (self: Self) !void
  {
    _ = self;
    try log_app ("Loop Vulkan OK", severity.DEBUG, .{});
  }

  pub fn cleanup (self: Self) !void
  {
    self.device_dispatch.destroyCommandPool (self.logical_device, self.command_pool, null);

    for (self.framebuffers) |framebuffer|
    {
      self.device_dispatch.destroyFramebuffer (self.logical_device, framebuffer, null);
    }

    self.device_dispatch.destroyPipeline (self.logical_device, self.pipeline, null);
    self.device_dispatch.destroyPipelineLayout (self.logical_device, self.pipeline_layout, null);
    self.device_dispatch.destroyRenderPass (self.logical_device, self.render_pass, null);

    for (self.views) |image_view|
    {
      self.device_dispatch.destroyImageView (self.logical_device, image_view, null);
    }

    self.allocator.free (self.views);
    self.device_dispatch.destroySwapchainKHR (self.logical_device, self.swapchain, null);
    self.device_dispatch.destroyDevice (self.logical_device, null);
    self.initializer.instance_dispatch.destroySurfaceKHR (self.initializer.instance, self.surface, null);
    try self.initializer.cleanup ();
    try log_app ("Cleanup Vulkan OK", severity.DEBUG, .{});
  }
};
