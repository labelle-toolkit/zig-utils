//! Z-Index Bucket Storage
//!
//! Maintains items sorted by z-index using 256 buckets (one per z-index level).
//! This eliminates the need to re-sort the entire list when z-indices change.
//!
//! Complexity:
//! - Insert: O(1) amortized
//! - Remove: O(bucket_size) - typically small due to clustered z-indices
//! - Change z-index: O(bucket_size)
//! - Iteration: O(256 + n) ≈ O(n)

const std = @import("std");

/// Z-index bucket storage for efficient ordered iteration by u8 key.
/// Generic over item type T.
pub fn ZIndexBuckets(comptime T: type) type {
    return struct {
        const Self = @This();
        const Bucket = std.ArrayListUnmanaged(T);

        buckets: [256]Bucket,
        allocator: std.mem.Allocator,
        total_count: usize,

        pub fn init(allocator: std.mem.Allocator) Self {
            return Self{
                .buckets = [_]Bucket{.{}} ** 256,
                .allocator = allocator,
                .total_count = 0,
            };
        }

        pub fn deinit(self: *Self) void {
            for (&self.buckets) |*bucket| {
                bucket.deinit(self.allocator);
            }
        }

        /// Insert an item at the given z-index
        pub fn insert(self: *Self, item: T, z: u8) !void {
            try self.buckets[z].append(self.allocator, item);
            self.total_count += 1;
        }

        /// Remove an item from the given z-index bucket using equality comparison.
        /// Returns true if the item was found and removed.
        pub fn remove(self: *Self, item: T, z: u8) bool {
            const bucket = &self.buckets[z];
            for (bucket.items, 0..) |existing, i| {
                if (eql(existing, item)) {
                    _ = bucket.swapRemove(i);
                    self.total_count -= 1;
                    return true;
                }
            }
            return false;
        }

        /// Change an item's z-index from old_z to new_z
        /// Returns error if the item was not found at old_z
        pub fn changeZIndex(self: *Self, item: T, old_z: u8, new_z: u8) !void {
            if (old_z == new_z) return;
            const removed = self.remove(item, old_z);
            if (!removed) {
                return error.ItemNotFound;
            }
            try self.insert(item, new_z);
        }

        /// Get total number of items across all buckets
        pub fn count(self: *const Self) usize {
            return self.total_count;
        }

        /// Clear all buckets
        pub fn clear(self: *Self) void {
            for (&self.buckets) |*bucket| {
                bucket.clearRetainingCapacity();
            }
            self.total_count = 0;
        }

        /// Iterator that yields items in z-index order (0 to 255)
        pub fn iterator(self: *const Self) Iterator {
            return Iterator.init(self);
        }

        pub const Iterator = struct {
            buckets: *const [256]Bucket,
            z: u16,
            idx: usize,

            pub fn init(storage: *const Self) Iterator {
                var iter = Iterator{
                    .buckets = &storage.buckets,
                    .z = 0,
                    .idx = 0,
                };
                iter.skipEmptyBuckets();
                return iter;
            }

            pub fn next(self: *Iterator) ?T {
                while (self.z < 256) {
                    const bucket = &self.buckets[self.z];
                    if (self.idx < bucket.items.len) {
                        const item = bucket.items[self.idx];
                        self.idx += 1;
                        return item;
                    }
                    self.z += 1;
                    self.idx = 0;
                }
                return null;
            }

            fn skipEmptyBuckets(self: *Iterator) void {
                while (self.z < 256 and self.buckets[self.z].items.len == 0) {
                    self.z += 1;
                }
            }

            pub fn reset(self: *Iterator) void {
                self.z = 0;
                self.idx = 0;
                self.skipEmptyBuckets();
            }
        };

        /// Collect all items into a slice in z-index order.
        /// The caller must provide a buffer of at least `count()` size.
        pub fn collectInto(self: *const Self, buffer: []T) []T {
            var i: usize = 0;
            var iter = self.iterator();
            while (iter.next()) |item| {
                if (i >= buffer.len) break;
                buffer[i] = item;
                i += 1;
            }
            return buffer[0..i];
        }

        /// Equality comparison for items
        fn eql(a: T, b: T) bool {
            // Use eql method if available, otherwise use ==
            if (@hasDecl(T, "eql")) {
                return a.eql(b);
            } else {
                return std.meta.eql(a, b);
            }
        }
    };
}

// Tests
test "ZIndexBuckets basic operations" {
    const allocator = std.testing.allocator;

    var buckets = ZIndexBuckets(u32).init(allocator);
    defer buckets.deinit();

    // Insert
    try buckets.insert(100, 5);
    try buckets.insert(200, 10);
    try buckets.insert(300, 5);

    try std.testing.expectEqual(@as(usize, 3), buckets.count());

    // Iterate in z-order
    var iter = buckets.iterator();
    try std.testing.expectEqual(@as(?u32, 100), iter.next());
    try std.testing.expectEqual(@as(?u32, 300), iter.next()); // same z=5
    try std.testing.expectEqual(@as(?u32, 200), iter.next()); // z=10
    try std.testing.expectEqual(@as(?u32, null), iter.next());

    // Remove
    try std.testing.expect(buckets.remove(100, 5));
    try std.testing.expectEqual(@as(usize, 2), buckets.count());

    // Change z-index
    try buckets.changeZIndex(200, 10, 0);
    iter.reset();
    try std.testing.expectEqual(@as(?u32, 200), iter.next()); // now at z=0
}

test "ZIndexBuckets with struct items" {
    const allocator = std.testing.allocator;

    const Item = struct {
        id: u32,
        name: []const u8,

        pub fn eql(self: @This(), other: @This()) bool {
            return self.id == other.id;
        }
    };

    var buckets = ZIndexBuckets(Item).init(allocator);
    defer buckets.deinit();

    try buckets.insert(.{ .id = 1, .name = "first" }, 10);
    try buckets.insert(.{ .id = 2, .name = "second" }, 5);

    try std.testing.expectEqual(@as(usize, 2), buckets.count());

    // Remove by id (uses eql method)
    try std.testing.expect(buckets.remove(.{ .id = 1, .name = "" }, 10));
    try std.testing.expectEqual(@as(usize, 1), buckets.count());
}
