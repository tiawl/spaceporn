const std = @import ("std");
const c   = @import ("c");

const vk  = @import ("vk");
const raw = @import ("raw");

pub const Shader = extern struct
{
  pub const Module = enum (u64)
  {
    NULL_HANDLE = vk.NULL_HANDLE, _,

    pub const Create = extern struct
    {
      pub const Flags = u32;

      pub const Info = extern struct
      {
        s_type: vk.StructureType = .SHADER_MODULE_CREATE_INFO,
        p_next: ?*const anyopaque = null,
        flags: vk.Shader.Module.Create.Flags = 0,
        code_size: usize,
        p_code: [*] const u32,
      };
    };

    pub fn create (device: vk.Device, p_create_info: *const vk.Shader.Module.Create.Info, p_allocator: ?*const vk.AllocationCallbacks) !@This ()
    {
      var shader_module: vk.Shader.Module = undefined;
      const result = raw.prototypes.device.vkCreateShaderModule (device, p_create_info, p_allocator, &shader_module);
      if (result > 0)
      {
        std.debug.print ("{s} failed with {} status code\n", .{ @typeName (@This ()) ++ "." ++ @src ().fn_name, result, });
        return error.UnexpectedResult;
      }
      return shader_module;
    }

    pub fn destroy (shader_module: @This (), device: vk.Device, p_allocator: ?*const vk.AllocationCallbacks) void
    {
      raw.prototypes.device.vkDestroyShaderModule (device, shader_module, p_allocator);
    }
  };

  pub const Stage = extern struct
  {
    pub const Flags = u32;

    pub const Bit = enum (vk.Shader.Stage.Flags)
    {
      FRAGMENT = c.VK_SHADER_STAGE_FRAGMENT_BIT,
      VERTEX = c.VK_SHADER_STAGE_VERTEX_BIT,
    };
  };
};
