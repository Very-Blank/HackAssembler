const std = @import("std");

pub const SymbolTable = struct {
    labels: std.StringHashMap(u15),
    addresses: std.StringHashMap(u15),
    variableCount: u15 = 15,

    pub fn init(allocator: std.mem.Allocator) !SymbolTable {
        var symbolTable: SymbolTable = .{
            .labels = std.StringHashMap(u15).init(allocator),
            .addresses = std.StringHashMap(u15).init(allocator),
        };

        errdefer symbolTable.deinit();

        try symbolTable.addresses.put("SP", 0);
        try symbolTable.addresses.put("LCL", 1);
        try symbolTable.addresses.put("ARG", 2);
        try symbolTable.addresses.put("THIS", 3);
        try symbolTable.addresses.put("THAT", 4);

        try symbolTable.addresses.put("SCREEN", 0b100000000000000);
        try symbolTable.addresses.put("THAT", 0b110000000000000);

        inline for (0..16) |i| {
            try symbolTable.addresses.put("R" ++ std.fmt.comptimePrint("{any}", .{i}), i);
        }

        return symbolTable;
    }

    pub fn addVariable(self: *SymbolTable, symbol: []const u8) !u15 {
        self.variableCount += 1;

        try self.addresses.put(symbol, self.variableCount);
        return self.variableCount;
    }

    pub fn deinit(self: *SymbolTable) void {
        self.labels.deinit();
        self.addresses.deinit();
    }
};
