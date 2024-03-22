const std = @import ("std");
const c   = @import ("c");

const vk  = @import ("vk");
const raw = @import ("raw");

pub const DEVICE_ADDRESS_BINDING_REPORT = c.VK_EXT_DEVICE_ADDRESS_BINDING_REPORT_EXTENSION_NAME;
pub const DEBUG_REPORT = c.VK_EXT_DEBUG_REPORT_EXTENSION_NAME;
pub const DEBUG_UTILS = c.VK_EXT_DEBUG_UTILS_EXTENSION_NAME;
pub const VALIDATION_FEATURES = c.VK_EXT_VALIDATION_FEATURES_EXTENSION_NAME;

pub const DebugUtils = @import ("debug_utils").DebugUtils;

pub const ValidationFeature = extern struct
{
  pub const Disable = enum (i32) {};

  pub const Enable = enum (i32)
  {
    BEST_PRACTICES = c.VK_VALIDATION_FEATURE_ENABLE_BEST_PRACTICES_EXT,
    DEBUG_PRINTF = c.VK_VALIDATION_FEATURE_ENABLE_DEBUG_PRINTF_EXT,
  };
};

pub const ValidationFeatures = extern struct
{
  s_type: vk.StructureType = .VALIDATION_FEATURES_EXT,
  p_next: ?*const anyopaque = null,
  enabled_validation_feature_count: u32 = 0,
  p_enabled_validation_features: ?[*] const vk.EXT.ValidationFeature.Enable = null,
  disabled_validation_feature_count: u32 = 0,
  p_disabled_validation_features: ?[*] const vk.EXT.ValidationFeature.Disable = null,
};
