const std = @import ("std");
const c   = @import ("c");

const vk  = @import ("vk");
const raw = @import ("raw");

pub const Instance = enum (usize)
{
  NULL_HANDLE = vk.NULL_HANDLE, _,

  pub fn create (p_create_info: *const vk.Instance.Create.Info) !@This ()
  {
    var instance: @This () = undefined;
    const p_allocator: ?*const vk.AllocationCallbacks = null;
    const result = raw.prototypes.structless.vkCreateInstance (p_create_info,
      p_allocator, &instance);
    if (result > 0)
    {
      std.debug.print ("{s} failed with {} status code\n",
        .{ @typeName (@This ()) ++ "." ++ @src ().fn_name, result, });
      return error.UnexpectedResult;
    }
    return instance;
  }

  pub fn destroy (self: @This ()) void
  {
    const p_allocator: ?*const vk.AllocationCallbacks = null;
    raw.prototypes.instance.vkDestroyInstance (self, p_allocator);
  }

  pub fn load (self: @This ()) !void
  {
    inline for (std.meta.fields (@TypeOf (raw.prototypes.instance))) |field|
    {
      const name: [*:0] const u8 = @ptrCast (field.name ++ "\x00");
      const pointer = raw.prototypes.structless.vkGetInstanceProcAddr (
        self, name) orelse return error.CommandLoadFailure;
      @field (raw.prototypes.instance, field.name) = @ptrCast (pointer);
    }
  }

  pub const Create = extern struct
  {
    pub const Flags = u32;
    pub const Info = extern struct
    {
      s_type: vk.StructureType = .INSTANCE_CREATE_INFO,
      p_next: ?*const anyopaque = null,
      flags: vk.Instance.Create.Flags = 0,
      p_application_info: ?*const vk.ApplicationInfo = null,
      enabled_layer_count: u32 = 0,
      pp_enabled_layer_names: ?[*] const [*:0] const u8 = null,
      enabled_extension_count: u32 = 0,
      pp_enabled_extension_names: ?[*] const [*:0] const u8 = null,
    };
  };

  pub const ExtensionProperties = extern struct
  {
    pub fn enumerate (p_layer_name: ?[*:0] const u8, p_property_count: *u32,
      p_properties: ?[*] vk.ExtensionProperties) !void
    {
      const result =
        raw.prototypes.structless.vkEnumerateInstanceExtensionProperties (
          p_layer_name, p_property_count, p_properties);
      if (result > 0)
      {
        std.debug.print ("{s} failed with {} status code\n",
          .{ @typeName (@This ()) ++ "." ++ @src ().fn_name, result, });
        return error.UnexpectedResult;
      }
    }
  };

  pub const LayerProperties = extern struct
  {
    pub fn enumerate (p_property_count: *u32,
      p_properties: ?[*] vk.LayerProperties) !void
    {
      const result =
        raw.prototypes.structless.vkEnumerateInstanceLayerProperties (
          p_property_count, p_properties);
      if (result > 0)
      {
        std.debug.print ("{s} failed with {} status code\n",
          .{ @typeName (@This ()) ++ "." ++ @src ().fn_name, result, });
        return error.UnexpectedResult;
      }
    }
  };
};
