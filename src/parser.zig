const std = @import("std");
const instruction = @import("instruction.zig");
const FirstPass = @import("firstPass.zig");

const State = enum {
    newLine,
    comment,
    search,
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
        var currentLine: u64 = 1;
        //
        // var cInst: [3]u8 = .{ 0, 0, 0 };

        var i: u64 = 0;

        state: switch (State.search) {
            .newLine => {
                switch (buffer[i]) {
                    '\n' => {
                        currentLine += 1;

                        if (i + 1 < buffer.len) {
                            i += 1;
                            continue :state .search;
                        }

                        break :state;
                    },
                    '/' => {
                        continue :state .comment;
                    },
                    ' ', '\t', '\r', std.ascii.control_code.vt, std.ascii.control_code.ff => {},
                    else => return error.UnexpectedCharacter,
                }
            },
            .comment => {
                i += 1;
                if (i < buffer.len and buffer[i] == '/') {
                    std.debug.print("Comment, line: {any}\n", .{currentLine});
                    for (i..buffer.len) |j| {
                        if (buffer[j] == '\n') {
                            currentLine += 1;

                            if (j + 1 < buffer.len) {
                                i = j + 1;
                                continue :state .search;
                            }

                            i = j;
                            break :state;
                        }
                    }
                } else {
                    return error.@"Unexpected / found";
                }
            },
            .search => {
                switch (buffer[i]) {
                    '/' => {
                        continue :state .comment;
                    },
                    ' ', '\t', '\r', std.ascii.control_code.vt, std.ascii.control_code.ff => {
                        if (i + 1 < buffer.len) {
                            i += 1;
                            continue :state .search;
                        }

                        break :state;
                    },
                    '\n' => {
                        currentLine += 1;

                        if (i + 1 < buffer.len) {
                            i += 1;
                            continue :state .search;
                        }

                        break :state;
                    },
                    '@' => {
                        if (i + 1 < buffer.len) {
                            i += 1;
                            continue :state .aInstruction;
                        }

                        return error.ExpectedAInstruction;
                    },
                    '0'...'9', 'A'...'Z', 'a'...'z', '-', '!' => {
                        continue :state .cInstruction;
                    },
                    '(' => {
                        continue :state .label;
                    },
                    else => {
                        std.debug.print("Line: {any}\n", .{currentLine});
                        return error.UnexpectedCharacter;
                    },
                }
            },
            .aInstruction => {
                std.debug.print("A Instruction, line: {any}\n", .{currentLine});
                for (i..buffer.len) |j| {
                    switch (buffer[j]) {
                        '\n' => {
                            currentLine += 1;
                            if (j + 1 < buffer.len) {
                                i = j + 1;
                                continue :state .search;
                            }

                            i = j;
                            break :state;
                        },
                        '/' => {
                            i = j;
                            continue :state .comment;
                        },
                        else => {},
                    }
                }
            },
            .cInstruction => {
                std.debug.print("C Instruction, line: {any}\n", .{currentLine});
                for (i..buffer.len) |j| {
                    switch (buffer[j]) {
                        '\n' => {
                            currentLine += 1;
                            if (j + 1 < buffer.len) {
                                i = j + 1;
                                continue :state .search;
                            } else {
                                i = j;
                                break :state;
                            }
                        },
                        '/' => {
                            i = j;
                            continue :state .comment;
                        },
                        else => {},
                    }
                }
            },
            .label => {
                if (i + 2 >= buffer.len) return error.@"Unexpected ( found";
                if (!std.ascii.isAlphabetic(buffer[i + 1]) and buffer[i + 1] != '_') return error.@"Label start was not alphabetic";

                for (i + 1..buffer.len) |j| {
                    switch (buffer[j]) {
                        '0'...'9', 'A'...'Z', 'a'...'z', '_' => {},
                        ')' => {
                            std.debug.print("Label: {s}, line: {any}\n", .{ buffer[i + 1 .. j], currentLine });
                            if (j + 1 < buffer.len) {
                                i = j + 1;
                                continue :state .newLine;
                            }

                            break :state;
                        },
                        else => return error.UnexpectedCharacter,
                    }
                }
            },
        }
    }
};
