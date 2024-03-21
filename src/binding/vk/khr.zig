const std = @import ("std");
const c   = @import ("c");

const vk  = @import ("vk.zig");
const raw = @import ("prototypes.zig");

pub const KHR = extern struct
{
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

  pub const PhysicalDevice = extern struct
  {
    pub const Surface = extern struct
    {
      pub const Capabilities = extern struct
      {
        pub fn get (physical_device: vk.PhysicalDevice, surface: vk.KHR.Surface) !vk.KHR.Surface.Capabilities
        {
          var surface_capabilities: vk.KHR.Surface.Capabilities = undefined;
          const result = raw.prototypes.instance.vkGetPhysicalDeviceSurfaceCapabilitiesKHR (physical_device, surface, &surface_capabilities);
          if (result > 0)
          {
            std.debug.print ("{s} failed with {} status code\n", .{ @typeName (@This ()) ++ "." ++ @src ().fn_name, result, });
            return error.UnexpectedResult;
          }
          return surface_capabilities;
        }
      };

      pub const Formats = extern struct
      {
        pub fn get (physical_device: vk.PhysicalDevice, surface: vk.KHR.Surface, p_surface_format_count: *u32, p_surface_formats: ?[*] vk.KHR.Surface.Format) !void
        {
          const result = raw.prototypes.instance.vkGetPhysicalDeviceSurfaceFormatsKHR (physical_device, surface, p_surface_format_count, p_surface_formats);
          if (result > 0)
          {
            std.debug.print ("{s} failed with {} status code\n", .{ @typeName (@This ()) ++ "." ++ @src ().fn_name, result, });
            return error.UnexpectedResult;
          }
        }
      };

      pub const PresentModes = extern struct
      {
        pub fn get (physical_device: vk.PhysicalDevice, surface: vk.KHR.Surface, p_present_mode_count: *u32, p_present_modes: ?[*] vk.KHR.PresentMode) !void
        {
          const result = raw.prototypes.instance.vkGetPhysicalDeviceSurfacePresentModesKHR (physical_device, surface, p_present_mode_count, @ptrCast (@alignCast (p_present_modes)));
          if (result > 0)
          {
            std.debug.print ("{s} failed with {} status code\n", .{ @typeName (@This ()) ++ "." ++ @src ().fn_name, result, });
            return error.UnexpectedResult;
          }
        }
      };

      pub const Support = extern struct
      {
        pub fn get (physical_device: vk.PhysicalDevice, queue_family_index: u32, surface: vk.KHR.Surface) !vk.Bool32
        {
          var supported: vk.Bool32 = undefined;
          const result = raw.prototypes.instance.vkGetPhysicalDeviceSurfaceSupportKHR (physical_device, queue_family_index, surface, &supported);
          if (result > 0)
          {
            std.debug.print ("{s} failed with {} status code\n", .{ @typeName (@This ()) ++ "." ++ @src ().fn_name, result, });
            return error.UnexpectedResult;
          }
          return supported;
        }
      };
    };
  };

  pub const PresentMode = enum (i32)
  {
    FIFO = c.VK_PRESENT_MODE_FIFO_KHR,
    IMMEDIATE = c.VK_PRESENT_MODE_IMMEDIATE_KHR,
    MAILBOX = c.VK_PRESENT_MODE_MAILBOX_KHR,
  };

  pub const Surface = enum (u64)
  {
    NULL_HANDLE = 0, _,
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

  pub const Swapchain = enum (u64)
  {
    NULL_HANDLE = 0, _,

    pub fn create (device: vk.Device, p_create_info: *const vk.KHR.Swapchain.Create.Info, p_allocator: ?*const vk.AllocationCallbacks) !vk.KHR.Swapchain
    {
      var swapchain: vk.KHR.Swapchain = undefined;
      const result = raw.prototypes.device.vkCreateSwapchainKHR (device, p_create_info, p_allocator, &swapchain);
      if (result > 0)
      {
        std.debug.print ("{s} failed with {} status code\n", .{ @typeName (@This ()) ++ "." ++ @src ().fn_name, result, });
        return error.UnexpectedResult;
      }
      return swapchain;
    }

    pub fn destroy (device: vk.Device, swapchain: vk.KHR.Swapchain, p_allocator: ?*const vk. AllocationCallbacks) void
    {
      raw.prototypes.device.vkDestroySwapchainKHR (device, swapchain, p_allocator);
    }

    pub const Create = extern struct
    {
      pub const Flags = u32;
      pub const Info = extern struct
      {
        s_type: vk.StructureType = .SWAPCHAIN_CREATE_INFO_KHR,
        p_next: ?*const anyopaque = null,
        flags: vk.KHR.Swapchain.Create.Flags = 0,
        surface: vk.KHR.Surface,
        min_image_count: u32,
        image_format: vk.Format,
        image_color_space: vk.KHR.ColorSpace,
        image_extent: vk.Extent2D,
        image_array_layers: u32,
        image_usage: vk.Image.Usage.Flags,
        image_sharing_mode: vk.SharingMode,
        queue_family_index_count: u32 = 0,
        p_queue_family_indices: ?[*] const u32 = null,
        pre_transform: vk.KHR.Surface.Transform.Flags,
        composite_alpha: vk.KHR.CompositeAlpha.Flags,
        present_mode: vk.KHR.PresentMode,
        clipped: vk.Bool32,
        old_swapchain: vk.KHR.Swapchain = .NULL_HANDLE,
      };
    };

    pub const Images = extern struct
    {
      pub fn get (device: vk.Device, swapchain: vk.KHR.Swapchain, p_swapchain_image_count: *u32, p_swapchain_images: ?[*] vk.Image) !void
      {
        const result = raw.prototypes.device.vkGetSwapchainImagesKHR (device, swapchain, p_swapchain_image_count, p_swapchain_images);
        if (result > 0)
        {
          std.debug.print ("{s} failed with {} status code\n", .{ @typeName (@This ()) ++ "." ++ @src ().fn_name, result, });
          return error.UnexpectedResult;
        }
      }
    };
  };
};
