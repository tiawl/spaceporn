const std = @import ("std");
const c   = @import ("c");

const vk  = @import ("vk");
const raw = @import ("raw");

pub const RenderPass = enum (u64)
{
  NULL_HANDLE = vk.NULL_HANDLE, _,

  pub const Create = extern struct
  {
    pub const Flags = u32;

    pub const Info = extern struct
    {
      s_type: vk.StructureType = .RENDER_PASS_CREATE_INFO,
      p_next: ?*const anyopaque = null,
      flags: vk.RenderPass.Create.Flags = 0,
      attachment_count: u32 = 0,
      p_attachments: ?[*] const vk.Attachment.Description = null,
      subpass_count: u32,
      p_subpasses: [*] const vk.Subpass.Description,
      dependency_count: u32 = 0,
      p_dependencies: ?[*] const vk.Subpass.Dependency = null,
    };
  };

  pub fn create (device: vk.Device,
    p_create_info: *const vk.RenderPass.Create.Info) !@This ()
  {
    var render_pass: @This () = undefined;
    const p_allocator: ?*const vk.AllocationCallbacks = null;
    const result = raw.prototypes.device.vkCreateRenderPass (device,
      p_create_info, p_allocator, &render_pass);
    if (result > 0)
    {
      std.debug.print ("{s} failed with {} status code\n",
        .{ @typeName (@This ()) ++ "." ++ @src ().fn_name, result, });
      return error.UnexpectedResult;
    }
    return render_pass;
  }

  pub fn destroy (render_pass: @This (), device: vk.Device) void
  {
    const p_allocator: ?*const vk.AllocationCallbacks = null;
    raw.prototypes.device.vkDestroyRenderPass (device, render_pass,
      p_allocator);
  }
};
