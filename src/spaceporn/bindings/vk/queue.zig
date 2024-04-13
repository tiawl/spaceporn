const std = @import ("std");
const c   = @import ("c");

const vk  = @import ("vk");
const raw = @import ("raw");

pub const Queue = enum (usize)
{
  NULL_HANDLE = vk.NULL_HANDLE, _,

  pub const Flags = u32;

  pub const Bit = enum (vk.Queue.Flags)
  {
    GRAPHICS = c.VK_QUEUE_GRAPHICS_BIT,

    pub fn contains (self: @This (), flags: vk.Queue.Flags) bool
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

  pub fn presentKHR (queue: @This (),
    p_present_info: *const vk.KHR.Present.Info) !void
  {
    const result = raw.prototypes.device.vkQueuePresentKHR (queue,
      p_present_info);
    if (result == c.VK_ERROR_OUT_OF_DATE_KHR) return error.OutOfDateKHR;
    if (result > 0)
    {
      std.debug.print ("{s} failed with {} status code\n",
        .{ @typeName (@This ()) ++ "." ++ @src ().fn_name, result, });
      return error.UnexpectedResult;
    }
  }

  pub fn submit (queue: @This (), submit_count: u32,
    p_submits: ?[*] const vk.Submit.Info, fence: vk.Fence) !void
  {
    const result = raw.prototypes.device.vkQueueSubmit (queue, submit_count,
      p_submits, fence);
    if (result > 0)
    {
      std.debug.print ("{s} failed with {} status code\n",
        .{ @typeName (@This ()) ++ "." ++ @src ().fn_name, result, });
      return error.UnexpectedResult;
    }
  }

  pub fn waitIdle (queue: @This ()) !void
  {
    const result = raw.prototypes.device.vkQueueWaitIdle (queue);
    if (result > 0)
    {
      std.debug.print ("{s} failed with {} status code\n",
        .{ @typeName (@This ()) ++ "." ++ @src ().fn_name, result, });
      return error.UnexpectedResult;
    }
  }
};
