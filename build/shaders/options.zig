const std = @import ("std");

pub const Options = struct
{
  pub const Optimization = enum
  {
    Zero,
    Size,
    Performance,
  };

  pub const VulkanEnvVersion = enum
  {
    @"0", @"1", @"2", @"3",
  };

  optimization: Optimization,
  vulkan_env_version: VulkanEnvVersion,

  pub fn to_args (self: @This ()) [] const [] const u8
  {
    return &.{ @tagName (self.optimization),
      @tagName (self.vulkan_env_version), };
  }
};
