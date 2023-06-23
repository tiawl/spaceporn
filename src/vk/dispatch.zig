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
  .destroyInstance                         = true,
  .createDebugUtilsMessengerEXT            = build.LOG_LEVEL > @enumToInt (profile.TURBO),
  .destroyDebugUtilsMessengerEXT           = build.LOG_LEVEL > @enumToInt (profile.TURBO),
  .destroySurfaceKHR                       = true,
  .getPhysicalDeviceSurfaceSupportKHR      = true,
  .getPhysicalDeviceSurfaceCapabilitiesKHR = true,
  .getPhysicalDeviceSurfaceFormatsKHR      = true,
  .getPhysicalDeviceSurfacePresentModesKHR = true,
  .enumeratePhysicalDevices                = true,
  .getPhysicalDeviceProperties             = true,
  .getPhysicalDeviceFeatures               = true,
  .getPhysicalDeviceQueueFamilyProperties  = true,
  .createDevice                            = true,
  .getDeviceProcAddr                       = true,
  .enumerateDeviceExtensionProperties      = true,
});

pub const DeviceDispatch = vk.DeviceWrapper (
.{
  .destroyDevice           = true,
  .getDeviceQueue          = true,
  .createSwapchainKHR      = true,
  .destroySwapchainKHR     = true,
  .getSwapchainImagesKHR   = true,
  .createImageView         = true,
  .destroyImageView        = true,
  .createShaderModule      = true,
  .destroyShaderModule     = true,
  .createPipelineLayout    = true,
  .destroyPipelineLayout   = true,
  .createRenderPass        = true,
  .destroyRenderPass       = true,
  .createGraphicsPipelines = true,
  .destroyPipeline         = true,
  .createFramebuffer       = true,
  .destroyFramebuffer      = true,
  .createCommandPool       = true,
  .destroyCommandPool      = true,
  .allocateCommandBuffers  = true,
  .freeCommandBuffers      = true,
  .beginCommandBuffer      = true,
  .cmdBeginRenderPass      = true,
  .cmdBindPipeline         = true,
  .cmdSetViewport          = true,
  .cmdSetScissor           = true,
  .cmdDraw                 = true,
  .cmdEndRenderPass        = true,
  .endCommandBuffer        = true,
  .createSemaphore         = true,
  .destroySemaphore        = true,
  .createFence             = true,
  .destroyFence            = true,
  .waitForFences           = true,
  .resetFences             = true,
  .acquireNextImageKHR     = true,
  .resetCommandBuffer      = true,
  .queueSubmit             = true,
  .queuePresentKHR         = true,
  .deviceWaitIdle          = true,
});
