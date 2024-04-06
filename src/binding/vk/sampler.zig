const std = @import ("std");
const c   = @import ("c");

const vk  = @import ("vk");
const raw = @import ("raw");

pub const Sampler = enum (u64)
{
  NULL_HANDLE = vk.NULL_HANDLE, _,

  pub const AddressMode = enum (i32)
  {
    CLAMP_TO_BORDER = c.VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_BORDER,
  };

  pub const Create = extern struct
  {
    pub const Flags = u32;

    pub const Info = extern struct
    {
      s_type: vk.StructureType = .SAMPLER_CREATE_INFO,
      p_next: ?*const anyopaque = null,
      flags: vk.Sampler.Create.Flags = 0,
      mag_filter: vk.Filter,
      min_filter: vk.Filter,
      mipmap_mode: vk.Sampler.MipmapMode,
      address_mode_u: vk.Sampler.AddressMode,
      address_mode_v: vk.Sampler.AddressMode,
      address_mode_w: vk.Sampler.AddressMode,
      mip_lod_bias: f32,
      anisotropy_enable: vk.Bool32,
      max_anisotropy: f32,
      compare_enable: vk.Bool32,
      compare_op: vk.CompareOp,
      min_lod: f32,
      max_lod: f32,
      border_color: vk.BorderColor,
      unnormalized_coordinates: vk.Bool32,
    };
  };

  pub const MipmapMode = enum (i32)
  {
    LINEAR = c.VK_SAMPLER_MIPMAP_MODE_LINEAR,
  };

  pub fn create (device: vk.Device,
    p_create_info: *const vk.Sampler.Create.Info) !@This ()
  {
    var sampler: @This () = undefined;
    const p_allocator: ?*const vk.AllocationCallbacks = null;
    const result = raw.prototypes.device.vkCreateSampler (device,
      p_create_info, p_allocator, &sampler);
    if (result > 0)
    {
      std.debug.print ("{s} failed with {} status code\n",
        .{ @typeName (@This ()) ++ "." ++ @src ().fn_name, result, });
      return error.UnexpectedResult;
    }
    return sampler;
  }

  pub fn destroy (sampler: @This (), device: vk.Device) void
  {
    const p_allocator: ?*const vk.AllocationCallbacks = null;
    raw.prototypes.device.vkDestroySampler (device, sampler, p_allocator);
  }
};
