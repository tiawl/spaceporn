const std = @import ("std");
const c   = @import ("c");

const vk  = @import ("vk");
const raw = @import ("raw");

pub const Image = enum (u64)
{
  NULL_HANDLE = vk.NULL_HANDLE, _,

  pub const Aspect = extern struct
  {
    pub const Flags = u32;

    pub const Bit = enum (vk.Image.Aspect.Flags)
    {
      COLOR = c.VK_IMAGE_ASPECT_COLOR_BIT,
    };
  };

  pub const Create = extern struct
  {
    pub const Flags = u32;

    pub const Info = extern struct
    {
      s_type: vk.StructureType = .IMAGE_CREATE_INFO,
      p_next: ?*const anyopaque = null,
      flags: vk.Image.Create.Flags = 0,
      image_type: vk.Image.Type,
      format: vk.Format,
      extent: vk.Extent3D,
      mip_levels: u32,
      array_layers: u32,
      samples: vk.Sample.Count.Flags,
      tiling: vk.Image.Tiling,
      usage: vk.Image.Usage.Flags,
      sharing_mode: vk.SharingMode,
      queue_family_index_count: u32 = 0,
      p_queue_family_indices: ?[*] const u32 = null,
      initial_layout: vk.Image.Layout,
    };
  };

  pub const Layout = enum (i32)
  {
    UNDEFINED = c.VK_IMAGE_LAYOUT_UNDEFINED,
    PRESENT_SRC_KHR = c.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR,
    COLOR_ATTACHMENT_OPTIMAL = c.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
    SHADER_READ_ONLY_OPTIMAL = c.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
  };

  pub const Memory = extern struct
  {
    pub const Requirements = extern struct
    {
      pub fn get (device: vk.Device, image: vk.Image) vk.Memory.Requirements
      {
        var memory_requirements: vk.Memory.Requirements = undefined;
        raw.prototypes.device.vkGetImageMemoryRequirements (device, image, &memory_requirements);
        return memory_requirements;
      }
    };

    pub fn bind (device: vk.Device, image: vk.Image, memory: vk.Device.Memory, memory_offset: vk.Device.Size) !void
    {
      const result = raw.prototypes.device.vkBindImageMemory (device, image, memory, memory_offset);
      if (result > 0)
      {
        std.debug.print ("{s} failed with {} status code\n", .{ @typeName (@This ()) ++ "." ++ @src ().fn_name, result, });
        return error.UnexpectedResult;
      }
    }
  };

  pub const SubresourceRange = extern struct
  {
    aspect_mask: vk.Image.Aspect.Flags,
    base_mip_level: u32,
    level_count: u32,
    base_array_layer: u32,
    layer_count: u32,
  };

  pub const Tiling = enum (i32)
  {
    OPTIMAL = c.VK_IMAGE_TILING_OPTIMAL,
  };

  pub const Type = enum (i32)
  {
    @"2D" = c.VK_IMAGE_TYPE_2D,
  };

  pub const Usage = extern struct
  {
    pub const Flags = u32;

    pub const Bit = enum (vk.Image.Usage.Flags)
    {
      COLOR_ATTACHMENT = c.VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT,
      TRANSFER_DST = c.VK_IMAGE_USAGE_TRANSFER_DST_BIT,
      TRANSFER_SRC = c.VK_IMAGE_USAGE_TRANSFER_SRC_BIT,
      SAMPLED = c.VK_IMAGE_USAGE_SAMPLED_BIT,
    };
  };

  pub const View = enum (u64)
  {
    NULL_HANDLE = vk.NULL_HANDLE, _,

    pub fn create (device: vk.Device, p_create_info: *const vk.Image.View.Create.Info, p_allocator: ?*const vk.AllocationCallbacks) !@This ()
    {
      var view: vk.Image.View = undefined;
      const result = raw.prototypes.device.vkCreateImageView (device, p_create_info, p_allocator, &view);
      if (result > 0)
      {
        std.debug.print ("{s} failed with {} status code\n", .{ @typeName (@This ()) ++ "." ++ @src ().fn_name, result, });
        return error.UnexpectedResult;
      }
      return view;
    }

    pub fn destroy (image_view: @This (),device: vk.Device, p_allocator: ?*const vk.AllocationCallbacks) void
    {
      raw.prototypes.device.vkDestroyImageView (device, image_view, p_allocator);
    }

    pub const Create = extern struct
    {
      pub const Flags = u32;

      pub const Bit = enum (vk.Image.View.Create.Flags) {};

      pub const Info = extern struct
      {
        s_type: vk.StructureType = .IMAGE_VIEW_CREATE_INFO,
        p_next: ?*const anyopaque = null,
        flags: vk.Image.View.Create.Flags = 0,
        image: vk.Image,
        view_type: vk.Image.View.Type,
        format: vk.Format,
        components: vk.Component.Mapping,
        subresource_range: vk.Image.SubresourceRange,
      };
    };

    pub const Type = enum (i32)
    {
      @"2D" = c.VK_IMAGE_VIEW_TYPE_2D,
    };
  };

  pub fn create (device: vk.Device, p_create_info: *const vk.Image.Create.Info, p_allocator: ?*const vk.AllocationCallbacks) !@This ()
  {
    var image: vk.Image = undefined;
    const result = raw.prototypes.device.vkCreateImage (device, p_create_info, p_allocator, &image);
    if (result > 0)
    {
      std.debug.print ("{s} failed with {} status code\n", .{ @typeName (@This ()) ++ "." ++ @src ().fn_name, result, });
      return error.UnexpectedResult;
    }
    return image;
  }

  pub fn destroy (image: @This (), device: vk.Device, p_allocator: ?*const vk.AllocationCallbacks) void
  {
    raw.prototypes.device.vkDestroyImage (device, image, p_allocator);
  }
};
