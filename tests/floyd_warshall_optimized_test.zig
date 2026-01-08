const std = @import("std");
const expect = @import("zspec").expect;
const zig_utils = @import("zig_utils");
const FloydWarshallSimd = zig_utils.FloydWarshallSimd;

pub const FloydWarshallOptimizedSpec = struct {
    pub const basic_functionality = struct {
        test "computes distances for linear graph" {
            const allocator = std.testing.allocator;

            var fw = FloydWarshallSimd.init(allocator);
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

            var fw = FloydWarshallSimd.init(allocator);
            defer fw.deinit();

            fw.resize(4);
            try fw.clean();

            fw.addEdge(0, 1, 1);
            fw.addEdge(1, 2, 1);
            fw.addEdge(2, 3, 1);

            fw.generate();

            try expect.equal(fw.getNext(0, 3), 1);
            try expect.equal(fw.getNext(1, 3), 2);
        }
    };

    pub const entity_mapping = struct {
        test "works with entity ID mapping" {
            const allocator = std.testing.allocator;

            var fw = FloydWarshallSimd.init(allocator);
            defer fw.deinit();

            fw.resize(4);
            try fw.clean();

            // Use entity IDs: 100 -> 200 -> 300 -> 400
            try fw.addEdgeWithMapping(100, 200, 1);
            try fw.addEdgeWithMapping(200, 300, 1);
            try fw.addEdgeWithMapping(300, 400, 1);

            fw.generate();

            try expect.toBeTrue(fw.hasPathWithMapping(100, 400));
            try expect.toBeTrue(fw.hasPathWithMapping(100, 200));

            try expect.equal(fw.valueWithMapping(100, 200), 1);
            try expect.equal(fw.valueWithMapping(100, 400), 3);

            try expect.equal(fw.nextWithMapping(100, 400), 200);
        }
    };

    pub const weighted_shortest_path = struct {
        test "finds shorter path through intermediate node" {
            const allocator = std.testing.allocator;

            var fw = FloydWarshallSimd.init(allocator);
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
            try expect.equal(fw.getNext(0, 3), 2);
        }
    };

    pub const path_reconstruction = struct {
        test "reconstructs path correctly" {
            const allocator = std.testing.allocator;

            var fw = FloydWarshallSimd.init(allocator);
            defer fw.deinit();

            fw.resize(4);
            try fw.clean();

            try fw.addEdgeWithMapping(10, 20, 1);
            try fw.addEdgeWithMapping(20, 30, 1);
            try fw.addEdgeWithMapping(30, 40, 1);

            fw.generate();

            var path = std.ArrayListUnmanaged(u32){};
            defer path.deinit(allocator);

            try fw.setPathWithMappingUnmanaged(allocator, &path, 10, 40);

            try expect.equal(path.items.len, 4);
            try expect.equal(path.items[0], 10);
            try expect.equal(path.items[1], 20);
            try expect.equal(path.items[2], 30);
            try expect.equal(path.items[3], 40);
        }
    };
};
