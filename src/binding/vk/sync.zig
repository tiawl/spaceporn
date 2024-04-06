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

  pub fn create (device: vk.Device,
    p_create_info: *const vk.Fence.Create.Info) !@This ()
  {
    var fence: @This () = undefined;
    const p_allocator: ?*const vk.AllocationCallbacks = null;
    const result = raw.prototypes.device.vkCreateFence (device, p_create_info,
      p_allocator, &fence);
    if (result > 0)
    {
      std.debug.print ("{s} failed with {} status code\n",
        .{ @typeName (@This ()) ++ "." ++ @src ().fn_name, result, });
      return error.UnexpectedResult;
    }
    return fence;
  }

  pub fn destroy (fence: @This (), device: vk.Device) void
  {
    const p_allocator: ?*const vk.AllocationCallbacks = null;
    raw.prototypes.device.vkDestroyFence (device, fence, p_allocator);
  }
};

pub const Fences = extern struct
{
  pub fn reset (device: vk.Device, fence_count: u32,
    p_fences: [*] const vk.Fence) !void
  {
    const result = raw.prototypes.device.vkResetFences (device, fence_count,
      p_fences);
    if (result > 0)
    {
      std.debug.print ("{s} failed with {} status code\n",
        .{ @typeName (@This ()) ++ "." ++ @src ().fn_name, result, });
      return error.UnexpectedResult;
    }
  }

  pub fn waitFor (device: vk.Device, fence_count: u32,
    p_fences: [*] const vk.Fence, wait_all: vk.Bool32, timeout: u64) !void
  {
    const result = raw.prototypes.device.vkWaitForFences (device, fence_count,
      p_fences, wait_all, timeout);
    if (result > 0)
    {
      std.debug.print ("{s} failed with {} status code\n",
        .{ @typeName (@This ()) ++ "." ++ @src ().fn_name, result, });
      return error.UnexpectedResult;
    }
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

  pub fn create (device: vk.Device,
    p_create_info: *const vk.Semaphore.Create.Info) !@This ()
  {
    var semaphore: @This () = undefined;
    const p_allocator: ?*const vk.AllocationCallbacks = null;
    const result = raw.prototypes.device.vkCreateSemaphore (device,
      p_create_info, p_allocator, &semaphore);
    if (result > 0)
    {
      std.debug.print ("{s} failed with {} status code\n",
        .{ @typeName (@This ()) ++ "." ++ @src ().fn_name, result, });
      return error.UnexpectedResult;
    }
    return semaphore;
  }

  pub fn destroy (semaphore: @This (), device: vk.Device) void
  {
    const p_allocator: ?*const vk.AllocationCallbacks = null;
    raw.prototypes.device.vkDestroySemaphore (device, semaphore, p_allocator);
  }
};
