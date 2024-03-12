const std        = @import ("std");
const builtin    = @import ("builtin");
const c          = @import ("c");
const prototypes = @import ("prototypes");

const vk = @This ();

const Raw = struct
{
  fn basename (raw_name: [] const u8) [] const u8
  {
    var res = raw_name;
    if (std.mem.indexOf (u8, res, "_Vk")) |index| res = res [index + 3 ..];
    if (std.mem.lastIndexOfScalar (u8, res, '_')) |index| res = res [0 .. index];
    return res;
  }

  fn ziggify (raw_name: [] const u8) type
  {
    var name = basename (raw_name);
    var field = vk;
    for ([_][] const u8 { "EXT", "KHR", }) |prefix|
    {
      if (std.mem.endsWith (u8, name, prefix))
      {
        name = name [0 .. name.len - prefix.len];
        field = @field (vk, prefix);
        break;
      }
    }
    var start: usize = 0;
    var end = name.len;
    while (start < end)
    {
      if (@hasDecl (field, name [start .. end]))
      {
        field = @field (field, name [start .. end]);
        start = end;
        end = name.len;
      } else end = std.mem.lastIndexOfAny (u8, name [0 .. end - 1], "ABCDEFGHIJKLMNOPQRSTUVWXYZ")
        orelse std.debug.panic ("Undefined \"{s}\" into vk binding from \"{s}\"", .{ name [start .. end], name, });
    }

    return field;
  }

  fn cast_rec (comptime T: type, is_opaque: *bool) type
  {
    var info = @typeInfo (T);
    return switch (info)
    {
      .Opaque   => blk: { is_opaque.* = true; break :blk ziggify (@typeName (T)); },
      .Optional => blk: {
                     const child = cast_rec (info.Optional.child, is_opaque);
                     if (is_opaque.*) { is_opaque.* = false; break :blk child; }
                     else { info.Optional.child = child; break :blk @Type (info); }
                   },
      .Pointer  => blk: {
                     const child = cast_rec (info.Pointer.child, is_opaque);
                     if (is_opaque.*) break :blk child
                     else { info.Pointer.child = child; break :blk @Type (info); }
                   },
      .Struct   => if (info.Struct.layout == .Auto) T else ziggify (@typeName (T)),
      else      => T,
    };
  }

  fn cast (comptime T: type) type
  {
    var is_opaque = false;
    return cast_rec (T, &is_opaque);
  }

  fn Dispatch (comptime T: std.meta.DeclEnum (prototypes)) type
  {
    @setEvalBranchQuota (10_000);
    const size = @typeInfo (@field (prototypes, @tagName (T))).Enum.fields.len;
    var fields: [size] std.builtin.Type.StructField = undefined;
    for (@typeInfo (@field (prototypes, @tagName (T))).Enum.fields, 0 ..) |*field, i|
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
    return @Type (.{
      .Struct = .{
        .layout = .Auto,
        .fields = &fields,
        .decls = &[_] std.builtin.Type.Declaration {},
        .is_tuple = false,
      },
    });
  }

  structless: vk.Raw.Dispatch (.structless),
  instance: vk.Raw.Dispatch (.instance),
  device: vk.Raw.Dispatch (.device),
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
  inline for (std.meta.fields (@TypeOf (vk.raw.structless))) |field|
  {
    const name: [*:0] const u8 = @ptrCast (field.name ++ "\x00");
    const pointer = loader (vk.Instance.NULL_HANDLE, name) orelse return error.CommandLoadFailure;
    @field (vk.raw.structless, field.name) = @ptrCast (pointer);
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
    const loader: *const fn (vk.Device, [*:0] const u8) callconv (vk.call_conv) ?*const fn () callconv (vk.call_conv) void = @ptrCast (&vk.raw.instance.vkGetDeviceProcAddr);
    inline for (std.meta.fields (@TypeOf (vk.raw.device))) |field|
    {
      const name: [*:0] const u8 = @ptrCast (field.name ++ "\x00");
      const pointer = loader (self, name) orelse return error.CommandLoadFailure;
      @field (vk.raw.device, field.name) = @ptrCast (pointer);
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
    const result = vk.raw.structless.vkCreateInstance (p_create_info, p_allocator, &instance);
    if (result > 0)
    {
      std.debug.print ("{s} failed with {} status code\n", .{ @typeName (@This ()) ++ "." ++ @src ().fn_name, result, });
      return error.UnexpectedResult;
    }
    return instance;
  }

  pub fn destroy (self: @This (), p_allocator: ?*const vk.AllocationCallbacks) void
  {
    vk.raw.instance.vkDestroyInstance (self, p_allocator);
  }

  pub fn load (self: @This ()) !void
  {
    const loader: *const fn (vk.Instance, [*:0] const u8) callconv (vk.call_conv) ?*const fn () callconv (vk.call_conv) void = @ptrCast (&vk.raw.structless.vkGetInstanceProcAddr);
    inline for (std.meta.fields (@TypeOf (vk.raw.instance))) |field|
    {
      const name: [*:0] const u8 = @ptrCast (field.name ++ "\x00");
      const pointer = loader (self, name) orelse return error.CommandLoadFailure;
      @field (vk.raw.instance, field.name) = @ptrCast (pointer);
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
      const result = vk.raw.structless.vkEnumerateInstanceExtensionProperties (p_layer_name, p_property_count, p_properties);
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
      const result = vk.raw.structless.vkEnumerateInstanceLayerProperties (p_property_count, p_properties);
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
      s_type: vk.StructureType = .DEBUG_UTILS_LABEL_EXT,
      p_next: ?*const anyopaque = null,
      p_label_name: [*:0] const u8,
      color: [4] f32,
    };

    pub const Message = extern struct
    {
      pub const Severity = extern struct
      {
        pub const Flags = u32;

        pub const Bit = enum (vk.EXT.DebugUtils.Message.Severity.Flags)
        {
          VERBOSE = c.VK_DEBUG_UTILS_MESSAGE_SEVERITY_VERBOSE_BIT_EXT,
          INFO = c.VK_DEBUG_UTILS_MESSAGE_SEVERITY_INFO_BIT_EXT,
          WARNING = c.VK_DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT_EXT,
          ERROR = c.VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT,

          pub fn in (self: @This (), flags: vk.EXT.DebugUtils.Message.Severity.Flags) bool
          {
            return (flags & @intFromEnum (self)) == @intFromEnum (self);
          }
        };
      };

      pub const Type = extern struct
      {
        pub const Flags = u32;

        pub const Bit = enum (vk.EXT.DebugUtils.Message.Type.Flags)
        {
          GENERAL = c.VK_DEBUG_UTILS_MESSAGE_TYPE_GENERAL_BIT_EXT,
          VALIDATION = c.VK_DEBUG_UTILS_MESSAGE_TYPE_VALIDATION_BIT_EXT,
          PERFORMANCE = c.VK_DEBUG_UTILS_MESSAGE_TYPE_PERFORMANCE_BIT_EXT,
          DEVICE_ADDRESS_BINDING = c.VK_DEBUG_UTILS_MESSAGE_TYPE_DEVICE_ADDRESS_BINDING_BIT_EXT,

          pub fn in (self: @This (), flags: vk.EXT.DebugUtils.Message.Type.Flags) bool
          {
            return (flags & @intFromEnum (self)) == @intFromEnum (self);
          }
        };
      };
    };

    pub const Messenger = enum (u64)
    {
      NULL_HANDLE = 0, _,

      pub fn create (instance: vk.Instance, p_create_info: *const vk.EXT.DebugUtils.Messenger.Create.Info, p_allocator: ?*const vk.AllocationCallbacks) !@This ()
      {
        var messenger: vk.EXT.DebugUtils.Messenger = undefined;
        const result = vk.raw.instance.vkCreateDebugUtilsMessengerEXT (instance, p_create_info, p_allocator, &messenger);
        if (result > 0)
        {
          std.debug.print ("{s} failed with {} status code\n", .{ @typeName (@This ()) ++ "." ++ @src ().fn_name, result, });
          return error.UnexpectedResult;
        }
        return messenger;
      }

      pub fn destroy (self: @This (), instance: vk.Instance, p_allocator: ?*const vk.AllocationCallbacks) void
      {
        vk.raw.instance.vkDestroyDebugUtilsMessengerEXT (instance, self, p_allocator);
      }

      pub const Callback = extern struct
      {
        pub const Data = extern struct
        {
          s_type: vk.StructureType = .DEBUG_UTILS_MESSENGER_CALLBACK_DATA_EXT,
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
          s_type: vk.StructureType = .DEBUG_UTILS_MESSENGER_CREATE_INFO_EXT,
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
      s_type: vk.StructureType = .DEBUG_UTILS_OBJECT_NAME_INFO_EXT,
      p_next: ?*const anyopaque = null,
      object_type: vk.ObjectType,
      object_handle: u64,
      p_object_name: ?[*:0] const u8 = null,
    };
  };

  pub const ValidationFeature = extern struct
  {
    pub const Disable = enum (i32) {};

    pub const Enable = enum (i32)
    {
      BEST_PRACTICES = c.VK_VALIDATION_FEATURE_ENABLE_BEST_PRACTICES_EXT,
      DEBUG_PRINTF = c.VK_VALIDATION_FEATURE_ENABLE_DEBUG_PRINTF_EXT,
    };
  };

  pub const ValidationFeatures = extern struct
  {
    s_type: vk.StructureType = .VALIDATION_FEATURES_EXT,
    p_next: ?*const anyopaque = null,
    enabled_validation_feature_count: u32 = 0,
    p_enabled_validation_features: ?[*] const vk.EXT.ValidationFeature.Enable = null,
    disabled_validation_feature_count: u32 = 0,
    p_disabled_validation_features: ?[*] const vk.EXT.ValidationFeature.Disable = null,
  };
};

pub const KHR = extern struct
{
  pub const SHADER_NON_SEMANTIC_INFO = c.VK_KHR_SHADER_NON_SEMANTIC_INFO_EXTENSION_NAME;
  pub const ColorSpace = enum (i32)
  {
    SRGB_NONLINEAR_KHR = c.VK_COLOR_SPACE_SRGB_NONLINEAR_KHR,
  };

  pub const CompositeAlpha = extern struct
  {
    pub const Flags = extern struct
    {
      pub const OPAQUE_BIT_KHR = c.VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR;
    };
  };

  pub const PresentMode = enum (i32)
  {
    IMMEDIATE_KHR = c.VK_PRESENT_MODE_IMMEDIATE_KHR,
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
      pub const Flags = extern struct
      {
        pub const IDENTITY_BIT_KHR = c.VK_SURFACE_TRANSFORM_IDENTITY_BIT_KHR;
      };
    };
  };

  pub const Swapchain = enum (u64) { NULL_HANDLE = 0, _, };
};
