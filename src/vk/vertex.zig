const vk = @import ("vulkan");

pub const vertex_vk = struct
{
  pos:   [2] f32,
  color: [3] f32,

  const Self = @This ();

  pub const binding_description = [_] vk.VertexInputBindingDescription
                                  {
                                    vk.VertexInputBindingDescription
                                    {
                                      .binding    = 0,
                                      .stride     = @sizeOf (Self),
                                      .input_rate = vk.VertexInputRate.vertex,
                                    },
                                  };

  pub const attribute_description = [_] vk.VertexInputAttributeDescription
                                    {
                                      vk.VertexInputAttributeDescription
                                      {
                                        .binding  = 0,
                                        .location = 0,
                                        .format   = vk.Format.r32g32_sfloat,
                                        .offset   = @offsetOf (Self, "pos"),
                                      },
                                      vk.VertexInputAttributeDescription
                                      {
                                        .binding  = 0,
                                        .location = 1,
                                        .format   = vk.Format.r32g32b32_sfloat,
                                        .offset   = @offsetOf (Self, "color"),
                                      },
                                    };
};
