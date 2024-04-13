const std = @import ("std");
const c   = @import ("c");

const vk  = @import ("vk");
const raw = @import ("raw");

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

        pub fn contains (self: @This (),
          flags: vk.EXT.DebugUtils.Message.Severity.Flags) bool
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

        pub fn contains (self: @This (),
          flags: vk.EXT.DebugUtils.Message.Type.Flags) bool
        {
          return (flags & @intFromEnum (self)) == @intFromEnum (self);
        }
      };
    };
  };

  pub const Messenger = enum (u64)
  {
    NULL_HANDLE = vk.NULL_HANDLE, _,

    pub fn create (instance: vk.Instance,
      p_create_info: *const vk.EXT.DebugUtils.Messenger.Create.Info) !@This ()
    {
      var messenger: @This () = undefined;
      const p_allocator: ?*const vk.AllocationCallbacks = null;
      const result = raw.prototypes.instance.vkCreateDebugUtilsMessengerEXT (
        instance, p_create_info, p_allocator, &messenger);
      if (result > 0)
      {
        std.debug.print ("{s} failed with {} status code\n",
          .{ @typeName (@This ()) ++ "." ++ @src ().fn_name, result, });
        return error.UnexpectedResult;
      }
      return messenger;
    }

    pub fn destroy (self: @This (), instance: vk.Instance) void
    {
      const p_allocator: ?*const vk.AllocationCallbacks = null;
      raw.prototypes.instance.vkDestroyDebugUtilsMessengerEXT (instance, self,
        p_allocator);
    }

    pub const Callback = extern struct
    {
      pub const Data = extern struct
      {
        s_type: vk.StructureType = .DEBUG_UTILS_MESSENGER_CALLBACK_DATA_EXT,
        p_next: ?*const anyopaque = null,
        flags: vk.EXT.DebugUtils.Messenger.Callback.Data.Flags = 0,
        p_message_id_name: ?[*:0] const u8 = null,
        message_id_number: i32,
        p_message: [*:0] const u8,
        queue_label_count: u32 = 0,
        p_queue_labels: ?[*] const vk.EXT.DebugUtils.Label = null,
        cmd_buf_label_count: u32 = 0,
        p_cmd_buf_labels: ?[*] const vk.EXT.DebugUtils.Label = null,
        object_count: u32 = 0,
        p_objects: ?[*] const vk.EXT.DebugUtils.ObjectNameInfo = null,

        pub const Flags = u32;
      };

      pub const Pfn = ?*const fn (
        message_severity: vk.EXT.DebugUtils.Message.Severity.Flags,
        message_types: vk.EXT.DebugUtils.Message.Type.Flags,
        p_callback_data: ?*const vk.EXT.DebugUtils.Messenger.Callback.Data,
        p_user_data: ?*anyopaque,
      ) callconv (c.call_conv) vk.Bool32;
    };

    pub const Create = extern struct
    {
      pub const Flags = u32;

      pub const Info = extern struct
      {
        s_type: vk.StructureType = .DEBUG_UTILS_MESSENGER_CREATE_INFO_EXT,
        p_next: ?*const anyopaque = null,
        flags: vk.EXT.DebugUtils.Messenger.Create.Flags = 0,
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
