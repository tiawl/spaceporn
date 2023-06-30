const std = @import ("std");
const vk  = @import ("vulkan");

const utils      = @import ("../utils.zig");
const log_app    = utils.log_app;
const exe        = utils.exe;
const severity   = utils.severity;

const dispatch_vk      = @import ("dispatch.zig");
const BaseDispatch     = dispatch_vk.BaseDispatch;
const InstanceDispatch = dispatch_vk.InstanceDispatch;

pub const instance_vk = struct
{
  base_dispatch:      BaseDispatch,
  dispatch:           InstanceDispatch,
  instance:           vk.Instance,
  extensions:         [][*:0] const u8,
  instance_proc_addr: *const fn (?*anyopaque, [*:0] const u8) callconv (.C) ?*const fn () callconv (.C) void,

  const Self = @This ();

  pub const required_layers = [_][] const u8 {};

  pub fn init (extensions: *[][*:0] const u8,
    instance_proc_addr: *const fn (?*anyopaque, [*:0] const u8) callconv (.C) ?*const fn () callconv (.C) void,
    allocator: *std.mem.Allocator) !Self
  {
    _ = allocator;

    var self: Self = undefined;

    self.extensions = extensions.*;
    self.instance_proc_addr = instance_proc_addr;

    self.base_dispatch = try BaseDispatch.load (@as(vk.PfnGetInstanceProcAddr, @ptrCast (self.instance_proc_addr)));

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
                          .enabled_layer_count        = 0,
                          .pp_enabled_layer_names     = undefined,
                          .p_application_info         = &app_info,
                          .enabled_extension_count    = @intCast (self.extensions.len),
                          .pp_enabled_extension_names = @ptrCast (self.extensions),
                        };

    self.instance = try self.base_dispatch.createInstance (&create_info, null);

    self.dispatch = try InstanceDispatch.load (self.instance, self.base_dispatch.dispatch.vkGetInstanceProcAddr);
    errdefer self.dispatch.destroyInstance (self.instance, null);

    return self;
  }

  pub fn cleanup (self: Self) !void
  {
    self.dispatch.destroyInstance (self.instance, null);
  }
};
