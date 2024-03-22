const std = @import ("std");
const c   = @import ("c");

const vk  = @import ("vk");
const raw = @import ("raw");

pub const Image = enum (u64)
{
  NULL_HANDLE = 0, _,

  pub const Aspect = extern struct
  {
    pub const Flags = u32;

    pub const Bit = enum (vk.Image.Aspect.Flags)
    {
      COLOR = c.VK_IMAGE_ASPECT_COLOR_BIT,
    };
  };

  pub const SubresourceRange = extern struct
  {
    aspect_mask: vk.Image.Aspect.Flags,
    base_mip_level: u32,
    level_count: u32,
    base_array_layer: u32,
    layer_count: u32,
  };

  pub const Usage = extern struct
  {
    pub const Flags = u32;

    pub const Bit = enum (vk.Image.Usage.Flags)
    {
      COLOR_ATTACHMENT = c.VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT,
      TRANSFER_DST = c.VK_IMAGE_USAGE_TRANSFER_DST_BIT,
      TRANSFER_SRC = c.VK_IMAGE_USAGE_TRANSFER_SRC_BIT,
    };
  };

  pub const View = enum (u64)
  {
    NULL_HANDLE = 0, _,

    pub fn create (device: vk.Device, p_create_info: *const vk.Image.View.Create.Info, p_allocator: ?*const vk.AllocationCallbacks) !vk.Image.View
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

    pub fn destroy (device: vk.Device, image_view: vk.Image.View, p_allocator: ?*const vk.AllocationCallbacks) void
    {
      raw.prototypes.device.vkDestroyImageView (device, image_view, p_allocator);
    }

    pub const Create = extern struct
    {
      pub const Flags = u32;

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
};
