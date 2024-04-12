const std      = @import ("std");
const c        = @import ("c");
const literals = @import ("literals");

const vk = @import ("vk");

const Prototypes = struct
{
  fn ziggify (comptime T: type) type
  {
    var name: [] const u8 = @typeName (T);
    if (std.mem.indexOf (u8, name, "_Vk")) |index| name = name [index + 3 ..];
    if (std.mem.lastIndexOfScalar (u8, name, '_')) |index| name = name [0 .. index];

    var field = vk;
    for ([_][] const u8 { "EXT", "KHR", }) |prefix|
    {
      if (std.mem.endsWith (u8, name, prefix))
      {
        name = name [0 .. name.len - prefix.len];
        field = @field (vk, prefix);
        break;
      }
    }
    var start: usize = 0;
    var end = name.len;
    while (start < end)
    {
      if (@hasDecl (field, name [start .. end]))
      {
        field = @field (field, name [start .. end]);
        start = end;
        end = name.len;
      } else end = std.mem.lastIndexOfAny (u8, name [0 .. end - 1],
          "ABCDEFGHIJKLMNOPQRSTUVWXYZ") orelse
          @compileError ("Undefined \"" ++ name [start .. end] ++ "\" into vk binding from \"" ++ name ++ "\"");
    }

    return field;
  }

  fn cast_rec (comptime T: type, is_opaque: *bool) type
  {
    var info = @typeInfo (T);
    return switch (info)
    {
      .Opaque   => blk: {
                     if (T == anyopaque) break :blk T
                     else { is_opaque.* = true; break :blk ziggify (T); }
                   },
      .Optional => blk: {
                     const child = cast_rec (info.Optional.child, is_opaque);
                     if (is_opaque.*) { is_opaque.* = false; break :blk child; }
                     else { info.Optional.child = child; break :blk @Type (info); }
                   },
      .Pointer  => blk: {
                     const child = cast_rec (info.Pointer.child, is_opaque);
                     if (is_opaque.*) break :blk child
                     else { info.Pointer.child = child; break :blk @Type (info); }
                   },
      .Struct   => if (info.Struct.layout == .auto) T else ziggify (T),
      else      => T,
    };
  }

  fn cast (comptime T: type) type
  {
    var is_opaque = false;
    return cast_rec (T, &is_opaque);
  }

  fn Dispatch (comptime T: std.meta.DeclEnum (literals)) type
  {
    @setEvalBranchQuota (100_000);
    const size = @typeInfo (@field (literals, @tagName (T))).Enum.fields.len;
    var fields: [size] std.builtin.Type.StructField = undefined;
    for (@typeInfo (@field (literals, @tagName (T))).Enum.fields, 0 ..) |*field, i|
    {
      const pfn = pfn: {
        const pointer = @typeInfo (@TypeOf (@field (c, field.name)));
        var params: [pointer.Fn.params.len] std.builtin.Type.Fn.Param = undefined;
        for (pointer.Fn.params, 0 ..) |*param, j|
        {
          params [j] = .{
            .is_generic = param.is_generic,
            .is_noalias = param.is_noalias,
            .type = cast (param.type orelse
              @compileError ("Param type is null for " ++ field.name)),
          };
        }
        break :pfn @Type (.{
          .Pointer = .{
            .size = .One,
            .is_const = true,
            .is_volatile = false,
            .alignment = 1,
            .address_space = .generic,
            .child = @Type (.{
              .Fn = .{
                .calling_convention = c.call_conv,
                .is_generic = pointer.Fn.is_generic,
                .is_var_args = pointer.Fn.is_var_args,
                .return_type = cast (pointer.Fn.return_type orelse
                  @compileError ("Return type is null for " ++ field.name)),
                .params = &params,
              },
            }),
            .is_allowzero = false,
            .sentinel = null,
          },
        });
      };

      // @compileLog (field.name ++ ": " ++ @typeName (pfn));
      fields [i] = .{
        .name = field.name,
        .type = pfn,
        .default_value = null,
        .is_comptime = false,
        .alignment = @alignOf (pfn),
      };
    }
    return @Type (.{
      .Struct = .{
        .layout = .auto,
        .fields = &fields,
        .decls = &.{},
        .is_tuple = false,
      },
    });
  }

  structless: Prototypes.Dispatch (.structless),
  instance: Prototypes.Dispatch (.instance),
  device: Prototypes.Dispatch (.device),
};

pub var prototypes: Prototypes = undefined;
