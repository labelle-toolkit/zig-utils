const std = @import("std");
const expect = @import("zspec").expect;
const zig_utils = @import("zig_utils");
const AStar = zig_utils.AStar;

pub const AStarSpec = struct {
    pub const basic_pathfinding = struct {
        test "finds path in linear graph" {
            const allocator = std.testing.allocator;

            var astar = try AStar(u64).init(allocator);
            defer astar.deinit();

            astar.resize(4);
            try astar.clean();

            // Set positions for heuristic
            try astar.setNodePosition(0, .{ .x = 0, .y = 0 });
            try astar.setNodePosition(1, .{ .x = 1, .y = 0 });
            try astar.setNodePosition(2, .{ .x = 2, .y = 0 });
            try astar.setNodePosition(3, .{ .x = 3, .y = 0 });

            // Create graph: 0 -> 1 -> 2 -> 3
            try astar.addEdge(0, 1, 1);
            try astar.addEdge(1, 2, 1);
            try astar.addEdge(2, 3, 1);

            var path = std.array_list.Managed(u32).init(allocator);
            defer path.deinit();

            const cost = try astar.findPath(0, 3, &path);

            try expect.equal(cost.?, 3);
            try expect.equal(path.items.len, 4);
            try expect.equal(path.items[0], 0);
            try expect.equal(path.items[1], 1);
            try expect.equal(path.items[2], 2);
            try expect.equal(path.items[3], 3);
        }
    };

    pub const weighted_shortest_path = struct {
        test "finds shorter weighted path" {
            const allocator = std.testing.allocator;

            var astar = try AStar(u64).init(allocator);
            defer astar.deinit();

            astar.resize(4);
            try astar.clean();
            astar.setHeuristic(.zero); // Use Dijkstra for testing weighted paths

            // Graph with two paths to node 3:
            // 0 --5--> 1 --3--> 3  (total: 8)
            // 0 --2--> 2 --2--> 3  (total: 4) <- shorter
            try astar.addEdge(0, 1, 5);
            try astar.addEdge(1, 3, 3);
            try astar.addEdge(0, 2, 2);
            try astar.addEdge(2, 3, 2);

            var path = std.array_list.Managed(u32).init(allocator);
            defer path.deinit();

            const cost = try astar.findPath(0, 3, &path);

            try expect.equal(cost.?, 4);
            try expect.equal(path.items.len, 3);
            try expect.equal(path.items[0], 0);
            try expect.equal(path.items[1], 2);
            try expect.equal(path.items[2], 3);
        }
    };

    pub const no_path = struct {
        test "returns null when no path exists" {
            const allocator = std.testing.allocator;

            var astar = try AStar(u64).init(allocator);
            defer astar.deinit();

            astar.resize(4);
            try astar.clean();

            // Disconnected graph: 0 -> 1, 2 -> 3 (no path from 0 to 3)
            try astar.addEdge(0, 1, 1);
            try astar.addEdge(2, 3, 1);

            var path = std.array_list.Managed(u32).init(allocator);
            defer path.deinit();

            const cost = try astar.findPath(0, 3, &path);

            try expect.toBeTrue(cost == null);
        }
    };

    pub const different_weight_types = struct {
        test "works with u32 weights" {
            const allocator = std.testing.allocator;

            var astar = try AStar(u32).init(allocator);
            defer astar.deinit();

            astar.resize(3);
            try astar.clean();
            astar.setHeuristic(.zero);

            try astar.addEdge(0, 1, 10);
            try astar.addEdge(1, 2, 20);

            var path = std.array_list.Managed(u32).init(allocator);
            defer path.deinit();

            const cost = try astar.findPath(0, 2, &path);

            try expect.equal(cost.?, 30);
        }
    };
};
