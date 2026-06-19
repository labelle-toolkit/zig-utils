const std = @import("std");
const zig_utils = @import("zig_utils");

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

// std's `refAllDecls` is ONE level deep — it references the imported test
// structs above, but NOT the `pub const FooSpec = struct { pub const group =
// struct { test "..." {} } }` groups nested inside them. Under Zig 0.16 a
// `test` block is only collected into the test binary once its containing
// struct is semantically analyzed, so every doubly-nested zspec test was
// silently never run, and `zig build test` passed even with a failing
// assertion (#14). Recurse into every nested container type so each group
// struct is analyzed and its tests get collected. (Zig 0.16 dropped
// `std.testing.refAllDeclsRecursive`, hence the local copy.)
fn refAllDeclsRecursive(comptime T: type) void {
    if (!@import("builtin").is_test) return;
    inline for (comptime std.meta.declarations(T)) |decl| {
        const field = @field(T, decl.name);
        if (@TypeOf(field) == type) {
            switch (@typeInfo(field)) {
                .@"struct", .@"enum", .@"union", .@"opaque" => refAllDeclsRecursive(field),
                else => {},
            }
        }
        _ = &@field(T, decl.name);
    }
}

test {
    refAllDeclsRecursive(@This());
}

// Regression for #13 — kept at the test ROOT (top-level) on purpose: the
// zspec runner does not currently execute tests nested inside the `*Spec`
// structs under `zig build test`, so a nested test would compile but never
// run. The parallel `generate()` barrier was not a full barrier, so threads
// read a not-yet-finalized pivot row and corrupted `dist`/`next` into cycles
// (→ infinite path reconstruction, hang + OOM on a 1000-worker colony). This
// asserts the parallel result is bit-identical to the scalar reference.
test "parallel Floyd-Warshall matches scalar reference (issue #13)" {
    const allocator = std.testing.allocator;
    const FloydWarshallParallel = zig_utils.FloydWarshallParallel;
    const FloydWarshallScalar = zig_utils.FloydWarshallScalar;
    const N: u32 = 256; // > 64 → parallel path on multi-core
    const matrix = @as(usize, N) * @as(usize, N);

    for (0..24) |seed| {
        var par = FloydWarshallParallel.init(allocator);
        defer par.deinit();
        var scal = FloydWarshallScalar.init(allocator);
        defer scal.deinit();
        par.resize(N);
        try par.clean();
        scal.resize(N);
        try scal.clean();

        var rng = std.Random.DefaultPrng.init(0xF00D +% seed);
        const r = rng.random();
        var e: usize = 0;
        while (e < N * 4) : (e += 1) {
            const u = r.intRangeLessThan(u32, 0, N);
            const v = r.intRangeLessThan(u32, 0, N);
            if (u == v) continue;
            const w = r.intRangeLessThan(u32, 1, 20);
            par.addEdge(u, v, w);
            scal.addEdge(u, v, w);
        }

        par.generate();
        scal.generate();

        try std.testing.expectEqualSlices(u32, scal.dist[0..matrix], par.dist[0..matrix]);
        try std.testing.expectEqualSlices(u32, scal.next[0..matrix], par.next[0..matrix]);
    }
}
