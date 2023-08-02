const std = @import("std");

pub fn build(b: *std.build.Builder) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "ZigGorillas",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
        .main_pkg_path = .{ .path = "." },
    });
    if (exe.target.isWindows()) {
        exe.addVcpkgPaths(.dynamic) catch @panic("vcpkg not installed");
        if (exe.vcpkg_bin_path) |path| {
            const src_path = try std.fs.path.join(b.allocator, &.{ path, "SDL2.dll" });
            b.installBinFile(src_path, "SDL2.dll");
        }
        exe.subsystem = .Windows;
        exe.linkSystemLibrary("shell32");
        exe.addObjectFile(.{ .path = "banana.o" });
    }
    exe.addIncludePath(.{ .path = "lib/nanovg/src" });
    const c_flags = &.{ "-std=c99", "-D_CRT_SECURE_NO_WARNINGS", "-Ilib/gl2/include" };
    exe.addCSourceFile(.{ .file = .{ .path = "src/c/nanovg_gl2_impl.c" }, .flags = c_flags });
    exe.linkSystemLibrary("SDL2");
    if (exe.target.isDarwin()) {
        exe.linkFramework("OpenGL");
    } else if (exe.target.isWindows()) {
        exe.linkSystemLibrary("opengl32");
    } else {
        exe.linkSystemLibrary("gl");
    }
    exe.linkLibC();
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run ZigGorillas");
    run_step.dependOn(&run_cmd.step);
}
