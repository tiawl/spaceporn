const c = @import ("c");

pub const vk = struct
{
  pub const SurfaceKHR = enum (u64) { null_handle = 0, _ };
};

pub usingnamespace vk;
