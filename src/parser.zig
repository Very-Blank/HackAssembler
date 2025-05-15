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

    pub fn firstPass(self: *Parser, buffer: []u8) !FirstPass {
        _ = self;
        // var instructions: std.ArrayList(instruction.Instruction) = std.ArrayList(instruction.Instruction).init(self.allocator);
        // var instCount: u64 = 0;
        var lineCount: u64 = 0;
        //
        // var cInst: [3]u8 = .{ 0, 0, 0 };

        var i: u64 = 0;

        state: switch (State.Instruction) {
            .ignore => {
                if (buffer[i] == '\n') {
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
                        i += 1;
                        if (i + 1 < buffer.len and buffer[i + 1] == '/') {
                            continue :state .ignore;
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
                            break :state;
                        }
                    },
                    'A'...'Z', 'a'...'z' => {
                        //
                    },
                    else => {
                        return error.UnexpectedCharacter;
                    },
                }
            },
            .aInstruction => {},
            .cInstruction => {},
            .label => {},
        }
    }
};
