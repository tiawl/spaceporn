const std = @import ("std");

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
  target:    std.Build.ResolvedTarget,
  optimize:  std.builtin.OptimizeMode,
  variables: *std.Build.Step.Options,
  options:   Options,
  command:   [] const [] const u8,
};

// Create a hash from a shader's source contents.
pub fn digest (profile: ?*const Profile, source: [] u8) [64] u8
{
  var hasher = std.crypto.hash.blake2.Blake2b384.init (.{});

  // Make sure that there is no cache hit if the projet name has changed
  hasher.update (zon.name);
  // Make sure that there is no cache hit if the shader's source has changed.
  hasher.update (source);
  // Not only the shader source must be the same to ensure uniqueness the compile command, too.
  if (profile) |p| for (p.command) |token| hasher.update (token);

  // Create a base-64 hash digest from a hasher, which we can use as file name.
  var hash_digest: [48] u8 = undefined;
  hasher.final (&hash_digest);
  var hash: [64] u8 = undefined;
  _ = std.fs.base64_encoder.encode (&hash, &hash_digest);

  return hash;
}
