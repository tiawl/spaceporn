const std = @import ("std");
const c   = @import ("c");

const vk  = @import ("vk");
const raw = @import ("raw");

pub const Memory = extern struct
{
  pub const Allocate = extern struct
  {
    pub const Info = extern struct
    {
      s_type: vk.StructureType = .MEMORY_ALLOCATE_INFO,
      p_next: ?*const anyopaque = null,
      allocation_size: vk.Device.Size,
      memory_type_index: u32,
    };
  };

  pub const Heap = extern struct
  {
    pub const Flags = u32;

    size: vk.Device.Size,
    flags: vk.Memory.Heap.Flags = 0,
  };

  pub const Map = extern struct
  {
    pub const Flags = u32;
  };

  pub const Property = extern struct
  {
    pub const Flags = u32;

    pub const Bit = enum (vk.Memory.Property.Flags)
    {
      DEVICE_LOCAL = c.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT,
      HOST_VISIBLE = c.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT,
      HOST_COHERENT = c.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT,
    };
  };

  pub const Requirements = extern struct
  {
    size: vk.Device.Size,
    alignment: vk.Device.Size,
    memory_type_bits: u32,
  };

  pub const Type = extern struct
  {
    property_flags: vk.Memory.Property.Flags = 0,
    heap_index: u32,
  };

  pub fn allocate (device: vk.Device, p_allocate_info: *const vk.Memory.Allocate.Info, p_allocator: ?*const vk.AllocationCallbacks) !vk.Device.Memory
  {
    var memory: vk.Device.Memory = undefined;
    const result = raw.prototypes.device.vkAllocateMemory (device, p_allocate_info, p_allocator, &memory);
    if (result > 0)
    {
      std.debug.print ("{s} failed with {} status code\n", .{ @typeName (@This ()) ++ "." ++ @src ().fn_name, result, });
      return error.UnexpectedResult;
    }
    return memory;
  }
};
