const std = @import("std");
const fs = std.fs;
const mem = std.mem;
const Builder = std.build.Builder;

pub fn build(b: *Builder) !void {
    // workaround for windows not having visual studio installed
    // (makes .gnu the default target)
    const native_target = if (std.builtin.os.tag == .windows)
        std.zig.CrossTarget{ .abi = .gnu }
    else
        std.zig.CrossTarget{};
    const target = b.standardTargetOptions(.{
        .default_target = native_target,
    });
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("ZigGorillas", "src/main.zig");
    exe.setBuildMode(mode);
    exe.setTarget(target);
    if (exe.target.isWindows()) {
        try exe.addVcpkgPaths(.Dynamic);
        if (exe.vcpkg_bin_path) |path| {
            const src_path = try fs.path.join(b.allocator, &.{ path, "SDL2.dll" });
            b.installBinFile(src_path, "SDL2.dll");
        }
        exe.subsystem = .Windows;
        exe.linkSystemLibrary("shell32");
        exe.addObjectFile("banana.o");
    }
    exe.addIncludeDir("lib/nanovg/src");
    const c_flags = &.{ "-std=c99", "-D_CRT_SECURE_NO_WARNINGS", "-Ilib/gl2/include" };
    exe.addCSourceFile("src/c/nanovg_gl2_impl.c", c_flags);
    exe.linkSystemLibrary("SDL2");
    if (exe.target.isDarwin()) {
        exe.linkFramework("OpenGL");
    } else if (exe.target.isWindows()) {
        exe.linkSystemLibrary("opengl32");
    } else {
        exe.linkSystemLibrary("gl");
    }
    exe.linkLibC();
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run ZigGorillas");
    run_step.dependOn(&run_cmd.step);
}
