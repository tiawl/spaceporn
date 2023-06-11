const vk = @import ("vulkan");

const BaseDispatch = vk.BaseWrapper(.{
  .createInstance = true,
});

const InstanceDispatch = vk.InstanceWrapper(.{
  .destroyInstance = true,
});

const wrapper_vk_t = struct
{
  vkb: ?BaseDispatch,
  vki: ?InstanceDispatch,
};

const utils = @import ("utils.zig");
const Error = utils.SpacedreamError;
const debug = utils.debug;
const exe   = utils.exe;

pub const context_vk_t = struct
{
  instance:           ?vk.Instance               = null,
  app_info:           ?vk.ApplicationInfo        = null,
  create_info:        ?vk.InstanceCreateInfo     = null,
  extensions:         ?[][*:0] const u8          = null,
  instance_proc_addr: ?vk.PfnGetInstanceProcAddr = null,
  wrapper:            ?wrapper_vk_t              = null,
};

fn init_instance (context: *context_vk_t) Error!void
{
  context.wrapper = wrapper_vk_t{};
  context.wrapper.vkb = try BaseDispatch.load (@ptrCast (vk.PfnGetInstanceProcAddr, &(context.instance_proc_addr)));

  context.app_info.p_application_name  = exe;
  context.app_info.application_version = vk.makeApiVersion (0, 1, 0, 0);
  context.app_info.p_engine_name       = "No Engine";
  context.app_info.engine_version      = vk.makeApiVersion (0, 1, 0, 0);
  context.app_info.api_version         = vk.API_VERSION_1_2;

  context.create_info.enabledLayerCount = 0;
  context.create_info.p_application_info         = context.app_info;
  context.create_info.enabled_extension_count    = context.extensions.len;
  context.create_info.pp_enabled_extension_names = context.extensions;

  context.instance = context.wrapper.?.vkb.?.createInstance (context.create_info, null);

  context.wrapper.?.vki = try InstanceDispatch.load(context.wrapper.?.vkb.?.dispatch.vkGetInstanceProcAddr);
  errdefer context.wrapper.?.vki.?.destroyInstance (context.instance.?, null);

  debug ("Init Vulkan Instance OK", .{});
}

pub fn init (context: *context_vk_t) Error!void
{
  init_instance (context);
  debug ("Init Vulkan OK", .{});
}

pub fn loop () Error!void
{
  debug ("Loop Vulkan OK", .{});
}

pub fn cleanup (context: *context_vk_t) Error!void
{
  context.wrapper.?.vki.?.destroyInstance (context.instance.?, null);
  debug ("Clean Up Vulkan OK", .{});
}
