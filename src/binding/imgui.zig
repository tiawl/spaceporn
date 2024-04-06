const std = @import ("std");
const c = @import ("c");

const binding = struct
{
  const glfw = @import ("glfw");
  const vk = @import ("vk");
};

const imgui = @This ();

pub const vk = struct
{
  pub const DrawData = struct
  {
    pub const Ex = struct
    {
      pub fn render (draw_data: *const c.ImGui_DrawData, command_buffer: binding.vk.Command.Buffer, pipeline: binding.vk.Pipeline) void
      {
        c.cImGui_ImplVulkan_RenderDrawDataEx (draw_data, @ptrFromInt (@intFromEnum (command_buffer)), @ptrFromInt (@intFromEnum (pipeline)));
      }
    };
  };

  pub const FontsTexture = struct
  {
    pub fn create () !void
    {
      if (!c.cImGui_ImplVulkan_CreateFontsTexture ()) return error.ImGuiVulkanCreateFontsTexture;
    }
  };

  pub const Frame = struct
  {
    pub fn new () void
    {
      c.cImGui_ImplVulkan_NewFrame ();
    }
  };

  pub const InitInfo = struct
  {
    Instance:              binding.vk.Instance,
    PhysicalDevice:        binding.vk.PhysicalDevice,
    Device:                binding.vk.Device,
    QueueFamily:           u32,
    Queue:                 binding.vk.Queue,
    PipelineCache:         binding.vk.Pipeline.Cache,
    DescriptorPool:        binding.vk.Descriptor.Pool,
    Subpass:               u32,
    MinImageCount:         u32,
    ImageCount:            u32,
    MSAASamples:           c_uint,
    UseDynamicRendering:   bool,
    ColorAttachmentFormat: i32,
    Allocator:             [*c] const binding.vk.AllocationCallbacks,
    CheckVkResultFn:       ?*const fn (c_int) callconv (binding.vk.call_conv) void,
  };

  fn loader (function_name: [*c] const u8, instance: ?*anyopaque) callconv (binding.vk.call_conv) ?*const fn () callconv (binding.vk.call_conv) void
  {
    return c.vkGetInstanceProcAddr (if (instance) |v| @as (c.VkInstance, @ptrCast (v)) else null, function_name);
  }

  pub fn load () !void
  {
    if (!c.cImGui_ImplVulkan_LoadFunctions (loader)) return error.ImGuiVulkanLoadFunctionsFailure;
  }

  pub fn init (init_info: *imgui.vk.InitInfo) !void
  {
    if (!c.cImGui_ImplVulkan_Init (@ptrCast (init_info))) return error.ImGuiVulkanInitFailure;
  }

  pub fn shutdown () void
  {
    c.cImGui_ImplVulkan_Shutdown ();
  }
};

pub const glfw = struct
{
  pub const Frame = struct
  {
    pub fn new () void
    {
      c.cImGui_ImplGlfw_NewFrame ();
    }
  };

  pub fn init () !void
  {
    const window = try binding.glfw.Context.get ();
    if (!c.cImGui_ImplGlfw_InitForVulkan (@ptrCast (window), true)) return error.ImGuiGlfwInitForVulkanFailure;
  }

  pub fn shutdown () void
  {
    c.cImGui_ImplGlfw_Shutdown ();
  }
};

pub const Cond = c.ImGuiCond;

pub const Context = struct
{
  pub fn create () !void
  {
    if (c.ImGui_CreateContext (null) == null) return error.ImGuiCreateContextFailure;
  }

  pub fn destroy () void
  {
    c.ImGui_DestroyContext (null);
  }
};

pub const Col = struct
{
  pub const WindowBg = c.ImGuiCol_WindowBg;
};

pub const DrawData = struct
{
  pub fn get () *const c.ImDrawData
  {
    return &(c.ImGui_GetDrawData ().*);
  }
};

pub const Ex = struct
{
  pub fn button (label: [] const u8, size: imgui.Vec2) bool
  {
    return c.ImGui_ButtonEx (label.ptr, size);
  }

  pub fn sameline (offset_from_start_x: f32, spacing: f32) void
  {
    c.ImGui_SameLineEx (offset_from_start_x, spacing);
  }
};

pub const Frame = struct
{
  pub fn new () void
  {
    c.ImGui_NewFrame ();
  }
};

pub const IO = struct
{
  pub fn get () *const c.ImGuiIO
  {
    return &(c.ImGui_GetIO ().*);
  }
};

pub const NextWindow = struct
{
  pub const Pos = struct
  {
    pub const Ex = struct
    {
      pub fn set (pos: imgui.Vec2, cond: imgui.Cond, pivot: imgui.Vec2) void
      {
        c.ImGui_SetNextWindowPosEx (pos, cond, pivot);
      }
    };
  };

  pub const Size = struct
  {
    pub fn set (size: imgui.Vec2, cond: imgui.Cond) void
    {
      c.ImGui_SetNextWindowSize (size, cond);
    }
  };
};

pub const Style = struct
{
  pub fn colorsDark () void
  {
    c.ImGui_StyleColorsDark (null);
  }

  const SetterTag = enum
  {
    colors,
    window_rounding,
  };

  const Setter = union (SetterTag)
  {
    colors: struct { index: usize, channel: [] const u8, value: usize, },
    window_rounding: usize,
  };

  fn zig_to_c_name (setter: Setter) [] const u8
  {
    return switch (setter)
    {
      .colors          => "Colors",
      .window_rounding => "WindowRounding",
    };
  }

  pub fn set (comptime setters: [] const Setter) void
  {
    const style = c.ImGui_GetStyle ();

    inline for (setters) |setter|
    {
      switch (setter)
      {
        .colors => |colors| @field (@field (style.*, "Colors") [colors.index], colors.channel) = colors.value,
        else => |active| @field (style.*, zig_to_c_name (setter)) = @field (setter, @tagName (active)),
      }
    }
  }
};

pub const Vec2 = c.ImVec2;

pub const Window = struct
{
  //pub const Flags = c.ImGuiWindowFlags_;
  pub const Flags = i32;

  pub const Bit = enum (imgui.Window.Flags)
  {
    NO_COLLAPSE = c.ImGuiWindowFlags_NoCollapse,
    NO_MOVE = c.ImGuiWindowFlags_NoMove,
    NO_RESIZE = c.ImGuiWindowFlags_NoResize,
    NO_TITLE_BAR = c.ImGuiWindowFlags_NoTitleBar,
  };
};

pub fn begin (name: [] const u8, p_open: ?*bool, flags: imgui.Window.Flags) !void
{
  if (!c.ImGui_Begin (name.ptr, p_open, flags)) return error.ImGuiBeginFailure;
}

pub fn end () void
{
  c.ImGui_End ();
}

pub fn render () void
{
  c.ImGui_Render ();
}

pub fn text (allocator: std.mem.Allocator, comptime fmt: [] const u8, args: anytype) !void
{
  const str = try std.fmt.allocPrint (allocator, fmt, args);
  c.ImGui_Text (str.ptr);
}
