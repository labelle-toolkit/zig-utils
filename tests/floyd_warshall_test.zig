const std = @import("std");
const expect = @import("zspec").expect;
const zig_utils = @import("zig_utils");
const FloydWarshall = zig_utils.FloydWarshall;

pub const FloydWarshallSpec = struct {
    pub const basic_functionality = struct {
        test "computes distances for linear graph" {
            const allocator = std.testing.allocator;

            var fw = FloydWarshall(u64).init(allocator);
            defer fw.deinit();

            fw.resize(4);
            try fw.clean();

            // Create graph: 0 -> 1 -> 2 -> 3
            fw.addEdge(0, 1, 1);
            fw.addEdge(1, 2, 1);
            fw.addEdge(2, 3, 1);

            fw.generate();

            try expect.equal(fw.value(0, 0), 0);
            try expect.equal(fw.value(0, 1), 1);
            try expect.equal(fw.value(0, 2), 2);
            try expect.equal(fw.value(0, 3), 3);
        }

        test "computes next hops correctly" {
            const allocator = std.testing.allocator;

            var fw = FloydWarshall(u64).init(allocator);
            defer fw.deinit();

            fw.resize(4);
            try fw.clean();

            fw.addEdge(0, 1, 1);
            fw.addEdge(1, 2, 1);
            fw.addEdge(2, 3, 1);

            fw.generate();

            try expect.equal(fw.next(0, 3), 1);
            try expect.equal(fw.next(1, 3), 2);
        }
    };

    pub const weighted_shortest_path = struct {
        test "finds shorter path through intermediate node" {
            const allocator = std.testing.allocator;

            var fw = FloydWarshall(u64).init(allocator);
            defer fw.deinit();

            fw.resize(4);
            try fw.clean();

            // Graph with two paths to node 3:
            // 0 --5--> 1 --3--> 3  (total: 8)
            // 0 --2--> 2 --2--> 3  (total: 4) <- shorter
            fw.addEdge(0, 1, 5);
            fw.addEdge(1, 3, 3);
            fw.addEdge(0, 2, 2);
            fw.addEdge(2, 3, 2);

            fw.generate();

            try expect.equal(fw.value(0, 3), 4);
            try expect.equal(fw.next(0, 3), 2);
        }
    };

    pub const different_distance_types = struct {
        test "works with u32 distances" {
            const allocator = std.testing.allocator;

            var fw = FloydWarshall(u32).init(allocator);
            defer fw.deinit();

            fw.resize(3);
            try fw.clean();

            fw.addEdge(0, 1, 10);
            fw.addEdge(1, 2, 20);

            fw.generate();

            try expect.equal(fw.value(0, 2), 30);
        }
    };
};
