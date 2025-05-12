const std = @import("std");
const Instruction = @import("instruction.zig").Instruction;
const SymbolTable = @import("symbolTable.zig").SymbolTable;

pub const FirstPass = struct {
    instructions: []Instruction,
    symbolTable: SymbolTable,
};
