const std = @import("std");
const zig_utils = @import("zig_utils");
const QuadTree = zig_utils.QuadTree;
const QuadTreeNode = zig_utils.QuadTreeNode;
const Rectangle = zig_utils.Rectangle;

test "Rectangle.contains" {
    const rect = Rectangle{ .x = 0, .y = 0, .width = 100, .height = 100 };

    try std.testing.expect(rect.contains(50, 50));
    try std.testing.expect(rect.contains(0, 0));
    try std.testing.expect(rect.contains(99, 99));
    try std.testing.expect(!rect.contains(100, 100));
    try std.testing.expect(!rect.contains(-1, 50));
    try std.testing.expect(!rect.contains(50, -1));
}

test "Rectangle.intersects" {
    const rect1 = Rectangle{ .x = 0, .y = 0, .width = 100, .height = 100 };
    const rect2 = Rectangle{ .x = 50, .y = 50, .width = 100, .height = 100 };
    const rect3 = Rectangle{ .x = 200, .y = 200, .width = 50, .height = 50 };

    try std.testing.expect(rect1.intersects(rect2));
    try std.testing.expect(rect2.intersects(rect1));
    try std.testing.expect(!rect1.intersects(rect3));
    try std.testing.expect(!rect3.intersects(rect1));
}

test "QuadTree.init and deinit" {
    const allocator = std.testing.allocator;
    var qt = QuadTree.init(allocator, .{ .x = 0, .y = 0, .width = 100, .height = 100 });
    defer qt.deinit();

    try std.testing.expectEqual(@as(usize, 0), qt.count());
}

test "QuadTree.insert and count" {
    const allocator = std.testing.allocator;
    var qt = QuadTree.init(allocator, .{ .x = 0, .y = 0, .width = 100, .height = 100 });
    defer qt.deinit();

    try qt.insert(.{ .entity = 1, .x = 10, .y = 10 });
    try qt.insert(.{ .entity = 2, .x = 20, .y = 20 });
    try qt.insert(.{ .entity = 3, .x = 30, .y = 30 });

    try std.testing.expectEqual(@as(usize, 3), qt.count());
}

test "QuadTree.insert outside bounds" {
    const allocator = std.testing.allocator;
    var qt = QuadTree.init(allocator, .{ .x = 0, .y = 0, .width = 100, .height = 100 });
    defer qt.deinit();

    try qt.insert(.{ .entity = 1, .x = 200, .y = 200 });

    try std.testing.expectEqual(@as(usize, 0), qt.count());
}

test "QuadTree.insert causes subdivision" {
    const allocator = std.testing.allocator;
    var qt = QuadTree.init(allocator, .{ .x = 0, .y = 0, .width = 100, .height = 100 });
    defer qt.deinit();

    // Insert more than max_nodes to trigger subdivision
    for (0..10) |i| {
        try qt.insert(.{ .entity = @intCast(i), .x = @floatFromInt(i * 5), .y = @floatFromInt(i * 5) });
    }

    try std.testing.expectEqual(@as(usize, 10), qt.count());
    try std.testing.expect(qt.children != null);
}

test "QuadTree.query" {
    const allocator = std.testing.allocator;
    var qt = QuadTree.init(allocator, .{ .x = 0, .y = 0, .width = 100, .height = 100 });
    defer qt.deinit();

    try qt.insert(.{ .entity = 1, .x = 10, .y = 10 });
    try qt.insert(.{ .entity = 2, .x = 50, .y = 50 });
    try qt.insert(.{ .entity = 3, .x = 90, .y = 90 });

    var result: std.ArrayListUnmanaged(QuadTreeNode) = .empty;
    defer result.deinit(allocator);

    try qt.query(.{ .x = 0, .y = 0, .width = 30, .height = 30 }, &result, allocator);

    try std.testing.expectEqual(@as(usize, 1), result.items.len);
    try std.testing.expectEqual(@as(u32, 1), result.items[0].entity);
}

test "QuadTree.queryNearest" {
    const allocator = std.testing.allocator;
    var qt = QuadTree.init(allocator, .{ .x = 0, .y = 0, .width = 100, .height = 100 });
    defer qt.deinit();

    try qt.insert(.{ .entity = 1, .x = 10, .y = 10 });
    try qt.insert(.{ .entity = 2, .x = 50, .y = 50 });
    try qt.insert(.{ .entity = 3, .x = 90, .y = 90 });

    const nearest = qt.queryNearest(12, 12, 100);
    try std.testing.expect(nearest != null);
    try std.testing.expectEqual(@as(u32, 1), nearest.?.entity);

    const no_result = qt.queryNearest(12, 12, 1);
    try std.testing.expect(no_result == null);
}

test "QuadTree.clear" {
    const allocator = std.testing.allocator;
    var qt = QuadTree.init(allocator, .{ .x = 0, .y = 0, .width = 100, .height = 100 });
    defer qt.deinit();

    for (0..10) |i| {
        try qt.insert(.{ .entity = @intCast(i), .x = @floatFromInt(i * 5), .y = @floatFromInt(i * 5) });
    }

    try std.testing.expect(qt.count() > 0);
    try std.testing.expect(qt.children != null);

    qt.clear();

    try std.testing.expectEqual(@as(usize, 0), qt.count());
    // Children are retained after clear
    try std.testing.expect(qt.children != null);
}

test "QuadTree.query with subdivided tree" {
    const allocator = std.testing.allocator;
    var qt = QuadTree.init(allocator, .{ .x = 0, .y = 0, .width = 100, .height = 100 });
    defer qt.deinit();

    // Insert nodes in different quadrants
    for (0..20) |i| {
        const x: f32 = @floatFromInt((i % 10) * 10);
        const y: f32 = @floatFromInt((i / 10) * 50);
        try qt.insert(.{ .entity = @intCast(i), .x = x, .y = y });
    }

    var result: std.ArrayListUnmanaged(QuadTreeNode) = .empty;
    defer result.deinit(allocator);

    // Query top-left quadrant
    try qt.query(.{ .x = 0, .y = 0, .width = 50, .height = 50 }, &result, allocator);

    // Should find nodes in that region
    try std.testing.expect(result.items.len > 0);
}
