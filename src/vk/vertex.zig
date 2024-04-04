const vk = @import ("vk");

pub const vertex_vk = struct
{
  pos: [2] f32,

  pub const binding_description = [_] vk.VertexInput.BindingDescription
                                  {
                                    .{
                                       .binding    = 0,
                                       .stride     = @sizeOf (@This ()),
                                       .input_rate = .VERTEX,
                                     },
                                  };

  pub const attribute_description = [_] vk.VertexInput.AttributeDescription
                                    {
                                      .{
                                         .binding  = 0,
                                         .location = 0,
                                         .format   = .R32G32_SFLOAT,
                                         .offset   = @offsetOf (@This (), "pos"),
                                       },
                                    };
};
