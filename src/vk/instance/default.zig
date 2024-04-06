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
    vk.EXT.DEBUG_REPORT,
    vk.EXT.DEBUG_UTILS,
  };

  var optional_extensions = blk:
    {
      const size = Logger.build.vk.optional_extensions.len;
      var optionals: [size] ext_vk = undefined;
      for (Logger.build.vk.optional_extensions, 0 ..) |*ext, i|
      {
        var field = vk;
        for (0 .. ext.len - 1) |j| field = @field (field, ext.* [j]);
        optionals [i] = .{ .name = @field (field, ext.* [ext.len - 1]), };
      }
      break :blk &optionals;
    };

  const InitVkError = error
  {
    ExtensionNotSupported,
    LayerNotAvailable,
  };

  fn debug_callback (
    message_severity: vk.EXT.DebugUtils.Message.Severity.Flags,
    message_type:     vk.EXT.DebugUtils.Message.Type.Flags,
    p_callback_data:  ?*const vk.EXT.DebugUtils.Messenger.Callback.Data,
    p_user_data:      ?*anyopaque) bool
  {
    const self = @as (?*instance_vk, @ptrCast (@alignCast (p_user_data)));

    self.?.logger.vk (
      if (vk.EXT.DebugUtils.Message.Severity.Bit.VERBOSE.contains (message_severity)) .DEBUG
      else if (vk.EXT.DebugUtils.Message.Severity.Bit.INFO.contains (message_severity)) .INFO
      else if (vk.EXT.DebugUtils.Message.Severity.Bit.WARNING.contains (message_severity)) .WARNING
      else .ERROR,
      if (vk.EXT.DebugUtils.Message.Type.Bit.GENERAL.contains (message_type)) .GENERAL
      else if (vk.EXT.DebugUtils.Message.Type.Bit.VALIDATION.contains (message_type)) .VALIDATION
      else if (vk.EXT.DebugUtils.Message.Type.Bit.PERFORMANCE.contains (message_type)) .PERFORMANCE
      else .@"DEVICE ADDR BINDING",
      "{s}", .{ p_callback_data.?.p_message }) catch return false;

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

  fn init_debug_info (self: *@This (), debug_info: *vk.EXT.DebugUtils.Messenger.Create.Info) void
  {
    const use_features = blk:
                         {
                           var i: u8 = 0;
                           for (optional_extensions) |ext|
                           {
                             if (std.mem.eql (u8, std.mem.sliceTo (ext.name, 0), vk.KHR.SHADER_NON_SEMANTIC_INFO) and ext.supported) i += 1
                             else if (std.mem.eql (u8, std.mem.sliceTo (ext.name, 0), vk.EXT.VALIDATION_FEATURES) and ext.supported) i += 1;
                           }
                           break :blk (i == 2);
                         };

    const enabled_features = [_] vk.EXT.ValidationFeature.Enable { .DEBUG_PRINTF, .BEST_PRACTICES, };

    const features = vk.EXT.ValidationFeatures
                     {
                       .enabled_validation_feature_count  = enabled_features.len,
                       .p_enabled_validation_features     = &enabled_features,
                       .disabled_validation_feature_count = 0,
                       .p_disabled_validation_features    = null,
                     };

    debug_info.* = vk.EXT.DebugUtils.Messenger.Create.Info
                   {
                     .message_severity  = (@intFromEnum (vk.EXT.DebugUtils.Message.Severity.Bit.VERBOSE) & @intFromBool (Logger.build.profile.eql (.DEV))) |
                                          @intFromEnum (vk.EXT.DebugUtils.Message.Severity.Bit.INFO) |
                                          @intFromEnum (vk.EXT.DebugUtils.Message.Severity.Bit.WARNING) |
                                          @intFromEnum (vk.EXT.DebugUtils.Message.Severity.Bit.ERROR),
                     .message_type      = @intFromEnum (vk.EXT.DebugUtils.Message.Type.Bit.GENERAL) |
                                          @intFromEnum (vk.EXT.DebugUtils.Message.Type.Bit.VALIDATION) |
                                          (@intFromEnum (vk.EXT.DebugUtils.Message.Type.Bit.PERFORMANCE) & @intFromBool (Logger.build.profile.eql (.DEV))) | blk:
                                            {
                                              for (optional_extensions) |ext|
                                              {
                                                if (std.mem.eql (u8, std.mem.sliceTo (ext.name, 0), vk.EXT.DEVICE_ADDRESS_BINDING_REPORT) and ext.supported) break :blk 0;
                                              }
                                              break :blk @intFromEnum (vk.EXT.DebugUtils.Message.Type.Bit.DEVICE_ADDRESS_BINDING);
                                            },
                     .pfn_user_callback = @ptrCast (&debug_callback),
                     .p_user_data       = self,
                     .p_next            = if (use_features) @ptrCast (&features) else null,
                   };
  }

  fn check_extension_properties (self: *@This (), debug_info: *vk.EXT.DebugUtils.Messenger.Create.Info) !void
  {
    var extensions = try std.ArrayList ([*:0] const u8).initCapacity (self.logger.allocator.*, self.extensions.len + required_extensions.len + optional_extensions.len);

    try extensions.appendSlice(self.extensions);

    var supported_extensions_count: u32 = undefined;

    try vk.Instance.ExtensionProperties.enumerate (null, &supported_extensions_count, null);

    const supported_extensions = try self.logger.allocator.alloc (vk.ExtensionProperties, supported_extensions_count);

    try vk.Instance.ExtensionProperties.enumerate (null, &supported_extensions_count, supported_extensions.ptr);

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

    for (optional_extensions) |*optional_ext|
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
                       .p_application_name  = Logger.build.binary.name,
                       .application_version = @field (vk.API_VERSION.@"1", Logger.build.vk.minor),
                       .p_engine_name       = "No Engine",
                       .engine_version      = @field (vk.API_VERSION.@"1", Logger.build.vk.minor),
                       .api_version         = @field (vk.API_VERSION.@"1", Logger.build.vk.minor),
                     };

    const create_info = vk.Instance.Create.Info
                        {
                          .enabled_layer_count        = required_layers.len,
                          .pp_enabled_layer_names     = required_layers [0..].ptr,
                          .p_next                     = debug_info,
                          .p_application_info         = &app_info,
                          .enabled_extension_count    = @intCast (self.extensions.len),
                          .pp_enabled_extension_names = self.extensions [0..].ptr,
                        };

    self.instance = try vk.Instance.create (&create_info);

    try self.logger.app (.DEBUG, "check Vulkan extension properties initializer OK", .{});
  }

  pub fn init (extensions: *[][*:0] const u8, logger: *const Logger) !@This ()
  {
    var self: @This () = .{ .logger = logger, };

    var debug_info: vk.EXT.DebugUtils.Messenger.Create.Info = undefined;

    self.extensions = extensions.*;

    try check_layer_properties (&self);
    try check_extension_properties (&self, &debug_info);

    try self.instance.load ();
    errdefer self.instance.destroy ();

    self.init_debug_info (&debug_info);
    self.debug_messenger = try vk.EXT.DebugUtils.Messenger.create (self.instance, &debug_info);
    errdefer self.debug_messenger.destroy (self.instance);

    try self.logger.app (.DEBUG, "init Vulkan initializer instance OK", .{});
    return self;
  }

  pub fn cleanup (self: @This ()) !void
  {
    self.debug_messenger.destroy (self.instance);
    self.instance.destroy ();

    try self.logger.app (.DEBUG, "cleanup Vulkan initializer OK", .{});
  }
};
