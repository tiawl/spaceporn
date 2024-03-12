const std = @import ("std");
const vk  = @import ("vk");

const Logger = @import ("logger").Logger;

pub const instance_vk = struct
{
  instance:   vk.Instance = undefined,
  extensions: [][*:0] const u8 = undefined,

  pub const required_layers = [_][] const u8 {};

  pub fn init (extensions: *[][*:0] const u8, _: *const Logger) !@This ()
  {
    var self: @This () = .{};

    self.extensions = extensions.*;

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
                          .enabled_layer_count        = 0,
                          .pp_enabled_layer_names     = undefined,
                          .p_application_info         = &app_info,
                          .enabled_extension_count    = @intCast (self.extensions.len),
                          .pp_enabled_extension_names = @ptrCast (self.extensions),
                        };

    self.instance = try vk.Instance.create (&create_info, null);
    errdefer self.instance.destroy (null);

    try self.instance.load ();

    return self;
  }

  pub fn cleanup (self: @This ()) !void
  {
    self.instance.destroy (null);
  }
};
