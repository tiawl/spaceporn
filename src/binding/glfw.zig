const c = @import ("c");

pub const glfw = struct
{
  pub const Window = struct
  {
    pub const Size = struct
    {
      width: u32,
      height: u32,
    };
  };
};

pub usingnamespace glfw;
