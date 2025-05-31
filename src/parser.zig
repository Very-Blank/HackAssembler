const std = @import("std");
const instruction = @import("instruction.zig");
const SecondPass = @import("secondPass.zig").SecondPass;
const SymbolTable = @import("symbolTable.zig").SymbolTable;

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

    const FirstPassState = enum {
        newLine,
        comment,
        search,
    };

    /// FirstPass could contain pointers to the given buffer.
    pub fn firstPass(self: *const Parser, buffer: []const u8) !SecondPass {
        var instructions: std.ArrayList(instruction.Instruction) = std.ArrayList(instruction.Instruction).init(self.allocator);
        errdefer instructions.deinit();

        var symbolTable: SymbolTable = SymbolTable.init(self.allocator);
        errdefer symbolTable.deinit();

        var currentInstruction: u64 = 0;
        var currentLine: u64 = 1;

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

                        try instructions.append(.{
                            .line = currentLine,
                            .type = .{ .a = a },
                        });

                        currentInstruction += 1;

                        if (i < buffer.len) {
                            continue :state nextState;
                        } else break :state;
                    },
                    '0'...'9', 'A'...'Z', 'a'...'z', '-', '!' => {
                        const nextState, const pos, const c = try self.cInstruction(buffer[i..buffer.len]);
                        i += pos;

                        try instructions.append(.{
                            .line = currentLine,
                            .type = .{ .c = c },
                        });

                        currentInstruction += 1;

                        if (i < buffer.len) {
                            continue :state nextState;
                        } else break :state;
                    },
                    '(' => {
                        const nextState, const pos, const insides = try label(buffer[i..buffer.len]);
                        i += pos;

                        try symbolTable.labels.put(insides, @as(u15, @intCast(currentInstruction)));

                        if (i + 1 < buffer.len) {
                            i += 1;
                            continue :state nextState;
                        } else break :state;
                    },
                    else => {
                        return error.UnexpectedCharacter;
                    },
                }
            },
        }

        return .{
            .symbolTable = symbolTable,
            .instructions = try instructions.toOwnedSlice(),
            .allocator = self.allocator,
        };
    }

    /// Position might be end of the slice!
    inline fn cInstruction(self: *const Parser, slice: []const u8) !struct { FirstPassState, u64, instruction.C } {
        std.debug.assert(isCInstructionStart(slice[0]));

        var dest: ?[]const u8 = null;
        var comp: ?[]const u8 = null;
        var jump: ?[]const u8 = null;

        var nextFirstPassState: FirstPassState = .search;

        var splitter: SliceSplitter, var end, const current: []const u8 = try lookForSlice(slice);

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
                        ' ', '\t', '\r', std.ascii.control_code.vt, std.ascii.control_code.ff => {},
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
                        else => return error.UnexpectedCharacter,
                    }
                }

                return error.UnexpectedCharacter;
            },
            else => return error.UnexpectedCharacter,
        }

        state: switch (splitter) {
            .@";" => {
                if (slice.len < end + 1) return error.UnexpectedCharacter;
                end += 1;

                splitter, const j, jump = try lookForSlice(slice[end..slice.len]);
                end += j;

                switch (splitter) {
                    .@"\n", .EOF => {
                        break :state;
                    },
                    .@"/" => {
                        nextFirstPassState = .comment;
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
                                else => return error.UnexpectedCharacter,
                            }
                        }
                    },
                    else => return error.UnexpectedCharacter,
                }
            },
            .@"=" => {
                if (slice.len < end + 1) return error.UnexpectedCharacter;
                end += 1;

                splitter, const j, comp = try lookForSlice(slice[end..slice.len]);
                end += j;

                switch (splitter) {
                    .@";" => continue :state .@";",
                    .@"\n" => break :state,
                    .@"/" => {
                        nextFirstPassState = .comment;
                        break :state;
                    },
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
                                else => return error.UnexpectedCharacter,
                            }
                        }

                        return error.UnexpectedCharacter;
                    },
                    else => return error.UnexpectedCharacter,
                }
            },
            else => return error.UnexpectedCharacter,
        }

        if (dest != null and comp != null and jump != null) {
            const cDest = if (dest) |value| value else unreachable;
            const cComp = if (comp) |value| value else unreachable;
            const cJump = if (jump) |value| value else unreachable;

            return .{
                nextFirstPassState, end, instruction.C{
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
                nextFirstPassState, end, instruction.C{
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
                nextFirstPassState, end, instruction.C{
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
        EOF,
        @";",
        @"/",
        @"\n",
        @"=",
        space,
    };

    /// Returns the splitter that split the slice, the end position of the splitter and the new slice.
    /// IF THE SLICE ENDS before finding splitter, the end position will be slice.len!
    inline fn lookForSlice(slice: []const u8) !struct { SliceSplitter, u64, []const u8 } {
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
                    return .{ SliceSplitter.space, i, slice[start..i] };
                },
                '\n' => {
                    return .{ SliceSplitter.@"\n", i, slice[start..i] };
                },
                '=' => {
                    return .{ SliceSplitter.@"=", i, slice[start..i] };
                },
                ';' => {
                    return .{ SliceSplitter.@";", i, slice[start..i] };
                },
                '/' => {
                    return .{ SliceSplitter.@"/", i, slice[start..i] };
                },
                else => {},
            }
        }

        return .{ SliceSplitter.EOF, slice.len, slice[start..slice.len] };
    }

    /// Takes in a slice of the buffer that is in the format @......
    /// Returns the next state, position of the ending character (whitespace, buffer end, /) and the instruction.
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
                var number: u15 = @intCast(firstNum - '0');

                for (2..slice.len) |i| {
                    switch (slice[i]) {
                        ' ', '\t', '\r', std.ascii.control_code.vt, std.ascii.control_code.ff => {
                            return .{ FirstPassState.newLine, i, .{ .value = number } };
                        },
                        '0'...'9' => |num| {
                            number = number * 10 + @as(u15, @intCast((num - '0')));
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

                return .{ FirstPassState.newLine, slice.len, .{ .value = number } };
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

                return .{ FirstPassState.newLine, slice.len, .{ .symbol = slice[1..slice.len] } };
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
