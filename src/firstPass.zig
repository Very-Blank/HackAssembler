const std = @import("std");
const instruction = @import("instruction.zig");
const SecondPass = @import("secondPass.zig").SecondPass;
const SymbolTable = @import("symbolTable.zig").SymbolTable;
const Parser = @import("parser.zig").Parser;
const Logger = @import("logger.zig").Logger;

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

    /// SecondPass could contain pointers to the given buffer.
    pub fn firstPass(self: *const FirstPass, buffer: []const u8, logger: *const Logger) !SecondPass {
        var parser: Parser = try Parser.init(self.allocator, buffer);
        errdefer parser.errDeinit();

        while (parser.i < parser.buffer.len) : (parser.i += 1) {
            switch (parser.get()) {
                '/' => {
                    parser.comment() catch |err| {
                        switch (err) {
                            error.@"Expected a comment but only found /" => {
                                try logger.printError("{s}, on line {any}\n", .{ @errorName(err), parser.currentLine });
                                try logger.highlightError(parser.buffer, parser.currentLineStart, parser.i);
                            },
                        }

                        return err;
                    };
                    // logger.printError("{s}");
                },
                ' ', '\t', '\r', std.ascii.control_code.vt, std.ascii.control_code.ff => {},
                '\n' => {
                    parser.changeCurrentLine();
                },
                '@' => {
                    parser.aInstruction() catch |err| {
                        switch (err) {
                            error.UnexpectedCharacter,
                            error.@"Was expecting a new line, but found unexpected character",
                            error.@"Expected a comment but only found /",
                            error.@"Unexpected @ found",
                            => {
                                try logger.printError("{s}, on line {any}:\n", .{ @errorName(err), parser.currentLine });
                                try logger.highlightError(parser.buffer, parser.currentLineStart, parser.i);
                            },
                            else => {},
                        }

                        return err;
                    };
                },
                '0'...'9', 'A'...'Z', 'a'...'z', '-', '!' => {
                    parser.cInstruction(self) catch |err| {
                        switch (err) {
                            error.UnexpectedCharacter,
                            error.@"Expected a comment but only found /",
                            => {
                                try logger.printError("{s}, on line {any}:\n", .{ @errorName(err), parser.currentLine });
                                try logger.highlightError(parser.buffer, parser.currentLineStart, parser.i);
                            },
                            else => {},
                        }

                        return err;
                    };
                },
                '(' => {
                    parser.label() catch |err| {
                        switch (err) {
                            error.UnexpectedCharacter,
                            error.@"Unexpected ( found",
                            error.@"Was expecting a new line, but found unexpected character",
                            => {
                                try logger.printError("{s}, on line {any}:\n", .{ @errorName(err), parser.currentLine });
                                try logger.highlightError(parser.buffer, parser.currentLineStart, parser.i);
                            },
                            else => {},
                        }

                        return err;
                    };
                },
                else => {
                    return error.UnexpectedCharacter;
                },
            }
        }

        return .{
            .symbolTable = parser.symbolTable,
            .instructions = try parser.instructions.toOwnedSlice(),
            .allocator = self.allocator,
        };
    }
};
