const std = @import ("std");
const vk  = @import ("vk");

const Logger = @import ("logger").Logger;

pub const instance_vk = struct
{
  instance:   vk.Instance = undefined,
  extensions: [][*:0] const u8 = undefined,

  pub const required_layers = [_][] const u8 {};

  pub fn init (extensions: *[][*:0] const u8, logger: *const Logger) !@This ()
  {
    var self: @This () = .{};

    self.extensions = extensions.*;

    const app_info = vk.ApplicationInfo
                     {
                       .p_application_name  = logger.binary.name,
                       .application_version = vk.makeApiVersion (0, 1, 2, 0),
                       .p_engine_name       = "No Engine",
                       .engine_version      = vk.makeApiVersion (0, 1, 2, 0),
                       .api_version         = vk.API_VERSION_1_2,
                     };

    const create_info = vk.InstanceCreateInfo
                        {
                          .flags                      = vk.InstanceCreateFlags {},
                          .enabled_layer_count        = 0,
                          .pp_enabled_layer_names     = undefined,
                          .p_application_info         = &app_info,
                          .enabled_extension_count    = @intCast (self.extensions.len),
                          .pp_enabled_extension_names = @ptrCast (self.extensions),
                        };

    self.instance = try self.base_dispatch.createInstance (&create_info, null);
    errdefer self.dispatch.destroyInstance (self.instance, null);

    return self;
  }

  pub fn cleanup (self: @This ()) !void
  {
    self.dispatch.destroyInstance (self.instance, null);
  }
};
