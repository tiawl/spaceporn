const std = @import ("std");
const c   = @import ("c");

const vk  = @import ("vk");
const raw = @import ("raw");

pub const Framebuffer = enum (u64)
{
  NULL_HANDLE = vk.NULL_HANDLE, _,

  pub const Create = extern struct
  {
    pub const Flags = u32;

    pub const Info = extern struct
    {
      s_type: vk.StructureType = .FRAMEBUFFER_CREATE_INFO,
      p_next: ?*const anyopaque = null,
      flags: vk.Framebuffer.Create.Flags = 0,
      render_pass: vk.RenderPass,
      attachment_count: u32 = 0,
      p_attachments: ?[*] const vk.Image.View = null,
      width: u32,
      height: u32,
      layers: u32,
    };
  };

  pub fn create (device: vk.Device, p_create_info: *const vk.Framebuffer.Create.Info, p_allocator: ?*const vk.AllocationCallbacks) !@This ()
  {
    var framebuffer: vk.Framebuffer = undefined;
    const result = raw.prototypes.device.vkCreateFramebuffer (device, p_create_info, p_allocator, &framebuffer);
    if (result > 0)
    {
      std.debug.print ("{s} failed with {} status code\n", .{ @typeName (@This ()) ++ "." ++ @src ().fn_name, result, });
      return error.UnexpectedResult;
    }
    return framebuffer;
  }

  pub fn destroy (framebuffer: @This (), device: vk.Device, p_allocator: ?*const vk.AllocationCallbacks) void
  {
    raw.prototypes.device.vkDestroyFramebuffer (device, framebuffer, p_allocator);
  }
};
