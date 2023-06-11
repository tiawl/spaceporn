const std   = @import ("std");

const vk = @import ("vulkan");

const BaseDispatch = vk.BaseWrapper(.{
  .createInstance      = true,
  .getInstanceProcAddr = true,
});

const InstanceDispatch = vk.InstanceWrapper(.{
  .destroyInstance = true,
});

const utils = @import ("utils.zig");
const Error = utils.SpacedreamError;
const debug = utils.debug;
const exe   = utils.exe;

pub const context_vk_t = struct
{
  instance:           vk.Instance,
  app_info:           vk.ApplicationInfo,
  create_info:        vk.InstanceCreateInfo,
  extensions:         *[][*:0] const u8,
  instance_proc_addr: *const fn (?*anyopaque, [*:0] const u8) callconv (.C) ?*const fn () callconv (.C) void,
  vkb:                BaseDispatch,
  vki:                InstanceDispatch,

  fn init_instance (self: *context_vk_t) Error!void
  {
    self.vkb = BaseDispatch.load (@ptrCast (vk.PfnGetInstanceProcAddr, self.instance_proc_addr)) catch
    {
      std.log.err ("Load Vulkan Base Dispath error", .{});
      return Error.InitError;
    };

    self.app_info.p_application_name  = exe;
    self.app_info.application_version = vk.makeApiVersion (0, 0, 0, 0);
    self.app_info.p_engine_name       = "No Engine";
    self.app_info.engine_version      = vk.makeApiVersion (0, 0, 0, 0);
    self.app_info.api_version         = vk.API_VERSION_1_2;

    self.create_info.enabled_layer_count        = 0;
    self.create_info.p_application_info         = &(self.app_info);
    self.create_info.enabled_extension_count    = @intCast (u32, self.extensions.*.len);
    self.create_info.pp_enabled_extension_names = @ptrCast ([*] const [*:0] const u8, self.extensions.*);

    self.instance = self.vkb.createInstance (&(self.create_info), null) catch
    {
      std.log.err ("Create Vulkan Instance error", .{});
      return Error.InitError;
    };

    self.vki = InstanceDispatch.load (self.instance, self.vkb.dispatch.vkGetInstanceProcAddr) catch
    {
      std.log.err ("Load Vulkan Instance Dispath error", .{});
      return Error.InitError;
    };
    errdefer self.vki.destroyInstance (self.instance, null);

    debug ("Init Vulkan Instance OK", .{});
  }

  pub fn init (extensions: *[][*:0] const u8, instance_proc_addr: *const fn (?*anyopaque, [*:0] const u8) callconv (.C) ?*const fn () callconv (.C) void) Error!context_vk_t
  {
    var self: context_vk_t = undefined;
    self.extensions = extensions;
    self.instance_proc_addr = instance_proc_addr;
    init_instance (&self) catch |err|
    {
      std.log.err ("Init Vulkan Instance error", .{});
      return err;
    };
    debug ("Init Vulkan OK", .{});
    return self;
  }
};

pub fn loop () Error!void
{
  debug ("Loop Vulkan OK", .{});
}

pub fn cleanup (context: *context_vk_t) Error!void
{
  context.vki.destroyInstance (context.instance, null);
  debug ("Clean Up Vulkan OK", .{});
}
