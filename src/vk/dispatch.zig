const vk = @import ("vulkan");

const utils      = @import ("../utils.zig");
const is_logging = utils.is_logging;
const severity   = utils.severity;

pub const BaseDispatch = vk.BaseWrapper (
.{
  .createInstance                       = true,
  .enumerateInstanceLayerProperties     = is_logging (severity.INFO),
  .enumerateInstanceExtensionProperties = is_logging (severity.INFO),
  .getInstanceProcAddr                  = true,
});

pub const InstanceDispatch = vk.InstanceWrapper (
.{
  .destroyInstance                        = true,
  .createDebugUtilsMessengerEXT           = is_logging (severity.INFO),
  .destroyDebugUtilsMessengerEXT          = is_logging (severity.INFO),
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
