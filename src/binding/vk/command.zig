const std = @import ("std");
const c   = @import ("c");

const vk  = @import ("vk");
const raw = @import ("raw");

pub const Command = extern struct
{
  pub const Buffer = enum (usize)
  {
    NULL_HANDLE = vk.NULL_HANDLE, _,

    pub const Allocate = extern struct
    {
      pub const Info = extern struct
      {
        s_type: vk.StructureType = .COMMAND_BUFFER_ALLOCATE_INFO,
        p_next: ?*const anyopaque = null,
        command_pool: vk.Command.Pool,
        level: vk.Command.Buffer.Level,
        command_buffer_count: u32,
      };
    };

    pub const Begin = extern struct
    {
      pub const Info = extern struct
      {
        s_type: vk.StructureType = .COMMAND_BUFFER_BEGIN_INFO,
        p_next: ?*const anyopaque = null,
        flags: vk.Command.Buffer.Usage.Flags = 0,
        p_inheritance_info: ?*const vk.Command.Buffer.Inheritance.Info = null,
      };
    };

    pub const Inheritance = extern struct
    {
      pub const Info = extern struct
      {
        s_type: vk.StructureType = .COMMAND_BUFFER_INHERITANCE_INFO,
        p_next: ?*const anyopaque = null,
        render_pass: vk.RenderPass = .NULL_HANDLE,
        subpass: u32,
        framebuffer: vk.Framebuffer = .NULL_HANDLE,
        occlusion_query_enable: vk.Bool32,
        query_flags: vk.Query.Control.Flags = 0,
        pipeline_statistics: vk.Query.PipelineStatistic.Flags = 0,
      };
    };

    pub const Level = enum (i32)
    {
      PRIMARY = c.VK_COMMAND_BUFFER_LEVEL_PRIMARY,
    };

    pub const Reset = extern struct
    {
      pub const Flags = u32;
    };

    pub const Usage = extern struct
    {
      pub const Flags = u32;

      pub const Bit = enum (vk.Command.Buffer.Usage.Flags)
      {
        ONE_TIME_SUBMIT = c.VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT,
      };
    };

    pub fn begin (command_buffer: @This (),
      p_begin_info: *const vk.Command.Buffer.Begin.Info) !void
    {
      const result = raw.prototypes.device.vkBeginCommandBuffer (
        command_buffer, p_begin_info);
      if (result > 0)
      {
        std.debug.print ("{s} failed with {} status code\n",
          .{ @typeName (@This ()) ++ "." ++ @src ().fn_name, result, });
        return error.UnexpectedResult;
      }
    }

    pub fn end (command_buffer: @This ()) !void
    {
      const result = raw.prototypes.device.vkEndCommandBuffer (command_buffer);
      if (result > 0)
      {
        std.debug.print ("{s} failed with {} status code\n",
          .{ @typeName (@This ()) ++ "." ++ @src ().fn_name, result, });
        return error.UnexpectedResult;
      }
    }

    pub fn begin_render_pass (command_buffer: @This (),
      p_render_pass_begin: *const vk.RenderPass.Begin.Info,
      contents: vk.Subpass.Contents) void
    {
      raw.prototypes.device.vkCmdBeginRenderPass (command_buffer,
        p_render_pass_begin, @intFromEnum (contents));
    }

    pub fn end_render_pass (command_buffer: @This ()) void
    {
      raw.prototypes.device.vkCmdEndRenderPass (command_buffer);
    }

    pub fn blit_image (command_buffer: @This (), src_image: vk.Image,
      src_image_layout: vk.Image.Layout, dst_image: vk.Image,
      dst_image_layout: vk.Image.Layout, region_count: u32,
      p_regions: [*] const vk.Image.Blit, filter: vk.Filter) void
    {
      raw.prototypes.device.vkCmdBlitImage (command_buffer, src_image,
        @intFromEnum (src_image_layout), dst_image,
        @intFromEnum (dst_image_layout), region_count, p_regions,
        @intFromEnum (filter));
    }

    pub fn bind_descriptor_sets (command_buffer: @This (),
      pipeline_bind_point: vk.Pipeline.BindPoint, layout: vk.Pipeline.Layout,
      first_set: u32, descriptor_set_count: u32,
      p_descriptor_sets: [*] const vk.Descriptor.Set,
      dynamic_offset_count: u32, p_dynamic_offsets: ?[*]const u32) void
    {
      raw.prototypes.device.vkCmdBindDescriptorSets (command_buffer,
        @intFromEnum (pipeline_bind_point), layout, first_set,
        descriptor_set_count, p_descriptor_sets, dynamic_offset_count,
        p_dynamic_offsets);
    }

    pub fn bind_index_buffer (command_buffer: @This (), buffer: vk.Buffer,
      offset: vk.Device.Size, index_type: vk.IndexType) void
    {
      raw.prototypes.device.vkCmdBindIndexBuffer (command_buffer, buffer,
        offset, @intFromEnum (index_type));
    }

    pub fn bind_pipeline (command_buffer: @This (),
      pipeline_bind_point: vk.Pipeline.BindPoint, pipeline: vk.Pipeline) void
    {
      raw.prototypes.device.vkCmdBindPipeline (command_buffer,
        @intFromEnum (pipeline_bind_point), pipeline);
    }

    pub fn bind_vertex_buffers (command_buffer: @This (), first_binding: u32,
      binding_count: u32, p_buffers: [*] const vk.Buffer,
      p_offsets: [*] const vk.Device.Size) void
    {
      raw.prototypes.device.vkCmdBindVertexBuffers (command_buffer,
        first_binding, binding_count, p_buffers, p_offsets);
    }

    pub fn copy_buffer (command_buffer: @This (), src_buffer: vk.Buffer,
      dst_buffer: vk.Buffer, region_count: u32,
      p_regions: [*] const vk.Buffer.Copy) void
    {
      raw.prototypes.device.vkCmdCopyBuffer (command_buffer, src_buffer,
        dst_buffer, region_count, p_regions);
    }

    pub fn copy_image (command_buffer: vk.Command.Buffer, src_image: vk.Image,
      src_image_layout: vk.Image.Layout, dst_image: vk.Image,
      dst_image_layout: vk.Image.Layout, region_count: u32,
      p_regions: [*] const vk.Image.Copy) void
    {
      raw.prototypes.device.vkCmdCopyImage (command_buffer, src_image,
        @intFromEnum (src_image_layout), dst_image,
        @intFromEnum (dst_image_layout), region_count, p_regions);
    }

    pub fn draw_indexed (command_buffer: @This (), index_count: u32,
      instance_count: u32, first_index: u32, vertex_offset: i32,
      first_instance: u32) void
    {
      raw.prototypes.device.vkCmdDrawIndexed (command_buffer, index_count,
        instance_count, first_index, vertex_offset, first_instance);
    }

    pub fn pipeline_barrier (command_buffer: @This (),
      src_stage_mask: vk.Pipeline.Stage.Flags,
      dst_stage_mask: vk.Pipeline.Stage.Flags,
      dependency_flags: vk.Dependency.Flags, memory_barrier_count: u32,
      p_memory_barriers: ?[*] const vk.Memory.Barrier,
      buffer_memory_barrier_count: u32,
      p_buffer_memory_barriers: ?[*] const vk.Buffer.Memory.Barrier,
      image_memory_barrier_count: u32,
      p_image_memory_barriers: ?[*] const vk.Image.Memory.Barrier) void
    {
      raw.prototypes.device.vkCmdPipelineBarrier (command_buffer,
        src_stage_mask, dst_stage_mask, dependency_flags, memory_barrier_count,
        p_memory_barriers, buffer_memory_barrier_count,
        p_buffer_memory_barriers, image_memory_barrier_count,
        p_image_memory_barriers);
    }

    pub fn reset (command_buffer: @This (),
      flags: vk.Command.Buffer.Reset.Flags) !void
    {
      const result = raw.prototypes.device.vkResetCommandBuffer (
        command_buffer, flags);
      if (result > 0)
      {
        std.debug.print ("{s} failed with {} status code\n",
          .{ @typeName (@This ()) ++ "." ++ @src ().fn_name, result, });
        return error.UnexpectedResult;
      }
    }

    pub fn set_scissor (command_buffer: @This (), first_scissor: u32,
      scissor_count: u32, p_scissors: [*] const vk.Rect2D) void
    {
      raw.prototypes.device.vkCmdSetScissor (command_buffer, first_scissor,
        scissor_count, p_scissors);
    }

    pub fn set_viewport (command_buffer: @This (), first_viewport: u32,
      viewport_count: u32, p_viewports: [*] const vk.Viewport) void
    {
      raw.prototypes.device.vkCmdSetViewport (command_buffer, first_viewport,
        viewport_count, p_viewports);
    }
  };

  pub const Buffers = extern struct
  {
    pub fn allocate (device: vk.Device,
      p_allocate_info: *const vk.Command.Buffer.Allocate.Info,
      p_command_buffers: [*] vk.Command.Buffer) !void
    {
      const result = raw.prototypes.device.vkAllocateCommandBuffers (device,
        p_allocate_info, p_command_buffers);
      if (result > 0)
      {
        std.debug.print ("{s} failed with {} status code\n",
          .{ @typeName (@This ()) ++ "." ++ @src ().fn_name, result, });
        return error.UnexpectedResult;
      }
    }

    pub fn free (device: vk.Device, command_pool: vk.Command.Pool,
      command_buffer_count: u32,
      p_command_buffers: [*] const vk.Command.Buffer) void
    {
      raw.prototypes.device.vkFreeCommandBuffers (device, command_pool,
        command_buffer_count, p_command_buffers);
    }
  };

  pub const Pool = enum (u64)
  {
    NULL_HANDLE = vk.NULL_HANDLE, _,

    pub const Create = extern struct
    {
      pub const Flags = u32;

      pub const Bit = enum (vk.Command.Pool.Create.Flags)
      {
        RESET_COMMAND_BUFFER = c.VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT,
        TRANSIENT = c.VK_COMMAND_POOL_CREATE_TRANSIENT_BIT,
      };

      pub const Info = extern struct
      {
        s_type: vk.StructureType = .COMMAND_POOL_CREATE_INFO,
        p_next: ?*const anyopaque = null,
        flags: vk.Command.Pool.Create.Flags = 0,
        queue_family_index: u32,
      };
    };

    pub const Reset = extern struct
    {
      pub const Flags = u32;
    };

    pub fn create (device: vk.Device,
      p_create_info: *const vk.Command.Pool.Create.Info) !@This ()
    {
      var command_pool: @This () = undefined;
      const p_allocator: ?*const vk.AllocationCallbacks = null;
      const result = raw.prototypes.device.vkCreateCommandPool (device,
        p_create_info, p_allocator, &command_pool);
      if (result > 0)
      {
        std.debug.print ("{s} failed with {} status code\n",
          .{ @typeName (@This ()) ++ "." ++ @src ().fn_name, result, });
        return error.UnexpectedResult;
      }
      return command_pool;
    }

    pub fn destroy (command_pool: @This (), device: vk.Device) void
    {
      const p_allocator: ?*const vk.AllocationCallbacks = null;
      raw.prototypes.device.vkDestroyCommandPool (device, command_pool,
        p_allocator);
    }

    pub fn reset (command_pool: @This (), device: vk.Device,
      flags: vk.Command.Pool.Reset.Flags) !void
    {
      const result = raw.prototypes.device.vkResetCommandPool (device,
        command_pool, flags);
      if (result > 0)
      {
        std.debug.print ("{s} failed with {} status code\n",
          .{ @typeName (@This ()) ++ "." ++ @src ().fn_name, result, });
        return error.UnexpectedResult;
      }
    }
  };
};
