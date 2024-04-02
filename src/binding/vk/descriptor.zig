const std = @import ("std");
const c   = @import ("c");

const vk  = @import ("vk");
const raw = @import ("raw");

pub const Descriptor = extern struct
{
  pub const Pool = enum (u64) { NULL_HANDLE = vk.NULL_HANDLE, _, };

  pub const Set = enum (u64)
  {
    NULL_HANDLE = vk.NULL_HANDLE, _,

    pub const Layout = enum (u64)
    {
      NULL_HANDLE = vk.NULL_HANDLE, _,

      pub const Binding = extern struct
      {
        binding: u32,
        descriptor_type: vk.Descriptor.Type,
        descriptor_count: u32 = 0,
        stage_flags: vk.ShaderStage.Flags,
        p_immutable_samplers: ?[*] const vk.Sampler = null,
      };

      pub const Create = extern struct
      {
        pub const Flags = u32;

        pub const Info = extern struct
        {
          s_type: vk.StructureType = .DESCRIPTOR_SET_LAYOUT_CREATE_INFO,
          p_next: ?*const anyopaque = null,
          flags: vk.Descriptor.Set.Layout.Create.Flags = 0,
          binding_count: u32 = 0,
          p_bindings: ?[*] const vk.Descriptor.Set.Layout.Binding = null,
        };
      };
      pub fn create (device: vk.Device, p_create_info: *const vk.Descriptor.Set.Layout.Create.Info, p_allocator: ?*const vk.AllocationCallbacks) !vk.Descriptor.Set.Layout
      {
        var set_layout: vk.Descriptor.Set.Layout = undefined;
        const result = raw.prototypes.device.vkCreateDescriptorSetLayout (device, p_create_info, p_allocator, &set_layout);
        if (result > 0)
        {
          std.debug.print ("{s} failed with {} status code\n", .{ @typeName (@This ()) ++ "." ++ @src ().fn_name, result, });
          return error.UnexpectedResult;
        }
        return set_layout;
      }

      pub fn destroy (device: vk.Device, descriptor_set_layout: vk.Descriptor.Set.Layout, p_allocator: ?*const vk.AllocationCallbacks) void
      {
        raw.prototypes.device.vkDestroyDescriptorSetLayout(device, descriptor_set_layout, p_allocator);
      }
    };
  };

  pub const Type = enum (i32)
  {
    UNIFORM_BUFFER = c.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
    COMBINED_IMAGE_SAMPLER = c.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
  };
};
