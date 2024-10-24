const std = @import ("std");
const c   = @import ("c");

const vk  = @import ("vk");
const raw = @import ("raw");

pub const Buffer = enum (u64)
{
  NULL_HANDLE = vk.NULL_HANDLE, _,

  pub const Copy = extern struct
  {
    src_offset: vk.Device.Size,
    dst_offset: vk.Device.Size,
    size: vk.Device.Size,
  };

  pub const Create = extern struct
  {
    pub const Flags = u32;

    pub const Info = extern struct
    {
      s_type: vk.StructureType = .BUFFER_CREATE_INFO,
      p_next: ?*const anyopaque = null,
      flags: vk.Buffer.Create.Flags = 0,
      size: vk.Device.Size,
      usage: vk.Buffer.Usage.Flags,
      sharing_mode: vk.SharingMode,
      queue_family_index_count: u32 = 0,
      p_queue_family_indices: ?[*] const u32 = null,
    };
  };

  pub const Memory = extern struct
  {
    pub const Barrier = extern struct
    {
      s_type: vk.StructureType = .BUFFER_MEMORY_BARRIER,
      p_next: ?*const anyopaque = null,
      src_access_mask: vk.Access.Flags,
      dst_access_mask: vk.Access.Flags,
      src_queue_family_index: u32,
      dst_queue_family_index: u32,
      buffer: vk.Buffer,
      offset: vk.Device.Size,
      size: vk.Device.Size,
    };

    pub const Requirements = extern struct
    {
      pub fn get (device: vk.Device, buffer: vk.Buffer) vk.Memory.Requirements
      {
        var memory_requirements: vk.Memory.Requirements = undefined;
        raw.prototypes.device.vkGetBufferMemoryRequirements (device, buffer,
          &memory_requirements);
        return memory_requirements;
      }
    };

    pub fn bind (device: vk.Device, buffer: vk.Buffer, memory: vk.Device.Memory,
      memory_offset: vk.Device.Size) !void
    {
      const result = raw.prototypes.device.vkBindBufferMemory (device, buffer,
        memory, memory_offset);
      if (result > 0)
      {
        std.debug.print ("{s} failed with {} status code\n",
          .{ @typeName (@This ()) ++ "." ++ @src ().fn_name, result, });
        return error.UnexpectedResult;
      }
    }
  };

  pub const Usage = extern struct
  {
    pub const Flags = u32;

    pub const Bit = enum (vk.Buffer.Usage.Flags)
    {
      INDEX_BUFFER = c.VK_BUFFER_USAGE_INDEX_BUFFER_BIT,
      TRANSFER_DST = c.VK_BUFFER_USAGE_TRANSFER_DST_BIT,
      TRANSFER_SRC = c.VK_BUFFER_USAGE_TRANSFER_SRC_BIT,
      UNIFORM_BUFFER = c.VK_BUFFER_USAGE_UNIFORM_BUFFER_BIT,
      VERTEX_BUFFER = c.VK_BUFFER_USAGE_VERTEX_BUFFER_BIT,
    };
  };

  pub const View = enum (u64) { NULL_HANDLE = vk.NULL_HANDLE, _, };

  pub fn create (device: vk.Device,
    p_create_info: *const vk.Buffer.Create.Info) !@This ()
  {
    var buffer: @This () = undefined;
    const p_allocator: ?*const vk.AllocationCallbacks = null;
    const result = raw.prototypes.device.vkCreateBuffer (device, p_create_info,
      p_allocator, &buffer);
    if (result > 0)
    {
      std.debug.print ("{s} failed with {} status code\n",
        .{ @typeName (@This ()) ++ "." ++ @src ().fn_name, result, });
      return error.UnexpectedResult;
    }
    return buffer;
  }

  pub fn destroy (buffer: @This (), device: vk.Device) void
  {
    const p_allocator: ?*const vk.AllocationCallbacks = null;
    raw.prototypes.device.vkDestroyBuffer (device, buffer, p_allocator);
  }
};
