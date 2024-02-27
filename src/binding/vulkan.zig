const c = @import ("c");

pub usingnamespace vk;

pub const vk = struct
{
  pub const Buffer = enum (u64) { null_handle = 0, _ };
  pub const CommandBuffer = enum (usize) { null_handle = 0, _ };
  pub const CommandPool = enum (u64) { null_handle = 0, _ };
  pub const DescriptorPool = enum (u64) { null_handle = 0, _ };
  pub const DescriptorSet = enum (u64) { null_handle = 0, _ };
  pub const DescriptorSetLayout = enum (u64) { null_handle = 0, _ };
  pub const Device = enum (usize) { null_handle = 0, _ };
  pub const DeviceMemory = enum (u64) { null_handle = 0, _ };
  pub const Fence = enum (u64) { null_handle = 0, _ };
  pub const Framebuffer = enum (u64) { null_handle = 0, _ };
  pub const Image = enum (u64) { null_handle = 0, _ };
  pub const ImageView = enum (u64) { null_handle = 0, _ };
  pub const Instance = enum (usize) { null_handle = 0, _ };
  pub const PhysicalDevice = enum (usize) { null_handle = 0, _ };
  pub const Pipeline = enum (u64) { null_handle = 0, _ };
  pub const PipelineLayout = enum (u64) { null_handle = 0, _ };
  pub const Queue = enum (usize) { null_handle = 0, _ };
  pub const RenderPass = enum (u64) { null_handle = 0, _ };
  pub const Sampler = enum (u64) { null_handle = 0, _ };
  pub const Semaphore = enum (u64) { null_handle = 0, _ };

  pub const Extent2D = extern struct
  {
    width: u32,
    height: u32,
  };

  pub const EXT = extern struct
  {
    pub const DebugUtilsMessenger = enum (u64) { null_handle = 0, _ };
  };

  pub const Flags = extern struct
  {
    pub const ImageUsage = extern struct
    {
      pub const transfer_src_bit = c.VK_IMAGE_USAGE_TRANSFER_SRC_BIT;
    };

    pub const KHR = extern struct
    {
      pub const CompositeAlpha = extern struct
      {
        pub const opaque_bit_khr = c.VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR;
      };

      pub const SurfaceTransform = extern struct
      {
        pub const identity_bit_khr = c.VK_SURFACE_TRANSFORM_IDENTITY_BIT_KHR;
      };
    };
  };

  pub const Format = enum (i32)
  {
    undefined = c.VK_FORMAT_UNDEFINED,
    r4g4_unorm_pack8 = c.VK_FORMAT_R4G4_UNORM_PACK8,
    _,
  };

  pub const KHR = extern struct
  {
    pub const Surface = enum (u64) { null_handle = 0, _ };
    pub const Swapchain = enum (u64) { null_handle = 0, _ };

    pub const ColorSpace = enum (i32)
    {
      srgb_nonlinear_khr = c.VK_COLOR_SPACE_SRGB_NONLINEAR_KHR,
    };

    pub const PresentMode = enum (i32)
    {
      immediate_khr = c.VK_PRESENT_MODE_IMMEDIATE_KHR,
    };

    pub const SurfaceCapabilities = extern struct
    {
      min_image_count: u32,
      max_image_count: u32,
      current_extent: Extent2D,
      min_image_extent: Extent2D,
      max_image_extent: Extent2D,
      max_image_array_layers: u32,
      supported_transforms: Flags.KHR.SurfaceTransform,
      current_transform: Flags.KHR.SurfaceTransform,
      supported_composite_alpha: Flags.KHR.CompositeAlpha,
      supported_usage_flags: Flags.ImageUsage,
    };

    pub const SurfaceFormat = extern struct
    {
      format: Format,
      color_space: ColorSpace,
    };
  };

  pub const Offset2D = extern struct
  {
    x: i32,
    y: i32,
  };

  pub const Rect2D = extern struct
  {
    offset: Offset2D,
    extent: Extent2D,
  };

  pub const Viewport = extern struct
  {
    x: f32,
    y: f32,
    width: f32,
    height: f32,
    min_depth: f32,
    max_depth: f32,
  };
};
