const std = @import("std");

pub const vector_test = @import("vector_test.zig");
pub const quad_tree_test = @import("quad_tree_test.zig");

test {
    std.testing.refAllDeclsRecursive(@This());
}
