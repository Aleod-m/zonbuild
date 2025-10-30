const std = @import("std");


pub fn build(b: *std.Build) void {
    _ = @import("zonbuild").runBuildDesc(b, @import("build.desc.zon"));
}

pub fn genModule(b: *std.Build) *std.Build.Module {
    const gen_dep = b.dependencyFromBuildZig(@This(), .{.target = b.graph.host});
    const gen_exe = gen_dep.artifact("gen");
    const gen_run = b.addRunArtifact(gen_exe);
    const gen_output = gen_run.addPrefixedOutputDirectoryArg("-o", "gen-output");
    const gen_mod = b.createModule(.{
        .root_source_file = gen_output.path(b, "root.zig"),
    });
    return gen_mod;
}
