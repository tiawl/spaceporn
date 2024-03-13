const std     = @import ("std");
const builtin = @import ("builtin");
const c       = @import ("c");

const vk = @This ();

const raw = @import ("prototypes.zig");
pub const EXT = @import ("ext.zig").EXT;
pub const KHR = @import ("khr.zig").KHR;

pub const call_conv: std.builtin.CallingConvention = if (builtin.os.tag == .windows and builtin.cpu.arch == .x86)
  .Stdcall
else if (builtin.abi == .android and (builtin.cpu.arch.isARM () or builtin.cpu.arch.isThumb ()) and std.Target.arm.featureSetHas (builtin.cpu.features, .has_v7) and builtin.cpu.arch.ptrBitWidth () == 32)
  // On Android 32-bit ARM targets, Vulkan functions use the "hardfloat"
  // calling convention, i.e. float parameters are passed in registers. This
  // is true even if the rest of the application passes floats on the stack,
  // as it does by default when compiling for the armeabi-v7a NDK ABI.
  .AAPCSVFP
else
  .C;

pub fn load () !void
{
  const loader: *const fn (vk.Instance, [*:0] const u8) callconv (vk.call_conv) ?*const fn () callconv (vk.call_conv) void = @ptrCast (&c.glfwGetInstanceProcAddress);
  inline for (std.meta.fields (@TypeOf (raw.prototypes.structless))) |field|
  {
    const name: [*:0] const u8 = @ptrCast (field.name ++ "\x00");
    const pointer = loader (vk.Instance.NULL_HANDLE, name) orelse return error.CommandLoadFailure;
    @field (raw.prototypes.structless, field.name) = @ptrCast (pointer);
  }
}

pub const API_VERSION = extern struct
{
  pub const @"1" = enum
  {
    pub const @"0" = c.VK_API_VERSION_1_0;
    pub const @"1" = c.VK_API_VERSION_1_1;
    pub const @"2" = c.VK_API_VERSION_1_2;
    pub const @"3" = c.VK_API_VERSION_1_3;
  };
};

pub const MAX_EXTENSION_NAME_SIZE = c.VK_MAX_EXTENSION_NAME_SIZE;
pub const MAX_DESCRIPTION_SIZE = c.VK_MAX_DESCRIPTION_SIZE;

pub const AllocationCallbacks = extern struct
{
  p_user_data: ?*anyopaque = null,
  pfn_allocation: ?*const fn (?*anyopaque, usize, usize, vk.SystemAllocationScope) callconv (vk.call_conv) ?*anyopaque,
  pfn_reallocation: ?*const fn (?*anyopaque, ?*anyopaque, usize, usize, vk.SystemAllocationScope) callconv (vk.call_conv) ?*anyopaque,
  pfn_free: ?*const fn (?*anyopaque, ?*anyopaque) callconv (vk.call_conv) void,
  pfn_internal_allocation: ?*const fn (?*anyopaque, usize, vk.InternalAllocationType, vk.SystemAllocationScope) callconv (vk.call_conv) void = null,
  pfn_internal_free: ?*const fn (?*anyopaque, usize, vk.InternalAllocationType, vk.SystemAllocationScope) callconv (vk.call_conv) void = null,
};

pub const ApplicationInfo = extern struct
{
  s_type: vk.StructureType = .APPLICATION_INFO,
  p_next: ?*const anyopaque = null,
  p_application_name: ?[*:0] const u8 = null,
  application_version: u32,
  p_engine_name: ?[*:0] const u8 = null,
  engine_version: u32,
  api_version: u32,
};

pub const Bool32 = u32;
pub const Buffer = enum (u64) { NULL_HANDLE = 0, _, };

pub const Command = extern struct
{
  pub const Buffer = enum (usize) { NULL_HANDLE = 0, _, };
  pub const Pool = enum (u64) { NULL_HANDLE = 0, _, };
};

pub const Descriptor = extern struct
{
  pub const Pool = enum (u64) { NULL_HANDLE = 0, _, };
  pub const Set = enum (u64)
  {
    NULL_HANDLE = 0, _,
    pub const Layout = enum (u64) { NULL_HANDLE = 0, _, };
  };
};

pub const Device = enum (usize)
{
  NULL_HANDLE = 0, _,
  pub const Memory = enum (u64) { NULL_HANDLE = 0, _, };

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
};

pub const ExtensionProperties = extern struct
{
  extension_name: [vk.MAX_EXTENSION_NAME_SIZE] u8,
  spec_version: u32,
};

pub const Extent2D = extern struct
{
  width: u32,
  height: u32,
};

pub const Fence = enum (u64) { NULL_HANDLE = 0, _, };

pub const Format = enum (i32)
{
  UNDEFINED = c.VK_FORMAT_UNDEFINED,
  R4G4_UNORM_PACK8 = c.VK_FORMAT_R4G4_UNORM_PACK8,
  _,
};

pub const Framebuffer = enum (u64) { NULL_HANDLE = 0, _, };

pub const Image = enum (u64)
{
  NULL_HANDLE = 0, _,

  pub const Usage = extern struct
  {
    pub const Flags = extern struct
    {
      pub const TRANSFER_SRC_BIT = c.VK_IMAGE_USAGE_TRANSFER_SRC_BIT;
    };
  };

  pub const View = enum (u64) { NULL_HANDLE = 0, _, };
};

pub const Instance = enum (usize)
{
  NULL_HANDLE = 0, _,

  pub fn create (p_create_info: *const vk.Instance.Create.Info, p_allocator: ?*const vk.AllocationCallbacks) !@This ()
  {
    var instance: vk.Instance = undefined;
    const result = raw.prototypes.structless.vkCreateInstance (p_create_info, p_allocator, &instance);
    if (result > 0)
    {
      std.debug.print ("{s} failed with {} status code\n", .{ @typeName (@This ()) ++ "." ++ @src ().fn_name, result, });
      return error.UnexpectedResult;
    }
    return instance;
  }

  pub fn destroy (self: @This (), p_allocator: ?*const vk.AllocationCallbacks) void
  {
    raw.prototypes.instance.vkDestroyInstance (self, p_allocator);
  }

  pub fn load (self: @This ()) !void
  {
    const loader: *const fn (vk.Instance, [*:0] const u8) callconv (vk.call_conv) ?*const fn () callconv (vk.call_conv) void = @ptrCast (&raw.prototypes.structless.vkGetInstanceProcAddr);
    inline for (std.meta.fields (@TypeOf (raw.prototypes.instance))) |field|
    {
      const name: [*:0] const u8 = @ptrCast (field.name ++ "\x00");
      const pointer = loader (self, name) orelse return error.CommandLoadFailure;
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
    pub fn enumerate (p_layer_name: ?[*:0] const u8, p_property_count: *u32, p_properties: ?[*] vk.ExtensionProperties) !void
    {
      const result = raw.prototypes.structless.vkEnumerateInstanceExtensionProperties (p_layer_name, p_property_count, p_properties);
      if (result > 0)
      {
        std.debug.print ("{s} failed with {} status code\n", .{ @typeName (@This ()) ++ "." ++ @src ().fn_name, result, });
        return error.UnexpectedResult;
      }
    }
  };

  pub const LayerProperties = extern struct
  {
    pub fn enumerate (p_property_count: *u32, p_properties: ?[*] vk.LayerProperties) !void
    {
      const result = raw.prototypes.structless.vkEnumerateInstanceLayerProperties (p_property_count, p_properties);
      if (result > 0)
      {
        std.debug.print ("{s} failed with {} status code\n", .{ @typeName (@This ()) ++ "." ++ @src ().fn_name, result, });
        return error.UnexpectedResult;
      }
    }
  };
};

pub const InternalAllocationType = enum (i32) {};

pub const LayerProperties = extern struct
{
  layer_name: [vk.MAX_EXTENSION_NAME_SIZE] u8,
  spec_version: u32,
  implementation_version: u32,
  description: [vk.MAX_DESCRIPTION_SIZE] u8,
};

pub const ObjectType = enum (i32)
{
  unknown = 0,
};

pub const Offset2D = extern struct
{
  x: i32,
  y: i32,
};

pub const PhysicalDevice = enum (usize) { NULL_HANDLE = 0, _, };

pub const Pipeline = enum (u64)
{
  NULL_HANDLE = 0, _,
  pub const Layout = enum (u64) { NULL_HANDLE = 0, _, };
};

pub const Queue = enum (usize) { NULL_HANDLE = 0, _, };

pub const Rect2D = extern struct
{
  offset: vk.Offset2D,
  extent: vk.Extent2D,
};

pub const RenderPass = enum (u64) { NULL_HANDLE = 0, _, };
pub const Sampler = enum (u64) { NULL_HANDLE = 0, _, };
pub const Semaphore = enum (u64) { NULL_HANDLE = 0, _, };

pub const StructureType = enum (i32)
{
  APPLICATION_INFO = c.VK_STRUCTURE_TYPE_APPLICATION_INFO,
  DEBUG_UTILS_LABEL_EXT = c.VK_STRUCTURE_TYPE_DEBUG_UTILS_LABEL_EXT,
  DEBUG_UTILS_MESSENGER_CREATE_INFO_EXT = c.VK_STRUCTURE_TYPE_DEBUG_UTILS_MESSENGER_CREATE_INFO_EXT,
  DEBUG_UTILS_MESSENGER_CALLBACK_DATA_EXT = c.VK_STRUCTURE_TYPE_DEBUG_UTILS_MESSENGER_CALLBACK_DATA_EXT,
  DEBUG_UTILS_OBJECT_NAME_INFO_EXT = c.VK_STRUCTURE_TYPE_DEBUG_UTILS_OBJECT_NAME_INFO_EXT,
  INSTANCE_CREATE_INFO = c.VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO,
  VALIDATION_FEATURES_EXT = c.VK_STRUCTURE_TYPE_VALIDATION_FEATURES_EXT,
};

pub const SystemAllocationScope = enum (i32) {};

pub const Viewport = extern struct
{
  x: f32,
  y: f32,
  width: f32,
  height: f32,
  min_depth: f32,
  max_depth: f32,
};
