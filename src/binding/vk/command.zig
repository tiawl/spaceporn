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

    pub const Usage = extern struct
    {
      pub const Flags = u32;

      pub const Bit = enum (vk.Command.Buffer.Usage.Flags)
      {
        ONE_TIME_SUBMIT = c.VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT,
      };
    };

    pub fn begin (command_buffer: @This (), p_begin_info: *const vk.Command.Buffer.Begin.Info) !void
    {
      const result = raw.prototypes.device.vkBeginCommandBuffer (command_buffer, p_begin_info);
      if (result > 0)
      {
        std.debug.print ("{s} failed with {} status code\n", .{ @typeName (@This ()) ++ "." ++ @src ().fn_name, result, });
        return error.UnexpectedResult;
      }
    }

    pub fn end (command_buffer: @This ()) !void
    {
      const result = raw.prototypes.device.vkEndCommandBuffer (command_buffer);
      if (result > 0)
      {
        std.debug.print ("{s} failed with {} status code\n", .{ @typeName (@This ()) ++ "." ++ @src ().fn_name, result, });
        return error.UnexpectedResult;
      }
    }

    pub fn copy_buffer (command_buffer: @This (), src_buffer: vk.Buffer, dst_buffer: vk.Buffer, region_count: u32, p_regions: [*] const vk.Buffer.Copy) void
    {
      raw.prototypes.device.vkCmdCopyBuffer (command_buffer, src_buffer, dst_buffer, region_count, p_regions);
    }
  };

  pub const Buffers = extern struct
  {
    pub fn allocate (device: vk.Device, p_allocate_info: *const vk.Command.Buffer.Allocate.Info, p_command_buffers: [*] vk.Command.Buffer) !void
    {
      const result = raw.prototypes.device.vkAllocateCommandBuffers (device, p_allocate_info, p_command_buffers);
      if (result > 0)
      {
        std.debug.print ("{s} failed with {} status code\n", .{ @typeName (@This ()) ++ "." ++ @src ().fn_name, result, });
        return error.UnexpectedResult;
      }
    }

    pub fn free (device: vk.Device, command_pool: vk.Command.Pool, command_buffer_count: u32, p_command_buffers: [*] const vk.Command.Buffer) void
    {
      raw.prototypes.device.vkFreeCommandBuffers (device, command_pool, command_buffer_count, p_command_buffers);
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

    pub fn create (device: vk.Device, p_create_info: *const vk.Command.Pool.Create.Info, p_allocator: ?*const vk.AllocationCallbacks) !@This ()
    {
      var command_pool: @This () = undefined;
      const result = raw.prototypes.device.vkCreateCommandPool (device, p_create_info, p_allocator, &command_pool);
      if (result > 0)
      {
        std.debug.print ("{s} failed with {} status code\n", .{ @typeName (@This ()) ++ "." ++ @src ().fn_name, result, });
        return error.UnexpectedResult;
      }
      return command_pool;
    }

    pub fn destroy (command_pool: @This (), device: vk.Device, p_allocator: ?*const vk.AllocationCallbacks) void
    {
      raw.prototypes.device.vkDestroyCommandPool (device, command_pool, p_allocator);
    }

    pub fn reset (command_pool: @This (), device: vk.Device, flags: vk.Command.Pool.Reset.Flags) !void
    {
      const result = raw.prototypes.device.vkResetCommandPool (device, command_pool, flags);
      if (result > 0)
      {
        std.debug.print ("{s} failed with {} status code\n", .{ @typeName (@This ()) ++ "." ++ @src ().fn_name, result, });
        return error.UnexpectedResult;
      }
    }
  };
};
