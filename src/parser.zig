const std = @import("std");
const instruction = @import("instruction.zig");
const FirstPass = @import("firstPass.zig");

const FirstPassState = enum {
    newLine,
    comment,
    search,
};

const CInstructionState = enum {};

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
            try parser.destMap.put(dest.name, @field(instruction.Destination, dest.name));
        }

        inline for (@typeInfo(instruction.Computation).@"enum".fields) |comp| {
            try parser.compMap.put(comp.name, @field(instruction.Computation, comp.name));
        }

        inline for (@typeInfo(instruction.Jump).@"enum".fields) |jump| {
            try parser.jumpMap.put(jump.name, @field(instruction.Jump, jump.name));
        }

        return parser;
    }

    pub fn deinit(self: *Parser) void {
        self.destMap.deinit();
        self.compMap.deinit();
        self.jumpMap.deinit();
    }

    pub fn firstPass(self: *const Parser, buffer: []const u8) !void {
        // var instructions: std.ArrayList(instruction.Instruction) = std.ArrayList(instruction.Instruction).init(self.allocator);
        // var instCount: u64 = 0;
        var currentLine: u64 = 1;
        //
        // var cInst: [3]u8 = .{ 0, 0, 0 };

        var i: u64 = 0;

        state: switch (FirstPassState.search) {
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
                        const nextState, const pos, const a = try aInstruction(buffer[i..buffer.len]);
                        i += pos;

                        switch (a) {
                            .symbol => |symbol| {
                                std.debug.print("aInstruction with symbol: {s}, Line {any}\n", .{ symbol, currentLine });
                            },
                            .value => |value| {
                                std.debug.print("aInstruction with value: {any}, Line {any}\n", .{ value, currentLine });
                            },
                        }

                        if (nextState == .search) { // FIX: This might be a bug currentline could be extra counted by search!
                            currentLine += 1;
                        }

                        if (i + 1 < buffer.len) {
                            i += 1;
                            continue :state nextState;
                        } else break :state;
                    },
                    '0'...'9', 'A'...'Z', 'a'...'z', '-', '!' => {
                        const nextState, const pos, const c = try self.cInstruction(buffer[i..buffer.len]);
                        i += pos;

                        std.debug.print("C Instruction, line: {any}\n", .{c});

                        continue :state nextState;
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
        }
    }

    inline fn cInstruction(self: *const Parser, slice: []const u8) !struct { FirstPassState, u64, instruction.C } {
        std.debug.assert(isCInstructionStart(slice[0]));
        //M=D
        //D=M;JNE

        var dest: ?[]const u8 = null;
        var comp: ?[]const u8 = null;
        var jump: ?[]const u8 = null;

        var nextFirstPassState: FirstPassState = .search;
        //0;JMP

        var splitter: SliceSplitter, const current: []const u8 = try lookForSlice(slice);
        var end = current.len;

        init: switch (splitter) {
            .@";" => {
                comp = current;
            },
            .@"=" => {
                dest = current;
            },
            .space => {
                for (end..slice.len) |i| {
                    switch (slice[i]) {
                        '\n' => return error.UnexpectedCharacter1,
                        ';' => {
                            splitter = .@";";
                            comp = current;
                            end = i;
                            break :init;
                        },
                        '=' => {
                            splitter = .@"=";
                            dest = current;
                            end = i;
                            break :init;
                        },
                        else => {},
                    }
                }

                return error.UnexpectedCharacter2;
            },
            else => return error.UnexpectedCharacter3,
        }

        state: switch (splitter) {
            .@";" => {
                if (slice.len < end + 1) return error.UnexpectedCharacter4;
                splitter, jump = try lookForSlice(slice[end + 1 .. slice.len]);
                end += 1 + jump.?.len;

                switch (splitter) {
                    .@"\n" => {
                        break :state;
                    },
                    .space => {
                        for (end..slice.len) |i| {
                            switch (slice[i]) {
                                '\n' => {
                                    end = i;
                                    break :state;
                                },
                                '/' => {
                                    nextFirstPassState = .comment;
                                    end = i;
                                    break :state;
                                },
                                ' ', '\t', '\r', std.ascii.control_code.vt, std.ascii.control_code.ff => {},
                                else => return error.UnexpectedCharacter5,
                            }
                        }
                    },
                    else => return error.UnexpectedCharacter6,
                }
            },
            .@"=" => {
                if (slice.len < end + 1) return error.UnexpectedCharacter7;
                splitter, comp = try lookForSlice(slice[end + 1 .. slice.len]);
                end += 1 + comp.?.len;

                switch (splitter) {
                    .@";" => continue :state .@";",
                    .@"\n" => break :state,
                    .space => {
                        for (end..slice.len) |i| {
                            switch (slice[i]) {
                                ' ', '\t', '\r', std.ascii.control_code.vt, std.ascii.control_code.ff => {},
                                '\n' => {
                                    end = i;
                                    break :state;
                                },
                                '/' => {
                                    nextFirstPassState = .comment;
                                    end = i;
                                    break :state;
                                },
                                ';' => {
                                    end = i;
                                    continue :state .@";";
                                },
                                else => return error.UnexpectedCharacter8,
                            }
                        }

                        return error.UnexpectedCharacter9;
                    },
                    else => return error.UnexpectedCharacter10,
                }
            },
            else => return error.UnexpectedCharacter11,
        }

        if (dest != null and comp != null and jump != null) {
            const cDest = if (dest) |value| value else unreachable;
            const cComp = if (comp) |value| value else unreachable;
            const cJump = if (jump) |value| value else unreachable;

            return .{
                FirstPassState.search, end, instruction.C{
                    .dcj = .{
                        .dest = if (self.destMap.get(cDest)) |value| value else return error.InvalidDestination,
                        .comp = if (self.compMap.get(cComp)) |value| value else return error.InvalidComputation,
                        .jump = if (self.jumpMap.get(cJump)) |value| value else return error.InvalidJump,
                    },
                },
            };
        } else if (dest != null and comp != null and jump == null) {
            const cDest = if (dest) |value| value else unreachable;
            const cComp = if (comp) |value| value else unreachable;

            return .{
                FirstPassState.search, end, instruction.C{
                    .dc = .{
                        .dest = if (self.destMap.get(cDest)) |value| value else return error.InvalidDestination,
                        .comp = if (self.compMap.get(cComp)) |value| value else return error.InvalidComputation,
                    },
                },
            };
        } else if (dest == null and comp != null and jump != null) {
            const cComp = if (comp) |value| value else unreachable;
            const cJump = if (jump) |value| value else unreachable;

            return .{
                FirstPassState.search, end, instruction.C{
                    .cj = .{
                        .comp = if (self.compMap.get(cComp)) |value| value else return error.InvalidComputation,
                        .jump = if (self.jumpMap.get(cJump)) |value| value else return error.InvalidJump,
                    },
                },
            };
        }

        unreachable;
    }

    const SliceSplitter = enum {
        @";",
        @"\n",
        @"=",
        space,
    };

    inline fn lookForSlice(slice: []const u8) !struct { SliceSplitter, []const u8 } {
        var start: u64 = 0;
        for (0..slice.len) |i| {
            switch (slice[i]) {
                ' ', '\t', '\r', std.ascii.control_code.vt, std.ascii.control_code.ff => {},
                '\n' => return error.NoStartForSlice,
                else => {
                    start = i;
                    break;
                },
            }
        }

        for (start..slice.len) |i| {
            switch (slice[i]) {
                ' ', '\t', '\r', std.ascii.control_code.vt, std.ascii.control_code.ff => {
                    return .{ SliceSplitter.space, slice[start..i] };
                },
                '\n' => {
                    return .{ SliceSplitter.@"\n", slice[start..i] };
                },
                '=' => {
                    return .{ SliceSplitter.@"=", slice[start..i] };
                },
                ';' => {
                    return .{ SliceSplitter.@";", slice[start..i] };
                },
                else => {},
            }
        }

        return error.@"Slice ended, but no splitter was found";
    }

    /// Takes in a slice of the buffer that is in the format @......
    /// Returns the next state, position of the ending character (whitespace, buffer end, /) and the instruction.
    /// If next state is search the function found a newline character.
    inline fn aInstruction(slice: []const u8) !struct { FirstPassState, u64, instruction.A } {
        std.debug.assert(slice[0] == '@');
        if (slice.len < 2) return error.@"Unexpected @ found";

        switch (slice[1]) {
            '0' => {
                if (3 < slice.len) {
                    switch (slice[2]) {
                        ' ', '\t', '\r', std.ascii.control_code.vt, std.ascii.control_code.ff => {
                            return .{ FirstPassState.newLine, 2, .{ .value = 0 } };
                        },
                        '/' => {
                            return .{ FirstPassState.comment, 2, .{ .value = 0 } };
                        },
                        '\n' => {
                            return .{ FirstPassState.search, 2, .{ .value = 0 } };
                        },
                        else => return error.UnexpectedCharacter,
                    }
                }

                return .{ FirstPassState.search, 2, .{ .value = 0 } };
            },
            '1'...'9' => |firstNum| {
                var number: u64 = @intCast(firstNum - '0');

                for (2..slice.len) |i| {
                    switch (slice[i]) {
                        ' ', '\t', '\r', std.ascii.control_code.vt, std.ascii.control_code.ff => {
                            return .{ FirstPassState.newLine, i, .{ .value = number } };
                        },
                        '0'...'9' => |num| {
                            number = number * 10 + @as(u64, @intCast((num - '0')));
                        },
                        '/' => {
                            return .{ FirstPassState.comment, i, .{ .value = number } };
                        },
                        '\n' => {
                            return .{ FirstPassState.search, i, .{ .value = number } };
                        },
                        else => return error.UnexpectedCharacter,
                    }
                }

                return .{ FirstPassState.newLine, slice.len - 1, .{ .value = number } };
            },
            'A'...'Z', 'a'...'z', '_' => {
                for (2..slice.len) |i| {
                    switch (slice[i]) {
                        ' ', '\t', '\r', std.ascii.control_code.vt, std.ascii.control_code.ff => {
                            return .{ FirstPassState.newLine, i, .{ .symbol = slice[1..i] } };
                        },
                        '/' => {
                            return .{ FirstPassState.comment, i, .{ .symbol = slice[1..i] } };
                        },
                        '\n' => {
                            return .{ FirstPassState.search, i, .{ .symbol = slice[1..i] } };
                        },
                        'A'...'Z', 'a'...'z', '0'...'9', '_' => {},
                        else => return error.UnexpectedCharacter,
                    }
                }

                return .{ FirstPassState.newLine, slice.len - 1, .{ .symbol = slice[1..slice.len] } };
            },
            else => return error.UnexpectedCharacter,
        }
    }

    /// Takes in a slice of the buffer that is in the format (......
    /// Returns the next state, position of the ) and a slice that contains the insides of the label
    inline fn label(slice: []const u8) !struct { FirstPassState, u64, []const u8 } {
        std.debug.assert(slice[0] == '(');

        if (slice.len < 3 or !std.ascii.isAlphabetic(slice[1])) return error.@"Unexpected ( found";

        for (2..slice.len) |i| {
            switch (slice[i]) {
                '0'...'9', 'A'...'Z', 'a'...'z', '_' => {},
                ')' => {
                    return .{ FirstPassState.newLine, i, slice[1..i] };
                },
                else => return error.UnexpectedCharacter,
            }
        }

        return error.@"Unexpected ( found";
    }

    inline fn isCInstructionStart(char: u8) bool {
        switch (char) {
            '0'...'9', 'A'...'Z', 'a'...'z', '-', '!' => return true,
            else => return false,
        }
    }
};
