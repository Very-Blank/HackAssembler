const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mainMod = b.createModule(.{
        .root_source_file = b.path("src/hackAsm.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    exe_mod.addImport("HackAsm", mainMod);

    const exe = b.addExecutable(.{
        .name = "HackAssembler",
        .root_module = exe_mod,
    });

    b.installArtifact(exe);
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // Tests:
    const testFiles = .{
        "cTest",
        "fullTest",
        "parsingTest",
        "perfTest",
    };

    const test_step = b.step("test", "Run unit tests");

    inline for (testFiles) |fileName| {
        const testModule = b.createModule(.{
            .root_source_file = b.path("tests/" ++ fileName ++ ".zig"),
            .target = target,
            .optimize = optimize,
        });

        testModule.addImport("HackAsm", mainMod);

        const unitTest = b.addTest(.{
            .root_module = testModule,
        });

        const runUnitTest = b.addRunArtifact(unitTest);

        test_step.dependOn(&runUnitTest.step);
    }
}
