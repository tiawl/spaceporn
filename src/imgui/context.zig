const std   = @import ("std");
const build = @import ("build_options");
const glfw  = @import ("glfw");

const utils    = @import ("../utils.zig");
const log_app  = utils.log_app;
const profile  = utils.profile;

const imgui = if (build.LOG_LEVEL > @intFromEnum (profile.DEFAULT))
                @cImport ({
                            @cDefine ("CIMGUI_DEFINE_ENUMS_AND_STRUCTS", {});
                            @cDefine ("CIMGUI_USE_VULKAN", {});
                            @cDefine ("CIMGUI_USE_GLFW", {});
                            @cInclude ("vulkan/vulkan.h");
                            @cInclude ("cimgui.h");
                            @cInclude ("cimgui_impl.h"); })
              else null;

pub const context_imgui = struct
{
  const Self = @This ();

  pub fn init (window: glfw.Window) Self
  {
    var self = Self {};

    if (build.LOG_LEVEL > @intFromEnum (profile.DEFAULT))
    {
      _ = imgui.igCreateContext (null);
      var io = imgui.igGetIO ();
      io.*.ConfigFlags |= imgui.ImGuiConfigFlags_NavEnableKeyboard; // Enable Keyboard Controls
      io.*.ConfigFlags |= imgui.ImGuiConfigFlags_DockingEnable;     // Enable Docking
      io.*.ConfigFlags |= imgui.ImGuiConfigFlags_ViewportsEnable;   // Enable Multi-Viewport / Platform Windows
      io.*.BackendRendererName = "imgui_impl_vulkan";
      io.*.BackendPlatformName = "imgui_impl_glfw";

      imgui.igStyleColorsDark (null);

      var style = imgui.igGetStyle ();
      style.*.WindowRounding = 0;
      style.*.Colors [imgui.ImGuiCol_WindowBg].w = 1;

      imgui.ImGui_ImplGlfw_InitForVulkan (window, true);
      const init_info = imgui.ImGui_ImplVulkan_InitInfo
                        {
                          .Instance        = g_Instance;
                          .PhysicalDevice  = g_PhysicalDevice;
                          .Device          = g_Device;
                          .QueueFamily     = g_QueueFamily;
                          .Queue           = g_Queue;
                          .PipelineCache   = g_PipelineCache;
                          .DescriptorPool  = g_DescriptorPool;
                          .Subpass         = 0;
                          .MinImageCount   = g_MinImageCount;
                          .ImageCount      = wd->ImageCount;
                          .MSAASamples     = VK_SAMPLE_COUNT_1_BIT;
                          .Allocator       = g_Allocator;
                          .CheckVkResultFn = check_vk_result;
                        };
      imgui.ImGui_ImplVulkan_Init(&init_info, wd->RenderPass);
    }

    return self;
  }
};
