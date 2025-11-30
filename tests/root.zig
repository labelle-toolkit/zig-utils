const std = @import("std");

test {
    std.testing.refAllDecls(@This());
    _ = @import("vector_test.zig");
    _ = @import("quad_tree_test.zig");
}
