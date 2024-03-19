const std     = @import ("std");
const builtin = @import ("builtin");
const c       = @import ("c");

const vk = @This ();

const raw = @import ("prototypes.zig");
pub const EXT = @import ("ext.zig").EXT;
pub const KHR = @import ("khr.zig").KHR;

pub const call_conv: std.builtin.CallingConvention = if (builtin.os.tag == .windows and builtin.cpu.arch == .x86)
  .Stdcall
else if (builtin.abi == .android and (builtin.cpu.arch.isARM () or builtin.cpu.arch.isThumb ()) and std.Target.arm.featureSetHas (builtin.cpu.features, .has_v7) and builtin.cpu.arch.ptrBitWidth () == 32)
  // On Android 32-bit ARM targets, Vulkan functions use the "hardfloat"
  // calling convention, i.e. float parameters are passed in registers. This
  // is true even if the rest of the application passes floats on the stack,
  // as it does by default when compiling for the armeabi-v7a NDK ABI.
  .AAPCSVFP
else
  .C;

pub fn load () !void
{
  const loader: *const fn (vk.Instance, [*:0] const u8) callconv (vk.call_conv) ?*const fn () callconv (vk.call_conv) void = @ptrCast (&c.glfwGetInstanceProcAddress);
  inline for (std.meta.fields (@TypeOf (raw.prototypes.structless))) |field|
  {
    const name: [*:0] const u8 = @ptrCast (field.name ++ "\x00");
    const pointer = loader (vk.Instance.NULL_HANDLE, name) orelse return error.CommandLoadFailure;
    @field (raw.prototypes.structless, field.name) = @ptrCast (pointer);
  }
}

pub const API_VERSION = extern struct
{
  pub const @"1" = enum
  {
    pub const @"0" = c.VK_API_VERSION_1_0;
    pub const @"1" = c.VK_API_VERSION_1_1;
    pub const @"2" = c.VK_API_VERSION_1_2;
    pub const @"3" = c.VK_API_VERSION_1_3;
  };
};

pub const MAX_DESCRIPTION_SIZE = c.VK_MAX_DESCRIPTION_SIZE;
pub const MAX_EXTENSION_NAME_SIZE = c.VK_MAX_EXTENSION_NAME_SIZE;
pub const MAX_PHYSICAL_DEVICE_NAME_SIZE = c.VK_MAX_PHYSICAL_DEVICE_NAME_SIZE;
pub const UUID_SIZE = c.VK_UUID_SIZE;

pub const AllocationCallbacks = extern struct
{
  p_user_data: ?*anyopaque = null,
  pfn_allocation: ?*const fn (?*anyopaque, usize, usize, vk.SystemAllocationScope) callconv (vk.call_conv) ?*anyopaque,
  pfn_reallocation: ?*const fn (?*anyopaque, ?*anyopaque, usize, usize, vk.SystemAllocationScope) callconv (vk.call_conv) ?*anyopaque,
  pfn_free: ?*const fn (?*anyopaque, ?*anyopaque) callconv (vk.call_conv) void,
  pfn_internal_allocation: ?*const fn (?*anyopaque, usize, vk.InternalAllocationType, vk.SystemAllocationScope) callconv (vk.call_conv) void = null,
  pfn_internal_free: ?*const fn (?*anyopaque, usize, vk.InternalAllocationType, vk.SystemAllocationScope) callconv (vk.call_conv) void = null,
};

pub const ApplicationInfo = extern struct
{
  s_type: vk.StructureType = .APPLICATION_INFO,
  p_next: ?*const anyopaque = null,
  p_application_name: ?[*:0] const u8 = null,
  application_version: u32,
  p_engine_name: ?[*:0] const u8 = null,
  engine_version: u32,
  api_version: u32,
};

pub const Bool32 = u32;
pub const TRUE = c.VK_TRUE;
pub const FALSE = c.VK_FALSE;

pub const Buffer = enum (u64) { NULL_HANDLE = 0, _, };

pub const Command = extern struct
{
  pub const Buffer = enum (usize) { NULL_HANDLE = 0, _, };
  pub const Pool = enum (u64) { NULL_HANDLE = 0, _, };
};

pub const Descriptor = extern struct
{
  pub const Pool = enum (u64) { NULL_HANDLE = 0, _, };
  pub const Set = enum (u64)
  {
    NULL_HANDLE = 0, _,
    pub const Layout = enum (u64) { NULL_HANDLE = 0, _, };
  };
};

pub const Device = enum (usize)
{
  NULL_HANDLE = 0, _,
  pub const Memory = enum (u64) { NULL_HANDLE = 0, _, };
  pub const Size = u64;

  pub fn load (self: @This ()) !void
  {
    const loader: *const fn (vk.Device, [*:0] const u8) callconv (vk.call_conv) ?*const fn () callconv (vk.call_conv) void = @ptrCast (&raw.prototypes.instance.vkGetDeviceProcAddr);
    inline for (std.meta.fields (@TypeOf (raw.prototypes.device))) |field|
    {
      const name: [*:0] const u8 = @ptrCast (field.name ++ "\x00");
      const pointer = loader (self, name) orelse return error.CommandLoadFailure;
      @field (raw.prototypes.device, field.name) = @ptrCast (pointer);
    }
  }

  pub const ExtensionProperties = extern struct
  {
    pub fn enumerate (physical_device: PhysicalDevice, p_layer_name: ?[*:0] const u8, p_property_count: *u32, p_properties: ?[*] vk.ExtensionProperties) !void
    {
      const result = raw.prototypes.structless.vkEnumerateDeviceExtensionProperties (physical_device, p_layer_name, p_property_count, p_properties);
      if (result > 0)
      {
        std.debug.print ("{s} failed with {} status code\n", .{ @typeName (@This ()) ++ "." ++ @src ().fn_name, result, });
        return error.UnexpectedResult;
      }
    }
  };
};

pub const ExtensionProperties = extern struct
{
  extension_name: [vk.MAX_EXTENSION_NAME_SIZE] u8,
  spec_version: u32,
};

pub const Extent2D = extern struct
{
  width: u32,
  height: u32,
};

pub const Extent3D = extern struct
{
  width: u32,
  height: u32,
  depth: u32,
};

pub const Fence = enum (u64) { NULL_HANDLE = 0, _, };

pub const Format = enum (u32)
{
  A8B8G8R8_UNORM_PACK32 = c.VK_FORMAT_A8B8G8R8_UNORM_PACK32,
  B8G8R8A8_UNORM = c.VK_FORMAT_B8G8R8A8_UNORM,
  R8G8B8_UNORM = c.VK_FORMAT_R8G8B8_UNORM,
  R8G8B8A8_UNORM = c.VK_FORMAT_R8G8B8A8_UNORM,
  _,

  pub const Feature = extern struct
  {
    pub const Flags = u32;

    pub const Bit = enum (vk.Format.Feature.Flags)
    {
      BLIT_SRC = c.VK_FORMAT_FEATURE_BLIT_SRC_BIT,
      BLIT_DST = c.VK_FORMAT_FEATURE_BLIT_DST_BIT,

      pub fn in (self: @This (), flags: vk.Format.Feature.Flags) bool
      {
        return (flags & @intFromEnum (self)) == @intFromEnum (self);
      }
    };
  };

  pub const Properties = extern struct
  {
    linear_tiling_features: vk.Format.Feature.Flags = 0,
    optimal_tiling_features: vk.Format.Feature.Flags = 0,
    buffer_features: vk.Format.Feature.Flags = 0,
  };
};

pub const Framebuffer = enum (u64) { NULL_HANDLE = 0, _, };

pub const Image = enum (u64)
{
  NULL_HANDLE = 0, _,

  pub const Usage = extern struct
  {
    pub const Flags = extern struct
    {
      pub const TRANSFER_SRC_BIT = c.VK_IMAGE_USAGE_TRANSFER_SRC_BIT;
    };
  };

  pub const View = enum (u64) { NULL_HANDLE = 0, _, };
};

pub const Instance = enum (usize)
{
  NULL_HANDLE = 0, _,

  pub fn create (p_create_info: *const vk.Instance.Create.Info, p_allocator: ?*const vk.AllocationCallbacks) !@This ()
  {
    var instance: vk.Instance = undefined;
    const result = raw.prototypes.structless.vkCreateInstance (p_create_info, p_allocator, &instance);
    if (result > 0)
    {
      std.debug.print ("{s} failed with {} status code\n", .{ @typeName (@This ()) ++ "." ++ @src ().fn_name, result, });
      return error.UnexpectedResult;
    }
    return instance;
  }

  pub fn destroy (self: @This (), p_allocator: ?*const vk.AllocationCallbacks) void
  {
    raw.prototypes.instance.vkDestroyInstance (self, p_allocator);
  }

  pub fn load (self: @This ()) !void
  {
    const loader: *const fn (vk.Instance, [*:0] const u8) callconv (vk.call_conv) ?*const fn () callconv (vk.call_conv) void = @ptrCast (&raw.prototypes.structless.vkGetInstanceProcAddr);
    inline for (std.meta.fields (@TypeOf (raw.prototypes.instance))) |field|
    {
      const name: [*:0] const u8 = @ptrCast (field.name ++ "\x00");
      const pointer = loader (self, name) orelse return error.CommandLoadFailure;
      @field (raw.prototypes.instance, field.name) = @ptrCast (pointer);
    }
  }

  pub const Create = extern struct
  {
    pub const Flags = u32;
    pub const Info = extern struct
    {
      s_type: vk.StructureType = .INSTANCE_CREATE_INFO,
      p_next: ?*const anyopaque = null,
      flags: vk.Instance.Create.Flags = 0,
      p_application_info: ?*const vk.ApplicationInfo = null,
      enabled_layer_count: u32 = 0,
      pp_enabled_layer_names: ?[*] const [*:0] const u8 = null,
      enabled_extension_count: u32 = 0,
      pp_enabled_extension_names: ?[*] const [*:0] const u8 = null,
    };
  };

  pub const ExtensionProperties = extern struct
  {
    pub fn enumerate (p_layer_name: ?[*:0] const u8, p_property_count: *u32, p_properties: ?[*] vk.ExtensionProperties) !void
    {
      const result = raw.prototypes.structless.vkEnumerateInstanceExtensionProperties (p_layer_name, p_property_count, p_properties);
      if (result > 0)
      {
        std.debug.print ("{s} failed with {} status code\n", .{ @typeName (@This ()) ++ "." ++ @src ().fn_name, result, });
        return error.UnexpectedResult;
      }
    }
  };

  pub const LayerProperties = extern struct
  {
    pub fn enumerate (p_property_count: *u32, p_properties: ?[*] vk.LayerProperties) !void
    {
      const result = raw.prototypes.structless.vkEnumerateInstanceLayerProperties (p_property_count, p_properties);
      if (result > 0)
      {
        std.debug.print ("{s} failed with {} status code\n", .{ @typeName (@This ()) ++ "." ++ @src ().fn_name, result, });
        return error.UnexpectedResult;
      }
    }
  };
};

pub const InternalAllocationType = enum (i32) {};

pub const LayerProperties = extern struct
{
  layer_name: [vk.MAX_EXTENSION_NAME_SIZE] u8,
  spec_version: u32,
  implementation_version: u32,
  description: [vk.MAX_DESCRIPTION_SIZE] u8,
};

pub const ObjectType = enum (i32)
{
  unknown = 0,
};

pub const Offset2D = extern struct
{
  x: i32,
  y: i32,
};

pub const PhysicalDevice = enum (usize)
{
  NULL_HANDLE = 0, _,

  pub const Features = extern struct
  {
    robust_buffer_access: vk.Bool32 = vk.FALSE,
    full_draw_index_uint_32: vk.Bool32 = vk.FALSE,
    image_cube_array: vk.Bool32 = vk.FALSE,
    independent_blend: vk.Bool32 = vk.FALSE,
    geometry_shader: vk.Bool32 = vk.FALSE,
    tessellation_shader: vk.Bool32 = vk.FALSE,
    sample_rate_shading: vk.Bool32 = vk.FALSE,
    dual_src_blend: vk.Bool32 = vk.FALSE,
    logic_op: vk.Bool32 = vk.FALSE,
    multi_draw_indirect: vk.Bool32 = vk.FALSE,
    draw_indirect_first_instance: vk.Bool32 = vk.FALSE,
    depth_clamp: vk.Bool32 = vk.FALSE,
    depth_bias_clamp: vk.Bool32 = vk.FALSE,
    fill_mode_non_solid: vk.Bool32 = vk.FALSE,
    depth_bounds: vk.Bool32 = vk.FALSE,
    wide_lines: vk.Bool32 = vk.FALSE,
    large_points: vk.Bool32 = vk.FALSE,
    alpha_to_one: vk.Bool32 = vk.FALSE,
    multi_viewport: vk.Bool32 = vk.FALSE,
    sampler_anisotropy: vk.Bool32 = vk.FALSE,
    texture_compression_etc2: vk.Bool32 = vk.FALSE,
    texture_compression_astc_ldr: vk.Bool32 = vk.FALSE,
    texture_compression_bc: vk.Bool32 = vk.FALSE,
    occlusion_query_precise: vk.Bool32 = vk.FALSE,
    pipeline_statistics_query: vk.Bool32 = vk.FALSE,
    vertex_pipeline_stores_and_atomics: vk.Bool32 = vk.FALSE,
    fragment_stores_and_atomics: vk.Bool32 = vk.FALSE,
    shader_tessellation_and_geometry_point_size: vk.Bool32 = vk.FALSE,
    shader_image_gather_extended: vk.Bool32 = vk.FALSE,
    shader_storage_image_extended_formats: vk.Bool32 = vk.FALSE,
    shader_storage_image_multisample: vk.Bool32 = vk.FALSE,
    shader_storage_image_read_without_format: vk.Bool32 = vk.FALSE,
    shader_storage_image_write_without_format: vk.Bool32 = vk.FALSE,
    shader_uniform_buffer_array_dynamic_indexing: vk.Bool32 = vk.FALSE,
    shader_sampled_image_array_dynamic_indexing: vk.Bool32 = vk.FALSE,
    shader_storage_buffer_array_dynamic_indexing: vk.Bool32 = vk.FALSE,
    shader_storage_image_array_dynamic_indexing: vk.Bool32 = vk.FALSE,
    shader_clip_distance: vk.Bool32 = vk.FALSE,
    shader_cull_distance: vk.Bool32 = vk.FALSE,
    shader_float_64: vk.Bool32 = vk.FALSE,
    shader_int_64: vk.Bool32 = vk.FALSE,
    shader_int_16: vk.Bool32 = vk.FALSE,
    shader_resource_residency: vk.Bool32 = vk.FALSE,
    shader_resource_min_lod: vk.Bool32 = vk.FALSE,
    sparse_binding: vk.Bool32 = vk.FALSE,
    sparse_residency_buffer: vk.Bool32 = vk.FALSE,
    sparse_residency_image_2d: vk.Bool32 = vk.FALSE,
    sparse_residency_image_3d: vk.Bool32 = vk.FALSE,
    sparse_residency_2_samples: vk.Bool32 = vk.FALSE,
    sparse_residency_4_samples: vk.Bool32 = vk.FALSE,
    sparse_residency_8_samples: vk.Bool32 = vk.FALSE,
    sparse_residency_16_samples: vk.Bool32 = vk.FALSE,
    sparse_residency_aliased: vk.Bool32 = vk.FALSE,
    variable_multisample_rate: vk.Bool32 = vk.FALSE,
    inherited_queries: vk.Bool32 = vk.FALSE,

    pub fn get (physical_device: vk.PhysicalDevice) vk.PhysicalDevice.Features
    {
      var features: vk.PhysicalDevice.Features = undefined;
      raw.prototypes.instance.vkGetPhysicalDeviceFeatures (physical_device, &features);
      return features;
    }
  };

  pub const Format = extern struct
  {
    pub const Properties = extern struct
    {
      pub fn get (physical_device: vk.PhysicalDevice, format: vk.Format) vk.Format.Properties
      {
        var format_properties: vk.Format.Properties = undefined;
        raw.prototypes.instance.vkGetPhysicalDeviceFormatProperties (physical_device, @intFromEnum (format), &format_properties);
        return format_properties;
      }
    };
  };

  pub const Limits = extern struct
  {
    max_image_dimension_1d: u32,
    max_image_dimension_2d: u32,
    max_image_dimension_3d: u32,
    max_image_dimension_cube: u32,
    max_image_array_layers: u32,
    max_texel_buffer_elements: u32,
    max_uniform_buffer_range: u32,
    max_storage_buffer_range: u32,
    max_push_constants_size: u32,
    max_memory_allocation_count: u32,
    max_sampler_allocation_count: u32,
    buffer_image_granularity: vk.Device.Size,
    sparse_address_space_size: vk.Device.Size,
    max_bound_descriptor_sets: u32,
    max_per_stage_descriptor_samplers: u32,
    max_per_stage_descriptor_uniform_buffers: u32,
    max_per_stage_descriptor_storage_buffers: u32,
    max_per_stage_descriptor_sampled_images: u32,
    max_per_stage_descriptor_storage_images: u32,
    max_per_stage_descriptor_input_attachments: u32,
    max_per_stage_resources: u32,
    max_descriptor_set_samplers: u32,
    max_descriptor_set_uniform_buffers: u32,
    max_descriptor_set_uniform_buffers_dynamic: u32,
    max_descriptor_set_storage_buffers: u32,
    max_descriptor_set_storage_buffers_dynamic: u32,
    max_descriptor_set_sampled_images: u32,
    max_descriptor_set_storage_images: u32,
    max_descriptor_set_input_attachments: u32,
    max_vertex_input_attributes: u32,
    max_vertex_input_bindings: u32,
    max_vertex_input_attribute_offset: u32,
    max_vertex_input_binding_stride: u32,
    max_vertex_output_components: u32,
    max_tessellation_generation_level: u32,
    max_tessellation_patch_size: u32,
    max_tessellation_control_per_vertex_input_components: u32,
    max_tessellation_control_per_vertex_output_components: u32,
    max_tessellation_control_per_patch_output_components: u32,
    max_tessellation_control_total_output_components: u32,
    max_tessellation_evaluation_input_components: u32,
    max_tessellation_evaluation_output_components: u32,
    max_geometry_shader_invocations: u32,
    max_geometry_input_components: u32,
    max_geometry_output_components: u32,
    max_geometry_output_vertices: u32,
    max_geometry_total_output_components: u32,
    max_fragment_input_components: u32,
    max_fragment_output_attachments: u32,
    max_fragment_dual_src_attachments: u32,
    max_fragment_combined_output_resources: u32,
    max_compute_shared_memory_size: u32,
    max_compute_work_group_count: [3] u32,
    max_compute_work_group_invocations: u32,
    max_compute_work_group_size: [3] u32,
    sub_pixel_precision_bits: u32,
    sub_texel_precision_bits: u32,
    mipmap_precision_bits: u32,
    max_draw_indexed_index_value: u32,
    max_draw_indirect_count: u32,
    max_sampler_lod_bias: f32,
    max_sampler_anisotropy: f32,
    max_viewports: u32,
    max_viewport_dimensions: [2] u32,
    viewport_bounds_range: [2] f32,
    viewport_sub_pixel_bits: u32,
    min_memory_map_alignment: usize,
    min_texel_buffer_offset_alignment: vk.Device.Size,
    min_uniform_buffer_offset_alignment: vk.Device.Size,
    min_storage_buffer_offset_alignment: vk.Device.Size,
    min_texel_offset: i32,
    max_texel_offset: u32,
    min_texel_gather_offset: i32,
    max_texel_gather_offset: u32,
    min_interpolation_offset: f32,
    max_interpolation_offset: f32,
    sub_pixel_interpolation_offset_bits: u32,
    max_framebuffer_width: u32,
    max_framebuffer_height: u32,
    max_framebuffer_layers: u32,
    framebuffer_color_sample_counts: vk.SampleCount.Flags = 0,
    framebuffer_depth_sample_counts: vk.SampleCount.Flags = 0,
    framebuffer_stencil_sample_counts: vk.SampleCount.Flags = 0,
    framebuffer_no_attachments_sample_counts: vk.SampleCount.Flags = 0,
    max_color_attachments: u32,
    sampled_image_color_sample_counts: vk.SampleCount.Flags = 0,
    sampled_image_integer_sample_counts: vk.SampleCount.Flags = 0,
    sampled_image_depth_sample_counts: vk.SampleCount.Flags = 0,
    sampled_image_stencil_sample_counts: vk.SampleCount.Flags = 0,
    storage_image_sample_counts: vk.SampleCount.Flags = 0,
    max_sample_mask_words: u32,
    timestamp_compute_and_graphics: vk.Bool32,
    timestamp_period: f32,
    max_clip_distances: u32,
    max_cull_distances: u32,
    max_combined_clip_and_cull_distances: u32,
    discrete_queue_priorities: u32,
    point_size_range: [2] f32,
    line_width_range: [2] f32,
    point_size_granularity: f32,
    line_width_granularity: f32,
    strict_lines: vk.Bool32,
    standard_sample_locations: vk.Bool32,
    optimal_buffer_copy_offset_alignment: vk.Device.Size,
    optimal_buffer_copy_row_pitch_alignment: vk.Device.Size,
    non_coherent_atom_size: vk.Device.Size,
  };

  pub const Properties = extern struct
  {
    api_version: u32,
    driver_version: u32,
    vendor_id: u32,
    device_id: u32,
    device_type: vk.PhysicalDevice.Type,
    device_name: [vk.MAX_PHYSICAL_DEVICE_NAME_SIZE] u8,
    pipeline_cache_uuid: [vk.UUID_SIZE] u8,
    limits: vk.PhysicalDevice.Limits,
    sparse_properties: vk.PhysicalDevice.SparseProperties,

    pub fn get (physical_device: vk.PhysicalDevice) vk.PhysicalDevice.Properties
    {
      var properties: vk.PhysicalDevice.Properties = undefined;
      raw.prototypes.instance.vkGetPhysicalDeviceProperties (physical_device, &properties);
      return properties;
    }
  };

  pub const Queue = extern struct
  {
    pub const FamilyProperties = extern struct
    {
      pub fn get (physical_device: vk.PhysicalDevice, p_queue_family_property_count: *u32, p_queue_family_properties: ?[*] vk.Queue.FamilyProperties) void
      {
        raw.prototypes.instance.vkGetPhysicalDeviceQueueFamilyProperties (physical_device, p_queue_family_property_count, p_queue_family_properties);
      }
    };
  };

  pub const SparseProperties = extern struct
  {
    residency_standard_2d_block_shape: vk.Bool32,
    residency_standard_2d_multisample_block_shape: vk.Bool32,
    residency_standard_3d_block_shape: vk.Bool32,
    residency_aligned_mip_size: vk.Bool32,
    residency_non_resident_strict: vk.Bool32,
  };

  pub const Type = enum (i32)
  {
    DISCRETE_GPU = c.VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU,
  };
};

pub const PhysicalDevices = extern struct
{
  pub fn enumerate (instance: vk.Instance, p_physical_device_count: *u32, p_physical_devices: ?[*] vk.PhysicalDevice) !void
  {
    const result = raw.prototypes.instance.vkEnumeratePhysicalDevices (instance, p_physical_device_count, p_physical_devices);
    if (result > 0)
    {
      std.debug.print ("{s} failed with {} status code\n", .{ @typeName (@This ()) ++ "." ++ @src ().fn_name, result, });
      return error.UnexpectedResult;
    }
  }
};

pub const Pipeline = enum (u64)
{
  NULL_HANDLE = 0, _,
  pub const Layout = enum (u64) { NULL_HANDLE = 0, _, };
};

pub const Queue = enum (usize)
{
  NULL_HANDLE = 0, _,

  pub const Flags = u32;

  pub const Bit = enum (vk.Queue.Flags)
  {
    GRAPHICS = c.VK_QUEUE_GRAPHICS_BIT,

    pub fn in (self: @This (), flags: vk.Queue.Flags) bool
    {
      return (flags & @intFromEnum (self)) == @intFromEnum (self);
    }
  };

  pub const FamilyProperties = extern struct
  {
    queue_flags: vk.Queue.Flags = 0,
    queue_count: u32,
    timestamp_valid_bits: u32,
    min_image_transfer_granularity: vk.Extent3D,
  };
};

pub const Rect2D = extern struct
{
  offset: vk.Offset2D,
  extent: vk.Extent2D,
};

pub const RenderPass = enum (u64) { NULL_HANDLE = 0, _, };
pub const Sampler = enum (u64) { NULL_HANDLE = 0, _, };

pub const SampleCount = extern struct
{
  pub const Flags = u32;
};

pub const Semaphore = enum (u64) { NULL_HANDLE = 0, _, };

pub const StructureType = enum (i32)
{
  APPLICATION_INFO = c.VK_STRUCTURE_TYPE_APPLICATION_INFO,
  DEBUG_UTILS_LABEL_EXT = c.VK_STRUCTURE_TYPE_DEBUG_UTILS_LABEL_EXT,
  DEBUG_UTILS_MESSENGER_CREATE_INFO_EXT = c.VK_STRUCTURE_TYPE_DEBUG_UTILS_MESSENGER_CREATE_INFO_EXT,
  DEBUG_UTILS_MESSENGER_CALLBACK_DATA_EXT = c.VK_STRUCTURE_TYPE_DEBUG_UTILS_MESSENGER_CALLBACK_DATA_EXT,
  DEBUG_UTILS_OBJECT_NAME_INFO_EXT = c.VK_STRUCTURE_TYPE_DEBUG_UTILS_OBJECT_NAME_INFO_EXT,
  INSTANCE_CREATE_INFO = c.VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO,
  VALIDATION_FEATURES_EXT = c.VK_STRUCTURE_TYPE_VALIDATION_FEATURES_EXT,
};

pub const SystemAllocationScope = enum (i32) {};

pub const Viewport = extern struct
{
  x: f32,
  y: f32,
  width: f32,
  height: f32,
  min_depth: f32,
  max_depth: f32,
};
