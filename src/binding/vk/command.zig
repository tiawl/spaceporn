const std = @import ("std");
const c   = @import ("c");

const vk  = @import ("vk");
const raw = @import ("raw");

pub const Command = extern struct
{
  pub const Buffer = enum (usize) { NULL_HANDLE = vk.NULL_HANDLE, _, };

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

    pub fn create (device: vk.Device, p_create_info: *const vk.Command.Pool.Create.Info, p_allocator: ?*const vk.AllocationCallbacks) !vk.Command.Pool
    {
      var command_pool: vk.Command.Pool = undefined;
      const result = raw.prototypes.device.vkCreateCommandPool (device, p_create_info, p_allocator, &command_pool);
      if (result > 0)
      {
        std.debug.print ("{s} failed with {} status code\n", .{ @typeName (@This ()) ++ "." ++ @src ().fn_name, result, });
        return error.UnexpectedResult;
      }
      return command_pool;
    }

    pub fn destroy (device: vk.Device, command_pool: vk.Command.Pool, p_allocator: ?*const vk.AllocationCallbacks) void
    {
      raw.prototypes.device.vkDestroyCommandPool (device, command_pool, p_allocator);
    }
  };
};
