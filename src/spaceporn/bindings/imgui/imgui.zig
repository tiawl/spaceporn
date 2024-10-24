const std = @import ("std");
const c = @import ("c");

const imgui = @This ();

pub const glfw = @import ("glfw");
pub const vk = @import ("vk");

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
  pub fn get () *c.ImDrawData
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

pub const Style = @import ("style").Style;

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
