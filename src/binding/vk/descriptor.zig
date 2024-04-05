const std = @import ("std");
const c   = @import ("c");

const vk  = @import ("vk");
const raw = @import ("raw");

pub const Copy = extern struct
{
  pub const Descriptor = extern struct
  {
    pub const Set = extern struct
    {
      s_type: vk.StructureType = .COPY_DESCRIPTOR_SET,
      p_next: ?*const anyopaque = null,
      src_set: vk.Descriptor.Set,
      src_binding: u32,
      src_array_element: u32,
      dst_set: vk.Descriptor.Set,
      dst_binding: u32,
      dst_array_element: u32,
      descriptor_count: u32,
    };
  };
};

pub const Descriptor = extern struct
{
  pub const Buffer = extern struct
  {
    pub const Info = extern struct
    {
      buffer: vk.Buffer = .NULL_HANDLE,
      offset: vk.Device.Size,
      range: vk.Device.Size,
    };
  };

  pub const Image = extern struct
  {
    pub const Info = extern struct
    {
      sampler: vk.Sampler,
      image_view: vk.Image.View,
      image_layout: vk.Image.Layout,
    };
  };

  pub const Pool = enum (u64)
  {
    NULL_HANDLE = vk.NULL_HANDLE, _,

    pub const Create = extern struct
    {
      pub const Flags = u32;

      pub const Bit = enum (vk.Descriptor.Pool.Create.Flags)
      {
        FREE_DESCRIPTOR_SET = c.VK_DESCRIPTOR_POOL_CREATE_FREE_DESCRIPTOR_SET_BIT,
      };

      pub const Info = extern struct
      {
        s_type: vk.StructureType = .DESCRIPTOR_POOL_CREATE_INFO,
        p_next: ?*const anyopaque = null,
        flags: vk.Descriptor.Pool.Create.Flags = 0,
        max_sets: u32,
        pool_size_count: u32 = 0,
        p_pool_sizes: ?[*] const vk.Descriptor.Pool.Size = null,
      };
    };

    pub const Size = extern struct
    {
      type: vk.Descriptor.Type,
      descriptor_count: u32,
    };

    pub fn create (device: vk.Device, p_create_info: *const vk.Descriptor.Pool.Create.Info, p_allocator: ?*const vk.AllocationCallbacks) !@This ()
    {
      var descriptor_pool: @This () = undefined;
      const result = raw.prototypes.device.vkCreateDescriptorPool (device, p_create_info, p_allocator, &descriptor_pool);
      if (result > 0)
      {
        std.debug.print ("{s} failed with {} status code\n", .{ @typeName (@This ()) ++ "." ++ @src ().fn_name, result, });
        return error.UnexpectedResult;
      }
      return descriptor_pool;
    }

    pub fn destroy (descriptor_pool: @This (), device: vk.Device, p_allocator: ?*const vk.AllocationCallbacks) void
    {
      raw.prototypes.device.vkDestroyDescriptorPool (device, descriptor_pool, p_allocator);
    }
  };

  pub const Set = enum (u64)
  {
    NULL_HANDLE = vk.NULL_HANDLE, _,

    pub const Allocate = extern struct
    {
      pub const Info = extern struct
      {
        s_type: vk.StructureType = .DESCRIPTOR_SET_ALLOCATE_INFO,
        p_next: ?*const anyopaque = null,
        descriptor_pool: vk.Descriptor.Pool,
        descriptor_set_count: u32,
        p_set_layouts: [*] const vk.Descriptor.Set.Layout,
      };
    };

    pub const Layout = enum (u64)
    {
      NULL_HANDLE = vk.NULL_HANDLE, _,

      pub const Binding = extern struct
      {
        binding: u32,
        descriptor_type: vk.Descriptor.Type,
        descriptor_count: u32 = 0,
        stage_flags: vk.Shader.Stage.Flags,
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

      pub fn create (device: vk.Device, p_create_info: *const vk.Descriptor.Set.Layout.Create.Info, p_allocator: ?*const vk.AllocationCallbacks) !@This ()
      {
        var set_layout: @This () = undefined;
        const result = raw.prototypes.device.vkCreateDescriptorSetLayout (device, p_create_info, p_allocator, &set_layout);
        if (result > 0)
        {
          std.debug.print ("{s} failed with {} status code\n", .{ @typeName (@This ()) ++ "." ++ @src ().fn_name, result, });
          return error.UnexpectedResult;
        }
        return set_layout;
      }

      pub fn destroy (descriptor_set_layout: @This (), device: vk.Device, p_allocator: ?*const vk.AllocationCallbacks) void
      {
        raw.prototypes.device.vkDestroyDescriptorSetLayout(device, descriptor_set_layout, p_allocator);
      }
    };
  };

  pub const Sets = extern struct
  {
    pub fn allocate (device: vk.Device, p_allocate_info: *const vk.Descriptor.Set.Allocate.Info, p_descriptor_sets: [*] vk.Descriptor.Set) !void
    {
      const result = raw.prototypes.device.vkAllocateDescriptorSets (device, p_allocate_info, p_descriptor_sets);
      if (result > 0)
      {
        std.debug.print ("{s} failed with {} status code\n", .{ @typeName (@This ()) ++ "." ++ @src ().fn_name, result, });
        return error.UnexpectedResult;
      }
    }

    pub fn update (device: vk.Device, descriptor_write_count: u32, p_descriptor_writes: ?[*] const vk.Write.Descriptor.Set, descriptor_copy_count: u32, p_descriptor_copies: ?[*] const vk.Copy.Descriptor.Set) void
    {
      raw.prototypes.device.vkUpdateDescriptorSets (device, descriptor_write_count, p_descriptor_writes, descriptor_copy_count, p_descriptor_copies);
    }
  };

  pub const Type = enum (i32)
  {
    UNIFORM_BUFFER = c.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
    COMBINED_IMAGE_SAMPLER = c.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
  };
};

pub const Write = extern struct
{
  pub const Descriptor = extern struct
  {
    pub const Set = extern struct
    {
      s_type: vk.StructureType = .WRITE_DESCRIPTOR_SET,
      p_next: ?*const anyopaque = null,
      dst_set: vk.Descriptor.Set,
      dst_binding: u32,
      dst_array_element: u32,
      descriptor_count: u32,
      descriptor_type: vk.Descriptor.Type,
      p_image_info: [*] const vk.Descriptor.Image.Info,
      p_buffer_info: [*] const vk.Descriptor.Buffer.Info,
      p_texel_buffer_view: [*] const vk.Buffer.View,
    };
  };
};
