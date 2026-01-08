const std = @import("std");
const expect = @import("zspec").expect;
const zig_utils = @import("zig_utils");
const SparseSet = zig_utils.SparseSet;

pub const SparseSetSpec = struct {
    pub const basic_operations = struct {
        test "inserts and retrieves values" {
            const allocator = std.testing.allocator;

            var set = try SparseSet(u64, u64).init(allocator, 1000, 16);
            defer set.deinit();

            try set.put(5, 500);
            try set.put(10, 1000);
            try set.put(3, 300);

            try expect.equal(set.get(5).?, 500);
            try expect.equal(set.get(10).?, 1000);
            try expect.equal(set.get(3).?, 300);
            try expect.toBeTrue(set.get(999) == null);
        }

        test "contains returns correct values" {
            const allocator = std.testing.allocator;

            var set = try SparseSet(u64, u64).init(allocator, 1000, 16);
            defer set.deinit();

            try set.put(5, 500);

            try expect.toBeTrue(set.contains(5));
            try expect.toBeFalse(set.contains(999));
        }

        test "updates existing values" {
            const allocator = std.testing.allocator;

            var set = try SparseSet(u64, u64).init(allocator, 1000, 16);
            defer set.deinit();

            try set.put(5, 500);
            try set.put(5, 555);

            try expect.equal(set.get(5).?, 555);
        }

        test "removes values correctly" {
            const allocator = std.testing.allocator;

            var set = try SparseSet(u64, u64).init(allocator, 1000, 16);
            defer set.deinit();

            try set.put(5, 500);
            try set.put(10, 1000);

            set.remove(10);

            try expect.toBeFalse(set.contains(10));
            try expect.equal(set.len(), 1);
        }

        test "iterates over values" {
            const allocator = std.testing.allocator;

            var set = try SparseSet(u64, u64).init(allocator, 1000, 16);
            defer set.deinit();

            try set.put(5, 555);
            try set.put(3, 300);

            var sum: u64 = 0;
            for (set.values()) |v| {
                sum += v;
            }
            try expect.equal(sum, 855);
        }
    };

    pub const iteration_after_remove = struct {
        test "iterates correctly after removing middle element" {
            const allocator = std.testing.allocator;

            var set = try SparseSet(u32, u32).init(allocator, 100, 16);
            defer set.deinit();

            try set.put(1, 10);
            try set.put(2, 20);
            try set.put(3, 30);
            try set.put(4, 40);

            set.remove(2);

            var sum: u32 = 0;
            for (set.values()) |v| {
                sum += v;
            }
            try expect.equal(sum, 80);
        }
    };

    pub const different_key_types = struct {
        test "works with u8 keys" {
            const allocator = std.testing.allocator;

            var set = try SparseSet(u8, []const u8).init(allocator, 256, 4);
            defer set.deinit();

            try set.put(0, "zero");
            try set.put(255, "max");

            try expect.toBeTrue(std.mem.eql(u8, set.get(0).?, "zero"));
            try expect.toBeTrue(std.mem.eql(u8, set.get(255).?, "max"));
        }

        test "works with u16 keys" {
            const allocator = std.testing.allocator;

            var set = try SparseSet(u16, f32).init(allocator, 1000, 4);
            defer set.deinit();

            try set.put(500, 3.14);

            try expect.equal(set.get(500).?, 3.14);
        }
    };
};
