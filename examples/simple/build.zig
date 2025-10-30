const std = @import("std");
const zb = @import("zonbuild");

pub fn build(b: *std.Build) void {
    const desc: zb.BuildDesc = @import("build.desc.zon");
    _ = zb.runBuildDesc(b, desc);
}
