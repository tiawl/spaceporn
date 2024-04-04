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
pub const MAX_MEMORY_HEAPS = c.VK_MAX_MEMORY_HEAPS;
pub const MAX_MEMORY_TYPES = c.VK_MAX_MEMORY_TYPES;
pub const MAX_PHYSICAL_DEVICE_NAME_SIZE = c.VK_MAX_PHYSICAL_DEVICE_NAME_SIZE;
pub const NULL_HANDLE: u32 = @intCast (@intFromPtr (c.VK_NULL_HANDLE));
pub const SUBPASS_EXTERNAL = c.VK_SUBPASS_EXTERNAL;
pub const UUID_SIZE = c.VK_UUID_SIZE;

pub const Access = extern struct
{
  pub const Flags = u32;

  pub const Bit = enum (vk.Access.Flags)
  {
    COLOR_ATTACHMENT_WRITE = c.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT,
    SHADER_READ = c.VK_ACCESS_SHADER_READ_BIT,
  };
};

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

pub const Attachment = @import ("attachment").Attachment;

pub const Bool32 = u32;
pub const TRUE = c.VK_TRUE;
pub const FALSE = c.VK_FALSE;

pub const Blend = extern struct
{
  pub const Factor = enum (i32)
  {
    ONE = c.VK_BLEND_FACTOR_ONE,
    ZERO = c.VK_BLEND_FACTOR_ZERO,
  };

  pub const Op = enum (i32)
  {
    ADD = c.VK_BLEND_OP_ADD,
  };
};

pub const BorderColor = enum (i32)
{
  FLOAT_OPAQUE_BLACK = c.VK_BORDER_COLOR_FLOAT_OPAQUE_BLACK,
};

pub const Buffer = @import ("buffer").Buffer;

pub const ColorComponent = extern struct
{
  pub const Flags = u32;

  pub const Bit = enum (vk.ColorComponent.Flags)
  {
    A = c.VK_COLOR_COMPONENT_A_BIT,
    B = c.VK_COLOR_COMPONENT_B_BIT,
    G = c.VK_COLOR_COMPONENT_G_BIT,
    R = c.VK_COLOR_COMPONENT_R_BIT,
  };
};

pub const Command = @import ("command").Command;

pub const CompareOp = enum (i32)
{
  ALWAYS = c.VK_COMPARE_OP_ALWAYS,
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

pub const CullMode = extern struct
{
  pub const Flags = u32;

  pub const Bit = enum (vk.CullMode.Flags)
  {
    BACK = c.VK_CULL_MODE_BACK_BIT,
  };
};

pub const Dependency = extern struct
{
  pub const Flags = u32;

  pub const Bit = enum (vk.Dependency.Flags)
  {
    BY_REGION = c.VK_DEPENDENCY_BY_REGION_BIT,
  };
};

pub const Descriptor = @import ("descriptor").Descriptor;
pub const Device = @import ("device").Device;

pub const DynamicState = enum (i32)
{
  SCISSOR = c.VK_DYNAMIC_STATE_SCISSOR,
  VIEWPORT = c.VK_DYNAMIC_STATE_VIEWPORT,
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

pub const Extent3D = extern struct
{
  width: u32,
  height: u32,
  depth: u32,
};

pub const Fence = enum (u64) { NULL_HANDLE = vk.NULL_HANDLE, _, };

pub const Filter = enum (i32)
{
  LINEAR = c.VK_FILTER_LINEAR,
};

pub const Format = @import ("format").Format;
pub const Framebuffer = @import ("framebuffer").Framebuffer;

pub const FrontFace = enum (i32)
{
  CLOCKWISE = c.VK_FRONT_FACE_CLOCKWISE,
};

pub const Graphics = @import ("pipeline").Graphics;

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

pub const LogicOp = enum (i32)
{
  COPY = c.VK_LOGIC_OP_COPY,
};

pub const Memory = @import ("memory").Memory;

pub const ObjectType = enum (i32)
{
  UNKNOWN = c.VK_OBJECT_TYPE_UNKNOWN,
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

pub const Pipeline = @import ("pipeline").Pipeline;

pub const PolygonMode = enum (i32)
{
  FILL = c.VK_POLYGON_MODE_FILL,
};

pub const PrimitiveTopology = enum (i32)
{
  TRIANGLE_LIST = c.VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST,
};

pub const PushConstantRange = extern struct
{
  stage_flags: vk.Shader.Stage.Flags,
  offset: u32,
  size: u32,
};

pub const Query = extern struct
{
  pub const Control = extern struct
  {
    pub const Flags = u32;
  };

  pub const PipelineStatistic = extern struct
  {
    pub const Flags = u32;
  };
};

pub const Queue = enum (usize)
{
  NULL_HANDLE = vk.NULL_HANDLE, _,

  pub const Flags = u32;

  pub const Bit = enum (vk.Queue.Flags)
  {
    GRAPHICS = c.VK_QUEUE_GRAPHICS_BIT,

    pub fn contains (self: @This (), flags: vk.Queue.Flags) bool
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

  pub fn submit (queue: @This (), submit_count: u32, p_submits: ?[*] const vk.Submit.Info, fence: vk.Fence) !void
  {
    const result = raw.prototypes.device.vkQueueSubmit (queue, submit_count, p_submits, fence);
    if (result > 0)
    {
      std.debug.print ("{s} failed with {} status code\n", .{ @typeName (@This ()) ++ "." ++ @src ().fn_name, result, });
      return error.UnexpectedResult;
    }
  }

  pub fn waitIdle (queue: @This ()) !void
  {
    const result = raw.prototypes.device.vkQueueWaitIdle (queue);
    if (result > 0)
    {
      std.debug.print ("{s} failed with {} status code\n", .{ @typeName (@This ()) ++ "." ++ @src ().fn_name, result, });
      return error.UnexpectedResult;
    }
  }
};

pub const Rect2D = extern struct
{
  offset: vk.Offset2D,
  extent: vk.Extent2D,
};

pub const RenderPass = @import ("render_pass").RenderPass;

pub const Sampler = @import ("sampler").Sampler;

pub const Sample = extern struct
{
  pub const Count = extern struct
  {
    pub const Flags = u32;

    pub const Bit = enum (vk.Sample.Count.Flags)
    {
      @"1" = c.VK_SAMPLE_COUNT_1_BIT,
    };
  };

  pub const Mask = u32;
};

pub const Semaphore = enum (u64) { NULL_HANDLE = vk.NULL_HANDLE, _, };

pub const Shader = @import ("shader").Shader;

pub const SharingMode = enum (i32)
{
  EXCLUSIVE = c.VK_SHARING_MODE_EXCLUSIVE,
  CONCURRENT = c.VK_SHARING_MODE_CONCURRENT,
};

pub const Specialization = extern struct
{
  pub const Info = extern struct
  {
    map_entry_count: u32 = 0,
    p_map_entries: ?[*] const vk.Specialization.MapEntry = null,
    data_size: usize = 0,
    p_data: ?*const anyopaque = null,
  };

  pub const MapEntry = extern struct
  {
    constant_id: u32,
    offset: u32,
    size: usize,
  };
};

pub const StencilOp = enum (i32)
{
  pub const State = extern struct
  {
    fail_op: vk.StencilOp,
    pass_op: vk.StencilOp,
    depth_fail_op: vk.StencilOp,
    compare_op: vk.CompareOp,
    compare_mask: u32,
    write_mask: u32,
    reference: u32,
  };
};

pub const StructureType = enum (i32)
{
  APPLICATION_INFO = c.VK_STRUCTURE_TYPE_APPLICATION_INFO,
  BUFFER_CREATE_INFO = c.VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO,
  COMMAND_BUFFER_ALLOCATE_INFO = c.VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO,
  COMMAND_BUFFER_BEGIN_INFO = c.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO,
  COMMAND_BUFFER_INHERITANCE_INFO = c.VK_STRUCTURE_TYPE_COMMAND_BUFFER_INHERITANCE_INFO,
  COMMAND_POOL_CREATE_INFO = c.VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO,
  DEBUG_UTILS_LABEL_EXT = c.VK_STRUCTURE_TYPE_DEBUG_UTILS_LABEL_EXT,
  DEBUG_UTILS_MESSENGER_CREATE_INFO_EXT = c.VK_STRUCTURE_TYPE_DEBUG_UTILS_MESSENGER_CREATE_INFO_EXT,
  DEBUG_UTILS_MESSENGER_CALLBACK_DATA_EXT = c.VK_STRUCTURE_TYPE_DEBUG_UTILS_MESSENGER_CALLBACK_DATA_EXT,
  DEBUG_UTILS_OBJECT_NAME_INFO_EXT = c.VK_STRUCTURE_TYPE_DEBUG_UTILS_OBJECT_NAME_INFO_EXT,
  DESCRIPTOR_SET_LAYOUT_CREATE_INFO = c.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO,
  DEVICE_CREATE_INFO = c.VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO,
  DEVICE_QUEUE_CREATE_INFO = c.VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
  FRAMEBUFFER_CREATE_INFO = c.VK_STRUCTURE_TYPE_FRAMEBUFFER_CREATE_INFO,
  GRAPHICS_PIPELINE_CREATE_INFO = c.VK_STRUCTURE_TYPE_GRAPHICS_PIPELINE_CREATE_INFO,
  IMAGE_CREATE_INFO = c.VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO,
  IMAGE_VIEW_CREATE_INFO = c.VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO,
  INSTANCE_CREATE_INFO = c.VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO,
  MEMORY_ALLOCATE_INFO = c.VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO,
  PIPELINE_COLOR_BLEND_STATE_CREATE_INFO = c.VK_STRUCTURE_TYPE_PIPELINE_COLOR_BLEND_STATE_CREATE_INFO,
  PIPELINE_DEPTH_STENCIL_STATE_CREATE_INFO = c.VK_STRUCTURE_TYPE_PIPELINE_DEPTH_STENCIL_STATE_CREATE_INFO,
  PIPELINE_DYNAMIC_STATE_CREATE_INFO = c.VK_STRUCTURE_TYPE_PIPELINE_DYNAMIC_STATE_CREATE_INFO,
  PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO = c.VK_STRUCTURE_TYPE_PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO,
  PIPELINE_LAYOUT_CREATE_INFO = c.VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO,
  PIPELINE_MULTISAMPLE_STATE_CREATE_INFO = c.VK_STRUCTURE_TYPE_PIPELINE_MULTISAMPLE_STATE_CREATE_INFO,
  PIPELINE_RASTERIZATION_STATE_CREATE_INFO = c.VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_STATE_CREATE_INFO,
  PIPELINE_SHADER_STAGE_CREATE_INFO = c.VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO,
  PIPELINE_TESSELLATION_STATE_CREATE_INFO = c.VK_STRUCTURE_TYPE_PIPELINE_TESSELLATION_STATE_CREATE_INFO,
  PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO = c.VK_STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO,
  PIPELINE_VIEWPORT_STATE_CREATE_INFO = c.VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_STATE_CREATE_INFO,
  RENDER_PASS_CREATE_INFO = c.VK_STRUCTURE_TYPE_RENDER_PASS_CREATE_INFO,
  SAMPLER_CREATE_INFO = c.VK_STRUCTURE_TYPE_SAMPLER_CREATE_INFO,
  SHADER_MODULE_CREATE_INFO = c.VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO,
  SUBMIT_INFO = c.VK_STRUCTURE_TYPE_SUBMIT_INFO,
  SWAPCHAIN_CREATE_INFO_KHR = c.VK_STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR,
  VALIDATION_FEATURES_EXT = c.VK_STRUCTURE_TYPE_VALIDATION_FEATURES_EXT,
};

pub const Submit = extern struct
{
  pub const Info = extern struct
  {
    s_type: vk.StructureType = .SUBMIT_INFO,
    p_next: ?*const anyopaque = null,
    wait_semaphore_count: u32 = 0,
    p_wait_semaphores: ?[*] const vk.Semaphore = null,
    p_wait_dst_stage_mask: ?[*] const vk.Pipeline.Stage.Flags = null,
    command_buffer_count: u32 = 0,
    p_command_buffers: ?[*] const vk.Command.Buffer = null,
    signal_semaphore_count: u32 = 0,
    p_signal_semaphores: ?[*] const vk.Semaphore = null,
  };
};

pub const Subpass = extern struct
{
  pub const Dependency = extern struct
  {
    src_subpass: u32,
    dst_subpass: u32,
    src_stage_mask: vk.Pipeline.Stage.Flags = 0,
    dst_stage_mask: vk.Pipeline.Stage.Flags = 0,
    src_access_mask: vk.Access.Flags = 0,
    dst_access_mask: vk.Access.Flags = 0,
    dependency_flags: vk.Dependency.Flags = 0,
  };

  pub const Description = extern struct
  {
    flags: vk.Subpass.Description.Flags = 0,
    pipeline_bind_point: vk.Pipeline.BindPoint,
    input_attachment_count: u32 = 0,
    p_input_attachments: ?[*] const vk.Attachment.Reference = null,
    color_attachment_count: u32 = 0,
    p_color_attachments: ?[*] const vk.Attachment.Reference = null,
    p_resolve_attachments: ?[*] const vk.Attachment.Reference = null,
    p_depth_stencil_attachment: ?*const vk.Attachment.Reference = null,
    preserve_attachment_count: u32 = 0,
    p_preserve_attachments: ?[*] const u32 = null,

    pub const Flags = u32;
  };
};

pub const SystemAllocationScope = enum (i32) {};

pub const VertexInput = extern struct
{
  pub const AttributeDescription = extern struct
  {
    location: u32,
    binding: u32,
    format: vk.Format,
    offset: u32,
  };

  pub const BindingDescription = extern struct
  {
    binding: u32,
    stride: u32,
    input_rate: vk.VertexInput.Rate,
  };

  pub const Rate = enum (i32)
  {
    VERTEX = c.VK_VERTEX_INPUT_RATE_VERTEX,
  };
};

pub const Viewport = extern struct
{
  x: f32,
  y: f32,
  width: f32,
  height: f32,
  min_depth: f32,
  max_depth: f32,
};
