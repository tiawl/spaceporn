const std = @import ("std");

const ShaderCompileOptions = @import ("shaders/options.zig").Options;

pub const zon = .{ .name = "spaceporn", .version = "0.1.0", .min_zig_version = "0.11.0", };

pub const Options = struct
{
  dev:     bool = false,
  turbo:   bool = false,
  logdir:  [] const u8 = "",
  vkminor: [] const u8 = "2",

  pub const default: @This () = .{};
};

pub const Profile = struct
{
  target:          std.Build.ResolvedTarget,
  optimize:        std.builtin.OptimizeMode,
  variables:       *std.Build.Step.Options,
  options:         Options,
  compile_options: ShaderCompileOptions,
};

pub const Package = struct
{
  name: [] const u8,
  module: *std.Build.Module,
  subs: std.StringHashMap (*@This ()),

  pub fn init (builder: *std.Build, profile: *const Profile,
    name: [] const u8, path: [] const u8) !*@This ()
  {
    const self = try builder.allocator.create (@This ());
    self.name = name;
    self.module = builder.createModule (.{
      .root_source_file = .{ .path = path, },
      .target = profile.target,
      .optimize = profile.optimize,
    });
    self.subs = std.StringHashMap (*@This ()).init (builder.allocator);
    return self;
  }

  pub fn get (self: @This (), key: [] const u8) *@This ()
  {
    return self.subs.get (key) orelse
      std.debug.panic ("\"{s}\" module does not exist into \"{s}\" package",
        .{ key, self.name, });
  }

  pub fn put (self: *@This (), pkg: *@This (),
    optional: struct { pkg_name: ?[] const u8 = null, }) !void
  {
    const name = if (optional.pkg_name) |n| n else pkg.name;
    self.module.addImport (name, pkg.module);
    try self.subs.put (name, pkg);
  }

  pub fn link (self: @This (), lib: *std.Build.Step.Compile) void
  {
    self.module.linkLibrary (lib);
  }

  pub fn include (self: @This (), path: std.Build.LazyPath) void
  {
    self.module.addIncludePath (path);
  }
};

// Create a hash from a shader's source contents.
pub fn digest (options: ?*const ShaderCompileOptions, source: [] u8) [64] u8
{
  var hasher = std.crypto.hash.blake2.Blake2b384.init (.{});

  // Make sure that there is no cache hit if the projet name has changed
  hasher.update (zon.name);
  // Make sure that there is no cache hit if the shader's source has changed.
  hasher.update (source);
  // Not only the shader source must be the same to ensure uniqueness the compile command, too.
  if (options) |o|
  {
    inline for (std.meta.fields (@TypeOf (o.*))) |field|
    {
      hasher.update (field.name);
      hasher.update (@tagName (@field (o.*, field.name)));
    }
  }

  // Create a base-64 hash digest from a hasher, which we can use as file name.
  var hash_digest: [48] u8 = undefined;
  hasher.final (&hash_digest);
  var hash: [64] u8 = undefined;
  _ = std.fs.base64_encoder.encode (&hash, &hash_digest);

  return hash;
}
