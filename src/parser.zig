const std = @import("std");
const instruction = @import("instruction.zig");
const FirstPass = @import("firstPass.zig");

const State = enum {
    ignore,
    instruction,
    aInstruction,
    cInstruction,
    label,
};

pub const Parser = struct {
    destMap: std.StringHashMap(instruction.Destination),
    compMap: std.StringHashMap(instruction.Computation),
    jumpMap: std.StringHashMap(instruction.Jump),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) Parser {
        var parser: Parser = .{
            .destMap = std.StringHashMap(instruction.Destination).init(allocator),
            .compMap = std.StringHashMap(instruction.Computation).init(allocator),
            .jumpMap = std.StringHashMap(instruction.Jump).init(allocator),
            .allocator = allocator,
        };

        inline for (@typeInfo(instruction.Destination).@"enum".fields) |dest| {
            parser.destMap.put(dest.name, dest.value);
        }

        inline for (@typeInfo(instruction.Computation).@"enum".fields) |comp| {
            parser.compMap.put(comp.name, comp.value);
        }

        inline for (@typeInfo(instruction.Jump).@"enum".fields) |jump| {
            parser.jumpMap.put(jump.name, jump.value);
        }
    }

    pub fn firstPass(buffer: []const u8) !void {
        // var instructions: std.ArrayList(instruction.Instruction) = std.ArrayList(instruction.Instruction).init(self.allocator);
        // var instCount: u64 = 0;
        var lineCount: u64 = 0;
        //
        // var cInst: [3]u8 = .{ 0, 0, 0 };

        var i: u64 = 0;

        state: switch (State.instruction) {
            .ignore => {
                if (buffer[i] == '\n') {
                    lineCount += 1;
                    i += 1;
                    if (i < buffer.len) {
                        continue :state .instruction;
                    } else {
                        break :state;
                    }
                } else {
                    i += 1;
                    if (i < buffer.len) {
                        continue :state .ignore;
                    } else {
                        break :state;
                    }
                }
            },
            .instruction => {
                switch (buffer[i]) {
                    '/' => {
                        if (i + 1 < buffer.len and buffer[i + 1] == '/') {
                            std.debug.print("Commment\n", .{});

                            i += 2;
                            if (i < buffer.len) {
                                continue :state .ignore;
                            } else {
                                break :state;
                            }
                        } else {
                            return error.@"Unexpected / found";
                        }
                    },
                    ' ', '\t', '\r', std.ascii.control_code.vt, std.ascii.control_code.ff => {
                        i += 1;
                        if (i < buffer.len) {
                            continue :state .instruction;
                        } else {
                            break :state;
                        }
                    },
                    '\n' => {
                        i += 1;
                        lineCount += 1;

                        if (i < buffer.len) {
                            continue :state .instruction;
                        } else {
                            break :state;
                        }
                    },
                    '@' => {
                        i += 1;
                        if (i < buffer.len) {
                            continue :state .aInstruction;
                        } else {
                            return error.ExpectedAInstruction;
                        }
                    },
                    '0'...'9', 'A'...'Z', 'a'...'z' => {
                        continue :state .cInstruction;
                    },
                    '(' => {
                        i += 1;
                        if (i < buffer.len) {
                            continue :state .aInstruction;
                        } else {
                            return error.ExpectedLabel;
                        }
                    },
                    else => {
                        std.debug.print("Line: {any}\n", .{lineCount});
                        return error.UnexpectedCharacter;
                    },
                }
            },
            .aInstruction => {
                for (i..buffer.len) |j| {
                    if (buffer[j] == '\n') {
                        lineCount += 1;

                        std.debug.print("A Instruction\n", .{});
                        if (j + 1 < buffer.len) {
                            i = j + 1;
                            continue :state .instruction;
                        } else {
                            i = j;
                            break :state;
                        }
                    }
                }
            },
            .cInstruction => {
                for (i..buffer.len) |j| {
                    if (buffer[j] == '\n') {
                        lineCount += 1;

                        std.debug.print("C Instruction\n", .{});
                        if (j + 1 < buffer.len) {
                            i = j + 1;
                            continue :state .instruction;
                        } else {
                            i = j;
                            break :state;
                        }
                    }
                }
            },
            .label => {
                for (i..buffer.len) |j| {
                    if (buffer[j] == '\n') {
                        lineCount += 1;

                        std.debug.print("Label\n", .{});
                        if (j + 1 < buffer.len) {
                            i = j + 1;
                            continue :state .instruction;
                        } else {
                            i = j;
                            break :state;
                        }
                    }
                }
            },
        }
    }
};
