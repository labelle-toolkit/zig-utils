const std = @import("std");
const expect = @import("zspec").expect;
const zig_utils = @import("zig_utils");
const QuadTree = zig_utils.QuadTree;
const QuadTreeNode = zig_utils.QuadTreeNode;
const Rectangle = zig_utils.Rectangle;

pub const RectangleSpec = struct {
    pub const contains = struct {
        test "returns true for point inside rectangle" {
            const rect = Rectangle{ .x = 0, .y = 0, .width = 100, .height = 100 };

            try expect.toBeTrue(rect.contains(50, 50));
            try expect.toBeTrue(rect.contains(0, 0));
            try expect.toBeTrue(rect.contains(99, 99));
        }

        test "returns false for point outside rectangle" {
            const rect = Rectangle{ .x = 0, .y = 0, .width = 100, .height = 100 };

            try expect.toBeFalse(rect.contains(100, 100));
            try expect.toBeFalse(rect.contains(-1, 50));
            try expect.toBeFalse(rect.contains(50, -1));
        }
    };

    pub const intersects = struct {
        test "returns true for overlapping rectangles" {
            const rect1 = Rectangle{ .x = 0, .y = 0, .width = 100, .height = 100 };
            const rect2 = Rectangle{ .x = 50, .y = 50, .width = 100, .height = 100 };

            try expect.toBeTrue(rect1.intersects(rect2));
            try expect.toBeTrue(rect2.intersects(rect1));
        }

        test "returns false for non-overlapping rectangles" {
            const rect1 = Rectangle{ .x = 0, .y = 0, .width = 100, .height = 100 };
            const rect3 = Rectangle{ .x = 200, .y = 200, .width = 50, .height = 50 };

            try expect.toBeFalse(rect1.intersects(rect3));
            try expect.toBeFalse(rect3.intersects(rect1));
        }
    };
};

pub const QuadTreeSpec = struct {
    pub const init = struct {
        test "creates empty tree with zero count" {
            const allocator = std.testing.allocator;
            var qt = QuadTree.init(allocator, .{ .x = 0, .y = 0, .width = 100, .height = 100 });
            defer qt.deinit();

            try expect.equal(qt.count(), 0);
        }
    };

    pub const insert = struct {
        test "adds nodes and increments count" {
            const allocator = std.testing.allocator;
            var qt = QuadTree.init(allocator, .{ .x = 0, .y = 0, .width = 100, .height = 100 });
            defer qt.deinit();

            try qt.insert(.{ .entity = 1, .x = 10, .y = 10 });
            try qt.insert(.{ .entity = 2, .x = 20, .y = 20 });
            try qt.insert(.{ .entity = 3, .x = 30, .y = 30 });

            try expect.equal(qt.count(), 3);
        }

        test "ignores nodes outside bounds" {
            const allocator = std.testing.allocator;
            var qt = QuadTree.init(allocator, .{ .x = 0, .y = 0, .width = 100, .height = 100 });
            defer qt.deinit();

            try qt.insert(.{ .entity = 1, .x = 200, .y = 200 });

            try expect.equal(qt.count(), 0);
        }

        test "subdivides when exceeding max_nodes" {
            const allocator = std.testing.allocator;
            var qt = QuadTree.init(allocator, .{ .x = 0, .y = 0, .width = 100, .height = 100 });
            defer qt.deinit();

            for (0..10) |i| {
                try qt.insert(.{ .entity = @intCast(i), .x = @floatFromInt(i * 5), .y = @floatFromInt(i * 5) });
            }

            try expect.equal(qt.count(), 10);
            try expect.toBeTrue(qt.children != null);
        }
    };

    pub const query = struct {
        test "returns nodes within range" {
            const allocator = std.testing.allocator;
            var qt = QuadTree.init(allocator, .{ .x = 0, .y = 0, .width = 100, .height = 100 });
            defer qt.deinit();

            try qt.insert(.{ .entity = 1, .x = 10, .y = 10 });
            try qt.insert(.{ .entity = 2, .x = 50, .y = 50 });
            try qt.insert(.{ .entity = 3, .x = 90, .y = 90 });

            var result: std.ArrayListUnmanaged(QuadTreeNode) = .empty;
            defer result.deinit(allocator);

            try qt.query(.{ .x = 0, .y = 0, .width = 30, .height = 30 }, &result, allocator);

            try expect.equal(result.items.len, 1);
            try expect.equal(result.items[0].entity, 1);
        }

        test "works with subdivided tree" {
            const allocator = std.testing.allocator;
            var qt = QuadTree.init(allocator, .{ .x = 0, .y = 0, .width = 100, .height = 100 });
            defer qt.deinit();

            for (0..20) |i| {
                const x: f32 = @floatFromInt((i % 10) * 10);
                const y: f32 = @floatFromInt((i / 10) * 50);
                try qt.insert(.{ .entity = @intCast(i), .x = x, .y = y });
            }

            var result: std.ArrayListUnmanaged(QuadTreeNode) = .empty;
            defer result.deinit(allocator);

            try qt.query(.{ .x = 0, .y = 0, .width = 50, .height = 50 }, &result, allocator);

            try expect.toBeTrue(result.items.len > 0);
        }
    };

    pub const queryNearest = struct {
        test "returns closest node within max_distance" {
            const allocator = std.testing.allocator;
            var qt = QuadTree.init(allocator, .{ .x = 0, .y = 0, .width = 100, .height = 100 });
            defer qt.deinit();

            try qt.insert(.{ .entity = 1, .x = 10, .y = 10 });
            try qt.insert(.{ .entity = 2, .x = 50, .y = 50 });
            try qt.insert(.{ .entity = 3, .x = 90, .y = 90 });

            const nearest = qt.queryNearest(12, 12, 100);

            try expect.toBeTrue(nearest != null);
            try expect.equal(nearest.?.entity, 1);
        }

        test "returns null when no nodes within max_distance" {
            const allocator = std.testing.allocator;
            var qt = QuadTree.init(allocator, .{ .x = 0, .y = 0, .width = 100, .height = 100 });
            defer qt.deinit();

            try qt.insert(.{ .entity = 1, .x = 10, .y = 10 });

            const no_result = qt.queryNearest(12, 12, 1);

            try expect.toBeTrue(no_result == null);
        }
    };

    pub const clear = struct {
        test "removes all nodes but retains tree structure" {
            const allocator = std.testing.allocator;
            var qt = QuadTree.init(allocator, .{ .x = 0, .y = 0, .width = 100, .height = 100 });
            defer qt.deinit();

            for (0..10) |i| {
                try qt.insert(.{ .entity = @intCast(i), .x = @floatFromInt(i * 5), .y = @floatFromInt(i * 5) });
            }

            try expect.toBeTrue(qt.count() > 0);
            try expect.toBeTrue(qt.children != null);

            qt.clear();

            try expect.equal(qt.count(), 0);
            try expect.toBeTrue(qt.children != null);
        }
    };
};
