const std = @import("std");
const instruction = @import("instruction.zig");
const SecondPass = @import("secondPass.zig").SecondPass;
const SymbolTable = @import("symbolTable.zig").SymbolTable;
const Parser = @import("parser.zig").Parser;

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

    /// FirstPass could contain pointers to the given buffer.
    pub fn firstPass(self: *const FirstPass, buffer: []const u8) !SecondPass {
        var parser: Parser = try Parser.init(self.allocator, buffer);
        errdefer parser.errDeinit();

        while (parser.i < parser.buffer.len) : (parser.i += 1) {
            switch (parser.get()) {
                '/' => {
                    try parser.comment();
                },
                ' ', '\t', '\r', std.ascii.control_code.vt, std.ascii.control_code.ff => {},
                '\n' => {
                    parser.changeCurrentLine();
                },
                '@' => {
                    try parser.aInstruction();
                },
                '0'...'9', 'A'...'Z', 'a'...'z', '-', '!' => {
                    try parser.cInstruction(self);
                },
                '(' => {
                    try parser.label();
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
