const std = @import ("std");
const c   = @import ("c");

const vk  = @import ("vk");
const raw = @import ("raw");

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
