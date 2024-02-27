const c = @import ("c");

const vk = @import ("vulkan");

pub usingnamespace imgui;

pub const imgui = struct
{
  pub const vulkan = extern struct
  {
    pub const InitInfo = extern struct
    {
      Instance:              vk.Instance,
      PhysicalDevice:        vk.PhysicalDevice,
      Device:                vk.Device,
      QueueFamily:           u32,
      Queue:                 vk.Queue,
      PipelineCache:         vk.PipelineCache,
      DescriptorPool:        vk.DescriptorPool,
      Subpass:               u32,
      MinImageCount:         u32,
      ImageCount:            u32,
      MSAASamples:           c_uint,
      UseDynamicRendering:   bool,
      ColorAttachmentFormat: i32,
      Allocator:             [*c] const vk.AllocationCallbacks,
      CheckVkResultFn:       ?*const fn (c_int) callconv (.C) void,
    };
  };
};
