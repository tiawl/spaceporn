const std     = @import ("std");
const builtin = @import ("builtin");
const c       = @import ("c");

const vk = @This ();

const raw = @import ("raw");
pub const EXT = @import ("ext");
pub const KHR = @import ("khr");

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

pub const MAX_DESCRIPTION_SIZE = c.VK_MAX_DESCRIPTION_SIZE;
pub const MAX_EXTENSION_NAME_SIZE = c.VK_MAX_EXTENSION_NAME_SIZE;
pub const MAX_PHYSICAL_DEVICE_NAME_SIZE = c.VK_MAX_PHYSICAL_DEVICE_NAME_SIZE;
pub const UUID_SIZE = c.VK_UUID_SIZE;

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
pub const TRUE = c.VK_TRUE;
pub const FALSE = c.VK_FALSE;

pub const Buffer = enum (u64) { NULL_HANDLE = 0, _, };

pub const Command = extern struct
{
  pub const Buffer = enum (usize) { NULL_HANDLE = 0, _, };
  pub const Pool = enum (u64) { NULL_HANDLE = 0, _, };
};

pub const Component = extern struct
{
  pub const Mapping = extern struct
  {
    r: vk.Component.Swizzle,
    g: vk.Component.Swizzle,
    b: vk.Component.Swizzle,
    a: vk.Component.Swizzle,
  };

  pub const Swizzle = enum (i32)
  {
    IDENTITY = c.VK_COMPONENT_SWIZZLE_IDENTITY,
  };
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

pub const Device = @import ("device").Device;
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

pub const Extent3D = extern struct
{
  width: u32,
  height: u32,
  depth: u32,
};

pub const Fence = enum (u64) { NULL_HANDLE = 0, _, };

pub const Format = enum (u32)
{
  A8B8G8R8_UNORM_PACK32 = c.VK_FORMAT_A8B8G8R8_UNORM_PACK32,
  B8G8R8A8_SRGB = c.VK_FORMAT_B8G8R8A8_SRGB,
  B8G8R8A8_UNORM = c.VK_FORMAT_B8G8R8A8_UNORM,
  R8G8B8_UNORM = c.VK_FORMAT_R8G8B8_UNORM,
  R8G8B8A8_UNORM = c.VK_FORMAT_R8G8B8A8_UNORM,
  _,

  pub const Feature = extern struct
  {
    pub const Flags = u32;

    pub const Bit = enum (vk.Format.Feature.Flags)
    {
      BLIT_SRC = c.VK_FORMAT_FEATURE_BLIT_SRC_BIT,
      BLIT_DST = c.VK_FORMAT_FEATURE_BLIT_DST_BIT,

      pub fn in (self: @This (), flags: vk.Format.Feature.Flags) bool
      {
        return (flags & @intFromEnum (self)) == @intFromEnum (self);
      }
    };
  };

  pub const Properties = extern struct
  {
    linear_tiling_features: vk.Format.Feature.Flags = 0,
    optimal_tiling_features: vk.Format.Feature.Flags = 0,
    buffer_features: vk.Format.Feature.Flags = 0,
  };
};

pub const Framebuffer = enum (u64) { NULL_HANDLE = 0, _, };

pub const Image = @import ("image").Image;
pub const Instance = @import ("instance").Instance;

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

pub const PhysicalDevice = @import ("physical_device").PhysicalDevice;

pub const PhysicalDevices = extern struct
{
  pub fn enumerate (instance: vk.Instance, p_physical_device_count: *u32, p_physical_devices: ?[*] vk.PhysicalDevice) !void
  {
    const result = raw.prototypes.instance.vkEnumeratePhysicalDevices (instance, p_physical_device_count, p_physical_devices);
    if (result > 0)
    {
      std.debug.print ("{s} failed with {} status code\n", .{ @typeName (@This ()) ++ "." ++ @src ().fn_name, result, });
      return error.UnexpectedResult;
    }
  }
};

pub const Pipeline = enum (u64)
{
  NULL_HANDLE = 0, _,
  pub const Layout = enum (u64) { NULL_HANDLE = 0, _, };
};

pub const Queue = enum (usize)
{
  NULL_HANDLE = 0, _,

  pub const Flags = u32;

  pub const Bit = enum (vk.Queue.Flags)
  {
    GRAPHICS = c.VK_QUEUE_GRAPHICS_BIT,

    pub fn in (self: @This (), flags: vk.Queue.Flags) bool
    {
      return (flags & @intFromEnum (self)) == @intFromEnum (self);
    }
  };

  pub const FamilyProperties = extern struct
  {
    queue_flags: vk.Queue.Flags = 0,
    queue_count: u32,
    timestamp_valid_bits: u32,
    min_image_transfer_granularity: vk.Extent3D,
  };
};

pub const Rect2D = extern struct
{
  offset: vk.Offset2D,
  extent: vk.Extent2D,
};

pub const RenderPass = enum (u64) { NULL_HANDLE = 0, _, };
pub const Sampler = enum (u64) { NULL_HANDLE = 0, _, };

pub const SampleCount = extern struct
{
  pub const Flags = u32;
};

pub const Semaphore = enum (u64) { NULL_HANDLE = 0, _, };
pub const SharingMode = enum (i32)
{
  EXCLUSIVE = c.VK_SHARING_MODE_EXCLUSIVE,
  CONCURRENT = c.VK_SHARING_MODE_CONCURRENT,
};

pub const StructureType = enum (i32)
{
  APPLICATION_INFO = c.VK_STRUCTURE_TYPE_APPLICATION_INFO,
  DEBUG_UTILS_LABEL_EXT = c.VK_STRUCTURE_TYPE_DEBUG_UTILS_LABEL_EXT,
  DEBUG_UTILS_MESSENGER_CREATE_INFO_EXT = c.VK_STRUCTURE_TYPE_DEBUG_UTILS_MESSENGER_CREATE_INFO_EXT,
  DEBUG_UTILS_MESSENGER_CALLBACK_DATA_EXT = c.VK_STRUCTURE_TYPE_DEBUG_UTILS_MESSENGER_CALLBACK_DATA_EXT,
  DEBUG_UTILS_OBJECT_NAME_INFO_EXT = c.VK_STRUCTURE_TYPE_DEBUG_UTILS_OBJECT_NAME_INFO_EXT,
  DEVICE_CREATE_INFO = c.VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO,
  DEVICE_QUEUE_CREATE_INFO = c.VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
  IMAGE_VIEW_CREATE_INFO = c.VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO,
  INSTANCE_CREATE_INFO = c.VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO,
  SWAPCHAIN_CREATE_INFO_KHR = c.VK_STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR,
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
