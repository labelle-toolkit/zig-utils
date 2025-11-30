const std = @import("std");

pub const Rectangle = struct {
    x: f32,
    y: f32,
    width: f32,
    height: f32,

    pub fn contains(self: Rectangle, px: f32, py: f32) bool {
        return px >= self.x and px < self.x + self.width and
            py >= self.y and py < self.y + self.height;
    }

    pub fn intersects(self: Rectangle, other: Rectangle) bool {
        return !(other.x >= self.x + self.width or
            other.x + other.width <= self.x or
            other.y >= self.y + self.height or
            other.y + other.height <= self.y);
    }
};

pub const QuadTreeNode = struct {
    entity: u32,
    x: f32,
    y: f32,
};

pub const QuadTree = struct {
    allocator: std.mem.Allocator,
    bounds: Rectangle,
    nodes: std.ArrayListUnmanaged(QuadTreeNode) = .empty,
    children: ?[4]*QuadTree = null,
    max_nodes: usize = 8,
    max_depth: usize = 8,
    depth: usize = 0,

    pub fn init(allocator: std.mem.Allocator, bounds: Rectangle) QuadTree {
        return .{
            .allocator = allocator,
            .bounds = bounds,
            .nodes = .empty,
        };
    }

    pub fn initWithDepth(allocator: std.mem.Allocator, bounds: Rectangle, depth: usize) QuadTree {
        var qt = init(allocator, bounds);
        qt.depth = depth;
        return qt;
    }

    pub fn deinit(self: *QuadTree) void {
        self.nodes.deinit(self.allocator);
        if (self.children) |children| {
            for (children) |child| {
                child.deinit();
                self.allocator.destroy(child);
            }
        }
    }

    pub fn clear(self: *QuadTree) void {
        self.nodes.clearRetainingCapacity();
        if (self.children) |children| {
            for (children) |child| {
                child.clear();
            }
        }
    }

    pub fn insert(self: *QuadTree, node: QuadTreeNode) !void {
        if (!self.bounds.contains(node.x, node.y)) {
            return;
        }

        if (self.children) |children| {
            const index = self.getQuadrant(node.x, node.y);
            if (index) |i| {
                try children[i].insert(node);
                return;
            }
        }

        try self.nodes.append(self.allocator, node);

        if (self.nodes.items.len > self.max_nodes and self.depth < self.max_depth) {
            if (self.children == null) {
                try self.subdivide();
            }

            var i: usize = 0;
            while (i < self.nodes.items.len) {
                const n = self.nodes.items[i];
                const quadrant = self.getQuadrant(n.x, n.y);
                if (quadrant) |q| {
                    try self.children.?[q].insert(n);
                    _ = self.nodes.swapRemove(i);
                } else {
                    i += 1;
                }
            }
        }
    }

    pub fn query(self: *QuadTree, range: Rectangle, result: *std.ArrayListUnmanaged(QuadTreeNode), allocator: std.mem.Allocator) !void {
        if (!self.bounds.intersects(range)) {
            return;
        }

        for (self.nodes.items) |node| {
            if (range.contains(node.x, node.y)) {
                try result.append(allocator, node);
            }
        }

        if (self.children) |children| {
            for (children) |child| {
                try child.query(range, result, allocator);
            }
        }
    }

    pub fn queryNearest(self: *QuadTree, x: f32, y: f32, max_distance: f32) ?QuadTreeNode {
        var nearest: ?QuadTreeNode = null;
        var nearest_dist: f32 = max_distance;

        self.findNearest(x, y, &nearest, &nearest_dist);
        return nearest;
    }

    fn findNearest(self: *QuadTree, x: f32, y: f32, nearest: *?QuadTreeNode, nearest_dist: *f32) void {
        for (self.nodes.items) |node| {
            const dx = node.x - x;
            const dy = node.y - y;
            const dist = @sqrt(dx * dx + dy * dy);
            if (dist < nearest_dist.*) {
                nearest_dist.* = dist;
                nearest.* = node;
            }
        }

        if (self.children) |children| {
            for (children) |child| {
                child.findNearest(x, y, nearest, nearest_dist);
            }
        }
    }

    pub fn count(self: *QuadTree) usize {
        var total = self.nodes.items.len;
        if (self.children) |children| {
            for (children) |child| {
                total += child.count();
            }
        }
        return total;
    }

    fn subdivide(self: *QuadTree) !void {
        const half_w = self.bounds.width / 2;
        const half_h = self.bounds.height / 2;
        const x = self.bounds.x;
        const y = self.bounds.y;

        var children: [4]*QuadTree = undefined;

        children[0] = try self.allocator.create(QuadTree);
        children[0].* = initWithDepth(self.allocator, .{ .x = x, .y = y, .width = half_w, .height = half_h }, self.depth + 1);

        children[1] = try self.allocator.create(QuadTree);
        children[1].* = initWithDepth(self.allocator, .{ .x = x + half_w, .y = y, .width = half_w, .height = half_h }, self.depth + 1);

        children[2] = try self.allocator.create(QuadTree);
        children[2].* = initWithDepth(self.allocator, .{ .x = x, .y = y + half_h, .width = half_w, .height = half_h }, self.depth + 1);

        children[3] = try self.allocator.create(QuadTree);
        children[3].* = initWithDepth(self.allocator, .{ .x = x + half_w, .y = y + half_h, .width = half_w, .height = half_h }, self.depth + 1);

        self.children = children;
    }

    fn getQuadrant(self: *QuadTree, x: f32, y: f32) ?usize {
        const mid_x = self.bounds.x + self.bounds.width / 2;
        const mid_y = self.bounds.y + self.bounds.height / 2;

        const top = y < mid_y;
        const left = x < mid_x;

        if (top and left) return 0;
        if (top and !left) return 1;
        if (!top and left) return 2;
        if (!top and !left) return 3;
        return null;
    }
};

// Tests
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
    // Children are retained after clear (unlike before)
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
