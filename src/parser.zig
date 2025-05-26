const std = @import("std");
const instruction = @import("instruction.zig");
const FirstPass = @import("firstPass.zig");

const State = enum {
    newLine,
    comment,
    search,
};

pub const Parser = struct {
    destMap: std.StringHashMap(instruction.Destination),
    compMap: std.StringHashMap(instruction.Computation),
    jumpMap: std.StringHashMap(instruction.Jump),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) !Parser {
        var parser: Parser = .{
            .destMap = std.StringHashMap(instruction.Destination).init(allocator),
            .compMap = std.StringHashMap(instruction.Computation).init(allocator),
            .jumpMap = std.StringHashMap(instruction.Jump).init(allocator),
            .allocator = allocator,
        };

        errdefer parser.deinit();

        inline for (@typeInfo(instruction.Destination).@"enum".fields) |dest| {
            try parser.destMap.put(dest.name, dest.value);
        }

        inline for (@typeInfo(instruction.Computation).@"enum".fields) |comp| {
            try parser.compMap.put(comp.name, comp.value);
        }

        inline for (@typeInfo(instruction.Jump).@"enum".fields) |jump| {
            try parser.jumpMap.put(jump.name, jump.value);
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
                        continue :state .aInstruction;
                    },
                    '0'...'9', 'A'...'Z', 'a'...'z', '-', '!' => {
                        continue :state .cInstruction;
                    },
                    '(' => {
                        const nextState, const pos, const insides = try label(buffer[i..buffer.len]);
                        i += pos;

                        std.debug.print("Label: {s}, Line {any}\n", .{ insides, currentLine });

                        if (i + 1 < buffer.len) {
                            i += 1;
                            continue :state nextState;
                        } else break :state;
                    },
                    else => {
                        std.debug.print("Line: {any}\n", .{currentLine});
                        return error.UnexpectedCharacter;
                    },
                }
            },
            .aInstruction => {},
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
        }
    }

    /// Takes in a slice of the buffer that is in the format @......
    /// Returns the next state, position of the ending character (whitespace, buffer end, /) and an union of what the instruction was.
    inline fn aInstruction(slice: []u8) !struct { State, u64, union(enum) { number: u64, slice: []u8 } } {
        std.debug.assert(slice[0] == '@');
        if (slice.len < 2) return error.@"Unexpected @ found";
        // if (!std.ascii.isAlphabetic(buffer[i + 1]) and buffer[i + 1] != '_') return error.@"Label start was not alphabetic";

        // std.debug.print("A Instruction, line: {any}\n", .{currentLine});
        switch (slice[1]) {
            // FIXME: something like this should be invalid!!!! 09448
            '0'...'9' => |firstNum| {
                var number: u64 = @intCast(firstNum - '0');

                for (2..slice.len) |i| {
                    switch (slice[i]) {
                        ' ', '\t', '\r', std.ascii.control_code.vt, std.ascii.control_code.ff => {
                            return .{ State.newLine, i, .{ .number = number } };
                        },
                        '0'...'9' => |num| {
                            number = number * 10 + @as(u64, @intCast((num - '0')));
                        },
                        '/' => {
                            return .{ State.comment, i, .{ .number = number } };
                        },
                        '\n' => {
                            return .{ State.search, i, .{ .number = number } };
                        },
                        else => return error.UnexpectedCharacter,
                    }
                }

                return .{ State.newLine, slice.len - 1, .{ .number = number } };
            },
            'A'...'Z', 'a'...'z', '_' => {
                for (2..slice.len) |i| {
                    switch (slice[i]) {
                        ' ', '\t', '\r', std.ascii.control_code.vt, std.ascii.control_code.ff => {
                            return .{ State.newLine, i, .{ .slice = slice[1..i] } };
                        },
                        '/' => {
                            return .{ State.newLine, i, .{ .slice = slice[1..i] } };

                            std.debug.print("A instruction: {s}, line: {any}\n", .{ buffer[i + 1 .. i], currentLine });
                            if (i + 1 < buffer.len) {
                                i = i + 1;
                                continue :state .comment;
                            }

                            break :state;
                        },
                        '\n' => {
                            std.debug.print("A instruction: {s}, line: {any}\n", .{ buffer[i + 1 .. i], currentLine });

                            currentLine += 1;
                            if (i + 1 < buffer.len) {
                                i = i + 1;
                                continue :state .search;
                            }

                            break :state;
                        },
                        'A'...'Z', 'a'...'z', '0'...'9', '_' => {},
                        else => return error.UnexpectedCharacter,
                    }
                }

                // FIXME: slice ended return the instruction
            },
            else => return error.UnexpectedCharacter,
        }
    }

    /// Takes in a slice of the buffer that is in the format (......
    /// Returns the next state, position of the ) and a slice that contains the insides of the label
    inline fn label(slice: []u8) !struct { State, u64, []u8 } {
        std.debug.assert(slice[0] == '(');

        if (slice.len < 3 or !std.ascii.isAlphabetic(slice[1])) return error.@"Unexpected ( found";

        for (2..slice.len) |i| {
            switch (slice[i]) {
                '0'...'9', 'A'...'Z', 'a'...'z', '_' => {},
                ')' => {
                    return .{ State.newLine, i, slice[1..i] };
                },
                else => return error.UnexpectedCharacter,
            }
        }

        return error.@"Unexpected ( found";
    }
};
