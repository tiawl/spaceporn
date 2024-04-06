const std = @import ("std");
const c = @import ("c");

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
