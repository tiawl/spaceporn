const std = @import ("std");
const c   = @import ("c");

const vk  = @import ("vk");
const raw = @import ("raw");

pub const Pipeline = enum (u64)
{
  NULL_HANDLE = vk.NULL_HANDLE, _,

  pub const Cache = enum (u64) { NULL_HANDLE = vk.NULL_HANDLE, _, };


  pub const ColorBlend = extern struct
  {
    pub const AttachmentState = extern struct
    {
      blend_enable: vk.Bool32,
      src_color_blend_factor: vk.Blend.Factor,
      dst_color_blend_factor: vk.Blend.Factor,
      color_blend_op: vk.Blend.Op,
      src_alpha_blend_factor: vk.Blend.Factor,
      dst_alpha_blend_factor: vk.Blend.Factor,
      alpha_blend_op: vk.Blend.Op,
      color_write_mask: vk.ColorComponent.Flags = 0,
    };

    pub const State = extern struct
    {
      pub const Create = extern struct
      {
        pub const Flags = u32;

        pub const Info = extern struct
        {
          s_type: vk.StructureType = .PIPELINE_COLOR_BLEND_STATE_CREATE_INFO,
          p_next: ?*const anyopaque = null,
          flags: vk.Pipeline.ColorBlend.State.Create.Flags = 0,
          logic_op_enable: vk.Bool32,
          logic_op: vk.LogicOp,
          attachment_count: u32 = 0,
          p_attachments: ?[*] const vk.Pipeline.ColorBlend.AttachmentState = null,
          blend_constants: [4] f32,
        };
      };
    };
  };

  pub const BindPoint = enum (i32)
  {
    GRAPHICS = c.VK_PIPELINE_BIND_POINT_GRAPHICS,
  };

  pub const Create = extern struct
  {
    pub const Flags = u32;
  };

  pub const DepthStencilState = extern struct
  {
    pub const Create = extern struct
    {
      pub const Flags = u32;

      pub const Info = extern struct
      {
        s_type: vk.StructureType = .PIPELINE_DEPTH_STENCIL_STATE_CREATE_INFO,
        p_next: ?*const anyopaque = null,
        flags: vk.Pipeline.DepthStencilState.Create.Flags = 0,
        depth_test_enable: vk.Bool32,
        depth_write_enable: vk.Bool32,
        depth_compare_op: vk.CompareOp,
        depth_bounds_test_enable: vk.Bool32,
        stencil_test_enable: vk.Bool32,
        front: vk.StencilOp.State,
        back: vk.StencilOp.State,
        min_depth_bounds: f32,
        max_depth_bounds: f32,
      };
    };
  };

  pub const DynamicState = extern struct
  {
    pub const Create = extern struct
    {
      pub const Flags = u32;

      pub const Info = extern struct
      {
        s_type: vk.StructureType = .PIPELINE_DYNAMIC_STATE_CREATE_INFO,
        p_next: ?*const anyopaque = null,
        flags: vk.Pipeline.DynamicState.Create.Flags = 0,
        dynamic_state_count: u32 = 0,
        p_dynamic_states: ?[*] const vk.DynamicState = null,
      };
    };
  };

  pub const InputAssemblyState = extern struct
  {
    pub const Create = extern struct
    {
      pub const Flags = u32;

      pub const Info = extern struct
      {
        s_type: vk.StructureType = .PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO,
        p_next: ?*const anyopaque = null,
        flags: vk.Pipeline.InputAssemblyState.Create.Flags = 0,
        topology: vk.PrimitiveTopology,
        primitive_restart_enable: vk.Bool32,
      };
    };
  };

  pub const Layout = enum (u64)
  {
    NULL_HANDLE = vk.NULL_HANDLE, _,

    pub const Create = extern struct
    {
      pub const Flags = u32;

      pub const Info = extern struct
      {
        s_type: vk.StructureType = .PIPELINE_LAYOUT_CREATE_INFO,
        p_next: ?*const anyopaque = null,
        flags: vk.Pipeline.Layout.Create.Flags = 0,
        set_layout_count: u32 = 0,
        p_set_layouts: ?[*] const vk.Descriptor.Set.Layout = null,
        push_constant_range_count: u32 = 0,
        p_push_constant_ranges: ?[*] const vk.PushConstantRange = null,
      };
    };

    pub fn create (device: vk.Device, p_create_info: *const vk.Pipeline.Layout.Create.Info, p_allocator: ?*const vk.AllocationCallbacks) !@This ()
    {
      var pipeline_layout: @This () = undefined;
      const result = raw.prototypes.device.vkCreatePipelineLayout (device, p_create_info, p_allocator, &pipeline_layout);
      if (result > 0)
      {
        std.debug.print ("{s} failed with {} status code\n", .{ @typeName (@This ()) ++ "." ++ @src ().fn_name, result, });
        return error.UnexpectedResult;
      }
      return pipeline_layout;
    }

    pub fn destroy (pipeline_layout: @This (), device: vk.Device, p_allocator: ?*const vk.AllocationCallbacks) void
    {
      raw.prototypes.device.vkDestroyPipelineLayout (device, pipeline_layout, p_allocator);
    }
  };

  pub const MultisampleState = extern struct
  {
    pub const Create = extern struct
    {
      pub const Flags = u32;

      pub const Info = extern struct
      {
        s_type: vk.StructureType = .PIPELINE_MULTISAMPLE_STATE_CREATE_INFO,
        p_next: ?*const anyopaque = null,
        flags: vk.Pipeline.MultisampleState.Create.Flags = 0,
        rasterization_samples: vk.Sample.Count.Flags,
        sample_shading_enable: vk.Bool32,
        min_sample_shading: f32,
        p_sample_mask: ?[*] const vk.Sample.Mask = null,
        alpha_to_coverage_enable: vk.Bool32,
        alpha_to_one_enable: vk.Bool32,
      };
    };
  };

  pub const RasterizationState = extern struct
  {
    pub const Create = extern struct
    {
      pub const Flags = u32;

      pub const Info = extern struct
      {
        s_type: vk.StructureType = .PIPELINE_RASTERIZATION_STATE_CREATE_INFO,
        p_next: ?*const anyopaque = null,
        flags: vk.Pipeline.RasterizationState.Create.Flags = 0,
        depth_clamp_enable: vk.Bool32,
        rasterizer_discard_enable: vk.Bool32,
        polygon_mode: vk.PolygonMode,
        cull_mode: vk.CullMode.Flags = 0,
        front_face: vk.FrontFace,
        depth_bias_enable: vk.Bool32,
        depth_bias_constant_factor: f32,
        depth_bias_clamp: f32,
        depth_bias_slope_factor: f32,
        line_width: f32,
      };
    };
  };

  pub const ShaderStage = extern struct
  {
    pub const Create = extern struct
    {
      pub const Flags = u32;

      pub const Info = extern struct
      {
        s_type: vk.StructureType = .PIPELINE_SHADER_STAGE_CREATE_INFO,
        p_next: ?*const anyopaque = null,
        flags: vk.Pipeline.ShaderStage.Create.Flags = 0,
        stage: vk.Shader.Stage.Flags,
        module: vk.Shader.Module = .NULL_HANDLE,
        p_name: [*:0] const u8,
        p_specialization_info: ?*const vk.Specialization.Info = null,
      };
    };
  };

  pub const Stage = extern struct
  {
    pub const Flags = u32;

    pub const Bit = enum (vk.Pipeline.Stage.Flags)
    {
      COLOR_ATTACHMENT_OUTPUT = c.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT,
      FRAGMENT_SHADER = c.VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT,
    };
  };

  pub const TessellationState = extern struct
  {
    pub const Create = extern struct
    {
      pub const Flags = u32;

      pub const Info = extern struct
      {
        s_type: vk.StructureType = .PIPELINE_TESSELLATION_STATE_CREATE_INFO,
        p_next: ?*const anyopaque = null,
        flags: vk.Pipeline.TessellationState.Create.Flags = 0,
        patch_control_points: u32,
      };
    };
  };

  pub const VertexInputState = extern struct
  {
    pub const Create = extern struct
    {
      pub const Flags = u32;

      pub const Info = extern struct
      {
        s_type: vk.StructureType = .PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO,
        p_next: ?*const anyopaque = null,
        flags: vk.Pipeline.VertexInputState.Create.Flags = 0,
        vertex_binding_description_count: u32 = 0,
        p_vertex_binding_descriptions: ?[*] const vk.VertexInput.BindingDescription = null,
        vertex_attribute_description_count: u32 = 0,
        p_vertex_attribute_descriptions: ?[*] const vk.VertexInput.AttributeDescription = null,
      };
    };
  };

  pub const ViewportState = extern struct
  {
    pub const Create = extern struct
    {
      pub const Flags = u32;

      pub const Info = extern struct
      {
        s_type: vk.StructureType = .PIPELINE_VIEWPORT_STATE_CREATE_INFO,
        p_next: ?*const anyopaque = null,
        flags: vk.Pipeline.ViewportState.Create.Flags = 0,
        viewport_count: u32 = 0,
        p_viewports: ?[*] const vk.Viewport = null,
        scissor_count: u32 = 0,
        p_scissors: ?[*] const vk.Rect2D = null,
      };
    };
  };

  pub fn destroy (pipeline: @This (), device: vk.Device, p_allocator: ?*const vk.AllocationCallbacks) void
  {
    raw.prototypes.device.vkDestroyPipeline (device, pipeline, p_allocator);
  }
};

pub const Graphics = extern struct
{
  pub const Pipeline = extern struct
  {
    pub const Create = extern struct
    {
      pub const Info = extern struct
      {
        s_type: vk.StructureType = .GRAPHICS_PIPELINE_CREATE_INFO,
        p_next: ?*const anyopaque = null,
        flags: vk.Pipeline.Create.Flags = 0,
        stage_count: u32 = 0,
        p_stages: ?[*] const vk.Pipeline.ShaderStage.Create.Info = null,
        p_vertex_input_state: ?*const vk.Pipeline.VertexInputState.Create.Info = null,
        p_input_assembly_state: ?*const vk.Pipeline.InputAssemblyState.Create.Info = null,
        p_tessellation_state: ?*const vk.Pipeline.TessellationState.Create.Info = null,
        p_viewport_state: ?*const vk.Pipeline.ViewportState.Create.Info = null,
        p_rasterization_state: ?*const vk.Pipeline.RasterizationState.Create.Info = null,
        p_multisample_state: ?*const vk.Pipeline.MultisampleState.Create.Info = null,
        p_depth_stencil_state: ?*const vk.Pipeline.DepthStencilState.Create.Info = null,
        p_color_blend_state: ?*const vk.Pipeline.ColorBlend.State.Create.Info = null,
        p_dynamic_state: ?*const vk.Pipeline.DynamicState.Create.Info = null,
        layout: vk.Pipeline.Layout = .NULL_HANDLE,
        render_pass: vk.RenderPass = .NULL_HANDLE,
        subpass: u32,
        base_pipeline_handle: vk.Pipeline = .NULL_HANDLE,
        base_pipeline_index: i32,
      };
    };
  };

  pub const Pipelines = extern struct
  {
    pub fn create (device: vk.Device, pipeline_cache: vk.Pipeline.Cache, create_info_count: u32, p_create_infos: [*] const vk.Graphics.Pipeline.Create.Info, p_allocator: ?*const vk.AllocationCallbacks, p_pipelines: [*] vk.Pipeline) !void
    {
      const result = raw.prototypes.device.vkCreateGraphicsPipelines (device, pipeline_cache, create_info_count, p_create_infos, p_allocator, p_pipelines);
      if (result > 0)
      {
        std.debug.print ("{s} failed with {} status code\n", .{ @typeName (@This ()) ++ "." ++ @src ().fn_name, result, });
        return error.UnexpectedResult;
      }
    }
  };
};
