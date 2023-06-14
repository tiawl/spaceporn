const std   = @import ("std");
const builtin = @import ("builtin");

const build = @import ("build_options");

const vk = @import ("vulkan");

const BaseDispatch = vk.BaseWrapper(.{
  .createInstance                       = true,
  .enumerateInstanceLayerProperties     = build.DEV,
  .enumerateInstanceExtensionProperties = build.DEV,
  .getInstanceProcAddr                  = true,
});

const InstanceDispatch = vk.InstanceWrapper(.{
  .destroyInstance               = true,
  .createDebugUtilsMessengerEXT  = build.DEV,
  .destroyDebugUtilsMessengerEXT = build.DEV,
});

const utils            = @import ("utils.zig");
const debug_spacedream = utils.debug_spacedream;
const debug_vk         = utils.debug_vk;
const exe              = utils.exe;

pub const context_vk = struct
{
  base_dispatch:      BaseDispatch,
  instance_dispatch:  InstanceDispatch,
  instance:           vk.Instance,
  app_info:           vk.ApplicationInfo,
  create_info:        vk.InstanceCreateInfo,
  extensions:         [][*:0] const u8,
  instance_proc_addr: *const fn (?*anyopaque, [*:0] const u8) callconv (.C) ?*const fn () callconv (.C) void,
  debug_messenger:    vk.DebugUtilsMessengerEXT,
  debug_info:         vk.DebugUtilsMessengerCreateInfoEXT,

  const Self = @This ();

  const required_layers = [_][] const u8
  {
    "VK_LAYER_KHRONOS_validation",
  };

  const required_extensions = [_][*:0] const u8
  {
    vk.extension_info.ext_debug_report.name,
    vk.extension_info.ext_debug_utils.name,
  };

  const ContextVkError = error
  {
    ExtensionNotSupported,
    LayerNotAvailable,
  };

  fn debug_callback (
    message_severity: vk.DebugUtilsMessageSeverityFlagsEXT,
    message_type: vk.DebugUtilsMessageTypeFlagsEXT,
    p_callback_data: ?*const vk.DebugUtilsMessengerCallbackDataEXT,
    p_user_data: ?*anyopaque) bool
  {
    _ = p_user_data;

    var severity: [] const u8 = undefined;
    var _type: [] const u8 = undefined;

    if (message_severity.verbose_bit_ext)
    {
      severity = "VERBOSE";
    } else if (message_severity.info_bit_ext) {
      severity = "INFO";
    } else if (message_severity.warning_bit_ext) {
      severity = "WARNING";
    } else if (message_severity.error_bit_ext) {
      severity = "ERROR";
    }

    if (message_type.general_bit_ext)
    {
      _type = "GENERAL";
    } else if (message_type.validation_bit_ext) {
      _type = "VALIDATION";
    } else if (message_type.performance_bit_ext) {
      _type = "PERFORMANCE";
    }

    debug_vk ("{s}", severity, _type, .{ p_callback_data.?.p_message }) catch
    {
      return false;
    };

    return true;
  }

  fn check_layer_properties (self: *Self) !void
  {
    var available_layers_count: u32 = undefined;

    _ = self.base_dispatch.enumerateInstanceLayerProperties (&available_layers_count, null) catch |err|
    {
      std.log.err ("Enumerate Instance Layer Properties counting available layers error", .{});
      return err;
    };

    var gpa = std.heap.GeneralPurposeAllocator (.{}){};
    defer _ = gpa.deinit ();
    const allocator = gpa.allocator ();
    var available_layers = try allocator.alloc (vk.LayerProperties, available_layers_count);
    defer allocator.free (available_layers);

    _ = self.base_dispatch.enumerateInstanceLayerProperties (&available_layers_count, available_layers.ptr) catch |err|
    {
      std.log.err ("Enumerate Instance Layer Properties available layers error", .{});
      return err;
    };

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
        try debug_spacedream ("{s} layer available", .{ layer });
      } else {
        std.log.err ("{s} layer not available", .{ layer });
        return ContextVkError.LayerNotAvailable;
      }

      flag = false;
    }
  }

  fn init_debug_info (debug_info: *vk.DebugUtilsMessengerCreateInfoEXT) void
  {
    debug_info.* = vk.DebugUtilsMessengerCreateInfoEXT
                   {
                     .message_severity = .{
                                            .verbose_bit_ext = true,
                                            .info_bit_ext    = true,
                                            .warning_bit_ext = true,
                                            .error_bit_ext   = true,
                                          },
                     .message_type = .{
                                        .general_bit_ext     = true,
                                        .validation_bit_ext  = true,
                                        .performance_bit_ext = true,
                                      },
                     .pfn_user_callback = @ptrCast (vk.PfnDebugUtilsMessengerCallbackEXT, &debug_callback),
                   };
  }

  fn check_extension_properties (self: *Self) !void
  {
    var gpa = std.heap.GeneralPurposeAllocator (.{}){};
    defer _ = gpa.deinit ();
    const allocator = gpa.allocator ();

    var extensions = std.ArrayList ([*:0] const u8).initCapacity (allocator, self.extensions.len + 1) catch |err|
    {
      std.log.err ("Init ArrayList extensions error", .{});
      return err;
    };
    defer extensions.deinit ();

    extensions.appendSlice(self.extensions) catch |err|
    {
      std.log.err ("ArrayList extensions appendSlice error", .{});
      return err;
    };

    var supported_extensions_count: u32 = undefined;

    _ = self.base_dispatch.enumerateInstanceExtensionProperties (null, &supported_extensions_count, null) catch |err|
    {
      std.log.err ("Enumerate Instance Extension Properties counting supported extension error", .{});
      return err;
    };

    var supported_extensions = try allocator.alloc (vk.ExtensionProperties, supported_extensions_count);
    defer allocator.free (supported_extensions);

    _ = self.base_dispatch.enumerateInstanceExtensionProperties (null, &supported_extensions_count, supported_extensions.ptr) catch |err|
    {
      std.log.err ("Enumerate Instance Extension Properties supported extension error", .{});
      return err;
    };

    for (required_extensions) |required_ext|
    {
      for (supported_extensions) |supported_ext|
      {
        if (std.mem.eql (u8, supported_ext.extension_name[0..std.mem.indexOfScalar (u8, &(supported_ext.extension_name), 0).?], std.mem.span (required_ext)))
        {
          extensions.append (@ptrCast ([*:0] const u8, required_ext)) catch |err|
          {
            std.log.err ("ArrayList extensions append VK_EXT_DEBUG_UTILS_EXTENSION_NAME error", .{});
            return err;
          };
          try debug_spacedream ("{s} extension supported", .{ required_ext });
          break;
        }
      }
    }

    self.extensions = extensions.items;

    var debug_info: vk.DebugUtilsMessengerCreateInfoEXT = undefined;
    init_debug_info (&debug_info);

    self.create_info = vk.InstanceCreateInfo
                       {
                         .enabled_layer_count        = required_layers.len,
                         .pp_enabled_layer_names     = @ptrCast ([*] const [*:0] const u8, required_layers[0..required_layers.len]),
                         .p_next                     = &debug_info,
                         .p_application_info         = &(self.app_info),
                         .enabled_extension_count    = @intCast (u32, self.extensions.len),
                         .pp_enabled_extension_names = @ptrCast ([*] const [*:0] const u8, self.extensions),
                       };

    self.instance = self.base_dispatch.createInstance (&self.create_info, null) catch |err|
    {
      std.log.err ("Create Vulkan Instance error", .{});
      return err;
    };
  }

  fn init_instance (self: *Self) !void
  {
    self.base_dispatch = BaseDispatch.load (@ptrCast (vk.PfnGetInstanceProcAddr, self.instance_proc_addr)) catch |err|
    {
      std.log.err ("Load Vulkan Base Dispath error", .{});
      return err;
    };

    if (build.DEV)
    {
      try check_layer_properties (self);
    }

    self.app_info = vk.ApplicationInfo
                    {
                      .p_application_name  = exe,
                      .application_version = vk.makeApiVersion (0, 1, 2, 0),
                      .p_engine_name       = "No Engine",
                      .engine_version      = vk.makeApiVersion (0, 1, 2, 0),
                      .api_version         = vk.API_VERSION_1_2,
                    };

    if (build.DEV)
    {
      try check_extension_properties (self);
    } else {
      self.create_info = vk.InstanceCreateInfo
                         {
                           .enabled_layer_count        = 0,
                           .pp_enabled_layer_names     = undefined,
                           .p_application_info         = &(self.app_info),
                           .enabled_extension_count    = @intCast (u32, self.extensions.len),
                           .pp_enabled_extension_names = @ptrCast ([*] const [*:0] const u8, self.extensions),
                         };

      self.instance = self.base_dispatch.createInstance (&self.create_info, null) catch |err|
      {
        std.log.err ("Create Vulkan Instance error", .{});
        return err;
      };
    }

    self.instance_dispatch = InstanceDispatch.load (self.instance, self.base_dispatch.dispatch.vkGetInstanceProcAddr) catch |err|
    {
      std.log.err ("Load Vulkan Instance Dispath error", .{});
      return err;
    };
    errdefer self.instance_dispatch.destroyInstance (self.instance, null);

    if (build.DEV)
    {
      init_debug_info (&(self.debug_info));
      self.debug_messenger = self.instance_dispatch.createDebugUtilsMessengerEXT (self.instance, &(self.debug_info), null) catch |err|
      {
        std.log.err ("Create Debug Utils Messenger EXT error", .{});
        return err;
      };

      errdefer self.instance_dispatch.destroyDebugUtilsMessengerEXT (self.instance, self.debug_messenger, null);
    }

    try debug_spacedream ("Init Vulkan Instance OK", .{});
  }

  pub fn init (extensions: *[][*:0] const u8,
               instance_proc_addr: *const fn (?*anyopaque, [*:0] const u8) callconv (.C) ?*const fn () callconv (.C) void) !Self
  {
    var self: Self = undefined;

    self.extensions = extensions.*;
    self.instance_proc_addr = instance_proc_addr;

    init_instance (&self) catch |err|
    {
      std.log.err ("Init Vulkan Instance error", .{});
      return err;
    };

    try debug_spacedream ("Init Vulkan OK", .{});
    return self;
  }

  pub fn loop (self: Self) !void
  {
    _ = self;
    try debug_spacedream ("Loop Vulkan OK", .{});
  }

  pub fn cleanup (self: Self) !void
  {
    if (build.DEV)
    {
      self.instance_dispatch.destroyDebugUtilsMessengerEXT (self.instance, self.debug_messenger, null);
    }
    self.instance_dispatch.destroyInstance (self.instance, null);
    try debug_spacedream ("Clean Up Vulkan OK", .{});
  }
};
