const std = @import ("std");
const c   = @import ("c");

const vk  = @import ("vk");
const raw = @import ("raw");

pub const SHADER_NON_SEMANTIC_INFO = c.VK_KHR_SHADER_NON_SEMANTIC_INFO_EXTENSION_NAME;
pub const SWAPCHAIN = c.VK_KHR_SWAPCHAIN_EXTENSION_NAME;

pub const ColorSpace = enum (i32)
{
  SRGB_NONLINEAR = c.VK_COLOR_SPACE_SRGB_NONLINEAR_KHR,
};

pub const CompositeAlpha = extern struct
{
  pub const Flags = u32;

  pub const Bit = enum (vk.KHR.CompositeAlpha.Flags)
  {
    OPAQUE = c.VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR,
  };
};

pub const NextImage = extern struct
{
  pub fn acquire (device: vk.Device, swapchain: vk.KHR.Swapchain, timeout: u64,
    semaphore: vk.Semaphore, fence: vk.Fence) !u32
  {
    var image_index: u32 = undefined;
    const result = raw.prototypes.device.vkAcquireNextImageKHR (device,
      swapchain, timeout, semaphore, fence, &image_index);
    if (result == c.VK_ERROR_OUT_OF_DATE_KHR)
    {
      return error.OutOfDateKHR;
    } else if (result > 0 and result != c.VK_SUBOPTIMAL_KHR) {
      std.debug.print ("{s} failed with {} status code\n",
        .{ @typeName (@This ()) ++ "." ++ @src ().fn_name, result, });
      return error.UnexpectedResult;
    } else return image_index;
  }
};

pub const PhysicalDevice = @import ("physical_device").PhysicalDevice;

pub const Present = extern struct
{
  pub const Mode = enum (i32)
  {
    FIFO = c.VK_PRESENT_MODE_FIFO_KHR,
    IMMEDIATE = c.VK_PRESENT_MODE_IMMEDIATE_KHR,
    MAILBOX = c.VK_PRESENT_MODE_MAILBOX_KHR,
  };

  pub const Info = extern struct
  {
    s_type: vk.StructureType = .PRESENT_INFO_KHR,
    p_next: ?*const anyopaque = null,
    wait_semaphore_count: u32 = 0,
    p_wait_semaphores: ?[*] const vk.Semaphore = null,
    swapchain_count: u32,
    p_swapchains: [*] const vk.KHR.Swapchain,
    p_image_indices: [*] const u32,
    p_results: ?[*] i32 = null,
  };
};

pub const Surface = @import ("surface").Surface;
pub const Swapchain = @import ("swapchain").Swapchain;
