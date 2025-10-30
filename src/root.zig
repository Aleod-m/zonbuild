//! A build helper library the provides a way to declare the build with ZON.
//!
//! To use import the zonBuild dependency in your build.zig:
//! ```zig
//! const std = @import("std");
//! const zb = @import("zonBuild");
//!
//! fn build(b: *std.Build) {
//!    const buildDesc = @import("build.desc.zon");
//!    zb.runBuildDesc(b, buildDesc);
//! }
//! ```
const std = @import("std");
const Build = std.Build;

pub const CompileDesc = @import("CompileDesc.zig");
pub const Context= @import("Context.zig");
pub const BuildDesc = []const CompileDesc;

/// Evaluates the context with a pre-initialized context. 
///
/// This allows you to inject modules before the execution of the build description. 
/// The principal use case for this function is code generation.
pub fn runDescWithContext(ctx: *Context, build_desc: BuildDesc) void {
    // Define all modules.
    for (build_desc) |desc| {
        const module = ctx.b.createModule(.{
            .root_source_file = ctx.b.path(desc.root orelse desc.kind.defaultRoot()),
            .target = ctx.target,
            .optimize = ctx.optimize,
        });
        ctx.modules.put(desc.name, module) catch @panic("OOM");
    }

    for (build_desc) |desc| {
        // Resolve all imports.
        const module = ctx.modules.get(desc.name).?;
        for (desc.imports) |import| {
            // Resolve if import is a local module or a dependency.
            var import_module: *Build.Module = undefined;
            var import_name: []const u8 = undefined;
            if (std.mem.indexOfScalar(u8, import.name, '/')) |idx| {
                const dep = ctx.b.dependency(import.name[0..idx], .{});
                std.debug.print("Package name: {s}", .{import.name[0..idx]});
                std.debug.print("Package module: {s}", .{import.name[(idx + 1)..]});
                import_module = dep.module(import.name[(idx + 1)..]);
                import_name = import.as orelse import.name[(idx + 1)..];
            } else {
                import_module = ctx.modules.get(import.name) orelse @panic("Import module not found");
                import_name = import.as orelse import.name;
            }
            module.addImport(import_name, import_module);
        }

        // If public expose the module.
        if (desc.vis == .public) {
            if (desc.kind == .mod) { // If its a module export it normally
                ctx.b.modules.put(ctx.b.dupe(desc.name), module) catch @panic("OOM");
            } else { // Otherwise install the binary or the library.
                const compile_step = desc.getCompile(ctx);
                ctx.b.installArtifact(compile_step);
            }
        }

        // Add the steps to the correct steps.
        
        // If target module is defined and is not this one don't add module to steps.
        if (ctx.target_module_name) |target_module_name|
            if (!std.mem.eql(u8, target_module_name, desc.name))
                continue;

        // Otherwise add to steps
        const steps = desc.steps orelse desc.kind.defaultSteps();
        for (steps) |step| {
            switch (step) {
                .check => {
                    const compile_step = desc.getCompile(ctx);
                    ctx.check_step.dependOn(&compile_step.step);
                },
                .@"test" => {
                    const test_compile = ctx.b.addTest(.{
                        .root_module = ctx.modules.get(desc.name).?,
                    });
                    ctx.test_step.dependOn(&test_compile.step);
                },
                .run => {
                    const compile_step = desc.getCompile(ctx);
                    if (ctx.exe_step != null)
                        @panic("Multiple executable please select a target executable with -Dname=<target>");
                    ctx.exe_step = ctx.b.addRunArtifact(compile_step);
                    ctx.run_step.dependOn(&ctx.exe_step.?.step);
                },
                .doc => {
                    const compile_doc = desc.getCompile(ctx);
                    const install_step = ctx.b.addInstallDirectory(.{
                        .source_dir = compile_doc.getEmittedDocs(),
                        .install_dir = .prefix,
                        .install_subdir = ctx.b.pathJoin(&.{"docs/", desc.name}),
                    });
                    ctx.doc_step.dependOn(&install_step.step);
                }
            }
        }
    }
}

/// Initialize the context and evaluates the build description.
pub fn runBuildDesc(b: *Build, build_desc: BuildDesc) Context {
    var ctx: Context = .init(b);
    runDescWithContext(&ctx, build_desc);
    return ctx;
}
