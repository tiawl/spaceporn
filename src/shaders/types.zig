pub const Vec2 = @Vector(2, f32);
pub const Vec3 = @Vector(3, f32);
pub const Vec4 = @Vector(4, f32);
pub const Uvec4 = @Vector(4, u32);

// WARNING: manage alignment when adding new field
pub const OnscreenUBO = extern struct {
    time: f32,
    resolution_x: f32,
    resolution_y: f32,
    max_resolution_x: f32,
    max_resolution_y: f32,
};

// WARNING: manage alignment when adding new field
pub const OffscreenUBO = extern struct {
    seed: u32,
    resolution_x: f32,
    resolution_y: f32,
    layer: u32,
};
