const std = @import("std");
const deps = @import("./deps.zig");

pub fn build(b: *std.build.Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("zig-licenses", "src/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    //

    const exe2 = b.addExecutable("generate", "generate.zig");
    exe2.setTarget(target);
    exe2.setBuildMode(mode);
    deps.addAllTo(exe2);
    exe2.install();

    const run_cmd2 = exe2.run();
    run_cmd2.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd2.addArgs(args);
    }

    const run_step2 = b.step("gen", "generate the list");
    run_step2.dependOn(&run_cmd2.step);
}
