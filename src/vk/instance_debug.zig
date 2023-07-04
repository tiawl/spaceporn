const std   = @import ("std");
const build = @import ("build_options");
const vk    = @import ("vulkan");

const utils    = @import ("../utils.zig");
const log_app  = utils.log_app;
const log_vk   = utils.log_vk;
const exe      = utils.exe;
const profile  = utils.profile;
const severity = utils.severity;

const dispatch_vk      = @import ("dispatch.zig");
const BaseDispatch     = dispatch_vk.BaseDispatch;
const InstanceDispatch = dispatch_vk.InstanceDispatch;

const ext_vk = struct
{
  name: [*:0] const u8,
  supported: bool = false,
};

pub const instance_vk = struct
{
  base_dispatch:      BaseDispatch = undefined,
  dispatch:           InstanceDispatch = undefined,
  instance:           vk.Instance = undefined,
  extensions:         [][*:0] const u8 = undefined,
  instance_proc_addr: *const fn (?*anyopaque, [*:0] const u8) callconv (.C) ?*const fn () callconv (.C) void = undefined,
  debug_messenger:    vk.DebugUtilsMessengerEXT = undefined,

  const Self = @This ();

  pub const required_layers = [_][] const u8
  {
    "VK_LAYER_KHRONOS_validation",
  };

  const required_extensions = [_][*:0] const u8
  {
    vk.extension_info.ext_debug_report.name,
    vk.extension_info.ext_debug_utils.name,
  };

  var optional_extensions = [_] ext_vk
  {
    .{
       .name = vk.extension_info.ext_device_address_binding_report.name,
     },
  };

  const InitVkError = error
  {
    ExtensionNotSupported,
    LayerNotAvailable,
  };

  fn debug_callback (
    message_severity: vk.DebugUtilsMessageSeverityFlagsEXT,
    message_type:     vk.DebugUtilsMessageTypeFlagsEXT,
    p_callback_data:  ?*const vk.DebugUtilsMessengerCallbackDataEXT,
    p_user_data:      ?*anyopaque) bool
  {
    _ = p_user_data;

    var sev: severity = undefined;
    var _type: [] const u8 = undefined;

    if (message_severity.verbose_bit_ext)
    {
      sev = severity.DEBUG;
    } else if (message_severity.info_bit_ext) {
      sev = severity.INFO;
    } else if (message_severity.warning_bit_ext) {
      sev = severity.WARNING;
    } else if (message_severity.error_bit_ext) {
      sev = severity.ERROR;
    }

    if (message_type.general_bit_ext)
    {
      _type = " GENERAL";
    } else if (message_type.validation_bit_ext) {
      _type = " VALIDATION";
    } else if (message_type.performance_bit_ext) {
      _type = " PERFORMANCE";
    } else if (message_type.device_address_binding_bit_ext) {
      _type = " DEVICE ADDR BINDING";
    }

    log_vk ("{s}", sev, _type, .{ p_callback_data.?.p_message }) catch
    {
      return false;
    };

    return true;
  }

  fn check_layer_properties (self: *Self, allocator: std.mem.Allocator) !void
  {
    var available_layers_count: u32 = undefined;

    _ = try self.base_dispatch.enumerateInstanceLayerProperties (&available_layers_count, null);

    var available_layers = try allocator.alloc (vk.LayerProperties, available_layers_count);

    _ = try self.base_dispatch.enumerateInstanceLayerProperties (&available_layers_count, available_layers.ptr);

    var i: usize = 0;
    var found: bool = undefined;
    var flag = false;

    for (required_layers) |layer|
    {
      found = false;

      while (i < available_layers_count)
      {
        if (std.mem.eql (u8, layer, available_layers[i].layer_name[0..layer.len])) found = true;
        i += 1;
      }

      if (found)
      {
        try log_app ("{s} required layer is available", severity.DEBUG, .{ layer });
      } else {
        try log_app ("{s} required layer is not available", severity.ERROR, .{ layer });
        return InitVkError.LayerNotAvailable;
      }

      flag = false;
    }

    try log_app ("check Vulkan layer properties initializer OK", severity.DEBUG, .{});
  }

  fn init_debug_info (debug_info: *vk.DebugUtilsMessengerCreateInfoEXT) void
  {
    debug_info.* = vk.DebugUtilsMessengerCreateInfoEXT
                   {
                     .message_severity = vk.DebugUtilsMessageSeverityFlagsEXT
                                         {
                                           .verbose_bit_ext = (build.LOG_LEVEL > @intFromEnum (profile.DEFAULT)),
                                           .info_bit_ext    = true,
                                           .warning_bit_ext = true,
                                           .error_bit_ext   = true,
                                         },
                     .message_type = vk.DebugUtilsMessageTypeFlagsEXT
                                     {
                                       .general_bit_ext                = true,
                                       .validation_bit_ext             = true,
                                       .device_address_binding_bit_ext = blk:
                                                                         {
                                                                           for (optional_extensions) |ext|
                                                                           {
                                                                             if (ext.name == vk.extension_info.ext_device_address_binding_report.name.ptr and ext.supported)
                                                                             {
                                                                               break :blk true;
                                                                             }
                                                                           }
                                                                           break :blk false;
                                                                         },
                                       .performance_bit_ext            = (build.LOG_LEVEL > @intFromEnum (profile.DEFAULT)),
                                     },
                     .pfn_user_callback = @ptrCast (&debug_callback),
                   };
  }

  fn check_extension_properties (self: *Self, debug_info: *vk.DebugUtilsMessengerCreateInfoEXT, allocator: std.mem.Allocator) !void
  {
    var extensions = try std.ArrayList ([*:0] const u8).initCapacity (allocator, self.extensions.len + required_extensions.len + optional_extensions.len);

    try extensions.appendSlice(self.extensions);

    var supported_extensions_count: u32 = undefined;

    _ = try self.base_dispatch.enumerateInstanceExtensionProperties (null, &supported_extensions_count, null);

    var supported_extensions = try allocator.alloc (vk.ExtensionProperties, supported_extensions_count);

    _ = try self.base_dispatch.enumerateInstanceExtensionProperties (null, &supported_extensions_count, supported_extensions.ptr);

    var supported: bool = undefined;

    for (required_extensions) |required_ext|
    {
      supported = false;
      for (supported_extensions) |supported_ext|
      {
        if (std.mem.eql (u8, supported_ext.extension_name [0..std.mem.indexOfScalar (u8, &(supported_ext.extension_name), 0).?], std.mem.span (required_ext)))
        {
          try extensions.append (@ptrCast (required_ext));
          try log_app ("{s} required extension is supported", severity.DEBUG, .{ required_ext });
          supported = true;
          break;
        }
      }
      if (!supported)
      {
        try log_app ("{s} required extension is not supported", severity.ERROR, .{ required_ext });
        return InitVkError.ExtensionNotSupported;
      }
    }

    for (&optional_extensions) |*optional_ext|
    {
      for (supported_extensions) |supported_ext|
      {
        if (std.mem.eql (u8, supported_ext.extension_name[0..std.mem.indexOfScalar (u8, &(supported_ext.extension_name), 0).?], std.mem.span (optional_ext.name)))
        {
          try extensions.append (@ptrCast (optional_ext.name));
          try log_app ("{s} optional extension is supported", severity.DEBUG, .{ optional_ext.name });
          optional_ext.supported = true;
          break;
        }
      }
      if (!optional_ext.supported)
      {
        try log_app ("{s} optional extension is not supported", severity.WARNING, .{ optional_ext.name });
      }
    }

    self.extensions = extensions.items;

    init_debug_info (debug_info);

    const app_info = vk.ApplicationInfo
                     {
                       .p_application_name  = exe,
                       .application_version = vk.makeApiVersion (0, 1, 2, 0),
                       .p_engine_name       = "No Engine",
                       .engine_version      = vk.makeApiVersion (0, 1, 2, 0),
                       .api_version         = vk.API_VERSION_1_2,
                     };

    const create_info = vk.InstanceCreateInfo
                        {
                          .flags                      = vk.InstanceCreateFlags {},
                          .enabled_layer_count        = required_layers.len,
                          .pp_enabled_layer_names     = @ptrCast (required_layers[0..]),
                          .p_next                     = debug_info,
                          .p_application_info         = &app_info,
                          .enabled_extension_count    = @intCast (self.extensions.len),
                          .pp_enabled_extension_names = @ptrCast (self.extensions),
                        };

    self.instance = try self.base_dispatch.createInstance (&create_info, null);

    try log_app ("check Vulkan extension properties initializer OK", severity.DEBUG, .{});
  }

  pub fn init (extensions: *[][*:0] const u8,
    instance_proc_addr: *const fn (?*anyopaque, [*:0] const u8) callconv (.C) ?*const fn () callconv (.C) void,
    allocator: std.mem.Allocator) !Self
  {
    var self = Self {};
    var debug_info: vk.DebugUtilsMessengerCreateInfoEXT = undefined;

    self.extensions = extensions.*;
    self.instance_proc_addr = instance_proc_addr;

    self.base_dispatch = try BaseDispatch.load (@as(vk.PfnGetInstanceProcAddr, @ptrCast (self.instance_proc_addr)));

    try check_layer_properties (&self, allocator);
    try check_extension_properties (&self, &debug_info, allocator);

    self.dispatch = try InstanceDispatch.load (self.instance, self.base_dispatch.dispatch.vkGetInstanceProcAddr);
    errdefer self.dispatch.destroyInstance (self.instance, null);

    init_debug_info (&debug_info);
    self.debug_messenger = try self.dispatch.createDebugUtilsMessengerEXT (self.instance, &debug_info, null);
    errdefer self.dispatch.destroyDebugUtilsMessengerEXT (self.instance, self.debug_messenger, null);

    try log_app ("init Vulkan initializer instance OK", severity.DEBUG, .{});
    return self;
  }

  pub fn cleanup (self: Self) !void
  {
    self.dispatch.destroyDebugUtilsMessengerEXT (self.instance, self.debug_messenger, null);
    self.dispatch.destroyInstance (self.instance, null);

    try log_app ("cleanup Vulkan initializer OK", severity.DEBUG, .{});
  }
};
