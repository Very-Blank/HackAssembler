const std = @import("std");
const Instruction = @import("instruction.zig").Instruction;
const SymbolTable = @import("symbolTable.zig").SymbolTable;

pub const FirstPass = struct {
    instructions: []Instruction,
    symbolTable: SymbolTable,
    allocator: std.mem.Allocator,

    pub fn deinit(self: *FirstPass) void {
        self.allocator.free(self.instructions);
        self.symbolTable.deinit();
    }
};
