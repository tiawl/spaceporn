const std   = @import ("std");
const builtin = @import ("builtin");

const vk = @import ("vulkan");

const BaseDispatch = vk.BaseWrapper(.{
  .createInstance                   = true,
  .enumerateInstanceLayerProperties = true,
  .getInstanceProcAddr              = true,
});

const InstanceDispatch = vk.InstanceWrapper(.{
  .destroyInstance = true,
});

const build = @import ("build_options");

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

  const Self = @This ();

  pub const ContextVkError = error
  {
    LayerNotAvailable,
  };

  fn init_instance (self: *Self) !void
  {
    self.base_dispatch = BaseDispatch.load (@ptrCast (vk.PfnGetInstanceProcAddr, self.instance_proc_addr)) catch |err|
    {
      std.log.err ("Load Vulkan Base Dispath error", .{});
      return err;
    };

    if (build.DEV)
    {
      const layers = [_][] const u8
      {
        "VK_LAYER_KHRONOS_validation",
      };

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

      debug ("  Available layers:", .{});

      var i: usize = 0;
      var found: bool = undefined;
      var flag = false;

      for (layers) |layer|
      {
        found = false;

        while (i < available_layers_count)
        {
          if (!flag) debug ("  - {s}", .{ available_layers[i].layer_name[0..layer.len] });
          if (std.mem.eql (u8, layer, available_layers[i].layer_name[0..layer.len])) found = true;
          i += 1;
        }

        if (!found)
        {
          std.log.err ("{s} layer not available", .{ layer });
          return ContextVkError.LayerNotAvailable;
        }

        flag = false;
      }
    }

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

    debug ("Init Vulkan OK", .{});
    return self;
  }

  pub fn loop (self: Self) !void
  {
    _ = self;
    debug ("Loop Vulkan OK", .{});
  }

  pub fn cleanup (self: Self) !void
  {
    self.instance_dispatch.destroyInstance (self.instance, null);
    debug ("Clean Up Vulkan OK", .{});
  }
};
