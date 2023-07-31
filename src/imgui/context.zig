const std      = @import ("std");
const build    = @import ("build_options");
const glfw     = @import ("glfw");
const vk       = @import ("vulkan");
const datetime = @import ("datetime").datetime;

const utils    = @import ("../utils.zig");
const log_app  = utils.log_app;
const profile  = utils.profile;
const severity = utils.severity;

const imgui = @cImport ({
                          @cInclude ("cimgui.h");
                          @cInclude ("cimgui_impl_glfw.h");
                          @cInclude ("cimgui_impl_vulkan.h");
                        });

const dispatch         = @import ("../vk/dispatch.zig");
const DeviceDispatch   = dispatch.DeviceDispatch;
const InstanceDispatch = dispatch.InstanceDispatch;

const ImGui_ImplVulkan_InitInfo = extern struct
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

pub fn find_memory_type (instance_dispatch: InstanceDispatch, physical_device: vk.PhysicalDevice, type_filter: u32, properties: vk.MemoryPropertyFlags) !u32
{
  const memory_properties = instance_dispatch.getPhysicalDeviceMemoryProperties (physical_device);

  for (memory_properties.memory_types [0..memory_properties.memory_type_count], 0..) |memory_type, index|
  {
    if (type_filter & (@as (u32, 1) << @truncate (index)) != 0 and memory_type.property_flags.contains (properties))
    {
      return @truncate (index);
    }
  }

  return error.NoSuitableMemoryType;
}

pub const context_imgui = struct
{
  const Renderer = struct
                   {
                     device_dispatch: DeviceDispatch,
                     instance:        vk.Instance,
                     physical_device: vk.PhysicalDevice,
                     logical_device:  vk.Device,
                     graphics_family: u32,
                     graphics_queue:  vk.Queue,
                     descriptor_pool: vk.DescriptorPool,
                     render_pass:     vk.RenderPass,
                     command_pool:    vk.CommandPool,
                     command_buffer:  vk.CommandBuffer,
                   };

  const ScreenshotRenderer = struct
                             {
                               device_dispatch:    DeviceDispatch,
                               instance_dispatch:  InstanceDispatch,
                               logical_device:     vk.Device,
                               image:              vk.Image,
                               command_pool:       vk.CommandPool,
                               graphics_queue:     vk.Queue,
                               blitting_supported: bool,
                             };

  const ImguiContextError = error
                            {
                              InitFailure,
                              InitGlfwFailure,
                              InitVulkanFailure,
                              CreateFontsTextureFailure,
                              BeginFailure,
                              NoAvailableFilename,
                            };

  glfw_win_size: glfw.Window.Size = undefined,
  init_window: bool = false,

  const Self = @This ();

  pub fn init () Self
  {
    return Self {};
  }

  pub fn init_glfw (self: *Self, window: glfw.Window) !void
  {
    self.glfw_win_size = window.getFramebufferSize ();

    if (imgui.ImGui_CreateContext (null) == null)
    {
      return ImguiContextError.InitFailure;
    }

    imgui.ImGui_StyleColorsDark (null);

    var style = imgui.ImGui_GetStyle ();
    style.*.WindowRounding = 0;
    style.*.Colors [imgui.ImGuiCol_WindowBg].w = 1;

    if (!imgui.cImGui_ImplGlfw_InitForVulkan (@ptrCast (window.handle), true))
    {
      return ImguiContextError.InitGlfwFailure;
    }

    try log_app ("init Imgui GLFW OK", severity.DEBUG, .{});
  }

  fn check_vk_result (err: c_int) callconv(.C) void
  {
    if (err == 0) return;
    std.debug.print ("[vulkan ERROR from Imgui] VkResult = {d}\n", .{ err, });
    if (err < 0) std.process.exit (1);
  }

  fn upload_fonts (self: Self, renderer: Renderer) !void
  {
    _ = self;

    try renderer.device_dispatch.resetCommandPool (renderer.logical_device, renderer.command_pool, vk.CommandPoolResetFlags {});
    const begin_info = vk.CommandBufferBeginInfo
                       {
                         .flags = vk.CommandBufferUsageFlags { .one_time_submit_bit = true, },
                       };

    const command_buffers = [_] vk.CommandBuffer
                            {
                              renderer.command_buffer,
                            };

    try renderer.device_dispatch.beginCommandBuffer (command_buffers [0], &begin_info);

    if (!imgui.cImGui_ImplVulkan_CreateFontsTexture (@ptrFromInt (@intFromEnum (renderer.command_buffer))))
    {
      return ImguiContextError.CreateFontsTextureFailure;
    }

    const submit_info = [_] vk.SubmitInfo
                        {
                          vk.SubmitInfo
                          {
                            .command_buffer_count = command_buffers.len,
                            .p_command_buffers    = &command_buffers,
                          },
                        };

    try renderer.device_dispatch.endCommandBuffer (command_buffers [0]);
    try renderer.device_dispatch.queueSubmit (renderer.graphics_queue, 1, &submit_info, vk.Fence.null_handle);

    try renderer.device_dispatch.deviceWaitIdle (renderer.logical_device);
    imgui.cImGui_ImplVulkan_DestroyFontUploadObjects ();

    try log_app ("upload Imgui fonts OK", severity.DEBUG, .{});
  }

  pub fn init_vk (self: Self, renderer: Renderer) !void
  {
    const sample = vk.SampleCountFlags { .@"1_bit" = true, };
    const format = vk.Format.undefined;
    var init_info = ImGui_ImplVulkan_InitInfo
                    {
                      .Instance              = renderer.instance,
                      .PhysicalDevice        = renderer.physical_device,
                      .Device                = renderer.logical_device,
                      .QueueFamily           = renderer.graphics_family,
                      .Queue                 = renderer.graphics_queue,
                      .PipelineCache         = vk.PipelineCache.null_handle,
                      .DescriptorPool        = renderer.descriptor_pool,
                      .Subpass               = 0,
                      .MinImageCount         = 2,
                      .ImageCount            = 2,
                      .MSAASamples           = sample.toInt (),
                      .UseDynamicRendering   = false,
                      .ColorAttachmentFormat = @intFromEnum (format),
                      .Allocator             = null,
                      .CheckVkResultFn       = check_vk_result,
                    };

    if (!imgui.cImGui_ImplVulkan_Init (@ptrCast (&init_info), @ptrFromInt (@intFromEnum (renderer.render_pass))))
    {
      return ImguiContextError.InitVulkanFailure;
    }

    try self.upload_fonts (renderer);

    try log_app ("init Imgui Vulkan OK", severity.DEBUG, .{});
  }

  fn prepare_pane (self: *Self, framebuffer: struct { width: u32, height: u32, }) !void
  {
    if (framebuffer.height != self.glfw_win_size.height)
    {
      self.glfw_win_size.height = framebuffer.height;
      const window_size = imgui.ImVec2 { .x = 0.0, .y = @floatFromInt (self.glfw_win_size.height), };
      imgui.ImGui_SetNextWindowSize (window_size, 0);
    }

    if (!self.init_window)
    {
      const window_pos = imgui.ImVec2 { .x = 0.0, .y = 0.0, };
      const window_pivot = imgui.ImVec2 { .x = 0.0, .y = 0.0, };
      imgui.ImGui_SetNextWindowPosEx (window_pos, 0, window_pivot);

      const window_size = imgui.ImVec2 { .x = 0.0, .y = @floatFromInt (self.glfw_win_size.height), };
      imgui.ImGui_SetNextWindowSize (window_size, 0);

      self.init_window = true;
    }
  }

  fn prepare_fps (self: Self, last_displayed_fps: *?std.time.Instant, fps: *f32) !void
  {
    _ = self;

    if (last_displayed_fps.* == null or (try std.time.Instant.now ()).since (last_displayed_fps.*.?) > std.time.ns_per_s)
    {
      fps.* = imgui.ImGui_GetIO ().*.Framerate;
      last_displayed_fps.* = try std.time.Instant.now ();
    }

    imgui.ImGui_Text ("Average %.3f ms/frame (%.1f FPS)", 1000.0 / fps.*, fps.*);
  }

  fn prepare_seed (self: Self, tweak_me: anytype) void
  {
    _ = self;

    const button_size = imgui.ImVec2 { .x = 0, .y = 0, };

    if (imgui.ImGui_ButtonEx ("New seed", button_size)) tweak_me.seed.* = @intCast (@mod (std.time.milliTimestamp (), @as (i64, @intCast (std.math.maxInt (u32)))));
    if (build.LOG_LEVEL > @intFromEnum (profile.DEFAULT))
    {
      imgui.ImGui_SameLineEx (0.0, -1.0);
      imgui.ImGui_Text ("%u", tweak_me.seed.*);
    }
  }

  fn find_available_filename (self: Self, allocator: std.mem.Allocator) ![] const u8
  {
    _ = self;

    var screenshots_dir = std.fs.cwd ().openDir ("screenshots", .{}) catch |err| blk:
                          {
                            if (err == std.fs.Dir.OpenError.FileNotFound)
                            {
                              try std.fs.cwd ().makeDir ("screenshots");
                              break :blk try std.fs.cwd ().openDir ("screenshots", .{});
                            } else {
                              return err;
                            }
                          };
    defer screenshots_dir.close ();

    const now = datetime.Datetime.now ();
    var iterator = std.mem.tokenizeAny (u8, try now.formatISO8601 (allocator, true), ":.+");
    var id: u32 = 0;
    var filename: [] const u8 = undefined;
    var file: std.fs.File = undefined;
    var available = false;
    var date: [] const u8 = "";

    while (iterator.next ()) |token|
    {
      date = try std.fmt.allocPrint (allocator, "{s}{s}-", .{ date, token, });
    }

    while (id < std.math.maxInt (u32))
    {
      filename = try std.fmt.allocPrint (allocator, "{s}{d}", .{ date, id, });
      file = screenshots_dir.openFile (filename, .{}) catch |err|
             {
               if (err == std.fs.File.OpenError.FileNotFound)
               {
                 available = true;
                 break;
               } else {
                 return err;
               }
             };
      file.close ();
      id += 1;
    }

    if (!available)
    {
      return ImguiContextError.NoAvailableFilename;
    }

    return filename;
  }

  fn prepare_screenshot (self: Self, allocator: std.mem.Allocator, framebuffer: struct { width: u32, height: u32, }, renderer: ScreenshotRenderer) !void
  {
    _ = renderer;
    _ = framebuffer;
    const button_size = imgui.ImVec2 { .x = 0, .y = 0, };

    // TODO: display window size
    if (imgui.ImGui_ButtonEx ("Take a screenshot", button_size))
    {
      const filename = try self.find_available_filename (allocator);
      _ = filename;

      const image_create_info = vk.ImageCreateInfo
                                {
                                  .image_type     = vk.ImageType.@"2d",
                                  .format         = vk.Format.r8g8b8a8_unorm,
                                  .extent         = vk.Extent3D
                                                    {
                                                      .width  = framebuffer.width,
                                                      .height = framebuffer.height,
                                                      .depth  = 1,
                                                    },
                                  .mip_levels     = 1,
                                  .array_layers   = 1,
                                  .samples        = vk.SampleCountFlags { .@"1_bit" = true, },
                                  .tiling         = vk.ImageTiling.linear,
                                  .usage          = vk.ImageUsageFlags { .transfer_dst_bit = true, },
                                  .initial_layout = vk.ImageLayout.undefined,
                                };

      const dst_image = try renderer.device_dispatch.createImage (renderer.logical_device, &image_create_info, null);
      defer self.device_dispatch.destroyImage (self.logical_device, dst_image, null);

      const memory_requirements = renderer.device_dispatch.getImageMemoryRequirements (renderer.logical_device, dst_image);

      const alloc_info = vk.MemoryAllocateInfo
                         {
                           .allocation_size   = memory_requirements.size,
                           .memory_type_index = try find_memory_type (renderer.instance_dispatch, renderer.physical_device, memory_requirements.memory_type_bits,
                                                                      vk.MemoryPropertyFlags
                                                                      {
                                                                        .host_visible_bit  = true,
                                                                        .host_coherent_bit = true,
                                                                      }),
                         };

      const dst_image_memory = try renderer.device_dispatch.allocateMemory (renderer.logical_device, &alloc_info, null);
      errdefer renderer.device_dispatch.freeMemory (renderer.logical_device, renderer.dst_image_memory, null);

      try renderer.device_dispatch.bindImageMemory (renderer.logical_device, renderer.dst_image, renderer.dst_image_memory, 0);

      var command_buffers = [_] vk.CommandBuffer { undefined, };

      const buffers_alloc_info = vk.CommandBufferAllocateInfo
                                 {
                                   .command_pool         = renderer.command_pool,
                                   .level                = vk.CommandBufferLevel.primary,
                                   .command_buffer_count = command_buffers.len,
                                 };

      try renderer.device_dispatch.allocateCommandBuffers (renderer.logical_device, &buffers_alloc_info, &command_buffers);
      errdefer renderer.device_dispatch.freeCommandBuffers (renderer.logical_device, renderer.command_pool, 1, &command_buffers);

      const begin_info = vk.CommandBufferBeginInfo {};

      try renderer.device_dispatch.beginCommandBuffer (command_buffers [0], &begin_info);

      const dst_image_to_transfer_dst_layout = vk.ImageMemoryBarrier
                                               {
                                                 .src_access_mask:   vk.AccessFlags {},
                                                 .dst_access_mask:   vk.AccessFlags { .transfer_write_bit = true, },
                                                 .old_layout:        vk.ImageLayout.undefined,
                                                 .new_layout:        vk.ImageLayout.transfer_dst_optimal,
                                                 .image:             dst_image,
                                                 .subresource_range: vk.ImageSubresourceRange
                                                                     {
                                                                       .aspect_mask      = vk.ImageAspectFlags { .color_bit = true },
                                                                       .base_mip_level   = 0,
                                                                       .level_count      = 1,
                                                                       .base_array_layer = 0,
                                                                       .layer_count      = 1,
                                                                     },
                                               };
      vk.cmdPipelineBarrier (command_buffers [0],
                             vk.PipelineStageFlags { .transfer_bit = true, },
                             vk.PipelineStageFlags { .transfer_bit = true, },
                             vk.DependencyFlags {},
                             0, null, 0, null, 1,
                             &dst_image_to_transfer_dst_layout);

      const swapchain_image_from_present_to_transfer_src_layout = vk.ImageMemoryBarrier
                                                                  {
                                                                    .src_access_mask:   vk.AccessFlags { .memory_read_bit = true, },
                                                                    .dst_access_mask:   vk.AccessFlags { .transfer_read_bit = true, },
                                                                    .old_layout:        vk.ImageLayout.present_src_khr,
                                                                    .new_layout:        vk.ImageLayout.transfer_src_optimal,
                                                                    .image:             renderer.image,
                                                                    .subresource_range: vk.ImageSubresourceRange
                                                                     {
                                                                       .aspect_mask      = vk.ImageAspectFlags { .color_bit = true },
                                                                       .base_mip_level   = 0,
                                                                       .level_count      = 1,
                                                                       .base_array_layer = 0,
                                                                       .layer_count      = 1,
                                                                     },
                                                                  };
      vk.cmdPipelineBarrier (command_buffers [0],
                             vk.PipelineStageFlags { .transfer_bit = true, },
                             vk.PipelineStageFlags { .transfer_bit = true, },
                             vk.DependencyFlags {},
                             0, null, 0, null, 1,
                             &swapchain_image_from_present_to_transfer_src_layout);

      if (renderer.blitting_supported)
      {
        const blit_size = [2] vk.Offset3D
                          {
                            vk.Offset3D
                            {
                              .x = framebuffer.width,
                              .y = framebuffer.height,
                              .z = 1,
                            },
                            undefined,
                          };

        const image_blit_region = vk.ImageBlit
                                  {
                                    .src_subresource: vk.ImageSubresourceLayers
                                                      {
                                                        .aspect_mask: vk.ImageAspectFlags { .color_bit = true, },
                                                        .layer_count: 1,
                                                      },
                                    .src_offsets:     blit_size,
                                    .dst_subresource: vk.ImageSubresourceLayers
                                                      {
                                                        .aspect_mask: vk.ImageAspectFlags { .color_bit = true, },
                                                        .layer_count: 1,
                                                      },
                                    .dst_offsets:     blit_size,
                                  };

        vk.cmdBlitImage (command_buffer [0],
                         renderer.image, vk.ImageLayout.transfer_src_optimal,
                         dst_image, vk.ImageLayout.transfer_dst_optimal,
                         1, &image_blit_region, vk.Filter.nearest);
      } else {
        const image_copy_region = vk.ImageCopy
                                  {
                                    .src_subresource: vk.ImageSubresourceLayers
                                                      {
                                                        .aspect_mask: vk.ImageAspectFlags { .color_bit = true, },
                                                        .layer_count: 1,
                                                      },
                                    .dst_subresource: vk.ImageSubresourceLayers
                                                      {
                                                        .aspect_mask: vk.ImageAspectFlags { .color_bit = true, },
                                                        .layer_count: 1,
                                                      },
                                    .extent: vk.Extent3D
                                             {
                                               .width  = framebuffer.width,
                                               .height = framebuffer.height,
                                               .depth  = 1,
                                             },
                                  };

        vk.cmdCopyImage (command_buffer [0],
                         renderer.image, vk.ImageLayout.transfer_src_optimal,
                         dst_image, vk.ImageLayout.transfer_dst_optimal,
                         1, &image_copy_region);
      }

      const dst_image_to_general_layout = vk.ImageMemoryBarrier
                                          {
                                            .src_access_mask:   vk.AccessFlags { .transfer_write_bit = true, },
                                            .dst_access_mask:   vk.AccessFlags { .memory_read_bit = true, },
                                            .old_layout:        vk.ImageLayout.transfer_dst_optimal,
                                            .new_layout:        vk.ImageLayout.general,
                                            .image:             dst_image,
                                            .subresource_range: vk.ImageSubresourceRange
                                                                {
                                                                  .aspect_mask      = vk.ImageAspectFlags { .color_bit = true },
                                                                  .base_mip_level   = 0,
                                                                  .level_count      = 1,
                                                                  .base_array_layer = 0,
                                                                  .layer_count      = 1,
                                                                },
                                          };
      vk.cmdPipelineBarrier (command_buffers [0],
                             vk.PipelineStageFlags { .transfer_bit = true, },
                             vk.PipelineStageFlags { .transfer_bit = true, },
                             vk.DependencyFlags {},
                             0, null, 0, null, 1,
                             &dst_image_to_general_layout);

      const swapchain_image_after_blit = vk.ImageMemoryBarrier
                                         {
                                           .src_access_mask:   vk.AccessFlags { .transfer_read_bit = true, },
                                           .dst_access_mask:   vk.AccessFlags { .memory_read_bit = true, },
                                           .old_layout:        vk.ImageLayout.transfer_src_optimal,
                                           .new_layout:        vk.ImageLayout.present_src_khr,
                                           .image:             renderer.image,
                                           .subresource_range: vk.ImageSubresourceRange
                                                               {
                                                                 .aspect_mask      = vk.ImageAspectFlags { .color_bit = true },
                                                                 .base_mip_level   = 0,
                                                                 .level_count      = 1,
                                                                 .base_array_layer = 0,
                                                                 .layer_count      = 1,
                                                               },
                                         };
      vk.cmdPipelineBarrier (command_buffers [0],
                             vk.PipelineStageFlags { .transfer_bit = true, },
                             vk.PipelineStageFlags { .transfer_bit = true, },
                             vk.DependencyFlags {},
                             0, null, 0, null, 1,
                             &swapchain_image_after_blit);

      try renderer.device_dispatch.endCommandBuffer (command_buffers [0]);

      const submit_info = [_] vk.SubmitInfo
                          {
                            vk.SubmitInfo
                            {
                              .command_buffer_count = command_buffers.len,
                              .p_command_buffers    = &command_buffers,
                            },
                          };

      const fence = try renderer.device_dispatch.createFence(renderer.logical_device, &vk.FenceCreateInfo {}, null);
      defer renderer.device_dispatch.destroyFence (renderer.logical_device, fence, null);

      try renderer.device_dispatch.queueSubmit (renderer.graphics_queue, 1, &submit_info, fence);

      _ = try renderer.device_dispatch.waitForFences (renderer.logical_device, 1, &[_] vk.Fence { fence, }, vk.TRUE, std.math.maxInt (u64));

      const subresource = vk.ImageSubresource
                          {
                            .aspect_mask = vk.ImageAspectFlags { .color_bit = true },
                            .mip_level   = 0,
                            .array_layer = 0,
                          };

      const subresource_layout = renderer.device_dispatch.getImageSubresourceLayout (renderer.logical_device, dst_image, &subresource);

      var data = try self.device_dispatch.mapMemory (self.logical_device, dst_image_memory, 0, vk.WHOLE_SIZE, vk.MemoryMapFlags {});
      defer self.device_dispatch.unmapMemory (self.logical_device, dst_image_memory);

      data += subresource_layout.offset;

      // TODO: ppm
    }
  }

  pub fn prepare (self: *Self, allocator: std.mem.Allocator, last_displayed_fps: *?std.time.Instant, fps: *f32,
                  framebuffer: struct { width: u32, height: u32, }, renderer: ScreenshotRenderer, tweak_me: anytype) !void
  {
    imgui.cImGui_ImplVulkan_NewFrame ();
    imgui.cImGui_ImplGlfw_NewFrame ();
    imgui.ImGui_NewFrame ();

    try self.prepare_pane (.{ .width = framebuffer.width, .height = framebuffer.height, });

    const window_flags = imgui.ImGuiWindowFlags_NoTitleBar | imgui.ImGuiWindowFlags_NoCollapse | imgui.ImGuiWindowFlags_NoResize | imgui.ImGuiWindowFlags_NoMove;

    if (!imgui.ImGui_Begin ("Tweaker", null, window_flags))
    {
      return ImguiContextError.BeginFailure;
    }

    try self.prepare_fps (last_displayed_fps, fps);
    self.prepare_seed (tweak_me);
    try self.prepare_screenshot (allocator, .{ .width = framebuffer.width, .height = framebuffer.height, }, renderer);

    // Return a boolean depending on the fact that the value of the variable changed or not
    //_ = imgui.ImGui_SliderFloat ("Float", tweak_me.f, 0.0, 1.0, "%.3f", 0);

    imgui.ImGui_End ();
    imgui.ImGui_Render ();

    try log_app ("start render Imgui OK", severity.DEBUG, .{});
  }

  pub fn render (self: Self, command_buffer: vk.CommandBuffer) !void
  {
    _ = self;

    var pipeline = vk.Pipeline.null_handle;
    imgui.cImGui_ImplVulkan_RenderDrawDataEx (imgui.ImGui_GetDrawData (), @ptrFromInt (@intFromEnum (command_buffer)), @ptrFromInt (@intFromEnum (pipeline)));

    try log_app ("end render Imgui OK", severity.DEBUG, .{});
  }

  pub fn cleanup (self: Self) void
  {
    _ = self;

    imgui.cImGui_ImplVulkan_Shutdown ();
    imgui.cImGui_ImplGlfw_Shutdown ();
    imgui.ImGui_DestroyContext (null);

    try log_app ("cleanup Imgui OK", severity.DEBUG, .{});
  }
};
