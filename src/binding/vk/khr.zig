const std = @import ("std");
const c   = @import ("c");

const vk  = @import ("vk");

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

pub const PhysicalDevice = @import ("physical_device").PhysicalDevice;

pub const PresentMode = enum (i32)
{
  FIFO = c.VK_PRESENT_MODE_FIFO_KHR,
  IMMEDIATE = c.VK_PRESENT_MODE_IMMEDIATE_KHR,
  MAILBOX = c.VK_PRESENT_MODE_MAILBOX_KHR,
};

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
};

pub const Swapchain = @import ("swapchain").Swapchain;
