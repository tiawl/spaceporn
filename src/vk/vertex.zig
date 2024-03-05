const vk = @import ("vk");

pub const vertex_vk = struct
{
  pos: [2] f32,

  pub const binding_description = [_] vk.VertexInputBindingDescription
                                  {
                                    vk.VertexInputBindingDescription
                                    {
                                      .binding    = 0,
                                      .stride     = @sizeOf (@This ()),
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
                                        .offset   = @offsetOf (@This (), "pos"),
                                      },
                                    };
};
