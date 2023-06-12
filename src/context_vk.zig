const std   = @import ("std");
const builtin = @import("builtin");

const vk = @import ("vulkan");

const BaseDispatch = vk.BaseWrapper(.{
  .createInstance      = true,
  .getInstanceProcAddr = true,
});

const InstanceDispatch = vk.InstanceWrapper(.{
  .destroyInstance = true,
});

const utils = @import ("utils.zig");
const debug = utils.debug;
const exe   = utils.exe;

pub const context_vk = struct
{
  base_dispatch:      BaseDispatch,
  instance_dispatch:  InstanceDispatch,
  instance:           vk.Instance,
  app_info:           vk.ApplicationInfo,
  create_info:        vk.InstanceCreateInfo,
  extensions:         [][*:0] const u8,
  instance_proc_addr: *const fn (?*anyopaque, [*:0] const u8) callconv (.C) ?*const fn () callconv (.C) void,

  fn init_instance (self: *context_vk) !void
  {
    self.base_dispatch = BaseDispatch.load (@ptrCast (vk.PfnGetInstanceProcAddr, self.instance_proc_addr)) catch |err|
    {
      std.log.err ("Load Vulkan Base Dispath error", .{});
      return err;
    };

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
                         .p_application_info         = &(self.app_info),
                         .enabled_extension_count    = @intCast (u32, self.extensions.len),
                         .pp_enabled_extension_names = @ptrCast ([*] const [*:0] const u8, self.extensions),
                       };

    self.instance = self.base_dispatch.createInstance (&self.create_info, null) catch |err|
    {
      std.log.err ("Create Vulkan Instance error", .{});
      return err;
    };

    self.instance_dispatch = InstanceDispatch.load (self.instance, self.base_dispatch.dispatch.vkGetInstanceProcAddr) catch |err|
    {
      std.log.err ("Load Vulkan Instance Dispath error", .{});
      return err;
    };
    errdefer self.instance_dispatch.destroyInstance (self.instance, null);

    debug ("Init Vulkan Instance OK", .{});
  }

  pub fn init (extensions: *[][*:0] const u8,
               instance_proc_addr: *const fn (?*anyopaque, [*:0] const u8) callconv (.C) ?*const fn () callconv (.C) void) !context_vk
  {
    var self: context_vk = undefined;
    self.extensions = extensions.*;
    self.instance_proc_addr = instance_proc_addr;
    init_instance (&self) catch |err|
    {
      std.log.err ("Init Vulkan Instance error", .{});
      return err;
    };
    debug ("Init Vulkan OK", .{});
    return self;
  }

  pub fn loop (self: context_vk) !void
  {
    _ = self;
    debug ("Loop Vulkan OK", .{});
  }

  pub fn cleanup (self: context_vk) !void
  {
    self.instance_dispatch.destroyInstance (self.instance, null);
    debug ("Clean Up Vulkan OK", .{});
  }
};
