const std = @import ("std");
const c   = @import ("c");

const vk  = @import ("vk");
const raw = @import ("raw");

pub const Swapchain = enum (u64)
{
  NULL_HANDLE = vk.NULL_HANDLE, _,

  pub fn create (device: vk.Device,
    p_create_info: *const vk.KHR.Swapchain.Create.Info) !@This ()
  {
    var swapchain: @This () = undefined;
    const p_allocator: ?*const vk.AllocationCallbacks = null;
    const result = raw.prototypes.device.vkCreateSwapchainKHR (device,
      p_create_info, p_allocator, &swapchain);
    if (result > 0)
    {
      std.debug.print ("{s} failed with {} status code\n",
        .{ @typeName (@This ()) ++ "." ++ @src ().fn_name, result, });
      return error.UnexpectedResult;
    }
    return swapchain;
  }

  pub fn destroy (swapchain: @This (), device: vk.Device) void
  {
    const p_allocator: ?*const vk.AllocationCallbacks = null;
    raw.prototypes.device.vkDestroySwapchainKHR (device, swapchain,
      p_allocator);
  }

  pub const Create = extern struct
  {
    pub const Flags = u32;
    pub const Info = extern struct
    {
      s_type: vk.StructureType = .SWAPCHAIN_CREATE_INFO_KHR,
      p_next: ?*const anyopaque = null,
      flags: vk.KHR.Swapchain.Create.Flags = 0,
      surface: vk.KHR.Surface,
      min_image_count: u32,
      image_format: vk.Format,
      image_color_space: vk.KHR.ColorSpace,
      image_extent: vk.Extent2D,
      image_array_layers: u32,
      image_usage: vk.Image.Usage.Flags,
      image_sharing_mode: vk.SharingMode,
      queue_family_index_count: u32 = 0,
      p_queue_family_indices: ?[*] const u32 = null,
      pre_transform: vk.KHR.Surface.Transform.Flags,
      composite_alpha: vk.KHR.CompositeAlpha.Flags,
      present_mode: vk.KHR.Present.Mode,
      clipped: vk.Bool32,
      old_swapchain: vk.KHR.Swapchain = .NULL_HANDLE,
    };
  };

  pub const Images = extern struct
  {
    pub fn get (device: vk.Device, swapchain: vk.KHR.Swapchain,
      p_swapchain_image_count: *u32, p_swapchain_images: ?[*] vk.Image) !void
    {
      const result = raw.prototypes.device.vkGetSwapchainImagesKHR (device,
        swapchain, p_swapchain_image_count, p_swapchain_images);
      if (result > 0)
      {
        std.debug.print ("{s} failed with {} status code\n",
          .{ @typeName (@This ()) ++ "." ++ @src ().fn_name, result, });
        return error.UnexpectedResult;
      }
    }
  };
};
