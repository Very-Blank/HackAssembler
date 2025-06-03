const std = @import("std");
const instruction = @import("instruction.zig");
const SecondPass = @import("secondPass.zig").SecondPass;
const SymbolTable = @import("symbolTable.zig").SymbolTable;

// const logger = @import("logger.zig").Logger.init();

const Parser = struct {
    instructions: std.ArrayList(instruction.Instruction),
    symbolTable: SymbolTable,

    i: u64,
    buffer: []const u8,
    currentInstruction: u15,
    currentLine: u64,

    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, buffer: []const u8) Parser {
        var instructions: std.ArrayList(instruction.Instruction) = std.ArrayList(instruction.Instruction).init(allocator);
        errdefer instructions.deinit();

        var symbolTable: SymbolTable = try SymbolTable.init(allocator);
        errdefer symbolTable.deinit();

        return .{
            .instructions = instructions,
            .symbolTable = symbolTable,

            .i = 0,
            .buffer = buffer,
            .currentInstruction = 0,
            .currentLine = 1,
        };
    }

    pub inline fn addInstruction(comptime t: type, parser: *Parser, value: t) !void {
        switch (t) {
            instruction.A => {
                try parser.instructions.append(.{
                    .line = parser.currentLine,
                    .type = .{ .a = value },
                });

                parser.currentInstruction += 1;
            },
            instruction.C => {
                try parser.instructions.append(.{
                    .line = parser.currentLine,
                    .type = .{ .c = value },
                });

                parser.currentInstruction += 1;
            },
            else => @compileError("Type " ++ @typeName(t) ++ " is not supported"),
        }
    }

    pub inline fn next(self: *Parser) bool {
        if (self.i + 1 < self.buffer.len) {
            self.i += 1;
            return true;
        }

        return false;
    }

    pub inline fn comment(self: *Parser) !void {
        std.debug.assert(self.buffer[self.i] == '/');
        if (!self.next() or self.get() != '/') return error.@"Unexpected / found";

        if (self.next()) {
            while (self.i < self.buffer.len) : (self.i += 1) {
                switch (self.get()) {
                    '\n' => {
                        self.currentLine += 1;
                        return;
                    },
                    else => {},
                }
            }
        }
    }

    pub inline fn newLine(self: *Parser) !void {
        while (self.i < self.buffer.len) : (self.i += 1) {
            switch (self.get()) {
                '\n' => {
                    self.currentLine += 1;
                    return;
                },
                '/' => {
                    try self.comment();
                    return;
                },
                ' ', '\t', '\r', std.ascii.control_code.vt, std.ascii.control_code.ff => {},
                else => return error.UnexpectedCharacter,
            }
        }
    }

    pub inline fn get(self: *Parser) u8 {
        return self.buffer[self.i];
    }

    pub fn errDeinit(self: *Parser) void {
        self.instructions.deinit();
        self.symbolTable.deinit();
    }
};

pub const FirstPass = struct {
    destMap: std.StringHashMap(instruction.Destination),
    compMap: std.StringHashMap(instruction.Computation),
    jumpMap: std.StringHashMap(instruction.Jump),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) !FirstPass {
        var first: FirstPass = .{
            .destMap = std.StringHashMap(instruction.Destination).init(allocator),
            .compMap = std.StringHashMap(instruction.Computation).init(allocator),
            .jumpMap = std.StringHashMap(instruction.Jump).init(allocator),
            .allocator = allocator,
        };

        errdefer first.deinit();

        inline for (@typeInfo(instruction.Destination).@"enum".fields) |dest| {
            try first.destMap.put(dest.name, @field(instruction.Destination, dest.name));
        }

        inline for (@typeInfo(instruction.Computation).@"enum".fields) |comp| {
            try first.compMap.put(comp.name, @field(instruction.Computation, comp.name));
        }

        inline for (@typeInfo(instruction.Jump).@"enum".fields) |jump| {
            try first.jumpMap.put(jump.name, @field(instruction.Jump, jump.name));
        }

        return first;
    }

    pub fn deinit(self: *FirstPass) void {
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
    pub fn firstPass(self: *const FirstPass, buffer: []const u8) !SecondPass {
        var instructions: std.ArrayList(instruction.Instruction) = std.ArrayList(instruction.Instruction).init(self.allocator);
        errdefer instructions.deinit();

        var symbolTable: SymbolTable = try SymbolTable.init(self.allocator);
        errdefer symbolTable.deinit();

        var currentInstruction: u15 = 0;
        var currentLine: u64 = 1;

        var parser: Parser = Parser.init(self.allocator, buffer);

        var i: u64 = 0;
        while (i < buffer.len) : (i += 1) {}

        state: switch (FirstPassState.search) {
            .newLine => {
                while (i < buffer.len) : (i += 1) {
                    switch (buffer[i]) {
                        '\n' => {
                            continue :state .search;
                        },
                        '/' => {
                            continue :state .comment;
                        },
                        ' ', '\t', '\r', std.ascii.control_code.vt, std.ascii.control_code.ff => {},
                        else => return error.UnexpectedCharacter,
                    }
                }
            },
            .comment => {
                std.debug.assert(buffer[i] == '/');
                if (i + 1 < buffer.len and buffer[i + 1] == '/') {
                    i += 1;
                    while (i < buffer.len) : (i += 1) {
                        if (buffer[i] == '\n') {
                            continue :state .search;
                        }
                    }
                } else {
                    return error.@"Unexpected / found";
                }
            },
            .search => {
                while (i < buffer.len) : (i += 1) {
                    switch (buffer[i]) {
                        '/' => {
                            continue :state .comment;
                        },
                        ' ', '\t', '\r', std.ascii.control_code.vt, std.ascii.control_code.ff => {},
                        '\n' => {
                            currentLine += 1;
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
                            const pos, const insides = try label(buffer[i..buffer.len]);
                            i += pos;

                            try symbolTable.labels.put(insides, currentInstruction);

                            if (i < buffer.len) {
                                continue :state .newLine;
                            } else break :state;
                        },
                        else => {
                            return error.UnexpectedCharacter;
                        },
                    }
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
    inline fn cInstruction(self: *const FirstPass, slice: []const u8) !struct { FirstPassState, u64, instruction.C } {
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
                '\n', '/' => return error.NoStartForSlice,
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
    inline fn aInstruction(parser: *Parser) !struct { FirstPassState, u64, instruction.A } {
        std.debug.assert(parser.buffer[parser.i] == '@');

        if (parser.next()) {
            switch (parser.get()) {
                '0' => {
                    if (parser.next()) {
                        switch (parser.get()) {
                            ' ', '\t', '\r', std.ascii.control_code.vt, std.ascii.control_code.ff => {
                                parser.addInstruction(instruction.A, .{ .value = 0 });
                                try parser.newLine();
                                return;
                            },
                            '/' => {
                                parser.addInstruction(instruction.A, .{ .value = 0 });
                                try parser.comment();
                                return;
                            },
                            '\n' => {
                                parser.addInstruction(instruction.A, .{ .value = 0 });
                                parser.currentLine += 1;
                                return;
                            },
                            else => return error.UnexpectedCharacter,
                        }
                    }

                    parser.addInstruction(instruction.A, .{ .value = 0 });
                    return;
                },
                '1'...'9' => |firstNum| {
                    var number: u15 = @intCast(firstNum - '0');

                    if (parser.next()) {
                        while (parser.i < parser.buffer.len) : (parser.i += 1) {
                            switch (parser.get()) {
                                ' ', '\t', '\r', std.ascii.control_code.vt, std.ascii.control_code.ff => {
                                    parser.addInstruction(instruction.A, .{ .value = number });
                                    try parser.newLine();
                                    return;
                                },
                                '0'...'9' => |num| {
                                    number = number * 10 + @as(u15, @intCast((num - '0')));
                                },
                                '/' => {
                                    parser.addInstruction(instruction.A, .{ .value = number });
                                    try parser.comment();
                                    return;
                                },
                                '\n' => {
                                    parser.addInstruction(instruction.A, .{ .value = number });
                                    return;
                                },
                                else => return error.UnexpectedCharacter,
                            }
                        }
                    }

                    parser.addInstruction(instruction.A, .{ .value = number });
                    return;
                },
                'A'...'Z', 'a'...'z', '_' => {
                    const start = parser.i;
                    if (parser.next()) {
                        while (parser.i < parser.buffer.len) : (parser.i += 1) {
                            switch (parser.get()) {
                                ' ', '\t', '\r', std.ascii.control_code.vt, std.ascii.control_code.ff => {
                                    parser.addInstruction(instruction.A, .{ .symbol = parser.buffer[start..parser.i] });
                                    try parser.newLine();
                                    return;
                                },
                                '/' => {
                                    parser.addInstruction(instruction.A, .{ .symbol = parser.buffer[start..parser.i] });
                                    try parser.comment();
                                    return;
                                },
                                '\n' => {
                                    parser.addInstruction(instruction.A, .{ .symbol = parser.buffer[start..parser.i] });
                                    parser.currentLine += 1;
                                    return;
                                },
                                'A'...'Z', 'a'...'z', '0'...'9', '_' => {},
                                else => return error.UnexpectedCharacter,
                            }
                        }
                    }

                    parser.addInstruction(instruction.A, .{ .symbol = parser.buffer[start..parser.i] });
                    return;
                },
                else => return error.UnexpectedCharacter,
            }
        }

        return error.@"Unexpected @ found";
    }

    /// Takes in a slice of the buffer that is in the format (......
    inline fn label(parser: *Parser) !void {
        std.debug.assert(parser.get() == '(');
        if (!parser.next() or !std.ascii.isAlphabetic(parser.get())) return error.@"Unexpected ( found";

        const start = parser.i;

        if (parser.next()) {
            while (parser.i < parser.buffer.len) : (parser.i += 1) {
                switch (parser.get()) {
                    '0'...'9', 'A'...'Z', 'a'...'z', '_' => {},
                    ')' => {
                        try parser.symbolTable.labels.put(parser.buffer[start..parser.i], parser.currentInstruction);
                        if (parser.next()) {
                            try parser.newLine();
                        }

                        return;
                    },
                    else => return error.UnexpectedCharacter,
                }
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
