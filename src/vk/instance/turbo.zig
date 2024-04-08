const std = @import ("std");
const vk  = @import ("vk");

const Logger = @import ("logger").Logger;

pub const instance_vk = struct
{
  instance: vk.Instance = undefined,

  pub const required_layers = [_][*:0] const u8 {};

  pub fn init (extensions: *[][*:0] const u8, _: *const Logger) !@This ()
  {
    var self: @This () = .{};

    try vk.load ();

    const app_info = vk.ApplicationInfo
    {
      .p_application_name  = Logger.build.binary.name,
      .application_version =
        @field (vk.API_VERSION.@"1", Logger.build.vk.minor),
      .p_engine_name       = "No Engine",
      .engine_version      =
        @field (vk.API_VERSION.@"1", Logger.build.vk.minor),
      .api_version         =
        @field (vk.API_VERSION.@"1", Logger.build.vk.minor),
    };

    const create_info = vk.Instance.Create.Info
    {
      .enabled_layer_count        = required_layers.len,
      .pp_enabled_layer_names     = required_layers [0 ..].ptr,
      .p_application_info         = &app_info,
      .enabled_extension_count    = @intCast (extensions.len),
      .pp_enabled_extension_names = extensions.* [0 ..].ptr,
    };

    self.instance = try vk.Instance.create (&create_info);
    errdefer self.instance.destroy ();

    try self.instance.load ();

    return self;
  }

  pub fn cleanup (self: @This ()) !void
  {
    self.instance.destroy ();
  }
};
