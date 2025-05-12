const std = @import("std");
const instruction = @import("instruction.zig");
const FirstPass = @import("firstPass.zig");

const State = enum {
    ignore,
    instruction,
    aInstruction,
    cInstruction,
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

    pub fn firstPass(self: *Parser, buffer: []u8) !FirstPass {
        _ = self;
        // var instructions: std.ArrayList(instruction.Instruction) = std.ArrayList(instruction.Instruction).init(self.allocator);
        // var instCount: u64 = 0;
        var lineCount: u64 = 0;
        //
        // var cInst: [3]u8 = .{ 0, 0, 0 };

        var i: u64 = 0;
        var j: u64 = 0;

        state: switch (State.Instruction) {
            .ignore => {
                if (buffer[j] == '\n') {
                    j += 1;
                    if (buffer.len != j) {
                        i = j;
                        continue :state .instruction;
                    } else {
                        break :state;
                    }
                } else {
                    j += 1;
                    if (buffer.len != j) {
                        continue :state .ignore;
                    } else {
                        break :state;
                    }
                }
            },
            .instruction => {
                switch (buffer[j]) {
                    '/' => {
                        j += 1;
                        if (j + 1 < buffer.len and buffer[j + 1] == '/') {
                            i = j;
                            continue :state .ignore;
                        } else {
                            return error.@"Unexpected / found";
                        }
                    },
                    '@' => {},
                    // zig fmt: off
                    std.ascii.whitespace[0],
                    std.ascii.whitespace[1],
                    std.ascii.whitespace[3],
                    std.ascii.whitespace[4],
                    std.ascii.whitespace[5] => {
                        // zig fmt: on
                        j += 1;
                        if (buffer.len != j) {
                            i = j;
                            continue :state .instruction;
                        } else {
                            break :state;
                        }
                    },
                    '\n' => {
                        j += 1;
                        lineCount += 1;

                        if (buffer.len != j) {
                            i = j;
                            continue :state .instruction;
                        } else {
                            break :state;
                        }
                    },
                    else => {
                        if (std.ascii.is) {}
                    },
                }
            },
        }
    }
};
