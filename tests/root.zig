const std = @import("std");

pub const vector_test = @import("vector_test.zig");
pub const quad_tree_test = @import("quad_tree_test.zig");
pub const sweep_and_prune_test = @import("sweep_and_prune_test.zig");
pub const sparse_set_test = @import("sparse_set_test.zig");
pub const z_index_buckets_test = @import("z_index_buckets_test.zig");
pub const floyd_warshall_test = @import("floyd_warshall_test.zig");
pub const floyd_warshall_optimized_test = @import("floyd_warshall_optimized_test.zig");
pub const a_star_test = @import("a_star_test.zig");
pub const heuristics_test = @import("heuristics_test.zig");
pub const zon_coercion_test = @import("zon_coercion_test.zig");

test {
    std.testing.refAllDeclsRecursive(@This());
}
