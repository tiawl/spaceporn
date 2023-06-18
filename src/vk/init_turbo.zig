const vk = @import ("vulkan");

const utils      = @import ("../utils.zig");
const log_app    = utils.log_app;
const exe        = utils.exe;
const severity   = utils.severity;

const dispatch         = @import ("dispatch.zig");
const BaseDispatch     = dispatch.BaseDispatch;
const InstanceDispatch = dispatch.InstanceDispatch;

pub const init_vk = struct
{
  base_dispatch:      BaseDispatch,
  instance_dispatch:  InstanceDispatch,
  instance:           vk.Instance,
  app_info:           vk.ApplicationInfo,
  create_info:        vk.InstanceCreateInfo,
  extensions:         [][*:0] const u8,
  instance_proc_addr: *const fn (?*anyopaque, [*:0] const u8) callconv (.C) ?*const fn () callconv (.C) void,

  const Self = @This ();

  pub fn init_instance (extensions: *[][*:0] const u8,
    instance_proc_addr: *const fn (?*anyopaque, [*:0] const u8) callconv (.C) ?*const fn () callconv (.C) void) !Self
  {
    var self: Self = undefined;

    self.extensions = extensions.*;
    self.instance_proc_addr = instance_proc_addr;

    self.base_dispatch = try BaseDispatch.load (@ptrCast (vk.PfnGetInstanceProcAddr, self.instance_proc_addr));

    self.app_info = vk.ApplicationInfo
                    {
                      .p_application_name  = exe,
                      .application_version = vk.makeApiVersion (0, 1, 2, 0),
                      .p_engine_name       = "No Engine",
                      .engine_version      = vk.makeApiVersion (0, 1, 2, 0),
                      .api_version         = vk.API_VERSION_1_2,
                    };

    self.create_info = vk.InstanceCreateInfo
                       {
                         .enabled_layer_count        = 0,
                         .pp_enabled_layer_names     = undefined,
                         .p_application_info         = &(self.app_info),
                         .enabled_extension_count    = @intCast (u32, self.extensions.len),
                         .pp_enabled_extension_names = @ptrCast ([*] const [*:0] const u8, self.extensions),
                       };

    self.instance = try self.base_dispatch.createInstance (&self.create_info, null);

    self.instance_dispatch = try InstanceDispatch.load (self.instance, self.base_dispatch.dispatch.vkGetInstanceProcAddr);
    errdefer self.instance_dispatch.destroyInstance (self.instance, null);

    return self;
  }

  pub fn cleanup (self: Self) !void
  {
    self.instance_dispatch.destroyInstance (self.instance, null);
  }
};
