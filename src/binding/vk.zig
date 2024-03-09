const std        = @import ("std");
const builtin    = @import ("builtin");
const c          = @import ("c");
const prototypes = @import ("prototypes");

const vk = @This ();

const Raw = struct
{
  const Structless = struct
  {
    dispatch: Dispatch,

    fn cast (comptime T: type) type
    {
      var info = @typeInfo (T);
      return switch (info)
      {
        .Struct  => if (info.Struct.layout == .Auto) T else @field (vk, @typeName (T) [17 ..]),
        .Pointer => blk: { info.Pointer.child = cast (info.Pointer.child); break :blk @Type (info); },
        else     => T,
      };
    }

    const Dispatch = blk: {
      @setEvalBranchQuota (10_000);
      const size = @typeInfo (prototypes.structless).Enum.fields.len;
      var fields: [size] std.builtin.Type.StructField = undefined;
      for (@typeInfo (prototypes.structless).Enum.fields, 0 ..) |*field, i|
      {
        const pfn = pfn: {
          const pointer = @typeInfo (@TypeOf (@field (c, field.name)));
          var params: [pointer.Fn.params.len] std.builtin.Type.Fn.Param = undefined;
          for (pointer.Fn.params, 0 ..) |*param, j|
          {
            params [j] = .{
              .is_generic = param.is_generic,
              .is_noalias = param.is_noalias,
              .type = cast (param.type orelse @compileError ("Param type is null for " ++ field.name)),
            };
          }
          break :pfn @Type (.{
            .Pointer = .{
              .size = .One,
              .is_const = true,
              .is_volatile = false,
              .alignment = 1,
              .address_space = .generic,
              .child = @Type (.{
                .Fn = .{
                  .calling_convention = vk.call_conv,
                  .alignment = pointer.Fn.alignment,
                  .is_generic = pointer.Fn.is_generic,
                  .is_var_args = pointer.Fn.is_var_args,
                  .return_type = cast (pointer.Fn.return_type orelse @compileError ("Return type is null for " ++ field.name)),
                  .params = &params,
                },
              }),
              .is_allowzero = false,
              .sentinel = null,
            },
          });
        };

        @compileLog (field.name ++ ": " ++ @typeName (pfn));
        fields [i] = .{
          .name = field.name,
          .type = pfn,
          .default_value = null,
          .is_comptime = false,
          .alignment = @alignOf (pfn),
        };
      }
      break :blk @Type (.{
        .Struct = .{
          .layout = .Auto,
          .fields = &fields,
          .decls = &[_] std.builtin.Type.Declaration {},
          .is_tuple = false,
        },
      });
    };
  };

  structless: vk.Raw.Structless,
  //instance: vk.Raw.Instance = .{};
  //device: vk.Raw.Device = .{};
};

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

var raw: vk.Raw = undefined;

pub fn load () !void
{
  const loader: *const fn (vk.Instance, [*:0] const u8) callconv (vk.call_conv) ?*const fn () callconv (vk.call_conv) void = @ptrCast (&c.glfwGetInstanceProcAddress);
  inline for (std.meta.fields (vk.Raw.Structless.Dispatch)) |field|
  {
    const name: [*:0] const u8 = @ptrCast (field.name ++ "\x00");
    const pointer = loader (vk.Instance.null_handle, name) orelse return error.CommandLoadFailure;
    @field (vk.raw.structless.dispatch, field.name) = @ptrCast (pointer);
  }
}

pub const MAX_EXTENSION_NAME_SIZE = c.VK_MAX_EXTENSION_NAME_SIZE;
pub const MAX_DESCRIPTION_SIZE = c.VK_MAX_DESCRIPTION_SIZE;

pub const Bool32 = u32;
pub const Buffer = enum (u64) { null_handle = 0, _, };

pub const Command = extern struct
{
  pub const Buffer = enum (usize) { null_handle = 0, _, };
  pub const Pool = enum (u64) { null_handle = 0, _, };
};

pub const Descriptor = extern struct
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

  pub const Usage = extern struct
  {
    pub const Flags = extern struct
    {
      pub const transfer_src_bit = c.VK_IMAGE_USAGE_TRANSFER_SRC_BIT;
    };
  };

  pub const View = enum (u64) { null_handle = 0, _, };
};

pub const Instance = enum (usize)
{
  null_handle = 0, _,
  pub const ExtensionProperties = extern struct
  {
    pub fn enumerate (p_layer_name: ?[*:0] const u8, p_property_count: *u32, p_properties: ?[*] vk.ExtensionProperties) !void
    {
      const result = vk.raw.structless.dispatch.vkEnumerateInstanceExtensionProperties (p_layer_name, p_property_count, p_properties);
      if (result > 0)
      {
        std.debug.print ("{s} failed with {} status code\n", .{ @src ().fn_name, result, });
        return error.vkEnumerateInstanceExtensionProperties;
      }
    }
  };

  pub const LayerProperties = extern struct
  {
    pub fn enumerate (p_property_count: *u32, p_properties: ?[*] vk.LayerProperties) !void
    {
      const result = vk.raw.structless.dispatch.vkEnumerateInstanceLayerProperties (p_property_count, p_properties);
      if (result > 0)
      {
        std.debug.print ("{s} failed with {} status code\n", .{ @src ().fn_name, result, });
        return error.vkEnumerateInstanceLayerProperties;
      }
    }
  };
};

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

pub const PhysicalDevice = enum (usize) { null_handle = 0, _, };

pub const Pipeline = enum (u64)
{
  null_handle = 0, _,
  pub const Layout = enum (u64) { null_handle = 0, _, };
};

pub const Queue = enum (usize) { null_handle = 0, _, };

pub const Rect2D = extern struct
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

pub const Viewport = extern struct
{
  x: f32,
  y: f32,
  width: f32,
  height: f32,
  min_depth: f32,
  max_depth: f32,
};

pub const EXT = extern struct
{
  pub const DEVICE_ADDRESS_BINDING_REPORT = c.VK_EXT_DEVICE_ADDRESS_BINDING_REPORT_EXTENSION_NAME;
  pub const DEBUG_REPORT = c.VK_EXT_DEBUG_REPORT_EXTENSION_NAME;
  pub const DEBUG_UTILS = c.VK_EXT_DEBUG_UTILS_EXTENSION_NAME;
  pub const VALIDATION_FEATURES = c.VK_EXT_VALIDATION_FEATURES_EXTENSION_NAME;

  pub const DebugUtils = extern struct
  {
    pub const Label = extern struct
    {
      s_type: vk.StructureType = .debug_utils_label_ext,
      p_next: ?*const anyopaque = null,
      p_label_name: [*:0] const u8,
      color: [4] f32,
    };

    pub const Message = extern struct
    {
      pub const Severity = extern struct
      {
        pub const Flags = extern struct {};
      };

      pub const Type = extern struct
      {
        pub const Flags = extern struct {};
      };
    };

    pub const Messenger = enum (u64)
    {
      null_handle = 0, _,

      pub const Callback = extern struct
      {
        pub const Data = extern struct
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

          pub const Flags = extern struct {};
        };

        pub const Pfn = ?*const fn (
          message_severity: vk.EXT.DebugUtils.Message.Severity.Flags,
          message_types: vk.EXT.DebugUtils.Message.Type.Flags,
          p_callback_data: ?*const vk.EXT.DebugUtils.Messenger.Callback.Data,
          p_user_data: ?*anyopaque,
        ) callconv (vk.call_conv) vk.Bool32;
      };

      pub const Create = extern struct
      {
        pub const Flags = extern struct {};

        pub const Info = extern struct
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

    pub const ObjectNameInfo = extern struct
    {
      s_type: vk.StructureType = .debug_utils_object_name_info_ext,
      p_next: ?*const anyopaque = null,
      object_type: vk.ObjectType,
      object_handle: u64,
      p_object_name: ?[*:0] const u8 = null,
    };
  };
};

pub const KHR = extern struct
{
  pub const SHADER_NON_SEMANTIC_INFO = c.VK_KHR_SHADER_NON_SEMANTIC_INFO_EXTENSION_NAME;
  pub const ColorSpace = enum (i32)
  {
    srgb_nonlinear_khr = c.VK_COLOR_SPACE_SRGB_NONLINEAR_KHR,
  };

  pub const CompositeAlpha = extern struct
  {
    pub const Flags = extern struct
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
      pub const Flags = extern struct
      {
        pub const identity_bit_khr = c.VK_SURFACE_TRANSFORM_IDENTITY_BIT_KHR;
      };
    };
  };

  pub const Swapchain = enum (u64) { null_handle = 0, _, };
};
