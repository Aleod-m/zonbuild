const std = @import("std");
const gen = @import("gen");
const zb = @import("zonbuild");

pub fn build(b: *std.Build) void {
    var ctx: zb.Context = .init(b);
    ctx.addModule("generated", gen.genModule(b));
    const desc: zb.BuildDesc = @import("build.desc.zon");
    _ = zb.runDescWithContext(&ctx, desc);
}
