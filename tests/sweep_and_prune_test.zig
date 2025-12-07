const std = @import("std");
const expect = @import("zspec").expect;
const zig_utils = @import("zig_utils");
const SweepAndPrune = zig_utils.SweepAndPrune;
const AABB = zig_utils.AABB;
const CollisionPair = zig_utils.CollisionPair;
const Position = zig_utils.Position;
const sweepAndPruneSimple = zig_utils.sweepAndPruneSimple;

pub const AABBSpec = struct {
    pub const overlaps = struct {
        test "returns true for overlapping boxes" {
            const a = AABB.init(1, .{ .x = 0, .y = 0 }, 10, 10);
            const b = AABB.init(2, .{ .x = 5, .y = 5 }, 10, 10);

            try expect.toBeTrue(a.overlaps(b));
            try expect.toBeTrue(b.overlaps(a));
        }

        test "returns false for non-overlapping boxes" {
            const a = AABB.init(1, .{ .x = 0, .y = 0 }, 10, 10);
            const b = AABB.init(2, .{ .x = 50, .y = 50 }, 10, 10);

            try expect.toBeFalse(a.overlaps(b));
            try expect.toBeFalse(b.overlaps(a));
        }
    };

    pub const bounds = struct {
        test "calculates min/max correctly" {
            const box = AABB.init(1, .{ .x = 10, .y = 20 }, 5, 8);

            try expect.equal(box.minX(), 5);
            try expect.equal(box.maxX(), 15);
            try expect.equal(box.minY(), 12);
            try expect.equal(box.maxY(), 28);
        }
    };
};

pub const SweepAndPruneSpec = struct {
    const SAP = SweepAndPrune(u32);

    pub const findCollisions = struct {
        test "finds overlapping pairs" {
            const allocator = std.testing.allocator;
            var sap = SAP.init(allocator);
            defer sap.deinit();

            try sap.add(1, .{ .x = 0, .y = 0 }, 10, 10);
            try sap.add(2, .{ .x = 5, .y = 5 }, 10, 10);
            try sap.add(3, .{ .x = 100, .y = 100 }, 10, 10);

            var pairs: std.ArrayListUnmanaged(SAP.Pair) = .empty;
            defer pairs.deinit(allocator);

            try sap.findCollisions(&pairs);

            try expect.equal(pairs.items.len, 1);
            // Pair should be 1 and 2
            const pair = pairs.items[0];
            try expect.toBeTrue((pair.a == 1 and pair.b == 2) or (pair.a == 2 and pair.b == 1));
        }

        test "returns empty for no overlaps" {
            const allocator = std.testing.allocator;
            var sap = SAP.init(allocator);
            defer sap.deinit();

            try sap.add(1, .{ .x = 0, .y = 0 }, 5, 5);
            try sap.add(2, .{ .x = 50, .y = 50 }, 5, 5);
            try sap.add(3, .{ .x = 100, .y = 100 }, 5, 5);

            var pairs: std.ArrayListUnmanaged(SAP.Pair) = .empty;
            defer pairs.deinit(allocator);

            try sap.findCollisions(&pairs);

            try expect.equal(pairs.items.len, 0);
        }

        test "handles multiple overlaps" {
            const allocator = std.testing.allocator;
            var sap = SAP.init(allocator);
            defer sap.deinit();

            // All three overlap each other
            try sap.add(1, .{ .x = 0, .y = 0 }, 20, 20);
            try sap.add(2, .{ .x = 10, .y = 10 }, 20, 20);
            try sap.add(3, .{ .x = 20, .y = 20 }, 20, 20);

            var pairs: std.ArrayListUnmanaged(SAP.Pair) = .empty;
            defer pairs.deinit(allocator);

            try sap.findCollisions(&pairs);

            // Should have 3 pairs: (1,2), (1,3), (2,3)
            try expect.equal(pairs.items.len, 3);
        }
    };

    pub const updatePosition = struct {
        test "updates entity position" {
            const allocator = std.testing.allocator;
            var sap = SAP.init(allocator);
            defer sap.deinit();

            try sap.add(1, .{ .x = 0, .y = 0 }, 10, 10);
            try sap.add(2, .{ .x = 100, .y = 100 }, 10, 10);

            // Initially no collision
            var pairs: std.ArrayListUnmanaged(SAP.Pair) = .empty;
            defer pairs.deinit(allocator);

            try sap.findCollisions(&pairs);
            try expect.equal(pairs.items.len, 0);

            // Move entity 2 to overlap with 1
            sap.updatePosition(2, .{ .x = 5, .y = 5 });

            pairs.clearRetainingCapacity();
            try sap.findCollisions(&pairs);
            try expect.equal(pairs.items.len, 1);
        }
    };

    pub const remove = struct {
        test "removes entity" {
            const allocator = std.testing.allocator;
            var sap = SAP.init(allocator);
            defer sap.deinit();

            try sap.add(1, .{ .x = 0, .y = 0 }, 10, 10);
            try sap.add(2, .{ .x = 5, .y = 5 }, 10, 10);

            var pairs: std.ArrayListUnmanaged(SAP.Pair) = .empty;
            defer pairs.deinit(allocator);

            try sap.findCollisions(&pairs);
            try expect.equal(pairs.items.len, 1);

            // Remove entity 1
            const removed = sap.remove(1);
            try expect.toBeTrue(removed);

            pairs.clearRetainingCapacity();
            try sap.findCollisions(&pairs);
            try expect.equal(pairs.items.len, 0);
        }
    };

    pub const queryRect = struct {
        test "finds entities in rectangle" {
            const allocator = std.testing.allocator;
            var sap = SAP.init(allocator);
            defer sap.deinit();

            try sap.add(1, .{ .x = 10, .y = 10 }, 5, 5);
            try sap.add(2, .{ .x = 50, .y = 50 }, 5, 5);
            try sap.add(3, .{ .x = 100, .y = 100 }, 5, 5);

            var results: std.ArrayListUnmanaged(u32) = .empty;
            defer results.deinit(allocator);

            try sap.queryRect(.{ .x = 0, .y = 0 }, 30, 30, &results);

            try expect.equal(results.items.len, 1);
            try expect.equal(results.items[0], 1);
        }
    };

    pub const queryRadius = struct {
        test "finds entities in radius" {
            const allocator = std.testing.allocator;
            var sap = SAP.init(allocator);
            defer sap.deinit();

            try sap.add(1, .{ .x = 10, .y = 10 }, 5, 5);
            try sap.add(2, .{ .x = 50, .y = 50 }, 5, 5);
            try sap.add(3, .{ .x = 100, .y = 100 }, 5, 5);

            var results: std.ArrayListUnmanaged(u32) = .empty;
            defer results.deinit(allocator);

            try sap.queryRadius(.{ .x = 0, .y = 0 }, 20, &results);

            try expect.equal(results.items.len, 1);
            try expect.equal(results.items[0], 1);
        }
    };
};

pub const SweepAndPruneSimpleSpec = struct {
    pub const sweepAndPrune = struct {
        test "finds overlapping AABB pairs" {
            const allocator = std.testing.allocator;

            const boxes = [_]AABB{
                AABB.init(0, .{ .x = 0, .y = 0 }, 10, 10),
                AABB.init(1, .{ .x = 5, .y = 5 }, 10, 10),
                AABB.init(2, .{ .x = 100, .y = 100 }, 10, 10),
            };

            var pairs: std.ArrayListUnmanaged(CollisionPair) = .empty;
            defer pairs.deinit(allocator);

            try sweepAndPruneSimple(&boxes, &pairs, allocator);

            try expect.equal(pairs.items.len, 1);
            try expect.equal(pairs.items[0].a, 0);
            try expect.equal(pairs.items[0].b, 1);
        }
    };
};
