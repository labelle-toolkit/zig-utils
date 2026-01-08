const std = @import("std");
const expect = @import("zspec").expect;
const zig_utils = @import("zig_utils");
const ZIndexBuckets = zig_utils.ZIndexBuckets;

pub const ZIndexBucketsSpec = struct {
    pub const basic_operations = struct {
        test "inserts and counts items" {
            const allocator = std.testing.allocator;

            var buckets = ZIndexBuckets(u32, u8).init(allocator);
            defer buckets.deinit();

            try buckets.insert(100, 5);
            try buckets.insert(200, 10);
            try buckets.insert(300, 5);

            try expect.equal(buckets.count(), 3);
        }

        test "iterates in z-order" {
            const allocator = std.testing.allocator;

            var buckets = ZIndexBuckets(u32, u8).init(allocator);
            defer buckets.deinit();

            try buckets.insert(100, 5);
            try buckets.insert(200, 10);
            try buckets.insert(300, 5);

            var iter = buckets.iterator();
            try expect.equal(iter.next().?, 100);
            try expect.equal(iter.next().?, 300);
            try expect.equal(iter.next().?, 200);
            try expect.toBeTrue(iter.next() == null);
        }

        test "removes items correctly" {
            const allocator = std.testing.allocator;

            var buckets = ZIndexBuckets(u32, u8).init(allocator);
            defer buckets.deinit();

            try buckets.insert(100, 5);
            try buckets.insert(200, 10);

            try expect.toBeTrue(buckets.remove(100, 5));
            try expect.equal(buckets.count(), 1);
        }

        test "changes z-index" {
            const allocator = std.testing.allocator;

            var buckets = ZIndexBuckets(u32, u8).init(allocator);
            defer buckets.deinit();

            try buckets.insert(200, 10);

            try buckets.changeZIndex(200, 10, 0);

            var iter = buckets.iterator();
            try expect.equal(iter.next().?, 200);
        }
    };

    pub const struct_items = struct {
        test "works with struct items using eql method" {
            const allocator = std.testing.allocator;

            const Item = struct {
                id: u32,
                name: []const u8,

                pub fn eql(self: @This(), other: @This()) bool {
                    return self.id == other.id;
                }
            };

            var buckets = ZIndexBuckets(Item, u8).init(allocator);
            defer buckets.deinit();

            try buckets.insert(.{ .id = 1, .name = "first" }, 10);
            try buckets.insert(.{ .id = 2, .name = "second" }, 5);

            try expect.equal(buckets.count(), 2);

            try expect.toBeTrue(buckets.remove(.{ .id = 1, .name = "" }, 10));
            try expect.equal(buckets.count(), 1);
        }
    };

    pub const smaller_z_index_type = struct {
        test "works with u4 z-index type" {
            const allocator = std.testing.allocator;

            var buckets = ZIndexBuckets(u32, u4).init(allocator);
            defer buckets.deinit();

            try buckets.insert(100, 0);
            try buckets.insert(200, 15);
            try buckets.insert(300, 8);

            try expect.equal(buckets.count(), 3);

            var iter = buckets.iterator();
            try expect.equal(iter.next().?, 100);
            try expect.equal(iter.next().?, 300);
            try expect.equal(iter.next().?, 200);
            try expect.toBeTrue(iter.next() == null);
        }
    };
};
