const std = @import ("std");
const c   = @import ("c");

const vk  = @import ("vk");
const raw = @import ("raw");

pub const PhysicalDevice = enum (usize)
{
  NULL_HANDLE = vk.NULL_HANDLE, _,

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

    pub fn get (physical_device: vk.PhysicalDevice) @This ()
    {
      var features: vk.PhysicalDevice.Features = undefined;
      raw.prototypes.instance.vkGetPhysicalDeviceFeatures (physical_device,
        &features);
      return features;
    }
  };

  pub const Format = extern struct
  {
    pub const Properties = extern struct
    {
      pub fn get (physical_device: vk.PhysicalDevice,
        format: vk.Format) vk.Format.Properties
      {
        var format_properties: vk.Format.Properties = undefined;
        raw.prototypes.instance.vkGetPhysicalDeviceFormatProperties (
          physical_device, @intFromEnum (format), &format_properties);
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
    framebuffer_color_sample_counts: vk.Sample.Count.Flags = 0,
    framebuffer_depth_sample_counts: vk.Sample.Count.Flags = 0,
    framebuffer_stencil_sample_counts: vk.Sample.Count.Flags = 0,
    framebuffer_no_attachments_sample_counts: vk.Sample.Count.Flags = 0,
    max_color_attachments: u32,
    sampled_image_color_sample_counts: vk.Sample.Count.Flags = 0,
    sampled_image_integer_sample_counts: vk.Sample.Count.Flags = 0,
    sampled_image_depth_sample_counts: vk.Sample.Count.Flags = 0,
    sampled_image_stencil_sample_counts: vk.Sample.Count.Flags = 0,
    storage_image_sample_counts: vk.Sample.Count.Flags = 0,
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

  pub const Memory = extern struct
  {
    pub const Properties = extern struct
    {
      memory_type_count: u32,
      memory_types: [vk.MAX_MEMORY_TYPES] vk.Memory.Type,
      memory_heap_count: u32,
      memory_heaps: [vk.MAX_MEMORY_HEAPS] vk.Memory.Heap,

      pub fn get (physical_device: vk.PhysicalDevice) @This ()
      {
        var memory_properties: vk.PhysicalDevice.Memory.Properties = undefined;
        raw.prototypes.instance.vkGetPhysicalDeviceMemoryProperties (
          physical_device, &memory_properties);
        return memory_properties;
      }
    };
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

    pub fn get (physical_device: vk.PhysicalDevice) @This ()
    {
      var properties: vk.PhysicalDevice.Properties = undefined;
      raw.prototypes.instance.vkGetPhysicalDeviceProperties (physical_device,
        &properties);
      return properties;
    }
  };

  pub const Queue = extern struct
  {
    pub const FamilyProperties = extern struct
    {
      pub fn get (physical_device: vk.PhysicalDevice,
        p_queue_family_property_count: *u32,
        p_queue_family_properties: ?[*] vk.Queue.FamilyProperties) void
      {
        raw.prototypes.instance.vkGetPhysicalDeviceQueueFamilyProperties (
          physical_device, p_queue_family_property_count,
          p_queue_family_properties);
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
