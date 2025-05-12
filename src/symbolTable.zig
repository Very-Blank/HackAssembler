const std = @import("std");

const SymbolTable = struct {
    // Altough they could be in the same hashmap, since they mean different things I will keep them seperate.
    labels: std.StringHashMap(u64),
    varibales: std.StringHashMap(u64),
};
