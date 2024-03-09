const std = @import ("std");
const vk  = @import ("vk");

const Logger = @import ("logger").Logger;

// TODO: why ?
const ext_vk = struct
{
  name: [*:0] const u8,
  supported: bool = false,
};

pub const instance_vk = struct
{
  instance:        vk.Instance = undefined,
  extensions:      [][*:0] const u8 = undefined,
  debug_messenger: vk.EXT.DebugUtils.Messenger = undefined,
  logger:          *const Logger = undefined,

  pub const required_layers = [_][*:0] const u8
  {
    "VK_LAYER_KHRONOS_validation",
  };

  const required_extensions = [_][*:0] const u8
  {
    vk.extension_info.ext_debug_report.name,
    vk.extension_info.ext_debug_utils.name,
  };

  var optional_extensions: [] const ext_vk = undefined;

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
    const self = @as (?*instance_vk, @ptrCast (@alignCast (p_user_data)));

    var event: [] const u8 = undefined;

    if (message_type.general_bit_ext)
    {
      event = " GENERAL";
    } else if (message_type.validation_bit_ext) {
      event = " VALIDATION";
    } else if (message_type.performance_bit_ext) {
      event = " PERFORMANCE";
    } else if (message_type.device_address_binding_bit_ext) {
      event = " DEVICE ADDR BINDING";
    }

    if (message_severity.verbose_bit_ext)
    {
      self.logger.vk ("{s}", .DEBUG, event, .{ p_callback_data.?.p_message }) catch return false;
    } else if (message_severity.info_bit_ext) {
      self.logger.vk ("{s}", .INFO, event, .{ p_callback_data.?.p_message }) catch return false;
    } else if (message_severity.warning_bit_ext) {
      self.logger.vk ("{s}", .WARNING, event, .{ p_callback_data.?.p_message }) catch return false;
    } else if (message_severity.error_bit_ext) {
      self.logger.vk ("{s}", .ERROR, event, .{ p_callback_data.?.p_message }) catch return false;
    }

    return true;
  }

  fn check_layer_properties (self: *@This ()) !void
  {
    var available_layers_count: u32 = undefined;

    try vk.load ();

    try vk.Instance.LayerProperties.enumerate (&available_layers_count, null);

    var available_layers = try self.logger.allocator.alloc (vk.LayerProperties, available_layers_count);

    try vk.Instance.LayerProperties.enumerate (&available_layers_count, available_layers.ptr);

    var i: usize = 0;
    var found: bool = undefined;
    var flag = false;

    for (required_layers) |layer|
    {
      found = false;

      while (i < available_layers_count)
      {
        const required_layer = std.mem.span (layer);
        const available_layer = available_layers [i].layer_name [0..required_layer.len];
        found = std.mem.eql (u8, required_layer, available_layer);
        if (found) break;
        i += 1;
      }

      if (found)
      {
        try self.logger.app (.DEBUG, "{s} required layer is available", .{ layer });
      } else {
        try self.logger.app (.ERROR, "{s} required layer is not available", .{ layer });
        return InitVkError.LayerNotAvailable;
      }

      flag = false;
    }

    try self.logger.app (.DEBUG, "check Vulkan layer properties initializer OK", .{});
  }

  fn init_debug_info (self: @This (), debug_info: *vk.DebugUtilsMessengerCreateInfoEXT) void
  {
    const use_features = blk:
                         {
                           var i: u8 = 0;
                           for (optional_extensions) |ext|
                           {
                             if (ext.name == vk.extension_info.khr_shader_non_semantic_info.name.ptr and ext.supported)
                             {
                               i += 1;
                             } else if (ext.name == vk.extension_info.ext_validation_features.name.ptr and ext.supported) {
                               i += 1;
                             }
                           }
                           break :blk (i == 2);
                         };

    const enabled_features = [_] vk.ValidationFeatureEnableEXT { .debug_printf_ext, .best_practices_ext, };

    const features = vk.ValidationFeaturesEXT
                     {
                       .enabled_validation_feature_count  = enabled_features.len,
                       .p_enabled_validation_features     = &enabled_features,
                       .disabled_validation_feature_count = 0,
                       .p_disabled_validation_features    = null,
                     };

    debug_info.* = vk.DebugUtilsMessengerCreateInfoEXT
                   {
                     .message_severity  = vk.DebugUtilsMessageSeverityFlagsEXT
                                          {
                                            .verbose_bit_ext = (self.logger.profile.gt (.DEFAULT)),
                                            .info_bit_ext    = true,
                                            .warning_bit_ext = true,
                                            .error_bit_ext   = true,
                                          },
                     .message_type      = vk.DebugUtilsMessageTypeFlagsEXT
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
                                            .performance_bit_ext            = (self.logger.profile.gt (.DEFAULT)),
                                          },
                     .pfn_user_callback = @ptrCast (&debug_callback),
                     .p_user_data       = &self,
                     .p_next            = if (use_features) @ptrCast (&features) else null,
                   };
  }

  fn check_extension_properties (self: *@This (), debug_info: *vk.DebugUtilsMessengerCreateInfoEXT) !void
  {
    var extensions = try std.ArrayList ([*:0] const u8).initCapacity (self.logger.allocator.*, self.extensions.len + required_extensions.len + optional_extensions.len);

    try extensions.appendSlice(self.extensions);

    var supported_extensions_count: u32 = undefined;

    _ = try self.base_dispatch.enumerateInstanceExtensionProperties (null, &supported_extensions_count, null);

    const supported_extensions = try self.logger.allocator.alloc (vk.ExtensionProperties, supported_extensions_count);

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
          try self.logger.app (.DEBUG, "{s} required extension is supported", .{ required_ext });
          supported = true;
          break;
        }
      }
      if (!supported)
      {
        try self.logger.app (.ERROR, "{s} required extension is not supported", .{ required_ext });
        return InitVkError.ExtensionNotSupported;
      }
    }

    for (&optional_extensions) |*optional_ext|
    {
      for (supported_extensions) |supported_ext|
      {
        if (std.mem.eql (u8, supported_ext.extension_name [0..std.mem.indexOfScalar (u8, &(supported_ext.extension_name), 0).?], std.mem.span (optional_ext.name)))
        {
          try extensions.append (@ptrCast (optional_ext.name));
          try self.logger.app (.DEBUG, "{s} optional extension is supported", .{ optional_ext.name });
          optional_ext.supported = true;
          break;
        }
      }
      if (!optional_ext.supported)
      {
        try self.logger.app (.WARNING, "{s} optional extension is not supported", .{ optional_ext.name });
      }
    }

    self.extensions = extensions.items;

    self.init_debug_info (debug_info);

    const app_info = vk.ApplicationInfo
                     {
                       .p_application_name  = self.logger.binary.name,
                       .application_version = vk.makeApiVersion (0, 1, 2, 0),
                       .p_engine_name       = "No Engine",
                       .engine_version      = vk.makeApiVersion (0, 1, 2, 0),
                       .api_version         = vk.API_VERSION_1_2,
                     };

    const create_info = vk.InstanceCreateInfo
                        {
                          .flags                      = vk.InstanceCreateFlags {},
                          .enabled_layer_count        = required_layers.len,
                          .pp_enabled_layer_names     = required_layers [0..].ptr,
                          .p_next                     = debug_info,
                          .p_application_info         = &app_info,
                          .enabled_extension_count    = @intCast (self.extensions.len),
                          .pp_enabled_extension_names = self.extensions [0..].ptr,
                        };

    self.instance = try self.base_dispatch.createInstance (&create_info, null);

    try self.logger.app (.DEBUG, "check Vulkan extension properties initializer OK", .{});
  }

  pub fn init (extensions: *[][*:0] const u8, logger: *const Logger) !@This ()
  {
    var self: @This () = .{ .logger = logger, };

    optional_extensions = if (self.logger.profile.gt (.DEFAULT))
                            &.{
                                .{ .name = vk.extension_info.ext_device_address_binding_report.name, },
                                .{ .name = vk.extension_info.khr_shader_non_semantic_info.name, },
                                .{ .name = vk.extension_info.ext_validation_features.name, },
                              }
                          else
                            &.{
                                .{ .name = vk.extension_info.ext_device_address_binding_report.name, },
                              };

    var debug_info: vk.EXT.DebugUtils.Messenger.Create.Info = undefined;

    self.extensions = extensions.*;

    try check_layer_properties (&self);
    try check_extension_properties (&self, &debug_info);

    errdefer self.dispatch.destroyInstance (self.instance, null);

    self.init_debug_info (&debug_info);
    self.debug_messenger = try self.dispatch.createDebugUtilsMessengerEXT (self.instance, &debug_info, null);
    errdefer self.dispatch.destroyDebugUtilsMessengerEXT (self.instance, self.debug_messenger, null);

    try self.logger.app (.DEBUG, "init Vulkan initializer instance OK", .{});
    return self;
  }

  pub fn cleanup (self: @This ()) !void
  {
    self.dispatch.destroyDebugUtilsMessengerEXT (self.instance, self.debug_messenger, null);
    self.dispatch.destroyInstance (self.instance, null);

    try self.logger.app (.DEBUG, "cleanup Vulkan initializer OK", .{});
  }
};
