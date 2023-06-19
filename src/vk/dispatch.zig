const build = @import ("build_options");

const vk = @import ("vulkan");

const utils    = @import ("../utils.zig");
const profile  = utils.profile;
const severity = utils.severity;

pub const BaseDispatch = vk.BaseWrapper (
.{
  .createInstance                       = true,
  .enumerateInstanceLayerProperties     = build.LOG_LEVEL > @enumToInt (profile.TURBO),
  .enumerateInstanceExtensionProperties = build.LOG_LEVEL > @enumToInt (profile.TURBO),
  .getInstanceProcAddr                  = true,
});

pub const InstanceDispatch = vk.InstanceWrapper (
.{
  .destroyInstance                        = true,
  .createDebugUtilsMessengerEXT           = build.LOG_LEVEL > @enumToInt (profile.TURBO),
  .destroyDebugUtilsMessengerEXT          = build.LOG_LEVEL > @enumToInt (profile.TURBO),
  .enumeratePhysicalDevices               = true,
  .getPhysicalDeviceProperties            = true,
  .getPhysicalDeviceFeatures              = true,
  .getPhysicalDeviceQueueFamilyProperties = true,
  .createDevice                           = true,
  .getDeviceProcAddr                      = true,
});

pub const DeviceDispatch = vk.DeviceWrapper(
.{
  .destroyDevice  = true,
  .getDeviceQueue = true,
});
