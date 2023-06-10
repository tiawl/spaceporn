const vk  = @import ("vulkan");

const utils = @import ("utils.zig");
const Error = utils.SpacedreamError;
const debug = utils.debug;
const exe   = utils.exe;

pub const context_vk_t = struct
{
  instance:    ?vk.Instance           = null,
  app_info:    ?vk.ApplicationInfo    = null,
  create_info: ?vk.InstanceCreateInfo = null,
  extensions:  ?[][*:0] const u8      = null,
};

fn init_instance (context: *context_vk_t) Error!void
{
  context.app_info.sType              = VK_STRUCTURE_TYPE_APPLICATION_INFO;
  context.app_info.pApplicationName   = exe;
  context.app_info.applicationVersion = VK_MAKE_VERSION (1, 0, 0);
  context.app_info.pEngineName        = "No Engine";
  context.app_info.engineVersion      = VK_MAKE_VERSION (1, 0, 0);
  context.app_info.apiVersion         = VK_API_VERSION_1_0;

  context.create_info.enabledLayerCount = 0;
  context.create_info.sType                   = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO;
  context.create_info.pApplicationInfo        = context.app_info;
  context.create_info.enabledExtensionCount   = context.extensions.len;
  context.create_info.ppEnabledExtensionNames = context.extensions;

  createInstance (context.create_info, , context.instance);

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
  debug ("Clean Up Vulkan OK", .{});
}
