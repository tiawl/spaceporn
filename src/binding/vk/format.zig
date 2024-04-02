const std = @import ("std");
const c   = @import ("c");

const vk  = @import ("vk");
const raw = @import ("raw");

pub const Format = enum (u32)
{
  A8B8G8R8_UNORM_PACK32 = c.VK_FORMAT_A8B8G8R8_UNORM_PACK32,
  B8G8R8A8_SRGB = c.VK_FORMAT_B8G8R8A8_SRGB,
  B8G8R8A8_UNORM = c.VK_FORMAT_B8G8R8A8_UNORM,
  R8G8B8_UNORM = c.VK_FORMAT_R8G8B8_UNORM,
  R8G8B8A8_UNORM = c.VK_FORMAT_R8G8B8A8_UNORM,
  _,

  pub const Feature = extern struct
  {
    pub const Flags = u32;

    pub const Bit = enum (vk.Format.Feature.Flags)
    {
      BLIT_SRC = c.VK_FORMAT_FEATURE_BLIT_SRC_BIT,
      BLIT_DST = c.VK_FORMAT_FEATURE_BLIT_DST_BIT,

      pub fn contains (self: @This (), flags: vk.Format.Feature.Flags) bool
      {
        return (flags & @intFromEnum (self)) == @intFromEnum (self);
      }
    };
  };

  pub const Properties = extern struct
  {
    linear_tiling_features: vk.Format.Feature.Flags = 0,
    optimal_tiling_features: vk.Format.Feature.Flags = 0,
    buffer_features: vk.Format.Feature.Flags = 0,
  };
};
