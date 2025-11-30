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
            try children[index].insert(node);
            return;
        }

        try self.nodes.append(self.allocator, node);

        if (self.nodes.items.len > self.max_nodes and self.depth < self.max_depth) {
            if (self.children == null) {
                try self.subdivide();
            }

            while (self.nodes.items.len > 0) {
                const n = self.nodes.items[0];
                const quadrant = self.getQuadrant(n.x, n.y);
                try self.children.?[quadrant].insert(n);
                _ = self.nodes.swapRemove(0);
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
                // Prune: skip children whose bounds are entirely farther than current nearest
                if (child.minDistToBounds(x, y) < nearest_dist.*) {
                    child.findNearest(x, y, nearest, nearest_dist);
                }
            }
        }
    }

    fn minDistToBounds(self: *QuadTree, px: f32, py: f32) f32 {
        // Find closest point on rectangle bounds to query point
        const closest_x = std.math.clamp(px, self.bounds.x, self.bounds.x + self.bounds.width);
        const closest_y = std.math.clamp(py, self.bounds.y, self.bounds.y + self.bounds.height);

        const dx = closest_x - px;
        const dy = closest_y - py;
        return @sqrt(dx * dx + dy * dy);
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
        var allocated: usize = 0;

        errdefer {
            for (children[0..allocated]) |child| {
                self.allocator.destroy(child);
            }
        }

        children[0] = try self.allocator.create(QuadTree);
        allocated = 1;
        children[0].* = initWithDepth(self.allocator, .{ .x = x, .y = y, .width = half_w, .height = half_h }, self.depth + 1);

        children[1] = try self.allocator.create(QuadTree);
        allocated = 2;
        children[1].* = initWithDepth(self.allocator, .{ .x = x + half_w, .y = y, .width = half_w, .height = half_h }, self.depth + 1);

        children[2] = try self.allocator.create(QuadTree);
        allocated = 3;
        children[2].* = initWithDepth(self.allocator, .{ .x = x, .y = y + half_h, .width = half_w, .height = half_h }, self.depth + 1);

        children[3] = try self.allocator.create(QuadTree);
        allocated = 4;
        children[3].* = initWithDepth(self.allocator, .{ .x = x + half_w, .y = y + half_h, .width = half_w, .height = half_h }, self.depth + 1);

        self.children = children;
    }

    fn getQuadrant(self: *QuadTree, px: f32, py: f32) usize {
        const mid_x = self.bounds.x + self.bounds.width / 2;
        const mid_y = self.bounds.y + self.bounds.height / 2;

        const top = py < mid_y;
        const left = px < mid_x;

        if (top) {
            return if (left) 0 else 1;
        } else {
            return if (left) 2 else 3;
        }
    }
};
