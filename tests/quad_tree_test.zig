const std = @import("std");
const expect = @import("zspec").expect;
const zig_utils = @import("zig_utils");
const QuadTree = zig_utils.QuadTree;
const EntityPoint = zig_utils.EntityPoint;
const Rectangle = zig_utils.Rectangle;
const Position = zig_utils.Position;

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

    pub const containsPosition = struct {
        test "accepts Position type" {
            const rect = Rectangle{ .x = 0, .y = 0, .width = 100, .height = 100 };
            const pos = Position{ .x = 50, .y = 50 };

            try expect.toBeTrue(rect.containsPosition(pos));
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

    pub const fromPosition = struct {
        test "creates rectangle from position" {
            const pos = Position{ .x = 10, .y = 20 };
            const rect = Rectangle.fromPosition(pos, 100, 50);

            try expect.equal(rect.x, 10);
            try expect.equal(rect.y, 20);
            try expect.equal(rect.width, 100);
            try expect.equal(rect.height, 50);
        }
    };

    pub const centered = struct {
        test "creates rectangle centered on position" {
            const center = Position{ .x = 50, .y = 50 };
            const rect = Rectangle.centered(center, 20, 10);

            try expect.equal(rect.x, 40);
            try expect.equal(rect.y, 45);
            try expect.equal(rect.width, 20);
            try expect.equal(rect.height, 10);
        }
    };
};

pub const QuadTreeSpec = struct {
    const QT = QuadTree(u32);
    const Point = EntityPoint(u32);

    pub const init = struct {
        test "creates empty tree with zero count" {
            const allocator = std.testing.allocator;
            var qt = try QT.init(allocator, .{ .x = 0, .y = 0, .width = 100, .height = 100 });
            defer qt.deinit();

            try expect.equal(qt.count(), 0);
        }
    };

    pub const insert = struct {
        test "adds nodes and increments count" {
            const allocator = std.testing.allocator;
            var qt = try QT.init(allocator, .{ .x = 0, .y = 0, .width = 100, .height = 100 });
            defer qt.deinit();

            _ = qt.insert(Point.init(1, 10, 10));
            _ = qt.insert(Point.init(2, 20, 20));
            _ = qt.insert(Point.init(3, 30, 30));

            try expect.equal(qt.count(), 3);
        }

        test "ignores nodes outside bounds" {
            const allocator = std.testing.allocator;
            var qt = try QT.init(allocator, .{ .x = 0, .y = 0, .width = 100, .height = 100 });
            defer qt.deinit();

            _ = qt.insert(Point.init(1, 200, 200));

            try expect.equal(qt.count(), 0);
        }

        test "subdivides when exceeding capacity" {
            const allocator = std.testing.allocator;
            var qt = try QT.init(allocator, .{ .x = 0, .y = 0, .width = 100, .height = 100 });
            defer qt.deinit();

            for (0..10) |i| {
                _ = qt.insert(Point.init(@intCast(i), @floatFromInt(i * 5), @floatFromInt(i * 5)));
            }

            try expect.equal(qt.count(), 10);
        }
    };

    pub const queryRect = struct {
        test "returns nodes within range" {
            const allocator = std.testing.allocator;
            var qt = try QT.init(allocator, .{ .x = 0, .y = 0, .width = 100, .height = 100 });
            defer qt.deinit();

            _ = qt.insert(Point.init(1, 10, 10));
            _ = qt.insert(Point.init(2, 50, 50));
            _ = qt.insert(Point.init(3, 90, 90));

            var result: std.ArrayListUnmanaged(Point) = .empty;
            defer result.deinit(allocator);

            try qt.queryRect(.{ .x = 0, .y = 0, .width = 30, .height = 30 }, &result);

            try expect.equal(result.items.len, 1);
            try expect.equal(result.items[0].id, 1);
        }

        test "works with subdivided tree" {
            const allocator = std.testing.allocator;
            var qt = try QT.init(allocator, .{ .x = 0, .y = 0, .width = 100, .height = 100 });
            defer qt.deinit();

            for (0..20) |i| {
                const x: f32 = @floatFromInt((i % 10) * 10);
                const y: f32 = @floatFromInt((i / 10) * 50);
                _ = qt.insert(Point.init(@intCast(i), x, y));
            }

            var result: std.ArrayListUnmanaged(Point) = .empty;
            defer result.deinit(allocator);

            try qt.queryRect(.{ .x = 0, .y = 0, .width = 50, .height = 50 }, &result);

            try expect.toBeTrue(result.items.len > 0);
        }
    };

    pub const queryRadius = struct {
        test "returns nodes within radius" {
            const allocator = std.testing.allocator;
            var qt = try QT.init(allocator, .{ .x = 0, .y = 0, .width = 100, .height = 100 });
            defer qt.deinit();

            _ = qt.insert(Point.init(1, 10, 10));
            _ = qt.insert(Point.init(2, 50, 50));
            _ = qt.insert(Point.init(3, 90, 90));

            var result: std.ArrayListUnmanaged(Point) = .empty;
            defer result.deinit(allocator);

            try qt.queryRadius(.{ .x = 10, .y = 10 }, 15, &result);

            try expect.equal(result.items.len, 1);
            try expect.equal(result.items[0].id, 1);
        }
    };

    pub const queryNearest = struct {
        test "returns closest node within max_distance" {
            const allocator = std.testing.allocator;
            var qt = try QT.init(allocator, .{ .x = 0, .y = 0, .width = 100, .height = 100 });
            defer qt.deinit();

            _ = qt.insert(Point.init(1, 10, 10));
            _ = qt.insert(Point.init(2, 50, 50));
            _ = qt.insert(Point.init(3, 90, 90));

            const nearest = qt.queryNearest(.{ .x = 12, .y = 12 }, 100);

            try expect.toBeTrue(nearest != null);
            try expect.equal(nearest.?.id, 1);
        }

        test "returns null when no nodes within max_distance" {
            const allocator = std.testing.allocator;
            var qt = try QT.init(allocator, .{ .x = 0, .y = 0, .width = 100, .height = 100 });
            defer qt.deinit();

            _ = qt.insert(Point.init(1, 10, 10));

            const no_result = qt.queryNearest(.{ .x = 12, .y = 12 }, 1);

            try expect.toBeTrue(no_result == null);
        }
    };

    pub const remove = struct {
        test "removes node by id" {
            const allocator = std.testing.allocator;
            var qt = try QT.init(allocator, .{ .x = 0, .y = 0, .width = 100, .height = 100 });
            defer qt.deinit();

            _ = qt.insert(Point.init(1, 10, 10));
            _ = qt.insert(Point.init(2, 20, 20));

            try expect.equal(qt.count(), 2);

            const removed = qt.remove(1);
            try expect.toBeTrue(removed);
            try expect.equal(qt.count(), 1);
        }
    };

    pub const update = struct {
        test "updates node position" {
            const allocator = std.testing.allocator;
            var qt = try QT.init(allocator, .{ .x = 0, .y = 0, .width = 100, .height = 100 });
            defer qt.deinit();

            _ = qt.insert(Point.init(1, 10, 10));

            const updated = qt.update(1, .{ .x = 50, .y = 50 });
            try expect.toBeTrue(updated);

            var result: std.ArrayListUnmanaged(Point) = .empty;
            defer result.deinit(allocator);

            try qt.queryRect(.{ .x = 45, .y = 45, .width = 10, .height = 10 }, &result);
            try expect.equal(result.items.len, 1);
            try expect.equal(result.items[0].id, 1);
        }
    };

    pub const hasPointInRect = struct {
        test "returns true when point exists in rect" {
            const allocator = std.testing.allocator;
            var qt = try QT.init(allocator, .{ .x = 0, .y = 0, .width = 100, .height = 100 });
            defer qt.deinit();

            _ = qt.insert(Point.init(1, 10, 10));

            try expect.toBeTrue(qt.hasPointInRect(.{ .x = 0, .y = 0, .width = 20, .height = 20 }));
            try expect.toBeFalse(qt.hasPointInRect(.{ .x = 50, .y = 50, .width = 20, .height = 20 }));
        }
    };
};
