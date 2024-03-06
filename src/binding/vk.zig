const std        = @import ("std");
const builtin    = @import ("builtin");
const c          = @import ("c");
const prototypes = @import ("prototypes");

pub usingnamespace vk;

const API = struct
{
  const Structless = struct
  {
    const Dispatch = dispatch: {
      @setEvalBranchQuota (10_000);
      const size = @typeInfo (prototypes.structless).Enum.fields.len;
      var fields: [size] std.builtin.Type.StructField = undefined;
      for (@typeInfo (prototypes.structless).Enum.fields, 0 ..) |field, i|
      {
        //const pfn = @field (c, "PFN_" ++ field.name);
        const pfn = @TypeOf (@field (c, field.name));
        fields [i] = .{
          .name = field.name,
          .type = pfn,
          .default_value = null,
          .is_comptime = false,
          .alignment = @alignOf (pfn),
        };
      }
      break :dispatch @Type (.{
        .Struct = .{
          .layout = .Auto,
          .fields = &fields,
          .decls = &[_] std.builtin.Type.Declaration {},
          .is_tuple = false,
        },
      });
    };

    dispatch: Dispatch = dispatch: {
      var dispatch: Dispatch = undefined;
      for (std.meta.fields (Dispatch)) |field|
      {
        const name: [*:0] const u8 = @ptrCast (field.name ++ "\x00");
        const loader: *const fn (vk.Instance, [*:0] const u8) callconv (vk.call_conv) ?*const fn () callconv (vk.call_conv) void = @ptrCast (&c.glfwGetInstanceProcAddress);
        const pointer = loader (vk.Instance.null_handle, name) orelse @compileError ("Command load failure: " ++ name);
        @field (dispatch, field.name) = @ptrCast (pointer);
        @compileLog ("Structless '" ++ name ++ "' command loaded");
      }
      break :dispatch dispatch;
    },
  };

  structless: Structless = .{},
  //instance: API.Instance = .{};
  //device: API.Device = .{};
};

const api: API = .{};

pub const vk = struct
{
  pub const MAX_EXTENSION_NAME_SIZE = c.VK_MAX_EXTENSION_NAME_SIZE;
  pub const MAX_DESCRIPTION_SIZE = c.VK_MAX_DESCRIPTION_SIZE;

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

  pub const Bool32 = u32;
  pub const Buffer = enum (u64) { null_handle = 0, _, };

  pub const Command = struct
  {
    pub const Buffer = enum (usize) { null_handle = 0, _, };
    pub const Pool = enum (u64) { null_handle = 0, _, };
  };

  pub const Descriptor = struct
  {
    pub const Pool = enum (u64) { null_handle = 0, _, };
    pub const Set = enum (u64)
    {
      null_handle = 0, _,
      pub const Layout = enum (u64) { null_handle = 0, _, };
    };
  };

  pub const Device = enum (usize)
  {
    null_handle = 0, _,
    pub const Memory = enum (u64) { null_handle = 0, _, };
  };

  pub const Extent2D = struct
  {
    width: u32,
    height: u32,
  };

  pub const Fence = enum (u64) { null_handle = 0, _, };

  pub const Format = enum (i32)
  {
    undefined = c.VK_FORMAT_UNDEFINED,
    r4g4_unorm_pack8 = c.VK_FORMAT_R4G4_UNORM_PACK8,
    _,
  };

  pub const Framebuffer = enum (u64) { null_handle = 0, _, };

  pub const Image = enum (u64)
  {
    null_handle = 0, _,

    pub const Usage = struct
    {
      pub const Flags = struct
      {
        pub const transfer_src_bit = c.VK_IMAGE_USAGE_TRANSFER_SRC_BIT;
      };
    };

    pub const View = enum (u64) { null_handle = 0, _, };
  };

  pub const Instance = enum (usize)
  {
    null_handle = 0, _,
    pub const LayerProperties = struct
    {
      pub fn enumerate (p_property_count: *u32, p_properties: ?[*] vk.LayerProperties) !void
      {
        const result = api.structless.dispatch.vkEnumerateInstanceLayerProperties (p_property_count, p_properties);
        if (result > 0)
        {
          std.debug.print ("{s} failed with {} status code\n", .{ result, });
          return error.vkEnumerateInstanceLayerProperties;
        }
      }
    };
  };

  pub const LayerProperties = struct
  {
    layer_name: [MAX_EXTENSION_NAME_SIZE] u8,
    spec_version: u32,
    implementation_version: u32,
    description: [MAX_DESCRIPTION_SIZE] u8,
  };

  pub const ObjectType = enum (i32)
  {
    unknown = 0,
  };

  pub const Offset2D = struct
  {
    x: i32,
    y: i32,
  };

  pub const PhysicalDevice = enum (usize) { null_handle = 0, _, };

  pub const Pipeline = enum (u64)
  {
    null_handle = 0, _,
    pub const Layout = enum (u64) { null_handle = 0, _, };
  };

  pub const Queue = enum (usize) { null_handle = 0, _, };

  pub const Rect2D = struct
  {
    offset: vk.Offset2D,
    extent: vk.Extent2D,
  };

  pub const RenderPass = enum (u64) { null_handle = 0, _, };
  pub const Sampler = enum (u64) { null_handle = 0, _, };
  pub const Semaphore = enum (u64) { null_handle = 0, _, };

  pub const StructureType = enum (i32)
  {
    debug_utils_label_ext = c.VK_STRUCTURE_TYPE_DEBUG_UTILS_LABEL_EXT,
    debug_utils_messenger_create_info_ext = c.VK_STRUCTURE_TYPE_DEBUG_UTILS_MESSENGER_CREATE_INFO_EXT,
    debug_utils_messenger_callback_data_ext = c.VK_STRUCTURE_TYPE_DEBUG_UTILS_MESSENGER_CALLBACK_DATA_EXT,
    debug_utils_object_name_info_ext = c.VK_STRUCTURE_TYPE_DEBUG_UTILS_OBJECT_NAME_INFO_EXT,
  };

  pub const Viewport = struct
  {
    x: f32,
    y: f32,
    width: f32,
    height: f32,
    min_depth: f32,
    max_depth: f32,
  };

  pub const EXT = struct
  {
    pub const DebugUtils = struct
    {
      pub const Label = struct
      {
        s_type: vk.StructureType = .debug_utils_label_ext,
        p_next: ?*const anyopaque = null,
        p_label_name: [*:0] const u8,
        color: [4] f32,
      };

      pub const Message = struct
      {
        pub const Severity = struct
        {
          pub const Flags = struct {};
        };

        pub const Type = struct
        {
          pub const Flags = struct {};
        };
      };

      pub const Messenger = enum (u64)
      {
        null_handle = 0, _,

        pub const Callback = struct
        {
          pub const Data = struct
          {
            s_type: vk.StructureType = .debug_utils_messenger_callback_data_ext,
            p_next: ?*const anyopaque = null,
            flags: vk.EXT.DebugUtils.Messenger.Callback.Data.Flags = .{},
            p_message_id_name: ?[*:0] const u8 = null,
            message_id_number: i32,
            p_message: [*:0] const u8,
            queue_label_count: u32 = 0,
            p_queue_labels: ?[*] const vk.EXT.DebugUtils.Label = null,
            cmd_buf_label_count: u32 = 0,
            p_cmd_buf_labels: ?[*] const vk.EXT.DebugUtils.Label = null,
            object_count: u32 = 0,
            p_objects: ?[*] const vk.EXT.DebugUtils.ObjectNameInfo = null,

            pub const Flags = struct {};
          };

          pub const Pfn = ?*const fn (
            message_severity: vk.EXT.DebugUtils.Message.Severity.Flags,
            message_types: vk.EXT.DebugUtils.Message.Type.Flags,
            p_callback_data: ?*const vk.EXT.DebugUtils.Messenger.Callback.Data,
            p_user_data: ?*anyopaque,
          ) callconv (vk.call_conv) vk.Bool32;
        };

        pub const Create = struct
        {
          pub const Flags = struct {};

          pub const Info = struct
          {
            s_type: vk.StructureType = .debug_utils_messenger_create_info_ext,
            p_next: ?*const anyopaque = null,
            flags: vk.EXT.DebugUtils.Messenger.Create.Flags = .{},
            message_severity: vk.EXT.DebugUtils.Message.Severity.Flags,
            message_type: vk.EXT.DebugUtils.Message.Type.Flags,
            pfn_user_callback: vk.EXT.DebugUtils.Messenger.Callback.Pfn,
            p_user_data: ?*anyopaque = null,
          };
        };
      };

      pub const ObjectNameInfo = struct
      {
        s_type: vk.StructureType = .debug_utils_object_name_info_ext,
        p_next: ?*const anyopaque = null,
        object_type: vk.ObjectType,
        object_handle: u64,
        p_object_name: ?[*:0] const u8 = null,
      };
    };
  };

  pub const KHR = struct
  {
    pub const ColorSpace = enum (i32)
    {
      srgb_nonlinear_khr = c.VK_COLOR_SPACE_SRGB_NONLINEAR_KHR,
    };

    pub const CompositeAlpha = struct
    {
      pub const Flags = struct
      {
        pub const opaque_bit_khr = c.VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR;
      };
    };

    pub const PresentMode = enum (i32)
    {
      immediate_khr = c.VK_PRESENT_MODE_IMMEDIATE_KHR,
    };

    pub const Surface = enum (u64)
    {
      null_handle = 0, _,
      pub const Capabilities = struct
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

      pub const Format = struct
      {
        format: vk.Format,
        color_space: vk.KHR.ColorSpace,
      };

      pub const Transform = struct
      {
        pub const Flags = struct
        {
          pub const identity_bit_khr = c.VK_SURFACE_TRANSFORM_IDENTITY_BIT_KHR;
        };
      };
    };

    pub const Swapchain = enum (u64) { null_handle = 0, _, };
  };
};
