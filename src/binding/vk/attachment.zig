const std = @import ("std");
const c   = @import ("c");

const vk  = @import ("vk");
const raw = @import ("raw");

pub const Attachment = extern struct
{
  pub const Description = extern struct
  {
    flags: vk.Attachment.Description.Flags = 0,
    format: vk.Format,
    samples: vk.Sample.Count.Flags,
    load_op: vk.Attachment.LoadOp,
    store_op: vk.Attachment.StoreOp,
    stencil_load_op: vk.Attachment.LoadOp,
    stencil_store_op: vk.Attachment.StoreOp,
    initial_layout: vk.Image.Layout,
    final_layout: vk.Image.Layout,

    pub const Flags = u32;
  };

  pub const LoadOp = enum (i32)
  {
    CLEAR = c.VK_ATTACHMENT_LOAD_OP_CLEAR,
    DONT_CARE = c.VK_ATTACHMENT_LOAD_OP_DONT_CARE,
  };

  pub const Reference = extern struct
  {
    attachment: u32,
    layout: vk.Image.Layout,
  };

  pub const StoreOp = enum (i32)
  {
    STORE = c.VK_ATTACHMENT_STORE_OP_STORE,
    DONT_CARE = c.VK_ATTACHMENT_STORE_OP_DONT_CARE,
  };
};
