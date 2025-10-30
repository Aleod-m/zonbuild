# zonbuild

A quick way to define the build graph in the zon format.

This provides the folowing build steps:
- run (by default for executables)
- check (by default for all kinds of modules)
- test (by default for all kinds of modules)
- doc (by default for modules and libraries)

By default `.mod` and `.lib` take their root source file at `src/root.zig` and `.exe` at `src/main.zig`.

## Default usage:

Install:
```bash
zig fetch --save git+https://github.com/Aleod-m/zonbuild.git
```

```zon
// build.desc.zon
.{
    .{
        .name = "sub_lib",
        .kind = .mod,
        .vis = .private, // Hides the module. Modules are public by default.
        // Module not at src/root.zig
        .root = "src/sub_lib/root.zig"
    },
    .{
        .name = "lib",
        .kind = .mod, // Defines a module.
        // Overide the default steps this module should be included in.
        .steps = .{ .check, .test },
        .imports = .{ .{ .name = "sub_lib" } }
    },
    .{ 
        .name = "exec_alt",
        .kind = .exe,
        .step = .{ .run }
    },
    .{
        .name = "exec",
        .kind = .exe,
        .steps = .{ .run },
        .imports = .{
            .{ .name = "lib" }
            // Rename the module for import.
            .{ .name = "sub_lib", .as = "slib" }
        },
    }
}
```

If multiple exectuables are defined. Either exclude the executable from the exec step or select the executable with `zig build run -Dname=<exe_name>`.

This can also be used with the other steps. For example if you want to run only the test/check steps for a module `zig build <step> -Dname=<mod_name>`.

```zig
// build.zig
const std = @import("std");
const Build = std.Build;
const zb = @import("zonbuild");

fn build(b: *Build) void {
    const zon_desc = @import("build.desc.zon")
    _ = zb.runBuildDesc(b, zon_desc);
}
```

## Advanced usage

If you want to include code gen for example you can add modules before the execution of the build description manually like this:
```zig
// build.zig
const std = @import("std");
const Build = std.Build;
const zb = @import("zonbuild");
const codeGen = @import("codeGen");

fn build(b: *Build) void {
    const zon_desc = @import("build.desc.zon")
    const ctx: zb.Context = zb.Context.init(b);
    const generatedModule: *Build.Module = codeGen.genModule(b);
    ctx.addModule("codeGen", generatedModule);
    zb.runBuildDescWithContext(&ctx, zon_desc);
}

/// build.desc.zon
.{
    .{
        .name = "lib",
        .kind = .mod,
        .imports = .{ .{ .name = "codGen" } },
    }
}
```
