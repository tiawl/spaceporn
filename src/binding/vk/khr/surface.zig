const std = @import ("std");
const c   = @import ("c");

const vk  = @import ("vk");
const raw = @import ("raw");

pub const Surface = enum (u64)
{
  NULL_HANDLE = vk.NULL_HANDLE, _,
  pub const Capabilities = extern struct
  {
    min_image_count: u32,
    max_image_count: u32,
    current_extent: vk.Extent2D,
    min_image_extent: vk.Extent2D,
    max_image_extent: vk.Extent2D,
    max_image_array_layers: u32,
    supported_transforms: vk.KHR.Surface.Transform.Flags,
    current_transform: vk.KHR.Surface.Transform.Flags,
    supported_composite_alpha: vk.KHR.CompositeAlpha.Flags,
    supported_usage_flags: vk.Image.Usage.Flags,
  };

  pub const Format = extern struct
  {
    format: vk.Format,
    color_space: vk.KHR.ColorSpace,
  };

  pub const Transform = extern struct
  {
    pub const Flags = u32;

    pub const Bit = enum (vk.KHR.Surface.Transform.Flags)
    {
      IDENTITY = c.VK_SURFACE_TRANSFORM_IDENTITY_BIT_KHR,
    };
  };

  pub fn destroy (surface: @This (),instance: vk.Instance) void
  {
    const p_allocator: ?*const vk.AllocationCallbacks = null;
    raw.prototypes.instance.vkDestroySurfaceKHR (instance, surface,
      p_allocator);
  }
};
