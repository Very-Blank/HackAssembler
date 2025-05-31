const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "HackAssembler",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(exe);
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const cInstructionTest = b.createModule(.{
        .root_source_file = b.path("src/cInstructionTests.zig"),
        .target = target,
        .optimize = optimize,
    });

    const unitCInstructionTest = b.addTest(.{
        .root_module = cInstructionTest,
    });

    const runUnitCInstructionsTest = b.addRunArtifact(unitCInstructionTest);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&runUnitCInstructionsTest.step);

    const parsingTests = b.createModule(.{
        .root_source_file = b.path("src/parsingTests.zig"),
        .target = target,
        .optimize = optimize,
    });

    const unitParsingTests = b.addTest(.{
        .root_module = parsingTests,
    });

    const runUnitParsingTests = b.addRunArtifact(unitParsingTests);
    test_step.dependOn(&runUnitParsingTests.step);

    const fullTests = b.createModule(.{
        .root_source_file = b.path("src/fullTest.zig"),
        .target = target,
        .optimize = optimize,
    });

    const unitFullTests = b.addTest(.{
        .root_module = fullTests,
    });

    const runUnitFullTest = b.addRunArtifact(unitFullTests);

    test_step.dependOn(&runUnitFullTest.step);
}
