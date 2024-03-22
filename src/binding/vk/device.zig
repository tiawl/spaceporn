const std = @import ("std");
const c   = @import ("c");

const vk  = @import ("vk");
const raw = @import ("raw");

pub const Device = enum (usize)
{
  NULL_HANDLE = 0, _,
  pub const Memory = enum (u64) { NULL_HANDLE = 0, _, };
  pub const Size = u64;

  pub fn load (self: @This ()) !void
  {
    const loader: *const fn (vk.Device, [*:0] const u8) callconv (vk.call_conv) ?*const fn () callconv (vk.call_conv) void = @ptrCast (&raw.prototypes.instance.vkGetDeviceProcAddr);
    inline for (std.meta.fields (@TypeOf (raw.prototypes.device))) |field|
    {
      const name: [*:0] const u8 = @ptrCast (field.name ++ "\x00");
      const pointer = loader (self, name) orelse return error.CommandLoadFailure;
      @field (raw.prototypes.device, field.name) = @ptrCast (pointer);
    }
  }

  pub fn create (physical_device: vk.PhysicalDevice, p_create_info: *const vk.Device.Create.Info, p_allocator: ?*const vk.AllocationCallbacks) !vk.Device
  {
    var device: Device = undefined;
    const result = raw.prototypes.instance.vkCreateDevice (physical_device, p_create_info, p_allocator, &device);
    if (result > 0)
    {
      std.debug.print ("{s} failed with {} status code\n", .{ @typeName (@This ()) ++ "." ++ @src ().fn_name, result, });
      return error.UnexpectedResult;
    }
    return device;
  }

  pub fn destroy (self: @This (), p_allocator: ?*const vk.AllocationCallbacks) void
  {
    raw.prototypes.device.vkDestroyDevice (self, p_allocator);
  }

  pub const Create = extern struct
  {
    pub const Flags = u32;
    pub const Info = extern struct
    {
      s_type: vk.StructureType = .DEVICE_CREATE_INFO,
      p_next: ?*const anyopaque = null,
      flags: vk.Device.Create.Flags = 0,
      queue_create_info_count: u32,
      p_queue_create_infos: [*] const vk.Device.Queue.Create.Info,
      enabled_layer_count: u32 = 0,
      pp_enabled_layer_names: ?[*] const [*:0] const u8 = null,
      enabled_extension_count: u32 = 0,
      pp_enabled_extension_names: ?[*] const [*:0]const u8 = null,
      p_enabled_features: ?*const vk.PhysicalDevice.Features = null,
    };
  };

  pub const ExtensionProperties = extern struct
  {
    pub fn enumerate (physical_device: vk.PhysicalDevice, p_layer_name: ?[*:0] const u8, p_property_count: *u32, p_properties: ?[*] vk.ExtensionProperties) !void
    {
      const result = raw.prototypes.structless.vkEnumerateDeviceExtensionProperties (physical_device, p_layer_name, p_property_count, p_properties);
      if (result > 0)
      {
        std.debug.print ("{s} failed with {} status code\n", .{ @typeName (@This ()) ++ "." ++ @src ().fn_name, result, });
        return error.UnexpectedResult;
      }
    }
  };

  pub const Queue = extern struct
  {
    pub fn get (device: vk.Device, queue_family_index: u32, queue_index: u32) vk.Queue
    {
      var queue: vk.Queue = undefined;
      raw.prototypes.device.vkGetDeviceQueue (device, queue_family_index, queue_index, &queue);
      return queue;
    }

    pub const Create = extern struct
    {
      pub const Flags = u32;

      pub const Info = extern struct
      {
        s_type: vk.StructureType = .DEVICE_QUEUE_CREATE_INFO,
        p_next: ?*const anyopaque = null,
        flags: vk.Device.Queue.Create.Flags = 0,
        queue_family_index: u32,
        queue_count: u32,
        p_queue_priorities: [*] const f32,
      };
    };
  };
};

