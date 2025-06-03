const std = @import("std");
const instruction = @import("instruction.zig");
const SymbolTable = @import("symbolTable.zig").SymbolTable;
const FirstPass = @import("firstPass.zig").FirstPass;

const SliceSplitter = enum {
    EOF,
    @";",
    @"/",
    @"\n",
    @"=",
    space,
};

pub const Parser = struct {
    instructions: std.ArrayList(instruction.Instruction),
    symbolTable: SymbolTable,

    i: u64 = 0,
    buffer: []const u8,
    currentInstruction: u15 = 0,
    currentLine: u64 = 0,
    currentLineStart: u64 = 0,

    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, buffer: []const u8) !Parser {
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
            .currentLineStart = 0,

            .allocator = allocator,
        };
    }

    pub inline fn addInstruction(self: *Parser, comptime t: type, value: t) !void {
        switch (t) {
            instruction.A => {
                try self.instructions.append(.{
                    .line = self.currentLine,
                    .type = .{ .a = value },
                });

                self.currentInstruction += 1;
            },
            instruction.C => {
                try self.instructions.append(.{
                    .line = self.currentLine,
                    .type = .{ .c = value },
                });

                self.currentInstruction += 1;
            },
            else => @compileError("Type " ++ @typeName(t) ++ " is not supported"),
        }
    }

    pub inline fn aInstruction(self: *Parser) !void {
        std.debug.assert(self.get() == '@');

        if (self.next()) {
            switch (self.get()) {
                '0' => {
                    if (self.next()) {
                        switch (self.get()) {
                            ' ', '\t', '\r', std.ascii.control_code.vt, std.ascii.control_code.ff => {
                                try self.addInstruction(instruction.A, .{ .value = 0 });
                                try self.newLine();
                                return;
                            },
                            '/' => {
                                try self.addInstruction(instruction.A, .{ .value = 0 });
                                try self.comment();
                                return;
                            },
                            '\n' => {
                                try self.addInstruction(instruction.A, .{ .value = 0 });
                                self.changeCurrentLine();
                                return;
                            },
                            else => return error.UnexpectedCharacter,
                        }
                    }

                    try self.addInstruction(instruction.A, .{ .value = 0 });
                    return;
                },
                '1'...'9' => |firstNum| {
                    var number: u15 = @intCast(firstNum - '0');

                    if (self.next()) {
                        while (self.i < self.buffer.len) : (self.i += 1) {
                            switch (self.get()) {
                                ' ', '\t', '\r', std.ascii.control_code.vt, std.ascii.control_code.ff => {
                                    try self.addInstruction(instruction.A, .{ .value = number });
                                    try self.newLine();
                                    return;
                                },
                                '0'...'9' => |num| {
                                    number = number * 10 + @as(u15, @intCast((num - '0')));
                                },
                                '/' => {
                                    try self.addInstruction(instruction.A, .{ .value = number });
                                    try self.comment();
                                    return;
                                },
                                '\n' => {
                                    try self.addInstruction(instruction.A, .{ .value = number });
                                    self.changeCurrentLine();
                                    return;
                                },
                                else => return error.UnexpectedCharacter,
                            }
                        }
                    }

                    try self.addInstruction(instruction.A, .{ .value = number });
                    return;
                },
                'A'...'Z', 'a'...'z', '_' => {
                    const start = self.i;
                    if (self.next()) {
                        while (self.i < self.buffer.len) : (self.i += 1) {
                            switch (self.get()) {
                                ' ', '\t', '\r', std.ascii.control_code.vt, std.ascii.control_code.ff => {
                                    try self.addInstruction(instruction.A, .{ .symbol = self.buffer[start..self.i] });
                                    try self.newLine();
                                    return;
                                },
                                '/' => {
                                    try self.addInstruction(instruction.A, .{ .symbol = self.buffer[start..self.i] });
                                    try self.comment();
                                    return;
                                },
                                '\n' => {
                                    try self.addInstruction(instruction.A, .{ .symbol = self.buffer[start..self.i] });
                                    self.changeCurrentLine();
                                    return;
                                },
                                'A'...'Z', 'a'...'z', '0'...'9', '_' => {},
                                else => return error.UnexpectedCharacter,
                            }
                        }
                    }

                    try self.addInstruction(instruction.A, .{ .symbol = self.buffer[start..self.i] });
                    return;
                },
                else => return error.UnexpectedCharacter,
            }
        }

        return error.@"Unexpected @ found";
    }

    inline fn isCInstructionStart(char: u8) bool {
        switch (char) {
            '0'...'9', 'A'...'Z', 'a'...'z', '-', '!' => return true,
            else => return false,
        }
    }

    inline fn toCInstruction(first: *const FirstPass, dest: ?[]const u8, comp: ?[]const u8, jump: ?[]const u8) !instruction.C {
        if (dest != null and comp != null and jump != null) {
            const cDest = if (dest) |value| value else unreachable;
            const cComp = if (comp) |value| value else unreachable;
            const cJump = if (jump) |value| value else unreachable;

            return instruction.C{
                .dcj = .{
                    .dest = if (first.destMap.get(cDest)) |value| value else return error.InvalidDestination,
                    .comp = if (first.compMap.get(cComp)) |value| value else return error.InvalidComputation,
                    .jump = if (first.jumpMap.get(cJump)) |value| value else return error.InvalidJump,
                },
            };
        } else if (dest != null and comp != null and jump == null) {
            const cDest = if (dest) |value| value else unreachable;
            const cComp = if (comp) |value| value else unreachable;

            return instruction.C{
                .dc = .{
                    .dest = if (first.destMap.get(cDest)) |value| value else return error.InvalidDestination,
                    .comp = if (first.compMap.get(cComp)) |value| value else return error.InvalidComputation,
                },
            };
        }

        const cComp = if (comp) |value| value else unreachable;
        const cJump = if (jump) |value| value else unreachable;

        return instruction.C{
            .cj = .{
                .comp = if (first.compMap.get(cComp)) |value| value else return error.InvalidComputation,
                .jump = if (first.jumpMap.get(cJump)) |value| value else return error.InvalidJump,
            },
        };
    }

    pub inline fn cInstruction(self: *Parser, first: *const FirstPass) !void {
        std.debug.assert(isCInstructionStart(self.get()));

        var dest: ?[]const u8 = null;
        var comp: ?[]const u8 = null;
        var jump: ?[]const u8 = null;

        var splitter: SliceSplitter, const current: []const u8 = try self.lookForSlice();

        init: switch (splitter) {
            .@";" => {
                comp = current;
            },
            .@"=" => {
                dest = current;
            },
            .space => {
                while (self.i < self.buffer.len) : (self.i += 1) {
                    switch (self.get()) {
                        ' ', '\t', '\r', std.ascii.control_code.vt, std.ascii.control_code.ff => {},
                        ';' => {
                            splitter = .@";";
                            comp = current;
                            break :init;
                        },
                        '=' => {
                            splitter = .@"=";
                            dest = current;
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
                if (!self.next()) return error.UnexpectedCharacter;

                splitter, jump = try self.lookForSlice();

                switch (splitter) {
                    .EOF => {
                        try self.addInstruction(instruction.C, try toCInstruction(first, dest, comp, jump));
                        return;
                    },
                    .@"\n" => {
                        try self.addInstruction(instruction.C, try toCInstruction(first, dest, comp, jump));
                        self.changeCurrentLine();
                        return;
                    },
                    .@"/" => {
                        try self.addInstruction(instruction.C, try toCInstruction(first, dest, comp, jump));
                        try self.comment();
                        return;
                    },
                    .space => {
                        while (self.i < self.buffer.len) : (self.i += 1) {
                            switch (self.get()) {
                                '\n' => {
                                    try self.addInstruction(instruction.C, try toCInstruction(first, dest, comp, jump));
                                    self.changeCurrentLine();
                                    return;
                                },
                                '/' => {
                                    try self.addInstruction(instruction.C, try toCInstruction(first, dest, comp, jump));
                                    try self.comment();
                                    return;
                                },
                                ' ', '\t', '\r', std.ascii.control_code.vt, std.ascii.control_code.ff => {},
                                else => return error.UnexpectedCharacter,
                            }
                        }
                    },
                    else => return error.UnexpectedCharacter,
                }

                return error.UnexpectedCharacter;
            },
            .@"=" => {
                if (!self.next()) return error.UnexpectedCharacter;

                splitter, comp = try self.lookForSlice();

                switch (splitter) {
                    .@";" => continue :state .@";",
                    .@"\n" => {
                        try self.addInstruction(instruction.C, try toCInstruction(first, dest, comp, jump));
                        self.changeCurrentLine();
                        return;
                    },
                    .@"/" => {
                        try self.addInstruction(instruction.C, try toCInstruction(first, dest, comp, jump));
                        try self.comment();
                        return;
                    },
                    .space => {
                        while (self.i < self.buffer.len) : (self.i += 1) {
                            switch (self.get()) {
                                ' ', '\t', '\r', std.ascii.control_code.vt, std.ascii.control_code.ff => {},
                                '\n' => {
                                    try self.addInstruction(instruction.C, try toCInstruction(first, dest, comp, jump));
                                    self.changeCurrentLine();
                                    return;
                                },
                                '/' => {
                                    try self.addInstruction(instruction.C, try toCInstruction(first, dest, comp, jump));
                                    try self.comment();
                                    return;
                                },
                                ';' => {
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

        unreachable;
    }

    inline fn lookForSlice(parser: *Parser) !struct { SliceSplitter, []const u8 } {
        var start: u64 = 0;
        while (parser.i < parser.buffer.len) : (parser.i += 1) {
            switch (parser.get()) {
                ' ', '\t', '\r', std.ascii.control_code.vt, std.ascii.control_code.ff => {},
                '\n', '/' => return error.NoStartForSlice,
                else => {
                    start = parser.i;
                    break;
                },
            }
        }

        while (parser.i < parser.buffer.len) : (parser.i += 1) {
            switch (parser.get()) {
                ' ', '\t', '\r', std.ascii.control_code.vt, std.ascii.control_code.ff => {
                    return .{ SliceSplitter.space, parser.buffer[start..parser.i] };
                },
                '\n' => {
                    return .{ SliceSplitter.@"\n", parser.buffer[start..parser.i] };
                },
                '=' => {
                    return .{ SliceSplitter.@"=", parser.buffer[start..parser.i] };
                },
                ';' => {
                    return .{ SliceSplitter.@";", parser.buffer[start..parser.i] };
                },
                '/' => {
                    return .{ SliceSplitter.@"/", parser.buffer[start..parser.i] };
                },
                else => {},
            }
        }

        return .{ SliceSplitter.EOF, parser.buffer[start..parser.buffer.len] };
    }

    /// Takes in a slice of the buffer that is in the format (......
    pub inline fn label(self: *Parser) !void {
        std.debug.assert(self.get() == '(');
        if (!self.next() or !std.ascii.isAlphabetic(self.get())) return error.@"Unexpected ( found";

        const start = self.i;

        if (self.next()) {
            while (self.i < self.buffer.len) : (self.i += 1) {
                switch (self.get()) {
                    '0'...'9', 'A'...'Z', 'a'...'z', '_' => {},
                    ')' => {
                        try self.symbolTable.labels.put(self.buffer[start..self.i], self.currentInstruction);
                        if (self.next()) {
                            try self.newLine();
                        }

                        return;
                    },
                    else => return error.UnexpectedCharacter,
                }
            }
        }

        return error.@"Unexpected ( found";
    }

    pub inline fn changeCurrentLine(self: *Parser) void {
        if (self.hasNext()) {
            self.currentLine += 1;
            self.currentLineStart = self.i + 1;
        }
    }

    pub inline fn hasNext(self: *Parser) bool {
        if (self.i + 1 < self.buffer.len) {
            return true;
        }

        return false;
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
                        self.changeCurrentLine();
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
                    self.changeCurrentLine();
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
