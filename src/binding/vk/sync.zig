const std = @import ("std");
const c   = @import ("c");

const vk  = @import ("vk");
const raw = @import ("raw");

pub const Fence = enum (u64)
{
  NULL_HANDLE = vk.NULL_HANDLE, _,

  pub const Create = extern struct
  {
    pub const Flags = u32;

    pub const Bit = enum (vk.Fence.Create.Flags)
    {
      SIGNALED = c.VK_FENCE_CREATE_SIGNALED_BIT,
    };

    pub const Info = extern struct
    {
      s_type: vk.StructureType = .FENCE_CREATE_INFO,
      p_next: ?*const anyopaque = null,
      flags: vk.Semaphore.Create.Flags = 0,
    };
  };

  pub fn create (device: vk.Device, p_create_info: *const vk.Fence.Create.Info, p_allocator: ?*const vk.AllocationCallbacks) !@This ()
  {
    var fence: @This () = undefined;
    const result = raw.prototypes.device.vkCreateFence (device, p_create_info, p_allocator, &fence);
    if (result > 0)
    {
      std.debug.print ("{s} failed with {} status code\n", .{ @typeName (@This ()) ++ "." ++ @src ().fn_name, result, });
      return error.UnexpectedResult;
    }
    return fence;
  }

  pub fn destroy (fence: @This (), device: vk.Device, p_allocator: ?*const vk.AllocationCallbacks) void
  {
    raw.prototypes.device.vkDestroyFence (device, fence, p_allocator);
  }
};

pub const Semaphore = enum (u64)
{
  NULL_HANDLE = vk.NULL_HANDLE, _,

  pub const Create = extern struct
  {
    pub const Flags = u32;

    pub const Info = extern struct
    {
      s_type: vk.StructureType = .SEMAPHORE_CREATE_INFO,
      p_next: ?*const anyopaque = null,
      flags: vk.Semaphore.Create.Flags = 0,
    };
  };

  pub fn create (device: vk.Device, p_create_info: *const vk.Semaphore.Create.Info, p_allocator: ?*const vk.AllocationCallbacks) !@This ()
  {
    var semaphore: @This () = undefined;
    const result = raw.prototypes.device.vkCreateSemaphore (device, p_create_info, p_allocator, &semaphore);
    if (result > 0)
    {
      std.debug.print ("{s} failed with {} status code\n", .{ @typeName (@This ()) ++ "." ++ @src ().fn_name, result, });
      return error.UnexpectedResult;
    }
    return semaphore;
  }

  pub fn destroy (semaphore: @This (), device: vk.Device, p_allocator: ?*const vk.AllocationCallbacks) void
  {
    raw.prototypes.device.vkDestroySemaphore (device, semaphore, p_allocator);
  }
};
